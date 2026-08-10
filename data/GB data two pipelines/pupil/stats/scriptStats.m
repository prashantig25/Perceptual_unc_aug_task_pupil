clc
clearvars
% USER-BASED PATH
currentDir = cd;
reqPath = 'GBSliderPupil_NatComms';
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

%% Figure 3 MS - descriptive analysis

condiffbin = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "descriptive", filesep, "fb_PE2bins_linearInt.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff2bins_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff2bins_linearInt.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));

% 3c: Binned regression PE for high and low state uncertainty
results = [results; table({'peBinned_condiff'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

% 3b: High vs. low PE 
results = [results; table({'peBinned'}, round(min(condiffbin.prob(1, condiffbin.stat(1,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

% 3c with cubic spline
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff2bins_cubicSplineNew.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
results = [results; table({'peBinned_condiff_cubicSpline'}, round(min(perm.prob(pe_idx, perm.prob(pe_idx,:) < 0.1)), 3), 'VariableNames', {'term', 'pval'})];

% 3c with deconvolution
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for supplement", filesep,"perm_pe_condiff2bins_deconv.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
results = [results; table({'peBinned_condiff_deconv'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% Figure 4 MS - main regression model

perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_linearInt.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

results = [results; table({'pe_main'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];
pVals = round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3);
if pVals == 0.010
    pVals = 0.010; % for the sake of MS
end
results = [results; table({'peCondiff_main'}, pVals, 'VariableNames', {'term', 'pval'})];

%% Figure 5 MS - learning residual analysis

data_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'residual');
perm = importdata(fullfile(data_dir,"perm_betas_behvresidual_abs_pecondiff_nomain_linearInt.mat"));
betas_pupil = importdata(fullfile(data_dir,"betas_behvresidual_abs_pecondiff_nomain_linearInt.mat")); % import coeff names
coeffs_name = betas_pupil.coeff_names;

post_up_idx = find(strcmp(coeffs_name, 'post_up'));
pupil_idx = find(strcmp(coeffs_name, 'pupil'));
coeffs = squeeze(mean(betas_pupil.with_intercept(1, post_up_idx, :, :), 4));
[h, pVals] = ttest(coeffs);
if pVals < 0.001
    pVals = 0.001; % for the sake of MS
end

results = [results; table({'post_up'}, pVals, 'VariableNames', {'term', 'pval'})];
results = [results; table({'pupil'},   round(min(perm.prob(pupil_idx,   perm.mask(pupil_idx,:)   == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% Figure S10 MS - non-baseline corrected

perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for supplement", filesep,"perm_pe_condiff_nonBaselineCorrected_linearInt.mat"));
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "control analyses for supplement", filesep,"pe_condiff_nonBaselineCorrected_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

% Main effect non-baseline corrected
results = [results; table({'pe_NBC'},       round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];

% Interaction effect non-baseline corrected
results = [results; table({'peCondiff_NBC'}, round(min(perm.prob(peCondiff_idx, perm.prob(peCondiff_idx,:) < 0.05)), 3), 'VariableNames', {'term', 'pval'})];

%% Figure S9 MS - regressed RT

betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff_regressedRT_linearInt.mat"));
coeff_names = betas_struct.coeff_names;
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff_regressedRT_linearInt.mat"));
pe_idx = find(strcmp(coeff_names,'pe'));
peCondiff_idx = find(strcmp(coeff_names,'zsc_condiff:pe'));

% Main effect
results = [results; table({'pe_regressedRT'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];

% Interaction effect
results = [results; table({'peCondiff_regressedRT'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% Figure S14 Additive model 

data_dir  = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
betas_struct = importdata(fullfile(data_dir,"additiveMdl_linearInt.mat")); 
coeff_names = betas_struct.coeff_names;
perm = importdata(fullfile(data_dir,"perm_additiveMdl_linearInt.mat")); 
pe_idx = find(strcmp(coeff_names,'pe'));

% Main effect only
results = [results; table({'pe_additiveMdl'}, round(min(perm.prob(pe_idx, perm.mask(pe_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% Figure S11 Het model, linear int

het_save_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', ...
                        'regression', 'control analyses for supplement');
coeff_names = importdata(fullfile(het_save_dir,"coeff_names_hetero.mat"));
perm = importdata(fullfile(het_save_dir,"perm_hetModel_linearInt_newSP.mat"));
pe_idx = find(strcmp(coeff_names,'PE'));
peCondiff_idx = find(strcmp(coeff_names,'PExCondiff'));
results = [results; table({'pe_het_linearInt'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_het_linearInt'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% Het model, cubic spline (not separately shown outside of multiverse)

coeff_names = importdata(fullfile(het_save_dir,"coeff_names_hetero.mat"));
perm = importdata(fullfile(het_save_dir,"perm_hetModel_CS_newSP.mat"));
pe_idx = find(strcmp(coeff_names,'PE'));
peCondiff_idx = find(strcmp(coeff_names,'PExCondiff'));
results = [results; table({'pe_het_cubicSpline'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_het_cubicSpline'}, round(min(perm.prob(peCondiff_idx, perm.mask(peCondiff_idx,:) == 1)), 3), 'VariableNames', {'term', 'pval'})];

%% Het model, deconvolution (not separately shown outside of multiverse)

coeff_names = importdata(fullfile(het_save_dir,"coeff_names_hetero.mat"));
perm = importdata(fullfile(het_save_dir,"perm_hetModel_deconv_newSP.mat"));
pe_idx = find(strcmp(coeff_names,'PE'));
peCondiff_idx = find(strcmp(coeff_names,'PExCondiff'));
results = [results; table({'pe_het_deconvolution'},        round(min(perm.prob(pe_idx,       perm.mask(pe_idx,:)       == 1)), 3), 'VariableNames', {'term', 'pval'})];
results = [results; table({'peCondiff_het_deconvolution'}, round(min(perm.prob(peCondiff_idx, perm.prob(peCondiff_idx,:) < 0.05)), 3), 'VariableNames', {'term', 'pval'})];

%% SAVE ALL

safe_saveall(fullfile(save_dir,filesep,"allStats.csv"),results)

%% CONSOLIDATED SUMMARY OF ALL PUPIL STATS (FOR MANUSCRIPT REFERENCE)

% Reads back every pupil-stats CSV in the repo and stitches them into one
% ordered table. Sources store different levels of detail (some only a
% p-value, some the full t/df/mean/SEM/CI/Cohen's d), so missing fields
% are left as NaN. Figures with no saved stats file (SM6, SM8, SM15,
% SM17) get an explicit placeholder row so the gap is visible instead of
% silently omitted. SM7 (behavioral, absolute PE by state uncertainty) is
% already covered by supplement_stats_summary.csv and is not duplicated
% here.

pupil_residual_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'residual');

allStatsMulti = readtable(fullfile(save_dir, 'allStats_multiverse.csv'));
fig5a         = readtable(fullfile(save_dir, 'figure5a_stats.csv'));
rtPrevTrial   = readtable(fullfile(save_dir, 'RTRegression_previousTrial.csv'));
patchResid    = readtable(fullfile(pupil_residual_dir, 'patchResidual_stats.csv'));

rowsP = {}; % figure, analysis, term, pval, tStat, df, mean, sem, cohenD, CILower, CIUpper

addPvalRow = @(rowsIn, fig, analysis, T, termName) ...
    [rowsIn; {fig, analysis, termName, T.pval(strcmp(string(T.term), termName)), NaN, NaN, NaN, NaN, NaN, NaN, NaN}]; %#ok<*NASGU>

% --- Figure 3 (main): descriptive/binned regression ---
rowsP = addPvalRow(rowsP, "Fig. 3", "PE bin high vs. low", results, 'peBinned');
rowsP = addPvalRow(rowsP, "Fig. 3", "Binned regression PE x condiff", results, 'peBinned_condiff');
rowsP = addPvalRow(rowsP, "Fig. 3", "Binned PE x condiff (cubic spline)", results, 'peBinned_condiff_cubicSpline');
rowsP = addPvalRow(rowsP, "Fig. 3", "Binned PE x condiff (deconvolution)", results, 'peBinned_condiff_deconv');

% --- Figure 4 (main): main regression model ---
rowsP = addPvalRow(rowsP, "Fig. 4", "PE main effect", results, 'pe_main');
rowsP = addPvalRow(rowsP, "Fig. 4", "Uncertainty-weighted PE", results, 'peCondiff_main');

% --- Figure 5 (main): residual learning analysis ---
r = fig5a(strcmp(string(fig5a.term), 'Predicted update (beta1)'), :);
rowsP = [rowsP; {"Fig. 5a", "Posterior-predicted update", "post_up", r.p_value, r.t_stat, r.df, r.mean, r.SEM, r.cohen_d, r.CI_low, r.CI_high}];
rowsP = addPvalRow(rowsP, "Fig. 5b", "Pupil predicts residual update", results, 'pupil');

% --- SM2: reaction-time regression ---
for term = ["condition","condiff","PE_prevTrial"]
    r = rtPrevTrial(strcmp(string(rtPrevTrial.term), term), :);
    rowsP = [rowsP; {"SM Fig. 2", "RT regression", term, r.pValuesRT, r.t_stat, r.df, r.mean, r.SEM, NaN, r.CI_low, r.CI_high}];
end

% --- SM6: not saved as a stats CSV ---
rowsP = [rowsP; {"SM Fig. 6", "UP-modulated pupil (binned, low vs. high uncertainty)", "NotSaved", NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}];

% --- SM8: not saved as a stats CSV ---
rowsP = [rowsP; {"SM Fig. 8", "UP/RT/x-gaze/y-gaze regressors (main model)", "NotSaved", NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}];

% --- SM9: removing RT prior to analysis ---
rowsP = addPvalRow(rowsP, "SM Fig. 9", "PE main effect (RT regressed out)", results, 'pe_regressedRT');
rowsP = addPvalRow(rowsP, "SM Fig. 9", "Uncertainty-weighted PE (RT regressed out)", results, 'peCondiff_regressedRT');

% --- SM10: excluding high-pass filtering and baseline correction ---
rowsP = addPvalRow(rowsP, "SM Fig. 10", "PE main effect (no baseline correction)", results, 'pe_NBC');
rowsP = addPvalRow(rowsP, "SM Fig. 10", "Uncertainty-weighted PE (no baseline correction)", results, 'peCondiff_NBC');

% --- SM11: heteroskedasticity model ---
rowsP = addPvalRow(rowsP, "SM Fig. 11", "PE main effect (het., linear int.)", results, 'pe_het_linearInt');
rowsP = addPvalRow(rowsP, "SM Fig. 11", "Uncertainty-weighted PE (het., linear int.)", results, 'peCondiff_het_linearInt');
rowsP = addPvalRow(rowsP, "SM Fig. 11", "PE main effect (het., cubic spline)", results, 'pe_het_cubicSpline');
rowsP = addPvalRow(rowsP, "SM Fig. 11", "Uncertainty-weighted PE (het., cubic spline)", results, 'peCondiff_het_cubicSpline');
rowsP = addPvalRow(rowsP, "SM Fig. 11", "PE main effect (het., deconvolution)", results, 'pe_het_deconvolution');
rowsP = addPvalRow(rowsP, "SM Fig. 11", "Uncertainty-weighted PE (het., deconvolution)", results, 'peCondiff_het_deconvolution');

% --- SM12/13: multiverse (all specifications) ---
for i = 1:height(allStatsMulti)
    rowsP = [rowsP; {"SM Fig. 12/13", "Multiverse specification", char(string(allStatsMulti.term(i))), allStatsMulti.pval(i), NaN, NaN, NaN, NaN, NaN, NaN, NaN}];
end

% --- SM14: additive regression model ---
rowsP = addPvalRow(rowsP, "SM Fig. 14", "PE main effect (additive model)", results, 'pe_additiveMdl');

% --- SM15: not saved as a stats CSV ---
rowsP = [rowsP; {"SM Fig. 15", "Uncertainty-modulated pupil (residual learning)", "NotSaved", NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}];

% --- SM16: choice-phase logistic regression + pupil ---
for term = ["condition_choicePhase","condiff_choicePhase","muZsc_choicePhase","ppc","pupil_choicePhase"]
    rowsP = addPvalRow(rowsP, "SM Fig. 16", "Choice-phase regression", patchResid, term);
end

% --- SM17: not saved as a stats CSV ---
rowsP = [rowsP; {"SM Fig. 17", "Contrast diff / condition / x-gaze / y-gaze (patch phase)", "NotSaved", NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}];

orderP = (1:size(rowsP,1)).';
pupilSummaryTable = table(orderP, string(rowsP(:,1)), string(rowsP(:,2)), string(rowsP(:,3)), ...
    round(cell2mat(rowsP(:,4)),3), round(cell2mat(rowsP(:,5)),3), round(cell2mat(rowsP(:,6)),3), ...
    round(cell2mat(rowsP(:,7)),3), round(cell2mat(rowsP(:,8)),3), round(cell2mat(rowsP(:,9)),3), ...
    round(cell2mat(rowsP(:,10)),3), round(cell2mat(rowsP(:,11)),3), ...
    'VariableNames', {'order','figure','analysis','term','pval','tStat','df','mean','sem','cohenD','CILower','CIUpper'});

safe_saveall(fullfile(save_dir, 'pupil_stats_summary.csv'), pupilSummaryTable);
disp("Consolidated pupil stats summary");
display(pupilSummaryTable);

