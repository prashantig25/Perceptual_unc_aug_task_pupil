clc
clearvars

% INITIALISE VARS
subj_ids = importdata("subj_ids.mat");
num_sess = importdata("num_sess.mat");
timewindow = 'feedback';
col = 300;
num_subs = length(subj_ids);

% -------------------------------------------------------------------------
% ADJUSTABLE BIN NUMBERS
% -------------------------------------------------------------------------
num_pe_bins = 2;      % Number of PE bins
num_cd_bins = 2;      % Number of condiff bins

pe_binedges   = [0, 0.5, 1];        % Define PE bin edges (must have num_pe_bins + 1 values)
cd_binedges   = [0, 0.05, 0.1];                    % Define condiff bin edges (must have num_cd_bins + 1 values)

% -------------------------------------------------------------------------
% Storage: [num_cd_bins x num_pe_bins] structure
% First dimension: condiff bins | Second dimension: PE bins
% -------------------------------------------------------------------------
subj_pupil = struct();
for c = 1:num_cd_bins
    for pe = 1:num_pe_bins
        subj_pupil(c,pe).signal = NaN(num_subs, col);
    end
end

% USER-BASED PATH
currentDir = cd;
reqPath = 'Perceptual_unc_aug_task_pupil';
pathParts = strsplit(currentDir, filesep);
if startsWith(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

save_dir  = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'descriptive');
pupil_dir = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'pupil', filesep, 'pupil signal', filesep, 'fb Mathot 2023 linearInt');
behv_dir  = strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'behavior', filesep, 'raw data');
preds_all = readtable(strcat(desiredPath, filesep, 'data', filesep, 'GB data two pipelines', filesep, 'behavior', filesep, 'LR analyses', filesep, 'preprocessed_lr_pupil.xlsx'));
mkdir(save_dir);

% -------------------------------------------------------------------------
for i = 1:num_subs

    % GET BEHAVIORAL DATA
    behv_data = [];
    for j = 1:num_sess(i)
        filename = strcat(behv_dir, filesep, subj_ids{i}, '_', 'main', num2str(j), '.xlsx');
        if strcmp(subj_ids{i}, '4672')
            filename = strcat(behv_dir, filesep, subj_ids{i}, '_', 'main', num2str(j), '_red.xlsx');
        end
        data_run = readtable(filename, 'VariableNamingRule', 'preserve');
        rt     = table(data_run.("choice.rt"),              'VariableNames', {'rt'});
        slider = table(data_run.("slider_respond.response"),'VariableNames', {'slider'});
        data_run = [data_run(:,1:16), rt, slider];
        behv_data = [behv_data; data_run];
    end

    % REMOVE MISSED TRIALS
    missed_trials = [];
    for b = 1:height(behv_data)
        if isnan(behv_data.rt(b,:))
            missed_trials = [missed_trials; b];
        end
    end
    behv_data(missed_trials,:) = [];
    missedSlider = isnan(behv_data.slider);

    % GET PREDICTOR DATA FOR THIS SUBJECT
    preds = preds_all(preds_all.id == str2num(subj_ids{i}), :);

    % GET PUPIL DATA
    filename     = strcat(pupil_dir, filesep, subj_ids{i}, '.mat');
    pupil        = importdata(filename);
    pupil_signal = pupil(:, 1:col);
    pupil_signal(missedSlider == 1, :) = [];

    % BIN PE AND CONDIFF
    preds.pe_bins = discretize(abs(preds.pe),      pe_binedges);
    preds.cd_bins = discretize(abs(preds.con_diff), cd_binedges);
    pupil_signal(preds.pe == 0,:) = [];
    preds(preds.pe == 0,:) = [];

    % AVERAGE PUPIL SIGNAL PER CONDIFF BIN x PE BIN
    % First loop over condiff bins, then within each condiff bin, loop over PE bins
    for cd = 1:num_cd_bins
        for pe = 1:num_pe_bins
            idx = (preds.pe_bins == pe) & (preds.cd_bins == cd);
            if any(idx)
                subj_pupil(cd,pe).signal(i,:) = nanmean(pupil_signal(idx,:), 1);
            end
        end
    end
end

% =========================================================================
% COMPUTE mean PE and mean condiff per bin, per subject
% =========================================================================

% meanPE_all     [num_subs x num_pe_bins]   — mean of abs(pe) within each PE bin
% meanCondiff_all [num_subs x num_cd_bins]  — mean of abs(con_diff) within each condiff bin

meanPE_all      = NaN(num_subs, num_pe_bins);
meanCondiff_all = NaN(num_subs, num_cd_bins);

for i = 1:num_subs
    preds = preds_all(preds_all.id == str2num(subj_ids{i}), :);
    
    % Remove pe == 0 rows (same exclusion as in the main loop)
    preds(preds.pe == 0, :) = [];
    
    % Re-bin (same edges as main loop)
    preds.pe_bins = discretize(abs(preds.pe),       pe_binedges);
    preds.cd_bins = discretize(abs(preds.con_diff),  cd_binedges);
    
    % Mean PE per bin
    for pe = 1:num_pe_bins
        idx = preds.pe_bins == pe;
        if any(idx)
            meanPE_all(i, pe) = mean(abs(preds.pe(idx)), 'omitnan');
        end
    end
    
    % Mean condiff per bin
    for cd = 1:num_cd_bins
        idx = preds.cd_bins == cd;
        if any(idx)
            meanCondiff_all(i, cd) = mean(abs(preds.con_diff(idx)), 'omitnan');
        end
    end
end

% SAVE
safe_saveall(fullfile(save_dir, 'meanPE_all.mat'),      meanPE_all);
safe_saveall(fullfile(save_dir, 'meanCondiff_all.mat'), meanCondiff_all);

% -------------------------------------------------------------------------
% PERMUTATION TESTS: for each PE bin, compare condiff bin 1 vs bin 2
% -------------------------------------------------------------------------
num_vars  = 1;
two_tailed = 1;
betas     = 0;

% perm_results = struct();
% for pe = 1:num_pe_bins
%     var1 = subj_pupil(1,pe).signal;  % condiff bin 1, PE bin pe
%     var2 = subj_pupil(2,pe).signal;  % condiff bin 2, PE bin pe
%     perm_results(pe).perm = get_permtest(num_vars, num_subs, col, var1, var2, two_tailed, betas);
% end

% PERMUTATION TESTS: For each Contrast bin, compare PE bin 1 vs PE bin 2
perm_results = struct();
for cd = 1:num_cd_bins
    var1 = subj_pupil(cd,1).signal;  % PE bin 1 (Blue)
    var2 = subj_pupil(cd,2).signal;  % PE bin 2 (Orange)
    perm_results(cd).perm = get_permtest(num_vars, num_subs, col, var1, var2, two_tailed, betas);
end
% -------------------------------------------------------------------------
% SAVE
% -------------------------------------------------------------------------
output = struct();
output.num_pe_bins = num_pe_bins;
output.num_cd_bins = num_cd_bins;
output.pe_binedges = pe_binedges;
output.cd_binedges = cd_binedges;
output.subj_pupil  = subj_pupil;
output.perm        = perm_results;
safe_saveall(strcat(save_dir, filesep, 'fb_PE', num2str(num_pe_bins), 'bins_condiff', num2str(num_cd_bins), 'bins_linearInt.mat'), output);
% -------------------------------------------------------------------------
% UPDATED PLOTTING SECTION
% -------------------------------------------------------------------------

% TIME AXIS
time_axis = linspace(0, col-1, col); 

% DYNAMIC LABELS
pe_labels = cell(num_pe_bins, 1);
for i = 1:num_pe_bins
    pe_labels{i} = sprintf('Absolute PE: %.2f-%.2f', pe_binedges(i), pe_binedges(i+1));
end

cd_labels = cell(num_cd_bins, 1);
for i = 1:num_cd_bins
    cd_labels{i} = sprintf('Contrast difference: %.2f-%.2f', cd_binedges(i), cd_binedges(i+1));
end

% COLORS: Generate a gradient for PE bins (e.g., from light to dark or a colormap)
% Using 'lines' or 'parula' for distinct PE curves
pe_colors = lines(num_pe_bins); 
alpha_fill = 0.15;

% CREATE FIGURE
figure('Units','normalized','Position',[0.05 0.3 0.9 0.4]);

% OUTER LOOP: Create one subplot per Condiff bin
for cd = 1:num_cd_bins
    ax = subplot(1, num_cd_bins, cd); 
    hold on;
    
    % INNER LOOP: Plot each PE bin as a different colored curve
    for pe = 1:num_pe_bins
        sig = subj_pupil(cd,pe).signal;               % [num_subs x col]
        
        % Calculate stats
        mn  = nanmean(sig, 1);
        sem = nanstd(sig, 0, 1) ./ sqrt(sum(~isnan(sig(:,1))));
        
        % 1. Plot Shaded SEM
        fill([time_axis, fliplr(time_axis)], ...
             [mn + sem, fliplr(mn - sem)], ...
             pe_colors(pe,:), 'FaceAlpha', alpha_fill, 'EdgeColor', 'none', ...
             'HandleVisibility', 'off'); % Hide from legend
        
        % 2. Plot Mean line
        plot(time_axis, mn, '-', 'Color', pe_colors(pe,:), ...
            'LineWidth', 2, 'DisplayName', pe_labels{pe});
    end
    
    % 3. SIGNIFICANCE BARS (Optional)
    % Note: Your current perm_results compares Condiff 1 vs 2. 
    % If you want to show where Condiff 1 and 2 differ for a specific PE, 
    % you'd need to decide which subplot to put that bar in.
    % Below is a placeholder if you have within-subplot stats:
    % (Example: plotting the 1v2 permutation result in the first subplot only)
% Inside your 'for cd = 1:num_cd_bins' loop:
    mask = perm_results(cd).perm.mask; % Get the mask for THIS subplot
    if any(mask)
        yl = ylim;
        bar_y = yl(1) + 0.05 * diff(yl); % Position bar near the bottom
        sig_x = time_axis(logical(mask));
        plot(sig_x, repmat(bar_y, size(sig_x)), 'k.', 'MarkerSize', 6);
    end
    
    % FORMATTING
    % grid on;
    xlabel('Time since feedback onset');
    ylabel('Pupil signal');
    title(cd_labels{cd}, 'FontWeight', 'normal');
    xlim([time_axis(1) time_axis(end)]);
    
    % Add vertical/horizontal lines for reference
    xline(0, '--k', 'Alpha', 0.5, 'HandleVisibility', 'off');
    yline(0, ':k', 'Alpha', 0.5, 'HandleVisibility', 'off');
    
    % Only add legend to the last subplot to save space
    if cd == num_cd_bins
        legend('Location', 'best', 'FontSize', 8);
    end
    
    set(ax, 'FontSize', 10, 'Box', 'off');
end

% Overall Figure Title
sgtitle('Pupil Response: PE Bins nested within Contrast Difference Bins', ...
    'FontSize', 14, 'FontWeight', 'normal');

%% -------------------------------------------------------------------------
% DIFFERENCE CURVE PLOT: (PE bin 2) minus (PE bin 1), per contrast diff bin
% -------------------------------------------------------------------------

% TIME AXIS (same as above)
time_axis = linspace(0, col-1, col);

% DYNAMIC LABELS
cd_labels = cell(num_cd_bins, 1);
for i = 1:num_cd_bins
    cd_labels{i} = sprintf('Contrast difference: %.2f-%.2f', cd_binedges(i), cd_binedges(i+1));
end

% COLORS FOR THE DIFFERENCE CURVES (one per contrast diff bin)
cd_colors = lines(num_cd_bins);
alpha_fill = 0.15;

% FIGURE
figure('Units', 'normalized', 'Position', [0.15 0.3 0.55 0.4]);
hold on;

for cd = 1:num_cd_bins

    % Subject-wise difference: high PE minus low PE
    diff_signal = subj_pupil(cd, 2).signal - subj_pupil(cd, 1).signal;
    % [num_subs x col] — NaN rows handled by nanmean/nanstd below

    mn  = nanmean(diff_signal, 1);
    sem = nanstd(diff_signal, 0, 1) ./ sqrt(sum(~isnan(diff_signal(:,1))));

    % Shaded SEM
    fill([time_axis, fliplr(time_axis)], ...
         [mn + sem, fliplr(mn - sem)], ...
         cd_colors(cd,:), 'FaceAlpha', alpha_fill, 'EdgeColor', 'none', ...
         'HandleVisibility', 'off');

    % Mean difference line
    plot(time_axis, mn, '-', 'Color', cd_colors(cd,:), ...
        'LineWidth', 2, 'DisplayName', cd_labels{cd});

    
end
% Subject-wise PE difference (high PE - low PE) for each CD bin
diff_cd1 = subj_pupil(1, 2).signal - subj_pupil(1, 1).signal;  % [num_subs x col]
diff_cd2 = subj_pupil(2, 2).signal - subj_pupil(2, 1).signal;  % [num_subs x col]

% Permutation test: is the PE effect larger in CD bin 2 than CD bin 1?
between_perm = get_permtest(1, num_subs, col, diff_cd2, diff_cd1, 1, 0);
mask = logical(between_perm.mask);

diff_cd1_win = diff_cd1(:,101:200);
diff_cd2_win = diff_cd2(:,101:200);
% 
% % Permutation test: is the PE effect larger in CD bin 2 than CD bin 1?
% between_perm_win = get_permtest(1, num_subs, 100, diff_cd2_win, diff_cd1_win, 1, 0);
% mask_win = logical(between_perm_win.mask);

% Add significance bar to the existing plot
if any(mask)
    yl = ylim;
    bar_y = yl(2) - 0.05 * diff(yl);  % just below the top of the plot
    plot(time_axis(mask), repmat(bar_y, 1, sum(mask)), 'k.', ...
        'MarkerSize', 5, 'HandleVisibility', 'off');
end

% Reference line at zero
yline(0, ':k', 'Alpha', 0.4, 'HandleVisibility', 'off');
xline(0, '--k', 'Alpha', 0.4, 'HandleVisibility', 'off');

% Formatting
xlabel('Time since feedback onset');
ylabel('Pupil signal difference (high PE - low PE)');
legend('Location', 'best', 'FontSize', 9);
xlim([time_axis(1) time_axis(end)]);
title('PE effect (bin 2 - bin 1) per contrast difference bin', 'FontWeight', 'normal');
set(gca, 'FontSize', 10, 'Box', 'off'); 

%% averaged and max

diff_cd2_mean = mean(diff_cd2,2);
diff_cd1_mean = mean(diff_cd1,2);

[h,p_mean] = ttest(diff_cd2_mean,diff_cd1_mean);

diff_cd2_max = max(diff_cd2,[],2);
diff_cd1_max = max(diff_cd1,[],2);

[h,p_max] = ttest(diff_cd2_max,diff_cd1_max);

% Data Preparation (Assuming you have these from your snippet)
% data1 = diff_cd1_mean; data2 = diff_cd2_mean;
% data1_max = diff_cd1_max; data2_max = diff_cd2_max;

figure('Color', 'w', 'Position', [100 100 1000 500]);

% --- Plot 1: Mean Differences ---
subplot(1,2,1); hold on;
plot_bar_with_dots(diff_cd1_mean, diff_cd2_mean, 'Mean Pupil Difference', p_mean);

% --- Plot 2: Max Differences ---
subplot(1,2,2); hold on;
plot_bar_with_dots(diff_cd1_max, diff_cd2_max, 'Max Pupil Difference', p_max);

%% averaged and max
 
diff_cd2_mean = mean(diff_cd2_win,2);
diff_cd1_mean = mean(diff_cd1_win,2);

[h,p_mean] = ttest(diff_cd2_mean,diff_cd1_mean);

diff_cd2_max = max(diff_cd2_win,[],2);
diff_cd1_max = max(diff_cd1_win,[],2);

[h,p_max] = ttest(diff_cd2_max,diff_cd1_max);

% Data Preparation (Assuming you have these from your snippet)
% data1 = diff_cd1_mean; data2 = diff_cd2_mean;
% data1_max = diff_cd1_max; data2_max = diff_cd2_max;

figure('Color', 'w', 'Position', [100 100 1000 500]);

% --- Plot 1: Mean Differences ---
subplot(1,2,1); hold on;
plot_bar_with_dots(diff_cd1_mean, diff_cd2_mean, 'Mean Pupil Difference (time window = 1 to 2 ms)', p_mean);

% --- Plot 2: Max Differences ---
subplot(1,2,2); hold on;
plot_bar_with_dots(diff_cd1_max, diff_cd2_max, 'Max Pupil Difference (time window = 1 to 2 ms)', p_max);

% Helper Function for the plotting
function plot_bar_with_dots(d1, d2, title_str, p_val)
    data = [d1, d2];
    means = mean(data);
    sems = std(data) ./ sqrt(length(data));
    
    % Plot Bars
    b = bar(means, 'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    b.CData(1,:) = [0.2 0.6 0.8]; % Blueish
    b.CData(2,:) = [0.9 0.5 0.2]; % Orangish
    
    % Plot SEM Error Bars
    errorbar(1:2, means, sems, 'k', 'linestyle', 'none', 'LineWidth', 1.5);
    
    % Plot Individual Subject Dots (with jitter)
    rng(1); % for consistent jitter
    jitter = (rand(size(data)) - 0.5) * 0.1;
    scatter(ones(size(d1)) + jitter(:,1), d1, 30, 'k', 'filled', 'MarkerFaceAlpha', 0.3);
    scatter(2*ones(size(d2)) + jitter(:,2), d2, 30, 'k', 'filled', 'MarkerFaceAlpha', 0.3);
    
    % Connect paired subjects (Optional but recommended for paired t-tests)
    % for i = 1:length(d1)
    %     plot([1+jitter(i,1), 2+jitter(i,2)], [d1(i), d2(i)], 'Color', [0.5 0.5 0.5 0.2]);
    % end
    
    % Formatting
    ylabel('Pupil Signal Difference (PE High - Low)');
    xlabel('Contrast difference')
    set(gca, 'XTick', 1:2, 'XTickLabel', {'0.00-0.05', '0.05-0.10'}, 'Box', 'off');
    title(title_str);
    
    % Add P-value text
    yl = ylim;
    text(1.5, yl(2)*0.9, sprintf('p = %.4f', p_val), 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
end