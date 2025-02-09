function varagout=flvoice_QCgui(option,varargin)
% Quality control GUI that utilizes FLvoice
% To run GUI simply use the command.
% >> flvoice_QCgui()
% This will initialize the GUI at the first subject available in the current 'ROOT' folder
%
% If you'd like to start the GUI at a specific subj / trial, use the command structure
% flvoice_QCgui('setup', 'sub', 'ses', 'run', 'task', trialnum)
% ex)
% >> flvoice_QCgui('setup', 'sub-SAP03', 'ses-1', 'run-1', 'som', 1)


% if no input / no /option/, initialize
if ~nargin||isempty(option)
    option ='init';
elseif strcmp(option,'init')
    option = 'init';
else
    option ='setup';
end

switch(lower(option))
    case 'init' % initializing main elements of the GUI
        setup = 0;
        initGUI(setup)
    case 'setup'
        setup = 1;
        if nargin <2; disp('Please input a subject');
        else; sub = varargin{1}; end
        if nargin <3; sess = [];
        else; sess = varargin{2}; end
        if nargin <4; run = [];
        else; run = varargin{3}; end
        if nargin <5; task = [];
        else; task = varargin{4}; end
        if nargin <6; trial = [];
        else; trial = varargin{5}; end
        if ischar(trial); trial = str2double(trial); end
        initGUI(setup, sub, sess, run, task, trial)
end
end

function initGUI(varargin) %(setup, sub, sess, run, task, trial)
if numel(varargin) < 1 || varargin{1} == 0
    setup = 0;
else
    setup = varargin{1};
    sub = varargin{2};
    sess = varargin{3};
    run = varargin{4};
    task = varargin{5};
    trial = varargin{6};
end

% Main figure
data.handles.hfig=figure('Units','norm','Position',[.05 .15 .9 .8],'Menubar','none','Name','FLvoice QC GUI','numbertitle','off','color','w','colormap',jet(256)); %parula(256).*repmat(linspace(0,1,256)',1,3));
% reminder; position is [(bottom left corner normalized x pos) (bottom left corner normalized y pos) (width) (heigth)]

% SETTINGS PANEL
data.handles.settPanel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.02 .45 .2 .52],'Parent',data.handles.hfig);

% Time Settings
data.handles.FSettText=uicontrol('Style', 'text','String','General Settings','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.7,'HorizontalAlignment', 'center','Position',[.1 .95 .8 .05],'Parent',data.handles.settPanel);
data.handles.selectReferenceText=uicontrol('Style', 'text','String','Reference Time:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .90 .4 .05],'Parent',data.handles.settPanel);
data.handles.selectReference=uicontrol('Style', 'edit','String','','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .90 .45 .05],'BackgroundColor', [.94 .94 .94],'Tooltip','<HTML>Reference time (in seconds). This will be the time t=0 in the (time-aligned) output traces<br/>Leave empty to use the default/automatic reference time (defined in the <i>reference_time</i> field of the input files)','Parent',data.handles.settPanel);
data.handles.selectCropText=uicontrol('Style', 'text','String','Crop:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .85 .4 .05],'Parent',data.handles.settPanel);
data.handles.selectCrop=uicontrol('Style', 'edit','String','','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .85 .45 .05],'BackgroundColor', [.94 .94 .94],'Tooltip','<HTML>Crop window (in seconds): timepoints outside the crop window will be filled with NaN / missing-values<br/>Leave empty to keep all of the data within the output window (defined in the <i>OUT_WINDOW</i> input to flvoice_import)','Parent',data.handles.settPanel);
data.handles.selectAmpText=uicontrol('Style', 'text','String','Amp/Dur Min:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .80 .4 .05],'Parent',data.handles.settPanel);
data.handles.selectAmp=uicontrol('Style', 'edit','String','','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .80 .45 .05],'BackgroundColor', [.94 .94 .94],'Tooltip','<HTML>Amplitude & Duration threshold:  Two values: minimum amplitude threshold (in dB units), and minimum duration (in seconds)<br/>Timepoints with amplitude/duration below this threshold will be filled with NaN / missing-values<br/>Set the minimum amplitude to NaN to determine this threshold automatically<br/>Leave empty to keep all of the data irrespective of amplitude','Parent',data.handles.settPanel);

% Formant Settings
data.handles.FSettText=uicontrol('Style', 'text','String','Formant Settings','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.7,'HorizontalAlignment', 'center','Position',[.1 .725 .8 .05],'Parent',data.handles.settPanel);
% Formants (FMT_ARGS)
% 'lporder', 'windowsize', 'viterbfilter', 'medianfilter'
% 'NLPCtxtBox', 'winSizeFtxtBox', 'vfiltertxtBox', 'mfilterFtxtBox'
data.handles.NLPCtxt=uicontrol('Style','text','String','Num LPC:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .675 .4 .05],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
data.handles.NLPCtxtBox=uicontrol('Style','edit','String','[ ]','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .675 .45 .05],'Parent',data.handles.settPanel,'Tooltip','Number of Linear Predictor Coefficients');
data.handles.winSizeFtxt=uicontrol('Style','text','String','Window Size:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .625 .4 .05],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
data.handles.winSizeFtxtBox=uicontrol('Style','edit','String','0.05','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .625 .45 .05],'Parent',data.handles.settPanel,'Tooltip','Sliding window size (in seconds)');
data.handles.vfiltertxt=uicontrol('Style','text','String','Viterbi Filter:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .575 .4 .05],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
data.handles.vfiltertxtBox=uicontrol('Style','edit','String','1','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .575 .45 .05],'Parent',data.handles.settPanel,'Tooltip','Viterbi filter smoothing penalty term (0 for no filter)');
data.handles.mfilterFtxt=uicontrol('Style','text','String','Median Filter:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .525 .4 .05],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
data.handles.mfilterFtxtBox=uicontrol('Style','edit','String','0.25','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .525 .45 .05],'Parent',data.handles.settPanel,'Tooltip','Median filter sliding window size (in seconds)');

% Pitch Settings
data.handles.PSettText=uicontrol('Style', 'text','String','Pitch Settings','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.7,'HorizontalAlignment', 'center','Position',[.1 .45 .8 .05],'Parent',data.handles.settPanel);
% Pitch (F0_ARGS)
% 'windowsize', 'methods', 'range', 'hr_min', 'medianfilter', 'outlierfilter'
% 'winSizePtxtBox', 'methodstxtBox', 'rangetxtBox', 'hr_mintxtBox', 'mfilterPtxtBox', 'ofilterPtxtBox'
data.handles.winSizePtxt=uicontrol('Style','text','String','Window Size:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .40 .4 .05],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
data.handles.winSizePtxtBox=uicontrol('Style','edit','String','0.05','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .40 .45 .05],'Parent',data.handles.settPanel,'Tooltip','Sliding window size (in seconds)');
data.handles.methodstxt=uicontrol('Style','text','String','Methods:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .35 .4 .05],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
data.handles.methodstxtBox=uicontrol('Style','edit','String','CEP','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .35 .45 .05],'Parent',data.handles.settPanel,'Tooltip','Pitch estimation method : CEP (Cepstrum), PEF (Pitch Estimation Filter), NCF (Normalized Correlation Function), LHS (Log-harmonic Summation), SRH (Summation of Residual Harmonics)');
data.handles.rangetxt=uicontrol('Style','text','String','Range:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .30 .4 .05],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
data.handles.rangetxtBox=uicontrol('Style','edit','String','[ ]','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .30 .45 .05],'Parent',data.handles.settPanel,'Tooltip','Range of valid pitch values (in Hz)');
data.handles.hr_mintxt=uicontrol('Style','text','String','HR Min:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .25 .4 .05],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
data.handles.hr_mintxtBox=uicontrol('Style','edit','String','0.5','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .25 .45 .05],'Parent',data.handles.settPanel,'Tooltip','Harmonic ratio threshold (0-1; increase this value to remove segments with low evidence of periodicity)');
data.handles.mfilterPtxt=uicontrol('Style','text','String','Median Filter:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .20 .4 .05],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
data.handles.mfilterPtxtBox=uicontrol('Style','edit','String','1','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .20 .45 .05],'Parent',data.handles.settPanel,'Tooltip','Median filter (in multiples of window size; 0 for no median filtering)');
data.handles.ofilterPtxt=uicontrol('Style','text','String','Outlier Filter:','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'right','Position',[.02 .15 .4 .05],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
data.handles.ofilterPtxtBox=uicontrol('Style','edit','String','0','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.5 .15 .45 .05],'Parent',data.handles.settPanel,'Tooltip','Outlier filter (0/1 values; detect&interpolate outlier values)');
% General
% 'SKIP_LOWAMP'
% 'skipLowAMPtxtBox'
%data.handles.skipLowAtxt=uicontrol('Style','text','String','Skip Lowamp:','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'right','Position',[.02 .10 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
%data.handles.skipLowAMPtxtBox=uicontrol('Style', 'edit','String','[ ]','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.5 .11 .45 .065],'Parent',data.handles.settPanel);

% Update Button
data.handles.upSettButton=uicontrol('Style','pushbutton','String','Update Settings','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.1 .01 .8 .08],'Parent',data.handles.settPanel,'Callback', @updateSettings);

% QC FLAG PANEL
data.handles.flagPanel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.02 .02 .2 .42],'Parent',data.handles.hfig);
data.handles.flagText=uicontrol('Style', 'text','String','QC Flags','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.53,'HorizontalAlignment', 'center','Position',[.2 .915 .6 .08],'Parent',data.handles.flagPanel);
data.handles.Flags={'Performed incorrectly','Bad F0 trace','Bad F1 trace','Incorrect voice onset','Utterance too short','Distortion / audio issues','Needs review'};
FlagsExtended=[data.handles.Flags, {'Others:'}];
%         data.handles.flag1txt=uicontrol('Style', 'checkbox','String',,'Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'right','Position',[.02 .83 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'Callback', @checkFlag1);
%         data.handles.flag2txt=uicontrol('Style', 'checkbox','String',,'Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'right','Position',[.02 .73 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'Callback', @checkFlag2);
%         data.handles.flag3txt=uicontrol('Style', 'checkbox','String',,'Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'right','Position',[.02 .63 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'Callback', @checkFlag3);
%         data.handles.flag4txt=uicontrol('Style', 'checkbox','String',,'Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'right','Position',[.02 .53 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'Callback', @checkFlag4);
%         data.handles.flag5txt=uicontrol('Style', 'checkbox','String',,'Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'right','Position',[.02 .43 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel, 'Callback', @checkFlag5);
%         data.handles.flag6txt=uicontrol('Style', 'checkbox','String',,'Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'right','Position',[.02 .33 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel, 'Callback', @checkFlag6);
%         data.handles.flag7txt=uicontrol('Style', 'checkbox','String','Other:','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'right','Position',[.02 .23 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel, 'Callback', @checkFlag7);
for nflags=1:numel(FlagsExtended),
    data.handles.flag1txt(nflags)=uicontrol('Style', 'checkbox','String',FlagsExtended{nflags},'Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .83-.08*(nflags-1) .9 .08],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'Callback', @(varargin)FlagPN(nflags,'check'));
    data.handles.flagPrev(nflags)=uicontrol('Style', 'pushbutton','String','<','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'center','Position',[.86 .83-.08*(nflags-1) .06 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'visible','off','Callback', @(varargin)FlagPN(nflags,'prev'));
    data.handles.flagNext(nflags)=uicontrol('Style', 'pushbutton','String','>','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'center','Position',[.92 .83-.08*(nflags-1) .06 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'visible','off','Callback', @(varargin)FlagPN(nflags,'next'));
end
data.handles.flag7edit=uicontrol('Style', 'edit','String','Comment','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'center','Position',[.2 .18 .692 .09],'BackgroundColor', [.94 .94 .94], 'Enable', 'off', 'Parent',data.handles.flagPanel,'Callback', @editFlag7);
% Save Flag Button
data.handles.saveFlagButton=uicontrol('Style', 'pushbutton','String','Save flags','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.1 .01 .8 .1],'Parent',data.handles.flagPanel,'Callback', @saveFlags, 'visible','off');

% SUBJECT PANEL
data.handles.subPanel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.24 .89 .742 .08],'Parent',data.handles.hfig);
% Sub
data.handles.subText=uicontrol('Style', 'text','String','Subject:','Units','norm','FontWeight','bold','FontUnits','norm','fontsize',0.4,'HorizontalAlignment', 'left','Position',[.01 .45 .08 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
data.handles.subDrop=uicontrol('Style', 'popupmenu','String','Sub01','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.0 .0 .155 .6],'BackgroundColor', 1*[1 1 1],'Parent',data.handles.subPanel, 'Callback', @subDrop);
% Sess
data.handles.sessionText=uicontrol('Style', 'text','String','Sess:','Units','norm','FontWeight','bold','FontUnits','norm','fontsize',0.4,'HorizontalAlignment', 'left','Position',[.175 .45 .06 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
data.handles.sessionDrop=uicontrol('Style', 'popupmenu','String','1','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.165 .0 .115 .6],'BackgroundColor', 1*[1 1 1],'Parent',data.handles.subPanel, 'Callback', @sessDrop);
% Run
data.handles.runText=uicontrol('Style', 'text','String','Run:','Units','norm','FontWeight','bold','FontUnits','norm','fontsize',0.4,'HorizontalAlignment', 'left','Position',[.3 .45 .045 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
data.handles.runDrop=uicontrol('Style', 'popupmenu','String','1','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.29 .0 .115 .6],'BackgroundColor', 1*[1 1 1],'Parent',data.handles.subPanel, 'Callback', @runDrop);
% Task
data.handles.taskText=uicontrol('Style', 'text','String','Task:','Units','norm','FontWeight','bold','FontUnits','norm','fontsize',0.4,'HorizontalAlignment', 'left','Position',[.425 .45 .06 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
data.handles.taskDrop=uicontrol('Style', 'popupmenu','String','aud','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.415 .0 .11 .6],'BackgroundColor', 1*[1 1 1],'Parent',data.handles.subPanel, 'Callback', @taskDrop);
% Trial
data.handles.trialText=uicontrol('Style', 'text','String','Trial:','Units','norm','FontWeight','bold','FontUnits','norm','fontsize',0.4,'HorizontalAlignment', 'left','Position',[.545 .45 .05 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
data.handles.trialDrop=uicontrol('Style', 'popupmenu','String','1','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.535 .0 .1 .6],'BackgroundColor', 1*[1 1 1],'Parent',data.handles.subPanel, 'Callback', @trialDrop);
% Cond
data.handles.condText=uicontrol('Style', 'text','String','Cond:','Units','norm','FontWeight','bold','FontUnits','norm','fontsize',0.4,'HorizontalAlignment', 'center','Position',[.635 .45 .055 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
data.handles.condVal=uicontrol('Style', 'text','String','N0','Units','norm','FontUnits','norm','fontsize',0.4,'HorizontalAlignment', 'left','Position',[.64 .1 .05 .5],'BackgroundColor', 1*[1 1 1],'Parent',data.handles.subPanel);
% Token
data.handles.tokText=uicontrol('Style', 'text','String','Tok:','Units','norm','FontWeight','bold','FontUnits','norm','fontsize',0.4,'HorizontalAlignment', 'center','Position',[.685 .45 .055 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
data.handles.tokVal=uicontrol('Style', 'text','String','N0','Units','norm','FontUnits','norm','fontsize',0.4,'HorizontalAlignment', 'left','Position',[.695 .1 .05 .5],'BackgroundColor', 1*[1 1 1],'Parent',data.handles.subPanel);
%data.handles.conditionDrop=uicontrol('Style', 'popupmenu','String','N0','Units','norm','FontUnits','norm','fontsize',0.4,'HorizontalAlignment', 'left','Position',[.74 .16 .05 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
% Prev / Next Buttons
data.handles.prevButton=uicontrol('Style', 'pushbutton','String','<Prev','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.75 .55 .12 .55],'Parent',data.handles.subPanel,'Callback', @prevTrial);
data.handles.nextButton=uicontrol('Style', 'pushbutton','String','Next>','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.87 .55 .12 .55],'Parent',data.handles.subPanel,'Callback', @nextTrial);
data.handles.prevFlagButton=uicontrol('Style', 'pushbutton','String','<Prev with flag','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.75 .30 .12 .30],'Parent',data.handles.subPanel,'Callback', @(varargin)FlagPN([],'prev'));
data.handles.nextFlagButton=uicontrol('Style', 'pushbutton','String','Next with flag>','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.87 .30 .12 .30],'Parent',data.handles.subPanel,'Callback', @(varargin)FlagPN([],'next'));
data.handles.prevCondButton=uicontrol('Style', 'pushbutton','String','<Prev with Cond','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.75 .00 .12 .30],'Parent',data.handles.subPanel,'Callback', @(varargin)CondPN([],'prev'));
data.handles.nextCondButton=uicontrol('Style', 'pushbutton','String','Next with Cond>','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.87 .00 .12 .30],'Parent',data.handles.subPanel,'Callback', @(varargin)CondPN([],'next'));


% Axes (Mic / Head / Spectograms) Panel
data.handles.axes1Panel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.24 .02 .742 .84],'Parent',data.handles.hfig,'backgroundcolor',[1 1 1],'BorderType','none');
data.handles.ampAxis = axes('FontUnits', 'normalized', 'fontsize', .05, 'Units', 'normalized', 'Position', [.028, 0.54, .786, 0.06], 'ticklength',[0 0], 'Visible', 'on', 'Tag', 'mic_axis','Parent',data.handles.axes1Panel);
data.handles.micAxis = axes('FontUnits', 'normalized', 'fontsize', .05, 'Units', 'normalized', 'Position', [.028, 0.81, .786, 0.17], 'ticklength',[0 0], 'Visible', 'on', 'box','on', 'Tag', 'mic_axis','Parent',data.handles.axes1Panel);
data.handles.referenceAxis = axes('FontUnits', 'normalized', 'fontsize', .05, 'Units', 'normalized', 'Position',[.028, 0.67, .786, 0.04], 'ticklength',[0 0], 'Visible', 'on', 'Tag', 'reference_axis','Parent',data.handles.axes1Panel);
%data.handles.pitchAxis = axes('FontUnits', 'normalized', 'Units', 'normalized', 'Position', [-0.12, 0.32, 1.14, 0.25], 'Visible', 'on', 'Tag', 'pitch_axis','Parent',data.handles.axes1Panel);
data.handles.ppAxis = axes('FontUnits', 'normalized', 'fontsize', .05, 'Units', 'normalized', 'Position', [0.028, 0.10, 0.786, 0.2], 'Visible', 'on', 'Tag', 'pp_axis','Parent',data.handles.axes1Panel);
data.handles.formantAxis = axes('FontUnits', 'normalized', 'fontsize', .05, 'Units', 'normalized', 'Position', [0.028, 0.32, 0.786, 0.2], 'Visible', 'on', 'Tag', 'formant_axis','Parent',data.handles.axes1Panel);
data.handles.globalAxis = axes('FontUnits', 'normalized', 'fontsize', .05, 'Units', 'normalized', 'Position',[.028, 0.10, .786, 0.88], 'ticklength',[0 0], 'Visible', 'off', 'Tag', 'global_axis','Parent',data.handles.axes1Panel);

% Axes Buttons
data.handles.selectSourceText=uicontrol('Style', 'text','String','Input source:','Units','norm','FontWeight','normal','FontUnits','norm','fontsize',0.65,'HorizontalAlignment', 'left','Position',[.845 .96 .15 .025],'BackgroundColor', [1 1 1],'Parent',data.handles.axes1Panel);
data.handles.selectSource=uicontrol('Style', 'popupmenu','String',{'mic'},'value',1,'Units','norm','FontUnits','norm','FontSize',0.40,'HorizontalAlignment', 'left','Position',[.845 .91 .15 .04],'BackgroundColor', 1*[1 1 1],'Parent',data.handles.axes1Panel, 'Callback', @trialDrop);
data.handles.playMicButton=uicontrol('Style', 'pushbutton','String','Play','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'center','Position',[.845 .75 .15 .04],'Parent',data.handles.axes1Panel,'Callback', @playMic);
data.handles.spectAxis = axes('FontUnits', 'normalized', 'fontsize', .10, 'Units', 'normalized', 'Position', [0.845, 0.81, 0.15, 0.10], 'xcolor',.75*[1 1 1], 'ycolor',.75*[1 1 1], 'Visible', 'on', 'box','on', 'Tag', 'spectrum_axis','Parent',data.handles.axes1Panel);

%data.handles.playHeadButton=uicontrol('Style', 'pushbutton','String','<html>Play<br/>Head</html>','Units','norm','FontUnits','norm','FontSize',0.20,'HorizontalAlignment', 'center','Position',[.93 .67 .07 .08],'Parent',data.handles.axes1Panel,'Callback', @playHead);

data.handles.ppMic=[];
data.handles.fmtMic=[];
data.handles.ppAxis_checkbox = uicontrol('style','checkbox','Units', 'normalized', 'Position', [0.008, 0.10, 0.02, 0.02], 'backgroundcolor',[1 1 1], 'value',1, 'Visible', 'on', 'Tag', 'pp_checkbox','Parent',data.handles.axes1Panel,'callback','data=get(gcbf,''userdata''); if get(gcbo,''value'')>0, set(data.handles.ppMic, ''visible'',''on''); else set(data.handles.ppMic, ''visible'',''off''); end');
data.handles.formantAxis_checkbox = uicontrol('style','checkbox','Units', 'normalized', 'Position', [0.008, 0.32, 0.02, 0.02], 'backgroundcolor',[1 1 1], 'value', 1, 'Visible', 'on', 'Tag', 'pp_checkbox','Parent',data.handles.axes1Panel,'callback','data=get(gcbf,''userdata''); if get(gcbo,''value'')>0, set(data.handles.fmtMic, ''visible'',''on''); else set(data.handles.fmtMic, ''visible'',''off''); end');
data.handles.selectColormap=uicontrol('Style', 'popupmenu','String',regexprep({'jet','parula','turbo','hsv','hot','cool','spring','summer','autumn','winter','gray','bone','copper','pink','sky','abyss'},'^.*$','colormap $0'),'value',1,'Units','norm','FontUnits','norm','FontSize',0.40,'HorizontalAlignment', 'left','Position',[.028 .01 .15 .04],'BackgroundColor', 1*[1 1 1],'Parent',data.handles.axes1Panel, 'Callback', 'map=regexprep(get(gcbo,''string''),''colormap\s*'',''''); colormap(map{get(gcbo,''value'')});');
data.handles.selectZoomText=uicontrol('Style', 'pushbutton','String','Reset zoom','Units','norm','FontUnits','norm','FontSize',0.65,'HorizontalAlignment', 'right','Position',[.20 .035 .10 .025],'BackgroundColor', 1*[1 1 1],'Parent',data.handles.axes1Panel,'callback',@(varargin)ZoomIn(varargin{:},'reset'));
data.handles.selectZoom=uicontrol('Style', 'edit','String','','Units','norm','FontUnits','norm','FontSize',0.65,'HorizontalAlignment', 'center','Position',[.20 .01 .10 .025],'BackgroundColor', 1*[1 1 1],'Tooltip','Enter window limits for display (in seconds)','Parent',data.handles.axes1Panel, 'Callback', @ZoomIn);

%optional buttons
%data.handles.trialTimeButton=uicontrol('Style', 'pushbutton','String','View trial timing','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.02 .02 .3 .06], 'Enable', 'off', 'Parent',data.handles.axes1Panel, 'Callback', @viewTime);
%data.handles.refTimeButton=uicontrol('Style', 'pushbutton','String','Change reference time','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.4 .02 .3 .06], 'Enable', 'off','Parent',data.handles.axes1Panel,'Callback', @changeReference);
data.handles.saveExitButton=uicontrol('Style', 'pushbutton','String','<html>Exit</html>','Units','norm','FontUnits','norm','FontSize',0.33,'HorizontalAlignment', 'left','Position',[.845 .005 .15 .06],'Parent',data.handles.axes1Panel,'Callback', @dontsaveExit);
data.handles.plotGraphsButton=uicontrol('Style', 'pushbutton','String','<html>Plot Graphs</html>','Units','norm','FontUnits','norm','FontSize',0.33,'HorizontalAlignment', 'left','Position',[.650 .005 .15 .06],'Parent',data.handles.axes1Panel,'Callback', @plotGraphs);

% Update GUI to current sub / trial
switch setup
    case 0
        updateSubj(data);
    case 1 % start GUI at requested subj
        updateSubj(data, sub, sess, run, task, trial)
        %if subj empty, 'disp' message requesting at least subj
        %if sess missing, default to fist available (but this
        %   is usually done in updateSubj (may be redundant here)
        %if run missing, default to first available run
        %if task is missing find task of current run
        %if trial missing default to 1st......
end

set(zoom(data.handles.hfig),'motion','horizontal','actionpostcallback',@(varargin)ZoomIn(varargin{:},'callback'),'enable','on');
if ~ishandle(data.handles.hfig), return; end
data = get(data.handles.hfig, 'userdata');
% if ~isempty(data)
%     set(data.handles.hfig,'userdata',data);
% end
end



function updateSettings(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

set(data.handles.hfig,'pointer','watch');
drawnow;
% disable buttons while loading
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton, data.handles.prevCondButton, data.handles.nextCondButton, data.handles.flagPrev, data.handles.flagNext], 'Enable', 'off');

% Formants (FMT_ARGS)
% 'lporder', 'windowsize', 'viterbfilter', 'medianfilter'
% 'NLPCtxtBox', 'winSizeFtxtBox', 'vfiltertxtBox', 'mfilterFtxtBox'
lporder = str2num(get(data.handles.NLPCtxtBox, 'String'));
windowsizeF = str2num(get(data.handles.winSizeFtxtBox, 'String'));
viterbfilter = str2num(get(data.handles.vfiltertxtBox, 'String'));
medianfilterF = str2num(get(data.handles.mfilterFtxtBox, 'String'));
% Pitch (F0_ARGS)
% 'windowsize', 'methods', 'range', 'hr_min', 'medianfilter', 'outlierfilter'
% 'winSizePtxtBox', 'methodstxtBox', 'rangetxtBox', 'hr_mintxtBox', 'mfilterPtxtBox', 'ofilterPtxtBox'
windowsizeP = str2num(get(data.handles.winSizePtxtBox, 'String'));
methods = get(data.handles.methodstxtBox, 'String');
range = str2num(get(data.handles.rangetxtBox, 'String'));
hr_min = str2num(get(data.handles.hr_mintxtBox, 'String'));
medianfilterP = str2num(get(data.handles.mfilterPtxtBox, 'String'));
outlierfilter = str2num(get(data.handles.ofilterPtxtBox, 'String'));
ReferenceTime = str2num(get(data.handles.selectReference, 'String'));
CropTime = str2num(get(data.handles.selectCrop, 'String'));
MinAmp = str2num(get(data.handles.selectAmp, 'String'));
if numel(MinAmp)>1, MinDur=MinAmp(2); else MinDur=[]; end
if numel(MinAmp)>0, MinAmp=MinAmp(1); end
%lowamp = str2num(get(data.handles.selectMinAmp, 'String'));
%lowdur = str2num(get(data.handles.selectMinDur, 'String'));
% General
% 'SKIP_LOWAMP'
% 'skipLowAMPtxtBox'
%SKIP_LOWAMP = str2num(get(data.handles.skipLowAMPtxtBox, 'String'));

curSub = data.vars.curSub; curSess = data.vars.curSess; curRun = data.vars.curRun; curTask = data.vars.curTask; curTrial = data.vars.curTrial;

choice = conn_questdlg('Re-process this subjects entire run, or just this trial?', 'Update Settings', 'Current run', 'Just Trial', 'Cancel', 'Just Trial');
switch choice
    case 'Current run'
%         data.vars.curRunQC.settings{data.vars.curTrial}.lporder = lporder;
%         data.vars.curRunQC.settings{data.vars.curTrial}.windowsizeF = windowsizeF;
%         data.vars.curRunQC.settings{data.vars.curTrial}.viterbfilter = viterbfilter;
%         data.vars.curRunQC.settings{data.vars.curTrial}.medianfilterF = medianfilterF;
%         data.vars.curRunQC.settings{data.vars.curTrial}.windowsizeP = windowsizeP;
%         data.vars.curRunQC.settings{data.vars.curTrial}.methods = methods;
%         data.vars.curRunQC.settings{data.vars.curTrial}.range = range;
%         data.vars.curRunQC.settings{data.vars.curTrial}.hr_min = hr_min;
%         data.vars.curRunQC.settings{data.vars.curTrial}.medianfilterP = medianfilterP;
%         data.vars.curRunQC.settings{data.vars.curTrial}.outlierfilter = outlierfilter;
%         data.vars.curRunQC.settings{data.vars.curTrial}.SKIP_LOWAMP = SKIP_LOWAMP;
%         data.vars.curRunQC.settings(1:end) = data.vars.curRunQC.settings(data.vars.curTrial);
        SKIP_LOWAMP=''; try, if ~isempty(data.vars.curOutputINFO.options.SKIP_LOWAMP), SKIP_LOWAMP =  mat2str(data.vars.curOutputINFO.options.SKIP_LOWAMP); end; end
        SKIP_LOWDUR=''; try, if ~isempty(data.vars.curOutputINFO.options.SKIP_LOWDUR), SKIP_LOWDUR =  mat2str(data.vars.curOutputINFO.options.SKIP_LOWDUR); end; end
        OUT_WINDOW=[]; try, if ~isempty(data.vars.curOutputINFO.options.OUT_WINDOW), OUT_WINDOW =  data.vars.curOutputINFO.options.OUT_WINDOW; end; end
        answ=conn_menu_inputdlg(...
            {'Minimum amplitude (in dB units)','Minimum duration (in seconds)'},...
            'Automatic QC labeling of low-amplitude or low-duration utterances (select cancel to skip)',...
            1,...
            {SKIP_LOWAMP, SKIP_LOWDUR});
        if isempty(answ), 
            SKIP_LOWAMP=[];
            SKIP_LOWDUR=[];
        else
            SKIP_LOWAMP=str2num(answ{1});
            SKIP_LOWDUR=str2num(answ{2});
        end
        flvoice_import(curSub,curSess,curRun,curTask, ...
            'PRINT',false,...
            'N_LPC',lporder, 'F0_RANGE',range, ... % obsolete: delete this line
            'FMT_ARGS',{'lpcorder',lporder, 'windowsize',windowsizeF, 'viterbifilter',viterbfilter, 'medianfilter', medianfilterF}, ...
            'F0_ARGS', {'windowsize',windowsizeP, 'methods',methods, 'range',range, 'hr_min',hr_min, 'medianfilter',medianfilterP, 'outlierfilter',outlierfilter}, ...
            'SKIP_LOWAMP', SKIP_LOWAMP, 'SKIP_LOWDUR', SKIP_LOWDUR, 'OUT_WINDOW', OUT_WINDOW, 'REFERENCE_TIME', ReferenceTime, 'CROP_TIME', CropTime, 'MINAMP', MinAmp, 'MINDUR', MinDur);

    case 'Just Trial'
%         data.vars.curRunQC.settings{data.vars.curTrial}.lporder = lporder;
%         data.vars.curRunQC.settings{data.vars.curTrial}.windowsizeF = windowsizeF;
%         data.vars.curRunQC.settings{data.vars.curTrial}.viterbfilter = viterbfilter;
%         data.vars.curRunQC.settings{data.vars.curTrial}.medianfilterF = medianfilterF;
%         data.vars.curRunQC.settings{data.vars.curTrial}.windowsizeP = windowsizeP;
%         data.vars.curRunQC.settings{data.vars.curTrial}.methods = methods;
%         data.vars.curRunQC.settings{data.vars.curTrial}.range = range;
%         data.vars.curRunQC.settings{data.vars.curTrial}.hr_min = hr_min;
%         data.vars.curRunQC.settings{data.vars.curTrial}.medianfilterP = medianfilterP;
%         data.vars.curRunQC.settings{data.vars.curTrial}.outlierfilter = outlierfilter;
%         data.vars.curRunQC.settings{data.vars.curTrial}.SKIP_LOWAMP = SKIP_LOWAMP;
        OUT_WINDOW=[]; try, if ~isempty(data.vars.curOutputINFO.options.OUT_WINDOW), OUT_WINDOW =  data.vars.curOutputINFO.options.OUT_WINDOW; end; end
        flvoice_import(curSub,curSess,curRun,curTask, 'SINGLETRIAL', curTrial, ...
            'PRINT',false,...
            'N_LPC',lporder, 'F0_RANGE',range, ... % obsolete: delete this line
            'FMT_ARGS',{'lpcorder',lporder, 'windowsize',windowsizeF, 'viterbifilter',viterbfilter, 'medianfilter', medianfilterF}, ...
            'F0_ARGS', {'windowsize',windowsizeP, 'methods',methods, 'range',range, 'hr_min',hr_min, 'medianfilter',medianfilterP, 'outlierfilter',outlierfilter}, ...
            'OUT_WINDOW', OUT_WINDOW, 'REFERENCE_TIME', ReferenceTime, 'CROP_TIME', CropTime, 'MINAMP', MinAmp, 'MINDUR', MinDur);
%             'SKIP_LOWAMP', SKIP_LOWAMP);

    case 'Cancel'
%         set(data.handles.hfig,'pointer','arrow');
%         drawnow;
%         return
end

%flvoice_import(curSub,curSess,curRun,curTask, 'set_qc', data.vars.curRunQC)
set(data.handles.hfig,'pointer','arrow');
drawnow;
% re-enable buttons when done
updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, data.vars.curTrial);
data = get(data.handles.hfig, 'userdata');
end

function FlagPN(nflags,option)
hfig=gcbf;
data=get(hfig,'userdata');
switch(option)
    case {'prev','next'}
        % before changing subject save cur subj / ses / run's QC flags
        sub = data.vars.curSub;
        ses = data.vars.curSess;
        run = data.vars.curRun;
        task = data.vars.curTask;
        curRunQC = data.vars.curRunQC;
        flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)

        curTrial = data.vars.curTrial;
        curRunQC = data.vars.curRunQC;
        if isempty(nflags), nflags=1:size(curRunQC.badTrial,1); 
        elseif nflags>numel(data.handles.Flags), nflags=numel(data.handles.Flags)+1:size(curRunQC.badTrial,1);
        end
        if strcmp(option,'prev'), nextTrial = find(any(curRunQC.badTrial(nflags,1:curTrial-1),1),1,'last');
        else nextTrial = curTrial + find(any(curRunQC.badTrial(nflags,curTrial+1:end),1),1);
        end
        if ~isempty(nextTrial)
            updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, nextTrial);
            data = get(data.handles.hfig, 'userdata');
            %data.vars.curTrial = nextTrial;
        end

        set(data.handles.hfig,'userdata',data);
    
    case 'check'
        flagVal = get(data.handles.flag1txt(nflags), 'Value');
        curTrial = data.vars.curTrial;
        curRunQC = data.vars.curRunQC;
        if flagVal
            curRunQC.keepData(curTrial) = 0;
            if nflags>numel(data.handles.Flags)
                set(data.handles.flag7edit, 'Enable', 'on');
            else
                curRunQC.badTrial(nflags,curTrial) = 1;
            end
        else
            curRunQC.keepData(curTrial) = 1;
            if nflags>numel(data.handles.Flags)
                set(data.handles.flag7edit, 'String', 'Comment', 'Enable', 'off');
                curRunQC.badTrial(nflags:end,curTrial) = 0;
            else
                curRunQC.badTrial(nflags,curTrial) = 0;
            end
        end
        data.vars.curRunQC = curRunQC;
        set(data.handles.hfig,'userdata',data);
end
end

function CondPN(nflags,option)
    hfig=gcbf;
    data=get(hfig,'userdata');
    switch(option)
        case {'prev','next'}
            % before changing subject save cur subj / ses / run's QC flags
            sub = data.vars.curSub;
            ses = data.vars.curSess;
            run = data.vars.curRun;
            task = data.vars.curTask;
            curRunQC = data.vars.curRunQC;
            flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)
    
            curTrial = data.vars.curTrial;
            curRunQC = data.vars.curRunQC;
            if isempty(nflags), nflags=1:size(curRunQC.badTrial,1); 
            elseif nflags>numel(data.handles.Flags), nflags=numel(data.handles.Flags)+1:size(curRunQC.badTrial,1);
            end
            if strcmp(option,'prev'), nextTrial = find(strcmp({data.vars.curOutputData(1:curTrial-1).condLabel}, data.vars.curOutputData(curTrial).condLabel), 1, 'last');
            else nextTrial = curTrial + find(strcmp({data.vars.curOutputData(curTrial+1:end).condLabel}, data.vars.curOutputData(curTrial).condLabel), 1); end
            if ~isempty(nextTrial)
                updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, nextTrial);
                data = get(data.handles.hfig, 'userdata');
                %data.vars.curTrial = nextTrial;
            end
    
            set(data.handles.hfig,'userdata',data);
    end
end

%     function checkFlag1(ObjH, EventData)
%     hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
%     data=get(hfig,'userdata');
%
%     flagVal = get(data.handles.flag1txt, 'Value');
%     curTrial = data.vars.curTrial;
%     %curRunQCflags = data.vars.curRunQCflags;
%     %curRunQCflags{curTrial,1} = flagVal;
%     %data.vars.curRunQCflags = curRunQCflags;
%     curRunQC = data.vars.curRunQC;
%     if flagVal
%         curRunQC.keepData(curTrial) = 0;
%         curRunQC.badTrial(1,curTrial) = 1;
%         if isempty(curRunQC.dictionary{1,curTrial})
%             curRunQC.dictionary{1,curTrial} = {'Performed incorrectly'};
%         else
%             curRunQC.dictionary{1,curTrial} = {curRunQC.dictionary{1,curTrial}, 'Performed incorrectly'};
%         end
%     else
%         curRunQC.keepData(curTrial) = 1;
%         curRunQC.badTrial(1,curTrial) = 0;
%         QCdict = curRunQC.dictionary{1,curTrial};
%         QCdict(ismember(QCdict,'Performed incorrectly')) = [];
%         curRunQC.dictionary{1,curTrial} = QCdict;
%     end
%     data.vars.curRunQC = curRunQC;
%     set(data.handles.hfig,'userdata',data);
%     end
%
%     function checkFlag2(ObjH, EventData)
%     hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
%     data=get(hfig,'userdata');
%
%     flagVal = get(data.handles.flag2txt, 'Value');
%     curTrial = data.vars.curTrial;
%     %curRunQCflags = data.vars.curRunQCflags;
%     %curRunQCflags{curTrial,2} = flagVal;
%     %data.vars.curRunQCflags = curRunQCflags;
%     curRunQC = data.vars.curRunQC;
%     if flagVal
%         curRunQC.keepData(curTrial) = 0;
%         curRunQC.badTrial(2,curTrial) = 1;
%         if isempty(curRunQC.dictionary{1,curTrial})
%             curRunQC.dictionary{1,curTrial} = {'Bad F0 trace'};
%         else
%             curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial}, 'Bad F0 trace'];
%         end
%     else
%         curRunQC.keepData(curTrial) = 1;
%         curRunQC.badTrial(2,curTrial) = 0;
%         QCdict = curRunQC.dictionary{1,curTrial};
%         QCdict(ismember(QCdict,'Bad F0 trace')) = [];
%         curRunQC.dictionary{1,curTrial} = QCdict;
%     end
%     data.vars.curRunQC = curRunQC;
%     set(data.handles.hfig,'userdata',data);
%     end
%
%     function checkFlag3(ObjH, EventData)
%     hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
%     data=get(hfig,'userdata');
%
%     flagVal = get(data.handles.flag3txt, 'Value');
%     curTrial = data.vars.curTrial;
%     %curRunQCflags = data.vars.curRunQCflags;
%     %curRunQCflags{curTrial,3} = flagVal;
%     %data.vars.curRunQCflags = curRunQCflags;
%     curRunQC = data.vars.curRunQC;
%     if flagVal
%         curRunQC.keepData(curTrial) = 0;
%         curRunQC.badTrial(3,curTrial) = 1;
%         if isempty(curRunQC.dictionary{1,curTrial})
%             curRunQC.dictionary{1,curTrial} = {'Bad F1 trace'};
%         else
%             curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial}, 'Bad F1 trace'];
%         end
%     else
%         curRunQC.keepData(curTrial) = 1;
%         curRunQC.badTrial(3,curTrial) = 0;
%         QCdict = curRunQC.dictionary{1,curTrial};
%         QCdict(ismember(QCdict,'Bad F1 trace')) = [];
%         curRunQC.dictionary{1,curTrial} = QCdict;
%     end
%     data.vars.curRunQC = curRunQC;
%     set(data.handles.hfig,'userdata',data);
%     end
%
%     function checkFlag4(ObjH, EventData)
%     hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
%     data=get(hfig,'userdata');
%
%     flagVal = get(data.handles.flag4txt, 'Value');
%     curTrial = data.vars.curTrial;
%     %curRunQCflags = data.vars.curRunQCflags;
%     %curRunQCflags{curTrial,4} = flagVal;
%     %data.vars.curRunQCflags = curRunQCflags;
%     curRunQC = data.vars.curRunQC;
%     if flagVal
%         curRunQC.keepData(curTrial) = 0;
%         curRunQC.badTrial(4,curTrial) = 1;
%         if isempty(curRunQC.dictionary{1,curTrial})
%             curRunQC.dictionary{1,curTrial} = {'Incorrect voice onset'};
%         else
%             curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial}, 'Incorrect voice onset'];
%         end
%     else
%         curRunQC.keepData(curTrial) = 1;
%         curRunQC.badTrial(4,curTrial) = 0;
%         QCdict = curRunQC.dictionary{1,curTrial};
%         QCdict(ismember(QCdict,'Incorrect voice onset')) = [];
%         curRunQC.dictionary{1,curTrial} = QCdict;
%     end
%     data.vars.curRunQC = curRunQC;
%     set(data.handles.hfig,'userdata',data);
%     end
%
%     function checkFlag5(ObjH, EventData)
%     hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
%     data=get(hfig,'userdata');
%
%     flagVal = get(data.handles.flag5txt, 'Value');
%     curTrial = data.vars.curTrial;
%     %curRunQCflags = data.vars.curRunQCflags;
%     %curRunQCflags{curTrial,5} = flagVal;
%     %data.vars.curRunQCflags = curRunQCflags;
%     curRunQC = data.vars.curRunQC;
%     if flagVal
%         curRunQC.keepData(curTrial) = 0;
%         curRunQC.badTrial(5,curTrial) = 1;
%         if isempty(curRunQC.dictionary{1,curTrial})
%             curRunQC.dictionary{1,curTrial} = {'Utterance too short'};
%         else
%             curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial}, 'Utterance too short'];
%         end
%     else
%         curRunQC.keepData(curTrial) = 1;
%         curRunQC.badTrial(5,curTrial) = 0;
%         QCdict = curRunQC.dictionary{1,curTrial};
%         QCdict(ismember(QCdict,'Utterance too short')) = [];
%         curRunQC.dictionary{1,curTrial} = QCdict;
%     end
%     data.vars.curRunQC = curRunQC;
%     set(data.handles.hfig,'userdata',data);
%     end
%
%     function checkFlag6(ObjH, EventData)
%     hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
%     data=get(hfig,'userdata');
%
%     flagVal = get(data.handles.flag6txt, 'Value');
%     curTrial = data.vars.curTrial;
%     %curRunQCflags = data.vars.curRunQCflags;
%     %curRunQCflags{curTrial,6} = flagVal;
%     %data.vars.curRunQCflags = curRunQCflags;
%     curRunQC = data.vars.curRunQC;
%     if flagVal
%         curRunQC.keepData(curTrial) = 0;
%         curRunQC.badTrial(6,curTrial) = 1;
%         if isempty(curRunQC.dictionary{1,curTrial})
%             curRunQC.dictionary{1,curTrial} = {'Distortion / audio issues'};
%         else
%             curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial}, 'Distortion / audio issues'];
%         end
%     else
%         curRunQC.keepData(curTrial) = 1;
%         curRunQC.badTrial(6,curTrial) = 0;
%         QCdict = curRunQC.dictionary{1,curTrial};
%         QCdict(ismember(QCdict,'Distortion / audio issues')) = [];
%         curRunQC.dictionary{1,curTrial} = QCdict;
%     end
%     data.vars.curRunQC = curRunQC;
%     set(data.handles.hfig,'userdata',data);
%     end
%
%     function checkFlag7(ObjH, EventData)
%     hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
%     data=get(hfig,'userdata');
%
%     flagVal = get(data.handles.flag7txt, 'Value');
%     %QCcomment = get(data.handles.flag7edit, 'String');
%     curTrial = data.vars.curTrial;
%     %curRunQCflags = data.vars.curRunQCflags;
%     curRunQC = data.vars.curRunQC;
%     if flagVal
%         set(data.handles.flag7edit, 'Enable', 'on');
%         curRunQC.keepData(curTrial) = 0;
%         curRunQC.badTrial(7,curTrial) = 1;
%         %curRunQC.badTrial(curTrial) = get(data.handles.flag7edit, 'String');
%     else
%         QCcomment = get(data.handles.flag7edit, 'String');
%         QCdict = curRunQC.dictionary{1,curTrial};
%         QCdict(ismember(QCdict,QCcomment)) = [];
%         curRunQC.dictionary{1,curTrial} = QCdict;
%         curRunQC.keepData(curTrial) = 1;
%         curRunQC.badTrial(7,curTrial) = 0;
%         set(data.handles.flag7edit, 'String', 'Comment', 'Enable', 'off');
%         %curRunQCflags{curTrial,7} = 0;
%     end
%     %data.vars.curRunQCflags = curRunQCflags;
%     data.vars.curRunQC = curRunQC;
%     set(data.handles.hfig,'userdata',data);
%     end

function editFlag7(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

QCcomment = deblank(get(data.handles.flag7edit, 'String'));
curTrial = data.vars.curTrial;
%curRunQCflags = data.vars.curRunQCflags;
%curRunQCflags{curTrial,7} = QCcomment;
%data.vars.curRunQCflags = curRunQCflags;
curRunQC = data.vars.curRunQC;
%curDict =  curRunQC.dictionary{curTrial};

[ok,imatch]=ismember(QCcomment,curRunQC.dictionary);
if ~ok
    curRunQC.dictionary = [curRunQC.dictionary,  {QCcomment}];
    imatch = numel(curRunQC.dictionary);
end

curRunQC.badTrial(numel(data.handles.Flags)+1:end,curTrial) = 0;
curRunQC.badTrial(imatch,curTrial) = 1;
% removes unused flags
keep=union(1:numel(data.handles.Flags),find(any(curRunQC.badTrial>0,2)));
curRunQC.dictionary=curRunQC.dictionary(keep);
curRunQC.badTrial = curRunQC.badTrial(keep,:);
data.vars.curRunQC = curRunQC;
set(data.handles.hfig,'userdata',data);
end

function saveFlags(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

sub = data.vars.curSub;
ses = data.vars.curSess;
run = data.vars.curRun;
task = data.vars.curTask;
%curRunQCflags = data.vars.curRunQCflags;
%saveFileName = sprintf('%s_%s_%s_%s_QC_Flags.mat', sub, ses, run, task);
%varName = 'curRunQCflags';
%save(saveFileName,varName);
curRunQC = data.vars.curRunQC;
flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)

set(data.handles.hfig,'userdata',data);
end

function subDrop(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

set(data.handles.hfig,'pointer','watch');
drawnow;
% disable buttons when loading
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton,  data.handles.prevCondButton, data.handles.nextCondButton], 'Enable', 'off');

% before changing subject save cur subj / ses / run's QC flags
sub = data.vars.curSub;
ses = data.vars.curSess;
run = data.vars.curRun;
task = data.vars.curTask;
%curRunQCflags = data.vars.curRunQCflags;
%saveFileName = sprintf('%s_%s_%s_%s_QC_Flags.mat', sub, ses, run, task);
%varName = 'curRunQCflags';
%save(saveFileName,varName);
try
    curRunQC = data.vars.curRunQC;
    flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)
end

subList = data.vars.subList;
newSubIdx = get(data.handles.subDrop, 'Value');
newSub = subList{newSubIdx};

% sessList = flvoice('import', newSub);
% % check for empty sessions
% for i = 1:numel(sessList)
%     if ~isempty(flvoice('import', newSub, sessList{i}))
%         continue
%     else
%         sessList{i} = [];
%     end
% end
% emptyIdx = cellfun(@isempty,sessList);
% sessList(emptyIdx) = [];
% curSess = sessList{1};
% data.vars.curSess = curSess;
% 
% runList = flvoice('import',newSub, curSess);
% curRun = runList{1};
% data.vars.curRun = curRun;
% 
% taskList = flvoice('import',newSub, curSess, curRun);
% set(data.handles.taskDrop, 'String', taskList, 'Value', 1);
% curTask = taskList{get(data.handles.taskDrop, 'Value')};

updateSubj(data, newSub, [], [], [], 1);
data = get(data.handles.hfig, 'userdata');
% data.vars.curSub = newSub;

set(data.handles.hfig,'pointer','arrow');
drawnow;
% % re-enable buttons when done
% set(data.handles.hfig,'userdata',data);
end

function sessDrop(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

set(data.handles.hfig,'pointer','watch');
drawnow;
% disable buttons when loading
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton, data.handles.prevCondButton, data.handles.nextCondButton, data.handles.flagPrev, data.handles.flagNext], 'Enable', 'off');

% before changing subject save cur subj / ses / run's QC flags
sub = data.vars.curSub;
ses = data.vars.curSess;
run = data.vars.curRun;
task = data.vars.curTask;
%curRunQCflags = data.vars.curRunQCflags;
%saveFileName = sprintf('%s_%s_%s_%s_QC_Flags.mat', sub, ses, run, task);
%varName = 'curRunQCflags';
%save(saveFileName,varName);
try
    curRunQC = data.vars.curRunQC;
    flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)
end

sessList = data.vars.sessList;
newSessIdx = get(data.handles.sessionDrop, 'Value');
newSess = sessList{newSessIdx};
% 
% runList = flvoice('import',sub, newSess);
% curRun = runList{1};
% data.vars.curRun = curRun;
% 
% taskList = flvoice('import',sub, newSess, curRun);
% set(data.handles.taskDrop, 'String', taskList, 'Value', 1);
% curTask = taskList{get(data.handles.taskDrop, 'Value')};
% %data.vars.taskList = taskList;
% %data.vars.curTask = curTask;

updateSubj(data, data.vars.curSub, newSess, [], [], 1);
data = get(data.handles.hfig, 'userdata');
% data.vars.curSess = newSess;

set(data.handles.hfig,'pointer','arrow');
drawnow;
% set(data.handles.hfig,'userdata',data);
end

function runDrop(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

set(data.handles.hfig,'pointer','watch');
drawnow;
% disable buttons when loading
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton, data.handles.prevCondButton, data.handles.nextCondButton, data.handles.flagPrev, data.handles.flagNext], 'Enable', 'off');

% before changing subject save cur subj / ses / run's QC flags
sub = data.vars.curSub;
ses = data.vars.curSess;
run = data.vars.curRun;
task = data.vars.curTask;

%curRunQCflags = data.vars.curRunQCflags;
%saveFileName = sprintf('%s_%s_%s_%s_QC_Flags.mat', sub, ses, run, task);
%varName = 'curRunQCflags';
%save(saveFileName,varName);
try
    curRunQC = data.vars.curRunQC;
    flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)
end

runList = data.vars.runList;
newRunIdx = get(data.handles.runDrop, 'Value');
newRun = runList{newRunIdx};

% %not all runs have the same task:
% taskList = flvoice_import(sub,ses,newRun);
% newTask = taskList{end}; % will there ever be 2 tasks per run?

updateSubj(data, data.vars.curSub, data.vars.curSess, newRun, [], 1);
data = get(data.handles.hfig, 'userdata');
% data.vars.curRun = newRun;
% data.vars.curTask = newTask;

set(data.handles.hfig,'pointer','arrow');
drawnow;
% set(data.handles.hfig,'userdata',data);
end

function taskDrop(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

set(data.handles.hfig,'pointer','watch');
drawnow;
% disable buttons when loading
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton, data.handles.prevCondButton, data.handles.nextCondButton, data.handles.flagPrev, data.handles.flagNext], 'Enable', 'off');

% before changing subject save cur subj / ses / run's QC flags
sub = data.vars.curSub;
ses = data.vars.curSess;
run = data.vars.curRun;
task = data.vars.curTask;
%curRunQCflags = data.vars.curRunQCflags;
%saveFileName = sprintf('%s_%s_%s_%s_QC_Flags.mat', sub, ses, run, task);
%varName = 'curRunQCflags';
%save(saveFileName,varName);
try
    curRunQC = data.vars.curRunQC;
    flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)
end

taskList = data.vars.taskList;
newTaskIdx = get(data.handles.taskDrop, 'Value');
newTask = taskList{newTaskIdx};
updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, newTask, 1);
data = get(data.handles.hfig, 'userdata');
% data.vars.curTask = newTask;

set(data.handles.hfig,'pointer','arrow');
drawnow;
% set(data.handles.hfig,'userdata',data);
end

function trialDrop(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

set(data.handles.hfig,'pointer','watch');
drawnow;
% disable buttons when loading
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton, data.handles.prevCondButton, data.handles.nextCondButton, data.handles.flagPrev, data.handles.flagNext], 'Enable', 'off');

% before changing subject save cur subj / ses / run's QC flags
sub = data.vars.curSub;
ses = data.vars.curSess;
run = data.vars.curRun;
task = data.vars.curTask;
%curRunQCflags = data.vars.curRunQCflags;
%saveFileName = sprintf('%s_%s_%s_%s_QC_Flags.mat', sub, ses, run, task);
%varName = 'curRunQCflags';
%save(saveFileName,varName);
curRunQC = data.vars.curRunQC;
flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)

newTrial = get(data.handles.trialDrop, 'Value');
updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, newTrial);
data = get(data.handles.hfig, 'userdata');
% data.vars.curTrial = newTrial;

set(data.handles.hfig,'pointer','arrow');
drawnow;
% set(data.handles.hfig,'userdata',data);
end

function prevTrial(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');
% disable buttons while loading
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton, data.handles.prevCondButton, data.handles.nextCondButton, data.handles.flagPrev, data.handles.flagNext], 'Enable', 'off');

% before changing subject save cur subj / ses / run's QC flags
sub = data.vars.curSub;
ses = data.vars.curSess;
run = data.vars.curRun;
task = data.vars.curTask;
%curRunQCflags = data.vars.curRunQCflags;
%saveFileName = sprintf('%s_%s_%s_%s_QC_Flags.mat', sub, ses, run, task);
%varName = 'curRunQCflags';
%save(saveFileName,varName);
curRunQC = data.vars.curRunQC;
flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)

curTrial = data.vars.curTrial;
prevTrial = curTrial - 1;
trialList = data.vars.trialList;
if curTrial == trialList(1)
    choice = questdlg('This is the first trial for this run, attempt to load previous run?', 'Change runs?', 'Yes', 'No', 'No');
    switch choice
        case 'Yes'
            curRun = data.vars.curRun;
            runList = data.vars.runList;
            runIdx = find(strcmp(runList,curRun));
            prevIdx = runIdx-1;
            if prevIdx < 1;
                warning = msgbox('Previous run does not exist, consider changing session?');
            else
                prevRun = runList{prevIdx};
                taskList = data.vars.taskList;
                updateSubj(data, data.vars.curSub, data.vars.curSess, prevRun, taskList{1}, 1) % maybe should load last trial of prev run
                data = get(data.handles.hfig, 'userdata');
%                 data.vars.curRun = prevRun;
                data.vars.curTrial = 1;
            end
        case 'No'
            updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, data.vars.curTrial);
            data = get(data.handles.hfig, 'userdata');
    end
else
    updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, prevTrial);
    data = get(data.handles.hfig, 'userdata');
%     data.vars.curTrial = prevTrial;
end

set(data.handles.hfig,'userdata',data);
end

function nextTrial(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

% disable buttons while loading
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton, data.handles.prevCondButton, data.handles.nextCondButton, data.handles.flagPrev, data.handles.flagNext], 'Enable', 'off');

% before changing subject save cur subj / ses / run's QC flags
sub = data.vars.curSub;
ses = data.vars.curSess;
run = data.vars.curRun;
task = data.vars.curTask;
%curRunQCflags = data.vars.curRunQCflags;
%saveFileName = sprintf('%s_%s_%s_%s_QC_Flags.mat', sub, ses, run, task);
%varName = 'curRunQCflags';
%save(saveFileName,varName);
curRunQC = data.vars.curRunQC;
flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)

curTrial = data.vars.curTrial;
nextTrial = curTrial + 1;
trialList = data.vars.trialList;
if curTrial == trialList(end)
    choice = questdlg('This is the last trial for this run, attempt to load next run?', 'Change runs?', 'Yes', 'No', 'No');
    switch choice
        case 'Yes'
            curRun = data.vars.curRun;
            runList = data.vars.runList;
            runIdx = find(strcmp(runList,curRun));
            nextIdx = runIdx+1;
            if nextIdx > numel(runList)
                warning = msgbox('Next run does not exist, consider changing session?')
            else
                nextRun = runList{nextIdx};
                taskList = data.vars.taskList;
                updateSubj(data, data.vars.curSub, data.vars.curSess, nextRun, taskList{1}, 1)
                data = get(data.handles.hfig, 'userdata');
%                 data.vars.curRun = nextRun;
%                 data.vars.curTrial = 1;
            end
        case 'No'
            updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, data.vars.curTrial);
            data = get(data.handles.hfig, 'userdata');
    end
else
    updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, nextTrial);
    data = get(data.handles.hfig, 'userdata');
    %data.vars.curTrial = nextTrial;
end

set(data.handles.hfig,'userdata',data);
end

function ZoomIn(ObjH, EventData, xlimits)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');
if nargin<3||isempty(xlimits), xlimits=str2num(get(data.handles.selectZoom,'string')); end
if isequal(xlimits,'reset'), set(data.handles.micAxis,'xtick',round(10*data.vars.xlimits(1))/10:.1:round(10*data.vars.xlimits(end))/10);
else set(data.handles.micAxis,'xticklabel',[],'xtickmode','auto','xticklabelmode','auto'); 
end
if isequal(xlimits,'callback'), 
    xlimits=get(EventData.Axes,'xlim');
    if isequal(EventData.Axes,data.handles.spectAxis), set(data.handles.spectAxis,'xticklabel',[],'xtickmode','auto','xticklabelmode','auto'); return; end
elseif isequal(xlimits,'reset'), xlimits=data.vars.xlimits; 
end
if numel(xlimits)~=2, return; end
set(data.handles.selectZoom,'string',mat2str(xlimits,4)); 
set([data.handles.globalAxis, data.handles.referenceAxis,data.handles.micAxis,data.handles.ampAxis, data.handles.formantAxis,data.handles.ppAxis],'xlim', xlimits);
set(data.handles.micAxis,'ylim',1.1*max(abs(data.vars.micWav))*[-1 1]);
updateSpect(data.handles.spectAxis, data.vars.micWav(data.vars.micTime>=xlimits(1)&data.vars.micTime<=xlimits(2)), data.vars.fs, data.handles.spectPlot);
end

function playMic(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

curTrial = data.vars.curTrial;
micWav = data.vars.micWav;
fs = data.vars.curInputData(curTrial).fs;
soundsc(micWav, fs, [-0.2 , 0.2]); % low and high placed as in some cases sound scaled to be way to loud

%set(data.handles.hfig,'userdata',data);
end

% function playHead(ObjH, EventData)
% hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
% data=get(hfig,'userdata');
% 
% curTrial = data.vars.curTrial;
% headWav = data.vars.headWav;
% fs = data.vars.curInputData(curTrial).fs;
% soundsc(headWav, fs, [-0.2 , 0.2]); % low and high placed as in some cases sound scaled to be way to loud
% 
% %set(data.handles.hfig,'userdata',data);
% end
% 
function viewTime(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

%set(data.handles.hfig,'userdata',data);
end

function changeReference(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

%set(data.handles.hfig,'userdata',data);
end

function saveExit(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');

sub = data.vars.curSub;
ses = data.vars.curSess;
run = data.vars.curRun;
task = data.vars.curTask;
curRunQC = data.vars.curRunQC;
flvoice_import(sub,ses,run,task, 'set_qc', curRunQC)
closereq();
end

function dontsaveExit(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
close(hfig);
end

function plotGraphs(ObjH, EventData)
hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
data=get(hfig,'userdata');
sub = data.vars.curSub;
ses = data.vars.curSess;
run = data.vars.curRun;
task = data.vars.curTask;
flvoice_import(sub,ses,run,task, 'plot', true, 'overwrite', false)
end

function updateSubj(data,varargin)
% Helper function that updates the GUI based on current sub / trial
set(data.handles.hfig,'pointer','watch');
% disable buttons while loading
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton,  data.handles.prevCondButton, data.handles.nextCondButton, data.handles.flagPrev, data.handles.flagNext], 'Enable', 'off');
drawnow;

if ~isfield(data,'vars')||~isfield(data.vars,'allsubList')
    [data.vars.allsubList,data.vars.allsesList,data.vars.allrunList,data.vars.alltaskList]=flvoice_dirtree;
    if isempty(data.vars.allsubList),
        close(data.handles.hfig);
        warndlg({sprintf('Unable to find any sub-* directories in root folder %s',flvoice('private.root')),'Please change the root folder of your subject directories using the syntax:',' ','flvoice root YOURROOTFOLDER'});
        return
    end
end
if numel(varargin) < 1
    % init = 1;
    sub = [];
    sess = [];
    run = [];
    task=[];
    trial=[];
else
    % init = 0;
    sub = varargin{1}; if ischar(sub), sub=regexprep(sub,'sub-',''); end
    sess = varargin{2}; if ischar(sess), sess=str2double(regexprep(sess,'ses-','')); end
    run = varargin{3};  if ischar(run), run=str2double(regexprep(run,'run-','')); end
    task = varargin{4};
    trial = varargin{5}; if ischar(trial), trial=str2double(regexprep(trial,'trial-','')); end
    % if it's the same sub, sess, task, no need to run fl_import in the future
    % if 0,%isfield(data,'vars')
    %     if isequal(sub,data.vars.curSub) && isequal(sess,data.vars.curSess) && isequal(run,data.vars.curRun) && isequal(task,data.vars.curTask)
    %         loadData = 0;
    %     else
    %         loadData = 1;
    %     end
    % else
    %     loadData = 1;
    % end
end

subList=data.vars.allsubList;
sesList=data.vars.allsesList;
runList=data.vars.allrunList;
taskList=data.vars.alltaskList;

if isempty(sub)&&isfield(data.vars,'curSub')&&ismember(data.vars.curSub,subList), sub=data.vars.curSub; end
if isempty(sub), sub=subList{1}; end
ok = ismember(subList,regexprep(sub,'sub-',''));
assert(any(ok), 'unable to find subject %s',sub);
[usubList,nill,isubList]=unique(subList);
[subList,sesList,runList,taskList]=deal(subList(ok),sesList(ok),runList(ok),taskList(ok));
data.vars.subList = regexprep(usubList,'^.*','sub-$0');
set(data.handles.subDrop, 'String',data.vars.subList, 'Value', isubList(find(ok,1)));
data.vars.curSub = sub;

if isempty(sess)&&isfield(data.vars,'curSess')&&ismember(data.vars.curSess,sesList), sess=data.vars.curSess; end
if isempty(sess), sess=sesList(1); end
[ok,idx] = ismember(sesList,sess);
assert(any(ok), 'unable to find session %d',sess);
[usesList,nill,isesList]=unique(sesList);
[subList,sesList,runList,taskList]=deal(subList(ok),sesList(ok),runList(ok),taskList(ok));
data.vars.sessList=arrayfun(@(n)sprintf('ses-%d',n),usesList,'uni',0);
set(data.handles.sessionDrop, 'String',data.vars.sessList, 'Value', isesList(find(ok,1)));
data.vars.curSess = sess;

if isempty(run)&&isfield(data.vars,'curRun')&&ismember(data.vars.curRun,runList), run=data.vars.curRun; end
if isempty(run), run=runList(1); end
[ok,idx] = ismember(runList,run);
assert(any(ok), 'unable to find run %d',run);
[urunList,nill,irunList]=unique(runList);
[subList,sesList,runList,taskList]=deal(subList(ok),sesList(ok),runList(ok),taskList(ok));
data.vars.runList=arrayfun(@(n)sprintf('run-%d',n),urunList,'uni',0);
set(data.handles.runDrop, 'String',data.vars.runList, 'Value', irunList(find(ok,1)));
data.vars.curRun = run;

if isempty(task)&&isfield(data.vars,'curTask')&&ismember(data.vars.curTask,taskList), task=data.vars.curTask; end
if isempty(task), task=taskList{1}; end
[ok,idx] = ismember(taskList,task);
assert(any(ok), 'unable to find task %d',task);
[utaskList,nill,itaskList]=unique(taskList);
[subList,sesList,runList,taskList]=deal(subList(ok),sesList(ok),runList(ok),taskList(ok));
data.vars.taskList=utaskList;
set(data.handles.taskDrop, 'String',data.vars.taskList, 'Value', itaskList(find(ok,1)));
data.vars.curTask = task;

% if init % set values to first value in each droplist
% 
%     if isempty(subList),
%         close(data.handles.hfig);
%         warndlg({sprintf('Unable to find any sub-* directories in root folder %s',flvoice('private.root')),'Please change the root folder of your subject directories using the syntax:',' ','flvoice root YOURROOTFOLDER'});
%         return
%     end
% 
% 
%     % update subjects
%     subList = flvoice('import');
%     for i = 1:numel(subList)
%         if isempty(flvoice('import', subList{i})) % if no sessions skip subj
%             subList{i} = [];
%             continue
%         else
%             sessL = flvoice('import', subList{i}); %  if session is empty, exclude it
%             allempty = 1;
%             for j = 1:numel(sessL)
%                 tsess = sessL{j};
%                 if ~isempty(flvoice('import', subList{i},tsess))
%                     allempty = 0;
%                     continue
%                 end
%             end
%             if allempty == 1 % if all sessions are empty, exclude the subject
%                 subList{i} = [];
%                 continue
%             end
%         end
%     end
%     emptyIdx = cellfun(@isempty,subList);
%     subList(emptyIdx) = [];
%     if isempty(subList),
%         close(data.handles.hfig);
%         warndlg({sprintf('Unable to find any sub-* directories in root folder %s',flvoice('private.root')),'Please change the root folder of your subject directories using the syntax:',' ','flvoice root YOURROOTFOLDER'});
%         return
%     end
%     data.vars.subList = subList;
%     set(data.handles.subDrop, 'String', subList, 'Value', 1);
%     disp('Loading default data from root folder:')
%     curSub = subList{get(data.handles.subDrop, 'Value')};
%     fprintf('Loading subject %s:', curSub);
%     data.vars.subList = subList;
%     data.vars.curSub = curSub;
% 
%     % update sess
%     sessList = flvoice('import', curSub);
%     % check for empty sessions
%     for i = 1:numel(sessList)
%         if ~isempty(flvoice('import', curSub, sessList{i}))
%             continue
%         else
%             sessList{i} = [];
%         end
%     end
%     emptyIdx = cellfun(@isempty,sessList);
%     sessList(emptyIdx) = [];
%     set(data.handles.sessionDrop, 'String', sessList, 'Value', 1);
%     curSess = sessList{get(data.handles.sessionDrop, 'Value')};
%     data.vars.sessList = sessList;
%     data.vars.curSess = curSess;
% 
%     sub=curSub;
%     sess=curSess;
%     run=[];
%     task=[];
%     trial=[];
%     loadData=true;
% 
% end % set values based on given inputs

% update subjects
% if isfield(data, 'vars') && isfield(data.vars, 'subList')
%     subList = data.vars.subList;
% else
%     subList = flvoice('import');
%     for i = 1:numel(subList)
%         sessL = flvoice('import', subList{i});
%         if isempty(sessL) % if no sessions skip subj
%             subList{i} = [];
%             continue
%         else
%             allempty = 1;
%             for j = 1:numel(sessL)
%                 tsess = sessL{j};
%                 if ~isempty(flvoice('import', subList{i},tsess))
%                     allempty = 0;
%                     continue
%                 end
%             end
%             if allempty == 1 % if all sessions are empty, exclude the subject
%                 subList{i} = [];
%                 continue
%             end
%         end
%     end
% end

% emptyIdx = cellfun(@isempty,subList);
% subList(emptyIdx) = [];
% data.vars.subList = subList;
% subIdx = find(contains(subList,sub));
% set(data.handles.subDrop, 'String', subList, 'Value', subIdx);
% data.vars.curSub = sub;

% % update sess
% sessList = flvoice('import', sub);
% % check for empty sessions
% for i = 1:numel(sessList)
%     if ~isempty(flvoice('import', sub, sessList{i}))
%         continue
%     else
%         sessList{i} = [];
%     end
% end
% emptyIdx = cellfun(@isempty,sessList);
% sessList(emptyIdx) = [];
% if isempty(sess)
%     sess = sessList{1};
% end
% sessIdx = find(contains(sessList,sess));
% set(data.handles.sessionDrop, 'String', sessList, 'Value', sessIdx);
% data.vars.sessList = sessList;
% data.vars.curSess = sess;

% % update run
% runList = flvoice('import', sub,sess);
% if isempty(run)
%     run = runList{1};
% end
% runIdx = find(contains(runList,run));
% set(data.handles.runDrop, 'String', runList, 'Value', runIdx);
% data.vars.runList = runList;
% data.vars.curRun = run;

% % update task
% taskList = flvoice('import', sub,sess,run);
% if isempty(task)
%     task = taskList{1};
% end
% taskIdx = find(contains(taskList,task));
% set(data.handles.taskDrop, 'String', taskList, 'Value', taskIdx);
% data.vars.taskList = taskList;
% data.vars.curTask = task;

% get trial data
loadData=1;
if loadData % only run fl_voice_import() if data being loaded is different from current
    curInputData = flvoice_import(sub,sess,run,task,'input');
    curInputData = curInputData{1};
    if ~isfield(curInputData, 's') || ~isfield(curInputData, 'fs') %&&~isfield(curInputData, 'audapData')&&~isfield(curInputData, 'audioData')
        msgbox("Current subject / run has not been pre-processed using flvoice yet. Please select a different subject/run or use flvoice to pre-process data before using the GUI.", 'Warning', 'warn')
        set([findobj(data.handles.settPanel);findobj(data.handles.flagPanel);findobj(data.handles.axes1Panel)],'visible','off')
        set(data.handles.hfig,'userdata',data);
        return
    end
else
    curInputData = data.vars.curInputData;
end
set([findobj(data.handles.settPanel);findobj(data.handles.flagPanel);findobj(data.handles.axes1Panel)],'visible','on');
if loadData % only run fl_voice_import() if data being loaded is different from current
    curOutputData = flvoice_import(sub,sess,run,task,'output_all');
    curOutputINFO = curOutputData{1}.INFO;
    curOutputData = curOutputData{1}.trialData;
else
    curOutputINFO = data.vars.curOutputINFO;
    curOutputData = data.vars.curOutputData;
end

% update trial
trialList = (1:size(curInputData,2));
if isempty(trial)
    trial = trialList(1);
end
trialIdx = find(trialList == trial); % most likely unecessary but useful for futureproofing
set(data.handles.trialDrop, 'String', trialList, 'Value', trialIdx);
curCond = curInputData(trial).condLabel;
set(data.handles.condVal, 'String', curCond);
curTok = curInputData(trial).stimName;
set(data.handles.tokVal, 'String', curTok)
data.vars.trialList = trialList;
data.vars.curCond = curCond;
data.vars.curTrial = trial;

% load previous flags if they exist here
curRunQC = flvoice_import(sub,sess,run,task, 'get_qc');
numFlags = numel(data.handles.Flags);

% updates QC format if necessary
if iscell(curRunQC.dictionary)&&~isempty(curRunQC.dictionary)&&any(cellfun(@iscell,curRunQC.dictionary)) % converts old format (explicit label per trial) to new format (common dictionary of labels)
    newdictionary={};
    newbadTrial=zeros(0,size(curRunQC.badTrial,2));
    for idxj=reshape(find(any(curRunQC.badTrial>0,1)),1,[]),
        label=curRunQC.dictionary{idxj};
        if iscell(label), label=sprintf('%s ',label{:}); end
        label=deblank(label);
        [ok,imatch]=ismember(label,newdictionary);
        if ~ok
            newdictionary{end+1}=label;
            imatch=numel(newdictionary);
        end
        newbadTrial(imatch,idxj)=1;
    end
    curRunQC.badTrial=newbadTrial;
    curRunQC.dictionary=newdictionary;
    curRunQC.keepData=reshape(all(isnan(curRunQC.badTrial)|curRunQC.badTrial==0,1),1,[]);
end
if size(curRunQC.badTrial,2) < size(data.vars.trialList,2) || size(curRunQC.keepData,2) < size(data.vars.trialList,2) % new trials were added (NOTE: ASSUME NEW TRIALS ARE AT THE END)
    fprintf('Warning: mismatch number of trials in QC file. Please double-check QC flag assignments\n');
    curRunQC.badTrial = [curRunQC.badTrial zeros(size(curRunQC.badTrial,1), (size(data.vars.trialList,2)- size(curRunQC.badTrial,2)))];
    curRunQC.keepData=reshape(all(isnan(curRunQC.badTrial)|curRunQC.badTrial==0,1),1,[]);
    %curRunQC.settings{1,size(data.vars.trialList,2)} = [];
end
% removes unused flags
keep=find(any(curRunQC.badTrial>0,2));
curRunQC.dictionary=curRunQC.dictionary(keep);
curRunQC.badTrial = curRunQC.badTrial(keep,:);
% adds GUI flags
curRunQC.dictionary = [data.handles.Flags, curRunQC.dictionary];
curRunQC.badTrial = [zeros(numFlags,size(curRunQC.badTrial,2)); curRunQC.badTrial];
newdictionary={};
newbadTrial=zeros(0,size(curRunQC.badTrial,2));
for nflags=1:numel(curRunQC.dictionary)
    if ~ismember(curRunQC.dictionary{nflags},newdictionary)
        newdictionary=[newdictionary, curRunQC.dictionary(nflags)];
        newbadTrial=[newbadTrial; any(curRunQC.badTrial(ismember(curRunQC.dictionary,curRunQC.dictionary(nflags)),:),1)];
    end
end
curRunQC.badTrial=newbadTrial;
curRunQC.dictionary=newdictionary;

for nflags=1:numFlags,
    set(data.handles.flag1txt(nflags),'value',curRunQC.badTrial(nflags,trial));
end
set(data.handles.flag1txt(numFlags+1),'value',any(curRunQC.badTrial(numFlags+1:end,trial)));
%         set(data.handles.flag1txt, 'Value',  curRunQC.badTrial(1,trial));
%         set(data.handles.flag2txt, 'Value',  curRunQC.badTrial(2,trial));
%         set(data.handles.flag3txt, 'Value',  curRunQC.badTrial(3,trial));
%         set(data.handles.flag4txt, 'Value',  curRunQC.badTrial(4,trial));
%         set(data.handles.flag5txt, 'Value',  curRunQC.badTrial(5,trial));
%         set(data.handles.flag6txt, 'Value',  curRunQC.badTrial(6,trial));
if all(curRunQC.badTrial(numFlags+1:end,trial) == 0,1)
    set(data.handles.flag7edit, 'String', 'Comment', 'Enable', 'off');
else
    set(data.handles.flag7edit, 'String',  curRunQC.dictionary{numFlags+find(curRunQC.badTrial(numFlags+1:end,trial))}, 'Enable', 'on');
end
data.vars.curRunQC = curRunQC;

% gets information from output files to update GUI values
if isfield(curOutputData,'options') && ~isempty(curOutputData(trial).options.formants) && ~isempty(curOutputData(trial).options.pitch)
    if isempty(curOutputData(trial).options.formants.lpcorder); lporder = '[ ]'; else; lporder =  num2str(curOutputData(trial).options.formants.lpcorder); end
    set(data.handles.NLPCtxtBox, 'String', lporder);
    set(data.handles.winSizeFtxtBox, 'String', num2str(curOutputData(trial).options.formants.windowsize));
    set(data.handles.vfiltertxtBox, 'String', num2str(curOutputData(trial).options.formants.viterbifilter));
    set(data.handles.mfilterFtxtBox, 'String', num2str(curOutputData(trial).options.formants.medianfilter));
    set(data.handles.winSizePtxtBox, 'String', num2str(curOutputData(trial).options.pitch.windowsize));
    set(data.handles.methodstxtBox, 'String', curOutputData(trial).options.pitch.methods);
    if isempty(curOutputData(trial).options.pitch.range); range = '[ ]'; else; range = [ '[' num2str(curOutputData(trial).options.pitch.range) ']' ]; end
    set(data.handles.rangetxtBox, 'String', range);
    set(data.handles.hr_mintxtBox, 'String', num2str(curOutputData(trial).options.pitch.hr_min));
    set(data.handles.mfilterPtxtBox, 'String', num2str(curOutputData(trial).options.pitch.medianfilter));
    set(data.handles.ofilterPtxtBox, 'String', num2str(curOutputData(trial).options.pitch.outlierfilter));
    set(data.handles.methodstxtBox, 'String', curOutputData(trial).options.pitch.methods);
    if isfield(curOutputData(trial).options,'time')&&isfield(curOutputData(trial).options.time,'reference')&&~isempty(curOutputData(trial).options.time.reference), set(data.handles.selectReference, 'String', curOutputData(trial).options.time.reference); 
    else set(data.handles.selectReference, 'String', ''); 
    end
    if isfield(curOutputData(trial).options,'time')&&isfield(curOutputData(trial).options.time,'crop')&&~isempty(curOutputData(trial).options.time.crop), set(data.handles.selectCrop, 'String', mat2str(curOutputData(trial).options.time.crop));
    else set(data.handles.selectCrop, 'String', ''); 
    end
    if isfield(curOutputData(trial).options,'time')&&isfield(curOutputData(trial).options.time,'minamp')&&~isempty(curOutputData(trial).options.time.minamp), set(data.handles.selectAmp, 'String', mat2str([curOutputData(trial).options.time.minamp curOutputData(trial).options.time.mindur]));
    else set(data.handles.selectAmp, 'String', ''); 
    end
    %if isempty(curOutputINFO.options.SKIP_LOWAMP); SKIP_LOWAMP = '[ ]'; else; SKIP_LOWAMP =  num2str(curOutputINFO.options.SKIP_LOWAMP); end
    %set(data.handles.skipLowAMPtxtBox, 'String', SKIP_LOWAMP);
    % backward compat for trial prior to 'options' field additon in flvoice
elseif isfield(curRunQC,'settings') && numel(curRunQC.settings)>=trial && ~isempty(curRunQC.settings{trial}) % OBSOLETE: this information is now stored in output data files 'options' field
    if isempty(curRunQC.settings{trial}.lporder); lporder = '[ ]'; else; lporder =  num2str(curRunQC.settings{trial}.lporder); end
    set(data.handles.NLPCtxtBox, 'String', lporder);
    set(data.handles.winSizeFtxtBox, 'String', num2str(curRunQC.settings{trial}.windowsizeF));
    set(data.handles.vfiltertxtBox, 'String', num2str(curRunQC.settings{trial}.viterbfilter));
    set(data.handles.mfilterFtxtBox, 'String', num2str(curRunQC.settings{trial}.medianfilterF));
    set(data.handles.winSizePtxtBox, 'String', num2str(curRunQC.settings{trial}.windowsizeP));
    set(data.handles.methodstxtBox, 'String', curRunQC.settings{trial}.methods);
    if isempty(curRunQC.settings{trial}.range); range = '[ ]'; else; range =  num2str(curRunQC.settings{trial}.lporder); end
    set(data.handles.rangetxtBox, 'String', range);
    set(data.handles.hr_mintxtBox, 'String', num2str(curRunQC.settings{trial}.hr_min));
    set(data.handles.mfilterPtxtBox, 'String', num2str(curRunQC.settings{trial}.medianfilterP));
    set(data.handles.ofilterPtxtBox, 'String', num2str(curRunQC.settings{trial}.outlierfilter));
    set(data.handles.selectReference, 'String', ''); 
    set(data.handles.selectCrop, 'String', ''); 
    %if isempty(curRunQC.settings{trial}.SKIP_LOWAMP); SKIP_LOWAMP = '[ ]'; else; SKIP_LOWAMP =  num2str(curRunQC.settings{trial}.SKIP_LOWAMP); end
    %set(data.handles.skipLowAMPtxtBox, 'String', SKIP_LOWAMP);
else
    msgbox("Please use flvoice to update and pre-process this data data before using the GUI.", 'Warning', 'warn')
    return
end

pertOnset=[];
if isfield(curInputData,'reference_time')&&~isempty(curInputData(trial).reference_time)&&isfield(curInputData,'t')&&~isempty(curInputData(trial).t')
    pertOnset = curInputData(trial).reference_time - curInputData(trial).t; 
elseif isfield(curInputData,'reference_time')&&~isempty(curInputData(trial).reference_time)
    pertOnset = curInputData(trial).reference_time; 
    pertLabel = {'Reference time'};
elseif isfield(curInputData(trial), 'timingTrial')&&numel(curInputData(trial).timingTrial)>=4
    pertOnset = [(curInputData(trial).timingTrial(3)- curInputData(trial).timingTrial(2)), (curInputData(trial).timingTrial(4)- curInputData(trial).timingTrial(2))];
    pertLabel = {'Voice onset','Pert onset'};
    %if isnan(pertOnset(end)), pertOnset(end) = (curInputData(trial).timingTrial(4)- curInputData(trial).timingTrial(1)); end
elseif isfield(curInputData,'pertOnset')&&~isempty(curInputData(trial).pertOnset)
    pertOnset = curInputData(trial).pertOnset;
    pertLabel = {'Pert onset'};
end
reference_time = str2num(get(data.handles.selectReference,'string'));
if isempty(reference_time), reference_time = pertOnset(end); end
OUT_WINDOW=[]; try, if ~isempty(data.vars.curOutputINFO.options.OUT_WINDOW), OUT_WINDOW =  data.vars.curOutputINFO.options.OUT_WINDOW; end; end
if isempty(OUT_WINDOW), OUT_WINDOW=[-0.2 1.0]; end
crop_time= str2num(get(data.handles.selectCrop,'string'));
min_amp= str2num(get(data.handles.selectAmp,'string'));

% update mic plot
cla(data.handles.micAxis);
axes(data.handles.micAxis);
if ~isfield(curInputData,'dataLabel')||numel(curInputData(trial).dataLabel)<=1, set(data.handles.selectSource,'string','mic','value',1);
else set(data.handles.selectSource,'string',regexprep(curInputData(trial).dataLabel,'^[-_\s]',''),'value',min(get(data.handles.selectSource,'value'),numel(curInputData(trial).dataLabel)));
end
selectSource = get(data.handles.selectSource,'value');
micWav = curInputData(trial).s{selectSource};
xlimits=[0, numel(micWav)/curInputData(trial).fs];
set(data.handles.selectZoom,'string',mat2str(xlimits,4));
%micTime = (0+(0:numel(micWav)-1*1/curInputData(trial).fs));
%set(data.handles.micAxis, 'XLim', [0, numel(micTime)]);
micTime = (0+(0:numel(micWav)-1)*1/curInputData(trial).fs);
hold on; data.handles.micPlot = plot(micTime,micWav, 'Parent', data.handles.micAxis, 'color',[0 0 0]); hold off
set(data.handles.micAxis, 'FontUnits', 'normalized', 'FontSize', 0.06, 'XLim', xlimits,'xtick',round(10*xlimits(1))/10:.1:round(10*xlimits(end))/10,'XAxisLocation','top','ylim',1.1*max(abs(micWav))*[-1 1],'yaxislocation','right')
grid(data.handles.micAxis,'on');
data.vars.micWav = micWav;
data.vars.micTime = micTime;
data.vars.xlimits=xlimits;
data.vars.fs=curInputData(trial).fs;

if numel(curInputData(trial).dataLabel)>0, set(data.handles.playMicButton, 'enable', 'on'); end %,'string',['<html>Play<br/>',regexprep(curInputData(trial).dataLabel{selectSource},'^[-_\s]',''),'</html>']); end
htemp=[];
for npertonset=1:numel(pertOnset), 
    hold on; 
    htemp=xline(pertOnset(npertonset),'k-',pertLabel{npertonset},'linewidth',1,'LabelHorizontalAlignment', 'Left','LabelVerticalAlignment','bottom','LabelOrientation','horizontal'); 
    if npertonset>1&&pertOnset(npertonset)>pertOnset(npertonset-1), text(.5*pertOnset(npertonset)+.5*pertOnset(npertonset-1),get(data.handles.micAxis,'ylim')*[.95;.05],sprintf('[ %d ms ]',round(1e3*(pertOnset(npertonset)-pertOnset(npertonset-1)))),'FontSize', 6.5,'horizontalalignment','center'); end
    if npertonset==numel(pertOnset), set(htemp,'LabelHorizontalAlignment','Right'); end
    hold off; 
end

% update spectrum plot
data.handles.spectPlot = updateSpect(data.handles.spectAxis, micWav, curInputData(trial).fs);

% update headphones plot
% if numel(curInputData(trial).s)>1,%strcmp(task, 'aud')
%     cla(data.handles.headAxis);
%     axes(data.handles.headAxis);
%     set(data.handles.headAxis, 'visible', 'on');
%     set(data.handles.playHeadButton, 'enable', 'on');
%     if numel(curInputData(trial).dataLabel)>1, set(data.handles.playHeadButton, 'string',['<html>Play<br/>',regexprep(curInputData(trial).dataLabel{2},'^[-_\s]',''),'</html>']); end
%     headWav = curInputData(trial).s{2};
%     %headTime = (0+(0:numel(headWav)-1*1/curInputData(trial).fs));
%     %set(data.handles.headAxis, 'XLim', [0, numel(headTime)]);
%     headTime = (0+(0:numel(headWav)-1)*1/curInputData(trial).fs);
%     hold on; data.handles.headPlot = plot(headTime,headWav, 'Parent', data.handles.headAxis, 'color',[.6 .6 .6]); hold off
%     set(data.handles.headAxis, 'FontUnits', 'normalized', 'FontSize', 0.06);
%     set(data.handles.headAxis, 'XLim', [0, numel(headWav)/curInputData(trial).fs],'xtick',0:.1:numel(headWav)/curInputData(trial).fs,'xticklabel',[],'XAxisLocation','bottom','yaxislocation','right','box','off');
%     grid(data.handles.headAxis,'on');
%     data.vars.headWav = headWav;
%     data.vars.headTime = headTime;
% else
%     set(data.handles.headAxis, 'visible', 'off');
%     %set(data.handles.playHeadButton, 'enable', 'off');
%     data.vars.headWav = [];
%     data.vars.headTime = [];
% end

% update amp plot
set([data.handles.flagPrev, data.handles.flagNext],'visible','off');
ampidx=find(contains(curOutputData(trial).dataLabel,'raw-Amp'));
VALID=[];
if ~isempty(ampidx)
    skip_lowamp=[]; try, if ~isempty(curOutputINFO.options.SKIP_LOWAMP), skip_lowamp =  curOutputINFO.options.SKIP_LOWAMP; end; end
    skip_lowdur=[]; try, if ~isempty(curOutputINFO.options.SKIP_LOWDUR), skip_lowdur =  curOutputINFO.options.SKIP_LOWDUR; end; end
    %if isempty(skip_lowdur), skip_lowdur=0; end
    cla(data.handles.ampAxis)
    axes(data.handles.ampAxis);
    for nampidx=numel(ampidx):-1:1
        ampWav = curOutputData(trial).s{ampidx(nampidx)};
        ampWav(ampWav<0)=nan;
        ampTime = (0+(0:numel(ampWav)-1)*1/curOutputData(trial).fs);
        temp_skip_lowamp = [];
        if ~isempty(min_amp), temp_skip_lowamp = min_amp(1); end
        if isempty(temp_skip_lowamp), temp_skip_lowamp=skip_lowamp; end
        if isempty(temp_skip_lowamp)||isnan(temp_skip_lowamp), 
            m=[]; for n1=1:100, m=[m, mode(round(ampWav/(max(ampWav)-min(ampWav)+eps)*n1))*(max(ampWav)-min(ampWav)+eps)/n1]; end; temp_skip_lowamp=mean(m);
            %temp_skip_lowamp=mean(ampWav(~isnan(ampWav))); 
        end
        temp_skip_lowdur = [];
        if numel(min_amp)>1, temp_skip_lowdur = min_amp(2); end
        if isempty(temp_skip_lowdur), temp_skip_lowdur=skip_lowdur; end
        if isempty(temp_skip_lowdur)&&isempty(min_amp), temp_skip_lowdur=.5; end
        if isempty(temp_skip_lowdur), temp_skip_lowdur=0; end
        ampPlot=max(ampWav,temp_skip_lowamp);
        [nill,VALID]=findsuprathresholdsegment(ampWav,temp_skip_lowamp,temp_skip_lowdur*curOutputData(trial).fs);
        ampPlot(~VALID)=temp_skip_lowamp;
        hold on; area(ampTime,ampPlot,temp_skip_lowamp,'facecolor','y','edgecolor','none','facealpha',.5); hold off;
        % if ~isempty(skip_lowamp)
        %     ampPlot=max(ampWav,skip_lowamp); 
        %     [nill,in]=findsuprathresholdsegment(ampWav,skip_lowamp,skip_lowdur*curOutputData(trial).fs);
        %     ampPlot(~in)=skip_lowamp;
        %     hold on; area(ampTime,ampPlot,skip_lowamp,'facecolor','y','edgecolor','none','facealpha',.5); hold off; 
        % end
        hold on; ampPlot=plot(ampTime,ampWav,'.-', 'Color', [.6 .6 .6]*((nampidx-1)/max(eps,numel(ampidx)-1))); hold off
    end
    if ~isempty(min_amp)||~isempty(skip_lowamp), hold on; htemp=yline(temp_skip_lowamp,'b-',sprintf('%d dB',round(temp_skip_lowamp)),'linewidth',1,'LabelHorizontalAlignment', 'Right','LabelVerticalAlignment','top','LabelOrientation','horizontal'); hold off; end
    set(data.handles.ampAxis, 'FontUnits', 'normalized', 'FontSize', 0.20);
    set(data.handles.ampAxis,'XLim', xlimits,'xtick',round(10*xlimits(1))/10:.1:round(10*xlimits(end))/10,'xticklabel',[],'XAxisLocation','bottom','yaxislocation','right')
    grid(data.handles.ampAxis,'on');
    hold on; text(-.01*numel(ampWav)/curOutputData(trial).fs, mean(get(data.handles.ampAxis,'ylim')), 'Amp','fontweight','bold','fontsize',14,'Rotation',90,'horizontalalignment','center'); hold off;
    %hold on; htemp=xline(reference_time,'k-','','linewidth',1,'LabelHorizontalAlignment', 'Left','LabelVerticalAlignment','bottom','LabelOrientation','horizontal','LabelHorizontalAlignment','Right'); hold off;
    %hold on; htemp=xline(reference_time+[OUT_WINDOW(1) 0 OUT_WINDOW(2)],'b-','','linewidth',1,'LabelHorizontalAlignment', 'Left','LabelVerticalAlignment','bottom','LabelOrientation','horizontal','LabelHorizontalAlignment','Right'); hold off;
    ylabel 'Amplitude (dB)';
else
    set(data.handles.ampAxis, 'visible', 'off');
end


% update reference plot
cla(data.handles.globalAxis);
axes(data.handles.globalAxis);
hold on; htemp=xline(reference_time,'k-','','linewidth',1,'LabelHorizontalAlignment', 'Left','LabelVerticalAlignment','bottom','LabelOrientation','horizontal','LabelHorizontalAlignment','Right'); hold off;
set(data.handles.globalAxis, 'XLim', xlimits,'xtick',[],'xticklabel',[],'ytick',[],'box','off','visible','off');

% update reference plot
cla(data.handles.referenceAxis);
axes(data.handles.referenceAxis);
if isempty(crop_time), 
    hold on; patch(reference_time+OUT_WINDOW([1 2 2 1]),[0 0 1 1],'w','facecolor',[1 1 0],'edgecolor','k','facealpha',.5,'linewidth',2); hold off;
    hold on; text(reference_time+OUT_WINDOW(1),1.25,sprintf('output data window (from T0%+dms to T0%+dms)',round(OUT_WINDOW(1)*1e3),round(OUT_WINDOW(2)*1e3)),'color',.75*[1 1 1],'fontsize',10,'HorizontalAlignment','left'); hold off;
else 
    hold on; patch(reference_time+OUT_WINDOW([1 2 2 1]),[.5 .5 1 1],'w','facecolor',[1 1 0],'edgecolor','k','facealpha',.5,'linewidth',2); hold off;
    hold on; patch(crop_time([1 2 2 1]),[0 0 .5 .5],'w','facecolor',[1 1 0],'edgecolor','k','facealpha',.5,'linewidth',2); hold off; 
    hold on; text(reference_time+OUT_WINDOW(1),1.25,sprintf('output data window (from T0%+dms to T0%+dms)',round(OUT_WINDOW(1)*1e3),round(OUT_WINDOW(2)*1e3)),'color',.75*[1 1 1],'fontsize',10,'HorizontalAlignment','left'); hold off;
    hold on; text(crop_time(1),-.25,'crop window','color',.75*[1 1 1],'fontsize',10,'HorizontalAlignment','left'); hold off;
end
hold on; htemp=xline(reference_time,'k-','T0 (output data reference time)','linewidth',1,'LabelHorizontalAlignment', 'Left','LabelVerticalAlignment','bottom','LabelOrientation','horizontal','LabelHorizontalAlignment','Right'); hold off;
%hold on; htemp=xline(reference_time+[OUT_WINDOW(1) 0 OUT_WINDOW(2)],'b-','','linewidth',1,'LabelHorizontalAlignment', 'Left','LabelVerticalAlignment','bottom','LabelOrientation','horizontal','LabelHorizontalAlignment','Right'); hold off;
set(data.handles.referenceAxis, 'XLim', xlimits,'xtick',round(10*xlimits(1))/10:.1:round(10*xlimits(end))/10,'xticklabel',[],'ytick',[],'box','off','visible','off');

% update spectogram plots
set([data.handles.ppAxis,data.handles.formantAxis],'visible','off');
cla(data.handles.ppAxis);
try, delete(data.handles.ppAxis.Colorbar); end
cla(data.handles.formantAxis);
try, delete(data.handles.formantAxis.Colorbar); end
s = curInputData(trial).s{1};
fs = curInputData(trial).fs;
%         cla(data.handles.pitchAxis, 'reset');
%         axes(data.handles.pitchAxis);
%         data.handles.fPlot = plot((0:numel(s)-1)/fs,s, 'Parent', data.handles.pitchAxis);
%         set(data.handles.pitchAxis,'xlim',[0 numel(s)/fs],'xtick',.5:.5:numel(s)/fs,'ylim',max(abs(s))*[-1.1 1.1],'ytick',max(abs(s))*linspace(-1.1,1.1,7),'yticklabel',[]);
%         hold on; yyaxis('right'); ylabel('pitch (Hz)'); ylim([0, 600]); yticks(0:100:600); hold off;
%         % only relevant for some backward compat data
%         % .timingTrial = [TIME_TRIAL_START; TIME_TRIAL_ACTUALLYSTART; TIME_VOICE_START; TIME_PERT_START; TIME_PERT_ACTUALLYSTART; TIME_PERT_END; TIME_PERT_ACTUALLYEND; TIME_SCAN_START; TIME_SCAN_ACTUALLYSTART; TIME_SCAN_END];
%hold on; xline(pertOnset,'y:','linewidth',2); grid on; % problem pertOnset

axes(data.handles.ppAxis);
hwindowsize=str2num(get(data.handles.winSizePtxtBox,'string')); % .025
flvoice_spectrogram(s,fs,round(hwindowsize*fs),round((hwindowsize-.001)*fs),1024);
%set(data.handles.ppAxis, 'OuterPosition', [-0.12, 0.32, 1, 0.25]);
xlabel 'Time (s)'
ylabel 'Pitch Frequency (Hz)';
ppMic=[];
hold on; text(numel(s)/fs+zeros(1,7),.1:.1:.7,arrayfun(@(n)sprintf(' %dHz',round(n)),1000*(.1:.1:.7),'uni',0),'horizontalalignment','left','fontsize',9); hold off
hold on; plot([0 numel(s)/fs]'*ones(1,7),ones(2,1)*[.1:.1:.7],'k:','color',.5*[1 1 1]); hold off
if 0,%strcmp(task, 'som') % alfnote: not allowed special conditions based on task names
    f0idx = find(contains(curOutputData(trial).dataLabel,'raw-F0measure1'));
    f0 = curOutputData(trial).s{1,f0idx};%NOTE always s{1,1}?
    fs2 = curOutputData(trial).fs;
    %t = (0.025:0.001:2.524); % how do I derive this from given data?
    t = [0+(0:numel(f0)-1)/fs2]; % correct??
    hold on; ppMic=[ppMic,plot(t,1e-3*f0,'.','LineWidth',1, 'Color', [.6 .6 .6])]; hold off
else
    fs2 = curOutputData(trial).fs;
    f0idx = find(contains(curOutputData(trial).dataLabel,'raw-F0'));
    for nf0idx=numel(f0idx):-1:1
        f0 = curOutputData(trial).s{1,f0idx(nf0idx)};
        t = [0+(0:numel(f0)-1)/fs2]; % correct??
        hold on; ppMic=[ppMic,plot(t,1e-3*f0,'.-','LineWidth',1, 'Color', [.6 .6 .6]*((nf0idx-1)/max(eps,numel(f0idx)-1)))]; hold off
        %if ~isempty(crop_time), t(t>=crop_time(1)&t<=crop_time(2))=NaN; hold on; ppMic=[ppMic,plot(t,1e-3*f0,'.-','LineWidth',1, 'Color', [.5 .5 .5])]; hold off; end
        %if ~isempty(VALID), t(VALID)=NaN; hold on; ppMic=[ppMic,plot(t,1e-3*f0,'.-','LineWidth',1, 'Color', [.5 .5 .5])]; hold off; end
    end
    %uistack(ppMic, 'top'); % making sure mic trace is on top
end
data.handles.ppMic=ppMic;
if get(data.handles.ppAxis_checkbox,'value')==0, set(ppMic,'visible','off'); end;
hold on; text(-.01*numel(s)/fs, .375, 'Pitch','fontweight','bold','fontsize',14,'Rotation',90,'horizontalalignment','center'); hold off;
hold on; htemp=xline(reference_time,'k-','','linewidth',1,'LabelHorizontalAlignment', 'Left','LabelVerticalAlignment','bottom','LabelOrientation','horizontal','LabelHorizontalAlignment','Right'); hold off;
%hold on; htemp=xline(reference_time+[OUT_WINDOW(1) 0 OUT_WINDOW(2)],'b-','','linewidth',1,'LabelHorizontalAlignment', 'Left','LabelVerticalAlignment','bottom','LabelOrientation','horizontal','LabelHorizontalAlignment','Right'); hold off;
set(data.handles.ppAxis, 'yscale','lin','xlim',xlimits,'xtick',round(10*xlimits(1))/10:.1:round(10*xlimits(end))/10, 'ytick',[]);%, 'yaxislocation','right', 'ytick',0:.1:1,'yticklabel',arrayfun(@(n)sprintf('%d',round(n)),1000*(0:.1:1),'uni',0));
set(data.handles.ppAxis, 'ylim', [.01 .75],'ytick',0:.1:1,'yticklabel',arrayfun(@(n)sprintf('%dHz',round(n)),1000*(.1:.1:7),'uni',0));
set(data.handles.ppAxis.Colorbar, 'FontSize', 6.5, 'Position', [0.8550    0.10    0.017    0.2007]);
%set(data.handles.ppAxis,'visible','off','ylim',[0 600]);
hold off;

axes(data.handles.formantAxis);
%set(data.handles.formantAxis, 'OuterPosition', [-0.12, 0.10, 1, 0.25]);
%spectrogram(s,round(.015*fs),round(.014*fs),[],fs,'yaxis');
hwindowsize=.005; %str2num(get(data.handles.winSizeFtxtBox,'string')); % .005
flvoice_spectrogram(s,fs,round(hwindowsize*fs),round((hwindowsize-.001)*fs),1024);
xlabel ''
ylabel 'Formant Frequency (Hz)';
fmtMic=[];
hold on; text(numel(s)/fs+zeros(1,7),.5:.5:3.5,arrayfun(@(n)sprintf(' %dHz',round(n)),1000*(.5:.5:3.5),'uni',0),'horizontalalignment','left','fontsize',9); hold off
hold on; plot([0 numel(s)/fs]'*ones(1,7),ones(2,1)*[.5:.5:3.5],'k:','color',.5*[1 1 1]); hold off
if 0,%strcmp(task, 'som') % alfnote: not allowed special conditions based on task names
    f1micIdx = find(contains(curOutputData(trial).dataLabel,'raw-F1measure1'));
    f2micIdx = find(contains(curOutputData(trial).dataLabel,'raw-F2measure1'));
    fmt = [curOutputData(trial).s{1,f1micIdx},curOutputData(trial).s{1,f2micIdx}];
    hold on; fmtMic = [fmtMic,plot(t,fmt'/1e3,'.-', 'Color', [.6 .6 .6])]; hold off;
else
    f1idx = find(contains(curOutputData(trial).dataLabel,'raw-F2'));
    for nf1idx=numel(f1idx):-1:1
        f1 = curOutputData(trial).s{1,f1idx(nf1idx)};
        t = [0+(0:numel(f0)-1)/fs2]; % correct??
        hold on; fmtMic=[fmtMic, plot(t,1e-3*f1,'.-','LineWidth',1, 'Color', [.6 .6 .6]*((nf1idx-1)/max(eps,numel(f1idx)-1)))]; hold off
        %if ~isempty(crop_time), t(t>=crop_time(1)&t<=crop_time(2))=NaN; hold on; fmtMic=[fmtMic,plot(t,1e-3*f1,'.','LineWidth',1, 'Color', [.5 .5 .5])]; hold off; end
        %if ~isempty(VALID), t(VALID)=NaN; hold on; fmtMic=[fmtMic,plot(t,1e-3*f1,'.','LineWidth',1, 'Color', [.5 .5 .5])]; hold off; end
    end
    f1idx = find(contains(curOutputData(trial).dataLabel,'raw-F1'));
    for nf1idx=numel(f1idx):-1:1
        f1 = curOutputData(trial).s{1,f1idx(nf1idx)};
        t = [0+(0:numel(f0)-1)/fs2]; % correct??
        hold on; fmtMic=[fmtMic, plot(t,1e-3*f1,'.-','LineWidth',1, 'Color', [.6 .6 .6]*((nf1idx-1)/max(eps,numel(f1idx)-1)))]; hold off
        %if ~isempty(crop_time), t(t>=crop_time(1)&t<=crop_time(2))=NaN; hold on; fmtMic=[fmtMic,plot(t,1e-3*f1,'.','LineWidth',1, 'Color', [.5 .5 .5])]; hold off; end
        %if ~isempty(VALID), t(VALID)=NaN; hold on; fmtMic=[fmtMic,plot(t,1e-3*f1,'.','LineWidth',1, 'Color', [.5 .5 .5])]; hold off; end
    end
    %             f1micIdx = find(contains(curOutputData(trial).dataLabel,'raw-F1-mic'));
    %             f2micIdx = find(contains(curOutputData(trial).dataLabel,'raw-F2-mic'));
    %             fmt = [curOutputData(trial).s{1,f1micIdx},curOutputData(trial).s{1,f2micIdx}];
    %             hold on; fmtMic = plot(t,fmt'/1e3,'.-', 'Color', [.6 .6 .6]); hold off;
    %             hold on;
    %             f1headIdx = find(contains(curOutputData(trial).dataLabel,'raw-F1-headphones'));
    %             f2headIdx = find(contains(curOutputData(trial).dataLabel,'raw-F2-headphones'));
    %             fmtHead = [curOutputData(trial).s{1,f1headIdx},curOutputData(trial).s{1,f2headIdx}];
    %             hold on; fmtHead = plot(t,fmtHead'/1e3,'.-', 'Color', [0 0 0]); hold off;
    %             uistack(fmtMic, 'top'); % making sure mic trace is on top
end
data.handles.fmtMic=fmtMic;
if get(data.handles.formantAxis_checkbox,'value')==0, set(fmtMic,'visible','off'); end;
%hold on; plot(headTime,headWav); hold off;
hold on; text(-.01*numel(s)/fs, 2, 'Formants','fontweight','bold','fontsize',14,'Rotation',90,'horizontalalignment','center'); hold off;
hold on; htemp=xline(reference_time,'k-','','linewidth',1,'LabelHorizontalAlignment', 'Left','LabelVerticalAlignment','bottom','LabelOrientation','horizontal','LabelHorizontalAlignment','Right'); hold off;
%hold on; htemp=xline(reference_time+[OUT_WINDOW(1) 0 OUT_WINDOW(2)],'b-','','linewidth',1,'LabelHorizontalAlignment', 'Left','LabelVerticalAlignment','bottom','LabelOrientation','horizontal','LabelHorizontalAlignment','Right'); hold off;
set(data.handles.formantAxis, 'yscale','lin', 'xlim',xlimits,'xtick',round(10*xlimits(1))/10:.1:round(10*xlimits(end))/10,'xticklabel',[], 'ylim', [.01 4], 'ytick', []); %'yaxislocation','right', 'ytick',0:.25:4,'yticklabel',arrayfun(@(n)sprintf('%d',round(n)),1000*(0:.25:4),'uni',0));
set(data.handles.formantAxis.Colorbar, 'FontSize', 6.5, 'Position', [0.8550    0.32    0.017    0.2007]);
%set([data.handles.ppAxis,data.handles.formantAxis],'visible','on');

%if isempty(ReferenceTime), set(data.handles.selectReference,'string','');
%else set(data.handles.selectReference,'string',num2str(reference_time));
%end
%if isempty(crop_time), set(data.handles.selectCrop,'string','');
%else set(data.handles.selectCrop,'string',mat2str(crop_time));
%end

% update button enable status
for nflags=1:numFlags,
    if any(curRunQC.badTrial(nflags,trial+1:end),2), set(data.handles.flagNext(nflags),'visible','on','enable','on'); else set(data.handles.flagNext(nflags),'visible','off'); end
    if any(curRunQC.badTrial(nflags,1:trial-1),2), set(data.handles.flagPrev(nflags),'visible','on','enable','on'); else set(data.handles.flagPrev(nflags),'visible','off'); end
end
if nnz(curRunQC.badTrial(numFlags+1:end,trial+1:end)), set(data.handles.flagNext(numFlags+1),'visible','on','enable','on'); else set(data.handles.flagNext(numFlags+1),'visible','off'); end
if nnz(curRunQC.badTrial(numFlags+1:end,1:trial-1)), set(data.handles.flagPrev(numFlags+1),'visible','on','enable','on'); else set(data.handles.flagPrev(numFlags+1),'visible','off'); end
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton, data.handles.prevCondButton, data.handles.nextCondButton], 'Enable', 'on');

%end
% save curr data
data.vars.curInputData = curInputData;
data.vars.curOutputData = curOutputData;
data.vars.curOutputINFO = curOutputINFO;
set(data.handles.hfig,'userdata',data);
set(data.handles.hfig,'pointer','arrow');
% re-enable buttons when done
set([data.handles.prevButton, data.handles.nextButton, data.handles.prevFlagButton, data.handles.nextFlagButton, data.handles.prevCondButton, data.handles.nextCondButton], 'Enable', 'on');
drawnow;
end

function [ok,in]=findsuprathresholdsegment(x,thr,N)
in=x>thr;
idx=reshape(find(diff([false, reshape(in,1,[]), false])),2,[]);
ok=any(idx(2,:)-idx(1,:)>=N);
for k=find(idx(2,:)-idx(1,:)<N), in(idx(1,k):idx(2,k)-1)=0; end
end

function h=updateSpect(spectAxis, micWav, fs, spectPlot)
FmicWav=log10(abs(fft(micWav.*reshape(.5*(1 - cos(2*pi*(1:numel(micWav))/(numel(micWav)+1))),size(micWav)))));
if nargin<4
    cla(spectAxis);
    axes(spectAxis);
    hold on; h=plot((0:floor(numel(micWav)/2)-1)/numel(micWav)*fs,FmicWav(1:floor(numel(micWav)/2)), 'k-', 'Parent', spectAxis, 'color',.0*[1 1 1]); hold off
    set(spectAxis,'xlim',[0 8000],'xtick',2000:2000:8000,'xticklabel',{'2KHz','4KHz','6KHz','8KHz'},'ytick',[],'ylim',[min(FmicWav) max(FmicWav)]*[1.1 -.1; -.1 1.1],'FontUnits', 'normalized', 'FontSize', 0.10);
    grid(spectAxis,'on');
else
    h=[];
    set(spectPlot,'xdata',(0:floor(numel(micWav)/2)-1)/numel(micWav)*fs,'ydata',FmicWav(1:floor(numel(micWav)/2)));
    set(spectAxis,'ylim',[min(FmicWav(1:floor(numel(micWav)/2))) max(FmicWav(1:floor(numel(micWav)/2)))]*[1.1 -.1; -.1 1.1]);
end
end