% Figure SM1: Plots choice performance

clc
clearvars

linewidth_axes = 0.5; % arrow width
font_name = 'Arial'; % font name
horz_align = 'center'; % alignment
vert_align = 'middle';
font_size = 7;
[~,~,~,~,color_screen,fb_green,darkblue_muted,mix,perc,rew,~,~,~,~,...
    ~,~,~,~,~] = colors_rgb(); % colors

% Path setup
currentDir = cd;
reqPath = 'Perceptual_unc_aug_task_pupil';
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

descriptive_path = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'descriptive (n = 47)');

mix_ecoperf = importdata(fullfile(descriptive_path,"mix_ecoperf.mat"));
perc_ecoperf = importdata(fullfile(descriptive_path,"perc_ecoperf.mat"));

%% INITIALIZE FIGURE

figure("Position",[100,100,200,200])
hold on

%% PLOT ECONOMIC PERFORMANCE

% MEAN ECONOMIC PERFORMANCE ACROSS SUBJECTS
y = [mix_ecoperf;perc_ecoperf;];
num_subjs = length(mix_ecoperf);
mix_avg = mean(mix_ecoperf,1);
perc_avg = mean(perc_ecoperf,1);
mean_avg = [mix_avg; perc_avg;];

% SEM ACROSS SUBJECTS
mix_sd = std(mix_ecoperf,1)/sqrt(num_subjs);
perc_sd = std(perc_ecoperf,1)/sqrt(num_subjs);
mean_sd = [mix_sd; perc_sd;];
xticks = [1; 2];

% FIGURE PROPERTIES
xticklabs = {'High','Low'}; % x-axis tick labels
title_name = {''}; % figure title
legend_names = {''}; % legend names
xlabelname = {'Reward uncertainty'}; % x-axis label name
ylabelname = {'P(Correct)'}; % y-axis label name
colors_name = darkblue_muted; % bar colors

% PLOT CHOICE DATA
bar_plots(y,mean_avg,mean_sd,num_subjs,length(mean_avg),length(legend_names), ...
    legend_names,xticks,xticklabs,title_name,xlabelname,ylabelname,7,1,'Arial',darkblue_muted)
set(gca,'color','none','FontName',font_name,'FontSize',font_size,'YLim',[0.3,1], ...
    'LineWidth',linewidth_axes,'YTick',[0.3,0.4,0.5,0.6,0.7,0.8,0.9,1], ...
    'YTickLabels',{'0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'})

%% SAVE AS PNG

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'choice_behv1.png', '-dpng', '-r600')