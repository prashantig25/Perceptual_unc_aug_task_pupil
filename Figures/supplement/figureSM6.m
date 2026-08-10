% Figure S6: Plot results from all regressors of the binned pupil analysis.

clc
clearvars

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
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff2bins_linearInt.mat")); % add PE bin curves
coeff_names = betas_struct.coeff_names;
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff2bins_linearInt.mat")); % add PE bin curves

[~,high_PU,mid_PU,low_PU,~,~,~,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
x = linspace(-300, 2700, 300); % x-axis
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids); % number of subjects
font_name = 'Arial'; % font name
font_size = 7; % font size
fontsize_label = 12; % font size for subplot labels
line_style = '-'; % line style

%% TILED LAYOUT

fig = figure;

% Size in CM
width_cm = 17;
height_cm = 6;
set(fig, 'Units', 'centimeters');
set(fig, 'Position', [10, 10, width_cm, height_cm]);
set(fig, 'PaperUnits', 'centimeters');
set(fig, 'PaperSize', [width_cm, height_cm]);
set(fig, 'PaperPosition', [0, 0, width_cm, height_cm]);

hold on
tiledlayout(1,4);
ax1 = nexttile(1,[1,1]);
ax2 = nexttile(2,[1,1]);
ax3 = nexttile(3,[1,1]);
ax4 = nexttile(4,[1,1]);
axes_old = [ax1, ax2, ax3, ax4];
ax1_new = ax1;
ax2_new = ax2;
ax3_new = ax3;
ax4_new = ax4;
axes_new = [ax1_new, ax2_new, ax3_new, ax4_new];

%% PLOT COEFFICIENTS

ylabel_strings = {'UP-modulated pupil', 'RT-modulated pupil', 'x-gaze-modulated pupil', 'y-gaze-modulated pupil'};

up_idx = find(strcmp(coeff_names, 'zsc_up'));
rt_idx = find(strcmp(coeff_names, 'rt'));
xgaze_idx = find(strcmp(coeff_names, 'xgaze'));
ygaze_idx = find(strcmp(coeff_names, 'ygaze'));
ncoeffs = [up_idx, rt_idx, xgaze_idx, ygaze_idx]; % order of coefficients

% Update subplot placing
first_plot_pos = axes_old(1).Position;
start_left = first_plot_pos(1)-0.06; % inherit the exact left anchor from tile 1
row1_bottom = first_plot_pos(2); % vertical position for plots 1-4
plot_width = first_plot_pos(3); % keep the precise width of the tile
plot_height = first_plot_pos(4); % keep the precise height of the tile

% Define fixed horizontal gap
horizontal_gap = 0.08;

% Number of categories
cats = [1, 2];
color_cell = {high_PU; low_PU}; % colors for low and high perceptual uncertainty data
col = 300; % number of time points

for a = 1:length(ncoeffs)

    % Position subplot automatically
    % ------------------------------

    % Left and bottom
    exact_left = start_left + (a - 1) * (plot_width + horizontal_gap);
    current_bottom = row1_bottom;

    % Construct the position vector
    new_pos = [exact_left, current_bottom, plot_width, plot_height];

    % Generate the updated axis layer
    axes_new(a) = axes('Units', 'Normalized', 'Position', new_pos);
    box(axes_new(a), 'off'); % remove box
    delete(axes_old(a)); % delete old axis

    % PLOT FOR EACH OF THE BIN CATEGORIES
    handle = cell(2);
    for j = cats
        data_plot = zeros(num_subjs,col);
        for s = 1:num_subjs
            for c = 1:col
                data_plot(s,c) = betas_struct.with_intercept(j, ncoeffs(a), s, c);
            end
        end
        hold on

        color = color_cell;
        ySignal = mean(data_plot);
        handle{j} = plot(x, ySignal, "Color", color{j,:}, 'LineWidth',2);
        color = cell2mat(color_cell);
        shadedErrorBar(x, ySignal, std(data_plot, 0)./sqrt(num_subjs), {'LineWidth', 2, "Color", color(j,:)}, 1);

    end

    % PLOT PERMUTATION TEST RESULTS
    disp_perm = 1;
    if disp_perm == 1
        if a == 1
            multFactor = 35;
        else
            multFactor = 0;
        end
        plot(x(find(perm.mask(ncoeffs(a),:) == 1)), multFactor * ones(1, length(find(perm.mask(ncoeffs(a),:) == 1))), '.', 'color', ...
            [119, 119, 119]./255, 'markersize', 4);
    end

    % Compute dynamic p-value string for this coefficient
    if any(perm.mask(ncoeffs(a),:) == 1)
        perm_prob_a = perm.prob(ncoeffs(a),:);
        perm_mask_a = perm.mask(ncoeffs(a),:);
        pval_a = min(perm_prob_a(perm_mask_a == 1));
        if pval_a < 0.001
            pval_str_a = "\itp\rm < 0.001";
        else
            pval_str_a = sprintf("\\itp\\rm = %.3f", pval_a);
        end
        if a == 1
            pPos = 35.5;
        else
            pPos = 0.5;
        end
        text(mean(x(perm.mask(ncoeffs(a),:) == 1)), pPos, pval_str_a, "FontSize",font_size,"FontName",font_name,"VerticalAlignment","bottom","HorizontalAlignment","center")
    end

    % ADJUST FIGURE PROPERTIES
    adjust_figprops(axes_new(a),font_name,font_size,0.5)
    xlim([-300,2700])
    xline(0,'--')
    yline(0,'--')
    xlabel('Time since feedback (ms)')
    ylabel(ylabel_strings(:,a))
end

l = legend([handle{2}, handle{1}], 'Low state uncertainty', 'High state uncertainty', 'Location', 'NorthEast', 'EdgeColor', ...
    'none', 'AutoUpdate', 'off', 'FontSize', font_size,'FontName', font_name,'Color', 'none');
l.ItemTokenSize = [7 7];
legend_pos = l.Position;
l.Position = legend_pos + [0.05, 0.05, 0.0, 0.0];

%% ADD SUBPLOT LABELS

ax1_pos = axes_new(a).Position;
adjust_x = -0.07; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.05; % adjusted y-position for subplot label
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


%% SAVE AS PNG

fig = gcf;
fig.PaperPositionMode = 'auto';
% print(fig, 'binnedreg_full2_linearInt1.png', '-dpng', '-r600')
% exportgraphics(gcf, 'Figures/PDF_Versions/Figure_SM6.pdf', 'ContentType', 'vector')

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none';
hgexport(fig, 'Figures/PDF_Versions/Figure_SM6.pdf', style);