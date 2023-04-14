function varInfo = getVarParam(param)
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
sigmaFinal = finalIdx;
sigma.type = repmat('B',[sigmaFinal - sigmaStart + 1,1]);

%validate sigma
nSigmaExpect = param.charger.nCharger*nStops;
assert(isValid(sigma.val, sigmaStart, sigmaFinal, nSigmaExpect));
assert(numel(sigma.type) == nSigmaExpect);


% p
pStart = startIdx;
nMaxTime = param.maxTimeIdx;
p.val.onRamp = nan([nBus,maxStops,param.maxTimeIdx]);
p.val.offRamp = nan([nBus,maxStops,param.maxTimeIdx]);
p.val.total = nan([param.maxTimeIdx,1]);
p.val.onRampAvg = nan([nBus,maxStops]);
p.val.offRampAvg = nan([nBus,maxStops]);
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
for iBus = 1:nBus
    finalIdx1 = startIdx + nRoute(iBus) - 1;
    startIdx2 = finalIdx1 + 1;
    finalIdx2 = startIdx2 + nRoute(iBus) - 1;
    p.val.onRampAvg(iBus,1:nRoute(iBus)) = startIdx:finalIdx1;
    p.val.offRampAvg(iBus,1:nRoute(iBus)) = startIdx2:finalIdx2;
    startIdx = finalIdx2 + 1;
end
% p.total contains 96 values
pFinal = startIdx - 1;
p.type = repmat('C',[pFinal - pStart + 1,1]);

% validate p
nPExpect = (nStops*2 + 1)*param.maxTimeIdx + nStops*2;
assert(isValid(p.val ,pStart, pFinal, nPExpect));
assert(numel(p.type) == nPExpect);

% c
cStart = startIdx;
c.val = nan([nBus,maxStops]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus) - 1;
    c.val(iBus,1:nRoute(iBus)) = startIdx:finalIdx;
    startIdx = finalIdx + 1;
end % c containts 91 values
cFinal = startIdx - 1;
c.type = repmat('C',[cFinal - cStart + 1,1]);
nCExpect = nStops;
assert(isValid(c.val,cStart,cFinal,nCExpect));
assert(numel(c.type) == nCExpect);

% s
sStart = startIdx;
s.val = nan([nBus,maxStops]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus) - 1;
    s.val(iBus,1:nRoute(iBus)) = startIdx:finalIdx;
    startIdx = finalIdx + 1;
end % s containts 91 values
sFinal = finalIdx;
s.type = repmat('C',[sFinal - sStart + 1,1]);
nSExpect = nStops;
assert(isValid(s.val,sStart,sFinal,nSExpect));
assert(numel(s.type) == nSExpect);

% h
hStart = startIdx;
h.val = nan([nBus,maxStops + 1]);
for iBus = 1:nBus
    finalIdx = startIdx + nRoute(iBus);
    h.val(iBus,1:nRoute(iBus) + 1) = startIdx:finalIdx;
    startIdx = finalIdx + 1;
end % s containts 97 values
hFinal = finalIdx;
h.type = repmat('C',[hFinal - hStart + 1,1]);
nHExpect = nStops + nBus;
assert(isValid(h.val,hStart,hFinal,nHExpect));
assert(numel(h.type) == nHExpect);

% k
kStart = startIdx;
k.val.start = nan([nBus,maxStops]);
k.val.final = nan([nBus,maxStops]);
k.val.equal = nan([nBus,maxStops]);
iK = 1;
for iBus = 1:nBus
    startIdx1 = startIdx;
    finalIdx1 = startIdx + nRoute(iBus) - 1;
    startIdx2 = finalIdx1 + 1;
    finalIdx2 = startIdx2 + nRoute(iBus) - 1;
    startIdx3 = finalIdx2 + 1;
    finalIdx3 = startIdx3 + nRoute(iBus) - 1;
    k.val.start(iBus,1:nRoute(iBus)) = startIdx1:finalIdx1;
    k.val.final(iBus,1:nRoute(iBus)) = startIdx2:finalIdx2;
    k.val.equal(iBus,1:nRoute(iBus)) = startIdx3:finalIdx3;
    k.type(iK + 0*nRoute(iBus):iK + 1*nRoute(iBus) - 1) = 'I';
    k.type(iK + 1*nRoute(iBus):iK + 2*nRoute(iBus) - 1) = 'I';
    k.type(iK + 2*nRoute(iBus):iK + 3*nRoute(iBus) - 1) = 'B';
    iK = iK + 3*nRoute(iBus);
    startIdx =finalIdx3 + 1;
end % both k.start and k.final both have 91 values each
kFinal = finalIdx3;
k.type = repmat('I',[kFinal - kStart + 1,1]);
nKExpect = nStops*3;
assert(isValid(k.val,kStart,kFinal,nKExpect));
assert(numel(k.type) == nKExpect);

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
rFinal = finalIdx2;
r.type = repmat('C',[rFinal - rStart + 1,1]);
nRExpect = nStops*2;
assert(isValid(r.val,rStart,rFinal,nRExpect));
assert(numel(r.type) == nRExpect);

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
s2Final = finalIdx3;
s2.type = repmat('B',[s2Final - s2Start + 1,1]);
nS2Expect = param.maxTimeIdx*3*nStops;
assert(isValid(s2.val,s2Start,s2Final,nS2Expect));
assert(numel(s2.type) == nS2Expect);

% get contention indices
l.val = nan([nBus,maxStops,nBus,maxStops]);
lStart = startIdx;
nConst = 0;
for iBus = 2:nBus
    for iRoute = 1:nRoute(iBus)
        iTArrive = param.routes.tArrival(iBus,iRoute);
        iTDepart = param.routes.tDepart(iBus,iRoute);
        for jBus = 1:iBus
            for jRoute = 1:nRoute(jBus)
                jTArrive = param.routes.tArrival(jBus,jRoute);
                jTDepart = param.routes.tDepart(jBus,jRoute);
                if iTArrive < jTArrive && iTDepart > jTArrive
                    l.val(iBus,iRoute,jBus,jRoute) = startIdx;
                    startIdx = startIdx + 1;
                    nConst = nConst + 1;
                elseif jTArrive < iTArrive && jTDepart > iTArrive
                    l.val(iBus,iRoute,jBus,jRoute) = startIdx;
                    startIdx = startIdx + 1;
                    nConst = nConst + 1;
                end
            end
        end
    end
end
lFinish = startIdx - 1;
assert(isValid(l.val,lStart,lFinish,nConst));
l.type = repmat('B',[nConst,1]);

% get max power indices
qStart = startIdx;
q.val.onPeak = startIdx;
q.val.all = startIdx + 1;
q.val.bus = startIdx + 2;
qFinal = startIdx + 2;
q.type = repmat('C',[qFinal - qStart + 1,1]);
nQExpect = 3;
assert(isValid(q,qStart,qFinal,nQExpect));
assert(numel(q.type) == nQExpect);

% verify starting and ending positions
assert(sigmaStart == 1);
assert(sigmaFinal + 1 == pStart);
assert(pFinal + 1 == cStart);
assert(cFinal + 1 == sStart);
assert(sFinal + 1 == hStart);
assert(hFinal + 1 == kStart);
assert(kFinal + 1 == rStart);
assert(rFinal + 1 == s2Start);
assert(s2Final + 1 == lStart);
assert(lFinish + 1 == qStart);

% package variable descriptions
varInfo.val.sigma = sigma;
varInfo.val.p = p;
varInfo.val.c = c;
varInfo.val.s = s;
varInfo.val.h = h;
varInfo.val.k = k;
varInfo.val.r = r;
varInfo.val.s2 = s2;
varInfo.val.l = l;
varInfo.val.q = q;
varInfo.nVar = startIdx + 2;
varInfo.type = [sigma.type;
                p.type;
                c.type;
                s.type;
                h.type;
                k.type;
                r.type;
                s2.type;
                l.type;
                q.type];
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