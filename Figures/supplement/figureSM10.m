clc
clearvars

% INITIALIZE VARS
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'};
num_subjs = length(subj_ids);
num_break = 30; % how long should the pupil signal be broken
col_patch = 100; % how long should the patch-related pupil signal
col_fb = 300; % how long should the patch-related pupil signal
total = 630; % how long should the entire trial be
trial_all = NaN(num_subjs,total);

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
fb_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data peak corrected',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb'); % directory to get preprocessed data
xaxis = linspace(-0.3,9.7,1000);
% LOOP OVER SUBJECTS
figure("Position",[100,100,600,600],"Visible","on")
participants = [1,26,3,35,15,11];
for i = 1:length(participants)

    filename = strcat(fb_dir,'\',subj_ids{participants(i)},'.mat');
    fb = importdata(filename); 

    % CONCATANATE
    trial_subj = nanmean(fb,1);
    hold on
    subplot(2,3,i)
    hold on
    plot(xaxis,fb,"Color",[200,200,200]./255,'LineWidth',0.5)
    hold on
    plot(xaxis,trial_subj,"Color",'k','LineWidth',2)
    xlim([-0.3,9.7])
    xline(0,'LineStyle','--','LineWidth',0.5)
    xlabel('Time from feedback onset (s)')
    title(strcat("Participant"," ",subj_ids{participants(i)}),'FontWeight','Normal')
end

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'fb_singleSubj.png', '-dpng', '-r600') 