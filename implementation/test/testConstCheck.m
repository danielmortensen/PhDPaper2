function Const = testConstCheck(Const, sol, doPlots)
nVar = numel(Const.obj);
if nargin == 2
    doPlots = false;
elseif strcmp(doPlots,'plotResults')
    doPlots = true;
else
    doPlots = false;
end

for iConst = 1:Const.nConst
    name = "Constraint" + string(iConst);
    curConst = Const.(name);
    equalityIdx = find(curConst.eq == '=');
    lessThanIdx = find(curConst.eq == '<');
    A = toSparse(curConst.A, nVar);
    b = curConst.b;
    Aeq = A(equalityIdx,:);
    Ain = A(lessThanIdx,:);
    beq = b(equalityIdx);
    bin = b(lessThanIdx);    

    % plot constraint and solution values
    if doPlots
        figure;
    end
    Const.(name).myEval.sol = sol;
    if ~isempty(equalityIdx) && ~isempty(lessThanIdx)
        if doPlots
            subplot(1,2,1);
            plot(Aeq*sol,'blue','linewidth',2); hold on;
            plot(beq,'--','color','red');
            title("Blue == red " + name);
            legend('solution','b');
        end
        Const.(name).myEval.equality.Aeq = Aeq;
        Const.(name).myEval.equality.SolEq = Aeq*sol;
        Const.(name).myEval.equality.isCorrect = all(isAlmost(Aeq*sol, beq));
        badConstIdx = find(Aeq*sol ~= beq);
        Const.(name).myEval.equality.badConstIdx = badConstIdx;
        Const.(name).myEval.equality.badConstA = Aeq(badConstIdx,:);
        Const.(name).myEval.equality.badConstb = beq(badConstIdx);
        Const.(name).myEval.equality.beq = beq;

        if doPlots
            subplot(1,2,2);
            plot(Ain*sol,'blue','linewidth',2); hold on;
            plot(bin,'red');
            title("Blue <= red " + name);
            legend('solution','b');
        end
        Const.(name).myEval.inequality.Ain = Ain;
        Const.(name).myEval.inequality.SolIn = Ain*sol;
        Const.(name).myEval.inequality.isCorrect = all(Ain*sol - bin <= 1e-10);
        badConstIdx = find(Ain*sol > bin);
        Const.(name).myEval.inequality.badConstIdx = badConstIdx;
        Const.(name).myEval.inequality.badConstA = Ain(badConstIdx,:);
        Const.(name).myEval.inequality.badConstb = bin(badConstIdx);
        Const.(name).myEval.inequality.bin = bin;

    elseif ~isempty(equalityIdx)
        if doPlots
            plot(Aeq*sol,'blue','linewidth',2); hold on;
            plot(beq,'--','color','red');
            title("Blue == red " + name);
            legend('solution','b');
        end
        Const.(name).myEval.equality.Aeq = Aeq;
        Const.(name).myEval.equality.SolEq = Aeq*sol;
        Const.(name).myEval.equality.isCorrect = all(isAlmost(Aeq*sol, beq));
        badConstIdx = find(Aeq*sol ~= beq);
        Const.(name).myEval.equality.badConstIdx = badConstIdx;
        Const.(name).myEval.equality.badConstA = Aeq(badConstIdx,:);
        Const.(name).myEval.equality.badConstb = beq(badConstIdx);
        Const.(name).myEval.equality.beq = beq;
    else
        if doPlots
            plot(Ain*sol,'blue','linewidth',2); hold on;
            plot(bin,'red');
            title("Blue <= red " + name);
            legend('solution','b');
        end
        Const.(name).myEval.inequality.Ain = Ain;
        Const.(name).myEval.inequality.SolIn = Ain*sol;
        Const.(name).myEval.inequality.isCorrect = all(Ain*sol - bin <= 1e-10);
        badConstIdx = find(Ain*sol > bin);
        Const.(name).myEval.inequality.badConstIdx = badConstIdx;
        Const.(name).myEval.inequality.badConstA = Ain(badConstIdx,:);
        Const.(name).myEval.inequality.badConstb = bin(badConstIdx);
        Const.(name).myEval.inequality.bin = bin;
    end
end
end

function spA = toSparse(A, nCol)
nRow = max(A(:,1));
spA = sparse(A(:,1), A(:,2), A(:,3), nRow, nCol);
end