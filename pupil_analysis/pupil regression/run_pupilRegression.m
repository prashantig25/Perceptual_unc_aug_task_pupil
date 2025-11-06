function [betas_struct,perm,residuals_all,predicted_all] = run_pupilRegression(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, ...
    subj_ids, num_subs, num_sess, timewindow, regress_rt, baseline_mdl, ...
    preds_all, binned, bins, binned_accuracy, two_tailed, ~, ~, ~ ...
    ,base_dir, bins_array, col, num_vars, model_def, pred_vars, cat_vars, resp_var)
% function run_pupilRegression uses a model-based approach to analyse pupil
% responses in the learning window.
%
% INPUT:
%   behv_dir: Directory containing behavioral data files.
%   pupil_dir: Directory containing pupil data files.
%   xgaze_dir: Directory containing X gaze data files.
%   ygaze_dir: Directory containing Y gaze data files.
%   subj_ids: Cell array of subject IDs.
%   num_subs: Number of subjects.
%   num_sess: Array indicating number of sessions per subject.
%   timewindow: Time window for analysis ('patch' or 'feedback').
%   regress_rt: Boolean indicating whether to regress reaction times.
%   baseline_mdl: Boolean indicating whether to use a baseline model.
%   preds_all: Table containing all predictors.
%   binned: Boolean indicating whether to bin data.
%   bins: Array defining the bin edges or categories.
%   binned_accuracy: Boolean indicating whether to bin by accuracy.
%   two_tailed: Boolean indicating whether to perform two-tailed tests.
%   save_dir: Directory for saving results.
%   betas_save: Filename for saving beta coefficients.
%   perm_save: Filename for saving permutation test results.
%   base_dir: Directory with baseline pupil data.
%   bins_array: array with bin numbers.
%   col: length of pupil signal in learning window.
%   num_vars: number of variables in the regression model.
%   model_def: string with model to be fit.
%   pred_vars: cell array with predictor variables names.
%   cat_vars: cell array with categorical predictors.
%   resp_var: cell array with dependent variable.
%
% OUTPUT:
%   betas_struct: Estimated betas
%   perm: results from the permutation test

% LOOP OVER SUBJECTS
residuals_all = cell(num_subs,1);
predicted_all = cell(num_subs,1);

for i = 1:num_subs

    residuals_subj = [];
    predicted_subj = [];

% GET BEHAVIORAL DATA
fprintf('reading in %s ...\n', subj_ids{i});
behv_data = [];
data_run = [];
for j = 1:num_sess(i)
    filename = strcat(behv_dir,filesep,subj_ids{i},'_','main',num2str(j),'.xlsx');
    if strcmp(subj_ids{i},'4672') == 1
        filename = strcat(behv_dir,filesep,subj_ids{i},'_','main',num2str(j),'_red.xlsx');
    end
    data_run = readtable(filename);
    rt = table(data_run.choice_rt,'VariableNames',{'rt'});
    slider = table(data_run.slider_respond_response,'VariableNames',{'slider'});
    data_run = [data_run(:,[1:16]),rt,slider];
    behv_data = [behv_data; data_run];
end

% MISSED TRIALS
missedtrials_rt = isnan(behv_data.rt); % trials with rt = NaN
behvdata_missedRT = behv_data(missedtrials_rt == 0,:); % remove these trials
missedtrials_slider = isnan(behvdata_missedRT.slider); % trials with slider = NaN
missedtrials = isnan(behv_data.rt) | isnan(behv_data.slider); % remove these trials
behv_data(missedtrials == 1,:) = [];

% GET PUPIL SIGNAL, X-GAZE, Y-GAZE
fprintf('pupil signal...\n');
filename = strcat(pupil_dir,filesep,subj_ids{i},'.mat');
pupil = importdata(filename);
size_pupil = size(pupil);

filename = strcat(xgaze_dir,filesep,subj_ids{i},'.mat');
xgaze_event = importdata(filename);

filename = strcat(ygaze_dir,filesep,subj_ids{i},'.mat');
ygaze_event = importdata(filename);

if strcmp(timewindow,'patch') == 1
    zsc_pupil = pupil;
    xgaze_signal = xgaze_event;
    ygaze_signal = ygaze_event;
    col = size_pupil(2);
elseif strcmp(timewindow,'feedback') == 1
    zsc_pupil = pupil(:,1:col);
    xgaze_signal = xgaze_event(:,1:col);
    ygaze_signal = ygaze_event(:,1:col);
    col = size(zsc_pupil);
    col = col(2);
end

% REMOVE MISSED TRIALS
zsc_pupil(missedtrials_slider==1,:) = [];
xgaze_signal(missedtrials==1,:) = [];
ygaze_signal(missedtrials==1,:) = [];

% IF RTs TO BE REGRESSED
if regress_rt == 1
    for c = 1:col
        zsc_pupil(:,c) = remove_rt_effects(zsc_pupil(:,c),log(behv_data.rt));
    end
end

% IF BASELINE MODEL IS BEING USED
if baseline_mdl == 1
    fprintf('getting baseline pupil measures...\n');
    filename = strcat(base_dir,filesep,subj_ids{i},'.mat');
    zsc_base = importdata(filename);
    zsc_base(missedtrials_slider==1,:) = [];
end

% GET BEHAVIORAL PREDICTORS
fprintf('get predictors from behavioural data...\n');
preds = preds_all(preds_all.id == str2num(subj_ids{i}),:);
preds(isnan(preds.slider),:) = []; % remove no slider responses
validIndices = find(preds.pe == 0); % pe == 0
preds(validIndices,:) = []; % delete pe == 0
zsc_pupil(validIndices,:) = [];
xgaze_signal(validIndices,:) = [];
ygaze_signal(validIndices,:) = [];
behv_data(validIndices,:) = [];
zsc_base(validIndices,:) = []; % added to check what's going on here 

% BINNED REGRESSION
if binned == 1
    preds.bin_columns = discretize(preds.con_diff,bins);
end

% LOOP OVER BINS
for r = bins_array
    fprintf('fitting model...\n');

    % GET RELEVANT DATA FOR EACH BIN
    if binned == 1
        pupil_signal_bins = zsc_pupil(preds.bin_columns == r,:);
        xgaze_signal_bins = xgaze_signal(preds.bin_columns == r,:);
        ygaze_signal_bins = ygaze_signal(preds.bin_columns == r,:);
        behv_data_bins = behv_data(preds.bin_columns == r,:);
        preds_bins = preds(preds.bin_columns == r,:);
    elseif binned_accuracy == 1
        pupil_signal_bins = zsc_pupil(preds.correct == r,:);
        xgaze_signal_bins = xgaze_signal(preds.correct == r,:);
        ygaze_signal_bins = ygaze_signal(preds.correct == r,:);
        behv_data_bins = behv_data(preds.correct == r,:);
        preds_bins = preds(preds.correct == r,:);
    end

    for c = 1:col

        % GET RID OF NaNs
        if binned == 1 || binned_accuracy == 1
            y = pupil_signal_bins(:,c);
            zsc_xgaze = nanzscore(xgaze_signal_bins(:,c));
            zsc_ygaze = nanzscore(ygaze_signal_bins(:,c));
            behv = behv_data_bins;
            predictors = preds_bins;
        else
            y = zsc_pupil(:,c);
            zsc_xgaze = nanzscore(xgaze_signal(:,c));
            zsc_ygaze = nanzscore(ygaze_signal(:,c));
            behv = behv_data;
            predictors = preds;
            if baseline_mdl == 1
                base_regressor = zsc_base;
            end
        end

        % REMOVE ALL NANs
        validIndices = ~isnan(y);
        yValid = y(validIndices==1);
        xgazeValid = zsc_xgaze(validIndices==1);
        ygazeValid = zsc_ygaze(validIndices==1);
        preds_nan = predictors(validIndices==1,:);
        behv_nan = behv(validIndices==1,:);

        validIndices = ~isnan(preds_nan.up);
        yValid = yValid(validIndices==1);
        xgazeValid = xgazeValid(validIndices==1);
        ygazeValid = ygazeValid(validIndices==1);
        preds_nan = preds_nan(validIndices==1,:);
        behv_nan = behv_nan(validIndices==1,:);
        if baseline_mdl == 1
            base_nan = base_regressor(validIndices == 1,:);
        end
        if height(preds_nan) > num_vars + 1

            % should be greater than number of predictors + intercept
            % for categorical vars, there should be enough trials with all
            % category information

            % GET TABLE WITH REGRESSORS
            tbl = table(yValid,xgazeValid,ygazeValid,...
                nanzscore(preds_nan.con_diff),nanzscore(preds_nan.pe),...
                nanzscore(abs(preds_nan.pe)),nanzscore(abs(preds_nan.up)), ...
                nanzscore(log(preds_nan.rt)),preds_nan.condition,preds_nan.ecoperf,preds_nan.correct,nanzscore(preds.pe_condiff),...
                'VariableNames',{'pupil','xgaze','ygaze', ...
                'zsc_condiff','signed_pe','pe','zsc_up','rt','condition','ecoperf','reward','pe_condiff'});

            if baseline_mdl == 1
                tbl.baseline = base_nan;
            end

            % FIT THE MODEL
            [betas,rsquared,residuals,coeffs_name,lm] = linear_fit(tbl,model_def ...
                ,pred_vars,resp_var,cat_vars,num_vars,0,0,0,0);
            residuals_subj = [residuals_subj,residuals];
            predicted = predict(lm,tbl);
            predicted_subj = [predicted_subj,predicted];
            if binned_accuracy == 1
                betas_struct.with_intercept(r+1,:,i,c) = betas(1:end);
            else
                betas_struct.with_intercept(r,:,i,c) = betas(1:end);
            end
        end
    end
    fprintf('storing beta coefficients...\n');
end
residuals_all{i,1} = residuals_subj;
predicted_all{i,1} = predicted_subj;
end

% SAVE

% RUN PERM TEST
num_vars = 1:num_vars+1; % number of variables
var1 = betas_struct.with_intercept;
var2 = betas_struct.with_intercept;
betas = 1; % permutation test on regression data
perm = get_permtest(num_vars, num_subs, col, var1, var2, two_tailed, betas);
end