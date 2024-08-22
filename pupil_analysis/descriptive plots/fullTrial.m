clc
clearvars

% INITIALIZE VARS
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'};
num_subjs = length(subj_ids);
num_break = 30; % how long should the pupil signal be broken
col_patch = 100; % how long should the patch-related pupil signal
col_fb = 300; % how long should the patch-related pupil signal
total = 630; % how long should the entire trial be
trial_all = NaN(num_subjs,total);

% PATH STUFF
currentDir = pwd; % Get the current working directory
save_dir = strcat('data', filesep,'GB data',filesep, 'pupil', filesep, 'descriptive'); 
fb_dir = strcat('data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb'); % directory to get preprocessed data
patch_dir = strcat('data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch'); % directory to get preprocessed data
resp_dir = strcat('data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp'); % directory to get preprocessed data
mkdir(save_dir);

% LOOP OVER SUBJECTS
for i = 1:num_subjs

    filename = strcat(patch_dir,'\',subj_ids{i},'.mat');
    importdata(filename); patch = pupil(:,1:col_patch);

    filename = strcat(resp_dir,'\',subj_ids{i},'.mat');
    importdata(filename); resp = pupil;

    filename = strcat(fb_dir,'\',subj_ids{i},'.mat');
    importdata(filename); fb = pupil(:,1:col_fb);

    patch_tp = repelem(1,1,size(patch,2));
    resp_tp = [zeros(1,num_break),repelem(2,1,size(resp,2)-num_break)];
    fb_tp = [zeros(1,num_break),repelem(3,1,size(fb,2)-num_break)];

    trial = [patch,resp,fb];
    trial_subj = nanmean(trial,1);
    trial_all(i,:) = trial_subj;
end

% SAVE
safe_saveall(strcat(save_dir,filesep,"full_trial.mat"),trial_all);