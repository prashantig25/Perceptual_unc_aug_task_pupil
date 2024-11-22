% get_pupilsignal saves single-trial pupil response for feedback.

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
base = 1; % baseline correct signal
regress_rt = 0; % regress RT from pupil phasic signal
time_pupil = 1000; % time duration of the pupil 1000
time_base = 10; % time duration of the bases
event_name = 'feedback'; % which event 'feedback'
pupil_cell = cell(1,num_subs); % empty cell array to store pupil signal
base_trialspecific = 1; % get baseline signal for that trial '1'

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

save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb full trial'); 
save_sliderOnset = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'slider onset'); 
preproc_dir = strcat(desiredPath,filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'preprocessed', filesep, 'peak correctedNEW after trials'); % directory to get preprocessed data
behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
mkdir(save_dir);
mkdir(save_sliderOnset);

% FB-LOCKED PUPIL SIGNAL CORRECTED WITH TRIAL SPECIFIC BASELINE

for s = 1:num_subs
    % LOOP OVER SESSIONS
    for ss = 1:num_sess(s)
        [pupil,sliderOnset] = run_PupilSignal(num_sess,subj_ids,behv_dir, ...
            preproc_dir,regress_rt,s,ss,time_pupil,time_base,event_name, ...
            pre_duration,base_duration,base,base_trialspecific);
    end
    safe_saveall(strcat(save_dir,filesep,subj_ids{s},'.mat'),pupil) % safe save
    safe_saveall(strcat(save_sliderOnset,filesep,subj_ids{s},'.mat'),sliderOnset) % safe save
end

% FB-LOCKED PUPIL SIGNAL CORRECTED WITH EVENT SPECIFIC BASELINE

base_trialspecific = 0; % event specific baseline
save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb'); 
mkdir(save_dir);

% LOOP OVER SUBJECTS
for s = 1:num_subs
    % LOOP OVER SESSIONS
    for ss = 1:num_sess(s)
        [pupil,~] = run_PupilSignal(num_sess,subj_ids,behv_dir, ...
            preproc_dir,regress_rt,s,ss,time_pupil,time_base,event_name, ...
            pre_duration,base_duration,base,base_trialspecific);
    end
    safe_saveall(strcat(save_dir,filesep,subj_ids{s},'.mat'),pupil) % safe save
end

%% FB-LOCKED PUPIL SIGNAL NON-BASELINE CORRECTED

base_trialspecific = 0; % event specific baseline
base = 0; % don't correct for baseline
save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb'); 
mkdir(save_dir);

% LOOP OVER SUBJECTS
for s = [1:num_subs]
    % LOOP OVER SESSIONS
    for ss = 1:num_sess(s)
        [pupil,~] = run_PupilSignal(num_sess,subj_ids,behv_dir, ...
            preproc_dir,regress_rt,s,ss,time_pupil,time_base,event_name, ...
            pre_duration,base_duration,base,base_trialspecific);
    end
    safe_saveall(strcat(save_dir,filesep,subj_ids{s},'.mat'),pupil) % safe save
end

%% PATCH-LOCKED PUPIL SIGNAL

time_pupil = 300; % time duration of the pupil
time_base = 10; % time duration of the base
event_name = 'choice'; % which event
base_trialspecific = 0; % trial/event specific baseline
base = 1;
save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch'); 
mkdir(save_dir);

% LOOP OVER SUBJECTS
for s = [1:num_subs]
    % LOOP OVER SESSIONS
    for ss = 1:num_sess(s)
        [pupil,~] = run_PupilSignal(num_sess,subj_ids,behv_dir, ...
            preproc_dir,regress_rt,s,ss,time_pupil,time_base,event_name, ...
            pre_duration,base_duration,base,base_trialspecific);
    end
    safe_saveall(strcat(save_dir,filesep,subj_ids{s},'.mat'),pupil) % safe save
end

%% RESPONSE-LOCKED PUPIL SIGNAL

time_pupil = 230; % time duration of the pupil
time_base = 10; % time duration of the base
event_name = 'response'; % which event
base_trialspecific = 1; % trial/event specific baseline
save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp'); 
mkdir(save_dir);

% LOOP OVER SUBJECTS
for s = [1:num_subs]
    % LOOP OVER SESSIONS
    for ss = 1:num_sess(s)
        [pupil,~] = run_PupilSignal(num_sess,subj_ids,behv_dir, ...
            preproc_dir,regress_rt,s,ss,time_pupil,time_base,event_name, ...
            pre_duration,base_duration,base,base_trialspecific);
    end
    safe_saveall(strcat(save_dir,filesep,subj_ids{s},'.mat'),pupil) % safe save
end

%%

base = 0; % baseline correct signal
regress_rt = 0; % regress RT from pupil phasic signal
time_pupil = 200; % time duration of the pupil 1000
time_base = 10; % time duration of the bases
event_name = 'tonic_prefb'; % which event 'feedback'
pupil_cell = cell(1,num_subs); % empty cell array to store pupil signal
base_trialspecific = 1; % get baseline signal for that trial '1'

save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
mkdir(save_dir);

% BASELINE BEFORE FB MEAN PUPIL SIGNAL

for s = 1:num_subs
    % LOOP OVER SESSIONS
    for ss = 1:num_sess(s)
        [pupil,sliderOnset] = run_PupilSignal(num_sess,subj_ids,behv_dir, ...
            preproc_dir,regress_rt,s,ss,time_pupil,time_base,event_name, ...
            pre_duration,base_duration,base,base_trialspecific);
    end
    safe_saveall(strcat(save_dir,filesep,subj_ids{s},'.mat'),nanmean(pupil,2)) % safe save
end
