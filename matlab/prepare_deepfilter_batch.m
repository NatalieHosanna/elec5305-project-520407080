
% ELEC5305 - Prepare matched DeepFilterNet batch
% Re-create mixtures from the expanded MATLAB experiment

clear;
clc;

projectDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectDir, 'matlab'));

speechDir = fullfile(projectDir, 'data', 'speech_batch');
noiseDir = fullfile(projectDir, 'data', 'noise');
resultsDir = fullfile(projectDir, 'results', 'extended');

inputDir = fullfile(resultsDir, 'deepfilter_batch_inputs');
noisyDir = fullfile(inputDir, 'noisy');
cleanDir = fullfile(inputDir, 'clean');

if ~isfolder(noisyDir), mkdir(noisyDir); end
if ~isfolder(cleanDir), mkdir(cleanDir); end

csvFile = fullfile(resultsDir, 'extended_results.csv');
if ~isfile(csvFile)
    csvFile = fullfile(projectDir, ...
        'results', 'extended_results.csv');
end

T = readtable(csvFile);

fsTarget = 48000;
winLen = 1024;
hop = 256;
nfft = 1024;

% Start with 2 recordings at 0 dB.
% Later change maxFiles to 40.

maxFiles = 40;
snrLevels = [-5, 0, 5, 10];

noiseNames = {'white', 'stationary', ...
    'traffic', 'public_space'};

% Use the same sorted file order as the expanded study
files = dir(fullfile(speechDir, '*.wav'));
[~, order] = sort({files.name});
files = files(order);

assert(numel(files) >= maxFiles, ...
    'Not enough clean speech recordings.');

manifest = table();

for i = 1:maxFiles

    speechFile = files(i).name;
    [~, stem] = fileparts(speechFile);

    [raw, fsIn] = audioread( ...
        fullfile(speechDir, speechFile));

    s = convert_audio(raw, fsIn, fsTarget);
    s = s(:) - mean(s(:));

    % Match the original speech trimming
    idx = find(abs(s) > 0.02 * max(abs(s)));

    assert(~isempty(idx), 'Clean speech is silent.');

    startIdx = max(1, ...
        idx(1) - round(0.1 * fsTarget));

    endIdx = min(numel(s), ...
        idx(end) + round(0.1 * fsTarget));

    s = s(startIdx:endIdx);
    s = s / max(max(abs(s)), eps) * 0.5;

    [S, ~] = pilot_stft(s, winLen, hop, nfft);
    Ps = abs(S).^2;

    for q = 1:numel(noiseNames)

        label = noiseNames{q};

        % Reconstruct the original noise segment
        if strcmp(label, 'white')

            rng(5305 + 1000*i + q, 'twister');
            n = randn(size(s));

        else

            source = fullfile(noiseDir, ...
                [label '.wav']);

            info = audioinfo(source);
            assert(info.SampleRate == fsTarget, ...
                'Noise sampling rate must be 48 kHz.');

            referenceRow = T( ...
                string(T.SpeechFile) == speechFile & ...
                string(T.Noise) == label & ...
                T.TargetSNR_dB == 0, :);

            assert(height(referenceRow) == 1, ...
                'Missing noise segment information.');

            noiseStart = round( ...
                referenceRow.NoiseStartSample);

            segment = audioread(source, ...
                [noiseStart, noiseStart + numel(s) - 1]);

            n = mean(double(segment), 2);

        end

        n = n(:) - mean(n(:));

        for snrDB = snrLevels

            row = T( ...
                string(T.SpeechFile) == speechFile & ...
                string(T.Noise) == label & ...
                T.TargetSNR_dB == snrDB, :);

            assert(height(row) == 1, ...
                'Missing original experiment result.');

            % Generate the controlled mixture
            alpha = sqrt(sum(s.^2) / ...
                (sum(n.^2) * 10^(snrDB/10)));

            scaledN = alpha * n;
            x = s + scaledN;

            measuredSNR = 10 * log10( ...
                sum(s.^2) / sum(scaledN.^2));

            % Check the acoustic measures
            [N, ~] = pilot_stft( ...
                scaledN, winLen, hop, nfft);

            Pn = abs(N).^2;

            overlapO = sum(min(Ps(:), Pn(:))) / ...
                (sum(Ps(:)) + eps);

            normNoise = Pn ./ (sum(Pn,1) + eps);

            variationVN = mean(sqrt(sum( ...
                diff(normNoise,1,2).^2, 1)));

            assert(abs(measuredSNR - ...
                row.MeasuredSNR_dB) < 1e-8, ...
                'SNR does not match.');

            assert(abs(overlapO - ...
                row.OverlapO) < 1e-8, ...
                'Overlap does not match.');

            assert(abs(variationVN - ...
                row.VariationVN) < 1e-8, ...
                'Noise variation does not match.');

            % Use the same scaling for clean and noisy audio
            commonScale = max([1; abs(s(:)); abs(x(:))]);

            baseName = sprintf('%s_%s_%gdB', ...
                stem, label, snrDB);

            noisyName = [baseName '_noisy.wav'];
            cleanName = [baseName '_clean.wav'];

            audiowrite(fullfile(noisyDir, noisyName), ...
                x/commonScale, fsTarget, ...
                'BitsPerSample', 32);

            audiowrite(fullfile(cleanDir, cleanName), ...
                s/commonScale, fsTarget, ...
                'BitsPerSample', 32);

            newRow = table( ...
                string(speechFile), string(label), ...
                snrDB, string(noisyName), ...
                string(cleanName), measuredSNR, ...
                overlapO, variationVN, commonScale, ...
                'VariableNames', { ...
                'SpeechFile', 'Noise', 'SNR_dB', ...
                'NoisyFile', 'CleanFile', ...
                'MeasuredSNR_dB', ...
                'OverlapO', 'VariationVN', ...
                'CommonScale'});

            manifest = [manifest; newRow];

        end
    end

    fprintf('Prepared %d/%d: %s\n', ...
        i, maxFiles, speechFile);

end

writetable(manifest, ...
    fullfile(inputDir, 'batch_manifest.csv'));

fprintf('\nValidated %d matched mixtures.\n', ...
    height(manifest));

disp('DeepFilterNet batch inputs prepared.');
