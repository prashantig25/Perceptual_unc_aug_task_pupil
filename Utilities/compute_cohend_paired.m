function cohen_d = compute_cohend_paired(cond1, cond2)
% COMPUTE_COHEND_PAIRED  Computes Cohen's d_z for paired samples.
%
%   cohen_d = compute_cohend_paired(cond1, cond2)
%
%   INPUTS:
%     cond1 : vector of per-subject means for condition 1 (e.g. perc_avg)
%     cond2 : vector of per-subject means for condition 2 (e.g. mix_avg)
%             Must be the same length as cond1 — one entry per subject.
%
%   OUTPUT:
%     cohen_d : Cohen's d_z = mean(diff) / std(diff)
%               This matches the paired t-statistic: d_z = t / sqrt(n)
%               and correctly removes between-subject variance.

    diff_scores = cond1 - cond2;
    cohen_d     = nanmean(diff_scores) / nanstd(diff_scores);
end