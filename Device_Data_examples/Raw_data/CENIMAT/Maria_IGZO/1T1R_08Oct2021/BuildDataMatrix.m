clear all;
close all;
clc;

%% load files

set = readmatrix('set.csv');
reset = readmatrix('reset.csv');

%%
% absI is not acctually |I|, it is I. Need to use -0.1V as read voltage in
% PedroSim interface

absI = [];
V = [];
for i = 1:size(set, 2)
    absI = [absI; set(:,i)];
    V = [V; repelem(1, size(set, 1))'];
    absI = [absI; reset(:,i)];
    V = [V; repelem(-1, size(reset, 1))'];
end

Pulse = (0:1:length(absI)-1)';

Data = table(Pulse, V, absI);

save('Data.mat', 'Data');
