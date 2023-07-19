function [jitter_timing] = gen_jitters(num_trials,lower_lim,upper_lim, rand_array)
    % GEN_JITTERS generates jittered stimuli duration
    % INPUT:
        % num_trials = number of trials in a block
        % upper_lim = upper limit of jittered duration
        % lower_lim = lower limit of jittered duration
    % OUTPUT:
        % jitter_timing = array with jittered stimulus timings for each
        % trial in a block
    
        jitter_timing = lower_lim + (upper_lim-lower_lim).*rand_array;
end