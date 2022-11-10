doClean = false;
visualizeData = false;
exportToFile = true;
doCombination = false;
labelWarning = 'MATLAB:table:ModifiedAndSavedVarnames';
% parfevalOnAll(@warning,0,'off',labelWarning);
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
    dataNewFlyer = extractAndClean(fileNewFlyer);
    dataUta = extractAndClean(fileUTA);

    % determine when a bus is in the hub
    dataUta = addInHubColumn(dataUta);
    dataNewFlyer = addInHubColumn(dataNewFlyer);
    nflPath = fullfile(basePath,'processed','dataNewFlyer.csv');
    utaPath = fullfile(basePath,'processed','dataUta.csv');
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
    clear('socTable');
    if ~exist('dataCombined','var')
        dataCombined = readtable('../data/processed/dataCombined.csv');
    end

    % initialize routes and times to export
    busId = [18151; 15023; 15020; 15019;...
             15018; 15017; 15014; 15013;...
             15012; 15009; 15007; 15006;...
             15006; 15006; 15003 ...
             ];
    if ~exist('busId','var')
        busId = unique(dataCombined.BusID);
    else
        years = 2022*ones(size(busId)); months = 3*ones(size(busId));
        days = [4; 9; 14; 8; 8; 8; 11; 4; 4; 4; 12; 4; 8; 9; 9];
        dates = datetime(years, months, days);
    end

    
    
    % add each element to the output results
    % result = struct;
    % waypointOffset = 0;
    nBus = numel(busId);
    iRoute = 1;
    iFinalBus = 1;
    dataFormated = {};
    dt = seconds(dataCombined.Time(2) - dataCombined.Time(1));
    nSamplePerDay = 24*3600/dt;
    nRoute = 0;
    iWaypoint = 1;
    rejects = {};
    isFirstWrite = true;
    tOffset = [minutes(0); minutes(20); minutes(20); minutes(20)];
    for iBus = 1:nBus

        % designate which bus to use
        id = busId(iBus);
        dataBus = dataCombined(dataCombined.BusID == id,:);
        dataBus = sortrows(dataBus,'Time','ascend');

        iTable = 1;
        nTable = size(dataBus,1);
        while iTable < nTable

            % get the start and end times
            if exist('dates','var')
                tStart = dates(iBus);
            else                
                tStart = dataBus.Time(iTable,:);
            end
            tStart.Hour = 0;
            tStart.Second = 0;
            tFinal = tStart + hours(24);

            % separate corresponding data
            routeIdx = dataBus.Time >= tStart;
            routeIdx = routeIdx & (dataBus.Time < tFinal);
            dataRoute = dataBus(routeIdx,:);
            nData = size(dataRoute,1);            
           
            if ~all(dataRoute.SOC < 500)
                dataRoute.SOC = dataRoute.SOC*450/max(dataRoute.SOC);
            end
            if nData > nSamplePerDay
                [~, idx] = unique(dataRoute.Time);
                dataRoute = dataRoute(idx,:);
            end
            if nData > nSamplePerDay
                dataRoute = dataRoute(1:nSamplePerDay,:);
                nData = nSamplePerDay;
            end
            diff = dataRoute.SOC(2:end) - dataRoute.SOC(1:end-1);
            diff(diff > 0) = 0;
            dsoc = sum(diff);
            if (all(dataRoute.SOC > 0) && nData == nSamplePerDay && all(dataRoute.SOC < 500) && (range(dataRoute.SOC) > 20) && dsoc < -200 && dsoc > -450) || exist('dates','var')

                % rename fields to comply with justin's request
                dataRoute = renamevars(dataRoute,["BusID","Lat","Lon","inHub","SOC"],...
                    ["BusId", "Latitude", "Longitude", "Type", "Charge"]);

                % add altitude column (for when buses can fly)
                dataRoute.Altitude = zeros([nData,1]);

                
                % write to file
                isFirstOffset = true;
                for iOffset = 1:numel(tOffset)

                    % account for temporal offsets
                    tDiff = dataRoute.Time(2) - dataRoute.Time(1);
                    offset = tOffset(iOffset);
                    dataRoute.Time = dataRoute.Time + offset;
                    overflowIdx = dataRoute.Time >= tFinal;
                    dataRoute(overflowIdx,:) = [];
                    tFill = tStart:tDiff:(dataRoute.Time(1) - tDiff);
                    dataFill = dataRoute(ones([numel(tFill),1]),:);
                    dataFill.Time = tFill(:);
                    dataRoute = [dataFill; dataRoute];

                    % relable to create distinct bus indices
                    dataRoute.BusId = ones(size(dataRoute.BusId))*iFinalBus;
                    iFinalBus = iFinalBus + 1;

                    % add waypoint ID
                    waypointId = iWaypoint:iWaypoint + nData - 1;
                    dataRoute.WaypointId = waypointId(:);
                    iWaypoint = iWaypoint + nData;

                    % Convert to 'Type' s.t. (0=Station, 1=Depot, 2=Route)
                    if isFirstOffset
                        dataRoute.Type = ~(dataRoute.Type)*2;
                        isFirstOffset = false;
                    end
                    tIdx = dataRoute.Time.Hour < 5 | dataRoute.Time.Hour >= 23;
                    dataRoute.Type(tIdx) = 1;

                    % write table to file
                    isFirstWrite = writeToFile("bestRepeatedRoutes.csv",dataRoute, isFirstWrite);
                end
                fprintf("wrote the %ith route to file.\n",nRoute);
                nRoute = nRoute + 1;
                if exist('dates','var')
                    break;
                end
            else
                rejects{end + 1} = dataRoute;
            end

            % update indices
            iTable = iTable + nData;
        end
        fprintf("Finished processing for bus %i\n",iBus);
%         timeStart = dates(iRoute);
%         timeEnd = timeStart + hours(24);
%         isBus = dataCombined.BusID == id;
%         isTime1 = dataCombined.Time >= timeStart;
%         isTime2 = dataCombined.Time < timeEnd;
%         selectedIdx = isBus & isTime1 & isTime2;
%         dataRoute = dataCombined(selectedIdx,:);
%         dataRoute = dataRoute(1:60:end,:);
%         [result, nWaypoint] = addBusToResult(result,iRoute,dataRoute,waypointOffset);
%         waypointOffset = waypointOffset + nWaypoint;
%         dataRoute.BusID = ones(size(dataRoute.BusID))*iRoute;
%         if ~exist('socTable','var')
%             socTable = appendSocTable(dataRoute);
%         else
%             socTable = appendSocTable(dataRoute, socTable);
%         end
%         fprintf("formatted %f percent of bus routes\n",iRoute/numel(busId));
    end
%     writetable(socTable,'busSoc2.csv');
%     yaml.dumpFile('Waypoints2.yaml',result,'block');
end

function isFirstWrite = writeToFile(filePath, data, isFirstWrite)

% convert time to seconds
tStart = data.Time(1);
data.Time = seconds(data.Time - tStart);

if isFirstWrite
    writetable(data, filePath)
    isFirstWrite = false;
else    
    writetable(data,filePath,'WriteMode','Append');
end
iBus = data.BusId(1);
figure; subplot(4,1,1);
plot(data.Latitude); title(sprintf("Longitude for Bus %i",iBus));
subplot(4,1,2);
plot(data.Longitude); title(sprintf("Latitude for Bus %i",iBus));
subplot(4,1,3);
plot(data.Charge); title(sprintf("Charge for Bus %i",iBus));
subplot(4,1,4);
plot(data.Type); title(sprintf("Station, depot, or route for Bus %i",iBus));
ylim([-0.5,2.5]);
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
dataTables = cell(nFileUta,1);
parfor iFile = 1:nFileUta

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
    dataTables{iFile} = fileTable;
% 
%     if exist("dataTable",'var')
%         dataTable = [dataTable; fileTable];
%     else
%         dataTable = fileTable;
%     end
    fprintf('cleaned UTA file %i of %i\n',iFile,nFileUta);
end

% sort by bus index and then by time
dataTable = vertcat(dataTables{:});
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


