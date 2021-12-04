
function varargout=flvoice_update(SUB,SES,RUN,TASK, DOSAVE, DOPRINT, REDOFMT, DOREMOTE, FILEPATH)
% data = flvoice_update(SUB,RUN,SES,TASK, DOSAVE, DOPRINT, REDOFMT, DOREMOTE, FILEPATH)
% processes audio data from aud/som experiment
%   SUB             : subject id (e.g. 'test244' or 'sub-test244')
%   SES             : session number (e.g. 1 or 'ses-1')
%   RUN             : run number (e.g. 1 or 'run-1')
%   TASK            : task type 'aud' or 'som'
%   DOSAVE          : (default 0) 1/0 update offlineFmts and qcData files
%   DOPRINT         : (default 1) 1/0 create jpg files with formant&pitch trajectories
%   REDOFMT         : (default 1) 1/0 re-compute formants&pitch using Matlab function
%   DOREMOTE        : (default 0) 1/0 work remotely (0: work from SCC computer; 1: work remotely -run "conn remotely on" first from your home computer to connect to SCC; for first-time initialization run on remote server "conn remotely setup")
%   FILEPATH        : (default '/projectnb/busplab/Experiments/SAP-PILOT/') path to folder containing all subject's data
%
% Alternative syntax:
%   flvoice_update                         : returns list of available subjects
%   flvoice_update SUB                     : returns list of available sessions for this subject
%   flvoice_update SUB SES                 : returns list of available runs for this subject & session
%   flvoice_update SUB SES RUN             : returns list of available tasks for this subject & session & run
%   flvoice_update SUB all RUN TASK ...    : runs flvoice_update using data from all available sessions for this subject & run & task
%   flvoice_update SUB SES all TASK ...    : runs flvoice_update using data from all available runs for this subject & session & task
%   flvoice_update default <optionname> <defaultvalue>  : changes default values for DOSAVE/DOPRINT/REDOFMT/DOREMOTE/FILEPATH options above (changes will affect all subsequent flvoice_update commands where those options are not explicitly defined; defaults will revert back to their original values after your Matlab session ends)
%

persistent DEFAULTS;
if isempty(DEFAULTS), DEFAULTS=struct('DOSAVE',false,'DOPRINT',true,'REDOFMT',true,'DOREMOTE',false,'FILEPATH','/projectnb/busplab/Experiments/SAP-PILOT/'); end    
if nargin==1&&isequal(SUB,'default'), if nargout>0, varargout={DEFAULTS}; else disp(DEFAULTS); end; return; end
if nargin>1&&isequal(SUB,'default'), assert(isfield(DEFAULTS,SES),'unrecognized default field %s',SES); DEFAULTS.(SES)=RUN; return; end

if nargin<1||isempty(SUB), SUB=[]; end
if ischar(SUB), SUB=regexprep(SUB,'^sub-',''); end
if nargin<2||isempty(SES), SES=[]; end
if ischar(SES)&&strcmpi(SES,'all'), SES=0; end
if ischar(SES), SES=str2num(regexprep(SES,'^ses-','')); end
if nargin<3||isempty(RUN), RUN=[]; end
if ischar(RUN)&&strcmpi(RUN,'all'), RUN=0; end
if ischar(RUN), RUN=str2num(regexprep(RUN,'^run-','')); end
if nargin<4||isempty(TASK), TASK=[]; end
if nargin<5||isempty(DOSAVE), DOSAVE=DEFAULTS.DOSAVE; end
if ischar(DOSAVE), DOSAVE=str2num(DOSAVE); end
if nargin<6||isempty(DOPRINT), DOPRINT=DEFAULTS.DOPRINT; end
if ischar(DOPRINT), DOPRINT=str2num(DOPRINT); end
if nargin<7||isempty(REDOFMT), REDOFMT=DEFAULTS.REDOFMT; end
if ischar(REDOFMT), REDOFMT=str2num(REDOFMT); end
if nargin<8||isempty(DOREMOTE), DOREMOTE=DEFAULTS.DOREMOTE; end
if ischar(DOREMOTE), DOREMOTE=str2num(DOREMOTE); end
if nargin<9||isempty(FILEPATH), FILEPATH=DEFAULTS.FILEPATH; end
varargout=cell(1,nargout);

if DOREMOTE, FILEPATH=fullfile('/CONNSERVER',FILEPATH); end

if isempty(SUB),
    [nill,SUBS]=cellfun(@fileparts,conn_dir(fullfile(FILEPATH,'sub-*'),'-dir','-R','-cell'),'uni',0);
    disp('available subjects:');
    disp(char(SUBS));
    if nargout, varargout={SUBS}; end
    return
end
if isempty(SES)||isequal(SES,0),
    [nill,SESS]=cellfun(@fileparts,conn_dir(fullfile(FILEPATH,sprintf('sub-%s',SUB),'ses-*'),'-dir','-R','-cell'),'uni',0);
    disp('available sessions:');
    disp(char(SESS));
    if isempty(SES)
        if nargout, varargout={SESS}; end
        return
    end
    SES=str2double(regexprep(SESS,'^ses-',''));
end
if isempty(RUN)||isequal(RUN,0),
    RUNS={};
    SESS=[];
    for nSES=1:numel(SES)
        [nill,runs]=cellfun(@fileparts,conn_dir(fullfile(FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES(nSES)),'run-*'),'-dir','-R','-cell'),'uni',0);
        RUNS=[RUNS; runs(:)];
        SESS=[SESS; SES(nSES)+zeros(numel(runs),1)];
    end
    disp('available runs:');
    disp(char(RUNS));
    if isempty(RUN)
        if nargout, varargout={RUNS}; end
        return
    end
    RUN=str2double(regexprep(RUNS,'^run-',''));
    SES=SESS;
end
SESS=SES;
RUNS=RUN;
if numel(SESS)==1&&numel(RUNS)>1, SESS=SESS+zeros(size(RUNS)); end
if numel(RUNS)==1&&numel(SESS)>1, RUNS=RUNS+zeros(size(SESS)); end
if isempty(TASK)
    TASKS={};
    for nsample=1:numel(RUNS)
        RUN=RUNS(nsample);
        SES=SESS(nsample);
        [nill,tasks]=cellfun(@fileparts,conn_dir(fullfile(FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-*_expParams.mat',SUB,SES,RUN)),'-R','-cell'),'uni',0);
        TASKS=[TASKS; tasks(:)];
    end
    TASKS=regexprep(TASKS,{'^.*_task-','_expParams$'},'');
    disp('available tasks:');
    disp(char(TASKS));
    if nargout, varargout={TASKS}; end
    return
end

for nsample=1:numel(RUNS)
    RUN=RUNS(nsample);
    SES=SESS(nsample);
    filename_trialData=fullfile(FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-%s.mat',SUB,SES,RUN,TASK));
    assert(conn_existfile(filename_trialData),'file %s not found',filename_trialData);
    fprintf('loading file %s\n',filename_trialData);
    conn_loadmatfile(filename_trialData,'expParams','trialData','-cache');
    
    offlineFmts=[];
    if DOSAVE||~REDOFMT
        filename_offlineFmts=fullfile(FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('offlineFmts_run-%d.mat',RUN));
        assert(conn_existfile(filename_offlineFmts),'file %s not found',filename_offlineFmts);
        fprintf('loading file %s\n',filename_offlineFmts);
        conn_loadmatfile(filename_offlineFmts,'offlineFmts','-cache');
    end
    if DOSAVE
        filename_qcData=fullfile(FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('qcData_run-%d.mat',RUN));
        assert(conn_existfile(filename_qcData),'file %s not found',filename_qcData);
        fprintf('loading file %s\n',filename_qcData);
        conn_loadmatfile(filename_qcData,'qcData','-cache');
    end
    
    praatfile_mic=cell(1,numel(trialData));
    praatfile_head=cell(1,numel(trialData));
    if ~REDOFMT
        fprintf('loading praat files\n');
        for ntrial=1:numel(trialData)
            filename=fullfile(FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),'textfiles',sprintf('sub-%s_ses-%d_run-%d_task-%s_trial-%d_mic.txt',SUB,SES,RUN,TASK,ntrial));
            if conn_existfile(filename),
                if DOREMOTE, praatfile_mic{ntrial}=conn_cache('pull',filename);
                else praatfile_mic{ntrial}=filename;
                end
            end
            if isequal(TASK,'aud')
                filename=fullfile(FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),'textfiles',sprintf('sub-%s_ses-%d_run-%d_task-%s_trial-%d_headphones.txt',SUB,SES,RUN,TASK,ntrial));
                if conn_existfile(filename),
                    if DOREMOTE, praatfile_head{ntrial}=conn_cache('pull',filename);
                    else praatfile_head{ntrial}=filename;
                    end
                end
            end
        end
    end
    
    % SAPOfflineFormants & praat
    for trialNum=1:numel(trialData)
        data=trialData(trialNum);
        if REDOFMT
            %Nlpc=round(1.25*trialData(trialNum).p.nLPC);
            if isfield(data,'audapData'), % audapter data
                s=data.audapData.signalIn;
                fs=16000;
                Nlpc=trialData(trialNum).p.nLPC;
            else % raw data
                s=data.audioData.signalIn;
                fs=48000;
                if isequal(lower(expParams.gender),'male'), Nlpc=17;
                else Nlpc=15;
                end
            end
            if isequal(lower(expParams.gender),'male'), f0range=[50 150];
            else f0range=[150 300];
            end
            fprintf('estimating formants trial #%d\n',trialNum);
            if fs~=16000, s=resample(s,16000,fs); fs=16000; end
            [fmt,t,svar]=flvoice_formants(s,fs,6,'lpcorder',Nlpc,'windowsize',.050,'stepsize',.001);
            f0=flvoice_pitch(s,fs,'f0_t',t,'range',f0range);
            offlineFmts(trialNum).mic = interp1(t',fmt',(0:.001:(numel(s)-1)/fs)','lin',nan); % note: (implicit timing) these data starts at t=0 and it is sampled at offlineFmts(trialNum).fs rate
            praatfile_mic{trialNum}=[t(:), f0, 10*log10(svar(:))+100];                        % note: (explicit timing) these data explicitly lists the time of each sample (first column)
            
            if isfield(data,'audapData')
                s=data.audapData.signalOut;
                [fmt,t,svar]=flvoice_formants(s,fs,6,'lpcorder',Nlpc,'windowsize',.050,'stepsize',.001);
                f0=flvoice_pitch(s,fs,'f0_t',t);
                offlineFmts(trialNum).phones = interp1(t',fmt',(0:.001:(numel(s)-1)/fs)','lin',nan);  % note: (implicit timing) these data starts at t=0 and it is sampled at offlineFmts(trialNum).fs rate
                praatfile_head{trialNum}=[t(:), f0, 10*log10(svar(:))+100];                           % note: (explicit timing) these data explicitly lists the time of each sample (first column)
                %figure(11); plot(f0,'-'); disp(trialData(trialNum).condLabel); pause;
            end
            offlineFmts(trialNum).fs=1000;
        elseif ~isfield(offlineFmts(trialNum),'fs')||isempty(offlineFmts(trialNum).fs)
            if ~isfield(data,'p'), %data.p = setAudapterParams(expParams.gender, 'formant');
                data.p.downFact      = 3;
                data.p.frameLen      = 96 / data.p.downFact;
                data.p.sr            = 48000 / data.p.downFact;
            end
            if isfield(data.p,'sr'), sr=data.p.sr; % Audapter internal sampling rate (Hz)
            elseif isfield(data.p,'downFact'), sr=48000/data.p.downFact; % alf-note: this and line below uses defaults in Audapter as of 2021/10
            else sr=48000/3;
            end
            if isfield(data.p,'frameLen'), frameLen=data.p.frameLen; % Audapter internal frame-length (samples)
            elseif isfield(data.p,'downFact'), frameLen=96/p.downFact; % alf-note: this and line below uses defaults in Audapter as of 2021/10
            else frameLen=96/3;
            end
            offlineFmts(trialNum).fs = sr/frameLen; % Sampling rate of Audapter's output fmt traces
        end
    end
    if DOSAVE
        conn_savematfile(filename_offlineFmts,'offlineFmts','-append');
    end
    
    
    % SAPanalysisQC
    clear tempOut;
    baseTime = .2; %length (in seconds) of baseline period prior to pert onset
    pertTime = 1; %length (in seconds of pertation perior after pert onset
    for trialNum=1:numel(trialData)
        clear DATA;
        DATA.fs = 1000; % common sample rate (Hz)
        
        praatrialData_Mic=[];
        try,
            if isnumeric(praatfile_mic{trialNum}), praatrialData_Mic = praatfile_mic{trialNum};
            else praatrialData_Mic = Praatfileread(praatfile_mic{trialNum});
            end
            time_ch1= praatrialData_Mic(:,1);
            DATA.ch1.raw.F0  = interp1(time_ch1, praatrialData_Mic(:,2), 0:1/DATA.fs:max(time_ch1),'lin',nan);
            DATA.ch1.raw.Int = interp1(time_ch1, praatrialData_Mic(:,3), 0:1/DATA.fs:max(time_ch1),'lin',nan);
        end
        time_ch1 = (0:size(offlineFmts(trialNum).mic,1)-1)/offlineFmts(trialNum).fs;
        DATA.ch1.raw.F1 = interp1(time_ch1, offlineFmts(trialNum).mic(:,1),0:1/DATA.fs:max(time_ch1),'lin',nan);
        DATA.ch1.raw.F2 = interp1(time_ch1, offlineFmts(trialNum).mic(:,2),0:1/DATA.fs:max(time_ch1),'lin',nan) ;
        
        if isequal(TASK,'aud')
            praatrialData_Head=[];
            try,
                if isnumeric(praatfile_head{trialNum}), praatrialData_Head = praatfile_head{trialNum};
                else praatrialData_Head = Praatfileread(praatfile_head{trialNum});
                end
                time_ch2= praatrialData_Head(:,1);
                DATA.ch2.raw.F0  = interp1(time_ch2, praatrialData_Head(:,2), 0:1/DATA.fs:max(time_ch2),'lin',nan);
                DATA.ch2.raw.Int = interp1(time_ch2, praatrialData_Head(:,3), 0:1/DATA.fs:max(time_ch2),'lin',nan);
            end
            time_ch2 = (0:size(offlineFmts(trialNum).phones,1)-1)/offlineFmts(trialNum).fs;
            DATA.ch2.raw.F1 = interp1(time_ch2, offlineFmts(trialNum).phones(:,1),0:1/DATA.fs:max(time_ch2),'lin',nan);
            DATA.ch2.raw.F2 = interp1(time_ch2, offlineFmts(trialNum).phones(:,2),0:1/DATA.fs:max(time_ch2),'lin',nan);
        end
        
        pertOnset = trialData(trialNum).timingTrial(4)-trialData(trialNum).timingTrial(2);
        
        %Find time window for perturbation analysis (-200ms to 1000ms relative to pertOnset)
        pertWindowT = [pertOnset-baseTime pertOnset+pertTime]; %pert window time
        
        time2=pertWindowT(1):1/DATA.fs:pertWindowT(2);
        DATA.pertaligned_delta=baseTime; % first sample is pertaligned_delta seconds before the beginning of the perturbation
        for channel={'ch1','ch2'}
            if isfield(DATA,channel{1})
                for measure=reshape(fieldnames(DATA.(channel{1}).raw),1,[])
                    time1=(0:numel(DATA.(channel{1}).raw.(measure{1}))-1)/DATA.fs;
                    DATA.(channel{1}).pertaligned.(measure{1}) = interp1(time1, DATA.(channel{1}).raw.(measure{1}), time2, 'lin', nan);
                end
            end
        end
        
        tempOut.DATA(trialNum) = DATA; % alf-note: more possibly-redundant stuff for now
    end
    qcData.DATA = tempOut.DATA;
    qcData.condLabel = {trialData.condLabel};
    if ~isfield(qcData,'keepData'), qcData.keepData=true(1,numel(trialData)); end
    if DOSAVE
        conn_savematfile(filename_qcData,'qcData','-append');
    end
    
    
    
    % SAPSubData
    dLabels = [{'F0'}   {'F1'}  {'F2'}  {'Int'}];
    cLabels = unique(qcData.condLabel);
    for cidx = 0:length(cLabels)
        if cidx, 
            clabel=cLabels{cidx};
            curCond = find(strcmp(qcData.condLabel, clabel));
        else
            clabel='all';
            curCond = 1:numel(qcData.condLabel);
        end
        keepIdx = intersect(find(qcData.keepData),curCond);
        % Loop through each data trace type (dLabels) to aggregate data
        % from each run
        for didx = 1:length(dLabels)
            if RUN==RUNS(1)
                subData.(clabel).(dLabels{didx}) = [];
                ch2subData.(clabel).(dLabels{didx}) = [];
            end
            if ~isempty(keepIdx)&&isfield(qcData.DATA(keepIdx(1)).ch1.pertaligned,dLabels{didx})
                tmpData = cell2mat(arrayfun(@(n)reshape(qcData.DATA(n).ch1.pertaligned.(dLabels{didx}),[],1),keepIdx,'uni',0));
                subData.(clabel).(dLabels{didx}) = ...
                    [subData.(clabel).(dLabels{didx}) tmpData];
                if isfield(qcData.DATA(keepIdx(1)),'ch2')
                    tmpData = cell2mat(arrayfun(@(n)reshape(qcData.DATA(n).ch2.pertaligned.(dLabels{didx}),[],1),keepIdx,'uni',0));
                    ch2subData.(clabel).(dLabels{didx}) = ...
                        [ch2subData.(clabel).(dLabels{didx}) tmpData];
                end
            end
        end
    end
end


t0=1000*qcData.DATA(1).pertaligned_delta;
fs=qcData.DATA(1).fs;
if isequal(TASK,'aud'),
    dispconds={'N1','D1','U1','N0','D0','U0'};
    
    % raw plots
    figure('units','norm','position',[.2 .3 .6 .7]);
    h=[];
    for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .1 .8/3 .4]); x=ch2subData.(dispconds{ncond}).F1; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('headphones F1 (Hz)'); else set(gca,'yticklabel',[]); end; xlabel('time (ms)'); end
    for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .5 .8/3 .4]);    x=subData.(dispconds{ncond}).F1; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('mic F1 (Hz)'); else set(gca,'yticklabel',[]); end; set(gca,'xticklabel',[]); end
    try, cellfun(@(n)set(n,'ylim',[min(cellfun(@min,get(h,'ydata'))) min(1000,max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0); end
    if DOPRINT, conn_print(sprintf('fig_effectF1a_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
    if all(ismember({'D0','N0','U0'},qcData.condLabel))
        figure('units','norm','position',[.2 .0 .6 .7]);
        h=[];
        for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .1 .8/3 .4]); x=ch2subData.(dispconds{3+ncond}).F0; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{3+ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('headphones F0 (Hz)'); else set(gca,'yticklabel',[]); end; xlabel('time (ms)'); end
        for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .5 .8/3 .4]);    x=subData.(dispconds{3+ncond}).F0; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{3+ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('mic F0 (Hz)'); else set(gca,'yticklabel',[]); end; set(gca,'xticklabel',[]); end
        try, cellfun(@(n)set(n,'ylim',[min(cellfun(@min,get(h,'ydata'))) min(500,max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0); end
        if DOPRINT, conn_print(sprintf('fig_effectF0a_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
    end
    
    % summary plots
    color=[ 0.9290/4 0.6940/4 0.1250/4; 0.8500 0.3250 0.0980; 0 0.4470 0.7410];
    figure('units','norm','position',[.2 .3 .6 .7]); 
    h=[]; axes('units','norm','position',[.1 .1 .8 .4]); for ncond=1:3, x=ch2subData.(dispconds{ncond}).F1-ch2subData.(dispconds{1}).F1(:,round(linspace(1,size(ch2subData.(dispconds{1}).F1,2),size(ch2subData.(dispconds{ncond}).F1,2))));        mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1); x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('headphones F1 (Hz)'); legend(h,dispconds(1:3)); 
    set(gca,'ylim',100*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(400,.8*min(cellfun(@min,get(h,'ydata')))) min(1000,1.2*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
    if 1
        h=[]; axes('units','norm','position',[.1 .5 .8 .4]); for ncond=1:3, x=subData.(dispconds{ncond}).F1-subData.(dispconds{1}).F1(:,round(linspace(1,size(subData.(dispconds{1}).F1,2),size(subData.(dispconds{ncond}).F1,2))));                mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1); x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('mic F1 (Hz)'); legend(h,dispconds(1:3));
        set(gca,'ylim',50*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(400,.8*min(cellfun(@min,get(h,'ydata')))) min(1000,1.2*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
    else % normed units?
        h=[]; axes('units','norm','position',[.1 .5 .8 .4]); for ncond=1:3,
            x =subData.(dispconds{ncond}).F1-subData.(dispconds{1}).F1(:,round(linspace(1,size(subData.(dispconds{1}).F1,2),size(subData.(dispconds{ncond}).F1,2))));
            x0=ch2subData.(dispconds{ncond}).F1-ch2subData.(dispconds{1}).F1(:,round(linspace(1,size(ch2subData.(dispconds{1}).F1,2),size(ch2subData.(dispconds{ncond}).F1,2))));
            x=100*x./max(eps,abs(mean(x0(t0:end,:),1,'omitnan')));
            mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1); x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('mic F1 (% of perturbation)'); legend(h,dispconds(1:3));
        set(gca,'ylim',100*[-1 1],'ytick',-80:20:80,'yticklabel',arrayfun(@(x)sprintf('%d%%',x),-80:20:80,'uni',0)); %cellfun(@(n)set(n,'ylim',[max(400,.8*min(cellfun(@min,get(h,'ydata')))) min(1000,1.2*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
    end
    if DOPRINT, conn_print(sprintf('fig_effectF1b_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
    
    if all(ismember({'D0','N0','U0'},qcData.condLabel))
        figure('units','norm','position',[.2 .0 .6 .7]);
        h=[]; axes('units','norm','position',[.1 .1 .8 .4]); for ncond=4:6, x=ch2subData.(dispconds{ncond}).F0-ch2subData.(dispconds{4}).F0(:,round(linspace(1,size(ch2subData.(dispconds{4}).F0,2),size(ch2subData.(dispconds{ncond}).F0,2))));mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond-3,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('headphones F0 (Hz)'); legend(h,dispconds(4:6));
        set(gca,'ylim',20*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(40,.9*min(cellfun(@min,get(h,'ydata')))) min(300,1.1*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
        h=[]; axes('units','norm','position',[.1 .5 .8 .4]); for ncond=4:6, x=subData.(dispconds{ncond}).F0-subData.(dispconds{4}).F0(:,round(linspace(1,size(subData.(dispconds{4}).F0,2),size(subData.(dispconds{ncond}).F0,2))));            mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond-3,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('mic F0 (Hz)'); legend(h,dispconds(4:6));
        set(gca,'ylim',10*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(40,.9*min(cellfun(@min,get(h,'ydata')))) min(300,1.1*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
        if DOPRINT, conn_print(sprintf('fig_effectF0b_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
    end
else
    dispconds={'S','Js','Ls','S','Fs','Ls'};
    figure('units','norm','position',[.2 .3 .6 .7]);
    h=[];
    try, axes('units','norm','position',[.1+.8/3*0 .1 .8/3 .4]); h=[h plot(subData.(dispconds{4}).F0,'.-')]; k=mean(median(subData.(dispconds{4}).F0(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{4}); xline(t0,'linewidth',3); ylabel('mic F0 (Hz)'); 
    try, axes('units','norm','position',[.1+.8/3*1 .1 .8/3 .4]); h=[h plot(subData.(dispconds{5}).F0,'.-')]; k=mean(median(subData.(dispconds{5}).F0(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{5}); set(gca,'yticklabel',[]); xline(t0,'linewidth',3); 
    try, axes('units','norm','position',[.1+.8/3*2 .1 .8/3 .4]); h=[h plot(subData.(dispconds{6}).F0,'.-')]; k=mean(median(subData.(dispconds{6}).F0(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{6}); set(gca,'yticklabel',[]); xline(t0,'linewidth',3); 
    try, axes('units','norm','position',[.1+.8/3*0 .5 .8/3 .4]); h=[h plot(subData.(dispconds{1}).F1,'.-')]; k=mean(median(subData.(dispconds{1}).F1(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{4}); xline(t0,'linewidth',3); ylabel('mic F1 (Hz)'); 
    try, axes('units','norm','position',[.1+.8/3*1 .5 .8/3 .4]); h=[h plot(subData.(dispconds{2}).F1,'.-')]; k=mean(median(subData.(dispconds{2}).F1(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{5}); set(gca,'yticklabel',[]); xline(t0,'linewidth',3); 
    try, axes('units','norm','position',[.1+.8/3*2 .5 .8/3 .4]); h=[h plot(subData.(dispconds{3}).F1,'.-')]; k=mean(median(subData.(dispconds{3}).F1(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{6}); set(gca,'yticklabel',[]); xline(t0,'linewidth',3); 
    cellfun(@(n)set(n,'ylim',[min(cellfun(@min,get(h,'ydata'))) min(1000,max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
    if DOPRINT, conn_print(sprintf('fig_effectF0F1_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
end
drawnow

varargout={subData,ch2subData};

% if 0
%     DOPRINT=true;
%     REDOFMT=true;
%     figure(1);
%     names={'7 (jason)','3 (rohan)','6 (ricky)','2 (liam)','8 (latane)','5 (jackie)','4 (bobbie)','1 (dave)'};
%     subnames={'','sub-test244','sub-test245','sub-test249','sub-test250','sub-test252','sub-test257','sub-test258'};
%     for nsub=1:numel(subnames), if ~isempty(subnames{nsub}), filepath=fullfile(pwd,subnames{nsub}); flvoice_update; end; end
% end

                