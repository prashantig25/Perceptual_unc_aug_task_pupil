function areEqual = compareStructs(struct1, struct2, fieldPath, tol)
    % COMPARESTRUCTS Compare two structs for equality, treating NaNs as equal
    %   areEqual = compareStructs(struct1, struct2)
    %
    %   Inputs:
    %       struct1, struct2: The structs to compare
    %       fieldPath: Field path of the structures
    %       tol: Tolerance for approximate comparison
    %
    %   Output:
    %       areEqual: true if structs are equal (NaNs treated as equal), false otherwise
    
    % Track the field path for logging; default to 'root'
    if nargin < 3 || isempty(fieldPath)
        fieldPath = 'root';
    end

    % Tolerance on precision
    if nargin < 4 || isempty(tol)
        tol = 1e-12;
    end
    
    % Check if both inputs are structs
    if ~isstruct(struct1) || ~isstruct(struct2)
        areEqual = false;
        return;
    end
    
    % Get and compare field names (order-independent)
    fields1 = fieldnames(struct1);
    fields2 = fieldnames(struct2);
    
    if ~isequal(sort(fields1), sort(fields2))
        fprintf('Field Mismatch at %s: different field sets.\n', fieldPath);
        areEqual = false;
        return;
    end
    
    % Assume equal until proven otherwise
    areEqual = true;
    
    for i = 1:length(fields1)
        field = fields1{i};
        currentPath = [fieldPath, '.', field]; % Update path for this level
        val1 = struct1.(field);
        val2 = struct2.(field);
    
        % Recurse if the field value is itself a struct
        if isstruct(val1) && isstruct(val2)
            if ~compareStructs(val1, val2, currentPath)
                areEqual = false;  % keep going, do NOT return
            end
    
            % Handle numeric data with tolerance
        elseif isnumeric(val1) && isnumeric(val2)
            if ~isequal(size(val1), size(val2))
                fprintf('Size Mismatch at %s\n', currentPath);
                areEqual = false;
            else
                diffs = abs(val1 - val2);
                % Compare difference against tolerance, ignoring NaNs
                if any(diffs(:) > tol & ~isnan(diffs(:)))
                    maxDiff = max(diffs(~isnan(diffs)), [], 'all');
                    fprintf('Value Mismatch at %s: Max Diff = %.2e\n', currentPath, maxDiff);
                    areEqual = false;
                end
                % Ensure NaNs are in the same positions
                if any(isnan(val1(:)) ~= isnan(val2(:)))
                    fprintf('NaN Pattern Mismatch at %s\n', currentPath);
                    areEqual = false;
                end
            end
    
            % Handle cell arrays element-by-element
        elseif iscell(val1) && iscell(val2)
            if ~isequal(size(val1), size(val2))
                areEqual = false;  % keep going, do NOT return
            else
                for j = 1:numel(val1)
                    if isstruct(val1{j}) && isstruct(val2{j})
                        if ~compareStructs(val1{j}, val2{j})
                            areEqual = false;  % keep going, do NOT return
                        end
                    elseif ~isequaln(val1{j}, val2{j})
                        areEqual = false;  % keep going, do NOT return
                    end
                end
            end
    
        % General case: use isequaln to treat NaNs as equal
        else
            if ~isequaln(val1, val2)
                areEqual = false;  % keep going, do NOT return
            end
        end
    end
    end
