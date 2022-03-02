function [OutputCell] = RawData_to_Cells(InputTable)
%RawData_to_Cells Converts the input data to be used in PedroSim app from
%3 Col Table into a Matrix of cells separated by cycles
%   Each Cell in the Matrix will contain all of the data relating to Pulse
%   Voltage and Conductance.
%   Col 1 are the SET Cycles, Col 2 are the Reset Cycles.
%   Each Row refers to 1 cycle

%%
%PadData_bool = true;

StartSign = sign(InputTable.V(1));

j = 1; % Counter for Cycle number starting at 1
Cycle = j - 1; % Counter for Cycle number starting at 0

checkpoint = 1;
%%
for i = 2 : height(InputTable)
    if sign(InputTable.V(i)) ~= sign(InputTable.V(i-1)) % Switch from SET to RESET or vice versa
        
        if sign(InputTable.V(i-1)) == StartSign
            k = 1;
        else
            k = 2;
        end
        
        %% Separates Data from Input Table into the Cell slot each time V sign changes
        % For the very first case (j == 1 & k == 1) gets the data from
        % checkpoint to i-1.
        % For every other case, get the data from checkpoint-1 to i-1.
        % This condition makes so that the first point of each cell is
        % replicated from the last point of the previous cell.
        % The first value of each cell is = Pulse0
        if j == 1 && k == 1
            OutputCell{j, k} = InputTable(checkpoint:i-1 , :); 
        else
            OutputCell{j, k} = InputTable(checkpoint-1:i-1, :);
        end
        %%
        
        %NormPulse
        OutputCell{j,k}.NormPulse = linspace(0, 1, height(OutputCell{j,k}))'; % Creates new collumn with the Normalized Pulse # for that SET/RESET cycle     
        
        if k == 2
            %
            TotalCycle = linspace(Cycle, Cycle + 1, height(OutputCell{j,1}) + height(OutputCell{j,2}))'; %temp var for Cycle definition
            
            OutputCell{j,1}.Cycle = TotalCycle(1:height(OutputCell{j,1})); % Define Cycle array for SET cycle
            OutputCell{j,2}.Cycle = TotalCycle(height(OutputCell{j,1}) + 1 : end); % Define Cycle array for RESET cycle
            
            %
            j = j + 1;
            Cycle = j - 1;
        end       
        checkpoint = i;
        
    elseif i == height(InputTable) % Last Row
        
        if sign(InputTable.V(i-1)) == StartSign
            k = 1;
        else
            k = 2;
        end
        
        OutputCell{j,k} = InputTable(checkpoint-1:i, :);
        
        %NormPulse
        OutputCell{j,k}.NormPulse = linspace(0, 1, height(OutputCell{j,k}))';
        
        if k == 2
            TotalCycle = linspace(Cycle, Cycle + 1, height(OutputCell{j,1}) + height(OutputCell{j,2}))';
            %Cycle
            OutputCell{j,1}.Cycle = TotalCycle(1:height(OutputCell{j,1}));
            OutputCell{j,2}.Cycle = TotalCycle(height(OutputCell{j,1}) + 1 : end);
            
        end    
    end
end

clear i j k Cycle TotalCycle;
