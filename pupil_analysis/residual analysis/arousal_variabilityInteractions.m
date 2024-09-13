clc
clearvars

col = 300; % length of x-axis
xaxis = linspace(-300,2700,col); % x-axis
nsubjs = 47; % number of subjects
betas_pupil = importdata("betas_behvresidual_abs_pecondiff_nomain.mat");
preds_all = readtable("preprocessed_lr_pupil.xlsx");
posterior_all = importdata("post_absUP_predict.mat"); % posterior update
betas_field = betas_pupil.with_intercept;
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813',...
    '601','3319','129','4684','3886','620','901','900'};
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions

pupil_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\data_space\pupil\fb\base_corrected';
behv_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_data\pre_preprocessed\behv\with_missed_trials';

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

for s = [1:nsubjs]

    % GET BEHAVIORAL DATA
    fprintf('reading in %s ...\n', subj_ids{s});
    behv_data = [];
    data_run = [];
    for j = 1:num_sess(s)
        filename = strcat(behv_dir,'\',subj_ids{s},'_','main',num2str(j),'.xlsx');
        if strcmp(subj_ids{s},'4672') == 1
            filename = strcat(behv_dir,'\',subj_ids{s},'_','main',num2str(j),'_red.xlsx');
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

    % LOAD PUPIL SIGNAL
    filename = strcat(pupil_dir,'\',subj_ids{s},'.mat');
    pupil = importdata(filename);
    size_pupil = size(pupil);
    pupil_signal = pupil(:,1:col);
    pupil_signal(missedtrials_slider==1,:) = [];

    % GET BEHAVIORAL REGRESSORS
    preds = preds_all(preds_all.id == str2num(subj_ids{s}),:);
    validIndices = find(preds.pe == 0); % pe == 0
    preds(validIndices,:) = []; % delete pe == 0
    pupil_signal(validIndices,:) = []; % delete pe == 0
    preds.zsc_condiff = nanzscore(preds.norm_condiff);
    for c = 1:col
        coeffs.pupil(1,c) = betas_field(1,3,s,c);
        coeffs.pe_condiff_pupil(1,c) = betas_field(1,6,s,c);
        coeffs.pe_pupil(1,c) = betas_field(1,4,s,c);
        coeffs.con_diff_pupil(1,c) = betas_field(1,5,s,c);
        coeffs.post_up(1,c) = betas_field(1,2,s,c);
        coeffs.intercept(1,c) = betas_field(1,1,s,c);
        coeffs.pupil_signal(:,c) = pupil_signal(:,c);
    end
    post_up = abs(posterior_all{array_index(s),1});
    pe_trial = abs(preds.pe); % single trial PEs
    condiff_trial = preds.zsc_condiff; % contrast difference
    predicted_UP = coeffs.intercept + coeffs.pupil.*coeffs.pupil_signal + coeffs.pe_condiff_pupil.* pe_trial .* coeffs.pupil_signal.* condiff_trial + coeffs.pe_pupil.* pe_trial .* coeffs.pupil_signal + coeffs.con_diff_pupil.* condiff_trial .* coeffs.pupil_signal + coeffs.post_up .* post_up;
    pupil_mean = nanmean(pupil_signal,2); % mean pupil-linked arousa

    % DIVIDE TRIALS FOR HIGH AND LOW AROUSAL
    bin_edges = prctile(pupil_mean, 0:50:100); % calculate percentile edges
    bins = discretize(pupil_mean, bin_edges); % bin contrast differences 
    predicted_UP_lowarousal = predicted_UP(bins == 1,:);
    predicted_UP_higharousal = predicted_UP(bins == 2,:);

    % BIN TRIALS FOR HIGH AND LOW BS UNCERTAINTY
    condiff_lowarousal = condiff_trial(bins == 1,:);
    condiff_higharousal = condiff_trial(bins == 2,:);

    % BIN HIGH AROUSAL TRIALS FOR BS UNCERTAINTY
    bin_edges = prctile(condiff_higharousal, 0:50:100); % calculate percentile edges
    bins = discretize(condiff_higharousal, bin_edges); % bin contrast differences 
    predicted_UP_higharousal_lowcondiff = predicted_UP_higharousal(bins == 1,:);
    predicted_UP_higharousal_highcondiff = predicted_UP_higharousal(bins == 2,:); 

    % BIN LOW AROUSAL TRIALS FOR BS UNCERTAINTY
    bin_edges = prctile(condiff_lowarousal, 0:50:100); % calculate percentile edges
    bins = discretize(condiff_lowarousal, bin_edges); % bin contrast differences
    predicted_UP_lowarousal_lowcondiff = predicted_UP_lowarousal(bins == 1,:);
    predicted_UP_lowarousal_highcondiff = predicted_UP_lowarousal(bins == 2,:);

    % STORE
    posterior.lowarousal_lowcondiff(s,:) = nanmean(predicted_UP_lowarousal_lowcondiff);
    posterior.lowarousal_highcondiff(s,:) = nanmean(predicted_UP_lowarousal_highcondiff);
    posterior.higharousal_lowcondiff(s,:) = nanmean(predicted_UP_higharousal_lowcondiff);
    posterior.higharousal_highcondiff(s,:) = nanmean(predicted_UP_higharousal_highcondiff);

    clear coeffs
end

safe_saveall("BSarousal_interactions.mat",posterior);