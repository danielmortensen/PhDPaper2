function decision = isAlmost(input1, input2, tolerance)
if nargin == 2
    tolerance = 1e-12;
end
    decision = abs(input1 - input2) < tolerance;
end