function [weights] = weightDisturbance_parallel(weights, DisturbanceStruct, gradients)
%UNTITLED4 Summary of this function goes here
%   For now, this functions only apply to the weights. No Bias disturbance.

%% Discretization Loop
%Loop through the layers of dlnet
temp_weights = weights.Value;
temp_gradients = gradients.Value;
parfor i = 1 : size(weights, 1)
    
    layerWeights = temp_weights{i};    
    layerGradientsSignMatrix = sign(temp_gradients{i});
    
    %% Separate Weights into positive and negative matrix
    layerWeights_pos = layerWeights;
    layerWeights_pos(layerWeights_pos < 0) = nan;
    layerWeights_neg = layerWeights;
    layerWeights_neg(layerWeights >= 0) = nan;
    
    %% Rescale Weights to range [-1,1]
    %Store Range for rescaling
    maxRange_pos = max(layerWeights_pos, [], 'all');
    minRange_pos = min(layerWeights_pos, [], 'all');
    maxRange_neg = max(layerWeights_neg, [], 'all');
    minRange_neg = min(layerWeights_neg, [], 'all');
    %Rescale to [-1,0] for neg and [0,1] for pos
    layerWeights_pos = rescale(layerWeights_pos, 0, 1);
    layerWeights_neg = rescale(layerWeights_neg, -1, 0);
    % try Rescaling from [-1, min(layerWeights_neg)] and [min(layerWeights_pos), 1]
    %layerWeights_pos = rescale(layerWeights_pos, minRange_pos, 1);
    %layerWeights_neg = rescale(layerWeights_neg, -1, maxRange_neg);
    
    %% flip negative matrix to positive values
    layerWeights_neg = -layerWeights_neg;
    
    %% Discretization
    if DisturbanceStruct.Discretization_bool == true
        switch DisturbanceStruct.ProgrammingMethod
            case "Gradient-Based"
                %Separate layerWeights_pos and layerWeights_neg into 2
                %separate matrices for each one, according to the gradient sign:
                
                %layerWeights_pos_SET
                layerWeights_pos_SET = layerWeights_pos;
                layerWeights_pos_SET(layerGradientsSignMatrix == -1 | layerGradientsSignMatrix == 0) = nan;
                layerWeights_pos_SET = interp1(sort(DisturbanceStruct.DiscretizationStruct.SETArray, 'ascend'), ...
                    DisturbanceStruct.DiscretizationStruct.SETArray, ...
                    layerWeights_pos_SET, 'nearest', 'extrap');
                
                %layerWeights_pos_RESET
                layerWeights_pos_RESET = layerWeights_pos;
                layerWeights_pos_RESET(layerGradientsSignMatrix == 0 | layerGradientsSignMatrix == 1) = nan;
                layerWeights_pos_RESET = interp1(sort(DisturbanceStruct.DiscretizationStruct.RESETArray, 'ascend'), ...
                    DisturbanceStruct.DiscretizationStruct.RESETArray, ...
                    layerWeights_pos_RESET, 'nearest', 'extrap');
                
                %layerWeights_pos_ZERO
                layerWeights_pos_ZERO = layerWeights_pos;
                layerWeights_pos_ZERO(layerGradientsSignMatrix == -1 | layerGradientsSignMatrix == 1) = nan;
                
                %layerWeights_neg_SET
                layerWeights_neg_SET = layerWeights_neg;
                layerWeights_neg_SET(layerGradientsSignMatrix == -1 | layerGradientsSignMatrix == 0) = nan;
                layerWeights_neg_SET = interp1(sort(DisturbanceStruct.DiscretizationStruct.SETArray, 'ascend'), ...
                    DisturbanceStruct.DiscretizationStruct.SETArray, ...
                    layerWeights_neg_SET, 'nearest', 'extrap');
                
                %layerWeights_neg_RESET
                layerWeights_neg_RESET = layerWeights_neg;
                layerWeights_neg_RESET(layerGradientsSignMatrix == 0 | layerGradientsSignMatrix == 1) = nan;
                layerWeights_neg_RESET = interp1(sort(DisturbanceStruct.DiscretizationStruct.RESETArray, 'ascend'), ...
                    DisturbanceStruct.DiscretizationStruct.RESETArray, ...
                    layerWeights_neg_RESET, 'nearest', 'extrap');
                
                %layerWeights_neg_ZERO
                layerWeights_neg_ZERO = layerWeights_neg;
                layerWeights_neg_ZERO(layerGradientsSignMatrix == -1 | layerGradientsSignMatrix == 1) = nan;
                
                %Join DisturbanceMatrix SET and RESET     
                layerWeights_pos_SET(isnan(layerWeights_pos_SET)) = 0;
                layerWeights_pos_SET(layerWeights_pos_SET == 0 & isnan(layerWeights_pos)) = nan;
                
                layerWeights_pos_RESET(isnan(layerWeights_pos_RESET)) = 0;
                layerWeights_pos_RESET(layerWeights_pos_RESET == 0 & isnan(layerWeights_pos)) = nan;
                
                layerWeights_pos_ZERO(isnan(layerWeights_pos_ZERO)) = 0;
                layerWeights_pos_ZERO(layerWeights_pos_ZERO == 0 & isnan(layerWeights_pos)) = nan;

                layerWeights_neg_SET(isnan(layerWeights_neg_SET)) = 0;
                layerWeights_neg_SET(layerWeights_neg_SET == 0 & isnan(layerWeights_neg)) = nan;
                
                layerWeights_neg_RESET(isnan(layerWeights_neg_RESET)) = 0;
                layerWeights_neg_RESET(layerWeights_neg_RESET == 0 & isnan(layerWeights_neg)) = nan;
                
                layerWeights_neg_ZERO(isnan(layerWeights_neg_ZERO)) = 0;
                layerWeights_neg_ZERO(layerWeights_neg_ZERO == 0 & isnan(layerWeights_neg)) = nan;

                layerWeights_pos = layerWeights_pos_SET + layerWeights_pos_RESET + layerWeights_pos_ZERO;
                layerWeights_neg = layerWeights_neg_SET + layerWeights_neg_RESET + layerWeights_neg_ZERO;
                
                %clear layerWeights_pos_SET layerWeights_pos_RESET layerWeights_neg_SET layerWeights_neg_RESET layerWeights_pos_ZERO layerWeights_neg_ZERO;  
                                
            case "Set-Only"
                layerWeights_pos = interp1(sort(DisturbanceStruct.DiscretizationStruct.SETArray, 'ascend'), ...
                    sort(DisturbanceStruct.DiscretizationStruct.SETArray, 'ascend'), ...
                    layerWeights_pos, 'nearest', 'extrap');
                
                layerWeights_neg = interp1(sort(DisturbanceStruct.DiscretizationStruct.SETArray, 'ascend'), ...
                    sort(DisturbanceStruct.DiscretizationStruct.SETArray, 'ascend'), ...
                    layerWeights_neg, 'nearest', 'extrap');
            
            case "Reset-Only"
                layerWeights_pos = interp1(sort(DisturbanceStruct.DiscretizationStruct.RESETArray, 'ascend'), ...
                    DisturbanceStruct.DiscretizationStruct.RESETArray, ...
                    layerWeights_pos, 'nearest', 'extrap');
                
                layerWeights_neg = interp1(sort(DisturbanceStruct.DiscretizationStruct.RESETArray, 'ascend'), ...
                    DisturbanceStruct.DiscretizationStruct.RESETArray, ...
                    layerWeights_neg, 'nearest', 'extrap');
            
            case "Selective"
                %layerWeights_pos_SET
                layerWeights_pos_SET = layerWeights_pos;
                layerWeights_pos_SET(layerWeights_pos_SET < 0.5) = nan;
                layerWeights_pos_SET = interp1(sort(DisturbanceStruct.DiscretizationStruct.SETArray, 'ascend'), ...
                    DisturbanceStruct.DiscretizationStruct.SETArray, ...
                    layerWeights_pos_SET, 'nearest', 'extrap');
                
                %layerWeights_pos_RESET
                layerWeights_pos_RESET = layerWeights_pos;
                layerWeights_pos_RESET(layerWeights_pos_RESET >= 0.5) = nan;
                layerWeights_pos_RESET = interp1(sort(DisturbanceStruct.DiscretizationStruct.RESETArray, 'ascend'), ...
                    DisturbanceStruct.DiscretizationStruct.RESETArray, ...
                    layerWeights_pos_RESET, 'nearest', 'extrap');
                
                %layerWeights_neg_SET
                layerWeights_neg_SET = layerWeights_neg;
                layerWeights_neg_SET(layerWeights_neg_SET < 0.5) = nan;
                layerWeights_neg_SET = interp1(sort(DisturbanceStruct.DiscretizationStruct.SETArray, 'ascend'), ...
                    DisturbanceStruct.DiscretizationStruct.SETArray, ...
                    layerWeights_neg_SET, 'nearest', 'extrap');
                
                %layerWeights_neg_RESET
                layerWeights_neg_RESET = layerWeights_neg;
                layerWeights_neg_RESET(layerWeights_neg_RESET >= 0.5) = nan;
                layerWeights_neg_RESET = interp1(sort(DisturbanceStruct.DiscretizationStruct.RESETArray, 'ascend'), ...
                    DisturbanceStruct.DiscretizationStruct.RESETArray, ...
                    layerWeights_neg_RESET, 'nearest', 'extrap');
                
                %Join DisturbanceMatrix SET and RESET     
                layerWeights_pos_SET(isnan(layerWeights_pos_SET)) = 0;
                layerWeights_pos_SET(layerWeights_pos_SET == 0 & isnan(layerWeights_pos)) = nan;
                
                layerWeights_pos_RESET(isnan(layerWeights_pos_RESET)) = 0;
                layerWeights_pos_RESET(layerWeights_pos_RESET == 0 & isnan(layerWeights_pos)) = nan;

                layerWeights_neg_SET(isnan(layerWeights_neg_SET)) = 0;
                layerWeights_neg_SET(layerWeights_neg_SET == 0 & isnan(layerWeights_neg)) = nan;
                
                layerWeights_neg_RESET(isnan(layerWeights_neg_RESET)) = 0;
                layerWeights_neg_RESET(layerWeights_neg_RESET == 0 & isnan(layerWeights_neg)) = nan;

                layerWeights_pos = layerWeights_pos_SET + layerWeights_pos_RESET;
                layerWeights_neg = layerWeights_neg_SET + layerWeights_neg_RESET;
                
                %clear layerWeights_pos_SET layerWeights_pos_RESET layerWeights_neg_SET layerWeights_neg_RESET;                
        end
    end
    
    %% D2D
    if DisturbanceStruct.D2D_bool == true
        %Programming Method does not apply to D2D since data is user-input
        %only and there is no distinction between SET and RESET
        
        [layerWeights_pos, layerWeights_neg] = D2DDisturbance(layerWeights_pos, layerWeights_neg, ...
            DisturbanceStruct.D2DStruct.DisturbanceMatrix{i}, ...
            DisturbanceStruct.D2DStruct.WeightConversion);
        
    end
    %% C2C
    if DisturbanceStruct.C2C_bool == true       
        switch DisturbanceStruct.ProgrammingMethod
            %Gradient-Based
            case "Gradient-Based"
                %Needs 2 Matrices for each seperated Matrix:
                % pos_SET
                layerWeights_pos_SET = layerWeights_pos;
                layerWeights_pos_SET(layerGradientsSignMatrix == -1 | layerGradientsSignMatrix == 0) = nan;
                
                % pos_RESET
                layerWeights_pos_RESET = layerWeights_pos;
                layerWeights_pos_RESET(layerGradientsSignMatrix == 1 | layerGradientsSignMatrix == 0) = nan;
                
                % neg_SET
                layerWeights_neg_SET = layerWeights_neg;
                layerWeights_neg_SET(layerGradientsSignMatrix == -1 | layerGradientsSignMatrix == 0) = nan;
                
                % neg_RESET
                layerWeights_neg_RESET = layerWeights_neg;
                layerWeights_neg_RESET(layerGradientsSignMatrix == 1 | layerGradientsSignMatrix == 0) = nan;
                
                
                %ParamMatrices
                ParamAMatrix_pos_SET = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{1}(extractdata(layerWeights_pos_SET)), size(layerWeights_pos_SET));
                ParamAMatrix_pos_RESET = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{2}(extractdata(layerWeights_pos_RESET)), size(layerWeights_pos_RESET));
                ParamAMatrix_neg_SET = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{1}(extractdata(layerWeights_neg_SET)), size(layerWeights_neg_SET));
                ParamAMatrix_neg_RESET = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{2}(extractdata(layerWeights_neg_RESET)), size(layerWeights_neg_RESET));
                
                if DisturbanceStruct.C2CStruct.nParams > 1
                    ParamBMatrix_pos_SET = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{1}(extractdata(layerWeights_pos_SET)), size(layerWeights_pos_SET));
                    ParamBMatrix_pos_RESET = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{2}(extractdata(layerWeights_pos_RESET)), size(layerWeights_pos_RESET));
                    ParamBMatrix_neg_SET = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{1}(extractdata(layerWeights_neg_SET)), size(layerWeights_neg_SET));
                    ParamBMatrix_neg_RESET = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{2}(extractdata(layerWeights_neg_RESET)), size(layerWeights_neg_RESET));
                    
                    DisturbanceMatrix_pos_SET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos_SET, ParamBMatrix_pos_SET);
                    DisturbanceMatrix_pos_RESET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos_RESET, ParamBMatrix_pos_RESET);
                    DisturbanceMatrix_neg_SET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg_SET, ParamBMatrix_neg_SET);
                    DisturbanceMatrix_neg_RESET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg_RESET, ParamBMatrix_neg_RESET);
                    
                    
                    %clear ParamBMatrix_pos_SET ParamBMatrix_pos_RESET ParamBMatrix_neg_SET ParamBMatrix_neg_RESET;
                
                else
                    
                    DisturbanceMatrix_pos_SET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos_SET);
                    DisturbanceMatrix_pos_RESET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos_RESET);
                    DisturbanceMatrix_neg_SET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg_SET);
                    DisturbanceMatrix_neg_RESET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg_RESET);
                    
                end               
                
                % pos_SET
                DisturbanceMatrix_pos_SET(isnan(DisturbanceMatrix_pos_SET)) = 0;
                DisturbanceMatrix_pos_SET(DisturbanceMatrix_pos_SET == 0 & isnan(layerWeights_pos)) = nan;
                
                % pos_RESET
                DisturbanceMatrix_pos_RESET(isnan(DisturbanceMatrix_pos_RESET)) = 0;
                DisturbanceMatrix_pos_RESET(DisturbanceMatrix_pos_RESET == 0 & isnan(layerWeights_pos)) = nan;
                
                % neg_SET
                DisturbanceMatrix_neg_SET(isnan(DisturbanceMatrix_neg_SET)) = 0;
                DisturbanceMatrix_neg_SET(DisturbanceMatrix_neg_SET == 0 & isnan(layerWeights_neg)) = nan;
                
                % neg_RESET
                DisturbanceMatrix_neg_RESET(isnan(DisturbanceMatrix_neg_RESET)) = 0;
                DisturbanceMatrix_neg_RESET(DisturbanceMatrix_neg_RESET == 0 & isnan(layerWeights_neg)) = nan;
                
                % Join Matrices
                DisturbanceMatrix_pos = DisturbanceMatrix_pos_SET + DisturbanceMatrix_pos_RESET;
                DisturbanceMatrix_neg = DisturbanceMatrix_neg_SET + DisturbanceMatrix_neg_RESET;
                
                % Account for Zero Gradient idxs
                switch DisturbanceStruct.C2CStruct.WeightConversion
                    case "DeltaG/G"
                        DisturbanceMatrix_pos(layerGradientsSignMatrix == 0) = 0;
                        DisturbanceMatrix_neg(layerGradientsSignMatrix == 0) = 0;
                    case "NormG"
                        DisturbanceMatrix_pos(layerGradientsSignMatrix == 0) = 1;
                        DisturbanceMatrix_neg(layerGradientsSignMatrix == 0) = 1;
                end
                
                %clear DisturbanceMatrix_pos_SET DisturbanceMatrix_pos_RESET DisturbanceMatrix_neg_SET DisturbanceMatrix_neg_RESET;
                
                [layerWeights_pos, layerWeights_neg] = C2CDisturbance(layerWeights_pos, layerWeights_neg, ...
                    DisturbanceMatrix_pos, DisturbanceMatrix_neg, ...
                    DisturbanceStruct.C2CStruct.WeightConversion);
                
                %clear DisturbanceMatrix_pos DisturbanceMatrix_neg;
                
            %Set-Only
            case "Set-Only"
                ParamAMatrix_pos = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{1}(extractdata(layerWeights_pos)), size(layerWeights_pos));
                ParamAMatrix_neg = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{1}(extractdata(layerWeights_neg)), size(layerWeights_neg));
                
                if DisturbanceStruct.C2CStruct.nParams > 1
                    ParamBMatrix_pos = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{1}(extractdata(layerWeights_pos)), size(layerWeights_pos));
                    ParamBMatrix_neg = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{1}(extractdata(layerWeights_neg)), size(layerWeights_neg));

                    DisturbanceMatrix_pos = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos, ParamBMatrix_pos);
                    DisturbanceMatrix_neg = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg, ParamBMatrix_neg);
                    
                    %clear ParamBMatrix_pos ParamBMatrix_neg;
                else
                    DisturbanceMatrix_pos = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos);
                    DisturbanceMatrix_neg = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg);
                end
                
                %clear ParamAMatrix_pos ParamAMatrix_neg;
                
                [layerWeights_pos, layerWeights_neg] = C2CDisturbance(layerWeights_pos, layerWeights_neg, ...
                    DisturbanceMatrix_pos, DisturbanceMatrix_neg, ...
                    DisturbanceStruct.C2CStruct.WeightConversion);
                
                %clear DisturbanceMatrix_pos DisturbanceMatrix_neg;
            
            %Reset-Only    
            case "Reset-Only"
                ParamAMatrix_pos = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{2}(extractdata(layerWeights_pos)), size(layerWeights_pos));
                ParamAMatrix_neg = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{2}(extractdata(layerWeights_neg)), size(layerWeights_neg));
                
                if DisturbanceStruct.C2CStruct.nParams > 1
                    ParamBMatrix_pos = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{2}(extractdata(layerWeights_pos)), size(layerWeights_pos));
                    ParamBMatrix_neg = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{2}(extractdata(layerWeights_neg)), size(layerWeights_neg));

                    DisturbanceMatrix_pos = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos, ParamBMatrix_pos);
                    DisturbanceMatrix_neg = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg, ParamBMatrix_neg);
                    
                    %clear ParamBMatrix_pos ParamBMatrix_neg;
                else
                    DisturbanceMatrix_pos = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos);
                    DisturbanceMatrix_neg = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg);
                end
                
                %clear ParamAMatrix_pos ParamAMatrix_neg;
                
                [layerWeights_pos, layerWeights_neg] = C2CDisturbance(layerWeights_pos, layerWeights_neg, ...
                    DisturbanceMatrix_pos, DisturbanceMatrix_neg, ...
                    DisturbanceStruct.C2CStruct.WeightConversion);
                
                %clear DisturbanceMatrix_pos DisturbanceMatrix_neg;
            
            %Selective    
            case "Selective"
                %Needs 2 Matrices for each seperated Matrix:
                % pos_SET
                layerWeights_pos_SET = layerWeights_pos;
                layerWeights_pos_SET(layerWeights_pos_SET < 0.5) = nan;
                
                % pos_RESET
                layerWeights_pos_RESET = layerWeights_pos;
                layerWeights_pos_RESET(layerWeights_pos_RESET >= 0.5) = nan;
                
                % neg_SET
                layerWeights_neg_SET = layerWeights_neg;
                layerWeights_neg_SET(layerWeights_neg_SET < 0.5) = nan;
                
                % neg_RESET
                layerWeights_neg_RESET = layerWeights_neg;
                layerWeights_neg_RESET(layerWeights_neg_RESET >= 0.5) = nan;
                
                %ParamMatrices
                ParamAMatrix_pos_SET = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{1}(extractdata(layerWeights_pos_SET)), size(layerWeights_pos_SET));
                ParamAMatrix_pos_RESET = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{2}(extractdata(layerWeights_pos_RESET)), size(layerWeights_pos_RESET));
                ParamAMatrix_neg_SET = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{1}(extractdata(layerWeights_neg_SET)), size(layerWeights_neg_SET));
                ParamAMatrix_neg_RESET = reshape(DisturbanceStruct.C2CStruct.ParamA.Fit{2}(extractdata(layerWeights_neg_RESET)), size(layerWeights_neg_RESET));
                
                if DisturbanceStruct.C2CStruct.nParams > 1
                    ParamBMatrix_pos_SET = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{1}(extractdata(layerWeights_pos_SET)), size(layerWeights_pos_SET));
                    ParamBMatrix_pos_RESET = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{2}(extractdata(layerWeights_pos_RESET)), size(layerWeights_pos_RESET));
                    ParamBMatrix_neg_SET = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{1}(extractdata(layerWeights_neg_SET)), size(layerWeights_neg_SET));
                    ParamBMatrix_neg_RESET = reshape(DisturbanceStruct.C2CStruct.ParamB.Fit{2}(extractdata(layerWeights_neg_RESET)), size(layerWeights_neg_RESET));
                    
                    DisturbanceMatrix_pos_SET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos_SET, ParamBMatrix_pos_SET);
                    DisturbanceMatrix_pos_RESET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos_RESET, ParamBMatrix_pos_RESET);
                    DisturbanceMatrix_neg_SET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg_SET, ParamBMatrix_neg_SET);
                    DisturbanceMatrix_neg_RESET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg_RESET, ParamBMatrix_neg_RESET);
                    
                    
                    %clear ParamBMatrix_pos_SET ParamBMatrix_pos_RESET ParamBMatrix_neg_SET ParamBMatrix_neg_RESET;
                
                else
                    
                    DisturbanceMatrix_pos_SET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos_SET);
                    DisturbanceMatrix_pos_RESET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_pos_RESET);
                    DisturbanceMatrix_neg_SET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg_SET);
                    DisturbanceMatrix_neg_RESET = random(DisturbanceStruct.C2CStruct.dist, ParamAMatrix_neg_RESET);
                    
                end
                
                %Join DisturbanceMatrix SET and RESET     
                DisturbanceMatrix_pos_SET(isnan(DisturbanceMatrix_pos_SET)) = 0;
                DisturbanceMatrix_pos_SET(DisturbanceMatrix_pos_SET == 0 & isnan(layerWeights_pos)) = nan;
                
                DisturbanceMatrix_pos_RESET(isnan(DisturbanceMatrix_pos_RESET)) = 0;
                DisturbanceMatrix_pos_RESET(DisturbanceMatrix_pos_RESET == 0 & isnan(layerWeights_pos)) = nan;

                DisturbanceMatrix_neg_SET(isnan(DisturbanceMatrix_neg_SET)) = 0;
                DisturbanceMatrix_neg_SET(DisturbanceMatrix_neg_SET == 0 & isnan(layerWeights_neg)) = nan;
                
                DisturbanceMatrix_neg_RESET(isnan(DisturbanceMatrix_neg_RESET)) = 0;
                DisturbanceMatrix_neg_RESET(DisturbanceMatrix_neg_RESET == 0 & isnan(layerWeights_neg)) = nan;

                DisturbanceMatrix_pos = DisturbanceMatrix_pos_SET + DisturbanceMatrix_pos_RESET;
                DisturbanceMatrix_neg = DisturbanceMatrix_neg_SET + DisturbanceMatrix_neg_RESET;
                
                %clear DisturbanceMatrix_pos_SET DisturbanceMatrix_pos_RESET DisturbanceMatrix_neg_SET DisturbanceMatrix_neg_RESET;
                
                [layerWeights_pos, layerWeights_neg] = C2CDisturbance(layerWeights_pos, layerWeights_neg, ...
                    DisturbanceMatrix_pos, DisturbanceMatrix_neg, ...
                    DisturbanceStruct.C2CStruct.WeightConversion);
                
                %clear DisturbanceMatrix_pos DisturbanceMatrix_neg;
        end
    end
    
    %% flip negative matrix back to negative values
    layerWeights_neg = -layerWeights_neg;
    
    %% rescale to original values
    %Fix4 - Clip any weights that go beyond -1 or 1
    layerWeights_pos = rescale(layerWeights_pos, minRange_pos, maxRange_pos, 'InputMin', 0, 'InputMax', 1);
    layerWeights_neg = rescale(layerWeights_neg, minRange_neg, maxRange_neg, 'InputMax', 0, 'InputMin', -1);
    %% Remove NaN values
    layerWeights_pos(isnan(layerWeights_pos)) = 0;
    layerWeights_neg(isnan(layerWeights_neg)) = 0;
    %% join both matrices
    layerWeights = layerWeights_pos + layerWeights_neg;
    %% Export to weights.Value
    temp_weights{i} = layerWeights;
end
weights.Value = temp_weights;
end
