%Plot All NR histograms

%% Clear workspace
clear all;
close all;
clc;

%% Load Data
%NR
load('NR\NormWeights_GS_NR_RESET.mat');
load('NR\NormWeights_C2C_NR_Gradient.mat');
load('NR\NormWeights_C2C_NR_Selective.mat');
load('NR\NormWeights_GS_C2C_NR_RESET.mat');
load('NR\NormWeights_GS_C2C_NR_Selective.mat');
load('NR\NormWeights_GS_NR_Selective.mat');
load('NR\NormWeights_C2C_NR_RESET.mat');
load('NR\NormWeights_GS_NR_Gradient.mat');
load('NR\NormWeights_C2C_NR_SET.mat');
load('NR\NormWeights_GS_C2C_NR_SET.mat');
load('NR\NormWeights_GS_NR_SET.mat');
load('NR\NormWeights_GS_C2C_NR_Gradient.mat');

%LR
load('LR\NormWeights_C2C_LR_Selective.mat');
load('LR\NormWeights_GS_LR_SET.mat');
load('LR\NormWeights_GS_C2C_LR_SET.mat');
load('LR\NormWeights_GS_C2C_LR_Selective.mat');
load('LR\NormWeights_C2C_LR_Gradient.mat');
load('LR\NormWeights_GS_C2C_LR_RESET.mat');
load('LR\NormWeights_GS_LR_Selective.mat');
load('LR\NormWeights_GS_C2C_LR_Gradient.mat');
load('LR\NormWeights_GS_LR_Gradient.mat');
load('LR\NormWeights_C2C_LR_RESET.mat');
load('LR\NormWeights_GS_LR_RESET.mat');
load('LR\NormWeights_C2C_LR_SET.mat');

%% Create var with all weight data
%Fig1
%1st col of subplot of fig1
NormWeights{1,1,1} = NormWeights_GS_NR_SET{80,4};
NormWeights{2,1,1} = NormWeights_GS_NR_RESET{80,4};
NormWeights{3,1,1} = NormWeights_GS_NR_Gradient{80,4};
NormWeights{4,1,1} = NormWeights_GS_NR_Selective{80,4};

%2nd col of subplot of fig1
NormWeights{1,2,1} = NormWeights_C2C_NR_SET{80,4};
NormWeights{2,2,1} = NormWeights_C2C_NR_RESET{80,4};
NormWeights{3,2,1} = NormWeights_C2C_NR_Gradient{80,4};
NormWeights{4,2,1} = NormWeights_C2C_NR_Selective{80,4};

%3rd col of subplot of fig1
NormWeights{1,3,1} = NormWeights_GS_C2C_NR_SET{80,4};
NormWeights{2,3,1} = NormWeights_GS_C2C_NR_RESET{80,4};
NormWeights{3,3,1} = NormWeights_GS_C2C_NR_Gradient{80,4};
NormWeights{4,3,1} = NormWeights_GS_C2C_NR_Selective{80,4};

%Fig2
%1st col of subplot of fig2
NormWeights{1,1,2} = NormWeights_GS_LR_SET{80,4};
NormWeights{2,1,2} = NormWeights_GS_LR_RESET{80,4};
NormWeights{3,1,2} = NormWeights_GS_LR_Gradient{80,4};
NormWeights{4,1,2} = NormWeights_GS_LR_Selective{80,4};

%2nd col of subplot of fig2
NormWeights{1,2,2} = NormWeights_C2C_LR_SET{80,4};
NormWeights{2,2,2} = NormWeights_C2C_LR_RESET{80,4};
NormWeights{3,2,2} = NormWeights_C2C_LR_Gradient{80,4};
NormWeights{4,2,2} = NormWeights_C2C_LR_Selective{80,4};

%3rd col of subplot of fig2
NormWeights{1,3,2} = NormWeights_GS_C2C_LR_SET{80,4};
NormWeights{2,3,2} = NormWeights_GS_C2C_LR_RESET{80,4};
NormWeights{3,3,2} = NormWeights_GS_C2C_LR_Gradient{80,4};
NormWeights{4,3,2} = NormWeights_GS_C2C_LR_Selective{80,4};

%% Fig1 - plot
%{
fig1 = figure;

k = 1;
for i = 1 : size(NormWeights,1) - 1
    for j = 1 : size(NormWeights,2)
        subplot(size(NormWeights,1) - 1, size(NormWeights,2), k);
        
        h = histogram(NormWeights{i,j,1}, 'Normalization', 'probability');
               
        switch i
            case 1
                %title('SET');
                h.FaceColor = [1,0,0];
                if j == 1
                    ylabel('SET');
                end
            case 2
                %title('RESET');
                h.FaceColor = [0 0.4470 0.7410];
                if j == 1
                    ylabel('RESET');
                end
            case 3
                %title('Gradient-based');
                h.FaceColor = [0.9290 0.6940 0.1250];
                if j == 1
                    ylabel('Gradient-based');  
                end
                xlabel('Normalized Weight');
        end
        
        switch j
            case 1
                if i == 1
                    title('GS');
                end
            case 2
                if i == 1
                    title('C2C');
                end
            case 3
                if i == 1
                    title('GS+C2C');
                end
        end
        
        %xlabel('Normalized Weight');
        %ylabel('Probability');
        
        k=k+1;
    end
end

clear i j k;
%}

%% Fig1 - Tiled layout

fig1 = figure;

%k = 1;
t = tiledlayout(size(NormWeights,1)-1, size(NormWeights,2));

for i = 1 : size(NormWeights,1) - 1
    for j = 1 : size(NormWeights,2)

        nexttile;
        
        h = histogram(NormWeights{i,j,1}, 'Normalization', 'probability', 'EdgeAlpha', 0.1, 'LineWidth', 0.2, 'FaceAlpha', 1);
               
        switch i
            case 1
                %title('SET');
                h.FaceColor = [1,0,0];
                if j == 1
                    ylabel('SET');
                end
            case 2
                %title('RESET');
                h.FaceColor = [0 0.4470 0.7410];
                if j == 1
                    ylabel('RESET');
                end
            case 3
                %title('Gradient-based');
                h.FaceColor = [0.9290 0.6940 0.1250];
                if j == 1
                    ylabel('Gradient-based');  
                end
                %xlabel('Normalized Weight');
        end
        
        switch j
            case 1
                if i == 1
                    title('GS');
                end
            case 2
                if i == 1
                    title('C2C');
                end
            case 3
                if i == 1
                    title('GS+C2C');
                end
        end
        
    end
end

t.Padding = 'compact';
t.TileSpacing = 'compact';

clear i j k;
%% Fig2 - plot
%{
fig2 = figure;

k = 1;
for i = 1 : size(NormWeights,1) - 1
    for j = 1 : size(NormWeights,2)
        subplot(size(NormWeights,1) - 1, size(NormWeights,2), k);
        
        h = histogram(NormWeights{i,j,2}, 'Normalization', 'probability');    
        
        switch i
            case 1
                %title('SET');
                h.FaceColor = [1,0,0];
                if j == 1
                    ylabel('SET');
                end
            case 2
                %title('RESET');
                h.FaceColor = [0 0.4470 0.7410];
                if j == 1
                    ylabel('RESET');
                end
            case 3
                %title('Gradient-based');
                h.FaceColor = [0.9290 0.6940 0.1250];
                if j == 1
                    ylabel('Gradient-based');                    
                end
                xlabel('Normalized Weight');
        end
        
        switch j
            case 1
                if i == 1
                    title('GS');
                end
            case 2
                if i == 1
                    title('C2C');
                end
            case 3
                if i == 1
                    title('GS+C2C');
                end
        end
               
        %ylabel('Probability');
        
        k=k+1;
    end
end

clear i j k;
%}

%% Fig2 - Tiled layout

fig1 = figure;

t = tiledlayout(size(NormWeights,1)-1, size(NormWeights,2));

for i = 1 : size(NormWeights,1) - 1
    for j = 1 : size(NormWeights,2)
        
        nexttile;
        
        h = histogram(NormWeights{i,j,2}, 'Normalization', 'probability', 'EdgeAlpha', 0.3, 'LineWidth', 0.2, 'FaceAlpha', 1);
               
        switch i
            case 1
                %title('SET');
                h.FaceColor = [1,0,0];
                if j == 1
                    ylabel('SET');
                end
            case 2
                %title('RESET');
                h.FaceColor = [0 0.4470 0.7410];
                if j == 1
                    ylabel('RESET');
                end
            case 3
                %title('Gradient-based');
                h.FaceColor = [0.9290 0.6940 0.1250];
                if j == 1
                    ylabel('Gradient-based');  
                end
                %xlabel('Normalized Weight');
        end
        
        switch j
            case 1
                if i == 1
                    title('GS');
                end
            case 2
                if i == 1
                    title('C2C');
                end
            case 3
                if i == 1
                    title('GS+C2C');
                end
        end
        
    end
end

t.Padding = 'compact';
t.TileSpacing = 'compact';

clear i j k;