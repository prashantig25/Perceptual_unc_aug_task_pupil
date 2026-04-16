classdef unitTestsLrAnalyses < matlab.mock.TestCase
    % Unit tests for the learning-rate-analysis class

    methods (Test)

        function testInit(testCase)
            % Tests the initialization of the learning-rate-regression object.

            preprocess_obj = preprocess_LR();

            testCase.verifyEqual(preprocess_obj.filename, 'pupilbehv_allNEW.xlsx');
            testCase.verifyEqual(preprocess_obj.removed_cond, 3);
            testCase.verifyEqual(preprocess_obj.num_subjs, 47);
            testCase.verifyEqual(preprocess_obj.data, [])
            testCase.verifyEqual(preprocess_obj.mu, [])
            testCase.verifyEqual(preprocess_obj.flipped_mu, [])
            testCase.verifyEqual(preprocess_obj.obtained_reward, [])
            testCase.verifyEqual(preprocess_obj.condition, [])
            testCase.verifyEqual(preprocess_obj.action, [])
            testCase.verifyEqual(preprocess_obj.state, [])
            testCase.verifyEqual(preprocess_obj.recoded_reward, [])
            testCase.verifyEqual(preprocess_obj.mu_t, [])
            testCase.verifyEqual(preprocess_obj.mu_t_1, [])
        
        end


        function testGetData(testCase)
            % Tests the get_data function

            % Initialize preprocessing object object
            mockData = saveMockData(testCase);
            preprocess_obj = preprocess_LR();
            preprocess_obj.filename = "temp_test_data/001_main1.xlsx";
            preprocess_obj.get_data();

            % Remove non-response for testing
            mockData(isnan(mockData.slider),:) = [];

            % Add "trials" -- todo: why necessary?
            extraData = table([1; 3; 4],  'VariableNames', {'trials'});
            expectedData = [mockData, extraData];

            testCase.verifyEqual(preprocess_obj.data, expectedData);
            testCase.verifyEqual(preprocess_obj.mu, mockData.mu);
            testCase.verifyEqual(preprocess_obj.condition, mockData.condition);
            testCase.verifyEqual(preprocess_obj.obtained_reward, mockData.correct);
            testCase.verifyEqual(preprocess_obj.action, mockData.choice);
            testCase.verifyEqual(preprocess_obj.state, mockData.state);
            testCase.verifyEqual(preprocess_obj.flipped_mu, NaN(height(mockData),1));
            testCase.verifyEqual(preprocess_obj.recoded_reward, NaN(height(mockData),1));
            testCase.verifyEqual(preprocess_obj.mu_t, NaN(height(mockData),1));
            testCase.verifyEqual(preprocess_obj.mu_t_1, NaN(height(mockData),1));
            testCase.verifyEqual(preprocess_obj.data.trials, expectedData.trials,1);

        end

        function testFlipMu(testCase)
            % Tests the flip_mu function

            % Initialize preprocessing object object
            saveMockData(testCase);
            preprocess_obj = preprocess_LR();
            preprocess_obj.filename = "temp_test_data/001_main1.xlsx";
            preprocess_obj.get_data();
            preprocess_obj.flip_mu()

            testCase.verifyEqual(preprocess_obj.flipped_mu, [0.4; 0.6; 0.3], RelTol=1.e-10)

        end

        function testComputeActionDepRew(testCase)
            % Tests the compute_action_dep_rew function

            % Initialize preprocessing object object
            saveMockData(testCase);
            preprocess_obj = preprocess_LR();
            preprocess_obj.filename = "temp_test_data/001_main1.xlsx";
            preprocess_obj.get_data();
            preprocess_obj.compute_action_dep_rew()

            testCase.verifyEqual(preprocess_obj.recoded_reward, [0; 1; 0])
            testCase.verifyEqual(preprocess_obj.obtained_reward, [1; 1; 0])

        end

        function testComputeMu(testCase)
            % Tests the compute_mu function

            % Initialize preprocessing object object
            saveMockData(testCase);
            preprocess_obj = preprocess_LR();
            preprocess_obj.filename = "temp_test_data/001_main1.xlsx";
            preprocess_obj.get_data();
            preprocess_obj.flip_mu()
            preprocess_obj.compute_mu()

            testCase.verifyEqual(preprocess_obj.mu_t_1, [NaN; 0.6; 0.6], RelTol=1.e-10)
            testCase.verifyEqual(preprocess_obj.mu_t, [NaN; 0.4; 0.3], RelTol=1.e-10)

        end

        function testComputeStateDepPe(testCase)
            % Tests the compute_state_dep_pe function

            % Initialize preprocessing object object
            saveMockData(testCase);
            preprocess_obj = preprocess_LR();
            preprocess_obj.filename = "temp_test_data/001_main1.xlsx";
            preprocess_obj.get_data();
            preprocess_obj.flip_mu();
            preprocess_obj.compute_action_dep_rew();
            preprocess_obj.compute_mu();
            preprocess_obj.compute_state_dep_pe();

            testCase.verifyEqual(preprocess_obj.data.pe, [0; 0.4; 0.4], RelTol=1.e-10)
            testCase.verifyEqual(preprocess_obj.data.up, [NaN; -0.2; -0.3], RelTol=1.e-10)

        end

        function testComputeRU(testCase)
            % Tests the compute_ru function 

            % Initialize preprocessing object object
            saveMockData(testCase);
            preprocess_obj = preprocess_LR();
            preprocess_obj.filename = "temp_test_data/001_main1.xlsx";
            preprocess_obj.get_data();
            preprocess_obj.compute_ru()

            testCase.verifyEqual(preprocess_obj.data.ru, logical([0; 1; 1]))

        end

        function testComputeConfirm(testCase)
            % Tests the compute_confirm function 

            % Initialize preprocessing object object
            testComputeConfirm = true;
            mockData = saveMockData(testCase, testComputeConfirm);
            preprocess_obj = preprocess_LR();
            preprocess_obj.filename = "temp_test_data/001_main1.xlsx";
            preprocess_obj.data = mockData;
            preprocess_obj.state = mockData.state;
            preprocess_obj.action = mockData.action; 
            preprocess_obj.data.confirm_rew = NaN(length(mockData.state), 1);
            preprocess_obj.obtained_reward = ones(length(mockData.state), 1);
            preprocess_obj.compute_confirm();

            testCase.verifyEqual(preprocess_obj.data.confirm_rew, [1; 0; 0; 1; 0; 1; 1; 0])

        end

        function testComputeNormalise(testCase)
            % Tests the compute_normalise function 
            
            % Initialize preprocessing object object
            saveMockData(testCase);
            preprocess_obj = preprocess_LR();
            preprocess_obj.filename = "temp_test_data/001_main1.xlsx";
            preprocess_obj.get_data();
            norm_condiff = preprocess_obj.compute_normalise(abs(preprocess_obj.data.con_diff));
    
            testCase.verifyEqual(norm_condiff, [0.5; 0; 1], RelTol=1.e-10)

        end

        function testAddSplitHalf(testCase)
            % Tests the add_splithalf function
            
            % Initialize preprocessing object object
            saveMockData(testCase);
            preprocess_obj = preprocess_LR();
            preprocess_obj.filename = "temp_test_data/001_main1.xlsx";
            preprocess_obj.get_data();
            preprocess_obj.add_splithalf()

            testCase.verifyEqual(preprocess_obj.data.splithalf, logical([0; 0; 1]))

        end

        function testAddSalienceChoice(testCase)
            % Tests the add_saliencechoice function

            % Initialize preprocessing object object
            saveMockData(testCase);
            preprocess_obj = preprocess_LR();
            preprocess_obj.filename = "temp_test_data/001_main1.xlsx";
            preprocess_obj.get_data();
            preprocess_obj.add_saliencechoice(); 
            testCase.verifyEqual(preprocess_obj.data.salience_choice, logical([0; 0; 1]))

        end
    end
end
