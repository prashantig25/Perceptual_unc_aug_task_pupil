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
num_blocks = 8;

% Initialization
betas_baseline = NaN(numSubjs, 3);
subj_AIC       = NaN(numSubjs, 1);
subj_BIC       = NaN(numSubjs, 1);
subj_Rsquared  = NaN(numSubjs, 1);
subj_residuals = cell(numSubjs, 1);

currentDir = cd;
reqPath    = 'Perceptual_unc_aug_task_pupil-main';
pathParts  = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end
preds_file = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'LR analyses', 'preprocessed_lr_pupil.xlsx');
preds_all  = readtable(preds_file);

%% --- Fit Model: RT (current) ~ 1 + condiffZsc (current) + condition (current) + PE (previous trial, within block) ---

betas_RT = NaN(length(subj_ids), 3);

for s = 1:length(subj_ids)

    preds = preds_all(preds_all.id == str2double(subj_ids{s}), :);
    for h = 1:height(preds)
        if preds.congruence(h) == 0
            preds.mu_congruence(h) = 1-preds.mu(h);
        else
            preds.mu_congruence(h) = preds.mu(h);
        end
    end

    subjData     = preds;
    subjData_all = [];

    for b = 1:num_blocks
        blockData = subjData(subjData.blocks == b, :);

        % Delete trial 1 within this block
        blockData = blockData(blockData.trial ~= 1, :);

        if height(blockData) < 2; continue; end

        % Shift PE within this block only — no cross-block associations
        pe_prev          = [NaN; blockData.pe(1:end-1)];
        blockData.pe_prev = pe_prev;

        % Remove first row (NaN pe_prev)
        blockData = blockData(~isnan(blockData.pe_prev), :);

        subjData_all = [subjData_all; blockData];
    end

    if isempty(subjData_all); continue; end

    subjData_all.condiffZsc = nanzscore(subjData_all.con_diff);
    subjData_all.muZsc      = nanzscore(subjData_all.mu_congruence);
    subjData_all.logRT      = log(subjData_all.rt);
    subjData_all.pe_prevZsc = nanzscore(subjData_all.pe_prev);

    mdlRT = fitlm(subjData_all, 'logRT ~ 1 + condiffZsc + condition + pe_prevZsc', ...
        'CategoricalVars', 'condition');

    betas_RT(s,:) = mdlRT.Coefficients.Estimate(2:end);

end

% =================== 2. STATISTICAL ANALYSIS AND PLOTTING ========================

% 1. Calculate Mean and SEM
mean_betas = mean(betas_RT, 1);
SEM_betas  = std(betas_RT, 0, 1) / sqrt(numSubjs);

% 2. One-Sample T-tests against 0
p_values = NaN(1, size(betas_RT, 2));
t_stats  = NaN(1, size(betas_RT, 2));

for i = 1:size(betas_RT, 2)
    [~, p_values(i), ~, stats] = ttest(betas_RT(:, i));
    t_stats(i) = stats.tstat;
end

% 3. Prepare data for bar_plots_pval
y        = [betas_RT(:,1); betas_RT(:,2); betas_RT(:,3)];
mean_all = mean_betas';
SEM_all  = SEM_betas';

% Significance labels
bar_labels = cell(1, 3);
for i = 1:3
    if p_values(i) < 0.001
        bar_labels{i} = '\itp\rm < 0.001';
    else
        bar_labels{i} = ['\itp\rm = ' num2str(round(p_values(i), 3))];
    end
end

% Max y positions for significance stars
max_vals = zeros(1, 3);
for i = 1:3
    max_beta    = max(betas_RT(:, i));
    max_vals(i) = max(mean_betas(i) + SEM_betas(i), max_beta) + 0.01;
end
max_vals = repelem(max(max_vals),3);

% Predictor labels
xticklabs = {
    ['Perceptual'], ...
    ['Uncertainty'], ...
    ['Previous trial |PE|']
};

% Colors
[~,high_PU,mid_PU,low_PU,color_screen,fb_green,darkblue_muted,mix,perc,rew,~,~,binned_dots,~,...
    ~,~,~,~,~] = colors_rgb();

% 4. Bar Plot

xticklabs = {'', '', ''};
figure('Position',[100,100,250,250])
h = bar_plots_pval(y, mean_all, SEM_all, numSubjs, 3, 1, {''}, ...
    [1,2,3], xticklabs, '', '', ...
    'Regression coefficient', 1, 1, 10, 1, 7, 0.5, 'Arial', 0, ...
    darkblue_muted, bar_labels, max_vals);

ylim([-0.25, 0.29])
xlim([0.5, 3.5])
hold on
plot(xlim, [0 0], 'k--', 'LineWidth', 1);
hold off

% Manually draw multiline x-tick labels
multiline_labs = {
    sprintf('Perceptual\ncondition'), ...
    sprintf('Contrast\ndifference'), ...
    sprintf('Absolute PE\n(previous trial)')
};

% set(gcf, 'XTickLabels', {});   % clear any residual labels
yl = ylim(gca);
label_y = yl(1) - 0.02 * diff(yl); % adjust vertical offset as needed

for i = 1:3
    text(gca, i, label_y, multiline_labs{i}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'top', ...
        'FontName', 'Arial', ...
        'FontSize', 7);
end
% 
% Save statistics
termString = {"condition"; "condiff"; "PE_prevTrial"};
T = table(termString, round(p_values,3).', 'VariableNames', {'term', 'pValuesRT'});
saveStat = fullfile(desiredPath,"data","GB data two pipelines","pupil","stats");
safe_saveall(strcat(saveStat, filesep, 'RTRegression_previousTrial.csv'), T);

% Save figure
fig = gcf;
fig.PaperPositionMode = 'auto';
print(fig, 'coeffs_logRT_previousTrial.png', '-dpng', '-r600')