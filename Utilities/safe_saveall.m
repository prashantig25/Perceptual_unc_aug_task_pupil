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
            colNew = newData{:,col};
            colOld = oldData{:,col};

            if numericCols(col)
                absDiff = abs(colNew - colOld);
                denom = abs(colOld);
                nearZero = denom < 1e-2;
                validMask = ~isnan(absDiff);          % NaN-NaN pairs: skip
                nanMismatch = isnan(colNew) ~= isnan(colOld);  % one-sided NaN: real diff

                col_check = ~any(nanMismatch) && ...
                    all(absDiff(~nearZero & validMask) ./ denom(~nearZero & validMask) < 1e-2, 'all') && ...
                    all(absDiff(nearZero & validMask) < 1e-4, 'all');
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

            if ~col_check
                fprintf('MISMATCH at col %d (%s)\n', col, newData.Properties.VariableNames{col});
                if ~numericCols(col)
                    fprintf('  newData class: %s\n', class(colNew));
                    fprintf('  oldData class: %s\n', class(colOld));
                end

                % --- EXTENDED DIAGNOSTIC REPORT ---
                % 1. Identify where Nans don't match
                nan_mismatch_idx = find(nanMismatch);
                
                % 2. Calculate the specific violations
                rel_errors = absDiff ./ denom;
                mask_large = ~nearZero & validMask;
                mask_small = nearZero & validMask;
                
                fail_large_idx = find(mask_large & (rel_errors >= 1e-2));
                fail_small_idx = find(mask_small & (absDiff >= 1e-4));
                
                % 3. Print Summary to Command Window
                %fprintf('\n--- Consistency Report for Subject %s ---\n', subj_ids{s});
                if ~any(nanMismatch) && isempty(fail_large_idx) && isempty(fail_small_idx)
                    fprintf('✅ PASS: All values within tolerance.\n');
                else
                    fprintf('❌ FAIL: Discrepancies detected.\n');
                    
                    if ~isempty(nan_mismatch_idx)
                        fprintf('  - NaN Mismatch: %d samples differ in NaN placement.\n', length(nan_mismatch_idx));
                    end
                    
                    if ~isempty(fail_large_idx)
                        max_rel = max(rel_errors(mask_large));
                        fprintf('  - Large Values: %d violations. Max Rel Error: %.4f%%\n', ...
                            length(fail_large_idx), max_rel * 100);
                        fprintf('    Typical Index of failure: %d\n', fail_large_idx(1));
                    end
                    
                    if ~isempty(fail_small_idx)
                        max_abs = max(absDiff(mask_small));
                        fprintf('  - Near-Zero Values: %d violations. Max Abs Diff: %.6f\n', ...
                            length(fail_small_idx), max_abs);
                    end
                    
                    % 4. Visualizing the "Shape" of the error
                    %figure('Name', ['Error Profile: ' subj_ids{s}]);
                    subplot(2,1,1);
                    plot(absDiff);
                    title('Absolute Difference over Time');
                    ylabel('Difference'); xlabel('Sample Index');
                    
                    subplot(2,1,2);
                    plot(rel_errors);
                    ylim([0 0.05]); % Cap at 5% to see detail
                    title('Relative Error (capped at 5%)');
                    ylabel('Rel Error'); xlabel('Sample Index');
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