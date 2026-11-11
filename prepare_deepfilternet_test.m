% ELEC5305 - Prepare matched DeepFilterNet test inputs
% Re-create the four 0 dB mixtures for p232_010 from the expanded study.
% The saved CSV is used to verify that the same noise segments were used.
% Does not overwrite existing experimental results.

clear;
clc;

projectDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectDir, 'matlab'));

speechDir = fullfile(projectDir, 'data', 'speech_batch');
noiseDir = fullfile(projectDir, 'data', 'noise');
resultsDir = fullfile(projectDir, 'results', 'extended');
outputDir = fullfile(resultsDir, 'deepfilter_inputs');
if ~isfolder(outputDir), mkdir(outputDir); end

csvFile = fullfile(resultsDir, 'extended_results.csv');
if ~isfile(csvFile)
    csvFile = fullfile(projectDir, 'results', 'extended_results.csv');
end
if ~isfile(csvFile), error('extended_results.csv not found.'); end
T = readtable(csvFile);

fsTarget = 48000;
winLen = 1024;
hop = 256;
nfft = 1024;
snrDB = 0;
speechFile = 'p232_010.wav';
noiseNames = {'white','stationary','traffic','public_space'};

% Reproduce the same sorted recording order used in run_extended_study.m.
files = dir(fullfile(speechDir, '*.wav'));
[~, order] = sort({files.name});
files = files(order);
i = find(strcmp({files.name}, speechFile));
assert(isscalar(i), 'Could not find the selected speech file.');

[raw, fsIn] = audioread(fullfile(speechDir, speechFile));
s = convert_audio(raw, fsIn, fsTarget);
s = s(:) - mean(s(:));
idx = find(abs(s) > 0.02 * max(abs(s)));
assert(~isempty(idx), 'Clean speech is silent.');
startIdx = max(1, idx(1) - round(0.1 * fsTarget));
endIdx = min(numel(s), idx(end) + round(0.1 * fsTarget));
s = s(startIdx:endIdx);
s = s / max(max(abs(s)), eps) * 0.5;
[S, ~] = pilot_stft(s, winLen, hop, nfft);
Ps = abs(S).^2;

manifest = table('Size',[numel(noiseNames),7], ...
    'VariableTypes',{'string','string','double','double','double','double','double'}, ...
    'VariableNames',{'NoisyFile','CleanFile','TargetSNR_dB', ...
    'MeasuredSNR_dB','OverlapO','VariationVN','CommonScale'});

for q = 1:numel(noiseNames)
    label = noiseNames{q};
    row = T(strcmp(string(T.SpeechFile),speechFile) & ...
            strcmp(string(T.Noise),label) & ...
            T.TargetSNR_dB == snrDB,:);
    assert(height(row)==1, 'Expected one matching CSV row for %s.', label);

    if strcmp(label,'white')
        % Same deterministic white-noise realisation as the full batch.
        rng(5305 + 1000*i + q, 'twister');
        n = randn(size(s));
    else
        source = fullfile(noiseDir,[label '.wav']);
        assert(isfile(source),'Missing source noise: %s',source);
        noiseStart = round(row.NoiseStartSample);
        assert(noiseStart>=1,'Invalid noise start sample.');
        segment = audioread(source,[noiseStart,noiseStart+numel(s)-1]);
        n = mean(double(segment),2);
    end

    n = n(:) - mean(n(:));
    alpha = sqrt(sum(s.^2)/(sum(n.^2)*10^(snrDB/10)));
    scaledN = alpha*n;
    x = s + scaledN;

    measuredSNR = 10*log10(sum(s.^2)/sum(scaledN.^2));
    [N, ~] = pilot_stft(scaledN,winLen,hop,nfft);
    Pn = abs(N).^2;
    overlapO = sum(min(Ps(:),Pn(:))) / (sum(Ps(:))+eps);
    normNoise = Pn ./ (sum(Pn,1)+eps);
    variationVN = mean(sqrt(sum(diff(normNoise,1,2).^2,1)));

    assert(abs(measuredSNR-row.MeasuredSNR_dB)<1e-8, ...
        'Mismatch: measured SNR for %s.',label);
    assert(abs(overlapO-row.OverlapO)<1e-8, ...
        'Mismatch: overlap for %s. Check noise files and order.',label);
    assert(abs(variationVN-row.VariationVN)<1e-8, ...
        'Mismatch: variation for %s. Check noise files and order.',label);

    % Apply one shared scale to avoid clipping without changing SNR.
    % Record it, since the pretrained model may respond to input level.
    commonScale = max([1;abs(s(:));abs(x(:))]);
    name = sprintf('p232_010_%s_0dB',label);
    noisyName = [name '_noisy.wav'];
    cleanName = [name '_clean.wav'];
    audiowrite(fullfile(outputDir,noisyName),x/commonScale,fsTarget, ...
        'BitsPerSample',32);
    audiowrite(fullfile(outputDir,cleanName),s/commonScale,fsTarget, ...
        'BitsPerSample',32);

    manifest.NoisyFile(q) = string(noisyName);
    manifest.CleanFile(q) = string(cleanName);
    manifest.TargetSNR_dB(q) = snrDB;
    manifest.MeasuredSNR_dB(q) = measuredSNR;
    manifest.OverlapO(q) = overlapO;
    manifest.VariationVN(q) = variationVN;
    manifest.CommonScale(q) = commonScale;
    fprintf('%-13s | SNR %+6.3f dB | O %.5f | V_N %.5f | scale %.4f\n', ...
        label,measuredSNR,overlapO,variationVN,commonScale);
end

writetable(manifest,fullfile(outputDir,'test_manifest.csv'));
fprintf('\nSaved four matched noisy/clean pairs and manifest in:\n%s\n',outputDir);
