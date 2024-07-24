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
preds_all = readtable("C:\Users\prash\Nextcloud\Thesis_laptop\Semester 7\pupil_manuscript\" + ...
    "data_files\preprocessed_behv\preprocessed_lr_pupil.xlsx");
pupil_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 7\pupil_manuscript\data_files\pupil_events\fb\basecorrected';

% INITIALISE VARS TO STORE PUPIL SIGNAL
subj_pupil_signal = NaN(num_subs,col);

% LOOP OVER SUBJECTS
for i = 1:num_subs

    % GET PUPIL DATA
    filename = strcat(pupil_dir,'\',subj_ids{i},'.mat');
    load(filename,'pupil');
    if strcmp(timewindow,'patch') == 1
        pupil_signal = pupil;
    elseif strcmp(timewindow,'feedback') == 1
        pupil_signal = pupil(:,1:col);
    end

    % GET MEAN SIGNAL FOR EACH SUBJECT
    subj_pupil_signal(i,:) = nanmean(pupil_signal);

end

% SAVE
safe_save("fb_dilation.mat",subj_pupil_signal)