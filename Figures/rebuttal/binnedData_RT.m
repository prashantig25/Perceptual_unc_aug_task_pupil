clc
clearvars

%% SETUP
currentDir = cd;
reqPath = 'Perceptual_unc_aug_task_pupil-main';
pathParts = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

preds_file = fullfile(desiredPath, 'data', 'GB data two pipelines', 'behavior', 'LR analyses', 'preprocessed_lr_pupil_missingSlider.xlsx');
preds_all = readtable(preds_file);

[~,~,~,~,~,~,~,~,~,~,~,~,binned_dots,~,~,~,~,~,~] = colors_rgb();
font_name = 'Arial';
font_size = 7;
line_width = 0.5;

%% EXTRACT VARIABLES
rt_all      = log(preds_all.rt);
pe_all      = preds_all.pe;
con_diff_all = preds_all.con_diff;
id_all      = preds_all.id;
subj_ids    = unique(id_all);
nSubj       = length(subj_ids);

%% SECTION 1: BINNED CON_DIFF vs MEAN RT
nBins = 5;
subj_meanRT_con = NaN(nSubj, nBins);
binCenters_con  = NaN(1, nBins);

for s = 1:nSubj
    sid = subj_ids(s);
    idx = id_all == sid;
    con = con_diff_all(idx);
    rt  = rt_all(idx);
    valid = ~(isnan(con) | isnan(rt));

    if sum(valid) >= 1
        con_v = con(valid);
        rt_v  = rt(valid);
        edges_con = linspace(min(con_v), max(con_v), nBins + 1);

        if all(edges_con == edges_con(1))
            binIdx = ones(size(con_v)) * ceil(nBins/2);
        else
            binIdx = discretize(con_v, edges_con);
            isNan  = isnan(binIdx) & (con_v == max(con_v));
            binIdx(isNan) = nBins;
        end

        for b = 1:nBins
            if any(binIdx == b)
                subj_meanRT_con(s, b) = mean(rt_v(binIdx == b), 'omitnan');
            end
        end

        if ~all(edges_con == edges_con(1))
            binCenters_con = (edges_con(1:end-1) + edges_con(2:end)) / 2;
        else
            binCenters_con = linspace(min(con_v)-0.5, max(con_v)+0.5, nBins);
        end
    end
end

group_meanRT_con = mean(subj_meanRT_con, 1, 'omitnan');
group_semRT_con  = std(subj_meanRT_con, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(subj_meanRT_con), 1));
validBins_con    = ~isnan(group_meanRT_con) & ~isnan(binCenters_con);

if sum(validBins_con) >= 2
    [r_con_bins, p_con_bins] = corr(binCenters_con(validBins_con)', group_meanRT_con(validBins_con)', 'Rows', 'complete');
else
    r_con_bins = NaN; p_con_bins = NaN;
end

%% SECTION 2: BINNED PE vs MEAN RT
pe_edges    = [0, 0.2, 0.4, 0.6, 0.8, 1];
nBins_PE    = length(pe_edges) - 1;
binCenters_pe = (pe_edges(1:end-1) + pe_edges(2:end)) / 2;
subj_meanRT_pe = NaN(nSubj, nBins_PE);

for s = 1:nSubj
    sid = subj_ids(s);
    idx = id_all == sid;
    pe  = pe_all(idx);
    rt  = rt_all(idx);
    valid = ~(isnan(pe) | isnan(rt));
    pe = pe(valid); rt = rt(valid);
    if isempty(pe); continue; end

    binIdx = discretize(pe, pe_edges);
    for b = 1:nBins_PE
        subj_meanRT_pe(s, b) = mean(rt(binIdx == b), 'omitnan');
    end
end

group_meanRT_pe = mean(subj_meanRT_pe, 1, 'omitnan');
group_semRT_pe  = std(subj_meanRT_pe, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(subj_meanRT_pe), 1));
validBins_pe    = ~isnan(group_meanRT_pe);

if sum(validBins_pe) >= 2
    [r_pe_bins, p_pe_bins] = corr(binCenters_pe(validBins_pe)', group_meanRT_pe(validBins_pe)', 'Rows', 'complete');
else
    r_pe_bins = NaN; p_pe_bins = NaN;
end

%% PLOT RTPlot.png
figure('Position', [100, 100, 300, 150]);

% --- Subplot 1: Contrast Difference vs RT ---
ax1 = subplot(1, 2, 1);
hold(ax1, 'on');
scatter(ax1, binCenters_con, group_meanRT_con, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'none');
if sum(validBins_con) >= 2
    ls = lsline(ax1); ls.Color = 'k'; ls.LineWidth = line_width;
end
errorbar(ax1, binCenters_con, group_meanRT_con, group_semRT_con, 'k', 'LineWidth', line_width, 'LineStyle', 'none');
scatter(ax1, binCenters_con, group_meanRT_con, 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', binned_dots);
ylim([-1.03, -0.85]);
xlabel(ax1, ['Contrast difference bins' newline '(1 bin = 0.01)']);
ylabel(ax1, 'Mean log RT');
title(ax1, ['\itr\rm = ' sprintf('%.2f', r_con_bins) newline '\itp\rm = ' sprintf('%.3f', p_con_bins)], ...
    'FontWeight', 'normal', 'Interpreter', 'tex');
set(ax1, 'FontSize', font_size, 'FontName', font_name, 'LineWidth', line_width);
box(ax1, 'off');

% --- Subplot 2: PE vs RT ---
ax2 = subplot(1, 2, 2);
hold(ax2, 'on');
scatter(ax2, binCenters_pe, group_meanRT_pe, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'none');
if sum(validBins_pe) >= 2
    ls = lsline(ax2); ls.Color = 'k'; ls.LineWidth = line_width;
end
errorbar(ax2, binCenters_pe, group_meanRT_pe, group_semRT_pe, 'k', 'LineWidth', line_width, 'LineStyle', 'none');
scatter(ax2, binCenters_pe, group_meanRT_pe, 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', binned_dots);
xlabel(ax2, ['Absolute PE bins' newline '(1 bin = 0.01)']);
ylabel(ax2, 'Mean log RT');
title(ax2, ['\itr\rm = ' sprintf('%.2f', r_pe_bins) newline '\itp\rm = ' sprintf('%.3f', p_pe_bins)], ...
    'FontWeight', 'normal', 'Interpreter', 'tex');
set(ax2, 'FontSize', font_size, 'FontName', font_name, 'LineWidth', line_width);
box(ax2, 'off');

%% SAVE STATS AND FIGURE
rVals = [round(r_pe_bins,3); round(r_con_bins,3)];
pVals = [round(p_pe_bins,3); round(p_con_bins,3)];
termString = {"rtPE"; "rtCondiff"};
T = table(rVals, pVals, termString, 'VariableNames', {'rValuesRT','pValuesRT','term'});
saveStat = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'stats');
safe_saveall(strcat(saveStat, filesep, 'RTDescriptive.csv'), T);

fig = gcf;
fig.PaperPositionMode = 'auto';
print(fig, 'RTPlot.png', '-dpng', '-r600')