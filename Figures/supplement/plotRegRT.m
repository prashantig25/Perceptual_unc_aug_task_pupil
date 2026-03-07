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

%% --- Fit Baseline Model (RT ~ 1 + condiffZsc + condition + pe) ---

for s = 1:length(subj_ids)

    preds = preds_all(preds_all.id == str2double(subj_ids{s}), :);
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

    subjData.logRT = log(subjData.rt);
    subjData.peZsc = nanzscore(subjData.pe);
    mdlRT = fitlm(subjData,'logRT','logRT ~ 1 + condiffZsc + condition + peZsc','CategoricalVars','condition');

    betas_RT(s,:) = mdlRT.Coefficients.Estimate(2:end);

end

% =================== 2. STATISTICAL ANALYSIS AND PLOTTING ========================

% 1. Calculate Mean and Standard Error of the Mean (SEM)
mean_betas = mean(betas_RT, 1); % Mean across subjects (rows)
SEM_betas = std(betas_RT, 0, 1) / sqrt(numSubjs); % SEM across subjects

% 2. Perform One-Sample T-tests (against mu=0)
p_values = NaN(1, size(betas_RT, 2));
t_stats = NaN(1, size(betas_RT, 2));

for i = 1:size(betas_RT, 2)
    % Null hypothesis: mean(betas_RT(:, i)) = 0
    [~, p_values(i), ~, stats] = ttest(betas_RT(:, i));
    t_stats(i) = stats.tstat; 
end

% 3. Prepare data for bar_plots_pval function
% Reshape data: stack all groups vertically
y = [betas_RT(:,1); betas_RT(:,2); betas_RT(:,3)]; % (numSubjs*3) x 1

% Reshape means and SEMs
mean_all = mean_betas'; % 3 x 1
SEM_all = SEM_betas'; % 3 x 1

% Prepare significance labels
bar_labels = cell(1, 3);
for i = 1:3
    if p_values(i) < 0.001
        bar_labels{i} = 'p < 0.001';
    else
        bar_labels{i} = ['p = ' num2str(round(p_values(i), 3))];
    end
end


% Calculate max y positions for significance stars
max_vals = zeros(1, 3);
for i = 1:3
    max_beta = max(betas_RT(:, i));
    max_vals(i) = max(mean_betas(i) + SEM_betas(i), max_beta) + 0.02;
end

% Predictor labels
xticklabs = {
    ['Perceptual'], ...
    ['Uncertainty'], ...
    ['Absolute PE']
};

% Face color for bars
[~,high_PU,mid_PU,low_PU,color_screen,fb_green,darkblue_muted,mix,perc,rew,~,~,binned_dots,~,...
    ~,~,~,~,~] = colors_rgb(); % colors

% 4. Create the Bar Plot using bar_plots_pval
figure('Position',[100,100,200,200])
h = bar_plots_pval(y, mean_all, SEM_all, numSubjs, 3, 1, {''}, ...
    [1,2,3], xticklabs, 'Explaining reaction-times (RT)', '', ...
    'Regression Coefficient', 1, 1, 10, 1, 7, 0.5, 'Arial', 0, ...
    darkblue_muted, bar_labels, max_vals);

% Additional customization
ylim([-0.25, 0.25])
xlim([0.5, 3.5])
hold on
plot(xlim, [0 0], 'k--', 'LineWidth', 1); % Add horizontal line at y=0
hold off

% Save statistics
termString = {"condition";"condiff";"PE"};
T = table(termString, round(p_values,3).', 'VariableNames', {'term', 'pValuesRT'});
saveStat = fullfile(desiredPath,"data","GB data two pipelines","pupil","stats");
safe_saveall(strcat(saveStat, filesep, 'RTRegression.csv'), T);

% Save figure
fig = gcf;
fig.PaperPositionMode = 'auto';
print(fig, 'coeffs_logRT.png', '-dpng', '-r600')

