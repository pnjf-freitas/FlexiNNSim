function [x, y, pp] = GenerateLookupTable(G_Matrix)

% x(M-by-1) = Normalized Weight
% y(N-by-1) = deltaG
% z(M-by-N) = CDF

%G_Matrix = var_y_LTP;

%x_step = 100;
%y_step = 100;

x = mean(G_Matrix, 2);
for i = 1 : size(G_Matrix, 2)
    deltaG(:,i) = G_Matrix(:,i) - x;
end

y = linspace(min(deltaG, [], 'all'), max(deltaG, [], 'all'), size(deltaG,1))';

fig1 = figure;
for i = 1: size(deltaG, 2)
    
    if i==1
        [f, temp_cdf] = ecdf(deltaG(i,:));
    else
        [~, temp_cdf] = ecdf(deltaG(i,:));
    end
    f_x(:,i) = unique(temp_cdf);
    
    clear temp_cdf;
    
    plot(f_x(:,i), linspace(0,1,length(f_x(:,i))));
    if i == 1
        hold on;
        xlabel('Conductance (S)');
        ylabel('CDF');
    end
    
    pp(:,i) = interp1(f_x(:,i), linspace(0,1,length(f_x(:,i))), y, 'nearest', 'extrap');
end

fig2 = figure;

imagesc(x, y, pp);
colormap turbo;
set(fig2.Children, 'YDir', 'normal');
xlabel('Conductance (S)');
ylabel('\DeltaG (S)');
cbar = colorbar;
cbar.Label.String = 'CDF';

end

