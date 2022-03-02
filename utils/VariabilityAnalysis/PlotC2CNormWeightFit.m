function [ax1_children] = PlotC2CNormWeightFit(NormalizedWeight, paramValues,varargin)
%!! THIS FUNCTION IS CURRENTLY DEPRECATED!!
%   NormalizedWeight is a 2 cell array containing the normalized weights of SET in cell{1} and RESET in cell{2}
%   paramValues a 2 cell array containing the param (A or B) values to
%   plot. Cell{1} is for SET and cell{2} is for RESET
%   args is a struct containing all of the arguments needed for this
%   function
%   varargin{1} is the optional argument containing the param Fits

%   The function outputs ax_children which are the children object of the
%   plotting figure

fig1 = figure;

if nargin > 2
    fig1 = figure;
    plot(varargin{1}{1}, NormalizedWeight{1}, paramValues{1});

else
    fig1 = figure;
    plot(NormalizedWeight{1}, paramValues{1}, 'ob');
   
end

ax1_children = fig1.Children.Children;
end

