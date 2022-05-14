function Const = getConst05(sim,var,Const)
% define function variables
nConst = sim.bus.nBus;
nVal = nConst*2;
A = nan([nVal,3]);
b = nan([nConst,1]);

% define constraint (A and b)
iVal = 1;
iConst = 1;
for iBus = 1:sim.bus.nBus
    nRoute = sim.routes.nRoute(iBus);
    h0 = var.val.h.val(iBus,1);
    h1 = var.val.h.val(iBus,nRoute + 1);
    A(iVal + 0,:) = [iConst, h0,  1];
    A(iVal + 1,:) = [iConst, h1, -1];
    b(iConst) = 0;
    iVal = iVal + 2;
    iConst = iConst + 1;   
end

% sanity check matrix dimensions
assert(sum(isnan(b),'all') == 0);
assert(sum(isnan(A(:)),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraints
Const.Constraint5.A = A;
Const.Constraint5.b = b;
Const.Constraint5.eq = repmat('<',[nConst,1]);
Const.Constraint5.info = "Constrains the first SOC to be less than the last";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end