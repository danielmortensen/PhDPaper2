function Const = getConst18(sim,var,Const)
nConst = sim.maxTimeIdx;
nVal = nConst*2;
load = sim.externLoad;

% preallocate
A = nan([nVal,3]);
b = nan([nConst,1]);

% define constraint
iVal = 1;
q = var.val.q.val.bus;
for iConst = 1:nConst
    l = load(iConst);
    p = var.val.p.val.total(iConst);
    A(iVal + 0,:) = [iConst, q, -1];
    A(iVal + 1,:) = [iConst, p, 1];
    b(iConst) = l;
    iVal = iVal + 2;
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraints
Const.Constraint18.A = A;
Const.Constraint18.b = b;
Const.Constraint18.eq = repmat('<',[nConst,1]);
Const.Constraint18.info = "lower bounds constraint for max bus power";
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end