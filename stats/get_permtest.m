function perm = get_permtest(var, num_subjs, col, var1, var2, two_tailed, betas)

    % function GET_PERMTEST runs cluster-corrected permutation test.
    %
    % INPUTS:
    %   var: number of variables
    %   num_subjs: number of subjects
    %   col: length of pupil signal
    %   var1: array with pupil signal
    %   var2: array with pupil signal
    %   two_tailed: if permutation test needs to be two-tailed or
    %   one-tailed
    %   betas: if permutation test needs to be run on betas or descriptive
    %   data
    % OUTPUT:
    %   perm: struct with output from the permutation test

    %addpath(genpath('D:\Perceptual_unc_aug_task_pupil-main\Perceptual_unc_aug_task_pupil-main\Utilities'));
    
    % INITIALIZE VARS
    num_vars = length(var);
    perm.mask = NaN(num_vars, col);
    perm.pos_cluster = NaN(num_vars, col);
    perm.neg_cluster = NaN(num_vars, col);
    perm.prob = NaN(num_vars, col);
    
    % LOOP THROUGH VARIABLES
    for n = 1:num_vars
    
        % PREPARE VARS FOR PERM TEST
        grandavg_cat1.beta = zeros(num_subjs, 1, col);
        grandavg_cat2.beta = zeros(num_subjs, 1, col);
    
        % ASSIGN VALUES FOR PERM TEST 
        if betas == 1 % if perm test is to be conducted on regression betas
            for s = 1:num_subjs
                for c = 1:col
                    grandavg_cat1.beta(s, :, c) = var1(1, var(n), s, c);
                    if two_tailed == 1
                        grandavg_cat2.beta(s, :, c) = var2(2, var(n), s, c);
                    else
                        grandavg_cat2.beta(s, :, c) = 0;
                    end
                end
            end
        else % if perm test is to be conducted on descriptive data
            for s = 1:num_subjs
                for c = 1:col
                    grandavg_cat1.beta(:,c) = var1(:,c);
                    grandavg_cat2.beta(:,c) = var2(:,c);
                end
            end
        end
    
        % ADD RELEVANT VARIABLES
        grandavg_thiscat1.time = 1:col; % length of signal
        grandavg_thiscat1.label = {'EyePupil'}; % pupillometry data
        grandavg_thiscat1.dimord = 'subj_chan_time';
        grandavg_thiscat1.individual = grandavg_cat1.beta; % data
    
        grandavg_thiscat2.time = 1:col;
        grandavg_thiscat2.label = {'EyePupil'};
        grandavg_thiscat2.dimord = 'subj_chan_time';
        grandavg_thiscat2.individual = grandavg_cat2.beta;
    
        % RUN PERM TEST
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