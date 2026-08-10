% Figure S7: Plot average absolute PEs for high and low state uncertainty.

clc
clearvars

[~,high_PU,mid_PU,low_PU,color_screen,fb_green,darkblue_muted,mix,perc,rew,~,~,binned_dots,~,...
    ~,~,~,~,~] = colors_rgb(); % colors
line_width = 0.5; % line width for plots
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids); % number of subjects

% USER-BASED PATH
currentDir = cd; % current directory
reqPath = 'GBSliderPupil_NatComms'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end
behv_dir = strcat(desiredPath, filesep, 'data', filesep,'GB data two pipelines',filesep, 'behavior', filesep, 'LR analyses');

data_subjs = readtable(strcat(behv_dir,filesep, "preprocessed_lr_pupil_no_zerope.xlsx"));
id_subjs = unique(data_subjs.id);
font_name = 'Arial'; % font name
font_size = 7; % font size
linewidth_axes = 0.5; % line width for axes

% Bar plot comparing the two bins
% -------------------------------

% INITIALISE VARS TO BE PLOTTED
binned_data = abs(data_subjs.con_diff); % absolute contrast difference
nbins = 2; % number of bins
bin_edges = prctile(binned_data, 0:50:100); % calculate percentile edges
bins = discretize(binned_data, bin_edges); % bin contrast differences
data_subjs.lr = data_subjs.up./data_subjs.pe; % learning rates

% GET RID OF TRIALS WHERE PE = 0 AND OUTLIER LRs
run_id = data_subjs.id(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
y_data = abs(data_subjs.pe(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2));
bins = bins(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);

% MEAN LRs for CONDIFF BINS
avg_ydata_bins = NaN(nbins,num_subjs);
avg_behv_bins = NaN(nbins,num_subjs);
for b = 1:nbins
    for n = 1:num_subjs
        bins_subj = bins(run_id == id_subjs(n));
        y_data_subj = y_data(run_id == id_subjs(n));
        avg_ydata_bins(b,n) = mean(y_data_subj(bins_subj == b));
    end
end
avg_ydata = mean(avg_ydata_bins, 2);
sem_ydata = std(avg_ydata_bins, 0, 2)./sqrt(num_subjs);
y = [avg_ydata_bins(1, :).'; avg_ydata_bins(2, :).'];

[h,p] = ttest(avg_ydata_bins(1, :).',avg_ydata_bins(2, :).');
if p < 0.001
    pval_str = "\itp\rm < 0.001";
else
    pval_str = "\itp\rm = " + num2str(round(p,3));
end

% PLOT
fig = figure; 
set(fig, 'Visible', 'on'); 
 
% Size in CM 
width_cm = 6;  
height_cm = 6; 
set(fig, 'Units', 'centimeters'); 
set(fig, 'Position', [10, 10, width_cm, height_cm]); 
set(fig, 'PaperUnits', 'centimeters'); 
set(fig, 'PaperSize', [width_cm, height_cm]); 
set(fig, 'PaperPosition', [0, 0, width_cm, height_cm]); 

hold on
bar_plots(y, avg_ydata, sem_ydata, num_subjs, 2, 1, ...
    {'',''}, [1, 2], {'High','Low'}, '', 'State uncertainty', 'Mean absolute prediction error', font_size, 0.5, font_name, darkblue_muted)
plot([1.1, 1.9], [0.5 0.5], '-', 'LineWidth', 0.3,'Color', 'k');
text(1.5, 0.5, pval_str, 'horizontalalignment', 'center', 'BackgroundColor', 'w', 'FontSize', ...
   5, 'FontWeight', 'normal', 'FontName', font_name);

fig = gcf; 
fig.PaperPositionMode = 'auto'; 
% print(fig, 'PE_condiffbins.png', '-dpng', '-r600')
% exportgraphics(gcf, 'Figures/PDF_Versions/Figure_SM7.pdf', 'ContentType', 'vector')

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none'; 
hgexport(fig, 'Figures/PDF_Versions/Figure_SM7.pdf', style);