function [pval_pos] = create_pvalpos(ylim_axes)
% function CREATE_PVALPOS gives output of p-value to be plotted on a time
% course analysis.
% INPUTS:
%   ylim_axes: axes limits for y-axis

ylim_diff = ylim_axes(2) - ylim_axes(1);
pval_pos = ylim_diff*-0.09;
end