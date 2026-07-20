% figure3 plots descriptive pupil data.

clc
clearvars

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

condiffbin = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "descriptive", filesep, "fb_PE2bins_linearInt.mat")); % add PE bin curves
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff2bins_linearInt.mat")); % add PE bin curves
coeff_names = betas_struct.coeff_names; % importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff2bins_linearInt_coeffNames.mat")); % add PE bin curves
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff2bins_linearInt.mat")); % add PE bin curves
trial_all = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "descriptive", filesep, "full_trial_linearInt.mat")); % add PE bin curves

[~,high_PU,mid_PU,low_PU,~,~,~,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
subj_ids = importdata("subj_ids.mat");
num_subjs = length(subj_ids); % number of subjects
neutral = [7, 53, 94]/255;
bin_edges = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1];
dark_violet = [17, 0, 70]./255;
mid_violet = [88, 86, 138]./255;
light_violet = [158, 172, 206]./255;
font_size = 7;
font_name = 'Arial';
linewidth_plot = 0.5;

%% TILED LAYOUT

fig = figure; 
set(fig, 'Visible', 'on');

% Size in CM
width_cm = 15; 
height_cm = 6; 
set(fig, 'Units', 'centimeters');
set(fig, 'Position', [10, 10, width_cm, height_cm]);
set(fig, 'PaperUnits', 'centimeters');
set(fig, 'PaperSize', [width_cm, height_cm]);
set(fig, 'PaperPosition', [0, 0, width_cm, height_cm]);

hold on
tiledlayout(1, 3, "Padding", "compact", "TileSpacing", "compact");
ax1 = nexttile(1, [1, 1]);
ax2 = nexttile(2, [1, 1]);
ax3 = nexttile(3, [1, 1]);

%% PLOT DESCRIPTIVE CURVE

new_pos_a = change_position(ax1,[-0.005, 0.05, 0, -0.1]);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos_a); 
box(ax1_new, 'off'); 
delete(ax1); 

% TIME POINTS FOR EACH EVENT
patch_tp = repelem(1, 1, 100);
pre_resp = zeros(1, 30);
resp = repelem(2, 1 ,200);
resp_tp = [pre_resp,resp];
pre_fb = zeros(1, 30);
fb = repelem(3, 1, 270);
fb_tp = [pre_fb, fb];
trial_tp = [patch_tp, resp_tp, fb_tp];

% PLOT 
x = 1:630;
hold on
plot(mean(trial_all,1), "Color", neutral, "LineWidth", 2, "LineStyle","-")
shadedErrorBar(x, mean(trial_all,1), std(trial_all)./sqrt(num_subjs), {"Color", neutral}, 1)
xlim([1, length(trial_tp)])

% ADD LINES TO SEPARATE EVENTS
ylims = get(gca, 'ylim'); ylims(1) = ylims(1)*1.1;
x = length(patch_tp);
l = line([x x], ylims); set(l, 'Color', 'w', 'LineStyle', '-', 'LineWidth', 3);
x = length(patch_tp) + length(resp_tp);
l = line([x x], ylims); set(l, 'Color', 'w', 'LineStyle', '-', 'LineWidth', 3);

ylims = get(gca, 'ylim'); ylims(1) = ylims(1)*1.1;
x = 20;
l = line([x x], ylims); set(l, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);
x = length(patch_tp) + 30;
l = line([x x], ylims); set(l, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);
x = length(patch_tp) + length(resp_tp) + 30;
l = line([x x], ylims); set(l, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);

% Different segments of plot
segments = [patch_tp, resp_tp, fb_tp];
seg_lengths = [length(patch_tp), length(pre_resp), length(resp), length(pre_fb), length(fb(1,:))];
cum_lengths = cumsum([0, seg_lengths]);

% Midpoints of each event (patch, resp, fb)
patch_mid = cum_lengths(1) + seg_lengths(1)/2;
resp_mid  = cum_lengths(3) + seg_lengths(3)/2;
fb_mid = cum_lengths(5) + seg_lengths(1);   % mid of first fb half
fb_mid2 = cum_lengths(5) + seg_lengths(1) + seg_lengths(1);  % mid of first fb half

cut1 = length(patch_tp);
cut2 = length(patch_tp) + length(resp_tp);

xticks = [0, patch_mid, cum_lengths(3), resp_mid, cum_lengths(5), fb_mid, fb_mid2];
samples_per_100ms = 10; % Time within each event (in ms, at 10 samples/100ms rate)
xticks_within = (xticks - cum_lengths([1, 1, 3, 3, 5, 5, 5])) * (100/samples_per_100ms);
xlabels = arrayfun(@(t) num2str(round(t)), xticks_within, 'UniformOutput', false);
set(gca,  'XTick', xticks, 'XTickLabel', xlabels,'box', 'off');

% Limits and styling
ylim(ax1_new, [-20, 300]);
xlim(ax1_new, [1, 630]);
xl = xlim(ax1_new);
ylims = ylim(ax1_new);
set(ax1_new, 'XColor', 'k', 'YColor', 'k', 'FontName', font_name, 'FontSize', font_size, 'LineWidth', 0.5, 'TickDir', 'in');

% Draw vertical lines
pos_x_data = [20, length(patch_tp) + 30, length(patch_tp) + length(resp_tp) + 30];
line(ax1_new, [20, 20], ylims, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);
line(ax1_new, [pos_x_data(2), pos_x_data(2)], ylims, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);
line(ax1_new, [pos_x_data(3), pos_x_data(3)], ylims, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);

% Axis info
tick_len = (ylims(2) - ylims(1)) * 0.0225;
text(ax1_new, xl(1) + diff(xl)*0.5, ylims(1) - tick_len * 6.0, "Time since event onset (ms)", ...
     'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
ylh_a = ylabel(ax1_new, "Pupil dilation", FontSize=font_size);% 1. Set the tick label font size
adjust_figprops(ax1_new, font_name, font_size, linewidth_plot);

set(gca,'LineWidth',0.5)
set(gca,'Color','none')
box off

icon_ax = axes('Units', 'Normalized', 'Position', new_pos_a, ...
               'XLim', xl, 'YLim', ylims, ...
               'Color', 'none', 'XColor', 'none', 'YColor', 'none', ...
               'Clipping', 'off'); 
hold(icon_ax, 'on');

w = 4; 
p1 = patch(icon_ax, [cut1-w, cut1+w, cut1+w, cut1-w], [ylims(1)-2, ylims(1)-2, ylims(2), ylims(2)], [1, 1, 1], 'EdgeColor', 'none');
p2 = patch(icon_ax, [cut2-w, cut2+w, cut2+w, cut2-w], [ylims(1)-2, ylims(1)-2, ylims(2), ylims(2)], [1, 1, 1], 'EdgeColor', 'none');

text(icon_ax, cut1, ylims(1), '//', 'Color', 'k', 'FontName', font_name, 'FontSize', font_size, ...
     'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
text(icon_ax, cut2, ylims(1), '//', 'Color', 'k', 'FontName', font_name, 'FontSize', font_size, ...
     'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');

text(icon_ax, 145, 5.0, "Response", 'FontSize', 6, 'FontName', font_name, 'BackgroundColor', [222, 228, 233]./255);
text(icon_ax, 375, 5.0, "Feedback", 'FontSize', 6, 'FontName', font_name, 'BackgroundColor', [222, 228, 233]./255);

parent_fig = ancestor(icon_ax, 'figure');
fig_units = parent_fig.Units; parent_fig.Units = 'pixels'; fig_px = parent_fig.Position; parent_fig.Units = fig_units;
ax_pos = get(icon_ax, 'Position');
patch_h_norm = 0.05; 
patch_w_norm = patch_h_norm * (fig_px(4) / fig_px(3)); 
img_w_data = (patch_w_norm / ax_pos(3)) * (xl(2) - xl(1));
img_h_data = (patch_h_norm / ax_pos(4)) * (ylims(2) - ylims(1));

y_img_bottom = ylims(2) + (ylims(2) - ylims(1)) * 0.02; 
strings = ["lowcon.png", "tap.png", "audio_fb.png"];

for n = 1:3
    [img, ~, tr] = imread(strings(n));
    if n == 2
        img = rot90(img, 2);
        if ~isempty(tr)
            tr = rot90(tr, 2);
        end
    end
    
    if ~isempty(tr)
        alpha = double(tr) / 255;
        for c = 1:3
            img(:,:,c) = uint8(double(img(:,:,c)) .* alpha + 255 * (1 - alpha));
        end
    end
    
    x_bounds = [pos_x_data(n) - img_w_data/2, pos_x_data(n) + img_w_data/2];
    y_bounds = [y_img_bottom, y_img_bottom + img_h_data];
    
    im = image(icon_ax, 'XData', x_bounds, 'YData', y_bounds, 'CData', img);
end
uistack(icon_ax, 'top');

%% PLOT CURVES FOR PE BINS 

% POSITION CHANGE
new_pos = change_position(ax2,[0,0.05,0,-0.1]);
ax4_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax4_new, 'off'); % remove box
delete(ax2); % delete old axis

% GET POSITION FOR P-VALUE
x = linspace(-300,2700,300); % x-axis

avg_bin1= mean(condiffbin.pebin1);
sem_bin1 = std(condiffbin.pebin1)./sqrt(num_subjs);

avg_bin2 = mean(condiffbin.pebin2);
sem_bin2 = std(condiffbin.pebin2)./sqrt(num_subjs);

% PLOT
hold on
h1 = plot(x, avg_bin1, 'LineStyle', '-', 'Color', light_violet, 'LineWidth', 2);
h2 = plot(x, avg_bin2, 'LineStyle', '-', 'Color', mid_violet, 'LineWidth', 2);
shadedErrorBar(x, avg_bin1, sem_bin1,{'LineWidth', 2, 'Color', light_violet},1)
shadedErrorBar(x, avg_bin2, sem_bin2,{'LineWidth', 2, 'Color', mid_violet},1)

% ADJUST PLOT PROPERTIES
xline(0,'--')
yline(0,'--')
xlabel('Time since feedback onset (ms)')
ylh_b = ylabel(ax4_new, 'Pupil dilation');
adjust_figprops(ax4_new, font_name, font_size, 0.5)
xlim([-300, 2700])

% Legend
l = legend([h1, h2], 'Low PE', 'High PE', 'Location', 'northeast', 'EdgeColor', ...
    'none', 'AutoUpdate', 'off', 'FontSize', font_size, 'FontName', font_name, 'Color', 'none');
leg_pos = l.Position;
x_nudge = 0.05; % bit more right
y_nudge = 0.02; % bit higher
leg_pos(1) = leg_pos(1) + x_nudge; 
leg_pos(2) = leg_pos(2) + y_nudge;
l.Position = leg_pos;
l.ItemTokenSize = [7 7];

% PERMUTATION TEST P-VALUE
disp_perm = 1;
if disp_perm == 1
    plot(x(find(condiffbin.stat==1)), -40*ones(1, length(find(condiffbin.stat==1))), '.', 'color', ...
        [119, 119, 119]./255, 'markersize', 4);
end
permPE_prob = condiffbin.prob(1,:);
permPE_mask = condiffbin.stat(1,:);
pval = min(permPE_prob(1,permPE_mask == 1));
if pval < 0.001
    pval_str = "\itp\rm < 0.001";
else
    pval_str = sprintf("\\itp\\rm = %.3f", pval);
end

text(mean(x(condiffbin.stat == 1)), -39, pval_str, "FontSize", font_size, "FontName", font_name, "VerticalAlignment", "bottom", "HorizontalAlignment", "center")

%% PLOT BINNED REGRESSION RESULTS

% POSITION CHANGE
new_pos = change_position(ax3,[0.02, 0.05, 0, -0.1]);
ax5_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax5_new, 'off'); % remove box
delete(ax3); % delete old axis

% GET POSITION FOR P-VALUE
ylim_axes = [-0.05, 0.1];
[pval_pos] = create_pvalpos(ylim_axes);

ncoeffs  = find(strcmp(coeff_names, 'pe'));
permPE_prob = perm.prob(ncoeffs,:);
permPE_mask = perm.mask(ncoeffs,:);
pval = min(permPE_prob(1, permPE_mask == 1));
if pval < 0.001
    pval_str = "\itp\rm < 0.001";
else
    pval_str = sprintf("\\itp\\rm = %.3f", pval);
end
ncats = repelem(2, 1, 9);
xlabel_name = 'Time since feedback onset';
cats = [1, 2];
color_cell = {high_PU; low_PU}; % colors for low and high perceptual uncertainty data
col = 300; 
m = 0; 
start = 0;

% PLOT
for j = cats
    data_plot = zeros(num_subjs,col);
    for s = 1:num_subjs
        for c = 1:col
            data_plot(s,c) = betas_struct.with_intercept(j, ncoeffs,s,c);
        end
    end
    hold on
    color = color_cell;
    ySmoothed = mean(data_plot, 1);
    plot(x, ySmoothed, "Color", color{j,:}, 'LineWidth',2)
    hold on
    m = m + num_subjs;
    start = start + m;
end

for j = cats
    data_plot = zeros(num_subjs, col);
    for s = 1:num_subjs
        for c = 1:col
            data_plot(s, c) = betas_struct.with_intercept(j, ncoeffs, s, c);
        end
    end
    ySmoothed = mean(data_plot, 1);
    color = cell2mat(color_cell);
    shadedErrorBar(x, ySmoothed,std(data_plot)./sqrt(num_subjs), {'LineWidth',2,"Color",color(j,:)},1)
    hold on
end

% DISPLAY PERMUTATION TEST RESULTS
disp_perm = 1;
if disp_perm == 1
    plot(x(find(perm.mask(ncoeffs,:) == 1)), ones(1, length(find(perm.mask(ncoeffs,:) == 1))) + 1, '.', 'color', ...
        [119, 119, 119]./255, 'markersize', 4);
end
text(mean(x(perm.mask(ncoeffs,:) == 1)),pval_pos + 2.5,pval_str, ...
    "FontSize", font_size, "FontName", font_name, "VerticalAlignment", "bottom",...
    "HorizontalAlignment", "center")

% ADJUST FIGURE PROPERTIES
adjust_figprops(ax5_new, font_name, font_size, 0.5)
xlim([-300, 2700])
% ylim(ylim_axes)
l = legend('High state uncertainty', 'Low state uncertainty', 'Location', 'best', 'EdgeColor', ...
    'none', 'AutoUpdate', 'off', 'FontSize', font_size, 'FontName', font_name, 'Color', 'none');
l.ItemTokenSize = [7 7];
l.Position = [0.75, 0.2100, 0.2710, 0.0400];

xline(0,'--')
yline(0,'--')
xlabel('Time since feedback onset (ms)')
ylh_c = ylabel(ax5_new, 'PE-modulated pupil');

% Forces MATLAB to process the font bounding boxes first
drawnow; 

% Switch label tracking units to 'Normalized' mode
set(ylh_a, 'Units', 'Normalized');
set(ylh_b, 'Units', 'Normalized');
set(ylh_c, 'Units', 'Normalized');

%% ADD SUBPLOT LABELS

ax1_pos = ax5_new.Position;
adjust_x = -0.06; % adjusted x-position for subplot label
adjust_y = ax1_pos(4) + 0.06; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(ax1_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a', 'FontSize' ,12, 'LineStyle', 'none', 'HorizontalAlignment', 'center')

[label_x,label_y] = change_plotlabel(ax4_new, adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05], 'String', ...
    'b', 'FontSize', 12, 'LineStyle', 'none', 'HorizontalAlignment', 'center')

[label_x,label_y] = change_plotlabel(ax5_new, adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c', 'FontSize', 12, 'LineStyle', 'none', 'HorizontalAlignment','center')

%% SAVE 

fig = gcf; 
fig.PaperPositionMode = 'auto'; 
% print(fig, 'descriptive_pupil_linearInt1.png', '-dpng', '-r600') 

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters'; % <--- FORCE VECTOR RENDERING (No rasterization!)
style.FontMode = 'none'; % Tells hgexport NOT to touch your font sizes
hgexport(fig, 'Figures/PDF_Versions/Figure_3.pdf', style);