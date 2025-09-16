% fullTrial saves pupil signal from different events for the entire trial.

clc
clearvars

% INITIALIZE VARS
subj_ids = importdata("subj_ids.mat");
snum_subjs = length(subj_ids);
num_break = 30; % how long should the pupil signal be broken
col_patch = 100; % how long should the patch-related pupil signal
col_fb = 300; % how long should the patch-related pupil signal
total = 630; % how long should the entire trial be
trial_all = NaN(num_subjs,total);

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

% save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'descriptive'); 
save_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\descriptive\Mathot";
fb_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\pupil signal\Mathot\fb full trial"; % directory to get preprocessed data
patch_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\pupil signal\Mathot\patch"; % directory to get preprocessed data
resp_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\pupil signal\Mathot\resp"; % directory to get preprocessed data
% fb_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb full trial'); % directory to get preprocessed data
% patch_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch'); % directory to get preprocessed data
% resp_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp'); % directory to get preprocessed data
mkdir(save_dir);

% LOOP OVER SUBJECTS
for i = 1:num_subjs

    % IMPORT EVENT-RELATED DATA
    filename = strcat(patch_dir,'\',subj_ids{i},'.mat');
    pupil = importdata(filename); patch = pupil(:,1:col_patch);

    filename = strcat(resp_dir,'\',subj_ids{i},'.mat');
    pupil = importdata(filename); resp = pupil;

    filename = strcat(fb_dir,'\',subj_ids{i},'.mat');
    pupil = importdata(filename); fb = pupil(:,1:col_fb);

    % INITIALIZE ARRAY FOR TIME POINT
    patch_tp = repelem(1,1,size(patch,2));
    resp_tp = [zeros(1,num_break),repelem(2,1,size(resp,2)-num_break)];
    fb_tp = [zeros(1,num_break),repelem(3,1,size(fb,2)-num_break)];

    % CONCATANATE
    trial = [patch,resp,fb];
    trial_subj = nanmean(trial,1);
    trial_all(i,:) = trial_subj;
end

% SAVE
safe_saveall(strcat(save_dir,filesep,"full_trial.mat"),trial_all);