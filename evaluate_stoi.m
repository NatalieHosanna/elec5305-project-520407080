
% ELEC5305 - STOI evaluation
% Compare speech intelligibility before and after enhancement

clear;
clc;
close all;

projectDir = fileparts(fileparts(mfilename('fullpath')));
dataDir = fullfile(projectDir, 'data');
resultsDir = fullfile(projectDir, 'results');

% Load clean speech
[clean, fs] = audioread(fullfile(dataDir, 'speech', 'clean.wav'));

if size(clean, 2) > 1
    clean = mean(clean, 2);
end

clean = clean(:);

% Noise conditions
noiseFiles = {'white', 'stationary', 'traffic', 'public_space'};
noiseLabels = {'White', 'Kitchen', 'Traffic', 'Public space'};

nCases = numel(noiseFiles);

stoiNoisy = zeros(nCases, 1);
stoiSS = zeros(nCases, 1);
stoiWiener = zeros(nCases, 1);

% The same clean speech segment was used for all four mixtures
referenceOffset = [];

for i = 1:nCases

    noiseName = noiseFiles{i};

    % Load noisy and enhanced audio
    [noisy, fsNoisy] = audioread(fullfile(resultsDir, ...
        [noiseName '_noisy.wav']));

    [ss, fsSS] = audioread(fullfile(resultsDir, ...
        [noiseName '_spectral_subtraction.wav']));

    [wiener, fsWiener] = audioread(fullfile(resultsDir, ...
        [noiseName '_wiener.wav']));

    % Convert to mono
    if size(noisy, 2) > 1
        noisy = mean(noisy, 2);
    end

    if size(ss, 2) > 1
        ss = mean(ss, 2);
    end

    if size(wiener, 2) > 1
        wiener = mean(wiener, 2);
    end

    noisy = noisy(:);
    ss = ss(:);
    wiener = wiener(:);

    % Check sampling rates
    if any([fsNoisy, fsSS, fsWiener] ~= fs)
        error('Sampling rates do not match for %s.', noiseName);
    end

    % Check processed recording lengths
    lengths = [length(noisy), length(ss), length(wiener)];

    if max(lengths) - min(lengths) > round(0.01 * fs)
        error('Processed audio lengths do not match for %s.', ...
            noiseName);
    end

    N = min(lengths);

    noisy = noisy(1:N);
    ss = ss(1:N);
    wiener = wiener(1:N);

    if N > length(clean)
        error('Processed audio is longer than clean speech.');
    end

    % Find which part of the clean speech was used
    if isempty(referenceOffset)

        maxShift = length(clean) - N;

        % Find an approximate alignment using downsampled signals
        step = 16;

        cleanShort = clean(1:step:end);
        noisyShort = noisy(1:step:end);

        maxLag = ceil(maxShift / step);

        [r, lags] = xcorr(cleanShort, noisyShort, maxLag);

        valid = lags >= 0;

        validLags = lags(valid);
        validCorr = r(valid);

        [~, idx] = max(validCorr);

        coarseOffset = validLags(idx) * step;

        % Check nearby sample positions more accurately
        searchStart = max(0, coarseOffset - 2*step);
        searchEnd = min(maxShift, coarseOffset + 2*step);

        bestScore = -Inf;
        referenceOffset = 0;

        for offset = searchStart:searchEnd

            candidate = clean(offset + (1:N));

            score = sum(candidate .* noisy) / ...
                (sqrt(sum(candidate.^2) * sum(noisy.^2)) + eps);

            if score > bestScore
                bestScore = score;
                referenceOffset = offset;
            end

        end

        fprintf('\nEstimated clean speech start: %.4f seconds\n', ...
            referenceOffset / fs);

        fprintf('Alignment correlation: %.4f\n', bestScore);

        if bestScore < 0.3
            error(['Clean speech alignment could not be verified. ', ...
                'Check run_pilot.m before calculating STOI.']);
        end

    end

    % Use the matching clean speech segment
    if referenceOffset + N > length(clean)
        error('Clean speech segment is too short for %s.', noiseName);
    end

    reference = clean(referenceOffset + (1:N));

    % Check the alignment for each noise condition
    alignmentScore = sum(reference .* noisy) / ...
        (sqrt(sum(reference.^2) * sum(noisy.^2)) + eps);

    fprintf('\n%s:\n', noiseLabels{i});
    fprintf('Duration: %.3f seconds\n', N/fs);
    fprintf('Alignment correlation: %.4f\n', alignmentScore);

    if alignmentScore < 0.3
        error('Speech alignment could not be verified for %s.', ...
            noiseName);
    end

    % Calculate STOI
    stoiNoisy(i) = stoi(noisy, reference, fs);
    stoiSS(i) = stoi(ss, reference, fs);
    stoiWiener(i) = stoi(wiener, reference, fs);

    fprintf('Noisy STOI:  %.4f\n', stoiNoisy(i));
    fprintf('SS STOI:     %.4f\n', stoiSS(i));
    fprintf('Wiener STOI: %.4f\n', stoiWiener(i));

end

% Calculate STOI improvements
deltaSS = stoiSS - stoiNoisy;
deltaWiener = stoiWiener - stoiNoisy;

% Create results table
T = table(string(noiseLabels(:)), stoiNoisy, stoiSS, ...
    stoiWiener, deltaSS, deltaWiener, ...
    'VariableNames', {'Noise', 'STOI_Noisy', ...
    'STOI_SS', 'STOI_Wiener', ...
    'DeltaSTOI_SS', 'DeltaSTOI_Wiener'});

disp(' ');
disp('STOI Results:');
disp(T);

% Save the results
writetable(T, fullfile(resultsDir, 'stoi_results.csv'));

% Plot STOI improvement
figure('Color', 'w');

improvements = [deltaSS, deltaWiener];

bar(improvements, 'grouped');

xticks(1:nCases);
xticklabels(noiseLabels);

xlabel('Noise condition');
ylabel('STOI improvement');
title('Speech Intelligibility Improvement at 0 dB SNR');

legend('Spectral subtraction', 'Wiener filtering', ...
    'Location', 'best');

yline(0, 'k-');
grid on;

set(gca, 'FontSize', 11);

% Save the figure
exportgraphics(gcf, ...
    fullfile(resultsDir, 'stoi_improvement_summary.png'), ...
    'Resolution', 300);

disp('STOI evaluation completed.');
