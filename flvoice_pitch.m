function [f0,t,w]=flvoice_pitch(s,fs,varargin)
%
% f0=flvoice_pitch(s,fs [, option_name, option_value, ...])
%   estimates voice pitch f0 from audio sample [s,fs]
%
% s             : sound timeseries vector
% fs            : sampling frequency (Hz)
% f0            : output pitch vector (Hz)
%
% additional options:
%
%   windowsize      : window size (s) (default 0.050)
%   stepsize        : window step-size (s) (default 0.001)
%   range           : F0 range (Hz) (default [50 500])
%   methods         : pitch estimation method(s) used {'PEF' 'NCF' 'CEP' 'LHS' 'SRH'} (default 'CEP'; other methods require Matlab audio toolbox)
%   hr_min          : harmonic ratio threshold (default 0.7)
%   viterbifilter   : 1/0 uses viterbi filter for temporal interpolation (default 1; for CEP method use 0-inf viterbifilter values, higher values favour stable trajectories)
%   medianfilter    : 1/0 uses windowsize median filter (default 1)
%   meanfilter      : 1/0 uses windowsize smoothing filter (default 0)
%   outlierfilter   : 1/0 detect&interpolate outlier values (default 0)
%   f0_fs           : pitch output sampling rate (Hz) (default 1000)
%   f0_t            : pitch output sample timepoints (s) (default [], when f0_t is specified f0_fs is disregarded)
%
% alternative syntax:
%
% flvoice_pitch(filename_in, filename_out)
%   estimates voice pitch (output saved to .txt or .mat file filename_out) from audio sample (read from audio file filename_in)
%
% [f0,hr,t]=flvoice_pitch(...)
%   returns hr harmonic ratio vector (0-1 range)
%           t  timesamples vector (s)
% 
% example:
%
% [f0,t]=flvoice_pitch(s,fs); 
% clf;
% spectrogram(s,round(.100*fs),round(.099*fs),[],fs,'yaxis');
% set(gca,'ylim',[0 1]); 
% hold on; plot(t,1e-3*f0*[1:10],'b-',t,1e-3*f0,'k.-'); hold off;

params=struct(  'windowsize',.050,...           % s       
                'stepsize',.001,...             % s      
                'range',[50 300],...            % Hz
                'methods','CEP',...             % {{'PEF','NCF','CEP','LHS','SRH'}},...
                'hr_min',0.5,...                % harmonic ratio threshold
                'viterbifilter',1,...           % 1/0
                'medianfilter',1,...            % 1/0
                'meanfilter',0.5,...            % 1/0
                'outlierfilter',false,...       % 1/0
                'f0_fs',1000,...                % Hz            
                'f0_t',[],...                   % s            
                'filename_out','',...
                'viterbi_nf0',2,...             %
                'useaudiotoolbox',false,...     %
                'pitch_options',{{}});              
for n1=1:2:numel(varargin), assert(isfield(params,lower(varargin{n1})),'unrecognized parameter %s',varargin{n1}); params=setfield(params,lower(varargin{n1}),varargin{n1+1}); end

if ischar(s),
    if nargin>=2, params.filename_out=fs; end
    [s,fs]=audioread(s);
end
if ~isempty(params.f0_t), t=params.f0_t; params.f0_fs=1/mean(diff(params.f0_t));
else t=0:1/params.f0_fs:numel(s)/fs; 
end

windowlength=round(params.windowsize*fs);
overlaplength=round((params.windowsize-params.stepsize)*fs);
assert(numel(s)>=windowlength,'signal is too short (%d samples)',numel(s));
f0=[];
w=[];
for methods=reshape(cellstr(params.methods),1,[])
    if ~params.useaudiotoolbox&&(isequal(methods{1},'CEP')||isequal(methods{1},'NAC'))
        s2=flvoice_samplewindow(s(:),windowlength,overlaplength,'none','tight');
        Nt=size(s2,2);
        s2=s2.*repmat(flvoice_hamming(windowlength),[1,Nt]);
        i0=windowlength+(windowlength-overlaplength)*(0:Nt-1)'; % note: time of last sample within window
        if isequal(methods{1},'CEP')
            ceps=real(ifft(log(abs(fft(s2,2^nextpow2(2*windowlength-1))).^2)));
            idx0=(floor(fs/params.range(2)):ceil(fs/params.range(1)))';
            R=ceps(idx0,:);
            if params.viterbifilter
                idx=flvoice_pathsearch(fs/1024*R/max(abs(R(:)))/params.viterbifilter)';
            else
                [nill,idx]=max(R,[],1);
            end
            w3=R(max(1,min(size(R,1), repmat(idx,3,1)+repmat((-1:1)',1,numel(idx))))+(0:size(R,2)-1)*size(R,1)); % parabolic interpolation
            spart=(w3(3,:)-w3(1,:))./(2*w3(2,:)-w3(3,:)-w3(1,:))/2;
            tf0=fs./(idx0(1)-1+max(1,min(size(R,1), idx+spart))); %tf0=fs./idx0(idx);
        end
        
        cc=real(ifft(abs(fft(s2,2^nextpow2(2*windowlength-1))).^2));
        cp=flipud(cumsum(s2.^2,1));
        idx0=1:min(windowlength-1,ceil(.040*fs)); % remove delays above 40ms
        R=cc(idx0,:)./max(eps,sqrt(repmat(cc(1,:),numel(idx0),1).*cp(idx0,:))); % normalized cross-correlation
        [w,idx]=max(R.*(cumsum(R<0,1)>0),[],1); % remove first peak (up to first zero-crossing)
        w3=R(max(1,min(size(R,1), repmat(idx,3,1)+repmat((-1:1)',1,numel(idx))))+(0:size(R,2)-1)*size(R,1)); % parabolic peak-height interpolation
        w=((w>0).*max(0,min(1, w3(2,:)+(w3(1,:)-w3(3,:)).^2./(2*w3(2,:)-w3(3,:)-w3(1,:))/8)))';
        if isequal(methods{1},'NAC')
            spart=(w3(3,:)-w3(1,:))./(2*w3(2,:)-w3(3,:)-w3(1,:))/2;
            tf0=fs./(idx0(1)-1+max(1,min(size(R,1), idx+spart))); 
        end
    else
        [tf0,i0]=pitch(s,fs,'Method',methods{1},'WindowLength',windowlength,'OverlapLength',overlaplength,'Range',params.range,params.pitch_options{:});
        if isempty(w), w=harmonicRatio(s,fs,'Window',flvoice_hamming(windowlength),'OverlapLength',overlaplength); end
    end
    tf0=tf0(:);
    w=w(:);
    
    if params.viterbifilter&&~(~params.useaudiotoolbox&&(isequal(methods{1},'CEP'))),
        Nt=numel(tf0);
        D=zeros([2*params.viterbi_nf0+1,2*params.viterbi_nf0+1,Nt-1]); 
        etf0=tf0*[1./(params.viterbi_nf0+1:-1:2) 1:params.viterbi_nf0+1];
        for n1=1:Nt-1, D(:,:,n1)=-abs(etf0(n1+zeros(1,2*params.viterbi_nf0+1),:)'-etf0(n1+1+zeros(1,2*params.viterbi_nf0+1),:)); end
        C=1e3*params.stepsize*((-params.viterbi_nf0:params.viterbi_nf0)==0)'*w'.^2;
        C(etf0'<params.range(1)|etf0'>params.range(2))=-1e6*params.stepsize;
        D=D.*repmat(shiftdim(min(w(1:end-1),w(2:end)),-2),[size(D,1),size(D,2),1]);
        [idx,E]=flvoice_pathsearch(C,D);
        tf0=etf0((1:size(etf0,1))'+(idx(:)-1)*size(etf0,1));
    end
    
    ko=w<params.hr_min;
    tf0(ko)=nan;
    if params.outlierfilter
        d=abs(diff(tf0(:)));       
        ok=isnan(d)|(d<=-1.5*prctile(d,25)+2.5*prctile(d,75));
        ok=[ok;true]&[true;ok];
        %p25=prctile(tf0,25); p75=prctile(tf0,75); ok=ok&(isnan(tf0)|(tf0<=-1.5*p25+2.5*p75&tf0>=2.5*p25-1.5*p75));
        if ~all(ok|ko), tf0(~ko)=interp1(find(ok&~ko), tf0(ok&~ko), find(~ko),'nearest',nan); end
    end
    
    if params.medianfilter>0,
        nf=2*floor(params.medianfilter*params.windowsize*params.f0_fs/2)+1;
        [stf0,itf0]=flvoice_samplewindow(tf0,nf,nf-1,'none','same');
        stf0(isnan(itf0))=nan;
        tf0=median(stf0,1,'omitnan')';
    end
    
    if params.meanfilter>0
        nf=2*floor(params.meanfilter*params.windowsize*params.f0_fs/2)+1;
        tf0=convn(tf0(max(1,min(numel(tf0), 1-(nf-1)/2:numel(tf0)+(nf-1)/2))),flvoice_hanning(nf)/sum(flvoice_hanning(nf)),'valid');
    end
    
    f0=[f0 interp1(i0(:)/fs-params.windowsize/2, tf0(:), t(:),'lin',nan)]; % note: time of mid sample within window
end
f0=median(f0,2);
if ~isempty(params.filename_out)
    if ~isempty(regexp(params.filename_out,'\.mat$')), fs=params.f0_fs; save(params.filename_out, 'f0', 'fs'); 
    else save(params.filename_out,'f0','-ascii');
    end
end

end





