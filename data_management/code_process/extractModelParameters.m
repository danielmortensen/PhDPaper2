basepath = '../data/processed/';
if ~exist('dataUta','var')
    newflyerPath = fullfile(basepath,'dataNewFlyer.csv');
    utaPath = fullfile(basepath,'dataUta.csv');
    dataNewflyer = readtable(newflyerPath);
    dataUta = readtable(utaPath);
end

busId = unique(dataUta.BusID);
nBus = numel(busId);
routes = nan([2000,100]);
iSchedule = 1;
restThreshold = 10*60;
deltaLimit = -375;
for iBus = 1:nBus
busIdx = dataUta.BusID == busId(iBus);
dataBus = dataUta(busIdx,:);
while(~isempty(dataBus))
    startTime = min(dataBus.Time);
    finalTime = startTime + hours(24);
    dayIdx = (dataBus.Time >= startTime & dataBus.Time < finalTime);
    nData = sum(dayIdx);
    if nData > 86000
        dataDay = dataBus(dayIdx,:);

        % enforce curfew
        dataDay.inHub(dataDay.Time.Hour < 5) = 1;
        dataDay.inHub(dataDay.Time.Hour > 22) = 1;
        
        % get arrival/departure times
        diff = dataDay.inHub(2:end) - dataDay.inHub(1:end-1);

        % filter routes that are shorter than 5 minutes
        badRoute = 1;
        while sum(badRoute) > 0
            idxDepart = find(diff < 0);
            idxArrive = find(diff > 0);
            timeDepart = toSeconds(dataDay.Time(idxDepart));
            timeArrive = toSeconds(dataDay.Time(idxArrive));
            badRoute = (timeArrive - timeDepart) < restThreshold;
            diff(idxDepart(badRoute)) = 0;
            diff(idxArrive(badRoute)) = 0;
        end        

        % filter stops that last less than 5 minutes        
        badStop = 1;
        while sum(badStop) > 0
            badStop = (timeDepart(2:end) - timeArrive(1:end-1)) < restThreshold;
            diff(idxDepart([false; badStop])) = 0;
            diff(idxArrive([badStop; false])) = 0;
            idxDepart = find(diff < 0);
            idxArrive = find(diff > 0);
            timeDepart = toSeconds(dataDay.Time(idxDepart));
            timeArrive = toSeconds(dataDay.Time(idxArrive));
        end

        % compute delta soc
        delta = dataDay.SOC(idxArrive) - dataDay.SOC(idxDepart);
        delta = [delta; 0];                                                %#ok
        
        % compute variance on the delta
        deltaVar = zeros(size(delta));
        deltaVar(end) = 0;
        for iDelta = 1:numel(delta) - 1
            data = dataDay.SOC(idxDepart(iDelta):idxArrive(iDelta));
            diff = data(2:end) - data(1:end-1);
            dist = dataDay.Distance(idxDepart(iDelta):idxArrive(iDelta) - 1);
            diffPerMeter = diff./dist;
            diffPerMeter(isinf(diffPerMeter)) = nan;
            diffPerMeter(isnan(diffPerMeter)) = [];
            varPerMeter = var(diffPerMeter);
            deltaVar(iDelta) = var(diff)*sum(dist);      
            if deltaVar(iDelta) < 1
                deltaVar(iDelta) = 6.820014880297823e-05*sum(dist);
            end
        end

        % add times for start and end of day
        timeDepart = [timeDepart; 3600*24];                                %#ok
        timeArrive = [0; timeArrive];                                      %#ok     


        % remove routes that have too high a battery draw
        badDelta = find(delta < deltaLimit);        

        % if there are valid routes, insert for use
        if isempty(badDelta) && numel(timeDepart) > 1

            % derive metrics for bus route
            percentInHub = sum(dataDay.inHub)/size(dataDay,1)*100;
            nRoute = numel(delta);
            maxDelta = min(delta);

            % insert values in data structure
            if nRoute > 0
                schedule = [timeArrive'; timeDepart'; delta'; deltaVar'];
                schedule = schedule(:);
                routes(iSchedule,1:numel(schedule)) = schedule';
                routes(iSchedule,end-2:end) = [percentInHub nRoute maxDelta];
                iSchedule = iSchedule + 1;
            end
        end
    end
    dataBus(dayIdx,:) = [];
end
fprintf('percent complete: %f\n',iBus/nBus*100);
end

% crop unneeded space
maxNRoute = max(routes(:,end-1));
routes(iSchedule:end,:) = [];
maxX = maxNRoute*4;
routes(:,maxX+1:end-3) = [];

% define headers
headArrival = "arrival_" + string(1:maxNRoute);
headDepart = "departure_" + string(1:maxNRoute);
headDelta = "socDelta_" + string(1:maxNRoute);
headDeltaVar = "socDeltaVar_" + string(1:maxNRoute);
header = [headArrival; headDepart; headDelta; headDeltaVar];
header = header(:);
header = header';
header(end + 1) = "percentInHub"; 
header(end + 1) = "nRoute";
header(end + 1) = "maxDelta";

% export as table
routesTable = array2table(routes,'VariableNames',header);
writetable(routesTable,fullfile(basepath,'routesTableWithVar.csv'));

function sec = toSeconds(input)
    sec = input.Hour*3600 + input.Minute*60 + input.Second;
end