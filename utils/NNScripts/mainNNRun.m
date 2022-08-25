function [] = mainNNRun(SessionEntry)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% Session Inputs
%Name
SessionArgs.Name = SessionEntry{1};

%Training/Inference
if strcmp(SessionEntry{2}, 'Training')
    SessionArgs.Training.bool = true;
    SessionArgs.Inference.bool = false;
elseif strcmp(SessionEntry{2}, 'Inference')
    SessionArgs.Training.bool = false;
    SessionArgs.Inference.bool = true;
end

%Input Datastore_file
SessionArgs.InputDatastore.filePath = SessionEntry{3};

%Validation Data
SessionArgs.ValidationData = SessionEntry{4};
%Number of Runs
SessionArgs.nRuns = SessionEntry{5};

%Programming Method
SessionArgs.ProgrammingMethod = SessionEntry{6};

%Use_PreviousNN_bool
SessionArgs.PreviousNN.bool = SessionEntry{7};

%Use_LoadedNN_bool
SessionArgs.LoadedNN.bool = SessionEntry{8};

%LoadedNN_file
SessionArgs.LoadedNN.filePath = SessionEntry{9};

%Discretize_file
SessionArgs.Discretize.filePath = SessionEntry{10};
if strcmp(SessionArgs.Discretize.filePath, '')
    SessionArgs.Discretize.bool = false;
else
    SessionArgs.Discretize.bool = true;
    SessionArgs.Discretize.struct = load(SessionArgs.Discretize.filePath, 'DiscretizationStruct');
end

%D2D_file
SessionArgs.D2D.filePath = SessionEntry{11};
if strcmp(SessionArgs.D2D.filePath, '')
    SessionArgs.D2D.bool = false;
else
    SessionArgs.D2D.bool = true;
    SessionArgs.D2D.struct = load(SessionArgs.D2D.filePath, 'D2DStruct');
end

%C2C_file
SessionArgs.C2C.filePath = SessionEntry{12};
if strcmp(SessionArgs.C2C.filePath, '')
    SessionArgs.C2C.bool = false;
else
    SessionArgs.C2C.bool = true;
    SessionArgs.C2C.struct = load(SessionArgs.C2C.filePath, 'C2CStruct');
end

%NN_Layers
SessionArgs.NNLayers.str = SessionEntry{13};

%NN_Options
SessionArgs.NNOptions.str = SessionEntry{14};

clear SessionEntry;

%% Load Input Datastore

S = whos('-file', SessionArgs.InputDatastore.filePath);
temp = load(SessionArgs.InputDatastore.filePath);

ds = temp.(S.name);

clear S temp;

%% Training Options

f = str2func(SessionArgs.NNOptions.str);
trainOptions = f();
%Hotfix to include validation data
if isempty(trainOptions.ValidationData)
    if strcmp(trainOptions.Shuffle, 'once') || strcmp(trainOptions.Shuffle, 'every-epoch')
        ds = shuffle(ds);
    end    
        ds_size = length(ds.Labels);
        
        if SessionArgs.ValidationData < 1  && SessionArgs.ValidationData >= 0
            train_size = ds_size * (1 - SessionArgs.ValidationData);
            %test_size = ds_size * (SessionArgs.ValidationData);
        elseif SessionArgs.ValidationData >= 1
            train_size = ds_size - SessionArgs.ValidationData;
            %test_size = SessionArgs.ValidationData;         
        else
            errordlg('Error: Validation Data portion is negative!')
            return;
        end

    train_ds = subset(ds, 1:train_size);
    test_ds = subset(ds, train_size+1 : ds_size);
    trainOptions.ValidationData = test_ds;
    
    InputDatabase = combine(train_ds, test_ds);
    
end

%% parpool initialization
if trainOptions.DispatchInBackground == true || trainOptions.ExecutionEnvironment == "parallel"
    p = gcp;
end

%% Layers

f = str2func(SessionArgs.NNLayers.str);

layers = f();

%Hotfix for the uninitialized image input layer Mean problem
%imageInputLayer mean is not actually used for anything in dlnetTrain, so
%this exists only to support the creation of the dlnet object

%Compatible with image datastores with ReadSize = 1. Must be revised for
%other datastore types.
if isempty(layers(1,1).Mean)
    layers(1,1).Mean = mean(cell2mat(reshape(readall(train_ds), 1,1,1,[])), 4);
end

lgraph = layerGraph(layers);
dlnet = dlnetwork(lgraph);

clear f lgraph;


%for i = 1 : SessionArgs.nRuns
%% Train Net

close all;

dlnetTrain_Total(dlnet, InputDatabase, trainOptions, SessionArgs);
%{
if SessionArgs.Training.bool
    dlnetTrain(dlnet, InputDatabase, trainOptions, SessionArgs);
else
    dlnetInference(dlnet, InputDatabase, trainOptions, SessionArgs);
end
%}
    
%{
    SavePath = fullfile('SavedSessions', SessionArgs.Name, strcat('Run_', num2str(i)));
    
    if exist(SavePath, 'dir') == 0
        mkdir(SavePath);
    end
    
    %% Export as matlab files
    save(fullfile(SavePath, 'trainTable.mat'), 'trainTable');
    save(fullfile(SavePath, 'validationTable.mat'), 'validationTable');
    save(fullfile(SavePath, 'trainOptions.mat'), 'trainOptions');
    save(fullfile(SavePath, 'layers.mat'), 'layers');
    
    %% Export as csv and jpg
    writetable(trainTable, fullfile(SavePath, 'trainTable.csv'));
    writetable(validationTable, fullfile(SavePath, 'validationTable.csv'));
       
    if isempty(fig1) == 0
        savefig(fig1, fullfile(SavePath, 'TrainFig.fig'));
        exportgraphics(fig1, fullfile(SavePath, 'TrainFig.jpg'));
        close(fig1);
    end
    
    
    
    %% Export Histogram Gif
    if isempty(fig2_struct) == false
        
        if isfield(fig2_struct, 'Data') == true
            save(fullfile(SavePath, 'Weight_Gradient_Data.mat'), '-struct', 'fig2_struct', 'Data');
        end
        
        for j = 1 : length(fig2_struct.frame)
            im = frame2im(fig2_struct.frame(j));
            [imind, cm] = rgb2ind(im,256);
            
            if j == 1
                imwrite(imind, cm, fullfile(SavePath, 'weight_gradient.gif'), 'gif', 'Loopcount', inf);
            else
                imwrite(imind, cm, fullfile(SavePath, 'weight_gradient.gif'), 'gif', 'WriteMode', 'append');
            end
        end
        
        save(fullfile(SavePath, 'fig2_frame.mat'), '-struct', 'fig2_struct', 'frame');
    end
    %% Export gradCAM used Images png
    if isempty(fig3) == 0
        savefig(fig3, fullfile(SavePath, 'TestImages.fig'));
        exportgraphics(fig3, fullfile(SavePath, 'TestImages.jpg'));
        close(fig3);
    end
    
    
    %% Export gradCAM Gif
    if isempty(fig4_struct) == false
        
        for j = 1 : length(fig4_struct.frame)
            im = frame2im(fig4_struct.frame(j));
            [imind, cm] = rgb2ind(im,256);
            
            if j == 1
                imwrite(imind, cm, fullfile(SavePath, 'gradCAM.gif'), 'gif', 'Loopcount', inf);
            else
                imwrite(imind, cm, fullfile(SavePath, 'gradCAM.gif'), 'gif', 'WriteMode', 'append');
            end
        end
        
        save(fullfile(SavePath, 'fig4_frame.mat'), '-struct', 'fig4_struct', 'frame');
        save(fullfile(SavePath, 'fig4_scoreMap.mat'), '-struct', 'fig4_struct', 'scoreMap');
        
    end
    
    %% Save error message
    if isempty(ME) == false
        save(fullfile(SavePath, 'ErrorMessage'), 'ME');
    end
%}    
%end
end

