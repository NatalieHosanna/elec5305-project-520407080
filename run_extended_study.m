% ELEC5305 - Expanded controlled experiment
% Runs the original pilot methods on several clean speech recordings.
% The current noise-power estimate uses the known separate noise signal.
% Results are saved separately and do not replace the original pilot.

clear; clc; close all;

projectDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectDir, 'matlab'));
speechDir = fullfile(projectDir, 'data', 'speech_batch');
noiseDir = fullfile(projectDir, 'data', 'noise');
outDir = fullfile(projectDir, 'results', 'extended');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% Change to true for a quick check using four utterances.
smokeTest = false;

fsTarget = 48000;
snrLevels = [-5 0 5 10];
noiseNames = {'white','stationary','traffic','public_space'};
winLen = 1024;
hop = 256;
nfft = 1024;
seed = 5305;
minGain = 0.05;
beta = 1.0;

for k = 1:numel(noiseNames)
    if ~strcmp(noiseNames{k}, 'white')
        f = fullfile(noiseDir, [noiseNames{k} '.wav']);
        if ~isfile(f), error('Missing noise recording: %s', f); end
    end
end

files = dir(fullfile(speechDir, '*.wav'));
if isempty(files)
    error('No speech WAVs in %s. Copy the supplied speech_batch files there.', speechDir);
end
[~, order] = sort({files.name});
files = files(order);
if smokeTest
    files = files(unique(round(linspace(1, numel(files), min(4,numel(files))))));
    outputName = 'extended_results_smoke.csv';
else
    outputName = 'extended_results.csv';
end

% Open the environmental files once to record their sampling rates and lengths.
noiseInfo = cell(1, numel(noiseNames));
for q = 2:numel(noiseNames)
    info = audioinfo(fullfile(noiseDir, [noiseNames{q} '.wav']));
    if info.SampleRate ~= fsTarget
        error('%s.wav must be 48 kHz for this study.', noiseNames{q});
    end
    noiseInfo{q} = info;
end

names = {'SpeechFile','Speaker','Noise','TargetSNR_dB','MeasuredSNR_dB', ...
    'NoiseStartSample','OverlapO','VariationVN','SI_SDR_Noisy_dB', ...
    'SI_SDR_SS_dB','SI_SDR_Wiener_dB','STOI_Noisy', ...
    'STOI_SS','STOI_Wiener','DeltaSI_SDR_SS_dB', ...
    'DeltaSI_SDR_Wiener_dB','DeltaSTOI_SS','DeltaSTOI_Wiener'};
maxRows = numel(files) * numel(noiseNames) * numel(snrLevels);
variableTypes = [{'string','string','string'}, repmat({'double'},1,numel(names)-3)];
T = table('Size',[maxRows,numel(names)], ...
    'VariableTypes',variableTypes,'VariableNames',names);
rowCount = 0;

for i = 1:numel(files)
    speechFile = files(i).name;
    [raw, fsIn] = audioread(fullfile(speechDir, speechFile));
    s = convert_audio(raw, fsIn, fsTarget);
    s = s(:) - mean(s(:));

    % Use the same trimming and level setting as run_pilot.m.
    idx = find(abs(s) > 0.02 * max(abs(s)));
    if isempty(idx)
        warning('Skipping silent recording %s.', speechFile);
        continue;
    end
    startIdx = max(1, idx(1) - round(0.1 * fsTarget));
    endIdx = min(numel(s), idx(end) + round(0.1 * fsTarget));
    s = s(startIdx:endIdx);
    s = s / max(max(abs(s)), eps) * 0.5;
    if numel(s) < round(1.0 * fsTarget)
        warning('Skipping short recording %s.', speechFile);
        continue;
    end

    [S, pad] = pilot_stft(s, winLen, hop, nfft);
    check = pilot_istft(S, winLen, hop, nfft, pad);
    reconstructionError = norm(s-check) / max(norm(s), eps);
    if reconstructionError > 1e-8
        error('STFT reconstruction failed for %s: %.3g', speechFile, reconstructionError);
    end
    Ps = abs(S).^2;
    underscore = strfind(speechFile, '_');
    if isempty(underscore)
        speaker = string(erase(speechFile, '.wav'));
    else
        speaker = string(speechFile(1:underscore(1)-1));
    end

    for q = 1:numel(noiseNames)
        noiseName = noiseNames{q};

        % Choose one repeatable noise segment per utterance and environment.
        % It stays fixed across SNR levels, so the SNR comparison is paired.
        rng(seed + 1000*i + q, 'twister');
        if strcmp(noiseName, 'white')
            n = randn(size(s));
            noiseStart = 0;
        else
            info = noiseInfo{q};
            if info.TotalSamples < numel(s)
                error('%s.wav is shorter than %s.', noiseName, speechFile);
            end
            noiseStart = randi(info.TotalSamples - numel(s) + 1);
            source = fullfile(noiseDir, [noiseName '.wav']);
            segment = audioread(source, [noiseStart, noiseStart + numel(s) - 1]);
            n = mean(double(segment), 2);
        end
        n = n(:) - mean(n(:));
        if sum(n.^2) == 0, error('Silent noise segment for %s.', noiseName); end

        for j = 1:numel(snrLevels)
            snrDB = snrLevels(j);
            alpha = sqrt(sum(s.^2)/(sum(n.^2)*10^(snrDB/10)));
            scaledN = alpha * n;
            x = s + scaledN;
            measured = 10*log10(sum(s.^2)/sum(scaledN.^2));

            [N, ~] = pilot_stft(scaledN, winLen, hop, nfft);
            [X, ~] = pilot_stft(x, winLen, hop, nfft);
            Pn = abs(N).^2;
            Px = abs(X).^2;

            % These are experimental descriptors, not universal difficulty scores.
            overlapO = sum(min(Ps(:), Pn(:))) / (sum(Ps(:)) + eps);
            normNoise = Pn ./ (sum(Pn, 1) + eps);
            changes = diff(normNoise, 1, 2);
            variationVN = mean(sqrt(sum(changes.^2, 1)));

            % Reference-assisted average noise PSD: same assumption as pilot.
            noisePSD = mean(Pn, 2);
            gainSS = sqrt(max(Px-beta*noisePSD, minGain^2*Px) ./ (Px+eps));
            estSpeechPSD = max(Px-noisePSD, 0);
            gainWiener = max(estSpeechPSD ./ (estSpeechPSD+noisePSD+eps), minGain);
            ySS = pilot_istft(gainSS.*X, winLen, hop, nfft, pad);
            yWiener = pilot_istft(gainWiener.*X, winLen, hop, nfft, pad);

            % Evaluate the full-precision, sample-aligned signals.
            sisdrNoisy = pilot_sisdr(s, x);
            sisdrSS = pilot_sisdr(s, ySS);
            sisdrWiener = pilot_sisdr(s, yWiener);
            stoiNoisy = stoi(x, s, fsTarget);
            stoiSS = stoi(ySS, s, fsTarget);
            stoiWiener = stoi(yWiener, s, fsTarget);

            rowCount = rowCount + 1;
            T(rowCount,:) = {string(speechFile), speaker, string(noiseName), ...
                snrDB, measured, noiseStart, overlapO, variationVN, ...
                sisdrNoisy, sisdrSS, sisdrWiener, ...
                stoiNoisy, stoiSS, stoiWiener, ...
                sisdrSS-sisdrNoisy, sisdrWiener-sisdrNoisy, ...
                stoiSS-stoiNoisy, stoiWiener-stoiNoisy};

            % Save one illustrative example for each noise type at 0 dB SNR.
            if i == 1 && snrDB == 0
                examplesDir = fullfile(outDir, 'examples');
                if ~exist(examplesDir, 'dir'), mkdir(examplesDir); end
                commonScale = max(1, max(abs([x; ySS; yWiener; s])));
                audiowrite(fullfile(examplesDir, [noiseName '_clean.wav']), ...
                    s/commonScale, fsTarget);
                audiowrite(fullfile(examplesDir, [noiseName '_noisy.wav']), ...
                    x/commonScale, fsTarget);
                audiowrite(fullfile(examplesDir, [noiseName '_ss.wav']), ...
                    ySS/commonScale, fsTarget);
                audiowrite(fullfile(examplesDir, [noiseName '_wiener.wav']), ...
                    yWiener/commonScale, fsTarget);
            end
        end
    end
    fprintf('Processed %d/%d: %s\n', i, numel(files), speechFile);
end

if rowCount == 0, error('No results were generated.'); end
T = T(1:rowCount,:);
writetable(T, fullfile(outDir, outputName));

fprintf('\nSaved %d mixture results to %s\n', height(T), outputName);
fprintf('Number of different speakers: %d\n', numel(unique(T.Speaker)));
fprintf('Each row stores SNR, O, V_N, SI-SDR and STOI for both methods.\n');
fprintf('Enhancement algorithms are still reference-assisted and need validation.\n');
