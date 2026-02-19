% get_pupilsignal saves single-trial pupil response for feedback and other
% specific events using both main and alternate pipelines

clc
clearvars

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
regress_rt = 0; % regress RT from pupil phasic signal

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

%% LINEAR INTERPOLATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed linear int trials and events added');

%% 1. FB-LOCKED PUPIL SIGNAL - TRIAL SPECIFIC BASELINE

time_pupil = 1000;
time_base = 10;
event_name = 'feedback';
base = 1;
base_trialspecific = 1;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb full trial linear int');
save_sliderOnset = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'slider onset');
mkdir(save_dir);
mkdir(save_sliderOnset);
main = 1; % running analyses based on the main pipeline

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, sliderOnset] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
    safe_saveall(strcat(save_sliderOnset, filesep, subj_ids{s}, '.mat'), sliderOnset)
end

%% 2. FB-LOCKED PUPIL SIGNAL - EVENT SPECIFIC BASELINE

base_trialspecific = 0;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb Mathot 2023 linear int');
mkdir(save_dir);

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 3. FB-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED

base = 0;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'non-baseline corrected fb linearInt');
mkdir(save_dir);

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 4. PATCH-LOCKED PUPIL SIGNAL

time_pupil = 300;
time_base = 10;
event_name = 'choice';
base = 1;
base_trialspecific = 0;
main = 1;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch linear int');
mkdir(save_dir);

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 5. PATCH-LOCKED PUPIL SIGNAL - NON BASELINE CORRECTED

time_pupil = 300;
time_base = 10;
event_name = 'choice';
base = 0;
base_trialspecific = 0;
main = 1;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'patch non-baseline corrected linear int');
mkdir(save_dir);

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 6. RESPONSE-LOCKED PUPIL SIGNAL

time_pupil = 230;
time_base = 10;
event_name = 'response';
base_trialspecific = 1;
main = 1;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp linear int');
mkdir(save_dir);

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 7. RESPONSE-LOCKED PUPIL SIGNAL - NON BASELINE CORRECTED

time_pupil = 230;
time_base = 10;
event_name = 'response';
base_trialspecific = 1;
main = 1;
base = 0;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'resp non-baseline corrected linear int');
mkdir(save_dir);

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% CUBIC-SPLINE INTERPOLATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed cubic spline new trials and events added');

%% 1. FB-LOCKED PUPIL SIGNAL - EVENT SPECIFIC BASELINE

base_trialspecific = 0;

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb Mathot 2023 cubic spline new');
mkdir(save_dir);

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 2. FB-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED

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
time_base = 10;
event_name = 'feedback';
base = 1;
base_trialspecific = 0;
main = 0;

% ONLY DIFFERENCE: Use alternate preprocessing directory
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'preprocessing', filesep, 'alternate pipeline', ...
    filesep, 'preprocessed trials and events added');

%% 7. FB-LOCKED PUPIL SIGNAL - EVENT SPECIFIC BASELINE (DECONVOLUTION PIPELINE)

save_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', ...
    filesep, 'pupil', filesep, 'alternate pipeline', filesep, 'pupil signal', filesep, 'fb');
mkdir(save_dir);

for s = 1:num_subs
    for ss = 1:num_sess(s)
        [pupil, ~] = run_PupilSignal(num_sess, subj_ids, behv_dir, ...
            preproc_dir, regress_rt, s, ss, time_pupil, time_base, event_name, ...
            pre_duration, base_duration, base, base_trialspecific, main);
    end
    safe_saveall(strcat(save_dir, filesep, subj_ids{s}, '.mat'), pupil)
end

%% 3. FB-LOCKED PUPIL SIGNAL - NON-BASELINE CORRECTED (DECONVOLUTION PIPELINE)

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