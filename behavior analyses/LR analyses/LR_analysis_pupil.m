clc
clearvars 

% SCRIPT TO RUN MODEL BASED ANALYSIS OF LEARNING RATES
preprocess_obj = preprocess_LR(); % initialise object with all required variables and functions
preprocess_obj.flip_mu(); % compute reported contingency parameter, after correcting for congruence
if preprocess_obj.space_pavlovian == 0
    preprocess_obj.compute_action_dep_rew(); % compute action dependent reward
end
preprocess_obj.compute_mu(); % recode mu, contingent on if actual mu < 0.5 or not
preprocess_obj.compute_state_dep_pe(); % compute state dependent PE and UP

% COMPUTE VARS FOR LINEAR FIT
preprocess_obj.compute_ru(); % reward uncertainty
preprocess_obj.compute_confirm(); % confirming outcome
norm_condiff = preprocess_obj.compute_normalise(abs(preprocess_obj.data.con_diff)); % normalised contrast difference
preprocess_obj.add_splithalf(); % add splithalf variable
if preprocess_obj.space_pavlovian == 0
    preprocess_obj.add_saliencechoice(); % add salience chhoice
end

% ADD VARIABLES TO THE DATA TABLE
preprocess_obj.add_vars(norm_condiff,{'norm_condiff'});
preprocess_obj.add_vars(preprocess_obj.data.ru,'reward_unc');
preprocess_obj.add_vars(preprocess_obj.data.confirm_rew,'pe_sign');

% CHANGE DIRECTORY ACCORDINGLY
currentDir = 'D:\Perceptual_unc_aug_task_pupil-main\Perceptual_unc_aug_task_pupil-main'; % Get the current working directory
save_dir = strcat(currentDir,filesep,'data', filesep,'GB data',filesep, 'behavior', filesep, 'LR analyses'); 
mkdir(save_dir);

% SAVE PREPROCESSED FILE
safe_saveall(fullfile(save_dir,'preprocessed_lr_pupil.xlsx'),preprocess_obj.data)
safe_saveall(fullfile(save_dir,'preprocessed_lr_pupil_no_zerope.xlsx'),preprocess_obj.data(preprocess_obj.data.pe ~= 0, :));
%%
% FIT THE MODEL
lr_analysis = lr_analysis_obj();
lr_analysis.model_definition();
[betas_all,rsquared_full,residuals_all,coeffs_name,posterior_up_subjs] = lr_analysis.get_coeffs(@fitlm);

% SAVE DATA
if lr_analysis.absolute_analysis == 1 % save absolute analyses betas
    if lr_analysis.lr_mdl == 1 % best behavioral model
        safe_saveall(fullfile(save_dir,"betas_abs.mat"),betas_all);
        safe_saveall(fullfile(save_dir,"post_absUP_predict.mat"),posterior_up_subjs); % save posterior updates
    end
elseif lr_analysis.absolute_analysis == 0 % save signed analyses betas
    if lr_analysis.lr_mdl == 1 % best behavioral model
        safe_saveall(fullfile(save_dir,"betas_signed.mat"),betas_all); % save betas as betas_signed if running signed analysis
    end
end