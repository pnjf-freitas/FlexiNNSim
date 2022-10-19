clearvars;
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

G_LRS = str2double(answer{1});
G_HRS = str2double(answer{2});
max_GS = str2double(answer{3});
n_Pulses = str2double(answer{4});

clear answer;

%% Rewrite GS expression

syms symGS_LTP symGS_LTD;

num_w = 1/n_Pulses;

GS_LTP_eq = eq(symGS_LTP, eliminate(subs(GS_LTP, [symG_LRS, symG_HRS], [G_LRS, G_HRS]), [symG_LRS, symG_HRS]));
GS_LTD_eq = eq(-symGS_LTD, eliminate(subs(GS_LTD, [symG_LRS, symG_HRS], [G_LRS, G_HRS]), [symG_LRS, symG_HRS]));

num_alpha_p = double( vpasolve(eliminate(subs(GS_LTP_eq, [symGS_LTP, w], [max_GS, num_w]), [symGS_LTP, w]), symalpha_p) );
num_alpha_d = double( vpasolve(eliminate(subs(GS_LTD_eq, [symGS_LTD, w], [max_GS, num_w]), [symGS_LTD, w]), symalpha_d) );

%% Plot generated curves

LTP_Model = eq(G, eliminate(subs(G_LTP, [symG_LRS, symG_HRS, symalpha_p], [G_LRS, G_HRS, num_alpha_p]), [symG_LRS, symG_HRS, symalpha_p]));
LTD_Model = eq(G, eliminate(subs(G_LTD, [symG_LRS, symG_HRS, symalpha_d], [G_LRS, G_HRS, num_alpha_d]), [symG_LRS, symG_HRS, symalpha_d]));


% Figure 1 - Conductance vs Normalized Weight
fig1 = figure;

fimplicit(LTP_Model, [0,1], '-r');
ylim([G_HRS, G_LRS]);

hold on;
fimplicit(LTD_Model, [0,1], '-b');

ylabel('G (S)');
xlabel('Normalized Weight');

% Figure 2 - GS vs Normalized Weight
%fig2 = figure;

%fimplicit()