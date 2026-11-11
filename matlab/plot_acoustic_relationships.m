
% ELEC5305 - Acoustic characteristics and enhancement performance
% Compare the measured descriptors at a fixed input SNR

clear;
clc;
close all;

% Project folders
projectDir = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(projectDir, 'results', 'extended');

% Load the expanded study
inputFile = fullfile(resultsDir, 'extended_results.csv');

if ~isfile(inputFile)
    inputFile = fullfile(projectDir, 'results', ...
        'extended_results.csv');
end

T = readtable(inputFile);

% Start with 0 dB, then include the other SNR levels
snrLevels = 0;
% snrLevels = [-5, 0, 5, 10];

noiseNames = ["white", "stationary", ...
    "traffic", "public_space"];

noiseLabels = {'White', 'Kitchen', ...
    'Traffic', 'Public space'};

plotColors = lines(4);

% Acoustic descriptors
features = {'OverlapO', 'VariationVN'};
featureLabels = {'Time-frequency overlap O', ...
    'Noise spectral variation V_N'};

fileNames = {'overlap', 'variation'};

% Evaluation measures
metrics = {'DeltaSI_SDR_SS_dB', ...
    'DeltaSI_SDR_Wiener_dB', ...
    'DeltaSTOI_SS', 'DeltaSTOI_Wiener'};

panelTitles = {'Spectral subtraction - SI-SDR', ...
    'Wiener filtering - SI-SDR', ...
    'Spectral subtraction - STOI', ...
    'Wiener filtering - STOI'};

% Generate figures separately for each input SNR
for snr = snrLevels

    rows = T(T.TargetSNR_dB == snr, :);

    assert(height(rows) == 160, ...
        'Expected 160 measurements at this SNR.');

    for featureIdx = 1:2

        feature = features{featureIdx};

        f = figure('Color', 'w', ...
            'Position', [100 100 1200 850]);

        tiledlayout(2, 2, ...
            'TileSpacing', 'compact', ...
            'Padding', 'compact');

        for panelIdx = 1:4

            nexttile;
            hold on;

            metric = metrics{panelIdx};

            % Plot each noise condition separately
            for j = 1:4

                selected = rows( ...
                    string(rows.Noise) == noiseNames(j), :);

                assert(height(selected) == 40, ...
                    'Expected 40 measurements per noise.');

                scatter(selected.(feature), ...
                    selected.(metric), 32, ...
                    'MarkerFaceColor', plotColors(j,:), ...
                    'MarkerEdgeColor', plotColors(j,:), ...
                    'MarkerFaceAlpha', 0.55, ...
                    'DisplayName', noiseLabels{j});

            end

            xlabel(featureLabels{featureIdx});

            if panelIdx <= 2
                ylabel('SI-SDR improvement (dB)');
            else
                ylabel('STOI improvement');
            end

            title(panelTitles{panelIdx});
            grid on;

            if panelIdx >= 3
                yline(0, 'k:', ...
                    'HandleVisibility', 'off');
            end

            if panelIdx == 1
                legend('Location', 'best');
            end

            set(gca, 'FontSize', 10);

        end

        sgtitle(sprintf( ...
            'Acoustic characteristics at %g dB SNR', snr));

        % Save each figure
        outputName = sprintf('%s_relationships_%gdB.png', ...
            fileNames{featureIdx}, snr);

        exportgraphics(f, ...
            fullfile(resultsDir, outputName), ...
            'Resolution', 300);

    end

end

disp('Acoustic relationship figures saved successfully.');
