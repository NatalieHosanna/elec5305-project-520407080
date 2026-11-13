The two-step noise reduction (TSNR) technique removes the annoying reverberation effect while maintaining the benefits of the decision-directed approach. However, classic short-time noise reduction techniques, including TSNR, introduce harmonic distortion in the enhanced speech. To overcome this problem, a method called harmonic regeneration noise reduction (HRNR) is implemented in order to refine the a priori SNR used to compute a spectral gain able to preserve the speech harmonics as proposed by Plapous et al.  
("Improved Signal-to-Noise Ratio Estimation for Speech Enhancement", IEEE Transactions on ASLP, Vol. 14, Issue 6, pp. 2098 - 2108, Nov. 2006).

%% example with the noisy speech file car.wav  
\>\> [x,fs] = audioread('car.wav');  
\>\> [out,~] = WienerNoiseReduction(x,fs,10000) % first 10000 samples are noise samples (without speech)  
\>\> soundsc(out(1:122000),fs)