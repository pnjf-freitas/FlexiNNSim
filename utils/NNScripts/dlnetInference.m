function [varargout] = dlnetInference(dlnet, InputDatabase, trainOptions, SessionArgs)
%ToDo List:
% -Saving the graphs should include Weight Histogram before and after
% disturbance; GradCam before and after disturbance; Boxplots or CDF with the NN
% accuracy loss with data from all runs


%% TEMP
%{
if trainOptions.ExecutionEnvironment == "auto"
    trainOptions.ExecutionEnvironment = "cpu";
end
%}

%% Define flags
if SessionArgs.Discretize.bool || SessionArgs.D2D.bool || SessionArgs.C2C.bool
    flags.WeightDisturbance = true;
else
    flags.WeightDisturbance = false;
end

flags.WeightHistogramPlot = true;
flags.SaveWeightsGradients = true;

flags.GradCAM = false;

%% Define Disturbance struct
if flags.WeightDisturbance == true
    DisturbanceStruct.ProgrammingMethod = SessionArgs.ProgrammingMethod;
    
    DisturbanceStruct.ExecutionEnvironment = trainOptions.ExecutionEnvironment;
    
    %% Discretization
    if SessionArgs.Discretize.bool == true
        load(SessionArgs.Discretize.filePath, 'DiscretizationStruct');
        %Create arrays containing the Normalized Conductance values for:
        %SET
        DisturbanceStruct.DiscretizationStruct.SETArray = ...
            unique(DiscretizationStruct.Fit{1}(linspace(0,1,DiscretizationStruct.NPulses{1})));
        %RESET
        DisturbanceStruct.DiscretizationStruct.RESETArray = ...
            unique(DiscretizationStruct.Fit{2}(linspace(0,1,DiscretizationStruct.NPulses{2})));
        
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

clear InputDatabase;

%% Other vars
classes = categories(train_ds.Labels);
%numClasses = numel(classes);

if trainOptions.ExecutionEnvironment == "parallel"
    miniBatch_Env = "cpu";
else
    miniBatch_Env = trainOptions.ExecutionEnvironment;
end

%% Training Progress
if trainOptions.Plots == "training-progress"
    [fig1, lineAccTrain, lineAccValidation, lineLossTrain, lineLossValidation] = fig1_initialize();
end

%% Weight Histograms
if flags.WeightHistogramPlot == true
    [fig2, nLayers] = fig2_initialize(dlnet);
end

%% Velocity parameter initialization
velocity = [];

%%

train_ds = combine(train_ds, arrayDatastore(train_ds.Labels));
test_ds = combine(test_ds, arrayDatastore(test_ds.Labels));


%%
mbq = minibatchqueue(train_ds, ...
    'MiniBatchSize', trainOptions.MiniBatchSize, ...
    'PartialMiniBatch', "return", ...
    'MiniBatchFcn', @preprocessMiniBatch, ...
    'DispatchInBackground', trainOptions.DispatchInBackground, ...
    'OutputCast', 'single', ...
    'OutputAsDlarray', true, ...
    'MiniBatchFormat', {'SSCB', ''}, ...
    'OutputEnvironment', miniBatch_Env);

mbqTest = minibatchqueue(test_ds, ...
    'MiniBatchSize',trainOptions.MiniBatchSize, ...
    'PartialMiniBatch', "return", ...
    'MiniBatchFcn',@preprocessMiniBatch, ...
    'DispatchInBackground', trainOptions.DispatchInBackground, ...
    'OutputCast', 'single', ...
    'OutputAsDlarray', true, ...
    'MiniBatchFormat', {'SSCB', ''}, ...
    'OutputEnvironment', miniBatch_Env);

%Get Test Data
dlXTest = [];
dlYTest = [];

while hasdata(mbqTest)
    [dlXTest_temp, dlYTest_temp] = next(mbqTest);
    dlXTest = cat(4, dlXTest , dlXTest_temp);
    dlYTest = cat(2, dlYTest, dlYTest_temp);
end
%reset(mbqTest);
clear dlXTest_temp dlYTest_temp mbqTest;

%% GradCAM Initialization
GradCAM_Initialization;

%% Variable Initialization

dlnet_0 = dlnet;

if strcmp(trainOptions.Shuffle, 'once')
    shuffle(mbq);
end

% Table containing the data for inference (each row is the run #)
%Inference_table = table(Undisturbed_Train_Acc, Undisturbed_Train_Loss, Undisturbed_Validation_Acc, Undisturbed_Validation_Acc, ...
%    Disturbed_Train_Acc, Disturbed_Train_Loss, Disturbed_Validation_Acc, Disturbed_Validation_Loss);

Inference_Table = table('Size', [SessionArgs.nRuns, 10], ...
    'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Undisturbed_Train_Acc', 'Disturbed_Train_Acc', 'Undisturbed_Train_Loss', 'Disturbed_Train_Loss', ...
    'Undisturbed_Validation_Acc', 'Disturbed_Validation_Acc', 'Undisturbed_Validation_Loss', 'Disturbed_Validation_Loss', ...
    'NN_Train_Acc_Loss', 'NN_Validation_Acc_Loss'});

for run = 1:SessionArgs.nRuns
    dlnet = dlnet_0;
    
    iteration = 0;
    start = tic;

    total_TrainAcc = [];
    total_TrainLoss = [];

    total_ValidationAcc = [];
    total_ValidationLoss = [];

    %% Loop over epochs.

    j = 1;
    k = 1;


    for epoch = 1:trainOptions.MaxEpochs
        %% Shuffle data.
        if strcmp(trainOptions.Shuffle, 'every-epoch')
            shuffle(mbq);
        end

        %% Loop over mini-batches.
        while hasdata(mbq)
            iteration = iteration + 1;

            %% Read mini-batch of data.
            [dlX, dlY] = next(mbq);

            %% If training on a GPU, then convert data to gpuArray.
            if (trainOptions.ExecutionEnvironment == "auto" && canUseGPU) || trainOptions.ExecutionEnvironment == "gpu"
                dlX = gpuArray(dlX);
            end

            %% Evaluate the model gradients, state, and loss using dlfeval and the
            % modelGradients function and update the network state.
            try
                [gradients,state,lossTrain,accuracyTrain] = dlfeval(@modelGradients,dlnet,dlX,dlY, classes);
            catch ME
                break;
            end
            dlnet.State = state;

            total_TrainAcc = [total_TrainAcc ; accuracyTrain];
            total_TrainLoss = [total_TrainLoss ; lossTrain];

            %% L2Regularization
            if trainOptions.L2Regularization > 0
                idx = dlnet.Learnables.Parameter == "Weights";
                gradients(idx,:) = dlupdate(@(g,w) g + trainOptions.L2Regularization*w, ...
                    gradients(idx,:), ...
                    dlnet.Learnables(idx,:));
            end

            %% Gradient Clipping
            if isinf(trainOptions.GradientThreshold) == false
                switch trainOptions.GradientThresholdMethod
                    case "global-l2norm"
                        gradients = thresholdGlobalL2Norm(gradients, gradientThreshold);
                    case "l2norm"
                        gradients = dlupdate(@(g) thresholdL2Norm(g, gradientThreshold),gradients);
                    case "absolute-value"
                        gradients = dlupdate(@(g) thresholdAbsoluteValue(g, gradientThreshold),gradients);
                end
            end       

            %% Determine learning rate for time-based decay learning rate schedule.
            if iteration == 1
                learnRate = trainOptions.InitialLearnRate;
            end       
            if trainOptions.LearnRateSchedule == "piecewise" && (mod(epoch, trainOptions.DropPeriod) == 0)
                learnRate = learnRate * trainOptions.LearnRateDropFactor;
            end

            %% Validation
            if mod(iteration, trainOptions.ValidationFrequency) == 0 || iteration == 1
                try
                    [~, lossValidation, accuracyValidation] = ...
                        dlfeval(@modelPredictions, dlnet, dlXTest, dlYTest, classes);
                catch ME
                    break;
                end
                total_ValidationAcc = [total_ValidationAcc ; accuracyValidation];
                total_ValidationLoss = [total_ValidationLoss ; lossValidation];
            end        

            %% Update the network parameters using the SGDM optimizer.
            [dlnet,velocity] = sgdmupdate(dlnet,gradients,velocity,learnRate,trainOptions.Momentum);

            %% Display the training progress.
            if trainOptions.Plots == "training-progress"
                %Acc
                %subplot(2,1,1);
                D = duration(0,0,toc(start),'Format','hh:mm:ss');
                title(fig1.Children(2), "Epoch: " + epoch + ", Elapsed: " + string(D));
                addpoints(lineAccTrain,iteration,accuracyTrain);
                if mod(iteration, trainOptions.ValidationFrequency) == 0 || iteration == 1
                    addpoints(lineAccValidation,iteration,accuracyValidation);
                end
                drawnow;
                %Loss
                %subplot(2,1,2);
                addpoints(lineLossTrain,iteration,lossTrain);
                if mod(iteration, trainOptions.ValidationFrequency) == 0 || iteration == 1
                    addpoints(lineLossValidation, iteration, lossValidation);
                end
                drawnow;
            end

            %% Display gradient histogram
            if flags.WeightHistogramPlot == true && (mod(iteration, trainOptions.ValidationFrequency) == 0 || iteration == 1)
                temp_idx = find(idx);
                for i = 1 : length(fig2.Children) - 1
                    %Weights
                    if i > nLayers
                        histogram(fig2.Children(i), extractdata(gradients.Value{temp_idx(i-nLayers), :}));

                        if flags.SaveWeightsGradients == true
                            fig2_struct.Data.Gradients{j,i-nLayers} = fig2.Children(i).Children.Data;
                        end
                    %Gradients
                    else
                        histogram(fig2.Children(i), extractdata(dlnet.Learnables.Value{temp_idx(i), :}));

                        if flags.SaveWeightsGradients == true
                            fig2_struct.Data.Weights{j,i} = fig2.Children(i).Children.Data;
                        end
                    end
                end

                D = duration(0,0,toc(start),'Format','hh:mm:ss');
                set(fig2.Children(length(fig2.Children)), 'String', "Epoch: " + epoch + ", Elapsed: " + string(D));
                %sgtitle(fig2, "Epoch: " + epoch + ", Elapsed: " + string(D));

                %Capture plot as an image
                fig2_struct.frame(j) = getframe(fig2);

                j=j+1;
            end

            %% Display GradCAM
            if flags.GradCAM == true
                if iteration == 1 || mod(iteration, trainOptions.ValidationFrequency) == 0

                    for l = 1 : length(fig4.Children)-1
                        Display_prediction = dlfeval(@modelPredictions, dlnet, dlXTest(:,:,:,Digit_idx(l)), dlYTest(:,Digit_idx(l)), classes);
                        scoreMap = gradCAM(dlnet, dlXTest(:,:,:,Digit_idx(l)), Display_prediction);
                        fig4.Children(l+1).Children.CData = scoreMap;
                        fig4.Children(l+1).Title.String = strcat("Prediction = ", string(Display_prediction));

                        fig4_struct.scoreMap{k,l} = scoreMap;                   
                    end

                    set(fig4.Children(1), 'String', "Epoch: " + epoch + ", Elapsed: " + string(D));

                    fig4_struct.frame(k) = getframe(fig4);

                    k=k+1;
                end
            end

            %% Verbosity
            if trainOptions.Verbose && (iteration == 1 || mod(iteration,trainOptions.VerboseFrequency) == 0)
                if iteration == 1
                    disp("|======================================================================================================================|");
                    disp("|  Epoch  |  Iteration  |  Time Elapsed  |  Mini-batch  |  Validation  |  Mini-batch  |  Validation  |  Base Learning  |");
                    disp("|         |             |   (hh:mm:ss)   |   Accuracy   |   Accuracy   |     Loss     |     Loss     |      Rate       |");
                    disp("|======================================================================================================================|");
                end
                D = duration(0,0,toc(start), 'Format', 'hh:mm:ss');

                if isempty(trainOptions.ValidationData)
                    accuracyValidation = "";
                    lossValidation = "";
                end

                disp("| " + ...
                    pad(num2str(epoch),7,'left') + " | " + ...
                    pad(num2str(iteration),11,'left') + " | " + ...
                    pad(string(D),14,'left') + " | " + ...
                    pad(num2str(accuracyTrain),12,'left') + " | " + ...
                    pad(num2str(accuracyValidation),12,'left') + " | " + ...
                    pad(num2str(lossTrain),12,'left') + " | " + ...
                    pad(num2str(lossValidation),12,'left') + " | " + ...
                    pad(num2str(learnRate),15,'left') + " |");
            end

        end

        if exist('ME') ~= 0
            break;
        end

        reset(mbq);
    end

    %% Weight Disturbance
    % Weight disturbance applied only after training is complete
    %% Weight disturbance

    if flags.WeightDisturbance == true && SessionArgs.Training.bool == false

        % This condition exists only because of the gradient-based
        % programming method for the first iteration
        %{
        if iteration == 1
            gradients = dlfeval(@modelGradients,dlnet,dlX,dlY, classes);
        end
        %}
        idx = dlnet.Learnables.Parameter == "Weights";
        weights = dlnet.Learnables(idx,:);
        %clear idx;
        if trainOptions.ExecutionEnvironment == "parallel"
            weights = weightDisturbance_parallel(weights, DisturbanceStruct, gradients(idx,:));
        else               
            weights = weightDisturbance(weights, DisturbanceStruct, gradients(idx, :));
        end
        %weights = dlupdate(@(weights, DisturbanceStruct) weightDisturbance, weights, DisturbanceStruct);
        dlnet.Learnables(idx,:) = weights;
    end
    
    %% Re-evaluate NN accuracy
    % Evaluate the model gradients, state, and loss using dlfeval and the
    % modelGradients function and update the network state.
    try
        [gradients,state,lossTrain,accuracyTrain] = dlfeval(@modelGradients,dlnet,dlX,dlY, classes);
    catch ME
        break;
    end
    dlnet.State = state;

    total_TrainAcc = [total_TrainAcc ; accuracyTrain];
    total_TrainLoss = [total_TrainLoss ; lossTrain];
            
    try
        [~, lossValidation, accuracyValidation] = ...
            dlfeval(@modelPredictions, dlnet, dlXTest, dlYTest, classes);
    catch ME
        break;
    end
    total_ValidationAcc = [total_ValidationAcc ; accuracyValidation];
    total_ValidationLoss = [total_ValidationLoss ; lossValidation];
    
    %% Build table containing inference data
    Inference_Table.Undisturbed_Train_Acc(run) = total_TrainAcc(end-1);
    Inference_Table.Disturbed_Train_Acc(run) = total_TrainAcc(end);
    Inference_Table.Undisturbed_Train_Loss(run) = total_TrainLoss(end-1);
    Inference_Table.Disturbed_Train_Loss(run) = total_TrainLoss(end);
    Inference_Table.Undisturbed_Validation_Acc(run) = total_ValidationAcc(end-1);
    Inference_Table.Disturbed_Validation_Acc(run) = total_ValidationAcc(end);
    Inference_Table.Undisturbed_Validation_Loss(run) = total_ValidationLoss(end-1);
    Inference_Table.Disturbed_Validation_Loss(run) = total_ValidationLoss(end);
    Inference_Table.NN_Train_Acc_Loss(run) = Inference_Table.Undisturbed_Train_Acc(run) - Inference_Table.Disturbed_Train_Acc(run);
    Inference_Table.NN_Validation_Acc_Loss(run) = Inference_Table.Undisturbed_Validation_Acc(run) - Inference_Table.Disturbed_Validation_Acc(run);
    
    %% Verbosity
    if trainOptions.Verbose
        disp("|======================================================================================================================|");
        disp(strcat("Run ", num2str(run), "/", num2str(SessionArgs.nRuns), " completed."));
        disp(strcat("Undisturbed training accuracy: ", num2str(Inference_Table.Undisturbed_Train_Acc(run)), "%"));
        disp(strcat("Disturbed training accuracy: ", num2str(Inference_Table.Disturbed_Train_Acc(run)), "%"));
        disp(strcat("NN training accuracy loss: ", num2str(Inference_Table.NN_Train_Acc_Loss(run)), "%"));
        disp(strcat("Undisturbed validation accuracy: ", num2str(Inference_Table.Undisturbed_Validation_Acc(run)), "%"));
        disp(strcat("Disturbed validation accuracy: ", num2str(Inference_Table.Disturbed_Validation_Acc(run)), "%"));
        disp(strcat("NN validation accuracy loss: ", num2str(Inference_Table.NN_Validation_Acc_Loss(run)), "%"));
        disp(strcat("Undisturbed training loss: ", num2str(Inference_Table.Undisturbed_Train_Loss(run)), "%"));
        disp(strcat("Disturbed training loss: ", num2str(Inference_Table.Disturbed_Train_Loss(run)), "%"));
        disp(strcat("Undisturbed validation loss: ", num2str(Inference_Table.Undisturbed_Validation_Loss(run)), "%"));
        disp(strcat("Disturbed validation loss: ", num2str(Inference_Table.Disturbed_Validation_Loss(run)), "%"));
        disp("|======================================================================================================================|");
    end
    
    %% Figure reset
    % Fig1
    if trainOptions.Plots == "training-progress" && run ~= SessionArgs.nRuns
        close(fig1);
        [fig1, lineAccTrain, lineAccValidation, lineLossTrain, lineLossValidation] = fig1_initialize();
    end
    % Fig2
    if flags.WeightHistogramPlot == true && run ~= SessionArgs.nRuns
        close(fig2);
        [fig2, nLayers] = fig2_initialize(dlnet);
    end
    
end
%% Save Results
trainTable = table(total_TrainAcc, total_TrainLoss, 'VariableNames', {'Accuracy', 'Loss'});
validationTable = table(total_ValidationAcc, total_ValidationLoss);

varargout{1} = trainTable;
varargout{2} = validationTable;

if exist('fig1', 'var') ~= 0
    varargout{3} = fig1;
else
    varargout{3} = [];
end

if exist('fig2_struct', 'var') ~= 0
    varargout{4} = fig2_struct;
    close(fig2);
else
    varargout{4} = [];
end

if exist('fig3', 'var') ~= 0
    varargout{5} = fig3;
else
    varargout{5} = [];
end

if exist('fig4_struct', 'var') ~= 0
    varargout{6} = fig4_struct;
    close(fig4);
else
    varargout{6} = [];
end

if exist('ME') ~= 0
    varargout{7} = ME;
else
    varargout{7} = [];
end

end

%% Functions

function [fig1, lineAccTrain, lineAccValidation, lineLossTrain, lineLossValidation] = fig1_initialize()  
    fig1 = figure;
    %Acc
    subplot(2,1,1);
    lineAccTrain = animatedline('Color',[0.3010 0.7450 0.9330], 'LineStyle', '-');
    lineAccValidation = animatedline('Color', 'k', 'LineStyle', '--', 'Marker', '.');
    ylim([0 inf]);
    xlabel("Iteration");
    ylabel("Accuracy");
    grid on;

    %Loss
    subplot(2,1,2);
    lineLossTrain = animatedline('Color',[0.85 0.325 0.098], 'LineStyle', '-');
    lineLossValidation = animatedline('Color', 'k', 'LineStyle', '--', 'Marker', '.');
    ylim([0 inf]);
    xlabel("Iteration");
    ylabel("Loss");
    grid on;
end

function [fig2, nLayers] = fig2_initialize(dlnet)
    fig2 = figure;
    idx = find(dlnet.Learnables.Parameter == "Weights");
    nLayers = length(idx);
    for i = 1 : 2*nLayers
        if i <= nLayers
            subplot(2, nLayers, i);
            xlabel('Weight');
            title(strcat("Layer ", num2str(i), " Weights"));
        else
            subplot(2, nLayers, i);
            xlabel('Gradient');
            title(strcat("Layer ", num2str(i-nLayers), " Gradients"));
        end
        set(gca, 'NextPlot', 'replacechildren');
    end
    
    sgtitle("Epoch: " + "0" + ", Elapsed: " + string(duration(0,0,0)));
    
    set(fig2, 'Children', flipud(fig2.Children));
    
    clear i;
end