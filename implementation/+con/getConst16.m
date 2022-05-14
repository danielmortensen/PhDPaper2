function Const = getConst16(sim,var,Const)
% initialize function variables
nConst = sum(sim.routes.nRoute) + sim.bus.nBus;
nVal = nConst;

% preallocate
A = nan([nVal,3]);
b = nan([nConst,1]);

% define constraint
iVal = 1;
iConst = 1;
for iBus = 1:sim.bus.nBus
    for iSoc = 1:sim.routes.nRoute(iBus) + 1
        h = var.val.h.val(iBus,iSoc);        
        A(iVal,:) = [iConst, h, 1];
        b(iConst) = sim.bus.maxBattery;
        iVal = iVal + 1;
        iConst = iConst + 1;
    end
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);

% package constraint
Const.Constraint16.A = A;
Const.Constraint16.b = b;
Const.Constraint16.eq = repmat('<',[nConst,1]);
Const.Constraint16.info = "Constrain all SOC be lower then the max SOC";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end