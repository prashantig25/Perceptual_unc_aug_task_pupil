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

%% figure 3 MS - descriptive analysis

condiffbin = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "descriptive", filesep, "fb_PE2bins_linearInt.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff2bins_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff2bins_linearInt.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));

results = [results; table({'peBinned_condiff'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peBinned'}, round(min(condiffbin.prob(1, condiffbin.stat(1,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff2bins_cubicSplineNew.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
results = [results; table({'peBinned_condiff_cubicSpline'}, round(min(perm.prob(pe_idx, perm.prob(pe_idx,:) < 0.1)), 3), 'VariableNames', {'term', 'pval'})];

perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"perm_pe_condiff2bins_deconv_saccCorr_uraiParamsPG.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
results = [results; table({'peBinned_condiff_deconv'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure 4 MS - main regression model

perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_linearInt.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_main'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_main'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure 5 MS - learning residual analysis

data_dir = fullfile(desiredPath, 'Data', 'GB data two pipelines', 'pupil', 'residual');
perm = importdata(fullfile(data_dir,"perm_betas_behvresidual_abs_pecondiff_nomain_linearInt.mat"));
betas_pupil = importdata(fullfile(data_dir,"betas_behvresidual_abs_pecondiff_nomain_linearInt.mat")); % import coeff names
coeffs_name = betas_pupil.coeff_names;

post_up_idx = find(strcmp(coeffs_name, 'post_up'));
pupil_idx = find(strcmp(coeffs_name, 'pupil'));

results = [results; table({'post_up'}, round(min(perm.prob(post_up_idx, perm.mask(post_up_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'pupil'},   round(min(perm.prob(pupil_idx,   perm.mask(pupil_idx,:)   == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure S10 MS - non-baseline corrected

perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"perm_pe_condiff_mathot_nonBaselineCorrected_linearInt.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"pe_condiff_mathot_nonBaselineCorrected_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_NBC'},       round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_NBC'}, round(min(perm.prob(peCondiff_idx, perm.prob(peCondiff_idx,:) < 0.05)), 3), 'VariableNames', {'term', 'pval'})];

%% figure S12 MS - regressed RT

betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_regressedRT_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_regressedRT_linearInt.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_regressedRT'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_regressedRT'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure Additive model 

data_dir  = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
betas_struct = importdata(fullfile(data_dir,"additiveMdl_linearInt.mat")); 
coeff_names = betas_struct.coeff_names;
perm = importdata(fullfile(data_dir,"perm_additiveMdl_linearInt.mat")); 
pe_idx = find(strcmp(coeff_names,'pe'));

results = [results; table({'pe_additiveMdl'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure Het model, linear int

het_save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', ...
                        'regression', 'control analyses for revisions');
coeff_names = importdata(fullfile(het_save_dir,"coeff_names_hetero.mat"));
perm = importdata(fullfile(het_save_dir,"perm_hetModel_linearInt_newSP.mat"));
pe_idx = find(strcmp(coeff_names,'PE'));
peCondiff_idx = find(strcmp(coeff_names,'PExCondiff'));
results = [results; table({'pe_het_linearInt'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_het_linearInt'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure Het model, cubic spline

coeff_names = importdata(fullfile(het_save_dir,"coeff_names_hetero.mat"));
perm = importdata(fullfile(het_save_dir,"perm_hetModel_CS_newSP.mat"));
pe_idx = find(strcmp(coeff_names,'PE'));
peCondiff_idx = find(strcmp(coeff_names,'PExCondiff'));
results = [results; table({'pe_het_cubicSpline'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_het_cubicSpline'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure Het model, deconvolution
coeff_names = importdata(fullfile(het_save_dir,"coeff_names_hetero.mat"));
perm = importdata(fullfile(het_save_dir,"perm_hetModel_deconv_newSP.mat"));
pe_idx = find(strcmp(coeff_names,'PE'));
peCondiff_idx = find(strcmp(coeff_names,'PExCondiff'));
results = [results; table({'pe_het_deconvolution'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_het_deconvolution'}, round(min(perm.prob(peCondiff_idx, perm.prob(peCondiff_idx,:) < 0.05)), 3), 'VariableNames', {'term', 'pval'})];

%% SAVE ALL

safe_saveall(fullfile(save_dir,filesep,"allStats.csv"),results)

