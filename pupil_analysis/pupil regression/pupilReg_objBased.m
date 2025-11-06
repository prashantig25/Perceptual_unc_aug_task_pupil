% pupil_regressionNew_OOP - Object-oriented implementation of pupil regression analyses
% This script runs all model-based analyses on event-locked pupil response using the new OOP framework

clc
clearvars

%% SETUP COMMON PARAMETERS
% Subject and session information
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'};
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];

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

analyzer1 = PupilRegression();
analyzer1.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir1 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial";
save_dir1 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline + trial specific baseline/main";
analyzer1.setPaths(behv_dir, pupil_dir1, xgaze_dir, ygaze_dir, base_dir, save_dir1);

% Set model parameters
model_def1 = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
pred_vars1 = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf','pe_condiff'};
cat_vars1 = {'condition','reward','ecoperf'};
analyzer1.setModel(model_def1, pred_vars1, cat_vars1, 7);

% Set analysis parameters
analyzer1.timewindow = 'feedback';
analyzer1.col = 300;
analyzer1.regress_rt = 0;
analyzer1.baseline_mdl = 0;
analyzer1.binned = 0;
analyzer1.binned_accuracy = 0;
analyzer1.two_tailed = 0;
analyzer1.bins_array = 1;
analyzer1.preds_all = preds_all;

analyzer1.setFileNames('pe_condiff', 'perm_pe_condiff', 'pe_condiff_residuals', 'pe_condiff_predicted');

% Run analysis and save
[betas1, perm1, residuals1, predicted1] = analyzer1.runAnalysis();
analyzer1.saveResults();

%% ANALYSIS 2: BINNED REGRESSION APPROACH (Figure 3c)
fprintf('\n=== Running Analysis 2: Binned Regression Approach (Figure 3c) ===\n');

analyzer2 = PupilRegressionAnalyzer();
analyzer2.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir2 = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\pupil signal\only high pass filter used\fb";
save_dir2 = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\regression\only high pass filter used\main";
analyzer2.setPaths(behv_dir, pupil_dir2, xgaze_dir, ygaze_dir, base_dir, save_dir2);

% Set model parameters
model_def2 = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt';
analyzer2.setModel(model_def2, pred_vars1, cat_vars1, 5);

% Set analysis parameters
analyzer2.timewindow = 'feedback';
analyzer2.col = 300;
analyzer2.regress_rt = 0;
analyzer2.baseline_mdl = 0;
analyzer2.binned = 1;
analyzer2.bins = prctile(preds_all.con_diff, 0:50:100);
analyzer2.bins_array = [1:2];
analyzer2.binned_accuracy = 0;
analyzer2.two_tailed = 1;
analyzer2.preds_all = preds_all;

analyzer2.setFileNames('pe_condiff2bins', 'perm_pe_condiff2bins', '', '');

% Run analysis and save
[betas2, perm2, ~, ~] = analyzer2.runAnalysis();
analyzer2.saveResults();

%% ANALYSIS 3: REGRESSED RT MODEL (Figure S8)
fprintf('\n=== Running Analysis 3: Regressed RT Model (Figure S8) ===\n');

analyzer3 = PupilRegressionAnalyzer();
analyzer3.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir3 = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'fb');
save_dir3 = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'main');
analyzer3.setPaths(behv_dir, pupil_dir3, xgaze_dir, ygaze_dir, base_dir, save_dir3);

% Set model parameters
model_def3 = 'pupil ~ xgaze + ygaze + pe + zsc_up + zsc_condiff + pe:zsc_condiff + rt';
analyzer3.setModel(model_def3, pred_vars1, cat_vars1, 7);

% Set analysis parameters
analyzer3.timewindow = 'feedback';
analyzer3.col = 300;
analyzer3.regress_rt = 1;  % Key difference: regress RT effects
analyzer3.baseline_mdl = 0;
analyzer3.binned = 0;
analyzer3.bins_array = 1;
analyzer3.binned_accuracy = 0;
analyzer3.two_tailed = 0;
analyzer3.preds_all = preds_all;

analyzer3.setFileNames('pe_condiff_regressedRT', 'perm_pe_condiff_regressedRT', '', '');

% Run analysis and save
[betas3, perm3, ~, ~] = analyzer3.runAnalysis();
analyzer3.saveResults();

%% ANALYSIS 4: MODEL WITH BASELINE AS REGRESSOR (Figure S7)
fprintf('\n=== Running Analysis 4: Model with Baseline as Regressor (Figure S7) ===\n');

analyzer4 = PupilRegressionAnalyzer();
analyzer4.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir4 = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'non-baseline corrected fb');
save_dir4 = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'main');
analyzer4.setPaths(behv_dir, pupil_dir4, xgaze_dir, ygaze_dir, base_dir, save_dir4);

% Set model parameters
model_def4 = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff + pe:zsc_condiff + baseline';
analyzer4.setModel(model_def4, pred_vars1, cat_vars1, 8);

% Set analysis parameters
analyzer4.timewindow = 'feedback';
analyzer4.col = 300;
analyzer4.regress_rt = 0;
analyzer4.baseline_mdl = 1;  % Key difference: use baseline model
analyzer4.binned = 0;
analyzer4.bins_array = 1;
analyzer4.binned_accuracy = 0;
analyzer4.two_tailed = 0;
analyzer4.preds_all = preds_all;

analyzer4.setFileNames('pe_condiff_regressedbaseline', 'perm_pe_condiff_regressedbaseline', '', '');

% Run analysis and save
[betas4, perm4, ~, ~] = analyzer4.runAnalysis();
analyzer4.saveResults();

%% ANALYSIS 5: NON-BASELINE CORRECTED SIGNAL (MATHOT)
fprintf('\n=== Running Analysis 5: Non-baseline Corrected Signal (Mathot) ===\n');

analyzer5 = PupilRegressionAnalyzer();
analyzer5.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir5 = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\pupil signal\Mathot\non-baseline corrected fb";
save_dir5 = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\regression\Mathot\main";
analyzer5.setPaths(behv_dir, pupil_dir5, xgaze_dir, ygaze_dir, base_dir, save_dir5);

% Set model parameters
model_def5 = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff + pe:zsc_condiff';
analyzer5.setModel(model_def5, pred_vars1, cat_vars1, 7);

% Set analysis parameters
analyzer5.timewindow = 'feedback';
analyzer5.col = 300;
analyzer5.regress_rt = 0;
analyzer5.baseline_mdl = 1;
analyzer5.binned = 0;
analyzer5.bins_array = 1;
analyzer5.binned_accuracy = 0;
analyzer5.two_tailed = 0;
analyzer5.preds_all = preds_all;

analyzer5.setFileNames('pe_condiff_tonicSignal', 'perm_pe_condiff_tonicSignal', '', '');

% Run analysis and save
[betas5, perm5, ~, ~] = analyzer5.runAnalysis();
analyzer5.saveResults();

%% ANALYSIS 6: BINNED REGRESSION WITH MATHOT PREPROCESSING
fprintf('\n=== Running Analysis 6: Binned Regression with Mathot Preprocessing ===\n');

analyzer6 = PupilRegressionAnalyzer();
analyzer6.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir6 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/pupil signal/Mathot/non-baseline corrected fb";
save_dir6 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/Mathot/main";
analyzer6.setPaths(behv_dir, pupil_dir6, xgaze_dir, ygaze_dir, base_dir, save_dir6);

% Set model parameters
model_def6 = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt';
analyzer6.setModel(model_def6, pred_vars1, cat_vars1, 5);

% Set analysis parameters
analyzer6.timewindow = 'feedback';
analyzer6.col = 300;
analyzer6.regress_rt = 0;
analyzer6.baseline_mdl = 0;
analyzer6.binned = 1;
analyzer6.bins = prctile(preds_all.con_diff, 0:50:100);
analyzer6.bins_array = [1:2];
analyzer6.binned_accuracy = 0;
analyzer6.two_tailed = 1;
analyzer6.preds_all = preds_all;

analyzer6.setFileNames('pe_condiff2bins_tonicSignal', 'perm_pe_condiff2bins_tonicSignal', '', '');

% Run analysis and save
[betas6, perm6, ~, ~] = analyzer6.runAnalysis();
analyzer6.saveResults();

%% ANALYSIS 7: NON-BASELINE CORRECTED + NO BASELINE REGRESSOR
fprintf('\n=== Running Analysis 7: Non-baseline Corrected + No Baseline Regressor ===\n');

analyzer7 = PupilRegressionAnalyzer();
analyzer7.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir7 = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'non-baseline corrected fb');
save_dir7 = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'main');
analyzer7.setPaths(behv_dir, pupil_dir7, xgaze_dir, ygaze_dir, base_dir, save_dir7);

% Set model parameters
model_def7 = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff + pe:zsc_condiff';
analyzer7.setModel(model_def7, pred_vars1, cat_vars1, 7);

% Set analysis parameters
analyzer7.timewindow = 'feedback';
analyzer7.col = 300;
analyzer7.regress_rt = 0;
analyzer7.baseline_mdl = 1;
analyzer7.binned = 0;
analyzer7.bins_array = 1;
analyzer7.binned_accuracy = 0;
analyzer7.two_tailed = 0;
analyzer7.preds_all = preds_all;

analyzer7.setFileNames('pe_condiff_tonicSignal_nonBaselineCorrected_noBaselineRegressor', 'perm_pe_condiff_nonBaselineCorrected_noBaselineRegressor', '', '');

% Run analysis and save
[betas7, perm7, ~, ~] = analyzer7.runAnalysis();
analyzer7.saveResults();

%% ANALYSIS 8: PATCH-LOCKED PUPIL DILATION
fprintf('\n=== Running Analysis 8: Patch-locked Pupil Dilation ===\n');

analyzer8 = PupilRegressionAnalyzer();
analyzer8.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir8 = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'pupil signal', 'patch');
save_dir8 = fullfile(desiredPath, 'data', 'GB data peak corrected', 'pupil', 'regression', 'main');
analyzer8.setPaths(behv_dir, pupil_dir8, xgaze_dir, ygaze_dir, base_dir, save_dir8);

% Set model parameters
model_def8 = 'pupil ~ xgaze + ygaze + condition + zsc_condiff';
pred_vars8 = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf','condition'};
analyzer8.setModel(model_def8, pred_vars8, cat_vars1, 4);

% Set analysis parameters
analyzer8.timewindow = 'patch';  % Key difference: patch timewindow
analyzer8.col = 300;
analyzer8.regress_rt = 0;
analyzer8.baseline_mdl = 0;
analyzer8.binned = 0;
analyzer8.bins_array = 1;
analyzer8.binned_accuracy = 0;
analyzer8.two_tailed = 0;
analyzer8.preds_all = preds_all;

analyzer8.setFileNames('patch_condiff', 'perm_patch_condiff', '', '');

% Run analysis and save
[betas8, perm8, ~, ~] = analyzer8.runAnalysis();
analyzer8.saveResults();

%% ANALYSIS 9: CONTRAST DIFFERENCE ONLY MODEL
fprintf('\n=== Running Analysis 9: Contrast Difference Only Model ===\n');

analyzer9 = PupilRegressionAnalyzer();
analyzer9.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir9 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial";
save_dir9 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline/control";
analyzer9.setPaths(behv_dir, pupil_dir9, xgaze_dir, ygaze_dir, base_dir, save_dir9);

% Set model parameters
model_def9 = 'pupil ~ xgaze + ygaze + zsc_condiff + rt';
analyzer9.setModel(model_def9, pred_vars1, cat_vars1, 5);

% Set analysis parameters
analyzer9.timewindow = 'feedback';
analyzer9.col = 300;
analyzer9.regress_rt = 0;
analyzer9.baseline_mdl = 0;
analyzer9.binned = 0;
analyzer9.bins_array = 1;
analyzer9.binned_accuracy = 0;
analyzer9.two_tailed = 0;
analyzer9.preds_all = preds_all;

analyzer9.setFileNames('condiff_rt', 'perm_condiff_rt', '', '');

% Run analysis and save
[betas9, perm9, ~, ~] = analyzer9.runAnalysis();
analyzer9.saveResults();

%% ANALYSIS 10: CORRECT/REWARD TRIALS ONLY
fprintf('\n=== Running Analysis 10: Correct/Reward Trials Only ===\n');

analyzer10 = PupilRegressionAnalyzer();
analyzer10.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir10 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial";
save_dir10 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline/control";
analyzer10.setPaths(behv_dir, pupil_dir10, xgaze_dir, ygaze_dir, base_dir, save_dir10);

% Set model parameters
model_def10 = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
analyzer10.setModel(model_def10, pred_vars1, cat_vars1, 7);

% Set analysis parameters
analyzer10.timewindow = 'feedback';
analyzer10.col = 300;
analyzer10.regress_rt = 0;
analyzer10.baseline_mdl = 0;
analyzer10.binned = 0;
analyzer10.bins_array = [0,1];  % Key difference: analyze by reward/correct
analyzer10.binned_accuracy = 1;  % Key difference: bin by accuracy
analyzer10.two_tailed = 0;
analyzer10.preds_all = preds_all;

analyzer10.setFileNames('pe_condiff_binnedReward', 'perm_pe_condiff_binnedReward', '', '');

% Run analysis and save
[betas10, perm10, ~, ~] = analyzer10.runAnalysis();
analyzer10.saveResults();

%% ANALYSIS 11: NO INTERACTION MODEL (FOR PARTIAL REGRESSION)
fprintf('\n=== Running Analysis 11: No Interaction Model (For Partial Regression) ===\n');

analyzer11 = PupilRegressionAnalyzer();
analyzer11.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir11 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial";
save_dir11 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline/supplement";
analyzer11.setPaths(behv_dir, pupil_dir11, xgaze_dir, ygaze_dir, base_dir, save_dir11);

% Set model parameters
model_def11 = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff';  % No interaction term
analyzer11.setModel(model_def11, pred_vars1, cat_vars1, 6);

% Set analysis parameters
analyzer11.timewindow = 'feedback';
analyzer11.col = 300;
analyzer11.regress_rt = 0;
analyzer11.baseline_mdl = 0;
analyzer11.binned = 0;
analyzer11.bins_array = 1;
analyzer11.binned_accuracy = 0;
analyzer11.two_tailed = 0;
analyzer11.preds_all = preds_all;

analyzer11.setFileNames('pe_condiff_noInteraction', 'perm_pe_condiff_noInteraction', 'pe_condiff_noInteraction_residuals', '');

% Run analysis and save
[betas11, perm11, residuals11, ~] = analyzer11.runAnalysis();
analyzer11.saveResults();

%% ANALYSIS 12: PE x CONDIFF PREDICTION MODEL
fprintf('\n=== Running Analysis 12: PE x CONDIFF Prediction Model ===\n');

analyzer12 = PupilRegressionAnalyzer();
analyzer12.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir12 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial";
save_dir12 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline/supplement";
analyzer12.setPaths(behv_dir, pupil_dir12, xgaze_dir, ygaze_dir, base_dir, save_dir12);

% Set model parameters - Key difference: predict pe_condiff instead of pupil
model_def12 = 'pe_condiff ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff';
pred_vars12 = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
analyzer12.setModel(model_def12, pred_vars12, cat_vars1, 6);

% Set analysis parameters
analyzer12.timewindow = 'feedback';
analyzer12.col = 300;
analyzer12.regress_rt = 0;
analyzer12.baseline_mdl = 0;
analyzer12.binned = 0;
analyzer12.bins_array = 1;
analyzer12.binned_accuracy = 0;
analyzer12.two_tailed = 0;
analyzer12.resp_var = 'pe_condiff';  % Key difference: different response variable
analyzer12.preds_all = preds_all;

analyzer12.setFileNames('pe_condiff_noPupil', 'perm_pe_condiff_noPupil', 'pe_condiff_noPupil_residuals', '');

% Run analysis and save
[betas12, perm12, residuals12, ~] = analyzer12.runAnalysis();
analyzer12.saveResults();

%% SUMMARY
fprintf('\n=== ANALYSIS SUMMARY ===\n');
fprintf('Completed 12 unique pupil regression analyses:\n');
fprintf('1.  Main Model (Figure 4)\n');
fprintf('2.  Binned Regression Approach (Figure 3c)\n');
fprintf('3.  Regressed RT Model (Figure S8)\n');
fprintf('4.  Model with Baseline as Regressor (Figure S7)\n');
fprintf('5.  Non-baseline Corrected Signal (Mathot)\n');
fprintf('6.  Binned Regression with Mathot Preprocessing\n');
fprintf('7.  Non-baseline Corrected + No Baseline Regressor\n');
fprintf('8.  Patch-locked Pupil Dilation\n');
fprintf('9.  Contrast Difference Only Model\n');
fprintf('10. Correct/Reward Trials Only\n');
fprintf('11. No Interaction Model (For Partial Regression)\n');
fprintf('12. PE x CONDIFF Prediction Model\n');
fprintf('\nAll analyses completed successfully!\n');
