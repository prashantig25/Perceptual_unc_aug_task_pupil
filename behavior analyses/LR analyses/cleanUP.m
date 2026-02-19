% cleanUP cleans the behavioral data before further LR analyses by removing
% trials with no slider response.

clc
clearvars

% INITIALISE VARS (NOTE: DON'T CHANGE SUBJECT IDs and NUM_SESS)
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813',...
    '601','3319','129','4684','3886','620','901','900'};
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of recording sessions
total_blocks = 8; % total number of blocks
num_trials = 20; % number of trials
task_name = '_main'; % file name
format = '.xlsx';
num_subjs = length(subj_ids); % number of subjects
data_subj = []; % empty array for each subjects data
data_all = []; % empty array for all participants' data
num_trials = 20; % number of trials


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
behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected', filesep, 'behavior', filesep, 'preprocessed');
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'LR analyses'); 
mkdir(save_dir)

% LOOP OVER ALL SUBJECTS
for n = 1:num_subjs

    missed_trials_all = [];
    sess_trials = [];

    % LOOP OVER NUMBER OF SESSIONS FOR THAT PARTICIPANT

    filename = strcat(behv_dir,'\',subj_ids{n},format); % filename
    data = readtable(filename); % read file

    % REMOVE MISSED SLIDER TRIALS

    if j ~= 4 % if it is not practice block, delete trials where participant hasn't responded
        missed_trials = []; % initialize array for index of missed trials
        for i = 1:height(data)
            if isnan(data.slider(i,:)) % check if participant has not responded
                missed_trials = [missed_trials;i];
            end
        end
        if num_sess(n) > 1
            if j == 2
                missed_trials_all = [missed_trials_all;missed_trials+sess_trials(1)];
            else
                missed_trials_all = [missed_trials_all;missed_trials];
            end
        end
        data(missed_trials,:) = []; % delete such trials
    end

    % ADD TRIAL NUMBERS FOR EACH BLOCK

    t = 0;
    for i = 1:height(data)
        if t > num_trials - 1
            t = 1;
        else
            t = t + 1;
        end
        data.trial(i) = t;
    end

    data_subj = data;
    data_all = [data_all; data_subj];
    data_subj = [];
end

save_file = strcat(save_dir,'\','pupilbehv_allNEW','.xlsx');
safe_saveall(save_file,data_all);

