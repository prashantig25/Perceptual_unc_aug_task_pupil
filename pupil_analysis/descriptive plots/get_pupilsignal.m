% get_pupilsignal saves single-trial pupil response for feedback and other
% specific events using both main and alternate pipelines

clc
clearvars

% Todo: is regress_rt used at all?
% where do we used saved "sliderOnset"?
% For each file: indicate which figure/code uses this
% improve the "main" variable

%% ========================================================================
%  SHARED INITIALIZATION - USED BY BOTH PIPELINES
%  ========================================================================

% Load subject information
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
num_subs = length(subj_ids);

% Shared parameters
samp_rate = 100; % sampling rate in Hz after down-sampling
pre_duration = 29; % duration for start of pre-event signal
base_duration = 9; % duration for baseline signal

% Setup user-based path
currentDir = cd;
reqPath = 'Perceptual_unc_aug_task_pupil-main';
pathParts = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

% Shared behavioral data directory
behv_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'behavior', filesep, 'raw data');

% Initialize object instance
PupilDescriptive = PupilDescriptive();
PupilDescriptive.num_sess = num_sess;
PupilDescriptive.subj_ids = subj_ids;
PupilDescriptive.behv_dir = behv_dir;

%% ========================================================================
%  1. MAIN PIPELINE PROCESSING
%  ========================================================================

% Preprocessing directory
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed linear int trials and events added');
PupilDescriptive.preproc_dir = preproc_dir;

% 1.1 FEEDBACK-LOCKED PUPIL SIGNAL - TRIAL-SPECIFIC BASELINE
% -------------------------------------------------------------------------

% Basic regression attributes
time_pupil = 1000; % time window of interest
time_base = 10; % baseline length
event_name = 'feedback'; % trial phase
baseline = "trial-specific"; % "no baseline", "trial-specific", "event-specific"

% Add relevant attributes to object instance
PupilDescriptive.regress_rt = false;
PupilDescriptive.time_base = time_base;
PupilDescriptive.pre_duration = pre_duration;
PupilDescriptive.base_duration = base_duration;

% Save directories
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb full trial linear int');
save_sliderOnset = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'slider onset');

% Create directories if they don't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

if ~exist(save_sliderOnset, 'dir')
    mkdir(save_sliderOnset);
end

% Running analyses based on the main pipeline
main = 1;

% Cycle over subjects
fprintf("\n1.1 Running feedback-locked with trial-specific baseline and linear interpolation\n")
for s = 1:num_subs
    [pupil, sliderOnset] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
    safe_saveall(strcat(save_sliderOnset, filesep, subj_ids{s}, '.mat'), sliderOnset)
end

% 1.2 FEEDBACK-LOCKED PUPIL SIGNAL - EVENT-SPECIFIC BASELINE
% -------------------------------------------------------------------------

% The saved files are used for the main regression analysis
% (pupilAnalysis_object.m)

% Settings
baseline = "event-specific";

% Save directories
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb Mathot 2023 linearInt');

% Create directories if they don't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n1.2 Running feedback-locked with event-specific baseline and linear interpolation\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

% 1.3 FEEDBACK-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED
% -------------------------------------------------------------------------

% The saved files are used for the non-baseline-corrected regression analysis
% (pupilAnalysis_object.m)

% Settings
baseline = "no correction";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb linearInt');

% Create directory if it don't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n1.3 Running feedback-locked without baseline and linear interpolation\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

% 1.4 PATCH-LOCKED PUPIL SIGNAL - EVENT-SPECIFIC BASELINE
% -------------------------------------------------------------------------

% Settings
time_pupil = 300; % time window of interest
event_name = 'choice'; % trial phase

% Turn on event-specific baseline correction
baseline = "event-specific";

% Save path
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch linear int');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n1.4 Running patch-locked with event-specific baseline and linear interpolation\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

% 1.5 PATCH-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED
% -------------------------------------------------------------------------

% Settings
time_pupil = 300;
event_name = 'choice';
baseline = "no correction";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch non-baseline corrected linear int');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n1.5 Running patch-locked without baseline and linear interpolation\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

% 1.6 RESPONSE-LOCKED PUPIL SIGNAL
% -------------------------------------------------------------------------

% Settings
time_pupil = 230;
event_name = 'response';
base_trialspecific = 1;
baseline = "trial-specific";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp linear int');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n1.6 Running response-locked with trial-specific baseline and linear interpolation\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

% 1.7 RESPONSE-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED
% -------------------------------------------------------------------------

% Settings
time_pupil = 230;
event_name = 'response';
baseline = "no correction";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp non-baseline corrected linear int');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n1.7 Running response-locked without baseline and cubic-spline interpolation\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% ========================================================================
%  2. CUBIC-SPLINE INTERPOLATION
%  ========================================================================

% Update preprocessing directory
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed cubic spline new trials and events added');
PupilDescriptive.preproc_dir = preproc_dir;

% 2.1 FEEDBACK-LOCKED PUPIL SIGNAL - EVENT-SPECIFIC BASELINE
% -------------------------------------------------------------------------

% Settings
time_pupil = 1000;
time_base = 10;
event_name = 'feedback';
baseline = "event-specific";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb Mathot 2023 cubic spline new');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n2.1 Running feedback-locked with event-specific baseline and cubic-spline interpolation\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

% 2.2 FEEDBACK-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED
% -------------------------------------------------------------------------

% Settings
baseline = "no correction";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb cubic spline new');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n2.2 Running feedback-locked without baseline and cubic-spline interpolation\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% ========================================================================
%  3. Deconvolution based
%  ========================================================================

% Update preprocessing directory
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', ...
    filesep, 'preprocessed trials and events added');
PupilDescriptive.preproc_dir = preproc_dir;

% 3.1 FEEDBACK-LOCKED PUPIL SIGNAL - EVENT-SPECIFIC BASELINE
% -------------------------------------------------------------------------

% Settings
time_pupil = 1000;
event_name = 'feedback';
baseline = "event-specific";
main = 0;

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'fb');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n3.1 Running feedback-locked with event-specific baseline and deconvolution\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

% 3.2 FEEDBACK-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED
% -------------------------------------------------------------------------

% Settings
baseline = "no correction";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'non-baseline corrected fb');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n3.2 Running feedback-locked without baseline and deconvolution\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
        event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end