clc
clearvars

% =================== 1. INITIAL SETUP AND BASELINE MODEL FIT ========================
data = readtable("/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/" + ...
    "Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/" + ...
    "GB data peak corrected/behavior/model fitting/preprocessed_lr_pupil_no_zerope.xlsx");
uniqueID = unique(data.id);
data.ID = data.id;

% Pre-calculate mu_congruence
for h = 1:height(data)
    if data.congruence(h) == 0
        data.mu_congruence(h) = 1-data.mu(h);
    else
        data.mu_congruence(h) = data.mu(h);
    end
end
numSubjs = length(uniqueID);
data.condiff_relative = (data.contrast_left - data.contrast_right) ./ 2;

% Load auxiliary data
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");

% Initialization for Baseline Model
betas_baseline = NaN(numSubjs, 3);
subj_AIC = NaN(numSubjs, 1);
subj_BIC = NaN(numSubjs, 1);
subj_Rsquared = NaN(numSubjs, 1);
subj_residuals = cell(numSubjs,1);

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
preds_file = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'LR analyses', 'preprocessed_lr_pupil.xlsx');
preds_all = readtable(preds_file);
behv_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'raw data');
pupil_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'pupil signal', 'patch linear int');

col_patch = 130;
betas_pupil_full_patch = NaN(numSubjs, col_patch, 1);
betas_nonpupil_full_patch_coeff2 = NaN(numSubjs, col_patch, 1);
betas_nonpupil_full_patch_coeff3 = NaN(numSubjs, col_patch, 1);
betas_nonpupil_full_patch_coeff4 = NaN(numSubjs, col_patch, 1);
betas_nonPupil_patch = NaN(numSubjs, 3); % NEW: Store non-pupil betas from the Full Patch Model

% =================== FIT PUPIL-AUGMENTED MODEL ========================
for n = 1:numSubjs
    % --- Data Loading & Filtering ---
    behv_data = [];
    for j = 1:num_sess(n)
        filename = fullfile(behv_dir, [subj_ids{n}, '_main', num2str(j), '.xlsx']);
        if strcmp(subj_ids{n}, '4672')
            filename = fullfile(behv_dir, [subj_ids{n}, '_main', num2str(j), '_red.xlsx']);
        end
        data_run = readtable(filename);
        rt = table(data_run.choice_rt, 'VariableNames', {'rt'});
        slider = table(data_run.slider_respond_response, 'VariableNames', {'slider'});
        data_run = [data_run(:, 1:16), rt, slider];
        behv_data = [behv_data; data_run];
    end
    missedtrials = isnan(behv_data.rt);
    behv_data(missedtrials == 1, :) = [];
    missedTrials_slider = isnan(behv_data.slider);

    
    preds = preds_all(preds_all.id == str2double(subj_ids{n}), :);
    
    for h = 1:height(preds)
        if preds.congruence(h) == 0
            preds.mu_congruence(h) = 1-preds.mu(h);
        else
            preds.mu_congruence(h) = preds.mu(h);
        end
    end
    
    subjData = preds;
    subjData.condiffZsc = nanzscore(subjData.con_diff);
    subjData.muZsc = nanzscore(subjData.mu_congruence);
    
    filename = strcat(pupil_dir,filesep,subj_ids{n},'.mat');
    pupilSignal = importdata(filename);
    pupilSignal(missedTrials_slider == 1,:) = [];
    
    % --- Time-Point Loop ---
    for c = 1:col_patch
        subjData.pupil = pupilSignal(:,c);
        subjData.pupil = nanzscore(subjData.pupil);
        
        % Model 1: Full Model (ecoperf ~ 1 + pupil + condiffZsc + condition + muZsc)
        mdlfull = fitglm(subjData,'ecoperf','ecoperf ~ 1 + pupil + condiffZsc + condition + muZsc','CategoricalVars','condition','Distribution','binomial','Link','logit');
        betas_pupil_full_patch(n,c,1) = mdlfull.Coefficients.Estimate(5); % Pupil Beta is the 5th coefficient
        betas_nonpupil_full_patch_coeff2(n,c,1) = mdlfull.Coefficients.Estimate([2]); % Pupil Beta is the 5th coefficient
        betas_nonpupil_full_patch_coeff3(n,c,1) = mdlfull.Coefficients.Estimate([3]); % Pupil Beta is the 5th coefficient
        betas_nonpupil_full_patch_coeff4(n,c,1) = mdlfull.Coefficients.Estimate([4]); % Pupil Beta is the 5th coefficient
    end
    
    % Store non-pupil betas from the FULL model (using the last time point)
    betas_nonPupil_patch(n, :) = mdlfull.Coefficients.Estimate([2,3,4]); % Assuming Condiff, Condition, MuZsc are 3rd, 4th, 5th coefficients
    disp(['Patch - Processed subject: ' subj_ids{n}]);
end

meanCoeff2 = nanmean(betas_nonpupil_full_patch_coeff2,2);
meanCoeff3 = nanmean(betas_nonpupil_full_patch_coeff3,2);
meanCoeff4 = nanmean(betas_nonpupil_full_patch_coeff4,2);

num_subjs = 47;  % Example: Number of participants

% Example time points (REPLACE with your actual values)
col_patch = 130;
col_fb = 250;

% --- 2. DEFINE STRUCTURE FOR TESTS  ---

% Define individual columns (4x1 vertical cell arrays)
Label = {'Pupil dilation explains choice performance'};

% NOTE: The actual beta data for Var1
Var1_Data = {betas_pupil_full_patch;};

% Define Var2_Data (The baselines - all zeros for test vs. zero)
Var2_Data = {zeros(num_subjs, col_patch)};

Col_Len = {col_patch};

% Two_Tailed_Flag is set to 0 for all test-vs-zero logic
Two_Tailed = {0};
Betas_Flag = {0};

Color_RGB = {[0.2 0.4 0.8]};

% --- Combine columns into the final 'tests' cell array (4x7) ---
tests = [Label, Var1_Data, Var2_Data, Col_Len, Two_Tailed, Betas_Flag, Color_RGB];


% --- 3. LOOP THROUGH ALL TESTS AND RUN PERMUTATION ---
perm_results = cell(size(tests, 1), 1);

for i = 1:size(tests, 1)

    % Access the 7 columns directly using the correct (row, column) index
    label = tests{i, 1};
    var1_data = tests{i, 2};
    var2_data = tests{i, 3};
    col_len = tests{i, 4};
    two_tailed = tests{i, 5};
    betas_flag = tests{i, 6};
    color = tests{i, 7};


    fprintf('Running permutation test for: %s (N=%d, Time=%d)\n', label, num_subjs, col_len);

    % Run the Permutation Test
    perm_results{i} = get_permtest(1, num_subjs, col_len, var1_data, var2_data, two_tailed, betas_flag);

end

%% PLOT FOR REBUTTAL - UPDATED STYLE

clc

% Define plotting parameters (matching style from reference)
linewidth_plot = 0.5;      % line-width for axes
linewidth_curves = 2;      % line-width for curves
line_width = 0.5;          % line width for axes
font_size = 7;             % font size
font_name = 'Arial';       % font name
num_subjs = size(betas_pupil_full_patch, 1);  % number of subjects

% Get colors
[~, high_PU, mid_PU, low_PU, ~, ~, darkblue_muted, ~, ~, ~, ~, light_gray, binned_dots, ~, ...
    reg_color, ~, ~, ~, ~] = colors_rgb();
neutral = [7, 53, 94]/255;

% TILE LAYOUT

figure('Position', [200, 200, 400, 200])
t = tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

ax1 = nexttile(1);
ax2 = nexttile(2);

% SUBPLOT 1: BEHAVIORAL REGRESSORS (BAR PLOT)

% POSITION CHANGE
change = [0.05, 0.005, -0.1, 0];
new_pos = change_position(ax1, change);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax1_new, 'off');
delete(ax1);

% Prepare data for bar_plots_pval
patch_betas = [meanCoeff2, meanCoeff3, meanCoeff4];
[h, pVals] = ttest(patch_betas);

% Reshape data for bar_plots_pval function
% Stack all three predictors vertically
y = [patch_betas(:,1); patch_betas(:,2); patch_betas(:,3)];

% Calculate means and SEMs
mean_all = nanmean(patch_betas, 1)';  % 3 x 1
SEM_all = nanstd(patch_betas, 0, 1)' / sqrt(num_subjs);  % 3 x 1

% Prepare significance labels
bar_labels = cell(1, 3);
for i = 1:3
    if pVals(i) < 0.001
        bar_labels{i} = sprintf('\\itp\\rm < 0.001');
    else
        bar_labels{i} = sprintf('\\itp\\rm = %.3f', pVals(i));
    end
end

% Calculate max y positions for significance labels
max_vals = zeros(1, 3);
for i = 1:3
    max_beta = max(patch_betas(:, i));
    max_vals(i) = max(mean_all(i) + SEM_all(i), max_beta) + 0.05;
end

% X-tick labels (multi-line)
xticklabs = {
    ['Perceptual' newline 'condition'], ...
    ['Contrast' newline 'difference'], ...
    ['Reported reward prob.' newline 'on previous trial']
};

% Create bar plot using bar_plots_pval
h = bar_plots_pval(y, mean_all, SEM_all, num_subjs, 3, 1, {''}, ...
    [1, 2, 3], xticklabs, '', '', ...
    'Regression Coefficient', 1, 1, 20, 1, font_size, linewidth_plot, font_name, 0, ...
    darkblue_muted, bar_labels, max_vals);

% Adjust figure properties
ylim_vals = [min(mean_all) - 0.5, max(max_vals) + 0.1];
xlim_vals = [0.5, 3.5];
adjust_figprops(ax1_new, font_name, font_size, line_width, xlim_vals, ylim_vals);

% Add horizontal line at zero
hold on
plot(xlim, [0 0], 'k--', 'LineWidth', linewidth_plot);
hold off

% Title
title('Behavioral Predictors', 'FontWeight', 'Normal', 'FontSize', font_size + 1);

% SUBPLOT 2: PUPIL TIME-COURSE (TIME SERIES PLOT)

% POSITION CHANGE
change = [0.0, 0.005, 0.01, 0];
new_pos = change_position(ax2, change);
ax2_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax2_new, 'off');
delete(ax2);

% Prepare pupil time series data
data_ts = squeeze(betas_pupil_full_patch);
perm = perm_results{1};
safe_saveall("perm_residualPatch.mat", perm);

col_len = size(data_ts, 2);
time_points = linspace(-300, 1000, 130);

% Calculate mean and SEM
mean_ts = nanmean(data_ts, 1);
sem_ts = nanstd(data_ts, 0, 1) ./ sqrt(sum(~isnan(data_ts), 1));

% Plot with shaded error bar
hold on
plot(time_points, mean_ts, ...
    'Color', darkblue_muted, 'LineStyle', '-', 'LineWidth', linewidth_curves);
shadedErrorBar(time_points, mean_ts, ...
    sem_ts, ...
    {'Color', darkblue_muted, 'LineWidth', linewidth_curves}, 1);

% Add reference lines
xline(0, 'LineStyle', '--', 'LineWidth', linewidth_plot, 'Color', 'k');
yline(0, 'LineStyle', '--', 'LineWidth', linewidth_plot, 'Color', 'k');

% Add significance mask
sig_indices = find(perm.mask(1, :) ~= 0);
if ~isempty(sig_indices)
    prob_sig = perm.prob(:, sig_indices);
    probPEondiff_mean_hetCS = mean(prob_sig);
    
    % Get y-limits for positioning
    ylim_axes = ylim;
    pval_pos = ylim_axes(1) + 0.03 * diff(ylim_axes);
    
    % Plot significance markers
    plot(time_points(sig_indices), pval_pos * ones(1, length(sig_indices)), '.', ...
        'Color', [119, 119, 119]./255, 'MarkerSize', 4);
    
    % Add p-value text
    mid_point = time_points(sig_indices(round(length(sig_indices)/2)));
    text(mid_point, pval_pos - 0.02 * diff(ylim_axes), ...
        sprintf('\\itp\\rm = %.3f', probPEondiff_mean_hetCS), ...
        'FontName', font_name, 'FontSize', font_size, ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'center','FontAngle','italic');
end

% Adjust figure properties
xlim([-300, 1000]);
adjust_figprops(ax2_new, font_name, font_size, linewidth_plot);

% Labels
xlabel('Time since patch onset (ms)', 'FontSize', font_size);
ylabel('Mean Beta Coefficient', 'FontWeight', 'normal', 'FontSize', font_size);
title('Pupil dilation in choice phase', 'FontWeight', 'Normal', 'FontSize', font_size + 1);

hold off

% ADD SUBPLOT LABELS

% Label for subplot 1
ax1_pos = ax1_new.Position;
adjust_x = -0.09;
adjust_y = ax1_pos(4); % + 0.04;
[label_x, label_y] = change_plotlabel(ax1_new, adjust_x, adjust_y);
annotation('textbox', [label_x label_y .05 .05], 'String', 'a', ...
    'FontSize', 12, 'LineStyle', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

% Label for subplot 2
[label_x, label_y] = change_plotlabel(ax2_new, adjust_x, adjust_y);
annotation('textbox', [label_x label_y .05 .05], 'String', 'b', ...
    'FontSize', 12, 'LineStyle', 'none', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

%% 

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'coeffs_logRegModel_pupil.png', '-dpng', '-r600') 
