function [asc] = read_eyelink_ascNK_AU(filename)

% READ_EYELINK_ASC reads the header information, input triggers, messages
% and all data points from an Eyelink *.asc file
%
% Niels Kloosterman edit: add blink parsing
% Use as
%   asc = read_eyelink_asc(filename)
% Anne Urai edit
% 1. parse channel names?
% 2. add header information

% Copyright (C) 2010, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id: read_eyelink_asc.m 945 2010-04-21 17:41:20Z roboos $

fprintf('reading in %s ...\n', filename);
fid = fopen(filename, 'rt');

asc.header  = {};
asc.msg     = {};
asc.input   = [];
asc.sfix    = {};
asc.efix    = {};
asc.ssacc   = {};
asc.esacc   = {};
asc.sblink  = {}; % NK edit: add blink parsing
asc.eblink  = {};
asc.fsample = []; % NK edit: add fsample
asc.dat     = [];
current   = 0;

while ~feof(fid)
    tline = fgetl(fid);
    
    if regexp(tline, '^[0-9]');
        tmp   = sscanf(tline, '%f');
        nchan = numel(tmp);
        current = current + 1;
        
        if size(asc.dat,1)<nchan
            % increase the allocated number of channels
            asc.dat(nchan,:) = 0;
        end
        
        if size(asc.dat, 2)<current
            % increase the allocated number of samples
            asc.dat(:,end+10000) = 0;
        end
        
        % add the current sample to the data matrix
        asc.dat(1:nchan, current) = tmp;
        
    elseif regexp(tline, '^INPUT')
        [val, num] = sscanf(tline, 'INPUT %d %d');
        this.timestamp = val(1);
        % this.value     = val(2);
        if isempty(asc.input)
            asc.input = this;
        else
            asc.input = cat(1, asc.input, this);
        end
        
    elseif regexp(tline, '\*\*.*')
        asc.header = cat(1, asc.header, {tline});
        
    elseif regexp(tline, '^MSG')
        asc.msg = cat(1, asc.msg, {tline});
        if regexp(tline, '!MODE RECORD CR')
            tok = tokenize(tline);
            asc.fsample = str2num(tok{6});
%             asc.fsample = 1000;
        end
        
    elseif regexp(tline, '^SFIX')
        asc.sfix = cat(1, asc.sfix, {tline});
        
    elseif regexp(tline, '^EFIX')
        asc.efix = cat(1, asc.efix, {tline});
        
    elseif regexp(tline, '^SSACC')
        asc.ssacc = cat(1, asc.ssacc, {tline});
        
    elseif regexp(tline, '^ESACC')
        asc.esacc = cat(1, asc.esacc, {tline});
        
    elseif regexp(tline, '^SBLINK')
        asc.sblink = cat(1, asc.sblink, {tline});
        
    elseif regexp(tline, '^EBLINK')
        asc.eblink = cat(1, asc.eblink, {tline});
        
    else
        % all other lines are not parsed
    end
end

% close the file
fclose(fid);

% remove the samples that were not filled with real data
asc.dat = asc.dat(:,1:current);

end

