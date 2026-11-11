% ELEC5305 - Reference method comparison
% Plot the results from the pilot validation

clear;
clc;
close all;

% Project folders
projectDir = fileparts(fileparts(mfilename('fullpath')));
validationDir = fullfile(projectDir, 'results', 'validation');

% Load the validated results
R = readtable(fullfile(validationDir, ...
    'reference_comparison.csv'));

P = readtable(fullfile(validationDir, ...
    'pilot_validation.csv'));

% Noise conditions
noiseNames = ["white", "stationary", ...
    "traffic", "public_space"];

noiseLabels = {'White', 'Kitchen', ...
    'Traffic', 'Public space'};

methodLabels = {'Pilot spectral subtraction', ...
    'Pilot Wiener-type', ...
    'VOICEBOX spectral subtraction', ...
    'Scalart Wiener'};

% Store the improvement measurements
sisdrResults = zeros(4, 4);
stoiResults = zeros(4, 4);

for i = 1:4

    noise = noiseNames(i);

    % Select results for the current noise condition
    pilot = P(string(P.Noise) == noise, :);

    voicebox = R(string(R.Noise) == noise & ...
        contains(string(R.ReferenceMethod), 'VOICEBOX'), :);

    scalart = R(string(R.Noise) == noise & ...
        contains(string(R.ReferenceMethod), 'Scalart'), :);

    % Check that the required results are present
    assert(height(pilot) == 1, 'Missing pilot results.');
    assert(height(voicebox) == 1, 'Missing VOICEBOX results.');
    assert(height(scalart) == 1, 'Missing Scalart results.');

    % SI-SDR improvement in dB
    sisdrResults(i, :) = [ ...
        voicebox.PilotSS_DeltaSI_SDR_dB, ...
        voicebox.PilotWiener_DeltaSI_SDR_dB, ...
        voicebox.Reference_DeltaSI_SDR_dB, ...
        scalart.Reference_DeltaSI_SDR_dB];

    % STOI improvement (dimensionless)
    stoiResults(i, :) = [ ...
        pilot.STOI_SS - pilot.STOI_Noisy, ...
        pilot.STOI_Wiener - pilot.STOI_Noisy, ...
        voicebox.Reference_DeltaSTOI, ...
        scalart.Reference_DeltaSTOI];

end

% Figure 1 - SI-SDR improvement
f1 = figure('Color', 'w', ...
    'Position', [100, 100, 1100, 650]);

b1 = bar(sisdrResults, 'grouped');

xticks(1:4);
xticklabels(noiseLabels);

xlabel('Noise condition');
ylabel('SI-SDR improvement (dB)');
title('SI-SDR Improvement Across Enhancement Methods');

legend(b1, methodLabels, ...
    'Location', 'northoutside', ...
    'NumColumns', 2);

grid on;
set(gca, 'FontSize', 11);

exportgraphics(f1, fullfile(validationDir, ...
    'reference_sisdr_comparison.png'), ...
    'Resolution', 300);

% Figure 2 - STOI improvement
f2 = figure('Color', 'w', ...
    'Position', [100, 100, 1100, 650]);

b2 = bar(stoiResults, 'grouped');

xticks(1:4);
xticklabels(noiseLabels);

xlabel('Noise condition');
ylabel('STOI improvement');
title('STOI Improvement Across Enhancement Methods');

lgd = legend(b2, methodLabels, ...
    'Location', 'northoutside', ...
    'NumColumns', 2);

lgd.AutoUpdate = 'off';

yline(0, 'k-');
grid on;
set(gca, 'FontSize', 11);

exportgraphics(f2, fullfile(validationDir, ...
    'reference_stoi_comparison.png'), ...
    'Resolution', 300);

disp('Reference comparison figures saved successfully.');
