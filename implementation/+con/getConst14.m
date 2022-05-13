function Const = getConst14(sim,var,Const)
nConst = sim.maxTimeIdx;
nVal = nConst*2;

% preallocate
A = nan([nVal,3]);
b = nan([nConst,1]);

% define constraint
iVal = 1;
q = var.val.q.val.all;
for iConst = 1:nConst
    p = var.val.p.val.total(iConst);
    A(iVal,:) = [iConst, q, -1];
    A(iVal + 1,:) = [iConst, p, 1];
    b(iConst) = 0;
    iVal = iVal + 2;
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);

% package constraints
Const.Constraint14.A = A;
Const.Constraint14.b = b;
Const.Constraint14.eq = repmat('<',[nConst,1]);
Const.Constraint14.info = "lower bounds constraint for max average total power";
end