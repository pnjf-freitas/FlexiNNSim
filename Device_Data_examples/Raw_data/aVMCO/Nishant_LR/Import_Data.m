clear all;
close all;

%opts = detectImportOptions("Sheet1.csv");

opts = delimitedTextImportOptions('VariableNamesLine', 0, ...
    'Delimiter', ',', ...
    'WhiteSpace', '--', ...
    'ConsecutiveDelimitersRule', 'split', ...
    'VariableNamesLine', 1, ...
    'VariableTypes', 'double', ...
    'DataLines', 2, ...
    'VariableNamingRule', 'preserve');

Directory = dir('Sheet*.csv');

IBE = [];
for i = 1 : size(Directory, 1)
    Mat{i,1} = readtable(Directory(i).name, opts);
    %IBE = [IBE; Mat{i}(:,2)];
    for j = 1:size(Mat{i}, 2)
        Voltage = str2num(str2mat(string(erase(Mat{i}.Properties.VariableNames(2:end), 'V'))));
        IBE{i}(:,j) = rmmissing(Mat{i}(:,j));
        VTE{i}(:,j) = repelem(Voltage, size(IBE, 1));
    end
end

%Voltages = str2num(str2mat(string(erase(Mat{1}.Properties.VariableNames(2:end), 'V'))));
VTE = repelem(Voltages, 50); %50 is the number of pulses per stage

%{
VTE = [];
IBE = [];
for i = 1:size(Mat,1)
    VTE = [VTE; rmmissing(Mat{i}(1,:))'];
    %Pulse{i,1} = rmmissing(Mat{i}(:,1));
    IBE = [IBE; Mat{i}{}];    
end

Pulse = [0:1:size(IBE,1)-1]';

Data = table(Pulse, VTE, IBE, 'VariableNames', {'Pulse', 'V', 'absI'});
%}