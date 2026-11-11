
% ELEC5305 - Performance across four SNR levels
% Plot SI-SDR and STOI improvement for the three methods

clear;
clc;
close all;

projectDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(projectDir, 'results', 'extended');

T = readtable(fullfile(resultsDir, ...
    'deepfilter_all_snr_metrics.csv'));

assert(height(T) == 640, ...
    'Expected 640 matched results.');

snrs = [-5, 0, 5, 10];

noiseNames = ["white", "stationary", ...
    "traffic", "public_space"];

noiseLabels = {'White', 'Kitchen', ...
    'Traffic', 'Public space'};

methodLabels = {'Spectral subtraction', ...
    'Wiener-type filtering', 'DeepFilterNet'};

sisdrCols = {'SI_SDR_SS', ...
    'SI_SDR_Wiener', 'SI_SDR_DeepFilterNet'};

stoiCols = {'STOI_SS', ...
    'STOI_Wiener', 'STOI_DeepFilterNet'};

metricSets = {sisdrCols, stoiCols};

figureNames = {'all_snr_sisdr_comparison.png', ...
    'all_snr_stoi_comparison.png'};

figureTitles = { ...
    'SI-SDR Improvement Across SNR Levels', ...
    'STOI Improvement Across SNR Levels'};

yLabels = {'SI-SDR improvement (dB)', ...
    'STOI improvement'};

plotColors = lines(4);

% ============================================
% PLOT BOTH PERFORMANCE MEASURES
% ============================================

for metricIdx = 1:2

    f = figure('Color', 'w', ...
        'Position', [100 100 1600 620]);

    tiledlayout(1,3, ...
        'TileSpacing', 'compact', ...
        'Padding', 'compact');

    for methodIdx = 1:3

        nexttile;
        hold on;

        metricName = metricSets{metricIdx}{methodIdx};

        for noiseIdx = 1:4

            avgValues = zeros(4,1);
            sdValues = zeros(4,1);

            for snrIdx = 1:4

                G = T( ...
                    string(T.Noise) == ...
                        noiseNames(noiseIdx) & ...
                    T.SNR_dB == snrs(snrIdx), :);

                assert(height(G) == 40, ...
                    'Expected 40 recordings per group.');

                values = G.(metricName);

                assert(all(isfinite(values)), ...
                    'Invalid performance measurements.');

                avgValues(snrIdx) = mean(values);
                sdValues(snrIdx) = std(values);

            end

            % Mean improvement with standard deviation
            errorbar(snrs, avgValues, sdValues, ...
                '-o', ...
                'Color', plotColors(noiseIdx,:), ...
                'LineWidth', 1.3, ...
                'CapSize', 6, ...
                'MarkerSize', 5, ...
                'DisplayName', noiseLabels{noiseIdx});

        end

        if metricIdx == 2
            yline(0, 'k:', ...
                'HandleVisibility', 'off');
        end

        xticks(snrs);

        xlabel('Input SNR (dB)');
        ylabel(yLabels{metricIdx});

        title(methodLabels{methodIdx});

        grid on;
        set(gca, 'FontSize', 10);

        if methodIdx == 1
            legend('Location', 'best');
        end

    end

    sgtitle(figureTitles{metricIdx});

    exportgraphics(f, ...
        fullfile(resultsDir, figureNames{metricIdx}), ...
        'Resolution', 300);

end

disp('Full-SNR comparison figures saved successfully.');
