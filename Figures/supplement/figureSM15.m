% Figure S15: Plots full model results of the model-based analysis of residual learning.

clc
clearvars

linewidth_plot = 0.5; % line-width for axes
linewidth_curves = 2; % line-width for curves
xaxis = linspace(-300, 2700, 300); % x-axis
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids); % number of subjects
col = 300; % length of x-axis
font_size = 7; % font size
font_name = 'Arial'; % font name
[~,high_PU,mid_PU,low_PU,~,~,darkblue_muted,~,~,~,~,light_gray,binned_dots,barface_green,...
    reg_color,~,~,~,~] = colors_rgb(); % colors
neutral = [7, 53, 94]/255;

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
betas_pupil = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "residual", filesep,"betas_behvresidual_abs_pecondiff_nomain_linearInt.mat")); % add PE bin curves
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "residual", filesep,"perm_betas_behvresidual_abs_pecondiff_nomain_linearInt.mat")); % add PE bin curves
posterior = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "residual", filesep,"BSarousal_interactions_linearInt.mat")); % add PE bin curves
coeffs_name = betas_pupil.coeff_names;

% GET COEFFICIENT INDICES FROM NAMES
pe_pupil_idx = find(strcmp(coeffs_name, 'pe:pupil'));
pupil_condiff_idx = find(strcmp(coeffs_name, 'pupil:con_diff'));
pe_pupil_condiff_idx = find(strcmp(coeffs_name, 'pe:pupil:con_diff'));

%% TILED LAYOUT

fig = figure; 
set(fig, 'Visible', 'on'); 
 
% Size in CM 
width_cm = 14;  
height_cm = 12; 
set(fig, 'Units', 'centimeters'); 
set(fig, 'Position', [10, 10, width_cm, height_cm]); 
set(fig, 'PaperUnits', 'centimeters'); 
set(fig, 'PaperSize', [width_cm, height_cm]); 
set(fig, 'PaperPosition', [0, 0, width_cm, height_cm]); 

hold on
t = tiledlayout(2,2,"TileSpacing","compact");

%% PLOT COEFFICIENTS - pupil:con_diff

ax1 = nexttile(1);

data_plot = NaN(num_subjs, col);
for s = 1:num_subjs
    for c = 1:col
        data_plot(s,c) = betas_pupil.with_intercept(1,pupil_condiff_idx,s,c);
    end
end

% PLOT
hold on
shadedErrorBar(xaxis, mean(data_plot), std(data_plot)./sqrt(num_subjs), ...
    {'Color', neutral, 'LineWidth', linewidth_curves}, 1);

% ADJUST FIGURE PROPERTIES
xline(0, 'LineStyle', '--', 'LineWidth', 0.5);
yline(0, 'LineStyle', '--', 'LineWidth', 0.5);
adjust_figprops(ax1, font_name, font_size, linewidth_plot);
hold on
xlim([-300, 2700])
xlabel('Time since feedback (ms)')
ylabel('Uncertainty-modulated pupil', 'FontWeight', 'normal', 'FontName', font_name, 'FontSize', font_size)

pval_position = -0.003;
pval_text_dist = 0.05;
pval_sign = -1;
printPermTest(perm, xaxis, pupil_condiff_idx, pval_position, pval_sign, pval_text_dist, font_size, font_name)

%% PLOT INTERACTIONS

ax2 = nexttile(2);

% PLOT
hold on
a = shadedErrorBar(xaxis, mean(posterior.higharousal_lowcondiff), std(posterior.higharousal_lowcondiff)./sqrt(num_subjs), {'LineWidth', 2, "Color", high_PU}, 1);
b = shadedErrorBar(xaxis, mean(posterior.higharousal_highcondiff), std(posterior.higharousal_highcondiff)./sqrt(num_subjs), {'LineWidth', 2, "Color", low_PU}, 1);
c = shadedErrorBar(xaxis, mean(posterior.lowarousal_lowcondiff), std(posterior.lowarousal_lowcondiff)./sqrt(num_subjs), {'LineWidth', 2, "Color", high_PU, 'LineStyle','--'}, 1);
d = shadedErrorBar(xaxis, mean(posterior.lowarousal_highcondiff), std(posterior.lowarousal_highcondiff)./sqrt(num_subjs), {'LineWidth', 2, "Color", low_PU, 'LineStyle','--'}, 1);

% ADJUST FIGURE PROPERTIES
l = legend([a.mainLine, b.mainLine, c.mainLine, d.mainLine],...
    'High arousal & high uncertainty', 'High arousal & low uncertainty', 'Low arousal & high uncertainty', 'Low arousal & low uncertainty', font_name, ...
    'Location', 'NorthEast', 'EdgeColor', 'none', 'AutoUpdate', 'off', 'Color', 'none', 'FontName', font_name, 'FontSize', font_size);
l.ItemTokenSize = [20, 20];
xlabel('Time since feedback (ms)')
ylabel('Model-predicted absolute UP', 'FontWeight', 'normal', 'FontName', font_name, 'FontSize', font_size)
adjust_figprops(ax2, font_name, font_size, linewidth_plot);

hold on
xlim([-300, 2700])
legend_pos = l.Position;
l.Position = legend_pos + [0.01, 0.1, 0.0, 0.0];

%% PLOT COEFFICIENTS - pe:pupil

% POSITION CHANGE
ax3 = nexttile(3);

data_plot = NaN(num_subjs, col);
for s = 1:num_subjs
    for c = 1:col
        data_plot(s,c) = betas_pupil.with_intercept(1, pe_pupil_idx, s, c);
    end
end

% PLOT
hold on
shadedErrorBar(xaxis, mean(data_plot), std(data_plot)./sqrt(num_subjs), ...
    {'Color', neutral, 'LineWidth', linewidth_curves}, 1);

% ADJUST FIGURE PROPERTIES
xline(0, 'LineStyle','--','LineWidth', 0.5);
yline(0, 'LineStyle','--','LineWidth', 0.5);
adjust_figprops(ax3, font_name, font_size, linewidth_plot);
hold on
xlim([-300, 2700])
xlabel('Time since feedback (ms)')
ylabel('PE-modulated pupil', 'FontWeight', 'normal', 'FontName', font_name, 'FontSize', font_size)

printPermTest(perm, xaxis, pe_pupil_idx, pval_position, pval_text_dist, font_size, font_name)

%% PLOT COEFFICIENTS - pe:pupil:con_diff

ax4 = nexttile(4);

data_plot = NaN(num_subjs, col);
for s = 1:num_subjs
    for c = 1:col
        data_plot(s,c) = betas_pupil.with_intercept(1,pe_pupil_condiff_idx,s,c);
    end
end

% PLOT
hold on
shadedErrorBar(xaxis, mean(data_plot), std(data_plot)./sqrt(num_subjs), ...
    {'Color', neutral, 'LineWidth', linewidth_curves},1);

% ADJUST FIGURE PROPERTIES
xline(0, 'LineStyle', '--', 'LineWidth', 0.5);
yline(0, 'LineStyle', '--', 'LineWidth', 0.5);
adjust_figprops(ax4, font_name, font_size, linewidth_plot);
hold on
xlim([-300, 2700])
xlabel('Time since feedback (ms)')
ylabel('Uncertainty- and PE-modulated pupil', 'FontWeight', 'normal', 'FontName',font_name, 'FontSize', font_size)

printPermTest(perm, xaxis, pe_pupil_condiff_idx, pval_position, pval_text_dist, font_size, font_name)

%% ADD SUBPLOT LABELS

ax1_pos = ax1.Position;
adjust_x = -0.085; % adjusted x-position for subplot label
adjust_y = ax1_pos(4); % adjusted y-position for subplot label

[label_x,label_y] = change_plotlabel(ax1,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center','VerticalAlignment','top')

[label_x,label_y] = change_plotlabel(ax2,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center','VerticalAlignment','top')

[label_x,label_y] = change_plotlabel(ax3,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',12,'LineStyle','none','HorizontalAlignment','center','VerticalAlignment','top')

[label_x,label_y] = change_plotlabel(ax4,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'd','FontSize',12,'LineStyle','none','HorizontalAlignment','center','VerticalAlignment','top')

%% SAVE AS PNG

fig = gcf;
fig.PaperPositionMode = 'auto';
% print(fig, 'absresiduals_full2_linearInt1.png', '-dpng', '-r600')
% exportgraphics(gcf, 'Figure_SM15.pdf', 'ContentType', 'vector')

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none';
hgexport(fig, 'Figures/PDF_Versions/Figure_SM15.pdf', style);