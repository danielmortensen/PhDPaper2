function Const = getConst01(param,var,Const)

% preallocate for constraints
nVal = sum(param.routes.nRoute)*(4 + 2 + param.charger.nCharger);
nConst = sum(param.routes.nRoute)*4;
iConst = 1;
iA = 1;
A = nan([nVal,3]);
b = nan([nConst,1]);
M = param.maxTime;

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

    % fourth constraint
    A(iA + 4,:) = [iConst + 3, s,  1];
    A(iA + 5,:) = [iConst + 3, c, -1];
    b(iConst + 3) = 0;
    iA = iA + 6;
    for iCharger = 1:param.charger.nCharger
        sigma = var.val.sigma.val(iBus,iRoute,iCharger);
        A(iA,:) = [iConst + 3, sigma, -M];
        iA = iA + 1;
    end

    % update index variables
    iConst = iConst + 4;
end
end

% assert that the number of constraints and values is as expected
assert(sum(isnan(A(:))) == 0);
assert(sum(isnan(b)) == 0);
assert(all(A(:,1) > 0));
assert(all(A(:,2) > 0));

% package constraints
Const.Constraint1.A = A;
Const.Constraint1.b = b;
Const.Constraint1.info = "Constraint for SOC variable placement that" + ...
    " requires all start and end times to be in the bus availability time" + ...
    " and that the start time be before the end time.";
Const.Constraint1.eq = repmat('<',[nConst,1]);
Const.nConst = Const.nConst + 1;
Const.nAllVal = Const.nAllVal + nVal;
Const.nAllCon = Const.nAllCon + nConst;
end
