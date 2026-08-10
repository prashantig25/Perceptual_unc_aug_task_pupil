classdef PupilRegression < pupilReg_Vars

    properties
        % Results storage (inherited from original PupilRegression)
        betas_struct % structure containing regression beta coefficients
        perm_results % permutation test results
        residuals_all % model residuals for all subjects
        predicted_all % model-predicted pupil responses for all subjects
        starting_points % [n_subj x col x n_sp x num_params], pre-generated

        % Heteroskedastic model properties
        model_type
        n_sp
        use_sp
        p0
        minBound
        maxBound
        lb
        ub
        fmincon_options
        negLL_values

        % Progress bar
        wb % waitbar handle
        total_steps % total increments expected
        completed_steps % running counter (main thread only)
        
        % Default handle to external functions that simplify testing
        externalFitFcn = @linear_fit
        saveFcn = @safe_saveall;
        permtestFcn = @get_permtest_updated;
    end

    methods

        function obj = PupilRegression()
            % PUPILREGRESSION Construct a PupilRegression_intHet object.
            %   Outputs:
            %     obj - Initialised PupilRegression_intHet instance.

            obj = obj@pupilReg_Vars();
            obj.betas_struct    = struct();
            obj.model_type      = 'OLS';
            obj.n_sp            = 20;
            obj.use_sp          = 0;
            obj.wb              = [];
            obj.total_steps     = 0;
            obj.completed_steps = 0;
            obj.p0 = [0, 0, 0, 0.1, 0.1, 0, 0, 0, 0, 0];
        end
     
        function setHeteroskedasticConfig(obj, minBound, maxBound, lb, ub, n_sp)
            % SETHETEROSKEDASTICCONFIG  Configure the object for heteroskedastic
            %   maximum-likelihood estimation.
            %
            %   Inputs:
            %     minBound - Scalar or vector of lower search bounds used
            %                for generating starting points (stored as OBJ.minBound).
            %     maxBound - Scalar or vector of upper search bounds used
            %                for generating starting points (stored as OBJ.maxBound).
            %     lb       - Lower bound vector passed directly to fmincon.
            %     ub       - Upper bound vector passed directly to fmincon.
            %     n_sp     - Number of random starting points to evaluate
            %                per timepoint when OBJ.use_sp == 1.

            obj.model_type      = 'heteroskedastic';
            obj.minBound        = minBound;
            obj.maxBound        = maxBound;
            obj.lb              = lb;
            obj.ub              = ub;
            obj.n_sp            = n_sp;
            obj.fmincon_options = optimoptions('fmincon', ...
                'Display',             'off', ...
                'Algorithm',           'interior-point', ...
                'MaxIterations',       500, ...
                'OptimalityTolerance', 1e-4, ...
                'StepTolerance',       1e-6);
        end

        function initProgress(obj, total, titleStr)
            % INITPROGRESS Open a new waitbar.
            %
            %   Inputs:
            %     total    - Total number of steps expected in the analysis.
            %     titleStr - Message string displayed inside the waitbar dialog.
            
            obj.total_steps     = total;
            obj.completed_steps = 0;
            obj.wb = waitbar(0, titleStr, ...
                'Name', 'Pupil Regression', ...
                'CreateCancelBtn', 'setappdata(gcbf,''cancelled'',true)');
            setappdata(obj.wb, 'cancelled', false);
        end

        function updateProgress(obj, msg)
            % UPDATEPROGRESS Increment the step counter by 1 and refresh the waitbar.
            %
            %   Inputs:
            %     msg - Status message displayed in the waitbar on this update.

            if isempty(obj.wb) || ~isvalid(obj.wb)
                return
            end
            if getappdata(obj.wb, 'cancelled')
                delete(obj.wb);
                obj.wb = [];
                error('PupilRegression:Cancelled', 'Analysis cancelled by user.');
            end
            obj.completed_steps = obj.completed_steps + 1;
            frac = min(obj.completed_steps / max(obj.total_steps, 1), 1);
            waitbar(frac, obj.wb, msg);
        end

        function incrementProgress(obj, n)
            % INCREMENTPROGRESS Add N steps to the counter without changing the message.
            %
            %   Inputs:
            %     n - (numeric) Number of steps to add to the completed step count.

            if isempty(obj.wb) || ~isvalid(obj.wb)
                return
            end
            obj.completed_steps = obj.completed_steps + n;
            frac = min(obj.completed_steps / max(obj.total_steps, 1), 1);
            waitbar(frac, obj.wb);
        end

        function closeProgress(obj)
            % CLOSEPROGRESS Delete the waitbar dialog and reset the handle to empty.
            
            if ~isempty(obj.wb) && isvalid(obj.wb)
                delete(obj.wb);
            end
            obj.wb = [];
        end

        function runAnalysis(obj)
            % RUNANALYSIS  Execute the full pupil regression pipeline.

            % Validate configuration before starting analysis
            obj.validateConfig();

            % Choose number of bins
            if obj.binned == 1
                num_bins = length(obj.bins_array);
            elseif obj.binned_accuracy == 1
                num_bins = 2;
            else
                num_bins = 1;
            end
            
            % Initialize variables depending on model
            if strcmp(obj.model_type, 'heteroskedastic')
                obj.betas_struct.with_intercept = nan(num_bins, obj.num_vars+1, obj.num_subs, obj.col);
                obj.negLL_values = nan(num_bins, obj.num_subs, obj.col);
            else
                % todo: preallocate R2 etc.
                obj.betas_struct.with_intercept = nan(num_bins, obj.num_vars+1, obj.num_subs, obj.col);
            end
            
            % Initialize variables
            obj.residuals_all = cell(obj.num_subs, 1);
            obj.predicted_all = cell(obj.num_subs, 1);

            % Open progress bar
            % Total steps = subjects × bins × timepoints
            % Each timepoint inside fitModelAtTimepoint / fitHeteroAllTimepoints
            % counts as one tick, plus one tick per subject for data loading.
            totalTicks = obj.num_subs * (1 + num_bins * obj.col);
            obj.initProgress(totalTicks, 'Initialising…');

            % Run pipeline for each subject
            for i = 1:obj.num_subs
                obj.processSubject(i, obj.binned);
            end

            % Permutation testing
            if strcmp(obj.model_type, 'OLS')

                % Update progress bar
                obj.updateProgress('Running permutation test…');

                if obj.binned == 0
                    
                    num_vars = 1:obj.num_vars+1;                    
                    var1 = squeeze(obj.betas_struct.with_intercept(1, :, :, :)); % [num_vars x num_subjs x col]
                    obj.perm_results = obj.permtestFcn(num_vars, obj.num_subs, obj.col, var1);

                elseif length(obj.bins) <= 3
                    
                    num_vars = 1:obj.num_vars+1;
                    var1 = squeeze(obj.betas_struct.with_intercept(1, :, :, :)); % [num_vars x num_subjs x col]
                    var2 = squeeze(obj.betas_struct.with_intercept(2, :, :, :)); % [num_vars x num_subjs x col]
                    obj.perm_results = obj.permtestFcn(num_vars, obj.num_subs, obj.col, var1, var2);

                else
                    obj.perm_results = [];
                end
            elseif strcmp(obj.model_type, 'heteroskedastic')
                
                % Update progress bar
                obj.updateProgress('Running permutation test…');
                                  
                % Like this? rasmus added 17 april
                num_vars = 1:obj.num_vars+1;
                obj.updateProgress('Running permutation test…');
                var1 = squeeze(obj.betas_struct.with_intercept(1, :, :, :)); % [num_vars x num_subjs x col]
                obj.perm_results = obj.permtestFcn(num_vars, obj.num_subs, obj.col, var1);

            end
            
            % Close progress bar
            obj.closeProgress();
        end


        function processSubject(obj, subj_idx, binnedAnalysis)
            % PROCESSSUBJECT  Load data and run the regression for one subject.
            %
            % Inputs:
            %
            %   subj_idx - Index of subject to process (1 to num_subs)
            %   binnedAnalysis - Boolean indicating whether we run binned
            %       or regular analysis 
            %

            obj.updateProgress(sprintf('[%d/%d] Loading %s…', ...
                subj_idx, obj.num_subs, obj.subj_ids{subj_idx}));
                
            % Load and preprocess behavioral data
            behv_data = obj.loadBehavioralData(subj_idx);

            % Handle missed trials (remove NaN responses)
            [behv_data, missedtrials_slider] = obj.handleMissedTrials(behv_data);
            
            % Load pupil diameter and eye gaze data
            [zsc_pupil, xgaze_signal, ygaze_signal] = obj.loadPupilGazeData(subj_idx, missedtrials_slider);
            
            % Regress out reaction time effects if requested
            if obj.regress_rt == 1
                zsc_pupil = obj.regressRTEffects(zsc_pupil, behv_data);
            end

            % Load baseline pupil data if needed for model
            zsc_base = obj.loadBaselineData(subj_idx);

            % Extract behavioral predictors and align with pupil data
            [preds, zsc_pupil, xgaze_signal, ygaze_signal] = ...
                obj.getBehavioralPredictors(subj_idx, zsc_pupil, xgaze_signal, ygaze_signal, zsc_base);

            % Apply binning to continuous variables if requested
            if obj.binned == 1
                preds.bin_columns = discretize(preds.con_diff, obj.bins);
            end

            % Process data through bins and timepoints to fit regression models
            obj.processBinsAndTimepoints(preds, zsc_pupil, xgaze_signal, ygaze_signal, subj_idx, binnedAnalysis);

        end

        function behv_data = loadBehavioralData(obj, subj_idx)
            % LOADBEHAVIORALDATA  Read and concatenate behavioural Excel files for
            %   one subject across all sessions.
            %
            %   BEHV_DATA = loadBehavioralData(OBJ, SUBJ_IDX) iterates over subjects,
            %   extracts choice RT and slider response columns, and vertically 
            %   concatenates all sessions into a single table.
            %
            %   Inputs:
            %     subj_idx  - 1-based index into OBJ.subj_ids.
            %
            %   Outputs:
            %     behv_data - Concatenated behavioural table with columns
            %                 1:16 from the raw file plus 'rt' and 'slider'.

            behv_data = [];

            % Loop through all sessions for this subject
            for j = 1:obj.num_sess(subj_idx)

                % Construct filename (special case for subject 4672)
                filename = fullfile(obj.behv_dir, [obj.subj_ids{subj_idx}, '_main', num2str(j), '.xlsx']);
                if strcmp(obj.subj_ids{subj_idx}, '4672')
                    filename = fullfile(obj.behv_dir, [obj.subj_ids{subj_idx}, '_main', num2str(j), '_red.xlsx']);
                end

                % Load session data and extract relevant columns
                data_run = readtable(filename, 'VariableNamingRule', 'preserve');
                rt = table(data_run.('choice.rt'), 'VariableNames', {'rt'});
                slider = table(data_run.('slider_respond.response'), 'VariableNames', {'slider'});
                data_run = [data_run(:, 1:16), rt, slider];
                
                % Concatenate with previous sessions
                behv_data = [behv_data; data_run];
            end
        end

        function [behv_data, missedtrials_slider] = handleMissedTrials(~, behv_data)
            % HANDLEMISSEDTRIALS  Remove trials with missing RT or slider responses.
            %
            %   [BEHV_DATA, MISSEDTRIALS_SLIDER] = handleMissedTrials(OBJ, BEHV_DATA)
            %   identifies trials where either the choice RT or the slider response
            %   is NaN and removes them from BEHV_DATA.  A secondary logical index
            %   MISSEDTRIALS_SLIDER is returned, indicating which trials (among those
            %   with valid RT) had a missing slider response; this index is used
            %   downstream to remove the corresponding rows from pupil and gaze data.
            %
            %   Inputs:
            %     behv_data           - Raw concatenated behavioural table.
            %
            %   Outputs:
            %     behv_data           - Cleaned table with missed trials removed.
            %     missedtrials_slider - True for rows (from the
            %                          RT-valid subset) where the slider response
            %                          was NaN.
            
            % Identify missed reaction time trials
            missedtrials_rt = isnan(behv_data.rt);
            behvdata_missedRT = behv_data(missedtrials_rt == 0, :);
            
            % Identify missed slider response trials
            missedtrials_slider = isnan(behvdata_missedRT.slider);
            
            % Create combined index of all missed trials
            missedtrials = isnan(behv_data.rt) | isnan(behv_data.slider);
            
            % Remove all missed trials from behavioral data
            behv_data(missedtrials == 1, :) = [];

        end

        function [zsc_pupil, xgaze_signal, ygaze_signal] = loadPupilGazeData(obj, subj_idx, missedtrials_slider)
            % LOADPUPILGAZEDATA  Load z-scored pupil and gaze signals for one subject.
            %
            % Parameters:
            %   subj_idx - Index of subject to load data for
            %   missedtrials_slider - Logical index of missed slider trials
            %
            % Returns:
            %   zsc_pupil - Z-scored pupil diameter time series
            %   xgaze_signal - Horizontal eye gaze position time series  
            %   ygaze_signal - Vertical eye gaze position time series

            % Load pupil diameter data
            filename   = fullfile(obj.pupil_dir, [obj.subj_ids{subj_idx}, '.mat']);
            pupil      = importdata(filename);
            size_pupil = size(pupil);

            % Load horizontal gaze data
            filename     = fullfile(obj.xgaze_dir, [obj.subj_ids{subj_idx}, '.mat']);
            xgaze_event  = importdata(filename);

            % Load vertical gaze data
            filename     = fullfile(obj.ygaze_dir, [obj.subj_ids{subj_idx}, '.mat']);
            ygaze_event  = importdata(filename);

            % Extract relevant time window based on analysis timewindow
            if strcmp(obj.timewindow, 'patch')
                % Use entire signal for patch-locked analysis
                zsc_pupil     = pupil;
                xgaze_signal  = xgaze_event;
                ygaze_signal  = ygaze_event;
                obj.col       = size_pupil(2);
            elseif strcmp(obj.timewindow, 'feedback')
                % Use first 'col' timepoints for feedback-locked analysis
                zsc_pupil     = pupil(:, 1:obj.col);
                xgaze_signal  = xgaze_event(:, 1:obj.col);
                ygaze_signal  = ygaze_event(:, 1:obj.col);
            end

            % Remove trials with missing behavioral responses
            zsc_pupil(missedtrials_slider == 1, :) = [];
            xgaze_signal(missedtrials_slider == 1, :) = [];
            ygaze_signal(missedtrials_slider == 1, :) = [];
        end

        function residual = remove_rt_effects(~, pupil,rt)
            % NOTE: code is based on Urai et al., 2017
            % function REMOVE_RT_EFFECTS removes trial-by-trial variations in pupil
            % signal caused by very slow/long RTs
            %
            % INPUT:
            %   pupil: signal from which RT needs to be regressed
            %   rt: reaction-times
            %
            % OUTPUT:
            %   residual: pupil signal after regressing out RTs

            % normalise rt
            rt_norm = rt/norm(rt);

            % subtract dot product from pupil (formula: y' = y - (y.'r)r)
            residual = pupil - (pupil'*rt_norm)*rt_norm;
        end

        function zsc_pupil = regressRTEffects(obj, zsc_pupil, behv_data)
            % REGRESSRTEFFECTS  Remove log-RT variance from the pupil signal at
            %   every timepoint.
            %
            % Inputs:
            %   zsc_pupil - Original pupil signal matrix (trials x timepoints)
            %   behv_data - Behavioral data containing reaction times
            %
            % Outputs:
            %   zsc_pupil - Pupil signal with RT effects removed

            % Apply RT regression to each timepoint
            for c = 1:obj.col
                zsc_pupil(:, c) = obj.remove_rt_effects(zsc_pupil(:, c), log(behv_data.rt));
            end
        end

        function zsc_base = loadBaselineData(obj, subj_idx)
            % LOADBASELINEDATA  Load pre-trial baseline pupil data for one subject.
            %
            % Inputs:
            %   subj_idx - Index of subject to load baseline data for
            %   missedtrials_slider - Logical index of trials to exclude
            %
            % Outputs:
            %   zsc_base - Baseline pupil measurements, or empty if not needed

            zsc_base = [];
            if obj.baseline_mdl == 1
                filename = fullfile(obj.base_dir, [obj.subj_ids{subj_idx}, '.mat']);
                zsc_base = importdata(filename);
            end
        end

        function [preds, zsc_pupil, xgaze_signal, ygaze_signal] = getBehavioralPredictors(obj, subj_idx, zsc_pupil, xgaze_signal, ygaze_signal, zsc_base)
            % GETBEHAVIORALPREDICTORS  Extract and align predictor variables for
            % one subject, removing invalid rows.
            %
            % Inputs:
            %   subj_idx - Index of current subject
            %   zsc_pupil - Pupil diameter data
            %   xgaze_signal - Horizontal gaze data
            %   ygaze_signal - Vertical gaze data  
            %   behv_data - Behavioral data
            %   zsc_base - Baseline data (if applicable)
            %
            % Outputs:
            %   preds - Table of behavioral predictors for regression
            %   zsc_pupil - Aligned pupil data
            %   xgaze_signal - Aligned horizontal gaze data
            %   ygaze_signal - Aligned vertical gaze data
            %   behv_data - Aligned behavioral data
            %   zsc_base - Aligned baseline data

            % Extract predictors for current subject
            preds = obj.preds_all(obj.preds_all.id == str2double(obj.subj_ids{subj_idx}), :);
            
            % Remove trials with zero prediction error 
            % (not useful for regression since predicted UP would be 0 as well)
            invalidIndices = find(preds.pe == 0); 
            preds(invalidIndices, :) = [];
            zsc_pupil(invalidIndices, :) = [];
            xgaze_signal(invalidIndices, :) = [];
            ygaze_signal(invalidIndices, :) = [];

            % Remove corresponding baseline trials if applicable
            if obj.baseline_mdl == 1
                zsc_base(invalidIndices, :) = [];
            end
        end

        function processBinsAndTimepoints(obj, preds, zsc_pupil, xgaze_signal, ygaze_signal, subj_idx, binnedAnalysis)
            % PROCESSBINSANDTIMEPOINTS  Fit the regression model across all bins
            %   and timepoints for one subject.
            %
            % Parameters:
            %   preds - Behavioral predictors table
            %   zsc_pupil - Pupil diameter data
            %   xgaze_signal - Horizontal gaze data
            %   ygaze_signal - Vertical gaze data
            %   behv_data - Behavioral data
            %   subj_idx - Current subject index
            %   binnedAnalysis - Boolean indicating whether we run binned
            %       or regular analysis 
           
            numBins  = length(obj.bins_array);
            
            % Loop through bins (or single bin if not binned analysis)
            for r = obj.bins_array

                binLabel = sprintf('[%d/%d] Subj %s – bin %d/%d', ...
                    subj_idx, obj.num_subs, obj.subj_ids{subj_idx}, r, numBins);

                % Get binned data
                if binnedAnalysis == 1
                    [pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins] = ...
                        obj.getBinnedData(r, preds, zsc_pupil, xgaze_signal, ygaze_signal);
                else
                    pupil_signal_bins  = zsc_pupil;
                    xgaze_signal_bins  = xgaze_signal;
                    ygaze_signal_bins  = ygaze_signal;
                    preds_bins         = preds;
                end
               
                if strcmp(obj.model_type, 'heteroskedastic')
                    
                    % Heteroskedastic model
                    obj.updateProgress(sprintf('%s | Het model…', binLabel));
                    if obj.use_sp == 1
                        obj.fitHeteroAllTimepoints( ...
                            pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins, subj_idx);
                    else
                        obj.forPregenSP( ...
                            pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins, subj_idx);
                    end

                else
                    
                    % Fit model at each timepoint
                    for c = 1:obj.col
                        obj.updateProgress(sprintf('%s | t %d/%d', binLabel, c, obj.col));
                        obj.fitModelAtTimepoint(c, ...
                            pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins, r, subj_idx);
                    end
                end
            end
        end

        function [pupil_bins, xgaze_bins, ygaze_bins, preds_bins] = getBinnedData(obj, r, preds, zsc_pupil, xgaze_signal, ygaze_signal)
            % GETBINNEDDATA  Subset trial data to a single bin or accuracy level.
            %
            % Inputs:
            %   r - Current bin index
            %   preds - Behavioral predictors
            %   zsc_pupil - Pupil data
            %   xgaze_signal - Horizontal gaze data
            %   ygaze_signal - Vertical gaze data
            %   behv_data - Behavioral data
            %
            % Outputs:
            %   pupil_bins - Pupil data for current bin
            %   xgaze_bins - Horizontal gaze data for current bin  
            %   ygaze_bins - Vertical gaze data for current bin
            %   behv_bins - Behavioral data for current bin
            %   preds_bins - Predictors for current bin

            % Determine which trials belong to current bin
            if obj.binned == 1
                % Use discretized continuous variable bins
                idx = preds.bin_columns == r;
            elseif obj.binned_accuracy == 1
                % Use accuracy-based binning
                idx = preds.correct == r;
            end

            % Extract data for current bin
            pupil_bins  = zsc_pupil(idx, :);
            xgaze_bins  = xgaze_signal(idx, :);
            ygaze_bins  = ygaze_signal(idx, :);
            preds_bins  = preds(idx, :);
        end

        function fitModelAtTimepoint(obj, c, pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins, r, subj_idx)
            % FITMODELATTIMEPOINT Fit regression model at a specific timepoint
            % Creates predictor matrix and fits linear model to pupil data
            %
            % Inputs:
            %   c - Current timepoint index
            %   pupil_signal_bins - Pupil data for current bin
            %   xgaze_signal_bins - Horizontal gaze data for current bin
            %   ygaze_signal_bins - Vertical gaze data for current bin
            %   preds_bins - Predictors for current bin
            %   r - Current bin index
            %   subj_idx - Current subject index

            % Extract dependent variable (pupil diameter at timepoint c)
            y = pupil_signal_bins(:, c);
            
            % Z-score gaze signals
            zsc_xgaze = zscore(xgaze_signal_bins(:, c));
            zsc_ygaze = zscore(ygaze_signal_bins(:, c));

            % Extract valid data
            validIdx = ~isnan(y) & ~isnan(preds_bins.up);
            yValid = y(validIdx);
            xgazeValid = zsc_xgaze(validIdx);
            ygazeValid = zsc_ygaze(validIdx);
            preds_valid = preds_bins(validIdx, :);

            % Create regression table with all predictors
            tbl = table(yValid, xgazeValid, ygazeValid, ...
                zscore(preds_valid.con_diff), zscore(preds_valid.pe), ...
                zscore(abs(preds_valid.pe)), zscore(abs(preds_valid.up)), ...
                zscore(log(preds_valid.rt)), preds_valid.condition, preds_valid.ecoperf, ...
                preds_valid.correct, zscore(preds_valid.pe_condiff), ...
                'VariableNames', {'pupil','xgaze','ygaze','zsc_condiff','signed_pe', ...
                'pe','zsc_up','rt','condition','ecoperf','reward','pe_condiff'});

            % Fit linear regression model
            [betas, ~, ~, ~, lm] = obj.externalFitFcn(tbl, obj.model_def, ...
                obj.pred_vars, obj.resp_var, obj.cat_vars, obj.num_vars, 0);

            % Save coefficient names once
            if subj_idx == 1 && c == 1
                coeff_names = lm.CoefficientNames;
                % safe_saveall(fullfile(obj.save_dir, [obj.betas_save, '_coeffNames.mat']), coeff_names);
                obj.betas_struct.coeff_names = coeff_names;
            end

            % Store beta coefficients in results structure
            if obj.binned_accuracy == 1
                obj.betas_struct.with_intercept(r+1, :, subj_idx, c) = betas;
            else
                obj.betas_struct.with_intercept(r,   :, subj_idx, c) = betas;
            end
        end

        function [x1_z, x2_z, rt_z, up_z, zsc_pupil, xgaze_z, ygaze_z, dq] = ...
                preprocessSignals(obj, zsc_pupil, xgaze_signal, ygaze_signal, preds_bins, subj_idx)
            % PREPROCESSSIGNALS Z-score predictors and gaze signals, remove NaN
            %   rows, and create a DataQueue for parfor progress reporting.
            %
            %
            %   Inputs:
            %     zsc_pupil    -  Pupil signal 
            %     xgaze_signal - X-gaze signal 
            %     ygaze_signal - Y-gaze signal 
            %     preds_bins   - Predictor table for the current bin
            %     subj_idx     - 1-based subject index 
            %
            %   Outputs:
            %     x1_z      - Z-scored |PE| 
            %     x2_z      - Z-scored condition difficulty 
            %     rt_z      - Z-scored log-RT 
            %     up_z      - Z-scored |UP| 
            %     zsc_pupil - NaN-free pupil signal 
            %     xgaze_z   - NaN-free z-scored x-gaze 
            %     ygaze_z   - NaN-free z-scored y-gaze 
            %     dq        - Queue for forwarding per-timepoint
            %                 progress increments from parfor workers to the main thread.

            col = obj.col;

            % Pre-compute z-scored predictors
            x1_z = zscore(abs(preds_bins.pe));
            x2_z = zscore(preds_bins.con_diff);
            rt_z = zscore(log(preds_bins.rt));
            up_z = zscore(abs(preds_bins.up));
            xgaze_z = nan(size(xgaze_signal));
            ygaze_z = nan(size(ygaze_signal));
            for c = 1:col
                xgaze_z(:, c) = zscore(xgaze_signal(:, c));
                ygaze_z(:, c) = zscore(ygaze_signal(:, c));
            end

            % Remove NaN rows: todo: why are NaN values expected?
            valid_rows = ~any(isnan([x1_z, x2_z, rt_z, up_z, zsc_pupil, xgaze_z, ygaze_z]), 2);
            x1_z = x1_z(valid_rows);
            x2_z = x2_z(valid_rows);
            rt_z = rt_z(valid_rows);
            up_z = up_z(valid_rows);
            zsc_pupil = zsc_pupil(valid_rows, :);
            xgaze_z   = xgaze_z(valid_rows, :);
            ygaze_z   = ygaze_z(valid_rows, :);

            % Update progress bar
            dq = parallel.pool.DataQueue;
            afterEach(dq, @(v) obj.incrementProgress(v));

            % Update bar label once before launching parfor
            obj.updateProgress(sprintf('Subj %d/%d | het timepoints (0/%d)…', ...
                subj_idx, obj.num_subs, col));
        end

        function storeResults(obj, subj_idx, negLL_row, betas_row)
            % STORERESULTS  Write heteroskedastic MLE results into object arrays.
            %
            %
            %   Inputs:
            %     subj_idx  - Subject index
            %     negLL_row - Minimum negative log-likelihood
            %                 at each timepoint
            %     betas_row - Best-fit parameter
            %                 vector at each timepoint

            obj.negLL_values(1, subj_idx, :) = negLL_row;
            for c = 1:obj.col
                obj.betas_struct.with_intercept(1, :, subj_idx, c) = betas_row(c, :);
            end
        end

        function fitHeteroAllTimepoints( ...
                obj, zsc_pupil, xgaze_signal, ygaze_signal, preds_bins, subj_idx)
            % FITHETEREALLTIMEPOINTS  Fit the heteroskedastic model at all timepoints
            %   using multiple random starting points (parfor).
            %
            %
            %   Inputs:
            %     zsc_pupil    - Pupil signal 
            %     xgaze_signal - X-gaze signal
            %     ygaze_signal - Y-gaze signal
            %     preds_bins   - Predictor table for the current bin.
            %     subj_idx     - 1-based subject index.

            % Extract all obj fields into plain variables
            col        = obj.col;
            n_sp_parfor = obj.n_sp;
            lb_parfor = obj.lb;
            ub_parfor = obj.ub;
            foptions = obj.fmincon_options;
            num_params = obj.num_vars + 1;
            starts_subj = squeeze(obj.starting_points(subj_idx, :, :, :));

            [x1_z, x2_z, rt_z, up_z, zsc_pupil, xgaze_z, ygaze_z, dq] = ...
                obj.preprocessSignals(zsc_pupil, xgaze_signal, ygaze_signal, preds_bins, subj_idx);

            % Pre-allocate outputs
            negLL_row = nan(1, col);
            betas_row = nan(col, num_params);

            parfor c = 1:col
                y     = zsc_pupil(:, c);
                xgaze = xgaze_z(:, c);
                ygaze = ygaze_z(:, c);
                negLLfun = @(params) PupilRegression.negativeLogLikelihood( ...
                    params, x1_z, x2_z, y, rt_z, up_z, xgaze, ygaze); % todo: check this!! %#ok<PFBNS>

                bestNegLL  = inf;
                bestParams = zeros(1, num_params); % safe parfor initialisation
                for i = 1:n_sp_parfor
                    p0_parfor = squeeze(starts_subj(c, i, :))';
                    [p_est, nLL_val] = fmincon(negLLfun, p0_parfor, [], [], [], [], lb_parfor, ub_parfor, [], foptions);
                    if nLL_val < bestNegLL
                        bestNegLL  = nLL_val;
                        bestParams = p_est;
                    end
                end

                % k            = num_params;
                negLL_row(c) = bestNegLL;
                betas_row(c, :) = bestParams;
                % Notify main thread: one timepoint done
                send(dq, 1); %#ok<PFBNS>
            end

            obj.storeResults(subj_idx, negLL_row, betas_row);
        end

        function forPregenSP( ...
                obj, zsc_pupil, xgaze_signal, ygaze_signal, preds_bins, subj_idx)
            % FORPREGENSP Fit the heteroskedastic model at all timepoints using a
            %   single warm-started sequence.
            %
            %   Runs fmincon sequentially over timepoints, initialising
            %   each call with the best-fit parameters from the previous timepoint.
            %
            %   Inputs:
            %     zsc_pupil    - Pupil signal 
            %     xgaze_signal - X-gaze signal 
            %     ygaze_signal - Y-gaze signal 
            %     preds_bins   - Predictor table for the current bin
            %     subj_idx     - 1-based subject index

            % Extract all obj fields into plain variables
            col = obj.col;
            lb_parfor = obj.lb;
            ub_parfor = obj.ub;
            foptions = obj.fmincon_options;
            num_params = obj.num_vars + 1;
            bestParams = obj.p0;

            [x1_z, x2_z, rt_z, up_z, zsc_pupil, xgaze_z, ygaze_z, dq] = ...
                obj.preprocessSignals(zsc_pupil, xgaze_signal, ygaze_signal, preds_bins, subj_idx);

            % Pre-allocate outputs
            negLL_row = nan(1, col);
            betas_row = nan(col, num_params);
            %starts_subj = squeeze(obj.starting_points(subj_idx, :, :, :));

            for c = 1:col
                y     = zsc_pupil(:, c);
                xgaze = xgaze_z(:, c);
                ygaze = ygaze_z(:, c);
                negLLfun = @(params) PupilRegression.negativeLogLikelihood( ...
                    params, x1_z, x2_z, y, rt_z, up_z, xgaze, ygaze); %#ok<PFBNS>

                %bestNegLL  = inf;
                % bestParams = obj.p0;
                [p_est, nLL_val] = fmincon(negLLfun, bestParams, [], [], [], [], lb_parfor, ub_parfor, [], foptions);
                bestNegLL  = nLL_val;
                bestParams = p_est;
                %p0 = bestParams;

                %k            = num_params;
                negLL_row(c) = bestNegLL;
                betas_row(c, :) = bestParams;
                % Notify main thread: one timepoint done
                send(dq, 1); %#ok<PFBNS>
            end

            obj.storeResults(subj_idx, negLL_row, betas_row);
        end


        function saveResults(obj, tol)
            %SAVE RESULTS saves the results of interest for further
            %analysis
            %
            % Input
            %   tol: Optional tolerance for safe_saveall function

            % Tolerance on precision
            if isempty(tol)
                tol = 1e-12;
            end

            if ~exist(obj.save_dir, 'dir')
                mkdir(obj.save_dir);
            end

            safe_saveall(fullfile(obj.save_dir, [obj.betas_save, '.mat']), obj.betas_struct, tol);

            if strcmp(obj.model_type, 'OLS')
                safe_saveall(fullfile(obj.save_dir, [obj.perm_save, '.mat']), obj.perm_results);
            elseif strcmp(obj.model_type, 'heteroskedastic')
                safe_saveall(fullfile(obj.save_dir, ['negLL_', obj.betas_save, '.mat']), obj.negLL_values);
                safe_saveall(fullfile(obj.save_dir, ['perm_', obj.betas_save, '.mat']), obj.perm_results);
            end
        end

    end

    methods (Static)
        
        function nLL = negativeLogLikelihood(params, x1, x2, y, x3, x4, x5, x6)
            % NEGATIVELOGLIKELIHOOD Evaluate the negative log-likelihood of a
            %   heteroskedastic Gaussian regression model.
            % 
            %   Inputs:
            %     params - Parameter vector:
            %                [beta0, beta1, beta2, omik0, omik1, beta21,
            %                 beta3, beta4, beta5, beta6]
            %                where beta0   = intercept,
            %                      beta1   = coefficient for x1 (|PE|),
            %                      beta2   = coefficient for x2 (con_diff),
            %                      omik0   = baseline noise,
            %                      omik1   = noise scaling by |x2|,
            %                      beta21  = x1 × x2 interaction coefficient,
            %                      beta3-6 = coefficients for x3-x6 (rt, up, xgaze, ygaze).
            %     x1     - Z-scored |PE| [trials × 1]
            %     x2     - Z-scored condition difficulty [trials × 1]
            %     y      - Pupil signal at one timepoint [trials × 1]
            %     x3     - Z-scored log-RT [trials × 1]
            %     x4     - Z-scored |UP| [trials × 1]
            %     x5     - Z-scored x-gaze [trials × 1]
            %     x6     - Z-scored y-gaze [trials × 1]
            %
            %   Outputs:
            %     nLL - (scalar) Negative summed log-likelihood (to be minimised).

            beta0  = params(1);  beta1  = params(2);  beta2  = params(3);
            omik0  = params(4);  omik1  = params(5);  beta21 = params(6);
            beta3  = params(7);  beta4  = params(8);
            beta5  = params(9);  beta6  = params(10);

            yhat  = beta0 + beta1*x1 + beta2*x2 + beta21*(x1.*x2) ...
                + beta3*x3 + beta4*x4 + beta5*x5 + beta6*x6;
            sigma = max(omik0 + omik1.*abs(x2), 1e-6);
            logL  = -0.5*log(2*pi) - log(sigma) - 0.5*((y - yhat)./sigma).^2;
            nLL   = -sum(logL);
        end

    end

end