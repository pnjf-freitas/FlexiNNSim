function [ft] = Refit_Model(ft, x, y, varargin)
%UNTITLED Summary of this function goes here
%   varargin should be a 1-by-2 cell of fitoptions objects from where the Lower and Upper
%   Limits for fits should be given to the tables

uifig = uifigure('Name', 'Refit Model', 'Position', [500, 400, 1000, 500], 'WindowStyle', 'Modal');
set(uifig, 'HandleVisibility', 'on');

if isempty(varargin) == false
    ftOptions = varargin{1};
end

%% Model Label
for i = 1:2
    DependentVar{i} = dependnames(ft{i});
    IndependentVar{i} = indepnames(ft{i});
    Model{i} = formula(ft{i});
    Coeff.Values{i} = coeffvalues(ft{i});
    Coeff.Names{i} = coeffnames(ft{i});
end

%Label 1 - SET
lbl1 = uilabel(uifig, ...
    'Text', strcat('SET Model : ', DependentVar{1}, ' = ' , Model{1}), ...
    'Position', [10, 475, 500, 20]);
%Label 2 - RESET
lbl2 = uilabel(uifig, ...
    'Text', strcat('RESET Model : ', DependentVar{2}, ' = ', Model{2}), ...
    'Position', [10, 225, 500, 20]);

%% Plot
ax = axes(uifig, 'Position', [0.45, 0.11, 0.5, 0.815]);

fig1 = figure('Name', 'fig1');
plot(ft{1}, 'r-', x{1}, y{1}, 'or');
hold on;
plot(ft{2}, 'b-', x{2}, y{2}, 'sb');

set(fig1.Children(2).Children(1), 'LineWidth', 1.5);
set(fig1.Children(2).Children(2), 'MarkerSize', 4);
set(fig1.Children(2).Children(3), 'LineWidth', 1.5);
set(fig1.Children(2).Children(4), 'MarkerSize', 4);

copyobj(fig1.Children(2).Children, ax);
close fig1;

%% Coeffs tables

table_pos = [10, 275, 275, 175];

for i = 1 : 2
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
        'Position', table_pos);
    
    clear col temp_table;
    
    table_pos = [10, 50, 275, 175];
end

%% Buttons

RefitBtn_pos = [300, 250, 75, 50];

RefitBtn = uibutton(uifig, 'push', ...
    'Text', 'ReFit', ...
    'WordWrap', true, ...
    'Position', RefitBtn_pos, ...
    'ButtonPushedFcn', @(RefitBtn, event) RefitBtn_pushed(RefitBtn, event, ft, x, y, uit));

uiwait(uifig);
end

function [ft] = RefitBtn_pushed(btn, event, ft, x, y, t)
% !! Continue Here !!

for i = 1 : 2
    Model{i} = formula(ft{i});
    ftType{i} = fittype(Model{i});
    StartPoint{i} = t{i}.Data(:,1);
    Min{i} = t{i}.Data(:,2);
    Max{i} = t{i}.Data(:,3);
    ftOptions{i} = fitoptions(Model{i}, 'StartPoint', StartPoint{i}, 'Lower', Min{i}, 'Upper', Max{i});
    
    ft{i} = fit(x{i}, y{i}, ftType{i}, ftOptions{i});
end

close 'Refit Model';

Refit_Model(ft, x, y, ftOptions);

end


