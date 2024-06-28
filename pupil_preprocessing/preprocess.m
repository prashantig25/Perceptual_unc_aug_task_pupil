% clearvars
% clc

% NOTES:
% 4672 preprocessed with reduced trials. Had to remove 1st trial in 5th
% block from both behavioural and pupil file because first trials in the
% block has no pupil data because recording started late. Renamed to file
% with _red and extension changed from .DAT to .TXT. Change that in the
% filename string.

% IMPORT DAT, ASC, AND BEHAVIOURAL FILES FOR PUPIL, TASK, AND EVENTS DATA

% INITIALISE VARS AND DON'T CHANGE SUBJECT IDs and NUM_SESS
subj_ids = {'ec_00001','901','620','3886'}; % {'379','4057','4813','601','3319','129','4684'};
num_sess = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions
plot_steps = 1; % if you want to visualise data for each preprocessing step
sampling_rate = 1000; % original sampling rate
freqs = [0.01 10]; % filter cutoffs [lo hi]
downsample_rate = 100; % sampling rate after down sampling
event_names = {'blinks','saccades'}; % event names
deconv_time = [0,6]; % deconvolution time window [lo hi]

% PATH STUFF (update accordingly)
laptop = 1;
if laptop == 1
    savedir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_data\preprocessed\pupil';
    behv_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_data\pre_preprocessed\behv\with_missed_trials';
else
    savedir = 'C:\Users\prashantig25\Nextcloud\Thesis_laptop\Semester 6\pupil_data\preprocessed\pupil';
    behv_dir = 'C:\Users\prashantig25\Nextcloud\Thesis_laptop\Semester 6\pupil_data\pre_preprocessed\behv\with_missed_trials';
end

% Run preprocessing based on common function
preprocessing_fun(subj_ids, num_sess, plot_steps, sampling_rate, freqs, downsample_rate, event_names, deconv_time)
