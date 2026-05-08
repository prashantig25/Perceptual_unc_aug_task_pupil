% Multiverse plot with standardized values
% for PE coefficient

clc
clearvars

coeffStringHet = 'PE';
coeffStringNormal = 'pe';
multiversePlot(coeffStringHet, coeffStringNormal)

fig = gcf;
fig.PaperPositionMode = 'auto';
print(fig, 'multiverse_12_specifications.png', '-dpng', '-r600')
