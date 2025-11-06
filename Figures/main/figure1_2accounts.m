% figure1 creates a hypothesis illustration figure with 4 panels.

clc
clearvars

% INITIALISE VARS

font_name = 'Arial'; % font name
font_size = 7; % font size
horz_align = 'center'; % horizontal alignment for text
vert_align = 'middle'; % vertical alignment for text
line_width = 0.5; % linewidth for axes
linewidth_arrow = 0.5; % linewidth for arrows
linewidth_line = 2; % linewidth for plotted lines
headlength_arrow = 5; % headlength for arrows
[~,high_PU,mid_PU,low_PU,color_screen,~,~,~,~,~,gray_dots,light_gray,~,~,...
    ~,dots_edges,~,~,gray_arrow] = colors_rgb(); % colors

% VARS FOR LRs PLOT

colors_pu_all = [low_PU; high_PU; gray_arrow(1,1:3); gray_arrow(1,1:3)]; % colors for low and high perceptual uncertainty data
pe_vals = linspace(-1,1,10); % prediction error range
neg_up = [-0.5,-0.15,-0.325,-0.325]; % negative updates
pos_up = [0.5,0.15,0.325,0.325]; % positive updates

condiffbin = importdata("condiff_pebin2.mat"); % pupil regression
num_subjs = 47; % number of subjects
col = 300; % number of timepoints

%% INITIALISE TILE LAYOUT (2x2 grid)

f1 = figure;
set(gcf,'Visible','on','Position',[200,200,400,400])
t = tiledlayout(2,2);
ax1 = nexttile(1); % Top left - Classic RL account only
ax2 = nexttile(2); % Top right - Gray curve only
ax3 = nexttile(3); % Bottom left - Uncertainty-aware account (no gray)
ax4 = nexttile(4); % Bottom right - PE Encoding in Arousal (no gray)
t.TileSpacing = 'compact';
t.Padding = 'compact';

%% ADD ARROWS (adjusted for 2x2 layout)

% % Horizontal arrow between top panels
% ar1 = annotation('arrow','LineWidth',linewidth_arrow,'HeadLength',headlength_arrow,'Color','k','HeadWidth',10);
% ar1.X = [0.47 0.54];
% ar1.Y = [0.75,0.75]; % Adjusted for top row
% 
% % Vertical arrows from top to bottom
% ar2 = annotation('arrow','LineWidth',linewidth_arrow,'HeadLength',headlength_arrow,'Color',low_PU,'HeadWidth',10);
% ar2.X = [0.25 0.25];
% ar2.Y = [0.58,0.42]; % From top left to bottom left
% 
% ar3 = annotation('arrow','LineWidth',linewidth_arrow,'HeadLength',headlength_arrow,'Color',high_PU,'HeadWidth',10);
% ar3.X = [0.75 0.75];
% ar3.Y = [0.58,0.42]; % From top right to bottom right

%% PANEL 1 (TOP LEFT): CLASSIC RL ACCOUNT ONLY

% POSITION CHANGE
position_change = [0.025,0.03,-0.05,-0.05];
new_pos = change_position(ax1,position_change);
ax1_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax1_new, 'on');
delete(ax1);

% PLOT
hold on
plot(pe_vals,repelem(0,1,10),'LineStyle','--','Color','k','LineWidth',0.5)
hold on
plot(pe_vals,pe_vals,'LineStyle','--','Color','k','LineWidth',0.5)
hold on
% Only plot the classic RL account (gray line)
plot(pe_vals,linspace(neg_up(3),pos_up(3),10),'LineStyle','-','Color', ...
    colors_pu_all(3,:),'LineWidth',linewidth_line)

% ADJUST FIGURE PROPERTIES
xlim_vals = [-1 1];
ylim_vals = [-1 1];
adjust_figprops(ax1_new,font_name,font_size,line_width,xlim_vals,ylim_vals)
ylabel('Update')
xlabel({'Prediction error (PE)'})

% Legend for classic RL only
l1 = legend('', '', 'Classic RL account', 'Location','best', 'Color','none', ...
    'EdgeColor','none','AutoUpdate','off','FontSize',7);
l1.ItemTokenSize = [7, 7];
box off

% % ADD TEXT BOXES
% ypos = [0.71,-0.07]; % position on y-axis
% xpos = [0.8,0.8]; % position on x-axis
% rotate = [45.5, 0]; % degree of rotation
% allstrings = {'LR = 1','LR = 0'};
% for n = 1:2
%     txt = text(xpos(n),ypos(n),allstrings{1,n});
%     txt.Parent = ax1_new;
%     txt.FontSize = font_size;
%     txt.FontWeight = 'normal';
%     txt.Rotation = rotate(n);
%     txt.FontName = font_name;
%     txt.HorizontalAlignment = horz_align;
% end

%% PANEL 2 (TOP RIGHT): GRAY CURVE ONLY

% POSITION CHANGE
position_change = [0.09,0.03,-0.05,-0.05];
new_pos = change_position(ax2,position_change);
ax2_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax2_new, 'on');
delete(ax2);

% USE BETAS TO PLOT - ONLY GRAY CURVE
xaxis = linspace(-300,2700,250); % x-axis values
midPU_pupil = nanmean(smoothdata(condiffbin.pebin1(:,1:250),2,"gaussian"))*0.66; % mid perceptual uncertainty
midPU_pupil(1,midPU_pupil < 0) = 0;

% PLOT - ONLY GRAY CURVE
hold on
plot(xaxis,midPU_pupil,'LineWidth',2,'Color',gray_arrow)

hold on
box off
xlabel('Time')
ylabel('Arousal')
xlim([-300,2700])
ylim([-0.005,0.4])
xticks([]); % Remove x-axis ticks
title('PE Encoding in Arousal Signal','FontWeight','normal')
adjust_figprops(ax2_new,font_name,font_size,0.5);

%% PANEL 3 (BOTTOM LEFT): UNCERTAINTY-AWARE ACCOUNT (NO GRAY)

% POSITION CHANGE
position_change = [0.025,0.03,-0.05,-0.05];
new_pos = change_position(ax3,position_change);
ax3_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax3_new, 'on');
delete(ax3);

% PLOT
hold on
plot(pe_vals,repelem(0,1,10),'LineStyle','--','Color','k','LineWidth',0.5)
hold on
plot(pe_vals,pe_vals,'LineStyle','--','Color','k','LineWidth',0.5)
hold on
% Only plot low and high uncertainty lines (no gray classic RL)
plot(pe_vals,linspace(neg_up(1),pos_up(1),10),'LineStyle','-','Color', ...
    colors_pu_all(1,:),'LineWidth',linewidth_line)
hold on
plot(pe_vals,linspace(neg_up(2),pos_up(2),10),'LineStyle','-','Color', ...
    colors_pu_all(2,:),'LineWidth',linewidth_line)

% ADJUST FIGURE PROPERTIES
xlim_vals = [-1 1];
ylim_vals = [-1 1];
adjust_figprops(ax3_new,font_name,font_size,line_width,xlim_vals,ylim_vals)
ylabel('Update')
xlabel({'Prediction error (PE)'})

% Legend for uncertainty-aware account only
l3 = legend('', '', 'Low state uncertainty', 'High state uncertainty', ...
    'Location','best', 'Color','none', 'EdgeColor','none','AutoUpdate','off','FontSize',7);
l3.ItemTokenSize = [7, 7];
box off

% % ADD TEXT BOXES
% ypos = [0.71,-0.07,0.55,0.45]; % position on y-axis
% xpos = [0.8,0.8,0.1,0.1]; % position on x-axis
% rotate = [45.5, 0, 90, 90]; % degree of rotation
% allstrings = {'LR = 1','LR = 0','Up-regulation','Down-regulation'};
% for n = 1:4
%     txt = text(xpos(n),ypos(n),allstrings{1,n});
%     txt.Parent = ax3_new;
%     txt.FontSize = font_size;
%     txt.FontWeight = 'normal';
%     txt.Rotation = rotate(n);
%     txt.FontName = font_name;
%     txt.HorizontalAlignment = horz_align;
% end

%% PANEL 4 (BOTTOM RIGHT): PE ENCODING WITHOUT GRAY CURVE

% POSITION CHANGE
position_change = [0.09,0.03,-0.05,-0.05];
new_pos = change_position(ax4,position_change);
ax4_new = axes('Units', 'Normalized', 'Position', new_pos);
box(ax4_new, 'on');
delete(ax4);

% USE BETAS TO PLOT - NO GRAY CURVE
xaxis = linspace(-300,2700,250); % x-axis values
highPU_pupil = nanmean(smoothdata(condiffbin.pebin1(:,1:250),2,"gaussian")); % high perceptual uncertainty
lowPU_pupil = nanmean(smoothdata(condiffbin.pebin1(:,1:250),2,"gaussian"))*0.3; % low perceptual uncertainty

highPU_pupil(1,highPU_pupil < 0) = 0;
lowPU_pupil(1,lowPU_pupil < 0) = 0;

% PLOT - NO GRAY CURVE
hold on
plot(xaxis,highPU_pupil,'LineWidth',2,'Color',low_PU)
hold on
plot(xaxis,lowPU_pupil,'LineWidth',2,'Color',high_PU)

hold on
box off
xlabel('Time')
ylabel('Arousal')
xlim([-300,2700])
ylim([-0.005,0.4])
xticks([]); % Remove x-axis ticks
title('PE Encoding in Arousal Signal','FontWeight','normal')
adjust_figprops(ax4_new,font_name,font_size,0.5);

%% SUBPLOT LABELS

ax1_pos = ax1_new.Position;
adjust_x = -0.09; % adjust x-position of subplot label
adjust_y = ax1_pos(4) + 0.04; % adjust y-position of subplot label

% Label for panel 1 (top left)
[label_x,label_y] = change_plotlabel(ax1_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'a','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

% Label for panel 2 (top right)
[label_x,label_y] = change_plotlabel(ax2_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'b','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

% Label for panel 3 (bottom left)
[label_x,label_y] = change_plotlabel(ax3_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'c','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

% Label for panel 4 (bottom right)
[label_x,label_y] = change_plotlabel(ax4_new,adjust_x,adjust_y);
annotation("textbox",[label_x label_y .05 .05],'String', ...
    'd','FontSize',12,'LineStyle','none','HorizontalAlignment','center')

%% SAVE FIGURE

fig = gcf; % use `fig = gcf` ("Get Current Figure") if want to print the currently displayed figure
fig.PaperPositionMode = 'auto'; % To make Matlab respect the size of the plot on screen
print(fig, 'hypothesis_4panel.png', '-dpng', '-r600')