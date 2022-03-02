function [gradients,state,loss,accuracy] = modelGradients(dlnet,dlX,Y, classes)

[dlYPred,state] = forward(dlnet,dlX);

loss = crossentropy(dlYPred,Y);
gradients = dlgradient(loss,dlnet.Learnables);

loss = double(gather(extractdata(loss)));

accuracy = (sum(onehotdecode(dlYPred, classes, 1) == onehotdecode(Y, classes, 1)) / size(Y, 2)) * 100;
end

