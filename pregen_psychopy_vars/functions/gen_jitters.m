function [jitter_timing] = gen_jitters(num_trials,lower_lim,upper_lim)
    % GEN_JITTERS generates jittered stimuli duration

    % num_trials = number of trials in a block
    % upper_lim = upper limit of jittered duration
    % lower_lim = lower limit of jittered duration
    
    jitter_timing = NaN(num_trials,1);
    for i = 1:num_trials
        jitter_timing(i) = lower_lim + (upper_lim-lower_lim).*rand;
    end
end