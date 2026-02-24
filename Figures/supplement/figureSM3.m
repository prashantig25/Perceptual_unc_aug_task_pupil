% figureSM3 plots average absolute PEs for high and low state uncertainty.

clc
clearvars

[~,high_PU,mid_PU,low_PU,color_screen,fb_green,darkblue_muted,mix,perc,rew,~,~,binned_dots,~,...
    ~,~,~,~,~] = colors_rgb(); % colors
line_width = 0.5; % line width for plots 
num_subjs = 47;
data_subjs = readtable("preprocessed_lr_pupil.xlsx");
id_subjs = unique(data_subjs.id);
font_name = 'Arial'; % font name
font_size = 7; % font size
linewidth_axes = 0.5; % line width for axes

% bar plot comparing the two bins 

% INITIALISE VARS TO BE PLOTTED
binned_data = abs(data_subjs.con_diff); % absolute contrast difference
nbins = 2; % number of bins
bin_edges = prctile(binned_data, 0:50:100); % calculate percentile edges
bins = discretize(binned_data, bin_edges); % bin contrast differences 
data_subjs.lr = data_subjs.up./data_subjs.pe; % learning rates
data_subjs.abs_lr = abs(data_subjs.lr); % absolute learning rates

% GET RID OF TRIALS WHERE PE = 0 AND OUTLIER LRs
run_id = data_subjs.id(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
y_data = abs(data_subjs.pe(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2));
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
y = [avg_ydata_bins(1,:).';avg_ydata_bins(2,:).'];
[h,p] = ttest2(avg_ydata_bins(1,:).',avg_ydata_bins(2,:).');

% PLOT
figure("Position",[100,100,200,200])
hold on
bar_plots_pval(y,avg_ydata,sem_ydata,num_subjs,2,1,{'',''},[1,2],{'High','Low'},'', ...
    'State uncertainty','Mean absolute prediction error',0,1,10,1,7,0.5,'Arial',0,darkblue_muted,'p = 0.3',0.55)
hold on 
plot([1.1, 1.9], ...
        [0.5 0.5], '-','LineWidth', 0.3,'Color','k');
text(1.5, 0.5, "\itp\rm = 0.3", ...
    'horizontalalignment', 'center','BackgroundColor','w','FontSize', ...
    5,'FontWeight','normal','FontName',font_name);
set(gca,'color','none','FontName',font_name,'FontSize',font_size,'YLim',[0,0.5], ...
    'LineWidth',linewidth_axes,'YTick',[0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1], ...
    'YTickLabels',{'0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'})

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'PE_condiffbins.png', '-dpng', '-r600') 