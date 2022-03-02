clear all;
close all;

%Script to create MNISTds datastore file.
%Every user will need to run this for their machine because the ds object
%uses the absolute path of the datastore which will change from user to
%user.

%%

addpath(fullfile(matlabroot,'examples','nnet','main'));

XTrain = datastore('train-images.idx3-ubyte', 'Type', 'file', 'ReadFcn', @processImagesMNIST);
YTrain = datastore('train-labels.idx1-ubyte', 'Type', 'file', 'ReadFcn', @processLabelsMNIST);
XTest = datastore('t10k-images.idx3-ubyte', 'Type', 'file', 'ReadFcn', @processImagesMNIST);
YTest = datastore('t10k-labels.idx1-ubyte', 'Type', 'file', 'ReadFcn', @processLabelsMNIST);

MNISTds = combine(XTrain, YTrain, XTest, YTest);

save('MNISTds.mat', 'MNISTds');