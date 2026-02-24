clc
clearvars

% INITIALIZE VARS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
num_subjs = length(num_sess);
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
fb_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb Mathot 2023 linearInt'); % directory to get preprocessed data
xaxis = linspace(-0.3,9.7,1000);

% LOOP OVER SUBJECTS
figure("Position",[100,100,400,400],"Visible","on")
participants = [1,26,31,35,15,43];
for i = 1:length(participants)

    filename = strcat(fb_dir,filesep,subj_ids{participants(i)},'.mat');
    fb = importdata(filename); 

    % CONCATANATE
    trial_subj = nanmean(fb(:,1:1000),1);
    hold on
    subplot(2,3,i)
    hold on
    plot(xaxis,fb(:,1:1000),"Color",[200,200,200]./255,'LineWidth',0.5)
    hold on
    plot(xaxis,trial_subj,"Color",'k','LineWidth',2)
    xlim([-0.3,6])
    xline(0,'LineStyle','--','LineWidth',0.5)
    xlabel('Time from feedback onset (s)')
    title(strcat("Participant"," ",subj_ids{participants(i)}),'FontWeight','Normal')
    set(gca,'FontName','Arial','FontSize',7)
end

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'fb_singleSubj_fullDuration_linearInt1.png', '-dpng', '-r600') 