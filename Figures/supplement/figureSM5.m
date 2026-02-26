% figureSM5 plots full model results of the model-based analysis of
% residual learning.

clc
clearvars

linewidth_plot = 0.5; % line-width for axes
linewidth_curves = 2; % line-width for curves
xaxis = linspace(-300,2700,300); % x-axis
num_subjs = 47; % number of subjects
col = 300; % length of x-axis
font_size = 7; % font size
font_name = 'Arial'; % font name
[~,high_PU,mid_PU,low_PU,~,~,darkblue_muted,~,~,~,~,light_gray,binned_dots,barface_green,...
    reg_color,~,~,~,~] = colors_rgb(); % colors
neutral = [7, 53, 94]/255;

betas_pupil = importdata("betas_behvresidual_abs_pecondiff_nomain_linearInt.mat");
perm = importdata("perm_betas_behvresidual_abs_pecondiff_nomain_linearInt.mat");
posterior = importdata("BSarousal_interactions_linearInt.mat");

%% TILED LAYOT

figure("Position",[200,200,450,350])
hold on
t = tiledlayout(2,2,"TileSpacing","compact");
ax1 = nexttile(3);
ax2 = nexttile(4);
ax3 = nexttile(1);
ax4 = nexttile(2);

%% PLOT COEFFICIENTS

% POSITION CHANGE
change = [-0.02,0.02,0,0];
new_pos = change_position(ax3,change);
ax3_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax3_new, 'off'); % remove box
delete(ax3); % delete old axis

% GET POSITION TO PLOT P-VALUE
ylim_axes = [-0.05,0.01];
[pval_pos] = create_pvalpos(ylim_axes);

for s = 1:num_subjs
    for c = 1:col
        data_plot(s,c) = betas_pupil.with_intercept(1,5,s,c);
    end
end
coeffs = data_plot;

% PLOT
hold on 
plot(xaxis,nanmean(coeffs),"Color",neutral,"LineStyle","-","LineWidth",linewidth_curves);
hold on
shadedErrorBar(xaxis,nanmean(coeffs),nanstd(coeffs)./sqrt(num_subjs), ...
    {'Color',neutral,'LineWidth',linewidth_curves},1);
hold on
plot(xaxis(find(perm.mask(5,:)==1)), -0.003*ones(1,length(xaxis(find(perm.mask(5,:)==1)))), '.', 'color', ...
    [119, 119, 119]./255, 'markersize', 4);
text(mean(xaxis(perm.mask(5,:) == 1)),-0.003 + pval_pos,"\itp\rm < 0.01","FontName",font_name,"FontSize", ...
    font_size,"VerticalAlignment","bottom","HorizontalAlignment","center")

% ADJUST FIGURE PROPERTIES
xline(0,'LineStyle','--','LineWidth',0.5);
yline(0,'LineStyle','--','LineWidth',0.5);
adjust_figprops(ax3_new,font_name,font_size,linewidth_plot);
hold on
xlim([-300,2700])
xlabel('Time since feedback onset (ms)')
ylabel('Uncertainty-modulated pupil','FontWeight','normal','FontName',font_name,'FontSize',font_size)

%% PLOT INTERACTIONS

% POSITION CHANGE
change = [0.02,0.02,0,0];
new_pos = change_position(ax4,change);
ax4_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax4_new, 'off'); % remove box
delete(ax4); % delete old axis

% PLOT
hold on 
plot(xaxis,nanmean(posterior.lowarousal_lowcondiff),"LineWidth",2,'LineStyle','--','Color','none')
plot(xaxis,nanmean(posterior.lowarousal_highcondiff),"LineWidth",2,'LineStyle','--','Color','none')
plot(xaxis,nanmean(posterior.higharousal_lowcondiff),"LineWidth",1,'LineStyle','-','Color',high_PU)
plot(xaxis,nanmean(posterior.higharousal_highcondiff),"LineWidth",1,'LineStyle','-','Color',low_PU)

shadedErrorBar(xaxis,nanmean(posterior.lowarousal_lowcondiff),nanstd(posterior.lowarousal_lowcondiff)./sqrt(num_subjs),{'LineWidth',2,"Color",high_PU,'LineStyle','--'},1)
shadedErrorBar(xaxis,nanmean(posterior.lowarousal_highcondiff),nanstd(posterior.lowarousal_highcondiff)./sqrt(num_subjs),{'LineWidth',2,"Color",low_PU,'LineStyle','--'},1)
shadedErrorBar(xaxis,nanmean(posterior.higharousal_lowcondiff),nanstd(posterior.higharousal_lowcondiff)./sqrt(num_subjs),{'LineWidth',2,"Color",high_PU},1)
shadedErrorBar(xaxis,nanmean(posterior.higharousal_highcondiff),nanstd(posterior.higharousal_highcondiff)./sqrt(num_subjs),{'LineWidth',2,"Color",low_PU},1)

% ADJUST FIGURE PROPERTIES
% l = legend('','','High arousal-high uncertainty','High arousal-low uncertainty','','Low arousal-high uncertainty','','Low arousal-low uncertainty','','','','','','Location','best','EdgeColor', ...
%     'none','AutoUpdate','off','Color','none','FontName',font_name,'FontSize',font_size);
l = legend('','','High arousal-high uncertainty','High arousal-low uncertainty','','Low arousal-high uncertainty','','Low arousal-low uncertainty','','','','','', ...
    'Location','best','EdgeColor','none','AutoUpdate','off','Color','none','FontName',font_name,'FontSize',font_size);
l.ItemTokenSize = [20, 20];
xlabel('Time since feedback onset (ms)')
ylabel('Model predicted absolute UP')
adjust_figprops(ax4_new,font_name,font_size,linewidth_plot);
hold on
xlim([-300,2700])
% ylim([-0.02,0.12])
%% PLOT COEFFICIENTS

% POSITION CHANGE
change = [-0.02,0,0,0];
new_pos = change_position(ax1,change);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax1_new, 'off'); % remove box
delete(ax1); % delete old axis

for s = 1:num_subjs
    for c = 1:col
        data_plot(s,c) = betas_pupil.with_intercept(1,4,s,c);
    end
end
coeffs = data_plot;

% PLOT
hold on 
plot(xaxis,nanmean(coeffs),"Color",neutral,"LineStyle","-","LineWidth",linewidth_curves);
hold on
shadedErrorBar(xaxis,nanmean(coeffs),nanstd(coeffs)./sqrt(num_subjs), ...
    {'Color',neutral,'LineWidth',linewidth_curves},1);
hold on
plot(xaxis(find(perm.mask(4,:)==1)), -0.003*ones(1,length(xaxis(find(perm.mask(4,:)==1)))), '.', 'color', ...
    [119, 119, 119]./255, 'markersize', 4);
text(mean(xaxis(perm.mask(4,:) == 1)),-0.011,"\itp\rm < 0.01","FontName",font_name,"FontSize", ...
    font_size,"VerticalAlignment","bottom","HorizontalAlignment","center")

% ADJUST FIGURE PROPERTIES
xline(0,'LineStyle','--','LineWidth',0.5);
yline(0,'LineStyle','--','LineWidth',0.5);
adjust_figprops(ax1_new,font_name,font_size,linewidth_plot);
hold on
xlim([-300,2700])
xlabel('Time since feedback onset (ms)')
ylabel('PE-modulated pupil','FontWeight','normal','FontName',font_name,'FontSize',font_size)

%% PLOT COEFFICIENTS

% POSITION CHANGE
change = [0.02,0,0,0];
new_pos = change_position(ax2,change);
ax2_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax2_new, 'off'); % remove box
delete(ax2); % delete old axis

for s = 1:num_subjs
    for c = 1:col
        data_plot(s,c) = betas_pupil.with_intercept(1,6,s,c);
    end
end
coeffs = data_plot;

% PLOT
hold on 
plot(xaxis,nanmean(coeffs),"Color",neutral,"LineStyle","-","LineWidth",linewidth_curves);
hold on
shadedErrorBar(xaxis,nanmean(coeffs),nanstd(coeffs)./sqrt(num_subjs), ...
    {'Color',neutral,'LineWidth',linewidth_curves},1);
hold on
plot(xaxis(find(perm.mask(6,:)==1)), -0.003*ones(1,length(xaxis(find(perm.mask(6,:)==1)))), '.', 'color', ...
    [119, 119, 119]./255, 'markersize', 4);
text(mean(xaxis(perm.mask(6,:) == 1)),-0.008,"\itp\rm < 0.01","FontName",font_name,"FontSize", ...
    font_size,"VerticalAlignment","bottom","HorizontalAlignment","center")

% ADJUST FIGURE PROPERTIES
xline(0,'LineStyle','--','LineWidth',0.5);
yline(0,'LineStyle','--','LineWidth',0.5);
adjust_figprops(ax2_new,font_name,font_size,linewidth_plot);
hold on
xlim([-300,2700])
xlabel('Time since feedback onset (ms)')
ylabel('Uncertainty and PE-modulated pupil','FontWeight','normal','FontName',font_name,'FontSize',font_size)

%% ADD SUBPLOT LABELS

ax1_pos = ax1_new.Position;
adjust_x = -0.09; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.02; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(ax1_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',12,'LineStyle','none','HorizontalAlignment','center','VerticalAlignment','top')

[label_x,label_y] = change_plotlabel(ax2_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'd','FontSize',12,'LineStyle','none','HorizontalAlignment','center','VerticalAlignment','top')

[label_x,label_y] = change_plotlabel(ax3_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center','VerticalAlignment','top')

[label_x,label_y] = change_plotlabel(ax4_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center','VerticalAlignment','top')
%% SAVE AS PNG

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'absresiduals_full2_linearInt1.png', '-dpng', '-r600') 