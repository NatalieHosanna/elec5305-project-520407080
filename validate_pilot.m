% ELEC5305 - check the original pilot results
% Recalculate the saved measurements without changing the pilot files.
clearvars; clc; close all;

projectDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectDir,'matlab'));
resultsDir = fullfile(projectDir,'results');
validationDir = fullfile(resultsDir,'validation');
if ~exist(validationDir,'dir'), mkdir(validationDir); end

fsTarget = 48000;
L = 1024; H = 256; NFFT = 1024;

% Repeat the preprocessing used in run_pilot.m
[s,fs] = audioread(fullfile(projectDir,'data','speech','clean.wav'));
s = convert_audio(s,fs,fsTarget);
s = s(:) - mean(s(:));
idx = find(abs(s) > 0.02*max(abs(s)));
if isempty(idx), error('Clean speech file is silent.'); end
firstSample = max(1,idx(1)-round(.1*fsTarget));
lastSample = min(numel(s),idx(end)+round(.1*fsTarget));
s = s(firstSample:lastSample);
s = s/max(max(abs(s)),eps)*0.5;
fprintf('Clean speech begins at sample %d (%.6f s), length %.6f s.\n', ...
    firstSample-1,(firstSample-1)/fsTarget,numel(s)/fsTarget);

[S,pad] = pilot_stft(s,L,H,NFFT);
sRecovered = pilot_istft(S,L,H,NFFT,pad);
reconError = norm(s-sRecovered)/max(norm(s),eps);
fprintf('STFT/ISTFT relative error: %.3g\n',reconError);

stored = readtable(fullfile(resultsDir,'pilot_results.csv'));
labels = {'white','stationary','traffic','public_space'};
nCases = numel(labels);

measuredSNR = nan(nCases,1);
overlapO = nan(nCases,1);
variationVN = nan(nCases,1);
noisySI = nan(nCases,1);
ssSI = nan(nCases,1);
wienerSI = nan(nCases,1);
ssDifference = nan(nCases,1);
wienerDifference = nan(nCases,1);
stoiNoisy = nan(nCases,1);
stoiSS = nan(nCases,1);
stoiWiener = nan(nCases,1);
checksPass = false(nCases,1);

haveStoi = exist('stoi','file') == 2;

for j = 1:nCases
    label = labels{j};
    [x,fsX] = audioread(fullfile(resultsDir,[label '_noisy.wav']));
    [ySS,fsSS] = audioread(fullfile(resultsDir,[label '_spectral_subtraction.wav']));
    [yW,fsW] = audioread(fullfile(resultsDir,[label '_wiener.wav']));
    if any([fsX fsSS fsW] ~= fsTarget)
        error('Sample rate mismatch in %s.',label);
    end
    x=x(:); ySS=ySS(:); yW=yW(:);
    if any([numel(x) numel(ySS) numel(yW)] ~= numel(s))
        error('Processed files and trimmed reference have different lengths for %s.',label);
    end
    if any(~isfinite([x;ySS;yW]))
        error('Non-finite audio samples for %s.',label);
    end
    
    % The WAVs are from the original unscaled mixture (no clipping occurred).
    % Recover the scaled interference to check the reported mixture measurements.
    scaledNoise = x-s;
    measuredSNR(j) = 10*log10(sum(s.^2)/sum(scaledNoise.^2));
    [N,~] = pilot_stft(scaledNoise,L,H,NFFT);
    [X,~] = pilot_stft(x,L,H,NFFT);
    Ps=abs(S).^2; Pn=abs(N).^2; Px=abs(X).^2;
    overlapO(j) = sum(min(Ps(:),Pn(:)))/(sum(Ps(:))+eps);
    normalised = Pn./(sum(Pn,1)+eps);
    variationVN(j) = mean(sqrt(sum(diff(normalised,1,2).^2,1)));
    
    noisySI(j) = pilot_sisdr(s,x);
    ssSI(j) = pilot_sisdr(s,ySS);
    wienerSI(j) = pilot_sisdr(s,yW);
    
    % Check that the saved outputs match the implementation's filter equations.
    noisePSD=mean(Pn,2);
    minGain=0.05;
    Gss=sqrt(max(Px-noisePSD,minGain^2*Px)./(Px+eps));
    PestSpeech=max(Px-noisePSD,0);
    Gw=max(PestSpeech./(PestSpeech+noisePSD+eps),minGain);
    if any(~isfinite([Gss(:);Gw(:)])) || any(Gss(:)<0) || any(Gw(:)<0)
        error('Invalid spectral gain for %s.',label);
    end
    ssRebuilt=pilot_istft(Gss.*X,L,H,NFFT,pad);
    wRebuilt=pilot_istft(Gw.*X,L,H,NFFT,pad);
    ssDifference(j)=norm(ssRebuilt-ySS)/max(norm(ySS),eps);
    wienerDifference(j)=norm(wRebuilt-yW)/max(norm(yW),eps);
    
    row = find(strcmp(string(stored.Noise),label));
    if numel(row)~=1
        error('Cannot find one matching CSV row for %s.',label);
    end
    errors = [abs(measuredSNR(j)-stored.MeasuredSNR_dB(row)), ...
        abs(overlapO(j)-stored.OverlapO(row)), ...
        abs(variationVN(j)-stored.VariationVN(row)), ...
        abs(noisySI(j)-stored.SI_SDR_Noisy_dB(row)), ...
        abs(ssSI(j)-stored.SI_SDR_SS_dB(row)), ...
        abs(wienerSI(j)-stored.SI_SDR_Wiener_dB(row))];
    % Differences in the saved WAVs are expected from 16-bit export.
    checksPass(j) = reconError < 1e-8 && errors(1) < 0.01 && ...
        all(errors(2:3) < 0.002) && all(errors(4:6) < 0.01) && ...
        ssDifference(j) < 0.001 && wienerDifference(j) < 0.001;
    
    if haveStoi
        % Same exact trimmed reference for all conditions.
        stoiNoisy(j)=stoi(x,s,fsTarget);
        stoiSS(j)=stoi(ySS,s,fsTarget);
        stoiWiener(j)=stoi(yW,s,fsTarget);
    end
    fprintf('%-13s | SNR %+7.4f dB | O %.4f | V_N %.4f | output err SS %.5f W %.5f | %s\n', ...
        label,measuredSNR(j),overlapO(j),variationVN(j), ...
        ssDifference(j),wienerDifference(j),string(checksPass(j)));
end

T = table(string(labels(:)),measuredSNR,overlapO,variationVN, ...
    noisySI,ssSI,wienerSI,ssDifference,wienerDifference, ...
    stoiNoisy,stoiSS,stoiWiener,checksPass, ...
    'VariableNames',{'Noise','MeasuredSNR_dB','OverlapO','VariationVN', ...
    'SI_SDR_Noisy_dB','SI_SDR_SS_dB','SI_SDR_Wiener_dB', ...
    'SS_OutputRelativeError','Wiener_OutputRelativeError', ...
    'STOI_Noisy','STOI_SS','STOI_Wiener','CoreChecksPass'});

writetable(T,fullfile(validationDir,'pilot_validation.csv'));
disp(T);
if all(checksPass)
    fprintf('\nPASS: Original pilot measurements and saved output signals are internally consistent.\n');
else
    warning('One or more checks failed. Review results/validation/pilot_validation.csv.');
end
fprintf('This checks INTERNAL consistency, not equivalence with published enhancement methods.\n');
fprintf('Saved results/validation/pilot_validation.csv (original files unchanged).\n');
