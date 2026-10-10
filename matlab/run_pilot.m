% ELEC5305 speech enhancement pilot
clearvars; close all; clc;
projectDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectDir,'matlab'));
speechPath = fullfile(projectDir,'data','speech','clean.wav');
noiseDir = fullfile(projectDir,'data','noise');
resultsDir = fullfile(projectDir,'results');
if ~exist(resultsDir,'dir'), mkdir(resultsDir); end
required = {speechPath,fullfile(noiseDir,'stationary.wav'), ...
    fullfile(noiseDir,'traffic.wav'),fullfile(noiseDir,'public_space.wav')};
for i = 1:numel(required)
    if ~isfile(required{i})
        error('Missing audio: %s\nRead the README for setup.', required{i});
    end
end
fsTarget = 48000; targetSNR = 0; rng(5305,'twister');
winLen = 1024; hop = 256; nfft = 1024;
% All FFTs and metrics use identical frame boundaries.
[s,fsS] = audioread(speechPath);
s = convert_audio(s,fsS,fsTarget);
s = s(:); s = s-mean(s);
% Trim leading/trailing silence for meaningful global SNR
idx = find(abs(s)>0.02*max(abs(s)));
if isempty(idx), error('The clean speech file is silent.'); end
s = s(max(1,idx(1)-round(.1*fsTarget)):min(numel(s),idx(end)+round(.1*fsTarget)));
s = s/max(max(abs(s)),eps)*0.5;
if numel(s)<winLen, error('Speech must be longer than one STFT window.'); end
noiseNames = {'white','stationary','traffic','public_space'};
results = table('Size',[numel(noiseNames),8], ...
    'VariableTypes',{'string','double','double','double','double','double','double','double'}, ...
    'VariableNames',{'Noise','TargetSNR_dB','MeasuredSNR_dB','OverlapO', ...
    'VariationVN','SI_SDR_Noisy_dB','SI_SDR_SS_dB','SI_SDR_Wiener_dB'});
% Derive STFT of clean speech once.
[S,stftPad] = pilot_stft(s,winLen,hop,nfft);
reconstructed = pilot_istft(S,winLen,hop,nfft,stftPad);
reconError = norm(s-reconstructed)/max(norm(s),eps);
fprintf('STFT/ISTFT relative reconstruction error: %.4g\n',reconError);
if reconError>1e-8, warning('STFT reconstruction error is unexpectedly large.'); end
for q=1:numel(noiseNames)
    label = noiseNames{q};
    if strcmp(label,'white')
        n = randn(size(s));
    else
        [n,fsN] = audioread(fullfile(noiseDir,[label '.wav']));
        n = convert_audio(n,fsN,fsTarget); n=n(:);
        if numel(n)<numel(s)
            error('%s.wav is too short. Need %.1f seconds, got %.1f.', ...
                label,numel(s)/fsTarget,numel(n)/fsTarget);
        end
        n=n(1:numel(s)); % deterministic segment: begins at start
    end
    n=n-mean(n);
    if sum(n.^2)==0, error('Noise %s is silent.',label); end
    % Scale the ACTUAL noise component to the target global SNR.
    alpha = sqrt(sum(s.^2)/(sum(n.^2)*10^(targetSNR/10)));
    scaledN=alpha*n; x=s+scaledN;
    measuredSNR=10*log10(sum(s.^2)/sum(scaledN.^2));
    [N,~] = pilot_stft(scaledN,winLen,hop,nfft);
    [X,~] = pilot_stft(x,winLen,hop,nfft);
    Ps=abs(S).^2; Pn=abs(N).^2; Px=abs(X).^2;
    O=sum(min(Ps(:),Pn(:)))/(sum(Ps(:))+eps);
    normNoise=Pn./(sum(Pn,1)+eps);
    frameChange=diff(normNoise,1,2);
    VN=mean(sqrt(sum(frameChange.^2,1)));
    IRM=Ps./(Ps+Pn+eps); % Oracle descriptor, NOT a practical enhancer.
    % Calibration noise PSD averaged over independent noise frames.
    % Here it uses known separate noise: REFERENCE-ASSISTED baselines.
    % A deployable noise estimator should replace this later.
    noisePSD=mean(Pn,2);
    % Magnitude spectral subtraction with gain floor; noisy phase reused.
    beta=1.0; minGain=.05;
    Gss=sqrt(max(Px-beta*noisePSD,minGain^2*Px)./(Px+eps));
    % Simple Wiener-type estimated speech/noise power ratio gain.
    PestSpeech=max(Px-noisePSD,0);
    Gw=max(PestSpeech./(PestSpeech+noisePSD+eps),minGain);
    ySS=pilot_istft(Gss.*X,winLen,hop,nfft,stftPad);
    yW=pilot_istft(Gw.*X,winLen,hop,nfft,stftPad);
    noisyScore=pilot_sisdr(s,x);
    ssScore=pilot_sisdr(s,ySS);
    wScore=pilot_sisdr(s,yW);
    results(q,:)={string(label),targetSNR,measuredSNR,O,VN,noisyScore,ssScore,wScore};
    % Common scale; don't normalise signals separately for listening.
    peak=max(abs([x;ySS;yW])); commonScale=max(1,peak);
    audiowrite(fullfile(resultsDir,[label '_noisy.wav']),x/commonScale,fsTarget);
    audiowrite(fullfile(resultsDir,[label '_spectral_subtraction.wav']),ySS/commonScale,fsTarget);
    audiowrite(fullfile(resultsDir,[label '_wiener.wav']),yW/commonScale,fsTarget);
    fig=figure('Visible','off','Position',[100 100 1100 800]);
    plots={S,N,X,IRM}; labels={'Clean speech STFT','Scaled noise STFT','Noisy mixture STFT','Ideal ratio mask (oracle)'};
    for ii=1:4
        subplot(4,1,ii);
        if ii==4, im=IRM; else, im=20*log10(abs(plots{ii})+1e-8); end
        imagesc((0:size(im,2)-1)*hop/fsTarget,(0:size(im,1)-1)*fsTarget/nfft,im);
        axis xy; ylim([0 8000]); colorbar; title(labels{ii}); ylabel('Frequency (Hz)');
        if ii==4, xlabel('Time (s)'); end
    end
    saveas(fig,fullfile(resultsDir,[label '_spectrograms.png'])); close(fig);
    fprintf('%s: SNR %.2f dB | overlap %.4f | variation %.4f | SI-SDR noisy %.2f, SS %.2f, Wiener %.2f dB\n', ...
        label,measuredSNR,O,VN,noisyScore,ssScore,wScore);
end
writetable(results,fullfile(resultsDir,'pilot_results.csv'));
disp(results);
fprintf('\nSaved WAVs, plots, and pilot_results.csv to results/.\n');
