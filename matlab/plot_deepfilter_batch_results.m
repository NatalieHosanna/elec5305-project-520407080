
% ELEC5305 - DeepFilterNet batch results
% Compare the three enhancement methods at 0 dB SNR

clear;
clc;
close all;

% Project folders
projectDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(projectDir, 'results', 'extended');

% Load the results
T = readtable(fullfile(resultsDir, ...
    'deepfilter_batch_metrics.csv'));

assert(height(T) == 160, ...
    'Expected 160 matched results.');

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

% ============================================
% MEAN PERFORMANCE AND STANDARD DEVIATION
% ============================================

metricSets = {sisdrCols, stoiCols};

figureNames = {'batch_sisdr_comparison.png', ...
    'batch_stoi_comparison.png'};

yLabels = {'SI-SDR improvement (dB)', ...
    'STOI improvement'};

figureTitles = { ...
    'SI-SDR Improvement Across Enhancement Methods at 0 dB SNR', ...
    'STOI Improvement Across Enhancement Methods at 0 dB SNR'};

for metricIdx = 1:2

    metricCols = metricSets{metricIdx};

    means = zeros(4,3);
    stds = zeros(4,3);

    % Calculate mean and standard deviation
    for i = 1:4

        G = T(string(T.Noise) == noiseNames(i), :);

        assert(height(G) == 40, ...
            'Expected 40 recordings per noise.');

        for j = 1:3

            x = G.(metricCols{j});

            assert(all(isfinite(x)), ...
                'Invalid metric values found.');

            means(i,j) = mean(x);
            stds(i,j) = std(x);

        end
    end

    % Plot mean performance
    f = figure('Color', 'w', ...
        'Position', [100 100 1200 650]);

    bars = bar(means, 'grouped');
    hold on;

    % Add standard deviation error bars
    for j = 1:3

        errorbar(bars(j).XEndPoints, ...
            means(:,j), stds(:,j), ...
            'k.', ...
            'LineWidth', 1.1, ...
            'CapSize', 8, ...
            'HandleVisibility', 'off');

    end

    % Show zero reference for STOI improvement
    if metricIdx == 2

        yline(0, 'k-', ...
            'HandleVisibility', 'off');

    end

    xticks(1:4);
    xticklabels(noiseLabels);

    xlabel('Noise condition');
    ylabel(yLabels{metricIdx});

    title(figureTitles{metricIdx});

    legend(bars, methodLabels, ...
        'Location', 'northoutside', ...
        'NumColumns', 3);

    grid on;
    set(gca, 'FontSize', 11);

    % Save the figure
    exportgraphics(f, ...
        fullfile(resultsDir, figureNames{metricIdx}), ...
        'Resolution', 300);

end

% ============================================
% ACOUSTIC CHARACTERISTICS VS STOI
% ============================================

features = {'OverlapO', 'VariationVN'};

featureLabels = {'Time-frequency overlap O', ...
    'Noise spectral variation V_N'};

featureFiles = {'batch_overlap_vs_stoi.png', ...
    'batch_variation_vs_stoi.png'};

featureTitles = { ...
    'Time-Frequency Overlap vs STOI Improvement at 0 dB SNR', ...
    'Noise Spectral Variation vs STOI Improvement at 0 dB SNR'};

plotColors = lines(4);

for featureIdx = 1:2

    f = figure('Color', 'w', ...
        'Position', [100 100 1000 1100]);

    tiledlayout(3,1, ...
        'TileSpacing', 'compact', ...
        'Padding', 'compact');

    % Plot each enhancement method separately
    for methodIdx = 1:3

        nexttile;
        hold on;

        for i = 1:4

            G = T(string(T.Noise) == noiseNames(i), :);

            scatter(G.(features{featureIdx}), ...
                G.(stoiCols{methodIdx}), ...
                30, plotColors(i,:), ...
                'filled', ...
                'MarkerFaceAlpha', 0.55, ...
                'DisplayName', noiseLabels{i});

        end

        % Zero indicates no STOI improvement
        yline(0, 'k:', ...
            'HandleVisibility', 'off');

        xlabel(featureLabels{featureIdx});
        ylabel('STOI improvement');

        title(methodLabels{methodIdx});

        grid on;
        set(gca, 'FontSize', 10);

        if methodIdx == 1

            legend('Location', 'best');

        end

    end

    % Overall figure title
    sgtitle(featureTitles{featureIdx}, ...
        'FontWeight', 'bold');

    % Save the figure
    exportgraphics(f, ...
        fullfile(resultsDir, featureFiles{featureIdx}), ...
        'Resolution', 300);

end

disp('DeepFilterNet batch figures saved successfully.');
disp('Four figures updated in results/extended/.');
