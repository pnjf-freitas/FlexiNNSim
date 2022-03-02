function [ax_children] = Plot_D2DStatFit(args)
%NOT IN USE CURRENTLY
%   Detailed explanation goes here

%% Make dist
if isfield(args, 'ParamB') == 1
    pd = makedist(args.dist, args.ParamA.Name, args.ParamA.Value, args.ParamB.Name, args.ParamB.Value);
else
    pd = makedist(args.dist, args.ParamA.Name, args.ParamA.Value);
end

%% Plot Dist
x = args.PlotRange.Min : args.PlotRange.Interval : args.PlotRange.Max;

fig1 = figure;

plot(x, cdf(pd,x));

ax_children = fig1.Children.Children;
end

