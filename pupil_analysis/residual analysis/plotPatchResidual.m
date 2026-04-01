clc
clearvars

%% Load data
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
numSubjs = length(num_sess);

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

%% =================== FIT PUPIL-AUGMENTED MODEL ========================

for n = 1:numSubjs
    
    % --- Data Loading & Filtering ---
    behv_data = [];
    for j = 1:num_sess(n)
        filename = fullfile(behv_dir, [subj_ids{n}, '_main', num2str(j), '.xlsx']);
        if strcmp(subj_ids{n}, '4672')
            filename = fullfile(behv_dir, [subj_ids{n}, '_main', num2str(j), '_red.xlsx']);
        end
        data_run = readtable(filename,'VariableNamingRule', 'preserve');
        rt = table(data_run.("choice.rt"), 'VariableNames', {'rt'});
        slider = table(data_run.("slider_respond.response"), 'VariableNames', {'slider'});
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
    
    % load pupil data
    filename = strcat(pupil_dir,filesep,subj_ids{n},'.mat');
    pupilSignal = importdata(filename);
    pupilSignal(missedTrials_slider == 1,:) = [];
    
    % Loop over the pupil timepoints
    for c = 1:col_patch
        subjData.pupil = pupilSignal(:,c);
        subjData.pupil = nanzscore(subjData.pupil);
        
        % Model 1: Full Model (ecoperf ~ 1 + pupil + condiffZsc + condition + muZsc)
        mdlfull = fitglm(subjData,'ecoperf','ecoperf ~ 1 + pupil + condiffZsc + condition + muZsc','CategoricalVars','condition','Distribution','binomial','Link','logit');
        betas_pupil_full_patch(n,c,1) = mdlfull.Coefficients.Estimate(5); % Pupil Beta is the 5th coefficient
        betas_nonpupil_full_patch_coeff2(n,c,1) = mdlfull.Coefficients.Estimate([2]); % Pupil Beta is the 2nd coefficient
        betas_nonpupil_full_patch_coeff3(n,c,1) = mdlfull.Coefficients.Estimate([3]); % Pupil Beta is the 3rd coefficient
        betas_nonpupil_full_patch_coeff4(n,c,1) = mdlfull.Coefficients.Estimate([4]); % Pupil Beta is the 4th coefficient
    end
    
    % Store non-pupil betas from the FULL model (using the last time point)
    betas_nonPupil_patch(n, :) = mdlfull.Coefficients.Estimate([2,3,4]); % Condiff, Condition, MuZsc coefficients
    disp(['Patch - Processed subject: ' subj_ids{n}]);
end

% Permutation test
perm_results = get_permtest(1, numSubjs, col_patch, betas_pupil_full_patch, ...
                            zeros(numSubjs, col_patch), 0, 0);

%% PLOT FOR REBUTTAL - UPDATED STYLE

% get mean of the non-pupil regressors
meanCoeff2 = nanmean(betas_nonpupil_full_patch_coeff2,2);
meanCoeff3 = nanmean(betas_nonpupil_full_patch_coeff3,2);
meanCoeff4 = nanmean(betas_nonpupil_full_patch_coeff4,2);

% do ttest
patch_betas = [meanCoeff2, meanCoeff3, meanCoeff4];
[h, pVals] = ttest(patch_betas);

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

figure('Position', [200, 200, 450, 200])
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
max_vals = repelem(max(max_vals),3);

xticklabs = {'', '', ''};

% Create bar plot using bar_plots_pval
h = bar_plots_pval(y, mean_all, SEM_all, num_subjs, 3, 1, {''}, ...
    [1, 2, 3], xticklabs, '', '', ...
    'Regression coefficient', 1, 1, 20, 1, font_size, linewidth_plot, font_name, 0, ...
    darkblue_muted, bar_labels, max_vals);

% Adjust figure properties
ylim_vals = [min(mean_all) - 0.5, max(max_vals) + 0.15];
xlim_vals = [0.5, 3.5];
adjust_figprops(ax1_new, font_name, font_size, line_width, xlim_vals, ylim_vals);

% Manually draw multiline x-tick labels
multiline_labs = {
    sprintf('Perceptual\ncondition'), ...
    sprintf('Contrast\ndifference'), ...
    sprintf('Reward prob.\n(previous trial)')
};

set(ax1_new, 'XTickLabels', {});   % clear any residual labels
yl = ylim(ax1_new);
label_y = yl(1) - 0.02 * diff(yl); % adjust vertical offset as needed

for i = 1:3
    text(ax1_new, i, label_y, multiline_labs{i}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'top', ...
        'FontName', font_name, ...
        'FontSize', font_size);
end


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
perm = perm_results;
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
ylabel('Mean beta coefficient', 'FontWeight', 'normal', 'FontSize', font_size);
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

%% Save figure

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'coeffs_logRegModel_pupil.png', '-dpng', '-r600')

%% Save stats

results = table({}, [], 'VariableNames', {'term', 'pval'});
results = [results; table({'pupil_choicePhase'},    round(min(perm_results.prob(1, perm_results.mask(1,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'condiff_choicePhase'},  round(pVals(1), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'condition_choicePhase'}, round(pVals(2), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'muZsc_choicePhase'},    round(pVals(3), 3), 'VariableNames', {'term', 'pval'})];
writetable(results, fullfile('patchResidual_stats.csv'));
 
