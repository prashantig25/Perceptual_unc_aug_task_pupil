% gazeposition saves single trial x-gaze and y-gaze data for each
% participant.

clc
clearvars

% INITIALISE VARS and PATHS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
num_subs = length(subj_ids);
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

% SETUP PATHS (common to both pipelines)
currentDir = cd; % current directory
reqPath = 'Perceptual_unc_aug_task_pupil'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end
behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data

%% GAZE BASED LINEAR INT

save_xgaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze linear int'); 
save_ygaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze linear int'); 
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed linear int trials and events added');
mkdir(save_xgaze);
mkdir(save_ygaze);

% LOOP OVER SUBJECTS
parfor s = 1:num_subs

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
            data_run = readtable(filename,'VariableNamingRule', 'preserve');
            rt = table(data_run.("choice.rt"),'VariableNames',{'rt'}); % add RT data
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
        xgaze_event(missedtrials == 0,:) = []; % remove pupil response of missed trials
        ygaze_event(missedtrials == 0,:) = []; % remove pupil response of missed trials
    end

    % SAVE
    safe_saveall(fullfile(save_xgaze,strcat(subj_ids{s},'.mat')),xgaze_event) % save
    safe_saveall(fullfile(save_ygaze,strcat(subj_ids{s},'.mat')),ygaze_event) % save
end

%% GAZE BASED ON CUBIC SPLINE INTERPOLATION

save_xgaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze CS new'); 
save_ygaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze CS new'); 
preproc_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'preprocessing', filesep, 'main pipeline', ...
    filesep, 'preprocessed cubic spline new trials and events added');
behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
mkdir(save_xgaze);
mkdir(save_ygaze);

% LOOP OVER SUBJECTS
parfor s = 1:num_subs

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
            data_run = readtable(filename,'VariableNamingRule', 'preserve');
            rt = table(data_run.("choice.rt"),'VariableNames',{'rt'}); % add RT data
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
        xgaze_event(missedtrials == 0,:) = []; % remove pupil response of missed trials
        ygaze_event(missedtrials == 0,:) = []; % remove pupil response of missed trials
    end

    % SAVE
    safe_saveall(fullfile(save_xgaze,strcat(subj_ids{s},'.mat')),xgaze_event) % save
    safe_saveall(fullfile(save_ygaze,strcat(subj_ids{s},'.mat')),ygaze_event) % save
end

%% GAZE BASED ON DECONVOLUTION

save_xgaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'x-gaze deconv fixed seed'); 
save_ygaze = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'y-gaze deconv fixed seed'); 
preproc_dir = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil/data/" + ...
    "GB data two pipelines/pupil/preprocessing/alternate pipeline/preprocessed trials and events added fixed seed";
behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
mkdir(save_xgaze);
mkdir(save_ygaze);

% LOOP OVER SUBJECTS
parfor s = 1:num_subs

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
            data_run = readtable(filename,'VariableNamingRule', 'preserve');
            rt = table(data_run.("choice.rt"),'VariableNames',{'rt'}); % add RT data
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
        xgaze_event(missedtrials == 0,:) = []; % remove pupil response of missed trials
        ygaze_event(missedtrials == 0,:) = []; % remove pupil response of missed trials
    end

    % SAVE
    safe_saveall(fullfile(save_xgaze,strcat(subj_ids{s},'.mat')),xgaze_event) % save
    safe_saveall(fullfile(save_ygaze,strcat(subj_ids{s},'.mat')),ygaze_event) % save
end