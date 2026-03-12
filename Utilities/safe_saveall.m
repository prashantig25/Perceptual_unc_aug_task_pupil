function safe_saveall(filename, newData)
% function SAFE_SAVEALL is a custom replacement for MATLAB's save function
% to ensure that data does not get saved unexpectedly.
% INPUTS:
%   filename: input string with filename
%   newData: input data that needs to be saved

% Check if file already exists
if isfile(filename)
    % Load the existing data
    if contains(filename, '.mat')
        oldData = importdata(filename);
        if isstruct(oldData) && isfield(oldData, 'newData')
            oldData = oldData.newData;
        end
        if iscell(oldData)
            dollarIdx = cellfun(@(x) ischar(x) && strcmp(x, '$'), oldData);
            oldData = oldData(~dollarIdx);
        end
    elseif contains(filename, '.csv') || contains(filename, '.txt') || contains(filename, '.xlsx')
        oldData = readtable(filename);
    else
        error('Unsupported file type.');
    end

    % Compare the new data with the old data
    if isa(newData, "double")
        equality_check = isequaln(round(newData,10), round(oldData,10));
    elseif strcmp(string(class(newData)), "LinearModel") == 1
        equality_check = compare_LinearModels(newData, oldData);
    elseif isstruct(newData)
        equality_check = compareStructs(newData, oldData);
    elseif istable(newData)
        % Compare tables with tolerance for numeric columns
        numericCols = varfun(@isnumeric, newData, 'OutputFormat', 'uniform');
        equality_check = true;
        for col = 1:width(newData)
            if numericCols(col)
                absDiff = abs(newData{:,col} - oldData{:,col});
                denom = abs(oldData{:,col});
                nearZero = denom < 1e-2;
                relDiff = absDiff(~nearZero) ./ denom(~nearZero);
                % fprintf('Col %d: maxAbsDiff=%.2e, maxRelDiff=%.2e\n', col, max(absDiff), max(relDiff));
                equality_check = equality_check && ...
                    all(absDiff(~nearZero) ./ denom(~nearZero) < 1e-2, 'all') && ...
                    all(absDiff(nearZero) < 1e-4, 'all');
            else
                equality_check = equality_check && ...
                    isequal(newData{:,col}, oldData{:,col});
            end
        end
    elseif iscell(newData)
        equality_check = all(cellfun(@(a,b) isequaln(a,b), newData, oldData));
    else
        equality_check = isequaln(newData, oldData);
    end

    if equality_check == 1
        disp('Data is consistent. No need to save.');
    else
        % For different data, create a new filename
        [path, name, ext] = fileparts(filename);
        timestamp = datestr(now, 'yymmdd');
        newFilename = strcat(name, "_", timestamp, ext);
        % Save with new filename
        if contains(ext, '.mat')
            save(fullfile(path, newFilename), 'newData');
        elseif contains(ext, '.csv') || contains(ext, '.txt') || contains(ext, '.xlsx')
            writetable(newData, fullfile(path, newFilename));
        end
        disp(['Data is different. Saved with a new filename: ' newFilename]);
    end
else
    % Save the new data
    if contains(filename, '.mat')
        save(filename, 'newData');
    elseif contains(filename, '.csv') || contains(filename, '.txt') || contains(filename, '.xlsx')
        writetable(newData, filename);
    else
        error('Unsupported file type.');
    end
    disp(['File does not exist. Saved data to: ' filename]);
end
end