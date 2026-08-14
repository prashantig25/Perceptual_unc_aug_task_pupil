% Figure SM2: Reaction-time regression

clc
clearvars

currentDir = cd;
reqPath = 'GBSliderPupil_NatComms';
pathParts = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end
preds_file = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'LR analyses', 'preprocessed_lr_pupil.xlsx');
preds_all  = readtable(preds_file);
data = readtable(fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'LR analyses', 'preprocessed_lr_pupil_no_zerope.xlsx'));
uniqueID = unique(data.id);
numSubjs = length(uniqueID);
font_size = 7;
font_name = 'Arial';

% Load auxiliary data
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
num_blocks = 8;

%% Fit Model: RT (current) ~ 1 + condiffZsc (current) + condition (current) + PE (previous trial, within block)

% Initialize coefficients
betas_RT = NaN(length(subj_ids), 3);

% Cycle over subjects
for s = 1:length(subj_ids)

    % Extract data
    preds = preds_all(preds_all.id == str2double(subj_ids{s}), :);

    % Extract subject data
    subjData = preds;

    % Initialize variable for combined dat
    subjData_all = [];

    % Cycle over blocks
    for b = 1:num_blocks

        % Extract block data
        blockData = subjData(subjData.blocks == b, :);

        % Delete trial 1 within this block
        blockData = blockData(blockData.trial ~= 1, :);

        % Skip any block that has fewer than 2 trials, because there isn't
        % enough data to shift PE for the analysis. This happend in one
        % subject because of firealarm at FU.
        if height(blockData) < 2
            continue
        end

        % Shift PE within this block only — no cross-block associations
        pe_prev = [NaN; blockData.pe(1:end-1)];
        blockData.pe_prev = pe_prev;

        % Remove first row (NaN pe_prev)
        blockData = blockData(~isnan(blockData.pe_prev), :);

        % Combine all data
        subjData_all = [subjData_all; blockData];
    end

    % Prepare data for regression model
    subjData_all.condiffZsc = nanzscore(subjData_all.con_diff);
    subjData_all.logRT = log(subjData_all.rt);
    subjData_all.pe_prevZsc = nanzscore(subjData_all.pe_prev);

    % Fit model
    mdlRT = fitlm(subjData_all, 'logRT ~ 1 + condiffZsc + condition + pe_prevZsc', ...
        'CategoricalVars', 'condition');

    % Store coefficients
    betas_RT(s,:) = mdlRT.Coefficients.Estimate(2:end);

end

% STATISTICAL ANALYSIS AND PLOTTING

% Calculate Mean and SEM
mean_betas = mean(betas_RT, 1);
SEM_betas  = std(betas_RT, 0, 1) / sqrt(numSubjs);

% One-Sample T-tests against 0
p_values = NaN(1, size(betas_RT, 2));
ci = NaN(1, size(betas_RT, 2));
CI_low = NaN(1, size(betas_RT, 2));
CI_high = NaN(1, size(betas_RT, 2));
t_stats = NaN(1, size(betas_RT, 2));
df = NaN(1, size(betas_RT, 2));

for i = 1:size(betas_RT, 2)
    [~, p_values(i), ci, stats] = ttest(betas_RT(:, i));
    CI_low(i) = ci(1);
    CI_high(i) = ci(2);
    t_stats(i) = stats.tstat;
    df(i) = stats.df;
end

% Prepare data for bar_plots_pval
y = [betas_RT(:,1); betas_RT(:,2); betas_RT(:,3)];
mean_all = mean_betas';
SEM_all = SEM_betas';

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
    max_beta = max(betas_RT(:, i));
    max_vals(i) = max(mean_betas(i) + SEM_betas(i), max_beta) + 0.01;
end
max_vals = repelem(max(max_vals),3);

% Colors
[~,high_PU,mid_PU,low_PU,color_screen,fb_green,darkblue_muted,mix,perc,rew,~,~,binned_dots,~,...
    ~,~,~,~,~] = colors_rgb();

% Bar Plot
xticklabs = {'', '', ''};

fig = figure; 
set(fig, 'Visible', 'on'); 
 
% Size in CM 
width_cm = 6;  
height_cm = 7; 
set(fig, 'Units', 'centimeters'); 
set(fig, 'Position', [10, 10, width_cm, height_cm]); 
set(fig, 'PaperUnits', 'centimeters'); 
set(fig, 'PaperSize', [width_cm, height_cm]); 
set(fig, 'PaperPosition', [0, 0, width_cm, height_cm]); 

h = bar_plots_pval(y, mean_all, SEM_all, numSubjs, 3, 1, {''}, ...
    [1,2,3], xticklabs, '', '', ...
    'Regression coefficient', 1, 1, 10, 1, 7, 0.5, 'Arial', 0, ...
    darkblue_muted, bar_labels, max_vals);

ylim([-0.25, 0.29])
xlim([0.5, 3.5])

% Manually draw multiline x-tick labels
multiline_labs = {
    sprintf('Experimental\ncondition'), ...
    sprintf('Contrast\ndifference'), ...
    sprintf('Absolute PE\n(previous trial)')
    };

yl = ylim(gca);
label_y = yl(1) - 0.02 * diff(yl); % adjust vertical offset as needed

for i = 1:3
    text(gca, i, label_y, multiline_labs{i}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'top', ...
        'FontName', font_name, ...
        'FontSize', font_size);
end

% Save statistics
termString = {"condition"; "condiff"; "PE_prevTrial"};
T = table(termString, ...
    round(t_stats,3).', ...
    df.', ...
    round(mean_betas,3).', ...
    round(SEM_betas,3).', ...
    round(CI_low,3).', ...
    round(CI_high,3).', ...
    round(p_values,3).', ...
    'VariableNames', {'term','t_stat','df','mean','SEM','CI_low','CI_high','pValuesRT'});

saveStat = fullfile(desiredPath,"data","GB data two pipelines","pupil","stats");
safe_saveall(strcat(saveStat, filesep, 'RTRegression_previousTrial.csv'), T);

% Print for stat check
display(T);

% Save figure
fig = gcf;
fig.PaperPositionMode = 'auto';
%print(fig, 'coeffs_logRT_previousTrial.png', '-dpng', '-r600')
%exportgraphics(gcf, 'Figures/PDF_Versions/Figure_SM2.pdf', 'ContentType', 'vector')

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none'; 
hgexport(fig, 'Figures/PDF_Versions/Figure_SM2.pdf', style);