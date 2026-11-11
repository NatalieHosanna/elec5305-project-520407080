
% ELEC5305 - Investigation of individual enhancement results
% Compare clean, noisy and DeepFilterNet speech for two recordings

clear;
clc;
close all;

% Project folders
projectDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectDir, 'matlab'));

resultsDir = fullfile(projectDir, 'results', 'extended');

inputDir = fullfile(resultsDir, 'deepfilter_batch_inputs');
cleanDir = fullfile(inputDir, 'clean');
noisyDir = fullfile(inputDir, 'noisy');
enhancedDir = fullfile(resultsDir, 'deepfilter_batch_outputs');

figureDir = fullfile(resultsDir, 'failure_cases');

if ~isfolder(figureDir)
    mkdir(figureDir);
end

% Load the existing measurements
T = readtable(fullfile(resultsDir, ...
    'deepfilter_batch_metrics.csv'));

assert(exist('stoi', 'file') == 2, ...
    'MATLAB STOI function was not found.');

% Recordings selected for further investigation
speechNames = ["p257_284", "p257_311"];

% Both recordings use kitchen noise
noiseName = "stationary";

% Change to true to listen during the script
playAudio = false;

% Spectrogram parameters
winLen = 1024;
overlap = 768;
nfft = 1024;

for i = 1:numel(speechNames)

    name = speechNames(i);

    fprintf('\n-----------------------------------\n');
    fprintf('Investigating: %s\n', name);
    fprintf('Noise: Kitchen\n');
    fprintf('-----------------------------------\n');

    % Match the recording from the saved results
    R = T(string(T.SpeechFile) == name + ".wav" & ...
        string(T.Noise) == noiseName, :);

    assert(height(R) == 1, ...
        'Matching result was not found.');

    % Input and output filenames
    baseName = name + "_" + noiseName + "_0dB";

    cleanFile = fullfile(cleanDir, ...
        baseName + "_clean.wav");

    noisyFile = fullfile(noisyDir, ...
        baseName + "_noisy.wav");

    enhancedFile = fullfile(enhancedDir, ...
        baseName + "_noisy_DeepFilterNet.wav");

    assert(isfile(cleanFile), ...
        'Clean recording not found.');

    assert(isfile(noisyFile), ...
        'Noisy recording not found.');

    assert(isfile(enhancedFile), ...
        'Enhanced recording not found.');

    % Load audio
    [clean, fs1] = audioread(cleanFile);
    [noisy, fs2] = audioread(noisyFile);
    [enhanced, fs3] = audioread(enhancedFile);

    assert(fs1 == 48000 && fs2 == fs1 && fs3 == fs1, ...
        'Sampling rate mismatch.');

    clean = double(clean(:));
    noisy = double(noisy(:));
    enhanced = double(enhanced(:));

    assert(numel(clean) == numel(noisy) && ...
        numel(clean) == numel(enhanced), ...
        'Audio lengths do not match.');

    assert(all(isfinite(enhanced)), ...
        'Invalid enhanced audio values.');

    fs = fs1;

    % Calculate SI-SDR improvements
    sisdrNoisy = pilot_sisdr(clean, noisy);
    sisdrDeep = pilot_sisdr(clean, enhanced);

    deltaSISDR = sisdrDeep - sisdrNoisy;

    % Calculate STOI improvements
    stoiNoisy = stoi(noisy, clean, fs);
    stoiDeep = stoi(enhanced, clean, fs);

    deltaSTOI = stoiDeep - stoiNoisy;

    % Check against the saved batch results
    assert(abs(deltaSISDR - ...
        R.SI_SDR_DeepFilterNet) < 0.05, ...
        'SI-SDR does not match the batch result.');

    assert(abs(deltaSTOI - ...
        R.STOI_DeepFilterNet) < 0.001, ...
        'STOI does not match the batch result.');

    fprintf('Overlap O: %.5f\n', R.OverlapO);
    fprintf('Variation V_N: %.5f\n', R.VariationVN);

    fprintf('\nSI-SDR improvement (dB):\n');
    fprintf('Spectral subtraction: %+.4f\n', R.SI_SDR_SS);
    fprintf('Wiener-type filtering: %+.4f\n', R.SI_SDR_Wiener);
    fprintf('DeepFilterNet:         %+.4f\n', deltaSISDR);

    fprintf('\nSTOI improvement:\n');
    fprintf('Spectral subtraction: %+.5f\n', R.STOI_SS);
    fprintf('Wiener-type filtering: %+.5f\n', R.STOI_Wiener);
    fprintf('DeepFilterNet:         %+.5f\n', deltaSTOI);

    % Calculate spectrograms using identical settings
    window = hamming(winLen, 'periodic');

    audioSignals = {clean, noisy, enhanced};

    signalLabels = {'Clean speech', ...
        'Noisy speech at 0 dB SNR', ...
        'DeepFilterNet enhanced speech'};

    spectrogramDB = cell(1,3);
    frequency = cell(1,3);
    time = cell(1,3);

    for j = 1:3

        [S, F, timeFrames] = spectrogram( ...
            audioSignals{j}, ...
            window, overlap, nfft, fs);

        spectrogramDB{j} = ...
            20 * log10(abs(S) + 1e-10);

        frequency{j} = F;
        time{j} = timeFrames;

    end

    % Use the same colour scale for all three spectrograms
    highestDB = max([ ...
        spectrogramDB{1}(:); ...
        spectrogramDB{2}(:); ...
        spectrogramDB{3}(:)]);

    colourLimits = [highestDB - 80, highestDB];

    % Plot comparison spectrograms
    f = figure('Color', 'w', ...
        'Position', [100 100 1100 1000]);

    tiledlayout(3,1, ...
        'TileSpacing', 'compact', ...
        'Padding', 'compact');

    for j = 1:3

        nexttile;

        imagesc(time{j}, frequency{j}/1000, ...
            spectrogramDB{j});

        axis xy;

        ylim([0 8]);
        clim(colourLimits);

        xlabel('Time (s)');
        ylabel('Frequency (kHz)');

        title(signalLabels{j});

        colorbar;
        set(gca, 'FontSize', 10);

    end

    sgtitle(sprintf( ...
        'Speech Enhancement Comparison - %s, Kitchen Noise', ...
        name));

    % Save the figure
    outputFile = fullfile(figureDir, ...
        name + "_spectrogram_comparison.png");

    exportgraphics(f, outputFile, 'Resolution', 300);

    % Optional audio listening
    if playAudio

        fprintf('\nPlaying clean speech...\n');
        sound(clean, fs);
        pause(numel(clean)/fs + 0.5);

        fprintf('Playing noisy speech...\n');
        sound(noisy, fs);
        pause(numel(noisy)/fs + 0.5);

        fprintf('Playing DeepFilterNet output...\n');
        sound(enhanced, fs);
        pause(numel(enhanced)/fs + 0.5);

    end

    fprintf('\nSpectrogram saved for %s.\n', name);

end

disp(' ');
disp('Failure-case investigation completed.');
