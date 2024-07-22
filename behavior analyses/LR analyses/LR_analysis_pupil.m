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
% norm_patchphasic = preprocess_obj.compute_normalise(preprocess_obj.data.patch_phasic);
% norm_patchtonic = preprocess_obj.compute_normalise(preprocess_obj.data.patch_tonic);
% norm_fbphasic = preprocess_obj.compute_normalise(preprocess_obj.data.fb_phasic);
% norm_fbtonic = preprocess_obj.compute_normalise(preprocess_obj.data.fb_tonic);
preprocess_obj.add_splithalf(); % add splithalf variable
if preprocess_obj.space_pavlovian == 0
    preprocess_obj.add_saliencechoice(); % add salience chhoice
end

% ADD VARIABLES TO THE DATA TABLE
preprocess_obj.add_vars(norm_condiff,{'norm_condiff'});
preprocess_obj.add_vars(preprocess_obj.data.ru,'reward_unc');
preprocess_obj.add_vars(preprocess_obj.data.confirm_rew,'pe_sign');

% SAVE PREPROCESSED FILE
writetable(preprocess_obj.data,'preprocessed_lr_pavlovian.xlsx');
writetable(preprocess_obj.data(preprocess_obj.data.pe ~= 0, :),'preprocessed_lr_pavlovian_no_zerope.xlsx');

% SAVE FILES SEPARATELY FOR GROUPED REGRESSION
grouped = 0; % 1 if files need to be saved separately for grouped regression
if grouped == 1
    data = readtable("preprocessed_lr_pupil_no_zerope.xlsx");
    condiff = data.con_diff;
    bin_edges = prctile(condiff, 0:50:100); % Calculate percentile edges
    bins = discretize(data.con_diff, bin_edges);
    data.bins = bins;
    writetable(data(data.bins == 1,:),'preprocessed_subj_condiffbin1.xlsx');
    writetable(data(data.bins == 2,:),'preprocessed_subj_condiffbin2.xlsx');
end
% writetable(data(data.con_diff >= 0.02,:),'preprocessed_subj_no_condiffbin1.xlsx');
%%
% FIT THE MODEL
lr_analysis = lr_analysis_obj();
[betas_all,rsquared_full,residuals_all,coeffs_name,posterior_up_subjs] = lr_analysis.get_coeffs(@fitlm);
% p_vals = lr_analysis.p_vals;

% SAVE DATA 
save("betas_abs_condiff","betas_all"); % save betas
save("residuals_signed","residuals_all"); % residuals
save("rsquared_abs.mat","rsquared_full"); % save r-squared values
save("post_signedUP_predict.mat","posterior_up_subjs"); %