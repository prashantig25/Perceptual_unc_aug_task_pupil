% get_pupilsignal saves single-trial pupil response for feedback.

clc
clearvars

% INITIALISE VARS and PATHS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
num_subs = length(subj_ids); % number of subjects
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

% save_dir = strcat(desiredPath, filesep,'NatCommns Revisions', filesep, 'Reviewer 2', filesep, 'pupil', filesep, 'pupil signal', filesep, 'only high pass filter used', filesep, 'fb full trial'); 
save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb full trial'); 
save_sliderOnset = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'slider onset'); 
% preproc_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\preprocessing\only high pass filtering used and trials events added";
preproc_dir = strcat(desiredPath,filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'preprocessed', filesep, 'peak corrected after trials'); % directory to get preprocessed data
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

%% FB-LOCKED PUPIL SIGNAL CORRECTED WITH EVENT SPECIFIC BASELINE

base_trialspecific = 0; % event specific baseline
% save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb'); 
save_dir = strcat(desiredPath, filesep,'NatCommns Revisions', filesep, 'Reviewer 2', filesep, 'pupil', filesep, 'pupil signal', filesep, 'only high pass filter used', filesep, 'fb'); 
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
% save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb'); 
save_dir = strcat(desiredPath, filesep,'NatCommns Revisions', filesep, 'Reviewer 2', filesep, 'pupil', filesep, 'pupil signal', filesep, 'only high pass filter used', filesep, 'non-baseline corrected fb'); 
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
% save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch'); 
save_dir = strcat(desiredPath, filesep,'NatCommns Revisions', filesep, 'Reviewer 2', filesep, 'pupil', filesep, 'pupil signal', filesep, 'Mathot', filesep, 'patch'); 
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
% save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp'); 
save_dir = strcat(desiredPath, filesep,'NatCommns Revisions', filesep, 'Reviewer 2', filesep, 'pupil', filesep, 'pupil signal', filesep, 'Mathot', filesep, 'resp'); 
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

%% BASELINE BEFORE FB

base = 0; % baseline correct signal
regress_rt = 0; % regress RT from pupil phasic signal
time_pupil = 200; % time duration of the pupil 1000
time_base = 10; % time duration of the bases
event_name = 'tonic_prefb'; % which event 'feedback'
pupil_cell = cell(1,num_subs); % empty cell array to store pupil signal
base_trialspecific = 1; % get baseline signal for that trial '1'

% save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
save_dir = strcat(desiredPath, filesep,'NatCommns Revisions', filesep, 'Reviewer 2', filesep, 'pupil', filesep, 'pupil signal', filesep, 'Mathot', filesep, 'baseline before fb'); 
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

%% TRIAL-SPECIFIC BASELINE

base = 0; % baseline correct signal
regress_rt = 0; % regress RT from pupil phasic signal
time_pupil = 10; % time duration of the pupil 1000
time_base = 10; % time duration of the bases
event_name = 'tonic_pretrial'; % which event 'feedback'
pupil_cell = cell(1,num_subs); % empty cell array to store pupil signal
base_trialspecific = 1; % get baseline signal for that trial '1'

% save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
save_dir = strcat(desiredPath, filesep,'NatCommns Revisions', filesep, 'Reviewer 2', filesep, 'pupil', filesep, 'pupil signal', filesep, 'preprint pipeline', filesep, 'baseline before trial'); 
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

%% CALCULATING FB AND PSEUDOBASELINE FOR CORRECTION OF REVERSION TO MEAN

pre_duration = 30; % set duration for start of pre-event signal (note: good idea to use some pre-event signal)
base_duration = 9; % set duration for baseline signal
base = 0; % baseline correct signal
regress_rt = 0; % regress RT from pupil phasic signal
time_pupil = 180; % time duration of the pupil 1000
time_base = 10; % time duration of the bases
event_name = 'reversionToMean'; % which event 'feedback'
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

% save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb full trial'); 
save_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/pupil signal/preprint pipeline/fb for correction to reversion to mean new";
save_pseudobaseline = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/NatCommns Revisions/Reviewer 2/pupil/pupil signal/preprint pipeline/pseudobaseline for correction to reversion to mean new";
preproc_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/pupil/preprocessed/peak corrected after trials"; % directory to get preprocessed data
behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
mkdir(save_dir);
mkdir(save_pseudobaseline);

% FB-LOCKED PUPIL SIGNAL CORRECTED WITH TRIAL SPECIFIC BASELINE

for s = 1:num_subs
    % LOOP OVER SESSIONS
    for ss = 1:num_sess(s)
        [pupil,~,psuedobaseline] = run_PupilSignal(num_sess,subj_ids,behv_dir, ...
            preproc_dir,regress_rt,s,ss,time_pupil,time_base,event_name, ...
            pre_duration,base_duration,base,base_trialspecific);
    end
    safe_saveall(strcat(save_dir,filesep,subj_ids{s},'.mat'),pupil) % safe save
    safe_saveall(strcat(save_pseudobaseline,filesep,subj_ids{s},'.mat'),psuedobaseline) % safe save

    fprintf('Participant number:... %d\n', s);
end

%% FB BASELINE-CORRECTED WITH TRIAL-SPECIFIC BASELINE

% INITIALISE VARS and PATHS
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

save_dir = strcat(desiredPath, filesep,'NatCommns Revisions', filesep, 'Reviewer 2', filesep, 'pupil', filesep, 'pupil signal', filesep, 'only high pass filter used', filesep, 'fb full trial'); 
% save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb full trial'); 
save_sliderOnset = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'slider onset'); 
% preproc_dir = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\NatCommns Revisions\Reviewer 2\pupil\preprocessing\only high pass filtering used and trials events added";
preproc_dir = strcat(desiredPath,filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'preprocessed', filesep, 'peak corrected after trials'); % directory to get preprocessed data
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
