% pupil_regressionNew runs model-based analyses on event-locked pupil
% response.

clc
clearvars

subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'};
timewindow = 'feedback'; % time-window on which regression needs to be applied
col = 300; % number of samples on which the regression is applied
num_subs = length(subj_ids); % number of subjects
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf','pe_condiff'};% cell array with names of predictor variables
resp_var = 'pupil'; % name of response variable
cat_vars = {'condition','reward','ecoperf'}; % cell array with names of categorical variables
binned_accuracy = 0; % whether binned regression approach is to be used for separate bins of correct and incorrect trials
main_mdl = 1; % if the betas should be estimated for the main model (Fig. 4 in MS)
baseline_mdl = 0; % if betas should be estimated by fitting the model to non-baseline corrected pupil signal
noRT_mdl = 0; % if betas should be estimated after excluding RT as a regressor but regressing RTs separately

% USER-BASED PATH
currentDir = cd; % current directory
reqPath = 'Perceptual_unc_aug_task_pupil-main'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end
preds_all = readtable(strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx')); % get behavioral predictors
preds_all.pe_condiff = abs(preds_all.pe) .* preds_all.con_diff;
regress_rt = 0; % remove RT effects

%% RUN MAIN MODEL (Figure 4) - done

num_bins = 1;
bins_array = num_bins;
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
num_vars = 7; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
% save_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline + trial specific baseline/main";
% pupil_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial"; % directory to get preprocessed data

perm_save = "perm_pe_condiff";
betas_save = "pe_condiff";
residuals_save = "pe_condiff_residuals";
predicted_save = "pe_condiff_predicted";
binned = 0; % whether binned regression approach is to be used

behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
xgaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze'); 
ygaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze'); 
base_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
mkdir(save_dir);

[betas_struct,perm,residuals,predicted_all] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins_array, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);
safe_saveall(strcat(save_dir, filesep,predicted_save,".mat"), predicted_all);
safe_saveall(strcat(save_dir, filesep,residuals_save,".mat"), residuals);

%% RUN BINNED REGRESSION APPROACH (Figure 3c) - done

bins_array = [1:2]; % number of bins
num_bins = 2;
bins = prctile(preds_all.con_diff,0:50:100); % bin edges
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + rt';
num_vars = 5; % number of predictor vars
two_tailed = 1; % apply two-tailed permutation test
% pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
% save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
save_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\regression\only high pass filter used\main";
pupil_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\pupil signal\only high pass filter used\fb"; % directory to get preprocessed data

mkdir(save_dir)
perm_save = "perm_pe_condiff2bins";
betas_save = "pe_condiff2bins";
binned = 1;

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

%% RUN REGRESSED RT MODEL (Figure S8) - done

num_bins = 1;
bins_array = num_bins;
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + zsc_condiff + pe:zsc_condiff + rt';
num_vars = 7; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation tesT
pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
perm_save = "perm_pe_condiff_regressedRT";
betas_save = "pe_condiff_regressedRT";
binned = 0; % whether binned regression approach is to be used
regress_rt = 1; % regress RT effects

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

%% RUN MODEL WITH BASELINE AS REGRESSOR (Figure S7) - done

num_bins = 1;
binned = 0; % whether binned regression approach is to be used
bins = 1;
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + rt + zsc_condiff + pe:zsc_condiff + baseline';
num_vars = 8; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb'); % directory to get preprocessed data
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
perm_save = "perm_pe_condiff_regressedbaseline";
betas_save = "pe_condiff_regressedbaseline";
baseline_mdl = 1; % if betas should be estimated by fitting the model to non-baseline corrected pupil signal
regress_rt = 0;

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

%% RUN MODEL WITH NON-BASELINE CORRECTED SIGNAL - done

num_bins = 1;
binned = 0; % whether binned regression approach is to be used
bins = 1;
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + rt + zsc_condiff + pe:zsc_condiff';
num_vars = 7; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
% pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb'); % directory to get preprocessed data
% save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
pupil_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\pupil signal\Mathot\non-baseline corrected fb";
save_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\regression\Mathot\main";
perm_save = "perm_pe_condiff_tonicSignal";
betas_save = "pe_condiff_tonicSignal";
baseline_mdl = 1; % if betas should be estimated by fitting the model to non-baseline corrected pupil signal
regress_rt = 0;

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

%% RUN BINNED REGRESSION APPROACH (Figure 3c) WITH NON-BASELINE CORRECTED + MATHOT PREPROCESSED - done

bins_array = [1:2]; % number of bins
num_bins = 2;
bins = prctile(preds_all.con_diff,0:50:100); % bin edges
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + rt';
num_vars = 5; % number of predictor vars
two_tailed = 1; % apply two-tailed permutation test
% pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
% save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
save_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/Mathot/main";
pupil_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/pupil signal/Mathot/non-baseline corrected fb";

% mkdir(save_dir)
perm_save = "perm_pe_condiff2bins_tonicSignal";
betas_save = "pe_condiff2bins_tonicSignal";
binned = 1;

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

%% RUN MODEL WITH NON-BASELINE CORRECTED SIGNAL + NO BASELINE REGRESSOR + PREPRINT PIPELINE - done

num_bins = 1;
binned = 0; % whether binned regression approach is to be used
bins = 1;
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + rt + zsc_condiff + pe:zsc_condiff';
num_vars = 7; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb'); % directory to get preprocessed data
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
perm_save = "perm_pe_condiff_nonBaselineCorrected_noBaselineRegressor";
betas_save = "pe_condiff_tonicSignal_nonBaselineCorrected_noBaselineRegressor";
baseline_mdl = 1; % if betas should be estimated by fitting the model to non-baseline corrected pupil signal
regress_rt = 0;

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

%% MODEL-BASED ANALYSES OF PATCH-LOCKED PUPIL DILATION - done

timewindow = 'patch'; % time-window on which regression needs to be applied
col = 300; % number of samples on which the regression is applied
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf','condition'};% cell array with names of predictor variables

% USER-BASED PATH
currentDir = cd; % current directory
reqPath = 'Perceptual_unc_aug_task_pupil-main'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end
preds_all = readtable(strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx')); % get behavioral predictors
regress_rt = 0; % remove RT effects

num_bins = 1;
bins_array = num_bins;
model_def = 'pupil ~ xgaze + ygaze  + condition + zsc_condiff';
num_vars = 4; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep,'patch'); % directory to get preprocessed data
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
perm_save = "perm_patch_condiff";
betas_save = "patch_condiff";
binned = 0; % whether binned regression approach is to be used

behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
mkdir(save_dir);

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins_array, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

%% RUN ONLY CONTRAST DIFFERENCE MODEL - done

num_bins = 1;
bins_array = num_bins;
model_def = 'pupil ~ xgaze + ygaze + zsc_condiff + rt';
num_vars = 5; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
% pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
% save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
save_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline/control";
pupil_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial"; % directory to get preprocessed data

perm_save = "perm_condiff_rt";
betas_save = "condiff_rt";
binned = 0; % whether binned regression approach is to be used

behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
xgaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze'); 
ygaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze'); 
base_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
mkdir(save_dir);

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins_array, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);


%% RUN MAIN MODEL (Figure 4) BUT ONLY FOR CORRECT/REWARD TRIALS
% change lines 139-144 in run_pupilRegression. 
% for correct trials, set it as preds.ecoperf
% for reward = 1 trials, set it as preds.correct

num_bins = 1;
bins_array = [0,1];
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
num_vars = 7; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
save_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline/control";
pupil_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial"; % directory to get preprocessed data
preds_all = readtable(strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx')); % get behavioral predictors
% preds_all = preds_all(preds_all.ecoperf == 1,:);

perm_save = "perm_pe_condiff_binnedReward";
betas_save = "pe_condiff_binnedReward";
binned = 0; % whether binned regression approach is to be used
binned_accuracy = 1; 

behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
xgaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze'); 
ygaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze'); 
base_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
mkdir(save_dir);

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins_array, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

%% RUN MAIN MODEL WITHOUT PE X CONDIFF FOR PARTIAL REGRESSION PLOT 

num_bins = 1;
bins_array = num_bins;
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff';
num_vars = 6; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
% pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
% save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
save_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline/supplement";
pupil_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial"; % directory to get preprocessed data

perm_save = "perm_pe_condiff_noInteraction";
betas_save = "pe_condiff_noInteraction";
residuals_save = "pe_condiff_noInteraction_residuals";
binned = 0; % whether binned regression approach is to be used

behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
xgaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze'); 
ygaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze'); 
base_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
mkdir(save_dir);

[betas_struct,perm,residuals] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins_array, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);
safe_saveall(strcat(save_dir, filesep,residuals_save,".mat"), residuals);

%% RUN A MODEL PREDICTING PE X CONDIFF USING ALL OTHER BEHAVIORAL PREDICTORS FOR PARTIAL REGRESSION PLOT 

num_bins = 1;
bins_array = num_bins;
model_def = 'pe_condiff ~ xgaze + ygaze + pe + zsc_up + rt + zsc_condiff';
num_vars = 6; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};% cell array with names of predictor variables
resp_var = 'pe_condiff'; % name of response variable
% pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
% save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
save_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline/supplement";
pupil_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial"; % directory to get preprocessed data

perm_save = "perm_pe_condiff_noPupil";
betas_save = "pe_condiff_noPupil";
residuals_save = "pe_condiff_noPupil_residuals";
binned = 0; % whether binned regression approach is to be used

behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
xgaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze'); 
ygaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze'); 
base_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
mkdir(save_dir);

preds_all.pe_condiff = abs(preds_all.pe) .* preds_all.con_diff;

[betas_struct,perm,residuals] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins_array, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);
safe_saveall(strcat(save_dir, filesep,residuals_save,".mat"), residuals);

%% RUN MAIN MODEL WITH BASIC RL MODEL FITTED PE (Figure 4)

num_bins = 1;
bins_array = num_bins;
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
num_vars = 7; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
% pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
% save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'regression', filesep, 'main');
save_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/regression/preprint pipeline/supplement";
pupil_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/pupil signal/fb full trial"; % directory to get preprocessed data
preds_all = readtable("preprocessed_withRLSigmaSims_sampling.xlsx");
preds_all.pe_condiff = abs(preds_all.pe) .* preds_all.con_diff;
preds_all.pe = preds_all.pe_basicRL;
preds_all.up = preds_all.up_basicRL;

perm_save = "perm_pe_condiff_RLSigma";
betas_save = "pe_condiff_RLSigma";
residuals_save = "pe_condiff__RLSigma_residuals";
binned = 0; % whether binned regression approach is to be used

behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
xgaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze'); 
ygaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze'); 
base_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
mkdir(save_dir);

[betas_struct,perm,residuals] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins_array, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);
safe_saveall(strcat(save_dir, filesep,residuals_save,".mat"), residuals);
