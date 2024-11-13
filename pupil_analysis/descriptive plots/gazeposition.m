% gazeposition saves single trial x-gaze and y-gaze data for each
% participant.

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
base = 1; % baseline correct signal
regress_rt = 0; % regress RT from pupil phasic signal
time_pupil = 1000; % time duration of the pupil
time_base = 10; % time duration of the base
event_name = 'feedback'; % which event
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
save_xgaze = strcat(desiredPath,filesep,'data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze'); 
save_ygaze = strcat(desiredPath,filesep,'data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze'); 
preproc_dir = strcat(desiredPath,filesep,'data', filesep,'GB data',filesep, 'pupil', filesep, 'preprocessed'); % directory to get preprocessed data
behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
mkdir(save_xgaze);
mkdir(save_ygaze);

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
        data = []; 
        for j = 1:num_sess(s)
            filename = strcat(preproc_dir,filesep,subj_ids{s},'_main',num2str(j),'.xlsx');
            data_run = readtable(filename);
            data = [data; data_run];
        end
        trial_list = unique(data.trial); % number of trials      
        trial_base = trial_list; % check this ??
        n = length(condition);
        missedtrials = ~isnan(behv_data.rt); % missed trials
        behv_data(missedtrials == 0,:) = []; % remove missed trials

        % GET EVENT-LOCKED GAZE POSITION
        xgaze_event = NaN(n,time_pupil); % initialise array to store pupil
        ygaze_event = zeros(n,time_base); % initialise array to store baseline pupil
        [xgaze_event,ygaze_event]= get_gazepos(time_pupil,xgaze_event,ygaze_event, ...
            event_name,n,data,trial_list,pre_duration);        
    end

    % SAVE
    safe_saveall(fullfile(save_xgaze,strcat(subj_ids{s},'.mat')),xgaze_event) % save
    safe_saveall(fullfile(save_ygaze,strcat(subj_ids{s},'.mat')),ygaze_event) % save
end