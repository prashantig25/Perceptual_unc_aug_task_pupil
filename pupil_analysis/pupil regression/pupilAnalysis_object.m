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
behv_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'raw data');
xgaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'x-gaze');
ygaze_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'y-gaze');
base_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'baseline before fb');

% Load behavioral predictors
preds_file = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'LR analyses', 'preprocessed_lr_pupil.xlsx');
preds_all = readtable(preds_file);
preds_all.pe_condiff = abs(preds_all.pe) .* preds_all.con_diff;

%% ANALYSIS 1: MAIN MODEL (Figure 4)

%%%%%%%%% WITH LINEAR INTERPOLATION %%%%%%%%%%%%%%%%%

fprintf('\n=== Running Analysis 1: Main Model (Figure 4) linear interpolation ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 linearInt');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('pe_condiff_linearInt', 'perm_pe_condiff_linearInt', 'pe_condiff_residuals_linearInt', 'pe_condiff_predicted_linearInt');

% Run analysis and save
[betas, perm, residuals, predicted] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%%

%%%%%%%%% WITH CUBIC SPLINE INTERPOLATION %%%%%%%%%%%%%%%%%

fprintf('\n=== Running Analysis 1: Main Model (Figure 4) cubic spline interpolation ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 cubic spline new');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('pe_condiff_cubicSplineNew', 'perm_pe_condiff_cubicSplineNew', 'pe_condiff_residuals_CSnew', 'pe_condiff_predicted_CSnew');

% Run analysis and save
[betas, perm, residuals, predicted] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS: ADDITIVE MODEL 

%%%%%%%%% WITH LINEAR INTERPOLATION %%%%%%%%%%%%%%%%%

fprintf('\n=== Running Analysis ADDITIVE MODEL linear interpolation ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 linearInt');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('additiveMdl_linearInt', 'perm_additiveMdl_linearInt', '', '');

% Run analysis and save
[betas, perm, residuals, predicted] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% 
%%%%%%%%% WITH CUBIC SPLINE INTERPOLATION %%%%%%%%%%%%%%%%%

fprintf('\n=== Running Analysis ADDITIVE MODEL cubic spline interpolation ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 cubic spline new');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('additiveMdl_CSnew', 'perm_additiveMdl_CSnew', '', '');

% Run analysis and save
[betas, perm, residuals, predicted] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS 2: BINNED REGRESSION APPROACH (Figure 3c)

%%%%%%%% WITH LINEAR INTERPOLATION %%%%%%%%%%

fprintf('\n=== Running Analysis 2: Binned Regression Approach (Figure 3c) linear interpolation ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 linearInt');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('pe_condiff2bins_linearInt', 'perm_pe_condiff2bins_linearInt', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%%

%%%%%%%% WITH CUBIC SPLINE INTERPOLATION %%%%%%%%%%

fprintf('\n=== Running Analysis 2: Binned Regression Approach (Figure 3c) cubic spline interpolation ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 cubic spline new');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('pe_condiff2bins_cubicSplineNew', 'perm_pe_condiff2bins_cubicSplineNew', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();



%% ANALYSIS 3: REGRESSED RT MODEL (Figure S12)

%%%%%%%%%% WITH LINEAR INTERPOLATION %%%%%%%%%%%

fprintf('\n=== Running Analysis 3: Regressed RT Model (Figure S8) linear interpolation ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 linearInt');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + zsc_condiff + pe:zsc_condiff + rt';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('pe_condiff_regressedRT_linearInt', 'perm_pe_condiff_regressedRT_linearInt', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%%

%%%%%%%% WITH CUBIC SPLINE INTERPOLATION %%%%%%%%%%

fprintf('\n=== Running Analysis 3: Regressed RT Model (Figure S8) cubic spline interpolation ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 cubic spline new');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + zsc_condiff + pe:zsc_condiff + rt';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('pe_condiff_regressedRT_cubicSplineNew', 'perm_pe_condiff_regressedRT_cubicSplineNew', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();


%% ANALYSIS 5: PATCH-LOCKED PUPIL DILATION (Figure S8)

fprintf('\n=== Running Analysis 5: Patch-Locked Pupil Dilation (Figure S9) ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'patch linear int');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + condition + zsc_condiff';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf','condition'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('patch_condiff_linearInt', 'perm_patch_linearInt', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% =======================================================================
%          CONTROL ANALYSES: ALTERNATE PIPELINE 1 (Figure S10) 
%    Excludes high-pass filtering and only has baseline correction
% =======================================================================

%% ANALYSIS 6: MAIN MODEL BUT ON NON-BASELINE CORRECTED SIGNAL + MATHOT et al., 2022 PIPELINE

fprintf('\n=== Running Analysis 6: Non-baseline corrected Linear Interpolation ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'non-baseline corrected fb linear Int'); 
save_dir = fullfile(desiredPath, 'Data', 'GB data two pipelines', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('pe_condiff_mathot_nonBaselineCorrected_linearInt', 'perm_pe_condiff_mathot_nonBaselineCorrected_linearInt', 'pe_condiff_residuals_mathot_nonBaselineCorrected_linearInt', 'pe_condiff_predicted_mathot_nonBaselineCorrected_linearInt');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%%

%%%%%%%%% CUBIC SPLINE INTERPOLATION %%%%%%%%

fprintf('\n=== Running Analysis 6: Non-baseline corrected cubic spline interpolation ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'non-baseline corrected fb cubic spline new'); 
save_dir = fullfile(desiredPath, 'Data', 'GB data two pipelines', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('pe_condiff_mathot_nonBaselineCorrected_cubicSplineNew', 'perm_pe_condiff_mathot_nonBaselineCorrected_cubicSplineNew', 'pe_condiff_residuals_mathot_nonBaselineCorrected_cubicSplineNew', 'pe_condiff_predicted_mathot_nonBaselineCorrected_cubicSplineNew');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();


%% =======================================================================
%         CONTROL ANALYSES: ALTERNATE PIPELINE 2 (Figure S11)
%       Deconvolution-based correction for blinks and saccades
% =======================================================================

%% ANALYSIS 10: Figure S11
fprintf('\n=== Running Analysis 10: Main Model - Deconvolution Pipeline ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'fb');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff + pe:zsc_condiff';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff_deconvolution_updatedClusterStat', 'perm_pe_condiff_deconvolution_updatedClusterStat', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS 10: Figure S11 but w/o baseline correction
fprintf('\n=== Running Analysis 10: Main Model - Deconvolution Pipeline ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'non-baseline corrected fb');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff + pe:zsc_condiff';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.residuals_predicted = 0;

% Set filenames for saving
PupilRegression.setFileNames('pe_condiff_deconvolution_nonBaselineCorrected', 'perm_pe_condiff_deconvolution_nonBaselineCorrected', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS 3: REGRESSED RT MODEL BUT WITH DECONVOLUTION

fprintf('\n=== Running Analysis 3: Regressed RT Model (Figure S8) ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'fb');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + zsc_condiff + pe:zsc_condiff + rt';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('pe_condiff_regressedRT_deconvolution', 'perm_pe_condiff_regressedRT_deconvolution', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();

%% ANALYSIS: BINNED REGRESSION APPROACH (Figure 3c) BUT WITH DECONVOLUTION-BASED

fprintf('\n=== Running Analysis 2: Binned Regression Approach (Figure 3c) ===\n');

PupilRegression = PupilRegression();
PupilRegression.setSubjects(subj_ids, num_sess);

% Set paths
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'fb');
save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'control analyses for revisions');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
PupilRegression.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

% Set model parameters
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt';
vars = unique(regexp(model_def, '\w+', 'match'), 'stable'); % This regex finds all words, excluding the '~', '+', and ':' operators
dummyData = array2table(zeros(1, numel(vars)), 'VariableNames', vars); % Using 'VariableNames' ensures the table matches your model_def
tmpMdl = fitlm(dummyData, model_def); % 3. Fit a "thin" model to get the structure
numBetas = tmpMdl.NumCoefficients; % 4. Get the count 
num_vars = numBetas - 1;
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};
cat_vars = {'condition','reward','ecoperf'};
PupilRegression.setModel(model_def, pred_vars, cat_vars, num_vars);

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
PupilRegression.setFileNames('pe_condiff2bins_deconv', 'perm_pe_condiff2bins_deconv', '', '');

% Run analysis and save
[betas, perm, ~, ~] = PupilRegression.runAnalysis();
PupilRegression.saveResults();


fprintf('\n=== All analyses completed successfully ===\n');