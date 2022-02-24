function varagout=flvoice_QCgui(option,varargin)
% Quality control GUI for FLvoice

% if no input / no /option/, initialize 
if ~nargin||isempty(option)
    option ='init'; 
end

switch(lower(option))
    case 'init' % initializing main elements of the GUI
        % Main figure
        data.handles.hfig=figure('Units','norm','Position',[.25 .2 .6 .6],'Menubar','none','Name','FLvoice QC GUI','numbertitle','off','color','w');
        % reminder; position is [(bottom left corner normalized x pos) (bottom left corner normalized y pos) (width) (heigth)]
        
        % SETTINGS PANEL
        data.handles.settPanel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.02 .47 .2 .5],'Parent',data.handles.hfig);
        % Formant Settings
        data.handles.FSettText=uicontrol('Style', 'text','String','Formant Settings:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.625,'HorizontalAlignment', 'left','Position',[.2 .915 .8 .08],'Parent',data.handles.settPanel);
        data.handles.NLPCtxt=uicontrol('Style', 'text','String','NLPC:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .85 .4 .08],'BackgroundColor', [1 1 1], 'Parent',data.handles.settPanel);
        data.handles.NLPCtxtBox=uicontrol('Style', 'edit','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .85 .45 .074],'Parent',data.handles.settPanel);    
        data.handles.step1txt=uicontrol('Style', 'text','String','Step Size:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .77 .4 .08],'BackgroundColor', [1 1 1], 'Parent',data.handles.settPanel);
        data.handles.step1txtBox=uicontrol('Style', 'edit','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .77 .45 .074],'Parent',data.handles.settPanel);
        data.handles.window1txt=uicontrol('Style', 'text','String','Window Size:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .69 .4 .08],'BackgroundColor', [1 1 1], 'Parent',data.handles.settPanel);
        data.handles.window1txtBox=uicontrol('Style', 'edit','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .69 .45 .074],'Parent',data.handles.settPanel);
        data.handles.LPCtxt=uicontrol('Style', 'text','String','LPC order:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .61 .4 .08],'BackgroundColor', [1 1 1], 'Parent',data.handles.settPanel);
        data.handles.LPCtxtBox=uicontrol('Style', 'edit','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .61 .45 .074],'Parent',data.handles.settPanel);
        % Pitch Settings
        data.handles.PSettText=uicontrol('Style', 'text','String','Pitch Settings:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.625,'HorizontalAlignment', 'left','Position',[.2 .505 .8 .08],'Parent',data.handles.settPanel);
        data.handles.rangeCtxt=uicontrol('Style', 'text','String','Range (Hz):','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .44 .4 .08],'BackgroundColor', [1 1 1], 'Parent',data.handles.settPanel);
        data.handles.rangetxtBox=uicontrol('Style', 'edit','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .44 .45 .074],'Parent',data.handles.settPanel);    
        data.handles.step2txt=uicontrol('Style', 'text','String','Step Size:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .36 .4 .08],'BackgroundColor', [1 1 1], 'Parent',data.handles.settPanel);
        data.handles.step2txtBox=uicontrol('Style', 'edit','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .36 .45 .074],'Parent',data.handles.settPanel);
        data.handles.window2txt=uicontrol('Style', 'text','String','Window Size:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .28 .4 .08],'BackgroundColor', [1 1 1], 'Parent',data.handles.settPanel);
        data.handles.window2txtBox=uicontrol('Style', 'edit','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .28 .45 .074],'Parent',data.handles.settPanel);
        data.handles.methodtxt=uicontrol('Style', 'text','String','Method:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .2 .4 .08],'BackgroundColor', [1 1 1], 'Parent',data.handles.settPanel);
        data.handles.methodxtBox=uicontrol('Style', 'edit','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .2 .45 .074],'Parent',data.handles.settPanel);
        data.handles.HRtxt=uicontrol('Style', 'text','String','HR min:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .12 .4 .08],'BackgroundColor', [1 1 1], 'Parent',data.handles.settPanel);
        data.handles.HRtxtBox=uicontrol('Style', 'edit','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.5 .12 .45 .074],'Parent',data.handles.settPanel);
        % Update Button
        data.handles.upSettButton=uicontrol('Style', 'pushbutton','String','Update Settings','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.1 .02 .8 .08],'Parent',data.handles.settPanel,'Callback', @updateSettings);
                   
        % QC FLAG PANEL
        data.handles.flagPanel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.02 .02 .2 .42],'Parent',data.handles.hfig);
        data.handles.flagText=uicontrol('Style', 'text','String','QC Flags:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.63,'HorizontalAlignment', 'center','Position',[.2 .915 .6 .08],'Parent',data.handles.flagPanel);
        data.handles.flag1txt=uicontrol('Style', 'checkbox','String','Performed incorrectly','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .83 .9 .1],'BackgroundColor', [1 1 1], 'Parent',data.handles.flagPanel);
        data.handles.flag2txt=uicontrol('Style', 'checkbox','String','Bad F0 trace','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .73 .9 .1],'BackgroundColor', [1 1 1], 'Parent',data.handles.flagPanel);
        data.handles.flag3txt=uicontrol('Style', 'checkbox','String','Bad F1 trace','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .63 .9 .1],'BackgroundColor', [1 1 1], 'Parent',data.handles.flagPanel);
        data.handles.flag4txt=uicontrol('Style', 'checkbox','String','Incorrect voice onset ','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .53 .9 .1],'BackgroundColor', [1 1 1], 'Parent',data.handles.flagPanel);
        data.handles.flag5txt=uicontrol('Style', 'checkbox','String','Utterance too short','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .43 .9 .1],'BackgroundColor', [1 1 1], 'Parent',data.handles.flagPanel);
        data.handles.flag6txt=uicontrol('Style', 'checkbox','String','Distortion / audio issues','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .33 .9 .1],'BackgroundColor', [1 1 1], 'Parent',data.handles.flagPanel);
        data.handles.flag7txt=uicontrol('Style', 'checkbox','String','Other:','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'right','Position',[.02 .23 .9 .1],'BackgroundColor', [1 1 1], 'Parent',data.handles.flagPanel);
        data.handles.flag7edit=uicontrol('Style', 'edit','String','"Comment"','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'center','Position',[.2 .135 .65 .09],'BackgroundColor', [1 1 1], 'Parent',data.handles.flagPanel);
        % Save Flag Button 
        data.handles.saveFlagButton=uicontrol('Style', 'pushbutton','String','Save flags','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.1 .02 .8 .1],'Parent',data.handles.flagPanel,'Callback', @saveFlags);
        
        % SUBJECT PANEL 
        data.handles.subPanel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.24 .89 .742 .08],'Parent',data.handles.hfig);
        % Sub
        data.handles.subText=uicontrol('Style', 'text','String','Subject:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.01 .15 .08 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
        data.handles.subDrop=uicontrol('Style', 'popupmenu','String','Sub01','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.095 .16 .12 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel, 'Callback', @subDrop);
        % Sess
        data.handles.sessionText=uicontrol('Style', 'text','String','Sess:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.22 .18 .05 .5],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
        data.handles.sessionDrop=uicontrol('Style', 'popupmenu','String','1','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.274 .16 .07 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel, 'Callback', @sessDrop);
        % Run
        data.handles.runText=uicontrol('Style', 'text','String','Run:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.35 .18 .04 .5],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
        data.handles.runDrop=uicontrol('Style', 'popupmenu','String','1','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.395 .16 .07 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel, 'Callback', @runDrop);
        % Task
        data.handles.taskText=uicontrol('Style', 'text','String','Task:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.47 .18 .045 .5],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
        data.handles.taskDrop=uicontrol('Style', 'popupmenu','String','aud','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.52 .16 .06 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel, 'Callback', @taskDrop);
        % Trial
        data.handles.trialText=uicontrol('Style', 'text','String','Trial:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.585 .18 .05 .5],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
        data.handles.trialDrop=uicontrol('Style', 'popupmenu','String','1','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.638 .16 .048 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel, 'Callback', @trialDrop);
        % Cond
        data.handles.condText=uicontrol('Style', 'text','String','Cond:','Units','norm','FontWeight','bold','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.69 .18 .055 .5],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
        data.handles.condVal=uicontrol('Style', 'text','String','N0','Units','norm','FontUnits','norm','FontSize',0.6,'HorizontalAlignment', 'left','Position',[.75 .16 .042 .5],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
        %data.handles.conditionDrop=uicontrol('Style', 'popupmenu','String','N0','Units','norm','FontUnits','norm','FontSize',0.5,'HorizontalAlignment', 'left','Position',[.74 .16 .05 .6],'BackgroundColor', [1 1 1],'Parent',data.handles.subPanel);
        % Prev / Next Buttons
        data.handles.prevButton=uicontrol('Style', 'pushbutton','String','<Prev','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.805 .15 .09 .7],'Parent',data.handles.subPanel,'Callback', @prevTrial);
        data.handles.nextButton=uicontrol('Style', 'pushbutton','String','Next>','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.9 .15 .09 .7],'Parent',data.handles.subPanel,'Callback', @nextTrial);
        
        %set defaults:
        %%% root set here for testing, generally root would be defined beforehand: %%%
        % flvoice_import SUB RUN SES TASK
        flvoice('ROOT','C:\Users\RickyFals\Documents\0BU\0GuentherLab\LabGit\SAPdata');
       
        % Axes (Mic / Head / Spectograms) Panel
        data.handles.axes1Panel=uipanel('Units','norm','FontUnits','norm','FontSize',0.28,'Position',[.24 .02 .742 .86],'Parent',data.handles.hfig);        
        data.handles.micAxis = axes('FontUnits', 'normalized', 'Units', 'normalized', 'OuterPosition', [-0.12, 0.76, 1.14, 0.25], 'Visible', 'on', 'Tag', 'mic_axis','Parent',data.handles.axes1Panel);
        data.handles.headAxis = axes('FontUnits', 'normalized', 'Units', 'normalized', 'OuterPosition', [-0.12, 0.54, 1.14, 0.25], 'Visible', 'on', 'Tag', 'head_axis','Parent',data.handles.axes1Panel);
        data.handles.formantAxis = axes('FontUnits', 'normalized', 'Units', 'normalized', 'OuterPosition', [-0.12, 0.32, 1.14, 0.25], 'Visible', 'on', 'Tag', 'mic_axis','Parent',data.handles.axes1Panel);
        data.handles.pitchAxis = axes('FontUnits', 'normalized', 'Units', 'normalized', 'OuterPosition', [-0.12, 0.10, 1.14, 0.25], 'Visible', 'on', 'Tag', 'head_axis','Parent',data.handles.axes1Panel);
        % Axes Buttons
        data.handles.playMicButton=uicontrol('Style', 'pushbutton','String','<html>Play<br/>Mic</html>','Units','norm','FontUnits','norm','FontSize',0.35,'HorizontalAlignment', 'left','Position',[.92 .86 .075 .08],'Parent',data.handles.axes1Panel,'Callback', @playMic);
        data.handles.playHeadButton=uicontrol('Style', 'pushbutton','String','<html>Play<br/>Head</html>','Units','norm','FontUnits','norm','FontSize',0.35,'HorizontalAlignment', 'left','Position',[.92 .64 .075 .08],'Parent',data.handles.axes1Panel,'Callback', @playHead);
        data.handles.trialTimeButton=uicontrol('Style', 'pushbutton','String','View trial timing','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.02 .02 .3 .06],'Parent',data.handles.axes1Panel,'Callback', @viewTime);
        data.handles.refTimeButton=uicontrol('Style', 'pushbutton','String','Change reference time','Units','norm','FontUnits','norm','FontSize',0.4,'HorizontalAlignment', 'left','Position',[.4 .02 .3 .06],'Parent',data.handles.axes1Panel,'Callback', @changeReference);
        data.handles.saveExitButton=uicontrol('Style', 'pushbutton','String','<html>Save &<br/>Exit</html>','Units','norm','FontUnits','norm','FontSize',0.35,'HorizontalAlignment', 'left','Position',[.92 .02 .075 .08],'Parent',data.handles.axes1Panel,'Callback', @saveExit);
        
        % Update GUI to current sub / trial
        updateSubj(data);       
        %updateSubj(data, 'sub-SAP04', 'ses-1', 'run-1', 'som', '10');       
             
        %data = data.handles.hfig.UserData;
        data = data.handles.hfig.UserData;
        set(data.handles.hfig,'userdata',data);
        
        
    case 'update'
        if isempty(hfig), hfig=gcf; end
        data=get(hfig,'userdata');
        set(data.handles.hfig,'userdata',data);
        
end

    function updateSettings(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');

    %set(data.handles.hfig,'userdata',data);
    end

    function saveFlags(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');

    %set(data.handles.hfig,'userdata',data);
    end

    function subDrop(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    subList = data.vars.subList;
    newSubIdx = get(data.handles.subDrop, 'Value');
    newSub = subList{newSubIdx};
    updateSubj(data, newSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, '1');
    data.vars.curSub = newSub;
    set(data.handles.hfig,'userdata',data);
    end

    function sessDrop(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    sessList = data.vars.sessList;
    newSessIdx = get(data.handles.sessDrop, 'Value');
    newSess = sessList{newSessIdx};
    updateSubj(data, data.vars.curSub, newSess, data.vars.curRun, data.vars.curTask, '1');
    data.vars.curSess = newSess;
    set(data.handles.hfig,'userdata',data);
    end

    function runDrop(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    runList = data.vars.runList;
    newRunIdx = get(data.handles.runDrop, 'Value');
    newRun = runList{newRunIdx};
    updateSubj(data, data.vars.curSub, data.vars.curSess, newRun, data.vars.curTask, '1');
    data.vars.curRun = newRun;
    set(data.handles.hfig,'userdata',data);
    end

    function taskDrop(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    taskList = data.vars.taskList;
    newTaskIdx = get(data.handles.taskDrop, 'Value');
    newTask = taskList{newTaskIdx};
    updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, newTask, '1');
    data.vars.curTask = newTask;
    set(data.handles.hfig,'userdata',data);
    end
    
    function trialDrop(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    newTrial = num2str(get(data.handles.trialDrop, 'Value'));
    updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, newTrial);
    data.vars.curTrial = newTrial;
    set(data.handles.hfig,'userdata',data);
    end

    function prevTrial(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    curTrial = str2num(data.vars.curTrial);
    prevTrial = num2str(curTrial - 1);
    trialList = data.vars.trialList;
    if curTrial == trialList(1)
        choice = questdlg('This is the first trial for this run, attempt to load previous run?', 'Change runs?', 'Yes', 'No', 'opts');
        switch choice
            case 'Yes'
                curRun = regexp(data.vars.curRun,'\d*','Match');
                runList = data.vars.runList;
                runIdx = find(runList == str2num(curRun));
                prevIdx = runIdx-1;
                if prevIdx < numel(runList) || prevIdx > numel(runList);
                    warning = msgbox('Previous run does not exist, consider changing session?')
                else
                    prevRun = runList(prevIdx);
                    taskList = data.vars.taskList;
                    updateSubj(data, data.vars.curSub, data.vars.curSess, prevRun, taskList{1}, '1') % maybe should load last trial of prev run
                    data.vars.curRun = prevRun;
                    data.vars.curTrial = prevTrial;
                end
                case 'No'
                    return 
        end
    else
        updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, num2str(prevTrial));
        data.vars.curTrial = prevTrial;
    end
   
    set(data.handles.hfig,'userdata',data);
    end
    
    function nextTrial(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');

    curTrial = str2num(data.vars.curTrial);
    nextTrial = num2str(curTrial + 1);
    trialList = data.vars.trialList;
    if curTrial == trialList(end)
        choice = questdlg('This is the last trial for this run, attempt to load next run?', 'Change runs?', 'Yes', 'No', 'opts');
        switch choice
            case 'Yes'
                curRun = regexp(data.vars.curRun,'\d*','Match');
                runList = data.vars.runList;
                runIdx = find(runList == str2num(curRun));
                nextIdx = runIdx+1;
                if nextIdx < numel(runList) || nextIdx > numel(runList);
                    warning = msgbox('Previous run does not exist, consider changing session?')
                else
                    nextRun = runList(nextIdx);
                    taskList = data.vars.taskList;
                    updateSubj(data, data.vars.curSub, data.vars.curSess, nextRun, taskList{1}, '1') % maybe should load last trial of prev run
                    data.vars.curRun = nextRun;
                    data.vars.curTrial = nextTrial;
                end
                case 'No'
                    return 
        end
    else
        updateSubj(data, data.vars.curSub, data.vars.curSess, data.vars.curRun, data.vars.curTask, num2str(nextTrial));
        data.vars.curTrial = nextTrial;
    end
   
    set(data.handles.hfig,'userdata',data);
    end

    function playMic(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');
    
    curTrial = data.vars.curTrial;
    micWav = data.vars.micWav;
    fs = data.vars.curTrialData(curTrial).fs;
    soundsc(micWav, fs);
    

    %set(data.handles.hfig,'userdata',data);
    end

    function playHead(ObjH, EventData)
    hfig=gcbf; if isempty(hfig), hfig=ObjH; while ~isequal(get(hfig,'type'),'figure'), hfig=get(hfig,'parent'); end; end
    data=get(hfig,'userdata');

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

    %set(data.handles.hfig,'userdata',data);
    end
    
    function updateSubj(data,varargin)
    % Helper function that updates the GUI based on current sub / trial 
    if numel(varargin) < 1
        init = 1;
    else
        init = 0;
        sub = varargin{1};
        sess = varargin{2};
        run = varargin{3};
        task = varargin{4};
        trial = varargin{5};
    end 
    if init % set values to first value in each droplist
        % update subjects
        subList = flvoice('import');
        set(data.handles.subDrop, 'String', subList, 'Value', 1);
        disp('Loading default data from root folder:')
        curSub = subList{get(data.handles.subDrop, 'Value')};
        data.vars.subList = subList;
        data.vars.curSub = curSub;
        
        % update sess
        sessList = flvoice('import', curSub);
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
        curTrialData = curInputData{1};
        % update trial
        trialList = (1:size(curTrialData,2));
        set(data.handles.trialDrop, 'String', trialList, 'Value', 1);
        curTrial = num2str(get(data.handles.trialDrop, 'Value'));
        curCond = curTrialData(curTrial).condLabel;
        set(data.handles.condVal, 'String', curCond);
        data.vars.trialList = trialList;
        data.vars.curTrial = curTrial;
        
        % update plots
        runIdx = get(data.handles.runDrop, 'Value');
        micWav = curTrialData(curTrial).s{1};
        micTime = (0+(0:numel(micWav)-1*1/curTrialData(curTrial).fs));
        data.handles.micPlot = plot(micTime,micWav, 'Parent', data.handles.micAxis);
        data.vars.micWav = micWav;
        data.vars.micTime = micTime;
        % update spectogram plots

        
    else % set values based on given inputs
        % update subjects
        subList = flvoice('import');
        subIdx = find(contains(subList,sub));
        set(data.handles.subDrop, 'String', subList, 'Value', subIdx);
        disp('Loading default data from root folder:')
        data.vars.subList = subList;
        data.vars.curSub = sub;
        
        % update sess
        sessList = flvoice('import', sub);
        sessIdx = find(contains(sessList,sess));
        set(data.handles.sessionDrop, 'String', sessList, 'Value', sessIdx);
        data.vars.sessList = sessList;
        data.vars.curSess = sess;
        
        % update run
        runList = flvoice('import', sub,sess);
        runIdx = find(contains(runList,run));
        set(data.handles.runDrop, 'String', runList, 'Value', runIdx);
        data.vars.runList = runList;
        data.vars.curRun = run;
        
        % update task
        taskList = flvoice('import', sub,sess,run);
        taskIdx = find(contains(taskList,task));
        set(data.handles.taskDrop, 'String', taskList, 'Value', taskIdx);
        data.vars.taskList = taskList;
        data.vars.curTask = task;
        
        % get trial data
        curInputData = flvoice_import(sub,sess,run,task,'input');
        curTrialData = curInputData{1};
        % update trial
        trialList = (1:size(curTrialData,2));
        trialIdx = find(trialList == str2num(trial)); % most likely unecessary but useful for futureproofing
        set(data.handles.trialDrop, 'String', trialList, 'Value', trialIdx);
        curCond = curTrialData(trial).condLabel;
        set(data.handles.condVal, 'String', curCond);
        data.vars.trialList = trialList;
        data.vars.curTrial = trial;
        
        % update mic plot
        micWav = curTrialData(str2num(trial)).s{1};
        micTime = (0+(0:numel(micWav)-1*1/curTrialData(str2num(trial)).fs));
        data.handles.micPlot = plot(micTime,micWav, 'Parent', data.handles.micAxis);
        data.vars.micWav = micWav;
        data.vars.micTime = micTime;
        % update spectogram plots
 
    end
        % save curr data
        data.vars.curTrialData = curTrialData;
        set(data.handles.hfig,'userdata',data);
    end 

end