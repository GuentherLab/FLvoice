function varargout=flvoice_secondlevel(SUB,FIRSTLEVEL_NAME, SECONDLEVEL_NAME, DESIGN, CONTRAST_VECTOR, CONTRAST_TIME, varargin)
% data = flvoice_secondlevel(SUB,FIRSTLEVEL_NAME, SECONDLEVEL_NAME, DESIGN, CONTRAST_VECTOR, CONTRAST_TIME) : runs second-level analyses on audio data
%   SUB              : subjects id (e.g. {'test244','test245'}) (default, [] = all subjects)
%   FIRSTLEVEL_NAME  : first-level analysis/contrast name(s)
%   SECONDLEVEL_NAME : second-level analysis name
%   DESIGN           : [M x N] design matrix (M rows, one per subject; N columns, one per modeled effect)
%                      alternatively, function defining one row of design matrix (one row per subject)
%                         fun(subNumber) should return a [1,N] vector of values associated with this trial
%                          e.g. @(subjectNumber, subjectId)[subjectNumber<=10, subjectNumber>10]
%                      the GLM 2nd-level design matrix will be defined in this case by concatenating the @fun output vectors with one row per subject & contrast (all 1st-level contrast for 1st subject, followed by all 1st-level contrasts for 2nd subject, etc.)
%                      if unspecified the default DESIGN value is @(subjectNumber,subjectId)1 (defining a one-sample t-test)
%   CONTRAST_VECTOR  : condition weights defining second-level contrast across modeled effects / columns of design matrix (1 x N vector or k x N matrix)
%                          e.g. [1, -1]
%                      if unspecified the default CONTRAST_VECTOR value is eye(N) with N equal to the number of columns of the design matrix
%   CONTRAST_TIME    : condition weights defining second-level contrast across data elements (e.g. timepoints or within-subjects 1st-level contrasts) (1 x Nt vector or k x Nt matrix)
%                          e.g. [-1 1]
%                      alternatively, function defining contrast values for (or column of CONTRAST_TIME matrix) each data element
%                          e.g. @(idx) (idx<=10) - (idx>10)
%                      if unspecified the default CONTRAST_TIME value is eye(Nt) with Nt equal to the number of first-level analyses times the number of data points per analysis
%
%
% flvoice_secondlevel(... [, OPTION_NAME, OPTION_VALUE, ...]) : runs second-level model estimation using non-default options
%   'CONTRAST_SCALE'   : 1/0 (default 1) scales CONTRAST_TIME rows to maintain original data units (sum of positive values = 1, and if applicable sum of negative values = -1)
%   'SAVE'             : (default 1) 1/0 save analysis results .mat file
%   'PRINT'            : (default 0) 1/0 save jpg files with analysis results
%   'PLOTASTIME'       : (default []) timepoint values for plotting results as a timeseries
%
%
% Input data files: $ROOT$/derivatives/acoustic/sub-##/sub-##_desc-firstlevel_#[FIRSTLEVEL_NAME]#.mat
%   Variables:
%       effect                               : effect-sizes (one value per contrast & timepoint)
%
% Output stats files: $ROOT$/derivatives/acoustic/results/results_desc-secondlevel_#[SECONDLEVEL_NAME]#.mat
%   Variables:
%       effect                               : effect-sizes (one value per contrast & timepoint)
%       effect_CI                            : effect-size 95% confidence intervals
%       stats                                : stats structure with fields
%             X                                    : design matrix
%             Y                                    : data matrix
%             C1                                   : between-subjects contrast vector
%             C2                                   : within-subjects contrast vector
%             h                                    : effect-sizes
%             f                                    : statistics
%             p                                    : p-values
%             pFDR                                 : FDR-corrected p-values
%             dof                                  : degrees of freedom
%             statsname                            : name of statistics ('F' or 'T')
%
%
% Examples:
%
%    flvoice_secondlevel({'sub-PTP001','sub-PTP002','sub-PTP003','sub-PTP004','sub-PTP005'},'test01','onesamplettest',ones(5,1));
%      runs a one-sample t-tets across subjects on the values estimated in the 'test01' 1st-level analysis
%
%    flvoice_secondlevel({'sub-PTP001','sub-PTP002','sub-PTP003','sub-PTP004','sub-PTP005'},'test01','twosamplettest',[1 0;1 0;1 0;0 1;0 1],[-1 1]);
%      runs a two-sample t-tets comparing test01 values across two groups of subjects
%
%    flvoice_secondlevel({'sub-PTP001','sub-PTP002','sub-PTP003','sub-PTP004','sub-PTP005'},{'test01','test02'},'pairedttest',ones(5,1),1,[-1 1]);
%      runs a paired t-tets comparing test01 and test02 values across subjects
%
%    flvoice_secondlevel({'sub-PTP001','sub-PTP002','sub-PTP003','sub-PTP004','sub-PTP005'},'test01','correlation',[ones(5,1),BEHAV],[0 1]);
%      runs a correlation across subejcts between test01 values and a subject-level covariate BEHAV (column vector with one value per subject)
%


persistent DEFAULTS;
if isempty(DEFAULTS), DEFAULTS=struct('CONTRAST_SCALE',true,'PLOTASTIME',[],'SAVE',true,'DOPLOT',true,'PRINT',true); end
if nargin==1&&isequal(SUB,'default'), if nargout>0, varargout={DEFAULTS}; else disp(DEFAULTS); end; return; end
if nargin>1&&isequal(SUB,'default'),
    if nargin>=6, varargin=[{CONTRAST_TIME},varargin]; end
    if nargin>=5, varargin=[{CONTRAST_VECTOR},varargin]; end
    if nargin>=4, varargin=[{DESIGN},varargin]; end
    if nargin>=3, varargin=[{SECONDLEVEL_NAME},varargin]; end
    if nargin>=2, varargin=[{FIRSTLEVEL_NAME},varargin]; end
    for n=1:2:numel(varargin)-1, assert(isfield(DEFAULTS,upper(varargin{n})),'unrecognized default field %s',varargin{n}); DEFAULTS.(upper(varargin{n}))=varargin{n+1}; end %fprintf('default %s value changed to %s\n',upper(varargin{n}),mat2str(varargin{n+1})); end
    return
end

if nargin<1||isempty(SUB), SUB=[]; end
if iscell(SUB)||ischar(SUB), SUB=regexprep(SUB,'^sub-',''); end
if ischar(SUB), SUB={SUB}; end
if nargin<2||isempty(FIRSTLEVEL_NAME), FIRSTLEVEL_NAME=[]; end
if nargin<3||isempty(SECONDLEVEL_NAME), SECONDLEVEL_NAME=[]; end
if nargin<4||isempty(DESIGN), DESIGN=[]; end
if ischar(DESIGN), DESIGN=str2num(DESIGN); assert(~isempty(DESIGN),'unable to interpret DESIGN input'); end
if nargin<5||isempty(CONTRAST_VECTOR), CONTRAST_VECTOR=[]; end
if ischar(CONTRAST_VECTOR), CONTRAST_VECTOR=str2num(CONTRAST_VECTOR); assert(~isempty(CONTRAST_VECTOR),'unable to interpret CONTRAST_VECTOR input'); end
if nargin<6||isempty(CONTRAST_TIME), CONTRAST_TIME=[]; end
if ischar(CONTRAST_TIME), CONTRAST_TIME=str2num(CONTRAST_TIME); assert(~isempty(CONTRAST_VECTOR),'unable to interpret CONTRAST_TIME input'); end

OPTIONS=DEFAULTS;
if numel(varargin)>0, for n=1:2:numel(varargin)-1, assert(isfield(DEFAULTS,upper(varargin{n})),'unrecognized default field %s',varargin{n}); OPTIONS.(upper(varargin{n}))=varargin{n+1}; end; end %fprintf('%s = %s\n',upper(varargin{n}),mat2str(varargin{n+1})); end; end
if ischar(OPTIONS.CONTRAST_SCALE), OPTIONS.CONTRAST_SCALE=str2num(OPTIONS.CONTRAST_SCALE); end
if ischar(OPTIONS.DOPLOT), OPTIONS.DOPLOT=str2num(OPTIONS.DOPLOT); end
if ischar(OPTIONS.SAVE), OPTIONS.SAVE=str2num(OPTIONS.SAVE); end
if ischar(OPTIONS.PRINT), OPTIONS.PRINT=str2num(OPTIONS.PRINT); end
OPTIONS.FILEPATH=flvoice('PRIVATE.ROOT');
varargout=cell(1,nargout);


if isempty(SUB),
    [nill,SUB]=cellfun(@fileparts,conn_dir(fullfile(OPTIONS.FILEPATH,'sub-*'),'-dir','-R','-cell'),'uni',0);
    SUB=regexprep(SUB,'^sub-','');
end
if isempty(FIRSTLEVEL_NAME),
    %filename_outData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',USUBS{nsub}),sprintf('sub-%s_desc-firstlevel_%s.mat',USUBS{nsub},FIRSTLEVEL_NAME));
    [nill,names] = cellfun(@fileparts, conn_dir(fullfile(OPTIONS.FILEPATH,'derivatives','acoustic','sub-*_desc-firstlevel_*.mat'),'-cell'),'uni',0);
    tokens = regexp(names,'sub-(.*)_desc-(.*)$','tokens','once');
    validtokens=cellfun(@(x)iscell(x)&&numel(x)==2,tokens);
    validtokens(validtokens)=cellfun(@(x)ismember(x{1},SUB)&~isempty(x{2}),tokens(validtokens));
    [FIRSTLEVEL_NAME,nill,iidx]=unique(cellfun(@(x)x{2},tokens(validtokens),'uni',0));
    if nargout, varargout={FIRSTLEVEL_NAME};
    else
        disp('available first-level analyses:');
        disp(char(cellfun(@(a,b)[a,' (',num2str(b),')'],FIRSTLEVEL_NAME,num2cell(reshape(accumarray(iidx(:),1),size(FIRSTLEVEL_NAME))),'uni',0)));
    end
    return
end
if ~iscell(FIRSTLEVEL_NAME), FIRSTLEVEL_NAME={FIRSTLEVEL_NAME}; end
FIRSTLEVEL_NAME=regexprep(FIRSTLEVEL_NAME,'^firstlevel_','');
validsub=false(numel(SUB),numel(FIRSTLEVEL_NAME));
Y=[];
X=[];
for nsub=1:numel(SUB)
    y=[];
    for nfl=1:numel(FIRSTLEVEL_NAME)
        filename_inData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic',sprintf('sub-%s',SUB{nsub}),sprintf('sub-%s_desc-firstlevel_%s.mat',SUB{nsub},FIRSTLEVEL_NAME{nfl}));
        if ~conn_existfile(filename_inData), fprintf('file %s not found, skipping this subject\n',filename_inData); break;
        else
            % finds data
            fprintf('loading file %s\n',filename_inData);
            tdata=conn_loadmatfile(filename_inData,'-cache');
            assert(isfield(tdata,'effect'), 'data file %s does not contain effect variable',filename_inData);
            y=cat(2,y, reshape(tdata.effect,1,[])); % note: vectorized data matrix (e.g. conditions x timepoints)
            validsub(nsub,nfl)=true;
        end
    end
    if all(validsub(nsub,:))
        % finds design
        if isa(DESIGN,'function_handle'), x=full(double(DESIGN(nsub,SUB{nsub})));
        else x=DESIGN(nsub,:);
        end
        ok=all(~isnan(x))&any(x~=0);
        if ok % adds this subject to analysis
            if ~isempty(X)&&size(X,2)<size(x,2), X=[X, zeros(size(X,1),size(x,2)-size(X,2))]; fprintf('warning: subject %s design matrix row has %d elements (%d expected). Extending design matrix\n',SUB{nsub},size(x,2),size(X,2)); end
            if size(x,2)<size(X,2), x=[x, zeros(size(x,1),size(X,2)-size(x,2))]; fprintf('warning: subject %s design matrix row has %d elements (%d expected). Extending this row\n',SUB{nsub},size(x,2),size(X,2)); end
            X=[X;x];
            if ~isempty(CONTRAST_TIME)
                if isa(CONTRAST_TIME,'function_handle'), c=double(CONTRAST_TIME(1:numel(y)));
                else c=double(CONTRAST_TIME);
                end
                if numel(y)~=size(c,2), fprintf('warning: subject %s data has %d elements while contrast has %d columns. Cropping to match\n',SUB{nsub},numel(y),size(c,2)); end
                ny=min(numel(y),size(c,2));
                y=y(1:ny);
                c=c(:,1:ny);
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
            end
            if ~isempty(Y)&&size(Y,2)<size(y,2), Y=[Y, nan(size(Y,1),size(y,2)-size(Y,2))]; fprintf('warning: subject %s data has %d elements (%d expected). Extending data matrix with NaN values\n',SUB{nsub},size(y,2),size(Y,2)); end
            if size(y,2)<size(Y,2), y=[y, nan(size(y,1),size(Y,2)-size(y,2))]; fprintf('warning: subject %s data has %d elements (%d expected). Extending data row with NaN values\n',SUB{nsub},size(y,2),size(Y,2)); end
            Y=[Y;y];
        end
    end
end

if isempty(CONTRAST_VECTOR), CONTRAST_VECTOR=eye(size(X,2)); end
validX=any(X~=0,1);
validY=~isnan(Y);
validC=~any(CONTRAST_VECTOR(:,~validX)~=0,2);
nvalid=sum(validY,1);
fprintf('Data: %d (%d-%d) subjects, %d (%d-%d) measures/timepoints\n',size(Y,1),min(nvalid),max(nvalid),size(Y,2),min(sum(validY,2)),max(sum(validY,2)));
stats=struct('X',X,'Y',Y,'C1',CONTRAST_VECTOR,'C2',CONTRAST_TIME);
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
    for n1=reshape(find(nvalid>0&nvalid<size(Y,1)),1,[])
        [h(:,n1),f(:,n1),p(:,n1),dof(:,n1)]=conn_glm(X(validY(:,n1),:),Y(validY(:,n1),n1),CONTRAST_VECTOR,[],options{nrepeat});
    end
    if isequal(statsname,'T'), p=2*min(p,1-p); end % two-sided
    pFDR=conn_fdr(p,2);
    if nrepeat==1, stats.h=h;stats.f=f;stats.p=p;stats.pFDR=pFDR;stats.dof=dof;stats.statsname=statsname;
    else stats.i_f=f;stats.i_p=p;stats.i_pFDR=pFDR;stats.i_dof=dof;stats.i_statsname=statsname;
    end
end

filename_outData=fullfile(OPTIONS.FILEPATH,'derivatives','acoustic','results',sprintf('results_desc-secondlevel_%s.mat',SECONDLEVEL_NAME));
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
if OPTIONS.DOPLOT,
    %color=[ 0.9290/4 0.6940/4 0.1250/4; 0.6500 0.0980 0.0980; 0.8500 0.0980 0.0980];
    if size(effect,1)==1, color=[ .25 .25 .25; 0.0980 0.0980 0.6500 ; 0.6500 0.0980 0.0980];
    else color=jet(max(128,size(effect,1))); color=color(round(linspace(1,size(color,1),size(effect,1))),:);
    end
    figure('units','norm','position',[.2 .3 .6 .3],'color','w');
    h=[]; axes('units','norm','position',[.2 .2 .6 .6]);
    %if isempty(OPTIONS.PLOTASTIME)&&size(effect,1)==1&&size(effect,2)>100, OPTIONS.PLOTASTIME=1:size(effect,2); end
    if ~isempty(OPTIONS.PLOTASTIME)
        t=OPTIONS.PLOTASTIME;
        for n1=1:size(effect,1)
            h=[h plot(t,effect(n1,:),'.-','linewidth',2,'color',color(n1,:))];
            hold all;
            tempx=[t,fliplr(t)];
            tempy=[effect_CI(n1,:),fliplr(effect_CI(n1+size(effect_CI,1)/2,:))];
            tempy2=[effect(n1,:),fliplr(effect(n1,:))];
            maskp1=p(n1,:)>.05;                           maskp1=[maskp1 fliplr(maskp1)]; tempy1=tempy; tempy1(~maskp1)=tempy2(~maskp1); patch(tempx',tempy1','k','edgecolor','none','facecolor',color(n1,:),'facealpha',.25);
            if size(effect,1)==1
                maskp1=p(n1,:)<.05&effect(n1,:)<0;        maskp1=[maskp1 fliplr(maskp1)]; tempy1=tempy; tempy1(~maskp1)=tempy2(~maskp1); patch(tempx',tempy1','k','edgecolor','none','facecolor',color(2,:),'facealpha',.5);
                maskp1=p(n1,:)<.05&effect(n1,1)>0;        maskp1=[maskp1 fliplr(maskp1)]; tempy1=tempy; tempy1(~maskp1)=tempy2(~maskp1); patch(tempx',tempy1','k','edgecolor','none','facecolor',color(3,:),'facealpha',.5);
            else
                maskp1=p(n1,:)<.05;                       maskp1=[maskp1 fliplr(maskp1)]; tempy1=tempy; tempy1(~maskp1)=tempy2(~maskp1); patch(tempx',tempy1','k','edgecolor','none','facecolor',color(n1,:),'facealpha',.5);
            end
        end
        grid on;
        xline(0,'linewidth',3);
        yline(0);
        xlabel('time (ms)'); ylabel('effect size'); title(SECONDLEVEL_NAME);
        if numel(effect)>1, set(gca,'ylim',[min(effect(:)),max(effect(:))]*[1.5 -.5; -.5 1.5]); end
    else
        t=1:size(effect,2);
        if size(effect,1)==1||size(effect,2)==1, dx=1; 
        elseif numel(t)>1, dx=(t(2)-t(1))/(size(effect,1)+2); 
        else dx=1/(size(effect,1)+2); 
        end
        for n1=1:size(effect,2),
            for n2=1:size(effect,1)
                hpatch(n2,n1)=patch(t(n1)+dx*(n2-1)+dx*[-1,-1,1,1]/2*1,effect(n2,n1)*[0,1,1,0],'k','facecolor',color(n2,:),'edgecolor','none','facealpha',.5);
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
        xlabel('measures'); ylabel('effect size'); title(SECONDLEVEL_NAME);
        set(gca,'xtick',[]);
        if numel(t)>1, set(gca,'xlim',[min(t(:)),max(t(:))]*[1.5 -.5; -.5 1.5]); else set(gca,'xlim',[t-3,t+3]); end
    end
    if OPTIONS.PRINT,
        fprintf('Printing. Please wait... ');
        conn_print(conn_prepend('',filename_outData,'.jpg'),'-nogui');
    end
end
end
