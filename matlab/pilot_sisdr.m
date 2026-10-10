function val = pilot_sisdr(reference,estimate)
% SI-SDR in dB; zero-mean projection onto clean reference.
s=reference(:)-mean(reference);
y=estimate(:)-mean(estimate);
assert(numel(s)==numel(y),'Signals need aligned, equal lengths.');
target=(dot(y,s)/(dot(s,s)+eps))*s;
e=y-target;
val=10*log10((sum(target.^2)+eps)/(sum(e.^2)+eps));
end
