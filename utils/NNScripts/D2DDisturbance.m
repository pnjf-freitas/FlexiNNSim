function [layerWeights_pos, layerWeights_neg] = D2DDisturbance(layerWeights_pos, layerWeights_neg, DisturbanceMatrix, WeightConversion)

switch WeightConversion
    case "DeltaG/G"
        %r defines wether disturbance is applied summed or
        %subtracted
        r = randi([0,1], size(layerWeights_pos));
        r(r == 0) = -1;

        layerWeights_pos = layerWeights_pos .* (1 + (r .* DisturbanceMatrix));
        layerWeights_neg = layerWeights_neg .* (1 + (r .* DisturbanceMatrix));
        
        clear r;
    case "NormG"
        layerWeights_pos = layerWeights_pos .* DisturbanceMatrix;
        layerWeights_neg = layerWeights_neg .* DisturbanceMatrix;
end

end
