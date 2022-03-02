classdef pwlLayer < nnet.layer.Layer
    % pluLayer   Piece-Wise Linear unit (pwl) layer
    %
    %   To create a piece-wise linear unit layer, use pluLayer.
    %
    %   A piecewise linear unit layer. Activation function similar to tanh
    %   but is composed of a saturated linear unit for both positive and 
    %   negative values
    %
    %   pwlLayer properties:
    %       Name                   - A name for the layer.
    %       NumInputs              - The number of inputs of the layer.
    %       InputNames             - The names of the inputs of the layer.
    %       NumOutputs             - The number of outputs of the layer.
    %       OutputNames            - The names of the outputs of the layer.
    %       alpha                  - The tilt when x<-c | x>c
    %       c                      - The constant value at which the linear
    %                                segment saturates
    %
    %   Example:
    %       Create a pwl layer.
    %
    %       layer = pwlLayer()
    
    properties
        % (Optional) Layer properties.

        % Layer properties go here.
        alpha
        c
    end

    properties (Learnable)
        % (Optional) Layer learnable parameters.

        % Layer learnable parameters go here.
    end
    
    methods
        function layer = pwlLayer(alpha, c, name)
            layer.Name = name;
            layer.Description = strcat('Piece-Wise Linear unit with alpha = ', num2str(alpha), ' and c = ', num2str(c));
            layer.Type = 'PWL';
            layer.alpha = alpha;
            layer.c = c;
        end
        
        function Z = predict(layer, X)
            % Forward input data through the layer at prediction time and
            % output the result
            
            Z = max( layer.alpha.*(X+ layer.c) - layer.c, min( layer.alpha .* (X - layer.c)+ layer.c, X));
        end        

        function dLdX = backward(layer, X, ~, dLdZ, ~)
            % Backward propagate the derivative of the loss function through 
            % the layer
            
            dLdX = dLdZ;
            dLdX(X<-layer.c | X>layer.c) = layer.alpha .* dLdZ(X<-layer.c | X>layer.c);
        end
    end
        
end
