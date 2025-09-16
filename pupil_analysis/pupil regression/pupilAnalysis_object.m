clc
clearvars

%% =======================================================================
%                            SETUP COMMON PARAMETERS
% =======================================================================

% Subject and session information
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");

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
behv_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'behavior', 'raw data');
xgaze_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'x-gaze');
ygaze_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'y-gaze');
base_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'baseline before fb');

% Load behavioral predictors
preds_file = fullfile(desiredPath, 'data', 'GB data peak corrected', 'behavior', 'LR analyses', 'preprocessed_lr_pupil.xlsx');
preds_all = readtable(preds_file);
preds_all.pe_condiff = abs(preds_all.pe) .* preds_all.con_diff;

%% ANALYSIS 1: MAIN MODEL (Figure 4)
fprintf('\n=== Running Analysis 1: Main Model (Figure 4) ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'fb');
save_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'main');
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 7);

% Set analysis parameters
PupilRegression.timewindow = 'feedback';
PupilRegression.col = 300;
PupilRegression.regress_rt = 0;
PupilRegression.baseline_mdl = 0;
PupilRegression.binned = 0;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 0;
PupilRegression.bins_array = 1;
PupilRegression.preds_all = preds_all;
PupilRegression.residuals_predicted = 1;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff', 'perm_pe_condiff', 'pe_condiff_residuals', 'pe_condiff_predicted');

% Run analysis and save
[betas, perm, residuals, predicted] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS 2: BINNED REGRESSION APPROACH (Figure 3c)
fprintf('\n=== Running Analysis 2: Binned Regression Approach (Figure 3c) ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'fb');
save_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'main');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 5);

% Set analysis parameters
PupilRegression.timewindow = 'feedback';
PupilRegression.col = 300;
PupilRegression.regress_rt = 0;
PupilRegression.baseline_mdl = 0;
PupilRegression.binned = 1;
PupilRegression.bins = prctile(preds_all.con_diff, 0:50:100);
PupilRegression.bins_array = 1:2;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 1;
PupilRegression.preds_all = preds_all;
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff2bins', 'perm_pe_condiff2bins', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS 3: REGRESSED RT MODEL (Figure S8)
fprintf('\n=== Running Analysis 3: Regressed RT Model (Figure S8) ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'fb');
save_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'main');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + zsc_condiff + pe:zsc_condiff + rt';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 7);

% Set analysis parameters
PupilRegression.timewindow = 'feedback';
PupilRegression.col = 300;
PupilRegression.regress_rt = 1;  % regress RT effects
PupilRegression.baseline_mdl = 0;
PupilRegression.binned = 0;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 0;
PupilRegression.bins_array = 1;
PupilRegression.preds_all = preds_all;
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff_regressedRT', 'perm_pe_condiff_regressedRT', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS 4: MODEL WITH BASELINE AS REGRESSOR (Figure S7)
fprintf('\n=== Running Analysis 4: Model with Baseline as Regressor (Figure S7) ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'non-baseline corrected fb');
save_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'main');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff + pe:zsc_condiff + baseline';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 8);

% Set analysis parameters
PupilRegression.timewindow = 'feedback';
PupilRegression.col = 300;
PupilRegression.regress_rt = 0;
PupilRegression.baseline_mdl = 1;  % use non-baseline corrected signal
PupilRegression.binned = 0;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 0;
PupilRegression.bins_array = 1;
PupilRegression.preds_all = preds_all;
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff_regressedbaseline', 'perm_pe_condiff_regressedbaseline', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS 5: PATCH-LOCKED PUPIL DILATION (Figure S9)
fprintf('\n=== Running Analysis 5: Patch-Locked Pupil Dilation (Figure S9) ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'patch');
save_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'main');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + condition + zsc_condiff';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf','condition'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 4);

% Set analysis parameters
PupilRegression.timewindow = 'patch';
PupilRegression.col = 300;
PupilRegression.regress_rt = 0;
PupilRegression.baseline_mdl = 0;
PupilRegression.binned = 0;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 0;
PupilRegression.bins_array = 1;
PupilRegression.preds_all = preds_all;

% Set filenames for saving
PupilRegression.setFileNames('patch_condiff', 'perm_patch_condiff', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% =======================================================================
%          CONTROL ANALYSES: ALTERNATE PIPELINE 1 (MATHOT et al., 2022)
%    Excludes high-pass filtering and only has baseline correction
% =======================================================================

%% ANALYSIS 6: MAIN MODEL - MATHOT PIPELINE
fprintf('\n=== Running Analysis 6: Main Model - Mathot Pipeline ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'alternate and control pipelines', 'Mathot', 'fb'); 
save_dir = fullfile(desiredPath, 'Data', 'GB data peak corrected', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 7);

% Set analysis parameters
PupilRegression.timewindow = 'feedback';
PupilRegression.col = 300;
PupilRegression.regress_rt = 0;
PupilRegression.baseline_mdl = 0;
PupilRegression.binned = 0;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 0;
PupilRegression.bins_array = 1;
PupilRegression.preds_all = preds_all;
PupilRegression.residuals_predicted = 1;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff_mathot', 'perm_pe_condiff_mathot', 'pe_condiff_residuals_mathot', 'pe_condiff_predicted_mathot');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS 7: BINNED REGRESSION - MATHOT PIPELINE
fprintf('\n=== Running Analysis 7: Binned Regression - Mathot Pipeline ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'alternate and control pipelines', 'Mathot', 'fb'); 
save_dir = fullfile(desiredPath, 'Data', 'GB data peak corrected', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 5);

% Set analysis parameters
PupilRegression.timewindow = 'feedback';
PupilRegression.col = 300;
PupilRegression.regress_rt = 0;
PupilRegression.baseline_mdl = 0;
PupilRegression.binned = 1;
PupilRegression.bins = prctile(preds_all.con_diff, 0:50:100);
PupilRegression.bins_array = 1:2;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 1;
PupilRegression.preds_all = preds_all;
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff2bins_mathot', 'perm_pe_condiff2bins_mathot', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% =======================================================================
%         CONTROL ANALYSES: ALTERNATE PIPELINE 2 (NO HIGH-PASS + NO BASELINE)
%    Excludes both high-pass filtering and baseline correction
% =======================================================================

%% ANALYSIS 8: MAIN MODEL - NO HIGH-PASS + NO BASELINE CORRECTION
fprintf('\n=== Running Analysis 8: Main Model - No High-Pass + No Baseline Correction ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'alternate and control pipelines', 'Mathot', 'non-baseline corrected fb'); 
save_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff + pe:zsc_condiff';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 7);

% Set analysis parameters
PupilRegression.timewindow = 'feedback';
PupilRegression.col = 300;
PupilRegression.regress_rt = 0;
PupilRegression.baseline_mdl = 1;  % non-baseline corrected signal
PupilRegression.binned = 0;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 0;
PupilRegression.bins_array = 1;
PupilRegression.preds_all = preds_all;
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff_tonicSignal_nohighpass', 'perm_pe_condiff_tonicSignal_nohighpass', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS 9: BINNED REGRESSION - NO HIGH-PASS + NO BASELINE CORRECTION
fprintf('\n=== Running Analysis 9: Binned Regression - No High-Pass + No Baseline Correction ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'alternate and control pipelines', 'Mathot', 'non-baseline corrected fb'); 
save_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 5);

% Set analysis parameters
PupilRegression.timewindow = 'feedback';
PupilRegression.col = 300;
PupilRegression.regress_rt = 0;
PupilRegression.baseline_mdl = 1;  % using non-baseline corrected signal
PupilRegression.binned = 1;  % binned regression approach
PupilRegression.bins = prctile(preds_all.con_diff, 0:50:100);
PupilRegression.bins_array = 1:2;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 1;
PupilRegression.preds_all = preds_all;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff2bins_tonicSignal_nohighpass', 'perm_pe_condiff2bins_tonicSignal_nohighpass', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% =======================================================================
%      CONTROL ANALYSES: PREPRINT PIPELINE (NON-BASELINE CORRECTED)
%           Non-baseline corrected signal + no baseline regressor
% =======================================================================

%% ANALYSIS 10: MAIN MODEL - PREPRINT PIPELINE  
fprintf('\n=== Running Analysis 10: Main Model - Preprint Pipeline ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'non-baseline corrected fb');
save_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff + pe:zsc_condiff';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 7);

% Set analysis parameters
PupilRegression.timewindow = 'feedback';
PupilRegression.col = 300;
PupilRegression.regress_rt = 0;
PupilRegression.baseline_mdl = 1;  % non-baseline corrected signal
PupilRegression.binned = 0;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 0;
PupilRegression.bins_array = 1;
PupilRegression.preds_all = preds_all;
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff_tonicSignal', 'perm_pe_condiff_tonicSignal', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS 11: BINNED REGRESSION - PREPRINT PIPELINE
fprintf('\n=== Running Analysis 11: Binned Regression - Preprint Pipeline ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'non-baseline corrected fb');
save_dir = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt';
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, 5);

% Set analysis parameters
PupilRegression.timewindow = 'feedback';
PupilRegression.col = 300;
PupilRegression.regress_rt = 0;
PupilRegression.baseline_mdl = 0;
PupilRegression.binned = 1;
PupilRegression.bins = prctile(preds_all.con_diff, 0:50:100);
PupilRegression.bins_array = 1:2;
PupilRegression.binned_accuracy = 0;
PupilRegression.two_tailed = 1;
PupilRegression.preds_all = preds_all;
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff2bins_tonicSignal', 'perm_pe_condiff2bins_tonicSignal', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

fprintf('\n=== All analyses completed successfully ===\n');