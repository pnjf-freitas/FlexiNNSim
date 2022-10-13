clear all;
close all;
clc;

%% Define GS symfun

% Define symbolic variables
syms symG_LRS symG_HRS symalpha_p symalpha_d w G;

% Define G symbolic functions
G_LTP = symfun(((symG_LRS^symalpha_p - symG_HRS^symalpha_p) * w + symG_HRS^symalpha_p)^(1/symalpha_p), [symG_LRS, symG_HRS, symalpha_p, w]);
G_LTD = symfun(((symG_LRS^symalpha_d - symG_HRS^symalpha_d) * w + symG_HRS^symalpha_d)^(1/symalpha_d), [symG_LRS, symG_HRS, symalpha_d, w]);

% Define GS as the derivative
GS_LTP = (diff(G_LTP, w)/symG_LRS) * 100;
GS_LTD = (diff(G_LTD, w)/symG_LRS) * 100;

%% Receive user input variables (symG_LRS, symG_HRS, alpha)

answer = inputdlg(["G_LRS", "G_HRS", "max_GS (%)", "# of pulses"]);

G_LRS = str2num(answer{1});
G_HRS = str2num(answer{2});
max_GS = str2num(answer{3});
n_Pulses = str2num(answer{4});

clear answer;

%% Rewrite GS expression

%syms symGS_LTP symGS_LTD;

num_w = 1/n_Pulses;

GS_LTP_eq = eq(max_GS, eliminate(subs(GS_LTP, [symG_LRS, symG_HRS, w], [G_LRS, G_HRS, num_w]), [symG_LRS, symG_HRS, w]));
GS_LTD_eq = eq(-max_GS, eliminate(subs(GS_LTD, [symG_LRS, symG_HRS, w], [G_LRS, G_HRS, num_w]), [symG_LRS, symG_HRS, w]));

num_alpha_p = vpasolve(GS_LTP_eq, symalpha_p);
num_alpha_d = vpasolve(GS_LTD_eq, symalpha_d);

%% Plot generated curves

%LTP_Model = eq(G, eliminate(subs(G_LTP, [symG_LRS, symG_HRS, symalpha_p], [G_LRS, G_HRS, num_alpha_p]), [symG_LRS, symG_HRS, symalpha_p]));
