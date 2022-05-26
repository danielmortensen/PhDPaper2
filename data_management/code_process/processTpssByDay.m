basedir = {'/home','daniel','PhD','paper2','data_management','data','processed_tpss'};
infile = 'TPSS.csv';
outdir = fullfile(basedir{:},'TPSSWeekdayMat.mat');
doCompute = false;
...covdir = fullfile(basedir{:},'TPSSWeekdayCov.mat');

% initialize data object
if (~isfile(outdir) && ~exit('data','var')) || doCompute
    fieldname = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
    nFieldname = 7;
    nRow = 22;
    nCol = 172800;
    data = struct;
    for iField = 1:nFieldname
        data.(fieldname(iField)).value = nan([nRow, nCol]);
        data.(fieldname(iField)).finalIdx = 1;
    end

    % load data from .csv and convert to matrix
    indir = fullfile(basedir{:},infile);
    ds = tabularTextDatastore(indir);
    ds.ReadSize = 1;
    for iRow = 1:nRow

        % read row of data
        row = ds.read();

        % get day of week
        dayIdx = weekday(row.Row);
        name = fieldname(dayIdx);

        % remove unnecessary column
        row(:,1) = [];

        % store data as array
        row = table2array(row);
        data.(name).value(data.(name).finalIdx,:) = row;
        data.(name).finalIdx = data.(name).finalIdx + 1;

        % report progress
        fprintf("week of day: " + name + "\n");
        fprintf('percent complete: %f\n',iRow/nRow*100);
    end

    % remove unnecessary rows
    for iField = 1:nFieldname
        name = fieldname(iField);
        finalIdx = data.(name).finalIdx;
        data.(name).value(finalIdx:end,:) = [];
    end

    % save data
    save(outdir, 'data');
elseif ~exist('data','var')
    data = load(outdir);
    data = data.data;
end

% compute average data over [Mon, Tues, Wed, Thurs], [Fri], [Sat], [Sun]
set1 = ["Monday","Tuesday","Wednesday","Thursday"];
set2 = "Friday";
set3 = "Saturday";
set4 = "Sunday";

% compute average data for set1
avg1 = getAvg(data,set1);

% compute average data for set2
avg2 = getAvg(data,set2);

% compute average data for set3
avg3 = getAvg(data, set3);

% compute average data for set4
avg4 = getAvg(data, set4);

% plot graphs
sec = (0:numel(avg1) - 1)/2;
secDateNum = datenum(seconds(sec));
xAxis = datetime(secDateNum, 'ConvertFrom','datenum','Format','HH:mm:ss');

% plot Monday - Thursday
subplot(4,1,1);
plot(xAxis, avg1); 
xlabel('Time of Day'); ylabel('Power (kW)'); ylim([0,1500]);
title('Monday - Thursday');

% plot Friday
subplot(4,1,2);
plot(xAxis, avg2);
xlabel('Time of Day'); ylabel('Power (kW)'); ylim([0,1500]);
title('Friday');

% plot Saturday
subplot(4,1,3);
plot(xAxis, avg3);
xlabel('Time of Day'); ylabel('Power (kW)'); ylim([0,1500]);
title('Saturday');

% plot Sunday
subplot(4,1,4);
plot(xAxis, avg4); 
ylabel('Power (kW)'); xlabel('Time of Day'); ylim([0,1500]);
title('Sunday');

function avg1 = getAvg(data, inSet)
nData1 = nan([numel(inSet),1]);
for iSet = 1:numel(inSet)
    nData1(iSet) = data.(inSet(iSet)).finalIdx - 1;
end
nAllData1 = sum(nData1);
nElement = size(data.Monday.value,2);
dataVal = nan([nAllData1, nElement]);
iVal = 1;
for iSet = 1:numel(inSet)
    dataVal(iVal:iVal + nData1(iSet) - 1,:) = data.(inSet(iSet)).value;
    iVal = iVal + nData1(iSet) - 1;
end
avg1 = mean(dataVal,1,'omitnan');
end
