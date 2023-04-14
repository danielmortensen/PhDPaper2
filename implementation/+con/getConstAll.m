function Const = getConstAll(sim, var)
Const = con.getConst01(sim,var,struct('nConst',0, 'nAllVal',0,'nAllCon',0));
Const = con.getConst02(sim,var,Const);
Const = con.getConst03(sim,var,Const);
Const = con.getConst04(sim,var,Const);
Const = con.getConst05(sim,var,Const);
Const = con.getConst06(sim,var,Const);
Const = con.getConst07(sim,var,Const);
Const = con.getConst08(sim,var,Const);
Const = con.getConst09(sim,var,Const);
Const = con.getConst10(sim,var,Const);
Const = con.getConst11(sim,var,Const);
Const = con.getConst12(sim,var,Const);
Const = con.getConst13(sim,var,Const);
Const = con.getConst14(sim,var,Const);
Const = con.getConst15(sim,var,Const);
Const = con.getConst16(sim,var,Const);
Const = con.getConst17(sim,var,Const);
Const = con.getConst18(sim,var,Const);
if strcmp(sim.objType,'fiscal')
    Const = con.getObjective(sim,var,Const);
elseif strcmp(sim.objType,'energy')
    Const = con.getObjectiveEnergy(sim,var,Const);
elseif strcmp(sim.objType,'busDemand')
    Const = con.getObjectiveBusDemand(sim,var,Const);
else
    Const = con.getObjectiveBase(sim,var,Const);
end