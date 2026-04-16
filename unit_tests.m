classdef unit_tests < matlab.mock.TestCase
    % Unit tests for the PupilRegression class

    % Todo:
    % 1. Heteroskedastic model
    % 2. If used: Test init with config copy
    %   2.1 test copyFromConfig
    % 3. Test RegressRTEffects function
    % 4. TestloadBaselineData function
    % 5. testGetBehavioralPredictors with baseline_mdl == 1
    % 6. testGetBinnedData with binning options
    % 7. Test runPermutationTest (if used in future)

    % Further notes

    % Separate tests for AIC/BIC functions (or getting rid of them)
    %
    % Don't forget to test linear_fit directly
    %
    % Same for functions doing permutation test like test get_permtest
    %
    % Finally, we should have integration test with small simulated data set at
    % least for the regression part to test binning and basic regression
    % results.

    methods (Test)

        % ----------------------
        % Part 1: Initialization
        % ----------------------

        function testInit(testCase)
            % Tests the initialization of the pupil-regression object.

            % Initialize pupil-regression object
            analyzer = PupilRegression_intHet();

            % General properties
            testCase.verifyEqual(analyzer.betas_struct, struct())
            testCase.verifyEqual(analyzer.perm_results, [])
            testCase.verifyEqual(analyzer.residuals_all, [])
            testCase.verifyEqual(analyzer.predicted_all, [])

            % Model comparison and heteroskedastic model
            testCase.verifyEqual(analyzer.aic_values, [])
            testCase.verifyEqual(analyzer.bic_values, [])
            testCase.verifyEqual(analyzer.logL_values, [])
            testCase.verifyEqual(analyzer.rsquaredOrdinary, [])
            testCase.verifyEqual(analyzer.rsquaredAdjusted, [])
            testCase.verifyEqual(analyzer.starting_points, [])
            testCase.verifyEqual(analyzer.model_type, 'OLS')
            testCase.verifyEqual(analyzer.n_sp, 20)
            testCase.verifyEqual(analyzer.minBound, [])
            testCase.verifyEqual(analyzer.maxBound, [])
            testCase.verifyEqual(analyzer.lb, [])
            testCase.verifyEqual(analyzer.ub, [])
            testCase.verifyEqual(analyzer.fmincon_options, [])
            testCase.verifyEqual(analyzer.negLL_values, [])
            testCase.verifyEqual(analyzer.externalFitFcn, @linear_fit)

            % Subject and session parameters
            testCase.verifyEqual(analyzer.subj_ids, [])
            testCase.verifyEqual(analyzer.num_subs, [])
            testCase.verifyEqual(analyzer.num_sess, [])

            % Directory paths
            testCase.verifyEqual(analyzer.behv_dir, [])
            testCase.verifyEqual(analyzer.pupil_dir, [])
            testCase.verifyEqual(analyzer.xgaze_dir, [])
            testCase.verifyEqual(analyzer.ygaze_dir, [])
            testCase.verifyEqual(analyzer.base_dir, [])
            testCase.verifyEqual(analyzer.save_dir, [])

            % Analysis parameters
            testCase.verifyEqual(analyzer.timewindow, 'feedback');
            testCase.verifyEqual(analyzer.regress_rt, 0);
            testCase.verifyEqual(analyzer.baseline_mdl, 0);
            testCase.verifyEqual(analyzer.binned, 0);
            testCase.verifyEqual(analyzer.bins, [])
            testCase.verifyEqual(analyzer.bins_array, 1);
            testCase.verifyEqual(analyzer.binned_accuracy, 0);
            testCase.verifyEqual(analyzer.two_tailed, 0);
            testCase.verifyEqual(analyzer.col, 300);
            testCase.verifyEqual(analyzer.residuals_predicted, [])

            % Model specification
            testCase.verifyEqual(analyzer.num_vars, [])
            testCase.verifyEqual(analyzer.model_def, [])
            testCase.verifyEqual(analyzer.pred_vars, {'pe','signed_pe','zsc_up','rt','xgaze','ygaze','zsc_condiff','baseline','reward','ecoperf','pe_condiff'});
            testCase.verifyEqual(analyzer.cat_vars, {'condition','reward','ecoperf'});
            testCase.verifyEqual(analyzer.resp_var, 'pupil');

            % Data
            testCase.verifyEqual(analyzer.preds_all, [])

            % File names
            testCase.verifyEqual(analyzer.betas_save, [])
            testCase.verifyEqual(analyzer.perm_save, [])
            testCase.verifyEqual(analyzer.residuals_save, [])
            testCase.verifyEqual(analyzer.predicted_save, [])
        end

        % ------------------------------------
        % Part 2: Functions from pupilReg_Vars
        % ------------------------------------

        function testSetSubjects(testCase)
            % Tests the setSubjects function in pupilReg_Vars.

            % Initialize pupil-regression object
            analyzer = PupilRegression_intHet();

            subj_ids = {'01', '02', '03'};
            num_sess = [1, 1, 2];
            analyzer.setSubjects(subj_ids, num_sess);

            testCase.verifyEqual(analyzer.subj_ids, subj_ids)
            testCase.verifyEqual(analyzer.num_sess, num_sess)
            testCase.verifyEqual(analyzer.num_subs, 3)
            testCase.verifyEqual(analyzer.model_type, 'OLS')
            testCase.verifyEqual(analyzer.n_sp, 20)

        end


        function testSetPaths(testCase)
            % Test the setPaths function in pupilReg_Vars.

            % Initialize pupil-regression object
            analyzer = PupilRegression_intHet();

            % Mock directories
            behv_dir = "my_path/raw_data";
            pupil_dir = "my_path/pupil";
            xgaze_dir = "my_path/x_gaze";
            ygaze_dir = "my_path/y_gaze";
            base_dir = "my_path/base_dir";
            save_dir = "my_path/save_dir";
            analyzer.setPaths(behv_dir, pupil_dir, xgaze_dir, ygaze_dir, base_dir, save_dir);

            testCase.verifyEqual(analyzer.behv_dir, behv_dir)
            testCase.verifyEqual(analyzer.pupil_dir, pupil_dir)
            testCase.verifyEqual(analyzer.xgaze_dir, xgaze_dir)
            testCase.verifyEqual(analyzer.ygaze_dir, ygaze_dir)
            testCase.verifyEqual(analyzer.base_dir, base_dir)
            testCase.verifyEqual(analyzer.save_dir, save_dir)
        end


        function testSetModel(testCase)
            % Tests the setModel in pupilReg_Vars.

            % Initialize pupil-regression object
            analyzer = PupilRegression_intHet();

            % Set model parameters
            model_def = 'y ~ a + b';
            pred_vars = {'a','b','c'};
            cat_vars = {'d','e','f'};
            num_vars = length(pred_vars);

            analyzer.setModel(model_def, pred_vars, cat_vars, num_vars);

            testCase.verifyEqual(analyzer.model_def, model_def)
            testCase.verifyEqual(analyzer.pred_vars, pred_vars)
            testCase.verifyEqual(analyzer.cat_vars, cat_vars)
            testCase.verifyEqual(analyzer.num_vars, num_vars)
        end

        function testSetFilenames(testCase)
            % Tests the setFilenames function.

            % Initialize pupil-regression object
            analyzer = PupilRegression_intHet();

            betas_save = 'a';
            perm_save = 'b';
            residuals_save = 'c';
            predicted_save = 'd';

            analyzer.setFileNames(betas_save, perm_save, residuals_save, predicted_save);

            testCase.verifyEqual(analyzer.betas_save, betas_save);
            testCase.verifyEqual(analyzer.perm_save, perm_save);
            testCase.verifyEqual(analyzer.residuals_save, residuals_save);
            testCase.verifyEqual(analyzer.predicted_save, predicted_save);
        end

        % ------------------------------------
        % Part 3: Core pupilRegression methods
        % ------------------------------------

        function testRunAnalysisOLS(testCase)
            % Tests the runAnalysis function with OLS appraoch.

            % Import mocking methods
            import matlab.mock.actions.Invoke

            % Create mock with which we mock out runPermuationTest
            % and processSubject. The rest remains consistent with
            % original function. We use the TestPupilRegression helper
            % class with mock processSubject function
            [mockAnalyzer, behavior] = testCase.createMock( ...
                ?TestPupilRegression, ...
                "MockedMethods", "runPermutationTest");

            % Define output behavior of mocked runPermutationTest function
            when( ...
                withAnyInputs(behavior.runPermutationTest), ...
                Invoke(@(~) assignSignificance(mockAnalyzer)) ...
                );

            % Create helper function for permutation-test output
            function assignSignificance(obj)
                obj.perm_results = struct('p_value', 0.01);
            end

            % Set attributes for test case
            mockAnalyzer.col = 1;
            mockAnalyzer.subj_ids = {"001", "003","003"};
            mockAnalyzer.behv_dir = "my_path/raw_data";
            mockAnalyzer.pupil_dir = "my_path/pupil";
            mockAnalyzer.model_def = 'y ~ a + b';
            mockAnalyzer.num_vars = 2;
            mockAnalyzer.num_subs = 3;

            % obj.betas_struct.with_intercept is filled in function
            % processSubject. Therefore also sequentially fill this when mocking.
            [betas, perm] = mockAnalyzer.runAnalysis();

            % Expected output
            num_bins = 1;
            expected_betas = nan(num_bins, mockAnalyzer.num_vars+1, mockAnalyzer.num_subs, mockAnalyzer.col);
            expected_betas(:,:,1) = 1;
            expected_betas(:,:,2) = 2;
            expected_betas(:,:,3) = 3;

            testCase.verifyEqual(perm.p_value, 0.01)
            testCase.verifyEqual(betas.with_intercept, expected_betas)
            testCase.verifyEqual(mockAnalyzer.betas_struct.with_intercept, expected_betas)

        end


        function testRunAnalysisHet(testCase)
            % Tests the runAnalysis function with regression accounting for
            % heteroskedasticity.

            % Import mocking methods
            import matlab.mock.actions.Invoke

            % Create mock with which we mock out runPermuationTest
            % and processSubject. The rest remains consistent with
            % original function. We use the TestPupilRegression helper
            % class with mock processSubject function
            [mockAnalyzer, behavior] = testCase.createMock( ...
                ?TestPupilRegression, ...
                "MockedMethods", "runPermutationTest");

            % Define output behavior of mocked runPermutationTest function
            when( ...
                withAnyInputs(behavior.runPermutationTest), ...
                Invoke(@(~) assignSignificance(mockAnalyzer)) ...
                );

            % Create helper function for permutation-test output
            function assignSignificance(obj)
                obj.perm_results = struct('p_value', 0.01);
            end

            % Set attributes for test case
            mockAnalyzer.model_type = 'heteroskedastic';
            mockAnalyzer.col = 1;
            mockAnalyzer.subj_ids = {"001", "003","003"};
            mockAnalyzer.behv_dir = "my_path/raw_data";
            mockAnalyzer.pupil_dir = "my_path/pupil";
            mockAnalyzer.model_def = 'y ~ a + b';
            mockAnalyzer.num_vars = 2;
            mockAnalyzer.num_subs = 3;

            % obj.betas_struct.with_intercept is filled in function
            % processSubject. Therefore also sequentially fill this when mocking.
            [betas, perm] = mockAnalyzer.runAnalysis();

            % Expected output
            num_bins = 1;
            expected_betas = nan(num_bins, mockAnalyzer.num_vars+1, mockAnalyzer.num_subs, mockAnalyzer.col);
            expected_betas(:,:,1) = 1;
            expected_betas(:,:,2) = 2;
            expected_betas(:,:,3) = 3;

            % Todo: Het currently does not compute the p-value within the
            % function, but this should absolutely be done.
            % testCase.verifyEqual(perm.p_value, 0.01)
            testCase.verifyEqual(betas.with_intercept, expected_betas)
            testCase.verifyEqual(mockAnalyzer.betas_struct.with_intercept, expected_betas)

        end


        function testProcessSubject(testCase)
            % Tests the processSubject function.

            % Since this is sort of a wrapper function, we mock out
            % multiple methods
            [mockPupilRegression, behavior] = testCase.createMock(?PupilRegression_intHet, ...
                "ConstructorInputs", {1}, ...
                "MockedMethods", ["loadBehavioralData",...
                "handleMissedTrials", "loadPupilGazeData",...
                "loadBaselineData", "getBehavioralPredictors",...
                "processBinsAndTimepoints"]);

            % Define the behvior of the mock functions
            testCase.assignOutputsWhen(withAnyInputs(behavior.loadBehavioralData), 1);
            testCase.assignOutputsWhen(withAnyInputs(behavior.handleMissedTrials), 1,2,3);
            testCase.assignOutputsWhen(withAnyInputs(behavior.loadPupilGazeData), 1,2,3);
            testCase.assignOutputsWhen(withAnyInputs(behavior.loadBaselineData), 1);
            testCase.assignOutputsWhen(withAnyInputs(behavior.getBehavioralPredictors), 1,2,3,4,5,6);
            testCase.assignOutputsWhen(withAnyInputs(behavior.processBinsAndTimepoints), 0);

            mockPupilRegression.subj_ids = {"001", "002", "003"};

            % Run function
            mockPupilRegression.processSubject(1, 1);

            % Verify calls of function
            testCase.verifyCalled(withAnyInputs(behavior.loadBehavioralData));
            testCase.verifyCalled(withAnyInputs(behavior.handleMissedTrials));
            testCase.verifyCalled(withAnyInputs(behavior.loadPupilGazeData));
            testCase.verifyCalled(withAnyInputs(behavior.loadBaselineData));
            testCase.verifyCalled(withAnyInputs(behavior.getBehavioralPredictors));
            testCase.verifyCalled(withAnyInputs(behavior.processBinsAndTimepoints));

            % Verify input to processBinsAndTimepoint, where regression
            % model is implemented
            testCase.verifyCalled(behavior.processBinsAndTimepoints(...
                1, ... % preds
                2, ... % zsc_pupil
                3, ... % xgaze_signal
                4, ... % ygaze_signal
                5, ... % behv_data
                6, ... % zsc_base
                1, ... % subj_idx
                1));   % binnedAnalysiss
        end


        function testLoadBehavioralData(testCase)
            % Tests the loadBehavioralData function.

            % Define temporary test environment
            testDir = fullfile(pwd, 'temp_test_data');
            if ~exist(testDir, 'dir'), mkdir(testDir); end

            % Ensure the directory is deleted after the test, even if it fails
            testCase.addTeardown(@() rmdir(testDir, 's'));

            % Create mock table
            numRows = 5;
            dummyData = array2table(zeros(numRows, 16));
            extraData = table(repmat(0.5, numRows, 1), repmat(10, numRows, 1), ...
                'VariableNames', {'choice.rt', 'slider_respond.response'});
            mockTable = [dummyData, extraData];

            % Save mock table for testing
            subjID = '001';
            sessNum = 1;
            filename = [subjID, '_main', num2str(sessNum), '.xlsx'];
            fullFilePath = fullfile(testDir, filename);
            writetable(mockTable, fullFilePath);

            % Initialize analyzer
            analyzer = PupilRegression_intHet();
            analyzer.behv_dir = testDir;
            analyzer.subj_ids = {subjID};
            analyzer.num_sess = 1;
            
            % Run the function
            behv_data = analyzer.loadBehavioralData(1);

            % Verfify everything is loaded correctly
            testCase.verifyClass(behv_data, 'table');
            testCase.verifyEqual(height(behv_data), numRows);
            testCase.verifyTrue(any(strcmp(behv_data.Properties.VariableNames, 'rt')));
            testCase.verifyEqual(behv_data.rt(1), 0.5);
            testCase.verifyTrue(any(strcmp(behv_data.Properties.VariableNames, 'slider')));
            testCase.verifyEqual(behv_data.slider(1), 10);
        end


        function testHandleMissedTrials(testCase)
            % Tests the handleMissedTrials function.

            % Initialize pupil-regression object
            analyzer = PupilRegression_intHet();

            % Create behavioral data
            % We have 2 nan values that are expected to be removed.
            % And 1 on the slider.
            subj_id = [1; 2; 3; 4; 5];
            rt      = [nan; 0.61; 0.55; 0.80; 0.21];
            group   = {'A'; 'B'; 'A'; 'B'; "A"};
            slider = [0.5; nan; 0.6; 0.7; 0.8];
            behv_data_input = table(subj_id, rt, group, slider, ...
                'VariableNames', {'ID', 'rt', 'group', 'slider'});

            expected_behv_data = behv_data_input(3:end,:);
            expected_missedtrials_slider = logical([1; 0; 0; 0]);

            [behv_data, missedtrials_slider] =...
                analyzer.handleMissedTrials(behv_data_input);
            testCase.verifyEqual(behv_data, expected_behv_data);
            testCase.verifyEqual(missedtrials_slider, expected_missedtrials_slider);
            
        end


        function testLoadPupilGazeData(testCase)
            % Tests the loadPupilGazeData function.

            % Define the temporary test environments
            % for the different directories
            pupil_dir = fullfile(pwd, 'temp_pupil_dir');
            if ~exist(pupil_dir, 'dir'), mkdir(pupil_dir); end

            xgaze_dir = fullfile(pwd, 'temp_xgaze_dir');
            if ~exist(xgaze_dir, 'dir'), mkdir(xgaze_dir); end

            ygaze_dir = fullfile(pwd, 'temp_ygaze_dir');
            if ~exist(ygaze_dir, 'dir'), mkdir(ygaze_dir); end

            % Ensure the directories are deleted after the test, even if it fails
            testCase.addTeardown(@() rmdir(pupil_dir, 's'));
            testCase.addTeardown(@() rmdir(xgaze_dir, 's'));
            testCase.addTeardown(@() rmdir(ygaze_dir, 's'));

            % Create mock table
            dummyData = zeros(10, 10);

            % Save mock table for testing
            % ---------------------------

            % Subject info
            subj_idx = 1;
            subjID = '001';

            % Pupil directory
            pupil_dir = fullfile(pwd, 'temp_pupil_dir');
            filename_pupil = [subjID, '.mat'];
            fullFilePathPupil = fullfile(pupil_dir, filename_pupil);
            save(fullFilePathPupil, 'dummyData');

            % xgaze directory
            xgaze_dir = fullfile(pwd, 'temp_xgaze_dir');
            filename_xgaze = [subjID, '.mat'];
            fullFilePathXGaze = fullfile(xgaze_dir, filename_xgaze);
            save(fullFilePathXGaze, 'dummyData');

            % ygaze directory
            ygaze_dir = fullfile(pwd, 'temp_ygaze_dir');
            filename_ygaze = [subjID, '.mat'];
            fullFilePathYGaze = fullfile(ygaze_dir, filename_ygaze);
            save(fullFilePathYGaze, 'dummyData');

            % Initialize analyzer and add directory info for testing
            analyzer = PupilRegression_intHet();
            analyzer.pupil_dir = pupil_dir;
            analyzer.xgaze_dir = xgaze_dir;
            analyzer.ygaze_dir = ygaze_dir;
            analyzer.subj_ids = {'001', '002', '003'};
            analyzer.col = 5;

            % Set missedtrials
            missedtrials = zeros(10,1);
            missedtrials(2:3) = 1;
            missedtrials = logical(missedtrials);

            % Set missedtrials_slider
            missedtrials_slider = missedtrials;
            missedtrials_slider(10) = 1;
            missedtrials_slider = logical(missedtrials_slider);

            % Test "feedback" case
            [zsc_pupil, xgaze_signal, ygaze_signal] =...
                analyzer.loadPupilGazeData(subj_idx, missedtrials_slider);
            verifyTrue(testCase, all(size(zsc_pupil) == [7,5]));
            verifyTrue(testCase, all(size(xgaze_signal) == [7,5]));
            verifyTrue(testCase, all(size(ygaze_signal) == [7,5]));

            % Test "patch" case
            analyzer.timewindow = 'patch';

            [zsc_pupil, xgaze_signal, ygaze_signal] =...
                analyzer.loadPupilGazeData(subj_idx, missedtrials_slider);
            verifyTrue(testCase, all(size(zsc_pupil) == [7,10]));
            verifyTrue(testCase, all(size(xgaze_signal) == [7,10]));
            verifyTrue(testCase, all(size(ygaze_signal) == [7,10]));
            verifyTrue(testCase, analyzer.col == 10);
        end


        function testGetBehavioralPredictors(testCase)
            % Tests the getBehavioralPredictors function.

            % Create preds_all
            id = [1; 1; 1; 1; 1];
            rt = [nan; 0.61; 0.55; 0.80; 0.21];
            group = {'A'; 'B'; 'A'; 'B'; 'A'};
            slider = [0.5; 0.5; 0.6; 0.7; 0.8];
            pe = [1; 1; 1; 0; 1];
            preds_all = table(id, rt, group, slider, pe,...
                'VariableNames', {'id', 'rt', 'group', 'slider', 'pe'});

            % For simplicity, take the same for behv_data
            behv_data = preds_all;

            % Create other input variables; nothing removed yet
            zsc_pupil = zeros(5, 5);
            xgaze_signal = zeros(5, 5);
            ygaze_signal = zeros(5, 5);

            % Initialize analyzer
            analyzer = PupilRegression_intHet();

            % Input variables and attributes
            subj_idx = 1;
            zsc_base = [];
            analyzer.preds_all = preds_all; % defined in config file
            analyzer.subj_ids = {"001"; "002"; "003"; "004"; "005"};

            [preds, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base]...
                = analyzer.getBehavioralPredictors(subj_idx, zsc_pupil, xgaze_signal, ygaze_signal, behv_data, zsc_base);

            % We expect 4 rows left (PE = 0)
            verifyTrue(testCase, all(size(preds) == [4,5]));
            verifyTrue(testCase, all(size(zsc_pupil) == [4,5]));
            verifyTrue(testCase, all(size(xgaze_signal) == [4,5]));
            verifyTrue(testCase, all(size(ygaze_signal) == [4,5]));
            verifyTrue(testCase, all(size(behv_data) == [4,5]));
            testCase.verifyEmpty(zsc_base);
        end


        function testProcessBinsAndTimepointsWbinnedAnalysis(testCase)
            % Test processBinsAndTimepoints function.
            %
            % In this case with binnedAnalysis == 1

            % Mock out two functions and define their behavior
            [mockPupilRegression, behavior] = testCase.createMock(?PupilRegression_intHet, ...
                "ConstructorInputs", {1}, ...
                "MockedMethods", ["getBinnedData", "fitModelAtTimepoint"]);
            testCase.assignOutputsWhen(withAnyInputs(behavior.getBinnedData), 1, 2, 3, 4, 5);
            testCase.assignOutputsWhen(withAnyInputs(behavior.fitModelAtTimepoint), 0);

            % Add attributes for testing
            mockPupilRegression.residuals_predicted = 1;
            mockPupilRegression.col = 3;

            % Todo: function has not output anymore. Adjust test
            % accordingly
            mockPupilRegression.processBinsAndTimepoints(1, 2, 3, 4, 5, 6, 7, true);
            
            % Verify input to fitModelAtTimepoint, where regression
            % model is implemented
            testCase.verifyCalled(behavior.fitModelAtTimepoint(...
                1, ... % c
                1, ... % pupil_signal_bins
                2, ... % xgaze_signal_bins
                3, ... % ygaze_signal_bins
                4, ... % preds_bins
                6, ... % zsc_base
                1, ... % r
                7));   % % subj_idx
        end


        function testProcessBinsAndTimepointsNobinnedAnalysis(testCase)
            % Test processBinsAndTimepoints function.
            %
            % In this case w binnedAnalysis == 0

            % Mock out two functions and define their behavior
            [mockPupilRegression, behavior] = testCase.createMock(?PupilRegression_intHet, ...
                "ConstructorInputs", {1}, ...
                "MockedMethods", "fitModelAtTimepoint");
            testCase.assignOutputsWhen(withAnyInputs(behavior.fitModelAtTimepoint), 40, 50, 60);

            % Add attributes for testing
            mockPupilRegression.residuals_predicted = 1;
            mockPupilRegression.col = 3;

            % Todo: function has not output anymore. Adjust test
            % accordingly
            mockPupilRegression.processBinsAndTimepoints(1, 2, 3, 4, 5, 6, 7, false);
           
            % Verify input to fitModelAtTimepoint, where regression
            % model is implemented
            testCase.verifyCalled(behavior.fitModelAtTimepoint(...
                1, ... % c
                2, ... % pupil_signal_bins
                3, ... % xgaze_signal_bins
                4, ... % ygaze_signal_bins
                1, ... % preds_bins
                6, ... % zsc_base
                1, ... % r
                7));   % % subj_idx
        end


        function testGetBinnedData(testCase)
            % Test getBinnedData function.

            % Input variable
            id = [1; 1; 1; 1; 1];
            rt = [nan; 0.61; 0.55; 0.80; 0.21];
            group = {'A'; 'B'; 'A'; 'B'; 'A'};
            slider = [0.5; nan; 0.6; 0.7; 0.8];
            pe = [1; 1; 1; 0; 1];
            preds = table(id, rt, group, slider, pe,...
                'VariableNames', {'id', 'rt', 'group', 'slider', 'pe'});

            % Define other input variables
            zsc_pupil = zeros(5, 5);
            xgaze_signal = zeros(5, 5);
            ygaze_signal = zeros(5, 5);

            % Non-binned case: we expect that all variables are literally
            % used (note in this case function should not even be called)
            analyzer = PupilRegression_intHet();
            analyzer.binned = 0;
            analyzer.binned_accuracy = 0;
            r = nan;

            [pupil_bins, xgaze_bins, ygaze_bins, preds_bins] =...
                analyzer.getBinnedData(r, preds, zsc_pupil, xgaze_signal, ygaze_signal);
            verifyTrue(testCase, all(size(pupil_bins) == size(zsc_pupil)));
            verifyTrue(testCase, all(size(xgaze_bins) == size(xgaze_signal)));
            verifyTrue(testCase, all(size(ygaze_bins) == size(ygaze_signal)));
            verifyTrue(testCase, all(size(preds_bins) == size(preds)));
        end

        function testFitModelAtTimepoint(testCase)
            % Test fitModelAtTimepoint function

            % Initialize analyzer
            analyzer = PupilRegression_intHet();

            % Define mock data
            mockBetas = [2, 10, 7, 1];
            mockResid = 40;
            mockPrediction = 99;

            % Create a mock prediction variable returned when LM predict is
            % called in the class
            mockLM = struct();
            mockLM.predict = @(varargin) mockPrediction;

            % Linear model mock R2
            mockLM.Rsquared.Adjusted = 0.2;
            mockLM.Rsquared.Ordinary = 0.3;

            % todo: only save temporarily for testing!
            mockLM.CoefficientNames = {'(Intercept)', 'xgaze', 'ygaze', 'zsc_condiff', 'pe', 'zsc_up', 'rt', 'zsc_condiff:pe'};

            % Use mock function for linear_fit via new handle construction
            analyzer.externalFitFcn = @(varargin) deal(mockBetas, [], mockResid, [], mockLM);

            % Mock save function
            analyzer.saveFcn = @(path, data) captureSave(path, data);
            
            % Captured path and data
            capturedPath = '';
            capturedData = {};
            
            % Trap function
            function captureSave(path, data)
                capturedPath = path;
                capturedData = data;
            end

            % Start defining and building the input variables
            % -----------------------------------------------

            % Current timepoint index
            c = 1;

            % Pupil and gaze data
            n_trials = 5;
            n_bins = 10;
            pupil_signal_bins = ones(n_bins, n_trials);
            xgaze_signal_bins = ones(n_bins, n_trials);
            ygaze_signal_bins = ones(n_bins, n_trials);

            % Behavioral data in "preds_bins"
            pupil = ones(n_bins, 1);
            xgaze = ones(n_bins, 1);
            ygaze = ones(n_bins, 1);
            con_diff = ones(n_bins, 1);
            signed_pe = ones(n_bins, 1);
            pe = ones(n_bins, 1);
            up = ones(n_bins, 1);
            rt = ones(n_bins, 1);
            condition = {'A'; 'B'; 'A'; 'B'; 'A'; 'B'; 'A'; 'B'; 'A'; 'B'};
            ecoperf = ones(n_bins, 1);
            correct = ones(n_bins, 1);
            pe_condiff = ones(n_bins, 1);
            preds_bins = table(pupil, xgaze, ygaze, ...
                con_diff, signed_pe, pe, up, rt, condition, ecoperf, correct, pe_condiff,...
                'VariableNames', {'pupil', 'xgaze', 'ygaze', ...
                'con_diff', 'signed_pe', 'pe', 'up', 'rt', 'condition', 'ecoperf', 'correct', 'pe_condiff'});

            zsc_base = nan; % baseline data
            r = 5; % current bin index
            subj_idx = 1; % current subject index

            % Define analyzer attributes
            analyzer.num_vars = 3;
            analyzer.num_subs = 1;
            analyzer.col = 1;
            analyzer.betas_struct.with_intercept = nan(n_bins, analyzer.num_vars+1, analyzer.num_subs, analyzer.col);
            
            analyzer.betas_save = 'unit_test';
            % Run function
            analyzer.fitModelAtTimepoint(c, pupil_signal_bins, xgaze_signal_bins, ygaze_signal_bins, preds_bins, zsc_base, r, subj_idx);
           
            % Expected properties
            expected_betas_struct = nan(n_bins, analyzer.num_vars+1, analyzer.num_subs, analyzer.col);
            expected_betas_struct(r, :) = mockBetas;
            expectedRsquaredAdjusted = zeros(5, 1);
            expectedRsquaredAdjusted(end,1) = mockLM.Rsquared.Adjusted;
            expectedRsquaredOrdinary = zeros(5, 1);
            expectedRsquaredOrdinary(end,1) = mockLM.Rsquared.Ordinary;
            
            % Test updated properties
            testCase.verifyEqual(analyzer.betas_struct.with_intercept, expected_betas_struct);
            testCase.verifyEqual(analyzer.rsquaredAdjusted, expectedRsquaredAdjusted) % todo: preallocate in class like beta_struct
            testCase.verifyEqual(analyzer.rsquaredOrdinary, expectedRsquaredOrdinary) % todo: preallocate in class like beta_struct
            
            % Check that the path contains the expected string
            testCase.verifyTrue(contains(capturedPath, '_coeffNames.mat'));
            
            % Check that data was actually saved
            testCase.verifyNotEmpty(capturedData);
        
        end
    end

end