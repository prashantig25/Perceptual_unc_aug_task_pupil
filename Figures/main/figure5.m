% figure5 plots results from the arousal and learning analysis.

clc
clearvars

linewidth_plot = 0.5; % line-width for plot
linewidth_curves = 2; % line-width for curves
xaxis = linspace(-300,2700,300); % x-axis
num_subjs = 47; % number of subjects
col = 300; % length of x-axis
line_width = 0.5; % line width for axes
font_size = 7; % font size
font_name = 'Arial'; % font name
[~,high_PU,mid_PU,low_PU,~,~,darkblue_muted,~,~,~,~,light_gray,binned_dots,barface_green,...
    reg_color,~,~,~,~] = colors_rgb(); % colors
neutral = [7, 53, 94]/255;

colors_name = darkblue_muted;
betas_pupil = importdata("betas_behvresidual_abs_pecondiff_nomain.mat");
perm = importdata("perm_betas_behvresidual_abs_pecondiff_nomain.mat");

%% TILE LAYOUT

figure("Position",[200,200,370,200])
hold on
t = tiledlayout(1,2,"Padding","compact","TileSpacing","compact");
ax1 = nexttile(1);
ax2 = nexttile(2);

sgtitle('|Update| = \beta_0 + \beta_1 \cdot |Posterior update| + \beta_2 \cdot Pupil + ... + \epsilon', ...
    'Interpreter','Tex','FontSize',8,'FontName','Arial')
%% PLOT COEFFS FOR POSTERIOR UPDATES

% POSITION CHANGE
change = [0.1,0.005,-0.2,0];
new_pos = change_position(ax1,change);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax1_new, 'off'); % remove box
delete(ax1); % delete old axis

% PLOT
for s = 1:num_subjs
    for c = 1:col
        data_plot(s,c) = betas_pupil.with_intercept(1,2,s,c);
    end
end
coeffs = nanmean(data_plot,2);
[avg,sd,coeffs] = prepare_betas(coeffs,1,num_subjs);
h = bar_plots_pval(coeffs,avg,sd,num_subjs, ...
        1,1,{'','Example participant','Normative agent'}, ...
        xticks,{'','',''},"\itp\rm < 0.001",'','Posterior update',0,1, ...
        10,1,font_size,linewidth_plot,font_name,0,colors_name,{'*'},0.1);
h.BarWidth = 0.4;
ylim_vals = [0 0.85];
xlim_vals = [0.5 1.5];
adjust_figprops(ax1_new,font_name,font_size,line_width,xlim_vals,ylim_vals);
%%

% POSITION CHANGE
change = [-0.05,0.005,0.01,0];
new_pos = change_position(ax2,change);
ax2_new = axes('Units', 'Normalized', 'Position', new_pos); % update
box(ax2_new, 'off'); % remove box
delete(ax2); % delete old axis

% GET POSITION FOR P-VALUE
ylim_axes = [-0.02,0.08];
[pval_pos] = create_pvalpos(ylim_axes);

for s = 1:num_subjs
    for c = 1:col
        data_plot(s,c) = betas_pupil.with_intercept(1,3,s,c);
    end
end
coeffs = data_plot;

% PLOT
hold on 
plot(xaxis,nanmean(smoothdata(coeffs,2,"movmean")),"Color",neutral,"LineStyle","-","LineWidth",linewidth_curves);
hold on
shadedErrorBar(xaxis,nanmean(smoothdata(coeffs,2,"movmean")),nanstd(smoothdata(coeffs,2,"movmean"))./sqrt(num_subjs), ...
    {'Color',neutral,'LineWidth',linewidth_curves},1);
hold on
xline(0,'LineStyle','--','LineWidth',0.5);
yline(0,'LineStyle','--','LineWidth',0.5);
adjust_figprops(ax2_new,font_name,font_size,linewidth_plot);
hold on
plot(xaxis(find(perm.mask(3,:)==1)), -0.003*ones(1,length(xaxis(find(perm.mask(3,:)==1)))), '.', 'color', ...
    [119, 119, 119]./255, 'markersize', 4);
xlim([-300,2700])
% ylim([-0.02,0.08])
xlabel('Time since feedback onset (ms)')
ylabel('Pupil dilation','FontWeight','normal','FontName',font_name,'FontSize',font_size)
text(mean(xaxis(perm.mask(3,:) == 1)),pval_pos + -0.003,"\itp\rm = 0.009","FontName",font_name,"FontSize", ...
    font_size,"VerticalAlignment","bottom","HorizontalAlignment","center")

%% ADD SUBPLOT LABELS

ax1_pos = ax1_new.Position;
adjust_x = -0.095; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.04; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(ax1_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center','VerticalAlignment','top')

[label_x,label_y] = change_plotlabel(ax2_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center','VerticalAlignment','top')

%% SAVE

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'residuals_pupil6.png', '-dpng', '-r600') 