function perm = get_permtest_updated(var, num_subjs, col, var1, var2)
% function GET_PERMTEST runs cluster-corrected permutation test.
%
% INPUTS:
%   var       : indices of variables to test
%   num_subjs : number of subjects
%   col       : length of pupil signal
%   var1      : data array [num_vars x num_subjs x col], pre-sliced
%   var2      : (optional) data array [num_vars x num_subjs x col];
%               if omitted or empty, tests against zero
% OUTPUT:
%   perm: struct with output from the permutation test

if nargin < 5 || isempty(var2)
    var2 = [];
end

num_vars = length(var);

perm.mask        = NaN(num_vars, col);
perm.pos_cluster = NaN(num_vars, col);
perm.neg_cluster = NaN(num_vars, col);
perm.prob        = NaN(num_vars, col);

for n = 1:num_vars

    data1 = reshape(var1(n, :, :), [num_subjs, 1, col]);

    if isempty(var2)
        data2 = zeros(num_subjs, 1, col);
    else
        data2 = reshape(var2(n, :, :), [num_subjs, 1, col]);
    end

    grandavg_thiscat1.individual = data1;
    grandavg_thiscat1.time       = 1:col;
    grandavg_thiscat1.label      = {'EyePupil'};
    grandavg_thiscat1.dimord     = 'subj_chan_time';

    grandavg_thiscat2.individual = data2;
    grandavg_thiscat2.time       = 1:col;
    grandavg_thiscat2.label      = {'EyePupil'};
    grandavg_thiscat2.dimord     = 'subj_chan_time';

    stat = clusterStat(grandavg_thiscat1, grandavg_thiscat2, num_subjs);

    perm.mask(n, :) = stat.mask;
    perm.prob(n, :) = stat.prob;

    if isfield(stat, 'posclusterslabelmat')
        perm.pos_cluster(n, :) = stat.posclusterslabelmat;
    end
    if isfield(stat, 'negclusterslabelmat')
        perm.neg_cluster(n, :) = stat.negclusterslabelmat;
    end

end
end