
% ELEC5305 - Expanded experiment summary
% Check the results and plot performance across SNR levels

clear;
clc;
close all;

projectDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(projectDir, 'results', 'extended');

if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

% Load the completed experiment
inputFile = fullfile(resultsDir, 'extended_results.csv');

if ~isfile(inputFile)
    inputFile = fullfile(projectDir, 'results', ...
        'extended_results.csv');
end

T = readtable(inputFile);

% Check that the expected data is present
assert(height(T) == 640, 'Expected 640 result rows.');
assert(numel(unique(string(T.SpeechFile))) == 40, ...
    'Expected 40 speech recordings.');

numericColumns = varfun(@isnumeric, T, ...
    'OutputFormat', 'uniform');

assert(all(isfinite(T{:, numericColumns}), 'all'), ...
    'Some numerical results are invalid.');

snrError = abs(T.TargetSNR_dB - T.MeasuredSNR_dB);

assert(max(snrError) < 0.01, ...
    'Some mixtures have incorrect SNR.');

% Check that all experiment combinations are unique
keys = strcat(string(T.SpeechFile), "|", ...
    string(T.Noise), "|", string(T.TargetSNR_dB));

assert(numel(unique(keys)) == height(T), ...
    'Duplicate experimental combinations found.');

fprintf('Validated %d experiment rows.\n', height(T));
fprintf('Speakers: %d\n', numel(unique(string(T.Speaker))));
fprintf('Maximum SNR error: %.6g dB\n', max(snrError));

% Calculate group means and standard deviations
metrics = {'DeltaSI_SDR_SS_dB', ...
    'DeltaSI_SDR_Wiener_dB', ...
    'DeltaSTOI_SS', 'DeltaSTOI_Wiener'};

S = groupsummary(T, {'TargetSNR_dB', 'Noise'}, ...
    {'mean', 'std'}, metrics);

writetable(S, fullfile(resultsDir, ...
    'extended_summary.csv'));

% Noise conditions and SNR levels
noiseNames = {'white', 'stationary', ...
    'traffic', 'public_space'};

noiseLabels = {'White', 'Kitchen', ...
    'Traffic', 'Public space'};

snrs = [-5, 0, 5, 10];

% Create SI-SDR and STOI figures
metricPairs = { ...
    {'DeltaSI_SDR_SS_dB', 'DeltaSI_SDR_Wiener_dB'}, ...
    {'DeltaSTOI_SS', 'DeltaSTOI_Wiener'}};

figureNames = {'extended_sisdr_vs_snr.png', ...
    'extended_stoi_vs_snr.png'};

yLabels = {'SI-SDR improvement (dB)', ...
    'STOI improvement'};

methodLabels = {'Spectral subtraction', 'Wiener filtering'};

for figIdx = 1:2

    f = figure('Color', 'w', ...
        'Position', [100, 100, 1250, 540]);

    tiledlayout(1, 2, 'TileSpacing', 'compact');

    pair = metricPairs{figIdx};

    for methodIdx = 1:2

        nexttile;
        hold on;

        metric = pair{methodIdx};

        for j = 1:4

            meanValues = zeros(1, 4);
            stdValues = zeros(1, 4);

            for i = 1:4

                idx = S.TargetSNR_dB == snrs(i) & ...
                    string(S.Noise) == noiseNames{j};

                assert(nnz(idx) == 1, ...
                    'Missing summary group.');

                meanColumn = ['mean_' metric];
                stdColumn = ['std_' metric];

                meanValues(i) = S{idx, meanColumn};
                stdValues(i) = S{idx, stdColumn};

            end

            errorbar(snrs, meanValues, stdValues, ...
                '-o', 'LineWidth', 1.2, ...
                'DisplayName', noiseLabels{j});

        end

        yline(0, 'k:', 'HandleVisibility', 'off');

        xlabel('Input SNR (dB)');
        ylabel(yLabels{figIdx});
        title(methodLabels{methodIdx});

        xticks(snrs);
        grid on;
        set(gca, 'FontSize', 11);

        if methodIdx == 1
            legend('Location', 'best');
        end

    end

    exportgraphics(f, ...
        fullfile(resultsDir, figureNames{figIdx}), ...
        'Resolution', 300);

end

disp('Expanded summary and figures saved.');
