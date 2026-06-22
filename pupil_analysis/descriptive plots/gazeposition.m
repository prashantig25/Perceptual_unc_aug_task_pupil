% gazeposition saves single trial x-gaze and y-gaze data for each
% participant.

% todo: 
% check if we can delete all other cases than "feedback" in get_gazepos (still used after update?)
% check consistency with main branch due to previously inconsistent initialization

clc
clearvars

% INITIALISE VARS and PATHS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
num_subs = length(subj_ids);
pre_duration = 29; % set duration for start of pre-event signal (note: good idea to use some pre-event signal)
time_pupil = 1000; % time duration of the pupil
time_base = 10; % time duration of the base
event_name = 'feedback'; % which event

% SETUP PATHS (common to both pipelines)
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
behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data

% Initialize object instance
PupilDescriptive = PupilDescriptive();
PupilDescriptive.num_sess = num_sess;
PupilDescriptive.subj_ids = subj_ids;
PupilDescriptive.behv_dir = behv_dir;
PupilDescriptive.time_base = time_base;
PupilDescriptive.pre_duration = pre_duration;
PupilDescriptive.base_duration = 9; % todo: put in defaults

%% GAZE BASED ON LINEAR INTERPOLATION

fprintf("\n1. Gaze based on linear interpolation\n")

save_xgaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze linear int'); 
save_ygaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze linear int'); 
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed linear int trials and events added');
PupilDescriptive.preproc_dir = preproc_dir;

dirs = {
    'save_xgaze',  save_xgaze;
    'save_ygaze',  save_ygaze;
    'preproc_dir',  preproc_dir;
};
keywords = {'linearInt', 'linear int', 'linear Int', 'LinearInt'};
checkPathKeywords(dirs, keywords);

% Create directories if they don't exist yet
if ~exist(save_xgaze, 'dir')
    mkdir(save_xgaze);
end

if ~exist(save_ygaze, 'dir')
    mkdir(save_ygaze);
end

% LOOP OVER SUBJECTS
parfor s = 1:num_subs
  
    [xgaze_event, ygaze_event] = PupilDescriptive.runGazePosition(s, time_pupil, event_name);

    % SAVE
    safe_saveall(fullfile(save_xgaze,strcat(subj_ids{s},'.mat')),xgaze_event)
    safe_saveall(fullfile(save_ygaze,strcat(subj_ids{s},'.mat')),ygaze_event)
end

%% GAZE BASED ON CUBIC SPLINE INTERPOLATION

fprintf("\n2. Gaze based on cubic spline interpolation\n")

save_xgaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze CS'); 
save_ygaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze CS'); 
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed cubic spline new trials and events added');
PupilDescriptive.preproc_dir = preproc_dir;
time_pupil = 1000; % time duration of the pupil
time_base = 10; % time duration of the base

dirs = {
    'save_xgaze',  save_xgaze;
    'save_ygaze',  save_ygaze;
    'preproc_dir', preproc_dir;
};
keywords = {'CS', 'cubic spline'};
checkPathKeywords(dirs, keywords);

% Create directories if they don't exist yet
if ~exist(save_xgaze, 'dir')
    mkdir(save_xgaze);
end

if ~exist(save_ygaze, 'dir')
    mkdir(save_ygaze);
end

% LOOP OVER SUBJECTS
parfor s = 1:num_subs

    [xgaze_event, ygaze_event] = PupilDescriptive.runGazePosition(s, time_pupil, event_name);

    % SAVE
    safe_saveall(fullfile(save_xgaze,strcat(subj_ids{s},'.mat')),xgaze_event)
    safe_saveall(fullfile(save_ygaze,strcat(subj_ids{s},'.mat')),ygaze_event)
end

%% GAZE BASED ON DECONVOLUTION

fprintf("\n3. Gaze based on deconvolution\n")

% Todo: also here - ensure consistent folder name x and y after refactoring
save_xgaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze deconv'); 
save_ygaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze deconv'); 
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, ...
    'GB data two pipelines', filesep, 'pupil', filesep, ...
    'preprocessing', filesep, 'alternate pipeline', filesep, ...
    'preprocessed trials and events added deconv');
PupilDescriptive.preproc_dir = preproc_dir;
% behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
time_pupil = 1000; % time duration of the pupil
time_base = 10; % time duration of the base

dirs = {
    'save_xgaze',  save_xgaze;
    'save_ygaze',  save_ygaze;
    'preproc_dir', preproc_dir;
};
keywords = {'deconv', 'deconvolution'};
checkPathKeywords(dirs, keywords);

% Create directories if they don't exist yet
if ~exist(save_xgaze, 'dir')
    mkdir(save_xgaze);
end

if ~exist(save_ygaze, 'dir')
    mkdir(save_ygaze);
end

% LOOP OVER SUBJECTS
parfor s = 1:num_subs

    [xgaze_event, ygaze_event] = PupilDescriptive.runGazePosition(s, time_pupil, event_name);

    % SAVE
    safe_saveall(fullfile(save_xgaze,strcat(subj_ids{s},'.mat')),xgaze_event) 
    safe_saveall(fullfile(save_ygaze,strcat(subj_ids{s},'.mat')),ygaze_event)
end

%% GAZE BASED ON LINEAR INTERPOLATION IN THE PATCH PHASE

fprintf("\n1. Gaze based on linear interpolation (patch phase)\n")

save_xgaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze linear int patch'); 
save_ygaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze linear int patch'); 
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed linear int trials and events added');
PupilDescriptive.preproc_dir = preproc_dir;

dirs = {
    'save_xgaze',  save_xgaze;
    'save_ygaze',  save_ygaze;
    'preproc_dir',  preproc_dir;
};
keywords = {'linearInt', 'linear int', 'linear Int', 'LinearInt'};
checkPathKeywords(dirs, keywords);

% Create directories if they don't exist yet
if ~exist(save_xgaze, 'dir')
    mkdir(save_xgaze);
end

if ~exist(save_ygaze, 'dir')
    mkdir(save_ygaze);
end

time_pupil = 300; % time duration of the pupil
event_name = 'choice'; % which event
pre_duration = 29; % set duration for start of pre-event signal (note: good idea to use some pre-event signal)

% LOOP OVER SUBJECTS
parfor s = 1:num_subs
  
    [xgaze_event, ygaze_event] = PupilDescriptive.runGazePosition(s, time_pupil, event_name);

    % SAVE
    safe_saveall(fullfile(save_xgaze,strcat(subj_ids{s},'.mat')),xgaze_event)
    safe_saveall(fullfile(save_ygaze,strcat(subj_ids{s},'.mat')),ygaze_event)
end
