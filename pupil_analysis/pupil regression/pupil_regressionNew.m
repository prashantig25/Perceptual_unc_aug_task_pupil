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
pred_vars = {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf'};% cell array with names of predictor variables
resp_var = 'pupil'; % name of response variable
cat_vars = {'condition','reward','ecoperf'}; % cell array with names of categorical variables
binned_accuracy = 0; % whether binned regression approach is to be used for separate bins of correct and incorrect trials
main_mdl = 1; % if the betas should be estimated for the main model (Fig. 3 in MS)
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
preds_all = readtable(strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx')); % get behavioral predictors
regress_rt = 0; % remove RT effects

% RUN MAIN MODEL (Figure 4)

num_bins = 1;
bins_array = num_bins;
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up + pe:zsc_condiff + rt + zsc_condiff';
num_vars = 7; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'pupil', filesep, 'regression', filesep, 'main');
perm_save = "perm_pe_condiff";
betas_save = "pe_condiff";
binned = 0; % whether binned regression approach is to be used

behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
xgaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze'); 
ygaze_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze'); 
base_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
mkdir(save_dir);

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins_array, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

% RUN BINNED REGRESSION APPROACH (Figure 3c)

bins_array = [1:2]; % number of bins
num_bins = 2;
bins = prctile(preds_all.con_diff,0:50:100); % bin edges
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + rt';
num_vars = 5; % number of predictor vars
two_tailed = 1; % apply two-tailed permutation test
pupil_dir = strcat('data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'pupil', filesep, 'regression', filesep, 'binned');
perm_save = "perm_pe_condiff2bins";
betas_save = "pe_condiff2bins";
binned = 1;

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

% RUN REGRESSED RT MODEL (Figure S8)

num_bins = 1;
bins_array = num_bins;
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + zsc_condiff + pe:zsc_condiff + rt';
num_vars = 7; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation tesT
pupil_dir = strcat('data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep,'fb'); % directory to get preprocessed data
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'pupil', filesep, 'regression', filesep, 'main');
perm_save = "perm_pe_condiff_regressedRT";
betas_save = "pe_condiff_regressedRT";
binned = 0; % whether binned regression approach is to be used

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);

% RUN MODEL WITH BASELINE AS REGRESSOR (Figure S7)

num_bins = 1;
model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + rt + zsc_condiff + pe:zsc_condiff + baseline';
num_vars = 8; % number of predictor vars
two_tailed = 0; % apply two-tailed permutation test
pupil_dir = strcat('data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep,'non baseline corrected', filesep, 'fb'); % directory to get preprocessed data
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'pupil', filesep, 'regression', filesep, 'main');
perm_save = "perm_pe_condiff_regressedbaseline";
betas_save = "pe_condiff_regressedbaseline";
baseline_mdl = 1; % if betas should be estimated by fitting the model to non-baseline corrected pupil signal

[betas_struct,perm] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins, binned_accuracy, two_tailed, save_dir, betas_save, perm_save ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var);
safe_saveall(strcat(save_dir, filesep, betas_save,".mat"), betas_struct);
safe_saveall(strcat(save_dir, filesep,perm_save,".mat"), perm);