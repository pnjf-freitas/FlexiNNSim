clear all;
close all;

%% Model equations

%G_LTP = B*(1-exp(-P/A)) + G_min
%G_LTD = -B*(1-exp((P-P_max)/A)) + G_max
%B = (G_max - G_min) / (1-exp(-P_max/A))

%G_LTP = fittype('((G_max - G_min) / (1-exp(-P_max/A))) * (1-exp(-P/A)) + G_min', 'dependent', 'G_LTP', 'independent', 'P');
%G_LTD = fittype('-((G_max - G_min) / (1-exp(-P_max/A))) * (1-exp((P-P_max)/A)) + G_max', 'dependent', 'G_LTD', 'independent', 'P');

G_LTP = fittype('((G_LRS^alpha_p - G_HRS^alpha_p) * w + G_HRS^alpha_p)^(1/alpha_p)', 'dependent', 'G_LTP', 'independent', 'w');
G_LTD = fittype('((G_LRS^alpha_d - G_HRS^alpha_d) * w + G_HRS^alpha_d)^(1/alpha_d)', 'dependent', 'G_LTD', 'independent', 'w');

%G_LTP = fittype('G_HRS * (G_LRS/G_HRS)^w', 'dependent', 'G_LTP', 'independent', 'w');
%G_LTD = fittype('G_HRS * (G_LRS/G_HRS)^w', 'dependent', 'G_LTD', 'independent', 'w');

%syms w G_LRS G_HRS alpha_p alpha_d;

%G_LTP = piecewise(w==0, G_HRS * (G_LRS/G_HRS)^w, w~=0, ((G_LRS^alpha_p - G_HRS^alpha_p) * w + G_HRS^alpha_p)^(1/alpha_p));
%G_LTD = piecewise(w==0, G_HRS * (G_LRS/G_HRS)^w, w~=0, ((G_LRS^alpha_d - G_HRS^alpha_d) * w + G_HRS^alpha_d)^(1/alpha_d));

%% Define coeff names
LTP_Coeffnames = coeffnames(G_LTP);
LTD_Coeffnames = coeffnames(G_LTD);

%% Define coeff values
LTP_Coeffvalues = inputdlg(LTP_Coeffnames, 'LTP coefficient values');
if isequal(LTP_Coeffnames, LTD_Coeffnames)
    LTD_Coeffvalues = LTP_Coeffvalues;
else
    LTD_Coeffvalues = inputdlg(LTD_Coeffnames, 'LTD coefficient values');
end

%% If alpha == 0
%alpha_p
if str2double(LTP_Coeffvalues{end}) == 0
    G_LTP = fittype('G_HRS * (G_LRS/G_HRS)^w', 'dependent', 'G_LTP', 'independent', 'w');
    LTP_Coeffnames = LTP_Coeffnames(1:end-1);
    LTP_Coeffvalues = LTP_Coeffvalues(1:end-1);
end

if str2double(LTD_Coeffvalues{end}) == 0
    G_LTD = fittype('G_HRS * (G_LRS/G_HRS)^w', 'dependent', 'G_LTD', 'independent', 'w');
    LTD_Coeffnames = LTD_Coeffnames(1:end-1);
    LTD_Coeffvalues = LTD_Coeffvalues(1:end-1);
end

%% Define symbolic functions
symG_LTP = str2sym(formula(G_LTP));
symG_LTD = str2sym(formula(G_LTD));

%% Substitute symbolic variables by the received coeff values
symG_LTP = subs(symG_LTP, LTP_Coeffnames, LTP_Coeffvalues);
symG_LTD = subs(symG_LTD, LTD_Coeffnames, LTD_Coeffvalues);

%% Convert syms variables to symfuns
symG_LTP = symfun(formula(symG_LTP), symvar(symG_LTP));
symG_LTD = symfun(formula(symG_LTD), symvar(symG_LTD));

%clearvars -except symG_LTP symG_LTD;

%% Get # of pulses per LTP/LTD

nPulses = inputdlg({'LTP # of Pulses', 'LTD # of Pulses'}, '# of Pulses');
LTP_nPulses = str2double(nPulses{1});
LTD_nPulses = str2double(nPulses{2});

clear nPulses;

%% Infer Ref Cycle (w/o variability)

x_LTP = rescale((0:1:LTP_nPulses)', 0 ,1);
x_LTD = rescale((0:1:LTD_nPulses)', 0, 1);

y_LTP = double(symG_LTP(x_LTP));
y_LTD = flipud(double(symG_LTD(x_LTD))); % LTD is flipped as to make sense as the continuation of LTP

%% Change first n points according to a scaling factor (k)
% To use ideal data with no changes, use k=1
% I couldn't make this work with the scaling factor.
% I'm commenting this and trying the other option of changing the data
% manually
% y_LTP_modified & y_LTD_modified must be defined to be used with the rest
% of the script
%{
n = 5;
k = 1/4;

y_LTP_modified = y_LTP;
y_LTD_modified = y_LTD;

y_LTP_modified(2:n+1) = y_LTP(2:n+1) - (y_LTP(2:n+1) .* k);
y_LTD_modified(2:n+1) = y_LTD(2:n+1) + (y_LTD(2:n+1) .* k);
%}

%% Change first points of LTP & LTD manually
y_LTP_modified = y_LTP;
y_LTD_modified = y_LTD;

% Changes will occur here. If no changes wanted, comment this section
% Default changes are meant for curves with G_LRS = 1e-7 & G_HRS = 1e-8
%{
% Change y_LTP (Lower GS)
y_LTP_modified(2) = 2e-8;
y_LTP_modified(3) = 4e-8;
y_LTP_modified(4) = 5e-8;

% Change y_LTD (Lower GS)
y_LTD_modified(2) = 6e-8;
y_LTD_modified(3) = 4e-8;
y_LTD_modified(4) = 3e-8;
%}
%{
% Change y_LTP (Higher GS)
y_LTP_modified(2) = 5e-8;
y_LTP_modified(3) = 5.5e-8;
y_LTP_modified(4) = 5.8e-8;

% Change y_LTD (Higher GS)
y_LTD_modified(2) = 2.7e-8;
y_LTD_modified(3) = 2.5e-8;
y_LTD_modified(4) = 2.3e-8;
%}
%% Define variability

pd_name = 'lognormal';
pd_param1_name = 'mu';
pd_param2_name = 'sigma';
pd_param1 = 0;
pd_param2 = 1e-1; % if sigma (1e-2 default) is multiplied by pd_param1, param2 is absolute sigma and sigma is normalized sigma

pd = makedist(pd_name, pd_param1_name, pd_param1, pd_param2_name, pd_param2);

%% Get # of cycles

nCycles = str2double(cell2mat(inputdlg('# of Cycles', '# of Cycles')));

%% Apply variability for # of cycles

% NormG
var_y_LTP = y_LTP_modified .* random(pd, size(y_LTP,1), nCycles);
var_y_LTD = y_LTD_modified .* random(pd, size(y_LTD,1), nCycles);

% DeltaG/G
%{
DeltaG_LTP = (y_LTP .* random(pd, size(y_LTP,1), nCycles) - y_LTP) ./ y_LTP;
var_y_LTP = y_LTP + (y_LTP .* DeltaG_LTP);

DeltaG_LTD = (y_LTD .* random(pd, size(y_LTP,1), nCycles) - y_LTD) ./ y_LTD;
var_y_LTD = y_LTD + (y_LTD .* DeltaG_LTD);
%}
%% Plot symbolic functions
%LTP Fit
fig1 = figure;
%LTP Data
plot(x_LTP, y_LTP_modified, 'or', 'MarkerSize', 6);
xlabel('Normalized Weight');
ylabel('G (S)');
hold on;

%LTD Data
plot(x_LTD, flipud(y_LTD_modified), 'sb', 'MarkerSize', 6); % y_LTD needs to be reflipped for this specific plot only

%LTP Fit
fplot(symG_LTP, [0,1], '--r', 'LineWidth', 2);

%LTD Fit
fplot(symG_LTD, [0,1], '--b', 'LineWidth', 2);

legend('LTP Data', 'LTD Data', 'LTP Fit', 'LTD Fit');

%% Plot Reference Cycle

x_LTP_rescaled = rescale(x_LTP, 0, LTP_nPulses);
x_LTD_rescaled = rescale(x_LTD, 0, LTD_nPulses) + x_LTP_rescaled(end); % x_LTP_rescaled is summed so that x_LTD is seen as the continuation of x_LTP

fig2 = figure;

% LTP Data
plot(x_LTP_rescaled, y_LTP_modified, 'or', 'MarkerSize', 6);
hold on;

% LTD Data
plot(x_LTD_rescaled, y_LTD_modified, 'sb', 'MarkerSize', 6);

% LTP Fit
plot(x_LTP_rescaled, y_LTP, '--r', 'LineWidth', 2);

% LTD Fit
plot(x_LTD_rescaled, y_LTD, '--b', 'LineWidth', 2);

xlabel('Pulse #');
ylabel('G (S)');
legend('LTP Fit', 'LTD Fit', 'LTP Data', 'LTD Data');

%% Plot cdf of pd
fig3 = figure;
cdfplot(random(pd, 100, 1)); % Plot ecdf with 100 points

%% Plot variable cycles
fig4 = figure;
for i = 1:nCycles
    plot(x_LTP_rescaled, var_y_LTP(:,i), '.', 'Color', '#808080');
    if i == 1
        hold on;
        xlabel('Pulse #');
        ylabel('G (S)');
        title('Variable LTP');
    elseif i == nCycles
        plot(x_LTP_rescaled, y_LTP, '-r', 'LineWidth', 2);
    end
end

fig5 = figure;
for i = 1:nCycles
    plot(x_LTP_rescaled, var_y_LTD(:,i), '.', 'Color', '#808080');
    if i == 1
        hold on;
        xlabel('Pulse #');
        ylabel('G (S)');
        title('Variable LTD');
    elseif i == nCycles
        plot(x_LTP_rescaled, y_LTD, '-b', 'LineWidth', 2);
    end
end

%% Recreate table for PedroSim

for i = 1:nCycles
    if i == 1
        %LTP
        absI = var_y_LTP(:,i);
        V = -ones(size(var_y_LTP, 1), 1); % V is used as dummy data for PedroSim to distinguish SET from RESET
        %LTD
        absI = [absI ; var_y_LTD(2:end, i)];
        V = [V ; ones(size(var_y_LTD, 1) - 1, 1)];
    else
        %LTP
        absI = [absI ; var_y_LTP(2:end, i)];
        V = [V ; -ones(size(var_y_LTP, 1) - 1, 1)];
        %LTD
        absI = [absI ; var_y_LTD(2:end, i)];
        V = [V ; ones(size(var_y_LTD, 1) - 1, 1)];
    end
end

Pulse = (0:1:length(absI)-1)';

Data = table(Pulse, V, absI);

clear Pulse V absI;

%% Plot Data from PedroSim Table
fig6 = figure;
plot(Data.Pulse, Data.absI, '--.r');
xlabel('Pulse #');
ylabel('G (S)');

%% Plot GS/G_LRS (%)
% Define GS
GS_LTP = abs(diff(y_LTP_modified));
GS_LTD = abs(diff(y_LTD_modified));
% Plot
fig7 = figure;
plot(x_LTP(2:end), (GS_LTP./max(y_LTP_modified)).*100, '-or');
hold on;
plot(x_LTD(2:end), (GS_LTD./max(y_LTD_modified)).*100, '-sb');

xlabel('Normalized Weight');
ylabel('GS (%)');
ylim([0, 100]);

legend('LTP', 'LTD');

%% Save Data table for PedroSim
%{
[file, path, indx] = uiputfile('*.mat');

save(fullfile(path, file), 'Data');
%}