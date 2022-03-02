function [Residuals] = CalcResiduals(GMatrix, TargetG, PulseRefArray, WeightConv_method, Write_Verify_bool, nonzero_bool)
%UNTITLED Summary of this function goes here
%   NormGMatrix is a 2 col cell containing a M-by-N matrix, where M is max
%   number of pulses and N is the number of cycles. Col 1 of the cell is
%   for SET and Col 2 is for RESET
%
%   TargetG and PulseRefArray are calculated in the previous function according to the spacing
%   method: (Linear or by Pulse Number)
%   TargetG should be a 2 col cell containing a col array each: col 1 for
%   SET and col 2 for RESET. If spacing is by Pulse Number, TargetG will be
%   a col array containing the values from the ref cycle. If spacing is
%   linear it should be an array of linspace(0,1,NPoints).
%   
%   PulseRefArray is a 2 col cell for SET and RESET respectivelly
%   containing the idx of the min error between TargetG and refCycle

%% Initialize variables
Residuals = cell(1,size(GMatrix, 2));
GMatrix_by_pulseRef = cell(1,size(GMatrix, 2));

%%
for i = 1 : size(GMatrix, 2)
    if Write_Verify_bool == true
        % In this case, the residuals will always be taken from the closest
        % value to TargetG without regard to the Ref Pulse Number       
        for j = 1 : size(GMatrix{1,i}, 2)           
            tempErrorMatrix = zeros(size(TargetG{1,i}, 1), size(GMatrix, 1));
            
                for k = 1 : size(GMatrix{1,i}, 1)
                    %tempErrorMatrix is a M-by-N matrix with size(TargetG, RefCycle)
                    switch WeightConv_method
                        case "NormG"
                            tempErrorMatrix(:,k) = GMatrix{1,i}(k,j) ./ TargetG{1,i};                   
                        case "DeltaG/G"
                            tempErrorMatrix(:,k) = abs( (GMatrix{1,i}(k,j) - TargetG{1,i}) ./ TargetG{1,i} );
                    end
                end
                
                switch WeightConv_method
                    case "NormG"
                        Residuals{1,i}(:,j) = Close_to_1(tempErrorMatrix);
                    case "DeltaG/G"
                        %Values can be zero! (whilst being unlikely)
                        %This needs a solution: For now, solution is
                        %when using a distribution that cannot take
                        %values = 0 (i.e. lognormal or weibull),
                        %convert values = 0 to extremely low value (i.e. 2 orders below min nonzero value)
                        %
                        %nonzero_bool is true when distribution cannot take
                        %zero values
                        
                        %Convert zero values
                        if nonzero_bool == 1
                            tempMin = min(tempErrorMatrix(tempErrorMatrix > 0));
                            tempLowestValue = tempMin * 1e-2;
                            tempErrorMatrix(tempErrorMatrix == 0) = tempLowestValue;
                            clear tempMin tempLowestValue;
                        end
                        
                        Residuals{1,i}(:,j) = min(tempErrorMatrix, [], 2);
                end
                clear tempErrorArray;
        end
    else
        % In this case, the residuals are always taken with respect to the Ref
        % Pulse Number
        
        %GMatrix_by_pulseRef is the GMatrix when all of the values are
        %taken according to the pulse numbers in PulseRefArray
        GMatrix_by_pulseRef{1,i} = GMatrix{1,i}(PulseRefArray{1,i}, :);
        
        switch WeightConv_method
            case "NormG"
                Residuals{1,i} = GMatrix_by_pulseRef{1,i} ./ TargetG{1,i};

            case "DeltaG/G"
                Residuals{1,i} = abs( (GMatrix_by_pulseRef{1,i} - TargetG{1,i}) ./ TargetG{1,i} );
                %Convert zero values
                if nonzero_bool == 1
                    tempMin = min(Residuals{1,i}(Residuals{1,i} > 0), [], 'all');
                    tempLowestValue = tempMin * 1e-2;
                    Residuals{1,i}(Residuals{1,i} <= 0) = tempLowestValue;
                    clear tempMin tempLowestValue;
                end
        end
    end
end
end

function [output_col] = Close_to_1(input_matrix)

%Variable initialization
output_col = zeros(size(input_matrix, 1), 1);

for i = 1 : size(input_matrix, 1)
    input_col = input_matrix(i,:)';          %input_col is the ith row of input_matrix
    [~, temp_idx] = min(abs(input_col - 1)); %Get the idx of input_col value closest to 1
    output_col(i,1) = input_col(temp_idx);   %Store value closest to 1 from input_col into output_col
end

end
