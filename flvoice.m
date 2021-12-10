function varargout = flvoice(varargin)
% FLVOICE  Frank Lab voice tools
%
% FLVOICE LOAD      : loads and processes audio data from aud/som experiment (see "help flvoice_load")
% FLVOICE PITCH     : estimates pitch from sound sample (see "help flvoice_pitch")
% FLVOICE FORMANTS  : estimates formants from sound sample (see "help flvoice_formants")
%


if ~isempty(which(sprintf('flvoice_%s',lower(varargin{1})))),
    fh=eval(sprintf('@flvoice_%s',lower(varargin{1})));
    if ~nargout, feval(fh,varargin{2:end});
    else [varargout{1:nargout}]=feval(fh,varargin{2:end});
    end
else
    error('unrecognized option %s or flvoice_%s function',varargin{1},varargin{1});
end
