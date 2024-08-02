% INITIALISE VARS AND DON'T CHANGE SUBJECT IDs and NUM_SESS
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'}; % subject IDs
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions
plot_steps = 1; % if you want to visualise data for each preprocessing step
sampling_rate = 1000;% original sampling rate
freqs = [0.01 10];% filter cutoffs [lo hi]
downsample_rate = 100; % sampling rate after down sampling
event_names = {'blinks','saccades'}; % event names
deconv_time = [0,6]; % deconvolution time interval

% PATH STUFF (update accordingly)
currentDir = pwd; % Get the current working directory
save_dir = strcat('data', filesep,'GB data',filesep, 'pupil', filesep, 'preprocessed'); 
mkdir(save_dir);

% PREPROCESS
preprocessing_fun(subj_ids, num_sess, plot_steps, sampling_rate, freqs, downsample_rate, event_names, deconv_time, savedir)