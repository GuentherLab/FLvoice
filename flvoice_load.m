
function varargout=flvoice_load(SUB,SES,RUN,TASK, varargin)
% data = flvoice_load(SUB,RUN,SES,TASK) : imports audio data, and computes formant and pitch trajectories for each trial
%   SUB             : subject id (e.g. 'test244' or 'sub-test244')
%   SES             : session number (e.g. 1 or 'ses-1')
%   RUN             : run number (e.g. 1 or 'run-1')
%   TASK            : task type 'aud' or 'som'
%
% Input data files: sub-##/ses-##/run-##/sub-##_ses-##_run-##_task-##_desc-audio.mat
%   Variables:
%       gender                       : subject gender 'male', 'female' (alternatively gender = expParams.gender) 
%       trialData(n)                 : trial data structure
%             trialData(n).s                 : audiowave timeseries (alternatively s = trialData(n).audapData.signalIn for Audapter data with fs=16000Hz; alternatively s = trialData(n).audioData.signalIn for devicereader data with fs=48000Hz)
%             trialData(n).fs                : sampling frequency (Hz)
%             trialData(n).t                 : time of initial sample (seconds)
%             trialData(n).reference_time    : reference time in trialData(n).s for time-alignment (s) (alternatively reference_time = trialData(n).timingTrial(4)-trialData(n).timingTrial(2))
%             trialData(n).condLabel         : condition label/name associated with this trial
%             trialData(n).dataLabel         : data labels (if trialData(n).s is a cell array defining multiple timeseries, trialData(n).labels defines the labels of each element)
%
% Output data files: derivatives/acoustic/sub-##/ses-##/run-##/sub-##_ses-##_run-##_task-##_desc-formants.mat
%   Variables:
%       trialData(n)                 : trial data structure
%             trialData(n).s                 : formant and pitch timeseries (cell array)
%             trialData(n).fs                : sampling frequency (Hz)
%             trialData(n).t                 : time of initial sample (seconds)
%             trialData(n).condLabel         : condition label/name associated with this trial
%             trialData(n).dataLabel         : data labels (cell array) {'F0','F1','F2','Int','rawF0','rawF1','rawF2','rawInt'}
%
% Output data files: derivatives/acoustic/sub-##/ses-##/run-##/sub-##_ses-##_run-##_task-##_desc-summary.mat
%   Variables:
%       trialData(n)                 : trial data structure
%             trialData(n).s                 : summary measures (cell array)
%             trialData(n).condLabel         : condition label/name associated with this trial
%             trialData(n).dataLabel         : data labels (cell array)
%
% data = flvoice_load(SUB,RUN,SES,TASK [, OPTION_NAME, OPTION_VALUE, ...]) : overrides default options (see below)
%   'NLPC'            : number of LPC coefficients for formant estimation (default -when empty- 17 for male and 15 for female subjects; note: data resampled to 16KHz)
%   'F0RANGE'         : valid range for pitch estimation (Hz) (default -when empty- [50 200] for male and [150 300] for female subjects)
%   'FMT_ARGS'        : additional arguments for FLVOICE_FORMANTS (default {})
%   'F0_ARGS'         : additional arguments for FLVOICE_PITCH (default {})
%   'OUT_WINDOW'      : time-window for formant&pitch estimation around time-alignment reference_time (s) (default [-0.2 1.0])
%   'OUT_FS'          : sampling frequency of formant&pitch estimation output (Hz) (default 1000)
%   'OVERWRITE'       : (default 1) 1/0 re-compute formants&pitch trajectories even if output data file already exists
%   'FILEPATH'        : (default '/projectnb/busplab/Experiments/SAP-PILOT/') path to folder containing all subject's data
%   'DOSAVE'          : (default 0) 1/0 save formant&pitch trajectory files
%   'DOPRINT'         : (default 1) 1/0 save jpg files with formant&pitch trajectories
%   'DOREMOTE'        : (default 0) 1/0 work remotely (0: work from SCC computer; 1: work remotely -run "conn remotely on" first from your home computer to connect to SCC; for first-time initialization run on remote server "conn remotely setup")
%
% flvoice_load default(OPTION_NAME,OPTION_VALUE): defines default values for DOSAVE/DOPRINT/DOREMOTE/OVERWRITE/FILEPATH options above (changes will affect all subsequent flvoice_load commands where those options are not explicitly defined; defaults will revert back to their original values after your Matlab session ends)
%
% Alternative syntax:
%   flvoice_load                         : returns list of available subjects
%   flvoice_load SUB                     : returns list of available sessions for this subject
%   flvoice_load SUB SES                 : returns list of available runs for this subject & session
%   flvoice_load SUB SES RUN             : returns list of available tasks for this subject & session & run
%   flvoice_load SUB all RUN TASK ...    : runs flvoice_load using data from all available sessions for this subject & run & task
%   flvoice_load SUB SES all TASK ...    : runs flvoice_load using data from all available runs for this subject & session & task
%   flvoice_load default <optionname> <defaultvalue>  : defines default options
%

persistent DEFAULTS;
if isempty(DEFAULTS), DEFAULTS=struct('DOSAVE',true,'DOPRINT',false,'OVERWRITE',true,'DOREMOTE',false,'FILEPATH',pwd,'NLPC',[],'F0RANGE',[],'OUT_FS',1000,'OUT_WINDOW',[-0.2 1.0],'FMT_ARGS',{{}},'F0_ARGS',{{}}); end %'/projectnb/busplab/Experiments/SAP-PILOT/'); end    
if nargin==1&&isequal(SUB,'default'), if nargout>0, varargout={DEFAULTS}; else disp(DEFAULTS); end; return; end
if nargin>1&&isequal(SUB,'default'), assert(isfield(DEFAULTS,upper(SES)),'unrecognized default field %s',SES); DEFAULTS.(upper(SES))=RUN; fprintf('default %s value changed to %s\n',upper(SES),mat2str(RUN)); return; end

if nargin<1||isempty(SUB), SUB=[]; end
if iscell(SUB)||ischar(SUB), SUB=regexprep(SUB,'^sub-',''); end
if nargin<2||isempty(SES), SES=[]; end
if ischar(SES)&&strcmpi(SES,'all'), SES=0; end
if ischar(SES), SES=str2num(regexprep(SES,'^ses-','')); end
if nargin<3||isempty(RUN), RUN=[]; end
if ischar(RUN)&&strcmpi(RUN,'all'), RUN=0; end
if ischar(RUN), RUN=str2num(regexprep(RUN,'^run-','')); end
if nargin<4||isempty(TASK), TASK=[]; end

OPTIONS=DEFAULTS;
if numel(varargin)>0, for n=1:2:numel(varargin)-1, assert(isfield(DEFAULTS,upper(varargin{n})),'unrecognized default field %s',varargin{n}); OPTIONS.(upper(varargin{n}))=varargin{n+1}; fprintf('%s = %s\n',upper(varargin{n}),mat2str(varargin{n+1})); end; end
if ischar(OPTIONS.NLPC), OPTIONS.NLPC=str2num(OPTIONS.NLPC); end
if ischar(OPTIONS.F0RANGE), OPTIONS.F0RANGE=str2num(OPTIONS.F0RANGE); end
if ischar(OPTIONS.OVERWRITE), OPTIONS.OVERWRITE=str2num(OPTIONS.OVERWRITE); end
if ischar(OPTIONS.DOSAVE), OPTIONS.DOSAVE=str2num(OPTIONS.DOSAVE); end
if ischar(OPTIONS.DOPRINT), OPTIONS.DOPRINT=str2num(OPTIONS.DOPRINT); end
if ischar(OPTIONS.DOREMOTE), OPTIONS.DOREMOTE=str2num(OPTIONS.DOREMOTE); end
varargout=cell(1,nargout);

if OPTIONS.DOREMOTE, OPTIONS.FILEPATH=fullfile('/CONNSERVER',OPTIONS.FILEPATH); end

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
        [nill,tasks]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-*_expParams.mat',SUB,SES,RUN)),'-R','-cell'),'uni',0);
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
    SUB=SUBS{nsample};
    filename_trialData=fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-audio.mat',SUB,SES,RUN,TASK));
    filename_fmtData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-formants.mat',SUB,SES,RUN,TASK));
    if ~conn_existfile(filename_trialData),
        fprintf('file %s not found, attempting alternative input filename\n',filename_trialData);
        filename_trialData=fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-%s.mat',SUB,SES,RUN,TASK));
    end
    if ~conn_existfile(filename_trialData), fprintf('file %s not found, skipping this run\n',filename_trialData);
    else
        fprintf('loading file %s\n',filename_trialData);
        tdata=conn_loadmatfile(filename_trialData,'-cache');
        assert(isfield(tdata,'trialData'), 'data file %s does not contain trialData variable',filename_trialData);
        in_trialData = tdata.trialData;
        if isfield(tdata,'gender'), gender=tdata.gender; 
        elseif isfield(tdata,'expParams')&&isfield(tdata.expParams,'gender'), gender=tdata.expParams.gender;
        else gender='unknown'; 
        end
        
        out_trialData=[];
        showwarn=true;
        %offlineFmts=[];
        %offlinePrms=[];
        if OPTIONS.OVERWRITE||~conn_existfile(filename_fmtData)
            for trialNum=1:numel(in_trialData)
                data=in_trialData(trialNum);
                
                %Nlpc=round(1.25*in_trialData(trialNum).p.nLPC);
                t0=0;
                if isfield(data,'audapData'), % audapter format
                    if isfield(data.audapData,'signalOut'), s={data.audapData.signalIn,data.audapData.signalOut}; labels={'-mic','-headphones'};
                    else s=data.audapData.signalIn;
                    end
                    fs=16000;
                elseif isfield(data,'audioData') % audiodevicereader format
                    s=data.audioData.signalIn;
                    fs=48000;
                else % raw audio format
                    s=data.s;
                    fs=data.fs;
                    if isfield(data,'dataLabel'), labels=data.dataLabel; 
                    elseif iscell(s), labels=arrayfun(@(n)sprintf('measure%d',n),1:numel(s),'uni',0); 
                    end
                    if isfield(data,'t'), t0=data.t; end
                end
                if ~iscell(s), s={s}; labels={''}; end
                if ~iscell(t0), t0={t0}; end
                if numel(s)>1&&numel(t0)==1, t0=repmat(t0,1,numel(s)); end
                assert(numel(t0)==numel(s),'mismatch number of elements in s (%d) and t (%d)',numel(s),numel(t0));
                assert(numel(labels)==numel(s),'mismatch number of elements in s (%d) and dataLabel (%d)',numel(s),numel(labels));
                if ~isempty(OPTIONS.NLPC), Nlpc=OPTIONS.NLPC;
                elseif isfield(in_trialData(trialNum),'p')&&isfield(in_trialData(trialNum).p,'nLPC'), Nlpc=in_trialData(trialNum).p.nLPC;
                elseif isequal(lower(gender),'female'), Nlpc=15;
                elseif isequal(lower(gender),'male'), Nlpc=17;
                else Nlpc=17;
                end
                if ~isempty(OPTIONS.F0RANGE), f0range=OPTIONS.F0RANGE;
                elseif isequal(lower(gender),'female'), f0range=[150 300];
                elseif isequal(lower(gender),'male'), f0range=[50 200];
                else f0range=[50 300];
                end
                if isfield(in_trialData(trialNum),'reference_time'), pertOnset = in_trialData(trialNum).reference_time;
                elseif isfield(in_trialData(trialNum),'timingTrial'), pertOnset = in_trialData(trialNum).timingTrial(4)-in_trialData(trialNum).timingTrial(2);
                else if showwarn, disp('warning: not found reference_time or timingTrial fields in trialData structure. Skipping time-alignment'); showwarn=false; end; pertOnset=0;
                end
                time2=(pertOnset + OPTIONS.OUT_WINDOW(1)):1/OPTIONS.OUT_FS:(pertOnset + OPTIONS.OUT_WINDOW(2)); %Find time window for perturbation analysis (-200ms to 1000ms relative to pertOnset)
                
                fprintf('estimating formants trial #%d\n',trialNum);
                if fs~=16000, for ns=1:numel(s), s{ns}=resample(s{ns},16000,fs); end; fs=16000; end
                for ns=1:numel(s)
                    [fmt,t,svar]=flvoice_formants(s{ns},fs,6,'lpcorder',Nlpc,'windowsize',.050,'stepsize',min(.001,1/OPTIONS.OUT_FS),OPTIONS.FMT_ARGS{:});    % formant estimation
                    f0=flvoice_pitch(s{ns},fs,'f0_t',t,'range',f0range,OPTIONS.F0_ARGS{:});                                                           % pitch estimation
                    out_trialData(trialNum).s{ns,1} = interp1(t', f0,(0:1/OPTIONS.OUT_FS:(numel(s{ns})-1)/fs)','lin',nan);
                    out_trialData(trialNum).s{ns,2} = interp1(t',fmt(1,:)',(0:1/OPTIONS.OUT_FS:(numel(s{ns})-1)/fs)','lin',nan);            % note: (raw = implicit timing) these data starts at t=0 and it is sampled at out_trialData(trialNum).fs rate
                    out_trialData(trialNum).s{ns,3} = interp1(t',fmt(2,:)',(0:1/OPTIONS.OUT_FS:(numel(s{ns})-1)/fs)','lin',nan);            
                    out_trialData(trialNum).s{ns,4} = interp1(t', 10*log10(svar(:))+100,(0:1/OPTIONS.OUT_FS:(numel(s{ns})-1)/fs)','lin',nan);
                    out_trialData(trialNum).dataLabel{ns,1} = ['raw-F0',labels{ns}]; % F0 (Hz)
                    out_trialData(trialNum).dataLabel{ns,2} = ['raw-F1',labels{ns}]; % F1 (Hz)
                    out_trialData(trialNum).dataLabel{ns,3} = ['raw-F2',labels{ns}]; % F2 (Hz)
                    out_trialData(trialNum).dataLabel{ns,4} = ['raw-Int',labels{ns}];% Intensity (dB)
                    out_trialData(trialNum).t{ns,1} = t0{ns};
                    out_trialData(trialNum).t{ns,2} = t0{ns};
                    out_trialData(trialNum).t{ns,3} = t0{ns};
                    out_trialData(trialNum).t{ns,4} = t0{ns};
                end
                out_trialData(trialNum).s=reshape(out_trialData(trialNum).s,1,[]);
                out_trialData(trialNum).dataLabel=reshape(out_trialData(trialNum).dataLabel,1,[]);
                out_trialData(trialNum).t=reshape(out_trialData(trialNum).t,1,[]);
                for ns=1:numel(out_trialData(trialNum).dataLabel), 
                    time1=(0:numel(out_trialData(trialNum).s{ns})-1)/OPTIONS.OUT_FS;
                    out_trialData(trialNum).s{end+1} = interp1(time1, out_trialData(trialNum).s{ns}, time2, 'lin', nan);       % time-alignment
                    out_trialData(trialNum).dataLabel{end+1} = regexprep(out_trialData(trialNum).dataLabel{ns},'^raw-','');     % note: timealigned data first sample is at t = reference_time + OUT_WINDOW(1)
                    out_trialData(trialNum).t{end+1} = time2(1);
                end
                out_trialData(trialNum).fs=OPTIONS.OUT_FS;
                if isfield(out_trialData(trialNum),'condLabel')&&~isempty(out_trialData(trialNum).condLabel), out_trialData(trialNum).condLabel=data.condLabel; 
                else out_trialData(trialNum).condLabel='unknown';
                end
            end
            out_INFO.label=sprintf('Created by %s from input file %s; %s',mfilename,filename_trialData,datestr(now));
            out_INFO.options=OPTIONS;
            try, out_INFO.pertSize = arrayfun(@(n)max([nan in_trialData(n).pertSize]),1:numel(in_trialData));
            catch, out_INFO.pertSize = nan(1,numel(out_trialData));
            end
            
            if OPTIONS.DOSAVE
                conn_fileutils('mkdir',fileparts(filename_fmtData));
                trialData = out_trialData; INFO=out_INFO; conn_savematfile(filename_fmtData,'trialData','INFO');
            end

        else
            assert(conn_existfile(filename_fmtData),'file %s not found',filename_fmtData);
            fprintf('loading file %s\n',filename_fmtData);
            tdata=conn_loadmatfile(filename_fmtData,'-cache');
            assert(isfield(tdata,'trialData'), 'data file %s does not contain trialData variable',filename_fmtData);
            out_trialData = tdata.trialData;
            if isfield(tdata,'INFO'), out_INFO=tdata.INFO; end
        end
        
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
        
        sum_trialData=[];
        filename_summaryData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('run-%d',RUN),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-summary.mat',SUB,SES,RUN,TASK));
        for trialNum=1:numel(in_trialData)
            for ns=1:numel(out_trialData(trialNum).s),
                time1=out_trialData(trialNum).t{ns}+(0:numel(out_trialData(trialNum).s{ns})-1)/out_trialData(trialNum).fs;
                sum_trialData(trialNum).s{ns} = mean(out_trialData(trialNum).s{ns}(time1>0),'omitnan'); % average value for t>0 
                sum_trialData(trialNum).dataLabel{ns}=out_trialData(trialNum).dataLabel{ns};
            end
            sum_trialData(trialNum).condLabel=out_trialData(trialNum).condLabel;
        end
        sum_INFO.label=sprintf('Created by %s from input file %s; %s',mfilename,filename_trialData,datestr(now));
        sum_INFO.options=OPTIONS;
        if OPTIONS.DOSAVE
            conn_fileutils('mkdir',fileparts(filename_summaryData));
            trialData = sum_trialData; INFO=sum_INFO; conn_savematfile(filename_summaryData,'trialData','INFO');
        end

        % plots
        figure('name',sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-audio.mat',SUB,SES,RUN,TASK));
        lnames=unique([out_trialData.dataLabel]);
        for trialNum=1:numel(in_trialData)
            for ns=1:numel(out_trialData(trialNum).s),
                t=out_trialData(trialNum).t{ns}+(0:numel(out_trialData(trialNum).s{ns})-1)/out_trialData(trialNum).fs;
                x=out_trialData(trialNum).s{ns};
                [ok,idx]=ismember(out_trialData(trialNum).dataLabel{ns},lnames);
                subplot(floor(sqrt(numel(lnames))),ceil(numel(lnames)/floor(sqrt(numel(lnames)))),idx); title(lnames{idx});
                hold all; 
                h=plot(t,x,'.-');
                set(h,'buttondownfcn',@(varargin)fprintf('trial # %d\n',trialNum));
            end
        end
        drawnow
%         % aggregated data cross runs
%         dLabels = [{'F0'}   {'F1'}  {'F2'}  {'Int'}];
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
%     for nsub=1:numel(subnames), if ~isempty(subnames{nsub}), filepath=fullfile(pwd,subnames{nsub}); flvoice_load; end; end
% end

                