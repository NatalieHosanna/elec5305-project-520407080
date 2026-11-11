function y = pilot_istft(X,L,H,NFFT,pad)
% Synthesis by overlap-add with squared-window normalisation.
nFrames=size(X,2);
outlen=(nFrames-1)*H+L;
y=zeros(outlen,1); ws=zeros(outlen,1);
w=.5-.5*cos(2*pi*(0:L-1)'/L);
for m=1:nFrames
    full=[X(:,m);conj(X(end-1:-1:2,m))];
    t=real(ifft(full,NFFT));
    ix=(m-1)*H+(1:L);
    y(ix)=y(ix)+t(1:L).*w;
    ws(ix)=ws(ix)+w.^2;
end
y=y./max(ws,eps);
y=y(L+1:L+pad.originalLength);
end
