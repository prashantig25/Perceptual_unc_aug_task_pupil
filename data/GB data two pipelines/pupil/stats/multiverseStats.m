clc
clearvars
% USER-BASED PATH
currentDir = cd;
reqPath = 'Perceptual_unc_aug_task_pupil';
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

% Initialize results table
results = table({}, [], 'VariableNames', {'term', 'pval'});

% Save dir
save_dir = fullfile(desiredPath,'data', 'GB data two pipelines', 'pupil', 'stats');

%% figure 4 MS - main regression model

perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_linearInt.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_main'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_main'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

% CS 
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_cubicSplineNew.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_cubicSplineNew.mat"));
coeff_names = betas_struct.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_mainCS'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_mainCS'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

% Deconv
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"perm_pe_condiff_deconvolution.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"pe_condiff_deconvolution.mat"));
coeff_names = betas_struct.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_mainDeconv'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_mainDeconv'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure S10 MS - non-baseline corrected

perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"perm_pe_condiff_nonBaselineCorrected_linearInt.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"pe_condiff_nonBaselineCorrected_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_NBC'},       round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_NBC'}, round(min(perm.prob(peCondiff_idx, perm.prob(peCondiff_idx,:) < 0.05)), 3), 'VariableNames', {'term', 'pval'})];

% CS
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"perm_pe_condiff_nonBaselineCorrected_cubicSplineNew.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"pe_condiff_nonBaselineCorrected_cubicSplineNew.mat"));
coeff_names = betas_struct.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_NBC_CS'},       round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_NBC_CS'}, round(min(perm.prob(peCondiff_idx, perm.prob(peCondiff_idx,:) < 0.05)), 3), 'VariableNames', {'term', 'pval'})];

% Deconv
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"perm_pe_condiff_deconvolution_nonBaselineCorrected_saccCorr_uraiParamsPG.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"pe_condiff_deconvolution_nonBaselineCorrected_saccCorr_uraiParamsPG.mat"));
coeff_names = betas_struct.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_NBC_deconv'},       round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_NBC_deconv'}, round(min(perm.prob(peCondiff_idx, perm.prob(peCondiff_idx,:) < 0.05)), 3), 'VariableNames', {'term', 'pval'})];

%% figure S12 MS - regressed RT

betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_regressedRT_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_regressedRT_linearInt.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_regressedRT'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_regressedRT'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

% CS 
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_regressedRT_cubicSplineNew.mat"));
coeff_names = betas_struct.coeff_names;
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_regressedRT_cubicSplineNew.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_regressedRT_CS'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_regressedRT_CS'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

% Deconv
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"pe_condiff_regressedRT_deconvolution.mat"));
coeff_names = betas_struct.coeff_names;
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"perm_pe_condiff_regressedRT_deconvolution.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_regressedRT_deconv'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_regressedRT_deconv'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];


%% SAVE ALL

safe_saveall(fullfile(save_dir,filesep,"allStats_multiverse.csv"),results)

