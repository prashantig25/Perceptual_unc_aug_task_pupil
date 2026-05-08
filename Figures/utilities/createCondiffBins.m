function bins = createCondiffBins(conDiffs)
% CREATECONDIFFBINS Helper function to create 10 equally sized
% bins of contrast differences from 0 to 0.1
%
% INPUT
%   conDiffs: Contrast differences
%
% OUTPUT
%   bins: Computed bins

% This creates 10 perfectly equal steps from 0 to 0.1
binEdges = linspace(0, 0.1, 11);

% Nudge the last one so the 0.1 values are included
binEdges(end) = 0.1001;

% Create bins
bins = discretize(abs(conDiffs), binEdges);

end