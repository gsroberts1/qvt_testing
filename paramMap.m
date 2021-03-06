function varargout = paramMap(varargin)
% PARAMMAP MATLAB code for paramMap.fig
%   Allows for 3D interaction and visualization of 4D flow MRI-derived
%   hemodynamic parameters.
%
%   PARAMMAP, by itself, creates a new PARAMMAP or raises the existing
%   singleton*.
%
%   H = PARAMMAP returns the handle to a new PARAMMAP or the handle to
%   the existing singleton*.
%
%   PARAMMAP('CALLBACK',hObject,eventData,handles,...) calls the local
%   function named CALLBACK in PARAMMAP.M with the given input arguments.
%
%   PARAMMAP('Property','Value',...) creates a new PARAMMAP or raises the
%   existing singleton*.  Starting from the left, property value pairs are
%   applied to the GUI before paramMap_OpeningFcn gets called.  An
%   unrecognized property name or invalid value makes property application
%   stop.  All inputs are passed to paramMap_OpeningFcn via varargin.
%
%   *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%   instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% Edit the above text to modify the response to help paramMap
% Last Modified by GUIDE v2.5 23-Aug-2021 09:13:02

% Developed by Carson Hoffman, University of Wisconsin-Madison 2019
%   Used by: NONE (START FILE)
%   Dependencies: loadpcvipr.m, myupdatefcn.m


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @paramMap_OpeningFcn, ...
    'gui_OutputFcn',  @paramMap_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before paramMap is made visible.
function paramMap_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to paramMap (see VARARGIN)

% Choose default command line output for paramMap
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

set(handles.TextUpdate,'String','Load in a 4D Flow Dataset');

% --- Outputs from this function are returned to the command line.
function varargout = paramMap_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
set(hObject,'Visible','on');
set(handles.ParameterTool,'Position',[1 41 190 48]) %move to top left (WORK)
%set(handles.ParameterTool,'Position',[276 32 190 48]); %HOME


% --- Executes on button press in LoadData.
function LoadData_Callback(hObject, eventdata, handles)
% hObject    handle to LoadData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Choose default command line output for paramMap
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes paramMap wait for user response (see UIRESUME)
% uiwait(handles.ParameterTool);

% Create global namespace
global branchList Planes hfull p branchLabeled Ntxt nframes res matrix VENC
global directory AveAreaBranch LogPoints fullCData area_vol flowPerHeartCycle_vol
global PI_vol diam_vol maxVel_vol RI_vol flowPulsatile_vol timeres segment
global r timeMIPcrossection segment1 vTimeFrameave velMean_val versionNum
global dcm_obj fig hpatch hscatter Labeltxt cbar hDataTip SavePath
global MAGcrossection bnumMeanFlow bnumStdvFlow StdvFromMean
global VplanesAllx VplanesAlly VplanesAllz imageData caseFilePath

global area_valK diam_valK flowPerHeartCycle_valK maxVel_valK
global velMean_valK PI_valK RI_valK flowPulsatile_valK segmentFullK
global bnumMeanFlowK bnumStdvFlowK StdvFromMeanK SummaryNameK SavePathK
global AveAreaBranchK vesselsAnalyzed allNotes

% Initial Variables
hfull = handles;
versionNum = 'v1-2'; %paramMap Version
branchLabeled = 0; %used in cursor updatefunction
Ntxt = []; %used in cursor updatefunction
p = []; %used in cursor updatefunction
directory = uigetdir; %interactive directory selection
vesselsAnalyzed = {};
allNotes = cell(length(get(handles.NamePoint,'String')),1);

% Creates list of all .mat files in selected directory
d = dir([directory filesep '*.mat']);
fn = [{'Load New Case'},{d.name}];
[fileIndx,~] = listdlg('PromptString','Select a file:', ...
    'ListSize',[200 300],'SelectionMode','single','ListString',fn);

%%% Data Loading
if  fileIndx > 1  %if a pre-processed case is selected
    
    set(handles.TextUpdate,'String','Loading Preprocessed Data'); drawnow;
    caseFilePath = [directory filesep fn{fileIndx}];

    load(caseFilePath,'data_struct') %load data_struct
    load(caseFilePath,'Vel_Time_Res') %load data_struct
    load(caseFilePath,'data_structK') %load data_struct

    % This will be the name used for the Excel file
    finalFolder = regexp(directory,filesep,'split');
    SummaryName = fn{fileIndx};
    SummaryName = [finalFolder{end} '_' SummaryName(1:end-4)];

    % Makes directory if it does already exist (folder is time-stamped)
    warning off
    mkdir(directory,SummaryName);
    SavePath = [directory filesep SummaryName];

    % Create excel files save summary data
    col_header = ({'Vessel Label', 'Centerline Point', 'Notes',['Max Velocity < ' num2str(VENC) 'cm/s'], ...
        'Mean Flow ml/s','Pulsatility Index','Branch Number'});
    xlwrite([SavePath filesep 'SummaryParamTool.xls'],col_header,'Summary_Centerline','A1');
    xlwrite([SavePath filesep 'SummaryParamTool.xls'],get(handles.NamePoint,'String'),'Summary_Centerline','A2');
    
    % New Data Structure
    area_vol = data_struct.area_vol; %area of vessels
    diam_vol = data_struct.diam_vol; %diameter of vessels
    branchList = data_struct.branchList; %point locations/labelings
    flowPerHeartCycle_vol = data_struct.flowPerHeartCycle_vol; %TA flow
    maxVel_vol = data_struct.maxVel_vol; %TA max velocities
    velMean_val = data_struct.velMean_val; %TA mean velocities
    nframes = data_struct.nframes; %number of temporal cardiac frames
    matrix = data_struct.matrix; %image matrix size (pixels)
    res = data_struct.res; %image resolution (mm)
    timeres = data_struct.timeres; %temporal resolution (ms)
    VENC = data_struct.VENC;
    segment = data_struct.segment; %binary mask (angiogram)
    PI_vol = data_struct.PI_vol; %pulsatility index
    RI_vol = data_struct.RI_vol; %resistivity index
    flowPulsatile_vol = data_struct.flowPulsatile_vol; %TR flow
    r = data_struct.r; %radius of plane (plane size=(2*r)+1)
    timeMIPcrossection = data_struct.timeMIPcrossection; %complex diff.
    MAGcrossection = data_struct.MAGcrossection; %magnitude (in-plane)
    segment1 = data_struct.segment1; %cross-sectional plane masks
    vTimeFrameave = data_struct.vTimeFrameave; %velocity (in-plane)
    Planes = data_struct.Planes; %outer coordinates of plane
    bnumMeanFlow = data_struct.bnumMeanFlow; %mean flow along branches
    bnumStdvFlow = data_struct.bnumStdvFlow; %stdv flow of branches
    StdvFromMean = data_struct.StdvFromMean; %CoV along branches

    VplanesAllx = Vel_Time_Res.VplanesAllx; %TR vel planes (uninterped)
    VplanesAlly = Vel_Time_Res.VplanesAlly;
    VplanesAllz = Vel_Time_Res.VplanesAllz;
    
    
    SummaryNameK = [SummaryName(1:14) 'KMEANS' SummaryName(15:end)];
    mkdir(directory,SummaryNameK);
    SavePathK = [directory filesep SummaryNameK];

    % Create excel files save summary data
    xlwrite([SavePathK filesep 'SummaryParamTool.xls'],col_header,'Summary_Centerline','A1');
    xlwrite([SavePathK filesep 'SummaryParamTool.xls'],get(handles.NamePoint,'String'),'Summary_Centerline','A2');

    area_valK = data_structK.area_vol; %area of vessels
    diam_valK = data_structK.diam_vol; %diameter of vessels
    flowPerHeartCycle_valK = data_structK.flowPerHeartCycle_vol; %TA flow
    maxVel_valK = data_structK.maxVel_vol; %TA max velocities
    velMean_valK = data_structK.velMean_val; %TA mean velocities
    PI_valK = data_structK.PI_vol; %pulsatility index
    RI_valK = data_structK.RI_vol; %resistivity index
    flowPulsatile_valK = data_structK.flowPulsatile_vol; %TR flow
    segmentFullK = data_structK.segment1; %cross-sectional plane masks
    bnumMeanFlowK = data_structK.bnumMeanFlow; %mean flow along branches
    bnumStdvFlowK = data_structK.bnumStdvFlow; %stdv flow of branches
    StdvFromMeanK = data_structK.StdvFromMean; %CoV along branches
    
    
    set(handles.TextUpdate,'String','Loading Complete'); drawnow;
    pause(1)
    set(handles.TextUpdate,'String','Please Select Analysis Plane Location'); drawnow;

else
    %Load in pcvipr data from scratch
    [nframes,matrix,res,timeres,VENC,area_vol,diam_vol,flowPerHeartCycle_vol, ...
        maxVel_vol,PI_vol,RI_vol,flowPulsatile_vol,velMean_val, ...
        VplanesAllx,VplanesAlly,VplanesAllz,Planes,branchList,segment,r, ...
        timeMIPcrossection,segment1,vTimeFrameave,MAGcrossection, imageData, ...
        area_valK,diam_valK,flowPerHeartCycle_valK,maxVel_valK,PI_valK,RI_valK,flowPulsatile_valK,...
        velMean_valK,segmentFullK,bnumMeanFlowK,bnumStdvFlowK,StdvFromMeanK, ...
        bnumMeanFlow,bnumStdvFlow,StdvFromMean] ...
        = loadpcvipr(directory,handles);
    
    directory = uigetdir; %select saving dir 
    % Save all variables needed to run parametertool. This will be used
    % later to load in data faster instead of having to reload all data.
    % Save data_structure with time/version-stamped filename in 'directory'
    time = datestr(now);
    saveState = [time(1:2) time(4:6) time(10:11) '_' time(13:14) time(16:17) '_' versionNum];
    set(handles.TextUpdate,'String',['Saving Data as pcviprData_' saveState '.mat']); drawnow;
    
    data_struct = [];
    data_struct.directory = directory;
    data_struct.area_vol = area_vol;
    data_struct.diam_vol = diam_vol;
    data_struct.branchList = branchList;
    data_struct.flowPerHeartCycle_vol = flowPerHeartCycle_vol;
    data_struct.maxVel_vol = maxVel_vol;
    data_struct.velMean_val = velMean_val;
    data_struct.nframes = nframes;
    data_struct.matrix = matrix;
    data_struct.res = res;
    data_struct.timeres = timeres;
    data_struct.VENC = VENC;
    data_struct.segment = segment;
    data_struct.PI_vol = PI_vol;
    data_struct.RI_vol = RI_vol;
    data_struct.flowPulsatile_vol = flowPulsatile_vol;
    data_struct.r = r;
    data_struct.timeMIPcrossection = timeMIPcrossection;
    data_struct.MAGcrossection = MAGcrossection;
    data_struct.segment1 = segment1;
    data_struct.vTimeFrameave = vTimeFrameave;
    data_struct.Planes = Planes;
    data_struct.bnumMeanFlow = bnumMeanFlow;
    data_struct.bnumStdvFlow = bnumStdvFlow;
    data_struct.StdvFromMean = StdvFromMean;
    
    Vel_Time_Res.VplanesAllx = VplanesAllx; %TR vel planes (uninterped)
    Vel_Time_Res.VplanesAlly = VplanesAlly;
    Vel_Time_Res.VplanesAllz = VplanesAllz;
    
        
    data_structK = [];
    data_structK.area_vol = area_valK;
    data_structK.diam_vol = diam_valK;
    data_structK.flowPerHeartCycle_vol = flowPerHeartCycle_valK;
    data_structK.maxVel_vol = maxVel_valK;
    data_structK.velMean_val = velMean_valK;
    data_structK.PI_vol = PI_valK;
    data_structK.RI_vol = RI_valK;
    data_structK.flowPulsatile_vol = flowPulsatile_valK;
    data_structK.segment1 = segmentFullK;
    data_structK.bnumMeanFlow = bnumMeanFlowK;
    data_structK.bnumStdvFlow = bnumStdvFlowK;
    data_structK.StdvFromMean = StdvFromMeanK;
    
    % Saves processed data in same location as pcvipr.mat files
    caseFilePath = fullfile(directory,['pcviprData_' saveState '.mat']);
    save(caseFilePath,'data_struct','data_structK','Vel_Time_Res','imageData')
    
    % This will be the name used for the Excel file
    finalFolder = regexp(directory,filesep,'split');
    SummaryName = [finalFolder{end} '_pcviprData_' saveState];
    warning off
    mkdir(directory,SummaryName); %makes directory if it already exists
    
    % Where to save data images and excel summary files
    SavePath = [directory filesep SummaryName];
        
    % Create excel files save summary data
    col_header = ({'Vessel Label', 'Centerline Point', 'Notes',['Max Velocity < ' num2str(VENC) 'cm/s'], ...
        'Mean Flow ml/s','Pulsatility Index','Branch Label'});
    xlwrite([SavePath filesep 'SummaryParamTool.xls'],col_header,'Summary_Centerline','A1');
    xlwrite([SavePath filesep 'SummaryParamTool.xls'],get(handles.NamePoint,'String'),'Summary_Centerline','A2');

    % Save a different folder for the K-means analysis
    finalFolder = regexp(directory,filesep,'split');
    SummaryNameK = [finalFolder{end} '_pcviprDataKMEANS_' saveState];
    warning off
    mkdir(directory,SummaryNameK); %makes directory if it already exists
    
    % Where to save data images and excel summary files
    SavePathK = [directory filesep SummaryNameK];
        
    % Create excel files save summary data
    xlwrite([SavePathK filesep 'SummaryParamTool.xls'],col_header,'Summary_Centerline','A1');
    xlwrite([SavePathK filesep 'SummaryParamTool.xls'],get(handles.NamePoint,'String'),'Summary_Centerline','A2');
    
    
    % export gating stats 
    gating_stats = {'Median RR (ms)'; 'HR (bpm)';'Values within expected RR (%)'};
    val = [imageData.gating_rr, imageData.gating_hr, imageData.gating_var]';
    gating_table = table(gating_stats,val);
    writetable(gating_table,[SavePath filesep 'gating_stats.csv'],'Delimiter',',');
    
    
    set(handles.TextUpdate,'String','Data Successfully Saved'); drawnow;
    pause(1)
    set(handles.TextUpdate,'String','Please Select Analysis Plane Location'); drawnow;
end

%%% Plotting 3D Interactive Display
set(handles.parameter_choice,'Value',3); %set parameter to flow as default
set(handles.Transparent, 'Value',0);
set(handles.AreaThreshSlide, 'Value',0);

% Initialize visualization
fig = figure(1); cla
set(fig,'Position',[963 374 946 731]); %WORK
%set(fig,'Position',[2366 295 904 683]); %HOME

hpatch = patch(isosurface(permute(segment,[2 1 3]),0.5),'FaceAlpha',0); %bw iso angiogram
reducepatch(hpatch,0.7);
set(hpatch,'FaceColor','white','EdgeColor', 'none','PickableParts','none');
set(gcf,'color','black');
axis off tight
view([1 0 0]);
axis vis3d
daspect([1 1 1])
set(gca,'zdir','reverse')
camlight headlight;
lighting gouraud
colorbar('off')

% Turn on data cursormode within the figure
dcm_obj = datacursormode(fig); %create dataCursorManager object
datacursormode on;
dcm_obj.DisplayStyle = 'window';
set(handles.CBARmin,'String','min')
set(handles.CBARmax,'String','max')
branchLabeled = 0;

% This will be used in the update function for cursor text
Labeltxt = {'Flow: ',  ' mL/s ';'Average: ',' mL/s '};
cdata = flowPerHeartCycle_valK;
hold on
dotSize = 25;
hscatter = scatter3(branchList(:,1),branchList(:,2),branchList(:,3),dotSize,cdata,'filled');
hold off

caxis([min(cdata) max(cdata)]);
cbar = colorbar;
caxis([0 0.8*max(flowPerHeartCycle_valK(:))])
set(get(cbar,'xlabel'),'string','Flow (mL/s)','fontsize',16,'Color','white');
set(cbar,'FontSize',16,'color','white');
ax = gca;
xlim([ax.XLim(1)-r ax.XLim(2)+r]) %buffer with extra space for planes
ylim([ax.YLim(1)-r ax.YLim(2)+r])
zlim([ax.ZLim(1)-r ax.ZLim(2)+r])

% Initialize visualization of tangent planes
hold on
p = fill3(Planes(1,:,1)',Planes(1,:,2)',Planes(1,:,3)',[1 0 0], ...
    'EdgeColor',[1 0 0],'FaceAlpha',0.3,'PickableParts','none', ...
    'Parent', fig.CurrentAxes); %fill3(pty',ptx',ptz','r') for isosurface
hold off

% Update string (undocumentedmatlab.com/articles/controlling-plot-data-tips)
set(dcm_obj,'UpdateFcn',@myupdatefcn_all); %update dataCursor w/ cust. fcn
hDataTip = dcm_obj.createDatatip(hscatter);

% Convert toolbar to old style and add hot keys
fig.CurrentAxes.Toolbar = [];
addToolbarExplorationButtons(fig)
updateDataCursors(dcm_obj)

% Calculate average area per branch
AveAreaBranch = size(max(branchList(:,4)),1);
for n = 1:max(branchList(:,4))
    Btemp = branchList(:,4)==n;
    AveAreaBranch(n,1) = mean(area_vol(Btemp)); %mean area of branch
end

AveAreaBranchK = size(max(branchList(:,4)),1);
for n = 1:max(branchList(:,4))
    Btemp = branchList(:,4)==n;
    AveAreaBranchK(n,1) = mean(area_valK(Btemp)); %mean area of branch
end

LogPoints = true(size(branchList,1),1); %logical array of 1s for areaThresh
fullCData = flowPerHeartCycle_valK; %initialize fullCData color as flow

steps = [1./(nframes-1) 10./(nframes-1)]; %set so one 'slide' moves to the next slice exactly
set(handles.VcrossTRslider,'SliderStep',steps);


% --- Executes on selection change in parameter_choice.
function parameter_choice_Callback(hObject, eventdata, handles)
global hscatter area_valK RI_valK PI_valK dcm_obj fig velMean_valK
global flowPerHeartCycle_valK fullCData maxVel_valK cbar Labeltxt diam_valK
global StdvFromMeanK

% Get parameter option
val = get(handles.parameter_choice, 'Value');
str = get(handles.parameter_choice, 'String');
switch str{val}
    case 'Area'
        % This will be used in the update function for cursor text
        Labeltxt = {'Area: ',  ' cm^2';'Average: ',' cm^2'};
        hscatter.CData = area_valK; %update colors on centerline display
        caxis(fig.CurrentAxes,[0 1.5*mean(hscatter.CData)])
        cl = caxis(fig.CurrentAxes);
        set(get(cbar,'xlabel'),'string','Area (cm^2)','fontsize',16,'Color','white');
        set(cbar,'FontSize',16,'color','white');
        fullCData = area_valK;
    case 'Ratio of Areas'
        Labeltxt = {'Area Ratio: ',  ' ';'Average: ',' '};
        hscatter.CData = diam_valK;
        caxis(fig.CurrentAxes,[min(hscatter.CData) max(hscatter.CData)]);
        cl = caxis(fig.CurrentAxes);
        set(get(cbar,'xlabel'),'string','Area Ratio','fontsize',16,'Color','white');
        set(cbar,'FontSize',16,'color','white');
        fullCData = diam_valK;
    case 'Total Flow'
        Labeltxt = {'Flow: ',  ' mL/s';'Average: ',' mL/s'};
        hscatter.CData = flowPerHeartCycle_valK;
        caxis(fig.CurrentAxes,[0 0.8*max(flowPerHeartCycle_valK(:))])
        cl = caxis(fig.CurrentAxes);
        set(get(cbar,'xlabel'),'string','Flow (mL/s)','fontsize',16,'Color','white');
        set(cbar,'FontSize',16,'color','white');
        fullCData = flowPerHeartCycle_valK;
    case 'Maximum Velocity '
        Labeltxt = {'Max Velocity: ',  ' cm/s';'Average: ',' cm/s'};
        hscatter.CData = maxVel_valK;
        caxis(fig.CurrentAxes,[min(hscatter.CData) max(hscatter.CData)])
        cl = caxis(fig.CurrentAxes);
        set(get(cbar,'xlabel'),'string','Max Velocity (cm/s)','fontsize',16,'Color','white');
        set(cbar,'FontSize',16,'color','white');
        fullCData = maxVel_valK;
    case 'Mean Velocity'
        Labeltxt = {'Mean Velocity: ',  ' cm/s';'Average: ',' cm/s'};
        hscatter.CData = velMean_valK;
        caxis(fig.CurrentAxes,[min(hscatter.CData) max(hscatter.CData)])
        cl = caxis(fig.CurrentAxes);
        set(get(cbar,'xlabel'),'string','Mean Velocity (cm/s)','fontsize',16,'Color','white');
        set(cbar,'FontSize',16,'color','white');
        fullCData = velMean_valK;
    case 'Flow Consistency'
        Labeltxt = {'Flow Consistency Metric: ',  ' ';'Stdv from Mean: ',' '};
        hscatter.CData = StdvFromMeanK;
        caxis(fig.CurrentAxes,[0 4])
        cl = caxis(fig.CurrentAxes);
        set(get(cbar,'xlabel'),'string','Flow Consistency Metric','fontsize',16,'Color','white');
        set(cbar,'FontSize',16,'color','white');
        fullCData = StdvFromMeanK;
    case 'Resistance Index'
        Labeltxt = {'Resistance Index: ',  ' ';'Average: ',' '};
        hscatter.CData = RI_valK;
        caxis(fig.CurrentAxes,[-0.5 1])
        cl = caxis(fig.CurrentAxes);
        set(get(cbar,'xlabel'),'string','Resistance Index','fontsize',16,'Color','white');
        set(cbar,'FontSize',16,'color','white');
        fullCData = RI_valK;
    case str{val}
        Labeltxt = {'Pulsatility Index: ',  ' ';'Average: ',' '};
        hscatter.CData = PI_valK;
        caxis(fig.CurrentAxes,[0 2])
        cl = caxis(fig.CurrentAxes);
        set(get(cbar,'xlabel'),'string','Pulsatility Index','fontsize',16,'Color','white');
        set(cbar,'FontSize',16,'color','white');
        fullCData = PI_valK;
end

set(handles.CBARmin,'String',num2str(cl(1)))
set(handles.CBARmax,'String',num2str(cl(2)))
set(handles.CBARmin,'Value',cl(1))
set(handles.CBARmax,'Value',cl(2))
updateDataCursors(dcm_obj)

% --- Executes during object creation, after setting all properties.
function parameter_choice_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function plot_flowWaveform_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function Transparent_Callback(hObject, eventdata, handles)
global hpatch Sval

Sval = get(hObject,'Value');
set(hpatch,'FaceAlpha',Sval);

% --- Executes during object creation, after setting all properties.
function Transparent_CreateFcn(hObject, eventdata, handles)
global Sval

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject, 'Min', 0);
set(hObject, 'Max', 1);
set(hObject,'Value',0);
Sval = get(hObject,'Value');


function CBARmin_Callback(hObject, eventdata, handles)
global fig

maxV = str2double(get(handles.CBARmax,'String'));
minV = str2double(get(handles.CBARmin,'String'));
caxis(fig.CurrentAxes,[minV maxV])

% --- Executes during object creation, after setting all properties.
function CBARmin_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function CBARmax_Callback(hObject, eventdata, handles)
global fig

maxV =   str2double(get(handles.CBARmax,'String'));
minV =   str2double(get(handles.CBARmin,'String'));
caxis(fig.CurrentAxes,[minV maxV])

% --- Executes during object creation, after setting all properties.
function CBARmax_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in CBARselection.
function CBARselection_Callback(hObject, eventdata, handles)
global fig

contents = cellstr(get(hObject,'String')); %turn color options to cells
colormap(fig.Children(end),contents{get(hObject,'Value')})

% --- Executes during object creation, after setting all properties.
function CBARselection_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in NamePoint.
function NamePoint_Callback(hObject, eventdata, handles)
global PointLabel dcm_obj vesselsAnalyzed

contents = cellstr(get(handles.NamePoint,'String'));
PointLabel = contents{get(handles.NamePoint,'Value')};
if sum(contains(vesselsAnalyzed,PointLabel))
    set(handles.NamePoint,'ForegroundColor',[0.6 0.6 0.6]);
else
    set(handles.NamePoint,'ForegroundColor',[0 0 0]);
end 
updateDataCursors(dcm_obj)

% --- Executes during object creation, after setting all properties.
function NamePoint_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global PointLabel

contents = cellstr(get(hObject,'String'));
PointLabel = contents{get(hObject,'Value')};


% --- Executes on button press in SavePoint.
function SavePoint_Callback(hObject, eventdata, handles)
global PointLabel nframes VENC timeres branchList timeMIPcrossection area_vol
global flowPerHeartCycle_vol PI_vol diam_vol maxVel_vol RI_vol flowPulsatile_vol
global vTimeFrameave velMean_val dcm_obj fig segment1 SavePath MAGcrossection

global area_valK diam_valK flowPerHeartCycle_valK maxVel_valK SavePathK
global velMean_valK PI_valK RI_valK flowPulsatile_valK segmentFullK
global vesselsAnalyzed allNotes

set(handles.TextUpdate,'String','Saving Data');drawnow;
SaveRow =  sprintf('B%i',get(handles.NamePoint,'Value')+1); %match excel row to vessel name

info_struct = getCursorInfo(dcm_obj);
ptList = [info_struct.Position];
ptList = reshape(ptList,[3,numel(ptList)/3])';
pindex = zeros(size(ptList,1),1);

vesselsAnalyzed{end+1} = PointLabel;

for n = 1:size(ptList,1)
    xIdx = find(branchList(:,1) == ptList(n,1));
    yIdx = find(branchList(xIdx,2) == ptList(n,2));
    zIdx = find(branchList(xIdx(yIdx),3) == ptList(n,3));
    pindex(n) = xIdx(yIdx(zIdx));
end

% Gives associated branch number if full branch point is wanted
bnum = branchList(pindex,4);
Logical_branch = branchList(:,4) ~= bnum;

% OUTPUT +/- points use this
index_range = pindex-2:pindex+2;

%removes outliers and points from other branches
index_range(index_range<1) = [];
index_range(index_range>size(branchList,1)) = [];
index_range(Logical_branch(index_range)) = [];

%%%%%%% SLIDING THRESHOLD %%%%%%%
% Time-averaged data
area = area_vol(index_range);
area = [area;mean(area);std(area)];
diam = diam_vol(index_range);
diam = [diam;mean(diam);std(diam)];
flowPerHeartCycle = flowPerHeartCycle_vol(index_range);
flowPerHeartCycle = [flowPerHeartCycle;mean(flowPerHeartCycle);std(flowPerHeartCycle)];
PI = PI_vol(index_range) ;
PI = [PI;mean(PI);std(PI)];
maxVel = maxVel_vol(index_range);
maxVel = [maxVel;mean(maxVel);std(maxVel)];
meanVel = velMean_val(index_range);
meanVel = [meanVel;mean(meanVel);std(meanVel)];
RI = RI_vol(index_range);
RI = [RI;mean(RI);std(RI)];

% Time-resolved flow
flowPulsatile = flowPulsatile_vol(index_range,:);
flowPulsatile = [flowPulsatile;mean(flowPulsatile,1);std(flowPulsatile,1)];

% Collect branch name and Labels
savename = PointLabel; %name of current vessel
warning('off','MATLAB:xlswrite:AddSheet') %shut off excel sheet warning
Labels = zeros(1,length(index_range));

% Current and neighboring centerline points along branch
for n = 1:length(index_range)
    branchActual = branchList(branchList(:,4) == bnum,5);
    Labels(n) = find(branchList(index_range(n),5)==branchActual)-1;
end
Labels = [Labels,0,0]; %neighboring CL points (including current)
CLpoint = find(branchList(pindex,5)==branchActual)-1; %current CL point

% Check if Max Velocity of current 5 planes is less than VENC
if sum(maxVel>VENC*0.1)==0
    MaxVel = 'YES';
else
    MaxVel = 'NO';
end

if isempty(allNotes{get(handles.NamePoint,'Value')})
    Notes = get(handles.NoteBox,'String'); %get any notes from notebox
    SummaryInfo = {CLpoint,Notes,MaxVel,flowPerHeartCycle(end-1),PI(end-1),bnum};
    xlwrite([SavePath filesep 'SummaryParamTool.xls'],SummaryInfo,'Summary_Centerline',SaveRow);
    set(handles.TextUpdate,'String','Saving Data.');drawnow;
end 

% save time-averaged
col_header = ({'Point along Vessel', 'Area (cm^2)', 'Area Ratio', 'Max Velocity (cm/s)',...
    'Mean Velocity (cm/s)','Average Flow(mL/s)','Pulsatility Index','Resistivity Index'});
time_avg = vertcat(col_header,num2cell(real(horzcat(Labels',...
    area,diam,maxVel,meanVel,flowPerHeartCycle,PI,RI))));
time_avg{end-1,1} = 'Mean';
time_avg{end,1} = 'Standard Deviation';
xlwrite([SavePath filesep 'SummaryParamTool.xls'],time_avg,[savename '_T_averaged']);
set(handles.TextUpdate,'String','Saving Data..');drawnow;

% save time-resolved
spaces = repmat({''},1,nframes-1);
col_header2 = ({'Cardiac Time (ms)'});
col_header3 = horzcat({'Point along Vessel','Flow (mL/s)'},spaces);
col_header2 = horzcat(col_header2, num2cell(real(timeres/1000*linspace(1,nframes,nframes))));
time_resolve = vertcat(col_header2, col_header3, num2cell(real(horzcat(Labels',flowPulsatile))));
time_resolve{end-1,1} = 'Mean';
time_resolve{end,1} = 'Standard Deviation';
xlwrite([SavePath filesep 'SummaryParamTool.xls'],time_resolve,[savename '_T_resolved']);
set(handles.TextUpdate,'String','Saving Data...');drawnow;

% Get the dimensions of the sides of the slices created
imdim = sqrt(size(segment1,2));

% Get the cross sections for all points for branch
BranchSlice = segment1(index_range,:); %Restricts for branch edges
cdSlice = timeMIPcrossection(index_range,:);
velSlice = vTimeFrameave(index_range,:);
magSlice = MAGcrossection(index_range,:);

subL = size(BranchSlice,1);
f1 = figure('Position',[100,100,700,700],'Visible','off');
FinalImage = zeros(imdim,imdim,1,3*subL);
temp = 1;

%Put all images into a single image for saving cross sectional data
for q = 1:subL
    % Create some images of the cross section that is used
    CDcross = cdSlice(q,:);
    CDcross = reshape(CDcross,imdim,imdim)./max(CDcross);
    Vcross = velSlice(q,:);
    Vcross = reshape(Vcross,imdim,imdim)./max(Vcross);
    Magcross = magSlice(q,:);
    Magcross = reshape(Magcross,imdim,imdim)./max(Magcross);
    Maskcross = BranchSlice(q,:);
    Maskcross = reshape(Maskcross,imdim,imdim);
    
    % Put all images into slices
    FinalImage(:,:,1,temp) = Magcross;
    FinalImage(:,:,1,temp+1) = CDcross;
    FinalImage(:,:,1,temp+2) = Vcross;
    FinalImage(:,:,1,temp+3) = Maskcross;
    temp = temp+4;
end
subplot('position', [0 0 1 1])
montage(FinalImage, 'Size', [subL 4]);
saveas(f1,[ SavePath filesep savename '_Slicesview.jpg'])
close(f1)
set(handles.TextUpdate,'String','Saving Data....');drawnow;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%% KMEANS %%%%%%%%%%%%%%
% Time-averaged data
area = area_valK(index_range);
area = [area;mean(area);std(area)];
diam = diam_valK(index_range);
diam = [diam;mean(diam);std(diam)];
flowPerHeartCycle = flowPerHeartCycle_valK(index_range);
flowPerHeartCycle = [flowPerHeartCycle;mean(flowPerHeartCycle);std(flowPerHeartCycle)];
PI = PI_valK(index_range) ;
PI = [PI;mean(PI);std(PI)];
maxVel = maxVel_valK(index_range);
maxVel = [maxVel;mean(maxVel);std(maxVel)];
meanVel = velMean_valK(index_range);
meanVel = [meanVel;mean(meanVel);std(meanVel)];
RI = RI_valK(index_range);
RI = [RI;mean(RI);std(RI)];

% Time-resolved flow
flowPulsatile = flowPulsatile_valK(index_range,:);
flowPulsatile = [flowPulsatile;mean(flowPulsatile,1);std(flowPulsatile,1)];

% Collect branch name and Labels
savename = PointLabel; %name of current vessel
warning('off','MATLAB:xlswrite:AddSheet') %shut off excel sheet warning
Labels = zeros(1,length(index_range));

% Current and neighboring centerline points along branch
for n = 1:length(index_range)
    branchActual = branchList(branchList(:,4) == bnum,5);
    Labels(n) = find(branchList(index_range(n),5)==branchActual)-1;
end
Labels = [Labels,0,0]; %neighboring CL points (including current)
CLpoint = find(branchList(pindex,5)==branchActual)-1; %current CL point

% Check if Max Velocity of current 5 planes is less than VENC
if sum(maxVel>VENC*0.1)==0
    MaxVel = 'YES';
else
    MaxVel = 'NO';
end

if isempty(allNotes{get(handles.NamePoint,'Value')})
    Notes = get(handles.NoteBox,'String'); %get any notes from notebox
    SummaryInfo = {CLpoint,Notes,MaxVel,flowPerHeartCycle(end-1),PI(end-1),bnum};
    xlwrite([SavePathK filesep 'SummaryParamTool.xls'],SummaryInfo,'Summary_Centerline',SaveRow);
    set(handles.TextUpdate,'String','Saving Data.....');drawnow;
end 

% save time-averaged
col_header = ({'Point along Vessel', 'Area (cm^2)', 'Area Ratio', 'Max Velocity (cm/s)',...
    'Mean Velocity (cm/s)','Average Flow(mL/s)','Pulsatility Index','Resistivity Index'});
time_avg = vertcat(col_header,num2cell(real(horzcat(Labels',...
    area,diam,maxVel,meanVel,flowPerHeartCycle,PI,RI))));
time_avg{end-1,1} = 'Mean';
time_avg{end,1} = 'Standard Deviation';
xlwrite([SavePathK filesep 'SummaryParamTool.xls'],time_avg,[savename '_T_averaged']);
set(handles.TextUpdate,'String','Saving Data......');drawnow;

% save time-resolved
spaces = repmat({''},1,nframes-1);
col_header2 = ({'Cardiac Time (ms)'});
col_header3 = horzcat({'Point along Vessel','Flow (mL/s)'},spaces);
col_header2 = horzcat(col_header2, num2cell(real(timeres/1000*linspace(1,nframes,nframes))));
time_resolve = vertcat(col_header2, col_header3, num2cell(real(horzcat(Labels',flowPulsatile))));
time_resolve{end-1,1} = 'Mean';
time_resolve{end,1} = 'Standard Deviation';
xlwrite([SavePathK filesep 'SummaryParamTool.xls'],time_resolve,[savename '_T_resolved']);
set(handles.TextUpdate,'String','Saving Data.......');drawnow;

% Save: interactive window, main GUI , and cross-section images as montage
fig.Color = 'black';
fig.InvertHardcopy = 'off';
img = getframe(fig);
imwrite(img.cdata, [ SavePathK filesep savename '_3dview.jpg']);

fig2 = handles.ParameterTool;
fig2.Color = [0.94,0.94,0.94];
fig2.InvertHardcopy = 'off';
saveas(fig2,[ SavePathK filesep savename '_GUIview.jpg'])
set(handles.TextUpdate,'String','Saving Data........');drawnow;

% Get the dimensions of the sides of the slices created
imdim = sqrt(size(segmentFullK,2));

% Get the cross sections for all points for branch
BranchSlice = segmentFullK(index_range,:); %Restricts for branch edges
cdSlice = timeMIPcrossection(index_range,:);
velSlice = vTimeFrameave(index_range,:);
magSlice = MAGcrossection(index_range,:);

subL = size(BranchSlice,1);
f1 = figure('Position',[100,100,700,700],'Visible','off');
FinalImage = zeros(imdim,imdim,1,4*subL);
temp = 1;

%Put all images into a single image for saving cross sectional data
for q = 1:subL
    % Create some images of the cross section that is used
    CDcross = cdSlice(q,:);
    CDcross = reshape(CDcross,imdim,imdim)./max(CDcross);
    Vcross = velSlice(q,:);
    Vcross = reshape(Vcross,imdim,imdim)./max(Vcross);
    Magcross = magSlice(q,:);
    Magcross = reshape(Magcross,imdim,imdim)./max(Magcross);
    Maskcross = BranchSlice(q,:);
    Maskcross = reshape(Maskcross,imdim,imdim);
    
    % Put all images into slices
    FinalImage(:,:,1,temp) = Magcross;
    FinalImage(:,:,1,temp+1) = CDcross;
    FinalImage(:,:,1,temp+2) = Vcross;
    FinalImage(:,:,1,temp+3) = Maskcross;
    temp = temp+4;
end
subplot('position', [0 0 1 1])
montage(FinalImage, 'Size', [subL 4]);
saveas(f1,[ SavePathK filesep savename '_Slicesview.jpg'])
close(f1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set(handles.NoteBox,'String',' ');
set(handles.TextUpdate,'String','Please select a new point for analysis');drawnow;
NamePoint_Callback(hObject, eventdata, handles)


% --- NoteBox_Callback
function NoteBox_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function NoteBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SubmitNote.
function SubmitNote_Callback(hObject, eventdata, handles)
global SavePath SavePathK allNotes

set(handles.TextUpdate,'String','Saving Note for Current Vessel');drawnow;
SaveLoc =  sprintf('C%i',get(handles.NamePoint,'Value')+1);
Notes = {get(handles.NoteBox,'String')}; %get any notes from notebox
allNotes(get(handles.NamePoint,'Value')) = Notes;
xlwrite([SavePath filesep 'SummaryParamTool.xls'],Notes,'Summary_Centerline',SaveLoc);
xlwrite([SavePathK filesep 'SummaryParamTool.xls'],Notes,'Summary_Centerline',SaveLoc);
set(handles.NoteBox,'String',' ');
set(handles.TextUpdate,'String','Done Saving Note');drawnow;

% --- Executes on button press in AxialView.
function AxialView_Callback(hObject, eventdata, handles)
global fig
view(fig.CurrentAxes,[180,90])


% --- Executes on button press in SagittalView.
function SagittalView_Callback(hObject, eventdata, handles)
global fig
view(fig.CurrentAxes,[180,0])


% --- Executes on button press in CoronalView.
function CoronalView_Callback(hObject, eventdata, handles)
global fig
view(fig.CurrentAxes,[90,0])


% --- Executes on slider movement.
function AreaThreshSlide_Callback(hObject, eventdata, handles)
global LogPoints area_valK branchList hscatter AveAreaBranchK PI_valK RI_valK
global velMean_valK diam_valK maxVel_valK flowPerHeartCycle_valK StdvFromMeanK

LogPoints = find(AveAreaBranchK>max(AveAreaBranchK)*get(hObject,'Value')*.15);
LogPoints = ismember(branchList(:,4),LogPoints);

if get(handles.InvertArea,'Value') == 0
    hscatter.XData = branchList(LogPoints,1);
    hscatter.YData = branchList(LogPoints,2);
    hscatter.ZData = branchList(LogPoints,3);
    
    val = get(handles.parameter_choice, 'Value');
    str = get(handles.parameter_choice, 'String');
    switch str{val}
        case 'Area'
            hscatter.CData = area_valK(LogPoints);
        case 'Ratio of Areas'
            hscatter.CData = diam_valK(LogPoints);
        case 'Total Flow'
            hscatter.CData = flowPerHeartCycle_valK(LogPoints);
        case 'Maximum Velocity '
            hscatter.CData = maxVel_valK(LogPoints);
        case 'Mean Velocity'
            hscatter.CData = velMean_valK(LogPoints);
        case 'Flow Consistency'
            hscatter.CData = StdvFromMeanK(LogPoints);
        case 'Resistance Index'
            hscatter.CData = RI_valK(LogPoints);
        case str{val}
            hscatter.CData = PI_valK(LogPoints);
    end
else
    hscatter.XData = branchList(~LogPoints,1);
    hscatter.YData = branchList(~LogPoints,2);
    hscatter.ZData = branchList(~LogPoints,3);
    
    val = get(handles.parameter_choice, 'Value');
    str = get(handles.parameter_choice, 'String');
    switch str{val}
        case 'Area'
            hscatter.CData = area_valK(~LogPoints);
        case 'Ratio of Areas'
            hscatter.CData = diam_valK(~LogPoints);
        case 'Total Flow'
            hscatter.CData = flowPerHeartCycle_valK(~LogPoints);
        case 'Maximum Velocity '
            hscatter.CData = maxVel_valK(~LogPoints);
        case 'Mean Velocity'
            hscatter.CData = velMean_valK(~LogPoints);
        case 'Flow Consistency'
            hscatter.CData = StdvFromMeanK(LogPoints);
        case 'Resistance Index'
            hscatter.CData = RI_valK(~LogPoints);
        case str{val}
            hscatter.CData = PI_valK(~LogPoints);
    end
end


% --- Executes during object creation, after setting all properties.
function AreaThreshSlide_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function clWidthSlider_Callback(hObject, eventdata, handles)
global hscatter 
set(hscatter,'SizeData',get(hObject,'Value'));


% --- Executes during object creation, after setting all properties.
function clWidthSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in VisualTool.
function VisualTool_Callback(hObject, eventdata, handles)
global Planes branchList segment caseFilePath res 
set(handles.TextUpdate,'String','Opening Visual Tool'); drawnow;
fourDvis(Planes,branchList,segment,caseFilePath,res);
uiwait;
set(handles.TextUpdate,'String','Visual Tool Closed'); drawnow;


% --- Executes on button press in InvertArea.
function InvertArea_Callback(hObject, eventdata, handles)
% hObject    handle to InvertArea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of InvertArea
global LogPoints area_valK branchList hscatter PI_valK RI_valK velMean_valK
global diam_valK maxVel_valK flowPerHeartCycle_valK StdvFromMeanK

% Capable of inverting areaThresh (keep vessels OUTSIDE/INSIDE areaThresh)
OnOff = get(hObject,'Value'); %on off switch
if OnOff == 0 %if turned off (default),
    hscatter.XData = branchList(LogPoints,1); %plot angio w/in areaThresh
    hscatter.YData = branchList(LogPoints,2);
    hscatter.ZData = branchList(LogPoints,3);
    
    val = get(handles.parameter_choice, 'Value');
    str = get(handles.parameter_choice, 'String');
    switch str{val} %plot centerlines w/in areaThresh
        case 'Area'
            hscatter.CData = area_valK(LogPoints);
        case 'Ratio of Areas'
            hscatter.CData = diam_valK(LogPoints);
        case 'Total Flow'
            hscatter.CData = flowPerHeartCycle_valK(LogPoints);
        case 'Maximum Velocity '
            hscatter.CData = maxVel_valK(LogPoints);
        case 'Mean Velocity'
            hscatter.CData = velMean_valK(LogPoints);
        case 'Flow Consistency'
            hscatter.CData = StdvFromMeanK(LogPoints);
        case 'Resistance Index'
            hscatter.CData = RI_valK(LogPoints);
        case str{val}
            hscatter.CData = PI_valK(LogPoints);
    end
else %if invert is turned on, PLOT DATA POINTS OUTSIDE AREA THRESHOLD
    hscatter.XData = branchList(~LogPoints,1);
    hscatter.YData = branchList(~LogPoints,2);
    hscatter.ZData = branchList(~LogPoints,3);
    
    val = get(handles.parameter_choice, 'Value');
    str = get(handles.parameter_choice, 'String');
    switch str{val}
        case 'Area'
            hscatter.CData = area_valK(~LogPoints);
        case 'Ratio of Areas'
            hscatter.CData = diam_valK(~LogPoints);
        case 'Total Flow'
            hscatter.CData = flowPerHeartCycle_valK(~LogPoints);
        case 'Maximum Velocity '
            hscatter.CData = maxVel_valK(~LogPoints);
        case 'Mean Velocity'
            hscatter.CData = velMean_valK(~LogPoints);
        case 'Flow Consistency'
            hscatter.CData = StdvFromMeanK(LogPoints);
        case 'Resistance Index'
            hscatter.CData = RI_valK(~LogPoints);
        case str{val}
            hscatter.CData = PI_valK(~LogPoints);
    end
end


% --- Executes on slider movement.
function VcrossTRslider_Callback(hObject, eventdata, handles)
updateVcrossTR(handles)


% --- Executes during object creation, after setting all properties.
function VcrossTRslider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function updateVcrossTR(handles)
global dcm_obj hfull segmentFullK VplanesAllx VplanesAlly VplanesAllz 
global nframes branchList

info_struct = getCursorInfo(dcm_obj);
if ~isempty(info_struct)
    ptList = [info_struct.Position];
    ptList = reshape(ptList,[3,numel(ptList)/3])';
    pindex = zeros(size(ptList,1),1);
    % Find cursor point in branchList
    for n = 1:size(ptList,1)
        xIdx = find(branchList(:,1) == ptList(n,1));
        yIdx = find(branchList(xIdx,2) == ptList(n,2));
        zIdx = find(branchList(xIdx(yIdx),3) == ptList(n,3));
        pindex(n) = xIdx(yIdx(zIdx));
    end
    imdim = sqrt(size(segmentFullK,2)); %side length of cross-section

    Maskcross = segmentFullK(pindex,:);
    Maskcross = reshape(Maskcross,imdim,imdim);

    %get slice number from slider
    sliceNum = 1+round( get(hfull.VcrossTRslider,'Value').*(nframes-1) ); 

    v1 = squeeze(VplanesAllx(pindex,:,:));
    v2 = squeeze(VplanesAlly(pindex,:,:));
    v3 = squeeze(VplanesAllz(pindex,:,:));
    VcrossTR = 0.1*(v1 + v2 + v3);
    normDim = sqrt(size(VcrossTR,1));
    VcrossTR = reshape(VcrossTR,normDim,normDim,nframes);
    VcrossTR = imresize(VcrossTR,[imdim imdim],'nearest');
    minn = min(Maskcross.*VcrossTR,[],'all')*1.1;
    maxx = max(Maskcross.*VcrossTR,[],'all')*1.1;
    imshow(VcrossTR(:,:,sliceNum),[minn maxx],'InitialMagnification','fit','Parent',hfull.TRcross)
    visboundaries(hfull.TRcross,Maskcross,'LineWidth',1)
end 
    


function txt = myupdatefcn_all(empt,event_obj)
% Customizes text of data tips
global Labeltxt branchLabeled PointLabel branchList fullCData
global flowPulsatile_valK Planes p dcm_obj Ntxt hfull timeMIPcrossection
global segmentFullK MAGcrossection vTimeFrameave fig timeres nframes
global VplanesAllx VplanesAlly VplanesAllz

info_struct = getCursorInfo(dcm_obj);
ptList = [info_struct.Position];
ptList = reshape(ptList,[3,numel(ptList)/3])';
pindex = zeros(size(ptList,1),1);

% Find cursor point in branchList
for n = 1:size(ptList,1)
    xIdx = find(branchList(:,1) == ptList(n,1));
    yIdx = find(branchList(xIdx,2) == ptList(n,2));
    zIdx = find(branchList(xIdx(yIdx),3) == ptList(n,3));
    pindex(n) = xIdx(yIdx(zIdx));
end

% Get associated branch number of full branch
bnum = branchList(pindex,4);
Logical_branch = branchList(:,4) ~= bnum;
index_range = pindex-2:pindex+2; % OUTPUT +/- points
index_range(index_range<1) = []; %removes outliers and other branch points
index_range(index_range>size(branchList,1)) = [];
index_range(Logical_branch(index_range)) = [];

% Update Cross-sectional planes for points
set(p,'XData',Planes(pindex,:,1)','YData',Planes(pindex,:,2)','ZData',Planes(pindex,:,3)')
imdim = sqrt(size(segmentFullK,2)); %side length of cross-section

Maskcross = segmentFullK(pindex,:);
Maskcross = reshape(Maskcross,imdim,imdim);

%Magnitude TA
MAGcross = MAGcrossection(pindex,:);
MAGcross = reshape(MAGcross,imdim,imdim);
imshow(MAGcross,[],'InitialMagnification','fit','Parent',hfull.MAGcross)
visboundaries(hfull.MAGcross,Maskcross,'LineWidth',1)

%Complex diffference TA
CDcross = timeMIPcrossection(pindex,:);
CDcross = reshape(CDcross,imdim,imdim);
imshow(CDcross,[],'InitialMagnification','fit','Parent', hfull.CDcross)
visboundaries(hfull.CDcross,Maskcross,'LineWidth',1)

%Velocity TA - through plane
Vcross = vTimeFrameave(pindex,:);
Vcross = reshape(Vcross,imdim,imdim);
imshow(Vcross,[],'InitialMagnification','fit','Parent',hfull.VELcross)
visboundaries(hfull.VELcross,Maskcross,'LineWidth',1)

%Velocity TR - through plane
sliceNum = 1+round( get(hfull.VcrossTRslider,'Value').*(nframes-1) ); 
v1 = squeeze(VplanesAllx(pindex,:,:));
v2 = squeeze(VplanesAlly(pindex,:,:));
v3 = squeeze(VplanesAllz(pindex,:,:));
VcrossTR = 0.1*(v1 + v2 + v3);
normDim = sqrt(size(VcrossTR,1));
VcrossTR = reshape(VcrossTR,normDim,normDim,nframes);
VcrossTR = imresize(VcrossTR,[imdim imdim],'nearest');
minn = min(Maskcross.*VcrossTR,[],'all')*1.1;
maxx = max(Maskcross.*VcrossTR,[],'all')*1.1;
imshow(VcrossTR(:,:,sliceNum),[minn maxx],'InitialMagnification','fit','Parent',hfull.TRcross)
visboundaries(hfull.TRcross,Maskcross,'LineWidth',1)

% Segmentation mask
%imshow(Maskcross,[],'InitialMagnification','fit','Parent',hfull.TRcross)

% Get value of parameter at point and mean within 5pt window
value = fullCData(pindex);
average = fullCData(index_range);
pside = index_range;
pside(pside==pindex) = [];

cardiacCycle = (1:nframes).*timeres; %vector of cardiac cycle (ms)
% Plot flow waveform
if length(pside)==2
    plot(cardiacCycle,smooth(flowPulsatile_valK(pindex,:)),...
        'k',cardiacCycle,smooth(flowPulsatile_valK(pside(1),:)),...
        'r',cardiacCycle,smooth(flowPulsatile_valK(pside(2),:)),...
        'r','LineWidth',2,'Parent',hfull.pfwaveform)
elseif length(pside)==3
    plot(cardiacCycle,smooth(flowPulsatile_valK(pindex,:)),...
        'k',cardiacCycle,smooth(flowPulsatile_valK(pside(1),:)),...
        'r',cardiacCycle,smooth(flowPulsatile_valK(pside(2),:)),...
        'r',cardiacCycle,smooth(flowPulsatile_valK(pside(3),:)),...
        'b','LineWidth',2,'Parent',hfull.pfwaveform)
else
    plot(cardiacCycle,smooth(flowPulsatile_valK(pindex,:)),...
        'k',cardiacCycle,smooth(flowPulsatile_valK(pside(1),:)),...
        'r',cardiacCycle,smooth(flowPulsatile_valK(pside(2),:)),...
        'r',cardiacCycle,smooth(flowPulsatile_valK(pside(3),:)),...
        'b',cardiacCycle,smooth(flowPulsatile_valK(pside(4),:)),...
        'b','LineWidth',2,'Parent',hfull.pfwaveform)
end
set(get(hfull.pfwaveform,'XLabel'),'String','Cardiac Time Frame (ms)','FontSize',12)
set(get(hfull.pfwaveform,'YLabel'),'String','Flow (mL/s)','FontSize',12)

% Put the number labels on the CenterlinePlot if new branch
if branchLabeled ~= bnum
    delete(Ntxt)
    branchLabeled = bnum;
    index_branch = branchList(:,4) == branchLabeled;
    branchActual = branchList(index_branch,1:3);
    textint = 0:5:length(branchActual)-1;
    numString_val = num2str(textint);
    numString_val = strsplit(numString_val);
    Ntxt = text(branchActual(textint+1,1),branchActual(textint+1,2), ...
        branchActual(textint+1,3),numString_val,'Color','w','FontSize',10,...
        'HitTest','off','PickableParts','none','Parent',fig.Children(2));
end

% Get branch indices and current label point
branchActual = branchList(branchList(:,4) == branchLabeled,5);
CurrentNum = find(branchList(pindex,5)==branchActual)-1;

% Update cursor text
txt = {['Point Label: ' , PointLabel , sprintf('\n'), ...
    Labeltxt{1,1}, sprintf('%0.3f',value),Labeltxt{1,2}, sprintf('\n'), ...
    Labeltxt{2,1},sprintf('%0.3f',mean(average)),Labeltxt{2,2},sprintf('\n'), ...
    'Current Branch #: ',sprintf('%i',CurrentNum),sprintf('\n') ...
    'Label Number: ', sprintf('%i',bnum)]};
