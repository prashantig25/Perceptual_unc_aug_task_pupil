%%%%%% RUN ALL SORTS OF SIGNIFICANCE TESTS AND SAVE OUTPUT FOR MANUSCRIPT 
%%%%%% AND FIGURES

% INITIALISE VARS
clc
clearvars

% USER-BASED PATH
currentDir = cd; % current directory
pathParts = strsplit(currentDir, filesep);
reqPath = 'Perceptual_unc_aug_task_pupil'; % to which directory one must save in
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

%% DESCRIPTIVE ANALYSIS FROM STUDY 2

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
cond_names = ["mix";"perc"];

% Perform a one-sample t-test
[h_vals(1,:), p_vals(1,:), ~, stats_mix] = ttest(ecoperf_mix_avg, chance_level); 
[h_vals(2,:), p_vals(2,:), ~, stats_perc] = ttest(ecoperf_perc_avg, chance_level);

t_vals(1,:) = stats_mix.tstat;
t_vals(2,:) = stats_perc.tstat;

df_vals(1,:) = stats_mix.df;
df_vals(2,:) = stats_perc.df;

[mean_ecoperf(1,:),sem_ecoperf(1,:)] = compute_mean_sem(ecoperf_mix_avg);
[mean_ecoperf(2,:),sem_ecoperf(2,:)] = compute_mean_sem(ecoperf_perc_avg);

% save output to .csv file for OVERLEAF
ttestResults = table(cond_names, round(h_vals(:,1),2), round(p_vals(:,1),2), ...
    round(t_vals,2), round(df_vals,2), round(mean_ecoperf,2), round(sem_ecoperf,3),...
    'VariableNames', {'Condition', 'HValue', 'PValue', 'TStat', 'df','mean','sem'}); % Create a table to store the t-test results

% Save the table as a CSV file
safe_saveall(strcat(save_behavior,filesep,'allconditions_chance_ttest47.csv'), ttestResults);

%% COHEN'S D FOR ECONOMIC PERFORMANCE ACROSS CONDITIONS

num_condition = 2; % number of conditions
cohen_d = NaN(num_condition,1); % initialise
ecoperf = [ecoperf_mix_avg,ecoperf_perc_avg];
for i = 1:num_condition
    cohen_d(i,1) = compute_cohen_ttest(nanmean(ecoperf(:,i)),0,nanstd(ecoperf(:,i)));
end

% save output to .csv file for OVERLEAF
cohenResults = table(cond_names, round(cohen_d,2), ...
    'VariableNames', {'Condition', 'cohend'}); % Create a table to store the t-test results
safe_saveall(strcat(save_behavior,filesep,'ecoperf_cohen47.csv'),cohenResults);
%% T-TEST TO COMPARE SLIDER DATA ACROSS UNCERTAINTIES

% Initialise variables
mix_avg = nanmean(mix_curve,2);
perc_avg = nanmean(perc_curve,2);
mean_avg = [mix_avg, perc_avg];
h_vals = NaN(1,1);
p_vals = NaN(1,1);
t_vals = NaN(1,1);
df_vals = NaN(1,1);
cohen_d = NaN(1,1);

% t-test
[h_vals(1,:), p_vals(1,:), ~, stats_mixperc] = ttest(mix_avg, perc_avg); % impact of reward uncertainty
cond_names = ["mix_perc"];

t_vals(1,:) = stats_mixperc.tstat;
df_vals(1,:) = stats_mixperc.df;

% Cohen's d
sd_pooled = sqrt((nanstd(perc_avg)^2 + nanstd(mix_avg)^2)./2);
cohen_d(1,1) = compute_cohend_ttest2(nanmean(perc_avg), nanmean(mix_avg), sd_pooled);

% Save
ttestResults = table(cond_names, round(h_vals(:,1),2), round(p_vals(:,1),2), ...
    round(t_vals,2), round(df_vals,2), round(cohen_d,2),...
    'VariableNames', {'Condition', 'HValue', 'PValue', 'TStat', 'df','cohen_d'}); % Create a table to store the t-test results
safe_saveall(strcat(save_behavior,filesep,'mu_uncertainty_ttest47.csv'),ttestResults);

%% SAVE MEAN and SEM FOR SLIDER UPDATES ACROSS CONDITIONS

% Initialise variables
mean_mu = NaN(2,1);
sem_mu = NaN(2,1);
cond_names = ["mix";"perc"];
chance_level = 0.5;

% Compute mean and SEM
[mean_mu(1,:),sem_mu(1,:)] = compute_mean_sem(mix_avg);
[mean_mu(2,:),sem_mu(2,:)] = compute_mean_sem(perc_avg);

[h_vals(1,:), p_vals(1,:), ~, stats_mix] = ttest(mix_avg, chance_level); 
[h_vals(2,:), p_vals(2,:), ~, stats_perc] = ttest(perc_avg, chance_level); 

t_vals(1,:) = stats_mix.tstat;
t_vals(2,:) = stats_perc.tstat;

df_vals(1,:) = stats_mix.df;
df_vals(2,:) = stats_perc.df;

% save
ttestResults = table(cond_names, round(h_vals(:,1),2), round(p_vals(:,1),2), ...
    round(t_vals,2), round(df_vals,2), round(mean_mu,2), round(sem_mu,2),...
    'VariableNames', {'Condition', 'HValue', 'PValue', 'TStat', 'df', 'mean', 'sem'}); % Create a table to store the t-test results
safe_saveall(strcat(save_behavior,filesep,'mu_meansem47.csv'),ttestResults);

%% COHEN'S D FOR SLIDER UPDATES ACROSS CONDITIONS

num_condition = 2;
cohen_d = NaN(num_condition,1);
mu = [mix_avg,perc_avg];
cond_names = ["mix";"perc"];

for i = 1:num_condition
    cohen_d(i,1) = compute_cohen_ttest(nanmean(mu(:,i)),0,nanstd(mu(:,i)));
end

% save output to .csv file for OVERLEAF
cohenResults = table(cond_names, round(cohen_d,2), ...
    'VariableNames', {'Condition', 'cohend'}); % Create a table to store the t-test results
safe_saveall(strcat(save_behavior,filesep,'mu_cohen47.csv'),cohenResults);

%% T-TEST ON BETA COEFFICIENTS

% t-test
cond_names = ["pe";"pe_condiff";"pe_salience";"pe_congruence";"pe_pesign"];
[h_vals, p_vals, ~, stats] = ttest(betas_all); % Perform a one-sample t-test
t_vals = stats.tstat;
df_vals = stats.df;

% compute mean and SEM
mean_ecoperf = NaN(size(betas_all,2),1);
sem_ecoperf = NaN(size(betas_all,2),1);
for i = 1:size(betas_all,2)
    [mean_ecoperf(i,:),sem_ecoperf(i,:)] = compute_mean_sem(betas_all(:,i));
end

% save output to .csv file for OVERLEAF
ttestResults = table(cond_names, round(h_vals,2).', round(p_vals,4).', ...
    round(t_vals,2).', round(df_vals,2).', round(mean_ecoperf,2), round(sem_ecoperf,3),...
    'VariableNames', {'Condition', 'HValue', 'PValue', 'TStat', 'df','mean','sem'}); % Create a table to store the t-test results
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

% save output to .csv file for OVERLEAF
cohenResults = table(cond_names, round(cohen_d,2), ...
    'VariableNames', {'Condition', 'cohend'}); % Create a table to store the t-test results
safe_saveall(strcat(save_behavior,filesep,'lr_betas_cohen.csv'),cohenResults);
disp("Learning rate betas Cohen's d");
display(cohenResults);