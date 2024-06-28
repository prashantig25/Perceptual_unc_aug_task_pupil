% clearvars
% clc

% INITIALISE VARS AND DON'T CHANGE SUBJECT IDs and NUM_SESS
subj_ids = {'ec_00001'};
num_sess = 1; % number of sessions
plot_steps = 1; % if you want to visualise data for each preprocessing step
sampling_rate = 1000; % original sampling rate
freqs = [0.01 10]; % filter cutoffs [lo hi]
downsample_rate = 100; % sampling rate after down sampling
event_names = {'blinks', 'saccades'}; % event names
deconv_time = [0, 6]; % deconvolution time window [lo hi]

savedir = '/home/rasmus/Dropbox/Anträge/Hamburg/pupil/preprocessed';
behv_dir = nan;

% Run preprocessing based on common function
preprocessing_fun(subj_ids, num_sess, plot_steps, sampling_rate, freqs, downsample_rate, event_names, deconv_time, savedir)
