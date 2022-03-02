function [varargout] = GetParamFits(NormalizedWeight, ft_str, varargin)
%UNTITLED Summary of this function goes here
%   varargin should take all of the different Params to fit ParamA to
%   ParamB according to the Statistical distribution used
%   Each cell of varargin should in turn also be a 2 cell array containing
%   the cases for both SET and RESET

%ft = fittype('a*exp(-((x-b)/c)^2)+d*x+e');
ft = fittype(ft_str);

fopt = fitoptions(ft);
temp = get(fopt);

if isfield(temp, 'TolFun') && isfield(temp, 'TolX')
    fopt = fitoptions(fopt, ...
        'TolFun', 1e-25, ...
        'TolX', 1e-25);
end

for i = 1 : size(varargin, 2) % Cycles through the arguments of varargin
    for j = 1 : size(varargin{i}, 2) % Cycles through the cells of each varargin
        varargout{i}{j} = fit(NormalizedWeight{j}, varargin{i}{j}, ft, fopt);
    end
end
end

