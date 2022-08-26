function [] = dlnetTrain_Total(dlnet, InputDatabase, trainOptions, SessionArgs)
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

flags.GradCAM = true;

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
    [fig1, lineAccTrain, lineAccValidation, lineLossTrain, lineLossValidation] = TrainProgress_fig_initialize();
end

%% Weight Histograms
if flags.WeightHistogramPlot == true
    [fig2, nLayers] = WeightHistogram_fig_initialize(dlnet);
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
if flags.GradCAM == true
    [fig3, fig4, Digit_idx] = GradCAM_Initialization(dlXTest, dlYTest, classes);
end
%% Variable Initialization

dlnet_0 = dlnet;

if strcmp(trainOptions.Shuffle, 'once')
    shuffle(mbq);
end

if SessionArgs.Training.bool == true
    % Table containing the data for training (each row is the run #)
    Train_Table = table('Size', [SessionArgs.nRuns, 8], ...
        'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
        'VariableNames', {'Train_Acc_End', 'Train_Loss_End', 'Validation_Acc_End', 'Validation_Loss_End', ...
        'Train_Acc_Max', 'Train_Loss_Min', 'Validation_Acc_Max', 'Validation_Loss_Min'});
else
    % Table containing the data for inference (each row is the run #)
    Inference_Table = table('Size', [SessionArgs.nRuns, 10], ...
        'VariableTypes', {'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
        'VariableNames', {'Undisturbed_Train_Acc', 'Disturbed_Train_Acc', 'Undisturbed_Train_Loss', 'Disturbed_Train_Loss', ...
        'Undisturbed_Validation_Acc', 'Disturbed_Validation_Acc', 'Undisturbed_Validation_Loss', 'Disturbed_Validation_Loss', ...
        'NN_Train_Acc_Loss', 'NN_Validation_Acc_Loss'});
end
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
            
            %% Weight disturbance @ each iteration (Training only)
            if flags.WeightDisturbance == true && SessionArgs.Training.bool == true

                % This condition exists only because of the gradient-based
                % programming method for the first iteration
                if iteration == 1
                    gradients = dlfeval(@modelGradients,dlnet,dlX,dlY, classes);
                end

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

            %% Evaluate the model gradients, state, and loss using dlfeval and the
            % modelGradients function and update the network state.
            try
                [gradients,dlnet.State,lossTrain,accuracyTrain] = dlfeval(@modelGradients,dlnet,dlX,dlY, classes);
            catch ME
                break;
            end
            %dlnet.State = state;

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
                TrainProgress_fig_update(fig1, start, trainOptions.ValidationFrequency, false, ...
                    lineAccTrain, accuracyTrain, lineAccValidation, accuracyValidation, ...
                    lineLossTrain, lossTrain, lineLossValidation, lossValidation,iteration, epoch);
                %{
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
                %}
            end

            %% Display gradient histogram
            if flags.WeightHistogramPlot == true && (mod(iteration, trainOptions.ValidationFrequency) == 0 || iteration == 1)
                if flags.SaveWeightsGradients == true && iteration > 1
                    fig2_struct = WeightHistogram_fig_update(fig2, idx, nLayers, dlnet.Learnables, gradients, ...
                        j, epoch, start, true, fig2_struct);
                elseif flags.SaveWeightsGradients == true && iteration == 1
                    fig2_struct = WeightHistogram_fig_update(fig2, idx, nLayers, dlnet.Learnables, gradients, ...
                        j, epoch, start, true);
                elseif flags.SaveWeightsGradients == false && iteration > 1
                    fig2_struct = WeightHistogram_fig_update(fig2, idx, nLayers, dlnet.Learnables, gradients, ...
                        j, epoch, start, false, fig2_struct);
                elseif flags.SaveWeightsGradients == false && iteration == 1
                    fig2_struct = WeightHistogram_fig_update(fig2, idx, nLayers, dlnet.Learnables, gradients, ...
                        j, epoch, start, false);    
                end
                %{
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
                %}
            end

            %% Display GradCAM
            if flags.GradCAM == true
                if iteration == 1
                    [fig4, fig4_struct, k] = GradCAM_Update(dlnet, dlXTest, dlYTest, Digit_idx, classes, fig4, epoch, start);
                elseif mod(iteration, trainOptions.ValidationFrequency) == 0
                    [fig4, fig4_struct, k] = GradCAM_Update(dlnet, dlXTest, dlYTest, Digit_idx, classes, fig4, epoch, start, fig4_struct, k);
                    %{
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
                    %}
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

    %% Weight disturbance after training is complete (Inference only)

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
    
    
        %% Re-evaluate NN accuracy
        % Evaluate the model gradients, state, and loss using dlfeval and the
        % modelGradients function and update the network state.
        try
            [gradients,dlnet.State,lossTrain,accuracyTrain] = dlfeval(@modelGradients,dlnet,dlX,dlY, classes);
        catch ME
            break;
        end
        %dlnet.State = state;

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
            disp(strcat("Inference Run ", num2str(run), "/", num2str(SessionArgs.nRuns), " completed."));
            disp(strcat("Undisturbed training accuracy: ", num2str(Inference_Table.Undisturbed_Train_Acc(run)), "%"));
            disp(strcat("Disturbed training accuracy: ", num2str(Inference_Table.Disturbed_Train_Acc(run)), "%"));
            disp(strcat("NN training accuracy loss: ", num2str(Inference_Table.NN_Train_Acc_Loss(run)), "%"));
            disp(strcat("Undisturbed validation accuracy: ", num2str(Inference_Table.Undisturbed_Validation_Acc(run)), "%"));
            disp(strcat("Disturbed validation accuracy: ", num2str(Inference_Table.Disturbed_Validation_Acc(run)), "%"));
            disp(strcat("NN validation accuracy loss: ", num2str(Inference_Table.NN_Validation_Acc_Loss(run)), "%"));
            disp(strcat("Undisturbed training loss: ", num2str(Inference_Table.Undisturbed_Train_Loss(run))));
            disp(strcat("Disturbed training loss: ", num2str(Inference_Table.Disturbed_Train_Loss(run))));
            disp(strcat("Undisturbed validation loss: ", num2str(Inference_Table.Undisturbed_Validation_Loss(run))));
            disp(strcat("Disturbed validation loss: ", num2str(Inference_Table.Disturbed_Validation_Loss(run))));
            disp("|======================================================================================================================|");
        end

        %% Figure Updates
        % Training Progress
        if trainOptions.Plots == "training-progress"
            TrainProgress_fig_update(fig1, start, trainOptions.ValidationFrequency, false, ...
                lineAccTrain, accuracyTrain, lineAccValidation, accuracyValidation, ...
                lineLossTrain, lossTrain, lineLossValidation, lossValidation,iteration, epoch);
        end

        % Weight & Gradient Histograms
        if flags.SaveWeightsGradients == true && iteration > 1
            fig2_struct = WeightHistogram_fig_update(fig2, idx, nLayers, dlnet.Learnables, gradients, ...
                j, epoch, start, true, fig2_struct);
        elseif flags.SaveWeightsGradients == true && iteration == 1
            fig2_struct = WeightHistogram_fig_update(fig2, idx, nLayers, dlnet.Learnables, gradients, ...
                j, epoch, start, true);
        elseif flags.SaveWeightsGradients == false && iteration > 1
            fig2_struct = WeightHistogram_fig_update(fig2, idx, nLayers, dlnet.Learnables, gradients, ...
                j, epoch, start, false, fig2_struct);
        elseif flags.SaveWeightsGradients == false && iteration == 1
            fig2_struct = WeightHistogram_fig_update(fig2, idx, nLayers, dlnet.Learnables, gradients, ...
                j, epoch, start, false);    
        end

        %GradCAM
        if flags.GradCAM == true
            [fig4, fig4_struct, ~] = GradCAM_Update(dlnet, dlXTest, dlYTest, Digit_idx, classes, fig4, epoch, start, fig4_struct, k);
        end
        
    else % Training (Not inference)
        %% Build table containing data when training w/ disturbance
        Train_Table.Train_Acc_End(run) = total_TrainAcc(end);
        Train_Table.Train_Loss_End(run) = total_TrainLoss(end);
        Train_Table.Validation_Acc_End(run) = total_ValidationAcc(end);
        Train_Table.Validation_Loss_End(run) = total_ValidationLoss(end);
        
        Train_Table.Train_Acc_Max(run) = max(total_TrainAcc);
        Train_Table.Train_Loss_Min(run) = min(total_TrainLoss);
        Train_Table.Validation_Acc_Max(run) = max(total_ValidationAcc);
        Train_Table.Validation_Loss_Min(run) = min(total_ValidationLoss);
        
        %% Verbosity
        if trainOptions.Verbose
            disp("|======================================================================================================================|");
            disp(strcat("Training Run ", num2str(run), "/", num2str(SessionArgs.nRuns), " completed."));
            disp(strcat("End training accuracy: ", num2str(Train_Table.Train_Acc_End(run)), "%"));
            disp(strcat("End training loss: ", num2str(Train_Table.Train_Loss_End(run))));
            disp(strcat("Max training accuracy: ", num2str(Train_Table.Train_Acc_Max(run)), "%"));
            disp(strcat("Min training loss: ", num2str(Train_Table.Train_Loss_Min(run))));
            disp(strcat("End validation accuracy: ", num2str(Train_Table.Validation_Acc_End(run)), "%"));
            disp(strcat("End validation loss: ", num2str(Train_Table.Validation_Loss_End(run))));
            disp(strcat("Max validation accuracy: ", num2str(Train_Table.Validation_Acc_Max(run)), "%"));
            disp(strcat("Min validation loss: ", num2str(Train_Table.Validation_Loss_Min(run))));
            disp("|======================================================================================================================|");
        end
    end
    %% Save figs and data @ each run
    
    SavePath = fullfile('SavedSessions', SessionArgs.Name, strcat('Run_', num2str(run)));
    
    if exist(SavePath, 'dir') == 0
        mkdir(SavePath);
    end
    
    trainTable = table(total_TrainAcc, total_TrainLoss, 'VariableNames', {'Accuracy', 'Loss'});
    validationTable = table(total_ValidationAcc, total_ValidationLoss);
    layers = dlnet.Layers;
    
    % Save Tables related to the training
    save(fullfile(SavePath, 'trainTable.mat'), 'trainTable');
    save(fullfile(SavePath, 'validationTable.mat'), 'validationTable');
    writetable(trainTable, fullfile(SavePath, 'trainTable.csv'));
    writetable(validationTable, fullfile(SavePath, 'validationTable.csv'));
    
    % Save other details
    save(fullfile(SavePath, 'trainOptions.mat'), 'trainOptions');
    save(fullfile(SavePath, 'layers.mat'), 'layers');
    
    % Save Training progress figure (fig1)
    if trainOptions.Plots == "training-progress"
        savefig(fig1, fullfile(SavePath, 'TrainFig.fig'));
        exportgraphics(fig1, fullfile(SavePath, 'TrainFig.jpg'));
    end
    
    % Save Weight Histogram figure (fig2)
    if flags.WeightHistogramPlot == true
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
            
            if SessionArgs.Training.bool == false && j == length(fig2_struct.frame) - 1
                imwrite(imind, cm, fullfile(SavePath, 'weight_gradient_Undisturbed.png'));
            elseif SessionArgs.Training.bool == false && j == length(fig2_struct.frame)
                imwrite(imind, cm, fullfile(SavePath, 'weight_gradient_Disturbed.png'));
            end
        end
        
        save(fullfile(SavePath, 'fig2_frame.mat'), '-struct', 'fig2_struct', 'frame'); % Save Weight Histograms gif (frame) data
        if flags.SaveWeightsGradients == true % Save All Weight and Gradient values in a file
            save(fullfile(SavePath, 'Weight_Gradient_Data.mat'), '-struct', 'fig2_struct', 'Data');
        end
    end
    
    % Save GradCAM   
    if flags.GradCAM == true
        % fig3
        savefig(fig3, fullfile(SavePath, 'TestImages.fig'));
        exportgraphics(fig3, fullfile(SavePath, 'TestImages.jpg'));
        
        % fig4
        if isempty(fig4_struct) == false
            for j = 1 : length(fig4_struct.frame)
                im = frame2im(fig4_struct.frame(j));
                [imind, cm] = rgb2ind(im,256);

                if j == 1
                    imwrite(imind, cm, fullfile(SavePath, 'gradCAM.gif'), 'gif', 'Loopcount', inf);
                else
                    imwrite(imind, cm, fullfile(SavePath, 'gradCAM.gif'), 'gif', 'WriteMode', 'append');
                end
                
                if SessionArgs.Training.bool == false && j == length(fig4_struct.frame) - 1
                    imwrite(imind, cm, fullfile(SavePath, 'gradCAM_Undisturbed.png'));
                elseif SessionArgs.Training.bool == false && j == length(fig4_struct.frame)
                    imwrite(imind, cm, fullfile(SavePath, 'gradCAM_Disturbed.png'));
                end
                
            end

            save(fullfile(SavePath, 'fig4_frame.mat'), '-struct', 'fig4_struct', 'frame');
            save(fullfile(SavePath, 'fig4_scoreMap.mat'), '-struct', 'fig4_struct', 'scoreMap');
        end
    end
    
    clear trainTable validationTable layers im imind cm SavePath;
    
    %% Figure reset
    
    if run ~= SessionArgs.nRuns
        % Fig1
        if trainOptions.Plots == "training-progress"
            close(fig1);
            [fig1, lineAccTrain, lineAccValidation, lineLossTrain, lineLossValidation] = TrainProgress_fig_initialize();
        end
        % Fig2
        if flags.WeightHistogramPlot == true
            close(fig2);
            [fig2, nLayers] = WeightHistogram_fig_initialize(dlnet);
        end
        % Fig3 & Fig4 (GradCAM)
        if flags.GradCAM == true
            close([fig3, fig4]);
            [fig3, fig4, Digit_idx] = GradCAM_Initialization(dlXTest, dlYTest, classes);
        end
    end
end

%% Figures to plot @ end of all runs
if SessionArgs.nRuns > 1 && SessionArgs.Training.bool == false %Figures for inference w/ disturbance
    
    % NN accuracy loss per run
    fig5 = figure;
    plot([1 : SessionArgs.nRuns], Inference_Table.NN_Train_Acc_Loss, '-sb');
    hold on;
    plot([1 : SessionArgs.nRuns], Inference_Table.NN_Validation_Acc_Loss, '-or');
    xlabel('NN Training Run');
    ylabel('NN Accuracy Loss (%)');

    legend('Training Data', 'Validation Data');

    % Boxplot of NN accuracy loss
    fig6 = figure;
    boxplot([Inference_Table.NN_Train_Acc_Loss, Inference_Table.NN_Validation_Acc_Loss], ["Training Data", "Validation Data"]);
    ylabel('NN Accuracy Loss (%)');
    
    % NN accuracy per run
    fig7 = figure;
    plot([1 : SessionArgs.nRuns], Inference_Table.Undisturbed_Train_Acc, '-sb');
    hold on;
    plot([1 : SessionArgs.nRuns], Inference_Table.Disturbed_Train_Acc, '-or');
    plot([1 : SessionArgs.nRuns], Inference_Table.Undisturbed_Validation_Acc, '-^', 'Color', '#4DBEEE');
    plot([1 : SessionArgs.nRuns], Inference_Table.Disturbed_Validation_Acc, '-v', 'Color', '#D95319');
    xlabel('NN Training Run');
    ylabel('Accuracy (%)');
    
    legend('Undisturbed Training Accuracy', 'Disturbed Training Accuracy', 'Undisturbed Validation Accuracy', 'Disturbed Validation Accuracy');
    
    % NN Loss per run
    fig8 = figure;
    plot([1 : SessionArgs.nRuns], Inference_Table.Undisturbed_Train_Loss, '-sb');
    hold on;
    plot([1 : SessionArgs.nRuns], Inference_Table.Disturbed_Train_Loss, '-or');
    plot([1 : SessionArgs.nRuns], Inference_Table.Undisturbed_Validation_Loss, '-^', 'Color', '#4DBEEE');
    plot([1 : SessionArgs.nRuns], Inference_Table.Disturbed_Validation_Loss, '-v', 'Color', '#D95319');
    xlabel('NN Training Run');
    ylabel('Loss');
    
    legend('Undisturbed Training Loss', 'Disturbed Training Loss', 'Undisturbed Validation Loss', 'Disturbed Validation Loss');
    
    % NN Accuracy and loss boxplots
    fig9 = figure;
    
    % Accuracy Boxplots
    subplot(1,2,1);
    boxplot([Inference_Table.Undisturbed_Train_Acc, Inference_Table.Disturbed_Train_Acc, ...
        Inference_Table.Undisturbed_Validation_Acc, Inference_Table.Disturbed_Validation_Acc], ...
        ["Undisturbed Training Data", "Disturbed Training Data", "Undisturbed Validation Data", "Disturbed Validation Data"]);
    ylabel('Accuracy (%)');
    
    % Loss Boxplots
    subplot(1,2,2);
    boxplot([Inference_Table.Undisturbed_Train_Loss, Inference_Table.Disturbed_Train_Loss, ...
        Inference_Table.Undisturbed_Validation_Loss, Inference_Table.Disturbed_Validation_Loss], ...
        ["Undisturbed Training Data", "Disturbed Training Data", "Undisturbed Validation Data", "Disturbed Validation Data"]);
    ylabel('Loss'); 
    
elseif SessionArgs.nRuns > 1 && SessionArgs.Training.bool == true % Figures for training w/ disturbance
    
    % NN accuracy per run
    fig5 = figure;
    plot([1 : SessionArgs.nRuns], Train_Table.Train_Acc_End, '-sb');
    hold on;
    plot([1 : SessionArgs.nRuns], Train_Table.Validation_Acc_End, '-or');
    plot([1 : SessionArgs.nRuns], Train_Table.Train_Acc_Max, '-^', 'Color', '#4DBEEE');
    plot([1 : SessionArgs.nRuns], Train_Table.Validation_Acc_Max, '-v', 'Color', '#D95319');
    xlabel('NN Training Run');
    ylabel('Accuracy (%)');
    
    legend('End Training Accuracy', 'End Validation Accuracy', 'Max Training Accuracy', 'End Validation Accuracy');
    
    % NN Loss per run
    fig6 = figure;
    plot([1 : SessionArgs.nRuns], Train_Table.Train_Loss_End, '-sb');
    hold on;
    plot([1 : SessionArgs.nRuns], Train_Table.Validation_Loss_End, '-or');
    plot([1 : SessionArgs.nRuns], Train_Table.Train_Loss_Min, '-^', 'Color', '#4DBEEE');
    plot([1 : SessionArgs.nRuns], Train_Table.Validation_Loss_Min, '-v', 'Color', '#D95319');
    xlabel('NN Training Run');
    ylabel('Loss');
    
    legend('End Training Loss', 'End Validation Loss', 'Min Train Loss', 'Min Validation Loss');
    
    % NN accuracy and loss boxplots
    fig7 = figure;
    
    % Accuracy Boxplots
    subplot(1,2,1);
    boxplot([Train_Table.Train_Acc_End, Train_Table.Validation_Acc_End, ...
        Train_Table.Train_Acc_Max, Train_Table.Validation_Acc_Max], ...
        ["End Training Accuracy", "End Validation Accuracy", "Max Training Accuracy", "Max Validation Accuracy"]);
    ylabel('Accuracy (%)');
    
    % Loss Boxplots
    subplot(1,2,2);
    boxplot([Train_Table.Train_Loss_End, Train_Table.Validation_Loss_End, ...
        Train_Table.Train_Loss_Min, Train_Table.Validation_Loss_Min], ...
        ["End Training Loss", "End Validation Loss", "Min Training Loss", "Min Validation Loss"]);
    ylabel('Loss');
    
end
%% Save Results @ end of all runs
% Define SavePath
    SavePath = fullfile('SavedSessions', SessionArgs.Name, 'All_Run_Summary');

    if exist(SavePath, 'dir') == 0
        mkdir(SavePath);
    end

    if SessionArgs.Training.bool == false
        % Inference Table
        save(fullfile(SavePath, 'Inference_Table.mat'), 'Inference_Table');
        if SessionArgs.nRuns > 1
            % Save NN accuracy loss per run fig
            savefig(fig5, fullfile(SavePath, 'Inference_AccLoss_per_run.fig'));
            exportgraphics(fig5, fullfile(SavePath, 'Inference_AccLoss_per_run.jpg'));

            % Save NN accuracy loss boxplot
            savefig(fig6, fullfile(SavePath, 'Inference_AccLoss_Boxplot.fig'));
            exportgraphics(fig6, fullfile(SavePath, 'Inference_AccLoss_Boxplot.jpg'));
            
            % Save NN accuracy per run fig
            savefig(fig7, fullfile(SavePath, 'Inference_Acc_per_run.fig'));
            exportgraphics(fig7, fullfile(SavePath, 'Inference_Acc_per_run.jpg'));
            
            % Save NN Loss per run fig
            savefig(fig8, fullfile(SavePath, 'Inference_Loss_per_run.fig'));
            exportgraphics(fig8, fullfile(SavePath, 'Inference_Loss_per_run.jpg'));
            
            % Save Acc & Loss Boxplots fig
            savefig(fig9, fullfile(SavePath, 'Inference_Acc_and_Loss_Boxplots.fig'));
            exportgraphics(fig9, fullfile(SavePath, 'Inference_Acc_and_Loss_Boxplots.jpg'));
        end
    else
        save(fullfile(SavePath, 'Train_Table.mat'), 'Train_Table');
        if SessionArgs.nRuns > 1
            % Save NN accuracy per run fig
            savefig(fig5, fullfile(SavePath, 'Train_Acc_per_run.fig'));
            exportgraphics(fig5, fullfile(SavePath, 'Train_Acc_per_run.jpg'));

            % Save NN loss per run fig
            savefig(fig6, fullfile(SavePath, 'Train_Loss_per_run.fig'));
            exportgraphics(fig6, fullfile(SavePath, 'Train_Loss_per_run.jpg'));
            
            % Save Acc & Loss Boxplots fig
            savefig(fig7, fullfile(SavePath, 'Train_Acc_and_Loss_Boxplots.fig'));
            exportgraphics(fig7, fullfile(SavePath, 'Train_Acc_and_Loss_Boxplots.jpg'));
        end
    end
    
%{
%trainTable = table(total_TrainAcc, total_TrainLoss, 'VariableNames', {'Accuracy', 'Loss'});
%validationTable = table(total_ValidationAcc, total_ValidationLoss);

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
%}
end