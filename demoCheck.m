clc
clearvars

folderPath = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 6/pupil_data/pre_preprocessed/behv/personal_info";
files = dir(fullfile(folderPath, '*.*'));
files = files(~[files.isdir]);

formResponses   = {};   % form_index == 1  (gender)
ageResponses    = {};   % form_index == 13
fileNames       = {};

for i = 1:length(files)
    fileName = files(i).name;
    fullPath = fullfile(folderPath, fileName);
    [~, ~, ext] = fileparts(fileName);
    
    try
        switch lower(ext)
            case {'.csv', '.xlsx'}
                T = readtable(fullPath);
            case '.mat'
                data = load(fullPath);
                T = struct2table(data);
            otherwise
                fprintf('Skipping unsupported file: %s\n', fileName);
                continue
        end
    catch ME
        fprintf('Error loading %s: %s\n', fileName, ME.message);
        continue
    end
    
    if ~ismember('form_index', T.Properties.VariableNames) || ...
       ~ismember('form_response', T.Properties.VariableNames)
        fprintf('Skipping %s: missing required columns\n', fileName);
        continue
    end
    
    % form_index == 1 (gender)
    idx1 = T.form_index == 1;
    if any(idx1)
        response = T.form_response(idx1);
        formResponses{end+1} = response;
        fileNames{end+1}     = fileName;
    end
    
    % form_index == 13
    idx13 = T.form_index == 13;
    if any(idx13)
        ageResponses{end+1} = T.form_response(idx13);
    end
end

% --- Gender distribution ---
summaryTable = table(fileNames', formResponses', 'VariableNames', {'FileName', 'FormResponse'});
genderDist   = cell2mat(summaryTable.FormResponse);
fprintf('Gender 0: %d\n', sum(genderDist == 0));
fprintf('Gender 1: %d\n', sum(genderDist == 1));
fprintf('Gender 2: %d\n', sum(genderDist == 2));

% --- form_index == 13: mean and SEM ---
responses13 = cell2mat(ageResponses');   % convert to numeric vector
meanVal = mean(responses13, 'omitnan');
semVal  = std(responses13, 'omitnan') / sqrt(sum(~isnan(responses13)));

fprintf('\nform_index 13 — Mean: %.2f, SEM: %.2f (n=%d)\n', meanVal, semVal, sum(~isnan(responses13)));

%% --- Missing participants ---
path2 = "/Users/prashantig/Brown Dropbox/Prashanti Ganesh/PhD/Semester 6/pupil_data/raw";
rawFolders = dir(path2);
rawFolders = rawFolders([rawFolders.isdir]);
rawFolders = rawFolders(~ismember({rawFolders.name}, {'.','..'}));
rawIDs     = string({rawFolders.name});
infoIDs    = replace(string(fileNames'), '_personal_info.csv', '');
missingIDs = setdiff(rawIDs, infoIDs);
fprintf('\nParticipants in raw but missing from personal_info (%d):\n', numel(missingIDs));
for i = 1:numel(missingIDs)
    fprintf('  %s\n', missingIDs(i));
end