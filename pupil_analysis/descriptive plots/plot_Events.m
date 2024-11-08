clc
clearvars

% INITIALISE VARS and PATHS
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'};
timewindow = 'feedback'; % specify for which event pupil signal is being plotted
col = 300; % length of signal to be plotted
num_subs = length(subj_ids); % number of subjects
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions

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
save_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'pupil', filesep, 'descriptive'); 
pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb'); % directory to get preprocessed data
preds_all = readtable(strcat(desiredPath, filesep, 'data', filesep,'GB data',filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx')); % get behavioral predictors
mkdir(save_dir);

% INITIALISE VARS TO STORE PUPIL SIGNAL
subj_pupil_signal = NaN(num_subs,col);

% LOOP OVER SUBJECTS
for i = 1:num_subs

    % GET PUPIL DATA
    filename = strcat(pupil_dir,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename);
    if strcmp(timewindow,'patch') == 1
        pupil_signal = pupil;
    elseif strcmp(timewindow,'feedback') == 1
        pupil_signal = pupil(:,1:col);
    end

    % GET MEAN SIGNAL FOR EACH SUBJECT
    subj_pupil_signal(i,:) = nanmean(pupil_signal);

end

% SAVE
safe_saveall(strcat(save_dir,filesep,"fb_dilation.mat"),subj_pupil_signal)