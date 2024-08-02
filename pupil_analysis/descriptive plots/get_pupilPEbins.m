clc
clearvars

% INITIALISE VARS
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'}; % subject IDs
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions
timewindow = 'feedback';
col = 300;
num_subs = length(subj_ids); % number of subjects
subj_pupil_signal_pebin2 = NaN(num_subs,col); % initialised array for PE bin = 2
subj_pupil_signal_pebin1 = NaN(num_subs,col); % initialised array for PE bin = 1

% PATH STUFF
currentDir = pwd; % Get the current working directory
save_dir = strcat('data', filesep,'GB data',filesep, 'pupil', filesep, 'descriptive'); 
pupil_dir = strcat('data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb'); % directory to get preprocessed data
behv_dir = strcat('data', filesep,'GB data',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
preds_all = readtable(strcat('data', filesep,'GB data',filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx')); % get behavioral predictors
mkdir(save_dir);

for i = 1:num_subs

    % GET PUPIL DATA
    filename = strcat(pupil_dir,'\',subj_ids{i},'.mat');
    load(filename,'pupil');
    size_pupil = size(pupil);

    % INITIALISE
    behv_data = [];
    data_run = [];

    % GET BEHAVIORAL DATA
    for j = 1:num_sess(i)
        filename = strcat(behv_dir,'\',subj_ids{i},'_','main',num2str(j),'.xlsx');
        if strcmp(subj_ids{i},'4672') == 1
            filename = strcat(behv_dir,'\',subj_ids{i},'_','main',num2str(j),'_red.xlsx');
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
    preds(validIndices,:) = []; % delete pe == 0

    % GET PUPIL DATA
    filename = strcat(pupil_dir,'\',subj_ids{i},'.mat');
    load(filename,'pupil');
  %  pupil(missed_trials,:) = []; % delete missed trials from pupil
    pupil(validIndices,:)  = []; % delete pe == 0 from pupil

    if strcmp(timewindow,'patch') == 1
        pupil_signal = pupil;
    elseif strcmp(timewindow,'feedback') == 1
        pupil_signal = pupil(:,1:col);
    end
    pe_binedges = [0,0.5,1]; % set bin edges
    preds.bins = discretize(abs(preds.pe),pe_binedges); % bin data

    subj_pupil_signal_pebin1(i,:) = nanmean(pupil_signal(preds.bins == 1,:));
    subj_pupil_signal_pebin2(i,:) = nanmean(pupil_signal(preds.bins == 2,:));
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
condiffbin.diff = subj_pupil_signal_pebin2 - subj_pupil_signal_pebin1;
safe_saveall(strcat(save_dir,filesep,"fb_PE2bins.mat"),condiffbin)