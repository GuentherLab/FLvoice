
function varargout=flvoice_import(SUB,SES,RUN,TASK, varargin)
% flvoice_import(SUB,SES,RUN,TASK) : imports audio data, and computes formant and pitch trajectories for each trial
%   SUB             : subject id (e.g. 'test244' or 'sub-test244')
%   SES             : session number (e.g. 1 or 'ses-1')
%   RUN             : run number (e.g. 1 or 'run-1')
%   TASK            : task type 'aud' or 'som'
%
%  notes: define SES and/or RUN as 'all' to specify all sessions/runs for the specified subject
%         define SUB/SES/RUN as cell arrays with the same number of elements to specify complex combinations of SUB/SES/RUN values
%
% Input data files: $ROOT$/sub-##/ses-##/beh/sub-##_ses-##_run-##_task-##_desc-audio.mat
%   Variables:
%       gender                       : subject gender 'male', 'female' (alternatively gender = expParams.gender) 
%       trialData(n)                 : trial data structure
%             trialData(n).s                 : audiowave timeseries
%             trialData(n).fs                : sampling frequency (Hz)
%             trialData(n).t                 : time of initial sample (seconds) (default 0)
%             trialData(n).reference_time    : reference time for time-alignment (seconds)  (default 0)
%             trialData(n).condLabel         : condition label/name associated with this trial (default 'unknown')
%             trialData(n).dataLabel         : data labels (default '')
%             trialData(n).dataUnits         : data units (default '')
%
%   notes: trialData(n).s may alternatively be defined as a cell-array to enter multiple timeseries
%                         may alternatively be defined implicitly as trialData(n).s = {trialData(n).audapData.signalIn,trialData(n).audapData.signalOut} for Audapter data with fs=16000Hz
%                         may alternatively be defined implicitly as trialData(n).s = trialData(n).audioData.signalIn for devicereader data with fs=48000Hz
%          trialData(n).reference_time may alternatively be defined implicitly as reference_time = trialData(n).timingTrial(4)-trialData(n).timingTrial(2))
%          when trailData(n).s is a cell array containing multiple timeseries, trialData(n).t and trialData(n).dataLabel may be defined as a cell array as well to indicate a different value per timeseries
%
% Output data files: $ROOT$/derivatives/acoustic/sub-##/ses-##/sub-##_ses-##_run-##_task-##_desc-formants.jpg
% Output data files: $ROOT$/derivatives/acoustic/sub-##/ses-##/sub-##_ses-##_run-##_task-##_desc-formants.mat
%   Variables:
%       trialData(n)                 : trial data structure
%             trialData(n).s                 : formant and pitch timeseries (cell array)
%             trialData(n).fs                : sampling frequency (Hz)
%             trialData(n).t                 : time of initial sample (seconds)
%             trialData(n).condLabel         : condition label/name associated with this trial
%             trialData(n).dataLabel         : data labels (cell array) {'F0','F1','F2','Amp','rawF0','rawF1','rawF2','rawAmp'}
%             trialData(n).dataUnits         : data units (cell array) {'Hz','Hz','Hz','dB','Hz','Hz','Hz','dB'}
%
% Output data files: $ROOT$/derivatives/acoustic/sub-##/ses-##/sub-##_ses-##_run-##_task-##_desc-summary.mat
%   Variables:
%       trialData(n)                 : trial data structure
%             trialData(n).s                 : summary measures (cell array)
%             trialData(n).condLabel         : condition label/name associated with this trial
%             trialData(n).dataLabel         : data labels (cell array)
%             trialData(n).dataUnits         : data units (cell array)
%
% flvoice_import(SUB,RUN,SES,TASK [, OPTION_NAME, OPTION_VALUE, ...]) : imports/processes data using non-default options
%   'N_LPC'            : number of LPC coefficients for formant estimation (default -when empty- 17 for male and 15 for female subjects; note: data resampled to 16KHz)
%   'F0_RANGE'         : valid range for pitch estimation (Hz) (default -when empty- [50 200] for male and [150 300] for female subjects)
%   'FMT_ARGS'         : additional arguments for FLVOICE_FORMANTS (default {})
%   'F0_ARGS'          : additional arguments for FLVOICE_PITCH (default {})
%   'OUT_WINDOW'       : time-window around time-alignment reference_time (seconds) (default [-0.2 1.0])
%   'OUT_FS'           : sampling frequency of formant&pitch estimation output (Hz) (default 1000)
%   'SKIP_CONDITIONS'  : skip specific conditions; list of conditions labels (condLabel values) to be disregarded (default {})
%   'SKIP_LOWAMP'      : skip low-amplitude trials; minimum value of average 'Amp' value (default [])
%   'SINGLETRIAL'      : list of trial number(s) to re-process -expects all trials to have been processed at least once already- (default [])
%   'OVERWRITE'        : (default 1) 1/0 re-compute formants&pitch trajectories even if output data file already exists
%   'SAVE'             : (default 1) 1/0 save formant&pitch trajectory files
%   'PRINT'            : (default 1) 1/0 save jpg files with formant&pitch trajectories
%
% flvoice_import('default',OPTION_NAME,OPTION_VALUE): defines default values for any of the options above (changes will affect all subsequent flvoice_import commands where those options are not explicitly defined; defaults will revert back to their original values after your Matlab session ends)
%
% trialData = flvoice_import(SUB,SES,RUN,TASK, 'input')      : (does not import/process data) returns input trialData array for the selected subject/session/run/task
% trialData = flvoice_import(SUB,SES,RUN,TASK, 'output')     : (does not import/process data) returns output trialData array for the selected subject/session/run/task
% filename = flvoice_import(SUB,SES,RUN,TASK, 'input_file')  : (does not import/process data) returns input data filename(s) ($ROOT$/sub-##/ses-##/beh/sub-##_ses-##_run-##_task-##_desc-audio.mat) for the selected subject/session/run/task
% filename = flvoice_import(SUB,SES,RUN,TASK, 'output_file') : (does not import/process data) returns output data filename(s) ($ROOT$/derivatives/acoustic/sub-##/ses-##/sub-##_ses-##_run-##_task-##_desc-formants.mat) for the selected subject/session/run/task
% QC = flvoice_import(SUB,SES,RUN,TASK, 'get_qc')            : (does not import/process data) returns cell array of structures containing quality control information for the selected subject/session/run/task
% flvoice_import(SUB,SES,RUN,TASK, 'set_qc', QC)             : (does not import/process data) saves structure containing quality control information 
%                                                               QC.keepData(n) = 0/1 value indicating if n-th trial is valid
%                                                               QC.badTrial(n) = numeric values indicating n-th trial quality (0 = valid trial)
%                                                               QC.dictionary{i} = cell array of QC labels indicating what was wrong with trials where QC.badTrial(n)=i
%
% Alternative syntax:
%   flvoice_import                         : returns list of available subjects
%   flvoice_import SUB                     : returns list of available sessions for this subject
%   flvoice_import SUB SES                 : returns list of available runs for this subject & session
%   flvoice_import SUB SES RUN             : returns list of available tasks for this subject & session & run
%   flvoice_import SUB all RUN TASK ...    : runs flvoice_import using data from all available sessions for this subject & run & task
%   flvoice_import SUB SES all TASK ...    : runs flvoice_import using data from all available runs for this subject & session & task
%

persistent DEFAULTS;
if isempty(DEFAULTS), DEFAULTS=struct('SAVE',true,'PRINT',true,'OVERWRITE',true,'N_LPC',[],'F0_RANGE',[],'OUT_FS',1000,'OUT_WINDOW',[-0.2 1.0],'SKIP_CONDITIONS',{{}},'SKIP_LOWAMP',[],'SINGLETRIAL',[],'FMT_ARGS',{{}},'F0_ARGS',{{}}); end 
if nargin==1&&isequal(SUB,'default'), if nargout>0, varargout={DEFAULTS}; else disp(DEFAULTS); end; return; end
if nargin>1&&isequal(SUB,'default'), 
    if nargin>=4, varargin=[{TASK},varargin]; end
    if nargin>=3, varargin=[{RUN},varargin]; end
    if nargin>=2, varargin=[{SES},varargin]; end
    for n=1:2:numel(varargin)-1, assert(isfield(DEFAULTS,upper(varargin{n})),'unrecognized default field %s',varargin{n}); DEFAULTS.(upper(varargin{n}))=varargin{n+1}; end %fprintf('default %s value changed to %s\n',upper(varargin{n}),mat2str(varargin{n+1})); end
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

OPTIONS=DEFAULTS;
OPTIONS.set_qc=[];
if numel(varargin)>0, for n=1:2:numel(varargin)-1, assert(isfield(DEFAULTS,upper(varargin{n})),'unrecognized default field %s',varargin{n}); OPTIONS.(upper(varargin{n}))=varargin{n+1}; end; end %fprintf('%s = %s\n',upper(varargin{n}),mat2str(varargin{n+1})); end; end
if ischar(OPTIONS.N_LPC), OPTIONS.N_LPC=str2num(OPTIONS.N_LPC); end
if ischar(OPTIONS.F0_RANGE), OPTIONS.F0_RANGE=str2num(OPTIONS.F0_RANGE); end
if ischar(OPTIONS.OVERWRITE), OPTIONS.OVERWRITE=str2num(OPTIONS.OVERWRITE); end
if ischar(OPTIONS.SAVE), OPTIONS.SAVE=str2num(OPTIONS.SAVE); end
if ischar(OPTIONS.PRINT), OPTIONS.PRINT=str2num(OPTIONS.PRINT); end
if ischar(OPTIONS.SINGLETRIAL), OPTIONS.SINGLETRIAL=str2num(OPTIONS.SINGLETRIAL); end
OPTIONS.FILEPATH=flvoice('PRIVATE.ROOT');
varargout=cell(1,nargout);

if isempty(SUB),
    [nill,SUBS]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,'sub-*'),'-dir','-R','-cell'),'uni',0);
    if nargout, varargout={SUBS}; 
    else
        disp('available subjects:');
        disp(char(SUBS));
    end
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
    if isempty(SES)
        if nargout, varargout={SESS}; 
        else
            disp('available sessions:');
            disp(char(SESS));
        end
        return
    end
    SES=str2double(regexprep(SESS,'^ses-',''));
    SUB=SUBS;
end
if numel(SUB)==1&&numel(SES)>1, SUB=repmat(SUB,size(SES)); end
if numel(SUB)>1&&numel(SES)==1, SES=repmat(SES,size(SUB)); end
assert(numel(SUB)==numel(SES),'mismatched number of elements in SUB and SES entries');
if isempty(RUN)||isequal(RUN,0),
    SUBS={};
    SESS=[];
    RUNS={};
    for nsample=1:numel(SUB)
        [nill,runs1]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB{nsample}),sprintf('ses-%d',SES(nsample)),'beh',sprintf('sub-%s_ses-%d_run-*_desc-audio.mat',SUB{nsample},SES(nsample))),'-R','-cell'),'uni',0);
        [nill,runs2]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB{nsample}),sprintf('ses-%d',SES(nsample)),'beh',sprintf('sub-%s_ses-%d_run-*.mat',SUB{nsample},SES(nsample))),'-R','-cell'),'uni',0);
        runs=union(runs1,runs2);
        runs=regexprep(runs,'^.*_(run-[^\._]*)[\._].*$','$1');
        %[nill,runs]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB{nsample}),sprintf('ses-%d',SES(nsample)),'beh','run-*'),'-dir','-R','-cell'),'uni',0);
        RUNS=[RUNS; runs(:)];
        SESS=[SESS; SES(nsample)+zeros(numel(runs),1)];
        SUBS=[SUBS; repmat(SUB(nsample),numel(runs),1)];
    end
    if isempty(RUN)
        if nargout, varargout={RUNS}; 
        else
            disp('available runs:');
            disp(char(RUNS));
        end
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
        [nill,tasks1]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),'beh',sprintf('sub-%s_ses-%d_run-%d_task-*_desc-audio.mat',SUB,SES,RUN)),'-R','-cell'),'uni',0);
        [nill,tasks2]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),'beh',sprintf('sub-%s_ses-%d_run-%d_task-*.mat',SUB,SES,RUN)),'-R','-cell'),'uni',0);
        tasks=union(tasks1,tasks2);
        TASKS=[TASKS; tasks(:)];
    end
    TASKS=unique(regexprep(TASKS,{'^.*_task-','_expParams$|_desc-audio$'},''));
    if nargout, varargout={TASKS}; 
    else
        disp('available tasks:');
        disp(char(TASKS));
    end
    return
end

fileout={};
somethingout=false;

for nsample=1:numel(RUNS)
    RUN=RUNS(nsample);
    SES=SESS(nsample);
    SUB=SUBS{nsample};
    filename_trialData=fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),'beh',sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-audio.mat',SUB,SES,RUN,TASK));
    filename_fmtData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-formants.mat',SUB,SES,RUN,TASK));
    if ~conn_existfile(filename_trialData),
        fprintf('file %s not found, attempting alternative input filename\n',filename_trialData);
        filename_trialData=fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB),sprintf('ses-%d',SES),'beh',sprintf('sub-%s_ses-%d_run-%d_task-%s.mat',SUB,SES,RUN,TASK));
    end
    if isfield(OPTIONS,'set_qc')&&~isempty(OPTIONS.set_qc)
        assert(numel(RUNS)==1,'unable to save QC information for multiple subjects/sesions/runs simultaneously. Select a single subject/session/run and try again');
        filename_qcData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-qualitycontrol.mat',SUB,SES,RUN,TASK));
        if conn_existfile(filename_qcData), tdata=conn_loadmatfile(filename_qcData,'-cache'); end
        assert(isfield(OPTIONS.set_qc,'badTrial')||isfield(tdata,'badTrial'),'SETQC structure missing ''badTrial'' field');
        assert(isfield(OPTIONS.set_qc,'dictionary')||isfield(tdata,'dictionary'),'SETQC structure missing ''dictionary'' field');
        tdata.badTrial=OPTIONS.set_qc.badTrial;
        tdata.dictionary=OPTIONS.set_qc.dictionary;
        if isfield(OPTIONS.set_qc,'keepData'), tdata.keepData=OPTIONS.set_qc.keepData;
        else tdata.keepData=reshape(isnan(tdata.badTrial)|tdata.badTrial==0,1,[]);
        end
        fprintf('saving file %s\n',filename_qcData);
        keepData=tdata.keepData; badTrial=tdata.badTrial; dictionary=tdata.dictionary;
        conn_savematfile(filename_qcData,'keepData','badTrial','dictionary');
    elseif rem(numel(varargin),2)==1&&ischar(varargin{end})
        somethingout=true;
        switch(lower(varargin{end}))
            case 'input_file'
                fileout{nsample}=filename_trialData;
            case 'output_file'
                fileout{nsample}=filename_fmtData;
            case 'input'
                tdata=conn_loadmatfile(filename_trialData,'trialData','-cache');
                fileout{nsample}=tdata.trialData;
            case 'output'
                tdata=conn_loadmatfile(filename_fmtData,'trialData','-cache');
                fileout{nsample}=tdata.trialData;
            case 'input_all'
                fileout{nsample}=conn_loadmatfile(filename_trialData,'-cache');
            case 'output_all'
                fileout{nsample}=conn_loadmatfile(filename_fmtData,'-cache');
            case 'get_qc'
                filename_qcData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-qualitycontrol.mat',SUB,SES,RUN,TASK));
                if ~conn_existfile(filename_qcData),
                    fprintf('unable to find QC file %s; initializing...\n',filename_qcData); 
                    tdata=conn_loadmatfile(filename_trialData,'-cache');
                    assert(isfield(tdata,'trialData'), 'data file %s does not contain trialData variable',filename_trialData);
                    in_trialData = tdata.trialData;
                    tdata.keepData=true(1,numel(in_trialData));
                else tdata=conn_loadmatfile(filename_qcData,'-cache');
                end
                if ~isfield(tdata,'badTrial'), tdata.badTrial=double(~tdata.keepData); tdata.dictionary={'bad trial'}; end
                if ~isfield(tdata,'dictionary'), tdata.dictionary=arrayfun(@(n)sprintf('bad trial type-%d',n),1:max(tdata.badTrial),'uni',0); end
                if ~isfield(tdata,'keepData'), tdata.keepData=reshape(isnan(tdata.badTrial)|tdata.badTrial==0,1,[]); end
                if numel(RUNS)>1, fileout{nsample}=tdata;
                else fileout=tdata;
                end
            otherwise
                error('unknown option %s',varargin{end});
        end
    elseif ~conn_existfile(filename_trialData), fprintf('file %s not found, skipping this run\n',filename_trialData);
    else
        hfig=[];
        starttif=true;
        fprintf('loading file %s\n',filename_trialData);
        tdata=conn_loadmatfile(filename_trialData,'-cache');
        assert(isfield(tdata,'trialData'), 'data file %s does not contain trialData variable',filename_trialData);
        in_trialData = tdata.trialData;
        if isfield(tdata,'gender'), gender=tdata.gender; 
        elseif isfield(tdata,'expParams')&&isfield(tdata.expParams,'gender'), gender=tdata.expParams.gender;
        else gender='unknown'; 
        end
        
        showwarn=true;
        modified=false;
        if ~isempty(OPTIONS.SINGLETRIAL) % re-processes a single trial
            starttif=false;
            modifytrials=OPTIONS.SINGLETRIAL;
            conn_loadmatfile(filename_fmtData);%,'trialData','INFO');
            out_trialData=trialData; out_INFO=INFO; 
        else
            if OPTIONS.SAVE||OPTIONS.PRINT, conn_fileutils('mkdir',fileparts(filename_fmtData)); end
            modifytrials=1:numel(in_trialData);
            out_trialData=[];
            out_INFO=[];
        end
        if OPTIONS.OVERWRITE||~conn_existfile(filename_fmtData)
            for trialNum=modifytrials(:)'
                data=in_trialData(trialNum);
                
                %Nlpc=round(1.25*in_trialData(trialNum).p.nLPC);
                t0=0;
                labels={''}; 
                if isfield(data,'audapData')&&(~isfield(data,'s')||isempty(data.s)), % audapter format (back-compatibility)
                    if isfield(data.audapData,'signalOut'), s={data.audapData.signalIn,data.audapData.signalOut}; labels={'-mic','-headphones'};
                    else
                        s=data.audapData.signalIn;
                        if ~iscell(s), s={s}; end
                        labels=arrayfun(@(n)sprintf('measure%d',n),1:numel(s),'uni',0);
                    end
                    fs=16000;
                    in_trialData(trialNum).s=s; 
                    in_trialData(trialNum).fs=fs;
                    in_trialData(trialNum).dataLabel=labels; 
                    modified=true; 
                elseif isfield(data,'audioData')&&(~isfield(data,'s')||isempty(data.s)) % audiodevicereader format (back-compatibility)
                    s=data.audioData.signalIn;
                    if ~iscell(s), s={s}; end
                    fs=48000;
                    labels=arrayfun(@(n)sprintf('measure%d',n),1:numel(s),'uni',0); 
                    in_trialData(trialNum).s=s; 
                    in_trialData(trialNum).fs=fs; 
                    in_trialData(trialNum).dataLabel=labels; 
                    modified=true; 
                else % raw audio format
                    s=data.s;
                    fs=data.fs;
                    if ~iscell(s), s={s}; end
                    if isfield(data,'dataLabel'), labels=data.dataLabel; 
                    else labels=arrayfun(@(n)sprintf('measure%d',n),1:numel(s),'uni',0); 
                    end
                    if isfield(data,'t'), t0=data.t; end
                end
                if ~iscell(t0), t0={t0}; end
                if ~iscell(labels), labels={labels}; end
                if numel(s)>1&&numel(t0)==1, t0=repmat(t0,1,numel(s)); end
                assert(numel(t0)==numel(s),'mismatch number of elements in s (%d) and t (%d)',numel(s),numel(t0));
                assert(numel(labels)==numel(s),'mismatch number of elements in s (%d) and dataLabel (%d)',numel(s),numel(labels));
                if ~isempty(OPTIONS.N_LPC), Nlpc=OPTIONS.N_LPC;
                elseif isfield(in_trialData(trialNum),'p')&&isfield(in_trialData(trialNum).p,'nLPC'), Nlpc=in_trialData(trialNum).p.nLPC;
                elseif isequal(lower(gender),'female'), Nlpc=15;
                elseif isequal(lower(gender),'male'), Nlpc=17;
                else Nlpc=17;
                end
                if ~isempty(OPTIONS.F0_RANGE), f0range=OPTIONS.F0_RANGE;
                elseif isequal(lower(gender),'female'), f0range=[150 300];
                elseif isequal(lower(gender),'male'), f0range=[50 200];
                else f0range=[50 300];
                end
                
                fprintf('estimating formants trial #%d\n',trialNum);
                if fs~=16000, for ns=1:numel(s), s{ns}=resample(s{ns},16000,fs); end; fs=16000; end
                for ns=1:numel(s)
                    
                    [fmt,t,svar]=flvoice_formants(s{ns},fs,6,'lpcorder',Nlpc,'windowsize',.050,'stepsize',min(.001,1/OPTIONS.OUT_FS),OPTIONS.FMT_ARGS{:});    % formant estimation
                    f0=flvoice_pitch(s{ns},fs,'f0_t',t,'range',f0range,OPTIONS.F0_ARGS{:});                                                                   % pitch estimation
                    
                    out_trialData(trialNum).s{ns,1} = interp1(t', f0,(0:1/OPTIONS.OUT_FS:(numel(s{ns})-1)/fs)','lin',nan);
                    out_trialData(trialNum).s{ns,2} = interp1(t',fmt(1,:)',(0:1/OPTIONS.OUT_FS:(numel(s{ns})-1)/fs)','lin',nan);            % note: (raw = implicit timing) these data starts at t=0 and it is sampled at out_trialData(trialNum).fs rate
                    out_trialData(trialNum).s{ns,3} = interp1(t',fmt(2,:)',(0:1/OPTIONS.OUT_FS:(numel(s{ns})-1)/fs)','lin',nan);            
                    out_trialData(trialNum).s{ns,4} = interp1(t', 10*log10(svar(:))+100,(0:1/OPTIONS.OUT_FS:(numel(s{ns})-1)/fs)','lin',nan);
                    out_trialData(trialNum).dataLabel{ns,1} = ['raw-F0',labels{ns}]; % F0 (Hz)
                    out_trialData(trialNum).dataLabel{ns,2} = ['raw-F1',labels{ns}]; % F1 (Hz)
                    out_trialData(trialNum).dataLabel{ns,3} = ['raw-F2',labels{ns}]; % F2 (Hz)
                    out_trialData(trialNum).dataLabel{ns,4} = ['raw-Amp',labels{ns}];% Intensity (dB)
                    out_trialData(trialNum).dataUnits{ns,1} = 'Hz';
                    out_trialData(trialNum).dataUnits{ns,2} = 'Hz';
                    out_trialData(trialNum).dataUnits{ns,3} = 'Hz';
                    out_trialData(trialNum).dataUnits{ns,4} = 'dB';
                    out_trialData(trialNum).t{ns,1} = t0{ns};
                    out_trialData(trialNum).t{ns,2} = t0{ns};
                    out_trialData(trialNum).t{ns,3} = t0{ns};
                    out_trialData(trialNum).t{ns,4} = t0{ns};
                end
                out_trialData(trialNum).s=reshape(out_trialData(trialNum).s,1,[]);
                out_trialData(trialNum).dataLabel=reshape(out_trialData(trialNum).dataLabel,1,[]);
                out_trialData(trialNum).dataUnits=reshape(out_trialData(trialNum).dataUnits,1,[]);
                out_trialData(trialNum).t=reshape(out_trialData(trialNum).t,1,[]);
                for ns=1:numel(out_trialData(trialNum).dataLabel), 
                    time1=(0:numel(out_trialData(trialNum).s{ns})-1)/OPTIONS.OUT_FS;
                    if isfield(in_trialData(trialNum),'reference_time'), pertOnset = in_trialData(trialNum).reference_time - t0{ns}; % note: pertOnset relative to beginning of audio sample
                    elseif isfield(in_trialData(trialNum),'timingTrial'), pertOnset = in_trialData(trialNum).timingTrial(4)-in_trialData(trialNum).timingTrial(2);
                    else if showwarn, disp('warning: not found reference_time or timingTrial fields in trialData structure. Skipping time-alignment'); showwarn=false; end; pertOnset=0;
                    end
                    time2=(pertOnset + OPTIONS.OUT_WINDOW(1)):1/OPTIONS.OUT_FS:(pertOnset + OPTIONS.OUT_WINDOW(2)); % e.g. defines time window for perturbation analysis (-200ms to 1000ms relative to pertOnset)
                    out_trialData(trialNum).s{end+1} = interp1(time1, out_trialData(trialNum).s{ns}, time2, 'lin', nan);       % time-alignment
                    out_trialData(trialNum).dataLabel{end+1} = regexprep(out_trialData(trialNum).dataLabel{ns},'^raw-','');     % note: timealigned data first sample is at t = reference_time + OUT_WINDOW(1)
                    out_trialData(trialNum).dataUnits{end+1} = out_trialData(trialNum).dataUnits{ns};
                    out_trialData(trialNum).t{end+1} = OPTIONS.OUT_WINDOW(1); % note: time relative to reference_time
                end
                out_trialData(trialNum).fs=OPTIONS.OUT_FS;
                if isfield(data,'condLabel')&&~isempty(data.condLabel), out_trialData(trialNum).condLabel=data.condLabel; 
                else out_trialData(trialNum).condLabel='unknown';
                end
                
                if OPTIONS.PRINT,
                    if any(ishandle(hfig)), close(hfig(ishandle(hfig))); end
                    hfig=figure;
                    for ns=1:numel(s)
                        clf
                        h3=axes('units','norm','position',[.1 .5 .7 .4]);
                        set(h3,'YAxisLocation','right','ycolor','r','box','off','xtick',[],'ylim',[0 600],'ytick',0:100:600);
                        ylabel('pitch (Hz)');
                        title(sprintf('sub-%s ses-%d run-%d task-%s trial_%d cond_%s (%s)',SUB,SES,RUN,TASK,trialNum,labels{ns},data.condLabel),'interpreter','none');
                        h1=axes('units','norm','position',[.1 .5 .7 .4]);
                        plot((0:numel(s{ns})-1)/fs,s{ns}); set(gca,'xlim',[0 numel(s{ns})/fs],'xtick',.5:.5:numel(s{ns})/fs,'ylim',max(abs(s{ns}))*[-1.1 1.1],'ytick',max(abs(s{ns}))*linspace(-1.1,1.1,7),'yticklabel',[]);
                        xline(pertOnset,'y:','linewidth',2);
                        grid on;
                        h2=axes('units','norm','position',[.1 .5 .7 .4]);
                        pp=plot(t,f0,'r.'); set(gca,'xlim',[0 numel(s{ns})/fs]);
                        hold off;
                        set(h2,'visible','off','ylim',[0 600])
                        h3=axes('units','norm','position',[.1 .1 .7 .4]);
                        spectrogram(s{ns},round(.015*fs),round(.014*fs),[],fs,'yaxis');
                        hold on; plot(t,fmt'/1e3,'k.-'); hold off;
                        set(h3, 'units','norm','position',[.1 .1 .7 .4],'yaxislocation','right', 'xlim',[0 numel(s{ns})/fs],'xtick',.5:.5:numel(s{ns})/fs);
                        xlabel('Time (s)'); ylabel('formants (KHz)');
                        [im,cmap] = rgb2ind(frame2im(getframe(hfig)),256); 
                        if starttif
                            conn_fileutils('imwrite',im,cmap,conn_prepend('',filename_fmtData,'.tif'),'tiff');
                            starttif=false;
                            fprintf('Saved file: %s\n',conn_prepend('',filename_fmtData,'.tif'));
                        else, conn_fileutils('imwrite',im,cmap,conn_prepend('',filename_fmtData,'.tif'),'tiff','WriteMode','append');
                        end
                    end
                end
            end
            if isempty(OPTIONS.SINGLETRIAL)
                out_INFO.label=sprintf('Created by %s from input file %s; %s',mfilename,filename_trialData,datestr(now));
                out_INFO.options=OPTIONS;
                try, out_INFO.pertSize = arrayfun(@(n)max([nan in_trialData(n).pertSize]),1:numel(in_trialData));
                catch, out_INFO.pertSize = nan(1,numel(out_trialData));
                end
            end
            
            if OPTIONS.SAVE
                if modified, trialData = in_trialData; conn_savematfile(filename_trialData,'trialData','-append'); end
                conn_fileutils('mkdir',fileparts(filename_fmtData));
                trialData = out_trialData; INFO=out_INFO; conn_savematfile(filename_fmtData,'trialData','INFO');
                fprintf('Saved file: %s\n',filename_fmtData);
            end

        else
            assert(conn_existfile(filename_fmtData),'file %s not found',filename_fmtData);
            fprintf('loading file %s\n',filename_fmtData);
            tdata=conn_loadmatfile(filename_fmtData,'-cache');
            assert(isfield(tdata,'trialData'), 'data file %s does not contain trialData variable',filename_fmtData);
            out_trialData = tdata.trialData;
            if isfield(tdata,'INFO'), out_INFO=tdata.INFO; end
        end
        
        if isempty(OPTIONS.SINGLETRIAL)
            filename_qcData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-qualitycontrol.mat',SUB,SES,RUN,TASK));
            if conn_existfile(filename_qcData),
                fprintf('loading file %s\n',filename_qcData);
                tdata=conn_loadmatfile(filename_qcData,'-cache');
                assert(isfield(tdata,'keepData')|isfield(tdata,'badTrial'), 'data file %s does not contain keepData or badTrial variable',filename_qcData);
                if isfield(tdata,'keepData'), keepData=tdata.keepData;
                else keepData=isnan(tdata.badTrial)|tdata.badTrial==0;
                end
                keepData=reshape(keepData,1,[]);
                assert(numel(keepData)==numel(out_trialData),'keepData vector contains %d values (expected %d)',numel(keepData),out_trialData);
            else
                fprintf('file %s not found, assuming all trials are valid\n',filename_qcData);
                keepData=true(1,numel(out_trialData));
            end
            if ~isempty(OPTIONS.SKIP_CONDITIONS)
                keepData=keepData&~arrayfun(@(n)ismember(out_trialData(n).condLabel,OPTIONS.SKIP_CONDITIONS),1:numel(out_trialData));
            end
            if ~isempty(OPTIONS.SKIP_LOWAMP)
                keepData=keepData&arrayfun(@(n)mean(out_trialData(n).s{find(cellfun('length',regexp(out_trialData(n).dataLabel,'^Amp'))>0,1)},'omitnan')>OPTIONS.SKIP_LOWAMP,1:numel(out_trialData));
            end
            %if conn_existfile(filename_qcData),
            %    conn_savematfile(filename_qcData,'keepData','-append');
            %end
        
            sum_trialData=[];
            filename_summaryData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-summary.mat',SUB,SES,RUN,TASK));
            for trialNum=1:numel(in_trialData)
                for ns=1:numel(out_trialData(trialNum).s),
                    time1=out_trialData(trialNum).t{ns}+(0:numel(out_trialData(trialNum).s{ns})-1)/out_trialData(trialNum).fs;
                    sum_trialData(trialNum).s{ns} = mean(out_trialData(trialNum).s{ns}(time1>0),'omitnan'); % average value for t>0
                    sum_trialData(trialNum).dataLabel{ns}=out_trialData(trialNum).dataLabel{ns};
                    sum_trialData(trialNum).dataUnits{ns}=out_trialData(trialNum).dataUnits{ns};
                end
                sum_trialData(trialNum).condLabel=out_trialData(trialNum).condLabel;
            end
            sum_INFO.label=sprintf('Created by %s from input file %s; %s',mfilename,filename_trialData,datestr(now));
            sum_INFO.options=OPTIONS;
            if OPTIONS.SAVE
                conn_fileutils('mkdir',fileparts(filename_summaryData));
                trialData = sum_trialData; INFO=sum_INFO; conn_savematfile(filename_summaryData,'trialData','INFO');
                fprintf('Saved file: %s\n',filename_summaryData);
            end

            % plots
            figure('units','norm','position',[.2 .2 .6 .6],'name',sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-formants.mat',SUB,SES,RUN,TASK));
            lnames=unique([out_trialData.dataLabel]);
            for idx=1:numel(lnames), hax(idx)=subplot(floor(sqrt(numel(lnames))),ceil(numel(lnames)/floor(sqrt(numel(lnames)))),idx); hold all; title(lnames{idx}); end
            initax=false(1,numel(hax));
            for trialNum=reshape(find(keepData),1,[])
                for ns=1:numel(out_trialData(trialNum).s),
                    t=out_trialData(trialNum).t{ns}+(0:numel(out_trialData(trialNum).s{ns})-1)/out_trialData(trialNum).fs;
                    x=out_trialData(trialNum).s{ns};
                    [ok,idx]=ismember(out_trialData(trialNum).dataLabel{ns},lnames);
                    h=plot(t,x,'-','parent',hax(idx));
                    if ~initax(idx)
                        xlabel('Time (s)');
                        ylabel(out_trialData(trialNum).dataUnits{ns});
                        if isempty(regexp(out_trialData(trialNum).dataLabel{ns},'^raw-'))
                            xline(0,'parent',hax(idx),'linewidth',3);
                        end
                        initax(idx)=true;
                    end
                    set(h,'buttondownfcn',@(varargin)fprintf('trial # %d\n',trialNum));
                end
            end
            for idx=1:numel(lnames), axis(hax(idx),'tight'); grid(hax(idx),'on'); end
            drawnow
            if OPTIONS.PRINT,
                conn_print(conn_prepend('',filename_fmtData,'.jpg'),'-nogui');
                conn_fileutils('savefig',conn_prepend('',filename_fmtData,'.fig'));
            end
        end
        
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
if somethingout, varargout={fileout}; end

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
%     if OPTIONS.PRINT, conn_print(sprintf('fig_effectF1a_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
%     if all(ismember({'D0','N0','U0'},condLabel))
%         figure('units','norm','position',[.2 .0 .6 .7]);
%         h=[];
%         for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .1 .8/3 .4]); x=ch2subData.(dispconds{3+ncond}).F0; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{3+ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('headphones F0 (Hz)'); else set(gca,'yticklabel',[]); end; xlabel('time (ms)'); end
%         for ncond=1:3, try, axes('units','norm','position',[.1+.8/3*(ncond-1) .5 .8/3 .4]);    x=subData.(dispconds{3+ncond}).F0; mx=mean(x(t0:end,:),1,'omitnan'); x=x(:,sum(mx(:)>=[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  h=[h;plot(x,'.-')]; k=median(median(x(ceil(t0):end,:))); disp(k);yline(max(0,k)); end; set(gca,'ylim',[0 1e3]); grid on; title(dispconds{3+ncond}); xline(t0,'linewidth',3); if ncond==1, ylabel('mic F0 (Hz)'); else set(gca,'yticklabel',[]); end; set(gca,'xticklabel',[]); end
%         try, cellfun(@(n)set(n,'ylim',[min(cellfun(@min,get(h,'ydata'))) min(500,max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0); end
%         if OPTIONS.PRINT, conn_print(sprintf('fig_effectF0a_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
%     end
%     
%     % summary plots
%     color=[ 0.9290/4 0.6940/4 0.1250/4; 0.8500 0.3250 0.0980; 0 0.4470 0.7410];
%     figure('units','norm','position',[.2 .3 .6 .7]); 
%     h=[]; axes('units','norm','position',[.1 .1 .8 .4]); for ncond=1:3, x=ch2subData.(dispconds{ncond}).F1-ch2subData.(dispconds{1}).F1(:,round(linspace(1,size(ch2subData.(dispconds{1}).F1,2),size(ch2subData.(dispconds{ncond}).F1,2))));        mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1); x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('headphones F1 (Hz)'); legend(h,dispconds(1:3)); 
%     set(gca,'ylim',100*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(400,.8*min(cellfun(@min,get(h,'ydata')))) min(1000,1.2*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
%     h=[]; axes('units','norm','position',[.1 .5 .8 .4]); for ncond=1:3, x=subData.(dispconds{ncond}).F1-subData.(dispconds{1}).F1(:,round(linspace(1,size(subData.(dispconds{1}).F1,2),size(subData.(dispconds{ncond}).F1,2))));                mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1); x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('mic F1 (Hz)'); legend(h,dispconds(1:3));
%     set(gca,'ylim',50*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(400,.8*min(cellfun(@min,get(h,'ydata')))) min(1000,1.2*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
%     if OPTIONS.PRINT, conn_print(sprintf('fig_effectF1b_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
%     
%     if all(ismember({'D0','N0','U0'},condLabel))
%         figure('units','norm','position',[.2 .0 .6 .7]);
%         h=[]; axes('units','norm','position',[.1 .1 .8 .4]); for ncond=4:6, x=ch2subData.(dispconds{ncond}).F0-ch2subData.(dispconds{4}).F0(:,round(linspace(1,size(ch2subData.(dispconds{4}).F0,2),size(ch2subData.(dispconds{ncond}).F0,2))));mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond-3,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('headphones F0 (Hz)'); legend(h,dispconds(4:6));
%         set(gca,'ylim',20*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(40,.9*min(cellfun(@min,get(h,'ydata')))) min(300,1.1*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
%         h=[]; axes('units','norm','position',[.1 .5 .8 .4]); for ncond=4:6, x=subData.(dispconds{ncond}).F0-subData.(dispconds{4}).F0(:,round(linspace(1,size(subData.(dispconds{4}).F0,2),size(subData.(dispconds{ncond}).F0,2))));            mx=mean((diff(x(t0:end,:),1,1)),1,'omitnan'); x=x(:,sum(mx(:)>=[-eps,eps]+[prctile(mx,25) prctile(mx,75)]*[2.5 -1.5;-1.5 2.5],2)==1);  x=x-mean(x(1:t0,:),1,'omitnan'); h=[h plot(mean(x,2,'omitnan'),'-','linewidth',3,'color',color(ncond-3,:))]; hold all; patch([1:size(x,1),fliplr(1:size(x,1))]',[mean(x,2,'omitnan')-1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))); flipud(mean(x,2,'omitnan')+1.96*std(x,1,2,'omitnan')./max(eps,sqrt(sum(~isnan(x),2))))],'k','edgecolor','none','facecolor',get(h(end),'color'),'facealpha',.25); end; set(gca,'ylim',[0 1e3],'xticklabel',[]); grid on; xline(t0,'linewidth',3); yline(0); xlabel('time (ms)'); ylabel('mic F0 (Hz)'); legend(h,dispconds(4:6));
%         set(gca,'ylim',10*[-1 1]); %cellfun(@(n)set(n,'ylim',[max(40,.9*min(cellfun(@min,get(h,'ydata')))) min(300,1.1*max(cellfun(@max,get(h,'ydata'))))]), get(h,'parent'), 'uni',0);
%         if OPTIONS.PRINT, conn_print(sprintf('fig_effectF0b_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
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
%     if OPTIONS.PRINT, conn_print(sprintf('fig_effectF0F1_sub-%s_ses-%d_run-%d_task-%s.jpg',SUB,SES,RUN,TASK),'-nogui'); end
% end
% drawnow
% 
% varargout={subData,ch2subData};

% if 0
%     PRINT=true;
%     OVERWRITE=true;
%     figure(1);
%     names={'7 (jason)','3 (rohan)','6 (ricky)','2 (liam)','8 (latane)','5 (jackie)','4 (bobbie)','1 (dave)'};
%     subnames={'','sub-test244','sub-test245','sub-test249','sub-test250','sub-test252','sub-test257','sub-test258'};
%     for nsub=1:numel(subnames), if ~isempty(subnames{nsub}), filepath=fullfile(pwd,subnames{nsub}); flvoice_import; end; end
% end

                