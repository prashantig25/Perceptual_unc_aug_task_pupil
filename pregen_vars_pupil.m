%% pregenerate vars for psychopy task

% state
num_trials = 20; % number of trials
s0_prob = 0.5; % proportion of trials with s = 0
state0 = 0; % value for state = 0
state1 = 1; % value for state = 1
[s0,s1,s]=gen_state(num_trials,s0_prob,state0,state1);

% condiff
avg_vis = 0.5; % avg visibility
contrast_level = 0.1; % highest contrast level
[condiff, con_left, con_right]= gen_condiff(avg_vis,contrast_level,s,num_trials); 

con = 1; % contrast of a block i.e. 0 = low contrast; 1 = high contrast
cond = 2; % condition of a block i.e. 1 = Mixed; 2 = Perceptual 
cong = 0; % congruence of a block i.e. 0 = incongruent; 1 = congruent
num_trials = 20;

% generate vars with details of contrast, congruence, condition and trial
% number
[contrast,condition,congruence,row_id] = repeat_vars(con,cond,cong,num_trials);

mu = 0.7; % reward probability in a block 
% generate correct action for a given trial
[a0,a1,action,mu_a0,mu_a1,prob_s_a] = gen_action(mu,con,s,num_trials);

% for slider patches state
prob_state_mu = 0.5; % proportion of state during slider
state0 = 0;
state1 = 1;
% generate state during slider phase
[state_mu] = gen_state_mu(prob_state_mu,num_trials,state0,state1);

% generate contrast difference for the slider phase
[con_left_mu,con_right_mu] = gen_condiff_mu(avg_vis,contrast_level,num_trials,state_mu);

pos = 0.15;
% generates border position on psychopy screen
[bord_pos,bord_text]= bord_pos_text(num_trials,con,state_mu,pos);

% jittered stimuli timings

lower_lim = 0.5; upper_lim = 0.7;
[jitter_fix] = gen_jitters(num_trials,lower_lim,upper_lim);

lower_lim = 1.5; upper_lim = 2.1;
[jitter_delay] = gen_jitters(num_trials,lower_lim,upper_lim);

lower_lim = 0.5; upper_lim = 1;
[jitter_inst] = gen_jitters(num_trials,lower_lim,upper_lim);

lower_lim = 1.6; upper_lim = 2.1;
[jitter_isi] = gen_jitters(num_trials,lower_lim,upper_lim);

lower_lim = 0.2; upper_lim = 0.5;
[jitter_base_degee] = gen_jitters(num_trials,lower_lim,upper_lim);

tbl = table(s,action,condiff,con_left,con_right,state_mu,con_left_mu,con_right_mu,bord_pos,bord_text ...
    ,contrast,congruence,condition,row_id,jitter_fix,jitter_base_degee,jitter_isi,jitter_delay,jitter_inst, ...
    'VariableNames',{'state','action','condiff','con_left','con_right','state_mu','con_left_mu','con_right_mu' ...
    'bord_pos','bord_text','contrast','congruent','condition','row_id','jitter_fix','jitter_base_degee','jitter_isi', ...
    'jitter_delay','jitter_inst'});

if cond == 1
    cond_name = 'mix_';
else
    cond_name = 'perc_';
end

if con == 1
    cont_name = 'hc_';
else
    cont_name = 'lc_';
end

if cong == 1
    cong_name = 'con';
else
    cong_name = 'incon';
end

filename_tbl = strcat(cond_name,cont_name,cong_name,'.xlsx');
writetable(tbl,filename_tbl);
