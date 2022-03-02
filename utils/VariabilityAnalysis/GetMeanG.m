function [MeanG,GMatrixCells, NormMeanG, NormGMatrixCells, RefCycle, NormRefCycle] = GetMeanG(InputCell, method, Ref_cycle_number)
%UNTITLED3 Summary of this function goes here
%   MeanG is 1-by-2 cell with the 1st col being the meanG of all SET
%   cycles and the 2nd col being the meanG of all RESET Cycles
%
%   GMatrixCells is a 1-by-2 cell containing M-by-N Matrix with M being the Max number of pulses
%   and N the Max number of cycles, containing all G's. The 1st col of the cell is for
%   SET and 2nd col of the cell for RESET
%   
%   NormMeanG and NormGMatrixCells are similar to MeanG and
%   GMatrixCells respectively but with the NormG instead of G

MeanG = cell(1, size(InputCell, 2));
NormMeanG = cell(1, size(InputCell, 2));
    
GMatrixCells = cell(1, size(InputCell, 2));
NormGMatrixCells = cell(1, size(InputCell, 2));
for j = 1 : size(InputCell, 2)
    GMatrixCells{1,j} = zeros( size(InputCell{1,j}, 1), size(InputCell, 1) );
    NormGMatrixCells{1,j} = zeros( size(InputCell{1,j}, 1), size(InputCell,1) );
    for i = 1 : size(InputCell, 1)
        GMatrixCells{1,j}(:,i) = InputCell{i,j}.G;
        NormGMatrixCells{1,j}(:,i) = InputCell{i,j}.NormG;
    end

    MeanG{1,j} = mean(GMatrixCells{1,j}, 2);
    %NormMeanG{1,j} = mean(NormGMatrixCells{1,j}, 2);
    %Using NormMeanG as the mean of NormGMatrixCells can lead to bad
    %normalization if there are outliers in the data (e.g. spikes) going
    %outside the regular On/Off ratio of the device
    NormMeanG{1,j} = rescale(MeanG{1,j}, 0,1);
end

%% Get Ref Cycle

switch method
    case "Mean"
        for i = 1 : size(MeanG, 2)
            RefCycle{1,i} = table(InputCell{1,i}.NormPulse, MeanG{1,i}, 'VariableNames', {'NormPulse', 'G'});
        end
        for i = 1 : size(NormMeanG, 2)
            NormRefCycle{1,i} = table(InputCell{1,i}.NormPulse, NormMeanG{1,i}, 'VariableNames', {'NormPulse', 'G'});
        end
    case "From Data"
        for i = 1 : size(GMatrixCells, 2)
            RefCycle{1,i} = table(InputCell{Ref_cycle_number, i}.NormPulse, GMatrixCells{1,i}(:,Ref_cycle_number), ...
                'VariableNames', {'NormPulse', 'G'});
        end
        
        for i = 1 : size(NormGMatrixCells, 2)
            NormRefCycle{1,i} = table(InputCell{Ref_cycle_number, i}.NormPulse, NormGMatrixCells{1,i}(:,Ref_cycle_number), ...
                'VariableNames', {'NormPulse', 'G'});
        end
end

end

