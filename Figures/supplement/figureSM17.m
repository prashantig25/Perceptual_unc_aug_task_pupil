% Figure S17: Plots results of the model-based analyses of patch-locked pupil
% response.

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
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"patch_condiff_linearInt_gazeCorrected.mat")); % add PE bin curves
coeffs_names = betas_struct.coeff_names; % importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"patch_condiff_linearInt_coeffNames.mat")); % add PE bin curves
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_patch_linearInt_gazeCorrected.mat")); % add PE bin curves

xgaze_idx = find(strcmp(coeffs_names, 'xgaze')); 
ygaze_idx = find(strcmp(coeffs_names, 'ygaze')); 
condiff_idx = find(strcmp(coeffs_names, 'zsc_condiff')); 
condition_idx = find(strcmp(coeffs_names, 'condition_2')); 

x = linspace(-300, 2700, 300); % x-axis
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids); % number of subjects
neutral = [7, 53, 94]/255;
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
tiledlayout(1, 4);
ax1 = nexttile(1, [1, 1]);
ax2 = nexttile(2, [1, 1]);
ax3 = nexttile(3, [1, 1]);
ax4 = nexttile(4, [1, 1]);
ax1_new = ax1;
ax2_new = ax2;
ax3_new = ax3;
ax4_new = ax4;
axes_new = [ax1_new, ax2_new, ax3_new, ax4_new];
axes_old = [ax1, ax2, ax3, ax4];

%% PLOT COEFFICIENT CURVES

ylabel_strings = ["x-gaze-modulated pupil", "x-gaze-modulated pupil", "Uncertainty-modulated pupil", "Low reward uncertainty"];
ncoeffs = [xgaze_idx, ygaze_idx, condiff_idx, condition_idx]; % order in which coefficients are to be plotted
pval_position = [5, 5, 0, 0]; % position to plot p-value
pval_sign = [1, 1, 1, 1];
pval_text_dist = 0.05;

% Update subplot placing
first_plot_pos = axes_old(1).Position; 
start_left = first_plot_pos(1)-0.06; % inherit the exact left anchor from tile 1
row1_bottom = first_plot_pos(2); % vertical position for plots 1-4
plot_width = first_plot_pos(3); % keep the precise width of the tile
plot_height = first_plot_pos(4); % keep the precise height of the tile

% Define fixed horizontal gap 
horizontal_gap = 0.08;

% 4 subplots
letters = 'a':'d';

for a = 1:length(ncoeffs)

    exact_left = start_left + (a - 1) * (plot_width + horizontal_gap);
    current_bottom = row1_bottom;

    % Construct the position vector
    new_pos = [exact_left, current_bottom, plot_width, plot_height];
    
    % Generate the updated axis layer
    axes_new(a) = axes('Units', 'Normalized', 'Position', new_pos);

    box(axes_new(a), 'off'); % remove box
    delete(axes_old(a)); % delete old axis

    color_cell = {neutral}; % colors for low and high perceptual uncertainty data
    col = 300; % length of x-axis

    % PLOT
    data_plot = zeros(num_subjs,col);
    for s = 1:num_subjs
        for c = 1:col
            data_plot(s,c) = betas_struct.with_intercept(1,ncoeffs(a),s,c);
        end
    end
    
    ySignal = mean(data_plot);
    hold on
    color = cell2mat(color_cell);
    shadedErrorBar(x, ySignal, std(data_plot,0)./sqrt(num_subjs), {'LineWidth', 2, "Color", color(1,:)},1)

    % ADJUST FIGURE PROPERTIES
    adjust_figprops(axes_new(a), font_name, font_size, 0.5)
    xlim([-300, 2700])
    xline(0,'--')
    yline(0,'--')
    xlabel('Time since patch (ms)')
    ylabel(ylabel_strings(:, a))

    % PLOT PERMUTATION TEST
    printPermTest(perm, x, ncoeffs(a), pval_position(a), pval_sign(a), pval_text_dist, font_size, font_name)

    hold on
    % Subplot label (a, b, c, ...)
    text(-0.4, 1.05, letters(a), ...
        'Units', 'normalized', ...
        'FontSize', 12, ...
        'FontWeight', 'normal');
    box off;
end

%% SAVE AS PNG
 
fig = gcf; 
fig.PaperPositionMode = 'auto'; 
% print(fig, 'patch_regression_linearInt1.png', '-dpng', '-r600') 
% exportgraphics(gcf, 'Figure_SM17.pdf', 'ContentType', 'vector')

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none';
hgexport(fig, 'Figures/PDF_Versions/Figure_SM17.pdf', style);