basedir = '/home/daniel/PhD/paper2/data_management/data/';
sampleRate = 2; % in Hz
replaceData = true;
collectdir = fullfile(basedir,'collects_tpss');
processdir = fullfile(basedir, 'processed_tpss');
outFile = 'TPSS.csv';

% List data files
collectFiles = dir(collectdir);
isData = contains([string({collectFiles.name})],"analog.csv");
collectFiles = collectFiles(isData);

% convert file names to datetime objects
fileTime = [string({collectFiles.name})];
fileTime = strrep(fileTime,'-analog.csv','');
fileTime = strrep(fileTime,'T',' ');
fileTime = datetime(fileTime,'InputFormat','yyyy-MM-dd HH,mm,ss.SSS');
cutoffTime = datetime('2022-03-08 10,25','InputFormat','yyyy-MM-dd HH,mm');
isUTC = fileTime < cutoffTime;
fileTime(isUTC) = fileTime(isUTC) - hours(7);

% get paths for all data files
fileNames = [string({collectFiles.name})];
fileFolder = [string({collectFiles.folder})];
collectPaths = fullfile(fileFolder, fileNames);
nFile = numel(collectPaths);

% process each day and store as column in table
outTable = fullfile(processdir,outFile);
while(numel(collectPaths) > 0)

    % define output times
    currTime = min(fileTime);
    currTime.Hour = 0; currTime.Minute = 0; currTime.Second = 0;
    timeDelta = seconds(1/sampleRate);
    dayDelta = hours(24) - timeDelta;
    time = currTime:timeDelta:currTime + dayDelta;

    % read in corresponding files
    currFileIdx = fileTime >= time(1) & fileTime <= time(end);
    currFiles = collectPaths(currFileIdx);   
    currIsUTC = isUTC(currFileIdx);
    currData = [];
    for iFile = 1:numel(currFiles)
        currFile = currFiles(iFile);
        fileData = readtable(currFile);
        if currIsUTC(iFile)
            fileData.time = fileData.time - hours(7); % convert to MST
        end
        currData = [currData; fileData];                                   %#ok
    end
    fprintf("Day " + string(currTime) + " has %i values\n",size(currData,1));
    if size(currData,1) < 100
        fprintf("passed on day:" + string(currTime) + "\n")
        continue
    end

    % resample data
    currData.Units = [string(currData.Units)];
    powerData = currData(strcmp(currData.Units,"kW"),:);
    powerData = rmmissing(powerData);   
    if exist('powerDataPrev','var')
        powerData = [powerDataPrev; powerData];                            %#ok
    end

    % remove duplicates
    [~, ia,~] = unique(powerData.time);
    powerData = powerData(ia,:);

    % the scale should be on the order of 100+ kw, if lower, multiply by
    % 10. sometimes the data is given in 10s of kW.
    if max(powerData.Value) < 300
        powerData.Value = 10*powerData.Value;
        fprintf("Multipled data from " + string(currTime) +" By ten.\n");
        fprintf("Max value is now: %f\n",max(powerData.Value));
    end
    
    % remove extreme outliers
    outlierIdx = powerData.Value > 3000;
    if sum(outlierIdx > 0)
        fprintf("Removed outliers from " + string(currTime) + ".\n");
    end
    powerData.Value(powerData.Value > 3000) = 0;

    % resample the data by interpolation (no anti-alias filter)
    powerResample = interp1(powerData.time, powerData.Value,time,'spline',nan);
    powerDataPrev = powerData(powerData.time > time(end),:);
    powerDataPost = powerData(powerData.time < time(1),:);

    % export to file
    label = string(currTime);
    columnNames = string(0:1/sampleRate:24*3600 - 1/sampleRate);
    powerTable = array2table(powerResample,'RowNames',label,'VariableNames',columnNames);
    if isfile(outTable)
        writetable(powerTable,outTable,'WriteMode','append',"WriteRowNames",true);
    else
        writetable(powerTable, outTable, "WriteRowNames",true);
    end
    
    % remove processed files from the list
    collectPaths(currFileIdx) = [];
    fileTime(currFileIdx) = [];
    fprintf("processed data for: " + string(currTime) + "\n \n \n");
end
computeTpssCovariance;