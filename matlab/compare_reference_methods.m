% ELEC5305 - compare the pilot against independent MATLAB implementations
% Install VOICEBOX and/or Scalart's code separately before running this file.
% The algorithms use different noise estimators, so this is a benchmark,
% NOT an exact output-matching test of the original gain functions.
clearvars; clc; close all;

projectDir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectDir, 'matlab'));
% VOICEBOX: GitHub folder
voiceboxDir = fullfile(projectDir, 'voicebox');
% VOICEBOX: Original ZIP folder structure
if ~isfolder(voiceboxDir)
    voiceboxDir = fullfile(projectDir, ...
        'sap-voicebox-master', 'voicebox');
end
if isfolder(voiceboxDir)
    addpath(voiceboxDir);
end
% Wiener reference implementation
wienerDir = fullfile(projectDir, ...
    'wienernoisereduction-2.1.0');
if isfolder(wienerDir)
    addpath(wienerDir);
end
% Also check the main project folder
addpath(projectDir);
resultsDir = fullfile(projectDir,'results');
validationDir = fullfile(resultsDir,'validation');
if ~exist(validationDir,'dir'), mkdir(validationDir); end

hasVoicebox = exist('v_specsub','file') == 2;
hasScalart = exist('WienerNoiseReduction','file') == 2;
hasStoi = exist('stoi','file') == 2;

fprintf('VOICEBOX v_specsub available: %d\n',hasVoicebox);
fprintf('Scalart WienerNoiseReduction available: %d\n',hasScalart);
if ~hasVoicebox && ~hasScalart
    fprintf(['No external reference methods found. ', ...
        'Install VOICEBOX and/or Scalart, add them ', ...
        'to the MATLAB path, and rerun this script.\n']);
    return;
end


fsTarget=48000;
[s,fsS]=audioread(fullfile(projectDir,'data','speech','clean.wav'));
s=convert_audio(s,fsS,fsTarget);
s=s(:)-mean(s(:));
idx=find(abs(s)>0.02*max(abs(s)));
s=s(max(1,idx(1)-round(.1*fsTarget)): ...
    min(numel(s),idx(end)+round(.1*fsTarget)));
s=s/max(max(abs(s)),eps)*0.5;
labels={'white','stationary','traffic','public_space'};

Noise = strings(0,1);
ReferenceMethod = strings(0,1);
NoiseOnlyCalibration = false(0,1);
AlignmentLag_ms = zeros(0,1);
ValidAudio_s = zeros(0,1);
PilotSS_DeltaSI_SDR_dB = zeros(0,1);
PilotWiener_DeltaSI_SDR_dB = zeros(0,1);
Reference_DeltaSI_SDR_dB = zeros(0,1);
Reference_DeltaSTOI = zeros(0,1);

for i = 1:numel(labels)
    label=labels{i};
    [x,fsX]=audioread(fullfile(resultsDir,[label '_noisy.wav']));
    [ss,~]=audioread(fullfile(resultsDir,[label '_spectral_subtraction.wav']));
    [w,~]=audioread(fullfile(resultsDir,[label '_wiener.wav']));
    x=x(:); ss=ss(:); w=w(:);
    if fsX~=fsTarget || numel(x)~=numel(s)
        error('Pilot mixture and clean reference do not align for %s.',label);
    end

    methods={}; outputs={}; usesCalibration=[];
    if hasVoicebox
        try
            % VOICEBOX estimates the noise from the noisy mixture itself.
            z=v_specsub(x,fsTarget);
            methods{end+1}='VOICEBOX v_specsub'; 
            outputs{end+1}=z(:); 
            usesCalibration(end+1)=false;
        catch ME
            warning('VOICEBOX failed for %s: %s',label,ME.message);
        end
    end
    if hasScalart
        try
            % Scalart's function requires initial noise-only samples.
            n=x-s;
            prefixLen=round(0.5*fsTarget);
            xWithPrefix=[n(1:prefixLen);x];
            [z,~]=WienerNoiseReduction(xWithPrefix,fsTarget,prefixLen);
            z=z(:);
            if numel(z) <= prefixLen
                error('Output was shorter than the noise-only prefix.');
            end
            z=z(prefixLen+1:end);
            methods{end+1}='Scalart decision-directed'; 
            outputs{end+1}=z; 
            usesCalibration(end+1)=true; 
        catch ME
            warning('Scalart failed for %s: %s',label,ME.message);
        end
    end

    for j=1:numel(methods)
        z=outputs{j};
        if any(~isfinite(z))
            warning('Non-finite output from %s on %s.',methods{j},label);
            continue;
        end
        [sAligned,xAligned,zAligned,ind,lag] = alignReferenceOutput(s,x,z,fsTarget);
        if numel(ind) < round(0.90*numel(x))
            warning('Reference method kept less than 90%% of %s: skipping.',label);
            continue;
        end
        originalSS=ss(ind);
        originalW=w(ind);
        base=pilot_sisdr(sAligned,xAligned);
        scoreSS=pilot_sisdr(sAligned,originalSS)-base;
        scoreW=pilot_sisdr(sAligned,originalW)-base;
        scoreRef=pilot_sisdr(sAligned,zAligned)-base;
        deltaStoi=NaN;
        if hasStoi
            deltaStoi=stoi(zAligned,sAligned,fsTarget)- ...
                stoi(xAligned,sAligned,fsTarget);
        end
        Noise(end+1,1)=string(label);
        ReferenceMethod(end+1,1)=string(methods{j});
        NoiseOnlyCalibration(end+1,1)=usesCalibration(j);
        AlignmentLag_ms(end+1,1)=lag*1000/fsTarget;
        ValidAudio_s(end+1,1)=numel(sAligned)/fsTarget;
        PilotSS_DeltaSI_SDR_dB(end+1,1)=scoreSS;
        PilotWiener_DeltaSI_SDR_dB(end+1,1)=scoreW;
        Reference_DeltaSI_SDR_dB(end+1,1)=scoreRef;
        Reference_DeltaSTOI(end+1,1)=deltaStoi;
        fprintf('%-12s %-26s lag %7.3f ms | reference improvement %+7.3f dB\n', ...
            label,methods{j},lag*1000/fsTarget,scoreRef);
    end
end

if isempty(Noise)
    warning('No reference outputs were evaluated. Check installed toolboxes.');
    return;
end
T=table(Noise,ReferenceMethod,NoiseOnlyCalibration,AlignmentLag_ms, ...
    ValidAudio_s,PilotSS_DeltaSI_SDR_dB,PilotWiener_DeltaSI_SDR_dB, ...
    Reference_DeltaSI_SDR_dB,Reference_DeltaSTOI);
writetable(T,fullfile(validationDir,'reference_comparison.csv'));
disp(T);
fprintf('Results saved to results/validation/reference_comparison.csv\n');
fprintf('Treat these as different IMPLEMENTATIONS, not numerically identical filters.\n');

function [sa,xa,ya,indices,lag] = alignReferenceOutput(s,x,y,fs)
    % Determine an output delay of at most 100 ms before scoring.
    lengthMax=max(numel(x),numel(y));
    xp=[x(:); zeros(lengthMax-numel(x),1)];
    yp=[y(:); zeros(lengthMax-numel(y),1)];
    maxLag=round(.1*fs);
    [cor,lags]=xcorr(yp,xp,maxLag);
    [~,j]=max(cor);
    lag=lags(j);
    first=max(1,1-lag);
    last=min(numel(s),numel(y)-lag);
    if last<first, error('Reference output has no common aligned segment.'); end
    indices=(first:last)';
    sa=s(indices);
    xa=x(indices);
    ya=y(indices+lag);
end
