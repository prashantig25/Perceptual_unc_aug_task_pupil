function mockData = saveMockData(testCase, testComputeConfirm)
% SAVEMOCKDATA Generates and saves data for the LR unit tests

if ~exist("testComputeConfirm", "var")
    testComputeConfirm = false;
end

% Define temporary test environment
testDir = fullfile(pwd, 'temp_test_data');
if ~exist(testDir, 'dir'), mkdir(testDir); end

% Ensure the directory is deleted after the test, even if it fails
testCase.addTeardown(@() rmdir(testDir, 's'));

if testComputeConfirm == 0

    % Create mock table
    slider = [40; NaN; 60; 70];
    mu = [0.4; 0.5; 0.6; 0.7];
    condition = [1; 1; 2; 2];
    correct = [1; 0; 1; 0];
    choice = [1; 1; 0; 0];
    state = [0; 1; 0; 1];
    trial = [1; 2; 3; 4];
    congruence = [1; 0 ; 1; 0];
    contrast = [1; 0; 1; 0];
    con_diff = [-0.1; -0.5; 0; 0.2];
    contrast_left = [0.6; 0.4; 0.4; 0.6];
    contrast_right = 1-contrast_left;

    mockData = table(slider, mu, condition, correct, choice, state,...
        trial, congruence, contrast, con_diff, contrast_left, contrast_right, ...
        'VariableNames', {'slider', 'mu', 'condition', 'correct', 'choice', 'state',...
        'trial', 'congruence', 'contrast', 'con_diff', 'contrast_left', 'contrast_right',});
else

    % Create mock table
    contrast = [0; 0; 0; 0; 1; 1; 1; 1];
    action =   [0; 0; 1; 1; 0; 0; 1; 1];
    state =    [0; 1; 0; 1; 0; 1; 0; 1];
    mockData = table(action, state, contrast,...
        'VariableNames', {'action', 'state', 'contrast'});

end

% Save mock table for testing
subjID = '001';
sessNum = 1;
filename = [subjID, '_main', num2str(sessNum), '.xlsx'];
fullFilePath = fullfile(testDir, filename);
writetable(mockData, fullFilePath);

end
