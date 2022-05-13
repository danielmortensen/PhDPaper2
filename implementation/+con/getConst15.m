function Const = getConst15(sim,var,Const)
% define function params
nConst = sum(sim.bill.onPeak.hours);
nVal = nConst*2;
isOnPeak = sim.bill.onPeak.hours;

% preallocate
A = nan([nVal,3]);
b = nan([nConst,1]);

% define constraint
iConst = 1;
iVal = 1;
q = var.val.q.val.onPeak;
for iTime = 1:sim.maxTimeIdx
if isOnPeak(iTime)
    p = var.val.p.val.total(iTime);
    A(iVal + 0,:) = [iConst, p,  1];
    A(iVal + 1,:) = [iConst, q, -1];
    b(iConst) = 0;
    iConst = iConst + 1;
    iVal = iVal + 2;
end
end

% sanity check dimensions
assert(sum(isnan(A(:)),'all') == 0);
assert(sum(isnan(b),'all') == 0);
assert(size(A,1) == nVal);
assert(size(b,1) == nConst);

% package constraint
Const.Constraint15.A = A;
Const.Constraint15.b = b;
Const.Constraint15.eq = repmat('<',[nConst,1]);
Const.Constraint15.info = "set lower bound for max average power during" + ...
    "on-peak hours.";
end