clear all;
close all;
clc;

%% Define GS symfun

% Define symbolic variables
syms symG_LRS symG_HRS symalpha_p symalpha_d w;

% Define G symbolic functions
G_LTP = symfun(((symG_LRS^symalpha_p - symG_HRS^symalpha_p) * w + symG_HRS^symalpha_p)^(1/symalpha_p), [symG_LRS, symG_HRS, symalpha_p, w]);
G_LTD = symfun(((symG_LRS^symalpha_d - symG_HRS^symalpha_d) * w + symG_HRS^symalpha_d)^(1/symalpha_d), [symG_LRS, symG_HRS, symalpha_d, w]);

% Define GS as the derivative
GS_LTP = diff(G_LTP, w);
GS_LTD = diff(G_LTD, w);

%% Receive user input variables (symG_LRS, symG_HRS, alpha)

answer = inputdlg(["G_LRS", "G_HRS", "max_GS"]);

G_LRS = str2num(answer{1});
G_HRS = str2num(answer{2});
max_GS = str2num(answer{3});

clear answer;

%% Rewrite GS expression

GS_LTP_new = subs(GS_LTP, [symG_LRS, symG_HRS], [G_LRS, G_HRS]);
GS_LTD_new = subs(GS_LTD, [symG_LRS, symG_HRS], [G_LRS, G_HRS]);