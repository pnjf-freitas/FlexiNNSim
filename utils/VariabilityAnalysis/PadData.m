function [OutputCellMatrix] = PadData(InputCellMatrix)
%PadData pads the missing values for the RRAM input data if different
%cycles have different number of data points (i.e. different number of
%pulses) (Mostly useful for Linear Response schemes with current limit)
%   The function loops through the collumns of InputCell and passes them to
%   the helper function PadCol.
%   PadCol checks if different cells in the Col have different number of
%   data points. If so, initially pads the missing values with zeros, then
%   absI and G are replaced by their max values (for SET) or min values
%   (for RESET).
%   Pulse# is adjusted to the Max Pulse Number size of the Col.
%   Normalized Pulse and Normalized Cycle are adjusted to fit into the
%   Padded table characteristics.

%% Initialize Output Matrix
OutputCellMatrix = cell(size(InputCellMatrix));


%% PadData
for i = 1 : size(InputCellMatrix,2) % loop through all cols in Cell Matrix
    OutputCellMatrix(:,i) = PadCol(InputCellMatrix(:,i));
end    

end

%% PadCol
function [OutputCol] = PadCol(InputCol)
% Function that checks if an input collumn array of cells containing a
% table each has different table heights.
% If there are different table heights, function pads the smaller cells to
% be of equal size to the largest cell, padding the G value with the
% largest G value of that cell and the V value is filled with zeros.
% Pulse parameter is also filled continuing the array pattern and
% normalized Pulse and Cycle values are adjusted to fit into the padded
% values

OutputCol = cell(size(InputCol));

% Check if different sizes in cell col exists and Padding is needed
NeedPad_bool = false;
for i = 1:size(InputCol,1) - 1 % loop through all rows except last one
    if size(InputCol{i, 1}, 1) ~= size(InputCol{i+1, 1}, 1)
        NeedPad_bool = true;
        break;
    end
end

%Padding function
if NeedPad_bool == true
    %Define temp variables
    MaxSize = size(InputCol{1,1},1);
    
    %Loop through cells to define MaxSize
    for i = 1:size(InputCol,1) - 1
        if size(InputCol{i+1, 1}, 1) > MaxSize
            MaxSize = size(InputCol{i+1, 1}, 1);
        end
    end

    %Loop through cells for padding
    for i = 1:size(InputCol,1)
        if size(InputCol{i, 1}, 1) < MaxSize
            OutputCol{i,1} = PadCell(InputCol{i,1});
        elseif size(InputCol{i,1}, 1) == MaxSize
            OutputCol{i,1} = InputCol{i,1};
        end
    end
else %No padding case
    OutputCol = InputCol;
end

    %% PadCell
    function [OutputCell] = PadCell(InputCell)
        % Padding values for I and G
        ILast = InputCell.absI(end);
        GLast = InputCell.G(end);
        NormGLast = InputCell.NormG(end);

        %Create temp zero pad table
        tempArray = zeros(MaxSize - height(InputCell), size(InputCell, 2) );
        tempTable = array2table(tempArray);
        tempVarNames = InputCell.Properties.VariableNames;
        tempTable.Properties.VariableNames = tempVarNames;

        OutputCell = [InputCell ; tempTable]; % vertical concatenation of input table with padding table

        clear tempArray tempTable tempVarNames;

        %Pulse
        [~,maxPulse_idx] = max(OutputCell.Pulse);
        OutputCell.Pulse(maxPulse_idx+1 : end) = (max(OutputCell.Pulse) + 1 : 1 : max(OutputCell.Pulse) + abs(MaxSize - maxPulse_idx))';
        %absI
        OutputCell.absI(maxPulse_idx+1 : end) = ILast;
        %G
        OutputCell.G(maxPulse_idx+1 : end) = GLast;
        %NormG
        OutputCell.NormG(maxPulse_idx+1 : end) = NormGLast;
        %Normalized Pulse
        OutputCell.NormPulse = linspace(0,1,height(OutputCell))';
        %Normalized Cycle
        OutputCell.Cycle = linspace(min(InputCell.Cycle), max(InputCell.Cycle), height(OutputCell))';

    end
end