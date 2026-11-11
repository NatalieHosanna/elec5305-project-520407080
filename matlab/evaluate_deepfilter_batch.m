
% ELEC5305 - DeepFilterNet batch evaluation
% Compare the three methods using the same 0 dB mixtures

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
outputDir = fullfile(resultsDir, 'deepfilter_batch_outputs');

% Load the original results and the batch manifest
manifest = readtable(fullfile(inputDir, 'batch_manifest.csv'));

originalFile = fullfile(resultsDir, 'extended_results.csv');

if ~isfile(originalFile)
    originalFile = fullfile(projectDir, ...
        'results', 'extended_results.csv');
end

T = readtable(originalFile);

% Check the expected dataset
assert(height(manifest) == 160, ...
    'Expected 160 entries in the manifest.');

assert(height(T) == 640, ...
    'Expected 640 original experiment rows.');

assert(all(manifest.SNR_dB == 0), ...
    'This evaluation is for the 0 dB batch.');

files = dir(fullfile(outputDir, '*_DeepFilterNet.wav'));

assert(numel(files) == 160, ...
    'Expected 160 DeepFilterNet output recordings.');

assert(exist('stoi', 'file') == 2, ...
    'MATLAB STOI function was not found.');

% Store the results
results = table();

for i = 1:height(manifest)

    speechFile = string(manifest.SpeechFile(i));
    noise = string(manifest.Noise(i));

    % Find the matching original MATLAB result
    row = T( ...
        string(T.SpeechFile) == speechFile & ...
        string(T.Noise) == noise & ...
        T.TargetSNR_dB == 0, :);

    assert(height(row) == 1, ...
        'Could not find the matching original result.');

    % Audio filenames
    cleanFile = fullfile(cleanDir, ...
        string(manifest.CleanFile(i)));

    noisyName = string(manifest.NoisyFile(i));
    noisyFile = fullfile(noisyDir, noisyName);

    enhancedName = replace(noisyName, ...
        '.wav', '_DeepFilterNet.wav');

    enhancedFile = fullfile(outputDir, enhancedName);

    assert(isfile(cleanFile) && isfile(noisyFile) ...
        && isfile(enhancedFile), ...
        'Missing audio file for recording %d.', i);

    % Load audio
    [clean, fs1] = audioread(cleanFile);
    [noisy, fs2] = audioread(noisyFile);
    [enhanced, fs3] = audioread(enhancedFile);

    assert(fs1 == 48000 && fs2 == fs1 && fs3 == fs1, ...
        'Sampling rate mismatch.');

    assert(size(clean,2) == 1 && ...
        size(noisy,2) == 1 && ...
        size(enhanced,2) == 1, ...
        'Expected mono audio.');

    clean = double(clean(:));
    noisy = double(noisy(:));
    enhanced = double(enhanced(:));

    assert(all(isfinite(enhanced)) && ...
        any(abs(enhanced) > 1e-8), ...
        'Enhanced audio is invalid or silent.');

    % Confirm the noisy baseline matches the original study
    assert(numel(clean) == numel(noisy), ...
        'Clean and noisy audio lengths differ.');

    baselineSISDR = pilot_sisdr(clean, noisy);
    baselineSTOI = stoi(noisy, clean, fs1);

    assert(abs(baselineSISDR - ...
        row.SI_SDR_Noisy_dB) < 0.05, ...
        'Noisy SI-SDR differs from the original study.');

    assert(abs(baselineSTOI - row.STOI_Noisy) < 0.005, ...
        'Noisy STOI differs from the original study.');

    % Check output duration
    lengths = [numel(clean), numel(noisy), numel(enhanced)];

    assert((max(lengths)-min(lengths))/fs1 < 0.05, ...
        'Audio duration mismatch exceeds 50 ms.');

    N = min(lengths);

    clean = clean(1:N);
    noisy = noisy(1:N);
    enhanced = enhanced(1:N);

    % Estimate processing delay
    maxLag = round(0.03 * fs1);

    [c, lags] = xcorr(enhanced, clean, maxLag, 'coeff');
    [~, peakIndex] = max(abs(c));

    lag = lags(peakIndex);
    lagMs = 1000 * lag / fs1;

    assert(abs(lagMs) <= 20, ...
        'Unexpected alignment delay: %.3f ms.', lagMs);

    % Align recordings if necessary
    if lag > 0

        clean = clean(1:end-lag);
        noisy = noisy(1:end-lag);
        enhanced = enhanced(1+lag:end);

    elseif lag < 0

        shift = -lag;

        clean = clean(1+shift:end);
        noisy = noisy(1+shift:end);
        enhanced = enhanced(1:end-shift);

    end

    % Evaluate DeepFilterNet
    sisdrNoisy = pilot_sisdr(clean, noisy);
    sisdrDeep = pilot_sisdr(clean, enhanced);

    stoiNoisy = stoi(noisy, clean, fs1);
    stoiDeep = stoi(enhanced, clean, fs1);

    deltaSISDR = sisdrDeep - sisdrNoisy;
    deltaSTOI = stoiDeep - stoiNoisy;

    % Combine with the original classical results
    newRow = table( ...
        speechFile, noise, string(row.Speaker), ...
        row.OverlapO, row.VariationVN, ...
        row.DeltaSI_SDR_SS_dB, ...
        row.DeltaSI_SDR_Wiener_dB, ...
        deltaSISDR, ...
        row.DeltaSTOI_SS, ...
        row.DeltaSTOI_Wiener, ...
        deltaSTOI, lagMs, ...
        'VariableNames', { ...
        'SpeechFile', 'Noise', 'Speaker', ...
        'OverlapO', 'VariationVN', ...
        'SI_SDR_SS', 'SI_SDR_Wiener', ...
        'SI_SDR_DeepFilterNet', ...
        'STOI_SS', 'STOI_Wiener', ...
        'STOI_DeepFilterNet', 'AlignmentLag_ms'});

    results = [results; newRow];

    if mod(i, 10) == 0
        fprintf('Evaluated %d/160 recordings.\n', i);
    end

end

% Save results only after all recordings pass validation
assert(height(results) == 160, ...
    'Evaluation did not complete.');

writetable(results, fullfile(resultsDir, ...
    'deepfilter_batch_metrics.csv'));

% Calculate mean and standard deviation for each noise
metrics = {'SI_SDR_SS', 'SI_SDR_Wiener', ...
    'SI_SDR_DeepFilterNet', ...
    'STOI_SS', 'STOI_Wiener', ...
    'STOI_DeepFilterNet'};

summary = groupsummary(results, 'Noise', ...
    {'mean', 'std'}, metrics);

writetable(summary, fullfile(resultsDir, ...
    'deepfilter_batch_summary.csv'));

disp(' ');
disp('DeepFilterNet batch summary:');
disp(summary);

fprintf('\nEvaluated %d matched mixtures.\n', ...
    height(results));

disp('DeepFilterNet evaluation completed.');
