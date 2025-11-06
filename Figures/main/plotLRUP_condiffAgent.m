clc
clearvars

dataAgent = importdata("/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/eLife_MS/Reward-learning-analysis (code_review)/Data/model fitting/agent simulations for mu range/range mu/preprocessed_agent.mat");
id_subjs = unique(dataAgent.ID);
num_subjs = length(id_subjs);
line_width = 1;
binned_dots = [186, 220, 189]./255;

% INITIALISE VARS TO BE PLOTTED
binned_data = abs(dataAgent.contrast_diff); % absolute contrast difference
nbins = 10; % number of bins
bin_edges = prctile(binned_data, 0:10:100); % calculate percentile edges
bins = discretize(binned_data, bin_edges); % bin contrast differences 
dataAgent.lr = dataAgent.up./dataAgent.pe; % learning rates
dataAgent.abs_lr = abs(dataAgent.lr); % absolute learning rates
dataAgent.abs_up = abs(dataAgent.up); % absolute updates

% GET RID OF TRIALS WHERE PE = 0 AND OUTLIER LRs
run_id = dataAgent.ID(dataAgent.pe ~= 0 & abs(dataAgent.lr)<=2);
y_data = abs(dataAgent.lr(dataAgent.pe ~= 0 & abs(dataAgent.lr)<=2));
bins = bins(dataAgent.pe ~= 0 & abs(dataAgent.lr)<=2);
binned_data = binned_data(dataAgent.pe ~= 0 & abs(dataAgent.lr)<=2);

% MEAN LRs for CONDIFF BINS
avg_ydata_bins = NaN(nbins,99); 
avg_behv_bins = NaN(nbins,99); 
for b = 1:nbins
    for n = 1:99
        bins_subj = bins(run_id == id_subjs(n));
        y_data_subj = y_data(run_id == id_subjs(n));
        binned_data_subj = binned_data(run_id == id_subjs(n));
        avg_behv_bins(b,n) = nanmean(binned_data_subj(bins_subj == b));
        avg_ydata_bins(b,n) = nanmean(y_data_subj(bins_subj == b));
    end
end
avg_ydata = nanmean(avg_ydata_bins,2);
avg_binneddata = nanmean(avg_behv_bins,2);
sem_ydata = nanstd(avg_ydata_bins,0,2)./sqrt(num_subjs);

% PLOT
figure("Position",[100,100,600,200])
hold on
subplot(1,3,1)
hold on
s1 = scatter(1:nbins,avg_ydata,"filled",'MarkerEdgeColor',"none",'MarkerFaceColor',"none");
ls = lsline;
ls.Color = 'k';
hold('on')
errorbar(1:nbins,avg_ydata, sem_ydata, 'k', 'LineWidth',line_width,'LineStyle','none');
hold on
s1 = scatter(1:nbins,avg_ydata,"filled",'MarkerEdgeColor',"k",'MarkerFaceColor',binned_dots);
xlabel("Contrast difference bins" + newline + "(1 bin = 0.01)")
ylabel('Mean learning rate (Agent)')

% ADJUST FIGURE PROPERTIES
% xlim_vals = [0 10.3];
% ylim_vals = [-0.01 0.17];
% adjust_figprops(ax10_new,font_name,font_size,line_width,xlim_vals,ylim_vals);
[rho,pval] = corr(avg_ydata,avg_binneddata, 'rows', 'pairwise');
title(strcat("\itr\rm =",{' '},num2str(round(rho,2)),{' '}) + newline + "\itp\rm < 0.001", ...
    'FontWeight','normal','Interpreter','tex')

y_data = abs(dataAgent.up(dataAgent.pe ~= 0 & abs(dataAgent.lr)<=2));
bins = bins(dataAgent.pe ~= 0 & abs(dataAgent.lr)<=2);
binned_data = binned_data(dataAgent.pe ~= 0 & abs(dataAgent.lr)<=2);

% MEAN LRs for CONDIFF BINS
avg_ydata_bins = NaN(nbins,99); 
avg_behv_bins = NaN(nbins,99); 
for b = 1:nbins
    for n = 1:99
        bins_subj = bins(run_id == id_subjs(n));
        y_data_subj = y_data(run_id == id_subjs(n));
        binned_data_subj = binned_data(run_id == id_subjs(n));
        avg_behv_bins(b,n) = nanmean(binned_data_subj(bins_subj == b));
        avg_ydata_bins(b,n) = nanmean(y_data_subj(bins_subj == b));
    end
end
avg_ydata = nanmean(avg_ydata_bins,2);
avg_binneddata = nanmean(avg_behv_bins,2);
sem_ydata = nanstd(avg_ydata_bins,0,2)./sqrt(num_subjs);

% PLOT
hold on
subplot(1,3,2)
hold on
s1 = scatter(1:nbins,avg_ydata,"filled",'MarkerEdgeColor',"none",'MarkerFaceColor',"none");
ls = lsline;
ls.Color = 'k';
hold('on')
errorbar(1:nbins,avg_ydata, sem_ydata, 'k', 'LineWidth',line_width,'LineStyle','none');
hold on
s1 = scatter(1:nbins,avg_ydata,"filled",'MarkerEdgeColor',"k",'MarkerFaceColor',binned_dots);
xlabel("Contrast difference bins" + newline + "(1 bin = 0.01)")
ylabel('Mean update (Agent)')

% ADJUST FIGURE PROPERTIES
% xlim_vals = [0 10.3];
% ylim_vals = [-0.01 0.17];
% adjust_figprops(ax10_new,font_name,font_size,line_width,xlim_vals,ylim_vals);
[rho,pval] = corr(avg_ydata,avg_binneddata, 'rows', 'pairwise');
title(strcat("\itr\rm =",{' '},num2str(round(rho,2)),{' '}) + newline + "\itp\rm < 0.001", ...
    'FontWeight','normal','Interpreter','tex')

regression_path = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/behavior/LR analyses"; 
data_subjs = readtable(fullfile(regression_path,"preprocessed_lr_pupil_no_zerope.xlsx")); % preprocessed LR data
id_subjs = unique(data_subjs.id);
num_subjs = length(id_subjs);

% INITIALISE VARS TO BE PLOTTED
binned_data = abs(data_subjs.con_diff); % absolute contrast difference
nbins = 10; % number of bins
bin_edges = prctile(binned_data, 0:10:100); % calculate percentile edges
bins = discretize(binned_data, bin_edges); % bin contrast differences 
data_subjs.lr = data_subjs.up./data_subjs.pe; % learning rates
data_subjs.abs_lr = abs(data_subjs.lr); % absolute learning rates
data_subjs.abs_up = abs(data_subjs.up); % absolute updates

% GET RID OF TRIALS WHERE PE = 0 AND OUTLIER LRs
run_id = data_subjs.id(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
y_data = data_subjs.lr(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
bins = bins(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
binned_data = binned_data(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);

% MEAN LRs for CONDIFF BINS
avg_ydata_bins = NaN(nbins,num_subjs); 
avg_behv_bins = NaN(nbins,num_subjs); 
for b = 1:nbins
    for n = 1:num_subjs
        bins_subj = bins(run_id == id_subjs(n));
        y_data_subj = y_data(run_id == id_subjs(n));
        binned_data_subj = binned_data(run_id == id_subjs(n));
        avg_behv_bins(b,n) = nanmean(binned_data_subj(bins_subj == b));
        avg_ydata_bins(b,n) = nanmean(y_data_subj(bins_subj == b));
    end
end
avg_ydata = nanmean(avg_ydata_bins,2);
avg_binneddata = nanmean(avg_behv_bins,2);
sem_ydata = nanstd(avg_ydata_bins,0,2)./sqrt(num_subjs);

% PLOT
hold on
subplot(1,3,3)
s1 = scatter(1:nbins,avg_ydata,"filled",'MarkerEdgeColor',"none",'MarkerFaceColor',"none");
ls = lsline;
ls.Color = 'k';
hold('on')
errorbar(1:nbins,avg_ydata, sem_ydata, 'k', 'LineWidth',line_width,'LineStyle','none');
hold on
s1 = scatter(1:nbins,avg_ydata,"filled",'MarkerEdgeColor',"k",'MarkerFaceColor',binned_dots);
xlabel("Contrast difference bins" + newline + "(1 bin = 0.01)")
ylabel('Mean learning rate (Empirical data)')

% ADJUST FIGURE PROPERTIES
[rho,pval] = corr(avg_ydata,avg_binneddata, 'rows', 'pairwise');
title(strcat("\itr\rm =",{' '},num2str(round(rho,2)),{' '}) + newline + "\itp\rm < 0.001", ...
    'FontWeight','normal','Interpreter','tex')

% SAVE AS PNG

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'agentSimulations_linearCondiffLR.png', '-dpng', '-r600') 