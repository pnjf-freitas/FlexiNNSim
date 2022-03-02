function [ax_children, args_out] = Plot_Model(Ref_Cycle, args)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%% args
%args struct contains:
%Ref_Cycle_str
%Ref_Cycle
%
%ft.options for fitting options of the different parameters
%ft.options is a struct with StartPoint, Lower and Upper 
%Each of these is an array of values to be used in fitoptions
%Each array is ordered as follows: [A_LTP, B_LTP, A_LTD, B_LTD, GMin, GMax, PMax]
%
%If in any situation, the above order is changed, the code below must be
%revised and adjusted

ft.options.StartPoint.LTP = args.ft.StartPoint([1,2,5]); %A_LTP, B_LTP, GMin
ft.options.StartPoint.LTD = args.ft.StartPoint([3,4,6,7]); %A_LTD, B_LTD, GMax, PMax

ft.options.Lower.LTP = args.ft.Lower([1,2,5]); %A_LTP, B_LTP, GMin
ft.options.Lower.LTD = args.ft.Lower([3,4,6,7]); %A_LTD, B_LTD, GMax, PMax

ft.options.Upper.LTP = args.ft.Upper([1,2,5]); %A_LTP, B_LTP, GMin
ft.options.Upper.LTD = args.ft.Upper([3,4,6,7]); %A_LTD, B_LTD, GMax, PMax

%% Reference definition

%LTP
Ref.LTP.NormPulse = Ref_Cycle{1,1}.NormPulse;
Ref.LTP.NormG = Ref_Cycle{1,1}.G;
%LTD
Ref.LTD.NormPulse = flipud(Ref_Cycle{1,2}.NormPulse);
Ref.LTD.NormG = Ref_Cycle{1,2}.G;

%% Fit

%LTP
ft.expression.LTP = 'B*(1-exp(-(x/A)))+GMin';
ft.type.LTP = fittype(ft.expression.LTP);
if any(ft.options.StartPoint.LTP) == 0
    ft.options.LTP = fitoptions(ft.expression.LTP, 'Lower', ft.options.Lower.LTP, 'Upper', ft.options.Upper.LTP);
else
    ft.options.LTP = fitoptions(ft.expression.LTP, 'StartPoint', ft.options.StartPoint.LTP, 'Lower', ft.options.Lower.LTP, 'Upper', ft.options.Upper.LTP);
end
ft.LTP = fit(Ref.LTP.NormPulse, Ref.LTP.NormG, ft.type.LTP, ft.options.LTP);


%LTD
ft.expression.LTD = 'B*(1-exp((x-PMax)/A))+GMax';
ft.type.LTD = fittype(ft.expression.LTD);
if any(ft.options.StartPoint.LTD) == 0
    ft.options.LTD = fitoptions(ft.expression.LTD, 'Lower', ft.options.Lower.LTD, 'Upper', ft.options.Upper.LTD);
else
    ft.options.LTD = fitoptions(ft.expression.LTD, 'StartPoint', ft.options.StartPoint.LTD, 'Lower', ft.options.Lower.LTD, 'Upper', ft.options.Upper.LTD);
end
ft.LTD = fit(Ref.LTD.NormPulse, Ref.LTD.NormG, ft.type.LTD, ft.options.LTD);


%% Plot fit
fig1 = figure;
%LTP
plot(Ref.LTP.NormPulse, Ref.LTP.NormG, 'ob', 'MarkerSize', 2);
hold on;
plot(ft.LTP, '-b');
%LTD
plot(Ref.LTD.NormPulse, Ref.LTD.NormG, 'sr', 'MarkerSize', 2)
plot(ft.LTD, '-r');

%% Output to app axes
ax_children = fig1.Children(2).Children;

%% Output Model parameters
args_out.A_LTP = ft.LTP.A;
args_out.B_LTP = ft.LTP.B;
args_out.A_LTD = ft.LTD.A;
args_out.B_LTD = ft.LTD.B;
args_out.GMin = ft.LTP.GMin;
args_out.GMax = ft.LTD.GMax;
args_out.PMax = ft.LTD.PMax;

end

