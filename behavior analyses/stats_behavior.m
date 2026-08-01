%%%%%% RUN ALL SORTS OF SIGNIFICANCE TESTS AND SAVE OUTPUT FOR MANUSCRIPT 
%%%%%% AND FIGURES

% INITIALISE VARS
clc
clearvars

% USER-BASED PATH
currentDir = cd; % current directory
pathParts = strsplit(currentDir, filesep);
reqPath = 'GBSliderPupil_NatComms'; % to which directory one must save in
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
% Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end

save_behavior    = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'behavior', filesep, 'stats', filesep, 'behavior');
descriptive_path = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'behavior', filesep, 'descriptive (n = 47)');
regression_path  = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'behavior', filesep, 'LR analyses');

%% LOAD DATA

% descriptive choice data for study 2
mix_ecoperf = importdata("mix_ecoperf.mat");
perc_ecoperf = importdata("perc_ecoperf.mat");

% descriptive learning data
mix_curve = importdata(fullfile(descriptive_path,"mix_curve.mat")); % learning curves
perc_curve = importdata(fullfile(descriptive_path,"perc_curve.mat"));
mix_curve = nanmean(mix_curve,2);
perc_curve = nanmean(perc_curve,2);

% LR analysis
betas_all = importdata(fullfile(regression_path,"betas_signed.mat")); % betas from signed analysis 

%% DESCRIPTIVE ANALYSIS

% Comparison to chance performance
chance_level = 0.5; % Specify the chance level (e.g., 0.5 for a binary task)

ecoperf_mix_avg = nanmean(mix_ecoperf,2);
ecoperf_perc_avg = nanmean(perc_ecoperf,2);

% Initialise variables
h_vals = NaN(2,2);
p_vals = NaN(2,2);
t_vals = NaN(2,1);
df_vals = NaN(2,1);
mean_ecoperf = NaN(2,1);
sem_ecoperf = NaN(2,1);
ci_l = NaN(2,1);
ci_u = NaN(2,1);
cond_names = ["mix";"perc"];

% Perform a one-sample t-test
[h_vals(1,:), p_vals(1,:), ci_vals_mix, stats_mix] = ttest(ecoperf_mix_avg, chance_level); 
[h_vals(2,:), p_vals(2,:), ci_vals_perc, stats_perc] = ttest(ecoperf_perc_avg, chance_level);

t_vals(1,:) = stats_mix.tstat;
t_vals(2,:) = stats_perc.tstat;

df_vals(1,:) = stats_mix.df;
df_vals(2,:) = stats_perc.df;

% FIX: ci_vals_mix/ci_vals_perc are already CIs for the mean in original
% units (ttest's second argument only affects the p-value/t-stat, not
% the returned CI) -- do NOT add chance_level again.
ci_l = [ci_vals_mix(1); ci_vals_perc(1)];
ci_u = [ci_vals_mix(2); ci_vals_perc(2)];

[mean_ecoperf(1,:),sem_ecoperf(1,:)] = compute_mean_sem(ecoperf_mix_avg);
[mean_ecoperf(2,:),sem_ecoperf(2,:)] = compute_mean_sem(ecoperf_perc_avg);

% save output to .csv file for OVERLEAF
ttestResults = table(cond_names, round(h_vals(:,1),3), round(p_vals(:,1),3), ...
    round(t_vals,3), round(df_vals,3), round(mean_ecoperf,3), round(sem_ecoperf,3), round(ci_l,3), round(ci_u,3), ...
    'VariableNames', {'Condition', 'HValue', 'PValue', 'TStat', 'df','mean','sem', 'CI_Lower', 'CI_Upper'}); 

% Save the table as a CSV file
safe_saveall(strcat(save_behavior,filesep,'allconditions_chance_ttest47.csv'), ttestResults);
disp("Economic-choice performance");
display(ttestResults);

%% COHEN'S D FOR ECONOMIC PERFORMANCE ACROSS CONDITIONS

num_condition = 2; % number of conditions
cohen_d = NaN(num_condition,1); % initialise
ecoperf = [ecoperf_mix_avg,ecoperf_perc_avg];

for i = 1:num_condition
    cohen_d(i,1) = compute_cohen_ttest(nanmean(ecoperf(:,i)),chance_level,nanstd(ecoperf(:,i)));
end

% save output to .csv file for OVERLEAF
cohenResults = table(cond_names, round(abs(cohen_d),3), ...
    'VariableNames', {'Condition', 'cohend'}); % Create a table to store the t-test results
safe_saveall(strcat(save_behavior,filesep,'ecoperf_cohen47.csv'),cohenResults);
disp("Economic-choice performance Cohen's d");
display(cohenResults);

%% T-TEST TO COMPARE SLIDER DATA ACROSS UNCERTAINTIES

% Initialise variables
mix_avg = nanmean(mix_curve,2);
perc_avg = nanmean(perc_curve,2);
h_vals = NaN(1,1);
p_vals = NaN(1,1);
t_vals = NaN(1,1);
df_vals = NaN(1,1);
cohen_d = NaN(1,1);

% t-test
[h_vals(1,:), p_vals(1,:), ci_vals, stats_mixperc] = ttest(mix_avg, perc_avg);
cond_names_unc = ["mix_perc"];

t_vals(1,:) = stats_mixperc.tstat;
df_vals(1,:) = stats_mixperc.df;

cohen_d(1,1) = compute_cohend_paired(perc_avg, mix_avg);

% Save
ttestResults = table(cond_names_unc, round(h_vals(:,1),3), round(p_vals(:,1),3), ...
    round(t_vals,3), round(df_vals,3), round(abs(cohen_d),3), round(ci_vals(1),3), round(ci_vals(2),3), ...
    'VariableNames', {'Condition', 'HValue', 'PValue', 'TStat', 'df','cohen_d', 'CI_Lower', 'CI_Upper'});
safe_saveall(strcat(save_behavior,filesep,'mu_uncertainty_ttest47.csv'),ttestResults);
disp("Slider condition comparison");
display(ttestResults);

%% SAVE MEAN and SEM FOR SLIDER UPDATES ACROSS CONDITIONS

mean_mu = NaN(2,1);
sem_mu = NaN(2,1);
ci_l = NaN(2,1);
ci_u = NaN(2,1);
cond_names = ["mix";"perc"];
chance_level = 0.5;

[mean_mu(1,:),sem_mu(1,:)] = compute_mean_sem(mix_avg);
[mean_mu(2,:),sem_mu(2,:)] = compute_mean_sem(perc_avg);

[~, p1, ci_m, s1] = ttest(mix_avg, chance_level); 
[~, p2, ci_p, s2] = ttest(perc_avg, chance_level); 

ci_l = [ci_m(1); ci_p(1)];
ci_u = [ci_m(2); ci_p(2)];

ttestResults = table(cond_names, round([p1; p2],3), round([s1.tstat; s2.tstat],3), round([s1.df; s2.df],3), round(mean_mu,3), round(sem_mu,3), round(ci_l,3), round(ci_u,3), ...
    'VariableNames', {'Condition', 'PValue', 'TStat', 'df', 'mean', 'sem', 'CI_Lower', 'CI_Upper'});
safe_saveall(strcat(save_behavior,filesep,'mu_meansem47.csv'),ttestResults);
disp("Slider conditions against chance");
display(ttestResults);

%% COHEN'S D FOR SLIDER UPDATES ACROSS CONDITIONS

num_condition = 2;
cohen_d = NaN(num_condition,1);
mu = [mix_avg,perc_avg];
cond_names = ["mix";"perc"];

for i = 1:num_condition
    cohen_d(i,1) = compute_cohen_ttest(nanmean(mu(:,i)),chance_level,nanstd(mu(:,i)));
end

cohenResults = table(cond_names, round(abs(cohen_d),3), ...
    'VariableNames', {'Condition', 'cohend'}); 
safe_saveall(strcat(save_behavior,filesep,'mu_cohen47.csv'),cohenResults);
disp("Slider Cohen's d");
display(cohenResults);

%% T-TEST ON BETA COEFFICIENTS

cond_names = ["pe";"pe_condiff";"pe_salience";"pe_congruence";"pe_pesign"];
[h_vals, p_vals, ci_vals, stats] = ttest(betas_all); 
t_vals = stats.tstat;
df_vals = stats.df;

mean_beta = NaN(size(betas_all,2),1);
sem_beta = NaN(size(betas_all,2),1);
for i = 1:size(betas_all,2)
    [mean_beta(i,:),sem_beta(i,:)] = compute_mean_sem(betas_all(:,i));
end

ttestResults = table(cond_names, round(h_vals,3).', round(p_vals,3).', ...
    round(t_vals,3).', round(df_vals,3).', round(mean_beta,3), round(sem_beta,3), ...
    round(ci_vals(1,:).',3), round(ci_vals(2,:).',3),...
    'VariableNames', {'Condition', 'HValue', 'PValue', 'TStat', 'df','mean','sem', 'CI_Lower', 'CI_Upper'}); 
safe_saveall(strcat(save_behavior,filesep,'lr_betas_ttest.csv'),ttestResults);
disp("Learning rate betas");
display(ttestResults);

%% COHEN'S D FOR BETA COEFFICIENTS

num_vars = size(betas_all,2);
cohen_d = NaN(num_vars,1);
cond_names = ["pe";"pe_condiff";"pe_salience";"pe_congruence";"pe_pesign"];
for i = 1:num_vars
    cohen_d(i,1) = compute_cohen_ttest(nanmean(betas_all(:,i)),0,nanstd(betas_all(:,i)));
end

cohenResults = table(cond_names, round(abs(cohen_d),3), ...
    'VariableNames', {'Condition', 'cohend'});
safe_saveall(strcat(save_behavior,filesep,'lr_betas_cohen.csv'),cohenResults);
disp("Learning rate betas Cohen's d");
display(cohenResults);

%% T-TEST: ABSOLUTE PE ACROSS STATE UNCERTAINTY (FIGURE SM7)

% Reproduces the high-/low-state-uncertainty absolute-PE bins from
% figureSM7.m to save the underlying mean, SEM, and paired t-test stats.
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids);

data_subjs_pe = readtable(fullfile(regression_path, "preprocessed_lr_pupil_no_zerope.xlsx"));
id_subjs_pe = unique(data_subjs_pe.id);

binned_data = abs(data_subjs_pe.con_diff); % absolute contrast difference
nbins = 2; % number of bins
bin_edges = prctile(binned_data, 0:50:100); % percentile edges
bins = discretize(binned_data, bin_edges); % bin contrast differences
data_subjs_pe.lr = data_subjs_pe.up ./ data_subjs_pe.pe; % learning rates

% GET RID OF TRIALS WHERE PE = 0 AND OUTLIER LRs
run_id = data_subjs_pe.id(data_subjs_pe.pe ~= 0 & abs(data_subjs_pe.lr) <= 2);
y_data = abs(data_subjs_pe.pe(data_subjs_pe.pe ~= 0 & abs(data_subjs_pe.lr) <= 2));
bins = bins(data_subjs_pe.pe ~= 0 & abs(data_subjs_pe.lr) <= 2);

% MEAN ABSOLUTE PE for STATE-UNCERTAINTY BINS (bin 1 = high, bin 2 = low)
avg_ydata_bins = NaN(nbins,num_subjs);
for b = 1:nbins
    for n = 1:num_subjs
        bins_subj = bins(run_id == id_subjs_pe(n));
        y_data_subj = y_data(run_id == id_subjs_pe(n));
        avg_ydata_bins(b,n) = mean(y_data_subj(bins_subj == b));
    end
end

% SAVE MEAN AND SEM
cond_names = ["high"; "low"];
mean_pe = NaN(2,1);
sem_pe = NaN(2,1);
[mean_pe(1,:), sem_pe(1,:)] = compute_mean_sem(avg_ydata_bins(1,:).');
[mean_pe(2,:), sem_pe(2,:)] = compute_mean_sem(avg_ydata_bins(2,:).');

meansemResults = table(cond_names, round(mean_pe,3), round(sem_pe,3), ...
    'VariableNames', {'Condition','mean','sem'});
safe_saveall(strcat(save_behavior,filesep,'pe_uncertainty_meansem47.csv'), meansemResults);
disp("Absolute PE across state uncertainty: mean/SEM");
display(meansemResults);

% PAIRED T-TEST: HIGH VS LOW STATE UNCERTAINTY
[~, p_pe, ci_pe, stats_pe] = ttest(avg_ydata_bins(1,:).', avg_ydata_bins(2,:).');
cohen_d_pe = compute_cohend_paired(avg_ydata_bins(1,:).', avg_ydata_bins(2,:).');

ttestResults = table("highLow", round(p_pe,3), round(stats_pe.tstat,3), round(stats_pe.df,3), ...
    round(abs(cohen_d_pe),3), round(ci_pe(1),3), round(ci_pe(2),3), ...
    'VariableNames', {'Condition','PValue','TStat','df','cohenD','CI_Lower','CI_Upper'});
safe_saveall(strcat(save_behavior,filesep,'pe_uncertainty_ttest47.csv'), ttestResults);
disp("Absolute PE across state uncertainty: paired t-test");
display(ttestResults);

%% CONSOLIDATED SUMMARY OF ALL BEHAVIORAL STATS (FOR MANUSCRIPT REFERENCE)

% Reads back the CSVs saved above (rather than reusing in-script
% variables, which get overwritten across sections) and stitches them
% into a single table in the order the analyses appear in the paper.

mu_meansem   = readtable(strcat(save_behavior,filesep,'mu_meansem47.csv'));
mu_cohen     = readtable(strcat(save_behavior,filesep,'mu_cohen47.csv'));
mu_unc       = readtable(strcat(save_behavior,filesep,'mu_uncertainty_ttest47.csv'));
chance       = readtable(strcat(save_behavior,filesep,'allconditions_chance_ttest47.csv'));
ecoperf_coh  = readtable(strcat(save_behavior,filesep,'ecoperf_cohen47.csv'));
lr_ttest     = readtable(strcat(save_behavior,filesep,'lr_betas_ttest.csv'));
lr_cohen     = readtable(strcat(save_behavior,filesep,'lr_betas_cohen.csv'));
pe_meansem   = readtable(strcat(save_behavior,filesep,'pe_uncertainty_meansem47.csv'));
pe_ttest     = readtable(strcat(save_behavior,filesep,'pe_uncertainty_ttest47.csv'));

getRow = @(T, cond) T(strcmp(string(T.Condition), cond), :);

rows = {};

% 1-2: Slider response vs. chance (mix = high reward uncertainty, perc = low reward uncertainty)
for cond = ["mix","perc"]
    r_ms = getRow(mu_meansem, cond);
    r_c  = getRow(mu_cohen, cond);
    rows(end+1,:) = {"Slider response vs. chance", cond, r_ms.mean, r_ms.sem, ...
        r_ms.TStat, r_ms.df, r_ms.PValue, r_c.cohend, r_ms.CI_Lower, r_ms.CI_Upper}; %#ok<*SAGROW>
end

% 3: Slider response, task-condition effect (mix vs. perc)
r = getRow(mu_unc, "mix_perc");
rows(end+1,:) = {"Slider response: mix vs. perc", "mix_perc", NaN, NaN, ...
    r.TStat, r.df, r.PValue, r.cohen_d, r.CI_Lower, r.CI_Upper};

% 4-5: Economic-choice performance vs. chance (Supplementary Fig. 1)
for cond = ["mix","perc"]
    r_ch = getRow(chance, cond);
    r_c  = getRow(ecoperf_coh, cond);
    rows(end+1,:) = {"Economic-choice performance vs. chance", cond, r_ch.mean, r_ch.sem, ...
        r_ch.TStat, r_ch.df, r_ch.PValue, r_c.cohend, r_ch.CI_Lower, r_ch.CI_Upper};
end

% 6-10: Learning-rate regression betas vs. 0 (Fig. 2e/2f + control regressors)
for cond = ["pe","pe_condiff","pe_salience","pe_congruence","pe_pesign"]
    r_lr = getRow(lr_ttest, cond);
    r_c  = getRow(lr_cohen, cond);
    rows(end+1,:) = {"Learning-rate beta vs. 0", cond, r_lr.mean, r_lr.sem, ...
        r_lr.TStat, r_lr.df, r_lr.PValue, r_c.cohend, r_lr.CI_Lower, r_lr.CI_Upper};
end

% 11-12: Absolute PE by state uncertainty, descriptive (Fig. SM7)
for cond = ["high","low"]
    r_pe = getRow(pe_meansem, cond);
    rows(end+1,:) = {"Absolute PE by state uncertainty", cond, r_pe.mean, r_pe.sem, ...
        NaN, NaN, NaN, NaN, NaN, NaN};
end

% 13: Absolute PE, high vs. low state uncertainty (Fig. SM7)
r = getRow(pe_ttest, "highLow");
rows(end+1,:) = {"Absolute PE: high vs. low state uncertainty", "highLow", NaN, NaN, ...
    r.TStat, r.df, r.PValue, r.cohenD, r.CI_Lower, r.CI_Upper};

order = (1:size(rows,1)).';
summaryTable = table(order, string(rows(:,1)), string(rows(:,2)), ...
    round(cell2mat(rows(:,3)),3), round(cell2mat(rows(:,4)),3), round(cell2mat(rows(:,5)),3), ...
    round(cell2mat(rows(:,6)),3), round(cell2mat(rows(:,7)),3), round(cell2mat(rows(:,8)),3), ...
    round(cell2mat(rows(:,9)),3), round(cell2mat(rows(:,10)),3), ...
    'VariableNames', {'order','analysis','condition','mean','sem','TStat','df','PValue','cohenD','CILower','CIUpper'});

safe_saveall(strcat(save_behavior,filesep,'behavioral_stats_summary.csv'), summaryTable);
disp("Consolidated behavioral stats summary");
display(summaryTable);

%% CONSOLIDATED SUMMARY OF SUPPLEMENT BEHAVIORAL STATS (FOR MANUSCRIPT REFERENCE)

% Only covers the supplement analyses backed by behavioral CSVs:
% Supplementary Fig. 1 (economic-choice performance vs. chance) and
% Supplementary Fig. 7 (absolute PE by state uncertainty). The remaining
% supplement figures (SM2, SM4, SM6, SM8-17) are pupil-regression
% time-course analyses not covered by this script.

rows_supp = {};

% 1-2: Economic-choice performance vs. chance (Supplementary Fig. 1)
for cond = ["mix","perc"]
    r_ch = getRow(chance, cond);
    r_c  = getRow(ecoperf_coh, cond);
    rows_supp(end+1,:) = {"Economic-choice performance vs. chance (SM Fig. 1)", cond, r_ch.mean, r_ch.sem, ...
        r_ch.TStat, r_ch.df, r_ch.PValue, r_c.cohend, r_ch.CI_Lower, r_ch.CI_Upper}; %#ok<*SAGROW>
end

% 3-4: Absolute PE by state uncertainty, descriptive (Supplementary Fig. 7)
for cond = ["high","low"]
    r_pe = getRow(pe_meansem, cond);
    rows_supp(end+1,:) = {"Absolute PE by state uncertainty (SM Fig. 7)", cond, r_pe.mean, r_pe.sem, ...
        NaN, NaN, NaN, NaN, NaN, NaN};
end

% 5: Absolute PE, high vs. low state uncertainty (Supplementary Fig. 7)
r = getRow(pe_ttest, "highLow");
rows_supp(end+1,:) = {"Absolute PE: high vs. low state uncertainty (SM Fig. 7)", "highLow", NaN, NaN, ...
    r.TStat, r.df, r.PValue, r.cohenD, r.CI_Lower, r.CI_Upper};

order_supp = (1:size(rows_supp,1)).';
supplementSummaryTable = table(order_supp, string(rows_supp(:,1)), string(rows_supp(:,2)), ...
    round(cell2mat(rows_supp(:,3)),3), round(cell2mat(rows_supp(:,4)),3), round(cell2mat(rows_supp(:,5)),3), ...
    round(cell2mat(rows_supp(:,6)),3), round(cell2mat(rows_supp(:,7)),3), round(cell2mat(rows_supp(:,8)),3), ...
    round(cell2mat(rows_supp(:,9)),3), round(cell2mat(rows_supp(:,10)),3), ...
    'VariableNames', {'order','analysis','condition','mean','sem','TStat','df','PValue','cohenD','CILower','CIUpper'});

safe_saveall(strcat(save_behavior,filesep,'supplement_stats_summary.csv'), supplementSummaryTable);
disp("Consolidated supplement behavioral stats summary");
display(supplementSummaryTable);