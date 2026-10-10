
% Preliminary acoustic difficulty analysis
clear; clc; close all;

projectDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(projectDir, 'results');

T = readtable(fullfile(resultsDir, 'pilot_results.csv'));

% Improvement relative to unprocessed noisy speech
deltaSS = T.SI_SDR_SS_dB - T.SI_SDR_Noisy_dB;
deltaWiener = T.SI_SDR_Wiener_dB - T.SI_SDR_Noisy_dB;

% Figure 1: Overlap versus enhancement improvement
figure;
scatter(T.OverlapO, deltaSS, 80, 'o', 'filled');
hold on;
scatter(T.OverlapO, deltaWiener, 80, 's', 'filled');
xlabel('Time-frequency overlap O');
ylabel('SI-SDR improvement (dB)');
title('Effect of Time-Frequency Overlap');
legend('Spectral subtraction', 'Wiener filtering');
grid on;
saveas(gcf, fullfile(resultsDir, 'overlap_vs_improvement.png'));

% Figure 2: Noise variation versus improvement
figure;
scatter(T.VariationVN, deltaSS, 80, 'o', 'filled');
hold on;
scatter(T.VariationVN, deltaWiener, 80, 's', 'filled');
xlabel('Noise spectral variation V_N');
ylabel('SI-SDR improvement (dB)');
title('Effect of Noise Non-Stationarity');
legend('Spectral subtraction', 'Wiener filtering');
grid on;
saveas(gcf, fullfile(resultsDir, 'variation_vs_improvement.png'));

disp('Preliminary figures saved successfully.');
