% posteriorcurves_pecondiff saves posterior curves from model-based
% analyses of the pupil response.
clc
clearvars

% INITIALIZE VARS
col = 300; % number of datapoints
num_subjs = 47; % number of subjects

% USER-BASED PATH
currentDir = cd; % current directory
reqPath = 'Perceptual_unc_aug_task_pupil'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end

%%

save_dir = strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines",...
    filesep, "pupil", filesep, "regression", filesep, "main");
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines",...
    filesep, "pupil", filesep, "regression", filesep, "main", filesep, "pe_condiff_linearInt.mat"));
preds_all = readtable(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines",...
    filesep, "behavior", filesep, "LR analyses", filesep, "preprocessed_lr_pupil_no_zerope.xlsx"));
betas_field = betas_struct.with_intercept;
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
highPU = -1.5; % high BS uncertainty
midPU = 0.015; % medium BS uncertainty
lowPU = 1.5; % low BS uncertainty

highPE = 0.8; % high PE 
lowPE = 0.2; % low PE


% LOOP OVER SUBJECTS
for s = 1:num_subjs
    preds = preds_all(preds_all.id == str2num(subj_ids{s}),:);
    preds.zsc_condiff = zscore(preds.norm_condiff);
    for c = 1:col
        coeffs.pe(s,c) = betas_field(1,5,s,c);
        coeffs.pe_condiff(s,c) = betas_field(1,8,s,c);
        coeffs.up(s,c) = betas_field(1,6,s,c);
        coeffs.con_diff(s,c) = betas_field(1,4,s,c);
    end
    % Using the height of preds to ensure a perfect match
    highPE_vec = ones(height(preds), 1) * highPE;
    lowPE_vec  = ones(height(preds), 1) * lowPE;

    posterior.highPU_highPE(s,:) = mean(coeffs.pe_condiff(s,:).*highPU.*highPE_vec + coeffs.pe(s,:).*highPE_vec + coeffs.con_diff(s,:).*highPU);
    posterior.lowPU_lowPE(s,:) = mean(coeffs.pe_condiff(s,:).*lowPU.*lowPE_vec + coeffs.pe(s,:).*lowPE_vec + coeffs.con_diff(s,:).*lowPU);

    posterior.highPU_lowPE(s,:) = mean(coeffs.pe_condiff(s,:).*highPU.*lowPE_vec + coeffs.pe(s,:).*lowPE_vec + coeffs.con_diff(s,:).*highPU);
    posterior.lowPU_highPE(s,:) = mean(coeffs.pe_condiff(s,:).*lowPU.*highPE_vec + coeffs.pe(s,:).*highPE_vec + coeffs.con_diff(s,:).*lowPU);

end

% SAVE
safe_saveall(strcat(save_dir, filesep, "4c_MathotComments.mat"),posterior);

