doClean = true;
visualizeData = true;
exportToFile = false;
doCombination = true;
labelWarning = 'MATLAB:table:ModifiedAndSavedVarnames';
warning('off',labelWarning)
basePath = '../data/';

if doClean
    % get files of data
    collectPath = fullfile(basePath,'collects'); 
    directories = dir(collectPath);
    isBusData = contains([string({directories.name})],"bus_data");
    directories = directories(isBusData);
    for iPath = 1:numel(directories)
        filepath = fullfile(directories(iPath).folder, directories(iPath).name);
        if exist('files','var')
            files = [files; dir(filepath)];
        else
            files = dir(filepath);
        end
    end   

    % remove directories and separate new flyer and UTA files
    files([files.isdir]) = [];
    fileName = string({files.name});
    isNewFlyer = contains(fileName,'New_Flyer');
    fileNewFlyer = files(isNewFlyer);
    fileUTA = files(~isNewFlyer);

    % extract, merge, sort, and remove duplicate data
    dataUta = extractAndClean(fileUTA);
    dataNewFlyer = extractAndClean(fileNewFlyer);

    % determine when a bus is in the hub
    dataUta = addInHubColumn(dataUta);
    dataNewFlyer = addInHubColumn(dataNewFlyer);
    utaPath = fullfile(basePath,'processed','dataUta.csv');
    nflPath = fullfile(basePath,'processed','dataNewFlyer.csv');
    writetable(dataUta,utaPath);
    writetable(dataNewFlyer,nflPath);
elseif doCombination
    dataUta = readtable('data_cleaned/dataUta.csv');
    dataNewFlyer = readtable('data_cleaned/dataNewFlyer.csv');
end

if doCombination
    % remove repeated data from new flyer and uta
    newFlyerBus = unique(dataNewFlyer.BusID);
    for iBus = 1:numel(newFlyerBus)
        dataUta(dataUta.BusID == newFlyerBus(iBus),:) = [];
    end
    dataCombined = [dataNewFlyer; dataUta];
    combinedPath = fullfile(basePath,'processed','dataCombined.csv');
    writetable(dataCombined,combinedPath);
    if visualizeData
        displayBusInfo(dataCombined);
    end
end

% verify that the data looks right.
if visualizeData && ~doCombination
   % displayBusInfo(dataUta);
    displayBusInfo(dataNewFlyer);
end

if exportToFile
    % load in data as needed
    if ~exist('dataCombined','var')
        dataCombined = readtable('data_cleaned/dataCombined.csv');
    end

    % initialize routes and times to export
    busId = [18151;... 15023; 15020; 15019;...
             ...15018; 15017; 15014; 15013;...
             ...15012; 15009; 15007; 15006;...
             ...15006; 15006; 15003...
             ];
    years = 2022*ones(size(busId)); months = 3*ones(size(busId)); 
    days = [4; 9; 14; 8; 8; 8; 11; 4; 4; 4; 12; 4; 8; 9; 9];
    dates = datetime(years, months, days);
    
    % add each element to the output results
    result = struct;
    waypointOffset = 0;
    clear('socTable');
    for iRoute = 1:numel(busId)
        id = busId(iRoute);
        timeStart = dates(iRoute);
        timeEnd = timeStart + hours(24);
        isBus = dataCombined.BusID == id;
        isTime1 = dataCombined.Time >= timeStart;
        isTime2 = dataCombined.Time < timeEnd;
        selectedIdx = isBus & isTime1 & isTime2;
        dataRoute = dataCombined(selectedIdx,:);
        dataRoute = dataRoute(1:60:end,:);
        [result, nWaypoint] = addBusToResult(result,iRoute,dataRoute,waypointOffset);
        waypointOffset = waypointOffset + nWaypoint;
        dataRoute.BusID = ones(size(dataRoute.BusID))*iRoute;
        if ~exist('socTable','var')
            socTable = appendSocTable(dataRoute);
        else
            socTable = appendSocTable(dataRoute, socTable);
        end
        fprintf("formatted %f percent of bus routes\n",iRoute/numel(busId));
    end
    writetable(socTable,'busSoc2.csv');
    yaml.dumpFile('Waypoints2.yaml',result,'block');

% 
%     % convert SOC from percent to kWh.  Assume maximum capacity of 500 kWh.
%     dataNewFlyer.SOC = dataNewFlyer.SOC*500/100;
% 
%     % define discharge per meter traveled (on average)
%     discharge_per_meter = -0.001775155271245; %kWh/meter
% 
%     % get data for bus 18151
%     data18151 = dataNewFlyer(dataNewFlyer.BusID == 18151,:);
%     data15013 = dataUta(dataUta.BusID == 15013,:);
%     SOC15013 = zeros(size(data15013.Lat));
%     SOC15013(1) = 90*5; % start the SOC at 90 percent
%     SOC15013(2:end) = cumsum(data15013.distance(2:end))*discharge_per_meter + SOC15013(1);
%     data15013.SOC = SOC15013;
% 
%     % convert to waypoints yaml
%     result = struct;
%     [result, nAdditions] = addBusToResult(result,18151,data18151,0);
%     result = addBusToResult(result,15013,data15013,nAdditions);
%     yaml.dumpFile('Waypoints.yaml',result,'block');
% 
%     % convert to SOC.csv
%     SOCTable = appendSocTable(data18151);
%     SOCTable = appendSocTable(data15013, SOCTable);
%     SOCTable = unique(SOCTable,'rows');
%     SOCTable = sortrows(SOCTable,{'Bus ID','Time'});
%     writetable(SOCTable, 'BusSOC.csv');
% 
%     % find parameters for charge rates
%     hubSOC = data18151(12:87,:);
%     overheadSOC = data18151(255:277,:);
%     [hubSocResample, hubSocTx] = resample(hubSOC.SOC,hubSOC.Time,1/60);
%     [ohdSocResample, ohdSocTx] = resample(overheadSOC.SOC, overheadSOC.Time,1/60);
% 
%     % find charge rate for depot charging exponential model
%     rhs = hubSocResample(2:end) - 450;
%     lhs = hubSocResample(1:end-1) - 450;
%     aBar = mean(rhs./lhs);
%     aHubRate = log(aBar)/60;
% 
%     % find charge rate for overhead chargign exponential model
%     rhs = ohdSocResample(2:end) - 450;
%     lhs = ohdSocResample(1:end-1) - 450;
%     aBar = rhs./lhs;
%     aBar(1) = [];
%     aBar(end-7:end) = [];
%     aBar = mean(aBar);
%     aOhcBar = log(aBar)/60;
% 
%     % verify aHubRate
%     figure; scatter(ohdSocTx, ohdSocResample,'filled'); hold on;
%     ohdSocResample(1) = [];
%     ohdSocTx(1) = [];
%     cSoc = ohdSocResample(1);
%     approxOhdSoc = zeros(size(ohdSocResample));
%     approxOhdSoc(1) = cSoc;
%     aRate = -20.33e-4;
%     for iVal = 1:numel(ohdSocResample) - 1
%         nSoc = exp(aRate*60)*(cSoc - 450) + 450;
%         approxOhdSoc(iVal + 1) = nSoc;
%         cSoc = nSoc;
%     end
%     plot(ohdSocTx, approxOhdSoc, 'linewidth',2);
% 
%     % extract linear portion of hub samples
%     linHub = hubSocResample(1:14);
%     linHubTx = hubSocTx(1:14);
%     linOhd = ohdSocResample(1:13);
%     linOhdTx = ohdSocTx(1:13);
%     pHub = polyfit(datenum(linHubTx),linHub,1);
%     pOhd = polyfit(datenum(linOhdTx), linOhd,1);
%     rateSecondHub = pHub(1)/(3600*24);
%     rateSecondOhd = pOhd(1)/(3600*24);
%     plot(ohdSocTx, datenum(ohdSocTx)*pOhd(1) + pOhd(2),'linewidth',2); ylim([360,460]);
%     legend('Original','CCCV','Linear');


end

function data = addSocColumn(data)
fprintf('temp\n');
end

function currTable = appendSocTable(data, currTable)
data = filterToOneDay(data);
Charge = data.SOC;
Time = data.Time.Hour*3600 + data.Time.Minute*60 + data.Time.Second;
BusID = ones(size(data.Time))*data.BusID(1);
newTable = table(Charge, Time, BusID, 'VariableNames',{'Charge','Time','Bus ID'});

if nargin == 2
    currTable = [currTable; newTable];
else
    currTable = newTable;
end
end

function data = filterToOneDay(data)
diff = data.Time.Hour(1:end-1) - data.Time.Hour(2:end);
idx = find(diff > 12) + 1;
if ~isempty(idx)
    data = data(idx:end,:);
end
diff = data.Time.Hour(1:end-1) - data.Time.Hour(2:end);
idx = find(diff > 12) + 1;
if ~isempty(idx)
    data = data(1:idx,:);
end
end

function [results, nAdditions] = addBusToResult(results, busId, data, offset)

% filter data values before and after midnight.
data = filterToOneDay(data);

% format data as yaml file
nData = size(data,1);
fieldBusId = sprintf('Bus_%i',busId);
for iData = 1:nData
    fieldWaypoint = sprintf('Waypoint_%i',iData + offset);
    currData = data(iData,:);
    timeSeconds = currData.Time.Hour*3600 + currData.Time.Minute*60 + currData.Time.Second;
    results.(fieldBusId).(fieldWaypoint).position.lat = currData.Lat;
    results.(fieldBusId).(fieldWaypoint).position.lon = currData.Lon;
    results.(fieldBusId).(fieldWaypoint).position.alt = 0;
    results.(fieldBusId).(fieldWaypoint).time = timeSeconds;
    if currData.Time.Hour < 4 || currData.Time.Hour >= 22
        results.(fieldBusId).(fieldWaypoint).type = int32(1);
    elseif currData.inHub == 1
        results.(fieldBusId).(fieldWaypoint).type = int32(0);
    else
        results.(fieldBusId).(fieldWaypoint).type = int32(2);
    end
end
nAdditions = nData;
end

function displayBusInfo(data)
busId = unique(data.BusID);
nBus = numel(busId);
for iBus = 1:nBus

    % plot when buses are in the hub
    figure;
    busData = data(data.BusID == busId(iBus),:);    
    plot(busData.Time, busData.inHub); hold on;
    scatter(busData.Time, busData.inHub, 'filled');
    title(sprintf('Bus ID: %i',busId(iBus)));
    ylabel('In Hub');
    xlabel('Time');

    % plot the bus's location in lat/lon
    figure;
    plot(busData.Lat, busData.Lon); hold on;
    scatter(busData.Lat, busData.Lon);
    plot(getShape());
    xlabel('Lat'); ylabel('Lon');
    title(sprintf('Lat/Lon for Bus: %i',busId(iBus)))
    
    % plot the bus SOC if any
    if ~any(isnan(busData.SOC))
        figure; 
        plot(busData.Time, busData.SOC);
        hold on; scatter(busData.Time, busData.SOC);
        xlabel('Time'); ylabel('SOC'); title(sprintf('SOC for Bus %i',busId(iBus)));
    end

    % plot distance traveled (approximate)
    figure;     
    cumMag = cumsum(busData.Distance);
    plot(busData.Time, cumMag);
    xlabel('Time'); ylabel('Absolute Distance Traveled (meters)');
    title(sprintf('Distance plot for bus %i',busId(iBus)));
end
end

function data = addDistanceColumn(data)
lla = [data.Lat data.Lon, zeros(size(data.Lon))];    
    ecef = lla2ecef(lla);
    diff = ecef(2:end,:) - ecef(1:end-1,:);
    diffMag = sqrt(diff(:,1).^2 + diff(:,2).^2 + diff(:,3).^2);
    diffMag = [0; diffMag];     
    data.distance = diffMag;
end

function data = addInHubColumn(data)
busId = unique(data.BusID);
nBus = numel(busId);
data.inHub = zeros([size(data,1),1]);
data = sortrows(data,{'BusID','Time'});
for iBus = 1:nBus
    busIdx = data.BusID == busId(iBus);
    data.inHub(busIdx) = isInHub(data(busIdx,:).Lat, data(busIdx,:).Lon);
end
end

function data = resampleToTenHz(data)
busId = unique(data.BusID);
nBus = numel(busId);
allLat = [];
allLon = [];
allSoc = [];
allTime = [];
allBusId = [];
for iBus = 1:nBus
    
    % extract values from table
    busData = data(data.BusID == busId(iBus),:);
    busData = sortrows(busData,'Time');
    lat = busData.Lat;
    lon = busData.Lon;
    soc = busData.SOC;
    time = busData.Time;
    if size(busData,1) > 1
        % resample values to 10 Hz
        [~, outTime] = resample(lat, time, 10);
        temp = interp1(time,lat, outTime,'linear');
        if ~any(isnan(soc))
            soc = resample(soc,time,10,'linear');
        else
            soc = nan([numel(lat),1]);
        end
        [lon, time] = resample(lon,time,10,'linear');
    else

    end

    % store values
    allLat = [allLat; lat];                                                %#ok
    allLon = [allLon; lon];                                                %#ok
    allSoc = [allSoc; soc];                                                %#ok
    allTime = [allTime; time];                                             %#ok
    allBusId = [allBusId; ones([numel(lat),1])*busId(iBus)];               %#ok
end
Lat = allLat;
Lon = allLon;
Time = allTime;
BusID = allBusId;
SOC = allSoc;
data = table(Lat, Lon, Time, BusID, SOC);
end

function isInOut = isInHub(lat, lon)
persistent shape;
if isempty(shape)
    shape = getShape();
end

isIn = double(isinterior(shape, lat, lon));
% isIn0 = (movmedian(isIn,81));
% isIn2 = movmedian(isIn0,41);
% isIn1 = (movmedian(isIn2,21));
% isIn3 = (movmedian(isIn1,17));
% isIn5 = (movmedian(isIn3,11));
% isIn6 = (movmedian(isIn5,7));
% isIn7 = (movmedian(isIn6,5));
% isIn8 = (movmedian(isIn7,3));
% [left, right, all] = myFilter(isIn8);
% isInOut = conv(isIn8,ones([1,80])/80,'same');
% isInOut = conv(isInOut,ones([1,640])/640,'same') > 0;
isInOut = isIn;
end

function [left, right, all] = myFilter(data)
winHalfWidth = 80;
zpData = [zeros([winHalfWidth,1]); data; zeros([winHalfWidth,1])];
sumData = cumsum(zpData); 
result = zeros(size(data));
left = zeros(size(data));
right = zeros(size(data));
all = zeros(size(data));
for iData = 1:numel(data)
    start = iData;
    middle = iData + winHalfWidth;
    final = iData + winHalfWidth*2;
    left(iData) = sumData(middle) - sumData(start);
    right(iData) = sumData(final) - sumData(middle);
    all(iData) = sumData(final) - sumData(start);
end
end

function plotPoints(points, color)
scatter(1:numel(points), points, 10, color, 'filled'); hold on; plot(points, 'Color',color); shg
end

function shape = getShape()
% p1 = [40.76481, -111.90841];
% p2 = [40.76243, -111.90844];
% p3 = [40.76241, -111.90900];
% p4 = [40.76477, -111.91020];
% p5 = [40.76490, -111.90941];
% p6 = [40.76469, -111.90841];
% points = [p1; p2; p3; p4; p5; p6; p1]';
xLow = 40.76227;
xHigh = 40.7666;
yLow = -111.91300;
yHigh = -111.90600;
p1 = [xLow, yHigh];
p2 = [xHigh, yHigh];
p3 = [xHigh, yLow];
p4 = [xLow, yLow];
points = [p1; p2; p3; p4; p1]';
shape = polyshape(points(1,:),points(2,:));
end

function cleanTable = extractAndClean(fileList)
% concatenate all files into one table
nFileUta = numel(fileList);
for iFile = 1:nFileUta

    % read in file data
    fileCurrent = fileList(iFile);
    fileLoc = fullfile(fileCurrent.folder, fileCurrent.name);
    fileTable = readtable(fileLoc);

    % if the table is empty, continue
    if numel(fileTable) == 0
        continue
    end

    % for some reason, new flyer data is 7 hours ahead of MST
    if contains(fileCurrent.name,'New_Flyer') || contains(fileCurrent.name,'New_Flyler')
        fileTable.Time = fileTable.Time - hours(7);
    end

    % concatentate with current table
    if exist("dataTable",'var')
        dataTable = [dataTable; fileTable];
    else
        dataTable = fileTable;
    end
end

% sort by bus index and then by time
dataTable = sortrows(dataTable,{'BusID','Time'});
dataTable = unique(dataTable);

% remove buses that don't provide data
busId = unique(dataTable.("BusID"));
for iBus = 1:numel(busId)
    selectorIdx = dataTable.("BusID") == busId(iBus);
    if sum(selectorIdx) <= 10
        dataTable(selectorIdx,:) = [];
        fprintf('removed bus: %i\n',busId(iBus));
    end
end

% round the first and last time instances to 12AM (arbitrarily chosen)
cleanTable = [];
for iBus = 1:numel(busId)

    %get number of days for which there is data
    busSelectorIdx = dataTable.BusID == busId(iBus);
    busData = dataTable(busSelectorIdx,:);
    timeDay = busData.Time;
    timeDay.Hour = 0;
    timeDay.Minute = 0;
    timeDay.Second = 0;
    days = unique(timeDay);
    
    % continue if there is no data
    if isempty(busData)
        continue
    end

    % remove extra data
    futureExtraIdx = busData.Time > days(end);
    pastExtraIdx = busData.Time < days(1);
    if ~isempty(futureExtraIdx)
        busData(busData.Time > days(end),:) = [];
    end
    if ~isempty(pastExtraIdx)
        busData(busData.Time < days(1),:) = [];
    end
    nDays = numel(days);

   
    for iDay = 1:nDays - 1
       currDay = days(iDay);
       nextDay = days(iDay + 1);
       daySelectorIdx = (busData.Time > currDay) & (busData.Time < nextDay);
       dayData = busData(daySelectorIdx,:);
       if any(isnan(dayData.SOC))
           dayData.SOC(isnan(dayData.SOC)) = inf;
       end     
       dayData = unique(dayData,'rows');
       dayData.SOC(isinf(dayData.SOC)) = nan;

       % remove days where there is insufficient data
       if size(dayData,1) < 300
           continue
       end

       % sort and remove duplicates
       dayData = sortrows(dayData,'Time');
       inTime = dayData.Time.Hour*3600 + dayData.Time.Minute*60 + dayData.Time.Second;
       otTime = 0:3600*24;      
       [inTime, inIdx, ~] = unique(inTime);
       inLat = dayData.Lat(inIdx);
       inLon = dayData.Lon(inIdx);
       inSoc = dayData.SOC(inIdx);

       % resample to 1Hz
       Lat = interp1(inTime, inLat, otTime,'linear'); 
       Lon = interp1(inTime, inLon, otTime,'linear');
       Lat(isnan(Lat)) = inLat(1);
       Lon(isnan(Lon)) = inLon(1);

       % convert Lat/Lon to distance in meters
       LLA = [Lat', Lon', zeros(size(Lat'))];
       ECEF = lla2ecef(LLA);
       Distance = [[0 0 0]; ECEF(2:end,:) - ECEF(1:end-1,:)];
       Distance = sqrt(Distance(:,1).^2 + Distance(:,2).^2 + Distance(:,3).^2);

       % convert SOC to kWh and infer from distance if necessary
       max_soc = 450; % in kWh
       if any(isnan(inSoc))
           discharge_per_meter = -0.001775155271245; %kWh/meter
           SOC = max_soc + cumsum(Distance*discharge_per_meter);
       else
           SOC = interp1(inTime,inSoc,otTime,'linear');
           before = SOC(1:inTime(1));
           before(isnan(before)) = inSoc(1);
           SOC(1:inTime(1)) = before;
           after = SOC(inTime(end):end);
           after(isnan(after)) = inSoc(end);
           SOC(inTime(end):end) = after;
           SOC = SOC*max_soc;
       end

       % format and add to table
       BusID = ones(size(SOC))*busId(iBus);
       Time = currDay + seconds(otTime);
       BusID = BusID(:); Lat = Lat(:); Lon = Lon(:); 
       Distance = Distance(:); SOC = SOC(:); Time = Time(:);
       dayTable = table(BusID,Lat,Lon,Distance,SOC,Time);
       cleanTable = [cleanTable; dayTable];                                %#ok
    end
end
end


