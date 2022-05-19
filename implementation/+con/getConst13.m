function Const = getConst13(sim,var,Const)
nConst = sim.maxTimeIdx;
nVal = (3*sum(sim.routes.nRoute) + 1)*nConst;

% preallocate
A = nan([nVal,3]);
b = sim.externLoad';
p = sim.charger.chargeRate*3600; %convert from kwh/sec. to kwh/h

% define constraint
iConst = 1;
iVal = 1;
pAll = var.val.p.val.total;
for iTime = 1:sim.maxTimeIdx
    A(iVal,:) = [iConst, pAll(iTime), 1];
    iVal = iVal + 1;
    for iBus = 1:sim.bus.nBus
        for iRoute = 1:sim.routes.nRoute(iBus)
            pOn = var.val.p.val.onRamp(iBus,iRoute,iTime);
            pOff = var.val.p.val.offRamp(iBus,iRoute,iTime);
            sCen = var.val.s2.val.center(iBus,iRoute,iTime);
            A(iVal + 0,:) = [iConst, pOff, -1];
            A(iVal + 1,:) = [iConst, pOn,  -1];
            A(iVal + 2,:) = [iConst, sCen, -p];
            iVal = iVal + 3;
        end
    end    
    iConst = iConst + 1;
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraint
Const.Constraint13.A = A;
Const.Constraint13.b = b;
Const.Constraint13.eq = repmat('=',[nConst,1]);
Const.Constraint13.info = "Compute final average power";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end