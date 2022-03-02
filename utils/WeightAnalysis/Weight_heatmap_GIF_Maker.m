% Weight Heatmap GIF Maker
% Grabs a file containing Weight Data through different iterations (i.e.
% different validation steps) plots a heatmap of every iteration and saves
% it in a GIF
% Loaded file must be a struct called "Data" containing at least 1 struct
% field called "Weights"

%% Clear Workspace

clear all;
close all;
clc;

%% Load file

[file, path] = uigetfile;

load(fullfile(path, file));

%% General Definitions

validation_step = (1:1:size(Data.Weights,1));

layer_number = 4;

for i = 1:size(Data.Weights,1)
    Weight_ind1(i,1) = Data.Weights{i,layer_number}(1,1);
    Weight_Matrix(:,:,i) = Data.Weights{i,layer_number};
end

%% Get Min and Max values for clim

for i = 1:size(Data.Weights,1)
    if i ==  1
        cmin = min(Data.Weights{i,layer_number}, [], 'all');
        cmax = max(Data.Weights{i,layer_number}, [], 'all');
    else
        tempMin = min(Data.Weights{i,layer_number}, [], 'all');
        tempMax = max(Data.Weights{i,layer_number}, [], 'all');
        
        cmin = min([cmin, tempMin]);
        cmax = max([cmax, tempMax]);
    end
end

clear i tempMin tempMax;

%% Fig1 - Fixed clims

fig1 = figure;

for i = 1:size(Data.Weights,1)

    imagesc(Data.Weights{i,layer_number}', [cmin, cmax]);

    colormap turbo;
    c = colorbar;

    xlabel('Output Layer');
    ylabel('Input Layer');
    c.Label.String = 'Weight';
    title(strcat("Validation Step ", num2str(i)));

    frame = getframe(fig1);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im, 256);

    if i == 1
        imwrite(imind, cm, fullfile(path, strcat('Weight_GIF_Layer', num2str(layer_number), '_fixedCLims.gif')), 'gif', 'Loopcount', inf);
    else
        imwrite(imind, cm, fullfile(path, strcat('Weight_GIF_Layer', num2str(layer_number), '_fixedCLims.gif')), 'gif', 'WriteMode', 'append');
    end

end

close(fig1);
clear fig1;
%% Fig2 - Varying clims

fig2 = figure;

for i = 1:size(Data.Weights,1)

    imagesc(Data.Weights{i,layer_number}');

    colormap turbo;
    c = colorbar;

    xlabel('Output Layer');
    ylabel('Input Layer');
    c.Label.String = 'Weight';
    title(strcat("Validation Step ", num2str(i)));

    frame = getframe(fig2);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im, 256);

    if i == 1
        imwrite(imind, cm, fullfile(path, strcat('Weight_GIF_Layer', num2str(layer_number), '.gif')), 'gif', 'Loopcount', inf);
    else
        imwrite(imind, cm, fullfile(path, strcat('Weight_GIF_Layer', num2str(layer_number), '.gif')), 'gif', 'WriteMode', 'append');
    end

end

close(fig2);
clear fig2;

%% Fig3 - Weight vs validation Step

fig3 = figure;

plot(validation_step, Weight_ind1, '--.b', 'LineWidth', 3);
hold on;

for j = 1 : size(Weight_Matrix, 1)
    for k = 1 : size(Weight_Matrix, 2)
        plot(validation_step, squeeze(Weight_Matrix(j,k,:)), '-', 'Color', [0.6,0.6,0.6]);
    end
end

xlabel('Validation Step');
ylabel('Weight');

fig3.Children.Children = flipud(fig3.Children.Children);

clear i j;

saveas(fig3, fullfile(path, strcat('Weight_vs_validationStep_layer', num2str(layer_number), '.fig')));
saveas(fig3, fullfile(path, strcat('Weight_vs_validationStep_layer', num2str(layer_number), '.png')));

close(fig3);
clear fig3;

%% Fig4 - # of sign changes

for i = 1 : size(Data.Weights,1)
    if i == 1
        Sign_Matrix = zeros([size(Data.Weights{i,layer_number}), size(Data.Weights,1)]);
    else
        Sign_Matrix(:,:,i) = Sign_Matrix(:,:,i-1) + (sign(Data.Weights{i-1, layer_number}) ~= sign(Data.Weights{i,layer_number}));
    end
end

fig4 = figure;

for i = 1 : size(Sign_Matrix,1)
    for j = 1 : size(Sign_Matrix,2)
        if i == 1 && j == 1
            %tempMatrix = Sign_Matrix(i,j,:);
            plot(validation_step, squeeze(Sign_Matrix(i,j,:)), '-.b', 'LineWidth', 3);
            hold on;
            xlabel('Validation Step');
            ylabel('Cumulative # of sign changes');
            %legend('Weight idx 1,1');
        else
            %tempMatrix = Sign_Matrix(i,j,:);
            plot(validation_step, squeeze(Sign_Matrix(i,j,:)), '-', 'Color', [0.6, 0.6, 0.6]);
        end
    end
end

fig4.Children.Children = flipud(fig4.Children.Children);

clear i j;

saveas(fig4, fullfile(path, strcat('Weight_sign_changes_layer', num2str(layer_number), '.fig')));
saveas(fig4, fullfile(path, strcat('Weight_sign_changes_layer', num2str(layer_number), '.png')));

close(fig4);
clear fig4;

%% |Weight| vs validation step
%{
fig5 = figure;

plot(validation_step, abs(Weight_ind1), '--.b');
hold on;

for j = 1 : size(Weight_Matrix, 1)
    for k = 1 : size(Weight_Matrix, 2)
        plot(validation_step, abs(squeeze(Weight_Matrix(j,k,:))), '-', 'Color', [0.6,0.6,0.6]);
    end
end

xlabel('Validation Step');
ylabel('|Weight|');

fig5.Children.Children = flipud(fig5.Children.Children);

clear i j;

saveas(fig5, fullfile(path, 'abs_Weight_vs_validationStep.fig'));
saveas(fig5, fullfile(path, 'abs_Weight_vs_validationStep.png'));
%}
%% Fig6 - Weight vs Validation step - heatscatter

y = reshape(Weight_Matrix, [], 1);
x = repelem(validation_step, (length(y) / length(validation_step)))';

%fig6 = figure;

heatscatter(x,y, path, strcat('Weight_vs_validationStep_heatscatter_layer', num2str(layer_number)), '50', '10', 'o', 1, 0, 'Validation Step', 'Weight', '');
%saveas(fig6, 'Weight_vs_validationStep_heatscatter.fig');