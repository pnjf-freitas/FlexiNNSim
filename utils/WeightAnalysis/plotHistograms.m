%% Temp script to plot histograms

close all;

%% fig1 - GS
fig1 = figure;

subplot(4,1,1);
histogram(NormWeights_GS_NR_SET{80,4}, 'normalization', 'probability');
title('SET');
subplot(4,1,2);
histogram(NormWeights_GS_NR_RESET{80,4}, 'normalization', 'probability');
title('RESET');
subplot(4,1,3);
histogram(NormWeights_GS_NR_Gradient{80,4}, 'normalization', 'probability');
title('Gradient-based');
subplot(4,1,4);
histogram(NormWeights_GS_NR_Selective{80,4}, 'normalization', 'probability');
title('Selective');

xlabel('Normalized Weight');
ylabel('Probability');
sgtitle('GS');

%% fig2 - C2C
fig2 = figure;

subplot(4,1,1);
histogram(NormWeights_C2C_NR_SET{80,4}, 'normalization', 'probability');
title('SET');
subplot(4,1,2);
histogram(NormWeights_C2C_NR_RESET{80,4}, 'normalization', 'probability');
title('RESET');
subplot(4,1,3);
histogram(NormWeights_C2C_NR_Gradient{80,4}, 'normalization', 'probability');
title('Gradient-based');
subplot(4,1,4);
histogram(NormWeights_C2C_NR_Selective{80,4}, 'normalization', 'probability');
title('Selective');

xlabel('Normalized Weight');
ylabel('Probability');
sgtitle('C2C');

%% fig3 - GS+C2C

fig3 = figure;

subplot(4,1,1);
histogram(NormWeights_GS_C2C_NR_SET{80,4}, 'normalization', 'probability');
title('SET');
subplot(4,1,2);
histogram(NormWeights_GS_C2C_NR_RESET{80,4}, 'normalization', 'probability');
title('RESET');
subplot(4,1,3);
histogram(NormWeights_GS_C2C_NR_Gradient{80,4}, 'normalization', 'probability');
title('Gradient-based');
subplot(4,1,4);
histogram(NormWeights_GS_C2C_NR_Selective{80,4}, 'normalization', 'probability');
title('Selective');

xlabel('Normalized Weight');
ylabel('Probability');
sgtitle('GS+C2C');

