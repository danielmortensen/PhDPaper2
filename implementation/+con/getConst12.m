function Const = getConst12(sim,var,Const)
nConst = 4*sim.maxTimeIdx*sum(sim.routes.nRoute);
nVal = nConst/4*10;

% preallocate
A = nan([nVal,3]);
b = nan([nConst,1]);
M = sim.charger.chargeRate;

% define constraint
iConst = 1;
iVal = 1;
for iBus = 1:sim.bus.nBus
    for iRoute = 1:sim.routes.nRoute(iBus)
        s2 = var.val.s2.val.offRamp(iBus,iRoute,:);
        p = var.val.p.val.offRamp(iBus,iRoute,:);
        p0 = var.val.p.val.offRampAvg(iBus,iRoute);
        for iTime= 1:sim.maxTimeIdx
            pw = p(iTime);
            sw = s2(iTime);
            A(iVal + 0 ,:) = [iConst, pw, -1];
            A(iVal + 1 ,:) = [iConst, p0,  1];
            A(iVal + 2 ,:) = [iConst, sw,  M];
            b(iConst) = M;

            A(iVal + 3 ,:) = [iConst + 1, pw,  1];
            A(iVal + 4 ,:) = [iConst + 1, p0, -1];
            A(iVal + 5 ,:) = [iConst + 1, sw,  M];
            b(iConst + 1) = M;

            A(iVal + 6 ,:) = [iConst + 2, pw, -1];
            A(iVal + 7 ,:) = [iConst + 2, sw, -M];
            b(iConst + 2) = 0;

            A(iVal + 8 ,:) = [iConst + 3, pw,  1];
            A(iVal + 9,:) = [iConst + 3, sw, -M];
            b(iConst + 3) = 0;
            iVal = iVal + 10;
            iConst = iConst + 4;
        end
    end
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b)) == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraint
Const.Constraint12.A = A;
Const.Constraint12.b = b;
Const.Constraint12.eq = repmat('<',[nConst,1]);
Const.Constraint12.info = "constriants for discretized off-ramp average power";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end