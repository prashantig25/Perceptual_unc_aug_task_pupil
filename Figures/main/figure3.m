% figure3 plots descriptive pupil data.

clc
clearvars

currentDir = cd; % current directory
reqPath = 'Perceptual_unc_aug_task_pupil-main'; % to which directory one must save in
pathParts = strsplit(currentDir, filesep);
if strcmp(pathParts{end}, reqPath)
    disp('Current directory is already the desired path. No need to run createSavePaths.');
    desiredPath = currentDir;
else
    % Call the function to create the desired path
    desiredPath = createSavePaths(currentDir, reqPath);
end

condiffbin = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "descriptive", filesep, "fb_PE2bins_linearInt.mat")); % add PE bin curves
betas_struct = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff2bins_linearInt.mat")); % add PE bin curves
coeff_names = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"pe_condiff2bins_linearInt_coeffNames.mat")); % add PE bin curves
perm = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "regression", filesep, "main", filesep,"perm_pe_condiff2bins_linearInt.mat")); % add PE bin curves
trial_all = importdata(strcat(desiredPath, filesep, "data", filesep, "GB data two pipelines", filesep, "pupil", filesep, "descriptive", filesep, "full_trial_linearInt.mat")); % add PE bin curves

[~,high_PU,mid_PU,low_PU,~,~,~,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
x = linspace(-300,2700,300); % x-axis
num_subjs = 47; % number of subjects
neutral = [7, 53, 94]/255;
bin_edges = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1];
dark_violet = [17, 0, 70]./255;
mid_violet = [88, 86, 138]./255;
light_violet = [158, 172, 206]./255;
%% TILED LAYOUT

figure(Position=[200,200,450,175])
hold on
tiledlayout(1,3,"Padding","compact","TileSpacing","compact");
ax1 = nexttile(1,[1,1]);
ax2 = nexttile(2,[1,1]);
ax3 = nexttile(3,[1,1]);

%% PLOT DESCRIPTIVE CURVE

ax1 = nexttile(1,[1,1]);
new_pos = change_position(ax1,[-0.005,0.05,0,-0.1]);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax1_new, 'off'); % remove box
delete(ax1); % delete old axis

% TIME POINTS FOR EACH EVENT
patch_tp = repelem(1,1,100);
resp_tp = [zeros(1,30),repelem(2,1,200)];
fb_tp = [zeros(1,30),repelem(3,1,270)];

trial_tp = [patch_tp,resp_tp,fb_tp];
trial_all = [trial_all];

% PLOT 
x = 1:630;
hold on
plot(mean(trial_all,1),"Color",neutral,"LineWidth",2,"LineStyle","-")
hold on
shadedErrorBar(x,mean(trial_all,1),std(trial_all,1)./sqrt(num_subjs),{"Color",neutral},1)
% ylim([-0.1,0.55])
xlim([1,630])

% ADD LINES TO SEPARATE EVENTS
ylims = get(gca, 'ylim'); ylims(1) = ylims(1)*1.1;
x = length(patch_tp);
l = line([x x], ylims); set(l, 'Color', [0.99,0.99,0.99], 'LineStyle', '-', 'LineWidth', 3);
x = length(patch_tp) + length(resp_tp);
l = line([x x], ylims); set(l, 'Color', [0.99,0.99,0.99], 'LineStyle', '-', 'LineWidth', 3);

ylims = get(gca, 'ylim'); ylims(1) = ylims(1)*1.1;
x = 20;
l = line([x x], ylims); set(l, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);
x = length(patch_tp) + 30;
l = line([x x], ylims); set(l, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);
x = length(patch_tp) + length(resp_tp) + 30;
l = line([x x], ylims); set(l, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 0.5);

xlabels = {'0','500','0','1000','0','500','1000','200'};
xticks = [0,50,130,230,360,460,560];
set(gca,  'XTick', xticks, 'XTickLabel', xlabels,'box', 'off');

text(length(patch_tp), ylims(1) +  0.05, '//', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
text(length(patch_tp) + length(resp_tp), ylims(1) +  0.05, '//', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

set(gca,'Color','none','FontName','Arial','FontSize',7)
set(gca,'LineWidth',0.5)
set(gca,'Color','none')
box off
xlabel("Time since event onset (ms)")
ylabel("Pupil dilation")

text(145,-0.05,"Response","FontSize",6,"FontName",'Arial',"BackgroundColor",[222, 228, 233]./255)
text(375,-0.05,"Feedback","FontSize",6,"FontName",'Arial',"BackgroundColor",[222, 228, 233]./255)
%% PLOT CURVES FOR PE BINS 

% POSITION CHANGE
new_pos = change_position(ax2,[0,0.05,0,-0.08]);
ax4_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax4_new, 'off'); % remove box
delete(ax2); % delete old axis

% GET POSITION FOR P-VALUE
x = linspace(-300,2700,300); % x-axis
ylim_axes = [-0.1,0.45];
[pval_pos] = create_pvalpos(ylim_axes);

avg_bin1= nanmean(condiffbin.pebin1);
sem_bin1 = nanstd(condiffbin.pebin1)./sqrt(num_subjs);

avg_bin2 = nanmean(condiffbin.pebin2);
sem_bin2 = nanstd(condiffbin.pebin2)./sqrt(num_subjs);

% PLOT
hold on
plot(x,avg_bin1,'LineStyle','-','Color',light_violet,'LineWidth',2)
hold on
plot(x,avg_bin2,'LineStyle','-','Color',mid_violet,'LineWidth',2)

hold on
shadedErrorBar(x,avg_bin1,sem_bin1,{'LineWidth',2,'Color',light_violet},1)
hold on
shadedErrorBar(x,avg_bin2,sem_bin2,{'LineWidth',2,'Color',mid_violet},1)
hold on

% ADJUST PLOT PROPERTIES
xline(0,'--')
yline(0,'--')
xlabel('Time since feedback onset (ms)')
ylabel('Pupil dilation')
adjust_figprops(ax4_new,'Arial',7,0.5)
xlim([-300,2700])
% ylim(ylim_axes)
l = legend('Low PE','High PE','Location','best','EdgeColor', ...
    'none','AutoUpdate','off','FontSize',7,'FontName','Arial','Color','none');
l.ItemTokenSize = [7 7];

% PERMUTATION TEST P-VALUE
disp_perm = 1;
if disp_perm == 1
    plot(x(find(condiffbin.stat==1)), -0.05*ones(1, length(find(condiffbin.stat==1))), '.', 'color', ...
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

text(mean(x(condiffbin.stat == 1)),-0.1,pval_str,"FontSize",7,"FontName",'Arial',"VerticalAlignment","bottom","HorizontalAlignment","center")
%% PLOT BINNED REGRESSION RESULTS

% POSITION CHANGE
new_pos = change_position(ax3,[0.02,0.05,0,-0.08]);
ax5_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax5_new, 'off'); % remove box
delete(ax3); % delete old axis

% GET POSITION FOR P-VALUE
ylim_axes = [-0.05,0.1];
[pval_pos] = create_pvalpos(ylim_axes);

ncoeffs  = find(strcmp(coeff_names, 'pe'));
permPE_prob = perm.prob(ncoeffs,:);
permPE_mask = perm.mask(ncoeffs,:);
pval = min(permPE_prob(1,permPE_mask == 1));
if pval < 0.001
    pval_str = "\itp\rm < 0.001";
else
    pval_str = sprintf("\\itp\\rm = %.3f", pval);
end
ncats = repelem(2,1,9);
xlabel_name = 'Time since feedback onset';
cats = [1,2];
color_cell = {high_PU; low_PU}; % colors for low and high perceptual uncertainty data
col = 300; m = 0; start = 0;

% PLOT
for j = cats
    data_plot = zeros(num_subjs,col);
    for s = 1:num_subjs
        for c = 1:col
            data_plot(s,c) = betas_struct.with_intercept(j,ncoeffs,s,c);
        end
    end
    hold on
    color = color_cell;
    ySmoothed = nanmean(data_plot,1);
    plot(x,ySmoothed,"Color",color{j,:},'LineWidth',2)
    hold on
    m = m + num_subjs;
    start = start + m;
end

for j = cats
    data_plot = zeros(num_subjs,col);
    for s = 1:num_subjs
        for c = 1:col
            data_plot(s,c) = betas_struct.with_intercept(j,ncoeffs,s,c);
        end
    end
    ySmoothed = nanmean(data_plot,1);
    color = cell2mat(color_cell);
    shadedErrorBar(x,ySmoothed,nanstd(data_plot,1)./sqrt(num_subjs),{'LineWidth',2,"Color",color(j,:)},1)
    hold on
end

% DISPLAY PERMUTATION TEST RESULTS
disp_perm = 1;
if disp_perm == 1
    plot(x(find(perm.mask(ncoeffs,:) == 1)), -0.02*ones(1, length(find(perm.mask(ncoeffs,:) == 1))), '.', 'color', ...
        [119, 119, 119]./255, 'markersize', 4);
end
text(mean(x(perm.mask(ncoeffs,:) == 1)),pval_pos - 0.02,pval_str,"FontSize",7,"FontName",'Arial',"VerticalAlignment","bottom","HorizontalAlignment","center")

% ADJUST FIGURE PROPERTIES
adjust_figprops(ax5_new,'Arial',7,0.5)
xlim([-300,2700])
% ylim(ylim_axes)
l = legend('High state uncertainty','Low state uncertainty','Location','best','EdgeColor', ...
    'none','AutoUpdate','off','FontSize',7,'FontName','Arial','Color','none');
l.ItemTokenSize = [7 7];
xline(0,'--')
yline(0,'--')
xlabel('Time since feedback onset (ms)')
ylabel('PE-modulated pupil (a.u.)')

%% ADD EXTERNAL PNGs

strings = ["highcon_gabor_sine.png","tap.png","audio_fb.png"];
patch_dim = 0.08;
pos_y = [0.95,0.95,0.95,0.95]-0.05; pos_x = [0.067,0.109,0.207]-0.01;
num_pngs = 3;
adjust_x = 0.025;
for n = 1:num_pngs
    axes('pos',[pos_x(n) pos_y(n) 0.025 patch_dim]);
    [img, ~, tr] = imread(strings(n));
    im = image('CData',img);
    im.AlphaData = tr;
    set(gca,'YDir','reverse');
    set(gca,'color','none');
    set(gca,'XColor', 'none','YColor','none');
    hold on
end

%% ADD SUBPLOT LABELS

ax1_pos = ax5_new.Position;
adjust_x = -0.06; % adjusted x-position for subplot label
adjust_y = ax1_pos(4) + 0.05; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(ax1_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax4_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax5_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

%% SAVE 

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'descriptive_pupil_linearInt1.png', '-dpng', '-r600') 