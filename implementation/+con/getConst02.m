function Const = getConst02(param,var,Const)

% define constraint dimensions
nConstr = sum(param.routes.nRoute);
nCharger = param.charger.nCharger;
nVal = nConstr*nCharger;

% preallocate
A = nan([nVal,3]);
b = nan([nConstr,1]);

% define constraints
iConstr = 1;
iVal = 1;
for iBus = 1:param.bus.nBus
    nRoute = param.routes.nRoute(iBus);
    for iRoute = 1:nRoute
        for iCharger = 1:nCharger
            sigma = var.val.sigma.val(iBus,iRoute,iCharger);
            A(iVal,:) = [iConstr, sigma, 1];
            iVal = iVal + 1;
        end
        b(iConstr) = 1;
        iConstr = iConstr + 1;
    end
end

% verify that all is as expected
assert(sum(isnan(A(:))) == 0);
assert(sum(isnan(b)) == 0);

% package constraint
Const.Constraint2.A = A;
Const.Constraint2.b = b;
Const.Constraint2.info = "Constrans the sum of the charge indicators for " + ...
    "each bus to be one for each stop.  This ensures that each bus cannot" + ...
    "charge on two chargers at once.";
Const.Constraint2.eq = repmat('<',[nConstr,1]);
end
