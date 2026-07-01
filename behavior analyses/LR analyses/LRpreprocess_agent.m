% LR_analysis_pupil uses a model-based approach to analysing single-trial
% prediction errors and belief updates.

clc
clearvars 

% INITIALIZE
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
total_blocks = 8; % total number of blocks
num_trials = 25; % number of trials
format = '.xlsx';
num_subjs = length(subj_ids); % number of subjects

% USER-BASED PATH
currentDir = cd; % current directory
pathParts = strsplit(currentDir, filesep);
reqPath = 'GBSliderPupil_NatComms'; % to which directory one must save in
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
% Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'behavior', filesep, 'descriptive');
mkdir(save_dir);

% SCRIPT TO RUN MODEL BASED ANALYSIS OF LEARNING RATES
preprocess_obj = preprocess_LR(); % initialise object with all required variables and functions
preprocess_obj.filename = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'behavior', filesep, 'LR analyses', filesep, 'data_agentpupil0.06.txt'); % specify path to get the datasetpreprocess_obj.online = 0; % not running preprocessing for participants' data
preprocess_obj.get_data();

% ADD SIMULATION IDs
simulation_ids = [1:300];
ids = [];
for s = simulation_ids
    ids = [ids; repelem(s,100,1)];
end
all_ids = [repmat(ids,1,1);repmat(ids,1,1)];

preprocess_obj.data.ID = all_ids; % add simulation IDs

% step 1
preprocess_obj.flip_mu(); % compute reported contingency parameter, after correcting for congruence
preprocess_obj.compute_mu(); % compute reported contingency parameter, after correcting for congruence

% step 2
preprocess_obj.compute_action_dep_rew(); % compute action dependent rewardend

% step 3
preprocess_obj.compute_state_dep_pe(); % compute state dependent PE and UP

% COMPUTE VARS FOR LINEAR FIT
preprocess_obj.compute_ru(); % reward uncertainty
preprocess_obj.compute_confirm(); % confirming outcome

% ADD VARIABLES TO THE DATA TABLE
preprocess_obj.add_vars(preprocess_obj.data.ru,'reward_unc');
preprocess_obj.remove_conditions();

% USER-BASED PATH
currentDir = cd; % current directory
reqPath = 'GBSliderPupil_NatComms'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end
behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines', filesep, 'behavior', filesep, 'preprocessed');
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'LR analyses');
mkdir(save_dir);

% SAVE PREPROCESSED FILE
safe_saveall(fullfile(save_dir,'preprocessed_agentpupil0.06.mat'),preprocess_obj.data)
safe_saveall(fullfile(save_dir,'preprocessed_lr_agent_no_zerope0.06.mat').data(preprocess_obj.data.pe ~= 0, :));
