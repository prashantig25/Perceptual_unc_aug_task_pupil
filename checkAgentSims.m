clc
clearvars
data = readtable("data_agentpupil0.06.txt");
data.slider = data.mu;
data.condition = data.choice_cond;
data.obtained_reward = data.reward;
data.choice = data.action;
data.con_diff = data.contrast_diff;
% data(data.choice_cond ~= 2,:) = [];
data.congruence = ones(height(data),1);
data.contrast = zeros(height(data),1);

safe_saveall("data_agent0.06ForPreprocess.txt",data);

data = importdata("preprocessed_agent.mat");
data.con_diff = data.contrast_diff;

binEdges = linspace(0, 0.1, 11);
binEdges(end) = 0.1001;

% Create bins
bins = discretize(abs(data.con_diff), binEdges);
data.bins = bins;

% Track error proportion across all 10 bins
numBins = 10;
errorProportion = zeros(numBins, 1);

for b = 1:numBins
    data_bin = data(data.bins == b, :);
    errors = zeros(height(data_bin), 1);
    for h = 1:height(data_bin)
        if data_bin.state(h) == 0
            if data_bin.state_0(h) > data_bin.state_1(h)
                errors(h) = 1;
            end
        end
    end
    errorProportion(b) = sum(errors) / height(data_bin); % proportion
end

% Bin labels (midpoints)
binMidpoints = (binEdges(1:end-1) + binEdges(2:end)) / 2;

% Scatter plot
figure;
scatter(1:numBins, errorProportion, 80, 'filled', 'MarkerFaceColor', [0.2 0.4 0.8]);
xticks(1:numBins);
xticklabels(arrayfun(@(x) sprintf('%.3f', x), binMidpoints, 'UniformOutput', false));
xtickangle(45);
xlabel('Contrast Difference Bin (midpoint)');
ylabel('Proportion of Errors');
title('Error Proportion Across Contrast Difference Bins');
% ylim([0 1]);
grid on;


%%

data = importdata("preprocessed_agentpupil0.06.mat");
data.con_diff = data.contrast_diff;
binEdges = linspace(0, 0.1, 11);
binEdges(end) = 0.1001;

% Create bins
bins = discretize(abs(data.con_diff), binEdges);
data.bins = bins;

% Pre-allocate
numBins = 10;
errorProportion    = zeros(numBins, 1);
errorProportion_SE = zeros(numBins, 1);
mean_up_pe_err     = zeros(numBins, 1);
sem_up_pe_err      = zeros(numBins, 1);
mean_up_pe_nonerr  = zeros(numBins, 1);
sem_up_pe_nonerr   = zeros(numBins, 1);

for b = 1:numBins
    data_bin = data(data.bins == b, :);
    n = height(data_bin);

    % Identify error trials
    errors = zeros(n, 1);
    for h = 1:n
        if data_bin.state(h) == 0
            if data_bin.state_0(h) > data_bin.state_1(h)
                errors(h) = 1;
            end
        else
            if data_bin.state_0(h) < data_bin.state_1(h)
                errors(h) = 1;
            end
        end
    end

    % Error proportion + SEM (binomial SEM = sqrt(p*(1-p)/n))
    p = sum(errors) / n;
    errorProportion(b)    = p;
    errorProportion_SE(b) = sqrt(p * (1 - p) / n);

    % UP/PE ratio for error trials
    error_trials = data_bin(logical(errors), :);
    if height(error_trials) > 0
        ratios_err = error_trials.up ./ error_trials.pe;
        ratios_err = ratios_err(~isnan(ratios_err) & ~isinf(ratios_err));
        mean_up_pe_err(b) = mean(ratios_err);
        sem_up_pe_err(b)  = std(ratios_err) / sqrt(length(ratios_err));
    else
        mean_up_pe_err(b) = NaN;
        sem_up_pe_err(b)  = NaN;
    end

    % UP/PE ratio for non-error trials
    nonerror_trials = data_bin(~logical(errors), :);
    if height(nonerror_trials) > 0
        ratios_nonerr = nonerror_trials.up ./ nonerror_trials.pe;
        ratios_nonerr = ratios_nonerr(~isnan(ratios_nonerr) & ~isinf(ratios_nonerr));
        mean_up_pe_nonerr(b) = mean(ratios_nonerr);
        sem_up_pe_nonerr(b)  = std(ratios_nonerr) / sqrt(length(ratios_nonerr));
    else
        mean_up_pe_nonerr(b) = NaN;
        sem_up_pe_nonerr(b)  = NaN;
    end
end

% Bin labels (midpoints)
binMidpoints = (binEdges(1:end-1) + binEdges(2:end)) / 2;
xLabels = arrayfun(@(x) sprintf('%.3f', x), binMidpoints, 'UniformOutput', false);
x = 1:numBins;

% Colours
col_blue   = [0.20 0.40 0.80];
col_red    = [0.85 0.33 0.10];
col_green  = [0.18 0.63 0.34];

figure('Position', [100 100 900 750]);

% --- Subplot 1: Error proportion ---
subplot(3,1,1);
errorbar(x, errorProportion, errorProportion_SE, 'o', ...
    'Color', col_blue, 'MarkerFaceColor', col_blue, ...
    'MarkerSize', 7, 'LineWidth', 1.5, 'CapSize', 6);
xticks(x); xticklabels(xLabels); xtickangle(45);
xlabel('Contrast Difference Bin (midpoint)');
ylabel('Proportion of correct state inferred trials');
title('Proportion Across Bins');
grid on;

% --- Subplot 2: Mean UP/PE — error trials ---
subplot(3,1,2);
errorbar(x, mean_up_pe_err, sem_up_pe_err, 'o', ...
    'Color', col_red, 'MarkerFaceColor', col_red, ...
    'MarkerSize', 7, 'LineWidth', 1.5, 'CapSize', 6);
xticks(x); xticklabels(xLabels); xtickangle(45);
xlabel('Contrast Difference Bin (midpoint)');
ylabel('Mean UP/PE');
title('Mean UP/PE on correct state inferred trials');
grid on;

% --- Subplot 3: Mean UP/PE — non-error trials ---
subplot(3,1,3);
errorbar(x, mean_up_pe_nonerr, sem_up_pe_nonerr, 'o', ...
    'Color', col_green, 'MarkerFaceColor', col_green, ...
    'MarkerSize', 7, 'LineWidth', 1.5, 'CapSize', 6);
xticks(x); xticklabels(xLabels); xtickangle(45);
xlabel('Contrast Difference Bin (midpoint)');
ylabel('Mean UP/PE');
title('Mean UP/PE — incorrect state inferred trials');
grid on;

%%


clc
clearvars
data = readtable("data_agentpupil0.06.txt");

%% Parameters
num_trials = 25;
num_sims   = 300;
num_blocks = 8;

%% Create ID column (every 100 rows = 1 sim, repeated for 2 conditions)
ids = repelem((1:num_sims)', 100);   % 300 x 100 = 30000 rows per condition
data.ID = [ids; ids];                % repeat for both conditions

%% Assign block within each ID: every 25 trials = new block, resets per ID
data.block = zeros(height(data), 1);
unique_ids = unique(data.ID);

for s = 1:numel(unique_ids)
    mask    = data.ID == unique_ids(s);
    sub_idx = find(mask);
    % Within this ID, assign block 1-4 in chunks of 25
    n = numel(sub_idx);
    data.block(sub_idx) = ceil((1:n)' / num_trials);
end

% Verify
fprintf('Unique blocks: %s\n', num2str(unique(data.block)'));
fprintf('Unique IDs: %d\n',    numel(unique(data.ID)));

%% Parameters
conditions  = [1, 2];
colors      = {[0.18 0.49 0.80], [0.85 0.33 0.10]};
cond_labels = {'Both', 'Perceptual'};

% Remap trial within each block to 1:25
data.trial_in_block = mod(data.trials - 1, num_trials) + 1;

%% Pre-allocate: mu_store{cond}(sim, trial, block)
mu_store = cell(1, 2);
for c = 1:2
    mu_store{c} = NaN(num_sims, num_trials, num_blocks);
end

%% Extract mu
% --- check available column names first ---
disp(data.Properties.VariableNames);

mu_col = 'mu'; % <-- replace with actual column name if different

for c = 1:2
    cond_idx = conditions(c);
    for b = 1:num_blocks
        for s = 1:num_sims
            mask = data.choice_cond    == cond_idx & ...
                   data.block          == b         & ...
                   data.ID            == s;
            sub  = data(mask, :);
            if height(sub) == num_trials
                sub = sortrows(sub, 'trial_in_block');
                mu_store{c}(s, :, b) = sub.(mu_col)';
            else
                % Optional: warn about missing data
                % fprintf('Missing: cond=%d, block=%d, sim=%d (%d trials)\n', cond_idx, b, s, height(sub));
            end
        end
    end
end

%% Average across blocks → (num_sims x num_trials), then mean & SEM across sims
figure('Color', 'w', 'Position', [100 100 720 450]);
hold on;

patch_handles = gobjects(1, 2);
line_handles  = gobjects(1, 2);

for c = 1:2
    mu_avg_blocks = mean(mu_store{c}, 3, 'omitnan');         % 300 x 25
    mu_mean       = mean(mu_avg_blocks, 1, 'omitnan');        % 1 x 25
    mu_sem        = std(mu_avg_blocks, 0, 1, 'omitnan') ./ sqrt(num_sims);

    trials = 1:num_trials;
    col    = colors{c};

    % SEM shaded region
    patch_handles(c) = fill( ...
        [trials, fliplr(trials)], ...
        [mu_mean + mu_sem, fliplr(mu_mean - mu_sem)], ...
        col, 'FaceAlpha', 0.18, 'EdgeColor', 'none');

    % Mean line
    line_handles(c) = plot(trials, mu_mean, '-o', ...
        'Color',           col, ...
        'LineWidth',       2, ...
        'MarkerFaceColor', col, ...
        'MarkerSize',      4, ...
        'DisplayName',     cond_labels{c});
end

xlabel('Trial', 'FontSize', 13);
ylabel('\mu', 'FontSize', 14);
title('Mean \mu across blocks (\pm SEM across 300 simulations)', 'FontSize', 13);
legend(line_handles, cond_labels, 'Location', 'best', 'FontSize', 11);
xticks(1:num_trials);
xlim([1 num_trials]);
% grid on;
% box off;
hold off;