% figure4 plots model-based analysis of pupil data.

clc
clearvars

% INITIALIZE VARS

fontname = 'Arial'; % font name
fontsize = 7; % font size
linewidth_plot = 0.5; % line width for plot
linewidth_curves = 2; % line width for curves
xaxis = linspace(-300,2700,300); % x-axis
num_subjs = 47; % number of subjects
[~,high_PU,mid_PU,low_PU,~,~,~,~,~,~,~,~,binned_dots,~,...
    ~,~,~,~,study2_blue] = colors_rgb(); % colors
neutral = [7, 53, 94]/255;
num_subs = 47;
col = 300;

% GET BETAS

betas = importdata("pe_condiff_mathot.mat");
for s = 1:num_subs
    for c = 1:col
        coeffs.pe(s,c) = betas.with_intercept(1,5,s,c);
        coeffs.pe_condiff(s,c) = betas.with_intercept(1,8,s,c);
        coeffs.up(s,c) = betas.with_intercept(1,6,s,c);
    end
end
posterior = importdata("BSweightedPE_interactions.mat");
perm = importdata("perm_pe_condiff.mat"); 
pe_pval = perm.mask(5,:);
pecondiff_pval = perm.mask(8,:);

%% INITIALIZE TILE LAYOUT

figure("Position",[200,200,600,200])
hold on
t = tiledlayout(1,3,"Padding","compact","TileSpacing","compact");
ax1 = nexttile(1,[1,1]);
ax2 = nexttile(2,[1,1]);
ax3 = nexttile(3,[1,1]);

sg = sgtitle('Pupil dilation = \beta_0 + \beta_1 \cdot |\delta| + \beta_2 \cdot |\delta| \cdot |Contrast difference| + \beta_3 \cdot |Update| + ... + \epsilon', ...
    'Interpreter','Tex','FontSize',8,'FontName','Arial');

%% PLOT MAIN EFFECT OF PE

% POSITION CHANGE

new_pos = change_position(ax1,[0,0,0.002,0]);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos); % new position
delete(ax1);

% GET POSITION TO PLOT P-VALUE 

ylim_axes = [-0.04,0.05];
%ylim_axes = [0,80];
[pval_pos] = create_pvalpos(ylim_axes);

% PLOT

hold on 
plot(xaxis,nanmean(smoothdata(coeffs.pe,2,"movmean")),"Color",neutral,"LineStyle","-","LineWidth",linewidth_curves);
hold on
shadedErrorBar(xaxis,nanmean(smoothdata(coeffs.pe,2,"movmean")),nanstd(smoothdata(coeffs.pe,2,"movmean"))./sqrt(num_subjs), ...
    {'Color',neutral,'LineWidth',linewidth_curves},1);
hold on
xline(0,'LineStyle','--','LineWidth',0.5);
yline(0,'LineStyle','--','LineWidth',0.5);

% ADJUST FIGURE PROPERTIES

adjust_figprops(ax1_new,fontname,fontsize,linewidth_plot);
hold on
plot(xaxis(find(pe_pval==1)),pval_pos + -0.01*ones(1,length(pe_pval(pe_pval == 1))), '.', 'color', ...
    [119, 119, 119]./255, 'markersize', 4);
xlim([-300,2700])
% ylim(ylim_axes)
xlabel('Time since feedback onset (ms)')
ylabel('Absolute PE modulated pupil ({\bf\beta_1})','FontWeight','normal','FontName',fontname,'FontSize',fontsize)
text(mean(xaxis(pe_pval == 1)),pval_pos + -0.01,"\itp\rm < 0.001","FontName",fontname,"FontSize", ...
    fontsize,"VerticalAlignment","bottom","HorizontalAlignment","center")

%% PLOT BS-WEIGHTED PE

% POSITION CHANGE

new_pos = change_position(ax2,[0.015,0,0.002,0]);
ax2_new = axes('Units', 'Normalized', 'Position', new_pos); % new position
delete(ax2);
ylim_axes = [-0.01,0.023];
% ylim_axes = [-15,35];
[pval_pos] = create_pvalpos(ylim_axes);

% PLOT

hold on 
plot(xaxis,nanmean(smoothdata(coeffs.pe_condiff,2,"movmean")),"Color",neutral,"LineStyle","-","LineWidth",linewidth_curves);
hold on
shadedErrorBar(xaxis,nanmean(smoothdata(coeffs.pe_condiff,2,"movmean")),nanstd(smoothdata(coeffs.pe_condiff,2,"movmean"))./sqrt(num_subjs), ...
    {'Color',neutral,'LineWidth',linewidth_curves},1);
hold on

% ADJUST FIGURE PROPERTIES

xline(0,'LineStyle','--','LineWidth',0.5);
yline(0,'LineStyle','--','LineWidth',0.5);
adjust_figprops(ax2_new,fontname,fontsize,linewidth_plot);
hold on
plot(xaxis(find(pecondiff_pval==1)), pval_pos + -0.003*ones(1,length(pecondiff_pval(pecondiff_pval == 1))), '.', 'color', ...
    [119, 119, 119]./255, 'markersize', 4);
xlim([-300,2700])
% ylim(ylim_axes)
xlabel('Time since feedback onset (ms)')
% ylabel('BS-weighted-PE (\beta_2)','FontWeight','normal','FontName',fontname,'FontSize',fontsize)
ylabel('BS-weighted-PE ({\bf\beta_2})','FontWeight','normal','FontName',fontname,'FontSize',fontsize)
text(mean(xaxis(pecondiff_pval == 1)),pval_pos + -0.003,"\itp\rm = 0.02","FontName",fontname,"FontSize", ...
    fontsize,"VerticalAlignment","bottom","HorizontalAlignment","center")

%% ADD POSTERIOR CURVES

% POSITION CHANGE

new_pos = change_position(ax3,[0.035,0,0.002,0]);
ax3_new = axes('Units', 'Normalized', 'Position', new_pos); % new position
delete(ax3);

% PLOT

hold on 
plot(xaxis,nanmean(smoothdata(posterior.highPU,2,"movmean")),'Color',high_PU,'LineWidth',1.5)
plot(xaxis,nanmean(smoothdata(posterior.midPU,2,"movmean")),'Color',mid_PU,'LineWidth',1.5)
plot(xaxis,nanmean(smoothdata(posterior.lowPU,2,"movmean")),'Color',low_PU,'LineWidth',1.5)

% ADJUST FIGURE PROPERTIES

l = legend('High state uncertainty','Mid state uncertainty','Low state uncertainty','Location','best','EdgeColor', ...
    'none','AutoUpdate','off','FontSize',fontsize,'FontName',fontname,'Color','none');
l.ItemTokenSize = [7 7];
set(gca,'Color','none','FontName','Arial','FontSize',8)
xline(0,'--','LineWidth',0.5)
yline(0,'--','LineWidth',0.5)
xlim([-300,2700])
% ylim([-0.03,0.09])
xlabel('Time from feedback onset (ms)')
ylabel('Posterior pupil dilation (a.u.)')
hold on
a1 = annotation("arrow",[0.78,0.78],[0.67,0.77],'LineWidth',0.5,'Color',low_PU);
a2 = annotation("arrow",[0.78,0.78],[0.63,0.53],'LineWidth',0.5,'Color',high_PU);
a1.HeadLength = 5; a2.HeadLength = 5;
adjust_figprops(ax3_new,fontname,fontsize,linewidth_plot);

%% ADD SUBPLOT LABELS

ax1_pos = ax1_new.Position;
adjust_x = -0.065; % adjusted x-position for subplot label
adjust_y = ax1_pos(4)+0.05; % adjusted y-position for subplot label
[label_x,label_y] = change_plotlabel(ax1_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax2_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

[label_x,label_y] = change_plotlabel(ax3_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',12,'LineStyle','none','HorizontalAlignment','center')
%% SAVE

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'regression_pupil8.png', '-dpng', '-r600') 