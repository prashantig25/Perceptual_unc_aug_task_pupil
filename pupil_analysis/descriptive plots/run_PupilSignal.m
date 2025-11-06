function [pupil,sliderOnset,pupil_pseudobaseline] = run_PupilSignal(num_sess,subj_ids,behv_dir, ...
    preproc_dir,regress_rt,s,ss,time_pupil,time_base,event_name,pre_duration, ...
    base_duration,base,base_trialspecific,main)
% function run_PupilSignal gets event-specific pupil signal for each of the
% specified events.
% INPUTS:
%   num_sess: number of sessions for each participant
%   subj_ids: cell array with subject IDs
%   behv_dir: directory to get behavioral data
%   preprocessed data is to be used (1)
%   preproc_dir: directory to get preprocessed data
%   regress_rt: whether RT to be regressed from pupil signal
%   s: subject number
%   ss: session number
%   time_pupil: duration of pupil signal
%   time_base: duration of baseline
%   event_name: event name for which signal is being extracted
%   pre_duration: pre-event duration
%   base_duration: duration of baseline
%   base: if signal to be baseline corrected or now
%   base_trialspecific: if trial-specific or event-specific baseline to be
%   used
%   main: if using preprocessed signal from the main analysis
%
% OUPUT:
%   pupil: pupil signal

% GET BEHAVIORAL DATA
filename_behv = strcat(subj_ids{s},'_','main',num2str(ss),'.xlsx');
if strcmp(subj_ids{s},'4672') == 1
    filename_behv = strcat(subj_ids{s},'_','main',num2str(ss),'_red.xlsx');
end
behv_data = [];
data_run = [];
for j = 1:num_sess(s)
    filename = strcat(behv_dir,filesep,subj_ids{s},'_','main',num2str(j),'.xlsx');
    if strcmp(subj_ids{s},'4672') == 1
        filename = strcat(behv_dir,filesep,subj_ids{s},'_','main',num2str(j),'_red.xlsx');
    end
    data_run = readtable(filename);
    rt = table(data_run.choice_rt,'VariableNames',{'rt'}); % add RT data
    data_run = [data_run(:,[1:16]),rt];
    behv_data = [behv_data; data_run];
end
condition = behv_data.condition; % task conditions

% GET PUPIL DATA FROM DIFFERENT SESSIONS
data = [];
for j = 1:num_sess(s)
    filename = strcat(preproc_dir,filesep,subj_ids{s},'_main',num2str(j),'.xlsx');
    data_run = readtable(filename);
    data = [data; data_run];
end

% data.pupil_zsc = data.pupil_cleaned; % remove this if the preprociessing pipeline is not the one from Mathot

trial_list = unique(data.trial); % number of trials
trial_base = trial_list; % check this ??
n = length(condition);
missedtrials = ~isnan(behv_data.rt); % missed trials
behv_data(missedtrials == 0,:) = []; % remove missed trials
if main == 1
    data.pupil_zsc = data.pupil_cleaned;
end

% GET EVENT-LOCKED PUPIL SIGNAL
pupil_event = NaN(n,time_pupil); % initialise array to store pupil
pupil_pseudobaseline = NaN(n,time_pupil); % initialise array to store pupil
base_event = zeros(n,time_base); % initialise array to store baseline pupil
[pupil_event,base_event,sliderOnset,pupil_pseudobaseline]= get_pupil_event(time_pupil,pupil_event,base_event,event_name, ...
    n,data,trial_base,base_trialspecific,pre_duration,base_duration,pupil_pseudobaseline); % get pupil event

% BASELINE CORRECTION
base_event_mean = zeros(n,1); % initialise array to store mean of baseline pupil
for i = 1:n
    base_event_mean(i) = mean(base_event(i,:));
end
base_corrected = base_correction(pupil_event, base_event_mean, time_pupil); % baseline correct
if base == 0 % non-baseline corrected pupil
    pupil_cell{1,s} = pupil_event;
    pupil = pupil_event;
else
    pupil_cell{1,s} = base_corrected;
    pupil = base_corrected;
end
pupil(missedtrials == 0,:) = []; % remove pupil response of missed trials
pupil_pseudobaseline(missedtrials == 0,:) = []; 
if regress_rt == 1 % regress out RT
    for c = 1:col
        pupil(:,c) = remove_rt_effects(pupil(:,c),log(behv_data.rt));
    end
end
