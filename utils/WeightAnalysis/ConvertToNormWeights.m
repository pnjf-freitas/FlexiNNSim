clear all;
close all;
clc;
%% Grab Weights file and convert it to Normalized Weights

[file, path] = uigetfile;

load(fullfile(path, file));

Weights = Data.Weights;

clear Data;

for i = 1 : size(Weights,1)
    for j = 1 : size(Weights,2)
        NormWeights{i,j} = Weights{i,j};
        NormWeights{i,j}(NormWeights{i,j} >= 0) = rescale(NormWeights{i,j}(NormWeights{i,j} >= 0), 0,1);
        NormWeights{i,j}(NormWeights{i,j} < 0) = rescale(NormWeights{i,j}(NormWeights{i,j} < 0), -1,0);
    end
end

%% Plot Histogram

fig1 = figure;
histogram(NormWeights{1, size(NormWeights, 2)}, 'Normalization', 'probability');
xlabel('Normalized Weight');
ylabel('Probability');
title('1st Epoch');

fig2 = figure;
histogram(NormWeights{size(NormWeights,1), size(NormWeights, 2)}, 'Normalization', 'probability');
xlabel('Normalized Weight');
ylabel('Probability');
title('Final Epoch');

%% Save NormWeights

save(fullfile(path, 'NormWeights.mat'), 'NormWeights');