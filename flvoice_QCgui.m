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
        if nargin <2; disp('Please inputa subject'); 
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
        data.handles.hfig=figure('Units','norm','Position',[.25 .2 .6 .6],'Menubar','none','Name','FLvoice QC GUI','numbertitle','off','color','w');
        % reminder; position is [(bottom left corner normalized x pos) (bottom left corner normalized y pos) (width) (heigth)]
        
        %set defaults:
        %%% root set here for testing, generally root would be defined beforehand: %%%
        %flvoice('ROOT','C:\Users\RickyFals\Documents\0BU\0GuentherLab\LabGit\SAPdata');
             
        % Example for automatically adjusting field numbers for Formant section 
        %pos = {}; 
        %numFields = 4
        %for i = 1:numFields
        %    y1 = .94 - (i*.07); % for text
        %    y2 = y1 + 0.01; % for textbox
        %    pos(i,1) = {[.02 y1 .4 .07]}; 
        %    pos(i,2) = {[.5 y2 .45 .065]}; 
        %end
        
        % SETTINGS PANEL
        data.handles.settPanel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.02 .45 .2 .52],'Parent',data.handles.hfig);
        % Formant Settings
        data.handles.FSettText=uicontrol('Style', 'text','String','Formant Settings:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.58,'HorizontalAlignment', 'left','Position',[.2 .935 .8 .08],'Parent',data.handles.settPanel);
        % Formants (FMT_ARGS)
        % 'lporder', 'windowsize', 'viterbfilter', 'medianfilter'
        % 'NLPCtxtBox', 'winSizeFtxtBox', 'vfiltertxtBox', 'mfilterFtxtBox'
        data.handles.NLPCtxt=uicontrol('Style','text','String','Num LPC:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .87 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.NLPCtxtBox=uicontrol('Style','edit','String','[ ]','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .88 .45 .065],'Parent',data.handles.settPanel);    
        data.handles.winSizeFtxt=uicontrol('Style','text','String','Window Size:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .8 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.winSizeFtxtBox=uicontrol('Style','edit','String','0.05','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .81 .45 .065],'Parent',data.handles.settPanel);
        data.handles.vfiltertxt=uicontrol('Style','text','String','Viterb Filter:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .73 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.vfiltertxtBox=uicontrol('Style','edit','String','1','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .74 .45 .065],'Parent',data.handles.settPanel);
        data.handles.mfilterFtxt=uicontrol('Style','text','String','Median Filter:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .66 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.mfilterFtxtBox=uicontrol('Style','edit','String','0.25','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .67 .45 .065],'Parent',data.handles.settPanel);
        % Pitch Settings
        data.handles.PSettText=uicontrol('Style', 'text','String','Pitch Settings:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.58,'HorizontalAlignment', 'left','Position',[.2 .595 .8 .08],'Parent',data.handles.settPanel);
        % Pitch (F0_ARGS)
        % 'windowsize', 'methods', 'range', 'hr_min', 'medianfilter', 'outlierfilter'
        % 'winSizePtxtBox', 'methodstxtBox', 'rangetxtBox', 'hr_mintxtBox', 'mfilterPtxtBox', 'ofilterPtxtBox'
        data.handles.winSizePtxt=uicontrol('Style','text','String','Window Size:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .53 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.winSizePtxtBox=uicontrol('Style','edit','String','0.05','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .54 .45 .065],'Parent',data.handles.settPanel);    
        data.handles.methodstxt=uicontrol('Style','text','String','Methods:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .46 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.methodstxtBox=uicontrol('Style','edit','String','CEP','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .47 .45 .065],'Parent',data.handles.settPanel);
        data.handles.rangetxt=uicontrol('Style','text','String','Range:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .39 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.rangetxtBox=uicontrol('Style','edit','String','[ ]','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .4 .45 .065],'Parent',data.handles.settPanel);
        data.handles.hr_mintxt=uicontrol('Style','text','String','HR Min:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .32 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.hr_mintxtBox=uicontrol('Style','edit','String','0.5','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .33 .45 .065],'Parent',data.handles.settPanel);
        data.handles.mfilterPtxt=uicontrol('Style','text','String','Median Filter:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .25 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.mfilterPtxtBox=uicontrol('Style','edit','String','1','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .26 .45 .065],'Parent',data.handles.settPanel);
        data.handles.ofilterPtxt=uicontrol('Style','text','String','Outlier Filter:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .18 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.ofilterPtxtBox=uicontrol('Style','edit','String','0','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .19 .45 .065],'Parent',data.handles.settPanel);
        % General
        % 'SKIP_LOWAMP' 
        % 'skipLowAPtxtBox'
        data.handles.skipLowAtxt=uicontrol('Style','text','String','Skip Lowamp:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .10 .4 .07],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.settPanel);
        data.handles.skipLowAPtxtBox=uicontrol('Style', 'edit','String','[ ]','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .11 .45 .065],'Parent',data.handles.settPanel);
        
        % Update Button
        data.handles.upSettButton=uicontrol('Style','pushbutton','String','Update Settings','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.1 .01 .8 .08],'Parent',data.handles.settPanel,'Callback', @updateSettings);
                   
        % QC FLAG PANEL
        data.handles.flagPanel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.02 .02 .2 .42],'Parent',data.handles.hfig);
        data.handles.flagText=uicontrol('Style', 'text','String','QC Flags:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.63,'HorizontalAlignment', 'center','Position',[.2 .915 .6 .08],'Parent',data.handles.flagPanel);
        data.handles.flag1txt=uicontrol('Style', 'checkbox','String','Performed incorrectly','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .83 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'Callback', @checkFlag1);
        data.handles.flag2txt=uicontrol('Style', 'checkbox','String','Bad F0 trace','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .73 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'Callback', @checkFlag2);
        data.handles.flag3txt=uicontrol('Style', 'checkbox','String','Bad F1 trace','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .63 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'Callback', @checkFlag3);
        data.handles.flag4txt=uicontrol('Style', 'checkbox','String','Incorrect voice onset ','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .53 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel,'Callback', @checkFlag4);
        data.handles.flag5txt=uicontrol('Style', 'checkbox','String','Utterance too short','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .43 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel, 'Callback', @checkFlag5);
        data.handles.flag6txt=uicontrol('Style', 'checkbox','String','Distortion / audio issues','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .33 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel, 'Callback', @checkFlag6);
        data.handles.flag7txt=uicontrol('Style', 'checkbox','String','Other:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .23 .9 .1],'BackgroundColor', [.94 .94 .94], 'Parent',data.handles.flagPanel, 'Callback', @checkFlag7);
        data.handles.flag7edit=uicontrol('Style', 'edit','String','Comment','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'center','Position',[.2 .135 .692 .09],'BackgroundColor', [.94 .94 .94], 'Enable', 'off', 'Parent',data.handles.flagPanel,'Callback', @editFlag7);
        % Save Flag Button 
        data.handles.saveFlagButton=uicontrol('Style', 'pushbutton','String','Save flags','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.1 .01 .8 .1],'Parent',data.handles.flagPanel,'Callback', @saveFlags);
        
        % SUBJECT PANEL 
        data.handles.subPanel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.24 .89 .742 .08],'Parent',data.handles.hfig);
        % Sub
        data.handles.subText=uicontrol('Style', 'text','String','Subject:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.01 .45 .08 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
        data.handles.subDrop=uicontrol('Style', 'popupmenu','String','Sub01','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.0 .0 .155 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel, 'Callback', @subDrop);
        % Sess
        data.handles.sessionText=uicontrol('Style', 'text','String','Sess:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.175 .45 .06 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
        data.handles.sessionDrop=uicontrol('Style', 'popupmenu','String','1','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.165 .0 .115 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel, 'Callback', @sessDrop);
        % Run
        data.handles.runText=uicontrol('Style', 'text','String','Run:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.3 .45 .045 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
        data.handles.runDrop=uicontrol('Style', 'popupmenu','String','1','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.29 .0 .115 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel, 'Callback', @runDrop);
        % Task
        data.handles.taskText=uicontrol('Style', 'text','String','Task:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.425 .45 .06 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
        data.handles.taskDrop=uicontrol('Style', 'popupmenu','String','aud','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.415 .0 .11 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel, 'Callback', @taskDrop);
        % Trial
        data.handles.trialText=uicontrol('Style', 'text','String','Trial:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.545 .45 .05 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
        data.handles.trialDrop=uicontrol('Style', 'popupmenu','String','1','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.535 .0 .1 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel, 'Callback', @trialDrop);
        % Cond
        data.handles.condText=uicontrol('Style', 'text','String','Cond:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'center','Position',[.655 .45 .055 .6],'BackgroundColor', [.94 .94 .94],'Parent',data.handles.subPanel);
        data.handles.condVal=uicontrol('Style', 'text','String','N0','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.66 .1 .05 .5],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
        %data.handles.conditionDrop=uicontrol('Style', 'popupmenu','String','N0','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.74 .16 .05 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
        % Prev / Next Buttons
        data.handles.prevButton=uicontrol('Style', 'pushbutton','String','<Prev','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.75 .09 .12 .85],'Parent',data.handles.subPanel,'Callback', @prevTrial);
        data.handles.nextButton=uicontrol('Style', 'pushbutton','String','Next>','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.87 .09 .12 .85],'Parent',data.handles.subPanel,'Callback', @nextTrial);
        
        % Axes (Mic / Head / Spectograms) Panel
        data.handles.axes1Panel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.24 .02 .742 .86],'Parent',data.handles.hfig);        
        data.handles.micAxis = axes('FontUnits', 'normalized', 'Units', 'normalized', 'OuterPosition', [-0.12, 0.76, 1.14, 0.25], 'Visible', 'on', 'Tag', 'mic_axis','Parent',data.handles.axes1Panel);
        data.handles.headAxis = axes('FontUnits', 'normalized', 'Units', 'normalized', 'OuterPosition', [-0.12, 0.54, 1.14, 0.25], 'Visible', 'on', 'Tag', 'head_axis','Parent',data.handles.axes1Panel);
        data.handles.pitchAxis = axes('FontUnits', 'normalized', 'Units', 'normalized', 'OuterPosition', [-0.12, 0.32, 1.14, 0.25], 'Visible', 'on', 'Tag', 'pitch_axis','Parent',data.handles.axes1Panel);
        data.handles.ppAxis = axes('FontUnits', 'normalized', 'Units', 'normalized', 'OuterPosition', [-0.12, 0.32, 1.14, 0.25], 'Visible', 'on', 'Tag', 'pp_axis','Parent',data.handles.axes1Panel);
        data.handles.formantAxis = axes('FontUnits', 'normalized', 'Units', 'normalized', 'OuterPosition', [-0.12, 0.10, 1.14, 0.25], 'Visible', 'on', 'Tag', 'formant_axis','Parent',data.handles.axes1Panel);
        % Axes Buttons
        data.handles.playMicButton=uicontrol('Style', 'pushbutton','String','<html>Play<br/>Mic</html>','Units','norm','FontUnits','norm','FontSize',0.33,'HorizontalAlignment', 'left','Position',[.92 .86 .075 .08],'Parent',data.handles.axes1Panel,'Callback', @playMic);
        data.handles.playHeadButton=uicontrol('Style', 'pushbutton','String','<html>Play<br/>Head</html>','Units','norm','FontUnits','norm','FontSize',0.33,'HorizontalAlignment', 'left','Position',[.92 .64 .075 .08],'Parent',data.handles.axes1Panel,'Callback', @playHead);
        %optional buttons
        %data.handles.trialTimeButton=uicontrol('Style', 'pushbutton','String','View trial timing','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.02 .02 .3 .06], 'Enable', 'off', 'Parent',data.handles.axes1Panel, 'Callback', @viewTime);
        %data.handles.refTimeButton=uicontrol('Style', 'pushbutton','String','Change reference time','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.4 .02 .3 .06], 'Enable', 'off','Parent',data.handles.axes1Panel,'Callback', @changeReference);
        data.handles.saveExitButton=uicontrol('Style', 'pushbutton','String','<html>Save &<br/>Exit</html>','Units','norm','FontUnits','norm','FontSize',0.33,'HorizontalAlignment', 'left','Position',[.92 .005 .075 .08],'Parent',data.handles.axes1Panel,'Callback', @saveExit);
        
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
        data = get(data.handles.hfig, 'userdata');
        set(data.handles.hfig,'userdata',data);
    end
        


    function updateSettings(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    set(data.handles.hfig,'pointer','watch');
    drawnow;
    % disable buttons while loading 
    set(data.handles.prevButton, 'Enable', 'off');
    set(data.handles.nextButton, 'Enable', 'off');
    
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
    % General
    % 'SKIP_LOWAMP' 
    % 'skipLowAPtxtBox'
    SKIP_LOWAMP = str2num(get(data.handles.skipLowAPtxtBox, 'String'));
        
    curSub = data.vars.curSub; curSess = data.vars.curSess; curRun = data.vars.curRun; curTask = data.vars.curTask; curTrial = data.vars.curTrial;
    
    choice = questdlg('Re-process this subjects entire run, or just this trial?', 'Update Settings', 'Current run', 'Just Trial', 'Cancel', 'Cancel');
        switch choice
            case 'Current run'
                data.vars.curRunQC.settings{data.vars.curTrial}.lporder = lporder;
                data.vars.curRunQC.settings{data.vars.curTrial}.windowsizeF = windowsizeF;
                data.vars.curRunQC.settings{data.vars.curTrial}.viterbfilter = viterbfilter;
                data.vars.curRunQC.settings{data.vars.curTrial}.medianfilterF = medianfilterF;
                data.vars.curRunQC.settings{data.vars.curTrial}.windowsizeP = windowsizeP;
                data.vars.curRunQC.settings{data.vars.curTrial}.methods = methods;
                data.vars.curRunQC.settings{data.vars.curTrial}.range = range;
                data.vars.curRunQC.settings{data.vars.curTrial}.hr_min = hr_min;
                data.vars.curRunQC.settings{data.vars.curTrial}.medianfilterP = medianfilterP;
                data.vars.curRunQC.settings{data.vars.curTrial}.outlierfilter = outlierfilter;
                data.vars.curRunQC.settings{data.vars.curTrial}.SKIP_LOWAMP = SKIP_LOWAMP;
                data.vars.curRunQC.settings(1:end) = data.vars.curRunQC.settings(data.vars.curTrial);
                flvoice_import(curSub,curSess,curRun,curTask, ...
                    ['FMT_ARGS',{'lporder',lporder, 'windowsize',windowsizeF, 'viterbfilter',viterbfilter, 'medianfilter', medianfilterF}, ...
                     'F0_ARGS', {'windowsize',windowsizeP, 'methods,range',methods, 'range',range, 'hr_min',hr_min, 'medianfilter',medianfilterP, 'outlierfilter',outlierfilter}, ...
                     'SKIP_LOWAMP', SKIP_LOWAMP]);
                
            case 'Just Trial'
                data.vars.curRunQC.settings{data.vars.curTrial}.lporder = lporder;
                data.vars.curRunQC.settings{data.vars.curTrial}.windowsizeF = windowsizeF;
                data.vars.curRunQC.settings{data.vars.curTrial}.viterbfilter = viterbfilter;
                data.vars.curRunQC.settings{data.vars.curTrial}.medianfilterF = medianfilterF;
                data.vars.curRunQC.settings{data.vars.curTrial}.windowsizeP = windowsizeP;
                data.vars.curRunQC.settings{data.vars.curTrial}.methods = methods;
                data.vars.curRunQC.settings{data.vars.curTrial}.range = range;
                data.vars.curRunQC.settings{data.vars.curTrial}.hr_min = hr_min;
                data.vars.curRunQC.settings{data.vars.curTrial}.medianfilterP = medianfilterP;
                data.vars.curRunQC.settings{data.vars.curTrial}.outlierfilter = outlierfilter;
                data.vars.curRunQC.settings{data.vars.curTrial}.SKIP_LOWAMP = SKIP_LOWAMP;
                flvoice_import(curSub,curSess,curRun,curTask, 'SINGLETRIAL', curTrial, ...
                     ['FMT_ARGS',{'lporder',lporder, 'windowsize',windowsizeF, 'viterbfilter',viterbfilter, 'medianfilter', medianfilterF}, ...
                     'F0_ARGS', {'windowsize',windowsizeP, 'methods,range',methods, 'range',range, 'hr_min',hr_min, 'medianfilter',medianfilterP, 'outlierfilter',outlierfilter}, ...
                     'SKIP_LOWAMP', SKIP_LOWAMP]);
            
            case 'Cancel'
                set(data.handles.hfig,'pointer','arrow');
                drawnow;
                return
        end
        
    flvoice_import(curSub,curSess,curRun,curTask, 'set_qc', data.vars.curRunQC)
    set(data.handles.hfig,'pointer','arrow');
    drawnow;
    % re-enable buttons when done 
    set(data.handles.prevButton, 'Enable', 'on');
    set(data.handles.nextButton, 'Enable', 'on');
    updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, data.vars.curTrial);
    data = get(data.handles.hfig, 'userdata');
    set(data.handles.hfig,'userdata',data);
    end

    function checkFlag1(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    flagVal = get(data.handles.flag1txt, 'Value');
    curTrial = data.vars.curTrial; 
    %curRunQCflags = data.vars.curRunQCflags;
    %curRunQCflags{curTrial,1} = flagVal;
    %data.vars.curRunQCflags = curRunQCflags;
    curRunQC = data.vars.curRunQC;
    if flagVal
        curRunQC.keepData(curTrial) = 0;
        curRunQC.badTrial(1,curTrial) = 1;
        if isempty(curRunQC.dictionary{1,curTrial})
            curRunQC.dictionary{1,curTrial} = {'Performed incorrectly'};
        else
            curRunQC.dictionary{1,curTrial} = {curRunQC.dictionary{1,curTrial}, 'Performed incorrectly'};
        end
    else   
        curRunQC.keepData(curTrial) = 1;
        curRunQC.badTrial(1,curTrial) = 0;
        QCdict = curRunQC.dictionary{1,curTrial};
        QCdict(ismember(QCdict,'Performed incorrectly')) = [];
        curRunQC.dictionary{1,curTrial} = QCdict;
    end
    data.vars.curRunQC = curRunQC;
    set(data.handles.hfig,'userdata',data);
    end

    function checkFlag2(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    flagVal = get(data.handles.flag2txt, 'Value');
    curTrial = data.vars.curTrial; 
    %curRunQCflags = data.vars.curRunQCflags;
    %curRunQCflags{curTrial,2} = flagVal;
    %data.vars.curRunQCflags = curRunQCflags;
    curRunQC = data.vars.curRunQC;
    if flagVal
        curRunQC.keepData(curTrial) = 0;
        curRunQC.badTrial(2,curTrial) = 1;
        if isempty(curRunQC.dictionary{1,curTrial})
            curRunQC.dictionary{1,curTrial} = {'Bad F0 trace'};
        else
            curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial}, 'Bad F0 trace'];
        end
    else
        curRunQC.keepData(curTrial) = 1;
        curRunQC.badTrial(2,curTrial) = 0;
        QCdict = curRunQC.dictionary{1,curTrial};
        QCdict(ismember(QCdict,'Bad F0 trace')) = [];
        curRunQC.dictionary{1,curTrial} = QCdict;
    end
    data.vars.curRunQC = curRunQC;
    set(data.handles.hfig,'userdata',data);
    end

    function checkFlag3(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    flagVal = get(data.handles.flag3txt, 'Value');
    curTrial = data.vars.curTrial; 
    %curRunQCflags = data.vars.curRunQCflags;
    %curRunQCflags{curTrial,3} = flagVal;
    %data.vars.curRunQCflags = curRunQCflags;
    curRunQC = data.vars.curRunQC;
    if flagVal
        curRunQC.keepData(curTrial) = 0;
        curRunQC.badTrial(3,curTrial) = 1;
        if isempty(curRunQC.dictionary{1,curTrial})
            curRunQC.dictionary{1,curTrial} = {'Bad F1 trace'};
        else
            curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial}, 'Bad F1 trace'];
        end
    else
        curRunQC.keepData(curTrial) = 1;
        curRunQC.badTrial(3,curTrial) = 0;
        QCdict = curRunQC.dictionary{1,curTrial};
        QCdict(ismember(QCdict,'Bad F1 trace')) = [];
        curRunQC.dictionary{1,curTrial} = QCdict;
    end
    data.vars.curRunQC = curRunQC;
    set(data.handles.hfig,'userdata',data);
    end

    function checkFlag4(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    flagVal = get(data.handles.flag4txt, 'Value');
    curTrial = data.vars.curTrial; 
    %curRunQCflags = data.vars.curRunQCflags;
    %curRunQCflags{curTrial,4} = flagVal;
    %data.vars.curRunQCflags = curRunQCflags;
    curRunQC = data.vars.curRunQC;
    if flagVal
        curRunQC.keepData(curTrial) = 0;
        curRunQC.badTrial(4,curTrial) = 1;
        if isempty(curRunQC.dictionary{1,curTrial})
            curRunQC.dictionary{1,curTrial} = {'Incorrect voice onset'};
        else
            curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial}, 'Incorrect voice onset'];
        end
    else
        curRunQC.keepData(curTrial) = 1;
        curRunQC.badTrial(4,curTrial) = 0;
        QCdict = curRunQC.dictionary{1,curTrial};
        QCdict(ismember(QCdict,'Incorrect voice onset')) = [];
        curRunQC.dictionary{1,curTrial} = QCdict;
    end
    data.vars.curRunQC = curRunQC;
    set(data.handles.hfig,'userdata',data);
    end

    function checkFlag5(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    flagVal = get(data.handles.flag5txt, 'Value');
    curTrial = data.vars.curTrial; 
    %curRunQCflags = data.vars.curRunQCflags;
    %curRunQCflags{curTrial,5} = flagVal;
    %data.vars.curRunQCflags = curRunQCflags;
    curRunQC = data.vars.curRunQC;
    if flagVal
        curRunQC.keepData(curTrial) = 0;
        curRunQC.badTrial(5,curTrial) = 1;
        if isempty(curRunQC.dictionary{1,curTrial})
            curRunQC.dictionary{1,curTrial} = {'Utterance too short'};
        else
            curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial}, 'Utterance too short'];
        end
    else
        curRunQC.keepData(curTrial) = 1;
        curRunQC.badTrial(5,curTrial) = 0;
        QCdict = curRunQC.dictionary{1,curTrial};
        QCdict(ismember(QCdict,'Utterance too short')) = [];
        curRunQC.dictionary{1,curTrial} = QCdict;
    end
    data.vars.curRunQC = curRunQC;
    set(data.handles.hfig,'userdata',data);
    end

    function checkFlag6(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    flagVal = get(data.handles.flag6txt, 'Value');
    curTrial = data.vars.curTrial; 
    %curRunQCflags = data.vars.curRunQCflags;
    %curRunQCflags{curTrial,6} = flagVal;
    %data.vars.curRunQCflags = curRunQCflags;
    curRunQC = data.vars.curRunQC;
    if flagVal
        curRunQC.keepData(curTrial) = 0;
        curRunQC.badTrial(6,curTrial) = 1;
        if isempty(curRunQC.dictionary{1,curTrial})
            curRunQC.dictionary{1,curTrial} = {'Distortion / audio issues'};
        else
            curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial}, 'Distortion / audio issues'];
        end
    else
        curRunQC.keepData(curTrial) = 1;
        curRunQC.badTrial(6,curTrial) = 0;
        QCdict = curRunQC.dictionary{1,curTrial};
        QCdict(ismember(QCdict,'Distortion / audio issues')) = [];
        curRunQC.dictionary{1,curTrial} = QCdict;
    end
    data.vars.curRunQC = curRunQC;
    set(data.handles.hfig,'userdata',data);
    end

    function checkFlag7(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    flagVal = get(data.handles.flag7txt, 'Value');
    %QCcomment = get(data.handles.flag7edit, 'String');
    curTrial = data.vars.curTrial; 
    %curRunQCflags = data.vars.curRunQCflags;
    curRunQC = data.vars.curRunQC;
    if flagVal
        set(data.handles.flag7edit, 'Enable', 'on');
        curRunQC.keepData(curTrial) = 0;
        curRunQC.badTrial(7,curTrial) = 1;
        %curRunQC.badTrial(curTrial) = get(data.handles.flag7edit, 'String');
    else
        QCcomment = get(data.handles.flag7edit, 'String');
        QCdict = curRunQC.dictionary{1,curTrial};
        QCdict(ismember(QCdict,QCcomment)) = [];
        curRunQC.dictionary{1,curTrial} = QCdict;
        curRunQC.keepData(curTrial) = 1;
        curRunQC.badTrial(7,curTrial) = 0;
        set(data.handles.flag7edit, 'String', 'Comment', 'Enable', 'off');
        %curRunQCflags{curTrial,7} = 0;
    end
    %data.vars.curRunQCflags = curRunQCflags;
    data.vars.curRunQC = curRunQC;
    set(data.handles.hfig,'userdata',data);
    end

    function editFlag7(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    QCcomment = get(data.handles.flag7edit, 'String');
    curTrial = data.vars.curTrial; 
    %curRunQCflags = data.vars.curRunQCflags;
    %curRunQCflags{curTrial,7} = QCcomment;
    %data.vars.curRunQCflags = curRunQCflags;
    curRunQC = data.vars.curRunQC;
    %curDict =  curRunQC.dictionary{curTrial};
    
    if isempty(curRunQC.dictionary{1,curTrial})
        curRunQC.dictionary{1,curTrial} = {QCcomment};
    else
        curRunQC.dictionary{1,curTrial} = [curRunQC.dictionary{1,curTrial},  QCcomment];
    end
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
    set(data.handles.prevButton, 'Enable', 'off');
    set(data.handles.nextButton, 'Enable', 'off');
    
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
    
    subList = data.vars.subList;
    newSubIdx = get(data.handles.subDrop, 'Value');
    newSub = subList{newSubIdx};
    
    sessList = flvoice('import', newSub);
    % check for empty sessions
    for i = 1:numel(sessList)
        if ~isempty(flvoice('import', newSub, sessList{i}))
            continue
        else
            sessList{i} = [];
        end
    end
    emptyIdx = cellfun(@isempty,sessList);
    sessList(emptyIdx) = [];
    curSess = sessList{1};
    data.vars.curSess = curSess;
    
    runList = flvoice('import',newSub, curSess);
    curRun = runList{1};
    data.vars.curRun = curRun;
        
    taskList = flvoice('import',newSub, curSess, curRun);
    set(data.handles.taskDrop, 'String', taskList, 'Value', 1);
    curTask = taskList{get(data.handles.taskDrop, 'Value')};
    
    updateSubj(data, newSub, data.vars.curSess, data.vars.curRun, curTask, 1);
    data = get(data.handles.hfig, 'userdata');
    data.vars.curSub = newSub;
    
    set(data.handles.hfig,'pointer','arrow');
    drawnow;
    % re-enable buttons when done 
    set(data.handles.prevButton, 'Enable', 'on');
    set(data.handles.nextButton, 'Enable', 'on');
    set(data.handles.hfig,'userdata',data);
    end

    function sessDrop(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    set(data.handles.hfig,'pointer','watch');
    drawnow;
    % disable buttons when loading 
    set(data.handles.prevButton, 'Enable', 'off');
    set(data.handles.nextButton, 'Enable', 'off');
    
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
    
    sessList = data.vars.sessList;
    newSessIdx = get(data.handles.sessionDrop, 'Value');
    newSess = sessList{newSessIdx};
    
    runList = flvoice('import',sub, newSess);
    curRun = runList{1};
    data.vars.curRun = curRun;

    taskList = flvoice('import',sub, newSess, curRun);
    set(data.handles.taskDrop, 'String', taskList, 'Value', 1);
    curTask = taskList{get(data.handles.taskDrop, 'Value')};
    %data.vars.taskList = taskList;
    %data.vars.curTask = curTask;
        
    updateSubj(data, data.vars.curSub, newSess, data.vars.curRun, curTask, 1);
    data = get(data.handles.hfig, 'userdata');
    data.vars.curSess = newSess;
    
    set(data.handles.hfig,'pointer','arrow');
    drawnow;
    % re-enable buttons when done 
    set(data.handles.prevButton, 'Enable', 'on');
    set(data.handles.nextButton, 'Enable', 'on');
    set(data.handles.hfig,'userdata',data);
    end

    function runDrop(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    set(data.handles.hfig,'pointer','watch');
    drawnow;
    % disable buttons when loading 
    set(data.handles.prevButton, 'Enable', 'off');
    set(data.handles.nextButton, 'Enable', 'off');
    
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
    
    runList = data.vars.runList;
    newRunIdx = get(data.handles.runDrop, 'Value');
    newRun = runList{newRunIdx};
    
    updateSubj(data, data.vars.curSub, data.vars.curSess, newRun, data.vars.curTask, 1);
    data = get(data.handles.hfig, 'userdata');
    data.vars.curRun = newRun;
    
    set(data.handles.hfig,'pointer','arrow');
    drawnow;
    % re-enable buttons when done 
    set(data.handles.prevButton, 'Enable', 'on');
    set(data.handles.nextButton, 'Enable', 'on');
    set(data.handles.hfig,'userdata',data);
    end

    function taskDrop(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    set(data.handles.hfig,'pointer','watch');
    drawnow;
    % disable buttons when loading 
    set(data.handles.prevButton, 'Enable', 'off');
    set(data.handles.nextButton, 'Enable', 'off');
    
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
    
    taskList = data.vars.taskList;
    newTaskIdx = get(data.handles.taskDrop, 'Value');
    newTask = taskList{newTaskIdx};
    updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, newTask, 1);
    data = get(data.handles.hfig, 'userdata');
    data.vars.curTask = newTask;
    
    set(data.handles.hfig,'pointer','arrow');
    drawnow;
    % re-enable buttons when done 
    set(data.handles.prevButton, 'Enable', 'on');
    set(data.handles.nextButton, 'Enable', 'on');
    set(data.handles.hfig,'userdata',data);
    end
    
    function trialDrop(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    set(data.handles.hfig,'pointer','watch');
    drawnow;
    % disable buttons when loading 
    set(data.handles.prevButton, 'Enable', 'off');
    set(data.handles.nextButton, 'Enable', 'off');
    
    newTrial = get(data.handles.trialDrop, 'Value');
    updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, newTrial);
    data = get(data.handles.hfig, 'userdata');
    data.vars.curTrial = newTrial;
    
    set(data.handles.hfig,'pointer','arrow');
    drawnow;
    % re-enable buttons when done 
    set(data.handles.prevButton, 'Enable', 'on');
    set(data.handles.nextButton, 'Enable', 'on');
    set(data.handles.hfig,'userdata',data);
    end

    function prevTrial(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    % disable buttons while loading
    set(data.handles.prevButton, 'Enable', 'off');
    set(data.handles.nextButton, 'Enable', 'off');
    
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
        choice = questdlg('This is the first trial for this run, attempt to load previous run?', 'Change runs?', 'Yes', 'No', 'opts');
        switch choice
            case 'Yes'
                curRun = data.vars.curRun;
                runList = data.vars.runList;
                runIdx = find(strcmp(runList,curRun));
                prevIdx = runIdx-1;
                if prevIdx > numel(runList);
                    warning = msgbox('Previous run does not exist, consider changing session?')
                    % re-enable buttons 
                    set(data.handles.prevButton, 'Enable', 'on');
                    set(data.handles.nextButton, 'Enable', 'on');
                else
                    prevRun = runList{prevIdx};
                    taskList = data.vars.taskList;
                    updateSubj(data, data.vars.curSub, data.vars.curSess, prevRun, taskList{1}, 1) % maybe should load last trial of prev run
                    data = get(data.handles.hfig, 'userdata');
                    data.vars.curRun = prevRun;
                    data.vars.curTrial = 1;
                end
                case 'No'
                    % re-enable buttons 
                    set(data.handles.prevButton, 'Enable', 'on');
                    set(data.handles.nextButton, 'Enable', 'on');
                    return 
        end
    else
        updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, prevTrial);
        data = get(data.handles.hfig, 'userdata');
        data.vars.curTrial = prevTrial;
    end
    
    set(data.handles.hfig,'userdata',data);
    end
    
    function nextTrial(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    % disable buttons while loading
    set(data.handles.prevButton, 'Enable', 'off');
    set(data.handles.nextButton, 'Enable', 'off');
    
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
        choice = questdlg('This is the last trial for this run, attempt to load next run?', 'Change runs?', 'Yes', 'No', 'opts');
        switch choice
            case 'Yes'
                curRun = data.vars.curRun;
                runList = data.vars.runList;
                runIdx = find(strcmp(runList,curRun));
                nextIdx = runIdx+1;
                if nextIdx > numel(runList)
                    warning = msgbox('Next run does not exist, consider changing session?')
                    % re-enable buttons 
                    set(data.handles.prevButton, 'Enable', 'on');
                    set(data.handles.nextButton, 'Enable', 'on');
                else
                    nextRun = runList{nextIdx};
                    taskList = data.vars.taskList;
                    updateSubj(data, data.vars.curSub, data.vars.curSess, nextRun, taskList{1}, 1)
                    data = get(data.handles.hfig, 'userdata');
                    data.vars.curRun = nextRun;
                    data.vars.curTrial = 1;
                end
                case 'No'
                    % re-enable buttons 
                    set(data.handles.prevButton, 'Enable', 'on');
                    set(data.handles.nextButton, 'Enable', 'on');
                    return 
        end
    else
        updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, nextTrial);
        data = get(data.handles.hfig, 'userdata');
        %data.vars.curTrial = nextTrial;
    end
   
    set(data.handles.hfig,'userdata',data);
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

    function playHead(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    curTrial = data.vars.curTrial;
    headWav = data.vars.headWav;
    fs = data.vars.curInputData(curTrial).fs;
    soundsc(headWav, fs, [-0.2 , 0.2]); % low and high placed as in some cases sound scaled to be way to loud

    %set(data.handles.hfig,'userdata',data);
    end

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
    

    function updateSubj(data,varargin)
    % Helper function that updates the GUI based on current sub / trial 
    set(data.handles.hfig,'pointer','watch');
    drawnow;
    % disable buttons while loading
    set(data.handles.prevButton, 'Enable', 'off');
    set(data.handles.nextButton, 'Enable', 'off');
    
    if numel(varargin) < 1
        init = 1;
    else
        init = 0;
        sub = varargin{1};
        sess = varargin{2};
        run = varargin{3};
        task = varargin{4};
        trial = varargin{5};
        
        % if it's the same sub, sess, task, no need to run fl_import in the future 
        if isfield(data,'vars')
            if isequal(sub,data.vars.curSub) && isequal(sess,data.vars.curSess) && isequal(run,data.vars.curRun) && isequal(task,data.vars.curTask)
                loadData = 0;
            else
                loadData = 1;
            end 
        else
            loadData = 1;
        end
    end 
    if init % set values to first value in each droplist
       
        % update subjects
        subList = flvoice('import');
        for i = 1:numel(subList)
            if isempty(flvoice('import', subList{i})) % if no sessions skip subj
                subList{i} = [];
                continue
            else
                sessL = flvoice('import', subList{i}); %  if session is empty, exclude it
                allempty = 1;
                for j = 1:numel(sessL)
                    tsess = sessL{j};
                    if ~isempty(flvoice('import', subList{i},tsess))
                        allempty = 0;
                        continue
                    end
                end 
                if allempty == 1 % if all sessions are empty, exclude the subject
                    subList{i} = [];
                    continue
                end
            end
        end
        emptyIdx = cellfun(@isempty,subList);
        subList(emptyIdx) = [];    
        data.vars.subList = subList;
        set(data.handles.subDrop, 'String', subList, 'Value', 1);
        disp('Loading default data from root folder:')
        curSub = subList{get(data.handles.subDrop, 'Value')};
        fprintf('Loading subject %s:', curSub); 
        data.vars.subList = subList;
        data.vars.curSub = curSub;
        
        % update sess
        sessList = flvoice('import', curSub);
        % check for empty sessions
        for i = 1:numel(sessList)
            if ~isempty(flvoice('import', curSub, sessList{i}))
                continue
            else
                sessList{i} = [];
            end
        end
        emptyIdx = cellfun(@isempty,sessList);
        sessList(emptyIdx) = [];    
        set(data.handles.sessionDrop, 'String', sessList, 'Value', 1);
        curSess = sessList{get(data.handles.sessionDrop, 'Value')};
        data.vars.sessList = sessList;
        data.vars.curSess = curSess;
        
        % update run
        runList = flvoice('import', curSub,curSess);
        set(data.handles.runDrop, 'String', runList, 'Value', 1);
        curRun = runList{get(data.handles.runDrop, 'Value')};
        data.vars.runList = runList;
        data.vars.curRun = curRun;
        
        % update task
        taskList = flvoice('import', curSub,curSess, curRun);
        set(data.handles.taskDrop, 'String', taskList, 'Value', 1);
        curTask = taskList{get(data.handles.taskDrop, 'Value')};
        data.vars.taskList = taskList;
        data.vars.curTask = curTask;
        
        % get trial data
        curInputData = flvoice_import(curSub,curSess,curRun,curTask,'input');
        curInputData = curInputData{1};
        % update trial
        trialList = (1:size(curInputData,2));
        set(data.handles.trialDrop, 'String', trialList, 'Value', 1);
        if isempty(trialList)
            disp('Found no trials')
            set(data.handles.hfig,'pointer','arrow');
            drawnow;
            % re-enable buttons when done 
            set(data.handles.prevButton, 'Enable', 'on');
            set(data.handles.nextButton, 'Enable', 'on');
            set(data.handles.hfig,'userdata',data);
            return
        else
            curTrial = get(data.handles.trialDrop, 'Value');
            curCond = curInputData(curTrial).condLabel;
        end
        set(data.handles.condVal, 'String', curCond);
        data.vars.trialList = trialList;
        data.vars.curCond = curCond;
        data.vars.curTrial = curTrial;
        
        % Should load previous flags / settings if they exist here
        curRunQC = flvoice_import(curSub,curSess,curRun,curTask, 'get_qc');
        numFlags = 7;
        if isempty(curRunQC.badTrial) || size(curRunQC.badTrial,1) < numFlags
            curRunQC.badTrial = zeros(numFlags,size(data.vars.trialList,2));
            curRunQC.keepData = boolean(ones(1,size(data.vars.trialList,2)));
            curRunQC.dictionary = cell(1,size(data.vars.trialList,2));
            curRunQC.settings = cell(1,size(data.vars.trialList,2));
        elseif size(curRunQC.badTrial,2) < size(data.vars.trialList,2) || size(curRunQC.keepData,2) < size(data.vars.trialList,2)
            curRunQC.badTrial = [curRunQC.badTrial zeros(numFlags, (size(data.vars.trialList,2)- size(curRunQC.badTrial,2)))];
            curRunQC.keepData = ~any(curRunQC.badTrial ~=0);
            curRunQC.dictionary{1,size(data.vars.trialList,2)} = [];
            curRunQC.settings{1,size(data.vars.trialList,2)} = [];
        end
        set(data.handles.flag1txt, 'Value',  curRunQC.badTrial(1,1));
        set(data.handles.flag2txt, 'Value',  curRunQC.badTrial(2,1));
        set(data.handles.flag3txt, 'Value',  curRunQC.badTrial(3,1));
        set(data.handles.flag4txt, 'Value',  curRunQC.badTrial(4,1));
        set(data.handles.flag5txt, 'Value',  curRunQC.badTrial(5,1));
        set(data.handles.flag6txt, 'Value',  curRunQC.badTrial(6,1));
        if curRunQC.badTrial(7,1) == 0
            set(data.handles.flag7txt, 'Value', curRunQC.badTrial(7,1));
            set(data.handles.flag7edit, 'String', 'Comment', 'Enable', 'off');
        else
            set(data.handles.flag7txt, 'Value',  curRunQC.badTrial(7,1));
            set(data.handles.flag7edit, 'String',  curRunQC.dictionary{1,1}(end), 'Enable', 'on');
        end
        data.vars.curRunQC = curRunQC; 
        
        if ~isempty(curRunQC.settings{curTrial})
            if isempty(curRunQC.settings{curTrial}.lporder); lporder = '[ ]'; else; lporder =  num2str(curRunQC.settings{curTrial}.lporder); end
            set(data.handles.NLPCtxtBox, 'String', lporder);
            set(data.handles.winSizeFtxtBox, 'String', num2str(curRunQC.settings{curTrial}.windowsizeF));
            set(data.handles.vfiltertxtBox, 'String', num2str(curRunQC.settings{curTrial}.viterbfilter));
            set(data.handles.mfilterFtxtBox, 'String', num2str(curRunQC.settings{curTrial}.medianfilterF));
            set(data.handles.winSizePtxtBox, 'String', num2str(curRunQC.settings{curTrial}.windowsizeP));  
            set(data.handles.methodstxtBox, 'String', curRunQC.settings{curTrial}.methods);
            if isempty(curRunQC.settings{curTrial}.range); range = '[ ]'; else; range =  num2str(curRunQC.settings{curTrial}.lporder); end
            set(data.handles.rangetxtBox, 'String', range);
            set(data.handles.hr_mintxtBox, 'String', num2str(curRunQC.settings{curTrial}.hr_min));
            set(data.handles.mfilterPtxtBox, 'String', num2str(curRunQC.settings{curTrial}.medianfilterP)); 
            set(data.handles.ofilterPtxtBox, 'String', num2str(curRunQC.settings{curTrial}.outlierfilter));
            if isempty(curRunQC.settings{curTrial}.range); SKIP_LOWAMP = '[ ]'; else; SKIP_LOWAMP =  num2str(curRunQC.settings{curTrial}.lporder); end
            set(data.handles.skipLowAPtxtBox, 'String', SKIP_LOWAMP);
        end
                
        % update mic/ head plots
        micWav = curInputData(curTrial).s{1};
        micTime = (0+(0:numel(micWav)-1*1/curInputData(curTrial).fs));
        data.handles.micPlot = plot(micTime,micWav, 'Parent', data.handles.micAxis);
        set(data.handles.micAxis, 'XLim', [0, numel(micTime)]);
        data.vars.micWav = micWav;
        data.vars.micTime = micTime;
        
        if strcmp(data.vars.curTask, 'aud')
            set(data.handles.headAxis, 'visible', 'on');
            if isfield(data.handles, 'headPlot')
                set(data.handles.headPlot, 'visible', 'on');
            end
            set(data.handles.playHeadButton, 'enable', 'on');
            headWav = curInputData(curTrial).s{2};
            headTime = (0+(0:numel(headWav)-1*1/curInputData(curTrial).fs));
            data.handles.headPlot = plot(headTime,headWav, 'Parent', data.handles.headAxis);
            set(data.handles.headAxis, 'XLim', [0, numel(headTime)]);
            data.vars.headWav = headWav;
            data.vars.headTime = headTime;
        else
            set(data.handles.headAxis, 'visible', 'off');
            if isfield(data.handles, 'headPlot')
                set(data.handles.headPlot, 'visible', 'off');
            end
            set(data.handles.playHeadButton, 'enable', 'off');
        end
        
        % update spectogram plots
        curOutputData = flvoice_import(curSub,curSess,curRun,curTask,'output');
        curOutputData = curOutputData{1};
        
        axes(data.handles.pitchAxis);
        s = curInputData(curTrial).s{1}; %NOTE always s{1}?
        fs = curInputData(curTrial).fs;
        data.handles.fPlot = plot((0:numel(s)-1)/fs,s, 'Parent', data.handles.pitchAxis);
        set(data.handles.pitchAxis,'xlim',[0 numel(s)/fs],'xtick',.5:.5:numel(s)/fs,'ylim',max(abs(s))*[-1.1 1.1],'ytick',max(abs(s))*linspace(-1.1,1.1,7),'yticklabel',[]);
        hold on; yyaxis('right'); ylabel('pitch (Hz)'); ylim([0, 600]); yticks(0:100:600); hold off;
        % .timingTrial = [TIME_TRIAL_START; TIME_TRIAL_ACTUALLYSTART; TIME_VOICE_START; TIME_PERT_START; TIME_PERT_ACTUALLYSTART; TIME_PERT_END; TIME_PERT_ACTUALLYEND; TIME_SCAN_START; TIME_SCAN_ACTUALLYSTART; TIME_SCAN_END];
        if isfield(curInputData(curTrial), 'timingTrial')
            voiceOnset = (curInputData(curTrial).timingTrial(3)- curInputData(curTrial).timingTrial(2));
            pertOnset = (curInputData(curTrial).timingTrial(4)- curInputData(curTrial).timingTrial(2));
            if isnan(pertOnset)
                pertOnset = (curInputData(curTrial).timingTrial(4)- curInputData(curTrial).timingTrial(1));
            end
        else
            pertOnset = curInputData(curTrial).pertOnset;
        end
        hold on; xline(pertOnset,'b--',{'Pert','onset'},'linewidth',2); grid on;
        hold on; xline(voiceOnset,'m--',{'Voice','onset'},'linewidth',2); grid on;
        
        axes(data.handles.ppAxis);
        if strcmp(data.vars.curTask, 'som')
            f0idx = find(contains(curOutputData(curTrial).dataLabel,'raw-F0measure1'));
            f0 = curOutputData(curTrial).s{1,f0idx};%NOTE always s{1,1}?
            fs2 = curOutputData(curTrial).fs;
            %t = (0.025:0.001:2.524); % how do I derive this from given data?
            t = [0+(0:numel(f0)-1)/fs2]; % correct??
            ppMic=plot(t,f0,'.','LineWidth',.6, 'Color', [.6 .6 .6]);
        else
            f0idx = find(contains(curOutputData(curTrial).dataLabel,'raw-F0-mic'));
            f0 = curOutputData(curTrial).s{1,f0idx};%NOTE always s{1,1}?
            fs2 = curOutputData(curTrial).fs;
            %t = (0.025:0.001:2.524); % how do I derive this from given data?
            t = [0+(0:numel(f0)-1)/fs2]; % correct??
            ppMic=plot(t,f0,'.','LineWidth',.6, 'Color', [.6 .6 .6]);
            hold on;
            f0headIdx = find(contains(curOutputData(curTrial).dataLabel,'raw-F0-headphones'));
            f0head = curOutputData(curTrial).s{1,f0headIdx};
            ppHead=plot(t,f0head,'.','LineWidth',.6, 'Color', [0 0 0]);
            uistack(ppMic, 'top'); % making sure mic trace is on top
        end
        set(gca,'xlim',[0 numel(s)/fs]);
        set(data.handles.ppAxis,'visible','off','ylim',[0 600]);
        hold off; 
        
        axes(data.handles.formantAxis);
        set(data.handles.formantAxis, 'OuterPosition', [-0.12, 0.10, 1, 0.25]);
        %spectrogram(s,round(.015*fs),round(.014*fs),[],fs,'yaxis');
        flvoice_spectrogram(s,fs,round(.015*fs),round(.014*fs));
        if strcmp(data.vars.curTask, 'som')
            f1micIdx = find(contains(curOutputData(1).dataLabel,'raw-F1measure1'));
            f2micIdx = find(contains(curOutputData(1).dataLabel,'raw-F2measure1'));
            fmt = [curOutputData(1).s{1,f1micIdx},curOutputData(1).s{1,f2micIdx}];
            hold on; fmtMic = plot(t,fmt'/1e3,'.-','LineWidth',.6, 'Color', [.6 .6 .6]); hold off;   
        else
            f1micIdx = find(contains(curOutputData(1).dataLabel,'raw-F1-mic'));
            f2micIdx = find(contains(curOutputData(1).dataLabel,'raw-F2-mic'));
            fmt = [curOutputData(1).s{1,f1micIdx},curOutputData(1).s{1,f2micIdx}];
            hold on; fmtMic = plot(t,fmt'/1e3,'.-','LineWidth',.6, 'Color', [.6 .6 .6]); hold off;
            %hold on; fmtMic = plot(t,fmt'/1e3,'--','LineWidth',.3, 'Color', [.6 .6 .6]); hold off;
            hold on;
            f1headIdx = find(contains(curOutputData(1).dataLabel,'raw-F1-headphones'));
            f2headIdx = find(contains(curOutputData(1).dataLabel,'raw-F2-headphones'));
            fmtHead = [curOutputData(1).s{1,f1headIdx},curOutputData(1).s{1,f2headIdx}];
            hold on; fmtHead = plot(t,fmtHead'/1e3,'.-','LineWidth',.6, 'Color', [0 0 0]); hold off;
            %hold on; fmtHead = plot(t,fmtHead'/1e3,'.-','LineWidth',.3, 'Color', [0 0 0]); hold off;
            uistack(fmtMic, 'top'); % making sure mic trace is on top
        end
        
        %hold on; plot(headTime,headWav); hold off;
        set(data.handles.formantAxis, 'yscale','log');
        set(data.handles.formantAxis, 'units','norm', 'fontsize',0.09,'position',[0.028, 0.12, 0.886, 0.2],'yaxislocation','right', 'xlim',[0 numel(s)/fs],'xtick',.5:.5:numel(s)/fs);
        set(data.handles.formantAxis, 'ylim', [0 8],'ytick',[0 .1 .2 .4 1 2 4 8]) % helps  but not quite the same scale I think
        set(data.handles.formantAxis.Colorbar, 'FontSize', 6.5, 'Position', [0.9550    0.1193    0.017    0.2007]);
        colormap(jet)
        % can change colormap by doing the following:
        % colormap(jet); caxis('auto') %caxis([-170 0
        % maybe add button to do this? 
        % should probably also make the legend visible if so
        %xlabel('Time (s)'); ylabel('formants (KHz)');
        
        
    else % set values based on given inputs
        % update subjects
        if isfield(data, 'vars') && isfield(data.vars, 'subList')
            subList = data.vars.subList;
        else
            subList = flvoice('import');
            for i = 1:numel(subList)
                if isempty(flvoice('import', subList{i})) % if no sessions skip subj
                    subList{i} = [];
                    continue
                else
                    sessL = flvoice('import', subList{i}); %  if session is empty, exclude it
                    allempty = 1;
                    for j = 1:numel(sessL)
                        tsess = sessL{j};
                        if ~isempty(flvoice('import', subList{i},tsess))
                            allempty = 0;
                            continue
                        end
                    end
                    if allempty == 1 % if all sessions are empty, exclude the subject
                        subList{i} = [];
                        continue
                    end
                end
            end
        end
        emptyIdx = cellfun(@isempty,subList);
        subList(emptyIdx) = [];    
        data.vars.subList = subList;
        subIdx = find(contains(subList,sub));
        set(data.handles.subDrop, 'String', subList, 'Value', subIdx);
        data.vars.curSub = sub;
        
        % update sess
        sessList = flvoice('import', sub);
        % check for empty sessions
        for i = 1:numel(sessList)
            if ~isempty(flvoice('import', sub, sessList{i}))
                continue
            else
                sessList{i} = [];
            end
        end
        emptyIdx = cellfun(@isempty,sessList);
        sessList(emptyIdx) = [];    
        if isempty(sess)
            sess = sessList{1};
        end
        sessIdx = find(contains(sessList,sess));
        set(data.handles.sessionDrop, 'String', sessList, 'Value', sessIdx);
        data.vars.sessList = sessList;
        data.vars.curSess = sess;
        
        % update run
        runList = flvoice('import', sub,sess);
        if isempty(run)
            run = runList{1};
        end
        runIdx = find(contains(runList,run));
        set(data.handles.runDrop, 'String', runList, 'Value', runIdx);
        data.vars.runList = runList;
        data.vars.curRun = run;
               
        % update task
        taskList = flvoice('import', sub,sess,run);
        if isempty(task)
            task = taskList{1};
        end
        taskIdx = find(contains(taskList,task));
        set(data.handles.taskDrop, 'String', taskList, 'Value', taskIdx);
        data.vars.taskList = taskList;
        data.vars.curTask = task;
        
        % get trial data
        if loadData % only run fl_voice_import() if data being loaded is different from current
            curInputData = flvoice_import(sub,sess,run,task,'input');
            curInputData = curInputData{1};
        else
            curInputData = data.vars.curInputData;
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
        data.vars.trialList = trialList;
        data.vars.curCond = curCond;
        data.vars.curTrial = trial;
        
        % load previous flags if they exist here       
        curRunQC = flvoice_import(sub,sess,run,task, 'get_qc');
        numFlags = 7;
        if isempty(curRunQC.badTrial) || size(curRunQC.badTrial,1) < numFlags
            curRunQC.badTrial = zeros(numFlags,size(data.vars.trialList,2));
            curRunQC.keepData = boolean(ones(1,size(data.vars.trialList,2)));
            curRunQC.dictionary = cell(1,size(data.vars.trialList,2));
            curRunQC.settings = cell(1,size(data.vars.trialList,2));
        elseif size(curRunQC.badTrial,2) < size(data.vars.trialList,2) || size(curRunQC.keepData,2) < size(data.vars.trialList,2)
            curRunQC.badTrial = [curRunQC.badTrial zeros(numFlags, (size(data.vars.trialList,2)- size(curRunQC.badTrial,2)))];
            curRunQC.keepData = ~any(curRunQC.badTrial ~=0);
            curRunQC.dictionary{1,size(data.vars.trialList,2)} = [];
            curRunQC.settings{1,size(data.vars.trialList,2)} = [];
        end
        set(data.handles.flag1txt, 'Value',  curRunQC.badTrial(1,trial));
        set(data.handles.flag2txt, 'Value',  curRunQC.badTrial(2,trial));
        set(data.handles.flag3txt, 'Value',  curRunQC.badTrial(3,trial));
        set(data.handles.flag4txt, 'Value',  curRunQC.badTrial(4,trial));
        set(data.handles.flag5txt, 'Value',  curRunQC.badTrial(5,trial));
        set(data.handles.flag6txt, 'Value',  curRunQC.badTrial(6,trial));
        if curRunQC.badTrial(7,trial) == 0
            set(data.handles.flag7txt, 'Value',  0);
            set(data.handles.flag7edit, 'String', 'Comment', 'Enable', 'off');
        else
            set(data.handles.flag7txt, 'Value',  curRunQC.badTrial(7,trial));
            if isempty(curRunQC.dictionary{1,trial})
                set(data.handles.flag7edit, 'String',  'Comment', 'Enable', 'on');
            else
                set(data.handles.flag7edit, 'String',  curRunQC.dictionary{1,trial}(end), 'Enable', 'on');
            end
        end 
        data.vars.curRunQC = curRunQC; 
        
        if ~isempty(curRunQC.settings{trial})
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
            if isempty(curRunQC.settings{trial}.range); SKIP_LOWAMP = '[ ]'; else; SKIP_LOWAMP =  num2str(curRunQC.settings{trial}.lporder); end
            set(data.handles.skipLowAPtxtBox, 'String', SKIP_LOWAMP);
        end
        
        % update mic plot
        micWav = curInputData(trial).s{1};
        micTime = (0+(0:numel(micWav)-1*1/curInputData(trial).fs));
        data.handles.micPlot = plot(micTime,micWav, 'Parent', data.handles.micAxis);
        %set(data.handles.micAxis, 'XLim', [0, numel(micWav)/curInputData(trial).fs], 'xtick',.5:.5:numel(micWav)/curInputData(trial).fs);
        set(data.handles.micAxis, 'XLim', [0, numel(micTime)]);
        data.vars.micWav = micWav;
        data.vars.micTime = micTime;
        
        if strcmp(task, 'aud')
            set(data.handles.headAxis, 'visible', 'on');
            if isfield(data.handles, 'headPlot')
                set(data.handles.headPlot, 'visible', 'on');
            end
            set(data.handles.playHeadButton, 'enable', 'on');
            headWav = curInputData(trial).s{2};
            headTime = (0+(0:numel(headWav)-1*1/curInputData(trial).fs));
            data.handles.headPlot = plot(headTime,headWav, 'Parent', data.handles.headAxis);
            set(data.handles.headAxis, 'XLim', [0, numel(headTime)]);
            data.vars.headWav = headWav;
            data.vars.headTime = headTime;
        else
            set(data.handles.headAxis, 'visible', 'off');
            if isfield(data.handles, 'headPlot')
                set(data.handles.headPlot, 'visible', 'off');
            end
            set(data.handles.playHeadButton, 'enable', 'off');
        end
        
        % update spectogram plots
        if loadData % only run fl_voice_import() if data being loaded is different from current
            curOutputData = flvoice_import(sub,sess,run,task,'output');
            curOutputData = curOutputData{1};
        else
            curOutputData = data.vars.curOutputData;
        end
        
        cla(data.handles.pitchAxis, 'reset');
        axes(data.handles.pitchAxis);
        s = curInputData(trial).s{1};
        fs = curInputData(trial).fs;
        data.handles.fPlot = plot((0:numel(s)-1)/fs,s, 'Parent', data.handles.pitchAxis);
        set(data.handles.pitchAxis,'xlim',[0 numel(s)/fs],'xtick',.5:.5:numel(s)/fs,'ylim',max(abs(s))*[-1.1 1.1],'ytick',max(abs(s))*linspace(-1.1,1.1,7),'yticklabel',[]);
        hold on; yyaxis('right'); ylabel('pitch (Hz)'); ylim([0, 600]); yticks(0:100:600); hold off;
        % only relevant for some backward compat data
        % .timingTrial = [TIME_TRIAL_START; TIME_TRIAL_ACTUALLYSTART; TIME_VOICE_START; TIME_PERT_START; TIME_PERT_ACTUALLYSTART; TIME_PERT_END; TIME_PERT_ACTUALLYEND; TIME_SCAN_START; TIME_SCAN_ACTUALLYSTART; TIME_SCAN_END];
        if isfield(curInputData(trial), 'timingTrial')
            voiceOnset = (curInputData(trial).timingTrial(3)- curInputData(trial).timingTrial(2));
            pertOnset = (curInputData(trial).timingTrial(4)- curInputData(trial).timingTrial(2));
            if isnan(pertOnset)
                pertOnset = (curInputData(trial).timingTrial(4)- curInputData(trial).timingTrial(1));
            end
        else
            pertOnset = curInputData(trial).pertOnset;
        end
        hold on; xline(pertOnset,'b--',{'Pert','onset'},'linewidth',2); grid on;
        hold on; xline(voiceOnset,'m--',{'Voice','onset'},'linewidth',2); grid on;
        %hold on; xline(pertOnset,'y:','linewidth',2); grid on; % problem pertOnset 
        
        cla(data.handles.ppAxis);
        axes(data.handles.ppAxis);
        if strcmp(task, 'som')
            f0idx = find(contains(curOutputData(trial).dataLabel,'raw-F0measure1'));
            f0 = curOutputData(trial).s{1,f0idx};%NOTE always s{1,1}?
            fs2 = curOutputData(trial).fs;
            %t = (0.025:0.001:2.524); % how do I derive this from given data?
            t = [0+(0:numel(f0)-1)/fs2]; % correct??
            ppMic=plot(t,f0,'.','LineWidth',1, 'Color', [.6 .6 .6]);
        else
            f0idx = find(contains(curOutputData(trial).dataLabel,'raw-F0-mic'));
            f0 = curOutputData(trial).s{1,f0idx};%NOTE always s{1,1}?
            fs2 = curOutputData(trial).fs;
            %t = (0.025:0.001:2.524); % how do I derive this from given data?
            t = [0+(0:numel(f0)-1)/fs2]; % correct??
            ppMic=plot(t,f0,'.','LineWidth',1, 'Color', [.6 .6 .6]);
            hold on;
            f0headIdx = find(contains(curOutputData(trial).dataLabel,'raw-F0-headphones'));
            f0head = curOutputData(trial).s{1,f0headIdx};
            ppHead=plot(t,f0head,'.','LineWidth',1, 'Color', [0 0 0]);
            uistack(ppMic, 'top'); % making sure mic trace is on top
        end
        set(gca,'xlim',[0 numel(s)/fs]);
        set(data.handles.ppAxis,'visible','off','ylim',[0 600]);
        hold off; 
        
        cla(data.handles.formantAxis);
        set(data.handles.formantAxis.Colorbar, 'Visible', 'off');
        axes(data.handles.formantAxis);
        set(data.handles.formantAxis, 'OuterPosition', [-0.12, 0.10, 1, 0.25]);
        %spectrogram(s,round(.015*fs),round(.014*fs),[],fs,'yaxis');
        flvoice_spectrogram(s,fs,round(.015*fs),round(.014*fs));
        if strcmp(task, 'som')
            f1micIdx = find(contains(curOutputData(trial).dataLabel,'raw-F1measure1'));
            f2micIdx = find(contains(curOutputData(trial).dataLabel,'raw-F2measure1'));
            fmt = [curOutputData(trial).s{1,f1micIdx},curOutputData(trial).s{1,f2micIdx}];
            hold on; fmtMic = plot(t,fmt'/1e3,'.-', 'Color', [.6 .6 .6]); hold off;
        else
            f1micIdx = find(contains(curOutputData(trial).dataLabel,'raw-F1-mic'));
            f2micIdx = find(contains(curOutputData(trial).dataLabel,'raw-F2-mic'));
            fmt = [curOutputData(trial).s{1,f1micIdx},curOutputData(trial).s{1,f2micIdx}];
            hold on; fmtMic = plot(t,fmt'/1e3,'.-', 'Color', [.6 .6 .6]); hold off;
            hold on;
            f1headIdx = find(contains(curOutputData(trial).dataLabel,'raw-F1-headphones'));
            f2headIdx = find(contains(curOutputData(trial).dataLabel,'raw-F2-headphones'));
            fmtHead = [curOutputData(trial).s{1,f1headIdx},curOutputData(trial).s{1,f2headIdx}];
            hold on; fmtHead = plot(t,fmtHead'/1e3,'.-', 'Color', [0 0 0]); hold off;
            uistack(fmtMic, 'top'); % making sure mic trace is on top
        end
        
        %hold on; plot(headTime,headWav); hold off;
        set(data.handles.formantAxis, 'yscale','log');
        set(data.handles.formantAxis, 'units','norm', 'fontsize',0.09,'position',[0.028, 0.12, 0.886, 0.2],'yaxislocation','right', 'xlim',[0 numel(s)/fs],'xtick',.5:.5:numel(s)/fs);
        set(data.handles.formantAxis, 'ylim', [0 8],'ytick',[0 .1 .2 .4 1 2 4 8]) % helps  but not quite the same scale I think
        set(data.handles.formantAxis.Colorbar, 'FontSize', 6.5, 'Position', [0.9550    0.1193    0.017    0.2007]);
        colormap(jet)
        
    end
        % save curr data
        data.vars.curInputData = curInputData;
        data.vars.curOutputData = curOutputData;
        set(data.handles.hfig,'pointer','arrow');
        drawnow;
        % re-enable buttons when done 
        set(data.handles.prevButton, 'Enable', 'on');
        set(data.handles.nextButton, 'Enable', 'on');
        set(data.handles.hfig,'userdata',data);
    end 

end