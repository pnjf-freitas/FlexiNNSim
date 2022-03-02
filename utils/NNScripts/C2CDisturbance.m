function [layerWeights_pos, layerWeights_neg] = C2CDisturbance(layerWeights_pos, layerWeights_neg, ...
    DisturbanceMatrix_pos, DisturbanceMatrix_neg, WeightConversion)

switch WeightConversion
    case "DeltaG/G"
        %r defines wether disturbance is applied summed or
        %subtracted
        
        r = randi([0,1], size(layerWeights_pos));
        r(r == 0) = -1;
        %r = -1; %temp value to check what happens when SET only increases and RESET only decreases

        layerWeights_pos = layerWeights_pos .* (1 + (r .* DisturbanceMatrix_pos));
        layerWeights_neg = layerWeights_neg .* (1 + (r .* DisturbanceMatrix_neg));
        
        clear r;
    case "NormG"
        layerWeights_pos = layerWeights_pos .* DisturbanceMatrix_pos;
        layerWeights_neg = layerWeights_neg .* DisturbanceMatrix_neg;
end

end

