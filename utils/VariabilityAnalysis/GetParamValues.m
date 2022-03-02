function [varargout] = GetParamValues(Residuals,args)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% Calculate from Residuals

for i = 1 : size(Residuals, 2)
   for j = 1 : size(Residuals{1,i}, 1)
       pd{1,i}(j,1) = fitdist(Residuals{1,i}(j,:)', args.dist); %Transposed has to be used because fitdist only accepts column vectors
       
       varargout{1}{1,i}(j,1) = pd{1,i}(j,1).ParameterValues(1);
       if args.nParams > 1
           varargout{2}{1,i}(j,1) = pd{1,i}(j,1).ParameterValues(2);
       end
   end
end

end

