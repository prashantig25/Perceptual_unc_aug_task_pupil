% Multiverse plot with standardized values
% for uncertainty-weighted PE coefficient

clc
clearvars

coeffStringHet = 'PExCondiff';
coeffStringNormal = 'zsc_condiff:pe';
multiversePlot(coeffStringHet, coeffStringNormal)

fig = gcf;
fig.PaperPositionMode = 'auto';
print(fig, 'multiverse_12_specifications.png', '-dpng', '-r600')
