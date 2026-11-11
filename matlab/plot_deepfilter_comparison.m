% ELEC5305 - Classical and DeepFilterNet comparison
% Compare the four matched mixtures at 0 dB SNR
clear;
clc;
close all;

projectDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(projectDir, 'results', 'extended');

% Load the existing experimental results
extendedFile = fullfile(resultsDir, 'extended_results.csv');

if ~isfile(extendedFile)
    extendedFile = fullfile(projectDir, ...
        'results', 'extended_results.csv');
end

T = readtable(extendedFile);

D = readtable(fullfile(resultsDir, ...
    'deepfilter_test_metrics.csv'));

noiseNames = ["white", "stationary", ...
    "traffic", "public_space"];

noiseLabels = ["White", "Kitchen", ...
    "Traffic", "Public space"];

methodNames = {'Spectral subtraction', ...
    'Wiener-type filtering', 'DeepFilterNet'};

sisdrData = zeros(4,3);
stoiData = zeros(4,3);

for i = 1:4

    % Match the exact speech file, noise and SNR
    A = T(string(T.SpeechFile) == "p232_010.wav" & ...
          string(T.Noise) == noiseNames(i) & ...
          T.TargetSNR_dB == 0, :);

    B = D(string(D.Noise) == noiseLabels(i), :);

    assert(height(A) == 1 && height(B) == 1, ...
        'Missing or duplicate comparison data.');

    % Check that both experiments used the same input
    assert(abs(A.SI_SDR_Noisy_dB - ...
        B.SI_SDR_Noisy_dB) < 0.01, ...
        'Noisy SI-SDR measurements do not match.');

    assert(abs(A.STOI_Noisy - B.STOI_Noisy) < 0.001, ...
        'Noisy STOI measurements do not match.');

    % SI-SDR improvement
    sisdrData(i,:) = [ ...
        A.DeltaSI_SDR_SS_dB, ...
        A.DeltaSI_SDR_Wiener_dB, ...
        B.DeltaSI_SDR_DeepFilterNet_dB];

    % STOI improvement
    stoiData(i,:) = [ ...
        A.DeltaSTOI_SS, ...
        A.DeltaSTOI_Wiener, ...
        B.DeltaSTOI_DeepFilterNet];

end

% Save a combined numerical table
C = table(noiseLabels(:), ...
    sisdrData(:,1), sisdrData(:,2), sisdrData(:,3), ...
    stoiData(:,1), stoiData(:,2), stoiData(:,3), ...
    'VariableNames', { ...
    'Noise', 'SI_SDR_SS_dB', 'SI_SDR_Wiener_dB', ...
    'SI_SDR_DeepFilterNet_dB', ...
    'STOI_SS', 'STOI_Wiener', 'STOI_DeepFilterNet'});

writetable(C, fullfile(resultsDir, ...
    'deepfilter_comparison.csv'));

% Plot both evaluation metrics
datasets = {sisdrData, stoiData};
titles = {'SI-SDR Improvement at 0 dB SNR', ...
    'STOI Improvement at 0 dB SNR'};
yLabels = {'SI-SDR improvement (dB)', ...
    'STOI improvement'};
fileNames = {'deepfilter_sisdr_comparison.png', ...
    'deepfilter_stoi_comparison.png'};

for j = 1:2

    f = figure('Color', 'w', ...
        'Position', [100 100 1100 600]);

    bars = bar(datasets{j}, 'grouped');

    xticks(1:4);
    xticklabels(cellstr(noiseLabels));
    xlabel('Noise condition');
    ylabel(yLabels{j});
    title(titles{j});

    legend(bars, methodNames, ...
        'Location', 'northoutside', ...
        'NumColumns', 3);

    if j == 2
        yline(0, 'k-', 'HandleVisibility', 'off');
    end

    grid on;
    set(gca, 'FontSize', 11);

    exportgraphics(f, ...
        fullfile(resultsDir, fileNames{j}), ...
        'Resolution', 300);

end

disp('Matched classical and DeepFilterNet results:');
disp(C);
disp('Comparison table and figures saved.');