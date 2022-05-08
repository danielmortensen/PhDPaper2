param = getSimulationParam();
varInfo = getVarInfo(param);
const = struct;
const = getConst1(param,varInfo,const);
const = getConst2(param,varInfo,const);

function Const = getConst1(param,var,Const)

% preallocate for constraints
nVal = sum(param.routes.nRoute)*4;
nConst = sum(param.routes.nRoute)*3;
iConst = 1;
iA = 1;
A = nan([nVal,3]);
b = nan([nConst,1]);

% define sparse matrix for constraints
for iBus = 1:param.bus.nBus
nRoute = param.routes.nRoute(iBus);
for iRoute = 1:nRoute

    % define constraint indices
    c = var.val.c.val(iBus,iRoute);
    a = param.routes.tArrival(iBus,iRoute);

    % define constraint parameters
    s = var.val.s.val(iBus,iRoute);
    d = param.routes.tDepart(iBus,iRoute);

    % first constraint
    A(iA + 0,:) = [iConst, c, -1];
    b(iConst) = -a;

    % second constraint
    A(iA + 1,:) = [iConst + 1,c, 1];
    A(iA + 2,:) = [iConst + 1,s, -1];
    b(iConst + 1) = 0;

    % third constraint
    A(iA + 3,:) = [iConst + 2,s,1];
    b(iConst + 2) = d;

    % update index variables
    iA = iA + 4;
    iConst = iConst + 3;
end
end

% assert that the number of constraints and values is as expected
assert(sum(isnan(A(:))) == 0);
assert(sum(isnan(b)) == 0);

% package constraints
Const.Constraint1.A = A;
Const.Constraint1.b = b;
Const.Constraint1.info = "Constraint for SOC variable placement that" + ...
    " requires all start and end times to be in the bus availability time" + ...
    " and that the start time be before the end time.";
Const.Constraint1.eq = repmat('<',[nConst,1]);
end

function Const = getConst2(param,var,Const)

% define constraint dimensions
nConstr = sum(param.routes.nRoute);
nCharger = param.charger.nCharger;
nVal = nConstr*nCharger;

% preallocate
A = nan([nVal,3]);
b = nan([nConstr,1]);

% define constraints
iConstr = 1;
iVal = 1;
for iBus = 1:param.bus.nBus
    nRoute = param.routes.nRoute(iBus);
    for iRoute = 1:nRoute
        for iCharger = 1:nCharger
            sigma = var.val.sigma.val(iBus,iRoute,iCharger);
            A(iVal,:) = [iConstr, sigma, 1];
            iVal = iVal + 1;
        end
        b(iConstr) = 1;
        iConstr = iConstr + 1;
    end
end

% verify that all is as expected
assert(sum(isnan(A(:))) == 0);
assert(sum(isnan(b)) == 0);

% package constraint
Const.Constraint2.A = A;
Const.Constraint2.b = b;
Const.Constraint2.info = "Constrans the sum of the charge indicators for " + ...
    "each bus to be one for each stop.  This ensures that each bus cannot" + ...
    "charge on two chargers at once.";
Const.Constraint2.eq = repmat('<',[nConstr,1]);
end

function Const = getConst3(param,var,Const)
overlap = getOverlappingIndices(param);
end

function idx = getOverlappingIndices(param)
fprintf('temp\n');
end

function param = getSimulationParam()
% define input parameters
dirData = '/home/daniel/PhD/paper2/data_management/data/';
dirGridload = fullfile(dirData,'processed_tpss/TPSS_Cov15.mat');
dirRoutes = fullfile(dirData,'processed/routesTable.csv'); 
MBattery = 450; % battery capacity in kWh
MTime = 24*60*60; % maximum time index
soc0 = 85*MBattery/100; % initial soc in kWh
dTime = 15*60; % delta time in seconds
rCharge = 300/3600; % kWh/second
mBattery = 10*MBattery/100; % minimum allowed soc in kWh
nBus = 6;
nCharger = 2;

% load data
gridload = load(dirGridload);
gridload = gridload.mu;
routes = readtable(dirRoutes);
routes = sortrows(routes,'nRoute','descend');

% get nBus worth of route data
simRoutes = routes(1:nBus,:);
nRoute = simRoutes(:,end-1);
simRoutes = simRoutes(:,1:end-3);
simRoutes = table2array(simRoutes);
tArrival = simRoutes(:,1:3:end);
tDepart = simRoutes(:,2:3:end);
dSoc = simRoutes(:,3:3:end);

param.deltaT = dTime;
param.externLoad = gridload;
param.maxTime = MTime;
param.maxTimeIdx = MTime/dTime;
param.charger.chargeRate = rCharge;
param.charger.nCharger = nCharger;
param.bus.maxBattery = MBattery;
param.bus.initSoc = soc0;
param.bus.minBattery = mBattery;
param.bus.nBus = nBus;
param.routes.tArrival = tArrival;
param.routes.tDepart = tDepart;
param.routes.discharge = dSoc;
param.routes.nRoute = table2array(nRoute);
param.bill.facilitiesPower = 4.81;
param.bill.onPeak.energy = 5.8282e-2;
param.bill.onPeak.power = 15.73;
param.bill.onPeak.hours = zeros([param.maxTimeIdx,1]);
onPeakStart = 15*3600/param.deltaT + 1;
onPeakFinal = 22*3600/param.deltaT;
param.bill.onPeak.hours(onPeakStart:onPeakFinal) = 1;
param.bill.offPeak.energy = 2.9624e-2;
param.bill.offPeak.hours = ones([param.maxTimeIdx,1]) - param.bill.onPeak.hours;
end

function varInfo = getVarInfo(param)
startIdx = 1;
nBus = param.bus.nBus;
nRoute = param.routes.nRoute;
nStops = sum(nRoute);

% sigma
sigmaStart = startIdx;
nCharger = param.charger.nCharger;
maxStops = max(param.routes.nRoute);
sigma.val = nan([nBus,maxStops,nCharger]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus)*nCharger - 1;
    sz = size(sigma.val(iBus,1:nRoute(iBus),:));
    idx = reshape(startIdx:finalIdx,sz);
    sigma.val(iBus,1:nRoute(iBus),:) = idx;
    startIdx = finalIdx + 1;
end % 182 values in this constraint
sigma.type = 'B';
sigmaFinal = finalIdx;

%validate sigma
nSigmaExpect = param.charger.nCharger*nStops;
assert(isValid(sigma.val, sigmaStart, sigmaFinal, nSigmaExpect));


% p
pStart = startIdx;
nMaxTime = param.maxTimeIdx;
p.val.onRamp = nan([nBus,maxStops,param.maxTimeIdx]);
p.val.offRamp = nan([nBus,maxStops,param.maxTimeIdx]);
p.val.total = nan([param.maxTimeIdx,1]);
for iBus = 1:nBus
    finalIdx1 = startIdx + nRoute(iBus)*nMaxTime - 1;
    finalIdx2 = finalIdx1 + nRoute(iBus)*nMaxTime;
    sz = size(p.val.onRamp(iBus,1:nRoute(iBus),:));
    idx1 = reshape(startIdx:finalIdx1,sz);
    idx2 = reshape(finalIdx1 + 1:finalIdx2,sz);
    p.val.onRamp(iBus,1:nRoute(iBus),:) = idx1;
    p.val.offRamp(iBus,1:nRoute(iBus),:) = idx2;
    startIdx = finalIdx2 + 1;
end % p.onRamp and p.offRamp together contain 17472 values

p.val.total(1:end) = startIdx:startIdx + nMaxTime - 1;
startIdx = startIdx + nMaxTime;
p.type = 'C';
% p.total contains 96 values
pFinal = startIdx - 1;

% validate p
nPExpect = (nStops*2 + 1)*param.maxTimeIdx;
assert(isValid(p.val ,pStart, pFinal, nPExpect));

% c
cStart = startIdx;
c.val = nan([nBus,maxStops]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus) - 1;
    c.val(iBus,1:nRoute(iBus)) = startIdx:finalIdx;
    startIdx = finalIdx + 1;
end % c containts 91 values
c.type = 'C';
cFinal = startIdx - 1;
nCExpect = nStops;
assert(isValid(c.val,cStart,cFinal,nCExpect));

% s
sStart = startIdx;
s.val = nan([nBus,maxStops]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus) - 1;
    s.val(iBus,1:nRoute(iBus)) = startIdx:finalIdx;
    startIdx = finalIdx + 1;
end % s containts 91 values
s.type = 'C';
sFinal = finalIdx;
nSExpect = nStops;
assert(isValid(s.val,sStart,sFinal,nSExpect));

% h
hStart = startIdx;
h.val = nan([nBus,maxStops + 1]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus);
    h.val(iBus,1:nRoute(iBus) + 1) = startIdx:finalIdx;
    startIdx = finalIdx + 1;
end % s containts 97 values
h.type = 'C';
hFinal = finalIdx;
nHExpect = nStops + nBus;
assert(isValid(h.val,hStart,hFinal,nHExpect));

% k
kStart = startIdx;
k.val.start = nan([nBus,maxStops]);
k.val.final = nan([nBus,maxStops]);
for iBus = 1:nBus
    finalIdx1 = startIdx + nRoute(iBus) - 1;
    finalIdx2 = finalIdx1 + nRoute(iBus);
    k.val.start(iBus,1:nRoute(iBus)) = startIdx:finalIdx1;
    k.val.final(iBus,1:nRoute(iBus)) = finalIdx1 + 1:finalIdx2;
    startIdx = finalIdx2 + 1;
end % both k.start and k.final both have 91 values each
k.type = 'I';
kFinal = finalIdx2;
nKExpect = nStops*2;
assert(isValid(k.val,kStart,kFinal,nKExpect));

% r
rStart = startIdx;
r.val.start = nan([nBus,maxStops]);
r.val.final = nan([nBus,maxStops]);
for iBus = 1:nBus
    finalIdx1 = startIdx + nRoute(iBus) - 1;
    finalIdx2 = finalIdx1 + nRoute(iBus);
    r.val.start(iBus,1:nRoute(iBus)) = startIdx:finalIdx1;
    r.val.final(iBus,1:nRoute(iBus)) = finalIdx1 + 1:finalIdx2;
    startIdx = finalIdx2 + 1;
end % both r.start and r.final both have 91 values each
r.type = 'C';
rFinal = finalIdx2;
nRExpect = nStops*2;
assert(isValid(r.val,rStart,rFinal,nRExpect));

% s2
s2Start = startIdx;
s2.val.onRamp = nan([nBus,maxStops,nMaxTime]);
s2.val.offRamp = nan([nBus,maxStops,nMaxTime]);
s2.val.center = nan([nBus,maxStops,nMaxTime]);
for iBus = 1:nBus
    nCurRoute = nRoute(iBus);
finalIdx1 = startIdx + nCurRoute*nMaxTime - 1;
startIdx2 = finalIdx1 + 1;
finalIdx2 = startIdx2 + nCurRoute*nMaxTime - 1;
startIdx3 = finalIdx2 + 1;
finalIdx3 = startIdx3 + nCurRoute*nMaxTime - 1;
sz = size(s2.val.onRamp(iBus,1:nCurRoute,:));
s2.val.onRamp(iBus,1:nCurRoute,:) = reshape(startIdx:finalIdx1,sz);
s2.val.offRamp(iBus,1:nCurRoute,:) = reshape(startIdx2:finalIdx2,sz);
s2.val.center(iBus,1:nCurRoute,:) = reshape(startIdx3:finalIdx3,sz);
startIdx = finalIdx3 + 1;
end %s2.onRamp,s2.offRamp, and s2.center each contain 8736 values
s2.type = 'B';
s2Final = finalIdx3;
nS2Expect = param.maxTimeIdx*3*nStops;
assert(isValid(s2.val,s2Start,s2Final,nS2Expect));

qStart = startIdx;
q.val.onPeak = startIdx;
q.val.all = startIdx + 1;
q.type = 'C';
qFinal = startIdx + 1;
nQExpect = 2;
assert(isValid(q,qStart,qFinal,nQExpect));

% verify starting and ending positions
assert(sigmaStart == 1);
assert(sigmaFinal + 1 == pStart);
assert(pFinal + 1 == cStart);
assert(cFinal + 1 == sStart);
assert(sFinal + 1 == hStart);
assert(hFinal + 1 == kStart);
assert(kFinal + 1 == rStart);
assert(rFinal + 1 == s2Start);
assert(s2Final + 1 == qStart);

% package variable descriptions
varInfo.val.sigma = sigma;
varInfo.val.p = p;
varInfo.val.c = c;
varInfo.val.s = s;
varInfo.val.h = h;
varInfo.val.k = k;
varInfo.val.r = r;
varInfo.val.s2 = s2;
varInfo.val.q = q;
varInfo.nVar = startIdx + 1;
assert(isValid(varInfo.val,1,varInfo.nVar,varInfo.nVar));
end

function result = isValid(data, start, final, nExpect)
% get all data from data struct
values = getDataFromStruct(data);

% check that each value is unique
nUnique = numel(unique(values));
result1 = nUnique == numel(values);

% verify that they sum from their lowest to highest
result2 = sum(values) - (final - start + 1)*(start + final)/2 == 0;

% make sure data is all contained between the start and end values.
result3 = final - start + 1 == numel(values);

% make sure that the number of values is correct
result4 = nUnique == nExpect;

% and all results for final outcome
result = result1 & result2 & result3 & result4;
end

function data = getDataFromStruct(input)
    data = [];
    if isstruct(input)
        names = fieldnames(input);
        for iName = 1:numel(names)
            fieldData = input.(names{iName});
            data = [data; getDataFromStruct(fieldData)];                   %#ok
        end
    elseif ischar(input)
        data = [];
    else
        data = input(:);
        data(isnan(data)) = [];        
    end
end