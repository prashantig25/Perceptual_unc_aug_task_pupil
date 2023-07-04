% INITIALISE BLOCK VARS (don't change the combination)
% explain these with examples and context to the task
subj_state_crystal = [0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1]; % state 
subj_cond = [1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2]; % condition
subj_cong = [0,0,1,1,0,0,1,1,1,1,0,0,1,1,0,0]; % congruence
subj_left = [0,1,1,0,0,1,1,0,1,0,0,1,1,0,0,1]; % mu for left/right planet?
subj_planet_pos = [1,0,0,1,1,0,0,1,0,1,1,0,0,1,1,0]; % positions of planet
subj_state_prob = [0.3,0.1,0.3,0.1,0.3,0.1,0.3,0.1,0.7,0.9,0.7,0.9,0.7,0.9,0.7,0.9]; % probability of state = 1


num_subjs = 1; % number of subjects
blocks = 1:16; % number of blocks (for training as well??)

for n = 1:num_subjs
     
     % CREATE FOLDER FOR SUBJECT
     folder = strcat("C:\Users\prash\Nextcloud\Thesis_laptop\Semester 6\pupil_task\pregen_files_subjs\",num2str(n));
     mkdir(folder) 

     % PREGEN VARS FOR EVERY BLOCK
     for b = 1:length(blocks)

        choice_mu = repelem(0,length(subj_cong),1);
        choice = repelem(1,length(subj_cong),1);
        
        num_trials = 20; % number of trials
        s1_prob = subj_state_prob(b); % proportion of trials with s = 1
        avg_vis = 0.5; % avg visibility
        contrast_high = 0.1; % highest level of contrast difference
        contrast_low = 0; % lowest level of contrast difference
        state_crystal = subj_state_crystal(b); % more probable state of block
        cond = subj_cond(b); % condition of block
        cong = subj_cong(b); % congruence of block
        left = subj_left(b); % mu for left/right planet
        planet_pos = subj_planet_pos(b); % 0:green planet on left; 1:green planet on right
        rand_condiff = rand(num_trials,1); % random number array for contrast differences
        randperm_array = randperm(num_trials./2,num_trials./2); % pseudo random array

        % STATE
        [s0, s1, s] = gen_state(num_trials, s1_prob);
        
        % CONTRAST DIFFERENCE FOR CHOICE PHASE
        [condiff, con_left, con_right]= gen_condiff(avg_vis, contrast_low, contrast_high, s, num_trials, choice, rand_condiff);
        
        % GENERATE VARS AND ROW ID
        [state_crystal,~] = repeat_vars(state_crystal, num_trials);
        [condition,~] = repeat_vars(cond, num_trials);
        [left, ~] = repeat_vars(left, num_trials);
        [planet_pos, ~] = repeat_vars(planet_pos, num_trials);
        [congruence, row_id] = repeat_vars(cong, num_trials);

        tbl = table(s,condiff,con_left,con_right,state_crystal,congruence,condition,row_id, ...
            left,planet_pos,'VariableNames',{'state','condiff','con_left','con_right','state_crystal',...
            'congruence','condition','row_id','left','planet_pos'});

        B = tbl(randperm(20), :);

        % NAME THE FILE
        if cond == 1
            cond_name = '\mix_';
        else
            cond_name = '\perc_';
        end
        
        if state_crystal(1) == 1
            state_name = 's1_';
        else
            state_name = 's0_';
        end

        if left(1) == 1
            left_name = 'left_';
        else
            left_name = 'right_';
        end
        
        if cong(1) == 1
            cong_name = 'cong';
        else
            cong_name = 'incong';
        end
        
        % SAVE THE TABLE
        filename_tbl = strcat(folder,cond_name,state_name,left_name,cong_name,'.xlsx');
        writetable(B,filename_tbl);
     end
end
