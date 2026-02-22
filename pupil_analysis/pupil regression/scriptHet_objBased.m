clc
clearvars
rng(123);

%% =======================================================================
%                         COMMON SETUP
% =======================================================================

subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");

currentDir = cd;
reqPath    = 'Perceptual_unc_aug_task_pupil-main';
pathParts  = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

behv_dir  = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'raw data');
xgaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'x-gaze');
ygaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'y-gaze');
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
reg_het1.setPaths(behv_dir, ...
    fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 linearInt'), ...
    xgaze_dir, ygaze_dir, base_dir, het_save_dir);
reg_het1.setModel(model_def, pred_vars, cat_vars, num_params_hetero - 1);
reg_het1.setHeteroskedasticConfig(importdata('minHetParams_linearIntabs.mat'), ...
                                   importdata('maxHetParams_linearIntabs.mat'), lb, ub, 20);
reg_het1.setFileNames('placeholder', 'placeholder', 'placeholder', 'placeholder');
reg_het1.starting_points   = importdata('starting_points_linearInt.mat');
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

[~, ~, ~, ~] = reg_het1.runAnalysis();

safe_saveall(fullfile(het_save_dir, 'param_estimates_hetero_noZeroPE_linearInt_20SPAbs3Width_pregenSP.mat'), reg_het1.betas_struct);
safe_saveall(fullfile(het_save_dir, 'negLL_hetero_noZeroPE_linearInt_20SPAbs3Width_pregenSP.mat'),          reg_het1.negLL_values);
fprintf('Pipeline 1 saved.\n');

%% =======================================================================
%  PIPELINE 2: CUBIC SPLINE
% =======================================================================
fprintf('\n====================================================\n');
fprintf('  PIPELINE 2: CUBIC SPLINE\n');
fprintf('====================================================\n');

reg_het2 = PupilRegression_intHet();
reg_het2.setSubjects(subj_ids, num_sess);
reg_het2.setPaths(behv_dir, ...
    fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 cubic spline new'), ...
    xgaze_dir, ygaze_dir, base_dir, het_save_dir);
reg_het2.setModel(model_def, pred_vars, cat_vars, num_params_hetero - 1);
reg_het2.setHeteroskedasticConfig(importdata('minHetParams_CSabs.mat'), ...
                                   importdata('maxHetParams_CSabs.mat'), lb, ub, 20);
reg_het2.setFileNames('placeholder', 'placeholder', 'placeholder', 'placeholder');
reg_het2.starting_points   = importdata('starting_points_CS.mat');
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

[~, ~, ~, ~] = reg_het2.runAnalysis();

safe_saveall(fullfile(het_save_dir, 'param_estimates_hetero_noZeroPE_CS_20SPAbs3Width_pregenSP.mat'), reg_het2.betas_struct);
safe_saveall(fullfile(het_save_dir, 'negLL_hetero_noZeroPE_CS_20SPAbs3Width_pregenSP.mat'),          reg_het2.negLL_values);
fprintf('Pipeline 2 saved.\n');

%% =======================================================================
%  PIPELINE 3: DECONVOLUTION
% =======================================================================
fprintf('\n====================================================\n');
fprintf('  PIPELINE 3: DECONVOLUTION\n');
fprintf('====================================================\n');

reg_het3 = PupilRegression_intHet();
reg_het3.setSubjects(subj_ids, num_sess);
reg_het3.setPaths(behv_dir, ...
    fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'alternate pipeline', 'pupil signal', 'fb'), ...
    xgaze_dir, ygaze_dir, base_dir, het_save_dir);
reg_het3.setModel(model_def, pred_vars, cat_vars, num_params_hetero - 1);
reg_het3.setHeteroskedasticConfig(importdata('minHetParams_deconvolutionabs.mat'), ...
                                   importdata('maxHetParams_deconvolutionabs.mat'), lb, ub, 20);
reg_het3.setFileNames('placeholder', 'placeholder', 'placeholder', 'placeholder');
reg_het3.starting_points   = importdata('starting_points_deconvolution.mat');
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

[~, ~, ~, ~] = reg_het3.runAnalysis();

safe_saveall(fullfile(het_save_dir, 'param_estimates_hetero_noZeroPE_deconvolution_20SPAbs3Width_pregenSP.mat'), reg_het3.betas_struct);
safe_saveall(fullfile(het_save_dir, 'negLL_hetero_noZeroPE_deconvolution_20SPAbs3Width_pregenSP.mat'),          reg_het3.negLL_values);
fprintf('Pipeline 3 saved.\n');

fprintf('\n====================================================\n');
fprintf('  ALL PIPELINES COMPLETE\n');
fprintf('====================================================\n');