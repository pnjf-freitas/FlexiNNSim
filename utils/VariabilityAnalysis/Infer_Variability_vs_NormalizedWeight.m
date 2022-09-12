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
%% Plot symbolic functions
%LTP
fig1 = figure;
%fplot(symG_LTP, [0, str2double(LTP_Coeffvalues{ismember(LTP_Coeffnames, 'P_max')})]);
fplot(symG_LTP, [0,1], 'Color', 'r', 'LineWidth', 3);
%ylim([str2double(LTP_Coeffvalues{ismember(LTP_Coeffnames, 'G_min')}), str2double(LTP_Coeffvalues{ismember(LTP_Coeffnames, 'G_max')})]);
xlabel('Normalized Weight');
ylabel('G (S)');

%LTD
hold on;
fplot(symG_LTD, [0,1], 'Color', 'b', 'LineWidth', 3);

legend('LTP', 'LTD');

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

%% Plot Reference Cycle

x_LTP_rescaled = rescale(x_LTP, 0, LTP_nPulses);
x_LTD_rescaled = rescale(x_LTD, 0, LTD_nPulses) + x_LTP_rescaled(end); % x_LTP_rescaled is summed so that x_LTD is seen as the continuation of x_LTP

fig2 = figure;

plot(x_LTP_rescaled, y_LTP, 'or');
hold on;
plot(x_LTD_rescaled, y_LTD, 'sb');

xlabel('Pulse #');
ylabel('G (S)');
legend('LTP', 'LTD');

%% Define variability

pd_name = 'lognormal';
pd_param1_name = 'mu';
pd_param2_name = 'sigma';
pd_param1 = 0;
pd_param2 = 1e-1; % if sigma (1e-2 default) is multiplied by pd_param1, param2 is absolute sigma and sigma is normalized sigma

pd = makedist(pd_name, pd_param1_name, pd_param1, pd_param2_name, pd_param2);

%% Plot cdf of pd
fig3 = figure;
cdfplot(random(pd, 100, 1)); % Plot ecdf with 100 points

%% Get # of cycles

nCycles = str2double(cell2mat(inputdlg('# of Cycles', '# of Cycles')));

%% Apply variability for # of cycles

% NormG
var_y_LTP = y_LTP .* random(pd, size(y_LTP,1), nCycles);
var_y_LTD = y_LTD .* random(pd, size(y_LTD,1), nCycles);

% DeltaG/G
%{
DeltaG_LTP = (y_LTP .* random(pd, size(y_LTP,1), nCycles) - y_LTP) ./ y_LTP;
var_y_LTP = y_LTP + (y_LTP .* DeltaG_LTP);

DeltaG_LTD = (y_LTD .* random(pd, size(y_LTP,1), nCycles) - y_LTD) ./ y_LTD;
var_y_LTD = y_LTD + (y_LTD .* DeltaG_LTD);
%}
%% Plot variable cycles
fig4 = figure;
for i = 1:nCycles
    plot(x_LTP_rescaled, var_y_LTP(:,i), '.', 'Color', '#808080');
    if i == 1
        hold on;
        xlabel('Pulse #');
        ylabel('G (S)');
        title('Variable LTP');
    end
end

fig5 = figure;
for i = 1:nCycles
    plot(x_LTD_rescaled, var_y_LTD(:,i), '.', 'Color', '#808080');
    if i == 1
        hold on;
        xlabel('Pulse #');
        ylabel('G (S)');
        title('Variable LTD');
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

%% Save Data table for PedroSim
[file, path, indx] = uiputfile;

save(fullfile(path, file), 'Data');