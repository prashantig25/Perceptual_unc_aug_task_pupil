% figure2 plots task, choice and learning behavior.

% INITIALISE VARIABLES

clc
clearvars
linewidth_arrow = 0.5; % arrow width
headlength_arrow = 5; % arrow headlength
font_name = 'Arial'; % font name
horz_align = 'center'; % alignment
vert_align = 'middle';
bg_color = 'none'; % background color for text boxes
face_alpha = 0; % face alpha
edge_color = 'none'; % edge color for text boxes
trialtext_width = 0.1; % width for trial text
trialtext_height = 0.1;
screen_width = 3./2; % screen dimensions for trial
screen_height = 2./2;
linewidth_screens = 0.7; % line width for screens
fontsize_title = 9; % font size for plot titles
linewidth_axes = 0.5; % line width for axes
linewidth_box = 0.25; % line width for boxes
font_size = 7; % font size
fontsize_label = 12; % font size for subplot labels
line_style = '-'; % line style
[~,high_PU,mid_PU,low_PU,color_screen,fb_green,darkblue_muted,mix,perc,rew,~,~,binned_dots,~,...
    ~,~,~,~,~] = colors_rgb(); % colors
num_subjs = 46; % number of subjects
line_width = 0.5; % line width for plots 
example_participant = 20; % example participant for plots
model3 = 'up ~ pe + pe:contrast_diff + pe:congruence + pe:pe_sign + pe:salience';
mdl = model3; % which regression model
pred_vars = {'pe','salience','contrast_diff','congruence','condition','reward_unc','subj_est_unc' ...
        ,'reward','mu','pe_sign','pu'}; % cell array with names of predictor variables
resp_var = 'up'; % name of response variable
cat_vars = {'salience','congruence','condition','reward_unc','pe_sign'}; % cell array with names of categorical variables
num_vars = 5; % number of variables
weight_y_n = 0; % weighted regression
save_csv = 1; % save stats for 1(d) in CSV file for overleaf

descriptive_path = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\data\GB data\behavior\descriptive";
regression_path = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\Perceptual_unc_aug_task_pupil-main\data\GB data\behavior\LR analyses";

% load all required data
mix_curve = importdata(fullfile(descriptive_path,"mix_curve.mat")); % learning curves
perc_curve = importdata(fullfile(descriptive_path,"perc_curve.mat"));
mean_curves(1,:) = nanmean(mix_curve);mean_curves(2,:) = nanmean(perc_curve);
sem_curves(1,:) = nanstd(mix_curve)./sqrt(num_subjs);sem_curves(2,:) = nanstd(perc_curve)./sqrt(num_subjs);
data_subjs = readtable(fullfile(regression_path,"preprocessed_lr_pupil_no_zerope.xlsx")); % preprocessed LR data
betas_all = importdata(fullfile(regression_path,"betas_signed.mat")); % betas from signed analysis
[~,p_vals] = ttest(betas_all);
id_subjs = unique(data_subjs.id); % subject IDs
%% INITIALISE TILE LAYOUT

figure
set(gcf,'Position',[100 100 600 400])
t = tiledlayout(3,8);
t.Padding = 'compact';
t.TileSpacing = 'compact';
ax3 = nexttile(5,[2 4]);
ax5 = nexttile(17,[1 2]);
ax10 = nexttile(19,[1 2]);
ax12 = nexttile(21,[1,1]);
ax11 = nexttile(22,[1,1]);
ax15 = nexttile(23,[1,2]);
ax1 = nexttile(1,[2,4]);
%% PLOT TRIAL PROCEDURE

% POSITION CHANGE
position_change = [0, 0.03, -0.05, 0]; % change in position
new_pos = change_position(ax1,position_change); 
ax1_new = axes('Units', 'Normalized', 'Position', new_pos); % new position
box(ax1_new, 'on'); % box on
delete(ax1); % delete old axis

start_x = 0.5; % start-x for screens
start_y = 8;
adjust_x = 2.3./2; % adjustments for screens
adjust_y = -1.8./2;
num_screens = 8; % number of screens
screens_y = [];

% PLOT SCREENS
for n = 1:num_screens
    rectangle('Position',[start_x start_y screen_width screen_height],'LineWidth',linewidth_screens, ...
        'FaceColor',[200,200,200]./255)
    screens_y = [screens_y,start_y];
    start_x = start_x + adjust_x;
    start_y = start_y + adjust_y;
    axis([0 11 0 11]);
end

% PLOT SLIDER
line([8.7,9.9],[2,2],'color','k','LineWidth',1)
center_X = 9.5;  % X-coordinate of the center
center_Y = 2.0;  % Y-coordinate of the center
radius = 0.17./2;   % Radius of the circle
rectangle('Position', [center_X - radius, center_Y - radius, 2 * radius, 2 * radius], ...
    'Curvature', [1, 1], 'EdgeColor', 'k', 'FaceColor', 'w', 'LineWidth', 0.5);

% PLOT FIXATION DOT
fix_width = 0.08;
fix_height = 0.2;
fix_xpos = [2,3.1,4.3,5.4,6.6,7.7,8.9,10] - 0.7;
fix_ypos = [9.2,8.3,7.4,6.5,5.6,4.7,3.8,3] - 0.7;
num_fix = 8;
radius = 0.06./2;   % Radius of the circle
for n = [1:4,5,7,num_fix]
    if n == 4
        rectangle('Position',[4.7 5.75 0.06 0.06],'EdgeColor', 'k', 'FaceColor', 'k')
    else
        rectangle('Position', [fix_xpos(n) - radius fix_ypos(n) - radius, 2 * radius, 2 * radius], ...
        'Curvature', [1, 1], 'EdgeColor', 'k', 'FaceColor', 'k');
    end
end

% PLOT ARROW 
ar1 = annotation('arrow','LineWidth',linewidth_arrow,'HeadLength',headlength_arrow);
ar1.Parent = ax1_new;
ar1.X = [1 6];
ar1.Y = [6,2];

% ADD TEXTBOXES
all_strings = {{'Fixation (1.6-2.1s)', ''},{'Choice options (0.5s)' ,''},{'Delay (0.2-0.5s)', ''},{'Go cue (1s)'},{'Delay (0.5-1s)', ''},{'Feedback (0.25s)', ''},{'Delay (0.5-1s)', ''},{'Slider (7s)', ''}};
num_strings = 8;
text_xpos = [2.3,3.45,4.6,5.75,6.9,8.05,9.2,10.35]-0.1;
text_ypos = [8.9,8,7.1,6.2,5.3,4.4,3.5,2.6] + 0.1;
horzalign_trial = 'Left';
vertalign_trial = 'Top';
for n = 1:num_strings
    str = all_strings{1,n};
    position = [text_xpos(n) text_ypos(n) trialtext_width trialtext_height];
    annotate_textbox(ax1_new,position,str,font_name,font_size, ...
        horzalign_trial,vertalign_trial,bg_color,face_alpha,'none');
end

set(gca, 'Color', 'None')
box off
axis off
%% PLOT S-A-R CONTINGENCY

% POSITION CHANGE
pos = ax3.Position + [0, 0,0,0];
ax3_new = axes('Units', 'Normalized', 'Position', pos);
box(ax3_new, 'on');
delete(ax3);

axis([0 1 0 1])
title('Task contingency','FontWeight','normal',FontName=font_name,Position=[0.5,0.95], ...
    Parent=ax3_new,FontSize=fontsize_title)
line([0 1], [0.89 0.89],'Color','k','LineWidth',linewidth_axes);

% ADD TEXTBOXES
all_strings = {'State 0','State 1'};
num_strings = 2;
text_xpos = [0.23, 0.68] - 0.01;
text_ypos = [0.86, 0.86];
statebox_width = 0.1;
for n = 1:num_strings
    str = all_strings(n);
    position = [text_xpos(n) text_ypos(n) statebox_width statebox_width];
    annotate_textbox(ax3_new,position,str,font_name,font_size, ...
        horz_align,vert_align,bg_color,face_alpha,edge_color);
end

% ADD TEXT BOXES
all_strings = {'Right stronger','Left stronger'};
text_xpos = text_xpos - 0.07;
text_ypos = text_ypos - 0.06;
box_width = 0.25; 
box_height = 0.08;
for n = 1:num_strings
    str = all_strings(n);
    position = [text_xpos(n) text_ypos(n) box_width box_height];
    annotate_textbox(ax3_new,position,str,font_name,font_size, ...
        horz_align,vert_align,bg_color,face_alpha,edge_color);
end

all_strings = {'Left    Right','Left    Right','\mu = 0.7','\mu = 0.7','0.7      0.3','0.3      0.7'};
num_strings = 6;
text_xpos = [0.145, 0.6, 0.145, 0.6, 0.145, 0.6, 0.145, 0.6];
text_ypos = [0.5, 0.5, 0.335, 0.335, 0.27, 0.27, 0.73, 0.73];
edge_colors = {'k','k','none','none','k','k'};
bg_colors = {bg_color, bg_color, [238, 238, 238]/256, [238, 238, 238]/256, bg_color, bg_color};
for n = 1:num_strings
    str = all_strings(n);
    position = [text_xpos(n) text_ypos(n) box_width box_height];
    annotate_textbox(ax3_new,position,str,font_name,font_size, ...
        horz_align,vert_align,bg_colors{n},face_alpha,edge_colors{n},linewidth_box,line_style);
end

% ADD ROTATED TEXT BOXES
xpos = 0.01;
ypos = [0.55,0.3,0.8];
allstrings = {{'Economic', 'choice'},{'Contingency' 'parameter'},{'', 'Stimulus'}};
num_strings = 3;
for n = 1:num_strings
    txt = text(xpos,ypos(n),allstrings{1,n});
    txt.FontSize = font_size;
    txt.FontWeight = 'normal';
    txt.Rotation = 90;
    txt.LineStyle = 'none';
    txt.FontName = font_name;
    txt.HorizontalAlignment = horz_align;
end

% ADD ARROWS
annotation("textbox",[0.145,0.73,0.25,0.08],'LineWidth',linewidth_box,'String', ...
    '','FontSize',font_size,'LineStyle','-','Color','k','FontName','Arial', ...
    'HorizontalAlignment','center',Parent=gca)

annotation("textbox",[0.6,0.73,0.25,0.08],'LineWidth',linewidth_box,'String', ...
    '','FontSize',font_size,'LineStyle','-','Color','k','FontName','Arial', ...
    'HorizontalAlignment','center',Parent=gca)

a1 = annotation('arrow',[0.5 0.5],[0.6 0.4],'LineWidth',0.7,'Color', ...
    'k','LineStyle','-','HeadLength',headlength_arrow);
a1.Parent = gca;
set(gca, 'Color', 'None','FontName','Arial')
box off
axis off
%% DESCRIPTIVE PLOTS

% POSITION CHANGE
position_change = [0, 0.05, -0.03, 0];
new_pos = change_position(ax5,position_change);
ax5_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax5_new, 'on');
delete(ax5);

addpath("C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\behv_manuscript\code\results")

% PLOT SLIDER DATA
colors_name = [mix;perc]; % colors for plot lines
legend_names = {'High reward uncertainty','Low reward uncertainty'}; % legend names
title_name = {'Learning curve'}; % figure title
xlabelname = {'Trial'}; % x-axis label name
ylabelname = {'Slider response'}; % y-axis label name
x = 1:20; % x-axis
hold on
lg_curves(x,mean_curves,sem_curves,colors_name,legend_names,title_name,xlabelname,ylabelname,font_size,1.5,'Arial')
xlim([1,20])
set(gca,'color','none','FontName',font_name,'FontSize',font_size,'LineWidth',linewidth_axes)
yline(0.9,'--',"Color",'k',LineWidth=0.5)
yline(0.7,'--',"Color",'k',LineWidth=0.5)
ylim([0.5,1])
annotation("textbox",[1,0.95,0.2,0.04],'LineWidth',linewidth_box,'String', ...
    ' Actual reward probability','FontSize',font_size,'LineStyle','none','Color','k','FontName','Arial', ...
    'HorizontalAlignment','left',Parent=gca)

new_pos = change_position(ax10,position_change);
ax10_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax10_new, 'off');
delete(ax10);

% INITIALISE VARS TO BE PLOTTED
binned_data = abs(data_subjs.con_diff); % absolute contrast difference
nbins = 10; % number of bins
bin_edges = prctile(binned_data, 0:10:100); % calculate percentile edges
bins = discretize(binned_data, bin_edges); % bin contrast differences 
data_subjs.lr = data_subjs.up./data_subjs.pe; % learning rates
data_subjs.abs_lr = abs(data_subjs.lr); % absolute learning rates

% GET RID OF TRIALS WHERE PE = 0 AND OUTLIER LRs
run_id = data_subjs.id(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
y_data = data_subjs.lr(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
bins = bins(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);
binned_data = binned_data(data_subjs.pe ~= 0 & abs(data_subjs.lr)<=2);

% MEAN LRs for CONDIFF BINS
avg_ydata_bins = NaN(nbins,num_subjs); 
avg_behv_bins = NaN(nbins,num_subjs); 
for b = 1:nbins
    for n = 1:num_subjs
        bins_subj = bins(run_id == id_subjs(n));
        y_data_subj = y_data(run_id == id_subjs(n));
        binned_data_subj = binned_data(run_id == id_subjs(n));
        avg_behv_bins(b,n) = nanmean(binned_data_subj(bins_subj == b));
        avg_ydata_bins(b,n) = nanmean(y_data_subj(bins_subj == b));
    end
end
avg_ydata = nanmean(avg_ydata_bins,2);
avg_binneddata = nanmean(avg_behv_bins,2);
sem_ydata = nanstd(avg_ydata_bins,0,2)./sqrt(num_subjs);

% PLOT
s1 = scatter(1:nbins,avg_ydata,"filled",'MarkerEdgeColor',"none",'MarkerFaceColor',"none");
ls = lsline;
ls.Color = 'k';
hold('on')
errorbar(1:nbins,avg_ydata, sem_ydata, 'k', 'LineWidth',line_width,'LineStyle','none');
hold on
s1 = scatter(1:nbins,avg_ydata,"filled",'MarkerEdgeColor',"k",'MarkerFaceColor',binned_dots);
xlabel("Contrast difference bins" + newline + "(1 bin = 0.01)")
ylabel('Mean learning rate (LR)')

% ADJUST FIGURE PROPERTIES
xlim_vals = [0 10.3];
ylim_vals = [-0.01 0.17];
adjust_figprops(ax10_new,font_name,font_size,line_width,xlim_vals,ylim_vals);
[rho,pval] = corr(avg_ydata,avg_binneddata, 'rows', 'pairwise');
title(strcat("\itr\rm = ",{' '},num2str(round(rho,2)),{' '}) + newline + "\itp\rm < 0.001", ...
    'FontWeight','normal','Interpreter','tex')
if save_csv == 1
    save_figures = "C:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\stats\behavior";
    save_table = table("subplot_d",round(rho,2),round(pval,3),8,'VariableNames',{'name','rho','pval','df'});
    writetable(save_table,strcat(save_figures,'\','figure1d.csv'));
end
%% PLOT BETA COEFFICIENTS

% INITIALISE VARS FOR PLOTTING COEFFICIENTS
regressors = [1,2]; % regressors that need to be plotted
axes_old = [ax12,ax11]; % names of old axes
ax11_new = ax11; % initialise new axes
ax12_new = ax12;
axes_new = [ax12_new,ax11_new];
position_change = [0, 0.05, -0.025, 0]; % position changes for each axes
adjust_position = 0.015;
ylim_lower = [-0.1,-0.1,-0.2]; % lower y-axis limit for each regressor
ylim_upper = [0.5,0.35,0.6]; % upper y-axis limit for each regressor
xlabelname = {''}; % x-axis label
ylabelname = {'Fixed LR','Belief-state-adapted LR','Confirmation bias'}; % y-axis label name for each regressor
disp_pval = 0; % if p-val stars should be displayed on top of bars
scatter_dots = 1; % if single participant data should be scattered on top of bar
dot_size = 10; % scatter dot size
plot_err = 1; % if error bar should be plotted
disp_legend = [0,1,0]; % if legend should be displayed
xticklabs = {''}; % x-tick labels
y_label = 1; % if p-val stars to be displayed, initialise y-axis locationC:\Users\prash\Nextcloud\Thesis_laptop\Semester 8\pupil_manuscript\preprocessed_eventnames\pupil_signal\baseline corrected\fb

% PLOT
for r = 1:length(regressors)

    % CHANGE AXES POSITION
    new_pos = change_position(axes_old(r),position_change);
    axes_new(r) = axes('Units', 'Normalized', 'Position', new_pos);
    box(axes_new(r), 'off');
    delete(axes_old(r));
    
    % GET MEAN AND SEM FOR BETAS
    selected_regressors = regressors(r);
    [mean_avg,mean_sd,coeffs_subjs] = prepare_betas(betas_all,selected_regressors,num_subjs);
    
    % GET STARS FOR CORRESPONDING REGRESSOR'S P-VALUES
    bar_labels = {'*'};
    pstars = pvals_stars(p_vals,selected_regressors,bar_labels,0);
    title_name = string(pstars) + newline + " ";
    colors_name = darkblue_muted;
       
    hold on
    h = bar_plots_pval(coeffs_subjs,mean_avg,mean_sd,num_subjs, ...
        length(selected_regressors),1,{'Empirical data','Example participant'}, ...
        xticks,xticklabs,title_name,xlabelname,ylabelname(r),disp_pval,scatter_dots, ...
        dot_size,plot_err,font_size,line_width,font_name,disp_legend(r),colors_name, ...
        bar_labels,y_label,[NaN,NaN],[0.5,1.5],example_participant);
    h.BarWidth = 0.4; 
    ylim_vals = [ylim_lower(r) ylim_upper(r)];
    xlim_vals = [0.5 1.5];
    adjust_figprops(axes_new(r),font_name,font_size,line_width,xlim_vals,ylim_vals);
end

%% ADD AN INTERACTION PLOT

data = data_subjs;
% FIT THE MODEL
for i = example_participant
    tbl = table(data.pe(and(data.id == id_subjs(i),data.pe ~= 0)), ...
        data.up(and(data.id == id_subjs(i),data.pe ~= 0)), ...
        round(data.norm_condiff(and(data.id == id_subjs(i),data.pe ~= 0)),2), ...
        data.contrast(and(data.id == id_subjs(i),data.pe ~= 0)),...
        data.condition(and(data.id == id_subjs(i),data.pe ~= 0)),...
        data.congruence(and(data.id == id_subjs(i),data.pe ~= 0)),...
        data.reward_unc(and(data.id == id_subjs(i),data.pe ~= 0)),...
        data.pe_sign(and(data.id == id_subjs(i),data.pe ~= 0)),...
        'VariableNames',{'pe','up','contrast_diff','salience','condition','congruence' ...
        ,'reward_unc','pe_sign'});
    
    [~,~,~,~,lm] = linear_fit(tbl,mdl,pred_vars,resp_var, ...
        cat_vars,num_vars,weight_y_n);
end

% POSITION CHANGE
position_change = [0, 0.05, -0.03, 0]; 
new_pos = change_position(ax15,position_change);
ax15_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax15_new, 'off');
delete(ax15);

% INTERACTION PLOT
hold on
h = plotInteraction(lm,'contrast_diff','pe','predictions');
h(3).Color = low_PU;
h(2).Color = mid_PU;
h(1).Color = high_PU;
xlabel('Prediction error')
title('Update','FontWeight','normal')
ylabel('')
adjust_figprops(ax15_new,font_name,font_size,line_width);
l = legend('Contrast difference','0','0.5','1','Location','best','AutoUpdate','off');
l.EdgeColor = 'none';
l.Color = 'none';
l.ItemTokenSize = [7 7];
box off
xline(0,"LineWidth",0.5,LineStyle="--")
yline(0,"LineWidth",0.5,LineStyle="--")
%% ADD EXTERNAL PNGs

patch_dim = 0.035; % dimensions for patch
pos_y = 0.7825 + 0.03; % position of patches on y-axis
pos_x = [0.65,0.605,0.84,0.795]; % position of patches on x-axis
image_png = {'highcon.png','lowcon_02.png','lowcon_02.png','highcon.png'};
num_pngs = 4;
for n = 1:num_pngs
    axes('pos',[pos_x(n) pos_y patch_dim patch_dim]);
    imshow(image_png{n});
    hold on
end

patch_dim = 0.03;
pos_y = 0.768 + 0.03; pos_x = 0.123-0.006;
image_png = {'lowcon.png','highcon.png'};
num_pngs = 2;
adjust_x = 0.0275;
for n = 1:num_pngs
    axes('pos',[pos_x pos_y patch_dim patch_dim]);
    imshow(image_png{n});
    hold on
    pos_x = pos_x + adjust_x;
end

patch_dim = 0.02;
pos_y = [0.68,0.615]-0.003; pos_x = [0.221,0.297]-0.001;
num_pngs = 2;
adjust_x = 0.025;
for n = 2%:num_pngs
    axes('pos',[pos_x(n) pos_y(n) 0.015 patch_dim]);
    [img, ~, tr] = imread('audio_fb.png');
    im = image('CData',img);
    im.AlphaData = tr;
    set(gca,'YDir','reverse');
    set(gca,'color','none');
    set(gca,'XColor', 'none','YColor','none');
    hold on
end

% CREATE BARS
bar_width = 0.08; % width for bar plot
bar_height = 0.1; % height for bar plot
xpos = 0.42; % x-position
ypos = [0.8,0.08] - 0.025; % y-position
bar_data = [70,90]; % bar data
ylabel_strings = {'','Value'}; % strings for y
num_plots = 1;
for n = 1:num_plots
    axes('pos',[xpos ypos(n) bar_width bar_height])
    set(gca,'XColor', 'none','YColor','none')
    b = bar(bar_data(n,:),'BarWidth',0.5,'FaceAlpha',0.7,'LineWidth',0.5);
    b.FaceColor = 'flat';
    b.CData(1,:) = [0.5,0.5,0.5];
    b.CData(2,:) = [0.5,0.5,0.5];
    ylim([50,100])
    yticks([50,100])
    yticklabels(["50","100"])
    xlim([-0.05,3.05])
    xticks([1,2])
    set(gca,'color','none','LineWidth',linewidth_axes,'FontName',font_name)
    set(gca,'Xticklabel',["High","Low"],'FontSize',font_size,'Yticklabel',["50","100"])
    title(["Reward","uncertainty"],"FontWeight","normal","FontSize",font_size)
%     xlabel(["Reward","uncertainty"])
    box off
end
% ADD TEXT ON BARS
groupOffset = [0, 0];
barWidth = b.BarWidth;
bar_text(b,groupOffset,barWidth,font_size,font_name)
%% SUBPLOT LABELS

ax1_pos = ax1_new.Position;
adjust_x = -0.06; % adjust x-position of subplot label
adjust_y = ax1_pos(4) - 0.05; % adjust y-position of subplot label
[label_x,label_y] = change_plotlabel(ax1_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',fontsize_label,'LineStyle','none','HorizontalAlignment',horz_align)
adjust_y = ax1_pos(4) - 0.02;
[label_x,label_y] = change_plotlabel(ax3_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',fontsize_label,'LineStyle','none','HorizontalAlignment',horz_align)

ax5_pos = ax5_new.Position;
adjust_y = ax5_pos(4) + 0.02;
adjust_x = -0.06;
[label_x,label_y] = change_plotlabel(ax5_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',fontsize_label,'LineStyle','none','HorizontalAlignment',horz_align)
[label_x,label_y] = change_plotlabel(ax10_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'd','FontSize',fontsize_label,'LineStyle','none','HorizontalAlignment',horz_align)
[label_x,label_y] = change_plotlabel(axes_new(1),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'e','FontSize',fontsize_label,'LineStyle','none','HorizontalAlignment',horz_align)
[label_x,label_y] = change_plotlabel(axes_new(2),adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'f','FontSize',fontsize_label,'LineStyle','none','HorizontalAlignment',horz_align)
[label_x,label_y] = change_plotlabel(ax15_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'g','FontSize',fontsize_label,'LineStyle','none','HorizontalAlignment',horz_align)
%% SAVE AS PNG

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'task_behavior9.png', '-dpng', '-r600') 