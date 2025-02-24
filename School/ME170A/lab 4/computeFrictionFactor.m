%862274334
%perez, elijah
%Me18A assignment 4
%10/25/2022
function [F,Re] = computeFrictionFactor(velocity, pipe_parameters, fluid)
%pipe parameters = array [D e]
%fluide= array[p u]
p=fluid(1);
V=velocity;
u=fluid(2);
d=pipe_parameters(1);
e=pipe_parameters(2);
Re= (p*V*d)/u;

if Re<2000
    F=64/Re;

elseif Re>=2000 && Re<=4000
    F=-1;

elseif Re>4000
    f=@(x) -2*log10((e/(3.7*d))+(2.51/(Re*(x)^(0.5))))-(1/(x^(0.5)));
   % f=@(x) -2*log10((e/(3.7*d))+(2.51/(Re*sqrt(x))))-(1/sqrt(x));

    F=fzero(f,0.1);%%%%dont know what to put for initial guess

end
end
