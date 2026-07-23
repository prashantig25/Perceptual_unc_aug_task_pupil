% Figure 5: plots results from the arousal and learning analysis.

clc
clearvars

linewidth_plot = 0.5; % line-width for plot
linewidth_curves = 2; % line-width for curves
xaxis = linspace(-300,2700,300); % x-axis
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids); % number of subjects
col = 300; % length of x-axis
line_width = 0.5; % line width for axes
font_size = 7; % font size
font_name = 'Arial'; % font name
[~,high_PU,mid_PU,low_PU,~,~,darkblue_muted,~,~,~,~,light_gray,binned_dots,barface_green,...
    reg_color,~,~,~,~] = colors_rgb(); % colors
neutral = [7, 53, 94]/255;

colors_name = darkblue_muted;
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
data_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'residual');
betas_pupil = importdata(fullfile(data_dir, "betas_behvresidual_abs_pecondiff_nomain_linearInt.mat"));
coeffs_name = betas_pupil.coeff_names; % import coeff names
pupil_idx = find(strcmp(coeffs_name, 'pupil')); % GET INDEX OF PUPIL COEFFICIENT
postUP_idx = find(strcmp(coeffs_name, 'post_up')); % GET INDEX OF PUPIL COEFFICIENT
perm = importdata(fullfile(data_dir, "perm_betas_behvresidual_abs_pecondiff_nomain_linearInt.mat"));

% GET P-VALUE FOR PUPIL COEFFICIENT
pupil_pval = perm.prob(pupil_idx,:);
pupil_min_pval = round(min(pupil_pval), 3);

% FORMAT P-VALUE STRING
if pupil_min_pval < 0.001
    pval_str = "\itp\rm < 0.001";
elseif pupil_min_pval < 0.01
    pval_str = sprintf("\\itp\\rm = %.3f", pupil_min_pval);
else
    pval_str = sprintf("\\itp\\rm = %.2f", pupil_min_pval);
end

%% TILE LAYOUT

f1 = figure;
set(f1, 'Visible', 'on');

% Size in CM
width_cm = 12; 
height_cm = 6;
set(f1, 'Units', 'centimeters');
set(f1, 'Position', [10, 10, width_cm, height_cm]);
set(f1, 'PaperUnits', 'centimeters');
set(f1, 'PaperSize', [width_cm, height_cm]);
set(f1, 'PaperPosition', [0, 0, width_cm, height_cm]);

hold on
t = tiledlayout(1, 2, "Padding", "compact", "TileSpacing", "compact");
ax1 = nexttile(1);
ax2 = nexttile(2);

sgtitle('|Update| = \beta_0 + \beta_1 \cdot |Predicted update| + \beta_2 \cdot Pupil + ... + \epsilon', ...
    'Interpreter','Tex','FontSize',8,'FontName','Arial')

%% PLOT COEFFS FOR POSTERIOR UPDATES

% POSITION CHANGE
change = [0.1, 0.005, -0.2, -0.05];
new_pos = change_position(ax1,change);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax1_new, 'off'); % remove box
delete(ax1); % delete old axis

% PLOT
coeffs = squeeze(mean(betas_pupil.with_intercept(1, postUP_idx, :, :), 4));

% Run t-test
[~, pVals, ~, ttest_stats] = ttest(coeffs);
h_stat = ttest_stats.tstat;

% Save statistics for figure 5a
df_5a = num_subjs - 1;
t_crit_5a = tinv(0.975, df_5a);
mean_5a = mean(coeffs);
sem_5a = std(coeffs) / sqrt(num_subjs);
ci_low_5a = mean_5a - t_crit_5a * sem_5a;
ci_high_5a = mean_5a + t_crit_5a * sem_5a;
p_5a = max(pVals, 0.001);
d_5a = compute_cohen_ttest(mean_5a, 0, std(coeffs));

T5a = table( ...
    {"Predicted update (beta1)"}, ...
    round(h_stat, 3), ...
    df_5a, ...
    round(mean_5a, 3), ...
    round(sem_5a, 3), ...
    round(ci_low_5a, 3), ...
    round(ci_high_5a, 3), ...
    round(p_5a, 3), ...
    round(d_5a, 3), ...
    'VariableNames', {'term','t_stat','df','mean','SEM','CI_low','CI_high','p_value','cohen_d'});

saveStat5a = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'stats');
safe_saveall(fullfile(saveStat5a, 'figure5a_stats.csv'), T5a);

[avg,sd,coeffs] = prepare_betas(coeffs,1,num_subjs);
h = bar_plots_pval(coeffs,avg,sd,num_subjs, 1, 1,'', xticks,{'','',''},...
    "\itp\rm < 0.001", '', 'Predicted update ({\bf\beta_1})', 0,1, ...
        10, 1, font_size, linewidth_plot, font_name, 0, colors_name, {'*'}, 0.1);
h.BarWidth = 0.4;
ylim_vals = [0 0.85];
xlim_vals = [0.5 1.5];
adjust_figprops(ax1_new, font_name, font_size, line_width, xlim_vals, ylim_vals);

% POSITION CHANGE
change = [-0.05, 0.005, 0.01, -0.05];
new_pos = change_position(ax2,change);
ax2_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax2_new, 'off'); % remove box
delete(ax2); % delete old axis

% GET POSITION FOR P-VALUE
ylim_axes = [-0.02,0.07];

% Squeeze data
coeffs = squeeze(betas_pupil.with_intercept(1, pupil_idx, :, :));

% PLOT
hold on
shadedErrorBar(xaxis, mean(coeffs), std(coeffs)./sqrt(num_subjs), ...
    {'Color', neutral, 'LineWidth', linewidth_curves}, 1);
xline(0, 'LineStyle','--','LineWidth', 0.5);
yline(0, 'LineStyle','--','LineWidth', 0.5);
adjust_figprops(ax2_new, font_name, font_size, linewidth_plot);

hold on
xlim([-300,2700])
xlabel('Time since feedback onset (ms)')
ylabel('Pupil ({\bf\beta_2})','FontWeight','normal','FontName',font_name,'FontSize',font_size)
plot(xaxis(find(perm.mask(3,:)==1)), 0.01 * ones(1,length(xaxis(find(perm.mask(3,:)==1)))), '.', 'color', ...
    [119, 119, 119]./255, 'markersize', 4);
text(mean(xaxis(perm.mask(pupil_idx,:) == 1)), 0.0115, pval_str, ...
    "FontName", font_name, "FontSize", font_size, "VerticalAlignment", "bottom", "HorizontalAlignment", "center")

%% ADD SUBPLOT LABELS

ax1_pos = ax1_new.Position;
adjust_x = -0.095; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.03; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(ax1_new,adjust_x,adjust_y);
annotation("textbox", [label_x label_y .05 .05], 'String', ...
    'a', 'FontSize', 12, 'LineStyle', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top')

[label_x,label_y] = change_plotlabel(ax2_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05], 'String', ...
    'b', 'FontSize', 12, 'LineStyle', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top')

%% SAVE

fig = gcf; 
fig.PaperPositionMode = 'auto';
%print(fig, 'residuals_pupil7_linearInt1.png', '-dpng', '-r600') 

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none';
hgexport(fig, 'Figures/PDF_Versions/Figure_5.pdf', style);