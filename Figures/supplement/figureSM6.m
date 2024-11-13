% figureSM6 plots regression diagnostics of the behavioral model.

clc
clearvars

line_width = 0.5; % line width for axes
font_size = 6; % font size
font_name = 'Arial'; % font name
linewidth_axes = 0.5; % line width for plot lines
fontsize_label = 12; % fontsize for subplot labels
dot_size = 10;
[~,~,~,~,~,~,darkblue_muted,~,~,~,~,~,~,barface_green,...
    ~,~,~,fits_colors,~] = colors_rgb(); % colors

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
% Construct the file paths using fullfile
rsquared_full_path = fullfile(desiredPath, filesep, 'data', filesep, 'GB data', filesep, 'behavior', filesep, 'LR analyses', filesep, 'partialR2_abs.mat');
rsquared_signedpath = fullfile(desiredPath, filesep, 'data', filesep, 'GB data', filesep, 'behavior', filesep, 'LR analyses', filesep, 'partialR2_signed.mat');
posterior_up_subjs_path = fullfile(desiredPath, filesep, 'data', filesep, 'GB data', filesep, 'behavior', filesep, 'LR analyses', filesep, 'post_absUP_predict.mat');
data_subjs_path = fullfile(desiredPath, filesep, 'data', filesep, 'GB data', filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil_no_zerope.xlsx');

% Load the data
rsquared_full = importdata(rsquared_full_path); % r-squared values
rsquared_signed = importdata(rsquared_signedpath); % r-squared values
posterior_up_subjs = importdata(posterior_up_subjs_path); % posterior updates
data_subjs = readtable(data_subjs_path); % single-trial updates, prediction errors
num_subjs = 47; % number of subjects
%% INITIALISE TILE LAYOUT

figure
set(gcf,'Position',[100 100 400 200])
t = tiledlayout(1,2);
t.TileSpacing = 'compact';
t.Padding = 'compact';
ax1 = nexttile(1,[1,1]);

%% PLOT R-SQUARED VALUES

% CHANGE TILE POSITION
ax2 = nexttile(2,[1,1]);
position_change = [0.17, 0, -0.17, 0]; % change in position
new_pos = change_position(ax2,position_change); % new position
ax2_new = axes('Units', 'Normalized', 'Position', new_pos); % updated position
box(ax2_new, 'off'); % box off
delete(ax2); % delete old axis

% PLOT
title_name = {''}; 
bar_plots_pval([rsquared_full;rsquared_signed],[mean(rsquared_full),mean(rsquared_signed)].',[std(rsquared_full)./sqrt(num_subjs),std(rsquared_signed)./sqrt(num_subjs)].',num_subjs, ...
    2,1,{''},[1,2],{'Absolute','Signed'},title_name,{'Model'},{''},0,1,dot_size,1,font_size,line_width,font_name,0,darkblue_muted) 
hold on

% PLOT PROPERTIES
xlabel('')
% ylim([-0.3,0])
set(gca,'Color','none')
ylabel('Mean partial-\itr^2\rm values','Interpreter','tex')
title('Model fit','FontWeight','normal')
%% PLOT POSTERIOR DISTRIBUTION

% GET EMPIRICAL AND POSTERIOR UPDATES
y = abs(data_subjs.up(data_subjs.pe ~= 0)); % empirical updates
y_hat = posterior_up_subjs; % regression model estimated updates
nbins = 75; % number of bins in a distribution

% CHANGE POSITION
position_change = [0.03, 0, 0.15, 0];
new_pos = change_position(ax1,position_change);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax1_new, 'off');
delete(ax1);

y_hat = [];
for n = 1:num_subjs
    y_hat = [y_hat;cell2mat(posterior_up_subjs(n,1))];
end

% PLOT
h1 = histfit(y_hat,nbins);
hold on
h = histfit(y,nbins);

h1(1).FaceAlpha = 1; % face alpha for distributions
h(1).FaceAlpha = 0.7;

h(2).Color = fits_colors; % colors for distributions
h1(2).Color = [37, 50, 55]/255;

h(1).EdgeColor = fits_colors; % edge color for bars
h1(1).EdgeColor = [37, 50, 55]/255;

h(1).FaceColor = fits_colors; % face color for bars
h1(1).FaceColor = [37, 50, 55]/255;

% PLOT PROPERTIES
set(ax1_new,'Color','none','FontName',font_name,'FontSize',font_size)
set(ax1_new,'LineWidth',linewidth_axes)
l = legend('Regression fits','','Absolute empirical updates','','EdgeColor','none','Color','none');
l.ItemTokenSize = [7 7];
xlabel('Update')
ylabel('Frequency (x 10^3)','Interpreter','tex')
yticklabels({'0','1','2','3','4','5'})
title('Posterior and empirical distribution','FontWeight','normal')
set(gca,'Color','none')
box off
%% ADD SUBPLOT LABELS

ax1_pos = ax2_new.Position;
adjust_x = [- 0.06,-0.075]; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.05; % adjusted y-position for subplot label

all_axes = [ax1_new,ax2_new];
subplot_labels = {'a','b'};
for i = 1:2
    [label_x,label_y] = change_plotlabel(all_axes(i),adjust_x(i),adjust_y);
    annotation("textbox",[label_x label_y .05 .05],'String', ...
        subplot_labels{i},'FontSize',fontsize_label,'LineStyle','none','HorizontalAlignment','center')
end

%%
fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'reg_diagnostics1.png', '-dpng', '-r600') 