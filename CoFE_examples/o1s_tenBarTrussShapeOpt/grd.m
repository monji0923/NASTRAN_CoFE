% Objective function, constrants, and derivatives for optimization
%
function [objective,con] = grd(X,FEM)

[FEM,FEM_prime] = CoFE_design(FEM,X,@X_2_FEM);

% Stress constraints
con = zeros(20,10);
for i = 1:14
    con(1:10,i)  =  [FEM_prime(i).CROD.stress];
    con(11:20,i) = -[FEM_prime(i).CROD.stress];
end

% calculate mass
objective = zeros(10,1);
massDof = 1:6:FEM.ndof; % pick all of one displacement dof
for i = 1:14
    objective(i) = d(full(sum(sum(FEM_prime(i).M_G(massDof,massDof)))));
end

%% transpose con
con = con.';