classdef class_unittests < matlab.unittest.TestCase
    % CLASS_UNITTESTS is a collection of functions to run unit tests on
    % various functions used to pregenerate vars for psychopy.

    methods(Test)

        function test_state_count(testCase)
            % TEST_STATE_COUNT tests the length of the generated
            % array for s = 0 and s = 1

            num_trials = 20; % number of trials in a blcok
            s0_prob = 0.5; % probability of occurence of s = 0
            [s0,s1,~]=gen_state(num_trials,s0_prob); % run function to get actual ouput
            exp_lenght = 10; % expected length

            % COMPARE LENGTH OF EXPECTED AND ACTUAL OUTPUT
            assert(length(s0)==exp_lenght,'Number of trials with state 0 is incorrect')
            assert(length(s1)==exp_lenght,'Number of trials with state 1 is incorrect')
        end

        function test_state_length(testCase)
            % TEST_STATE_LENGTH tests the length of the generated state
            % array

            num_trials = 20; % number of trials in a blcok
            s0_prob = 0.5; % probability of occurence of s = 0
            [s0,s1,~]=gen_state(num_trials,s0_prob); % run function to get actual ouput
            expectedLength = num_trials; % expected length of state array
            actualLength = length(s0) + length(s1); % actual length of state array

            % COMPARE LENGTH OF ACTUAL AND EXPECTED OUTPUT
            errorMessage = 'The length of the output array is not equal to the number of trials';
            testCase.verifyEqual(actualLength, expectedLength, errorMessage);
        end

        function test_state_val(testCase)
            % TEST_STATE_VAL tests the value of arrays generated for s = 0
            % and s = 1

            num_trials = 20; % number of trials in a blcok
            s0_prob = 0.5; % probability of occurence of s = 0
            [s0,s1,s]=gen_state(num_trials,s0_prob); % run function to get actual ouput
            exp_s0 = repelem(0,10,1); % expected s = 0 array
            exp_s1 = repelem(1,10,1); % expected s = 1 array
            exp_s = [exp_s1;exp_s0]; % expected state array

            % COMPARE EXPECTED AND ACTUAL ARRAYS
            assert(isequal(s0,exp_s0),'s is not equal to 0')
            assert(isequal(s1,exp_s1),'s is not equal to 1')
            assert(isequal(s,exp_s),'state array is as expected')
        end

        function test_condiff_range(testCase)
            % TEST_CONDIFF_RANGE tests whether generated contrast
            % difference values are less than or equal to the highest
            % contrast level possible

            avg_vis = 0.5; % average visibility between the two patches
            contrast_low = 0; % lower limit of contrast difference range
            contrast_high = 0.1; % upper limit of contrast difference range
            s = [0 1 0 1 0 1]; % state array
            num_trials = length(s); % number of trials
            choice = 1; % to plot for choice phase
            seed = 123; % seed value
            rng(seed); % set the seed
            rand_condiff = rand(num_trials,1); % pseudo-random array
            [condiff, ~, ~] = gen_condiff(avg_vis, contrast_low, contrast_high, s, num_trials, choice, rand_condiff);
            exp_condiff = 0.1; % expected contrast difference

            % CHECK IF ACTUAL CONTRAST DIFFERENCE VALUES ARE WITHIN THE
            % RANGE
            verifyLessThanOrEqual(testCase,condiff,exp_condiff,'Contrast difference out of range')
        end

        function test_contrast_range(testCase)
            % TEST_CONTRAST_RANGE tests whether contrast levels of
            % left/right patch are within given range
            
            avg_vis = 0.5; % average visibility between the two patches
            contrast_low = 0; % lower limit of contrast difference range
            contrast_high = 0.1; % upper limit of contrast difference range
            s = [0 1 0 1 0 1]; % state array
            num_trials = length(s); % number of trials
            choice = 1; % to plot for choice phase
            seed = 123; % seed value
            rng(seed); % set the seed
            rand_condiff = rand(num_trials,1); % psuedo random number
            [~, con_left, con_right] = gen_condiff(avg_vis, contrast_low, contrast_high, s, num_trials, choice, rand_condiff);

            % CHECK IF CONTRAST LEVEL VALUES ARE WITHIN RANGE
            verifyLessThanOrEqual(testCase,con_right,0.6,'Contrast level (right) exceeding max contrast level')
            verifyLessThanOrEqual(testCase,con_left,0.6,'Contrast level (left) exceeding max contrast level')
            verifyGreaterThanOrEqual(testCase,con_right,0.4,'Contrast level (right) less than max contrast level')
            verifyGreaterThanOrEqual(testCase,con_left,0.4,'Contrast level (left) less than max contrast level')
        end

        function test_condiff_vals(testCase)
            % TEST_CONDIFF_VALES compares the exact contrast level values
            % of left/right patch

            avg_vis = 0.5; % average visibility between the two patches
            contrast_low = 0; % lower limit of contrast difference range
            contrast_high = 0.1; % upper limit of contrast difference range
            s = [0 1 0 1 0 1]; % state array
            num_trials = length(s); % number of trials
            choice = 1; % to plot for choice phase
            seed = 123; % seed value
            rng(seed); % set the seed
            rand_condiff = rand(num_trials,1); % psuedo random array between 0-1
            [condiff, con_left, con_right] = gen_condiff(avg_vis, contrast_low, contrast_high, s, num_trials, choice, rand_condiff);
            expected_condiff = (contrast_high-contrast_low).*rand_condiff + contrast_low; % expected contrast difference
            expectedConLeft = [avg_vis - condiff(1) avg_vis + condiff(2) avg_vis - condiff(3) ...
                               avg_vis + condiff(4) avg_vis - condiff(5) avg_vis + condiff(6)]';
            expectedConRight = [avg_vis + condiff(1) avg_vis - condiff(2) avg_vis + condiff(3) ...
                                avg_vis - condiff(4) avg_vis + condiff(5) avg_vis - condiff(6)]';

            % CHECK IF EXPECTED AND ACTUAL CONTRAST DIFFERENCE VALUES ARE
            % EQUAL
            errorMessage = 'The condiff array is incorrect';
            testCase.verifyEqual(condiff, expected_condiff, errorMessage);
            errorMessage = 'The con_left array is incorrect';
            testCase.verifyEqual(con_left, expectedConLeft, errorMessage);
            errorMessage = 'The con_right array is incorrect';
            testCase.verifyEqual(con_right, expectedConRight, errorMessage);
        end

        function test_state_dep_contrasts(testCase)
            % TEST_STATE_DEP_CONTRASTS tests if contrast values are
            % according to state of a trial
            
            avg_vis = 0.5; % average visibility between the two patches
            contrast_low = 0; % lower limit of contrast difference range
            contrast_high = 0.1; % upper limit of contrast difference range
            s = [0 1 0 1 0 1]; % state array
            num_trials = length(s); % number of trials
            choice = 1; % to plot for choice phase
            seed = 123; % seed value
            rng(seed); % set the seed
            rand_condiff = rand(num_trials,1);
            [~, con_left, con_right] = gen_condiff(avg_vis, contrast_low, contrast_high, s, num_trials, choice, rand_condiff);

            % CHECK IF CONTRAST LEVEL OF LEFT/RIGHT PATCHES ARE ACCORDING
            % TO A GIVEN STATE
            for i = 1:num_trials
                if s(i)== 0
                    verifyLessThan(testCase,con_left(i),con_right(i),'Contrast level (left) exceeding contrast level (right)')
                else
                    verifyLessThan(testCase,con_right(i),con_left(i),'Contrast level (right) exceeding contrast level (left)')
                end
            end
       end

       function test_repvars_count(testCase)
            % TEST_REPVARS_COUNT tests the row_id array values and length
            % of repeated arrays

            vars = 1; % variable that needs to be repeated
            num_trials = 20; % number of trials in a block
            
            [vars_array,row_id] = repeat_vars(vars,num_trials);

            % CHECK IF ROW_ID VALUES ARE LESS THAN NUMBER OF TRIALS IN A
            % BLOCK AND LENGTH OF REPEATED VARS ARRAY IS AS EXPECTED
            verifyLessThanOrEqual(testCase,row_id,20,'Trial row ID exceeds total no. of trials in a block')
            assert(length(vars_array)==20,'Number of trials is incorrect')
       end

       function test_repvars_val(testCase)
            % TEST_REPVARS_VAL tests the repeated vars array

            vars = 1; % variable that needs to be repeated
            num_trials = 20; % number of trials in a block
            
            [vars_array,~] = repeat_vars(vars,num_trials);
            exp_vars = repelem(vars,num_trials,1); % expected repeated vars array

            % COMPARE EXPECTED AND ACTUAL REPEATED VARS ARRAY
            verifyEqual(testCase,vars_array,exp_vars,'Repeated vars array is not as expected')
        end

        function test_action_mu(testCase)
            % TEST_ACTION_MU tests the probability of occurence of a = 0 or
            % a = 1 and also check the block contingency parameter (mu)

            num_trials = 20; % number of trials in a block 
            s0_prob = 0.5; % probability of trials with s = 0
            [~,~,s]=gen_state(num_trials,s0_prob); % state array of block
            con = 1; % contrast of block
            mu = 0.7; % contingency parameter of a block
            [~,~,~,mu_a0,mu_a1,prob_s_a] = gen_action(mu,con,s,num_trials);

            % CHECKS IF THE EXPECTED AND ACTUAL PROBABILITY OF a = 0, a = 1
            % AND BLOCK MU
            exp_mu = 0.7;
            verifyEqual(testCase,mu_a0,exp_mu,'prob of a = 0 is incorrect')
            exp_mu = 0.7;
            verifyEqual(testCase,mu_a1,exp_mu,'prob of a = 1 is incorrect')
            exp_mu = 0.7;
            verifyEqual(testCase,prob_s_a,exp_mu,'Block mu is incorrect')
        end

        function test_contrast_dep_action(testCase)
            % TEST_CONTRAST_DEP_ACTION check if the generated action is in
            % accordance with the current contrast of the block
            
            % LOW CONTRAST BLOCK
            s = [zeros(5, 1); ones(5, 1)];
            [a0,a1,action,~,~,~] = gen_action(0.6, 0, s, 10);
            assert(all(action(1:5) == a1) && all(action(6:10) == a0));
            
            % HIGH CONTRAST BLOCK
            s = [zeros(5, 1); ones(5, 1)];
            [a0,a1,action,~,~,~] = gen_action(0.6, 1, s, 10);
            assert(all(action(1:5) == a0) && all(action(6:10) == a1));
        end

        function test_state_mu(testCase)
            % TEST_STATE_MU tests the probability of occurence of s = 0, s
            % = 1 during slider phase

            num_trials = 20; % number of trials in a block
            s0_prob = 0.5; % probability of s = 0
            seed = 123; % seed value
            rng(seed) % set the seed
            randperm_array = randperm(num_trials./2,num_trials./2); % pseudo random array
            [~,~,~,prob_mu_s0,prob_mu_s1] = gen_state_mu(s0_prob,num_trials,randperm_array);

            exp_prob = 0.5; % expected probability
            verifyEqual(testCase,prob_mu_s0,exp_prob,'prob of s = 0 (during slider) is incorrect')
            verifyEqual(testCase,prob_mu_s1,exp_prob,'prob of s = 1 (during slider) is incorrect')
        end

        function test_condiff_vals_slider(testCase)
            % TEST_CONDIFF_VALS_SLIDER tests the contrast difference value
            % during the slider phase

            avg_vis = 0.5; % average visibility of the left/right patches
            contrast_low = 0; % lower limit of contrast difference
            contrast_high = 0.1; % upper limit of contrast difference
            s = [0 1 0 1 0 1]; % state array
            num_trials = length(s); % number of trials in a block
            choice = 0; % contrast difference for the slider phase
            
            seed = 123; % seed value
            rng(seed); % set the seed 
            rand_condiff = rand(num_trials,1); % pseudo random array
            [condiff, con_left, con_right] = gen_condiff(avg_vis, contrast_low, contrast_high, s, num_trials, choice, rand_condiff);
    
            
            % EXPECTED OUTPUTS
            expected_condiff = repelem(contrast_high, num_trials, 1);
            expectedConLeft = [avg_vis - condiff(1) avg_vis + condiff(2) avg_vis - condiff(3) ...
                               avg_vis + condiff(4) avg_vis - condiff(5) avg_vis + condiff(6)]';
            expectedConRight = [avg_vis + condiff(1) avg_vis - condiff(2) avg_vis + condiff(3) ...
                                avg_vis - condiff(4) avg_vis + condiff(5) avg_vis - condiff(6)]';
            
            % COMPARE THE EXPECTED AND ACTUAL CONTRAST DIFFERENCE
            errorMessage = 'The condiff array is incorrect';
            testCase.verifyEqual(condiff, expected_condiff, errorMessage);
            errorMessage = 'The con_left array is incorrect';
            testCase.verifyEqual(con_left, expectedConLeft, errorMessage);
            errorMessage = 'The con_right array is incorrect';
            testCase.verifyEqual(con_right, expectedConRight, errorMessage);
        end

        function test_jitter(testCase)
            % TEST_JITTER tests the length, range of the
            % jittered durations

            lower_lim = 0.5; % lower limit of the jittered duration range
            upper_lim = 1; % upper limit of the jittered duration range
            num_trials = 20; % number of trials in a block

            [jitter_timing] = gen_jitters(num_trials,lower_lim,upper_lim);

            % CHECK THE LENGTH, RANGE OF JITTERED DURATIONS
            assert(length(jitter_timing) == num_trials,"Length of array with jittered duration exceeds number of trials in a block");
            verifyLessThanOrEqual(testCase,jitter_timing,1,'Jittered stim duration exceeding upper limit')
            verifyGreaterThanOrEqual(testCase,jitter_timing,0.5,'Jittered stim duration exceeding lower limit')
        end

        function test_bord_pos_test(testCase)
            % Test function for bord_pos_text
            num_trials = 10; % number of trials in a block
            con = 1; % contrast of block 
            state_mu = [0; 1; 0; 1; 0; 1; 0; 1; 0; 1]; % state array for a block 
            pos = 0.15; % value of position on psychopy screen
            cong = 0; % congruence of block 
            [bord_pos, bord_text] = bord_pos_text(num_trials, con, state_mu, pos, cong);
            
            % TEST THAT THE FUNCTION RETURNS EXPECTED DIMENSIONS, POSITIONS
            % AND TEXT
            assert(all(size(bord_pos) == [num_trials, 1]));
            assert(all(size(bord_text) == [num_trials, 1]));
            assert(all(bord_pos(1:2:end) == -pos));
            assert(all(bord_pos(2:2:end) == pos));
            assert(isequal(bord_text, ["left"; "right"; "left"; "right"; "left"; "right"; "left"; "right"; "left"; "right"]));
        end

        function test_state_dep_border(testCase)
            % TEST_STATE_DEP_BORDER checks if the border position and text
            % for different contrast, congruence

            num_trials = 20; % number of trials in a block 
            con = 1; % contrast of a block
            pos = 0.15; % value of position on psychopy screen 
            s0_prob = 0.5; % probability of s = 0
            cong = 0; % congruence of a block
            [state_mu,~,~,~,~] = gen_state_mu(s0_prob,num_trials);
            [bord_pos,bord_text]= bord_pos_text(num_trials,con,state_mu,pos,cong);

            % COMPARE EXPECTED AND ACTUAL BORDER POSITION AND TEXT
            for i = 1:num_trials
                if con == 1 && cong == 1 || con == 0 && cong == 0
                    if state_mu(i)==1
                        assert(bord_pos(i)==-0.15,'Incorrect border position')
                    else
                        assert(bord_pos(i)==0.15,'Incorrect border position')
                    end
                elseif con == 1 && cong == 0 || con == 0 && cong == 1
                    if state_mu(i)==0
                        assert(bord_pos(i)==-0.15,'Incorrect border position')
                    else
                        assert(bord_pos(i)==0.15,'Incorrect border position')
                    end
                end
            end

            for i = 1:num_trials
                if bord_pos(i) > 0
                    verifyEqual(testCase,bord_text(i),"right")
                else
                    verifyEqual(testCase,bord_text(i),"left")
                end
            end
        end
    end
end