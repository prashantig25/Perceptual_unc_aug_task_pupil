% get_basebeforeFB saves tonic pupil response before feedback.

clc
clearvars

% INITIALISE VARS and PATHS
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'}; % subject IDs
num_subs = length(subj_ids); % number of subjects
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions
samp_rate = 100; % sampling rate in Hz after down-sampling
pre_duration = 29; % set duration for start of pre-event signal (note: good idea to use some pre-event signal)
base_duration = 9; % set duration for baseline signal
regress_rt = 0; % regress RT from pupil phasic signal
time_pupil = 200; % time duration of the pupil
time_base = 10; % time duration of the base
event_name = 'tonic_prefb'; % which event
pupil_cell = cell(1,num_subs); % empty cell array to store pupil signal
base_trialspecific = 0; % get baseline signal for that trial

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

save_dir = strcat(desiredPath, filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'baseline before fb'); 
used_preprocessed = 0; % if you don't want to preprocess but used pre-processed data then set it to 1
if used_preprocessed == 0
    preproc_dir = strcat(desiredPath,filesep,'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'preprocessed', filesep, 'peak correctedNEW after trials'); % directory to get preprocessed data
else
    preproc_dir = strcat(desiredPath,filesep,'data', filesep,'GB data',filesep, 'pupil', filesep, 'preprocessed', filesep, 'already_preprocessed'); % directory to get preprocessed data
end
behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
mkdir(save_dir);

% LOOP OVER SUBJECTS
for s = 1:num_subs

    % LOOP OVER SESSIONS
    for ss = 1:num_sess(s)

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
        if used_preprocessed == 0
            data = []; 
            for j = 1:num_sess(s)
                filename = strcat(preproc_dir,filesep,subj_ids{s},'_main',num2str(j),'.xlsx');
                data_run = readtable(filename);
                data = [data; data_run];
            end
        else
            filename = strcat(preproc_dir,filesep,subj_ids{s},'_main','.xlsx');
            data = readtable(filename);
        end

        trial_list = unique(data.trial); % number of trials      
        trial_base = trial_list; % check this ??
        n = length(condition);
        missedtrials = ~isnan(behv_data.rt); % missed trials
        behv_data(missedtrials == 0,:) = []; % remove missed trials

        % GET EVENT-LOCKED PUPIL SIGNAL
        pupil_event = NaN(n,time_pupil); % initialise array to store pupil
        base_event = zeros(n,time_base); % initialise array to store baseline pupil
        [pupil_event,base_event]= get_pupil_event(time_pupil,pupil_event,base_event,event_name, ...
            n,data,trial_base,base_trialspecific,pre_duration,base_duration); % get pupil event
        
        % BASELINE CORRECTION
%         base_event_mean = zeros(n,1); % initialise array to store mean of baseline pupil
%         for i = 1:n
%             base_event_mean(i) = mean(base_event(i,:));
%         end
%         base_corrected = base_correction(pupil_event, base_event_mean, time_pupil); % baseline correct
%         if base == 0 % non-baseline corrected pupil
           pupil_cell{1,s} = pupil_event;
           pupil = nanmean(pupil_event,2);
%         else
%            pupil_cell{1,s} = base_corrected;
%            pupil = base_corrected;
%         end
        pupil(missedtrials == 0,:) = []; % remove pupil response of missed trials
        if regress_rt == 1 % regress out RT
            for c = 1:col
                pupil(:,c) = remove_rt_effects(pupil(:,c),log(behv_data.rt));
            end
        end
    end

    safe_saveall(strcat(save_dir,filesep,subj_ids{s},'.mat'),pupil) % safe save
end