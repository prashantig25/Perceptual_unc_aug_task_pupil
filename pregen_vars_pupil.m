%% pregenerate vars for psychopy task

% STATE
num_trials = 20; % number of trials
s0_prob = 0.5; % proportion of trials with s = 1
% state0 = 0; % value for state = 0
% state1 = 1; % value for state = 1
[s0, s1, s] = gen_state(num_trials, s0_prob);

% CONTRAST DIFFERENCE FOR CHOICE PHASE
avg_vis = 0.5; % avg visibility
contrast_high = 0.1; % highest contrast level
contrast_low = 0; % lowest contrast level
choice = 1; % for choice phase
[condiff, con_left, con_right]= gen_condiff(avg_vis, contrast_low, contrast_high, s, num_trials, choice);

con = 1; % contrast of a block i.e. 0 = low contrast; 1 = high contrast
cond = 1; % condition of a block i.e. 1 = Mixed; 2 = Perceptual 
cong = 0; % congruence of a block i.e. 0 = incongruent; 1 = congruent
num_trials = 20;

% GENERATE VARS AND ROW ID
[contrast,~] = repeat_vars(con, num_trials);
[condition,~] = repeat_vars(cond, num_trials);
[congruence, row_id] = repeat_vars(cong, num_trials);

% GENERATE CORRECT ACTION FOR EACH TRIAL
mu = 0.7; % reward probability in a block 
[a0, a1, action, mu_a0, mu_a1, prob_s_a] = gen_action(mu, con, s, num_trials);

% STATE DURING SLIDER PHASE
prob_state_mu = 0.5; % proportion of state during slider
[state_mu] = gen_state_mu(prob_state_mu, num_trials);

% CONTRAST DIFFERENCE FOR SLIDER PHASE
avg_vis = 0.5; % avg visibility
contrast_high = 0.1; % highest contrast level
contrast_low = 0; % lowest contrast level
choice = 0; % for slider phase
[~, con_left_mu, con_right_mu]= gen_condiff(avg_vis, contrast_low, contrast_high, s, num_trials, choice);

% BORDER POS/TEXT FOR SLIDER PHASE
pos = 0.15;
[bord_pos, bord_text]= bord_pos_text(num_trials, con, state_mu, pos);

% JITTERED STIMULI TIMINGS
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
