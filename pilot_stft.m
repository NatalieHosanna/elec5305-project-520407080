function [X,pad] = pilot_stft(x,L,H,NFFT)
% Consistent one-sided STFT with zero padding before/after the signal.
% Toolbox-free Hann window and explicit bin conventions.
x=x(:); assert(NFFT>=L && mod(NFFT,2)==0);
pad.originalLength=numel(x); pad.extra=L;
x=[zeros(L,1);x;zeros(L,1)];
nFrames=ceil((numel(x)-L)/H)+1;
pad.tail=(nFrames-1)*H+L-numel(x);
x=[x;zeros(pad.tail,1)];
w=.5-.5*cos(2*pi*(0:L-1)'/L);
X=zeros(NFFT/2+1,nFrames);
for m=1:nFrames
    ix=(m-1)*H+(1:L);
    f=fft(x(ix).*w,NFFT);
    X(:,m)=f(1:NFFT/2+1);
end
end
