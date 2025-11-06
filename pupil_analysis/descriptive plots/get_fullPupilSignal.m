clc
clearvars

% INITIALISE VARS and PATHS
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'}; % subject IDs
num_subs = length(subj_ids); % number of subjects
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions
samp_rate = 100; % sampling rate in Hz after down-sampling
pre_duration = 29; % set duration for start of pre-event signal (note: good idea to use some pre-event signal)
base_duration = 9; % set duration for baseline signal
base = 0; % baseline correct signal
regress_rt = 0; % regress RT from pupil phasic signal
time_pupil = 1000; % time duration of the pupil 1000
time_base = 10; % time duration of the bases
event_name = 'feedback'; % which event 'feedback'
pupil_cell = cell(1,num_subs); % empty cell array to store pupil signal
base_trialspecific = 0; % get baseline signal for that trial '1'

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

save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb (non-base corrected)'); 
used_preprocessed = 0; % if you don't want to preprocess but used pre-processed data then set it to 1
if used_preprocessed == 0
    preproc_dir = strcat(desiredPath,filesep,'data', filesep,'GB data',filesep, 'pupil', filesep, 'preprocessed', filesep, 'after adding events trials'); % directory to get preprocessed data
else
    preproc_dir = strcat(desiredPath,filesep,'data', filesep,'GB data',filesep, 'pupil', filesep, 'preprocessed', filesep, 'already_preprocessed'); % directory to get preprocessed data
end
behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
mkdir(save_dir);

% FB-LOCKED PUPIL SIGNAL CORRECTED WITH TRIAL SPECIFIC BASELINE

for s = 1:num_subs
    % LOOP OVER SESSIONS
    for ss = 1:num_sess(s)
        [pupil,sliderOnset] = run_PupilSignal(num_sess,subj_ids,behv_dir,used_preprocessed, ...
            preproc_dir,regress_rt,s,ss,time_pupil,time_base,event_name, ...
            pre_duration,base_duration,base,base_trialspecific);
    end
    safe_saveall(strcat(save_dir,filesep,subj_ids{s},'.mat'),pupil) % safe save
end