clc
clearvars

% Create figure with specified dimensions
figure('Position', [100, 100, 550, 175]);
binned_dots = [159, 210, 235]./255; % bluish green color for binned analysis data
%% SUBPLOT A - Human Data Belief State Analysis
subplot(1,3,1)

% Load and process human data
data = importdata("preprocessed_agent.mat");
uniqueID = unique(data.ID);
numSubjs = length(uniqueID);
sigma = 0.06; %importdata("sigmaNoReward_simpleRL.mat");
dataContrast = data;
dataContrast = dataContrast(dataContrast.choice_cond ~= 3,:);
dataContrast.condiff_relative = dataContrast.contrast_diff;
% Bin data
nbins = 10;
binEdges = prctile(abs(dataContrast.contrast_diff), linspace(0, 100, nbins + 1));
dataContrast.bins = discretize(abs(dataContrast.contrast_diff), binEdges);

% Calculate belief states
BS_binned = NaN(numSubjs,nbins);
for n = 1:numSubjs
    dataSubj = dataContrast(dataContrast.ID == uniqueID(n),:);
    belief_state = NaN(height(dataSubj),1);
    
    for h = 1:height(dataSubj)
        if dataSubj.state(h) == 1
            belief_state(h,1) = normcdf(dataSubj.condiff_relative(h), 0, sigma);
        else
            belief_state(h,1) = 1-normcdf(dataSubj.condiff_relative(h), 0, sigma);
        end
        belief_state(h,1) = belief_state(h,1)-(1-belief_state(h,1));
        % belief_state(h,1) = belief_state(h,1)-0.5;
    end
    
    for b = 1:nbins 
        BS_binned(n,b) = nanmean(belief_state(dataSubj.bins == b),1);
    end
end

% Plot individual subjects
% for n = 1:numSubjs
%     plot(1:nbins, BS_binned(n,:), 'Color', [0.5,0.5,0.5], 'LineWidth', 0.25);
%     hold on
% end

% Plot group mean and error bars
scatter(1:nbins, nanmean(BS_binned), 50,"white");
% hold on
% plot(1:nbins, nanmean(BS_binned), 'Color', 'k');
hold on
ls = lsline;
% errorbar(1:nbins, nanmean(BS_binned), nanstd(BS_binned)./sqrt(numSubjs), 'Color', 'k');
hold on
scatter(1:nbins, nanmean(BS_binned), 50, binned_dots, 'filled','MarkerEdgeColor','k');
% lsline

% Calculate correlation
x_data_a = 1:nbins;
y_data_a = nanmean(BS_binned);
[rho_a, pval_a] = corr(x_data_a', y_data_a', 'rows', 'pairwise');
xlim([2,10])
xlabel('Contrast difference bins');
ylabel('Belief state difference (Agent)');
title(strcat("\itr\rm =",{' '},num2str(round(rho_a,2)),{' '}) + newline + "\itp\rm < 0.001", ...
 'FontWeight','normal','Interpreter','tex');
% Add subplot label A
text(-0.03, 1.07, 'a', 'Units', 'normalized', 'FontSize', 12, 'FontWeight','normal');
box off
hold off

%% SUBPLOT B - Agent Data Learning Analysis
subplot(1,3,2)

% Load and process agent data
agentAll = importdata("preprocessed_agent.mat");
agent_data = agentAll;

% Initialize variables
binned_data = abs(agent_data.contrast_diff);
nbins = 10;
bin_edges = prctile(binned_data, 0:10:100);
bins = discretize(binned_data, bin_edges);
agent_data.bins = bins;
agent_data.lr = agent_data.up./agent_data.pe;
agent_data.abs_lr = abs(agent_data.lr);

numSims = 99;
simID = 1:numSims;

% Filter data
run_id = agent_data.ID(agent_data.pe ~= 0 & abs(agent_data.lr)<=2);
y_data_absLR = abs(agent_data.lr(agent_data.pe ~= 0 & abs(agent_data.lr)<=2));
bins = bins(agent_data.pe ~= 0 & abs(agent_data.lr)<=2);
binned_data = binned_data(agent_data.pe ~= 0 & abs(agent_data.lr)<=2);

% Calculate means per bin per simulation
avg_ydataAbsLR_bins = NaN(nbins,numSims);
for b = 1:nbins
    for n = 1:numSims
        bins_subj = bins(run_id == simID(n));
        y_data_absLR_subj = y_data_absLR(run_id == simID(n));
        avg_ydataAbsLR_bins(b,n) = nanmean(y_data_absLR_subj(bins_subj == b));
    end
end

avg_ydataAbsLR = nanmean(avg_ydataAbsLR_bins,2);
sem_ydataAbsLR = nanstd(avg_ydataAbsLR_bins,0,2)./sqrt(numSims);

% Plot
scatter(1:nbins, avg_ydataAbsLR, 50, 'white', 'filled', 'MarkerEdgeColor', 'w','MarkerFaceAlpha',0.5);
hold on
errorbar(1:nbins, avg_ydataAbsLR, sem_ydataAbsLR, 'k', 'LineWidth', 1, 'LineStyle', 'none');
hold on
scatter(1:nbins, avg_ydataAbsLR, 50, binned_dots, 'filled', 'MarkerEdgeColor', 'k');
lsline
xlim([2,10])

% Calculate correlation
x_data_b = 2:nbins;
y_data_b = avg_ydataAbsLR(2:end)';
[rho_b, pval_b] = corrcoef(x_data_b', y_data_b');

xlabel('Contrast-difference bins');
ylabel('Mean learning rate (Agent)');
title(strcat("\itr\rm =",{' '},num2str(round(rho_b(1,2),2)),{' '}) + newline + "\itp\rm < 0.001", ...
 'FontWeight','normal','Interpreter','tex');
% Add subplot label B
text(-0.03, 1.07, 'b', 'Units', 'normalized', 'FontSize', 12, 'FontWeight','normal');

hold off

%% SUBPLOT C - Human Data Learning Rate Analysis
subplot(1,3,3)

% Load and process human learning rate data
regression_path = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 8/pupil_manuscript/Perceptual_unc_aug_task_pupil-main/data/GB data peak corrected/behavior/LR analyses";
data_subjs = readtable(fullfile(regression_path,"preprocessed_lr_pupil_no_zerope.xlsx"));

% Initialize variables
binned_data = abs(data_subjs.con_diff);
nbins = 10;
bin_edges = prctile(binned_data, 0:10:100);
bins = discretize(binned_data, bin_edges);
data_subjs.lr = data_subjs.up./data_subjs.pe;

% Get unique subjects
id_subjs = unique(data_subjs.id);
num_subjs = length(id_subjs);

% Filter data
run_id = data_subjs.id(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
y_data = data_subjs.lr(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
bins = bins(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
binned_data = binned_data(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);

% Calculate means per bin per subject
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

% Plot
scatter(1:nbins, avg_ydata,"filled",'MarkerEdgeColor',"none",'MarkerFaceColor',"none");
hold on
ls = lsline;
hold on
errorbar(1:nbins, avg_ydata, sem_ydata, 'k', 'LineWidth', 1, 'LineStyle', 'none');
hold on
scatter(1:nbins, avg_ydata, 50, binned_dots, 'filled', 'MarkerEdgeColor', 'k');

% ls.Color = 'k';

% Calculate correlation
[rho_c, pval_c] = corrcoef(avg_ydata.', avg_binneddata.');

xlabel('Contrast difference bins');
ylabel('Mean learning rate (Participants)');
title(strcat("\itr\rm =",{' '},num2str(round(rho_c(1,2),2)),{' '}) + newline + "\itp\rm < 0.001", ...
 'FontWeight','normal','Interpreter','tex');
% Add subplot label C
text(-0.03, 1.07, 'c', 'Units', 'normalized', 'FontSize', 14, 'FontWeight','normal');

hold off

% Adjust overall figure properties
% sgtitle('Learning Analysis Across Contrast Difficulty');

% Make sure subplots are properly spaced
set(gcf, 'PaperPositionMode', 'auto');

%% SAVE AS PNG

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'LRcondiff_BS.png', '-dpng', '-r600')