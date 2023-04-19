function [a0, a1, action, mu_a0, mu_a1, prob_s_a] = gen_action(mu, con, s, num_trials)
    % GEN_ACTION generates the rewarding action arrays in a block for a
    % given number of trials
	% INPUT:
    	% mu = s-a-r mu contingency parameter
    	% con = contrast of a block
    	% s = array with state of each trial in a block
    	% num_trials = number of trials
     % OUTPUT:
     	% a0 = array with a = 0
      	% a1 = array with a = 1
       	% action = action array with both a
        % mu_a0 = probability of a = 1 in a0
        % mu_a1 = probability of a = 1 in a1
        % prob_s_a = probability of correct s-a combo depending on th block's contrast
    
    trials_a0 = num_trials./2;
    other_mu = 1-mu; % mu for other action
    % ACTION
    a0 = [repelem(0,mu*trials_a0,1);repelem(1,trials_a0-mu*trials_a0,1)]; 
    a1 = [repelem(1,mu*trials_a0,1);repelem(0,trials_a0-mu*trials_a0,1)];
    
    % PROPORTION OF a = 1
    mu_a0 = sum(a0)./length(a0);
    mu_a0 = 1-mu_a0;
    mu_a1 = sum(a1)./length(a1);
    
    if con == 1
        action = [a0;a1];
        prob_s_a = sum(s~=action)./length(s);
    else
        action = [a1;a0];
        prob_s_a = sum(s==action)./length(s);
    end
end