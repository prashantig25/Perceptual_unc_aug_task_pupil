classdef PupilRegression_intHet < pupilReg_Vars

    properties
        betas_struct
        perm_results
        residuals_all
        predicted_all
        % aic_values
        % bic_values
        % logL_values
        % rsquaredOrdinary
        % rsquaredAdjusted
        starting_points

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

        % ── Progress-bar bookkeeping ──────────────────────────────────────
        wb                % waitbar handle
        total_steps       % total increments expected
        completed_steps   % running counter (main thread only)
    end

    methods

        %% ----------------------------------------------------------------
        %  CONSTRUCTOR
        %% ----------------------------------------------------------------
        function obj = PupilRegression_intHet(config)
            obj = obj@pupilReg_Vars();

            % if nargin > 0 && isa(config, 'PupilRegressionConfig')
            %     obj.copyFromConfig(config);
            % end

            obj.betas_struct    = struct();
            obj.model_type      = 'OLS';
            obj.n_sp            = 20;
            obj.use_sp          = 0; 
            obj.wb              = [];
            obj.total_steps     = 0;
            obj.completed_steps = 0;
            obj.p0 = [0, 0, 0, 0.1, 0.1, 0, 0, 0, 0, 0];
        end

        %% ----------------------------------------------------------------
        %  COPY CONFIG
        %% ----------------------------------------------------------------
        % function copyFromConfig(obj, config)
        %     props = properties(config);
        %     for i = 1:length(props)
        %         if isprop(obj, props{i})
        %             obj.(props{i}) = config.(props{i});
        %         end
        %     end
        % end

        %% ----------------------------------------------------------------
        %  HETEROSKEDASTIC CONFIGURATION SETTER
        %% ----------------------------------------------------------------
        function setHeteroskedasticConfig(obj, minBound, maxBound, lb, ub, n_sp)
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

        %% ----------------------------------------------------------------
        %  PROGRESS BAR HELPERS
        %% ----------------------------------------------------------------
        function initProgress(obj, total, titleStr)
            % INITPROGRESS Open a new waitbar. Call once at the start of runAnalysis.
            %
            %   initProgress(OBJ, TOTAL, TITLESTR) initialises the progress tracking
            %   by setting the total number of expected steps to TOTAL, resetting the
            %   completed step counter to zero, and opening a waitbar dialog with the
            %   title TITLESTR and a Cancel button.
            %
            %   Inputs:
            %     total    - (numeric) Total number of steps expected in the analysis.
            %     titleStr - (char) Message string displayed inside the waitbar dialog.
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
            %   updateProgress(OBJ, MSG) increments the completed step count by one,
            %   recomputes the fractional progress, and updates the waitbar label to
            %   MSG.  If the user has pressed Cancel, the waitbar is closed and an
            %   error is thrown.  Safe to call from the main thread only — do NOT
            %   call from inside a parfor loop.
            %
            %   Inputs:
            %     msg - (char) Status message displayed in the waitbar on this update.
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
            %   incrementProgress(OBJ, N) adds N to the completed step count and
            %   recomputes the fractional progress on the waitbar.  The existing
            %   waitbar message is left unchanged.  Intended for absorbing batched
            %   step increments forwarded from a DataQueue (e.g. from worker threads
            %   inside a parfor loop).
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
            %
            %   closeProgress(OBJ) closes the waitbar window if it is still open and
            %   valid, then sets the internal handle OBJ.wb to [] so subsequent
            %   guard checks in updateProgress and incrementProgress exit cleanly.
            %   Call once after runAnalysis completes (or errors out).
            if ~isempty(obj.wb) && isvalid(obj.wb)
                delete(obj.wb);
            end
            obj.wb = [];
        end
        %% ----------------------------------------------------------------
        %  RUN ANALYSIS
        %% ----------------------------------------------------------------
        function runAnalysis(obj)

            obj.validateConfig();

            % ── Resolve bin count ──────────────────────────────────────
            if obj.binned == 1
                num_bins = length(obj.bins_array);
            elseif obj.binned_accuracy == 1
                num_bins = 2;
            else
                num_bins = 1;
            end

            % ── Pre-allocate outputs ───────────────────────────────────
            if strcmp(obj.model_type, 'heteroskedastic')
                obj.betas_struct.with_intercept = nan(num_bins, obj.num_vars+1, obj.num_subs, obj.col);
                obj.negLL_values = nan(num_bins, obj.num_subs, obj.col);
                % obj.aic_values   = nan(num_bins, obj.num_subs, obj.col);
                % obj.bic_values   = nan(num_bins, obj.num_subs, obj.col);
            else
                obj.betas_struct.with_intercept = nan(num_bins, obj.num_vars+1, obj.num_subs, obj.col);
            end

            obj.residuals_all = cell(obj.num_subs, 1);
            obj.predicted_all = cell(obj.num_subs, 1);

            % ── Open progress bar ──────────────────────────────────────
            % Total steps = subjects × bins × timepoints
            % Each timepoint inside fitModelAtTimepoint / fitHeteroAllTimepoints
            % counts as one tick, plus one tick per subject for data loading.
            totalTicks = obj.num_subs * (1 + num_bins * obj.col);
            obj.initProgress(totalTicks, 'Initialising…');

            % ── Subject loop ───────────────────────────────────────────
            for i = 1:obj.num_subs
                obj.processSubject(i, obj.binned);
            end

            % ── Permutation test (OLS only) ────────────────────────────
            if strcmp(obj.model_type, 'OLS')
                obj.updateProgress('Running permutation test…');
                % obj.runPermutationTest();

                if obj.binned == 0
                    num_vars = 1:obj.num_vars+1;
                    % var2     = obj.betas_struct.with_intercept;
                    % betas    = 1;
                    % obj.perm_results = get_permtest(num_vars, obj.num_subs, obj.col, var1, var2, obj.two_tailed, betas);

                    var1 = squeeze(obj.betas_struct.with_intercept(1, :, :, :)); % [num_vars x num_subjs x col]
                    obj.perm_results = get_permtest_updated(num_vars, obj.num_subs, obj.col, var1);
                elseif length(obj.bins) <= 3
                    num_vars = 1:obj.num_vars+1;
                    % betas    = 1;
                    % obj.perm_results = get_permtest(num_vars, obj.num_subs, obj.col, var1, var2, obj.two_tailed, betas);

                    var1 = squeeze(obj.betas_struct.with_intercept(1, :, :, :)); % [num_vars x num_subjs x col]
                    var2 = squeeze(obj.betas_struct.with_intercept(2, :, :, :)); % [num_vars x num_subjs x col]
                    obj.perm_results = get_permtest_updated(num_vars, obj.num_subs, obj.col, var1, var2);
                else
                    obj.perm_results = [];
                end
            elseif strcmp(obj.model_type, 'heteroskedastic')
                num_vars = 1:obj.num_vars+1;
                obj.updateProgress('Running permutation test…');
                var1 = squeeze(obj.betas_struct.with_intercept(1, :, :, :)); % [num_vars x num_subjs x col]
                obj.perm_results = get_permtest_updated(num_vars, obj.num_subs, obj.col, var1);
            end

            obj.closeProgress();

            % betas_struct = obj.betas_struct;
            % perm         = obj.perm_results;
        end

        %% ----------------------------------------------------------------
        %  PROCESS SUBJECT
        %% ----------------------------------------------------------------
        function processSubject(obj, subj_idx, binnedAnalysis)

            obj.updateProgress(sprintf('[%d/%d] Loading %s…', ...
                subj_idx, obj.num_subs, obj.subj_ids{subj_idx}));

            behv_data = obj.loadBehavioralData(subj_idx);
            [behv_data, missedtrials_slider] = obj.handleMissedTrials(behv_data);
            [zsc_pupil, xgaze_signal, ygaze_signal] = obj.loadPupilGazeData(subj_idx, missedtrials_slider);

            if obj.regress_rt == 1
                zsc_pupil = obj.regressRTEffects(zsc_pupil, behv_data);
            end

            zsc_base = obj.loadBaselineData(subj_idx);

            [preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base] = ...
                obj.getBehavioralPredictors(subj_idx, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base, missedtrials_slider);

            if obj.binned == 1
                preds.bin_columns = discretize(preds.con_diff, obj.bins);
            end

            obj.processBinsAndTimepoints(preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base, subj_idx, binnedAnalysis);

            % residuals_subj = [];
            % predicted_subj = [];
        end

        %% ----------------------------------------------------------------
        %  LOAD BEHAVIORAL DATA
        %% ----------------------------------------------------------------
        function behv_data = loadBehavioralData(obj, subj_idx)

            behv_data = [];
            for j = 1:obj.num_sess(subj_idx)
                filename = fullfile(obj.behv_dir, [obj.subj_ids{subj_idx}, '_main', num2str(j), '.xlsx']);
                if strcmp(obj.subj_ids{subj_idx}, '4672')
                    filename = fullfile(obj.behv_dir, [obj.subj_ids{subj_idx}, '_main', num2str(j), '_red.xlsx']);
                end
                data_run = readtable(filename, 'VariableNamingRule', 'preserve');
                rt        = table(data_run.("choice.rt"),                   'VariableNames', {'rt'});
                slider    = table(data_run.("slider_respond.response"),     'VariableNames', {'slider'});
                data_run  = [data_run(:, 1:16), rt, slider];
                behv_data = [behv_data; data_run];
            end
        end

        %% ----------------------------------------------------------------
        %  HANDLE MISSED TRIALS
        %% ----------------------------------------------------------------
        function [behv_data, missedtrials_slider] = handleMissedTrials(obj, behv_data)
            missedtrials_rt     = isnan(behv_data.rt);
            behvdata_missedRT   = behv_data(missedtrials_rt == 0, :);
            missedtrials_slider = isnan(behvdata_missedRT.slider);
            missedtrials        = isnan(behv_data.rt) | isnan(behv_data.slider);
            behv_data(missedtrials == 1, :) = [];
        end

        %% ----------------------------------------------------------------
        %  LOAD PUPIL / GAZE DATA
        %% ----------------------------------------------------------------
        function [zsc_pupil, xgaze_signal, ygaze_signal] = loadPupilGazeData(obj, subj_idx, missedtrials_slider)

            filename   = fullfile(obj.pupil_dir, [obj.subj_ids{subj_idx}, '.mat']);
            pupil      = importdata(filename);
            size_pupil = size(pupil);

            filename    = fullfile(obj.xgaze_dir, [obj.subj_ids{subj_idx}, '.mat']);
            xgaze_event = importdata(filename);

            filename    = fullfile(obj.ygaze_dir, [obj.subj_ids{subj_idx}, '.mat']);
            ygaze_event = importdata(filename);

            if strcmp(obj.timewindow, 'patch')
                zsc_pupil    = pupil;
                xgaze_signal = xgaze_event;
                ygaze_signal = ygaze_event;
                obj.col      = size_pupil(2);
            elseif strcmp(obj.timewindow, 'feedback')
                zsc_pupil    = pupil(:, 1:obj.col);
                xgaze_signal = xgaze_event(:, 1:obj.col);
                ygaze_signal = ygaze_event(:, 1:obj.col);
            end

            zsc_pupil(missedtrials_slider == 1, :)    = [];
            xgaze_signal(missedtrials_slider == 1, :) = [];
            ygaze_signal(missedtrials_slider == 1, :) = [];
        end

        %% ----------------------------------------------------------------
        %  REGRESS RT EFFECTS
        %% ----------------------------------------------------------------
        function residual = remove_rt_effects(obj, pupil,rt)

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

        %% ----------------------------------------------------------------
        %  REGRESS RT EFFECTS
        %% ----------------------------------------------------------------
        function zsc_pupil = regressRTEffects(obj, zsc_pupil, behv_data)
            for c = 1:obj.col
                zsc_pupil(:, c) = obj.remove_rt_effects(zsc_pupil(:, c), log(behv_data.rt));
            end
        end

        %% ----------------------------------------------------------------
        %  LOAD BASELINE DATA
        %% ----------------------------------------------------------------
        function zsc_base = loadBaselineData(obj, subj_idx)
            zsc_base = [];
            if obj.baseline_mdl == 1
                filename = fullfile(obj.base_dir, [obj.subj_ids{subj_idx}, '.mat']);
                zsc_base = importdata(filename);
            end
        end

        %% ----------------------------------------------------------------
        %  GET BEHAVIORAL PREDICTORS
        %% ----------------------------------------------------------------
        function [preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base] = ...
                getBehavioralPredictors(obj, subj_idx, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base, missedtrials_slider)

            preds        = obj.preds_all(obj.preds_all.id == str2double(obj.subj_ids{subj_idx}), :);
            validIndices = find(preds.pe == 0);

            preds(validIndices, :)        = [];
            zsc_pupil(validIndices, :)    = [];
            xgaze_signal(validIndices, :) = [];
            ygaze_signal(validIndices, :) = [];
            behv_data(validIndices, :)    = [];

            if obj.baseline_mdl == 1
                zsc_base(validIndices, :) = [];
            end
        end

        %% ----------------------------------------------------------------
        %  PROCESS BINS AND TIMEPOINTS
        %% ----------------------------------------------------------------
        function processBinsAndTimepoints(obj, preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base, subj_idx, binnedAnalysis)

            numBins  = length(obj.bins_array);

            for r = obj.bins_array

                binLabel = sprintf('[%d/%d] Subj %s – bin %d/%d', ...
                    subj_idx, obj.num_subs, obj.subj_ids{subj_idx}, r, numBins);

                % ── Get binned data ────────────────────────────────────
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
                    %% ── HETEROSKEDASTIC PATH ──────────────────────────
                    obj.updateProgress(sprintf('%s | Het model…', binLabel));
                    obj.fitHeteroAllTimepoints( ...
                        pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins, subj_idx);

                else
                    %% ── OLS PATH ──────────────────────────────────────
                    for c = 1:obj.col
                        obj.updateProgress(sprintf('%s | t %d/%d', binLabel, c, obj.col));
                        obj.fitModelAtTimepoint(c, ...
                            pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins, zsc_base, r, subj_idx);
                    end
                end
            end
        end

        %% ----------------------------------------------------------------
        %  GET BINNED DATA
        %% ----------------------------------------------------------------
        function [pupil_bins, xgaze_bins, ygaze_bins, preds_bins] = getBinnedData(obj, r, preds, zsc_pupil, xgaze_signal, ygaze_signal)

            if obj.binned == 1
                idx = preds.bin_columns == r;
            elseif obj.binned_accuracy == 1
                idx = preds.correct == r;
            % else
            %     idx = true(height(preds), 1);
            end

            pupil_bins  = zsc_pupil(idx, :);
            xgaze_bins  = xgaze_signal(idx, :);
            ygaze_bins  = ygaze_signal(idx, :);
            preds_bins  = preds(idx, :);
        end

        %% ----------------------------------------------------------------
        %  FIT OLS MODEL AT TIMEPOINT
        %% ----------------------------------------------------------------
        function fitModelAtTimepoint(obj, c, pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins, zsc_base, r, subj_idx)

            y         = pupil_signal_bins(:, c);
            zsc_xgaze = zscore(xgaze_signal_bins(:, c));
            zsc_ygaze = zscore(ygaze_signal_bins(:, c));

            validIdx    = ~isnan(y) & ~isnan(preds_bins.up);
            yValid      = y(validIdx);
            xgazeValid  = zsc_xgaze(validIdx);
            ygazeValid  = zsc_ygaze(validIdx);
            preds_valid = preds_bins(validIdx, :);

            tbl = table(yValid, xgazeValid, ygazeValid, ...
                zscore(preds_valid.con_diff), zscore(preds_valid.pe), ...
                zscore(abs(preds_valid.pe)), zscore(abs(preds_valid.up)), ...
                zscore(log(preds_valid.rt)), preds_valid.condition, preds_valid.ecoperf, ...
                preds_valid.correct, zscore(preds_valid.pe_condiff), ...
                'VariableNames', {'pupil','xgaze','ygaze','zsc_condiff','signed_pe', ...
                'pe','zsc_up','rt','condition','ecoperf','reward','pe_condiff'});

            if obj.baseline_mdl == 1
                tbl.baseline = zsc_base(validIdx);
            end

            [betas, ~, ~, ~, lm] = linear_fit(tbl, obj.model_def, ...
                obj.pred_vars, obj.resp_var, obj.cat_vars, obj.num_vars, 0);

            % Save coefficient names once
            if subj_idx == 1 && c == 1
                coeff_names = lm.CoefficientNames;
                % safe_saveall(fullfile(obj.save_dir, [obj.betas_save, '_coeffNames.mat']), coeff_names);
                obj.betas_struct.coeff_names = coeff_names;
            end
            if ~isempty(lm)
                %     if isa(lm, 'LinearModel')
                %         negLL     = -lm.LogLikelihood;
                %         N         = lm.NumObservations;
                %         k         = lm.NumCoefficients + 1;
                %         aic       = 2*k + 2*negLL;
                %         bic       = k*log(N) + 2*negLL;
                %         residuals = lm.Residuals.Raw;
                %         sigma2    = var(residuals);
                %         n         = lm.NumObservations;
                %         logL      = -0.5*n*(log(2*pi*sigma2) + 1);
                %     else
                %         warning('lm is not a LinearModel. Cannot calculate AIC/BIC.');
                %         logL = nan;
                %     end

                if obj.binned_accuracy == 1
                    storage_r_idx = r + 1;
                else
                    storage_r_idx = r;
                end

                % obj.aic_values(storage_r_idx,  subj_idx, c) = aic;
                % obj.bic_values(storage_r_idx,  subj_idx, c) = bic;
                % obj.logL_values(storage_r_idx, subj_idx, c) = logL;
            end

            if obj.binned_accuracy == 1
                obj.betas_struct.with_intercept(r+1, :, subj_idx, c) = betas;
            else
                obj.betas_struct.with_intercept(r,   :, subj_idx, c) = betas;
            end

            % obj.rsquaredAdjusted(r, :, subj_idx, c) = lm.Rsquared.Adjusted;
            % obj.rsquaredOrdinary(r,  :, subj_idx, c) = lm.Rsquared.Ordinary;
        end

        %% ----------------------------------------------------------------
        %  FIT HETERO MODEL ACROSS ALL TIMEPOINTS
        %% ----------------------------------------------------------------
        function fitHeteroAllTimepoints( ...
                obj, zsc_pupil, xgaze_signal, ygaze_signal, preds_bins, subj_idx)

            % Extract all obj fields into plain variables (parfor-safe)
            col        = obj.col;
            n_sp       = obj.n_sp;
            lb         = obj.lb;
            ub         = obj.ub;
            foptions   = obj.fmincon_options;
            num_params = obj.num_vars + 1;
            use_sp     = obj.use_sp;
            bestParams = obj.p0;

            % ── Pre-compute z-scored predictors ───────────────────────
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

            % ── Remove NaN rows ────────────────────────────────────────
            valid_rows = ~any(isnan([x1_z, x2_z, rt_z, up_z, zsc_pupil, xgaze_z, ygaze_z]), 2);
            x1_z      = x1_z(valid_rows);
            x2_z      = x2_z(valid_rows);
            rt_z      = rt_z(valid_rows);
            up_z      = up_z(valid_rows);
            zsc_pupil = zsc_pupil(valid_rows, :);
            xgaze_z   = xgaze_z(valid_rows, :);
            ygaze_z   = ygaze_z(valid_rows, :);
            N_trials  = sum(valid_rows);

            % ── DataQueue: each parfor worker sends 1 when it finishes ─
            % The afterEach callback runs on the main thread and increments
            % the waitbar by the received value.
            wb_handle = obj.wb;   % capture handle for the listener closure
            dq = parallel.pool.DataQueue;
            afterEach(dq, @(v) obj.incrementProgress(v));

            % Update bar label once before launching parfor
            obj.updateProgress(sprintf('Subj %d/%d | het timepoints (0/%d)…', ...
                subj_idx, obj.num_subs, col));
            % The updateProgress above consumed 1 tick; we need to compensate
            % so the per-timepoint ticks still land correctly.  We pre-spent
            % that tick in the caller (processBinsAndTimepoints already called
            % updateProgress before entering here), so no double-count occurs.

            % Pre-allocate outputs
            negLL_row = nan(1, col);
            betas_row = nan(col, num_params);
            % aic_row   = nan(1, col);
            % bic_row   = nan(1, col);

            starts_subj = squeeze(obj.starting_points(subj_idx, :, :, :));

            parfor c = 1:col
                y     = zsc_pupil(:, c);
                xgaze = xgaze_z(:, c);
                ygaze = ygaze_z(:, c);

                negLLfun = @(params) PupilRegression_intHet.negativeLogLikelihood( ...
                    params, x1_z, x2_z, y, rt_z, up_z, xgaze, ygaze); %#ok<PFBNS>

                bestNegLL  = inf;
                bestParams = obj.p0;

                if use_sp == 1
                    for i = 1:n_sp
                        p0 = squeeze(starts_subj(c, i, :))';
                        [p_est, nLL_val] = fmincon(negLLfun, p0, [], [], [], [], lb, ub, [], foptions);
                        if nLL_val < bestNegLL
                            bestNegLL  = nLL_val;
                            bestParams = p_est;
                        end
                    end
                else
                    [p_est, nLL_val] = fmincon(negLLfun, bestParams, [], [], [], [], lb, ub, [], foptions);
                    bestNegLL  = nLL_val;
                    bestParams = p_est;
                    p0 = bestParams;
                end

                k            = num_params;
                negLL_row(c) = bestNegLL;
                betas_row(c, :) = bestParams;
                % aic_row(c)   = 2*k + 2*bestNegLL;
                % bic_row(c)   = k*log(N_trials) + 2*bestNegLL;

                % Notify main thread: one timepoint done
                send(dq, 1); %#ok<PFBNS>
            end

            obj.negLL_values(1, subj_idx, :) = negLL_row;
            for c = 1:obj.col
                obj.betas_struct.with_intercept(1, :, subj_idx, c) = betas_row(c, :);
            end
        end

        %% ----------------------------------------------------------------
        %  PERMUTATION TEST
        %% ----------------------------------------------------------------
        % function runPermutationTest(obj)
        %     num_vars = 1:obj.num_vars+1;
        %     var1     = obj.betas_struct.with_intercept;
        %     var2     = obj.betas_struct.with_intercept;
        %     betas    = 1;
        %     obj.perm_results = get_permtest(num_vars, obj.num_subs, obj.col, var1, var2, obj.two_tailed, betas);
        % end

        %% ----------------------------------------------------------------
        %  SAVE RESULTS
        %% ----------------------------------------------------------------
        function saveResults(obj)
            if ~exist(obj.save_dir, 'dir')
                mkdir(obj.save_dir);
            end

            safe_saveall(fullfile(obj.save_dir, [obj.betas_save, '.mat']), obj.betas_struct);

            if strcmp(obj.model_type, 'OLS')
                safe_saveall(fullfile(obj.save_dir, [obj.perm_save, '.mat']), obj.perm_results);
            elseif strcmp(obj.model_type, 'heteroskedastic')
                safe_saveall(fullfile(obj.save_dir, ['negLL_', obj.betas_save, '.mat']), obj.negLL_values);
                safe_saveall(fullfile(obj.save_dir, ['perm_', obj.betas_save, '.mat']), obj.perm_results);
            end
        end

    end % methods

    %% --------------------------------------------------------------------
    %  STATIC METHODS
    %% --------------------------------------------------------------------
    methods (Static)

        function nLL = negativeLogLikelihood(params, x1, x2, y, x3, x4, x5, x6)
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

    end % static methods

end