function [P,t,f]=flvoice_spectrogram(s, fs, windowsize, windowoverlap);

% FLVOICE_SPECTROGRAM computes audio signal spectrogram using a short-time fourier transform
% flvoice_spectrogram(s, fs, WINDOW, NOVERLAP, Type, Extent);
%     s             :  audio samples (vector)
%     fs            :  sampling frequency (Hz)
%     windowsize    :  # samples of window
%     windowoverlap :  # overlapping samples

S=flvoice_samplewindow(s(:), windowsize,windowoverlap,'none','same');
w=flvoice_hanning(size(S,1));
S=repmat(w,1,size(S,2)).*(S-repmat(mean(S,1),size(S,1),1));
S=abs(fft(S,max(2048,size(S,1)))).^2;
t=(0:size(S,2)-1)*(windowsize-windowoverlap)/fs;
f=(0:size(S,1)-1)*fs/size(S,1);
f=f(2:floor(size(S,1)/2));
S=S(2:floor(size(S,1)/2),:);
P=100+10*log10(2*S/fs/(w'*w)); % power spectrum in dB/Hz units

if nargout==0
    if 0
        [nill,nill,uP]=unique(P);
        uP=reshape(uP,size(P));
        h=surface(t,f/1e3,uP);
    else
        h=surface(t,f/1e3,0*P,P);
    end
    set(h,'edgecolor','none');
    set(gca,'ydir','normal','yscale','lin','ylim',[min(f) max(f)]/1e3,'xlim',[min(t) max(t)],'clim',[min(mean(P,1)), max(P(:))]);
    xlabel('Time (s)');
    ylabel('Frequency (KHz)');
    h=colorbar; ylabel(h,'Power/frequency (dB/Hz)')
end
