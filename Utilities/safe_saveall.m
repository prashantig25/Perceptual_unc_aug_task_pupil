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
        equality_check = isequaln(round(newData,5), round(oldData,5));
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

                % Extract data
                colNew = newData{:,col};
                colOld = oldData{:,col};

                % Compute differences
                absDiff = abs(colNew - colOld);
                denom = abs(colOld);
                validMask = ~isnan(colNew) & ~isnan(colOld); % ignore rows where either is NaN                nanMismatch = isnan(colNew) ~= isnan(colOld);  % one-sided NaN: real diff
                nanMismatch = isnan(colNew) ~= isnan(colOld);

                % Define a fFloor" for near-zero values (anything below 0.001 is noise)
                nearZeroLimit = 1e-3;
                mask_large = (denom >= nearZeroLimit) & validMask;
                mask_small = (denom < nearZeroLimit) & validMask;
                
                % Tolearance
                relTol = 1e-3;
                absTol = 1e-4;

                % Identify Violations
                fail_large = any(absDiff(mask_large) ./ denom(mask_large) > relTol);
                fail_small = any(absDiff(mask_small) > absTol);
                
                % Perform the check and indicate larger differences
                col_check = ~any(nanMismatch) && ~fail_large && ~fail_small;

                if ~col_check
                    fprintf('MISMATCH at col %d (%s)\n', col, newData.Properties.VariableNames{col});

                    if any(nanMismatch)
                        fprintf('NaN Mismatch detected.\n');
                    end
                    if fail_large
                        max_rel = max(absDiff(mask_large) ./ denom(mask_large));
                        fprintf('Large Values: Max Rel Error: %.4f%% (Limit: %.2f%%)\n', ...
                            max_rel * 100, relTol * 100);
                    end
                    if fail_small
                        max_abs = max(absDiff(mask_small));
                        fprintf('Near-Zero: Max Abs Diff: %.6f (Limit: %.6f)\n', ...
                            max_abs, absTol);
                    end
                end
               
            else
                col_check = isequaln(colNew, colOld);
                if ~col_check
                    % Fallback: compare as strings to handle char/string mismatches
                    try
                        col_check = isequal(string(colNew), string(colOld));
                    catch
                        col_check = false;
                    end
                end
            end

            equality_check = equality_check && col_check;
        end
    elseif iscell(newData)
        if ~isequal(size(newData), size(oldData))
            equality_check = false;
            fprintf('MISMATCH: size differs. newData=%s, oldData=%s\n', ...
                mat2str(size(newData)), mat2str(size(oldData)));
        else
            equality_check = true;
            for row = 1:numel(newData)
                a = newData{row};
                b = oldData{row};

                if isnumeric(a) && isnumeric(b)
                    absDiff = abs(a - b);
                    denom = abs(b);
                    nearZero = denom < 1e-2;
                    validMask = ~isnan(absDiff);
                    nanMismatch = isnan(a) ~= isnan(b);

                    row_check = ~any(nanMismatch) && ...
                        all(absDiff(~nearZero & validMask) ./ denom(~nearZero & validMask) < 1e-2, 'all') && ...
                        all(absDiff(nearZero & validMask) < 1e-4, 'all');
                else
                    row_check = isequaln(a, b);
                end

                if ~row_check
                    fprintf('MISMATCH at row %d: maxAbsDiff=%.2e, maxRelDiff=%.2e\n', ...
                        row, max(abs(a-b), [], 'all'), max(abs(a-b)./abs(b), [], 'all'));
                end

                equality_check = equality_check && row_check;
            end
        end
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