function Const = getConst06(sim,var,Const)
% define function parameters
nConst = sum(sim.routes.nRoute) + sim.bus.nBus;
nVal = nConst;
hMin = sim.bus.minBattery;

% initialize and preallocate
A = nan([nVal,3]);
b = nan([nConst,1]);

% define loop parameters and constraint
iConst = 1;
iVal = 1;
for iBus = 1:sim.bus.nBus
    for iSoc = 1:sim.routes.nRoute(iBus) + 1
        h = var.val.h.val(iBus, iSoc);
        A(iVal,:) = [iConst, h, -1];
        b(iConst) = -hMin;
        iVal = iVal + 1;
        iConst = iConst + 1;
    end
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraint
Const.Constraint6.A = A;
Const.Constraint6.b = b;
Const.Constraint6.eq = repmat('<',[nConst,1]);
Const.Constraint6.info = "constrain that all state of charge variables " + ...
    "be greater than some minimum value";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end