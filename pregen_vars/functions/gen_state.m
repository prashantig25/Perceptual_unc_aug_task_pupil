function [s0, s1, s] = gen_state(num_trials, s0_prob)
    % GEN_STATE generates trial states for a given number of trials in a
    % block.
	% INPUT:
    	% num_trials = number of trials in a block
    	% s0_prob = proportion of trials with state = 0
    % OUTPUT:
    	% s0 = array with s = 0
     	% s1 = array with s = 1
      	% s = array with state for each trial in a block

    s1 = repelem(1,num_trials*s0_prob,1); % state = 0
    s0 = repelem(0,num_trials*(1-s0_prob),1); % state = 1
    s = [s1;s0]; % state array
end