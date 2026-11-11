% ELEC5305 - DeepFilterNet evaluation
% Evaluate the four 0 dB test recordings

clear;
clc;
close all;

% Project folders
projectDir = fileparts(fileparts(mfilename('fullpath')));

resultsDir = fullfile(projectDir, 'results', 'extended');
inputDir = fullfile(resultsDir, 'deepfilter_inputs');
outputDir = fullfile(resultsDir, 'deepfilter_outputs');

% Load results from the expanded MATLAB experiment
csvFile = fullfile(resultsDir, 'extended_results.csv');

if ~isfile(csvFile)
    csvFile = fullfile(projectDir, ...
        'results', 'extended_results.csv');
end

T = readtable(csvFile);

% Check that the MATLAB STOI function is available
assert(exist('stoi', 'file') == 2, ...
    'MATLAB stoi function was not found.');

noiseNames = ["white", "stationary", ...
    "traffic", "public_space"];

noiseLabels = ["White", "Kitchen", ...
    "Traffic", "Public space"];

% Store the measurements
results = table();

for i = 1:numel(noiseNames)

    noise = noiseNames(i);

    % Find the clean, noisy and enhanced recordings
    baseName = "p232_010_" + noise + "_0dB";

    cleanFile = fullfile(inputDir, ...
        baseName + "_clean.wav");

    noisyFile = fullfile(inputDir, ...
        baseName + "_noisy.wav");

    enhancedFile = fullfile(outputDir, ...
        baseName + "_noisy_DeepFilterNet.wav");

    assert(isfile(cleanFile), ...
        'Missing clean recording: %s', cleanFile);

    assert(isfile(noisyFile), ...
        'Missing noisy recording: %s', noisyFile);

    assert(isfile(enhancedFile), ...
        'Missing DeepFilterNet output: %s', enhancedFile);

    % Load audio
    [clean, fsClean] = audioread(cleanFile);
    [noisy, fsNoisy] = audioread(noisyFile);
    [enhanced, fsEnhanced] = audioread(enhancedFile);

    assert(fsClean == fsNoisy && ...
        fsNoisy == fsEnhanced, ...
        'Sampling rates do not match.');

    assert(fsClean == 48000, ...
        'Expected 48 kHz recordings.');

    assert(size(clean,2) == 1 && ...
        size(noisy,2) == 1 && ...
        size(enhanced,2) == 1, ...
        'Expected mono audio.');

    fs = fsClean;

    clean = double(clean(:));
    noisy = double(noisy(:));
    enhanced = double(enhanced(:));

    % Check for large duration differences
    lengths = [numel(clean), numel(noisy), ...
        numel(enhanced)];

    durationDifference = ...
        (max(lengths) - min(lengths)) / fs;

    assert(durationDifference < 0.05, ...
        'Audio duration difference exceeds 50 ms.');

    N = min(lengths);

    clean = clean(1:N);
    noisy = noisy(1:N);
    enhanced = enhanced(1:N);

    % Check whether the clean/noisy pair matches
    % the previously calculated MATLAB results
    originalRow = T( ...
        string(T.SpeechFile) == "p232_010.wav" & ...
        string(T.Noise) == noise & ...
        T.TargetSNR_dB == 0, :);

    assert(height(originalRow) == 1, ...
        'Matching expanded-study result not found.');

    % Check the original noisy reference
    originalSISDR = calculateSISDR(clean, noisy);

    % MATLAB stoi uses processed audio first
    originalSTOI = stoi(noisy, clean, fs);

    assert(abs(originalSISDR - ...
        originalRow.SI_SDR_Noisy_dB) < 0.05, ...
        'Noisy SI-SDR does not match the expanded study.');

    assert(abs(originalSTOI - ...
        originalRow.STOI_Noisy) < 0.01, ...
        'Noisy STOI does not match the expanded study.');

    % Estimate the output delay using the noisy input
    maxLag = round(0.05 * fs);

    [c, lags] = xcorr( ...
        enhanced, noisy, maxLag, 'coeff');

    [~, peakIndex] = max(abs(c));

    lag = lags(peakIndex);
    lagMs = 1000 * lag / fs;

    % Align all recordings using the estimated delay
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

    % SI-SDR evaluation on the same sample interval
    sisdrNoisy = calculateSISDR( ...
        cleanEval, noisyEval);

    sisdrEnhanced = calculateSISDR( ...
        cleanEval, enhancedEval);

    deltaSISDR = sisdrEnhanced - sisdrNoisy;

    % STOI evaluation
    stoiNoisy = stoi(noisyEval, cleanEval, fs);

    stoiEnhanced = stoi( ...
        enhancedEval, cleanEval, fs);

    deltaSTOI = stoiEnhanced - stoiNoisy;

    % Save measurements
    newRow = table( ...
        noiseLabels(i), fs, ...
        numel(cleanEval)/fs, lagMs, ...
        sisdrNoisy, sisdrEnhanced, deltaSISDR, ...
        stoiNoisy, stoiEnhanced, deltaSTOI, ...
        'VariableNames', { ...
        'Noise', 'SampleRate_Hz', ...
        'Duration_s', 'AlignmentLag_ms', ...
        'SI_SDR_Noisy_dB', ...
        'SI_SDR_DeepFilterNet_dB', ...
        'DeltaSI_SDR_DeepFilterNet_dB', ...
        'STOI_Noisy', ...
        'STOI_DeepFilterNet', ...
        'DeltaSTOI_DeepFilterNet'});

    results = [results; newRow];

    fprintf('\n%s\n', noiseLabels(i));
    fprintf('Sampling rate: %d Hz\n', fs);
    fprintf('Alignment lag: %.3f ms\n', lagMs);
    fprintf('SI-SDR improvement: %+.4f dB\n', deltaSISDR);
    fprintf('STOI improvement: %+.5f\n', deltaSTOI);

end

% Save results without changing the original experiment
outputCSV = fullfile(resultsDir, ...
    'deepfilter_test_metrics.csv');

writetable(results, outputCSV);

disp(' ');
disp('DeepFilterNet evaluation results:');
disp(results);

fprintf('\nSaved results to:\n%s\n', outputCSV);

% SI-SDR calculation
function value = calculateSISDR(reference, estimate)

    reference = double(reference(:));
    estimate = double(estimate(:));

    assert(numel(reference) == numel(estimate), ...
        'SI-SDR requires matching audio lengths.');

    % Remove DC offsets
    reference = reference - mean(reference);
    estimate = estimate - mean(estimate);

    % Project the estimate onto the reference
    projection = ...
        (reference' * estimate) / ...
        (reference' * reference + eps);

    target = projection * reference;

    errorSignal = estimate - target;

    value = 10 * log10( ...
        (sum(target.^2) + eps) / ...
        (sum(errorSignal.^2) + eps));

end
