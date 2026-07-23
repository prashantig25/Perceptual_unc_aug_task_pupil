% Figure 2: Plot task, choice and learning behavior.

% INITIALISE VARIABLES
clc
clearvars
[~,high_PU,mid_PU,low_PU,color_screen,fb_green,darkblue_muted,mix,perc,rew,~,~,binned_dots,~,...
    ~,~,~,~,~] = colors_rgb(); % colors
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids); % number of subjects
save_csv = 1; % save stats for 2(d) in CSV file for overleaf

% Path setup
currentDir = cd;
reqPath = 'GBSliderPupil_NatComms';
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

descriptive_path = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'descriptive (n = 47)');
regression_path  = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'LR analyses');

% Load all required data
mix_curve = importdata(fullfile(descriptive_path, "mix_curve.mat")); % learning curves
perc_curve = importdata(fullfile(descriptive_path, "perc_curve.mat"));
mean_curves(1,:) = mean(mix_curve);
mean_curves(2,:) = mean(perc_curve);
sem_curves(1,:) = std(mix_curve)./sqrt(num_subjs);
sem_curves(2,:) = std(perc_curve)./sqrt(num_subjs);
data_subjs = readtable(fullfile(regression_path, "preprocessed_lr_pupil_no_zerope.xlsx")); % preprocessed LR data
betas_all = importdata(fullfile(regression_path, "betas_signed.mat")); % betas from signed analysis
[~, p_vals] = ttest(betas_all);
id_subjs = unique(data_subjs.id);

% General font size
font_size = 7;

%% INITIALISE TILE LAYOUT

fig = figure;

% Size in CM
width_cm = 17; 
height_cm = 10.5; 
set(fig, 'Units', 'centimeters');
set(fig, 'Position', [10, 10, width_cm, height_cm]);
set(fig, 'PaperUnits', 'centimeters');
set(fig, 'PaperSize', [width_cm, height_cm]);
set(fig, 'PaperPosition', [0, 0, width_cm, height_cm]);

t = tiledlayout(3,8);
t.Padding = 'compact';
t.TileSpacing = 'compact';
ax3 = nexttile(5,[2 4]);
ax5 = nexttile(17,[1 2]);
ax10 = nexttile(19,[1 2]);
ax12 = nexttile(21,[1,1]);
ax11 = nexttile(22,[1,1]);
ax15 = nexttile(23,[1,2]);
ax1 = nexttile(1,[2,4]);

%% PLOT TRIAL PROCEDURE

% POSITION CHANGE
position_change = [0, 0.03, -0.05, 0]; % change in position
new_pos = change_position(ax1,position_change);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos); % new position
set(ax1_new, 'FontSizeMode', 'manual');
set(ax1_new, 'ActivePositionProperty', 'position');
box(ax1_new, 'on'); % box on
delete(ax1); % delete old axis

% Define coordinates for task screens
start_x = 0.5;
start_y = 8;
adjust_x = 1.2;
adjust_y = 0.9;
num_screens = 8;
screen_width = 1.5;
screen_height = 1;

% PLOT SCREENS
dyn_xpos = start_x;
dyn_ypos = start_y;
for n = 1:num_screens
    rectangle('Position', [dyn_xpos dyn_ypos screen_width screen_height], 'LineWidth', 0.7, ...
        'FaceColor', [200, 200, 200]./255)
    dyn_xpos = dyn_xpos + adjust_x;
    dyn_ypos = dyn_ypos - adjust_y;
    axis([0 11 0 11]);
end

% Define coordinates for fixation dots
fix_width = 0.08;
fix_height = 0.2;
radius = 0.03; % radius of the circle

% PLOT FIXATION DOT
dyn_xpos = start_x + screen_width/2;
dyn_ypos = start_y + screen_height/2;
for n = 1:num_screens
    if n == 4
        rectangle('Position', [dyn_xpos - radius dyn_ypos - radius, 2 * radius, 2 * radius],...
            'EdgeColor', 'k', 'FaceColor', 'k')
    elseif ~(n==6)
        rectangle('Position', [dyn_xpos - radius dyn_ypos - radius, 2 * radius, 2 * radius], ...
            'Curvature', [1, 1], 'EdgeColor', 'k', 'FaceColor', 'k');
    end

    if n<num_screens
        dyn_xpos = dyn_xpos + adjust_x;
        dyn_ypos = dyn_ypos - adjust_y;
    end
end

% PLOT SLIDER
center_X = dyn_xpos; % x-coordinate of the center
center_Y = 1.85; % y-coordinate of the center
line([dyn_xpos-0.6,dyn_xpos+0.6],[center_Y,center_Y],'color','k','LineWidth',1)
radius = 0.17./2; % radius of the circle
rectangle('Position', [center_X - radius, center_Y - radius, 2 * radius, 2 * radius], ...
    'Curvature', [1, 1], 'EdgeColor', 'k', 'FaceColor', 'w', 'LineWidth', 0.5);

% PLOT ARROW
linewidth_arrow = 0.5;
headlength_arrow = 5; % arrow headlength
ar1 = annotation('arrow', 'LineWidth', linewidth_arrow, 'HeadLength', headlength_arrow);
ar1.Parent = ax1_new;
ar1.X = [1 7];
ar1.Y = [7,2];

% ADD TEXTBOXES
all_strings = {'Fixation (1.6-2.1s)', 'Choice options (0.5s)', 'Delay (0.2-0.5s)',...
    'Go cue (1s)', 'Delay (0.5-1s)', 'Feedback (0.25s)', 'Delay (0.5-1s)', 'Slider (6s)'};
horzalign_trial = 'Left';
vertalign_trial = 'Top';
dyn_xpos = start_x;
dyn_ypos = start_y + screen_height + 0.25;

% Add text in loop
adjust_x = 1.2;
for n = 1:num_screens
    str = all_strings{1,n};
    text(dyn_xpos, dyn_ypos, all_strings{1,n}, FontSize=font_size);
    dyn_xpos = dyn_xpos + adjust_x;
    dyn_ypos = dyn_ypos - adjust_y;
    if n == 1
        dyn_xpos = dyn_xpos + 0.35;
    end
end

set(gca, 'Color', 'None')
box off
axis off

% CREATE BARS
font_name = 'Arial'; % font name
linewidth_axes = 0.5; % line width for axes
bar_width = 0.08; % width for bar plot
bar_height = 0.1; % height for bar plot
xpos = 0.35; % x-position
ypos = 0.8; % y-position
bar_data = [70, 90]; % bar data
ylabel_strings = {'','Value'}; % strings for y

% Plot bars with reward probabilities
axes('pos',[xpos ypos bar_width bar_height])
set(gca,'XColor', 'none', 'YColor', 'none')
b = bar(bar_data(1,:), 'BarWidth', 0.5, 'FaceAlpha', 0.7, 'LineWidth', 0.5);
b.FaceColor = 'flat';
b.CData(1,:) = darkblue_muted;
b.CData(2,:) = darkblue_muted;
ylim([50, 100])
yticks([50, 100])
ylabel('Probability (%)')
xlim([-0.05, 3.05])
xticks([1,2])
set(gca,'color', 'none', 'LineWidth', linewidth_axes, 'FontName', font_name)
set(gca,'Xticklabel',["High","Low"], 'FontSize', font_size, 'Yticklabel', ["50","100"])

% Rotate x-axis labels by 45 degrees
xtickangle(45)
title(["Reward", "uncertainty"], "FontWeight", "normal", "FontSize", font_size)
box off

% ADD TEXT ON BARS
groupOffset = [0, 0];
barWidth = b.BarWidth;
bar_text(b, groupOffset, barWidth, font_size, font_name)

%% PLOT S-A-R CONTINGENCY

% POSITION CHANGE
pos = ax3.Position + [0, 0,0,0];
ax3_new = axes('Units', 'Normalized', 'Position', pos);
box(ax3_new, 'on');
delete(ax3);

axis([0 1 0 1])
fontsize_title = 9; % font size for plot titles
title('Task contingency', 'FontWeight', 'normal', FontName=font_name, Position=[0.5, 0.95], ...
    Parent=ax3_new, FontSize=fontsize_title)
line([0 1], [0.89 0.89], 'Color', 'k', 'LineWidth', linewidth_axes);

% Symmetric area
axis(ax3_new, [0 1 0 1]);

% Box coordinates
col_centers = [0.28, 0.72];  
box_width = 0.25;            
box_height = 0.08;            
col_lefts = col_centers - (box_width / 2);
statebox_width = 0.10;
statebox_lefts = col_centers - (statebox_width / 2);

% Define separate alpha tracking handles for background fills
face_alpha_text = 0; % transparent for text boxes
face_alpha_img = 1.0; % fully opaque for the gray image backgrounds
bg_gray = [200, 200, 200]./255; % light gray color matrix

% MAIN GRID MATRIX
% Columns: { Y, LeftContent, RightContent, LeftBorder, RightBorder, BGColor, BGAlpha }
grid_matrix = {
    0.870, 'State 0',           'State 1',           'none', 'none', 'none',  face_alpha_text;       
    0.800, 'Right stronger',    'Left stronger',     'none', 'none', 'none',  face_alpha_text;       
    0.730, {'', ''}, {'', ''},  'k', 'k',            bg_gray,                 face_alpha_img;
    0.500, {'Left', 'Right'},   {'Left', 'Right'},   'k',        'k',        'none',  face_alpha_text;              
    0.34, '\mu = 0.7',         '\mu = 0.7',         'none',     'none',     'none',  face_alpha_text;           
    0.270, {'0.7', '0.3'},      {'0.3', '0.7'},      'k',        'k',        'none',  face_alpha_text               
};

% Alignment and style
horz_align = 'center'; 
vert_align = 'middle';
linewidth_box = 0.25;
line_style = '-';

% LOOP OVER ALL ELEMENTS
hold(ax3_new, 'on');
for r = 1:size(grid_matrix, 1)

    y_pos = grid_matrix{r, 1};
    content_L = grid_matrix{r, 2};
    content_R = grid_matrix{r, 3};
    border_L = grid_matrix{r, 4};
    border_R = grid_matrix{r, 5};
    row_bg = grid_matrix{r, 6};
    row_alpha = grid_matrix{r, 7};
    
    % Determine box widths (row 1 gets statebox_width, others get standard box_width)
    if r == 1
        w = statebox_width; l_edges = statebox_lefts;
    else
        w = box_width; l_edges = col_lefts;
    end
    
    % Plot left column object
    pos_L = [l_edges(1), y_pos, w, box_height];
    annotate_textbox(ax3_new, pos_L, content_L, font_name, font_size, ...
        horz_align, vert_align, row_bg, row_alpha, border_L, linewidth_box, line_style);
        
    % Plot right column object
    pos_R = [l_edges(2), y_pos, w, box_height];
    annotate_textbox(ax3_new, pos_R, content_R, font_name, font_size, ...
        horz_align, vert_align, row_bg, row_alpha, border_R, linewidth_box, line_style);
end

% SIDEBAR LABELS
xpos_rotated = 0.06; 

row_mapping = [4, 6, 3];
strings_rotated = {{'Economic', 'choice'}, {'Contingency', 'parameter'}, 'Stimulus'};

for n = 1:length(row_mapping)
    
    % Raw Y position
    target_y = grid_matrix{row_mapping(n), 1};
    
    % Add exactly half of box_height
    y_center_perfect = target_y + (box_height / 2);
    
    % Print
    txt = text(xpos_rotated, y_center_perfect, strings_rotated{n}, 'Parent', ax3_new);
    set(txt, 'FontName', font_name, 'FontSize', font_size, 'FontWeight', 'normal', ...
             'Rotation', 90, 'HorizontalAlignment', horz_align, 'VerticalAlignment', 'middle');
end

% HEADER
title('Task contingency', 'FontWeight', 'normal', 'FontName', font_name, ...
    'Position', [0.5, 0.95], 'Parent', ax3_new, 'FontSize', fontsize_title);

line([0 1], [0.89 0.89], 'Color', 'k', 'LineWidth', linewidth_axes, 'Parent', ax3_new);
arrow_y_start = 0.5 + box_height; 
a1 = annotation('arrow', [0.5, 0.5], [arrow_y_start, 0.4], 'LineWidth', 0.7, ...
    'Color', 'k', 'LineStyle', '-', 'LineWidth', linewidth_arrow, 'HeadLength', headlength_arrow);
a1.Parent = ax3_new;

% Adjust axes
set(ax3_new, 'Color', 'none', 'FontName', font_name);
box(ax3_new, 'off');
axis(ax3_new, 'off');

%% DESCRIPTIVE PLOTS

% POSITION CHANGE
position_change = [0, 0.05, -0.03, 0];
new_pos = change_position(ax5, position_change);
ax5_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax5_new, 'on');
delete(ax5);
adjust_figprops(ax5_new, font_name, font_size, linewidth_axes);

% PLOT SLIDER DATA
colors_name = [mix; perc]; % colors for plot lines
legend_names = {'High reward uncertainty','Low reward uncertainty'}; % legend names
title_name = {''}; % figure title
xlabelname = {'Trial'}; % x-axis label name
ylabelname = {'Slider response'}; % y-axis label name
x = 1:20; % x-axis
hold on
lg_curves(x, mean_curves, sem_curves, colors_name, legend_names, title_name,...
    xlabelname, ylabelname, font_size, 1.5, font_name, [0.075, 0.45, 0.1, 0.075])
xlim([1,20])
set(gca, 'color','none', 'FontName', font_name, 'FontSize', font_size, 'LineWidth', linewidth_axes)
yline(0.9, '--', "Color", 'k', LineWidth=0.5)
yline(0.7, '--', "Color", 'k', LineWidth=0.5)
ylim([0.5, 1])
annotation("textbox", [1, 0.95, 0.2, 0.04], 'LineWidth', linewidth_box,'String', ...
    ' Actual reward probability', 'FontSize', font_size, 'LineStyle', 'none', 'Color', 'k','FontName', font_name, ...
    'HorizontalAlignment', 'left', Parent=gca)
new_pos = change_position(ax10, position_change);
ax10_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax10_new, 'off');
delete(ax10);

% Compute bins
nbins = 10; % number of bins
bins = createCondiffBins(data_subjs.con_diff);

% Compute mean and SEM learning rates
data_subjs = renamevars(data_subjs, "id", "ID"); % rename ID to use same function
[avg_ydataLR, sem_ydataLR] = computeMeanLR(data_subjs, bins, nbins, num_subjs, id_subjs);

% Plot average LRs
[rho, pval] = plotMeanLR(avg_ydataLR, sem_ydataLR, nbins, binned_dots, 'Mean LR');
data_subjs = renamevars(data_subjs, "ID", "id"); % rename ID back
ylim([-0.02,0.18])

% Save data for manuscript
if save_csv == 1
    save_figures = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'stats','behavior');
    save_table = table("subplot_d", round(rho,2), round(pval,3), 8, 'VariableNames', {'name','rho','pval','df'});
    safe_saveall(strcat(save_figures, filesep, 'figure1d.csv'), save_table);
    disp("Single-trial LR");
    display(save_table);
end

%% PLOT BETA COEFFICIENTS

% INITIALISE VARS FOR PLOTTING COEFFICIENTS
regressors = [1,2]; % regressors that need to be plotted
axes_old = [ax12, ax11]; % names of old axes
ax11_new = ax11; % initialise new axes
ax12_new = ax12;
axes_new = [ax12_new, ax11_new];
position_change = [0, 0.05, -0.025, 0]; % position changes for each axes
adjust_position = 0.015;
ylim_lower = [-0.1, -0.1, -0.2]; % lower y-axis limit for each regressor
ylim_upper = [0.5, 0.35, 0.6]; % upper y-axis limit for each regressor
xlabelname = {''}; % x-axis label
ylabelname = {'Fixed LR','Uncertainty-adapted LR'}; % y-axis label name for each regressor  % 'Confirmation bias'
disp_pval = 0; % if p-val stars should be displayed on top of bars
scatter_dots = 1; % if single participant data should be scattered on top of bar
dot_size = 10; % scatter dot size
plot_err = 1; % if error bar should be plotted
disp_legend = [0,1]; % if legend should be displayed
xticklabs = {''}; % x-tick labels
y_label = 1; % if p-val stars to be displayed, initialise y-axis location
line_width = 0.5; % line width for plots
example_participant = 20; % example participant for plots
mdl = 'up ~ pe + pe:contrast_diff + pe:congruence + pe:pe_sign + pe:salience'; %model3; % which regression model
pred_vars = {'pe','salience','contrast_diff','congruence','condition','reward_unc','subj_est_unc' ...
    ,'reward','mu','pe_sign','pu'}; % cell array with names of predictor variables
resp_var = 'up'; % name of response variable
cat_vars = {'salience','congruence','condition','reward_unc','pe_sign'}; % cell array with names of categorical variables
num_vars = 5; % number of variables
weight_y_n = 0; % weighted regression

% PLOT
for r = 1:length(regressors)
    
    % CHANGE AXES POSITION
    new_pos = change_position(axes_old(r), position_change);
    axes_new(r) = axes('Units', 'Normalized', 'Position', new_pos);
    box(axes_new(r), 'off');
    delete(axes_old(r));
    
    set(axes_new(r), 'FontSizeMode', 'manual');
    set(axes_new(r), 'ActivePositionProperty', 'position');
    
    % GET MEAN AND SEM FOR BETAS
    selected_regressors = regressors(r);
    [mean_avg, mean_sd, coeffs_subjs] = prepare_betas(betas_all, selected_regressors, num_subjs);
    
    % GET STARS FOR CORRESPONDING REGRESSOR'S P-VALUES
    bar_labels = {'*'};
    pstars = pvals_stars(p_vals, selected_regressors, bar_labels, 0);
    title_name = string(pstars) + newline + " ";
    colors_name = darkblue_muted;
    
    hold on    
    h = bar_plots_pval(coeffs_subjs, mean_avg, mean_sd, num_subjs, ...
        length(selected_regressors), 1, {'Data', 'Example participant'}, ...
        [], xticklabs, title_name, xlabelname, ylabelname(r), disp_pval, scatter_dots, ...
        dot_size, plot_err, font_size, line_width, font_name, disp_legend(r), colors_name, ...
        bar_labels, y_label, [NaN,NaN], [0.5,1.5], example_participant, [0.5, 0.025, 0.25, 0.05]);
        
    h.BarWidth = 0.4;
    ylim_vals = [ylim_lower(r) ylim_upper(r)];
    xlim_vals = [0.5 1.5];
    
    adjust_figprops(axes_new(r), font_name, font_size, line_width, xlim_vals, ylim_vals);
end

%% ADD AN INTERACTION PLOT

data = data_subjs;
% FIT THE MODEL
for i = example_participant
    tbl = table(data.pe(and(data.id == id_subjs(i),data.pe ~= 0)), ...
        data.up(and(data.id == id_subjs(i),data.pe ~= 0)), ...
        round(data.norm_condiff(and(data.id == id_subjs(i),data.pe ~= 0)),2), ...
        data.contrast(and(data.id == id_subjs(i),data.pe ~= 0)),...
        data.condition(and(data.id == id_subjs(i),data.pe ~= 0)),...
        data.congruence(and(data.id == id_subjs(i),data.pe ~= 0)),...
        data.reward_unc(and(data.id == id_subjs(i),data.pe ~= 0)),...
        data.pe_sign(and(data.id == id_subjs(i),data.pe ~= 0)),...
        'VariableNames',{'pe','up','contrast_diff','salience','condition','congruence' ...
        ,'reward_unc','pe_sign'});

    [~,~,~,~,lm] = linear_fit(tbl,mdl,pred_vars,resp_var, ...
        cat_vars,num_vars,weight_y_n);
end

% POSITION CHANGE
position_change = [0, 0.05, -0.03, 0];
new_pos = change_position(ax15, position_change);
ax15_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax15_new, 'off');
delete(ax15);

% INTERACTION PLOT
hold on
h = plotInteraction(lm, 'contrast_diff', 'pe', 'predictions');
h(3).Color = low_PU;
h(2).Color = mid_PU;
h(1).Color = high_PU;
xlabel('Prediction error')
ylabel('Update')

title('')
adjust_figprops(ax15_new,font_name,font_size,line_width);
l = legend('Contrast diff.', '0', '0.5', '1', 'Location', 'northeast', 'AutoUpdate',...
    'off', 'FontSize', font_size);
l.Position = [0.76, 0.1700, 0.2710, 0.0400];

l.EdgeColor = 'none';
l.Color = 'none';
l.ItemTokenSize = [7 7];
box off
xline(0, "LineWidth", 0.5, LineStyle="--")
yline(0, "LineWidth", 0.5, LineStyle="--")

%% SUBPLOT LABELS

fontsize_label = 12;
ax1_pos = ax1_new.Position;
adjust_x = -0.06; % adjust x-position of subplot label
adjust_y = ax1_pos(4) - 0.05; % adjust y-position of subplot label
[label_x,label_y] = change_plotlabel(ax1_new, adjust_x,adjust_y);
annotation("textbox", [label_x label_y .05 .05], 'String', ...
    'a','FontSize', fontsize_label, 'LineStyle', 'none', 'HorizontalAlignment',horz_align)
adjust_y = ax1_pos(4) - 0.02;
[label_x,label_y] = change_plotlabel(ax3_new, adjust_x, adjust_y);
annotation("textbox",[label_x label_y .05 .05], 'String', ...
    'b','FontSize', fontsize_label, 'LineStyle', 'none','HorizontalAlignment', horz_align)
ax5_pos = ax5_new.Position;
adjust_y = ax5_pos(4) + 0.02;
adjust_x = -0.06;
[label_x,label_y] = change_plotlabel(ax5_new, adjust_x,adjust_y);
annotation("textbox", [label_x label_y .05 .05], 'String', ...
    'c', 'FontSize', fontsize_label, 'LineStyle', 'none', 'HorizontalAlignment', horz_align)
[label_x,label_y] = change_plotlabel(ax10_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05], 'String', ...
    'd', 'FontSize', fontsize_label, 'LineStyle', 'none', 'HorizontalAlignment', horz_align)
[label_x,label_y] = change_plotlabel(axes_new(1), adjust_x,adjust_y);
annotation("textbox", [label_x label_y .05 .05], 'String', ...
    'e', 'FontSize', fontsize_label, 'LineStyle', 'none', 'HorizontalAlignment', horz_align)
[label_x,label_y] = change_plotlabel(axes_new(2),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'f', 'FontSize', fontsize_label, 'LineStyle', 'none', 'HorizontalAlignment', horz_align)
[label_x,label_y] = change_plotlabel(ax15_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05], 'String', ...
    'g', 'FontSize', fontsize_label, 'LineStyle', 'none', 'HorizontalAlignment',horz_align)

%% SAVE AS PNG

fig = gcf; 
fig.PaperPositionMode = 'auto';
% print(fig, 'task_behavior_ReviewerResponse1.png', '-dpng', '-r600')

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none';
hgexport(fig, 'Figures/PDF_Versions/Figure_2.pdf', style);