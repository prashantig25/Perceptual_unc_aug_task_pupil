clc
clearvars

currentDir = cd;
reqPath    = 'Perceptual_unc_aug_task_pupil-main';
pathParts  = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

mainFB = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'fb Mathot 2023 linearInt');
alternateFB = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'non-baseline corrected fb linearInt');

subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
num_subjs = length(subj_ids);

col = 300;

mainFB_data = nan(num_subjs,col);
altFB_data = nan(num_subjs,col);

for i = 1:num_subjs

    % IMPORT EVENT-RELATED DATA
    filename = strcat(mainFB,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename); mainFB_data(i,:) = nanmean(pupil(:,1:col));

    filename = strcat(alternateFB,filesep,subj_ids{i},'.mat');
    pupil = importdata(filename); altFB_data(i,:) = nanmean(pupil(:,1:col));

end

%% --- CALCULATE MEAN AND SEM ---
% Main Pipeline
m_main = nanmean(mainFB_data, 1);
s_main = nanstd(mainFB_data, 0, 1) ./ sqrt(sum(~isnan(mainFB_data(:,1))));

% Alternate Pipeline
m_alt = nanmean(altFB_data, 1);
s_alt = nanstd(altFB_data, 0, 1) ./ sqrt(sum(~isnan(altFB_data(:,1))));

x = 1:col; % Time axis

% FEEDBACK PIPELINES COMPARISON - UPDATED STYLE

clc

% Define plotting parameters (matching style from reference)
linewidth_plot = 0.5;      % line-width for axes
linewidth_curves = 2;      % line-width for curves
line_width = 0.5;          % line width for axes
font_size = 7;             % font size
font_name = 'Arial';       % font name

% Get colors
[~, high_PU, mid_PU, low_PU, ~, ~, darkblue_muted, ~, ~, ~, ~, light_gray, binned_dots, ~, ...
    reg_color, ~, ~, ~, ~] = colors_rgb();

% Define muted red color
muted_red = [150, 56, 56]./255;  % Softer red
neutral = [7, 53, 94]/255;

% Calculate means and SEMs
% Main Pipeline
m_main = nanmean(mainFB_data, 1);
s_main = nanstd(mainFB_data, 0, 1) ./ sqrt(sum(~isnan(mainFB_data(:,1))));

% Alternate Pipeline
m_alt = nanmean(altFB_data, 1);
s_alt = nanstd(altFB_data, 0, 1) ./ sqrt(sum(~isnan(altFB_data(:,1))));

col = size(mainFB_data, 2);  % Number of time points
x = 1:col; % Time axis

% CREATE FIGURE WITH TILE LAYOUT

figure('Position', [100, 100, 400, 150]);
t = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

ax1 = nexttile;
ax2 = nexttile;

% SUBPLOT 1: ALTERNATE PIPELINE

% POSITION CHANGE
change = [0.02, 0.005, -0.05, 0];
new_pos = change_position(ax1, change);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax1_new, 'off');
delete(ax1);

% Plot with shadedErrorBar
hold on;
plot(x, m_alt, 'Color', muted_red, 'LineStyle', '-', 'LineWidth', linewidth_curves);
shadedErrorBar(x, m_alt, s_alt, {'Color', muted_red, 'LineWidth', linewidth_curves}, 1);

% Add reference line at y=0
yline(0, 'LineStyle', '--', 'LineWidth', linewidth_plot, 'Color', 'k');

% Adjust figure properties
xlim_vals = [1, col];
ylim_vals = [5200, 5800];
adjust_figprops(ax1_new, font_name, font_size, line_width, xlim_vals, ylim_vals);

% Labels and formatting
title('Alternate pre-processing pipeline 1', 'FontSize', font_size, 'FontWeight', 'normal');
xlabel('Time since feedback onset (ms)', 'FontSize', font_size);
ylabel('Pupil signal', 'FontSize', font_size);

% X-axis ticks
set(ax1_new, 'XTick', [0, 50, 130, 230, 360, 460, 560], ...
    'XTickLabel', {'0', '500', '0', '1000', '0', '500', '1000'});

hold off;

% SUBPLOT 2: MAIN PIPELINE
[~,high_PU,mid_PU,low_PU,~,~,darkblue_muted,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
% POSITION CHANGE
change = [-0.02, 0.005, -0.05, 0];
new_pos = change_position(ax2, change);
ax2_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax2_new, 'off');
delete(ax2);

% Plot with shadedErrorBar
hold on;
plot(x, m_main, 'Color', neutral, 'LineStyle', '-', 'LineWidth', linewidth_curves);
shadedErrorBar(x, m_main, s_main, {'Color', neutral, 'LineWidth', linewidth_curves}, 1);

% Add reference line at y=0
yline(0, 'LineStyle', '--', 'LineWidth', linewidth_plot, 'Color', 'k');

% Adjust figure properties
xlim_vals = [1, col];
ylim_vals = [-50, 200];
adjust_figprops(ax2_new, font_name, font_size, line_width, xlim_vals, ylim_vals);

% Labels and formatting
title('Main pre-processing pipeline', 'FontSize', font_size, 'FontWeight', 'normal');
xlabel('Time since feedback onset (ms)', 'FontSize', font_size);
ylabel('Pupil dilation', 'FontSize', font_size);

% X-axis ticks
set(ax2_new, 'XTick', [0, 50, 130, 230, 360, 460, 560], ...
    'XTickLabel', {'0', '500', '0', '1000', '0', '500', '1000'});

hold off;

 % ADD SUBPLOT LABELS

% Label for subplot 1
ax1_pos = ax1_new.Position;
adjust_x = -0.085;
adjust_y = ax1_pos(4) + 0.04;
[label_x, label_y] = change_plotlabel(ax1_new, adjust_x, adjust_y);
annotation('textbox', [label_x label_y .05 .05], 'String', 'a', ...
    'FontSize', 12, 'LineStyle', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

% Label for subplot 2
[label_x, label_y] = change_plotlabel(ax2_new, adjust_x, adjust_y);
annotation('textbox', [label_x label_y .05 .05], 'String', 'b', ...
    'FontSize', 12, 'LineStyle', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'feedback_pipelinesLinearInt.png', '-dpng', '-r600') 
