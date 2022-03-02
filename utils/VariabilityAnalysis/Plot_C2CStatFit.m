function [fig1, fig2, ax1, ax2] = Plot_C2CStatFit(Residuals, args)
%NOT IN USE CURRENTLY
%   Detailed explanation goes here

%% User-Input function
if args.User_Input_bool == true
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
    ax1 = fig1.Children.Children;

%% Calculate from data  
else
    %% Fig1 - Probplot of 1 normalized weight value
    
    normalized_weight{1,1} = ( 1 : 1 : size(Residuals{1,1}, 1) )';
    normalized_weight{1,2} = ( 1 : 1 : size(Residuals{1,2}, 1) )';
    
    %SET
    fig1 = figure;
    if args.PlotAll_bool == true
        ax1 = probplot(args.dist, Residuals{1,1}');
    else
        ax1 = probplot(args.dist, Residuals{1,1}(1,:));
    end
    title(strcat(args.dist, ' probplot of SET-Only'));
    %RESET
    fig2 = figure;
    if args.PlotAll_bool == true
        ax2 = probplot(args.dist, Residuals{1,2}');
    else
        ax2 = probplot(args.dist, Residuals{1,2}(1,:));
    end
    title(strcat(args.dist, ' probplot of RESET-Only'));
    
    %fig1_children = fig1.Children.Children;
    %fig2_children = fig2.Children.Children;
end

end

