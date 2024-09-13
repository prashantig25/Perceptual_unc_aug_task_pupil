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
currentDir = 'D:\Perceptual_unc_aug_task_pupil-main\Perceptual_unc_aug_task_pupil-main'; % Get the current working directory
used_preprocessed = 0; % if you don't want to preprocess but used pre-processed data then set it to 1. this does not work currently. 
% need to fix a few bugs but will work if it is set to 0 with preprocessing done before that.
if used_preprocessed == 0
    preproc_dir = strcat(currentDir,filesep,'data', filesep,'GB data',filesep, 'pupil', filesep, 'preprocessed'); % directory to get preprocessed data
    save_dir = strcat(currentDir,filesep,'data', filesep,'GB data',filesep, 'pupil', filesep, 'preprocessed'); 
else
    preproc_dir = strcat(currentDir,filesep,'pupil_dataset', filesep,'pupil_preprocessedBIDS'); % directory to get preprocessed data
    save_dir = strcat(currentDir,filesep,'data', filesep,'GB data',filesep, 'pupil', filesep, 'preprocessed',filesep,'already_preprocessed');
end
behv_dir = strcat(currentDir,filesep,'data', filesep,'GB data',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
mkdir(save_dir);
prev_num_trials = 0; % number of trials from previous blocks 
num_trials_sess = 0; % number of trials for participants with multiple sessions

for s = 11:num_subs
    for ss = 1:num_sess(s)

        % READ ASC FILES
        % ASC FOR EVENTS, BLINKS, SACCADES
        if strcmp(subj_ids(s),'4672') == 1 % only for subj 4672 
            filename_asc = strcat(subj_ids{s},'_','m',num2str(ss),'_red.asc');
        else
            filename_asc = strcat(subj_ids{s},'m',num2str(ss),'.asc'); 
        end
        [asc] = read_eyelink_ascNK_AU(filename_asc); % read ASC file
        data_asc = asc2dat(asc); % convert asc to dat file
        events = data_asc.event; % get events information from the DAT file

        % GET EVENT NAMES AND THEIR TIMESTAMPS
        n = length(events); % length of events
        event_list = cell(n,1); % create an empty cell array to add the events of the task 
        time_stamp = nan(n,1); % create empty array to add the time stamp of the events of the task 
        for i = 1:length(events) 
            eve_spl = events(i,1).value; % extract event values
            eve = strsplit(eve_spl); % split the string to get the timestamp and event name separately
            time_stamp(i) = str2double(eve(2)); % convert to double
            event_list(i) = eve(3); % save the event name
        end       
        events = table(time_stamp,event_list); % create table of time stamp and event name to access during pre-processing and baseline correction
        events.Properties.VariableNames{1} = 'time_stamp'; 
        events.Properties.VariableNames{2} = 'event';
        str2double(events.event);
        
        % ADD ALL THE EVENTS RELEVANT FOR THE TASK (task_events should all 
        % relevant events for that particular task version don't forget to update it)
        task_events = ["trial_start","patches_start","instructed_delay_start",...
            "response_start","delay_start","feedback_start","delay1_start","slider_start"];       
        event_per_trial = length(task_events); % number of events in a trial

        % REMOVE ALL EVENT NAMES THAT DON'T MATCH THE ONES THAT ARE
        % RELEVANT TO THE TASK (i.e. task_events)
        h = height(events);
        not_event = zeros(h,1);
        for i = 1:h
            k = 1;
            if sum(strcmp(events.event(i),task_events)) > 0
                not_event(i,:) = 1;
            else
                not_event(i,:) = 0;
            end
        end
        events = events(not_event == 1,:); % only retain events which are part of task_events

        % GET BEHAVIOURAL DATA FOR THE PARTICIPANT
        filename_behv = strcat(subj_ids{s},'_','main',num2str(ss),'.xlsx');
        behv_data = readtable(strcat(behv_dir,'\',filename_behv)); % import from participant's behavioural file
        condition = behv_data.condition; % task conditions
        num_trial = length(condition); % number of trials in one run of the main task

        % GET PUPIL DATA FROM DIFFERENT SESSIONS
        if used_preprocessed == 0
            data = []; 
            filename = strcat(preproc_dir,'\',subj_ids{s},'_main',num2str(ss),'.xlsx');
            data_run = readtable(filename);
            [data] = events_trialnums(data,events,event_per_trial,num_trial);
        else
            if subj_ids{s} == "0806"
                filename = strcat(preproc_dir,filesep,"sub_806",filesep,"pupil_preprocessed",filesep,"sub_806.tsv");
                data = readtable(filename,"FileType","text",'Delimiter', '\t');
            else
                filename = strcat(preproc_dir,filesep,"sub_",subj_ids{s},filesep,"pupil_preprocessed",filesep,"sub_",subj_ids{s},".tsv");
                data = readtable(filename,"FileType","text",'Delimiter', '\t');
            end
            data.time_stamp = data.timestamp;
            [data] = events_trialnums(data,events,event_per_trial,num_trial);
        end

        % ADJUST TRIAL NUMBERS FOR PARTICIPANTS WITH MULTIPLE RECORDING
        % SESSIONS
        if ss == 1
            data.trial = data.trial_num;
        else
            prev_num_trials = prev_num_trials + num_trials_sess;
            data.trial = data.trial_num + prev_num_trials;
        end
        num_trials_sess = data.trial_num(end); % number of trials in previous block
        
        % SAVE FILE
        if used_preprocessed == 1
            filename = strcat(save_dir,'\',subj_ids{s},'_main','.xlsx');
        else
            filename = strcat(save_dir,'\',subj_ids{s},'_main',num2str(ss),'.xlsx');
        end
        safe_saveall(filename,data);
        prev_num_trials = 0;
    end
end