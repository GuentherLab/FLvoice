function [fmt,t,svar,spec]=flvoice_formants(s,fs,Nfmt,varargin);
% VOICEFORMANTS extracts formants from sound signal
% [fmt,t]=flvoice_formants(s,fs,N); extracts the formts from the sound signal s
% obtained with sampling frequency fs. FORMANTS returns a matrix fmt 
% containing the first N formants of the sound signal in s sampled every 
% 5 miliseconds, and a vector t containing the timepoints corresponding to 
% the columns of fmt.
%
% [fmt,t,spec]=flvoice_formants(...) also returns the LPC spectrum of the signal
%
% optional argument pairs:
% fmt=flvoice_formants(s,fs,N,'argument1_name',argument1_value,'argument2_name',argument2_value,......)
%       'stepsize'      :       output sampling (in seconds) [defaults to .001]
%       'windowsize'    :       input window size (in seconds) [defaults to .050]
%       'lpcorder'      :       number of poles of lpc model [defaults to 2+fs/1000]
%       'viterbifilter' :       viterbi smoothing factor (range 0 to inf) [defaults to 1] : set to 0 for not viterbi filtering.
%       'medianfilter'  :       median filter window size (in seconds) [defaults to .025]: set to 0 for not median filtering.
%
% e.g.
% [fmt,t]=flvoice_formants(s,fs,4); 
% specgram(s,1024,fs,256,200); 
% hold on; plot(t,fmt','.-'); hold off; 
%

% alfnie@bu.edu
% 01/05

fields={'windowsize',.050,...%.050, ...     % s       
        'stepsize',.001,...%.005, ...       % s      
        'overlap','data.windowsize-data.stepsize',...
        'lpcorder','2+ceil(fs/1000)',...      
        'fcutoff',100,...                   % Hz
        'bwcutoff',400,...                  % Hz
        'viterbifilter',1,...               % 1/0
        'medianfilter',.025};               % s

data=[]; for n1=1:2:nargin-4, data=setfield(data,lower(varargin{n1}),varargin{n1+1}); end
for n1=1:2:length(fields), 
    if ~isfield(data,fields{n1}) || isempty(getfield(data,fields{n1})), 
        if isstr(fields{n1+1}), data=setfield(data,fields{n1},eval(fields{n1+1})); 
        else, data=setfield(data,fields{n1},fields{n1+1}); end; 
    end; 
end

%if data.viterbifilter, data.lpcorder=round(data.lpcorder*1.25); end; 
data.Nfmt=floor(data.lpcorder/2); 
windowsize=round(data.windowsize*fs); % window size (in samples)
windowoverlap=round(data.overlap*fs);
medianfilter=2*round(data.medianfilter/(data.windowsize-data.overlap)/2)+1;  % median filtering (in samples)
k1=data.stepsize/.005;

%k=reshape(s(2:end),[],1)\reshape(s(1:end-1),[],1);
%s1=convn(s(:),[1;-k],'same');
s1=convn(s(:),[1;-.98],'same');
s2=flvoice_samplewindow(s1,windowsize,windowoverlap,'none','same');
Nt=size(s2,2);
s2=s2.*repmat(flvoice_hanning(windowsize),[1,Nt]);
svar=max(0,mean(s2.^2)-mean(s2).^2);
[a,g]=lpc(s2,data.lpcorder);
a(isnan(a))=0;
t=windowsize/fs/2+(windowsize-windowoverlap)/fs*(0:Nt-1); % note: time of last sample within window
rthr=exp(-2*data.bwcutoff*2*pi/fs);
fthr=data.fcutoff*2*pi/fs;
fmt=nan+zeros(data.Nfmt,Nt); for n1=1:Nt, r=roots(a(n1,:)); r(abs(r)<rthr | angle(r)<=fthr)=[]; r=sort(angle(r)/(2*pi)*fs); fmt(1:min(data.Nfmt,length(r)),n1)=r(1:min(data.Nfmt,length(r))); end 

if nargout>3, 
    Nff=512; % number of frequency bins for LPC spectrum
    ff=linspace(0,fs/2,Nff);
    spec=zeros(Nff,Nt); 
    for n1=1:Nt, spec(:,n1)=log10(abs(g(n1)*freqz(1,a(n1,:),ff,fs)')); end; 
end

if data.viterbifilter,
    D=zeros([data.Nfmt,data.Nfmt,Nt-1]); for n1=1:Nt-1, D(:,:,n1)=-abs(abs(fmt(:,n1+zeros(1,data.Nfmt))-fmt(:,n1+1+zeros(1,data.Nfmt))').^2); end
    C=-fmt;
    D=data.viterbifilter/k1*D;
    P=max(0,svar);
    P=tanh(max(0,P/(mean(P)/8)-1));
    D=D.*repmat(shiftdim(min(P(1:end-1),P(2:end)),-1),[size(D,1),size(D,2),1]);
    for n1=1:Nfmt,
        [idx,E]=flvoice_pathsearch(C(n1:end,:),D(n1:end,n1:end,:));
        for n2=1:Nt, 
            C(fmt(:,n2)<=fmt(n1+idx(n2)-1,n2),n2)=nan;
            C([n1+idx(n2)-1,n1],n2)=C([n1,n1+idx(n2)-1],n2);
            if n2<Nt, D([n1+idx(n2)-1,n1],:,n2)=D([n1,n1+idx(n2)-1],:,n2); D(:,[n1+idx(n2+1)-1,n1],n2)=D(:,[n1,n1+idx(n2+1)-1],n2); end
            fmt([n1+idx(n2)-1,n1],n2)=fmt([n1,n1+idx(n2)-1],n2);
            if ~isnan(fmt(n1,n2)), fmt(n1+find(fmt(n1+1:end,n2)<fmt(n1,n2)),n2)=nan; end
        end
    end
end

if medianfilter>1, 
    fmt=shiftdim(median(flvoice_samplewindow(fmt',medianfilter,medianfilter-1,'none','same'),1))'; 
end; 

fmt=fmt(1:Nfmt,:);
end






