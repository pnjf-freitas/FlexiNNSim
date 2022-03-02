function [ax_children] = Plot_RawData(Table, varargin)

%% Figure Declaration
fig = figure;
%% Main Plot
plot(Table.Pulse, Table.G, '-or', 'MarkerSize', 2);
%% Ref Lines Plot

if nargin > 0
    hold on;
    for i = 1 : length(varargin)
        plot(fig.Children.XLim, [varargin{i}, varargin{i}], '--k');
    end
end

%% Axis export
ax_children = fig.Children.Children;

end

