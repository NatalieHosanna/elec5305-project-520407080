
% ELEC5305 - DeepFilterNet evaluation across four SNR levels
% Compare the pretrained model with the original MATLAB results

clear;
clc;
close all;

projectDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectDir, 'matlab'));

resultsDir = fullfile(projectDir, 'results', 'extended');
inputDir = fullfile(resultsDir, 'deepfilter_batch_inputs');

cleanDir = fullfile(inputDir, 'clean');
noisyDir = fullfile(inputDir, 'noisy');
enhancedDir = fullfile(resultsDir, 'deepfilter_batch_outputs');

% Load the mixture manifest
manifest = readtable(fullfile(inputDir, 'batch_manifest.csv'));

originalFile = fullfile(resultsDir, 'extended_results.csv');

if ~isfile(originalFile)
    originalFile = fullfile(projectDir, ...
        'results', 'extended_results.csv');
end

T = readtable(originalFile);

% Check the experiment
assert(height(manifest) == 640, ...
    'Expected 640 mixture entries.');

assert(height(T) == 640, ...
    'Expected 640 original experiment results.');

assert(numel(unique(string(manifest.SpeechFile))) == 40, ...
    'Expected 40 speech recordings.');

assert(numel(unique(string(manifest.Noise))) == 4, ...
    'Expected four noise conditions.');

assert(isequal(sort(unique(manifest.SNR_dB)), ...
    [-5; 0; 5; 10]), ...
    'Expected SNR levels -5, 0, 5 and 10 dB.');

files = dir(fullfile(enhancedDir, ...
    '*_DeepFilterNet.wav'));

assert(numel(files) == 640, ...
    'Expected 640 DeepFilterNet output files.');

assert(exist('stoi', 'file') == 2, ...
    'MATLAB STOI function not found.');

assert(exist('pilot_sisdr', 'file') == 2, ...
    'pilot_sisdr.m not found.');

% Load the previous 0 dB evaluation
oldFile = fullfile(resultsDir, ...
    'deepfilter_batch_metrics.csv');

if isfile(oldFile)
    oldResults = readtable(oldFile);
    assert(height(oldResults) == 160, ...
        'Expected 160 previous 0 dB results.');
else
    oldResults = table();
    warning('Previous 0 dB results not found.');
end

results = table();

% ============================================
% EVALUATE ALL MIXTURES
% ============================================

for i = 1:height(manifest)

    speechFile = string(manifest.SpeechFile(i));
    noise = string(manifest.Noise(i));
    snrDB = manifest.SNR_dB(i);

    % Find the matching original MATLAB result
    originalRow = T( ...
        string(T.SpeechFile) == speechFile & ...
        string(T.Noise) == noise & ...
        T.TargetSNR_dB == snrDB, :);

    assert(height(originalRow) == 1, ...
        'Original result missing for row %d.', i);

    % Find the matching audio recordings
    cleanFile = fullfile(cleanDir, ...
        string(manifest.CleanFile(i)));

    noisyName = string(manifest.NoisyFile(i));

    noisyFile = fullfile(noisyDir, noisyName);

    enhancedName = replace(noisyName, ...
        '.wav', '_DeepFilterNet.wav');

    enhancedFile = fullfile(enhancedDir, enhancedName);

    assert(isfile(cleanFile) && ...
        isfile(noisyFile) && isfile(enhancedFile), ...
        'Missing WAV file for row %d.', i);

    % Load audio
    [clean, fs1] = audioread(cleanFile);
    [noisy, fs2] = audioread(noisyFile);
    [enhanced, fs3] = audioread(enhancedFile);

    assert(fs1 == 48000 && fs2 == fs1 && fs3 == fs1, ...
        'Sampling rate mismatch for row %d.', i);

    assert(size(clean,2) == 1 && ...
        size(noisy,2) == 1 && ...
        size(enhanced,2) == 1, ...
        'Expected mono audio for row %d.', i);

    clean = double(clean(:));
    noisy = double(noisy(:));
    enhanced = double(enhanced(:));

    assert(numel(clean) == numel(noisy), ...
        'Clean and noisy lengths differ.');

    assert(all(isfinite(clean)) && ...
        all(isfinite(noisy)) && ...
        all(isfinite(enhanced)) && ...
        any(abs(enhanced) > 1e-8), ...
        'Invalid audio values for row %d.', i);

    lengthDifference = ...
        abs(numel(enhanced) - numel(clean)) / fs1;

    assert(lengthDifference < 0.05, ...
        'Audio duration mismatch for row %d.', i);

    % Verify the SNR of the saved mixture
    actualNoise = noisy - clean;

    measuredSNR = 10 * log10( ...
        sum(clean.^2) / sum(actualNoise.^2));

    assert(abs(measuredSNR - snrDB) < 0.02, ...
        'Input SNR mismatch for row %d.', i);

    % Check the noisy baseline against the original study
    baselineSISDR = pilot_sisdr(clean, noisy);
    baselineSTOI = stoi(noisy, clean, fs1);

    assert(abs(baselineSISDR - ...
        originalRow.SI_SDR_Noisy_dB) < 0.05, ...
        'Noisy SI-SDR mismatch for row %d.', i);

    assert(abs(baselineSTOI - ...
        originalRow.STOI_Noisy) < 0.005, ...
        'Noisy STOI mismatch for row %d.', i);

    % ========================================
    % AUDIO ALIGNMENT
    % ========================================

    N = min([numel(clean), numel(enhanced)]);

    clean = clean(1:N);
    noisy = noisy(1:N);
    enhanced = enhanced(1:N);

    maxLag = round(0.03 * fs1);

    [c, lags] = xcorr( ...
        enhanced, clean, maxLag, 'coeff');

    [~, peakIndex] = max(abs(c));

    lag = lags(peakIndex);
    lagMs = 1000 * lag / fs1;

    assert(abs(lagMs) <= 20, ...
        'Unexpected delay for row %d.', i);

    if lag > 0

        cleanEval = clean(1:end-lag);
        noisyEval = noisy(1:end-lag);
        enhancedEval = enhanced(1+lag:end);

    elseif lag < 0

        shift = -lag;

        cleanEval = clean(1+shift:end);
        noisyEval = noisy(1+shift:end);
        enhancedEval = enhanced(1:end-shift);

    else

        cleanEval = clean;
        noisyEval = noisy;
        enhancedEval = enhanced;

    end

    % ========================================
    % SI-SDR AND STOI
    % ========================================

    sisdrNoisy = pilot_sisdr(cleanEval, noisyEval);
    sisdrDeep = pilot_sisdr(cleanEval, enhancedEval);

    stoiNoisy = stoi(noisyEval, cleanEval, fs1);
    stoiDeep = stoi(enhancedEval, cleanEval, fs1);

    deltaSISDR = sisdrDeep - sisdrNoisy;
    deltaSTOI = stoiDeep - stoiNoisy;

    % Confirm the previous 0 dB results are unchanged
    if snrDB == 0 && ~isempty(oldResults)

        oldRow = oldResults( ...
            string(oldResults.SpeechFile) == speechFile & ...
            string(oldResults.Noise) == noise, :);

        assert(height(oldRow) == 1, ...
            'Previous 0 dB result missing.');

        assert(abs(deltaSISDR - ...
            oldRow.SI_SDR_DeepFilterNet) < 0.05, ...
            '0 dB SI-SDR result changed for row %d.', i);

        assert(abs(deltaSTOI - ...
            oldRow.STOI_DeepFilterNet) < 0.005, ...
            '0 dB STOI result changed for row %d.', i);

    end

    % Store the classical and DeepFilterNet measurements
    newRow = table( ...
        speechFile, string(originalRow.Speaker), ...
        noise, snrDB, ...
        originalRow.OverlapO, ...
        originalRow.VariationVN, ...
        originalRow.DeltaSI_SDR_SS_dB, ...
        originalRow.DeltaSI_SDR_Wiener_dB, ...
        deltaSISDR, ...
        originalRow.DeltaSTOI_SS, ...
        originalRow.DeltaSTOI_Wiener, ...
        deltaSTOI, ...
        measuredSNR, lagMs, ...
        'VariableNames', { ...
        'SpeechFile', 'Speaker', 'Noise', 'SNR_dB', ...
        'OverlapO', 'VariationVN', ...
        'SI_SDR_SS', 'SI_SDR_Wiener', ...
        'SI_SDR_DeepFilterNet', ...
        'STOI_SS', 'STOI_Wiener', ...
        'STOI_DeepFilterNet', ...
        'MeasuredSNR_dB', 'AlignmentLag_ms'});

    results = [results; newRow];

    if mod(i, 40) == 0
        fprintf('Evaluated %d/640 mixtures.\n', i);
    end

end

% ============================================
% SAVE RESULTS
% ============================================

assert(height(results) == 640, ...
    'Expected 640 completed results.');

metricCols = { ...
    'SI_SDR_SS', 'SI_SDR_Wiener', ...
    'SI_SDR_DeepFilterNet', ...
    'STOI_SS', 'STOI_Wiener', ...
    'STOI_DeepFilterNet'};

% Mean and standard deviation by SNR and noise
summary = groupsummary( ...
    results, {'SNR_dB', 'Noise'}, ...
    {'mean', 'std'}, metricCols);

assert(height(summary) == 16 && ...
    all(summary.GroupCount == 40), ...
    'Expected 16 groups with 40 recordings each.');

% Separate summary for each speaker
speakerSummary = groupsummary( ...
    results, {'SNR_dB', 'Noise', 'Speaker'}, ...
    {'mean', 'std'}, metricCols);

% Save using new filenames
writetable(results, fullfile(resultsDir, ...
    'deepfilter_all_snr_metrics.csv'));

writetable(summary, fullfile(resultsDir, ...
    'deepfilter_all_snr_summary.csv'));

writetable(speakerSummary, fullfile(resultsDir, ...
    'deepfilter_all_snr_speaker_summary.csv'));

disp(' ');
fprintf('Evaluated %d matched mixtures.\n', ...
    height(results));

fprintf('Summary groups: %d.\n', ...
    height(summary));

fprintf('Maximum absolute alignment delay: %.3f ms.\n', ...
    max(abs(results.AlignmentLag_ms)));

disp('Full-SNR evaluation completed.');
disp(summary);
