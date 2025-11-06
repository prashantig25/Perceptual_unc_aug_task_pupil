% residualUP_analysis runs analysis to explain residual learning using
% pupil-linked arousal.

clc
clearvars 

% INITIALISE VARS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
mdl = 'up~ pupil + pe:pupil:con_diff + pupil:pe + pupil:con_diff + post_up'; % residual-analysis model
num_vars = 5; % number of predictors
resp_var = {'up'}; % response var
cat_vars = {''}; % cell-array of categorical vars
pred_vars = {'post_up','pe','pupil','con_diff'}; % cell array with predictor vars
col = 300; % length of pupil signal
num_subjs = length(subj_ids); % number of subjects
timewindow = 'feedback'; % pupil signal from which window is used for residual analysis
betas_pupil.with_intercept = NaN(1,num_vars+1,length(subj_ids),col); % initialised structure to store model-estimated betas
residulalsAnalyse_SSE = NaN(length(subj_ids),col); % initialised structure to store model-estimated betas

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
posterior_all = importdata(strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'LR analyses', filesep, "post_absUP_predict.mat")); % posterior update
pupil_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb'); % directory to get preprocessed data
save_dir = fullfile(desiredPath, 'Data', 'GB data two pipelines', 'pupil', 'residual');

preds_all = readtable(strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx')); % get behavioral predictors
behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'raw data'); % directory to get behavioral data
mkdir(save_dir);

% GET THE INDEX OF SUBJ_IDs AFTER SORTING
subj_ids_num = [];
for n = 1:length(subj_ids)
    subj_ids_num = [subj_ids_num;str2num(subj_ids{n})];
end
subj_ids_num_sorted = sort(subj_ids_num,"ascend"); % sort
array_index = [];
for n = 1:length(subj_ids)
    array_index = [array_index;find(str2num(subj_ids{n}) == subj_ids_num_sorted)];  % get index
end

for n = 1:num_subjs

    % GET MISSED TRIALS
    behv_data = [];
    data_run = [];
    for j = 1:num_sess(n)
        filename = strcat(behv_dir,filesep,subj_ids{n},'_','main',num2str(j),'.xlsx');
        if strcmp(subj_ids{n},'4672') == 1
            filename = strcat(behv_dir,filesep,subj_ids{n},'_','main',num2str(j),'_red.xlsx');
        end
        data_run = readtable(filename);
        rt = table(data_run.choice_rt,'VariableNames',{'rt'});
        slider = table(data_run.slider_respond_response,'VariableNames',{'slider'});
        data_run = [data_run(:,[1:16]),rt,slider];
        behv_data = [behv_data; data_run];
    end
    missedtrials_rt = isnan(behv_data.rt);
    behv_data(missedtrials_rt==1,:) = []; % remove missed trials
    missedtrials = isnan(behv_data.slider);

    % LOAD PUPIL SIGNAL
    filename = strcat(pupil_dir,filesep,subj_ids{n},'.mat');
    pupil = importdata(filename);
    size_pupil = size(pupil);
    if strcmp(timewindow,'patch') == 1
        pupil_signal = pupil;
    elseif strcmp(timewindow,'feedback') == 1 
        pupil_signal = pupil(:,1:col);
    end
    pupil_signal(missedtrials == 1,:) = [];

    % GET BEHAVIORAL REGRESSORS
    preds = preds_all(preds_all.id == str2num(subj_ids{n}),:);
    post_up = abs(posterior_all{array_index(n),1});  
    validIndices = find(preds.pe == 0); % pe == 0
    preds(validIndices,:) = []; % delete pe == 0
    pupil_signal(validIndices,:) = []; % delete pe == 0

    % FIT THE MODEL FOR EACH SAMPLE OF PUPIL SIGNAL
    for c = 1:col
        up = abs(preds.up);
        pe = abs(preds.pe);
        condiff = preds.con_diff;
        pupil_tp = pupil_signal(:,c);
        tbl = table(nanzscore(up),nanzscore(post_up),nanzscore(pe), ...
            nanzscore(pupil_tp),nanzscore(condiff),'VariableNames',{'up','post_up','pe','pupil','con_diff'});
        [betas,rsquared,residuals,coeffs_name,lm] = linear_fit(tbl,mdl, ...
            pred_vars,resp_var,'',num_vars,0,0,0,0);
        betas_pupil.with_intercept(1,:,n,c) = betas;
    end
end

% SAVE BETAS
safe_saveall(strcat(save_dir,filesep,"betas_behvresidual_abs_pecondiff_nomain.mat"), betas_pupil);

% RUN PERM TEST
num_vars = 1:num_vars+1; % number of variables
var1 = betas_pupil.with_intercept; 
var2 = betas_pupil.with_intercept;
betas = 1; % permutation test on regression data
two_tailed = 0; % run one-tailed permutation test 
perm = get_permtest(num_vars, num_subjs, col, var1, var2, two_tailed, betas);
safe_saveall(strcat(save_dir,filesep,"perm_betas_behvresidual_abs_pecondiff_nomain.mat"), perm);