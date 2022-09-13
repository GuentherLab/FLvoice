
function varargout=flvoice_firstlevel(SUB,SES,RUN,TASK, FIRSTLEVEL_NAME, MEASURE, DESIGN, CONTRAST_VECTOR, CONTRAST_TIME, varargin)
% data = flvoice_firstlevel(SUB,RUN,SES,TASK, FIRSTLEVEL_NAME, MEASURE, DESIGN, CONTRAST_VECTOR [, CONTRAST_TIME]) : runs first-level model estimation on audio data
%   SUB              : subject id (e.g. 'test244' or 'sub-test244')
%   SES              : session number (e.g. 1 or 'ses-1')
%   RUN              : run number (e.g. 1 or 'run-1')
%   TASK             : task type 'aud' or 'som'
%   FIRSTLEVEL_NAME  : new first-level analysis name
%   MEASURE          : input data value (valid values from input data .dataLabel)
%                          e.g. 'F1-mic'
%   DESIGN           : condition names defining N first-level conditions or covariate values (valid values from input data .condLabel to indicate individual conditions, or the keywords 'COVARIATE1', 'COVARIATE2', etc. to indicate individual covariates)
%                          e.g. {'U1','N1'}
%                         the GLM 1st-level design matrix will be defined in this case as N columns indicating individual conditions (0/1 values) or covariates (arbitrary values) 
%                      alternatively, function defining one row of design matrix (one row per trial)
%                         fun(condLabel, sesNumber, runNumber, trialNumber) should return a [1,N] vector of categorical or continuous values associated with this trial
%                          e.g. @(condLabel,sesNumber,runNumber,trialNumber)[strcmp(condLabel,'U1') strcmp(condLabel,'N1')]
%                         the GLM 1st-level design matrix will be defined in this case by concatenating the @fun output vectors with one row per trial (across all selected sessions and runs)
%   CONTRAST_VECTOR  : condition weights defining first-level contrast across modeled effects / columns of design matrix (1 x N vector or K x N matrix)
%                          e.g. [1, -1]
%   CONTRAST_TIME    : condition weights defining first-level contrast across data elements (e.g. timepoints) (1 x Nt vector or Kt x Nt matrix)
%                          e.g. [0 0 0 0 1 1 1 1 0 0 0 0 0]
%                      alternatively, function defining contrast values for each timepoint (or column of CONTRAST_TIME matrix)
%                          e.g. @(t) (t>0&t<.200) - (t<0)
%                      alternatively, empty array indicating a separate contrast for each data element / timepoint (eq. to CONTRAST_TIME=eye(Nt)) 
%
% flvoice_firstlevel(... [, OPTION_NAME, OPTION_VALUE, ...]) : runs first-level model estimation using non-default options
%   'REFERENCE'        : true/false (default true) uses samples before t=0 as implicit baseline/reference
%                         alternatively, function defining timewindow to be used as baseline/reference
%                          e.g. @(t) (t>-.100&t<0)
%                         alternatively, specific value to be used as baseline/reference
%                          e.g. double(0.5)
%   'REFERENCE_SCALE'  : type of 'REFERENCE' baseline used (default 'subtract'): 
%                           'subtract' to subtract from timeseries average value within reference timewindow (y=x-reference)
%                           'divide' to divide timeseries by average value within reference timewindow (y=x/reference)
%                           'cents' to convert timeseries to 'cents' units using reference timewindow as base level (y=log(x/reference)/log(2)*1200)
%   'CONTRAST_SCALE'   : true/false (default true) scales CONTRAST_TIME rows to maintain original data units (sum of positive values = 1, and if applicable sum of negative values = -1)
%   'SAVE'             : (default true) true/false saves analysis results .mat file
%   'PRINT'            : (default false) true/false saves jpg files with analysis results
%   'EXPORTDIVA'       : (default false) true/false exports analysis results as SimpleDIVA perturbation+data .csv file 
%                           SimpleDIVA perturbation+data files contain one row per trial, with a first column indicating perturbation size for each trial (e.g. timepoint), followed by one or more columns indicating the observations at each trial (e.g. formant values) 
%                           EXPORTDIVA=1 -> a separate trial will be created for each combination of CONTRAST_TIME*CONTRAST_VECTOR rows (i.e. the SimpleDIVA file will have dimensions Kt*K x 2)
%                           EXPORTDIVA=2 -> each row of CONTRAST_TIME will be treated as a separate TRIAL, and each row of CONTRAST_VECTOR as a separate observation (i.e. the SimpleDIVA file will have dimensions Kt x 1+K)
%                           EXPORTDIVA=3 -> each row of CONTRAST_VECTOR will be treated as a separate trial, and each row of CONTRAST_TIME as a separate observation (i.e. the SimpleDIVA file will have dimensions K x 1+Kt)
%                           Enter as field 'EXPORTDIVA_PERT' the experimental perturbation size for each trial (1 x K*Kt vector, 1 x Kt vector, or 1 x K vector for the three options above) 
%                           If EXPORTDIVA_PERT is undefined the experimental perturbation size will be computed by applying the same first-level model and contrast estimation procedure to the data defined by the last covariate in the input file for each trial
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
% Output stats files: $ROOT$/derivatives/acoustic/sub-##/sub-##_desc-firstlevel_#[FIRSTLEVEL_NAME]#.mat
%   Variables:
%       effect                               : effect-sizes (K x Kt matrix, one value per contrast_vector/contrast_time pair)
%       effect_CI                            : effect-size 95% confidence intervals
%       stats                                : stats structure with fields
%             X                                    : design matrix
%             Y                                    : data matrix
%             C1                                   : contrast vector
%             C2                                   : original CONTRAST_TIME value used to define data
%             h                                    : effect-sizes
%             f                                    : statistics
%             p                                    : p-values
%             pFDR                                 : FDR-corrected p-values
%             dof                                  : degrees of freedom
%             statsname                            : name of statistics ('F' or 'T')
%
% Examples:
%
%    flvoice_firstlevel('sub-PTP001','ses-1','run-1','aud-reflexive','test01','F0-headphones',{'U0','N0'},[1 -1]);
%      evaluates the difference in F0-headphones timeseries when comparing the U0 to the N0 conditions (separately at each timepoint)
% 
%    flvoice_firstlevel('sub-PTP001','ses-1','run-1','aud-reflexive','test01','F0-headphones',{'U0','N0'},[1 -1], @(t)(t>0));
%      same as above but averaging across all timepoints after perturbation (t>0)
% 
%    flvoice_firstlevel('sub-PTP001','ses-1','run-1','aud-reflexive','test01','F0-headphones',{'U0','N0'},[1 -1], @(t)(t>0)-(t<0))
%      same as above but contrasting all timepoints after perturbation (t>0) vs all timepoints before perturbation (t<0)
%
%    flvoice_firstlevel('sub-PTP001','ses-1','run-1','aud-reflexive','test01','F0-headphones',{'U0','N0'},[1 -1], @(t)[t>0; t<0])
%      same as above but averaging separate all timepoints before (t<0) and after (t>0) perturbation
%
%    flvoice_firstlevel('sub-PTP001','ses-1','run-1','aud-reflexive','test01','F0-headphones',{'U0'},[1],[],'REFERENCE',false);
%      displays the absolute values in F0-headphones timeseries during U0 condition (note: no reference contrast)
% 
%    flvoice_firstlevel('sub-PTP001','ses-1','run-1','aud-reflexive','test01','F0-headphones',{'U0'},[1],[],'REFERENCE',@(t)(t>-0.050 & t<0));
%      displays the absolute values in F0-headphones timeseries during U0 condition compared to the last 50ms before perturbation
% 
%    flvoice_firstlevel('sub-PTP001','ses-1','run-1','aud-reflexive','test01','F0-headphones',{'U0','D0','N0'},[1 0 -1; 0 1 -1]);
%      evaluates the difference in F0-headphones timeseries when comparing the U0 to the N0 conditions, as well as D0 to the N0 conditions (separately at each timepoint)
% 
%    f=@(condLabel, sesNumber, runNumber, trialNumber)[(1:10)==sesNumber]
%    flvoice_firstlevel('sub-PTP001','ses-1','run-1','aud-reflexive','test01','F0-headphones',@f,diff(eye(10)));
%      evaluates the differences in F0-headphones timeseries when comparing across sessions (separately at each timepoint)
%

persistent DEFAULTS;
if isempty(DEFAULTS), DEFAULTS=struct('REFERENCE',true,'REFERENCE_SCALE','subtract','CONTRAST_SCALE',true,'SAVE',true,'DOPLOT',true,'PRINT',true,'EXPORTDIVA',false,'EXPORTDIVA_PERT',[]); end 
if nargin==1&&isequal(SUB,'default'), if nargout>0, varargout={DEFAULTS}; else disp(DEFAULTS); end; return; end
if nargin>1&&isequal(SUB,'default'), 
    if nargin>=9, varargin=[{CONTRAST_TIME},varargin]; end
    if nargin>=8, varargin=[{CONTRAST_VECTOR},varargin]; end
    if nargin>=7, varargin=[{DESIGN},varargin]; end
    if nargin>=6, varargin=[{MEASURE},varargin]; end
    if nargin>=5, varargin=[{FIRSTLEVEL_NAME},varargin]; end
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
if nargin<5||isempty(FIRSTLEVEL_NAME), FIRSTLEVEL_NAME=[]; end
if nargin<6||isempty(MEASURE), MEASURE='F1'; end
if nargin<7||isempty(DESIGN), DESIGN={}; end
if ischar(DESIGN), DESIGN={DESIGN}; end
if nargin<8||isempty(CONTRAST_VECTOR), CONTRAST_VECTOR=[]; end
if ischar(CONTRAST_VECTOR), CONTRAST_VECTOR=str2num(CONTRAST_VECTOR); assert(~isempty(CONTRAST_VECTOR),'unable to interpret CONTRAST_VECTOR input'); end
if nargin<9||isempty(CONTRAST_TIME), CONTRAST_TIME=[]; end
if ischar(CONTRAST_TIME), CONTRAST_TIME=str2num(CONTRAST_TIME); assert(~isempty(CONTRAST_TIME),'unable to interpret CONTRAST_TIME input'); end

OPTIONS=DEFAULTS;
if numel(varargin)>0, for n=1:2:numel(varargin)-1, assert(isfield(DEFAULTS,upper(varargin{n})),'unrecognized default field %s',varargin{n}); OPTIONS.(upper(varargin{n}))=varargin{n+1}; end; end %fprintf('%s = %s\n',upper(varargin{n}),mat2str(varargin{n+1})); end; end
if ischar(OPTIONS.REFERENCE), OPTIONS.REFERENCE=str2num(OPTIONS.REFERENCE); end
if ~islogical(OPTIONS.REFERENCE)&&isequal(OPTIONS.REFERENCE,1), fprintf('warning: REFERENCE set to the user-defined value=1; if the intention was to use as reference the average of the samples before t=0 please use the syntax flvoice_firstlevel(...,''REFERENCE'',true) instead\n'); end
if ischar(OPTIONS.CONTRAST_SCALE), OPTIONS.CONTRAST_SCALE=str2num(OPTIONS.CONTRAST_SCALE); end
if ischar(OPTIONS.SAVE), OPTIONS.SAVE=str2num(OPTIONS.SAVE); end
if ischar(OPTIONS.DOPLOT), OPTIONS.DOPLOT=str2num(OPTIONS.DOPLOT); end
if ischar(OPTIONS.PRINT), OPTIONS.PRINT=str2num(OPTIONS.PRINT); end
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
if isempty(RUN)||isequal(RUN,0),
    SUBS={};
    SESS=[];
    RUNS={};
    for nsample=1:numel(SUB)
        [nill,runs]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB{nsample}),sprintf('ses-%d',SES(nsample)),sprintf('sub-%s_ses-%d_run-*_desc-formants.mat',SUB{nsample},SES(nsample))),'-R','-cell'),'uni',0);
        runs=regexprep(runs,'^.*_(run-[^\._]*)[\._].*$','$1');
        %[nill,runs]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,sprintf('sub-%s',SUB{nSUB}),sprintf('ses-%d',SES(nSES)),'beh','run-*'),'-dir','-R','-cell'),'uni',0);
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
if numel(SUBS)==1&&numel(SESS)>1&&numel(RUNS)>1&&numel(RUNS)==numel(SESS), SUBS=repmat(SUBS,size(RUNS)); end
if numel(SUBS)>1&&numel(SESS)==1&&numel(RUNS)>1&&numel(RUNS)==numel(SUBS), SESS=repmat(SESS,size(RUNS)); end
if numel(SUBS)>1&&numel(SESS)>1&&numel(RUNS)==1&&numel(SUBS)==numel(SESS), RUNS=repmat(RUNS,size(SUBS)); end
assert(numel(SUBS)==numel(SESS)&numel(SUBS)==numel(RUNS),'unequal number of subjects/runs/sessions selected');

if isempty(TASK)
    TASKS={};
    for nsample=1:numel(RUNS)
        RUN=RUNS(nsample);
        SES=SESS(nsample);
        SUB=SUBS{nsample};
        [nill,tasks]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('sub-%s_ses-%d_run-%d_task-*_desc-formants.mat',SUB,SES,RUN)),'-R','-cell'),'uni',0);
        TASKS=[TASKS; tasks(:)];
    end
    TASKS=unique(regexprep(TASKS,{'^.*_task-','_expParams$|_desc-formants$'},''));
    if nargout, varargout={TASKS}; 
    else
        disp('available tasks:');
        disp(char(TASKS));
    end
    return
end

USUBS=unique(SUBS);
out=struct([]);
for nsub=1:numel(USUBS)
    X=[]; 
    Y=[];
    T=[];
    C=[];
    COVS=[];
    Tlabel='time (ms)';
    Ylabel='';
    for nsample=reshape(find(strcmp(USUBS{nsub},SUBS)),1,[])
        RUN=RUNS(nsample);
        SES=SESS(nsample);
        SUB=SUBS{nsample};
        filename_fmtData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-formants.mat',SUB,SES,RUN,TASK));
        if ~conn_existfile(filename_fmtData), fprintf('file %s not found, skipping this run\n',filename_fmtData);
        else
            fprintf('loading file %s\n',filename_fmtData);
            tdata=conn_loadmatfile(filename_fmtData,'-cache');
            assert(isfield(tdata,'trialData'), 'data file %s does not contain trialData variable',filename_fmtData);
            in_trialData = tdata.trialData;
            filename_qcData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB),sprintf('ses-%d',SES),sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-qualitycontrol.mat',SUB,SES,RUN,TASK));
            if conn_existfile(filename_qcData),
                fprintf('loading file %s\n',filename_qcData);
                tdata=conn_loadmatfile(filename_qcData,'-cache');
                assert(isfield(tdata,'keepData')|isfield(tdata,'QCflags'), 'data file %s does not contain keepData or QCflags variable',filename_qcData);
                if isfield(tdata,'keepData'), keepData=tdata.keepData;
                else keepData=isnan(tdata.QCflags)|tdata.QCflags==0; 
                end
                keepData=reshape(keepData,1,[]);
                assert(numel(keepData)==numel(in_trialData),'incorrect dimensions of keepData variable (%d elements, expected %d)',numel(keepData),numel(in_trialData));
            else
                fprintf('file %s not found, assuming all trials are valid\n',filename_qcData);
                keepData=true(1,numel(in_trialData));
            end
            if isa(DESIGN,'function_handle'), idxcovariates=[]; idxconstant=[]; 
            else
                idxcovariates=find(cellfun('length',regexp(DESIGN,'^COVARIATE\d+$'))>0);
                ncovariates=str2double(regexprep(DESIGN(icovariates),'^COVARIATE',''));
                idxconstant=idxcovariates(ncovariates==0), % note: constant term ('COVARIATE0') = all conditions
                idxcovariates(ncovariates==0)=[];
                ncovariates(ncovariates==0)=[];
                end
            end
            ntrials=0;
            for ntrial=1:numel(in_trialData)
                % finds design
                if ~keepData(ntrial), ok=false;
                elseif isa(DESIGN,'function_handle'), x=full(double(DESIGN(in_trialData(ntrial).condLabel, SES, RUN, ntrial))); ok=all(~isnan(x))&any(x~=0);
                elseif ~isempty(idxconstant), ok=true; x=zeros(1,numel(DESIGN)); 
                else [ok,x]=ismember({in_trialData(ntrial).condLabel},DESIGN); if ok, x=full(sparse(1,x,1,1,numel(DESIGN))); end
                end
                if ok % adds this trial to analysis
                    ntrials=ntrials+1;
                    if ~isempty(idxconstant), x(idxconstant)=1; end
                    if ~isempty(idxcovariates), x(idxcovariates)=reshape(in_trialData(ntrial).covariates(ncovariates),1,[]); end
                    if size(X,2)<size(x,2), X=[X, zeros(size(X,1),size(x,2)-size(X,2))]; end
                    if size(x,2)<size(X,2), x=[x, zeros(size(x,1),size(X,2)-size(x,2))]; end
                    X=[X;x];
                    % finds data
                    idx=find(strcmp(MEASURE,in_trialData(ntrial).dataLabel));
                    assert(numel(idx)==1,'unable to find %s in trial %d (%s)',MEASURE,ntrial,sprintf('%s ',in_trialData(ntrial).dataLabel{:}));
                    y=in_trialData(ntrial).s{idx};
                    t=in_trialData(ntrial).t{idx}+(0:numel(y)-1)/in_trialData(ntrial).fs;
                    if isempty(Ylabel)
                        Ylabel=MEASURE;
                        if ~isempty(OPTIONS.REFERENCE)&&~isequal(OPTIONS.REFERENCE,0)&&isequal(OPTIONS.REFERENCE_SCALE,'cents'), Ylabel=[Ylabel ' (cents)']; 
                        elseif isfield(in_trialData(ntrial),'dataUnits'), Ylabel=[Ylabel ' (',in_trialData(ntrial).dataUnits{idx},')']; 
                        end
                    end
                    if ~isempty(OPTIONS.REFERENCE)
                        my=[]; mask=true;
                        if isa(OPTIONS.REFERENCE,'function_handle'), mask=logical(OPTIONS.REFERENCE(t));
                        elseif OPTIONS.REFERENCE==0, mask=false;
                        elseif islogical(OPTIONS.REFERENCE), mask=t<0;
                        else my=OPTIONS.REFERENCE; 
                        end
                        if ~isempty(my)||any(mask&~isnan(y))
                            if isempty(my), my=mean(y(mask&~isnan(y))); end
                            switch(lower(OPTIONS.REFERENCE_SCALE))
                                case 'subtract', y=y-my;
                                case 'divide', y=y/my;
                                case 'cents', y=log(y/my)/log(2)*1200;
                                otherwise, error('unknown REFERENCE_SCALE option %s',OPTIONS.REFERENCE_SCALE);
                            end
                        end
                    end
                    if ~isempty(CONTRAST_TIME)
                        if isa(CONTRAST_TIME,'function_handle'), c=double(CONTRAST_TIME(t));
                        else c=double(CONTRAST_TIME);
                        end
                        ny=min(numel(y),size(c,2));
                        y=y(1:ny);
                        c=c(:,1:ny);
                        Tlabel='contrasts';
                        valid=~isnan(y); % disregards samples with missing-values
                        y=y(valid);
                        c=c(:,valid);
                        if OPTIONS.CONTRAST_SCALE % re-scales contrast
                            for n1=1:size(c,1)
                                vmask=c(n1,:)>0; if nnz(vmask), c(n1,vmask)=c(n1,vmask)/max(eps,abs(sum(c(n1,vmask)))); end % pos-values add up to 1
                                vmask=c(n1,:)<0; if nnz(vmask), c(n1,vmask)=c(n1,vmask)/max(eps,abs(sum(c(n1,vmask)))); end % neg-values add up to -1
                            end
                        end
                        y=y*c';
                        t=1:size(y,2);
                    end
                    if size(Y,2)<size(y,2), Y=[Y, nan(size(Y,1),size(y,2)-size(Y,2))]; end
                    if size(y,2)<size(Y,2), y=[y, nan(size(y,1),size(Y,2)-size(y,2))]; end
                    Y=[Y;y];
                    if size(T,2)<size(t,2), T=[T, nan(size(T,1),size(t,2)-size(T,2))]; end
                    if size(t,2)<size(T,2), t=[t, nan(size(t,1),size(T,2)-size(t,2))]; end
                    T=[T;t];
                    if isfield(in_trialData,'covariates'), COVS=[COVS;in_trialData(ntrial).covariates(:)']; end
                end
            end
            fprintf('  included %d trials in analysis\n',ntrials);
        end
    end
    validX=any(X~=0,1);
    validY=~isnan(Y);
    validC=~any(CONTRAST_VECTOR(:,~validX)~=0,2);
    nvalid=sum(validY,1);
    fprintf('Data: %d (%d-%d) samples/trials, %d (%d-%d) measures/timepoints\n',size(Y,1),min(nvalid),max(nvalid),size(Y,2),min(sum(validY,2)),max(sum(validY,2)));
    stats=struct('X',X,'Y',Y,'T',T,'Ylabel',Ylabel,'Tlabel',Tlabel,'C1',CONTRAST_VECTOR,'C2',CONTRAST_TIME,'covs',COVS);
    options={'collapse_predictors','collapse_none'}; %'collapse_all_satterthwaite');
    contrasts={CONTRAST_VECTOR(validC,validX), CONTRAST_VECTOR(:,validX)};
    for nrepeat=1:2, % 1: combined stats; 2: separate stats for each individual contrast row
        h=[];f=[];p=[];dof=[];
        vmask=nvalid==size(Y,1);
        [th,tf,tp,tdof,statsname]=conn_glm(X(:,validX),Y(:,vmask),contrasts{nrepeat},[],options{nrepeat}); % note: skips non-estimable rows of contrast matrix for the combined stats
        if nrepeat==2, th(~validC,:)=nan; tf(~validC,:)=nan; tp(~validC,:)=nan; end % note: mark non-estimable contrasts with NaN
        h=nan(size(th,1),size(Y,2));f=nan(size(tf,1),size(Y,2));p=nan(size(tp,1),size(Y,2));dof=nan(numel(tdof),size(Y,2));
        h(:,vmask)=th;
        f(:,vmask)=tf;
        p(:,vmask)=tp;
        dof(:,vmask)=repmat(tdof(:),1,nnz(vmask));
        for n1=reshape(find(nvalid>0&nvalid<size(Y,1)),1,[]) % for cases with some (not zero not all) invalid samples
            [h(:,n1),f(:,n1),p(:,n1),dof(:,n1)]=conn_glm(X(validY(:,n1),:),Y(validY(:,n1),n1),CONTRAST_VECTOR,[],options{nrepeat});
        end
        if isequal(statsname,'T'), p=2*min(p,1-p); end % two-sided
        pFDR=conn_fdr(p,2);
        if nrepeat==1, stats.h=h;stats.f=f;stats.p=p;stats.pFDR=pFDR;stats.dof=dof;stats.statsname=statsname; 
        else stats.i_f=f;stats.i_p=p;stats.i_pFDR=pFDR;stats.i_dof=dof;stats.i_statsname=statsname;
        end
    end
    filename_outData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',USUBS{nsub}),sprintf('sub-%s_desc-firstlevel_%s.mat',USUBS{nsub},FIRSTLEVEL_NAME));
    effect=h;
    if isequal(statsname,'T')|(isequal(statsname,'F')&max(dof(1,:))==1), 
        if isequal(statsname,'T'), SE=abs(h./f);
        else SE=abs(h./sqrt(f));
        end
        effect_CI=cat(1, h-repmat(spm_invTcdf(.975,dof(end,:)),size(SE,1),1).*SE, h+repmat(spm_invTcdf(.975,dof(end,:)),size(SE,1),1).*SE);
    else effect_CI=[];
    end
    if numel(p)<10
        for n1=1:size(p,2)
            if isequal(statsname,'T'), sstr=sprintf('%s(%d)',statsname,dof(end,n1));
            else sstr=sprintf('%s(%d,%d)',statsname,dof(1,n1),dof(2,n1));
            end
            for n2=1:size(p,1)
                fprintf('contrast #%d: h=%s %s=%.3f p=%.4f p-FDR=%.4f\n',n2, mat2str(h(n2,n1),5),sstr,f(n2,n1),p(n2,n1),pFDR(n2,n1));
            end
        end
    end
    if OPTIONS.SAVE, 
        conn_savematfile(filename_outData,'effect','effect_CI','stats'); 
        fprintf('Output saved in file %s\n',filename_outData);
    end
    if nargout>0
        out=[out, struct('effect',effect,'effect_CI',effect_CI,'stats',stats)];
    end
    if OPTIONS.EXPORTDIVA
        filename_outExport=conn_prepend('',filename_outData,'.csv');
        if ~isempty(OPTIONS.EXPORTDIVA_PERT), exportdiva_pert=OPTIONS.EXPORTDIVA_PERT;
        elseif ~isempty(COVS), exportdiva_pert=conn_glm(X(:,validX),COVS(:,end),CONTRAST_VECTOR(:,validX)); if size(COVS,2)>1, fprintf('Warning: perturbation size values computed from last covariate among %d covariates defined\n',size(COVS,2)); end
        else error('Unable to find any covariates; please specify an EXPORTDIVA_PERT vector explicitly'); 
        end
        switch(OPTIONS.EXPORTDIVA)
            case 1, % Kt*K x 1
                assert(size(exportdiva_pert,1)==1&size(exportdiva_pert,2)==size(effect,1)*size(effect,2),'mismatched size of EXPORTDIVA_PERT (observed %dx%d, expected %dx%d)',size(exportdiva_pert,1),size(exportdiva_pert,2),1,size(effect,1)*size(effect,2));
                export_effect=[exportdiva_pert.', effect(:)]; % Kt*K x 1 matrix (e.g. timepoints perturbation vector + timepoints x conditions matrix)
            case 2, % Kt x K
                assert(size(exportdiva_pert,1)==1&size(exportdiva_pert,2)==size(effect,2),'mismatched size of EXPORTDIVA_PERT (observed %dx%d, expected %dx%d)',size(exportdiva_pert,1),size(exportdiva_pert,2),1,size(effect,2));
                export_effect=[exportdiva_pert.', effect.']; % Kt x (1+K) matrix (e.g. timepoints perturbation vector + timepoints x conditions matrix)
            case 3, % K x Kt
                assert(size(exportdiva_pert,1)==1&size(exportdiva_pert,2)==size(effect,1),'mismatched size of EXPORTDIVA_PERT (observed %dx%d, expected %dx%d)',size(exportdiva_pert,1),size(exportdiva_pert,2),1,size(effect,1));
                export_effect=[exportdiva_pert.', effect]; % K x (1+Kt) matrix (e.g. timepoints perturbation vector + timepoints x conditions matrix)
        end
        conn_savetextfile(filename_outExport,effect);
        fprintf('Output exported to SimpleDIVA file %s\n',filename_outExport);
    end
    if OPTIONS.DOPLOT,
        if size(effect,1)>10&size(effect,2)==1 % plot each CONTRAST_VECTOR row as a separate timepoint
            T=1:size(effect,1);
            effect=effect';
            effect_CI=reshape(effect_CI,[],2)';
            p=p';
            Tlabel='contrast rows';
        elseif ~isequal(Tlabel,'time (ms)') & size(effect,2)>10&size(effect,1)==1 % plot each CONTRAST_TIME row as a separate timepoint
            T=1:size(effect,2);
            Tlabel='contrast_time rows';
        end
            
        t=T; t(isnan(T))=0; t=sum(t,1)./sum(~isnan(T),1);
        %color=[ 0.9290/4 0.6940/4 0.1250/4; 0.6500 0.0980 0.0980; 0.8500 0.0980 0.0980];
        if size(effect,1)==1, color=[ .25 .25 .25; 0.0980 0.0980 0.6500 ; 0.6500 0.0980 0.0980];
        else color=jet(max(128,size(effect,1))); color=color(round(linspace(1,size(color,1),size(effect,1))),:);
        end
        figure('units','norm','position',[.2 .3 .6 .3],'color','w');
        h=[]; axes('units','norm','position',[.2 .2 .6 .6]); 
        if isequal(Tlabel,'time (ms)')||isequal(Tlabel,'contrast rows')
            for n1=1:size(effect,1)
                h=[h plot(t,effect(n1,:),'.-','linewidth',2,'color',color(n1,:))];
                hold all;
                tempx=[t,fliplr(t)];
                tempy=[effect_CI(n1,:),fliplr(effect_CI(n1+size(effect_CI,1)/2,:))];
                tempy2=[effect(n1,:),fliplr(effect(n1,:))];
                maskp1=p(n1,:)>.05;                           maskp1=[maskp1 fliplr(maskp1)]; tempy1=tempy; tempy1(~maskp1)=tempy2(~maskp1); patch(tempx',tempy1','k','edgecolor','none','facecolor',color(n1,:),'facealpha',.25);
                if size(effect,1)==1
                    maskp1=p(n1,:)<.05&effect(n1,:)<0;        maskp1=[maskp1 fliplr(maskp1)]; tempy1=tempy; tempy1(~maskp1)=tempy2(~maskp1); patch(tempx',tempy1','k','edgecolor','none','facecolor',color(2,:),'facealpha',.5);
                    maskp1=p(n1,:)<.05&effect(n1,:)>0;        maskp1=[maskp1 fliplr(maskp1)]; tempy1=tempy; tempy1(~maskp1)=tempy2(~maskp1); patch(tempx',tempy1','k','edgecolor','none','facecolor',color(3,:),'facealpha',.5);
                else
                    maskp1=p(n1,:)<.05;                       maskp1=[maskp1 fliplr(maskp1)]; tempy1=tempy; tempy1(~maskp1)=tempy2(~maskp1); patch(tempx',tempy1','k','edgecolor','none','facecolor',color(n1,:),'facealpha',.5);
                end
            end
            grid on;
            if isequal(Tlabel,'time (ms)'), xline(0,'linewidth',3); end
            yline(0);
            xlabel(Tlabel); ylabel(Ylabel); title(FIRSTLEVEL_NAME);
            %         legend(h,dispconds(1:3));
            if numel(effect)>1, set(gca,'ylim',[min(effect(:)),max(effect(:))]*[1.5 -.5; -.5 1.5]); end
        else
            if numel(t)>1, dx=(t(2)-t(1))/(size(effect,1)+2); else dx=1/(size(effect,1)+2); end
            for n1=1:size(effect,2),
                for n2=1:size(effect,1)
                    hpatch(n2,n1)=patch(t(n1)+dx*(n2-1)+dx*[-1,-1,1,1]/2*.9,effect(n2,n1)*[0,1,1,0],'k','facecolor',color(n2,:),'edgecolor','none','facealpha',.5);
                    if size(effect,1)==1
                        if p(n2,n1)<=.05&effect(n2,n1)<0, set(hpatch(n2,n1),'facecolor',color(2,:));
                        elseif p(n2,n1)<=.05&effect(n2,n1)>0, set(hpatch(n2,n1),'facecolor',color(3,:));
                        end
                    else
                        if p(n2,n1)<=.05, set(hpatch(n2,n1),'facealpha',.85); end
                    end
                    if ~isempty(effect_CI)
                        h=line(t(n1)+dx*(n2-1)+[1,-1,0,0,1,-1]*dx/8,effect_CI(n2+size(effect_CI,1)/2*[0 0 0 1 1 1],n1),[1,1,1,1,1,1],'linewidth',2,'color',[.75 .75 .75]);
                    end
                end
            end
            grid on
            xlabel(Tlabel); ylabel(Ylabel); title(FIRSTLEVEL_NAME);
            set(gca,'xtick',[]); 
            if numel(t)>1, set(gca,'xlim',[min(t(:)),max(t(:))]*[1.5 -.5; -.5 1.5]); else set(gca,'xlim',[t-3,t+3]); end
        end
        if OPTIONS.PRINT, 
            fprintf('Printing. Please wait... ');
            conn_print(conn_prepend('',filename_outData,'.jpg'),'-nogui'); 
        end
    end
end
varargout={out};
        
%         % plots
%         figure('units','norm','position',[.2 .2 .6 .6],'name',sprintf('sub-%s_ses-%d_run-%d_task-%s_desc-formants.mat',SUB,SES,RUN,TASK));
%         lnames=unique([out_trialData.dataLabel]);
%         for idx=1:numel(lnames), hax(idx)=subplot(floor(sqrt(numel(lnames))),ceil(numel(lnames)/floor(sqrt(numel(lnames)))),idx); hold all; title(lnames{idx}); end
%         for trialNum=reshape(find(keepData),1,[])
%             for ns=1:numel(out_trialData(trialNum).s),
%                 t=out_trialData(trialNum).t{ns}+(0:numel(out_trialData(trialNum).s{ns})-1)/out_trialData(trialNum).fs;
%                 x=out_trialData(trialNum).s{ns};
%                 [ok,idx]=ismember(out_trialData(trialNum).dataLabel{ns},lnames);
%                 h=plot(t,x,'.-','parent',hax(idx));
%                 set(h,'buttondownfcn',@(varargin)fprintf('trial # %d\n',trialNum));
%             end
%         end
%         for idx=1:numel(lnames), axis(hax(idx),'tight'); grid(hax(idx),'on'); end
%         drawnow
%         %if OPTIONS.DOPRINT, conn_print(conn_prepend('',filename_fmtData,'.jpg'),'-nogui'); end
        
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
%     end
% end

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

                