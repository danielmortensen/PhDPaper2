basedir = '/home/daniel/PhD/paper2/data_management/data/processed_tpss/';
otputDir = fullfile(basedidatar,'TPSSMat.mat');
outputCovDir = fullfile(basedir,'TPSS_Cov.mat');

% load data from .csv and convert to matrix
if ~isfile(otputDir)
inputDir = fullfile(basedir,'TPSS.csv');
ds = tabularTextDatastore(inputDir);
ds.ReadSize = 1;
nRows = 22;
data = zeros([nRows,172800]);
for iRow = 1:nRows
    rowData = ds.read();
    rowData(:,1) = [];
    rowArray = table2array(rowData); clear('rowData');
    data(iRow,:) = rowArray;
    fprintf('row %i\n',iRow);
end
save(otputDir,"data")

% load matrix from stored data
else
    d = load(otputDir);  
    data = d.data;
end

% replace nan with nearest neighbor
t = ~isnan(data);
ii = cumsum(t,2);
ii(ii==0) = 1;
ii = bsxfun(@plus,[0,ii(end,1:end-1)],ii);
m1 = data(t);
data1 = m1(ii);

% resample from 0.5s to 5 minute intervals
fsIn = 2;
fsOut = 1/300;
[p,q] = rat(fsOut/fsIn);
nInData = size(data);
dataIsNan = isnan(data);
data(dataIsNan) = 0;
dataResample = zeros(nInData(1),nInData(2)*p/q);
kernel = ones([1,q/p])*p/q;
for iData = 1:nInData(1)
    
    average = conv(data(iData,:),kernel,'same');
    dataResample(iData,:) = average(1:q/p:end);
end

% form covariance matrix
C = cov(dataResample,'omitrows');
mu = mean(dataResample,'omitnan');  
figure; imagesc(C); colorbar; 
save(outputCovDir,'dataResample','C','mu');

% plot results for sanity check
inTime = datetime(2022,3,3);
inTime = inTime:seconds(0.5):inTime + hours(24) - seconds(0.5);
xOut = 1:q/p:nInData(2);
outTime = inTime(xOut);
% figure; plot(inTime, data(3,:));
% hold on; scatter(outTime, dataResample(3,:),'filled'); legend('TPSS','5 Minute Average'); shg