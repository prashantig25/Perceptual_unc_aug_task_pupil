clc
clearvars

% INITIALISE VARS and PATHS
colors;
colors_manuscript;
subj_ids = {'0806','3970','4300','4885','4954','907','2505','3985','4711',...
    '3376','4927','190','306','3391','5047','3922','659','421','3943',...
    '4225','4792','3952','4249','4672','4681','4738','3904','852','3337',...
    '3442','3571','4360','4522','4807','4943','594','379','4057','4813','601',...
    '3319','129','4684','3886','620','901','900'};
timewindow = 'feedback'; % specify for which event pupil signal is being plotted
col = 300; % length of signal to be plotted
num_subs = length(subj_ids); % number of subjects
num_sess = [1,1,1,1,1,1,1,1,1,1,1,2,2,1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]; % number of sessions
preds_all = readtable("C:\Users\prash\Nextcloud\Thesis_laptop\Semester 7\pupil_manuscript\" + ...
    "data_files\preprocessed_behv\preprocessed_lr_pupil.xlsx");
pupil_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 7\pupil_manuscript\data_files\pupil_events\fb\basecorrected';
behv_dir = 'C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_data\pre_preprocessed\behv\with_missed_trials';
x = linspace(-300,2700,col); % specify x-axis for plot

% INITIALISE VARS TO STORE PUPIL SIGNAL
subj_pupil_signal = NaN(num_subs,col);
subj_pupil_signal_pebin1 = NaN(num_subs,col);
subj_pupil_signal_pebin2 = NaN(num_subs,col);
subj_pupil_signal_cond1 = NaN(num_subs,col);
subj_pupil_signal_cond2 = NaN(num_subs,col);

% LOOP OVER SUBJECTS
for i = 1:num_subs

    % GET BEHAVIORAL DATA
    preds = preds_all(preds_all.id == str2num(subj_ids{i}),:);
    ecoperf1 = find(abs(preds.pe) < 0.5); % pe bin = 1 trials
    ecoperf0 = find(abs(preds.pe) > 0.5);
    cond1 = find(preds.condition == 1); % both-uncertainties condition
    cond2 = find(preds.condition == 2); % perceptual uncertainty condition

    % GET PUPIL DATA
    filename = strcat(pupil_dir,'\',subj_ids{i},'.mat');
    load(filename,'pupil');
    if strcmp(timewindow,'patch') == 1
        pupil_signal = pupil;
    elseif strcmp(timewindow,'feedback') == 1
        pupil_signal = pupil(:,1:col);
    end

    % GET MEAN SIGNAL FOR EACH SUBJECT
    subj_pupil_signal(i,:) = nanmean(pupil_signal);
    subj_pupil_signal_pebin2(i,:) = nanmean(pupil_signal(ecoperf1,:));
    subj_pupil_signal_pebin1(i,:) = nanmean(pupil_signal(ecoperf0,:));
    subj_pupil_signal_cond1(i,:) = nanmean(pupil_signal(cond1,:));
    subj_pupil_signal_cond2(i,:) = nanmean(pupil_signal(cond2,:));
end

% save("fb_dilation",'subj_pupil_signal')

% GET MEANS and SEMs
avg_pupil_signal = nanmean(subj_pupil_signal);
sem_pupil_signal = nanstd(subj_pupil_signal)./sqrt(num_subs);

avg_pupil_signal_ecoperf1 = nanmean(subj_pupil_signal_pebin2);
sem_pupil_signal_ecoperf1 = nanstd(subj_pupil_signal_pebin2)./sqrt(num_subs);

avg_pupil_signal_ecoperf0 = nanmean(subj_pupil_signal_pebin1);
sem_pupil_signal_ecoperf0 = nanstd(subj_pupil_signal_pebin1)./sqrt(num_subs);

avg_pupil_signal_cond1 = nanmean(subj_pupil_signal_cond1);
sem_pupil_signal_cond1 = nanstd(subj_pupil_signal_cond1)./sqrt(num_subs);

avg_pupil_signal_cond2 = nanmean(subj_pupil_signal_cond2);
sem_pupil_signal_cond2 = nanstd(subj_pupil_signal_cond2)./sqrt(num_subs);

% PLOT CURVES
figure('Visible','on','Position',[100,100,250,250])
hold on
lg_curves(x,avg_pupil_signal,sem_pupil_signal,neutral,"","",'Time since feedback onset (ms)','Pupil dilation',6,1,'Arial')
xlim([-300,2700])
xline(0,'--')
yline(0,'--')

mean_curves = [avg_pupil_signal_ecoperf0; avg_pupil_signal_ecoperf1];
sem_curves = [sem_pupil_signal_ecoperf0; sem_pupil_signal_ecoperf1];
curve_colors = [incorr;fb_green];
figure('Visible','on','Position',[100,100,250,250])
hold on
lg_curves(x,mean_curves,sem_curves,curve_colors,{'PE bin 2','PE bin 1'},"",'Time since feedback onset (ms)','Pupil dilation',6,1,'Arial')
xlim([-300,2700])
xline(0,'--')
yline(0,'--')

mean_curves = [avg_pupil_signal_cond1; avg_pupil_signal_cond2];
sem_curves = [sem_pupil_signal_cond1; sem_pupil_signal_cond2];
curve_colors = [incorr;fb_green];
figure('Visible','on','Position',[100,100,250,250])
hold on
lg_curves(x,mean_curves,sem_curves,curve_colors,{'Both','Perceptual'},"",'Time since feedback onset (ms)','Pupil dilation',6,1,'Arial')
xlim([-300,2700])
xline(0,'--')
yline(0,'--')