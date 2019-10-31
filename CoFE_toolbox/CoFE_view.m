function [] = CoFE_view(FEM)

%% Main figure
%       [left bottom width height]
maxSize=[.05,.05,.9,.85];
scale = .75;
f = figure('Visible','on','Units','normalized','Color',[1 1 1],'Position',[maxSize(1:2),scale*maxSize(3:4)]);

%% Create GUI Handles Object to Store GUI data
h = guihandles(f);
h.FEM = FEM;

%% Gui Design Inputs
designColor         = [1 1 1];
implimentColor      = [0.9400 0.9400 0.9400];
h.textBackgroundColor = designColor;
h.titleBackground = [0.7 0.7 0.7];
h.fs = 12; % font Size

%% Logo Axis
im=imread(fullfile('+post','CoFEwb.png'));
normSize=[238,168]./238;
axes('position',[0,0,0.12*normSize]);
imshow(im);

%% Main Axis
h.ax = axes('Units','normalized','Position',[.05 .15 .65 .8]);
h.cb = colorbar('peer',h.ax);
set(h.cb,'visible','off');


%% Tabs
h.tgroup = uitabgroup('Parent',f,'Position',[.75 0 1 1]);
tab1 = uitab('Parent',h.tgroup, 'Title', 'Results');
tab2 = uitab('Parent',h.tgroup, 'Title', 'Options');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAB 1 - Results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBCASE Selection
subcase_text = uicontrol('Style','text','String','SUBCASE Selection:',...
    'Parent',tab1,...
    'HorizontalAlignment','left',...
    'FontSize',h.fs,...
    'FontWeight','bold',...
    'BackgroundColor',h.titleBackground,...
    'Units','normalized',...
    'Position',[.01,.95,.22,.03]);

% Create SUBCASE List
rm_id = 1; % response mode identification number
for sc = 1:size(FEM,2)
    switch FEM(sc).CASE.SOL
        case 101
            rm_list{rm_id} = sprintf(' %d - Linear Statics',sc);
            rm_key(rm_id,:) = [sc 1]; rm_id = rm_id + 1;
        case 103
            for m = 1:FEM(sc).ND;
                rm_list{rm_id} = sprintf(' %d - Vibration Mode %d, Freq. = %G Hz',sc,m,FEM(sc).fHz(m));
                rm_key(rm_id,:) = [sc m]; rm_id = rm_id + 1;
            end
        case 105
            for m = 1:FEM(sc).ND;
                rm_list{rm_id} = sprintf(' %d - Buckling Mode %d, EigVal. = %G ',sc,m,FEM(sc).eVal(m));
                rm_key(rm_id,:) = [sc m]; rm_id = rm_id + 1;
            end
        otherwise
            error('FEM.CASE.SOL should be 101, 103, or 105')
    end
end
h.rm_key = rm_key;
h.subcase = 1;
h.mode_number = 1;
h.subcaseTitleText = ['Subcase: ',rm_list{1}];
uicontrol('Parent',tab1, 'Style','listbox', ...
    'FontSize',h.fs,...
    'Callback',{@setSubcase},...
    'String',rm_list,...
    'Units','normalized',...
    'Value',1,...
    'Position',subcase_text.Position+[0 -.19 0 .15]);
%
% CONTOUR RESULT:
contour_text = uicontrol('Style','text','String','CONTOUR Selection:',...
    'Parent',tab1,...
    'HorizontalAlignment','left',...
    'FontSize',h.fs,...
    'FontWeight','bold',...
    'BackgroundColor',h.titleBackground,...
    'Units','normalized','Position',[subcase_text.Position(1) .70 subcase_text.Position(3) .03]);
h.contourLists = createContourList(FEM);
h.uiCountorList=uicontrol('Parent', tab1, 'Style','listbox', ...
    'FontSize',h.fs,...
    'Callback',{@setContourType},...
    'Units','normalized',...
	'Value',1,...
    'Position',contour_text.Position+[0 -.19 0 .15],...
    'String',h.contourLists{h.subcase});
h.fopts.contourType = h.contourLists{h.subcase}{1};
%
% Contour Type Specific Options Text
h.uiContourTypeSpecificText = uicontrol('Style','text',...
    'String',' ',...
    'Parent',tab1,...
    'Visible','off',...
    'HorizontalAlignment','left',...
    'FontSize',h.fs,...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized','Position',[subcase_text.Position(1) .47 subcase_text.Position(3) .03]);
%
% Contour Type Specific Options Dropdown
h.fopts.contourTypeSpecificOpt = '';
h.uiContourTypeSpecificOpt = ...
    uicontrol('style','popup','Parent',tab1,...
    'FontSize',h.fs,...
    'Value',1,...
    'Visible','off',...
    'Units','normalized','Position',[subcase_text.Position(1) .43 subcase_text.Position(3) .03],...
    'String',{'Opt. 1','Opt. 2'},'Callback',{@setContourTypeSpecificOpt});
%
% Quadrilateral Options:
uicontrol('Style','text','String','Quadrilateral Options:',...
    'Parent',tab1,...
    'HorizontalAlignment','left',...
    'FontSize',h.fs,...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized','Position',[subcase_text.Position(1) .37 subcase_text.Position(3) .03]);
uicontrol('style','popup','Parent',tab1,...
    'FontSize',h.fs,...
    'Units','normalized','Position',[subcase_text.Position(1) .33 subcase_text.Position(3) .03],...
    'String',{'  Top Corners','  Bottom Corners','  Top Center','  Bottom Center'},'Callback',{@setQuad4RecoveryPoint});
h.fopts.quad4RP = [4 6 8 10];
h.fopts.bliqRP = 2:5;

%
% Beam Options:
uicontrol('Style','text','String','Beam Recovery Point:',...
    'Parent',tab1,...
    'HorizontalAlignment','left',...
    'FontSize',h.fs,...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized','Position',[subcase_text.Position(1) .27 subcase_text.Position(3) .03]);
uicontrol('style','popup','Parent',tab1,...
    'FontSize',h.fs,...
    'Units','normalized','Position',[subcase_text.Position(1) .23 subcase_text.Position(3) .03],...
    'String',{'  C','  D','  E','  F'},'Callback',{@setBeamRecoveryPoint});
h.fopts.beamRP = [1 5]; % option "C"
%
% Deformation Options
uicontrol('Style','text','String','DEFORMATION Options:',...
    'Parent',tab1,...
    'HorizontalAlignment','Left',...
    'FontSize',h.fs,...
    'FontWeight','bold',...
    'BackgroundColor',h.titleBackground,...
    'Units','normalized','Position',[subcase_text.Position(1) .17 subcase_text.Position(3) .03]);
%
% Undeformed Structure
h.undeformedVisibility = 'on';
uicontrol('style','checkbox','Parent',tab1,...
    'FontSize',h.fs,...
    'Units','normalized','Position',[subcase_text.Position(1) .135 .03 .02],...
    'Value',1,...
    'Callback',{@setUndeformedVisibility});
uicontrol('style','text','String','Show Undeformed Structure',...
    'Parent',tab1,'FontSize',h.fs,...
    'HorizontalAlignment','left',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[subcase_text.Position(1)+.015 .13 subcase_text.Position(3)-.015 .03]);
%
% Deformed Structure
h.deformedVisibility = 'on';
uicontrol('style','checkbox','Parent',tab1,...
    'FontSize',h.fs,...
    'Value',1,...
    'Units','normalized','Position',[subcase_text.Position(1) .095 .03 .02],...
    'Callback',{@setDeformedVisibility});
uicontrol('style','text','String','Show Deformed Structure',...
    'Parent',tab1,'FontSize',h.fs,...
    'HorizontalAlignment','left',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[subcase_text.Position(1)+.015 .09 subcase_text.Position(3)-.015 .03]);
%
% Scale Deformed Structure
h.uiScaleFactor = uicontrol('style','edit','Parent',tab1,...
    'FontSize',h.fs,...
    'Units','normalized','Position',[subcase_text.Position(1) .035 .06 .04],...
    'Callback',{@setDeformedScaleFactor});
uicontrol('style','text','String','Scale Factor',...
    'Parent',tab1,'FontSize',h.fs,...
    'HorizontalAlignment','left',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[subcase_text.Position(1)+.06 .04 subcase_text.Position(3)-.06 .03]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAB 2 - Options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Contour Color Options
uicontrol('Style','text','String','  Contour Options',...
    'Parent',tab2,...
    'HorizontalAlignment','left',...
    'FontSize',h.fs,...
    'FontWeight','bold',...
    'BackgroundColor',h.titleBackground,...
    'Units','normalized',...
    'Position',[.01,.95,.23,.03]);

% Contour colormap options
h.colorMaps = {
    'Jet'
    'Parula'
    'HSV'
    'Hot'
    'Cool'
    'Spring'
    'Summer'
    'Autumn'
    'Winter'
    'Gray'
    'Bone'
    'Copper'
    'Pink'};
for i = 1:size(h.colorMaps,1);
    chooseColor{i} = ['<HTML>',sprintf('<font color="black" bgcolor="rgb(%f,%f,%f)">&nbsp;',255*colormap(h.colorMaps{i})'),'<font color="black" bgcolor="white">&nbsp;&nbsp;',h.colorMaps{i},'</HTML>',];
end
uicontrol('style','popup',...
    'Value',1,...
    'Units','normalized','Position',[.01,.88,.23,.05],'Parent',tab2,...
    'String',chooseColor,'Callback',{@setContourColorMap})
colormap(h.colorMaps{1});

% access colormap editor
uicontrol('Style', 'pushbutton', 'String', 'Open Colormap Editor',...
    'Parent',tab2,...
    'FontSize',h.fs,...
    'Units','normalized','Position',[.01,.84,.23,.05],...
    'Callback', 'colormapeditor');

%% Define Line Options
h.lineRgbValues =[0    0.4470    0.7410
    0.8500    0.3250    0.0980
    0.9290    0.6940    0.1250
    0.4940    0.1840    0.5560
    0.4660    0.6740    0.1880
    0.3010    0.7450    0.9330
    0.6350    0.0780    0.1840];
for i = 1:size(h.lineRgbValues,1);
    chooseLineRgbValue{i} = sprintf('<HTML><font color="white" bgcolor="rgb(%f,%f,%f)">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</HTML>',255*h.lineRgbValues(i,:));
end

%% Element Options
uicontrol('Style','text','String','  Element Options',...
    'Parent',tab2,...
    'HorizontalAlignment','left',...
    'FontSize',h.fs,...
    'FontWeight','bold',...
    'BackgroundColor',h.titleBackground,...
    'Units','normalized',...
    'Position',[.01,.78,.23,.03]);

% Tab Group
ele_tgroup = uitabgroup('Parent',tab2,'Position',[.01,.25,.23,.53]);

% vertical seperation steps
dvs = .08;

%% ELEMENT TAB 1 - 0D Element Options
ele_tab1 = uitab('Parent',ele_tgroup, 'Title','0D');

uicontrol('style','text','String','Point Elements',...
    'FontWeight','bold',...
    'Parent',ele_tab1,'FontSize',h.fs,...
    'HorizontalAlignment','left',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93,.9,.057]);

% Undeformed
uicontrol('style','text','String','Undeformed',...
    'Parent',ele_tab1,'FontSize',h.fs,...
    'HorizontalAlignment','center',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-1.*dvs,.9,.057]);
% Marker Size
uicontrol('style','text','String','Marker Size  ',...
    'Parent',ele_tab1,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-2.*dvs,.48,.057]);
uicontrol('style','popup',...
    'Units','normalized','Position',[.5,.93-2.*dvs,.48,.057],'Parent',ele_tab1,...
    'Value',4,...
    'String',{'1','4','8','12','16','20','24','28','32','36'},...
    'Callback',{@setUnd0DMarkerSize});
    h.fopts.und0DMarkerSize = 12;
% Marker Color
uicontrol('style','text','String','Marker Color  ',...
    'Parent',ele_tab1,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-3.*dvs,.48,.057]);
uicontrol('style','popup',......
    'Units','normalized','Position',[.5,.93-3.*dvs,.48,.057],'Parent',ele_tab1,...
    'Value',6,...
    'String',chooseLineRgbValue,'Callback',{@setUnd0DMarkerRgb});
    h.fopts.und0DMarkerRgb = h.lineRgbValues(6,:);
% Deformed
uicontrol('style','text','String','Deformed',...
    'Parent',ele_tab1,'FontSize',h.fs,...
    'HorizontalAlignment','center',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-5.*dvs,.9,.057]);
% Marker Size
uicontrol('style','text','String','Marker Size  ',...
    'Parent',ele_tab1,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-6.*dvs,.48,.057]);
uicontrol('style','popup',...
    'Units','normalized','Position',[.5,.93-6.*dvs,.48,.057],'Parent',ele_tab1,...
    'Value',4,...
    'String',{'1','4','8','12','16','20','24','28','32','36'},...
    'Callback',{@setDef0DMarkerSize});
    h.fopts.def0DMarkerSize = 12;
% Marker Color
uicontrol('style','text','String','Marker Color  ',...
    'Parent',ele_tab1,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-7.*dvs,.48,.057]);
uicontrol('style','popup',......
    'Units','normalized','Position',[.5,.93-7.*dvs,.48,.057],'Parent',ele_tab1,...
    'String',chooseLineRgbValue,'Value',7,'Callback',{@setDef0DMarkerRgb});
    h.fopts.def0DMarkerRgb = h.lineRgbValues(7,:);
    
%% ELEMENT TAB 2 - 1D Element Options
ele_tab2 = uitab('Parent',ele_tgroup, 'Title','1D');
uicontrol('Style','text','String','1D Element Options',...
    'FontWeight','bold',...
    'Parent',ele_tab2,...
    'HorizontalAlignment','left',...
    'FontSize',h.fs,...
    'FontWeight','bold',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93,.9,.057]);

% undeformed line width options
for i = 1:5;
    chooseLineWidth{i} = sprintf('<HTML><HR NOSHADE SIZE="%d" WIDTH="300"></HTML>',i);
end
% Undeformed
uicontrol('style','text','String','Undeformed',...
    'Parent',ele_tab2,'FontSize',h.fs,...
    'HorizontalAlignment','center',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-1.*dvs,.9,.057]);
% Line Width
h.fopts.und1DLineWidth = 2;
uicontrol('style','text','String','Line Width  ',...
    'Parent',ele_tab2,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-2.*dvs,.48,.057]);
uicontrol('style','popup',...
	'Value',h.fopts.und1DLineWidth,...
    'Units','normalized','Position',[.5,.93-2.*dvs,.48,.057],'Parent',ele_tab2,...
    'String',chooseLineWidth,'Callback',{@setUnd1DLineWidth});
% Line Color
h.fopts.und1DLineRgb = h.lineRgbValues(6,:);
uicontrol('style','text','String','Line Color  ',...
    'Parent',ele_tab2,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-3.*dvs,.48,.057]);
uicontrol('style','popup',......
    'Value',6,...
    'Units','normalized','Position',[.5,.93-3.*dvs,.48,.057],'Parent',ele_tab2,...
    'String',chooseLineRgbValue,'Callback',{@setUnd1DLineRgb});

% Deformed
uicontrol('style','text','String','Undeformed',...
    'Parent',ele_tab2,'FontSize',h.fs,...
    'HorizontalAlignment','center',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-5.*dvs,.9,.057]);
% Line Width
h.fopts.def1DLineWidth = 2;
uicontrol('style','text','String','Line Width  ',...
    'Parent',ele_tab2,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-6.*dvs,.48,.057]);
uicontrol('style','popup',...
	'Value',h.fopts.def1DLineWidth,...
    'Units','normalized','Position',[.5,.93-6.*dvs,.48,.057],'Parent',ele_tab2,...
    'String',chooseLineWidth,'Callback',{@setDef1DLineWidth});
% Line Color
h.fopts.def1DLineRgb = h.lineRgbValues(7,:);
uicontrol('style','text','String','Line Color  ',...
    'Parent',ele_tab2,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-7.*dvs,.48,.057]);
uicontrol('style','popup',...
    'Value',7,...
    'Units','normalized','Position',[.5,.93-7.*dvs,.48,.057],'Parent',ele_tab2,...
    'String',chooseLineRgbValue,'Callback',{@setDef1DLineRgb});

%% ELEMENT TAB 3 - 2D Element Options
ele_tab3 = uitab('Parent',ele_tgroup, 'Title','2D');
uicontrol('Style','text','String','2D Element Options',...
    'FontWeight','bold',...
    'Parent',ele_tab3,...
    'HorizontalAlignment','left',...
    'FontSize',h.fs,...
    'FontWeight','bold',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93,.9,.057]);

% undeformed line width options
for i = 1:5;
    chooseLineWidth{i} = sprintf('<HTML><HR NOSHADE SIZE="%d" WIDTH="300"></HTML>',i);
end
% Undeformed
uicontrol('style','text','String','Undeformed',...
    'Parent',ele_tab3,'FontSize',h.fs,...
    'HorizontalAlignment','center',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-1.*dvs,.9,.057]);
% Line Width
h.fopts.und2DLineWidth = 2;
uicontrol('style','text','String','Edge Width  ',...
    'Parent',ele_tab3,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-2.*dvs,.48,.057]);
uicontrol('style','popup',...
	'Value',h.fopts.und2DLineWidth,...
    'Units','normalized','Position',[.5,.93-2.*dvs,.48,.057],'Parent',ele_tab3,...
    'String',chooseLineWidth,'Callback',{@setUnd2DLineWidth});
% Line Color
h.fopts.und2DLineRgb = h.lineRgbValues(6,:);
uicontrol('style','text','String','Edge Color  ',...
    'Parent',ele_tab3,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-3.*dvs,.48,.057]);
uicontrol('style','popup',......
    'Value',6,...
    'Units','normalized','Position',[.5,.93-3.*dvs,.48,.057],'Parent',ele_tab3,...
    'String',chooseLineRgbValue,'Callback',{@setUnd2DLineRgb});
% Face Color
h.fopts.und2DFaceRgb = h.lineRgbValues(6,:);
uicontrol('style','text','String','Face Color  ',...
    'Parent',ele_tab3,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-4.*dvs,.48,.057]);
uicontrol('style','popup',......
    'Value',6,...
    'Units','normalized','Position',[.5,.93-4.*dvs,.48,.057],'Parent',ele_tab3,...
    'String',chooseLineRgbValue,'Callback',{@setUnd2DFaceRgb});
% Face Alpha
h.fopts.und2DFaceAlpha = .25;
uicontrol('style','text','String','Transparency ',...
    'Parent',ele_tab3,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-5.*dvs,.48,.057]);
uicontrol('style','popup',......
    'Value',2,...
    'Units','normalized','Position',[.5,.93-5.*dvs,.48,.057],'Parent',ele_tab3,...
    'String',{'0','25','50','75','100'},'Callback',{@setUnd2DFaceAlpha});


% Deformed
uicontrol('style','text','String','Deformed',...
    'Parent',ele_tab3,'FontSize',h.fs,...
    'HorizontalAlignment','center',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-7.*dvs,.9,.057]);
% Line Width
h.fopts.def2DLineWidth = 2;
uicontrol('style','text','String','Edge Width  ',...
    'Parent',ele_tab3,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-8.*dvs,.48,.057]);
uicontrol('style','popup',...
	'Value',h.fopts.def2DLineWidth,...
    'Units','normalized','Position',[.5,.93-8.*dvs,.48,.057],'Parent',ele_tab3,...
    'String',chooseLineWidth,'Callback',{@setDef2DLineWidth});
% Line Color
h.fopts.def2DLineRgb = h.lineRgbValues(7,:);
uicontrol('style','text','String','Edge Color  ',...
    'Parent',ele_tab3,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-9.*dvs,.48,.057]);
uicontrol('style','popup',...
    'Value',7,...
    'Units','normalized','Position',[.5,.93-9.*dvs,.48,.057],'Parent',ele_tab3,...
    'String',chooseLineRgbValue,'Callback',{@setDef2DLineRgb});
% Face Color
h.fopts.def2DFaceRgb = h.lineRgbValues(7,:);
uicontrol('style','text','String','Face Color  ',...
    'Parent',ele_tab3,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-10.*dvs,.48,.057]);
uicontrol('style','popup',......
    'Value',7,...
    'Units','normalized','Position',[.5,.93-10.*dvs,.48,.057],'Parent',ele_tab3,...
    'String',chooseLineRgbValue,'Callback',{@setDef2DFaceRgb});
% Face Alpha
h.fopts.def2DFaceAlpha = .25; h.fopts.def2DFaceAlphaUIValue = 2;
h.fopts.def2DFaceAlphaContour = 1.0; h.fopts.def2DFaceAlphaContourUIValue = 5;
uicontrol('style','text','String','Transparency ',...
    'Parent',ele_tab3,'FontSize',h.fs,...
    'HorizontalAlignment','right',...
    'BackgroundColor',h.textBackgroundColor,...
    'Units','normalized',...
    'Position',[.01,.93-11.*dvs,.48,.057]);
h.def2DFaceAlphaUI = ...
uicontrol('style','popup',......
    'Value',h.fopts.def2DFaceAlphaUIValue,...
    'Units','normalized','Position',[.5,.93-11.*dvs,.48,.057],'Parent',ele_tab3,...
    'String',{'0','25','50','75','100'},'Callback',{@setDef2DFaceAlpha});



%% Save Figure Button
uicontrol('Style', 'pushbutton', 'String', 'Save Figure as Image',...
    'Parent',tab2,...
    'FontSize',h.fs,...
    'Units','normalized','Position',[.01,.02,.22,.05],...
    'Callback', {@figureSave});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initial Figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Determine Model Size
h.model_size = max(max(FEM(1).gcoord,[],2)-min(FEM(1).gcoord,[],2));

%% store gui handles
guidata(f,h); 

%% Startup
plotUnd(f);
plotSig(f);
% deformedVisibility();
% undeformedVisibility();
% colormap(colorMaps{1});
% setLineColor();
% setLineWidth();

end

%% Plot Functions
function plotUnd(source,eventdata)
% Plot Undeformed - This should only execute once

h = guidata(source);

% Pick subcase and mode number
FEMP = h.FEM(h.subcase); % select subcase

% Loop through plotList
cla
hold on

% loop through 0D elements
iter0D = 0;
h.und0D = [];
for j = 1:size(FEMP.plot0DList,2)
    for i = 1:size(FEMP.(FEMP.plot0DList{j}),2)
        iter0D = iter0D + 1;
        h.und0D(iter0D) = plot(FEMP.(FEMP.plot0DList{j})(i),[],...
            'o',...
            'color',h.fopts.und0DMarkerRgb,...
            'MarkerFaceColor',h.fopts.und0DMarkerRgb,...
            'MarkerSize',h.fopts.und0DMarkerSize);
    end
end

% loop through 1D elements
iter1D = 0;
h.und1D = [];
for j = 1:size(FEMP.plot1DList,2)
    for i = 1:size(FEMP.(FEMP.plot1DList{j}),2)
        iter1D = iter1D + 1;
        h.und1D(iter1D) = plot(FEMP.(FEMP.plot1DList{j})(i),[],...
            'color',h.fopts.und1DLineRgb,...
            'LineWidth',h.fopts.und1DLineWidth);
    end
end

% loop through 2D elements
iter2D = 0;
h.und2D = [];
for j = 1:size(FEMP.plot2DList,2)
    for i = 1:size(FEMP.(FEMP.plot2DList{j}),2)
        iter2D = iter2D + 1;
        h.und2D(iter2D) = plot(FEMP.(FEMP.plot2DList{j})(i),[],...
            'color',h.fopts.und2DLineRgb,...
            'LineWidth',h.fopts.und2DLineWidth,...
            'FaceColor',h.fopts.und2DFaceRgb,...
            'FaceAlpha',h.fopts.und2DFaceAlpha);
    end
end

xlabel('x')
ylabel('y')
zlabel('z')
axis('on')
hold off

% assemble arrays
h.und = [h.und0D,h.und1D,h.und2D];

% Apply visibilities
set(h.und,'Visible',h.undeformedVisibility);

% Save plot handles to guidata
guidata(source,h);

end
function plotSig(source,eventdata,dontUpdateScaleFactor)

h = guidata(source);

% Pick subcase and mode number
FEMP = h.FEM(h.subcase); % select subcase

% Response scaling
if nargin < 3
    max_def = max(abs( FEMP.u(:,h.mode_number) ));
    h.fopts.scaleFac = .15 * h.model_size/max_def;
    set(h.uiScaleFactor,'String',num2str(h.fopts.scaleFac));
end

% Subcase Mode
u_plot = FEMP.u(:,h.mode_number);

% Loop through plotList
initialFlag = 0;
if isfield(h,'def') == 0
    h.def0D = [];
    h.def1D = [];
    h.def2D = [];
    initialFlag = 1;
end
hold on

% loop through 0D elements
iter0D = 0;
for j = 1:size(FEMP.plot0DList,2)
    for i = 1:size(FEMP.(FEMP.plot0DList{j}),2)
        iter0D = iter0D + 1;
        if initialFlag
            h.def0D(iter0D) = contour(FEMP.(FEMP.plot0DList{j})(i),u_plot,h.mode_number,h.fopts);
        else
            h.def0D(iter0D) = contour(FEMP.(FEMP.plot0DList{j})(i),u_plot,h.mode_number,h.fopts,h.def0D(iter0D));
        end
    end
end

% loop through 1D elements
iter1D = 0;
for j = 1:size(FEMP.plot1DList,2)
    for i = 1:size(FEMP.(FEMP.plot1DList{j}),2)
        iter1D = iter1D + 1;
        if initialFlag
            h.def1D(iter1D) = contour(FEMP.(FEMP.plot1DList{j})(i),u_plot,h.mode_number,h.fopts);
        else
            h.def1D(iter1D) = contour(FEMP.(FEMP.plot1DList{j})(i),u_plot,h.mode_number,h.fopts,h.def1D(iter1D));
        end
    end
end

% loop through 2D elements
iter2D = 0;
for j = 1:size(FEMP.plot2DList,2)
    for i = 1:size(FEMP.(FEMP.plot2DList{j}),2)
        iter2D = iter2D + 1;
        if initialFlag
            h.def2D(iter2D) = contour(FEMP.(FEMP.plot2DList{j})(i),u_plot,h.mode_number,h.fopts);
        else
            h.def2D(iter2D) = contour(FEMP.(FEMP.plot2DList{j})(i),u_plot,h.mode_number,h.fopts,h.def2D(iter2D));
        end
    end
end


% assemble arrays
h.def = [h.def0D,h.def1D,h.def2D];

% display text 
% ax = get(gca);
h.ax.XLabel.String='x';
h.ax.YLabel.String='y';
h.ax.ZLabel.String='z';
h.ax.Title.String=titleString(h);

% axis('on')
hold off

% Apply 0D marker size
if iter0D > 0
    setContourMarkerSize(h.def0D,h.fopts.def0DMarkerSize)
end

if strcmp(h.fopts.contourType,'None')~=1    
    C0 = get(h.def0D,'CData'); if iscell(C0); C0 = cell2mat(C0); end
    C1 = get(h.def1D,'CData'); if iscell(C1); C1 = cell2mat(C1); end
    C2 = get(h.def2D,'CData'); if iscell(C2); C2 = cell2mat(C2); end
    caxis(h.ax,[min([min(C0),min(min(C1)),min(min(C2))])-eps,max([max(C0),max(max(C1)),max(max(C2))])+eps]);
end

% Save plot handles to guidata
guidata(source,h);

end

%% Helper Functions
function contourLists = createContourList(FEM)
nsc = size(FEM,2);
contourLists = cell(nsc,1);
for i = 1:nsc
    list{1} = 'None';
    list{2} = 'Displacements';
    list{3} = 'Rotations';
    ln = 4;
%     if FEM(i).CASE.FORCE == 1
%         list{ln} = 'Element Nodal Forces'; ln = ln + 1;
%     end
    if FEM(i).CASE.STRESS == 1
        list{ln} = 'Stress'; ln = ln + 1;
    end
    if FEM(i).CASE.STRAIN == 1
        list{ln} = 'Strain'; ln = ln + 1;
    end
    if FEM(i).CASE.ESE == 1
        list{ln} = 'Element Strain Energy'; ln = ln + 1;
    end
    if FEM(i).CASE.EKE == 1 && FEM(i).CASE.SOL == 103
        list{ln} = 'Element Kinetic Energy';
    end
    contourLists{i}=list;
    clear list
end
end
function setContourMarkerSize(graphicsHandle,markerSize)
currentunits = get(gcf,'Units');
set(gcf, 'Units', 'Points');
axpos = get(gcf,'Position');
set(gcf, 'Units', currentunits);
markerS = markerSize/diff(xlim)*axpos(3);
set(graphicsHandle,'SizeData', markerS);
set(graphicsHandle,'SizeData',markerSize^2);
end
function tStr = titleString(h)
% h.subcaseTitleText = ['Subcase: ',rm_list{1}];
% h.contourTitleText = '';
% set(h.contourTitleText,'String',['Contours: ',h.fopts.contourType,' - ',h.fopts.contourTypeSpecificOpt])

if strcmp(h.fopts.contourType,'None')
    tStr = h.subcaseTitleText;
elseif strcmp(h.fopts.contourType,'Element Strain Energy') || ...
        strcmp(h.fopts.contourType,'Element Kinetic Energy')
    tStr = [h.subcaseTitleText,' | Contours: ',h.fopts.contourType];
else
    tStr = [h.subcaseTitleText,' | Contours: ',h.fopts.contourType,' - ',h.fopts.contourTypeSpecificOpt];
end
end

%% Callbacks
function setSubcase(source,eventdata)
h = guidata(source);

h.subcase = h.rm_key(source.Value,1);
h.mode_number = h.rm_key(source.Value,2);

h.subcaseTitleText=['Subcase: ',source.String{source.Value}];
set(h.uiCountorList,'String',h.contourLists{h.subcase})

% pick same contour option - if available
ind = find(strcmp(h.fopts.contourType,h.contourLists{h.subcase}));
if isempty(ind) == 1
    h.fopts.contourType = h.contourLists{h.subcase}{1};
    set(h.uiCountorList,'Value',1);
else
%   h.fopts.contourType = h.contourLists{h.subcase}{ind};
    set(h.uiCountorList,'Value',ind);
end

guidata(source,h);
plotSig(source,eventdata)
end
function setContourType(source,eventdata)

% Set New Contour Type
h = guidata(source);
h.fopts.contourType = h.contourLists{h.subcase}{source.Value};

% Provide Contour Type Specific Options
set(h.uiContourTypeSpecificOpt,'Visible','on');
set(h.uiContourTypeSpecificText,'Visible','on');
set(h.uiContourTypeSpecificText,'String',[h.fopts.contourType,' Contour Options']);

switch h.fopts.contourType
    case {'Displacements','Rotations','Element Nodal Forces'}
        set(h.uiContourTypeSpecificOpt,'String',...
            {'Magnitude','X Component','Y Component','Z Component'})
        set(h.uiContourTypeSpecificOpt,'Value',1)
        h.fopts.contourTypeSpecificOpt = 'Magnitude';
    case {'Stress','Strain'}
        set(h.uiContourTypeSpecificOpt,'String',...
            {'von Mises','X Component','Y Component','Z Component','XY Component','YZ Component','ZX Component'});
        set(h.uiContourTypeSpecificOpt,'Value',1)
        h.fopts.contourTypeSpecificOpt = 'von Mises';
    case {'Element Strain Energy',...
          'Element Kinetic Energy',...
          'None'}
        set(h.uiContourTypeSpecificOpt,'Visible','off');
        set(h.uiContourTypeSpecificText,'Visible','off');
        h.fopts.contourTypeSpecificOpt = '';
    otherwise
        error([fopts.contourType, 'Contour type not supported'])
end

if strcmp(h.fopts.contourType,'None')
    set(h.cb,'Visible','off')
    if isfield(h,'def2D')
        set(h.def2D,'FaceAlpha',h.fopts.def2DFaceAlpha);
        set(h.def2DFaceAlphaUI,'Value',h.fopts.def2DFaceAlphaUIValue);
    end
else
    set(h.cb,'Visible','on')
    if isfield(h,'def2D')
        set(h.def2D,'FaceAlpha',h.fopts.def2DFaceAlphaContour);
        set(h.def2DFaceAlphaUI,'Value',h.fopts.def2DFaceAlphaContourUIValue);
    end
end

guidata(source,h);
plotSig(source,eventdata,'Use Existing Scale Factor')
end
function setContourTypeSpecificOpt(source,eventdata)
h = guidata(source);
h.fopts.contourTypeSpecificOpt = ...
    h.uiContourTypeSpecificOpt.String{h.uiContourTypeSpecificOpt.Value};
guidata(source,h);
plotSig(source,eventdata,'Use Existing Scale Factor')
end
function setUndeformedVisibility(source,eventdata)
h = guidata(source);
if source.Value
    h.undeformedVisibility = 'on';
else
    h.undeformedVisibility = 'off';
end
guidata(source,h);
set(h.und,'Visible',h.undeformedVisibility);
end
function setDeformedVisibility(source,eventdata)
h = guidata(source);
if source.Value
    h.deformedVisibility = 'on';
else
    h.deformedVisibility = 'off';
end
guidata(source,h);
set(h.def,'Visible',h.deformedVisibility);
end
function setBeamRecoveryPoint(source,eventdata)
h = guidata(source);
beamOption = source.String{source.Value};
% Recovery Point Options
switch beamOption
    case '  C'
        h.fopts.beamRP = [1 5];
    case '  D'
        h.fopts.beamRP = [2 6];
    case '  E'
        h.fopts.beamRP = [3 7];
    case '  F'
        h.fopts.beamRP = [4 8];
    otherwise
        error(['Beam Recovery Point Option',beamOption,' not supported.'])
end
guidata(source,h);
plotSig(source,eventdata,'Use Existing Scale Factor')
end
function setQuad4RecoveryPoint(source,eventdata)
h = guidata(source);
quad4Option = source.String{source.Value};
% Recovery Point Options
switch quad4Option
    case '  Top Corners'
        h.fopts.quad4RP = [4 6 8 10];
        h.fopts.bliqRP = 2:5;
    case '  Bottom Corners'
        h.fopts.quad4RP = [3 5 7 9];
        h.fopts.bliqRP = 2:5;
    case '  Top Center'
        h.fopts.quad4RP = [2 2 2 2];
        h.fopts.bliqRP = [1 1 1 1];
    case '  Bottom Center'
        h.fopts.quad4RP = [1 1 1 1];
        h.fopts.bliqRP = [1 1 1 1];
    otherwise
        error(['Beam Recovery Point Option',beamOption,' not supported.'])
end
guidata(source,h);
plotSig(source,eventdata,'Use Existing Scale Factor')
end

function setUnd0DMarkerRgb(source,eventdata)
h = guidata(source);
h.fopts.und0DMarkerRgb = h.lineRgbValues(source.Value,:);
guidata(source,h);
set(h.und0D,'Color',h.fopts.und0DMarkerRgb);
set(h.und0D,'MarkerFaceColor',h.fopts.und0DMarkerRgb);
end
function setDef0DMarkerRgb(source,eventdata)
h = guidata(source);
h.fopts.def0DMarkerRgb = h.lineRgbValues(source.Value,:);
guidata(source,h);
if strcmp(h.fopts.contourType,'None')
    set(h.def0D,'Color',h.fopts.def0DMarkerRgb);
    set(h.def0D,'MarkerFaceColor',h.fopts.def0DMarkerRgb);
end
end
function setUnd0DMarkerSize(source,eventdata)
h = guidata(source);
h.fopts.und0DMarkerSize = str2double(source.String{source.Value});
set(h.und0D,'MarkerSize',h.fopts.und0DMarkerSize);
guidata(source,h);
end
function setDef0DMarkerSize(source,eventdata)
h = guidata(source);
h.fopts.def0DMarkerSize = str2double(source.String{source.Value});
setContourMarkerSize(h.def0D,h.fopts.def0DMarkerSize);
guidata(source,h);
end

function setUnd1DLineRgb(source,eventdata)
h = guidata(source);
h.fopts.und1DLineRgb = h.lineRgbValues(source.Value,:);
guidata(source,h);
set(h.und1D,'EdgeColor',h.fopts.und1DLineRgb);
end
function setDef1DLineRgb(source,eventdata)
h = guidata(source);
h.fopts.def1DLineRgb = h.lineRgbValues(source.Value,:);
guidata(source,h);
if strcmp(h.fopts.contourType,'None')
    set(h.def1D,'Color',h.fopts.def1DLineRgb);
end
end
function setUnd1DLineWidth(source,eventdata)
h = guidata(source);
h.fopts.und1DLineWidth = source.Value;
set(h.und1D,'LineWidth',h.fopts.und1DLineWidth);
guidata(source,h);
end
function setDef1DLineWidth(source,eventdata)
h = guidata(source);
h.fopts.def1DLineWidth = source.Value;
set(h.def1D,'LineWidth',h.fopts.def1DLineWidth);
guidata(source,h);
end

function setUnd2DLineRgb(source,eventdata)
h = guidata(source);
h.fopts.und2DLineRgb = h.lineRgbValues(source.Value,:);
guidata(source,h);
set(h.und2D,'EdgeColor',h.fopts.und2DLineRgb);
end
function setDef2DLineRgb(source,eventdata)
h = guidata(source);
h.fopts.def2DLineRgb = h.lineRgbValues(source.Value,:);
guidata(source,h);
set(h.def2D,'EdgeColor',h.fopts.def2DLineRgb);
end
function setUnd2DLineWidth(source,eventdata)
h = guidata(source);
h.fopts.und2DLineWidth = source.Value;
set(h.und2D,'LineWidth',h.fopts.und2DLineWidth);
guidata(source,h);
end
function setDef2DLineWidth(source,eventdata)
h = guidata(source);
h.fopts.def2DLineWidth = source.Value;
set(h.def2D,'LineWidth',h.fopts.def2DLineWidth);
guidata(source,h);
end
function setUnd2DFaceRgb(source,eventdata)
h = guidata(source);
h.fopts.und2DFaceRgb = h.lineRgbValues(source.Value,:);
guidata(source,h);
set(h.und2D,'FaceColor',h.fopts.und2DFaceRgb);
end
function setDef2DFaceRgb(source,eventdata)
h = guidata(source);
h.fopts.def2DFaceRgb = h.lineRgbValues(source.Value,:);
guidata(source,h);
set(h.def2D,'FaceColor',h.fopts.def2DFaceRgb);
end
function setUnd2DFaceAlpha(source,eventdata)
h = guidata(source);
h.fopts.und2DFaceAlpha = str2double(source.String(source.Value))/100;
guidata(source,h);
set(h.und2D,'FaceAlpha',h.fopts.und2DFaceAlpha);
end
function setDef2DFaceAlpha(source,eventdata)
h = guidata(source);

if strcmp(h.fopts.contourType,'None')
    h.fopts.def2DFaceAlphaUIValue = source.Value;
    h.fopts.def2DFaceAlpha = str2double(source.String(source.Value))/100;
    set(h.def2D,'FaceAlpha',h.fopts.def2DFaceAlpha);
else
    h.fopts.def2DFaceAlphaContourUIValue = source.Value;
    h.fopts.def2DFaceAlphaContour = str2double(source.String(source.Value))/100;
    set(h.def2D,'FaceAlpha',h.fopts.def2DFaceAlphaContour);
end
guidata(source,h);
end

function setContourColorMap(source,eventdata)
h = guidata(source);
colormap(h.colorMaps{source.Value});
end
function setDeformedScaleFactor(source,eventdata)
h = guidata(source);
% plotSig(source,eventdata,'Use Prescribed Scale Factor')
oldSF = h.fopts.scaleFac;
newSF = str2double(source.String);
if oldSF ~= 0
    SF = newSF/oldSF;
    for i = 1:size(h.def0D,2)
        set(h.def0D(i),'XData',SF*get(h.def0D(i),'XData')+(1-SF)*get(h.und0D(i),'XData'));
        set(h.def0D(i),'YData',SF*get(h.def0D(i),'YData')+(1-SF)*get(h.und0D(i),'YData'));
        set(h.def0D(i),'ZData',SF*get(h.def0D(i),'ZData')+(1-SF)*get(h.und0D(i),'ZData'));
    end
    for i = 1:size(h.def1D,2)
        set(h.def1D(i),'XData',SF*get(h.def1D(i),'XData')+(1-SF)*get(h.und1D(i),'XData'));
        set(h.def1D(i),'YData',SF*get(h.def1D(i),'YData')+(1-SF)*get(h.und1D(i),'YData'));
        set(h.def1D(i),'ZData',SF*get(h.def1D(i),'ZData')+(1-SF)*get(h.und1D(i),'ZData'));
    end
    for i = 1:size(h.def2D,2)
        set(h.def2D(i),'XData',SF*get(h.def2D(i),'XData')+(1-SF)*get(h.und2D(i),'XData'));
        set(h.def2D(i),'YData',SF*get(h.def2D(i),'YData')+(1-SF)*get(h.und2D(i),'YData'));
        set(h.def2D(i),'ZData',SF*get(h.def2D(i),'ZData')+(1-SF)*get(h.und2D(i),'ZData'));
    end
    h.fopts.scaleFac = newSF;
    guidata(source,h);
else
    h.fopts.scaleFac = newSF;
    guidata(source,h);
    plotSig(source,eventdata,'Use Prescribed Scale Factor')
end
end
function figureSave(source,eventdata)
[filename, pathname] = uiputfile({'*.pdf';'*.svg';'*.png'},'Save CoFE Display as High-Quality Image');
%
% % hide ui from image
H = guidata(source);
set(H.tgroup,'Visible','off');
%
DPI = 300; % Dots per square inch.  Higher dpi will give higher resolution
f= gcf;
set(f, 'PaperPositionMode','manual');
set(f,'Units','inches')
h=get(f,'Position');
set(f, 'PaperPosition', [0,0,h(3),h(4)]);
set(f, 'PaperSize', [.75*h(3), h(4)])
if strcmp(filename(end-3:end),'.pdf')
    print('-dpdf',strcat('-r',num2str(DPI)),fullfile(pathname,filename))
elseif strcmp(filename(end-3:end),'.svg')
    print('-dsvg',strcat('-r',num2str(DPI)),fullfile(pathname,filename))
else
    print('-dpng',strcat('-r',num2str(DPI)),fullfile(pathname,filename))
end
set(f,'Units','normalized')
set(H.tgroup,'Visible','on');
end