% Multiverse plot with standardized values for PE coefficient

clc
clearvars

% Size in CM
width_cm = 12;
height_cm = 15;

% Create plot
multiversePlot('pe', width_cm, height_cm)

% Save as PDF
fig = gcf;
fig.PaperPositionMode = 'auto';
% print(fig, 'multiverse_12_specifications.png', '-dpng', '-r600')

% We are using a slightly outdated way to save the figure as PDF
style = hgexport('factorystyle');
style.Format = 'pdf';
style.Width = width_cm;
style.Height = height_cm;
style.Units = 'centimeters';
style.Renderer = 'painters';
style.FontMode = 'none'; 
hgexport(fig, 'Figures/PDF_Versions/Figure_SM12.pdf', style);
