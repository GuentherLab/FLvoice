function varargout = flvoice(varargin)
% FLVOICE  Frank Lab voice tools
%
% FLVOICE LOAD       : loads and processes trial audio data from aud/som experiment (see "help flvoice_load")
% FLVOICE FIRSTLEVEL : first-level analysis of subjects audio data
% FLVOICE PITCH      : estimates pitch from sound sample (see "help flvoice_pitch")
% FLVOICE FORMANTS   : estimates formants from sound sample (see "help flvoice_formants")
% 
% Default options:
%
% FLVOICE DEFAULT ROOT [root_folder]    : returns/defines path to $ROOT$ folder containing data from all subjects (default current folder -pwd-)
% FLVOICE DEFAULT REMOTE [0/1]        : (default 0) 1/0 work remotely (0: when working from SCC computer or on a dataset saved locally on your computer; 1: when working remotely -run "conn remotely on" first from your home computer to connect to SCC; for first-time initialization run on remote server "conn remotely setup")
%


persistent DEFAULTS;
if isempty(DEFAULTS), DEFAULTS=struct('ROOT',[],'REMOTE',false); end

varargout=cell(1,nargout);
if ~isempty(which(sprintf('flvoice_%s',lower(varargin{1})))),
    fh=eval(sprintf('@flvoice_%s',lower(varargin{1})));
    if ~nargout, feval(fh,varargin{2:end});
    else [varargout{1:nargout}]=feval(fh,varargin{2:end});
    end
elseif numel(varargin)>=1&&ischar(varargin{1})&&isfield(DEFAULTS,varargin{1})
    if numel(varargin)>1
        DEFAULTS.(upper(varargin{1}))=varargin{2};
        fprintf('default %s value changed to %s\n',upper(varargin{1}),mat2str(varargin{2}));
        if strcmpi(varargin{1},'REMOTE')&&ischar(DEFAULTS.REMOTE), DEFAULTS.REMOTE=str2num(DEFAULTS.REMOTE); end
    elseif nargout>0, varargout={DEFAULTS.(upper(varargin{1}))};
    else disp(DEFAULTS.(upper(varargin{1})));
    end
elseif numel(varargin)>=1&&ischar(varargin{1})&&strcmpi(varargin{1},'PRIVATE.ROOT')
    if isempty(DEFAULTS.ROOT), ROOT=pwd;
    else ROOT=DEFAULTS.ROOT;
    end
    if DEFAULTS.REMOTE, varargout={fullfile('/CONNSERVER',ROOT)};
    else varargout={ROOT};
    end
else
    error('unrecognized option %s or flvoice_%s function',varargin{1},varargin{1});
end

