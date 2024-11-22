% LR_analysis_pupil uses a model-based approach to analysing single-trial
% prediction errors and belief updates.

clc
clearvars 
cleanUP; % run to clean up missing slider responses before further LR analyses

% SCRIPT TO RUN MODEL BASED ANALYSIS OF LEARNING RATES
preprocess_obj = preprocess_LR(); % initialise object with all required variables and functions
preprocess_obj.flip_mu(); % compute reported contingency parameter, after correcting for congruence
preprocess_obj.compute_action_dep_rew(); % compute action dependent rewardend
preprocess_obj.compute_mu(); % recode mu, contingent on if actual mu < 0.5 or not
preprocess_obj.compute_state_dep_pe(); % compute state dependent PE and UP

% COMPUTE VARS FOR LINEAR FIT
preprocess_obj.compute_ru(); % reward uncertainty
preprocess_obj.compute_confirm(); % confirming outcome
norm_condiff = preprocess_obj.compute_normalise(abs(preprocess_obj.data.con_diff)); % normalised contrast difference
preprocess_obj.add_splithalf(); % add splithalf variable
preprocess_obj.add_saliencechoice(); % add salience chhoice

% ADD VARIABLES TO THE DATA TABLE
preprocess_obj.add_vars(norm_condiff,{'norm_condiff'});
preprocess_obj.add_vars(preprocess_obj.data.ru,'reward_unc');
preprocess_obj.add_vars(preprocess_obj.data.confirm_rew,'pe_sign');

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
save_dir = strcat(desiredPath,filesep,'data', filesep,'GB data peak corrected',filesep, 'behavior', filesep, 'LR analyses'); 
mkdir(save_dir);

% SAVE PREPROCESSED FILE
safe_saveall(fullfile(save_dir,'preprocessed_lr_pupil.xlsx'),preprocess_obj.data)
safe_saveall(fullfile(save_dir,'preprocessed_lr_pupil_no_zerope.xlsx'),preprocess_obj.data(preprocess_obj.data.pe ~= 0, :));

% FIT THE MODEL

lr_analysis = lr_analysis_obj();
lr_analysis.mdl = 'up ~ pe + pe:salience + pe:congruence + pe:pe_sign + pe:contrast_diff';
lr_analysis.pred_vars = {'pe','contrast_diff','congruence','reward_unc' ...
                ,'reward','mu','pe_sign','fb_phasic','fb_tonic','patch_phasic','patch_tonic','fb_phasic_peak','fb_phasic_full','salience'}; % cell array with names of predictor variables
lr_analysis.cat_vars = {'congruence','condition','reward_unc','pe_sign','salience'};
lr_analysis.resp_var = 'up';
lr_analysis.num_vars = 5;
lr_analysis.absolute_analysis = 0;
[betas_all,rsquared_full,residuals_all,coeffs_name,posterior_up_subjs,loglikelihood_full,SSE_full] = lr_analysis.get_coeffs(@fitlm);

safe_saveall(fullfile(save_dir,"betas_signed.mat"),betas_all); % save betas as betas_signed if running signed analysis
safe_saveall(fullfile(save_dir,"post_signedUP_predict.mat"),posterior_up_subjs); % save posterior updates
safe_saveall(fullfile(save_dir,"rsquared_signed.mat"),rsquared_full); % save r-squared values
safe_saveall(fullfile(save_dir,"loglikelihood_signed.mat"),loglikelihood_full); % save r-squared values
safe_saveall(fullfile(save_dir,"SSE_signed.mat"),SSE_full); % save SSE values

% FIT ABSOLUTE MODEL

lr_analysis = lr_analysis_obj();
lr_analysis.mdl = 'up ~ pe + pe:salience + pe:congruence + pe:pe_sign + pe:contrast_diff';
lr_analysis.pred_vars = {'pe','contrast_diff','congruence','reward_unc' ...
                ,'reward','mu','pe_sign','fb_phasic','fb_tonic','patch_phasic','patch_tonic','fb_phasic_peak','fb_phasic_full','salience'}; % cell array with names of predictor variables
lr_analysis.cat_vars = {'congruence','condition','reward_unc','pe_sign','salience'};
lr_analysis.resp_var = 'up';
lr_analysis.num_vars = 5;
lr_analysis.absolute_analysis = 1;
[betas_all,rsquared_full,residuals_all,coeffs_name,posterior_up_subjs,loglikelihood_full,SSE_full] = lr_analysis.get_coeffs(@fitlm);

safe_saveall(fullfile(save_dir,"betas_abs.mat"),betas_all);
safe_saveall(fullfile(save_dir,"post_absUP_predict.mat"),posterior_up_subjs); % save posterior updates
safe_saveall(fullfile(save_dir,"SSE_abs.mat"),SSE_full); % save SSE values
safe_saveall(fullfile(save_dir,"loglikelihood_abs.mat"),loglikelihood_full); % save logL values
safe_saveall(fullfile(save_dir,"rsquared_abs.mat"),rsquared_full); % save rsq values

% FIT BASELINE MODEL TO SIGNED PREDICTORS

lr_analysis = lr_analysis_obj();
lr_analysis.mdl = 'up ~ 1';
lr_analysis.pred_vars = {'pe','contrast_diff','congruence','reward_unc' ...
                ,'reward','mu','pe_sign','fb_phasic','fb_tonic','patch_phasic','patch_tonic','fb_phasic_peak','fb_phasic_full','salience'}; % cell array with names of predictor variables
lr_analysis.cat_vars = {'congruence','condition','reward_unc','pe_sign','salience'};
lr_analysis.resp_var = 'up';
lr_analysis.num_vars = 0;
lr_analysis.absolute_analysis = 0;
[betas_all,rsquared_full,residuals_all,coeffs_name,posterior_up_subjs,loglikelihood_full,SSE_full] = lr_analysis.get_coeffs(@fitlm);

safe_saveall(fullfile(save_dir,"loglikelihood_baselineSigned.mat"),loglikelihood_full); % save r-squared values
safe_saveall(fullfile(save_dir,"SSEsigned_baseline.mat"),SSE_full); % save SSE values
% FIT BASELINE MODEL TO ABSOLUTE PREDICTORS

lr_analysis = lr_analysis_obj();
lr_analysis.mdl = 'up ~ 1';
lr_analysis.pred_vars = {'pe','contrast_diff','congruence','reward_unc' ...
                ,'reward','mu','pe_sign','fb_phasic','fb_tonic','patch_phasic','patch_tonic','fb_phasic_peak','fb_phasic_full','salience'}; % cell array with names of predictor variables
lr_analysis.cat_vars = {'congruence','condition','reward_unc','pe_sign','salience'};
lr_analysis.resp_var = 'up';
lr_analysis.num_vars = 0;
lr_analysis.absolute_analysis = 1;
[betas_all,rsquared_full,residuals_all,coeffs_name,posterior_up_subjs,loglikelihood_full,SSE_full] = lr_analysis.get_coeffs(@fitlm);

safe_saveall(fullfile(save_dir,"loglikelihood_baseline.mat"),loglikelihood_full); % save logL values        
safe_saveall(fullfile(save_dir,"SSE_baseline.mat"),SSE_full); % save SSE values
safe_saveall(fullfile(save_dir,"rsquared_baseline.mat"),rsquared_full); % save rsq values
