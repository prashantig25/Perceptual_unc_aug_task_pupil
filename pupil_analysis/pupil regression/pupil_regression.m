clc
clearvars

% INITIALIZE VARS
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'};
timewindow = 'feedback'; % time-window on which regression needs to be applied
col = 300; % number of samples on which the regression is applied
num_subs = length(subj_ids); % number of subjects
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions
regress_rt = 0; % remove RT effects
preds_all = readtable("C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\" + ...
    "data_files\behv_regression\preprocessed_lr_pupil.xlsx");
pred_vars = {'pe','abs_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff'};% cell array with names of predictor variables
resp_var = 'pupil'; % name of response variable
cat_vars = {'condition'}; % cell array with names of categorical variables
binned = 1; % whether binned regression approach is to be used
if binned == 1 
    num_bins = 2; % number of bins
    bins = prctile(preds_all.con_diff,0:50:100); % bin edges
    model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + rt';
    num_vars = 5; % number of predictor vars
else
    num_bins = 1;
    model_def = 'pupil ~ xgaze + ygaze + pe + zsc_up  + rt + zsc_condiff + pe:zsc_condiff';
    num_vars = 7; % number of predictor vars
end
betas_struct.with_intercept = NaN(num_bins,num_vars+1,length(subj_ids),col); % initialize struct to store number of bins

% PATH STUFF
behv_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_data\pre_preprocessed\behv\with_missed_trials';
preproc_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_data\preprocessed\pupil\gaze_data';
pupil_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\preprocessed_eventnames\pupil_signal\baseline corrected\fb';
xgaze_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\preprocessed_eventnames\gaze_position\x-gaze';
ygaze_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\preprocessed_eventnames\gaze_position\y-gaze';

% LOOP OVER SUBJECTS
for i = 1:num_subs

    % GET BEHAVIORAL DATA
    fprintf('reading in %s ...\n', subj_ids{i});
    behv_data = [];
    data_run = [];
    for j = 1:num_sess(i)
        filename = strcat(behv_dir,'\',subj_ids{i},'_','main',num2str(j),'.xlsx');
        if strcmp(subj_ids{i},'4672') == 1
            filename = strcat(behv_dir,'\',subj_ids{i},'_','main',num2str(j),'_red.xlsx');
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
    filename = strcat(pupil_dir,'\',subj_ids{i},'.mat');
    load(filename,'pupil');
    size_pupil = size(pupil);

    filename = strcat(xgaze_dir,'\',subj_ids{i},'.mat');
    load(filename,"xgaze_event");

    filename = strcat(ygaze_dir,'\',subj_ids{i},'.mat');
    load(filename,"ygaze_event");

    if strcmp(timewindow,'patch') == 1
        pupil_signal = pupil;
        xgaze_signal = xgaze_event;
        ygaze_signal = ygaze_event;
        col = size_pupil(2);
    elseif strcmp(timewindow,'feedback') == 1
        pupil_signal = pupil(:,1:col);
        xgaze_signal = xgaze_event(:,1:col);
        ygaze_signal = ygaze_event(:,1:col);
        col = size(pupil_signal);
        col = col(2);
    end

    % REMOVE MISSED TRIALS
    pupil_signal(missedtrials_slider==1,:) = [];
    xgaze_signal(missedtrials==1,:) = [];
    ygaze_signal(missedtrials==1,:) = [];

    % IF RTs TO BE REGRESSED
    if regress_rt == 1
        for c = 1:col
            pupil_signal(:,c) = remove_rt_effects(pupil_signal(:,c),log(behv_data.rt));
        end
    end

    % GET BEHAVIORAL PREDICTORS
    fprintf('get predictors from behavioural data...\n');
    preds = preds_all(preds_all.id == str2num(subj_ids{i}),:);
    validIndices = find(preds.pe == 0); % pe == 0
    preds(validIndices,:) = []; % delete pe == 0
    pupil_signal(validIndices,:) = [];
    xgaze_signal(validIndices,:) = [];
    ygaze_signal(validIndices,:) = [];
    behv_data(validIndices,:) = [];

    % BINNED REGRESSION
    if binned == 1
        preds.bin_columns = discretize(preds.con_diff,bins);
    end

    % LOOP OVER BINS
    for r = 1:num_bins
        fprintf('fitting model...\n');

        % GET RELEVANT DATA FOR EACH BIN
        if binned == 1
            pupil_signal_bins = pupil_signal(preds.bin_columns == r,:);
            xgaze_signal_bins = xgaze_signal(preds.bin_columns == r,:);
            ygaze_signal_bins = ygaze_signal(preds.bin_columns == r,:);
            behv_data_bins = behv_data(preds.bin_columns == r,:);            
            preds_bins = preds(preds.bin_columns == r,:);
        end

        for c = 1:col

            % GET RID OF NaNs
            if binned == 0
                y = nanzscore(pupil_signal(:,c));
                xgaze = nanzscore(xgaze_signal(:,c));
                ygaze = nanzscore(ygaze_signal(:,c));
                behv = behv_data;
                predictors = preds;
            else
                y = nanzscore(pupil_signal_bins(:,c));
                xgaze = nanzscore(xgaze_signal_bins(:,c));
                ygaze = nanzscore(ygaze_signal_bins(:,c));
                behv = behv_data_bins;
                predictors = preds_bins;
            end
            
            % REMOVE ALL NANs
            validIndices = ~isnan(y);
            yValid = y(validIndices==1);
            xgazeValid = xgaze(validIndices==1);
            ygazeValid = ygaze(validIndices==1);
            preds_nan = predictors(validIndices==1,:);
            behv_nan = behv(validIndices==1,:);
            if height(preds_nan) > num_vars + 1

                % should be greater than number of predictors + intercept
                % for categorical vars, there should be enough trials with all
                % category information

                % GET TABLE
                tbl = table(yValid,xgazeValid,ygazeValid,...
                    nanzscore(preds_nan.con_diff),abs(preds_nan.pe),...
                    nanzscore(abs(preds_nan.pe)),nanzscore(abs(preds_nan.up)), ...
                    nanzscore(log(behv_nan.rt)),preds_nan.condition, ...
                    'VariableNames',{'pupil','xgaze','ygaze', ...
                    'zsc_condiff','abs_pe','pe','zsc_up','rt','condition'});

                % FIT THE MODEL
                [betas,rsquared,residuals,coeffs_name,lm] = linear_fit(tbl,model_def ...
                    ,pred_vars,resp_var,cat_vars,num_vars,0,0,0,0);
                betas_struct.with_intercept(r,:,i,c) = betas(1:end);
            end
        end
        fprintf('storing beta coefficients...\n');
    end
end

% SAVE
save("pe_condiff2bins","betas_struct")