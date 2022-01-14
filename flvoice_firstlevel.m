
function varargout=flvoice_firstlevel(SUB,SES,RUN,TASK,MEASURE,DESIGN,CONTRAST, varargin)
% data = flvoice_firstlevel(SUB,RUN,SES,TASK) : runs first-level model estimation on audio data
%   SUB              : subject id (e.g. 'test244' or 'sub-test244')
%   SES              : session number (e.g. 1 or 'ses-1')
%   RUN              : run number (e.g. 1 or 'run-1')
%   TASK             : task type 'aud' or 'som'
%   MEASURE          : condLabel value (e.g. 'F1-mic')
%   DESIGN           : condition names defining first-level contrast
%                          e.g. {'U1','N1'}
%                      alternatively, function defining one row of design matrix (one row per trial)
%                         fun(condLabel, sesNumber, runNumber, trialNumber) should return a [1,N] vector of values associated with this trial
%                          e.g. @(condLabel,sesNumber,runNumber,trialNumber)[strcmp(condLabel,'U1') strcmp(condLabel,'N1')]
%   CONTRAST         : condition weights defining first-level contrast
%                          e.g. [1, -1]
%
% Input data files: $ROOT$/derivatives/acoustic/sub-##/ses-##/run-##/sub-##_ses-##_run-##_task-##_desc-formants.mat
%   Variables:
%       trialData(n)                 : trial data structure
%             trialData(n).s                 : formant and pitch timeseries (cell array)
%             trialData(n).fs                : sampling frequency (Hz)
%             trialData(n).t                 : time of initial sample (seconds)
%             trialData(n).condLabel         : condition label/name associated with this trial
%             trialData(n).dataLabel         : data labels (cell array) {'F0','F1','F2','Amp','rawF0','rawF1','rawF2','rawAmp'}
%

persistent DEFAULTS;
if isempty(DEFAULTS), DEFAULTS=struct('DOSAVE',true,'DOPRINT',true,'OVERWRITE',true); end 
if nargin==1&&isequal(SUB,'default'), if nargout>0, varargout={DEFAULTS}; else disp(DEFAULTS); end; return; end
if nargin>1&&isequal(SUB,'default'), 
    if nargin>=7, varargin=[{CONTRAST},varargin]; end
    if nargin>=6, varargin=[{DESIGN},varargin]; end
    if nargin>=5, varargin=[{MEASURE},varargin]; end
    if nargin>=4, varargin=[{TASK},varargin]; end
    if nargin>=3, varargin=[{RUN},varargin]; end
    if nargin>=2, varargin=[{SES},varargin]; end
    for n=1:2:numel(varargin)-1, assert(isfield(DEFAULTS,upper(varargin{n})),'unrecognized default field %s',varargin{n}); DEFAULTS.(upper(varargin{n}))=varargin{n+1}; fprintf('default %s value changed to %s\n',upper(varargin{n}),mat2str(varargin{n+1})); end
    return
end

if nargin<1||isempty(SUB), SUB=[]; end
if iscell(SUB)||ischar(SUB), SUB=regexprep(SUB,'^sub-',''); end
if nargin<2||isempty(SES), SES=[]; end
if ischar(SES)&&strcmpi(SES,'all'), SES=0; end
if ischar(SES), SES=str2num(regexprep(SES,'^ses-','')); end
if nargin<3||isempty(RUN), RUN=[]; end
if ischar(RUN)&&strcmpi(RUN,'all'), RUN=0; end
if ischar(RUN), RUN=str2num(regexprep(RUN,'^run-','')); end
if nargin<4||isempty(TASK), TASK=[]; end
if nargin<5||isempty(MEASURE), MEASURE='F1'; end
if nargin<6||isempty(DESIGN), DESIGN={}; end
if nargin<7||isempty(CONTRAST), CONTRAST=[]; end

OPTIONS=DEFAULTS;
if numel(varargin)>0, for n=1:2:numel(varargin)-1, assert(isfield(DEFAULTS,upper(varargin{n})),'unrecognized default field %s',varargin{n}); OPTIONS.(upper(varargin{n}))=varargin{n+1}; fprintf('%s = %s\n',upper(varargin{n}),mat2str(varargin{n+1})); end; end
if ischar(OPTIONS.OVERWRITE), OPTIONS.OVERWRITE=str2num(OPTIONS.OVERWRITE); end
if ischar(OPTIONS.DOSAVE), OPTIONS.DOSAVE=str2num(OPTIONS.DOSAVE); end
if ischar(OPTIONS.DOPRINT), OPTIONS.DOPRINT=str2num(OPTIONS.DOPRINT); end
OPTIONS.FILEPATH=flvoice('PRIVATE.ROOT');
varargout=cell(1,nargout);


if isempty(SUB),
    [nill,SUBS]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,'sub-*'),'-dir','-R','-cell'),'uni',0);
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
        [nill,sess]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB{nSUB}),'ses-*'),'-dir','-R','-cell'),'uni',0);
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
            [nill,runs]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB{nSUB}),sprintf('ses-%d',SES(nSES)),'run-*'),'-dir','-R','-cell'),'uni',0);
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
        [nill,tasks1]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-*_desc-audio.mat',SUB,SES,RUN)),'-R','-cell'),'uni',0);
        [nill,tasks2]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-*_expParams.mat',SUB,SES,RUN)),'-R','-cell'),'uni',0);
        tasks=union(tasks1,tasks2);
        TASKS=[TASKS; tasks(:)];
    end
    TASKS=unique(regexprep(TASKS,{'^.*_task-','_expParams$|_desc-audio$'},''));
    disp('available tasks:');
    disp(char(TASKS));
    if nargout, varargout={TASKS}; end
    return
end

for nsample=1:numel(RUNS)
    RUN=RUNS(nsample);
    SES=SESS(nsample);
    SUB=SUBS{nsample};
    filename_fmtData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-formants.mat',SUB,SES,RUN,TASK));
    if ~conn_existfile(filename_fmtData), fprintf('file %s not found, skipping this run\n',filename_fmtData);
    else
        fprintf('loading file %s\n',filename_fmtData);
        tdata=conn_loadmatfile(filename_fmtData,'-cache');
        assert(isfield(tdata,'trialData'), 'data file %s does not contain trialData variable',filename_fmtData);
        out_trialData = tdata.trialData;

        filename_qcData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-qualitycontrol.mat',SUB,SES,RUN,TASK));
        if conn_existfile(filename_qcData), 
            fprintf('loading file %s\n',filename_qcData);
            tdata=conn_loadmatfile(filename_qcData,'-cache');
            assert(isfield(tdata,'keepData'), 'data file %s does not contain keepData variable',filename_qcData);
            keepData=tdata.keepData;
        else
            fprintf('file %s not found, assuming all trials are valid\n',filename_qcData);
            keepData=true(1,numel(out_trialData)); 
        end
        
        % plots
        figure('units','norm','position',[.2 .2 .6 .6],'name',sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-formants.mat',SUB,SES,RUN,TASK));
        lnames=unique([out_trialData.dataLabel]);
        for idx=1:numel(lnames), hax(idx)=subplot(floor(sqrt(numel(lnames))),ceil(numel(lnames)/floor(sqrt(numel(lnames)))),idx); hold all; title(lnames{idx}); end
        for trialNum=reshape(find(keepData),1,[])
            for ns=1:numel(out_trialData(trialNum).s),
                t=out_trialData(trialNum).t{ns}+(0:numel(out_trialData(trialNum).s{ns})-1)/out_trialData(trialNum).fs;
                x=out_trialData(trialNum).s{ns};
                [ok,idx]=ismember(out_trialData(trialNum).dataLabel{ns},lnames);
                h=plot(t,x,'.-','parent',hax(idx));
                set(h,'buttondownfcn',@(varargin)fprintf('trial # %d\n',trialNum));
            end
        end
        for idx=1:numel(lnames), axis(hax(idx),'tight'); grid(hax(idx),'on'); end
        drawnow
        %if OPTIONS.DOPRINT, conn_print(conn_prepend('',filename_fmtData,'.jpg'),'-nogui'); end
        
%         % aggregated data cross runs
%         dLabels = [{'F0'}   {'F1'}  {'F2'}  {'Amp'}];
%         cLabels = unique(condLabel);
%         for cidx = 0:length(cLabels)
%             if cidx,
%                 clabel=cLabels{cidx};
%                 curCond = find(strcmp(condLabel, clabel));
%             else
%                 clabel='all';
%                 curCond = 1:numel(condLabel);
%             end
%             keepIdx = intersect(find(keepData),curCond);
%             % Loop through each data trace type (dLabels) to aggregate data
%             % from each run
%             for didx = 1:length(dLabels)
%                 if ~isfield(subData,clabel)||~isfield(subData.(clabel),dLabels{didx})
%                     subData.(clabel).(dLabels{didx}) = [];
%                     ch2subData.(clabel).(dLabels{didx}) = [];
%                 end
%                 if ~isempty(keepIdx)&&isfield(DATA(keepIdx(1)).ch1.pertaligned,dLabels{didx})
%                     tmpData = cell2mat(arrayfun(@(n)reshape(DATA(n).ch1.pertaligned.(dLabels{didx}),[],1),keepIdx,'uni',0));
%                     subData.(clabel).(dLabels{didx}) = ...
%                         [subData.(clabel).(dLabels{didx}) tmpData];
%                     if isfield(DATA(keepIdx(1)),'ch2')
%                         tmpData = cell2mat(arrayfun(@(n)reshape(DATA(n).ch2.pertaligned.(dLabels{didx}),[],1),keepIdx,'uni',0));
%                         ch2subData.(clabel).(dLabels{didx}) = ...
%                             [ch2subData.(clabel).(dLabels{didx}) tmpData];
%                     end
%                 end
%             end
%             if ~isfield(subData.(clabel),'pertSize')
%                 subData.(clabel).pertSize = [];
%             end
%             subData.(clabel).pertSize = [subData.(clabel).pertSize pertSize(keepIdx)];
%         end
    end
end

% t0=1000*DATA(1).pertaligned_delta;
% fs=DATA(1).fs;
% if isequal(TASK,'aud'),
%     dispconds={'N1','D1','U1','N0','D0','U0'};
%     
%     % raw plots
%     figure('units','norm','position',[.2 .3 .6 .7]);
%     h=[];
%     for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .1 .8/3 .4]); x=ch2subData.(dispconds{ncond}).F1; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('headphones F1 (Hz)'); else set(gca,'yticklabel',[]); end; xlabel('time (ms)'); end
%     for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .5 .8/3 .4]);    x=subData.(dispconds{ncond}).F1; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('mic F1 (Hz)'); else set(gca,'yticklabel',[]); end; set(gca,'xticklabel',[]); end
%     try, cellfun(@(n)set(n,'ylim',[min(cellfun(@min,get(h,'ydata'))) min(1000,max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0); end
%     if OPTIONS.DOPRINT, conn_print(sprintf('fig_effectF1a_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
%     if all(ismember({'D0','N0','U0'},condLabel))
%         figure('units','norm','position',[.2 .0 .6 .7]);
%         h=[];
%         for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .1 .8/3 .4]); x=ch2subData.(dispconds{3+ncond}).F0; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{3+ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('headphones F0 (Hz)'); else set(gca,'yticklabel',[]); end; xlabel('time (ms)'); end
%         for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .5 .8/3 .4]);    x=subData.(dispconds{3+ncond}).F0; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{3+ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('mic F0 (Hz)'); else set(gca,'yticklabel',[]); end; set(gca,'xticklabel',[]); end
%         try, cellfun(@(n)set(n,'ylim',[min(cellfun(@min,get(h,'ydata'))) min(500,max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0); end
%         if OPTIONS.DOPRINT, conn_print(sprintf('fig_effectF0a_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
%     end
%     
%     % summary plots
%     color=[ 0.9290/4 0.6940/4 0.1250/4; 0.8500 0.3250 0.0980; 0 0.4470 0.7410];
%     figure('units','norm','position',[.2 .3 .6 .7]); 
%     h=[]; axes('units','norm','position',[.1 .1 .8 .4]); for ncond=1:3, x=ch2subData.(dispconds{ncond}).F1-ch2subData.(dispconds{1}).F1(:,round(linspace(1,size(ch2subData.(dispconds{1}).F1,2),size(ch2subData.(dispconds{ncond}).F1,2))));        mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1); x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('headphones F1 (Hz)'); legend(h,dispconds(1:3)); 
%     set(gca,'ylim',100*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(400,.8*min(cellfun(@min,get(h,'ydata')))) min(1000,1.2*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
%     h=[]; axes('units','norm','position',[.1 .5 .8 .4]); for ncond=1:3, x=subData.(dispconds{ncond}).F1-subData.(dispconds{1}).F1(:,round(linspace(1,size(subData.(dispconds{1}).F1,2),size(subData.(dispconds{ncond}).F1,2))));                mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1); x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('mic F1 (Hz)'); legend(h,dispconds(1:3));
%     set(gca,'ylim',50*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(400,.8*min(cellfun(@min,get(h,'ydata')))) min(1000,1.2*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
%     if OPTIONS.DOPRINT, conn_print(sprintf('fig_effectF1b_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
%     
%     if all(ismember({'D0','N0','U0'},condLabel))
%         figure('units','norm','position',[.2 .0 .6 .7]);
%         h=[]; axes('units','norm','position',[.1 .1 .8 .4]); for ncond=4:6, x=ch2subData.(dispconds{ncond}).F0-ch2subData.(dispconds{4}).F0(:,round(linspace(1,size(ch2subData.(dispconds{4}).F0,2),size(ch2subData.(dispconds{ncond}).F0,2))));mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond-3,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('headphones F0 (Hz)'); legend(h,dispconds(4:6));
%         set(gca,'ylim',20*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(40,.9*min(cellfun(@min,get(h,'ydata')))) min(300,1.1*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
%         h=[]; axes('units','norm','position',[.1 .5 .8 .4]); for ncond=4:6, x=subData.(dispconds{ncond}).F0-subData.(dispconds{4}).F0(:,round(linspace(1,size(subData.(dispconds{4}).F0,2),size(subData.(dispconds{ncond}).F0,2))));            mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond-3,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('mic F0 (Hz)'); legend(h,dispconds(4:6));
%         set(gca,'ylim',10*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(40,.9*min(cellfun(@min,get(h,'ydata')))) min(300,1.1*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
%         if OPTIONS.DOPRINT, conn_print(sprintf('fig_effectF0b_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
%     end
% else
%     dispconds={'S','Js','Ls','S','Fs','Ls'};
%     figure('units','norm','position',[.2 .3 .6 .7]);
%     h=[];
%     try, axes('units','norm','position',[.1+.8/3*0 .1 .8/3 .4]); h=[h plot(subData.(dispconds{4}).F0,'.-')]; k=mean(median(subData.(dispconds{4}).F0(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{4}); xline(t0,'linewidth',3); ylabel('mic F0 (Hz)'); 
%     try, axes('units','norm','position',[.1+.8/3*1 .1 .8/3 .4]); h=[h plot(subData.(dispconds{5}).F0,'.-')]; k=mean(median(subData.(dispconds{5}).F0(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{5}); set(gca,'yticklabel',[]); xline(t0,'linewidth',3); 
%     try, axes('units','norm','position',[.1+.8/3*2 .1 .8/3 .4]); h=[h plot(subData.(dispconds{6}).F0,'.-')]; k=mean(median(subData.(dispconds{6}).F0(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{6}); set(gca,'yticklabel',[]); xline(t0,'linewidth',3); 
%     try, axes('units','norm','position',[.1+.8/3*0 .5 .8/3 .4]); h=[h plot(subData.(dispconds{1}).F1,'.-')]; k=mean(median(subData.(dispconds{1}).F1(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{4}); xline(t0,'linewidth',3); ylabel('mic F1 (Hz)'); 
%     try, axes('units','norm','position',[.1+.8/3*1 .5 .8/3 .4]); h=[h plot(subData.(dispconds{2}).F1,'.-')]; k=mean(median(subData.(dispconds{2}).F1(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{5}); set(gca,'yticklabel',[]); xline(t0,'linewidth',3); 
%     try, axes('units','norm','position',[.1+.8/3*2 .5 .8/3 .4]); h=[h plot(subData.(dispconds{3}).F1,'.-')]; k=mean(median(subData.(dispconds{3}).F1(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; title(dispconds{6}); set(gca,'yticklabel',[]); xline(t0,'linewidth',3); 
%     cellfun(@(n)set(n,'ylim',[min(cellfun(@min,get(h,'ydata'))) min(1000,max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
%     if OPTIONS.DOPRINT, conn_print(sprintf('fig_effectF0F1_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
% end
% drawnow
% 
% varargout={subData,ch2subData};

% if 0
%     DOPRINT=true;
%     OVERWRITE=true;
%     figure(1);
%     names={'7 (jason)','3 (rohan)','6 (ricky)','2 (liam)','8 (latane)','5 (jackie)','4 (bobbie)','1 (dave)'};
%     subnames={'','sub-test244','sub-test245','sub-test249','sub-test250','sub-test252','sub-test257','sub-test258'};
%     for nsub=1:numel(subnames), if ~isempty(subnames{nsub}), filepath=fullfile(pwd,subnames{nsub}); flvoice_import; end; end
% end

                