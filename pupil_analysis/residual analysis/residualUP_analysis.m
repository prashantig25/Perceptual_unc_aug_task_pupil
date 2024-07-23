clc
clearvars 

% INITIALISE VARS
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'}; % subject-IDs
load("post_signedUP_predict.mat"); posterior_all = posterior_up_subjs; % posterior update
mdl = 'up~ pupil + pe:pupil:con_diff + pupil:pe + pupil:con_diff +post_up'; % residual-analysis model
num_vars = 5; % number of predictors
resp_var = {'up'}; % response var
cat_vars = {''}; % cell-array of categorical vars
pred_vars = {'post_up','pe','pupil','con_diff'}; % cell array with predictor vars
preds_all = readtable("C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\" + ...
    "data_files\behv_regression\preprocessed_lr_pupil.xlsx"); % get behavioral variables
col = 300; % length of pupil signal
num_subjs = length(subj_ids); % number of subjects
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions
timewindow = 'feedback'; % pupil signal from which window is used for residual analysis
betas_pupil.with_intercept = NaN(1,num_vars+1,length(subj_ids),col); % initialised structure to store model-estimated betas

% PATH STUFF
behv_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_data\pre_preprocessed\behv\with_missed_trials';
preproc_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_data\preprocessed\pupil\gaze_data';
pupil_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 7\pupil_manuscript\data_files\pupil_events\fb\basecorrected';

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
        filename = strcat(behv_dir,'\',subj_ids{n},'_','main',num2str(j),'.xlsx');
        if strcmp(subj_ids{n},'4672') == 1
            filename = strcat(behv_dir,'\',subj_ids{n},'_','main',num2str(j),'_red.xlsx');
        end
        data_run = readtable(filename);
        rt = table(data_run.choice_rt,'VariableNames',{'rt'});
        slider = table(data_run.slider_respond_response,'VariableNames',{'slider'});
        data_run = [data_run(:,[1:16]),rt,slider];
        behv_data = [behv_data; data_run];
    end
    missedtrials = isnan(behv_data.rt) | isnan(behv_data.slider);

    % LOAD PUPIL SIGNAL
    filename = strcat(pupil_dir,'\',subj_ids{n},'.mat');
    load(filename,'pupil');
    size_pupil = size(pupil);
    if strcmp(timewindow,'patch') == 1
        pupil_signal = pupil;
    elseif strcmp(timewindow,'feedback') == 1 
        pupil_signal = pupil(:,1:300);
    end
    pupil_signal(missedtrials==1,:) = []; % remove missed trials

    % GET BEHAVIORAL REGRESSORS
    preds = preds_all(preds_all.id == str2num(subj_ids{n}),:);
    validIndices = find(preds.pe == 0); % pe == 0
    preds(validIndices,:) = []; % delete pe == 0
    pupil_signal(validIndices,:) = []; % delete pe == 0

    % FIT THE MODEL FOR EACH SAMPLE OF PUPIL SIGNAL
    for c = 1:col
        post_up = abs(posterior_all{array_index(n),1});
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
save("betas_behvresidual_abs_pecondiff_nomain","betas_pupil")