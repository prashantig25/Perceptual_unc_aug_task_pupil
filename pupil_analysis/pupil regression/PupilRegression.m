classdef PupilRegression < pupilReg_Vars
    % Main class for pupil regression analysis, inheriting from pupilReg_Vars
    % Performs comprehensive pupil dilation analysis with behavioral predictors
    
    properties (Access = private)
        % Results storage
        betas_struct     % Structure containing regression beta coefficients
        perm_results     % Permutation test results
        residuals_all    % Model residuals for all subjects
        predicted_all    % Model-predicted pupil responses for all subjects
    end
    
    methods
        function obj = PupilRegression(config)
            % Constructor - Creates a new PupilRegression instance
            % Can optionally accept a configuration object to initialize parameters
            %
            % Parameters:
            %   config - (optional) PupilRegressionConfig object with analysis parameters
            %
            % Returns:
            %   obj - PupilRegression object ready for analysis
            obj = obj@pupilReg_Vars(); % Call superclass constructor
            
            if nargin > 0 && isa(config, 'PupilRegressionConfig')
                obj.copyFromConfig(config);
            end
        end
        
        function copyFromConfig(obj, config)
            % Copy properties from another configuration object
            % Transfers all matching properties from config object to this instance
            %
            % Parameters:
            %   config - Source configuration object containing analysis parameters
            props = properties(config);
            for i = 1:length(props)
                if isprop(obj, props{i})
                    obj.(props{i}) = config.(props{i});
                end
            end
        end
        
        function [betas_struct, perm, residuals_all, predicted_all] = runAnalysis(obj)
            % Main method to run the complete pupil regression analysis pipeline
            % Processes all subjects, fits regression models, and runs permutation tests
            %
            % Returns:
            %   betas_struct - Structure containing regression coefficients for all subjects
            %   perm - Permutation test results with statistical significance
            %   residuals_all - Cell array of model residuals for each subject
            %   predicted_all - Cell array of model predictions for each subject
            
            % Validate configuration before starting analysis
            obj.validateConfig();
            
            % Initialize output variables
            obj.residuals_all = cell(obj.num_subs, 1);
            obj.predicted_all = cell(obj.num_subs, 1);
            
            % Loop over subjects and process each individually
            for i = 1:obj.num_subs
                [residuals_subj, predicted_subj] = obj.processSubject(i);
                obj.residuals_all{i, 1} = residuals_subj;
                obj.predicted_all{i, 1} = predicted_subj;
            end
            
            % Run permutation test for statistical significance
            obj.runPermutationTest();
            
            % Return results
            betas_struct = obj.betas_struct;
            perm = obj.perm_results;
            residuals_all = obj.residuals_all;
            predicted_all = obj.predicted_all;
        end
        
        function [residuals_subj, predicted_subj] = processSubject(obj, subj_idx)
            % Process a single subject through the complete analysis pipeline
            % Loads data, handles missing trials, applies preprocessing, and fits models
            %
            % Parameters:
            %   subj_idx - Index of subject to process (1 to num_subs)
            %
            % Returns:
            %   residuals_subj - Model residuals for this subject
            %   predicted_subj - Model predictions for this subject
            
            % Initialize output variables
            residuals_subj = [];
            predicted_subj = [];
            
            fprintf('Reading in %s ...\n', obj.subj_ids{subj_idx});
            
            % Load and preprocess behavioral data
            behv_data = obj.loadBehavioralData(subj_idx);
            
            % Handle missed trials (remove NaN responses)
            [behv_data, missedtrials, missedtrials_slider] = obj.handleMissedTrials(behv_data);
            
            % Load pupil diameter and eye gaze data
            [zsc_pupil, xgaze_signal, ygaze_signal] = obj.loadPupilGazeData(subj_idx, missedtrials, missedtrials_slider);
            
            % Regress out reaction time effects if requested
            if obj.regress_rt == 1
                zsc_pupil = obj.regressRTEffects(zsc_pupil, behv_data);
            end
            
            % Load baseline pupil data if needed for model
            zsc_base = obj.loadBaselineData(subj_idx, missedtrials_slider);
            
            % Extract behavioral predictors and align with pupil data
            [preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base] = ...
                obj.getBehavioralPredictors(subj_idx, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base);
            
            % Apply binning to continuous variables if requested
            if obj.binned == 1
                preds.bin_columns = discretize(preds.con_diff, obj.bins);
            end
            
            % Process data through bins and timepoints to fit regression models
            [residuals_subj, predicted_subj] = obj.processBinsAndTimepoints(preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base, subj_idx);
        end
        
        function behv_data = loadBehavioralData(obj, subj_idx)
            % Load behavioral data from Excel files for a specific subject
            % Concatenates data across multiple experimental sessions
            %
            % Parameters:
            %   subj_idx - Index of subject to load data for
            %
            % Returns:
            %   behv_data - Table containing all behavioral data for the subject
            
            behv_data = [];
            
            % Loop through all sessions for this subject
            for j = 1:obj.num_sess(subj_idx)
                % Construct filename (special case for subject 4672)
                filename = fullfile(obj.behv_dir, [obj.subj_ids{subj_idx}, '_main', num2str(j), '.xlsx']);
                if strcmp(obj.subj_ids{subj_idx}, '4672')
                    filename = fullfile(obj.behv_dir, [obj.subj_ids{subj_idx}, '_main', num2str(j), '_red.xlsx']);
                end
                
                % Load session data and extract relevant columns
                data_run = readtable(filename);
                rt = table(data_run.choice_rt, 'VariableNames', {'rt'});
                slider = table(data_run.slider_respond_response, 'VariableNames', {'slider'});
                data_run = [data_run(:, 1:16), rt, slider];
                
                % Concatenate with previous sessions
                behv_data = [behv_data; data_run];
            end
        end
        
        function [behv_data, missedtrials, missedtrials_slider] = handleMissedTrials(obj, behv_data)
            % Identify and remove trials with missing behavioral responses
            % Creates indices for trials with missing RT or slider responses
            %
            % Parameters:
            %   behv_data - Raw behavioral data table
            %
            % Returns:
            %   behv_data - Behavioral data with missed trials removed
            %   missedtrials - Logical index of all missed trials (RT or slider)
            %   missedtrials_slider - Logical index of missed slider responses only
            
            % Identify missed reaction time trials
            missedtrials_rt = isnan(behv_data.rt);
            behvdata_missedRT = behv_data(missedtrials_rt == 0, :); % Remove missed RT trials temporarily
            
            % Identify missed slider response trials
            missedtrials_slider = isnan(behvdata_missedRT.slider);
            
            % Create combined index of all missed trials
            missedtrials = isnan(behv_data.rt) | isnan(behv_data.slider);
            
            % Remove all missed trials from behavioral data
            behv_data(missedtrials == 1, :) = [];
        end
        
        function [zsc_pupil, xgaze_signal, ygaze_signal] = loadPupilGazeData(obj, subj_idx, missedtrials, missedtrials_slider)
            % Load pupil diameter and eye gaze position data
            % Extracts relevant time window and removes trials with missing behavioral data
            %
            % Parameters:
            %   subj_idx - Index of subject to load data for
            %   missedtrials - Logical index of missed behavioral trials
            %   missedtrials_slider - Logical index of missed slider trials
            %
            % Returns:
            %   zsc_pupil - Z-scored pupil diameter time series
            %   xgaze_signal - Horizontal eye gaze position time series  
            %   ygaze_signal - Vertical eye gaze position time series
            
            fprintf('Pupil signal...\n');
            
            % Load pupil diameter data
            filename = fullfile(obj.pupil_dir, [obj.subj_ids{subj_idx}, '.mat']);
            pupil = importdata(filename);
            size_pupil = size(pupil);
            
            % Load horizontal gaze data
            filename = fullfile(obj.xgaze_dir, [obj.subj_ids{subj_idx}, '.mat']);
            xgaze_event = importdata(filename);
            
            % Load vertical gaze data
            filename = fullfile(obj.ygaze_dir, [obj.subj_ids{subj_idx}, '.mat']);
            ygaze_event = importdata(filename);
            
            % Extract relevant time window based on analysis timewindow
            if strcmp(obj.timewindow, 'patch')
                % Use entire signal for patch-locked analysis
                zsc_pupil = pupil;
                xgaze_signal = xgaze_event;
                ygaze_signal = ygaze_event;
                obj.col = size_pupil(2);
            elseif strcmp(obj.timewindow, 'feedback')
                % Use first 'col' timepoints for feedback-locked analysis
                zsc_pupil = pupil(:, 1:obj.col);
                xgaze_signal = xgaze_event(:, 1:obj.col);
                ygaze_signal = ygaze_event(:, 1:obj.col);
            end
            
            % Remove trials with missing behavioral responses
            zsc_pupil(missedtrials_slider == 1, :) = [];
            xgaze_signal(missedtrials, :) = [];
            ygaze_signal(missedtrials, :) = [];
        end
        
        function zsc_pupil = regressRTEffects(obj, zsc_pupil, behv_data)
            % Remove reaction time effects from pupil signal
            % Regresses out log RT from each timepoint to isolate non-RT related variance
            %
            % Parameters:
            %   zsc_pupil - Original pupil signal matrix (trials x timepoints)
            %   behv_data - Behavioral data containing reaction times
            %
            % Returns:
            %   zsc_pupil - Pupil signal with RT effects removed
            
            % Apply RT regression to each timepoint
            for c = 1:obj.col
                zsc_pupil(:, c) = remove_rt_effects(zsc_pupil(:, c), log(behv_data.rt));
            end
        end
        
        function zsc_base = loadBaselineData(obj, subj_idx, missedtrials_slider)
            % Load baseline pupil measurements if required by the model
            % Baseline data is used as a covariate to control for individual differences
            %
            % Parameters:
            %   subj_idx - Index of subject to load baseline data for
            %   missedtrials_slider - Logical index of trials to exclude
            %
            % Returns:
            %   zsc_base - Baseline pupil measurements, or empty if not needed
            
            zsc_base = [];
            
            if obj.baseline_mdl == 1
                fprintf('Getting baseline pupil measures...\n');
                filename = fullfile(obj.base_dir, [obj.subj_ids{subj_idx}, '.mat']);
                zsc_base = importdata(filename);
            end
        end
        
        function [preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base] = getBehavioralPredictors(obj, subj_idx, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base)
            % Extract behavioral predictors and align with physiological data
            % Removes trials with invalid prediction errors and aligns data matrices
            %
            % Parameters:
            %   subj_idx - Index of current subject
            %   zsc_pupil - Pupil diameter data
            %   xgaze_signal - Horizontal gaze data
            %   ygaze_signal - Vertical gaze data  
            %   behv_data - Behavioral data
            %   zsc_base - Baseline data (if applicable)
            %
            % Returns:
            %   preds - Table of behavioral predictors for regression
            %   zsc_pupil - Aligned pupil data
            %   xgaze_signal - Aligned horizontal gaze data
            %   ygaze_signal - Aligned vertical gaze data
            %   behv_data - Aligned behavioral data
            %   zsc_base - Aligned baseline data
            
            fprintf('Get predictors from behavioural data...\n');
            
            % Extract predictors for current subject
            preds = obj.preds_all(obj.preds_all.id == str2double(obj.subj_ids{subj_idx}), :);
            
            % Remove trials with missing slider responses
            preds(isnan(preds.slider), :) = [];
            
            % Remove trials with zero prediction error (invalid trials)
            validIndices = find(preds.pe == 0);
            preds(validIndices, :) = [];
            zsc_pupil(validIndices, :) = [];
            xgaze_signal(validIndices, :) = [];
            ygaze_signal(validIndices, :) = [];
            behv_data(validIndices, :) = [];
            
            % Remove corresponding baseline trials if applicable
            if obj.baseline_mdl == 1
                zsc_base(validIndices, :) = [];
            end
        end
        
        function [residuals_subj, predicted_subj] = processBinsAndTimepoints(obj, preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base, subj_idx)
            % Process data through bins and timepoints to fit regression models
            % Handles binned analysis and fits models at each timepoint
            %
            % Parameters:
            %   preds - Behavioral predictors table
            %   zsc_pupil - Pupil diameter data
            %   xgaze_signal - Horizontal gaze data
            %   ygaze_signal - Vertical gaze data
            %   behv_data - Behavioral data
            %   zsc_base - Baseline data
            %   subj_idx - Current subject index
            %
            % Returns:
            %   residuals_subj - Model residuals for this subject
            %   predicted_subj - Model predictions for this subject
            
            residuals_subj = [];
            predicted_subj = [];
            
            % Loop through bins (or single bin if not binned analysis)
            for r = obj.bins_array
                fprintf('Fitting model...\n');
                
                % Get data for current bin
                [pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, behv_data_bins, preds_bins] = ...
                    obj.getBinnedData(r, preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data);
                
                % Fit model at each timepoint
                for c = 1:obj.col
                    [betas, residuals, predicted] = obj.fitModelAtTimepoint(c, pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, behv_data_bins, preds_bins, zsc_base, r, subj_idx);
                    
                    % Store residuals and predictions if requested
                    if obj.residuals_predicted == 1
                        if ~isempty(residuals)
                            residuals_subj = [residuals_subj, residuals];
                            predicted_subj = [predicted_subj, predicted];
                        end
                    end
                end
            end
        end
        
        function [pupil_bins, xgaze_bins, ygaze_bins, behv_bins, preds_bins] = getBinnedData(obj, r, preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data)
            % Extract data for a specific bin or condition
            % Supports binning by continuous variables or accuracy-based splitting
            %
            % Parameters:
            %   r - Current bin index
            %   preds - Behavioral predictors
            %   zsc_pupil - Pupil data
            %   xgaze_signal - Horizontal gaze data
            %   ygaze_signal - Vertical gaze data
            %   behv_data - Behavioral data
            %
            % Returns:
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
            else
                % Use all trials (no binning)
                idx = true(height(preds), 1);
            end
            
            % Extract data for current bin
            pupil_bins = zsc_pupil(idx, :);
            xgaze_bins = xgaze_signal(idx, :);
            ygaze_bins = ygaze_signal(idx, :);
            behv_bins = behv_data(idx, :);
            preds_bins = preds(idx, :);
        end
        
        function [betas, residuals, predicted] = fitModelAtTimepoint(obj, c, pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, behv_data_bins, preds_bins, zsc_base, r, subj_idx)
            % Fit regression model at a specific timepoint
            % Creates predictor matrix and fits linear model to pupil data
            %
            % Parameters:
            %   c - Current timepoint index
            %   pupil_signal_bins - Pupil data for current bin
            %   xgaze_signal_bins - Horizontal gaze data for current bin
            %   ygaze_signal_bins - Vertical gaze data for current bin
            %   behv_data_bins - Behavioral data for current bin
            %   preds_bins - Predictors for current bin
            %   zsc_base - Baseline data
            %   r - Current bin index
            %   subj_idx - Current subject index
            %
            % Returns:
            %   betas - Regression coefficients
            %   residuals - Model residuals
            %   predicted - Model-predicted values
            
            % Initialize output variables
            betas = [];
            residuals = [];
            predicted = [];
            
            % Extract dependent variable (pupil diameter at timepoint c)
            y = pupil_signal_bins(:, c);
            
            % Z-score gaze signals
            zsc_xgaze = nanzscore(xgaze_signal_bins(:, c));
            zsc_ygaze = nanzscore(ygaze_signal_bins(:, c));
            
            % Remove trials with NaN values
            validIdx = ~isnan(y) & ~isnan(preds_bins.up);
            if sum(validIdx) <= obj.num_vars + 1
                return; % Skip if insufficient valid trials
            end
            
            % Extract valid data
            yValid = y(validIdx);
            xgazeValid = zsc_xgaze(validIdx);
            ygazeValid = zsc_ygaze(validIdx);
            preds_valid = preds_bins(validIdx, :);
            
            % Create regression table with all predictors
            tbl = table(yValid, xgazeValid, ygazeValid, ...
                nanzscore(preds_valid.con_diff), nanzscore(preds_valid.pe), ...
                nanzscore(abs(preds_valid.pe)), nanzscore(abs(preds_valid.up)), ...
                nanzscore(log(preds_valid.rt)), preds_valid.condition, preds_valid.ecoperf, preds_valid.correct, nanzscore(preds_valid.pe_condiff), ...
                'VariableNames', {'pupil', 'xgaze', 'ygaze', ...
                'zsc_condiff', 'signed_pe', 'pe', 'zsc_up', 'rt', 'condition', 'ecoperf', 'reward', 'pe_condiff'});
            
            % Add baseline predictor if requested
            if obj.baseline_mdl == 1
                tbl.baseline = zsc_base(validIdx);
            end
            
            % Fit linear regression model
            [betas, ~, residuals, ~, lm] = linear_fit(tbl, obj.model_def, ...
                obj.pred_vars, obj.resp_var, obj.cat_vars, obj.num_vars, 0, 0, 0, 0);
            
            % Generate model predictions
            predicted = predict(lm, tbl);
            
            % Store beta coefficients in results structure
            if obj.binned_accuracy == 1
                obj.betas_struct.with_intercept(r+1, :, subj_idx, c) = betas;
            else
                obj.betas_struct.with_intercept(r, :, subj_idx, c) = betas;
            end
        end
        
        function runPermutationTest(obj)
            % Run permutation test for statistical significance testing
            % Tests significance of regression coefficients across subjects and timepoints
            
            num_vars = 1:obj.num_vars+1;
            var1 = obj.betas_struct.with_intercept;
            var2 = obj.betas_struct.with_intercept;
            betas = 1;
            
            % Run permutation test using external function
            obj.perm_results = get_permtest(num_vars, obj.num_subs, obj.col, var1, var2, obj.two_tailed, betas);
        end
        
        function saveResults(obj)
            % Save all analysis results to disk
            % Creates output directory if needed and saves beta coefficients,
            % permutation results, residuals, and predictions
            
            % Create output directory if it doesn't exist
            if ~exist(obj.save_dir, 'dir')
                mkdir(obj.save_dir);
            end
            
            % Save all result files
            safe_saveall(fullfile(obj.save_dir, [obj.betas_save, '.mat']), obj.betas_struct);
            safe_saveall(fullfile(obj.save_dir, [obj.perm_save, '.mat']), obj.perm_results);
            safe_saveall(fullfile(obj.save_dir, [obj.predicted_save, '.mat']), obj.predicted_all);
            safe_saveall(fullfile(obj.save_dir, [obj.residuals_save, '.mat']), obj.residuals_all);
        end
    end
end