function [a0,a1,action,mu_a0,mu_a1,prob_s_a] = gen_action(mu,con,s,num_trials)
    % GEN_ACTION generates the rewarding action arrays in a block for a
    % given number of trials

    % mu = s-a-r mu contingency parameter
    % con = contrast of a block
    % s = array with state of each trial in a block
    % num_trials = number of trials
    
    trials_a0 = num_trials./2;
    other_mu = 1-mu; % mu for other action
    % action 
    a0 = [repelem(0,mu*trials_a0,1);repelem(1,trials_a0-mu*trials_a0,1)]; 
    a1 = [repelem(1,mu*trials_a0,1);repelem(0,trials_a0-mu*trials_a0,1)];
    
    % prob of a0 and a1
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