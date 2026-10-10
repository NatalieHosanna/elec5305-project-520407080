function y = convert_audio(x,fsIn,fsOut)
% Convert stereo recordings to one mono channel; resample if needed.
x=mean(double(x),2);
if fsIn==fsOut, y=x; return; end
if exist('resample','file')~=2
    error(['Input is %d Hz; expected %d Hz. Install Signal Processing Toolbox ' ...
           'for resample(), or pre-convert the WAV to 48 kHz.'],fsIn,fsOut);
end
[p,q]=rat(fsOut/fsIn,1e-12);
y=resample(x,p,q);
end
