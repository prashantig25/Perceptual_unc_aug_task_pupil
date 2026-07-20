% Figure S3: Illustrate linearity assumption of key variables of interest

clc
clearvars

% Create figure with specified dimensions
figure(Position=[200,200,400,125])
binnedDotsColor = [159, 210, 235]./255; % bluish green color for binned analysis data

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

%% SUBPLOT A - Human Data Belief State Analysis
subplot(1,3,1)

% Load and process human data
sims_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'behavior', filesep, 'LR analyses');
data = importdata(fullfile(sims_dir, "preprocessed_agentpupil0.06.mat"));
uniqueID = unique(data.ID);
numSubjs = length(uniqueID);
sigma = 0.06;
dataContrast = data;
dataContrast = dataContrast(dataContrast.choice_cond ~= 3,:);
dataContrast.condiff_relative = dataContrast.contrast_diff;

% Bin data
nbins = 10;

% Compute bins
dataContrast.bins = createCondiffBins(dataContrast.contrast_diff);

% Calculate belief states
% -----------------------

% Initialize variables
BS_diff_binned = NaN(numSubjs,nbins);
BS0_binned = NaN(numSubjs,nbins);

% Cycle over subjects
for n = 1:numSubjs

    % Select subject data
    dataSubj = dataContrast(dataContrast.ID == uniqueID(n),:);

    % Initialize BS-difference (for plotting) and BS0 (for validation) variables
    belief_state_diff = NaN(height(dataSubj),1);
    belief_state = NaN(height(dataSubj),1);

    % Cycle over subject trials
    for h = 1:height(dataSubj)

        % Compute CDF compontents of belief state
        obj.u = normcdf(0, dataSubj.condiff_relative(h), sigma);
        obj.v = normcdf(-0.1, dataSubj.condiff_relative(h), sigma);
        obj.w = normcdf(0.1, dataSubj.condiff_relative(h), sigma);

        % Compute belief states
        pi_0 = (obj.u - obj.v) / (obj.w - obj.v);
        pi_1 = (obj.w - obj.u) / (obj.w - obj.v);

        % Get belief-state difference
        belief_state_diff(h,1) = abs(pi_1 - pi_0);

        % Get higher belief state just for validation
        belief_state(h, 1) = max(pi_0, pi_1);
    end

    % Cycle over bins
    for b = 1:nbins

        % Actual variable of interest
        BS_diff_binned(n,b) = mean(belief_state_diff(dataSubj.bins == b),1);

        % Check actual BS for validation (not the difference)
        BS0_binned(n,b) = mean(belief_state(dataSubj.bins == b),1);

    end
end

% Plot group mean and error bars
hold on
scatter(1:nbins, mean(BS_diff_binned), 50, binnedDotsColor, 'filled','MarkerEdgeColor','k');
lsline

% Calculate correlation
x_data_a = 1:nbins;
y_data_a = mean(BS_diff_binned);
[rho_a, pval_a] = corr(x_data_a', y_data_a', 'rows', 'pairwise');

xlabel('Contrast-difference bins');
ylabel('Belief-state difference (Agent)');
if pval_a < 0.001
    pval_str_a = "\itp\rm < 0.001";
else
    pval_str_a = "\itp\rm = " + num2str(round(pval_a,3));
end
title(strcat("\itr\rm =",{' '},num2str(round(rho_a,2)),{' '}) + newline + pval_str_a, ...
    'FontWeight','normal','Interpreter','tex');

% Add subplot label A
text(-0.03, 1.11, 'a', 'Units', 'normalized', 'FontSize', 12, 'FontWeight','normal');
box off
hold off
set(gca,'FontName','Arial','FontSize',7,'LineWidth',0.5)

%% SUBPLOT B - Agent Data Learning Analysis
subplot(1,3,2)

% Load and process agent data
agent_data = importdata("preprocessed_agentpupil0.06.mat");

numSims = 300;
simID = 1:300;

% Compute bins
bins = createCondiffBins(agent_data.contrast_diff);

% Compute mean and SEM learning rates
[avg_ydataLR, sem_ydataLR] = computeMeanLR(agent_data, bins, nbins, numSims, simID);

% Plot average LRs
plotMeanLR(avg_ydataLR, sem_ydataLR, nbins, binnedDotsColor, 'Mean LR (Agent)')

% Add subplot label B
text(-0.03, 1.11, 'b', 'Units', 'normalized', 'FontSize', 12, 'FontWeight','normal');

%% SUBPLOT C - Human Data Learning Rate Analysis
subplot(1,3,3)

% Load and process human learning rate data
regression_path = "data/GB data two pipelines/behavior/LR analyses";
data_subjs = readtable(fullfile(desiredPath,regression_path,"preprocessed_lr_pupil_no_zerope.xlsx"));

% Compute bins
bins = createCondiffBins(data_subjs.con_diff);

% Get unique subjects
id_subjs = unique(data_subjs.id);
num_subjs = length(id_subjs);

% Compute mean and SEM learning rates
data_subjs = renamevars(data_subjs, "id", "ID"); % rename ID to use same function
[avg_ydataLR, sem_ydataLR] = computeMeanLR(data_subjs, bins, nbins, num_subjs, id_subjs);

% Plot average LRs
plotMeanLR(avg_ydataLR, sem_ydataLR, nbins, binnedDotsColor, 'Mean LR (Participant)')

% Add subplot label C
text(-0.03, 1.11, 'c', 'Units', 'normalized', 'FontSize', 12, 'FontWeight','normal');

% Make sure subplots are properly spaced
set(gcf, 'PaperPositionMode', 'auto');

%% SAVE AS PNG

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'LRcondiff_BS.png', '-dpng', '-r600')

