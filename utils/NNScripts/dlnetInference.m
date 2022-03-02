function [varargout] = dlnetInference(dlnet, InputDatabase, trainOptions, SessionArgs)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% Define Disturbance struct
if SessionArgs.Discretize.bool || SessionArgs.D2D.bool || SessionArgs.C2C.bool
    flags.WeightDisturbance = true;
else
    flags.WeightDisturbance = false;
end

if flags.WeightDisturbance == true
    DisturbanceStruct.ProgrammingMethod = SessionArgs.ProgrammingMethod;
    
    DisturbanceStruct.ExecutionEnvironment = trainOptions.ExecutionEnvironment;
    
    %% Discretization
    if SessionArgs.Discretize.bool == true
        load(SessionArgs.Discretize.filePath, 'DiscretizationStruct');
        %Create arrays containing the Normalized Conductance values for:
        %SET
        DisturbanceStruct.DiscretizationStruct.SETArray = ...
            DiscretizationStruct.Fit{1}(linspace(0,1,DiscretizationStruct.NPulses{1}));
        %RESET
        DisturbanceStruct.DiscretizationStruct.RESETArray = ...
            DiscretizationStruct.Fit{2}(linspace(0,1,DiscretizationStruct.NPulses{2}));
        
        %DisturbanceStruct.DiscretizationStruct = DiscretizationStruct;
        clear DiscretizationStruct;
        DisturbanceStruct.Discretization_bool = true;
    else
        DisturbanceStruct.Discretization_bool = false;
    end
    
    %% D2D
    if SessionArgs.D2D.bool == true
        load(SessionArgs.D2D.filePath, 'D2DStruct');
        
        idx = find(dlnet.Learnables.Parameter == "Weights");
               
        DisturbanceStruct.D2DStruct = D2DStruct;        
        clear D2DStruct;
        
        %Cycle through layers
        j=1;
        for i = idx'
            if DisturbanceStruct.D2DStruct.nParams > 1
                %Create Disturbance arrays according to dlnet Learnables
                DisturbanceStruct.D2DStruct.DisturbanceMatrix{j} = random(DisturbanceStruct.D2DStruct.dist, ...
                    DisturbanceStruct.D2DStruct.ParamA.Values, ...
                    DisturbanceStruct.D2DStruct.ParamB.Values, ...
                    size(dlnet.Learnables.Value{i}));
                
            else
                DisturbanceStruct.D2DStruct.DisturbanceMatrix{j} = random(DisturbanceStruct.D2DStruct.dist, ...
                    DisturbanceStruct.D2DStruct.ParamA.Values, ...
                    size(dlnet.Learnables.Value{i}));
            end
            j=j+1;
        end
        
        clear i j;

        DisturbanceStruct.D2D_bool = true;
    else
        DisturbanceStruct.D2D_bool = false;
    end
    
    %% C2C
    if SessionArgs.C2C.bool == true
        load(SessionArgs.C2C.filePath, 'C2CStruct');
        DisturbanceStruct.C2CStruct = C2CStruct;
        clear C2CStruct;
        DisturbanceStruct.C2C_bool = true;
        
        if DisturbanceStruct.C2CStruct.UserInput_bool == true && (class(DisturbanceStruct.C2CStruct.ParamA.Fit) == "cfit")
            temp_fit = DisturbanceStruct.C2CStruct.ParamA.Fit;
            DisturbanceStruct.C2CStruct.ParamA = rmfield(DisturbanceStruct.C2CStruct.ParamA, 'Fit');
            DisturbanceStruct.C2CStruct.ParamA.Fit{1} = temp_fit;
            DisturbanceStruct.C2CStruct.ParamA.Fit{2} = temp_fit;
            clear temp_fit;
        end
        
        if DisturbanceStruct.C2CStruct.UserInput_bool == true && (class(DisturbanceStruct.C2CStruct.ParamB.Fit) == "cfit")
            temp_fit = DisturbanceStruct.C2CStruct.ParamB.Fit;
            DisturbanceStruct.C2CStruct.ParamB = rmfield(DisturbanceStruct.C2CStruct.ParamB, 'Fit');
            DisturbanceStruct.C2CStruct.ParamB.Fit{1} = temp_fit;
            DisturbanceStruct.C2CStruct.ParamB.Fit{2} = temp_fit;
            clear temp_fit;
        end
        
    else
        DisturbanceStruct.C2C_bool = false;
    end
    
end

%% Unfold InputDatabase struct

train_ds = InputDatabase.UnderlyingDatastores{1};
test_ds = InputDatabase.UnderlyingDatastores{2};

train_ds = combine(train_ds, arrayDatastore(train_ds.Labels));
test_ds = combine(test_ds, arrayDatastore(test_ds.Labels));

clear InputDatabase;

%% Other vars
classes = categories(train_ds.Labels);
%numClasses = numel(classes);

%% Get Datasets
dlX = readall(train_ds.UnderlyingDatastores{1});
dlY = readall(train_ds.UnderlyingDatastores{2});

dlXTest = readall(test_ds.UnderlyingDatastores{1});
dlYTest = readall(test_ds.UnderlyingDatstores{2});

%% Gradient evaluation
gradients = dlfeval(@modelGradients,dlnet,dlX,dlY, classes);

%% Weight disturbance
if flags.WeightDisturbance == true

    idx = dlnet.Learnables.Parameter == "Weights";
    weights = dlnet.Learnables(idx,:);

    if trainOptions.ExecutionEnvironment == "parallel"
        weights = weightDisturbance_parallel(weights, DisturbanceStruct, gradients(idx,:));
    else               
        weights = weightDisturbance(weights, DisturbanceStruct, gradients(idx, :));
    end
    
    dlnet.Learnables(idx,:) = weights;
end

%% Evaluate the model gradients, state, and loss using dlfeval and the
% modelGradients function and update the network state.
[~,state,lossTrain,accuracyTrain] = dlfeval(@modelGradients,dlnet,dlX,dlY, classes);
dlnet.State = state;

%% Validation
[~, lossValidation, accuracyValidation] = dlfeval(@modelPredictions, dlnet, dlXTest, dlYTest, classes);  
        

%% Save Results
trainTable = table(lossTrain, accuracyTrain, 'VariableNames', {'Accuracy', 'Loss'});
validationTable = table(lossValidation, accuracyValidation);

varargout{1} = trainTable;
varargout{2} = validationTable;
end

