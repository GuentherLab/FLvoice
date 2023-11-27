function varargout=flvoice_dirtree(filepath,varargin)
% [sub,ses,run,task] = flvoice_dirtree(filepath)

if nargin<1||isempty(filepath), filepath=flvoice('PRIVATE.ROOT'); end
if flvoice('remote'), [varargout{1:nargout}]=conn_server('run',mfilename,conn_server('util_localfile',filepath),varargin{:}); return; end
varargout=cell(1,nargout);

[nill,SUB]=cellfun(@fileparts,conn_dir(fullfile(filepath,'sub-*'),'-dir','-R','-cell'),'uni',0);
SUB=regexprep(SUB,'^sub-',''); 

SUBS={};
SESS={};
for nSUB=1:numel(SUB)
    [nill,sess]=cellfun(@fileparts,conn_dir(fullfile(filepath,sprintf('sub-%s',SUB{nSUB}),'ses-*'),'-dir','-R','-cell'),'uni',0);
    SESS=[SESS; sess(:)];
    SUBS=[SUBS; repmat(SUB(nSUB),numel(sess),1)];
end
SES=str2double(regexprep(SESS,'^ses-',''));
SUB=SUBS;


SUBS={};
SESS=[];
RUNS={};
TASKS={};
for nsample=1:numel(SUB)
    [nill,runs1]=cellfun(@fileparts,conn_dir(fullfile(filepath,sprintf('sub-%s',SUB{nsample}),sprintf('ses-%d',SES(nsample)),'beh',sprintf('sub-%s_ses-%d_run-*_desc-audio.mat',SUB{nsample},SES(nsample))),'-R','-cell'),'uni',0);
    [nill,runs2]=cellfun(@fileparts,conn_dir(fullfile(filepath,sprintf('sub-%s',SUB{nsample}),sprintf('ses-%d',SES(nsample)),'beh',sprintf('sub-%s_ses-%d_run-*.mat',SUB{nsample},SES(nsample))),'-R','-cell'),'uni',0);
    allruns=union(runs1,runs2);
    if ~isempty(allruns)
        runs=regexprep(allruns,'^.*_(run-[^\._]*)[\._].*$','$1');
        tasks=regexprep(allruns,{'^.*_task-','_expParams$|_desc-audio$'},'');
        [nill,idx]=unique(cellstr([char(runs) char(tasks)]));
        RUNS=[RUNS; runs(idx)];
        TASKS=[TASKS; tasks(idx)];
        SESS=[SESS; repmat(SES(nsample),numel(idx),1)];
        SUBS=[SUBS; repmat(SUB(nsample),numel(idx),1)];
    end
end
RUN=str2double(regexprep(RUNS,'^run-',''));
TASK=TASKS;
SES=SESS;
SUB=SUBS;
maskout=isnan(RUN);
varargout={SUB(~maskout),SES(~maskout),RUN(~maskout),TASK(~maskout)};

