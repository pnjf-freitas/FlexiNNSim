function [fig3, fig4, Digit_idx] = GradCAM_Initialization(dlXTest, dlYTest, classes)

%% GradCAM
% Temporarily only works with MNIST Database
j=1;
temp_YTest = onehotdecode(dlYTest, classes, 1);
for i = 1:length(classes)
    DigitDisplayed = categorical(classes(i));

    temp_Digit_idx = find(temp_YTest == DigitDisplayed);
    Digit_idx(j,1) = temp_Digit_idx(1);

    j=j+1;
end   

fig3 = figure;
for i = 1:length(Digit_idx)
    subplot(2,5,i)
    imshow(extractdata(dlXTest(:,:,:,Digit_idx(i))));
    title(strcat('Digit = ', string(temp_YTest(Digit_idx(i)))));
end
fig3.Children = flipud(fig3.Children);

fig4 = figure;
for i = 1:length(Digit_idx)
    subplot(2,5,i)
    imagesc(extractdata(dlXTest(:,:,:,Digit_idx(i))));
    title(strcat('Digit = ', string(temp_YTest(Digit_idx(i)))));
end
fig4.Children = flipud(fig4.Children);

sgtitle("Epoch: " + "0" + ", Elapsed: " + string(duration(0,0,0)));

clear temp_YTest temp_Digit_idx i j;
    
end