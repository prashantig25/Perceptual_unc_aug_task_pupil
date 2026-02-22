classdef PupilRegression_intHet < pupilReg_Vars
    % PupilRegression_intHet extends pupilReg_Vars to support both OLS and
    % heteroskedastic regression on pupil data. The heteroskedastic model
    % allows noise to scale with a predictor (condiff), fitted via fmincon
    % with multiple random starting points.
    
    properties
        % Results storage (inherited from original PupilRegression)
        betas_struct
        perm_results
        residuals_all
        predicted_all
        aic_values
        bic_values
        logL_values
        rsquaredOrdinary
        rsquaredAdjusted
        starting_points   % [n_subj x col x n_sp x num_params], pre-generated

        % Heteroskedastic model properties (new)
        model_type          % 'OLS' (default) or 'heteroskedastic'
        n_sp                % number of random starting points for fmincon
        minBound            % lower edge for uniform random start sampling
        maxBound            % upper edge for uniform random start sampling
        lb                  % hard lower bounds for fmincon
        ub                  % hard upper bounds for fmincon
        fmincon_options     % optimoptions object for fmincon
        negLL_values        % negative log-likelihood values (hetero only)
    end

    methods

        %% ----------------------------------------------------------------
        %  CONSTRUCTOR
        %% ----------------------------------------------------------------
        function obj = PupilRegression_intHet(config)
            obj = obj@pupilReg_Vars();

            if nargin > 0 && isa(config, 'PupilRegressionConfig')
                obj.copyFromConfig(config);
            end

            obj.betas_struct = struct();

            % Heteroskedastic defaults
            obj.model_type = 'OLS';
            obj.n_sp       = 20;
        end

        %% ----------------------------------------------------------------
        %  COPY CONFIG (unchanged from original)
        %% ----------------------------------------------------------------
        function copyFromConfig(obj, config)
            props = properties(config);
            for i = 1:length(props)
                if isprop(obj, props{i})
                    obj.(props{i}) = config.(props{i});
                end
            end
        end

        %% ----------------------------------------------------------------
        %  HETEROSKEDASTIC CONFIGURATION SETTER (new)
        %% ----------------------------------------------------------------
        function setHeteroskedasticConfig(obj, minBound, maxBound, lb, ub, n_sp)
            % Configure heteroskedastic model fitting
            %
            % Parameters:
            %   minBound - lower edge of uniform distribution for random starts
            %   maxBound - upper edge of uniform distribution for random starts
            %   lb       - hard lower bounds passed to fmincon
            %   ub       - hard upper bounds passed to fmincon
            %   n_sp     - number of random starting points per timepoint

            obj.model_type      = 'heteroskedastic';
            obj.minBound        = minBound;
            obj.maxBound        = maxBound;
            obj.lb              = lb;
            obj.ub              = ub;
            obj.n_sp            = n_sp;
            obj.fmincon_options = optimoptions('fmincon', ...
                'Display',              'off', ...
                'Algorithm',            'interior-point', ...
                'MaxIterations',        500, ...
                'OptimalityTolerance',  1e-4, ...
                'StepTolerance',        1e-6);
        end

        %% ----------------------------------------------------------------
        %  RUN ANALYSIS (extended from original to support hetero init)
        %% ----------------------------------------------------------------
        function [betas_struct, perm, residuals_all, predicted_all] = runAnalysis(obj)

            obj.validateConfig();

            % Pre-allocate betas_struct
            if obj.binned == 1
                num_bins = length(obj.bins_array);
            elseif obj.binned_accuracy == 1
                num_bins = 2;
            else
                num_bins = 1;
            end

            if strcmp(obj.model_type, 'heteroskedastic')
                % For hetero, num_vars is the total number of fmincon params
                obj.betas_struct.with_intercept = nan(num_bins, obj.num_vars+1, obj.num_subs, obj.col);
                obj.negLL_values = nan(num_bins, obj.num_subs, obj.col);
                obj.aic_values   = nan(num_bins, obj.num_subs, obj.col);
                obj.bic_values   = nan(num_bins, obj.num_subs, obj.col);
            else
                obj.betas_struct.with_intercept = nan(num_bins, obj.num_vars+1, obj.num_subs, obj.col);
            end

            obj.residuals_all = cell(obj.num_subs, 1);
            obj.predicted_all = cell(obj.num_subs, 1);

            for i = 1:obj.num_subs
                [residuals_subj, predicted_subj] = obj.processSubject(i, obj.binned);
                obj.residuals_all{i, 1} = residuals_subj;
                obj.predicted_all{i, 1} = predicted_subj;
            end

            % Permutation test only meaningful for OLS betas
            if strcmp(obj.model_type, 'OLS')
                obj.runPermutationTest();
            end

            betas_struct  = obj.betas_struct;
            perm          = obj.perm_results;
            residuals_all = obj.residuals_all;
            predicted_all = obj.predicted_all;
        end

        %% ----------------------------------------------------------------
        %  PROCESS SUBJECT (unchanged from original)
        %% ----------------------------------------------------------------
        function [residuals_subj, predicted_subj] = processSubject(obj, subj_idx, binnedAnalysis)

            fprintf('Reading in %s ...\n', obj.subj_ids{subj_idx});

            behv_data = obj.loadBehavioralData(subj_idx);
            [behv_data, missedtrials, missedtrials_slider] = obj.handleMissedTrials(behv_data);
            [zsc_pupil, xgaze_signal, ygaze_signal] = obj.loadPupilGazeData(subj_idx, missedtrials, missedtrials_slider);

            if obj.regress_rt == 1
                zsc_pupil = obj.regressRTEffects(zsc_pupil, behv_data);
            end

            zsc_base = obj.loadBaselineData(subj_idx);

            [preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base] = ...
                obj.getBehavioralPredictors(subj_idx, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base, missedtrials_slider);

            if obj.binned == 1
                preds.bin_columns = discretize(preds.con_diff, obj.bins);
            end

            [residuals_subj, predicted_subj] = obj.processBinsAndTimepoints(preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base, subj_idx, binnedAnalysis);
        end

        %% ----------------------------------------------------------------
        %  LOAD BEHAVIORAL DATA (unchanged from original)
        %% ----------------------------------------------------------------
        function behv_data = loadBehavioralData(obj, subj_idx)

            behv_data = [];

            for j = 1:obj.num_sess(subj_idx)
                filename = fullfile(obj.behv_dir, [obj.subj_ids{subj_idx}, '_main', num2str(j), '.xlsx']);
                if strcmp(obj.subj_ids{subj_idx}, '4672')
                    filename = fullfile(obj.behv_dir, [obj.subj_ids{subj_idx}, '_main', num2str(j), '_red.xlsx']);
                end
                data_run = readtable(filename);
                rt       = table(data_run.choice_rt, 'VariableNames', {'rt'});
                slider   = table(data_run.slider_respond_response, 'VariableNames', {'slider'});
                data_run = [data_run(:, 1:16), rt, slider];
                behv_data = [behv_data; data_run];
            end
        end

        %% ----------------------------------------------------------------
        %  HANDLE MISSED TRIALS (unchanged from original)
        %% ----------------------------------------------------------------
        function [behv_data, missedtrials, missedtrials_slider] = handleMissedTrials(obj, behv_data)

            missedtrials_rt      = isnan(behv_data.rt);
            behvdata_missedRT    = behv_data(missedtrials_rt == 0, :);
            missedtrials_slider  = isnan(behvdata_missedRT.slider);
            missedtrials         = isnan(behv_data.rt) | isnan(behv_data.slider);
            behv_data(missedtrials == 1, :) = [];
        end

        %% ----------------------------------------------------------------
        %  LOAD PUPIL GAZE DATA (unchanged from original)
        %% ----------------------------------------------------------------
        function [zsc_pupil, xgaze_signal, ygaze_signal] = loadPupilGazeData(obj, subj_idx, missedtrials, missedtrials_slider)

            fprintf('Pupil signal...\n');

            filename   = fullfile(obj.pupil_dir, [obj.subj_ids{subj_idx}, '.mat']);
            pupil      = importdata(filename);
            size_pupil = size(pupil);

            filename     = fullfile(obj.xgaze_dir, [obj.subj_ids{subj_idx}, '.mat']);
            xgaze_event  = importdata(filename);

            filename     = fullfile(obj.ygaze_dir, [obj.subj_ids{subj_idx}, '.mat']);
            ygaze_event  = importdata(filename);

            if strcmp(obj.timewindow, 'patch')
                zsc_pupil     = pupil;
                xgaze_signal  = xgaze_event;
                ygaze_signal  = ygaze_event;
                obj.col       = size_pupil(2);
            elseif strcmp(obj.timewindow, 'feedback')
                zsc_pupil     = pupil(:, 1:obj.col);
                xgaze_signal  = xgaze_event(:, 1:obj.col);
                ygaze_signal  = ygaze_event(:, 1:obj.col);
            end

            zsc_pupil(missedtrials_slider == 1, :)    = [];
            xgaze_signal(missedtrials_slider == 1, :) = [];
            ygaze_signal(missedtrials_slider == 1, :) = [];
        end

        %% ----------------------------------------------------------------
        %  REGRESS RT EFFECTS (unchanged from original)
        %% ----------------------------------------------------------------
        function zsc_pupil = regressRTEffects(obj, zsc_pupil, behv_data)
            for c = 1:obj.col
                zsc_pupil(:, c) = remove_rt_effects(zsc_pupil(:, c), log(behv_data.rt));
            end
        end

        %% ----------------------------------------------------------------
        %  LOAD BASELINE DATA (unchanged from original)
        %% ----------------------------------------------------------------
        function zsc_base = loadBaselineData(obj, subj_idx)
            zsc_base = [];
            if obj.baseline_mdl == 1
                fprintf('Getting baseline pupil measures...\n');
                filename = fullfile(obj.base_dir, [obj.subj_ids{subj_idx}, '.mat']);
                zsc_base = importdata(filename);
            end
        end

        %% ----------------------------------------------------------------
        %  GET BEHAVIORAL PREDICTORS (unchanged from original)
        %% ----------------------------------------------------------------
        function [preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base] = getBehavioralPredictors(obj, subj_idx, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base, missedtrials_slider)

            fprintf('Get predictors from behavioural data...\n');

            preds       = obj.preds_all(obj.preds_all.id == str2double(obj.subj_ids{subj_idx}), :);
            validIndices = find(preds.pe == 0);

            preds(validIndices, :)         = [];
            zsc_pupil(validIndices, :)     = [];
            xgaze_signal(validIndices, :)  = [];
            ygaze_signal(validIndices, :)  = [];
            behv_data(validIndices, :)     = [];

            if obj.baseline_mdl == 1
                zsc_base(validIndices, :) = [];
            end

            vars_to_check = {preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data};
            if obj.baseline_mdl == 1
                vars_to_check{end+1} = zsc_base;
            end

            ref_rows = size(vars_to_check{1}, 1);
            for i = 2:numel(vars_to_check)
                assert(size(vars_to_check{i}, 1) == ref_rows, ...
                    ['Dimension mismatch: Variable at index ', num2str(i), ' has different row count!']);
            end

            fprintf('Success: All %d variables have %d rows.\n', numel(vars_to_check), ref_rows);
        end

        %% ----------------------------------------------------------------
        %  PROCESS BINS AND TIMEPOINTS (extended to branch OLS vs hetero)
        %% ----------------------------------------------------------------
        function [residuals_subj, predicted_subj] = processBinsAndTimepoints(obj, preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base, subj_idx, binnedAnalysis)

            residuals_subj = [];
            predicted_subj = [];

            for r = obj.bins_array

                fprintf('Fitting model (bin %d)...\n', r);

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
                    %% --- HETEROSKEDASTIC PATH ---
                    [negLL_row, betas_row, aic_row, bic_row] = obj.fitHeteroAllTimepoints( ...
                        pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins,subj_idx);

                    % Resolve bin storage index (binned_accuracy uses r=0/1)
                    if obj.binned_accuracy == 1
                        storage_r = r + 1;
                    else
                        storage_r = r;
                    end

                    obj.negLL_values(storage_r, subj_idx, :)             = negLL_row;
                    obj.aic_values(storage_r, subj_idx, :)               = aic_row;
                    obj.bic_values(storage_r, subj_idx, :)               = bic_row;
                    % betas_row is [col x num_params]; store as [1 x num_params x 1 x col]
                    for c = 1:obj.col
                        obj.betas_struct.with_intercept(storage_r, :, subj_idx, c) = betas_row(c, :);
                    end

                else
                    %% --- OLS PATH (original behaviour, unchanged) ---
                    for c = 1:obj.col
                        [betas, residuals, predicted] = obj.fitModelAtTimepoint(c, ...
                            pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, ...
                            preds_bins, zsc_base, r, subj_idx);

                        if obj.residuals_predicted == 1 && ~isempty(residuals)
                            residuals_subj = [residuals_subj, residuals];
                            predicted_subj = [predicted_subj, predicted];
                        end
                    end
                end
            end
        end

        %% ----------------------------------------------------------------
        %  GET BINNED DATA (unchanged from original)
        %% ----------------------------------------------------------------
        function [pupil_bins, xgaze_bins, ygaze_bins, preds_bins] = getBinnedData(obj, r, preds, zsc_pupil, xgaze_signal, ygaze_signal)

            if obj.binned == 1
                idx = preds.bin_columns == r;
            elseif obj.binned_accuracy == 1
                idx = preds.correct == r;
            else
                idx = true(height(preds), 1);
            end

            pupil_bins  = zsc_pupil(idx, :);
            xgaze_bins  = xgaze_signal(idx, :);
            ygaze_bins  = ygaze_signal(idx, :);
            preds_bins  = preds(idx, :);
        end

        %% ----------------------------------------------------------------
        %  FIT OLS MODEL AT TIMEPOINT (unchanged from original)
        %% ----------------------------------------------------------------
        function [betas, residuals, predicted] = fitModelAtTimepoint(obj, c, pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins, zsc_base, r, subj_idx)

            betas     = [];
            residuals = [];
            predicted = [];
            aic       = nan;
            bic       = nan;

            y          = pupil_signal_bins(:, c);
            zsc_xgaze  = nanzscore(xgaze_signal_bins(:, c));
            zsc_ygaze  = nanzscore(ygaze_signal_bins(:, c));

            validIdx   = ~isnan(y) & ~isnan(preds_bins.up);

            yValid      = y(validIdx);
            xgazeValid  = zsc_xgaze(validIdx);
            ygazeValid  = zsc_ygaze(validIdx);
            preds_valid = preds_bins(validIdx, :);

            tbl = table(yValid, xgazeValid, ygazeValid, ...
                nanzscore(preds_valid.con_diff), nanzscore(preds_valid.pe), ...
                nanzscore(abs(preds_valid.pe)), nanzscore(abs(preds_valid.up)), ...
                nanzscore(log(preds_valid.rt)), preds_valid.condition, preds_valid.ecoperf, preds_valid.correct, nanzscore(preds_valid.pe_condiff), ...
                'VariableNames', {'pupil', 'xgaze', 'ygaze', ...
                'zsc_condiff', 'signed_pe', 'pe', 'zsc_up', 'rt', 'condition', 'ecoperf', 'reward', 'pe_condiff'});

            if obj.baseline_mdl == 1
                tbl.baseline = zsc_base(validIdx);
            end

            [betas, ~, residuals, ~, lm] = linear_fit(tbl, obj.model_def, ...
                obj.pred_vars, obj.resp_var, obj.cat_vars, obj.num_vars, 0, 0, 0, 0);

            if ~isempty(lm)
                if isa(lm, 'LinearModel')
                    negLL = -lm.LogLikelihood;
                    N     = lm.NumObservations;
                    k     = lm.NumCoefficients + 1;
                    aic   = 2*k + 2*negLL;
                    bic   = k*log(N) + 2*negLL;

                    residuals = lm.Residuals.Raw;
                    sigma2    = var(residuals);
                    n         = lm.NumObservations;
                    logL      = -0.5*n*(log(2*pi*sigma2) + 1);
                else
                    warning('lm is not a LinearModel. Cannot calculate AIC/BIC.');
                end

                if obj.binned_accuracy == 1
                    storage_r_idx = r + 1;
                else
                    storage_r_idx = r;
                end

                obj.aic_values(storage_r_idx, subj_idx, c) = aic;
                obj.bic_values(storage_r_idx, subj_idx, c) = bic;
                obj.logL_values(storage_r_idx, subj_idx, c) = logL;
            end

            predicted = predict(lm, tbl);

            if obj.binned_accuracy == 1
                obj.betas_struct.with_intercept(r+1, :, subj_idx, c) = betas;
            else
                obj.betas_struct.with_intercept(r, :, subj_idx, c) = betas;
            end

            obj.rsquaredAdjusted(r, :, subj_idx, c) = lm.Rsquared.Adjusted;
            obj.rsquaredOrdinary(r, :, subj_idx, c)  = lm.Rsquared.Ordinary;
        end

        %% ----------------------------------------------------------------
        %  FIT HETERO MODEL ACROSS ALL TIMEPOINTS (new)
        %% ----------------------------------------------------------------
        function [negLL_row, betas_row, aic_row, bic_row] = fitHeteroAllTimepoints(obj, zsc_pupil, xgaze_signal, ygaze_signal, preds_bins, subj_idx)
            % Fits the heteroskedastic model at every timepoint via fmincon
            % with multiple random starting points. Designed to be parfor-safe:
            % all obj fields are extracted into plain local variables first.
            %
            % Returns:
            %   negLL_row  - [1 x col] best negative log-likelihoods
            %   betas_row  - [col x num_params] parameter estimates
            %   aic_row    - [1 x col] AIC values
            %   bic_row    - [1 x col] BIC values

            % Extract all obj fields into plain variables (required for parfor)
            col        = obj.col;
            n_sp       = obj.n_sp;
            minBound   = obj.minBound;
            maxBound   = obj.maxBound;
            lb         = obj.lb;
            ub         = obj.ub;
            foptions   = obj.fmincon_options;
            num_params = obj.num_vars + 1;

            % Pre-compute z-scored predictors (once, outside timepoint loop)
            x1_z = nanzscore(abs(preds_bins.pe));
            x2_z = nanzscore(preds_bins.con_diff);
            rt_z = nanzscore(log(preds_bins.rt));
            up_z = nanzscore(abs(preds_bins.up));

            xgaze_z = nan(size(xgaze_signal));
            ygaze_z = nan(size(ygaze_signal));
            for c = 1:col
                xgaze_z(:, c) = nanzscore(xgaze_signal(:, c));
                ygaze_z(:, c) = nanzscore(ygaze_signal(:, c));
            end

            % Remove rows with any NaN across predictors or outcome
            valid_rows = ~any(isnan([x1_z, x2_z, rt_z, up_z, zsc_pupil, xgaze_z, ygaze_z]), 2);
            fprintf('  Hetero model: removing %d NaN trials, keeping %d\n', sum(~valid_rows), sum(valid_rows));

            x1_z      = x1_z(valid_rows);
            x2_z      = x2_z(valid_rows);
            rt_z      = rt_z(valid_rows);
            up_z      = up_z(valid_rows);
            zsc_pupil = zsc_pupil(valid_rows, :);
            xgaze_z   = xgaze_z(valid_rows, :);
            ygaze_z   = ygaze_z(valid_rows, :);
            N_trials  = sum(valid_rows);

            % Pre-allocate outputs
            negLL_row = nan(1, col);
            betas_row = nan(col, num_params);
            aic_row   = nan(1, col);
            bic_row   = nan(1, col);

            starts_subj = squeeze(obj.starting_points(subj_idx, :, :, :));
             
            parfor c = 1:col

                y      = zsc_pupil(:, c);
                xgaze  = xgaze_z(:, c);
                ygaze  = ygaze_z(:, c);

                negLLfun = @(params) PupilRegression_intHet.negativeLogLikelihood( ...
                    params, x1_z, x2_z, y, rt_z, up_z, xgaze, ygaze); %#ok<PFBNS>

                bestNegLL  = inf;
                bestParams = nan(1, num_params);

                for i = 1:n_sp
                    p0 = squeeze(starts_subj(c, i, :))';
                    [p_est, nLL_val] = fmincon(negLLfun, p0, [], [], [], [], lb, ub, [], foptions);
                    if nLL_val < bestNegLL
                        bestNegLL  = nLL_val;
                        bestParams = p_est;
                    end
                end

                k              = num_params;
                negLL_row(c)   = bestNegLL;
                betas_row(c,:) = bestParams;
                aic_row(c)     = 2*k + 2*bestNegLL;
                bic_row(c)     = k*log(N_trials) + 2*bestNegLL;
            end

            % save(fullfile(desiredPath, 'negLL_debug_obj.mat'), 'reg_het');
            fprintf('Object - negLL(1:5): %s\n', num2str(squeeze(negLL_row(1:5)), '%.6f '));
        end

        %% ----------------------------------------------------------------
        %  PERMUTATION TEST (unchanged from original)
        %% ----------------------------------------------------------------
        function runPermutationTest(obj)
            num_vars = 1:obj.num_vars+1;
            var1     = obj.betas_struct.with_intercept;
            var2     = obj.betas_struct.with_intercept;
            betas    = 1;
            obj.perm_results = get_permtest(num_vars, obj.num_subs, obj.col, var1, var2, obj.two_tailed, betas);
        end

        %% ----------------------------------------------------------------
        %  SAVE RESULTS (extended to save hetero-specific outputs)
        %% ----------------------------------------------------------------
        function saveResults(obj)

            if ~exist(obj.save_dir, 'dir')
                mkdir(obj.save_dir);
            end

            % Core results (always saved)
            safe_saveall(fullfile(obj.save_dir, [obj.betas_save,     '.mat']), obj.betas_struct);
            safe_saveall(fullfile(obj.save_dir, [obj.predicted_save, '.mat']), obj.predicted_all);
            safe_saveall(fullfile(obj.save_dir, [obj.residuals_save, '.mat']), obj.residuals_all);

            % AIC / BIC / logL
            safe_saveall(fullfile(obj.save_dir, ['AIC_',          obj.betas_save, '.mat']), obj.aic_values);
            safe_saveall(fullfile(obj.save_dir, ['BIC_',          obj.betas_save, '.mat']), obj.bic_values);

            if strcmp(obj.model_type, 'OLS')
                % OLS-specific outputs
                safe_saveall(fullfile(obj.save_dir, [obj.perm_save,       '.mat']), obj.perm_results);
                safe_saveall(fullfile(obj.save_dir, ['logL_',        obj.betas_save, '.mat']), obj.logL_values);
                safe_saveall(fullfile(obj.save_dir, ['r2Ordinary_',  obj.betas_save, '.mat']), obj.rsquaredOrdinary);
                safe_saveall(fullfile(obj.save_dir, ['r2Adjusted_',  obj.betas_save, '.mat']), obj.rsquaredAdjusted);

            elseif strcmp(obj.model_type, 'heteroskedastic')
                % Hetero-specific outputs
                safe_saveall(fullfile(obj.save_dir, ['negLL_',       obj.betas_save, '.mat']), obj.negLL_values);
            end
        end

    end % methods

    %% --------------------------------------------------------------------
    %  STATIC METHODS
    %% --------------------------------------------------------------------
    methods (Static)

        function nLL = negativeLogLikelihood(params, x1, x2, y, x3, x4, x5, x6)
            % Heteroskedastic Gaussian negative log-likelihood.
            % Noise (sigma) scales linearly with abs(condiff):
            %   sigma = omikron_0 + omikron_1 * |x2|
            %
            % Parameters:
            %   params(1)  beta0    - intercept
            %   params(2)  beta1    - PE
            %   params(3)  beta2    - condiff
            %   params(4)  omik0    - baseline noise (must be > 0)
            %   params(5)  omik1    - PE-scaled noise (must be > 0)
            %   params(6)  beta21   - PE x condiff interaction
            %   params(7)  beta3    - RT
            %   params(8)  beta4    - UP
            %   params(9)  beta5    - xgaze
            %   params(10) beta6    - ygaze

            beta0  = params(1);
            beta1  = params(2);
            beta2  = params(3);
            omik0  = params(4);
            omik1  = params(5);
            beta21 = params(6);
            beta3  = params(7);
            beta4  = params(8);
            beta5  = params(9);
            beta6  = params(10);

            yhat  = beta0 + beta1*x1 + beta2*x2 + beta21*(x1.*x2) ...
                  + beta3*x3 + beta4*x4 + beta5*x5 + beta6*x6;
            sigma = max(omik0 + omik1.*abs(x2), 1e-6);
            logL  = -0.5*log(2*pi) - log(sigma) - 0.5*((y - yhat)./sigma).^2;
            nLL   = -sum(logL);
        end

    end % static methods

end