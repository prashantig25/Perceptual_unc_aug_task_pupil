% get_pupilPEbins computes pupil response for separate bins of high and low
% PE.

clc
clearvars

% INITIALISE VARS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
timewindow = 'feedback';
col = 300;
num_subs = length(subj_ids); % number of subjects
subj_pupil_signal_pebin2 = NaN(num_subs,col); % initialised array for PE bin = 2
subj_pupil_signal_pebin1 = NaN(num_subs,col); % initialised array for PE bin = 1
subj_pupil_signal_pebin2correct = NaN(num_subs,col); % initialised array for PE bin = 2
subj_pupil_signal_pebin1correct = NaN(num_subs,col); % initialised array for PE bin = 1
subj_pupil_signal_pebin2incorrect = NaN(num_subs,col); % initialised array for PE bin = 2
subj_pupil_signal_pebin1incorrect = NaN(num_subs,col); % initialised array for PE bin = 1
plot_accuracy = 1; % get PE bins for accuracy

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
save_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'descriptive'); 
pupil_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb'); % directory to get preprocessed data
behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
preds_all = readtable(strcat(desiredPath,filesep, 'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx')); % get behavioral predictors
mkdir(save_dir);

for i = 1:num_subs

    % GET PUPIL DATA
    filename = strcat(pupil_dir,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename);
    size_pupil = size(pupil);

    % INITIALISE
    behv_data = [];
    data_run = [];

    % GET BEHAVIORAL DATA
    for j = 1:num_sess(i)
        filename = strcat(behv_dir,filesep,subj_ids{i},'_','main',num2str(j),'.xlsx');
        if strcmp(subj_ids{i},'4672') == 1
            filename = strcat(behv_dir,filesep,subj_ids{i},'_','main',num2str(j),'_red.xlsx');
        end
        data_run = readtable(filename); % get RT and slider data
        rt = table(data_run.choice_rt,'VariableNames',{'rt'});
        slider = table(data_run.slider_respond_response,'VariableNames',{'slider'});
        data_run = [data_run(:,(1:16)),rt,slider];
        behv_data = [behv_data; data_run];
    end

    % MISSED TRIALS
    missed_trials = []; % initialize array for index of missed trials
    for b = 1:height(behv_data)
        if isnan(behv_data.rt(b,:)) || isnan(behv_data.slider(b,:)) % check if participant has not responded
            missed_trials = [missed_trials;b];
        end
    end

    % GET PE DATA
    preds = preds_all(preds_all.id == str2num(subj_ids{i}),:);
    validIndices = find(preds.pe == 0); % pe == 0

    % GET PUPIL DATA
    filename = strcat(pupil_dir,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename);

    if strcmp(timewindow,'patch') == 1
        pupil_signal = pupil;
    elseif strcmp(timewindow,'feedback') == 1
        pupil_signal = pupil(:,1:col);
    end
    pe_binedges = [0,0.5,1]; % set bin edges
    preds.bins = discretize(abs(preds.pe),pe_binedges); % bin data

    subj_pupil_signal_pebin1(i,:) = nanmean(pupil_signal(preds.bins == 1,:));
    subj_pupil_signal_pebin2(i,:) = nanmean(pupil_signal(preds.bins == 2,:));

    if plot_accuracy == 1
        pupil_signalcorrect = pupil_signal(preds.correct == 1,:);
        pupil_signalincorrect = pupil_signal(preds.correct == 0,:);

        preds_incorrect = preds(preds.correct == 0,:);
        preds_correct = preds(preds.correct == 1,:);

        subj_pupil_signal_pebin1correct(i,:) = nanmean(pupil_signalcorrect(preds_correct.bins == 1,:));
        subj_pupil_signal_pebin2correct(i,:) = nanmean(pupil_signalcorrect(preds_correct.bins == 2,:));

        subj_pupil_signal_pebin1incorrect(i,:) = nanmean(pupil_signalincorrect(preds_incorrect.bins == 1,:));
        subj_pupil_signal_pebin2incorrect(i,:) = nanmean(pupil_signalincorrect(preds_incorrect.bins == 2,:));
    end
end

% RUN PERM TEST
num_vars = 1; % number of variables
var1 = subj_pupil_signal_pebin1; 
var2 = subj_pupil_signal_pebin2;
two_tailed = 1; % apply two-tailed permutation test
betas = 0; % permutation test on descriptive data
perm = get_permtest(num_vars, num_subs, col, var1, var2, two_tailed, betas);

% SAVE
condiffbin.stat = perm.mask;
condiffbin.prob = perm.prob;
condiffbin.pebin1 = subj_pupil_signal_pebin1;
condiffbin.pebin2 = subj_pupil_signal_pebin2;
condiffbin.pebin1_correct = subj_pupil_signal_pebin1correct;
condiffbin.pebin1_incorrect = subj_pupil_signal_pebin1incorrect;
condiffbin.pebin2_correct = subj_pupil_signal_pebin2correct;
condiffbin.pebin2_incorrect = subj_pupil_signal_pebin2incorrect;
condiffbin.diff = subj_pupil_signal_pebin2 - subj_pupil_signal_pebin1;
safe_saveall(strcat(save_dir,filesep,"fb_PE2bins.mat"),condiffbin)