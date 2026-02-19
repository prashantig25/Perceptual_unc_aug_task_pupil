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
%  MAIN PIPELINE PROCESSING
%  ========================================================================

preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed trials and events added');

PupilDescriptive.preproc_dir = preproc_dir;

%% 1. FEEDBACK-LOCKED PUPIL SIGNAL - TRIAL-SPECIFIC BASELINE

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
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb full trial');
save_sliderOnset = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'slider onset');

% Create directories if they don't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

if ~exist(save_sliderOnset, 'dir')
    mkdir(save_sliderOnset);
end

main = 1; % running analyses based on the main pipeline % todo why do we need this?

% Cycle over subjects
fprintf("\n1. Running feedback-locked with trial-specific baseline\n")
for s = 1:num_subs
        [pupil, sliderOnset] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
            event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
    safe_saveall(strcat(save_sliderOnset, filesep, subj_ids{s}, '.mat'), sliderOnset)
end

%% 2. FEEDBACK-LOCKED PUPIL SIGNAL - EVENT-SPECIFIC BASELINE

% The saved files are used for the main regression analysis
% (pupilAnalysis_object.m) 

% Turn off trial-specific baseline
baseline = "event-specific";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb');

% Create directories if they don't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n2. Running feedback-locked with event-specific baseline\n")
for s = 1:num_subs
     [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
             event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 3. FEEDBACK-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED

% The saved files are used for the non-baseline-corrected regression analysis
% (pupilAnalysis_object.m) 

% Turn off baseline correction
baseline = "no correction";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb');

% Create directory if it don't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n3. Running feedback-locked without baseline\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
              event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 4. PATCH-LOCKED PUPIL SIGNAL - EVENT-SPECIFIC BASELINE

% Update attributes for patch-locked analysis
time_pupil = 300; % time window of interest   % todo: why so short?
event_name = 'choice'; % trial phase
main = 1;

% Turn on event-specific baseline correction
baseline = "event-specific";

% Save path
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n4. Running patch-locked with event-specific baseline\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
              event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 5. RESPONSE-LOCKED PUPIL SIGNAL - TRIAL-SPECIFIC BASELINE

% Update attributes for response-locked analysis
time_pupil = 230; % time window of interest   % todo: why so short?
event_name = 'response';  % trial phase
main = 1;

% Trial-specific baseline
baseline = "trial-specific";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n5. Running response-locked with trial-specific baseline\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
               event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

% %% 6. BASELINE BEFORE Feedback - TRIAL-SPECIFIC BASELINE
% 
% time_pupil = 200; % time window of interest   % todo: why so short?
% %time_base = 10;
% event_name = 'tonic_prefb'; % trial phase
% base = 0; % no general... wait, is this possible? it currently would just not take any baseline
% base_trialspecific = 1; % but trial-specific baseline
% 
% % Save directory
% save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
%     filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb');
% 
% % Create directory if it don't exist yet
% if ~exist(save_dir, 'dir')
%     mkdir(save_dir);
% end
% 
% % Cycle over subjects
% fprintf("\n6. Running tonic before feedback with trial-specific baseline\n")
% for s = 1:num_subs
%     [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
%                event_name, base, base_trialspecific, main);
%     safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), nanmean(pupil, 2))
% end

%% ========================================================================
%  ALTERNATE PIPELINE PROCESSING
%  ========================================================================

% Reset parameters to defaults for alternate pipeline
time_pupil = 1000;
event_name = 'feedback';
base_trialspecific = 0;
main = 0;

% ONLY DIFFERENCE: Use alternate preprocessing directory
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', ...
    filesep, 'preprocessed trials and events added');

%% 7. FEEDBACK-LOCKED PUPIL SIGNAL - EVENT-SPECIFIC BASELINE (ALTERNATE PIPELINE)

% todo: doesn't seem to find pupil_zsc

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'fb');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n7. Running feedback-locked with event-specific baseline and XX alternate XX pipeline\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
               event_name, base_trialspecific, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end