function [ft] = Refit_Model(ft, x, y, varargin)
%UNTITLED Summary of this function goes here
%   Each variable is a cell array of up to 2 cells.
%   Cell 1 for SET and Cell 2 for RESET
%   varargin should be a 1-by-2 cell of fitoptions objects from where the Lower and Upper
%   Limits for fits should be given to the tables

uifig = uifigure('Name', 'Refit Model', 'Position', [500, 400, 1000, 500], 'WindowStyle', 'Modal');
set(uifig, 'HandleVisibility', 'on');

if isempty(varargin) == false
    ftOptions = varargin{1};
end

%% Script
[DependentVar, IndependentVar, Model] = Declare_vars(ft);
lbl = Draw_labels(uifig, DependentVar, Model);
ax = Plot_fig(uifig, ft, x, y);

if exist('ftOptions', 'var') ~= 0
    uit = Draw_tables(uifig, ft, ftOptions);
else
    uit = Draw_tables(uifig, ft);
end

[Refit_Btn, SaveBtn] = Draw_Btns(uifig, ft, x, y, uit);

%uiwait(uifig);

waitfor(SaveBtn);

% Very janky solution but it is what it is

% extract data from ReFitBtn.UserData
temp_ft = getappdata(uifig, 'newft');
if ~isempty(temp_ft)
    ft = temp_ft;
end
clear temp_ft;
% Close uifig
close(uifig);
% Export ft at the end of the program

end

%% Declare vars
function [DependentVar, IndependentVar, Model] = Declare_vars(ft)
    for i = 1:length(ft)
        DependentVar{i} = dependnames(ft{i});
        IndependentVar{i} = indepnames(ft{i});
        Model{i} = formula(ft{i});
    end
    clear i;
end
%% Model Label
function [lbl] = Draw_labels(uifig, DependentVar, Model)
    
    Pos = [10, 475, 500, 20];
    delta_pos = [0, -250, 0, 0];

    for i = 1 : length(Model)
        switch i
            case 1
                ProgramMode = 'SET';
            case 2
                ProgramMode = 'RESET';
        end
        
        lbl{i} = uilabel(uifig, ...
            'Text', strcat(ProgramMode, ' Model : ', DependentVar{i}, ' = ' , Model{i}), ...
            'Position', Pos);
    
        Pos = Pos + delta_pos;
    end
end

%% Plot
function [ax] = Plot_fig(uifig, ft, x, y)
    ax = axes(uifig, 'Position', [0.45, 0.11, 0.5, 0.815]);

    fig1 = figure('Name', 'fig1');
    for i = 1 : length(ft)
        if i == 1
            plot(ft{i}, 'r-', x{1}, y{1}, 'or');
        elseif i == 2
            hold on;
            plot(ft{2}, 'b-', x{2}, y{2}, 'sb');
        end
    end
    
    if length(ft) == 1
        set(fig1.Children(2).Children(1), 'LineWidth', 1.5);
        set(fig1.Children(2).Children(2), 'MarkerSize', 4, 'Color', 'b');
    elseif length(ft) == 2
        set(fig1.Children(2).Children(1), 'LineWidth', 1.5);
        set(fig1.Children(2).Children(2), 'MarkerSize', 4);
        set(fig1.Children(2).Children(3), 'LineWidth', 1.5);
        set(fig1.Children(2).Children(4), 'MarkerSize', 4);
    end
    
    copyobj(fig1.Children(2).Children, ax);
    close fig1;
end

%% Coeffs tables
function [uit] = Draw_tables(uifig, ft, varargin)
    table_pos = [10, 275, 275, 175];
    delta_pos = [0, -225, 0, 0];
    
    for i = 1 : length(ft)
        Coeff.Values{i} = coeffvalues(ft{i});
        Coeff.Names{i} = coeffnames(ft{i});
    end
    
    if isempty(varargin) == false
        ftOptions = varargin{1};
    end

    for i = 1 : length(ft)
        col{1} = Coeff.Values{i}';
        if exist('ftOptions', 'var') ~= 0
            col{2} = ftOptions{i}.Lower';
            col{3} = ftOptions{i}.Upper';
        else
            col{2} = -Inf(size(col{1}));
            col{3} = Inf(size(col{1}));
        end

        temp_table = [col{1}, col{2}, col{3}];

        uit{i} = uitable(uifig, ...
            'Data', temp_table, ...
            'RowName', Coeff.Names{i}, ...
            'ColumnName', {'StartPoint', 'Min', 'Max'}, ...
            'ColumnEditable', true, ...
            'Position', table_pos, ...
            'HandleVisibility', 'on', ...
            'Tag', 'uit');

        clear col temp_table;

        table_pos = table_pos + delta_pos;
    end
end

%% Buttons
function [RefitBtn, SaveBtn] = Draw_Btns(uifig, ft, x, y, uit)
    RefitBtn_pos = [300, 250, 75, 50];
    SaveBtn_pos = [300, 150, 75, 50];

    RefitBtn = uibutton(uifig, 'push', ...
        'Text', 'ReFit', ...
        'WordWrap', true, ...
        'Position', RefitBtn_pos, ...
        'ButtonPushedFcn', @(RefitBtn, event) RefitBtn_pushed(RefitBtn, event, ft, x, y, uit, uifig));
    
    SaveBtn = uibutton(uifig, 'push', ...
        'Text', 'Save & Close', ...
        'WordWrap', true, ...
        'Position', SaveBtn_pos, ...
        'Tag', 'SaveBtn', ...
        'ButtonPushedFcn', @(SaveBtn, event) SaveBtn_pushed(SaveBtn, event, uifig));
end


function [ft] = RefitBtn_pushed(btn, event, ft, x, y, t, uifig)

for i = 1 : length(ft)
    Model{i} = formula(ft{i});
    ftType{i} = fittype(Model{i});
    StartPoint{i} = t{i}.Data(:,1);
    Min{i} = t{i}.Data(:,2);
    Max{i} = t{i}.Data(:,3);
    ftOptions{i} = fitoptions(Model{i}, 'StartPoint', StartPoint{i}, 'Lower', Min{i}, 'Upper', Max{i});
    
    ft{i} = fit(x{i}, y{i}, ftType{i}, ftOptions{i});
    
    %Update tables
    set(t{i}, 'Data', [coeffvalues(ft{i})', Min{i}, Max{i}]);
end
%Delete axes
delete(get(uifig, 'CurrentAxes'));
%ReDraw ax
Plot_fig(uifig, ft, x, y);

setappdata(uifig, 'newft', ft);

end

function SaveBtn_pushed(btn, event, uifig)
	delete(findobj(uifig, 'Tag', 'SaveBtn'));
end
