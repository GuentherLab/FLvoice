
function varargout=flvoice_load(SUB,SES,RUN,TASK, DOSAVE, DOPRINT, REDOFMT, DOREMOTE, FILEPATH)
% data = flvoice_load(SUB,RUN,SES,TASK, DOSAVE, DOPRINT, REDOFMT, DOREMOTE, FILEPATH)
% processes audio data from aud/som experiment
%   SUB             : subject id (e.g. 'test244' or 'sub-test244')
%   SES             : session number (e.g. 1 or 'ses-1')
%   RUN             : run number (e.g. 1 or 'run-1')
%   TASK            : task type 'aud' or 'som'
%   REDOFMT         : (default 1) 1/0 re-compute formants&pitch trajectories
%   DOSAVE          : (default 0) 1/0 save formant&pitch trajectory files
%   DOPRINT         : (default 1) 1/0 save jpg files with formant&pitch trajectories
%   DOREMOTE        : (default 0) 1/0 work remotely (0: work from SCC computer; 1: work remotely -run "conn remotely on" first from your home computer to connect to SCC; for first-time initialization run on remote server "conn remotely setup")
%   FILEPATH        : (default '/projectnb/busplab/Experiments/SAP-PILOT/') path to folder containing all subject's data
%
% Alternative syntax:
%   flvoice_load                         : returns list of available subjects
%   flvoice_load SUB                     : returns list of available sessions for this subject
%   flvoice_load SUB SES                 : returns list of available runs for this subject & session
%   flvoice_load SUB SES RUN             : returns list of available tasks for this subject & session & run
%   flvoice_load SUB all RUN TASK ...    : runs flvoice_load using data from all available sessions for this subject & run & task
%   flvoice_load SUB SES all TASK ...    : runs flvoice_load using data from all available runs for this subject & session & task
%   flvoice_load default <optionname> <defaultvalue>  : changes default values for DOSAVE/DOPRINT/REDOFMT/DOREMOTE/FILEPATH options above (changes will affect all subsequent flvoice_load commands where those options are not explicitly defined; defaults will revert back to their original values after your Matlab session ends)
%

persistent DEFAULTS;
if isempty(DEFAULTS), DEFAULTS=struct('DOSAVE',true,'DOPRINT',false,'REDOFMT',false,'DOREMOTE',false,'FILEPATH',pwd); end %'/projectnb/busplab/Experiments/SAP-PILOT/'); end    
if nargin==1&&isequal(SUB,'default'), if nargout>0, varargout={DEFAULTS}; else disp(DEFAULTS); end; return; end
if nargin>1&&isequal(SUB,'default'), assert(isfield(DEFAULTS,upper(SES)),'unrecognized default field %s',SES); DEFAULTS.(upper(SES))=RUN; return; end

if nargin<1||isempty(SUB), SUB=[]; end
if iscell(SUB)||ischar(SUB), SUB=regexprep(SUB,'^sub-',''); end
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
if ischar(SUB), SUB={SUB}; end
if isempty(SES)||isequal(SES,0),
    SUBS={};
    SESS={};
    for nSUB=1:numel(SUB)
        [nill,sess]=cellfun(@fileparts,conn_dir(fullfile(FILEPATH,sprintf('sub-%s',SUB{nSUB}),'ses-*'),'-dir','-R','-cell'),'uni',0);
        SESS=[SESS; sess(:)];
        SUBS=[SUBS; repmat(SUB(nSUB),numel(sess),1)];
    end
    disp('available sessions:');
    disp(char(SESS));
    if isempty(SES)
        if nargout, varargout={SESS}; end
        return
    end
    SES=str2double(regexprep(SESS,'^ses-',''));
    SUB=SUBS;
end
if isempty(RUN)||isequal(RUN,0),
    SUBS={};
    SESS=[];
    RUNS={};
    for nSUB=1:numel(SUB)
        for nSES=1:numel(SES)
            [nill,runs]=cellfun(@fileparts,conn_dir(fullfile(FILEPATH,sprintf('sub-%s',SUB{nSUB}),sprintf('ses-%d',SES(nSES)),'run-*'),'-dir','-R','-cell'),'uni',0);
            RUNS=[RUNS; runs(:)];
            SESS=[SESS; SES(nSES)+zeros(numel(runs),1)];
            SUBS=[SUBS; repmat(SUB(nSUB),numel(runs),1)];
        end
    end
    disp('available runs:');
    disp(char(RUNS));
    if isempty(RUN)
        if nargout, varargout={RUNS}; end
        return
    end
    RUN=str2double(regexprep(RUNS,'^run-',''));
    SES=SESS;
    SUB=SUBS;
end
SUBS=SUB;
SESS=SES;
RUNS=RUN;
if numel(SUBS)==1&&numel(SESS)==1&&numel(RUNS)>1, SUBS=repmat(SUBS,size(RUNS)); SESS=SESS+zeros(size(RUNS)); end
if numel(SUBS)==1&&numel(SESS)>1&&numel(RUNS)==1, SUBS=repmat(SUBS,size(SESS)); RUNS=RUNS+zeros(size(SESS)); end
if numel(SUBS)>1&&numel(SESS)==1&&numel(RUNS)==1, SESS=SESS+zeros(size(SUBS)); RUNS=RUNS+zeros(size(SUBS)); end

if isempty(TASK)
    TASKS={};
    for nsample=1:numel(RUNS)
        RUN=RUNS(nsample);
        SES=SESS(nsample);
        SUB=SUBS{nsample};
        [nill,tasks]=cellfun(@fileparts,conn_dir(fullfile(FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-*_expParams.mat',SUB,SES,RUN)),'-R','-cell'),'uni',0);
        TASKS=[TASKS; tasks(:)];
    end
    TASKS=regexprep(TASKS,{'^.*_task-','_expParams$'},'');
    disp('available tasks:');
    disp(char(TASKS));
    if nargout, varargout={TASKS}; end
    return
end

subData=[];
for nsample=1:numel(RUNS)
    RUN=RUNS(nsample);
    SES=SESS(nsample);
    SUB=SUBS{nsample};
    filename_trialData=fullfile(FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-%s.mat',SUB,SES,RUN,TASK));
    filename_fmtData=fullfile(FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-formants.mat',SUB,SES,RUN,TASK));
    if ~conn_existfile(filename_trialData), fprintf('file %s not found, skipping this run\n',filename_trialData);
    else
        fprintf('loading file %s\n',filename_trialData);
        expParams=[]; trialData=[];
        conn_loadmatfile(filename_trialData,'expParams','trialData','-cache');
        if ~isfield(expParams,'gender'), expParams.gender='unknown'; end
        
        offlineFmts=[];
        offlinePrms=[];
        if REDOFMT||~conn_existfile(filename_fmtData)
            for trialNum=1:numel(trialData)
                data=trialData(trialNum);
                
                %Nlpc=round(1.25*trialData(trialNum).p.nLPC);
                if isfield(data,'audapData'), % audapter format
                    s=data.audapData.signalIn;
                    fs=16000;
                    Nlpc=trialData(trialNum).p.nLPC;
                elseif isfield(data,'audioData') % audiodevicereader format
                    s=data.audioData.signalIn;
                    fs=48000;
                    if isequal(lower(expParams.gender),'female'), Nlpc=15;
                    elseif isequal(lower(expParams.gender),'male'), Nlpc=17;
                    else Nlpc=17;
                    end
                elseif isfield(data,'audio') % raw audio format
                    s=data.audio.s;
                    fs=data.audio.fs;
                    if isequal(lower(expParams.gender),'female'), Nlpc=15;
                    elseif isequal(lower(expParams.gender),'male'), Nlpc=17;
                    else Nlpc=17;
                    end
                end
                if isequal(lower(expParams.gender),'female'), f0range=[150 300];
                elseif isequal(lower(expParams.gender),'male'), f0range=[50 200];
                else f0range=[50 300];
                end
                fprintf('estimating formants trial #%d\n',trialNum);
                if fs~=16000, s=resample(s,16000,fs); fs=16000; end
                [fmt,t,svar]=flvoice_formants(s,fs,6,'lpcorder',Nlpc,'windowsize',.050,'stepsize',.001);
                f0=flvoice_pitch(s,fs,'f0_t',t,'range',f0range);
                offlineFmts(trialNum).mic = interp1(t',fmt',(0:.001:(numel(s)-1)/fs)','lin',nan);     % formant trajectories; note: (implicit timing) these data starts at t=0 and it is sampled at offlineFmts(trialNum).fs rate
                offlinePrms(trialNum).mic = [t(:), f0, 10*log10(svar(:))+100];                        % time/pitch/amplitude trajectories; note: (explicit timing) these data explicitly lists the time of each sample (first column)
                
                if isfield(data,'audapData')
                    s=data.audapData.signalOut;
                    [fmt,t,svar]=flvoice_formants(s,fs,6,'lpcorder',Nlpc,'windowsize',.050,'stepsize',.001);
                    f0=flvoice_pitch(s,fs,'f0_t',t);
                    offlineFmts(trialNum).phones = interp1(t',fmt',(0:.001:(numel(s)-1)/fs)','lin',nan);
                    offlinePrms(trialNum).phones = [t(:), f0, 10*log10(svar(:))+100];
                    %figure(11); plot(f0,'-'); disp(trialData(trialNum).condLabel); pause;
                end
                offlineFmts(trialNum).fs=1000;
            end
            if DOSAVE
                conn_fileutils('mkdir',fileparts(filename_fmtData));
                conn_savematfile(filename_fmtData,'offlineFmts','offlinePrms');
            end
        else
            assert(conn_existfile(filename_fmtData),'file %s not found',filename_fmtData);
            fprintf('loading file %s\n',filename_fmtData);
            conn_loadmatfile(filename_fmtData,'offlineFmts','offlinePrms','-cache');
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
                if isnumeric(offlinePrms(trialNum).mic), praatrialData_Mic = offlinePrms(trialNum).mic;
                else praatrialData_Mic = Praatfileread(offlinePrms(trialNum).mic);
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
                    if isnumeric(offlinePrms(trialNum).phones), praatrialData_Head = offlinePrms(trialNum).phones;
                    else praatrialData_Head = Praatfileread(offlinePrms(trialNum).phones);
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
            
            tempOut.DATA(trialNum) = DATA;
        end
        try, condLabel = {trialData.condLabel};
        catch, condLabel = repmat({'unknown'},1,numel(trialData));
        end
        try, pertSize = arrayfun(@(n)max([nan trialData(n).pertSize]),1:numel(trialData)); 
        catch, pertSize = nan(1,numel(trialData));
        end
        keepData=true(1,numel(trialData)); % note: this will be read from QC module
        DATA=tempOut.DATA;
        clear tempOut;
        if DOSAVE
            fprintf('saving file %s\n',filename_fmtData);
            conn_fileutils('mkdir',fileparts(filename_fmtData));
            conn_savematfile(filename_fmtData,'DATA','condLabel','keepData','pertSize','-append');
        end
        
        % aggregated data cross runs
        dLabels = [{'F0'}   {'F1'}  {'F2'}  {'Int'}];
        cLabels = unique(condLabel);
        for cidx = 0:length(cLabels)
            if cidx,
                clabel=cLabels{cidx};
                curCond = find(strcmp(condLabel, clabel));
            else
                clabel='all';
                curCond = 1:numel(condLabel);
            end
            keepIdx = intersect(find(keepData),curCond);
            % Loop through each data trace type (dLabels) to aggregate data
            % from each run
            for didx = 1:length(dLabels)
                if ~isfield(subData,clabel)||~isfield(subData.(clabel),dLabels{didx})
                    subData.(clabel).(dLabels{didx}) = [];
                    ch2subData.(clabel).(dLabels{didx}) = [];
                end
                if ~isempty(keepIdx)&&isfield(DATA(keepIdx(1)).ch1.pertaligned,dLabels{didx})
                    tmpData = cell2mat(arrayfun(@(n)reshape(DATA(n).ch1.pertaligned.(dLabels{didx}),[],1),keepIdx,'uni',0));
                    subData.(clabel).(dLabels{didx}) = ...
                        [subData.(clabel).(dLabels{didx}) tmpData];
                    if isfield(DATA(keepIdx(1)),'ch2')
                        tmpData = cell2mat(arrayfun(@(n)reshape(DATA(n).ch2.pertaligned.(dLabels{didx}),[],1),keepIdx,'uni',0));
                        ch2subData.(clabel).(dLabels{didx}) = ...
                            [ch2subData.(clabel).(dLabels{didx}) tmpData];
                    end
                end
            end
            if ~isfield(subData.(clabel),'pertSize')
                subData.(clabel).pertSize = [];
            end
            subData.(clabel).pertSize = [subData.(clabel).pertSize pertSize(keepIdx)];
        end
    end
end

t0=1000*DATA(1).pertaligned_delta;
fs=DATA(1).fs;
if isequal(TASK,'aud'),
    dispconds={'N1','D1','U1','N0','D0','U0'};
    
    % raw plots
    figure('units','norm','position',[.2 .3 .6 .7]);
    h=[];
    for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .1 .8/3 .4]); x=ch2subData.(dispconds{ncond}).F1; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('headphones F1 (Hz)'); else set(gca,'yticklabel',[]); end; xlabel('time (ms)'); end
    for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .5 .8/3 .4]);    x=subData.(dispconds{ncond}).F1; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('mic F1 (Hz)'); else set(gca,'yticklabel',[]); end; set(gca,'xticklabel',[]); end
    try, cellfun(@(n)set(n,'ylim',[min(cellfun(@min,get(h,'ydata'))) min(1000,max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0); end
    if DOPRINT, conn_print(sprintf('fig_effectF1a_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
    if all(ismember({'D0','N0','U0'},condLabel))
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
    h=[]; axes('units','norm','position',[.1 .5 .8 .4]); for ncond=1:3, x=subData.(dispconds{ncond}).F1-subData.(dispconds{1}).F1(:,round(linspace(1,size(subData.(dispconds{1}).F1,2),size(subData.(dispconds{ncond}).F1,2))));                mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1); x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('mic F1 (Hz)'); legend(h,dispconds(1:3));
    set(gca,'ylim',50*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(400,.8*min(cellfun(@min,get(h,'ydata')))) min(1000,1.2*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
    if DOPRINT, conn_print(sprintf('fig_effectF1b_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
    
    if all(ismember({'D0','N0','U0'},condLabel))
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
%     for nsub=1:numel(subnames), if ~isempty(subnames{nsub}), filepath=fullfile(pwd,subnames{nsub}); flvoice_load; end; end
% end

                