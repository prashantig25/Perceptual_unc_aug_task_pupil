clc
clearvars

% INITIALIZE VARS

fontname = 'Arial'; % font name
fontsize = 7; % font size
linewidth_plot = 0.5; % line width for plot
linewidth_curves = 2; % line width for curves
xaxis = linspace(-300,2700,300); % x-axis
[~,high_PU,mid_PU,low_PU,~,~,~,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
neutral = [7, 53, 94]/255;
subj_ids = importdata("subj_ids.mat");
num_subs = length(subj_ids); % number of subjects
col = 300;

% USER-BASED PATH
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
posterior = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep,"regression",filesep,"main",filesep,"4c_MathotComments_diffVals_zscoredPESubjVals.mat"));
interaction = importdata("/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil/data/GB data two pipelines/pupil/descriptive/fb_PE2bins_condiff2bins_linearInt.mat");


figure
hold on

subplot(1,2,1)
hold on
plot(xaxis,mean(posterior.highPU_highPE),'LineStyle',':','Color','b','LineWidth',2)
hold on
plot(xaxis,mean(interaction.subj_pupil(1,2).signal),'Color','b','LineWidth',2)
hold on
plot(xaxis,mean(posterior.highPU_lowPE),'LineStyle',':','Color','r','LineWidth',2)
hold on
plot(xaxis,mean(interaction.subj_pupil(1,1).signal),'Color','r','LineWidth',2)

xlim([-300,2700])
xline(0,'--','LineWidth',0.5)
yline(0,'--','LineWidth',0.5)
xlim([-300,2700])
xlabel('Time from feedback onset (ms)')
ylabel({'Pupil curves'});
title('Low contrast difference bins')

subplot(1,2,2)
hold on
plot(xaxis,mean(posterior.lowPU_highPE),'LineStyle',':','Color','b','LineWidth',2)
hold on
plot(xaxis,mean(posterior.lowPU_lowPE),'LineStyle',':','Color','r','LineWidth',2)
hold on
plot(xaxis,mean(interaction.subj_pupil(2,2).signal),'Color','b','LineWidth',2)
hold on
plot(xaxis,mean(interaction.subj_pupil(2,1).signal),'Color','r','LineWidth',2)
title('High contrast difference bins')
legend('Posterior - high PE', 'Posterior - low PE', 'Empirical - high PE', 'Empirical - low PE','AutoUpdate','off')

xlim([-300,2700])
xline(0,'--','LineWidth',0.5)
yline(0,'--','LineWidth',0.5)
xlim([-300,2700])
xlabel('Time from feedback onset (ms)')
ylabel({'Pupil curves'});

