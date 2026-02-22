% Multiverse plot with STANDARDIZED values - 12 SPECIFICATIONS
% This includes heteroskedasticity analyses with coefficient 6
% All values normalized for comparability

clc
clearvars

% INITIALIZE VARS
fontname = 'Arial';
fontsize = 7;
linewidth_plot = 0.5; % line width for plot
xaxis = linspace(-300,2700,300);
num_subs = 47;
col = 300;

currentDir = cd;
reqPath    = 'Perceptual_unc_aug_task_pupil-main';
pathParts  = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    desiredPath = currentDir;
else
    desiredPath = createSavePaths(currentDir, reqPath);
end

main_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'main');
alt_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'regression', 'control analyses for revisions');

% Load OLS coefficient names and find pe:zsc_condiff index dynamically
ols_coeff_names = importdata(fullfile(main_dir, 'pe_condiff_linearInt_coeffNames.mat'));
pe_condiff_idx  = find(strcmp(ols_coeff_names, 'pe'));

% Load hetero coefficient names and find PExCondiff index dynamically
het_coeff_names    = importdata(fullfile(alt_dir, 'coeff_names_hetero.mat'));
pe_condiff_idx_het = find(strcmp(het_coeff_names, 'PE'));

%% LOAD ALL DATA (9 original + 3 heteroskedasticity)

fprintf('Loading original 9 specifications...\n');
betas_linearInt        = importdata(fullfile(main_dir, 'pe_condiff_linearInt.mat'));
perm_linearInt         = importdata(fullfile(main_dir, 'perm_pe_condiff_linearInt.mat'));
betas_cubicSpline      = importdata(fullfile(main_dir, 'pe_condiff_cubicSplineNew.mat'));
perm_cubicSpline       = importdata(fullfile(main_dir, 'perm_pe_condiff_cubicSplineNew.mat'));
betas_deconv           = importdata(fullfile(alt_dir,  'pe_condiff_deconvolution_updatedClusterStat.mat'));
perm_deconv            = importdata(fullfile(alt_dir,  'perm_pe_condiff_deconvolution_updatedClusterStat.mat'));
betas_linearInt_RT     = importdata(fullfile(main_dir, 'pe_condiff_regressedRT_linearInt.mat'));
perm_linearInt_RT      = importdata(fullfile(main_dir, 'perm_pe_condiff_regressedRT_linearInt.mat'));
betas_cubicSpline_RT   = importdata(fullfile(main_dir, 'pe_condiff_regressedRT_cubicSplineNew.mat'));
perm_cubicSpline_RT    = importdata(fullfile(main_dir, 'perm_pe_condiff_regressedRT_cubicSplineNew.mat'));
betas_deconv_RT        = importdata(fullfile(alt_dir,  'pe_condiff_regressedRT_deconvolution.mat'));
perm_deconv_RT         = importdata(fullfile(alt_dir,  'perm_pe_condiff_regressedRT_deconvolution.mat'));
betas_linearInt_noBL   = importdata(fullfile(alt_dir,  'pe_condiff_mathot_nonBaselineCorrected_linearInt.mat'));
perm_linearInt_noBL    = importdata(fullfile(alt_dir,  'perm_pe_condiff_mathot_nonBaselineCorrected_linearInt.mat'));
betas_cubicSpline_noBL = importdata(fullfile(alt_dir,  'pe_condiff_mathot_nonBaselineCorrected_cubicSplineNew.mat'));
perm_cubicSpline_noBL  = importdata(fullfile(alt_dir,  'perm_pe_condiff_mathot_nonBaselineCorrected_cubicSplineNew.mat'));
betas_deconv_noBL      = importdata(fullfile(alt_dir,  'pe_condiff_deconvolution_nonBaselineCorrected.mat'));
perm_deconv_noBL       = importdata(fullfile(alt_dir,  'perm_pe_condiff_deconvolution_nonBaselineCorrected.mat'));

fprintf('Loading heteroskedasticity specifications...\n');
betas_linear_het = importdata(fullfile(alt_dir, 'param_estimates_hetero_noZeroPE_linearInt_20SPAbs3Width_pregenSP.mat'));
betas_cubic_het  = importdata(fullfile(alt_dir, 'param_estimates_hetero_noZeroPE_CS_20SPAbs3Width_pregenSP.mat'));
betas_deconv_het = importdata(fullfile(alt_dir, 'param_estimates_hetero_noZeroPE_deconvolution_20SPAbs3Width_pregenSP.mat'));

fprintf('Running permutation tests for heteroskedasticity analyses...\n');

% Heteroskedastic permutation test
perm_linear_het = get_permtest(1:size(betas_linear_het.with_intercept,2), num_subs, col, betas_linear_het.with_intercept, [], 0, 1);
perm_cubic_het = get_permtest(1:size(betas_cubic_het.with_intercept,2), num_subs, col, betas_cubic_het.with_intercept, [], 0, 1);
perm_deconv_het = get_permtest(1:size(betas_deconv_het.with_intercept,2), num_subs, col, betas_deconv_het.with_intercept, [], 0, 1);

fprintf('Permutation tests complete!\n');

%% EXTRACT COEFFICIENTS

sub_id = 1:num_subs;
col_id = 1:col;

% Original 9 specifications (coefficient 8)
pe_condiff_linearInt(sub_id,col_id) = betas_linearInt.with_intercept(1,pe_condiff_idx,sub_id,col_id);
pe_condiff_cubicSpline(sub_id,col_id) = betas_cubicSpline.with_intercept(1,pe_condiff_idx,sub_id,col_id);
pe_condiff_deconv(sub_id,col_id) = betas_deconv.with_intercept(1,pe_condiff_idx,sub_id,col_id);
pe_condiff_linearInt_RT(sub_id,col_id) = betas_linearInt_RT.with_intercept(1,pe_condiff_idx,sub_id,col_id);
pe_condiff_cubicSpline_RT(sub_id,col_id) = betas_cubicSpline_RT.with_intercept(1,pe_condiff_idx,sub_id,col_id);
pe_condiff_deconv_RT(sub_id,col_id) = betas_deconv_RT.with_intercept(1,pe_condiff_idx,sub_id,col_id);
pe_condiff_linearInt_noBL(sub_id,col_id) = betas_linearInt_noBL.with_intercept(1,pe_condiff_idx,sub_id,col_id);
pe_condiff_cubicSpline_noBL(sub_id,col_id) = betas_cubicSpline_noBL.with_intercept(1,pe_condiff_idx,sub_id,col_id);
pe_condiff_deconv_noBL(sub_id,col_id) = betas_deconv_noBL.with_intercept(1,pe_condiff_idx,sub_id,col_id);

% Heteroskedasticity specifications (coefficient 6)
pe_condiff_linear_het(sub_id,col_id) = betas_linear_het.with_intercept(1,pe_condiff_idx_het,sub_id,col_id);
pe_condiff_cubic_het(sub_id,col_id) = betas_cubic_het.with_intercept(1,pe_condiff_idx_het,sub_id,col_id);
pe_condiff_deconv_het(sub_id,col_id) = betas_deconv_het.with_intercept(1,pe_condiff_idx_het,sub_id,col_id);

%% CALCULATE MEANS AND STANDARDIZE

fprintf('\nCalculating means and standardizing...\n');

% Calculate raw means
mean1_raw = mean(pe_condiff_linearInt);
mean2_raw = mean(pe_condiff_cubicSpline);
mean3_raw = mean(pe_condiff_deconv);
mean4_raw = mean(pe_condiff_linearInt_RT);
mean5_raw = mean(pe_condiff_cubicSpline_RT);
mean6_raw = mean(pe_condiff_deconv_RT);
mean7_raw = mean(pe_condiff_linearInt_noBL);
mean8_raw = mean(pe_condiff_cubicSpline_noBL);
mean9_raw = mean(pe_condiff_deconv_noBL);
mean10_raw = mean(pe_condiff_linear_het);
mean11_raw = mean(pe_condiff_cubic_het);
mean12_raw = mean(pe_condiff_deconv_het);

% Standardize by dividing by SD
mean1 = mean1_raw / std(mean1_raw);
mean2 = mean2_raw / std(mean2_raw);
mean3 = mean3_raw / std(mean3_raw);
mean4 = mean4_raw / std(mean4_raw);
mean5 = mean5_raw / std(mean5_raw);
mean6 = mean6_raw / std(mean6_raw);
mean7 = mean7_raw / std(mean7_raw);
mean8 = mean8_raw / std(mean8_raw);
mean9 = mean9_raw / std(mean9_raw);
mean10 = mean10_raw / std(mean10_raw);
mean11 = mean11_raw / std(mean11_raw);
mean12 = mean12_raw / std(mean12_raw);

fprintf('Standardization complete - all 12 curves in SD units\n');

% Stack for envelope
means_all = [mean1; mean2; mean3; mean4; mean5; mean6; mean7; mean8; mean9; mean10; mean11; mean12];
upper_bound = max(means_all);
lower_bound = min(means_all);
median_line = median(means_all);

%% EXTRACT SIGNIFICANCE MASKS AND P-VALUES

% Original 9
pecondiff_pval_linearInt = perm_linearInt.mask(pe_condiff_idx,:);
pecondiff_pval_cubicSpline = perm_cubicSpline.mask(pe_condiff_idx,:);
pecondiff_pval_deconv = perm_deconv.mask(pe_condiff_idx,:);
pecondiff_pval_linearInt_RT = perm_linearInt_RT.mask(pe_condiff_idx,:);
pecondiff_pval_cubicSpline_RT = perm_cubicSpline_RT.mask(pe_condiff_idx,:);
pecondiff_pval_deconv_RT = perm_deconv_RT.mask(pe_condiff_idx,:);
pecondiff_pval_linearInt_noBL = perm_linearInt_noBL.mask(pe_condiff_idx,:);
pecondiff_pval_cubicSpline_noBL = perm_cubicSpline_noBL.mask(pe_condiff_idx,:);
pecondiff_pval_deconv_noBL = perm_deconv_noBL.mask(pe_condiff_idx,:);

% Heteroskedasticity
pecondiff_pval_linear_het = perm_linear_het.mask(pe_condiff_idx_het,:);
pecondiff_pval_cubic_het = perm_cubic_het.mask(pe_condiff_idx_het,:);
pecondiff_pval_deconv_het = perm_deconv_het.mask(pe_condiff_idx_het,:);

% P-values - original 9
pecondiff_prob_linearInt = min(unique(perm_linearInt.prob(pe_condiff_idx,:)));
pecondiff_prob_cubicSpline = min(unique(perm_cubicSpline.prob(pe_condiff_idx,:)));
pecondiff_prob_deconv = min(unique(perm_deconv.prob(pe_condiff_idx,:)));
pecondiff_prob_linearInt_RT = min(unique(perm_linearInt_RT.prob(pe_condiff_idx,:)));
pecondiff_prob_cubicSpline_RT = min(unique(perm_cubicSpline_RT.prob(pe_condiff_idx,:)));
pecondiff_prob_deconv_RT = min(unique(perm_deconv_RT.prob(pe_condiff_idx,:)));
pecondiff_prob_linearInt_noBL = min(unique(perm_linearInt_noBL.prob(pe_condiff_idx,:)));
pecondiff_prob_cubicSpline_noBL = min(unique(perm_cubicSpline_noBL.prob(pe_condiff_idx,:)));
pecondiff_prob_deconv_noBL = min(unique(perm_deconv_noBL.prob(pe_condiff_idx,:)));

% P-values - heteroskedasticity
pecondiff_prob_linear_het = min(unique(perm_linear_het.prob(pe_condiff_idx_het,:)));
pecondiff_prob_cubic_het = min(unique(perm_cubic_het.prob(pe_condiff_idx_het,:)));
pecondiff_prob_deconv_het = min(unique(perm_deconv_het.prob(pe_condiff_idx_het,:)));

%% DEFINE 12 COLORS IN 4 HARMONIZING FAMILIES (BY ANALYSIS TYPE)

fprintf('Setting up color families for 12 specifications...\n');

% STANDARD FAMILY (Muted Blues) - dark to light
color_linear = [0.2, 0.35, 0.55];          % Dark muted blue
color_cubic = [0.35, 0.50, 0.70];          % Medium muted blue
color_deconv = [0.50, 0.65, 0.85];         % Light muted blue

% RT REGRESSED FAMILY (Grays) - dark to light
color_linear_RT = [0.35, 0.35, 0.35];      % Dark gray
color_cubic_RT = [0.55, 0.55, 0.55];       % Medium gray
color_deconv_RT = [0.75, 0.75, 0.75];      % Light gray

% NON-BASELINE CORRECTED FAMILY (Muted Greens) - dark to light
color_linear_noBL = [0.25, 0.50, 0.35];    % Dark muted green
color_cubic_noBL = [0.35, 0.60, 0.45];     % Medium muted green
color_deconv_noBL = [0.50, 0.75, 0.60];    % Light muted green

% HETEROSKEDASTIC FAMILY (Muted Purples) - dark to light
color_linear_hetero = [0.45, 0.25, 0.55];  % Dark muted purple
color_cubic_hetero = [0.55, 0.35, 0.65];   % Medium muted purple
color_deconv_hetero = [0.70, 0.50, 0.80];  % Light muted purple
%% CREATE FIGURE

fprintf('Creating figure with 12 specifications...\n');
figure("Position",[600,600,300,550])
t = tiledlayout(3,1,"Padding","compact","TileSpacing","compact");

xlim_axes = [-300,2700];

%% Panel 1: All 12 standardized curves

ax1 = nexttile(1,[1,1]);
hold on

% Plot all 12 standardized curves
plot(xaxis, mean1, 'Color', color_linear, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Linear');
plot(xaxis, mean2, 'Color', color_cubic, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Cubic Spline');
plot(xaxis, mean3, 'Color', color_deconv, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Deconvolution');
plot(xaxis, mean4, 'Color', color_linear_RT, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Linear regressed RT');
plot(xaxis, mean5, 'Color', color_cubic_RT, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Cubic regressed RT');
plot(xaxis, mean6, 'Color', color_deconv_RT, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Deconvolution regressed RT');
plot(xaxis, mean7, 'Color', color_linear_noBL, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Linear non-baseline corrected');
plot(xaxis, mean8, 'Color', color_cubic_noBL, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Cubic non-baseline corrected');
plot(xaxis, mean9, 'Color', color_deconv_noBL, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Deconvolution non-baseline corrected');
plot(xaxis, mean10, 'Color', color_linear_hetero, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Linear heteroskedastic');
plot(xaxis, mean11, 'Color', color_cubic_hetero, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Cubic heteroskedastic');
plot(xaxis, mean12, 'Color', color_deconv_hetero, 'LineWidth', 2, 'LineStyle', '-', 'DisplayName', 'Deconv heteroskedastic');

xlim(xlim_axes)
xline(0,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5],'HandleVisibility','off');
yline(0,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5],'HandleVisibility','off');

xlabel('Time since feedback onset (ms)','FontName',fontname,'FontSize',fontsize)
ylabel('Standardized absolute PE coefficients','FontWeight','normal','FontName',fontname,'FontSize',fontsize)
lgd = legend('Location','best','FontSize',4,'NumColumns',1,'Color','none','EdgeColor','none');
lgd.ItemTokenSize = [10, 10];
title('Multiverse Analysis: All 12 Specifications (Standardized)','FontName',fontname,'FontSize',fontsize+1,'FontWeight','normal')
adjust_figprops(ax1,fontname,fontsize,linewidth_plot);

% text(0.02, 0.95, 'Solid=Std | Dashed=RT | Dotted=NoBL | Dash-dot=Hetero', ...
%      'Units', 'normalized', 'FontSize', 6, 'VerticalAlignment', 'top', 'Color', [0.3 0.3 0.3]);

%% Panel 2: Significant clusters for all 12

ax2 = nexttile(2,[1,1]);
hold on
marker_size = 10;
y_positions = [1:12]/12;

plot(xaxis(pecondiff_pval_linearInt==1), y_positions(12)*ones(1,sum(pecondiff_pval_linearInt==1)), '.', 'color', color_linear, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_cubicSpline==1), y_positions(11)*ones(1,sum(pecondiff_pval_cubicSpline==1)), '.', 'color', color_cubic, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_deconv==1), y_positions(10)*ones(1,sum(pecondiff_pval_deconv==1)), '.', 'color', color_deconv, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_linearInt_RT==1), y_positions(9)*ones(1,sum(pecondiff_pval_linearInt_RT==1)), '.', 'color', color_linear_RT, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_cubicSpline_RT==1), y_positions(8)*ones(1,sum(pecondiff_pval_cubicSpline_RT==1)), '.', 'color', color_cubic_RT, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_deconv_RT==1), y_positions(7)*ones(1,sum(pecondiff_pval_deconv_RT==1)), '.', 'color', color_deconv_RT, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_linearInt_noBL==1), y_positions(6)*ones(1,sum(pecondiff_pval_linearInt_noBL==1)), '.', 'color', color_linear_noBL, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_cubicSpline_noBL==1), y_positions(5)*ones(1,sum(pecondiff_pval_cubicSpline_noBL==1)), '.', 'color', color_cubic_noBL, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_deconv_noBL==1), y_positions(4)*ones(1,sum(pecondiff_pval_deconv_noBL==1)), '.', 'color', color_deconv_noBL, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_linear_het==1), y_positions(3)*ones(1,sum(pecondiff_pval_linear_het==1)), '.', 'color', color_linear_hetero, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_cubic_het==1), y_positions(2)*ones(1,sum(pecondiff_pval_cubic_het==1)), '.', 'color', color_cubic_hetero, 'markersize', marker_size);
plot(xaxis(pecondiff_pval_deconv_het==1), y_positions(1)*ones(1,sum(pecondiff_pval_deconv_het==1)), '.', 'color', color_deconv_hetero, 'markersize', marker_size);

xlim(xlim_axes)
ylim([0,1])
xlabel('Time since feedback onset (ms)','FontName',fontname,'FontSize',fontsize)
ylabel("Significant clusters",'FontName',fontname,'FontSize',fontsize)
yticks(y_positions)
yticklabels({'','','','','','','','','','','',''})
adjust_figprops(ax2,fontname,fontsize,linewidth_plot);

%% Panel 3: P-values for all 12

ax3 = nexttile(3,[1,1]);
hold on

p_values = [pecondiff_prob_linearInt, pecondiff_prob_cubicSpline, pecondiff_prob_deconv, ...
            pecondiff_prob_linearInt_RT, pecondiff_prob_cubicSpline_RT, pecondiff_prob_deconv_RT, ...
            pecondiff_prob_linearInt_noBL, pecondiff_prob_cubicSpline_noBL, pecondiff_prob_deconv_noBL, ...
            pecondiff_prob_linear_het, pecondiff_prob_cubic_het, pecondiff_prob_deconv_het];

colors_all = [color_linear; color_cubic; color_deconv; ...
              color_linear_RT; color_cubic_RT; color_deconv_RT; ...
              color_linear_noBL; color_cubic_noBL; color_deconv_noBL; ...
              color_linear_hetero; color_cubic_hetero; color_deconv_hetero];

for i = 1:12
    plot(i, p_values(i), 'o', 'MarkerFaceColor', colors_all(i,:), 'MarkerEdgeColor', 'k', 'MarkerSize', 7, 'MarkerEdgeColor', colors_all(i,:))
end

medianPvalues = median(p_values);
disp(medianPvalues)

medianMultiverse = table(round(medianPvalues, 3), ...
    'VariableNames', {'median'});
stats_dir = fullfile(desiredPath, 'data', 'GB data two pipelines', 'pupil', 'stats');
safe_saveall(fullfile(stats_dir, 'medianMultiversePval.csv'), medianMultiverse);

yline(0.025, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1, 'HandleVisibility', 'off');
yline(0.05, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1, 'HandleVisibility', 'off');
text(1.5, 0.028, 'Significant threshold for two-tailed test', 'FontSize', 7, 'VerticalAlignment', 'middle');
text(1.5, 0.053, 'Significant threshold for one-tailed test', 'FontSize', 7, 'VerticalAlignment', 'middle');

ylabel("{\itp}-value",'FontName',fontname,'FontSize',fontsize)
xlabel("Specification",'FontName',fontname,'FontSize',fontsize)
xlim([0, 13])
ylim([0, 0.06])
xticks(1:12)
xticklabels({'Lin','Cub','Dec','Lin-RT','Cub-RT','Dec-RT','Lin-NBL','Cub-NBL','Dec-NBL','Lin-Het','Cub-Het','Dec-Het'})
xtickangle(45)
adjust_figprops(ax3,fontname,fontsize,linewidth_plot);

%% ADD SUBPLOT LABELS

ax1_pos = ax1.Position;
adjust_x = -0.065; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)-0.02; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(ax1,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax2,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax3,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

fig = gcf;
fig.PaperPositionMode = 'auto';
print(fig, 'multiverse_12_specifications.png', '-dpng', '-r600')
