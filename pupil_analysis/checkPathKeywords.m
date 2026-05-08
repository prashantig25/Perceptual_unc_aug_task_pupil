function checkPathKeywords(dirs, keywords)
% checkPathKeywords  Check one or more directory paths for keyword variants.
%
%   checkPathKeywords(dirs, keywords)
%
%   INPUTS:
%     dirs     - char (single path) OR cell array of {name, path} pairs
%                e.g. {'pupil_dir', pupil_dir; 'xgaze_dir', xgaze_dir; ...}
%     keywords - cell array of keyword strings to search for
%                e.g. {'linearInt', 'linear int', 'linear Int', 'LinearInt'}
%
%   EXAMPLE:
%     dirs = {'pupil_dir', pupil_dir; 'xgaze_dir', xgaze_dir; ...
%             'ygaze_dir', ygaze_dir; 'base_dir',  base_dir};
%     keywords = {'linearInt', 'linear int', 'linear Int', 'LinearInt'};
%     checkPathKeywords(dirs, keywords);

    colW = [15, 30, 70];
    sepLine = repmat('-', 1, sum(colW) + 7);

    fprintf('\n=== Path Keyword Check ===\n');
    fprintf('%-*s | %-*s | %s\n', colW(1), 'Variable', colW(2), 'Matched Keywords', 'Full Path');
    fprintf('%s\n', sepLine);

    for i = 1:size(dirs, 1)
        varName  = dirs{i, 1};
        fullPath = dirs{i, 2};

        matched = {};
        for j = 1:numel(keywords)
            if contains(fullPath, keywords{j}, 'IgnoreCase', false)
                matched{end+1} = keywords{j}; %#ok<AGROW>
            end
        end

        if isempty(matched)
            matchStr = 'ERROR';
        else
            matchStr = strjoin(matched, ', ');
        end

        fprintf('%-*s | %-*s | %s\n', colW(1), varName, colW(2), matchStr, fullPath);
    end

    fprintf('%s\n\n', sepLine);
end