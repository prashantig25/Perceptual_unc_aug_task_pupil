% INITIALISE BLOCK VARS
subj_con = [0,0,0,0,1,1,1,1]; % contrast
subj_cond = [1,2,1,2,1,2,1,2]; % condition
subj_cong = [0,1,1,0,1,1,0,0]; % congruence

num_subjs = 50; % number of subjects
blocks = 1:8; % number of blocks

for n = 1:num_subjs
     
     % CREATE FOLDER FOR SUBJECT
     folder = strcat("C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_task\pregen_files_subjs\",num2str(n));
     mkdir(folder) 

     % PREGEN VARS FOR EVERY BLOCK
     for b = 1:length(blocks)

        choice_mu = repelem(0,length(subj_cong),1);
        choice = repelem(1,length(subj_cong),1);
        
        num_trials = 20; % number of trials
        s0_prob = 0.5; % proportion of trials with s = 1
        avg_vis = 0.5; % avg visibility
        contrast_high = 0.1; % highest contrast level
        contrast_low = 0; % lowest contrast level
        prob_state_mu = 0.5; % proportion of state during slider
        pos = 0.15; % position on screen
        con = subj_con(b); % contrast of block
        cond = subj_cond(b); % condition of block
        cong = subj_cong(b); % congruence of block
        rand_condiff = rand(num_trials,1); % random number array for contrast differences
        randperm_array = randperm(num_trials./2,num_trials./2); % pseudo random array
        rand_array = rand(num_trials,1); % random number array for jitters
        if subj_cond(b) == 1 % condition dependent contingency parameter
            mu = 0.7;
        else
            mu = 0.9;
        end
        
        % STATE
        [s0, s1, s] = gen_state(num_trials, s0_prob);
        
        % CONTRAST DIFFERENCE FOR CHOICE PHASE
        [condiff, con_left, con_right]= gen_condiff(avg_vis, contrast_low, contrast_high, s, num_trials, choice, rand_condiff);
        
        % GENERATE VARS AND ROW ID
        [contrast,~] = repeat_vars(con, num_trials);
        [condition,~] = repeat_vars(cond, num_trials);
        [congruence, row_id] = repeat_vars(cong, num_trials);
        
        % GENERATE CORRECT ACTION FOR EACH TRIAL
        [a0, a1, action, mu_a0, mu_a1, prob_s_a] = gen_action(mu, con, s, num_trials);
        action_text = strings(num_trials,1);
        for i = 1:num_trials
            if action(i) == 0
                action_text(i) = 'left';
            else
                action_text(i) = 'right';
            end
        end
        
        % STATE DURING SLIDER PHASE
        [state_mu] = gen_state_mu(prob_state_mu, num_trials, randperm_array);
        
        % CONTRAST DIFFERENCE FOR SLIDER PHASE
        [~, con_left_mu, con_right_mu]= gen_condiff(avg_vis, contrast_low, contrast_high, state_mu, num_trials, choice_mu);
        
        % BORDER POS/TEXT FOR SLIDER PHASE
        [bord_pos, bord_text]= bord_pos_text(num_trials, con, state_mu, pos,cong);
        
        % JITTERED STIMULI TIMINGS
        lower_lim = 0.5; upper_lim = 0.7;
        [jitter_fix] = gen_jitters(num_trials,lower_lim, upper_lim, rand_array);
        
        lower_lim = 1.5; upper_lim = 2.1;
        [jitter_delay] = gen_jitters(num_trials,lower_lim, upper_lim, rand_array);
        
        lower_lim = 0.2; upper_lim = 0.5;
        [jitter_inst] = gen_jitters(num_trials,lower_lim, upper_lim, rand_array);
        
        lower_lim = 0.5; upper_lim = 1;
        [jitter_isi] = gen_jitters(num_trials,lower_lim,upper_lim, rand_array);
        
        lower_lim = 1.6; upper_lim = 2.1;
        [jitter_base_degee] = gen_jitters(num_trials,lower_lim,upper_lim, rand_array);
        
        tbl = table(s,action_text,condiff,con_left,con_right,state_mu,con_left_mu,con_right_mu,bord_pos,bord_text ...
            ,contrast,congruence,condition,row_id,jitter_fix,jitter_base_degee,jitter_isi,jitter_delay,jitter_inst, ...
            'VariableNames',{'state','action','condiff','con_left','con_right','state_mu','con_left_mu','con_right_mu' ...
            'bord_pos','bord_text','contrast','congruent','condition','row_id','jitter_fix','jitter_base_degee','jitter_isi', ...
            'jitter_delay','jitter_inst'});

        % NAME THE FILE
        if cond == 1
            cond_name = '\mix_';
        else
            cond_name = '\perc_';
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
        
        % SAVE THE TABLE
        filename_tbl = strcat(folder,cond_name,cont_name,cong_name,'.xlsx');
        writetable(tbl,filename_tbl);
     end
end
