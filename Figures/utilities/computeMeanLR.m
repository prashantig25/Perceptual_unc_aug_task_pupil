function [avg_ydataLR, sem_ydataLR] = computeMeanLR(data, bins, nbins, numSubj, ID)
% COMPUTEMEANLR Computes mean and SEM single-trial learning rates
%
%   INPUT:
%    data: Input data, agent or subjects
%    bins: Computed bins
%    nbins: Number of bins
%    numSubj: Number of subjects
%    data: Data set
%    ID: List of IDs
%
%   OUTPUT:
%    avg_ydataLR: Mean learning rates
%    sem_ydataLR: SEM learning rates

% Add N bins
data.bins = bins;

% Compute learning rate
data.lr = data.up./data.pe;

% Filter data
run_id = data.ID(data.pe ~= 0 & abs(data.lr)<=2);
y_data_LR = data.lr(data.pe ~= 0 & abs(data.lr)<=2);
bins = bins(data.pe ~= 0 & abs(data.lr)<=2);

% Initialize LR bins
avg_ydataLR_bins = NaN(nbins,numSubj);

% Cycle over bins
for b = 1:nbins

    % Cycle over subjects
    for n = 1:numSubj

        % Select bins
        bins_subj = bins(run_id == ID(n));

        % Select LRs
        y_data_LR_subj = y_data_LR(run_id == ID(n));

        % Compute average for bins
        avg_ydataLR_bins(b,n) = mean(y_data_LR_subj(bins_subj == b));
    end
end

% Compute mean and SEM
avg_ydataLR = mean(avg_ydataLR_bins,2);
sem_ydataLR = std(avg_ydataLR_bins,0,2)./sqrt(numSubj);

end