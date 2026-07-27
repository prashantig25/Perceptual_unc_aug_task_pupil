% Figure S11: Plot heteroskedastic model.

clc
clearvars

%% LOAD DATA

currentDir = cd;
reqPath = 'GBSliderPupil_NatComms';
pathParts  = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end
het_save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', ...
                        'regression', 'control analyses for supplement');
betas_struct = importdata(fullfile(het_save_dir, "hetModel_linearInt_newSP.mat")); 
coeffs_name = importdata(fullfile(het_save_dir, "coeff_names_hetero.mat"));
x = linspace(-300, 2700, 300);
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids); % number of subjects
num_params = 10;
col = 300;

% PREPARE AND GET PERMUTATION TEST
perm = importdata(fullfile(het_save_dir, "perm_hetModel_linearInt_newSP.mat"));

%% PLOT SETTINGS
neutral = [7, 53, 94]/255;
font_name = 'Arial';
font_size = 7;
line_style = '-';

% Order of coefficients to plot
ncoeffs = [ ...
    find(strcmp(coeffs_name, 'PE')), ...
    find(strcmp(coeffs_name, 'PExCondiff')), ...
    find(strcmp(coeffs_name, 'Condiff')), ...
    find(strcmp(coeffs_name, 'RT')), ...
    find(strcmp(coeffs_name, 'UP')), ...
    find(strcmp(coeffs_name, 'xgaze')), ...
    find(strcmp(coeffs_name, 'ygaze')), ...
    find(strcmp(coeffs_name, 'omikron_0')), ...
    find(strcmp(coeffs_name, 'omikron_1'))];

ylabel_strings = [ ...
    "PE-modulated pupil", ...
    "Uncertainty-weighted PE pupil", ...
    "Uncertainty-modulated pupil", ...
    "RT-modulated pupil", ...
    "UP-modulated pupil", ...
    "x-gaze-modulated pupil", ...
    "y-gaze-modulated pupil", ...
    "Residual intercept", ...
    "Residual slope"];

pval_position = [2 0.5 -1 -1 0.5 3 3 10 3];
pval_sign = [1, 1, 1, -1, 1, 1, 1, 1, 1];
pval_text_dist = 0.05;

%% TILED LAYOUT

fig = figure;

% Size in CM
width_cm = 17;
height_cm = 16;
set(fig, 'Units', 'centimeters');
set(fig, 'Position', [10, 10, width_cm, height_cm]);
set(fig, 'PaperUnits', 'centimeters');
set(fig, 'PaperSize', [width_cm, height_cm]);
set(fig, 'PaperPosition', [0, 0, width_cm, height_cm]);

hold on
tiledlayout(3,4);
ax1 = nexttile(1,[1,1]);
ax2 = nexttile(2,[1,1]);
ax3 = nexttile(3,[1,1]);
ax4 = nexttile(4,[1,1]);
ax5 = nexttile(5,[1,1]);
ax6 = nexttile(6,[1,1]);
ax7 = nexttile(7,[1,1]);
ax8 = nexttile(8,[1,1]);
ax9 = nexttile(9,[1,1]);

ax1_new = ax1;
ax2_new = ax2;
ax3_new = ax3;
ax4_new = ax4;
ax5_new = ax5;
ax6_new = ax6;
ax7_new = ax7;
ax8_new = ax8;
ax9_new = ax9;
axes_new = [ax1_new, ax2_new, ax3_new, ax4_new, ax5_new, ax6_new, ax7_new,  ax8_new, ax9_new];
axes_old = [ax1, ax2, ax3, ax4, ax5, ax6, ax7, ax8, ax9];

% Read out the positions calculated by tiledlayout
first_plot_pos = axes_old(1).Position;
fifth_plot_pos = axes_old(5).Position;
ninth_plot_pos = axes_old(9).Position;

start_left = first_plot_pos(1)-0.06; % inherit the exact left anchor from tile 1
row1_bottom = first_plot_pos(2); % vertical position for plots 1-4
row2_bottom = fifth_plot_pos(2); % vertical position for plot 5
row3_bottom = ninth_plot_pos(2); % vertical position for plot 5

plot_width = first_plot_pos(3); % keep the precise width of the tile
plot_height = first_plot_pos(4); % keep the precise height of the tile

% Define fixed horizontal gap
horizontal_gap = 0.08;

% 9 subplots
letters = 'a':'i';   
data_plot = NaN(num_subjs, col);

for a = 1:length(ncoeffs)

    if a <= 4 && a<=8
        % Top row
        exact_left = start_left + (a - 1) * (plot_width + horizontal_gap);
        current_bottom = row1_bottom;
    elseif a > 4 && a<=8
        % Bottom row
        col_idx = a - 4;
        exact_left = start_left + (col_idx - 1) * (plot_width + horizontal_gap);
        current_bottom = row2_bottom;
    else 
        % Bottom row
        col_idx = a - 8;
        exact_left = start_left + (col_idx - 1) * (plot_width + horizontal_gap);
        current_bottom = row3_bottom;
    end

    % Construct the position vector
    new_pos = [exact_left, current_bottom, plot_width, plot_height];

    % Generate the updated axis layer
    axes_new(a) = axes('Units', 'Normalized', 'Position', new_pos);

    % Generate the updated axis layer
    box(axes_new(a), 'off'); % remove box
    delete(axes_old(a)); % delete old axis

    hold on;

    current_idx = ncoeffs(a);

    for s = 1:num_subjs
        for c = 1:col
            data_plot(s,c) = betas_struct.with_intercept(1, current_idx, s, c);
        end
    end

    % Compute Mean and SEM
    yAvg = mean(data_plot);
    ySem = std(data_plot) ./ sqrt(num_subjs);

    % Plot Shaded Error Bar
    shadedErrorBar(x, yAvg, ySem, {'LineWidth', 2, 'Color', neutral}, 1);
    
    % Adjust Axes
    ylabel(ylabel_strings(:,a), 'FontName', font_name, 'FontSize', font_size);
    xlim([-300, 2700]);
    xline(0, '--k', 'HandleVisibility', 'off');
    yline(0, '--k', 'HandleVisibility', 'off');
    xlabel('Time since feedback (ms)', 'FontName', font_name, 'FontSize', font_size);
    set(gca, 'FontName', font_name, 'FontSize', font_size);

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
% print(fig, 'coeffs_HeteroSkedasticModel_linearInt20SP.png', '-dpng', '-r600')
% exportgraphics(gcf, 'Figure_SM11.pdf', 'ContentType', 'vector')

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none'; 
hgexport(fig, 'Figures/PDF_Versions/Figure_SM11.pdf', style);
