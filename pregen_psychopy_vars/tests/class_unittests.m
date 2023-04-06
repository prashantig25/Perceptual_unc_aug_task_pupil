classdef class_unittests < matlab.unittest.TestCase
    methods(Test)

        function state_count(testCase)
            num_trials = 20;
            s0_prob = 0.5;
            state0 = 0;
            state1 = 1;
            [s0,s1,~]=gen_state(num_trials,s0_prob,state0,state1);
            exp = 10;
            assert(length(s0)==exp,'Number of trials with state 0 is incorrect')
            assert(length(s1)==exp,'Number of trials with state 1 is incorrect')
        end

        function state_length(testCase)
            num_trials = 20;
            s0_prob = 0.5;
            state0 = 0;
            state1 = 1;
            [s0,s1,~]=gen_state(num_trials,s0_prob,state0,state1);
            expectedLength = num_trials;
            actualLength = length(s0) + length(s1);
            errorMessage = 'The length of the output array is not equal to the number of trials';
            testCase.verifyEqual(actualLength, expectedLength, errorMessage);
        end

        function state_val(testCase)
            num_trials = 20;
            s0_prob = 0.5;
            state0 = 0;
            state1 = 1;
            [s0,s1,~]=gen_state(num_trials,s0_prob,state0,state1);
            exp = repelem(0,10,1);
            assert(isequal(s0,exp),'s is not equal to 0')
            exp = repelem(1,10,1);
            assert(isequal(s1,exp),'s is not equal to 1')
        end

        function condiff_range(testCase)
            % condiff
            avg_vis = 0.5;
            contrast_level = 0.1;
            s = [0 1 0 1 0 1];
            num_trials = length(s);
            [condiff, ~, ~] = gen_condiff(avg_vis, contrast_level, s, num_trials);
            exp = 0.1;
            verifyLessThanOrEqual(testCase,condiff,exp,'Contrast difference out of range')
        end

        function contrast_range(testCase)
            
            % condiff
            avg_vis = 0.5;
            contrast_level = 0.1;
            s = [0 1 0 1 0 1];
            num_trials = length(s);
            [~, con_left, con_right] = gen_condiff(avg_vis, contrast_level, s, num_trials);

            verifyLessThanOrEqual(testCase,con_right,0.6,'Contrast level (right) exceeding max contrast level')
            verifyLessThanOrEqual(testCase,con_left,0.6,'Contrast level (left) exceeding max contrast level')
            verifyGreaterThanOrEqual(testCase,con_right,0.4,'Contrast level (right) less than max contrast level')
            verifyGreaterThanOrEqual(testCase,con_left,0.4,'Contrast level (left) less than max contrast level')
        end

        function condiff_vals(testCase)

            avg_vis = 0.5;
            contrast_level = 0.1;
            s = [0 1 0 1 0 1];
            num_trials = length(s);
            [condiff, con_left, con_right] = gen_condiff(avg_vis, contrast_level, s, num_trials);

            % Check the output
            expectedCondDiff = [rand()*contrast_level rand()*contrast_level rand()*contrast_level ...
                                rand()*contrast_level rand()*contrast_level rand()*contrast_level]';
            errorMessage = 'The condiff array is incorrect';
            testCase.verifyEqual(condiff, expectedCondDiff, 'AbsTol', 0.1, errorMessage);

            expectedConLeft = [avg_vis - condiff(1) avg_vis + condiff(2) avg_vis - condiff(3) ...
                               avg_vis + condiff(4) avg_vis - condiff(5) avg_vis + condiff(6)]';
            errorMessage = 'The con_left array is incorrect';
            testCase.verifyEqual(con_left, expectedConLeft, 'AbsTol', 0.001, errorMessage);

            expectedConRight = [avg_vis + condiff(1) avg_vis - condiff(2) avg_vis + condiff(3) ...
                                avg_vis - condiff(4) avg_vis + condiff(5) avg_vis - condiff(6)]';
            errorMessage = 'The con_right array is incorrect';
            testCase.verifyEqual(con_right, expectedConRight, 'AbsTol', 0.001, errorMessage);
        end

        function check_state_dep_condiff(testCase)
            s = [0 1 0 1 0 1];
            num_trials = length(s);
            
            % condiff
            avg_vis = 0.5; % avg visibility
            contrast_level = 0.1; % highest contrast level
            [~, con_left, con_right]= gen_condiff(avg_vis,contrast_level,s,num_trials);

            for i = 1:num_trials
                if s(i)== 0
                    verifyLessThan(testCase,con_left(i),con_right(i),'Contrast level (left) exceeding contrast level (right)')
                else
                    verifyLessThan(testCase,con_right(i),con_left(i),'Contrast level (right) exceeding contrast level (left)')
                end
            end
       end

       function check_repvars_count(testCase)
            con = 1;
            cond = 2;
            cong = 0;
            num_trials = 20;
            
            [contrast,condition,congruence,row_id] = repeat_vars(con,cond,cong,num_trials);
            verifyLessThanOrEqual(testCase,row_id,20,'Trial row ID exceeds total no. of trials in a block')
            assert(length(contrast)==20,'Number of trials is incorrect')
            assert(length(condition)==20,'Number of trials is incorrect')
            assert(length(congruence)==20,'Number of trials is incorrect')
       end

       function check_repvars_val(testCase)
            con = 1;
            cond = 2;
            cong = 0;
            num_trials = 20;
            
            [contrast,condition,congruence,~] = repeat_vars(con,cond,cong,num_trials);

            for i = 1:num_trials
                verifyEqual(testCase,contrast(i),1,'Block contrast is incorrect')
                verifyEqual(testCase,condition(i),2,'Block condition is incorrect')
                verifyEqual(testCase,congruence(i),0,'Block congruence is incorrect')
            end
        end

        function action_mu_check(testCase)
            num_trials = 20;
            state0 = 0;
            state1 = 1;
            s0_prob = 0.5;
            [~,~,s]=gen_state(num_trials,s0_prob,state0,state1);
            con = 1;
            mu = 0.7;
            [~,~,~,mu_a0,mu_a1,prob_s_a] = gen_action(mu,con,s,num_trials);

            exp = 0.7;
%             assert(mu_a0==exp,'prob for a = 0 is incorrect')
            tol = 0.00000001;
            verifyEqual(testCase,mu_a0,exp,'prob of a = 0 is incorrect','AbsTol',tol)

            exp = 0.7;
            verifyEqual(testCase,mu_a1,exp,'prob of a = 1 is incorrect','AbsTol',tol)

            exp = 0.7;
            verifyEqual(testCase,prob_s_a,exp,'Block mu is incorrect')
        end

        function contrast_dep_action(testCase)
            
            % low contrast block
            s = [zeros(5, 1); ones(5, 1)];
            [a0,a1,action,~,~,~] = gen_action(0.6, 0, s, 10);
            assert(all(action(1:5) == a0) && all(action(6:10) == a1));
            
            % high contrast block
            s = [zeros(5, 1); ones(5, 1)];
            [a0,a1,action,~,~,~] = gen_action(0.6, 1, s, 10);
            assert(all(action(1:5) == a1) && all(action(6:10) == a0));
        end

        function state_mu_check(testCase)

            num_trials = 20;
            s0_prob = 0.5;
            state0 = 0;
            state1 = 1;
            [~,~,~,prob_mu_s0,prob_mu_s1] = gen_state_mu(s0_prob,num_trials,state0,state1);

            exp = 0.5;
            verifyEqual(testCase,prob_mu_s0,exp,'prob of s = 0 (during slider) is incorrect')
            verifyEqual(testCase,prob_mu_s1,exp,'prob of s = 1 (during slider) is incorrect')
        end

        function condiff_range_slider(testCase)
            avg_vis = 0.5;
            num_trials = 20;
            contrast_level = 0.1;
            s0_prob = 0.5;
            state0 = 0;
            state1 = 1;
            [state_mu,~,~,~,~] = gen_state_mu(s0_prob,num_trials,state0,state1);
            [~,~,s]=gen_state(num_trials,s0_prob,state0,state1);
            [con_left_mu,con_right_mu] = gen_condiff_mu(avg_vis,contrast_level,s,num_trials,state_mu);

            for i = 1:num_trials
                if state_mu(i)== 0
                    verifyLessThan(testCase,con_left_mu(i),con_right_mu(i),'Contrast level (left) exceeding contrast level (right)')
                else
                    verifyLessThan(testCase,con_right_mu(i),con_left_mu(i),'Contrast level (right) exceeding contrast level (left)')
                end
            end
        end

        function test_gen_condiff_mu(testCase)
            % Test case 1
            avg_vis = 0.5;
            contrast_level = 0.1;
            num_trials = 10;
            state_mu = [0; 1; 0; 1; 0; 1; 0; 1; 0; 1];
            [con_left_mu, con_right_mu] = gen_condiff_mu(avg_vis, contrast_level, num_trials, state_mu);
            expected_con_left_mu = [0.4; 0.6; 0.4; 0.6; 0.4; 0.6; 0.4; 0.6; 0.4; 0.6];
            expected_con_right_mu = [0.6; 0.4; 0.6; 0.4; 0.6; 0.4; 0.6; 0.4; 0.6; 0.4];
            assert(all(abs(con_left_mu - expected_con_left_mu) < 1e-10), 'Test case 1 failed');
            assert(all(abs(con_right_mu - expected_con_right_mu) < 1e-10), 'Test case 1 failed');
            
            % Test case 2
            avg_vis = 0.8;
            contrast_level = 0.2;
            num_trials = 5;
            state_mu = [1; 0; 1; 0; 1];
            [con_left_mu, con_right_mu] = gen_condiff_mu(avg_vis, contrast_level, num_trials, state_mu);
            expected_con_left_mu = [1; 0.6; 1; 0.6; 1];
            expected_con_right_mu = [0.6; 1; 0.6; 1; 0.6];
            assert(all(abs(con_left_mu - expected_con_left_mu) < 1e-10), 'Test case 2 failed');
            assert(all(abs(con_right_mu - expected_con_right_mu) < 1e-10), 'Test case 2 failed');
        end

        function jitter_check(testCase)
            lower_lim = 0.5;
            upper_lim = 1;
            num_trials = 20;
            [jitter_timing] = gen_jitters(num_trials,lower_lim,upper_lim);
            assert(length(jitter_timing) == num_trials,"Length of array with jittered duration exceeds number of trials in a block");
            verifyLessThanOrEqual(testCase,jitter_timing,1,'Jittered stim duration exceeding upper limit')
            verifyGreaterThanOrEqual(testCase,jitter_timing,0.5,'Jittered stim duration exceeding lower limit')
        end

        function check_bord_pos_test(testCase)
            % Test function for bord_pos_text
            num_trials = 10;
            con = 1;
            state_mu = [0; 1; 0; 1; 0; 1; 0; 1; 0; 1];
            pos = 0.15;
            [bord_pos, bord_text] = bord_pos_text(num_trials, con, state_mu, pos);
            
            % Test that the function returns expected dimensions
            assert(all(size(bord_pos) == [num_trials, 1]));
            assert(all(size(bord_text) == [num_trials, 1]));
            
            % Test that the positions are correctly assigned
            assert(all(bord_pos(1:2:end) == pos));
            assert(all(bord_pos(2:2:end) == -pos));
            
            % Test that the text is correctly assigned
            assert(isequal(bord_text, ["right"; "left"; "right"; "left"; "right"; "left"; "right"; "left"; "right"; "left"]));
        end

        function state_dep_border(testCase)
            num_trials = 20;
            con = 1;
            pos = 0.15;
            s0_prob = 0.5;
            state0 = 0;
            state1 = 1;
            [state_mu,~,~,~,~] = gen_state_mu(s0_prob,num_trials,state0,state1);
            [bord_pos,bord_text]= bord_pos_text(num_trials,con,state_mu,pos);

            for i = 1:num_trials
                if con == 1
                    if state_mu(i)==1
                        assert(bord_pos(i)==-0.15,'Incorrect border position')
                    else
                        assert(bord_pos(i)==0.15,'Incorrect border position')
                    end
                else
                    if state_mu(i)==0
                        assert(bord_pos(i)==0.15,'Incorrect border position')
                    else
                        assert(bord_pos(i)==-0.15,'Incorrect border position')
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
