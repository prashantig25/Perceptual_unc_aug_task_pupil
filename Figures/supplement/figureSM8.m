% Figure S8: Plot results from all regressors of the pupil analysis.

clc
clearvars

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
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_linearInt.mat")); % add PE bin curves
coeff_names = betas_struct.coeff_names; % importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_linearInt_coeffNames.mat")); % add PE bin curves
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_linearInt.mat")); % add PE bin curves
[~,high_PU,mid_PU,low_PU,~,~,~,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
x = linspace(-300, 2700, 300); % x-axis
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids); % number of subjects
neutral = [7, 53, 94]/255;
font_name = 'Arial';
font_size = 7;

%% TILED LAYOUT

fig = figure;

% Size in CM
width_cm = 17;
height_cm = 10.5;
set(fig, 'Units', 'centimeters');
set(fig, 'Position', [10, 10, width_cm, height_cm]);
set(fig, 'PaperUnits', 'centimeters');
set(fig, 'PaperSize', [width_cm, height_cm]);
set(fig, 'PaperPosition', [0, 0, width_cm, height_cm]);

hold on
tiledlayout(2,4);
ax1 = nexttile(1,[1,1]);
ax2 = nexttile(2,[1,1]);
ax3 = nexttile(3,[1,1]);
ax4 = nexttile(4,[1,1]);
ax5 = nexttile(5,[1,1]);
ax1_new = ax1;
ax2_new = ax2;
ax3_new = ax3;
ax4_new = ax4;
ax5_new = ax5;
axes_new = [ax1_new, ax2_new, ax3_new, ax4_new, ax5_new];
axes_old = [ax1, ax2, ax3, ax4, ax5];

%% PLOT COEFFICIENT CURVES

ylabel_strings = {'Uncertainty-modulated pupil', 'UP-modulated pupil', 'RT-modulated pupil', 'x-gaze-modulated pupil', 'y-gaze-modulated pupil'};
condiff_idx = find(strcmp(coeff_names,'zsc_condiff'));
ygaze_idx = find(strcmp(coeff_names,'ygaze'));
xgaze_idx = find(strcmp(coeff_names,'xgaze'));
up_idx = find(strcmp(coeff_names,'zsc_up'));
rt_idx = find(strcmp(coeff_names,'rt'));
ncoeffs = [condiff_idx, up_idx, rt_idx, xgaze_idx, ygaze_idx]; % order of coefficients

ylim_lower = [-0.02, -0.02, -0.1, -0.1, -0.1]; % lower limit of y-axis
ylim_upper = [0.01, 0.08, 0.1, 0.1, 0.1]; % upper limit of y-axis

% Read out the positions calculated by tiledlayout
first_plot_pos = axes_old(1).Position;
fifth_plot_pos = axes_old(5).Position;

start_left = first_plot_pos(1)-0.06; % inherit the exact left anchor from tile 1
row1_bottom = first_plot_pos(2); % vertical position for plots 1-4
row2_bottom = fifth_plot_pos(2); % vertical position for plot 5
plot_width = first_plot_pos(3); % keep the precise width of the tile
plot_height = first_plot_pos(4); % keep the precise height of the tile

% Define fixed horizontal gap
horizontal_gap = 0.08;

% Some parameters
color_cell = {neutral};
col = 300;

for a = 1:length(ncoeffs)

    if a <= 4
        % Top row
        exact_left = start_left + (a - 1) * (plot_width + horizontal_gap);
        current_bottom = row1_bottom;
    else
        % Bottom row
        col_idx = a - 4;
        exact_left = start_left + (col_idx - 1) * (plot_width + horizontal_gap);
        current_bottom = row2_bottom;
    end

    % Construct the position vector
    new_pos = [exact_left, current_bottom, plot_width, plot_height];

    % Generate the updated axis layer
    axes_new(a) = axes('Units', 'Normalized', 'Position', new_pos);

    % Generate the updated axis layer
    box(axes_new(a), 'off'); % remove box
    delete(axes_old(a)); % delete old axis

    % PLOT
    data_plot = zeros(num_subjs,col);
    for s = 1:num_subjs
        for c = 1:col
            data_plot(s,c) = betas_struct.with_intercept(1,ncoeffs(a),s,c);
        end
    end
    hold on
    color = color_cell;
    ySignal = mean(data_plot);
    color = cell2mat(color_cell);
    shadedErrorBar(x, ySignal, std(data_plot, 0)./sqrt(num_subjs), {'LineWidth', 2, "Color", color(1,:)},1)

    % PLOT P-VALUE
    ylim_axes = [ylim_lower(a),ylim_upper(a)];
    [pval_pos] = create_pvalpos(ylim_axes);
    plot(x(find(perm.mask(ncoeffs(a),:) == 1)), 2.5*ones(1, length(find(perm.mask(ncoeffs(a),:) == 1))), '.', 'color', ...
        [119, 119, 119]./255, 'markersize', 4);

    % Compute summary p-values (minimum across timepoints), rounded to 3 decimal places
    pval = round(min(perm.prob(ncoeffs(a),:)), 3);

    % Format as strings
    if pval < 0.001
        pval_str = "\itp\rm < 0.001";
    else
        pval_str = sprintf("\\itp\\rm = %.3f", pval);
    end

    text(mean(x(perm.mask(ncoeffs(a),:) == 1)), pval_pos + 2.5,pval_str, "FontSize", font_size, "FontName",...
        font_name, "VerticalAlignment", "bottom" ,"HorizontalAlignment", "center")

    % ADJUST FIGURE PROPERTIES
    adjust_figprops(axes_new(a),font_name, font_size, 0.5)
    xlim([-300,2700])
    xline(0,'--')
    yline(0,'--')
    xlabel('Time since feedback (ms)')
    ylabel(ylabel_strings(:,a))
end

%% ADD SUBPLOT LABELS

ax1_pos = axes_new(a).Position;
adjust_x = -0.06; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.02; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(axes_new(1),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(axes_new(2),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(axes_new(3),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(axes_new(4),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'd','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(axes_new(5),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'e','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

%% SAVE AS PNG

fig = gcf;
fig.PaperPositionMode = 'auto';
% print(fig, 'reg_full2_linearInt1.png', '-dpng', '-r600')
% exportgraphics(gcf, 'Figures/PDF_Versions/Figure_SM8.pdf', 'ContentType', 'vector')

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none';
hgexport(fig, 'Figures/PDF_Versions/Figure_SM8.pdf', style);