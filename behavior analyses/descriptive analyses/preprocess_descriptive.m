%% GET RELEVANT BEHAVIOURAL DATA FROM PSYCHOPY FILES
clc
clearvars

%%%% DON'T CHANGE SUBJECT IDs and NUM_SESS
% INITIALISE VARS
subj_ids = {'806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813',...
    '601','3319','129','4684','3886','620','901','900'};
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
total_blocks = 8; % total number of blocks in the task
task_name = '_main'; % task name
format = '.xlsx'; % format to save preprocessed files

% CHANGE DIRECTORY ACCORDINGLY
currentDir = 'D:\Perceptual_unc_aug_task_pupil-main\Perceptual_unc_aug_task_pupil-main'; % Get the current working directory
behv_dir = strcat('pupil_dataset',filesep,'behavior_BIDS');
save_dir = strcat(currentDir, filesep, 'data', filesep,'GB data',filesep, 'behavior', filesep, 'preprocessed'); 
mkdir(save_dir);

num_subjs = length(subj_ids); % number of subjects
data_subj = []; % empty array for each subjects data
data_all = []; % empty array for all participants' data
num_trials = 20; % number of trials

% LOOP OVER ALL SUBJECTS
for n = 1:num_subjs
    
    missed_trials_all = [];
    sess_trials = [];

    % LOOP OVER NUMBER OF SESSIONS FOR THAT PARTICIPANT
    tsv_file = fullfile(currentDir, filesep, behv_dir,strcat('sub_',num2str(subj_ids{n})),'behav', ...
        strcat('sub_',num2str(subj_ids{n}),".tsv")); % path and file name for TSV file
    data_subj = readtable(tsv_file,"FileType","text",'Delimiter', '\t'); % read file
  
    % SAVE FILE
    save_file = strcat(save_dir,filesep,num2str(subj_ids{n}),'.xlsx');
    safe_saveall(save_file,data_subj);
    data_all = [data_all; data_subj];
    data_subj = [];
end

% SAVE FILE
save_file = strcat(save_dir,filesep,'pupilbehv_all.xlsx');
safe_saveall(save_file,data_all);