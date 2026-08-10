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

% USER-BASED PATH
currentDir = cd; % current directory
reqPath = 'GBSliderPupil_NatComms'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end

save_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'descriptive'); 
pupil_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb linearInt'); % directory to get preprocessed data
dirs = {
    'pupil_dir',  pupil_dir;
};
keywords = {'linearInt', 'linear int', 'linear Int', 'LinearInt'};
checkPathKeywords(dirs, keywords);

behv_dir = strcat(desiredPath,filesep,'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
preds_all = readtable(strcat(desiredPath,filesep, 'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx')); % get behavioral predictors
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Initialize object instance
PupilDescriptive = PupilDescriptive();
PupilDescriptive.num_sess = num_sess;
PupilDescriptive.subj_ids = subj_ids;
PupilDescriptive.behv_dir = behv_dir;

% Cycle over subjects
for i = 1:num_subs

    % GET BEHAVIORAL DATA
    behvData = PupilDescriptive.loadBehavioralData(i);

    % MISSED TRIALS
    missed_trials = find(isnan(behvData.rt));
    behvData(missed_trials,:) = [];
    missedSlider = isnan(behvData.slider);

    % GET PE DATA
    preds = preds_all(preds_all.id == str2num(subj_ids{i}),:);

    % GET PUPIL DATA
    filename = strcat(pupil_dir,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename);

    pupil_signal = pupil(:,1:col);
    pupil_signal(missedSlider == 1,:) = [];

    pe_binedges = [0,0.5,1]; % set bin edges
    preds.bins = discretize(abs(preds.pe),pe_binedges); % bin data

    subj_pupil_signal_pebin1(i,:) = mean(pupil_signal(preds.bins == 1,:));
    subj_pupil_signal_pebin2(i,:) = mean(pupil_signal(preds.bins == 2,:));
    
end

% RUN PERM TEST
num_vars = 1; % number of variables
var1 = reshape(subj_pupil_signal_pebin1, [1, num_subs, col]); % [num_vars x num_subjs x col]
var2 = reshape(subj_pupil_signal_pebin2, [1, num_subs, col]); % [num_vars x num_subjs x col]
perm = get_permtest_updated(num_vars, num_subs, col, var1, var2);

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
safe_saveall(strcat(save_dir,filesep,"fb_PE2bins_linearInt.mat"),condiffbin)

% Quick visual check of the mean curves 
figure()
hold on
plot(mean(squeeze(var1)))
plot(mean(squeeze(var2)))