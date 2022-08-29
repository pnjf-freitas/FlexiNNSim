function [] = dlnet_Gradient_heatmap_GIF_Maker(Data, layers, path)
%% General Definitions


validation_step = (1:1:size(Data.Gradients,1));

for layer_number = layers

    for i = 1:size(Data.Gradients,1)
        Gradient_ind1(i,1) = Data.Gradients{i,layer_number}(1,1);
        Gradient_Matrix(:,:,i) = Data.Gradients{i,layer_number};
    end


    %% Get Min and Max values for clim

    for i = 1:size(Data.Gradients,1)
        if i ==  1
            cmin = min(Data.Gradients{i,layer_number}, [], 'all');
            cmax = max(Data.Gradients{i,layer_number}, [], 'all');
        else
            tempMin = min(Data.Gradients{i,layer_number}, [], 'all');
            tempMax = max(Data.Gradients{i,layer_number}, [], 'all');

            cmin = min([cmin, tempMin]);
            cmax = max([cmax, tempMax]);
        end
    end

    clear i tempMin tempMax;

    %% Fig1 - Fixed clims

    fig1 = figure;

    for i = 1:size(Data.Gradients,1)

        imagesc(Data.Gradients{i,layer_number}', [cmin, cmax]);

        colormap turbo;
        c = colorbar;

        xlabel('Output Layer');
        ylabel('Input Layer');
        c.Label.String = 'Gradient';
        title(strcat("Validation Step ", num2str(i)));

        frame = getframe(fig1);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im, 256);

        if i == 1
            imwrite(imind, cm, fullfile(path, strcat('Gradient_GIF_Layer', num2str(layer_number), '_fixedCLims.gif')), 'gif', 'Loopcount', inf);
        else
            imwrite(imind, cm, fullfile(path, strcat('Gradient_GIF_Layer', num2str(layer_number), '_fixedCLims.gif')), 'gif', 'WriteMode', 'append');
        end

    end

    close(fig1);
    clear fig1;

    %% Fig2 - Varying clims
%{
    fig2 = figure;

    for i = 1:size(Data.Gradients,1)

        imagesc(Data.Gradients{i,layer_number}');

        colormap turbo;
        c = colorbar;

        xlabel('Output Layer');
        ylabel('Input Layer');
        c.Label.String = 'Gradient';
        title(strcat("Validation Step ", num2str(i)));

        frame = getframe(fig2);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im, 256);

        if i == 1
            imwrite(imind, cm, fullfile(path, strcat('Gradient_GIF_Layer', num2str(layer_number), '_varyingCLims.gif')), 'gif', 'Loopcount', inf);
        else
            imwrite(imind, cm, fullfile(path, strcat('Gradient_GIF_Layer', num2str(layer_number), '_varyingCLims.gif')), 'gif', 'WriteMode', 'append');
        end

    end

    close(fig2);
    clear fig2;
    %}
    %% Fig3 - Gradient vs validation Step

    fig3 = figure;

    plot(validation_step, Gradient_ind1, '--.b', 'LineWidth', 3);
    hold on;

    for j = 1 : size(Gradient_Matrix, 1)
        for k = 1 : size(Gradient_Matrix, 2)
            plot(validation_step, squeeze(Gradient_Matrix(j,k,:)), '-', 'Color', [0.6,0.6,0.6]);
        end
    end

    xlabel('Validation Step');
    ylabel('Gradient');

    fig3.Children.Children = flipud(fig3.Children.Children);

    clear i j;

    saveas(fig3, fullfile(path, strcat('Gradient_vs_validationStep_Layer', num2str(layer_number), '.fig')));
    saveas(fig3, fullfile(path, strcat('Gradient_vs_validationStep_Layer', num2str(layer_number), '.png')));

    close(fig3);
    clear fig3;
    %% Fig4 - # of sign changes
    %{
    for i = 1 : size(Data.Gradients,1)
        if i == 1
            Sign_Matrix = zeros([size(Data.Gradients{i,4}), size(Data.Gradients,1)]);
        else
            Sign_Matrix(:,:,i) = Sign_Matrix(:,:,i-1) + (sign(Data.Gradients{i-1, 4}) ~= sign(Data.Gradients{i,4}));
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
                %legend('Gradient idx 1,1');
            else
                %tempMatrix = Sign_Matrix(i,j,:);
                plot(validation_step, squeeze(Sign_Matrix(i,j,:)), '-', 'Color', [0.6, 0.6, 0.6]);
            end
        end
    end

    fig4.Children.Children = flipud(fig4.Children.Children);

    clear i j;

    saveas(fig4, fullfile(path, 'Gradient_sign_changes.fig'));
    saveas(fig4, fullfile(path, 'Gradient_sign_changes.png'));

    close(fig4);
    clear fig4;
    %}
    %% |Gradient| vs validation step
    %{
    fig5 = figure;

    plot(validation_step, abs(Gradient_ind1), '--.b');
    hold on;

    for j = 1 : size(Gradient_Matrix, 1)
        for k = 1 : size(Gradient_Matrix, 2)
            plot(validation_step, abs(squeeze(Gradient_Matrix(j,k,:))), '-', 'Color', [0.6,0.6,0.6]);
        end
    end

    xlabel('Validation Step');
    ylabel('|Gradient|');

    fig5.Children.Children = flipud(fig5.Children.Children);

    clear i j;

    saveas(fig5, fullfile(path, 'abs_Gradient_vs_validationStep.fig'));
    saveas(fig5, fullfile(path, 'abs_Gradient_vs_validationStep.png'));

    close(fig5);
    clear fig5;
    %}

    %% Weight vs Validation step - scatter_kde 

    y = reshape(Gradient_Matrix, [], 1);
    x = repelem(validation_step, (length(y) / length(validation_step)))';

    %fig6 = figure;

    heatscatter(x,y, path, strcat('Gradient_vs_validationStep_heatscatter_Layer', num2str(layer_number)), ...
        '50', '10', 'o', 1, 0, 'Validation Step', 'Gradient', '');
    %saveas(fig6, 'Gradient_vs_validationStep_heatscatter.fig');
    
    fig6 = gcf;
    close(fig6);
    
end
end

