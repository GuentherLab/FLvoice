function varargout = flvoice(varargin)
% FLVOICE  Frank Lab voice tools
%
% Main functions:
% FLVOICE IMPORT     : imports and preprocesses trial audio data from aud/som experiment (see "help flvoice_import")
% FLVOICE FIRSTLEVEL : first-level analysis of subjects audio data (see "help flvoice_firstlevel")
%
% Internal functions:
% FLVOICE PITCH      : estimates pitch from sound sample (see "help flvoice_pitch")
% FLVOICE FORMANTS   : estimates formants from sound sample (see "help flvoice_formants")
% 
% Default options:
% FLVOICE ROOT [root_folder]    : returns/defines path to $ROOT$ folder containing data from all subjects (default current folder -pwd-)
% FLVOICE REMOTE [on/off]       : work remotely (default off) (0/off: when working from SCC computer or on a dataset saved locally on your computer; 1/on: when working remotely -run "conn remotely on" first from your home computer to connect to SCC; for first-time initialization run on remote server "conn remotely setup")
%


persistent DEFAULTS;
if isempty(DEFAULTS), DEFAULTS=struct('ROOT',[],'REMOTE',false); end
if ~isempty(varargin)&&ischar(varargin{1})&&strcmpi(varargin{1},'load'), varargin{1}='IMPORT'; end % back-compatibility

varargout=cell(1,nargout);
if ~isempty(which(sprintf('flvoice_%s',lower(varargin{1})))), % calls to flvoice_*.m functions
    fh=eval(sprintf('@flvoice_%s',lower(varargin{1})));
    if ~nargout, feval(fh,varargin{2:end});
    else [varargout{1:nargout}]=feval(fh,varargin{2:end});
    end
elseif numel(varargin)>=1&&ischar(varargin{1})&&isfield(DEFAULTS,upper(varargin{1})) % sets FLVOICE default parameters
    if numel(varargin)>1
        if strcmpi(upper(varargin{1}),'ROOT'), DEFAULTS.(upper(varargin{1}))=conn_fullfile(varargin{2});
        else DEFAULTS.(upper(varargin{1}))=varargin{2};
        end
        fprintf('default %s value changed to %s\n',upper(varargin{1}),mat2str(varargin{2}));
        if strcmpi(upper(varargin{1}),'REMOTE')
            if ischar(DEFAULTS.REMOTE)
                switch(lower(DEFAULTS.REMOTE))
                    case 'on',  DEFAULTS.REMOTE=1;
                    case 'off', DEFAULTS.REMOTE=0;
                    otherwise, DEFAULTS.REMOTE=str2num(DEFAULTS.REMOTE); 
                end
            end
            if DEFAULTS.REMOTE&&~conn_server('isconnected')
                fprintf('Starting new remote connection to server\n');
                conn remotely on;
                conn_server('cmd','addpath(fullfile(fileparts(fileparts(which(''conn''))),''FLvoice''))');
            elseif ~DEFAULTS.REMOTE&&conn_server('isconnected')
                fprintf('Terminating remote connection to server\n');
                conn remotely off;
            end
        end
    elseif nargout>0, varargout={DEFAULTS.(upper(varargin{1}))};
    else disp(DEFAULTS.(upper(varargin{1})));
    end
elseif numel(varargin)>=1&&ischar(varargin{1}) % other
    switch(upper(varargin{1}))
        case 'PRIVATE.ROOT'
            if isempty(DEFAULTS.ROOT), ROOT=pwd;
            else ROOT=DEFAULTS.ROOT;
            end
            if DEFAULTS.REMOTE, varargout={fullfile('/CONNSERVER',ROOT)};
            else varargout={ROOT};
            end
        case 'IMPORT.INPUT'
            [varargout{1:nargout}]=flvoice_import(varargin{2:end},'input');
        case 'IMPORT.OUTPUT'
            [varargout{1:nargout}]=flvoice_import(varargin{2:end},'output');
        case 'submit'
            if ~nargout, conn('submit',mfilename,varargin{2:end}); % e.g. flvoice submit import ...
            else [varargout{1:nargout}]=conn('submit',mfilename,varargin{2:end});
            end
        otherwise
            error('unrecognized option %s',varargin{1});
    end
else
    error('unrecognized option %s or flvoice_%s function',varargin{1},varargin{1});
end

