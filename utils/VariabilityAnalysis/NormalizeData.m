function [Output_DataCells, RawData, LowerRefValue, UpperRefValue] = NormalizeData(RawData, DataCells, method, UpperRefLimit, LowerRefLimit)
%NormalizeData accepts PaddedDataCells and outputs a M-by-N Matrix of Normalized Conductance values according to the method 
%   M is max number of pulses
%   N is number of cycles
%   'Individually' method Normalizes the data according to each specific
%   cycle. (Every cycle will be normalized from 0 to 1)
%   'All Cycles' method takes into account all of the data cycles and
%   normalizes the data according to the set Normalization Upper and Lower
%   Ref Limits

switch method
    case 'Individually'
        % Work on DataCells
        Output_DataCells = DataCells;
        for j = 1 : size(DataCells, 2) % Cycle cols
            for i = 1 : size(DataCells, 1) % Cycle rows
                Output_DataCells{i,j}.NormG = rescale(DataCells{i,j}.G, 0,1);
            end
        end
        
    case 'All Cycles'
        % Work on RawData, based on Upper and Lower Ref Limits
        
        %Variable Initialization
        tempUpperRefValue = zeros(size(DataCells, 2),1);
        tempLowerRefValue = zeros(size(DataCells, 2),1);
        %Ref Arrays - These arrays store the max/min values of each cycle
        UpperRefArray = zeros(size(DataCells, 1), 1);
        LowerRefArray = zeros(size(DataCells, 1), 1);
        
        for i = 1 : size(DataCells, 1) % Cycle rows
            for j = 1 :size(DataCells, 2) % Cycle cols
                %This cycle stores the max of SET and RESET for each row
                tempUpperRefValue(j) = max(DataCells{i,j}.G);
                tempLowerRefValue(j) = min(DataCells{i,j}.G);
            end
            % This cycle decides for each row (Cycle), whether the max and
            % min belongs to SET or RESET
            UpperRefArray(i,1) = max(tempUpperRefValue);
            LowerRefArray(i,1) = min(tempLowerRefValue);
        end
        
        %These switches will decide based on the user-input whether the
        %Upper and Lower Ref Limits are the max, mean, or min of Upper and
        %Lower Ref Arrays
        switch UpperRefLimit
            case 'Max'
                UpperRefValue = max(UpperRefArray);
            case 'Mean'
                UpperRefValue = mean(UpperRefArray);
            case 'Median'
                UpperRefValue = median(UpperRefArray);
            case 'Min'
                UpperRefValue = min(UpperRefArray);
        end        
        switch LowerRefLimit
            case 'Max'
                LowerRefValue = max(LowerRefArray);
            case 'Mean'
                LowerRefValue = mean(LowerRefArray);
            case 'Median'
                LowerRefValue = median(LowerRefArray);
            case 'Min'
                LowerRefValue = min(LowerRefArray);
        end
        
        %% Continue here
        % Need to do the NormG of Raw Data and re-Pad the data
        
        % Solution(1): Cap anything above/below Upper/Lower Ref Values and
        % rescale; Drawback: unrealistic for lower limit if lower limit is
        % not Min. Besides, the statistical distributions will have
        % distorted tail ends
        
        %Solution(1) not implemented. Code may be revised in this section
        %if that solution is ever to be implemented
        
        % Solution(2): Come up with a new rescaling method, to rescale
        % beyond [0,1].
        
        RawData.NormG = (RawData.G - LowerRefValue) / (UpperRefValue - LowerRefValue);
        
        %% Reformat into DataCells
        
        Output_DataCells = RawData_to_Cells(RawData);
end

end

