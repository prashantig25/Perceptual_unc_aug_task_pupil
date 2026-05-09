clc
clearvars
rng(123);

%% =======================================================================
%                         COMMON SETUP
% =======================================================================

subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");

currentDir = cd; % current directory
reqPath = 'Perceptual_unc_aug_task_pupil'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end

behv_dir  = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'raw data');

xgaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'x-gaze linear int');
ygaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'y-gaze linear int new');

base_dir  = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'baseline before fb');

preds_file   = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'LR analyses', 'preprocessed_lr_pupil.xlsx');
preds_all    = readtable(preds_file);
preds_all.pe_condiff = abs(preds_all.pe) .* preds_all.con_diff;

het_save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', ...
                        'regression', 'control analyses for revisions');
if ~exist(het_save_dir, 'dir'); mkdir(het_save_dir); end

% Shared model specification
model_def       = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
pred_vars       = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf','pe_condiff'};
cat_vars        = {'condition','reward','ecoperf'};
num_params_hetero = 10;
lb = [-Inf, -Inf, -Inf,   0,   0, -Inf, -Inf, -Inf, -Inf, -Inf];
ub = [ Inf,  Inf,  Inf, Inf, Inf,  Inf,  Inf,  Inf,  Inf,  Inf];

% Heteroskedastic parameter names (fixed order matching negativeLogLikelihood)
coeff_names = {'Intercept', 'PE', 'Condiff', 'omikron_0', 'omikron_1', ...
               'PExCondiff', 'RT', 'UP', 'xgaze', 'ygaze'};
safe_saveall(fullfile(het_save_dir, 'coeff_names_hetero.mat'), coeff_names);

%% =======================================================================
%  PIPELINE 1: LINEAR INTERPOLATION
% =======================================================================
fprintf('\n====================================================\n');
fprintf('  PIPELINE 1: LINEAR INTERPOLATION\n');
fprintf('====================================================\n');

reg_het1 = PupilRegression_intHet();
reg_het1.setSubjects(subj_ids, num_sess);
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 linearInt');
reg_het1.setPaths(behv_dir, ...
    pupil_dir, ...
    xgaze_dir, ygaze_dir, het_save_dir);

dirs = {
    'pupil_dir',  pupil_dir;
    'xgaze_dir',  xgaze_dir;
    'ygaze_dir',  ygaze_dir;
};
keywords = {'linearInt', 'linear int', 'linear Int', 'LinearInt'};
checkPathKeywords(dirs, keywords);

reg_het1.setModel(model_def, pred_vars, cat_vars, num_params_hetero - 1);
reg_het1.setHeteroskedasticConfig(importdata('minHetParams_linearIntabs.mat'), ...
                                   importdata('maxHetParams_linearIntabs.mat'), lb, ub, 20);
reg_het1.setFileNames('placeholder', 'placeholder', 'placeholder', 'placeholder');
reg_het1.starting_points   = importdata('startingPoints_linearInt.mat');
reg_het1.preds_all         = preds_all;
reg_het1.timewindow        = 'feedback';
reg_het1.col               = 300;
reg_het1.regress_rt        = 0;
reg_het1.baseline_mdl      = 0;
reg_het1.binned            = 0;
reg_het1.binned_accuracy   = 0;
reg_het1.two_tailed        = 0;
reg_het1.bins_array        = 1;
reg_het1.residuals_predicted = 0;
reg_het1.use_sp              = 0;

reg_het1.runAnalysis();

safe_saveall(fullfile(het_save_dir, 'param_estimates_het_linearInt_ForPregenSP.mat'), reg_het1.betas_struct);
safe_saveall(fullfile(het_save_dir, 'negLL_het_linearInt_ForPregenSP.mat'),          reg_het1.negLL_values);
safe_saveall(fullfile(het_save_dir, 'perm_het_linearInt_ForPregenSP.mat'),          reg_het1.perm_results);

fprintf('Pipeline 1 saved.\n');

%% =======================================================================
%  PIPELINE 2: CUBIC SPLINE
% =======================================================================
fprintf('\n====================================================\n');
fprintf('  PIPELINE 2: CUBIC SPLINE\n');
fprintf('====================================================\n');

xgaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'x-gaze CS new');
ygaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'y-gaze CS');

reg_het2 = PupilRegression_intHet();
reg_het2.setSubjects(subj_ids, num_sess);
reg_het2.setPaths(behv_dir, ...
    fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 cubic spline new'), ...
    xgaze_dir, ygaze_dir, het_save_dir);
reg_het2.setModel(model_def, pred_vars, cat_vars, num_params_hetero - 1);
reg_het2.setHeteroskedasticConfig(importdata('minHetParams_CSabs.mat'), ...
                                   importdata('maxHetParams_CSabs.mat'), lb, ub, 20);
reg_het2.setFileNames('placeholder', 'placeholder', 'placeholder', 'placeholder');
reg_het2.starting_points   = importdata('startingPoints_CS.mat');
reg_het2.preds_all         = preds_all;
reg_het2.timewindow        = 'feedback';
reg_het2.col               = 300;
reg_het2.regress_rt        = 0;
reg_het2.baseline_mdl      = 0;
reg_het2.binned            = 0;
reg_het2.binned_accuracy   = 0;
reg_het2.two_tailed        = 0;
reg_het2.bins_array        = 1;
reg_het2.residuals_predicted = 0;
reg_het2.use_sp              = 0;

reg_het2.runAnalysis();

safe_saveall(fullfile(het_save_dir, 'param_estimates_het_CS_ForPregenSP.mat'), reg_het2.betas_struct);
safe_saveall(fullfile(het_save_dir, 'negLL_het_CS_ForPregenSP.mat'),          reg_het2.negLL_values);
safe_saveall(fullfile(het_save_dir, 'perm_het_CS_ForPregenSP.mat'),          reg_het2.perm_results);

fprintf('Pipeline 2 saved.\n');

%% =======================================================================
%  PIPELINE 3: DECONVOLUTION
% =======================================================================
fprintf('\n====================================================\n');
fprintf('  PIPELINE 3: DECONVOLUTION\n');
fprintf('====================================================\n');

xgaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'x-gaze deconv fixed seed');
ygaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'y-gaze deconv');

reg_het3 = PupilRegression_intHet();
reg_het3.setSubjects(subj_ids, num_sess);
reg_het3.setPaths(behv_dir, ...
    fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'alternate pipeline', 'pupil signal', 'fb deconv'), ...
    xgaze_dir, ygaze_dir, het_save_dir);

reg_het3.setModel(model_def, pred_vars, cat_vars, num_params_hetero - 1);
reg_het3.setHeteroskedasticConfig(importdata('minHetParams_deconvolutionabs.mat'), ...
                                   importdata('maxHetParams_deconvolutionabs.mat'), lb, ub, 20);
reg_het3.setFileNames('placeholder', 'placeholder', 'placeholder', 'placeholder');
reg_het3.starting_points   = importdata('startingPoints_deconv.mat');
reg_het3.preds_all         = preds_all;
reg_het3.timewindow        = 'feedback';
reg_het3.col               = 300;
reg_het3.regress_rt        = 0;
reg_het3.baseline_mdl      = 0;
reg_het3.binned            = 0;
reg_het3.binned_accuracy   = 0;
reg_het3.two_tailed        = 0;
reg_het3.bins_array        = 1;
reg_het3.residuals_predicted = 0;
reg_het3.use_sp              = 0;

reg_het3.runAnalysis();

safe_saveall(fullfile(het_save_dir, 'param_estimates_het_deconv_ForPregenSP.mat'), reg_het3.betas_struct);
safe_saveall(fullfile(het_save_dir, 'negLL_het_deconv_ForPregenSP.mat'),          reg_het3.negLL_values);
safe_saveall(fullfile(het_save_dir, 'perm_het_deconv_ForPregenSP.mat'),          reg_het3.perm_results);

fprintf('Pipeline 3 saved.\n');

fprintf('\n====================================================\n');
fprintf('  ALL PIPELINES COMPLETE\n');
fprintf('====================================================\n');

%% Configuration to pregen bounds
width = 3;              % Scaling factor for bounds (±width × max_abs_value)
ncoeffs = 1:10;        % Coefficient indices to process

%% Process Linear Interpolation Model
fprintf('Processing Linear Interpolation parameters...\n');
betas_struct = importdata("param_estimates_het_linearInt_ForPregenSP.mat");
[minCoeff, maxCoeff] = calculateSymmetricBounds(betas_struct, ncoeffs, width);

% Save results
safe_saveall("minHetParams_linearIntabs.mat", minCoeff);
safe_saveall("maxHetParams_linearIntabs.mat", maxCoeff);

%% Process Cubic Spline Model
fprintf('Processing Cubic Spline parameters...\n');
betas_struct = importdata("param_estimates_het_CS_ForPregenSP.mat");
[minCoeff, maxCoeff] = calculateSymmetricBounds(betas_struct, ncoeffs, width);

% Save results
safe_saveall("minHetParams_CSabs.mat", minCoeff);
safe_saveall("maxHetParams_CSabs.mat", maxCoeff);

%% Process Deconvolution Model
fprintf('Processing Deconvolution parameters...\n');
betas_struct = importdata("param_estimates_het_deconv_ForPregenSP.mat");
[minCoeff, maxCoeff] = calculateSymmetricBounds(betas_struct, ncoeffs, width);

% Save results
safe_saveall("minHetParams_deconvolutionabs.mat", minCoeff);
safe_saveall("maxHetParams_deconvolutionabs.mat", maxCoeff);

fprintf('All bounds calculated and saved successfully.\n');

%% pregen SP using bounds ...

nSubjs = length(subj_ids);
nCoeffs = 10;
nSp = 20;
col = 300;

rng(123)

%% SP for linear interpolation ...

minBound = importdata("minHetParams_linearIntabs.mat");
maxBound = importdata("maxHetParams_linearIntabs.mat");

startingPoints = NaN(nSubjs,col,nSp,num_params_hetero);

for n = 1:nSubjs
    for c = 1:nCoeffs
        for sp = 1:nSp
            for cl = 1:col
                startingPoints(n,cl,sp,c) = unifrnd(minBound(c), maxBound(c));
            end
        end
    end
end

safe_saveall("startingPoints_linearInt.mat",startingPoints)

%% SP for cubic-spline int ...

minBound = importdata("minHetParams_CSabs.mat");
maxBound = importdata("maxHetParams_CSabs.mat");

startingPoints = NaN(nSubjs,col,nSp,num_params_hetero);

for n = 1:nSubjs
    for c = 1:num_params_hetero
        for sp = 1:nSp
            for cl = 1:col
                startingPoints(n,cl,sp,c) = unifrnd(minBound(c), maxBound(c));
            end
        end
    end
end

safe_saveall("startingPoints_CS.mat",startingPoints)

%% SP for deconvolution-based preprocessing

minBound = importdata("minHetParams_deconvolutionabs.mat");
maxBound = importdata("maxHetParams_deconvolutionabs.mat");

startingPoints = NaN(nSubjs,col,nSp,num_params_hetero);

for n = 1:nSubjs
    for c = 1:nCoeffs
        for sp = 1:nSp
            for cl = 1:col
                startingPoints(n,cl,sp,c) = unifrnd(minBound(c), maxBound(c));
            end
        end
    end
end

safe_saveall("startingPoints_deconv.mat",startingPoints)


%% Helper Function: Calculate Symmetric Bounds
function [minCoeff, maxCoeff] = calculateSymmetricBounds(betas_struct, ncoeffs, width)
    % CALCULATESYMMETRICBOUNDS Compute symmetric min/max bounds for coefficients
    %
    % Inputs:
    %   betas_struct - Parameter estimates array (subjects × coeffs × bins)
    %   ncoeffs      - Vector of coefficient indices to process
    %   width        - Scaling factor for bounds
    %
    % Outputs:
    %   minCoeff     - Minimum bounds for each coefficient
    %   maxCoeff     - Maximum bounds for each coefficient
    
    % Preallocate output arrays
    minCoeff = NaN(length(ncoeffs), 1);
    maxCoeff = NaN(length(ncoeffs), 1);
    
    % Loop through each coefficient
    for a = 1:length(ncoeffs)
        coeff_idx = ncoeffs(a);
        
        % Extract data for current coefficient across all subjects and bins
        data_plot = squeeze(betas_struct.with_intercept(:, coeff_idx, :, :));
        
        % Find the maximum absolute value across all entries
        max_abs_val = max(abs(data_plot(:)));
        
        % Create symmetric bounds: ±width × max_abs_value
        minCoeff(a) = round(-width * max_abs_val);
        maxCoeff(a) = round(width * max_abs_val);
    end
end