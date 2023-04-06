function [s0,s1,s] = gen_state(num_trials,s0_prob,state0,state1)
    % GEN_STATE generates trial states for a given number of trials in a
    % block.

    % num_trials = number of trials in a block
    % s0_prob = proportion of trials with state = 0
    % state0 = numeric value of state = 0
    % state1 = numeric value of state = 1


    s1 = repelem(state1,num_trials*s0_prob,1); % state = 0
    s0 = repelem(state0,num_trials*(1-s0_prob),1); % state = 1
    s = [s1;s0]; % state array
end
