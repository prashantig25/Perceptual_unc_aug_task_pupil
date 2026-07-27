% Figure S5: Example pupil curves 

clc
clearvars

% INITIALIZE VARS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
num_subjs = length(subj_ids); % number of subjects
num_break = 30; % how long should the pupil signal be broken
col_patch = 100; % how long should the patch-related pupil signal
col_fb = 300; % how long should the patch-related pupil signal
total = 630; % how long should the entire trial be
trial_all = NaN(num_subjs,total);
font_size = 7;
font_name = 'Arial';

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
fb_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb linearInt'); % directory to get preprocessed data

% Plot properties
xaxisMax = 1000;
xaxis = linspace(-0.3, 9.7, xaxisMax);

% LOOP OVER SUBJECTS
%figure("Position",[100,100,400,400],"Visible","on")

f1 = figure;
set(f1, 'Visible', 'on');

% Size in CM
width_cm = 12; 
height_cm = 10.5;
set(f1, 'Units', 'centimeters');
set(f1, 'Position', [10, 10, width_cm, height_cm]);
set(f1, 'PaperUnits', 'centimeters');
set(f1, 'PaperSize', [width_cm, height_cm]);
set(f1, 'PaperPosition', [0, 0, width_cm, height_cm]);

participants = [1,26,31,35,15,43];
for i = 1:length(participants)

    filename = strcat(fb_dir,filesep,subj_ids{participants(i)},'.mat');
    fb = importdata(filename); 

    % CONCATANATE
    trial_subj = nanmean(fb(:,1:xaxisMax),1);
    hold on
    subplot(2,3,i)
    hold on
    plot(xaxis,fb(:,1:xaxisMax),"Color",[200,200,200]./255,'LineWidth',0.5)
    hold on
    plot(xaxis,trial_subj,"Color",'k','LineWidth',2)
    xlim([-0.3,6])
    xline(0,'LineStyle','--','LineWidth',0.5)
    xlabel('Time since feedback (s)')
    title(strcat("Participant"," ",subj_ids{participants(i)}),'FontWeight','Normal')
    if i == 1 || i == 4
        ylabel("Pupil dilation")
    end
    set(gca,'FontName', font_name, 'FontSize', font_size)
end

fig = gcf; 
fig.PaperPositionMode = 'auto';
% print(fig, 'fb_singleSubj_fullDuration_linearInt1.png', '-dpng', '-r600') 

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none'; 
hgexport(fig, 'Figures/PDF_Versions/Figure_SM5.pdf', style);