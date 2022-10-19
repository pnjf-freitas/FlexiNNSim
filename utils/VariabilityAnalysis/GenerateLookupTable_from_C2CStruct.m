clearvars;
close all;
clc;

%% Load C2C struct file
% Get filename and path
[file, path] = uigetfile('*.mat', 'Select C2C Struct file');

% Check if user pressed cancel in the dialog box
if isequal(file, 0) || isequal(path, 0)
    disp('User pressed cancel');
    return;
else
    disp(strcat('User selected: ', fullfile(path, file)));
end

% Load file
load(fullfile(path, file));

if C2CStruct.dist == "Weibull"
    C2CStruct.ParamA.Name = "A";
    C2CStruct.ParamB.Name = "B";
end

%% Plot C2C Fit params

fig1 = figure;

if C2CStruct.nParams == 2
    % Param A
    % Set
    subplot(2,2,1);
    plot(C2CStruct.ParamA.Fit{1}, linspace(0,1,length(C2CStruct.ParamA.Values{1})), C2CStruct.ParamA.Values{1});
    xlabel('Normalized Weight');
    ylabel('\alpha');
    title('SET');
    
    % Reset
    subplot(2,2,2);
    plot(C2CStruct.ParamA.Fit{2}, linspace(0,1,length(C2CStruct.ParamA.Values{2})), C2CStruct.ParamA.Values{2});
    xlabel('Normalized Weight');
    ylabel('\alpha');
    title('RESET');
    
    %ParamB
    % Set
    subplot(2,2,3);
    plot(C2CStruct.ParamB.Fit{1}, linspace(0,1,length(C2CStruct.ParamB.Values{1})), C2CStruct.ParamB.Values{1});
    xlabel('Normalized Weight');
    ylabel('\beta');
    title('SET');
    
    % Reset
    subplot(2,2,4);
    plot(C2CStruct.ParamB.Fit{2}, linspace(0,1,length(C2CStruct.ParamB.Values{2})), C2CStruct.ParamB.Values{2});
    xlabel('Normalized Weight');
    ylabel('\beta');
    title('RESET');
    
elseif C2CStruct.nParams == 1
    % Param A
    % Set
    subplot(2,1,1);
    plot(C2CStruct.ParamA.Fit{1}, linspace(0,1,length(C2CStruct.ParamA.Values{1})), C2CStruct.ParamA.Values{1});
    xlabel('Normalized Weight');
    ylabel('\alpha');
    title('SET');
    
    % Reset
    subplot(2,1,2);
    plot(C2CStruct.ParamA.Fit{2}, linspace(0,1,length(C2CStruct.ParamA.Values{2})), C2CStruct.ParamA.Values{2});
    xlabel('Normalized Weight');
    ylabel('\alpha');
    title('RESET');
else
    error(strcat('Error: C2CStruct.nParams should be 1 or 2. C2CStruct.nParams == ', str2double(C2CStruct.nParams)));
end

%% Input dialog: Infer from Param Data points or Fitted line
answer = questdlg('Infer Lookup Table from Params Data or Fitted line?', 'Data or Fit?', 'Data', 'Fit', 'Cancel');

switch answer
    case 'Data'
        nWeights = length(C2CStruct.ParamA.Values{1});
        
        %ParamA
        ParamsData.ParamA.X{1} = linspace(0,1,length(C2CStruct.ParamA.Values{1}));
        ParamsData.ParamA.X{2} = linspace(0,1,length(C2CStruct.ParamA.Values{2}));
        ParamsData.ParamA.Y{1} = C2CStruct.ParamA.Values{1};
        ParamsData.ParamA.Y{2} = C2CStruct.ParamA.Values{2};
        
        %ParamB
        if C2CStruct.nParams == 2
            ParamsData.ParamB.X{1} = linspace(0,1,length(C2CStruct.ParamB.Values{1}));
            ParamsData.ParamB.X{2} = linspace(0,1,length(C2CStruct.ParamB.Values{2}));
            ParamsData.ParamB.Y{1} = C2CStruct.ParamB.Values{1};
            ParamsData.ParamB.Y{2} = C2CStruct.ParamB.Values{2};
        end
    case 'Fit'
        
        nWeights = inputdlg('# of normalized weight data points', 'Input');
        nWeights = str2double(nWeights{1});
        
        ParamsData.ParamA.X{1} = linspace(0,1,nWeights);
        ParamsData.ParamA.X{2} = linspace(0,1,nWeights);
        ParamsData.ParamA.Y{1} = C2CStruct.ParamA.Fit{1}(ParamsData.ParamA.X{1});
        ParamsData.ParamA.Y{2} = C2CStruct.ParamA.Fit{2}(ParamsData.ParamA.X{2});
        
        %ParamB
        if C2CStruct.nParams == 2
            ParamsData.ParamB.X{1} = linspace(0,1,nWeights);
            ParamsData.ParamB.X{2} = linspace(0,1,nWeights);
            ParamsData.ParamB.Y{1} = C2CStruct.ParamB.Fit{1}(ParamsData.ParamB.X{1});
            ParamsData.ParamB.Y{2} = C2CStruct.ParamB.Fit{2}(ParamsData.ParamB.X{2});
        end
    case 'Cancel'
        disp('Cancelled by user');
        return;
end

%% Generate Probability distributions
%{
for i = 1:nWeights
    for j = 1:2
        pd{j}(i,1) = makedist(C2CStruct.dist, C2CStruct.ParamA.Name, ParamsData.ParamA.Y{j}(i), C2CStruct.ParamB.Name, ParamsData.ParamB.Y{j}(i));
    end
end
clear i j;
%}

%% Generate G_Matrix
nCycles = 100;

for i = 1:nWeights
    for j = 1:2
        Normalized_G_Matrix{j}(i,:) = random(C2CStruct.dist, ParamsData.ParamA.Y{j}(i), ParamsData.ParamB.Y{j}(i), [1, nCycles]);
    end
end

%% Generate lookup table

[x_set, y_set, pp_set] = GenerateLookupTable(Normalized_G_Matrix{1}, false);
[x_reset, y_reset, pp_reset] = GenerateLookupTable(Normalized_G_Matrix{2}, true);
