clc
clearvars
% USER-BASED PATH
currentDir = cd;
reqPath = 'Perceptual_unc_aug_task_pupil-main';
pathParts = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

% Initialize results table
results = table({}, [], 'VariableNames', {'term', 'pval'});

%% figure 3 MS

condiffbin = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "descriptive", filesep, "fb_PE2bins_linearInt.mat"));
coeff_names = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff2bins_linearInt_coeffNames.mat"));
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff2bins_linearInt.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));

results = [results; table({'peBinned_condiff'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peBinned'}, round(min(condiffbin.prob(1, condiffbin.stat(1,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure 4 MS
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_linearInt.mat"));
coeff_names = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_linearInt_coeffNames.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_fig4'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_fig4'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure 5 MS

data_dir = fullfile(desiredPath, 'Data', 'GB data two pipelines', 'pupil', 'residual');
perm = importdata(fullfile(data_dir,"perm_betas_behvresidual_abs_pecondiff_nomain_linearInt.mat"));
coeffs_name = importdata(fullfile(data_dir,"coeffs_name_behvresidual_abs_pecondiff_nomain_linearInt.mat")); % import coeff names

post_up_idx = find(strcmp(coeffs_name, 'post_up'));
pupil_idx = find(strcmp(coeffs_name, 'pupil'));

results = [results; table({'post_up'}, round(min(perm.prob(post_up_idx, perm.mask(post_up_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'pupil'},   round(min(perm.prob(pupil_idx,   perm.mask(pupil_idx,:)   == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure S10 MS

perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for revisions", filesep,"perm_pe_condiff_mathot_nonBaselineCorrected_linearInt.mat"));
coeff_names = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_linearInt_coeffNames.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_figS10'},       round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_figS10'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure S12 MS

coeff_names = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_regressedRT_linearInt_coeffNames.mat"));
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_regressedRT_linearInt.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_figS12'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_figS12'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure Additive model 

data_dir  = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
coeff_names = importdata(fullfile(data_dir,"additiveMdl_linearInt_coeffNames.mat")); 
perm = importdata(fullfile(data_dir,"perm_additiveMdl_linearInt.mat")); 
pe_idx = find(strcmp(coeff_names,'pe'));

results = [results; table({'pe_additiveMdl'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure Het model, linear int

het_save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', ...
    'regression', 'control analyses for revisions');
coeff_names = importdata(fullfile(het_save_dir,"coeff_names_het.mat"));
perm = importdata("permHet_linearInt_20SPAbs3Width");
pe_idx = find(strcmp(coeff_names,'pe'));
results = [results; table({'pe_het_linearInt'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure Het model, cubic spline

coeff_names = importdata(fullfile(het_save_dir,"coeff_names_het.mat"));
perm = importdata("permHet_CS_20SPAbs3Width");
pe_idx = find(strcmp(coeff_names,'pe'));
results = [results; table({'pe_het_cubicSpline'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% figure Het model, deconvolution

coeff_names = importdata(fullfile(het_save_dir,"coeff_names_het.mat"));
perm = importdata("permHet_deconvolution_20SPAbs3Width");
pe_idx = find(strcmp(coeff_names,'pe'));
results = [results; table({'pe_het_deconvolution'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%%

safe_saveall("allStats.csv",results)

