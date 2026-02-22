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
    filesep, 'preprocessed linear int trials and events added');

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

% Save directories
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb Mathot 2023 linearInt');

% Create directories if they don't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

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
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb linearInt');

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
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch linear int');

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

%% 5. PATCH-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED

time_pupil = 300;
% time_base = 10;
event_name = 'choice';
%base = 0;
%base_trialspecific = 0;
baseline = "no correction";
main = 1;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch non-baseline corrected linear int');
%mkdir(save_dir);
% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% for s = 1:num_subs
%     for ss = 1:num_sess(s)
%         [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
%             preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
%             pre_duration, base_duration, base, base_trialspecific, main);
%     end
%     safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
% end

fprintf("\n5. Running patch-locked without baseline\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
              event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 6. RESPONSE-LOCKED PUPIL SIGNAL

time_pupil = 230;
time_base = 10;
event_name = 'response';
base_trialspecific = 1;
main = 1;

% Trial-specific baseline
baseline = "trialspecific";

% Save directory
save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp linear int');

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Cycle over subjects
fprintf("\n6. Running response-locked with trial-specific baseline\n")
for s = 1:num_subs
    [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
               event_name, baseline, main);
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 7. RESPONSE-LOCKED PUPIL SIGNAL - NON BASELINE CORRECTED

time_pupil = 230;
time_base = 10;
event_name = 'response';
base_trialspecific = 1;
main = 1;
base = 0;
baseline = "no correction";

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp non-baseline corrected linear int');
%mkdir(save_dir);

% Create directory if it doesn't exist yet
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

fprintf("\n7. Running response-locked without baseline\n")
for s = 1:num_subs
    %for ss = 1:num_sess(s)
        % [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
        %     preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
        %     pre_duration, base_duration, base, base_trialspecific, main);
        [pupil, ~] = PupilDescriptive.run_PupilSignal(s, time_pupil,...
                event_name, baseline, main);
    %end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% CUBIC-SPLINE INTERPOLATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed cubic spline new trials and events added');

%% 1. FB-LOCKED PUPIL SIGNAL - EVENT SPECIFIC BASELINE

% not working for me

base_trialspecific = 0;
base = 1;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb Mathot 2023 cubic spline new');
mkdir(save_dir);
regress_rt = 0;

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 2. FB-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED

% not working

base = 0;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb cubic spline new');
mkdir(save_dir);

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end


%% ========================================================================
%  ALTERNATE PIPELINE PROCESSING - Deconvolution based
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

%% 3. FB-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED (DECONVOLUTION PIPELINE)

% no data available for this yet
base = 0;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'non-baseline corrected fb');
mkdir(save_dir);

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end