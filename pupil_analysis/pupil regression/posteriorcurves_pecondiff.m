% INITIALIZE VARS
col = 300; % number of datapoints
num_subjs = 47; % number of subjects

% USER-BASED PATH
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

save_dir = strcat(desiredPath, filesep, "data", filesep, "GB data",...
    filesep, "pupil", filesep, "regression", filesep, "main");
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data",...
    filesep, "pupil", filesep, "regression", filesep, "main", filesep, "pe_condiff.mat"));
preds_all = readtable(strcat(desiredPath, filesep, "data", filesep, "GB data",...
    filesep, "behavior", filesep, "LR analyses", filesep, "preprocessed_lr_pupil_no_zerope.xlsx"));
betas_field = betas_struct.with_intercept;
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813',...
    '601','3319','129','4684','3886','620','901','900'};
highPU = -1.5; % high BS uncertainty
midPU = 0.015; % medium BS uncertainty
lowPU = 1.5; % low BS uncertainty

% LOOP OVER SUBJECTS
for s = 1:num_subjs
    preds = preds_all(preds_all.id == str2num(subj_ids{s}),:);
    preds.zsc_condiff = nanzscore(preds.norm_condiff);
    for c = 1:col
        coeffs.pe(s,c) = betas_field(1,5,s,c);
        coeffs.pe_condiff(s,c) = betas_field(1,8,s,c);
        coeffs.up(s,c) = betas_field(1,6,s,c);
        coeffs.con_diff(s,c) = betas_field(1,4,s,c);
    end
    pe_trial = ones(height(preds),1);
    posterior.midPU(s,:) = nanmean(coeffs.pe_condiff(s,:).*midPU.*pe_trial(preds.con_diff > 0.033 & preds.con_diff < 0.0666) + coeffs.pe(s,:).*pe_trial(preds.con_diff > 0.033 & preds.con_diff < 0.0666) + coeffs.con_diff(s,:).*midPU);
    posterior.highPU(s,:) = nanmean(coeffs.pe_condiff(s,:).*highPU.*pe_trial(preds.con_diff < 0.033) + coeffs.pe(s,:).*pe_trial(preds.con_diff < 0.033) + coeffs.con_diff(s,:).*highPU);
    posterior.lowPU(s,:) = nanmean(coeffs.pe_condiff(s,:).*lowPU.*pe_trial(preds.con_diff > 0.066) + coeffs.pe(s,:).*pe_trial(preds.con_diff > 0.066) + coeffs.con_diff(s,:).*lowPU);
end

% SAVE
safe_saveall(strcat(save_dir, filesep, "BSweightedPE_interactions.mat"),posterior);