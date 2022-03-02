function [TargetG, PulseRefArray] = GetTargetG(RefCycle, Spacing, NPoints, Normalize_Method, LowerLimit, UpperLimit)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

for i = 1 : size(RefCycle, 2)
    tempPulseArray{1,i} = (1:size(RefCycle{1,i}, 1))';
end

switch Spacing
    case 'Linear'
        switch Normalize_Method
            case "All Cycles"
                TargetG{1,1} = linspace(LowerLimit, UpperLimit, NPoints)'; %SET
                TargetG{1,2} = linspace(UpperLimit, LowerLimit, NPoints)'; %RESET
            case "Individually"
                SET_Min = min(RefCycle{1,1}.G);
                SET_Max = max(RefCycle{1,1}.G);
                RESET_Min = min(RefCycle{1,2}.G);
                RESET_Max = max(RefCycle{1,2}.G);
                Total_Min = min([SET_Min, RESET_Min]);
                Total_Max = max([SET_Max, RESET_Max]);
                
                TargetG{1,1} = linspace(Total_Min, Total_Max, NPoints)'; %SET
                TargetG{1,2} = linspace(Total_Max, Total_Min, NPoints)'; %RESET
                
                clear SET_Min SET_Max RESET_Min RESET_Max Total_Min Total_Max;
        end
    case 'Pulse-Number'
        TargetG{1,1} = RefCycle{1,1}.G; %SET
        TargetG{1,2} = RefCycle{1,2}.G; %RESET
end

PulseRefArray = GetPulseRef(RefCycle, TargetG, Spacing);

end

function [PulseRefArray] = GetPulseRef(NormRefCycle, TargetG, Spacing);
    %Variable initialization
    PulseRefArray = cell(1, size(NormRefCycle, 2));
    
    switch Spacing
        case 'Linear'
            % !! Attention !! - This method uses the DeltaG method to
            % calculate the PulseRefArray. May or may not need two kinds of
            % implementation:
            % (1) For DeltaG
            % (2) For NormG
            % Assumption for now is that since it is only used to calculate
            % PulseRefArray, the impact may be minimal
            
            for i = 1 : size(NormRefCycle, 2)
                tempErrorArray = zeros(size(TargetG{1,i}, 1), size(NormRefCycle{1,i}, 1));
                for j = 1 : size(NormRefCycle{1,i}, 1)
                    %tempErrorArray is a M-by-N matrix with size(TargetG, NormRefCycle)
                    tempErrorArray(:,j) = abs(NormRefCycle{1,i}.G(j) - TargetG{1,i});                   
                end
                %PulseRefArray will take the idx of the minimum in the 2nd dimension
                %of tempErrorArray
                [~, PulseRefArray{1,i}] = min(tempErrorArray, [], 2);
                clear tempErrorArray;
            end
            
        case 'Pulse-Number'
            
            for i = 1 : size(NormRefCycle, 2)
                PulseRefArray{1,i} = (1 : 1 : size(NormRefCycle{1,i}, 1) )';
            end
            
    end

end