%% Multi-subject regression with prediction-dependent noise - THREE PREPROCESSING METHODS
clear; clc;
rng(123)

%% ========================================================================
%  COMMON SETUP FOR ALL THREE METHODS
%  ========================================================================

% Subject and session information
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
n_subj = length(num_sess);

% Path setup
currentDir = cd;
reqPath = 'Perceptual_unc_aug_task_pupil-main';
pathParts = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

% Common directories
behv_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'raw data');
xgaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'x-gaze');
ygaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'y-gaze');
base_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'baseline before fb');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');

% Load behavioral predictors
preds_file = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'LR analyses', 'preprocessed_lr_pupil.xlsx');
preds_all = readtable(preds_file);
preds_all.pe_condiff = abs(preds_all.pe) .* preds_all.con_diff;

% Other variables
col = 300;

% Pre-allocate results
param_names = {'Intercept','PE','Condiff','omikron_0','omikron_1','PEXCondiff','RT','UP','xgaze','ygaze'};
num_params = numel(param_names);

% Initial guess for parameters
param_init = [0, 0, 0, 0.1, 0.1, 0, 0, 0, 0, 0];
lb = [-Inf, -Inf, -Inf, 0, 0, -Inf, -Inf, -Inf, -Inf, -Inf];
ub = [ Inf,  Inf,  Inf, Inf, Inf, Inf,  Inf,  Inf, Inf, Inf];

% Optimization options
options = optimoptions('fmincon', ...
    'Display', 'off', ...
    'Algorithm', 'interior-point', ...
    'MaxIterations', 500, ...
    'OptimalityTolerance', 1e-4, ...
    'StepTolerance', 1e-6);

% Random starting points configuration
n_sp = 20;

%% ========================================================================
%  METHOD 1: LINEAR INTERPOLATION
%  ========================================================================

fprintf('\n========================================\n');
fprintf('METHOD 1: LINEAR INTERPOLATION\n');
fprintf('========================================\n\n');

% Method-specific paths and bounds
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 linearInt');
minBound = importdata("minHetParams_linearIntabs.mat");
maxBound = importdata("maxHetParams_linearIntabs.mat");

% Pre-allocate results for this method
param_estimates = nan(n_subj, num_params, col);
negLL_values = nan(n_subj, col);
aic_values = nan(n_subj, col);
bic_values = nan(n_subj, col);

% Loop through subjects
for s = 1:n_subj
    tic;
    fprintf('Subject %s: Getting behavioral predictors ...\n', subj_ids{s});
    behv_data = [];

    % Loop through all sessions for this subject
    for j = 1:num_sess(s)
        % Construct filename (special case for subject 4672)
        filename = fullfile(behv_dir, [subj_ids{s}, '_main', num2str(j), '.xlsx']);
        if strcmp(subj_ids{s}, '4672')
            filename = fullfile(behv_dir, [subj_ids{s}, '_main', num2str(j), '_red.xlsx']);
        end
        % Load session data and extract relevant columns
        data_run = readtable(filename);
        rt = table(data_run.choice_rt, 'VariableNames', {'rt'});
        slider = table(data_run.slider_respond_response, 'VariableNames', {'slider'});
        data_run = [data_run(:, 1:16), rt, slider];
        % Concatenate with previous sessions
        behv_data = [behv_data; data_run];
    end

    % Extract subject-specific data
    preds = preds_all(preds_all.id == str2double(subj_ids{s}), :);
    x1 = abs(preds.pe);
    x2 = preds.con_diff;
    missedtrials_rt = isnan(behv_data.rt);
    behvdata_missedRT = behv_data(missedtrials_rt == 0, :);
    missedtrials_slider = isnan(behvdata_missedRT.slider);
    missedtrials = isnan(behv_data.rt) | isnan(behv_data.slider);

    % Remove all missed trials from behavioral data
    behv_data(missedtrials == 1, :) = [];
    validIndices = find(preds.pe == 0);
    preds(validIndices, :) = [];

    fprintf('Subject %s: Loading pupil signal...\n', subj_ids{s});
    filename = fullfile(pupil_dir, [subj_ids{s}, '.mat']);
    pupil = importdata(filename);
    filename = fullfile(xgaze_dir, [subj_ids{s}, '.mat']);
    xgaze_event = importdata(filename);
    filename = fullfile(ygaze_dir, [subj_ids{s}, '.mat']);
    ygaze_event = importdata(filename);

    % Use first 'col' timepoints for feedback-locked analysis
    zsc_pupil = pupil(:, 1:col);
    xgaze_signal = xgaze_event(:, 1:col);
    ygaze_signal = ygaze_event(:, 1:col);

    % Remove trials with missing behavioral responses
    zsc_pupil(missedtrials_slider == 1, :) = [];
    xgaze_signal(missedtrials_slider == 1, :) = [];
    ygaze_signal(missedtrials_slider == 1, :) = [];

    zsc_pupil(validIndices, :) = [];
    xgaze_signal(validIndices, :) = [];
    ygaze_signal(validIndices, :) = [];
    behv_data(validIndices, :) = [];

    % PRE-COMPUTE Z-SCORES
    fprintf('Subject %s: Pre-computing z-scores...\n', subj_ids{s});
    x1_z = nanzscore(abs(preds.pe));
    x2_z = nanzscore(preds.con_diff);
    % condiff_z = nanzscore(preds.con_diff);
    rt_z = nanzscore(log(preds.rt));
    up_z = nanzscore(abs(preds.up));

    % Z-score gaze signals for each timepoint
    xgaze_z = nan(size(xgaze_signal));
    pupil_z = nan(size(zsc_pupil));
    ygaze_z = nan(size(ygaze_signal));
    for c = 1:col
        xgaze_z(:,c) = nanzscore(xgaze_signal(:,c));
        ygaze_z(:,c) = nanzscore(ygaze_signal(:,c));
        pupil_z(:,c) = nanzscore(zsc_pupil(:,c));
    end
    fprintf('Subject %s: Estimating parameters for each timepoint...\n', subj_ids{s});

    % Remove rows with ANY NaN values in predictors or outcome
    valid_rows = ~any(isnan([x1_z, x2_z, rt_z, up_z, zsc_pupil, xgaze_z, ygaze_z]), 2);
    fprintf('Subject %s: Removing %d trials with NaN values (keeping %d trials)\n', ...
        subj_ids{s}, sum(~valid_rows), sum(valid_rows));

    x1_z = x1_z(valid_rows);
    x2_z = x2_z(valid_rows);
    rt_z = rt_z(valid_rows);
    up_z = up_z(valid_rows);
    zsc_pupil = zsc_pupil(valid_rows, :);
    xgaze_z = xgaze_z(valid_rows, :);
    ygaze_z = ygaze_z(valid_rows, :);

    % Calculate N for AIC/BIC
    N_trials = sum(valid_rows);

    % RANDOM STARTING POINTS LOOP
    parfor c = 1:col
        % Extract data for this timepoint
        y = zsc_pupil(:,c);
        xgaze = xgaze_z(:,c);
        ygaze = ygaze_z(:,c);

        % Define negative log-likelihood for this timepoint
        negLLfun = @(params) negative_log_likelihood(params, x1_z, x2_z, y, ...
            rt_z, up_z, xgaze, ygaze);

        % Initialize best solution tracking
        bestNegLL = inf;
        bestParams = NaN;

        % Loop through random starting points
        for i = 1:n_sp
            % Generate random starting point
            current_params = unifrnd(minBound, maxBound);

            % Estimate parameters from this starting point
            [params_est, negLL_val] = fmincon(negLLfun, current_params, [], [], [], [], lb, ub, [], options);

            % Store best results
            if negLL_val < bestNegLL
                bestParams = params_est;
                bestNegLL = negLL_val;
            end
        end

        % Calculate AIC and BIC for best solution
        k = num_params;
        current_aic = 2 * k + 2 * bestNegLL;
        current_bic = k * log(N_trials) + 2 * bestNegLL;

        % Store results
        param_estimates(s,:,c) = bestParams;
        negLL_values(s,c) = bestNegLL;
        aic_values(s,c) = current_aic;
        bic_values(s,c) = current_bic;
    end

    elapsed = toc;
    fprintf('Subject %s completed in %.2f seconds (%.2f sec/timepoint)\n\n', subj_ids{s}, elapsed, elapsed/col);
end

% Save results for Linear Interpolation
safe_saveall('bic_values_hetero_noZeroPE_linearInt_20SPAbs3Width.mat', bic_values)
safe_saveall('param_estimates_hetero_noZeroPE_linearInt_20SPAbs3Width.mat', param_estimates)
safe_saveall('negLL_hetero_noZeroPE_linearInt_20SPAbs3Width.mat', negLL_values)

fprintf('==== LINEAR INTERPOLATION COMPLETED ====\n');
fprintf('Parameters estimated for %d subjects across %d timepoints\n\n', n_subj, col);

%% ========================================================================
%  METHOD 2: CUBIC SPLINE
%  ========================================================================

fprintf('\n========================================\n');
fprintf('METHOD 2: CUBIC SPLINE\n');
fprintf('========================================\n\n');

% Method-specific paths and bounds
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 cubic spline new');
minBound = importdata("minHetParams_CSabs.mat");
maxBound = importdata("maxHetParams_CSabs.mat");

% Pre-allocate results for this method
param_estimates = nan(n_subj, num_params, col);
negLL_values = nan(n_subj, col);
aic_values = nan(n_subj, col);
bic_values = nan(n_subj, col);

% Loop through subjects
for s = 1:n_subj
    tic;
    fprintf('Subject %s: Getting behavioral predictors ...\n', subj_ids{s});
    behv_data = [];

    % Loop through all sessions for this subject
    for j = 1:num_sess(s)
        % Construct filename (special case for subject 4672)
        filename = fullfile(behv_dir, [subj_ids{s}, '_main', num2str(j), '.xlsx']);
        if strcmp(subj_ids{s}, '4672')
            filename = fullfile(behv_dir, [subj_ids{s}, '_main', num2str(j), '_red.xlsx']);
        end
        % Load session data and extract relevant columns
        data_run = readtable(filename);
        rt = table(data_run.choice_rt, 'VariableNames', {'rt'});
        slider = table(data_run.slider_respond_response, 'VariableNames', {'slider'});
        data_run = [data_run(:, 1:16), rt, slider];
        % Concatenate with previous sessions
        behv_data = [behv_data; data_run];
    end

    % Extract subject-specific data
    preds = preds_all(preds_all.id == str2double(subj_ids{s}), :);
    x1 = abs(preds.pe);
    x2 = preds.con_diff;
    missedtrials_rt = isnan(behv_data.rt);
    behvdata_missedRT = behv_data(missedtrials_rt == 0, :);
    missedtrials_slider = isnan(behvdata_missedRT.slider);
    missedtrials = isnan(behv_data.rt) | isnan(behv_data.slider);

    % Remove all missed trials from behavioral data
    behv_data(missedtrials == 1, :) = [];
    validIndices = find(preds.pe == 0);
    preds(validIndices, :) = [];

    fprintf('Subject %s: Loading pupil signal...\n', subj_ids{s});
    filename = fullfile(pupil_dir, [subj_ids{s}, '.mat']);
    pupil = importdata(filename);
    filename = fullfile(xgaze_dir, [subj_ids{s}, '.mat']);
    xgaze_event = importdata(filename);
    filename = fullfile(ygaze_dir, [subj_ids{s}, '.mat']);
    ygaze_event = importdata(filename);

    % Use first 'col' timepoints for feedback-locked analysis
    zsc_pupil = pupil(:, 1:col);
    xgaze_signal = xgaze_event(:, 1:col);
    ygaze_signal = ygaze_event(:, 1:col);

    % Remove trials with missing behavioral responses
    zsc_pupil(missedtrials_slider == 1, :) = [];
    xgaze_signal(missedtrials_slider == 1, :) = [];
    ygaze_signal(missedtrials_slider == 1, :) = [];

    zsc_pupil(validIndices, :) = [];
    xgaze_signal(validIndices, :) = [];
    ygaze_signal(validIndices, :) = [];
    behv_data(validIndices, :) = [];

    % PRE-COMPUTE Z-SCORES
    fprintf('Subject %s: Pre-computing z-scores...\n', subj_ids{s});
    x1_z = nanzscore(abs(preds.pe));
    x2_z = nanzscore(preds.con_diff);
    rt_z = nanzscore(log(preds.rt));
    up_z = nanzscore(abs(preds.up));

    % Z-score gaze signals for each timepoint
    xgaze_z = nan(size(xgaze_signal));
    pupil_z = nan(size(zsc_pupil));
    ygaze_z = nan(size(ygaze_signal));
    for c = 1:col
        xgaze_z(:,c) = nanzscore(xgaze_signal(:,c));
        ygaze_z(:,c) = nanzscore(ygaze_signal(:,c));
        pupil_z(:,c) = nanzscore(zsc_pupil(:,c));
    end
    fprintf('Subject %s: Estimating parameters for each timepoint...\n', subj_ids{s});

    % Remove rows with ANY NaN values in predictors or outcome
    valid_rows = ~any(isnan([x1_z, x2_z, rt_z, up_z, zsc_pupil, xgaze_z, ygaze_z]), 2);
    fprintf('Subject %s: Removing %d trials with NaN values (keeping %d trials)\n', ...
        subj_ids{s}, sum(~valid_rows), sum(valid_rows));

    x1_z = x1_z(valid_rows);
    x2_z = x2_z(valid_rows);
    rt_z = rt_z(valid_rows);
    up_z = up_z(valid_rows);
    zsc_pupil = zsc_pupil(valid_rows, :);
    xgaze_z = xgaze_z(valid_rows, :);
    ygaze_z = ygaze_z(valid_rows, :);

    % Calculate N for AIC/BIC
    N_trials = sum(valid_rows);

    % RANDOM STARTING POINTS LOOP
    parfor c = 1:col
        % Extract data for this timepoint
        y = zsc_pupil(:,c);
        xgaze = xgaze_z(:,c);
        ygaze = ygaze_z(:,c);

        % Define negative log-likelihood for this timepoint
        negLLfun = @(params) negative_log_likelihood(params, x1_z, x2_z, y, ...
            rt_z, up_z, xgaze, ygaze);

        % Initialize best solution tracking
        bestNegLL = inf;
        bestParams = NaN;

        % Loop through random starting points
        for i = 1:n_sp
            % Generate random starting point
            current_params = unifrnd(minBound, maxBound);

            % Estimate parameters from this starting point
            [params_est, negLL_val] = fmincon(negLLfun, current_params, [], [], [], [], lb, ub, [], options);

            % Store best results
            if negLL_val < bestNegLL
                bestParams = params_est;
                bestNegLL = negLL_val;
            end
        end

        % Calculate AIC and BIC for best solution
        k = num_params;
        current_aic = 2 * k + 2 * bestNegLL;
        current_bic = k * log(N_trials) + 2 * bestNegLL;

        % Store results
        param_estimates(s,:,c) = bestParams;
        negLL_values(s,c) = bestNegLL;
        aic_values(s,c) = current_aic;
        bic_values(s,c) = current_bic;
    end

    elapsed = toc;
    fprintf('Subject %s completed in %.2f seconds (%.2f sec/timepoint)\n\n', subj_ids{s}, elapsed, elapsed/col);
end

% Save results for Cubic Spline
safe_saveall('bic_values_hetero_noZeroPE_CS_20SPAbs3Width.mat', bic_values)
safe_saveall('param_estimates_hetero_noZeroPE_CS_20SPAbs3Width.mat', param_estimates)
safe_saveall('negLL_hetero_noZeroPE_CS_20SPAbs3Width.mat', negLL_values)

fprintf('==== CUBIC SPLINE COMPLETED ====\n');
fprintf('Parameters estimated for %d subjects across %d timepoints\n\n', n_subj, col);

%% ========================================================================
%  METHOD 3: DECONVOLUTION
%  ========================================================================

fprintf('\n========================================\n');
fprintf('METHOD 3: DECONVOLUTION\n');
fprintf('========================================\n\n');

% Method-specific paths and bounds
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'fb');
minBound = importdata("minHetParams_deconvolutionabs.mat");
maxBound = importdata("maxHetParams_deconvolutionabs.mat");

% Pre-allocate results for this method
param_estimates = nan(n_subj, num_params, col);
negLL_values = nan(n_subj, col);
aic_values = nan(n_subj, col);
bic_values = nan(n_subj, col);

% Loop through subjects
for s = 1:n_subj
    tic;
    fprintf('Subject %s: Getting behavioral predictors ...\n', subj_ids{s});
    behv_data = [];

    % Loop through all sessions for this subject
    for j = 1:num_sess(s)
        % Construct filename (special case for subject 4672)
        filename = fullfile(behv_dir, [subj_ids{s}, '_main', num2str(j), '.xlsx']);
        if strcmp(subj_ids{s}, '4672')
            filename = fullfile(behv_dir, [subj_ids{s}, '_main', num2str(j), '_red.xlsx']);
        end
        % Load session data and extract relevant columns
        data_run = readtable(filename);
        rt = table(data_run.choice_rt, 'VariableNames', {'rt'});
        slider = table(data_run.slider_respond_response, 'VariableNames', {'slider'});
        data_run = [data_run(:, 1:16), rt, slider];
        % Concatenate with previous sessions
        behv_data = [behv_data; data_run];
    end

    % Extract subject-specific data
    preds = preds_all(preds_all.id == str2double(subj_ids{s}), :);
    x1 = abs(preds.pe);
    x2 = preds.con_diff;
    missedtrials_rt = isnan(behv_data.rt);
    behvdata_missedRT = behv_data(missedtrials_rt == 0, :);
    missedtrials_slider = isnan(behvdata_missedRT.slider);
    missedtrials = isnan(behv_data.rt) | isnan(behv_data.slider);

    % Remove all missed trials from behavioral data
    behv_data(missedtrials == 1, :) = [];
    validIndices = find(preds.pe == 0);
    preds(validIndices, :) = [];

    fprintf('Subject %s: Loading pupil signal...\n', subj_ids{s});
    filename = fullfile(pupil_dir, [subj_ids{s}, '.mat']);
    pupil = importdata(filename);
    filename = fullfile(xgaze_dir, [subj_ids{s}, '.mat']);
    xgaze_event = importdata(filename);
    filename = fullfile(ygaze_dir, [subj_ids{s}, '.mat']);
    ygaze_event = importdata(filename);

    % Use first 'col' timepoints for feedback-locked analysis
    zsc_pupil = pupil(:, 1:col);
    xgaze_signal = xgaze_event(:, 1:col);
    ygaze_signal = ygaze_event(:, 1:col);

    % Remove trials with missing behavioral responses
    zsc_pupil(missedtrials_slider == 1, :) = [];
    xgaze_signal(missedtrials_slider == 1, :) = [];
    ygaze_signal(missedtrials_slider == 1, :) = [];

    zsc_pupil(validIndices, :) = [];
    xgaze_signal(validIndices, :) = [];
    ygaze_signal(validIndices, :) = [];
    behv_data(validIndices, :) = [];

    % PRE-COMPUTE Z-SCORES
    fprintf('Subject %s: Pre-computing z-scores...\n', subj_ids{s});
    x1_z = nanzscore(abs(preds.pe));
    x2_z = nanzscore(preds.con_diff);
    rt_z = nanzscore(log(preds.rt));
    up_z = nanzscore(abs(preds.up));

    % Z-score gaze signals for each timepoint
    xgaze_z = nan(size(xgaze_signal));
    pupil_z = nan(size(zsc_pupil));
    ygaze_z = nan(size(ygaze_signal));
    for c = 1:col
        xgaze_z(:,c) = nanzscore(xgaze_signal(:,c));
        ygaze_z(:,c) = nanzscore(ygaze_signal(:,c));
        pupil_z(:,c) = nanzscore(zsc_pupil(:,c));
    end
    fprintf('Subject %s: Estimating parameters for each timepoint...\n', subj_ids{s});

    % Remove rows with ANY NaN values in predictors or outcome
    valid_rows = ~any(isnan([x1_z, x2_z, rt_z, up_z, zsc_pupil, xgaze_z, ygaze_z]), 2);
    fprintf('Subject %s: Removing %d trials with NaN values (keeping %d trials)\n', ...
        subj_ids{s}, sum(~valid_rows), sum(valid_rows));

    x1_z = x1_z(valid_rows);
    x2_z = x2_z(valid_rows);
    rt_z = rt_z(valid_rows);
    up_z = up_z(valid_rows);
    zsc_pupil = zsc_pupil(valid_rows, :);
    xgaze_z = xgaze_z(valid_rows, :);
    ygaze_z = ygaze_z(valid_rows, :);

    % Calculate N for AIC/BIC
    N_trials = sum(valid_rows);

    % RANDOM STARTING POINTS LOOP
    for c = 1:col
        % Extract data for this timepoint
        y = zsc_pupil(:,c);
        xgaze = xgaze_z(:,c);
        ygaze = ygaze_z(:,c);

        % Define negative log-likelihood for this timepoint
        negLLfun = @(params) negative_log_likelihood(params, x1_z, x2_z, y, ...
            rt_z, up_z, xgaze, ygaze);

        % Initialize best solution tracking
        bestNegLL = inf;
        bestParams = NaN;

        % Loop through random starting points
        for i = 1:n_sp
            % Generate random starting point
            current_params = unifrnd(minBound, maxBound);

            % Estimate parameters from this starting point
            [params_est, negLL_val] = fmincon(negLLfun, current_params, [], [], [], [], lb, ub, [], options);

            % Store best results
            if negLL_val < bestNegLL
                bestParams = params_est;
                bestNegLL = negLL_val;
            end
        end

        % Calculate AIC and BIC for best solution
        k = num_params;
        current_aic = 2 * k + 2 * bestNegLL;
        current_bic = k * log(N_trials) + 2 * bestNegLL;

        % Store results
        param_estimates(s,:,c) = bestParams;
        negLL_values(s,c) = bestNegLL;
        aic_values(s,c) = current_aic;
        bic_values(s,c) = current_bic;
    end

    elapsed = toc;
    fprintf('Subject %s completed in %.2f seconds (%.2f sec/timepoint)\n\n', subj_ids{s}, elapsed, elapsed/col);
end

% Save results for Deconvolution
safe_saveall('bic_values_hetero_noZeroPE_deconvolution_20SPAbs3Width.mat', bic_values)
safe_saveall('param_estimates_hetero_noZeroPE_deconvolution_20SPAbs3Width.mat', param_estimates)
safe_saveall('negLL_hetero_noZeroPE_deconvolution_20SPAbs3Width.mat', negLL_values)

fprintf('==== DECONVOLUTION COMPLETED ====\n');
fprintf('Parameters estimated for %d subjects across %d timepoints\n\n', n_subj, col);

%% ========================================================================
%  FINAL SUMMARY
%  ========================================================================

fprintf('\n========================================\n');
fprintf('ALL THREE METHODS COMPLETED\n');
fprintf('========================================\n');
fprintf('✓ Linear Interpolation\n');
fprintf('✓ Cubic Spline\n');
fprintf('✓ Deconvolution\n');
fprintf('\nParameters estimated for %d subjects across %d timepoints per method\n', n_subj, col);
fprintf('AIC and BIC values saved for all methods.\n');

%% ========================================================================
%  HELPER FUNCTION
%  ========================================================================

function nLL = negative_log_likelihood(params, x1, x2, y, x3, x4, x5, x6)

    % Extract regression parameters
    beta0 = params(1);     % intercept
    beta1 = params(2);     % PE
    beta2 = params(3);     % Condiff
    omikron_0 = params(4); % baseline noise
    omikron_1 = params(5); % prediction-dependent noise
    beta21 = params(6);    % PE x Condiff interaction
    beta3 = params(7);     % RT
    beta4 = params(8);     % UP
    beta5 = params(9);     % xgaze
    beta6 = params(10);    % ygaze

    % Predicted mean
    yhat = beta0 + beta1*x1 + beta2*x2 + beta21*(x2 .* x1) + beta3*x3 + beta4*x4 + beta5*x5 + beta6*x6;

    % Learning-rate dependent noise
    concentration = omikron_0 + omikron_1*abs(x2);
    concentration = max(concentration, 1e-6); % prevent negative or zero

    % Gaussian likelihood
    logL = -0.5*log(2*pi) - log(concentration) - 0.5*((y - yhat)./concentration).^2;

    % Negative log-likelihood
    nLL = -sum(logL);
end