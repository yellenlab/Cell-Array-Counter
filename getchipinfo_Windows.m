function [ChipType, MagFactor, filterUsed, TiforJpg] = getchipinfo()
%GETCHIPINFO creates a user interface in a uifigure within matlab, and
%   prompts the user with a popup menus of possible chip types,
%   magnification factor, the fluorescent filter used, and the image file
%   type that the original metamorph images were saved as. User responses
%   are saved in outputs ChipType, MagFactor, filterUsed, and TiforJpg,
%   respectively. Based on chip type, possible choices for magnification
%   factor are limited.
%
%   GETCHIPINFO() will ask user for all output types with no input given.
%
%   For matlab commands used, see also: UICONTROL

    % If input argument, then only needs to get chip type. If no input
    % argument provided, then will ask for all pieces of information
    if nargin >= 1
        error('No inputs are allowed for this function.')
    end
    
    % Windows offsets for ui appearence (OS = OffSet)
    HOS = 30;
    VOS = 20;
    OKBS = [50 30];
    OKBL = 9;
    
    %% Create figure for selecting chip type
    f = figure('Visible', 'off',...
               'numbertitle', 'off',...
               'name', 'Select Chip Type');
    set(f, 'units', 'centimeters', 'Position', [1 1 11 3]) % Dummy position to set figure size
    movegui(f, 'center');

    % Create pop-up menu
    popup = uicontrol('Style', 'popup',...
           'String', {'Full P-Chip','7-Condition Chip','Y-Chip (50x50)','Y-Chip (100x100)', },...
           'Position', [20+HOS 45+VOS 200 0],...
           'fontweight','bold',...
           'horizontalalign','center',...
           'Callback', @setChipType,...
           'fontsize', 11);
       
    % Add a text uicontrol to label chip type popup
    txt = uicontrol('Style','text',...
    'Position',[-10+HOS 50+VOS 200 20],...
    'String', 'Select the Primary Chip Type:',...
    'fontsize', 11);

   % Create Okay push button
    btn = uicontrol('Style', 'pushbutton', 'String', 'Okay',...
        'Position', [300+HOS 25+VOS-OKBL OKBS],...
        'fontweight','bold',...
        'horizontalalign','center',...
        'Callback', @Okay,...
        'fontsize', 11);
       
    f.Visible = 'on';
    CheckRun = 0;
    CheckOkay = 0; 
    ChipType = 'Dummy';
    
    function setChipType(hObject, ~)
        items = get(hObject,'String');
        index_selected = get(hObject,'Value');
        ChipType = items{index_selected};
        CheckRun = 1;
    end
    function Okay(~, ~)
        if CheckRun == 0
            ChipType = 'Full P-Chip';
            close(f);
        else
            close(f);
        end
        CheckOkay = 1;
    end
    if CheckOkay == 0
        uiwait
    else
        uiresume
    end
    
    % Setting offset based on ChipType value (different from OS)
    if strcmp(ChipType, 'Full P-Chip'); Offset1 = -6;
    elseif strcmp(ChipType, '7-Condition Chip'); Offset1 = 15;
    elseif strcmp(ChipType, 'Y-Chip (50x50)'); Offset1 = 6;
    elseif strcmp(ChipType, 'Y-Chip (100x100)'); Offset1 = 14;
    end
    
    %% Create figure again to select magnifcation factor based on chip type
    f = figure('Visible','off',...
               'numbertitle', 'off',...
               'name', 'Select Magnification Factor');
    set(f, 'units', 'centimeters', 'Position', [1 1 11 4])
    movegui(f, 'center');
    
    % Create cell array based on chip selection
    if strcmp(ChipType, 'Full P-Chip')
        PossibleMagFactors = {'8X', '16X', '20X'};
    elseif strcmp(ChipType, '7-Condition Chip')
        PossibleMagFactors = {'10X'};
    elseif strcmp(ChipType, 'Y-Chip (50x50)') || strcmp(ChipType, 'Y-Chip (100x100)')
        PossibleMagFactors = {'20X'};
    else
        PossibleMagFactors = [];
    end
    
    if isempty(PossibleMagFactors) == 1
        QuitErr = errordlg('No chip type selected. Program terminated.',...
                           'Program Terminated');
        return
    end
    
    % Create pop-up menu
    popup = uicontrol('Style', 'popup',...
           'String', PossibleMagFactors,...
           'Position', [20+HOS 36+VOS 200 0],...
           'fontweight','bold',...
           'horizontalalign','center',...
           'Callback', @setMagFactor,...
           'fontsize', 11);

    % Add a text uicontrol to label chip type
    txt = uicontrol('Style','text',...
    'Position',[-7+HOS 81+VOS 200 20],...
    'String', 'Select the Primary Chip Type',...
    'fontsize', 11);

    % Add a text uicontrol to label chip type selection
    txt = uicontrol('Style','text',...
    'Position',[-4+Offset1+HOS 61+VOS 250 20],...
    'String', sprintf('Chip Selected: %s', ChipType),...
    'fontweight', 'bold',...
    'fontsize', 11);

    % Add a text uicontrol to label magnification factor popup
    txt = uicontrol('Style','text',...
    'Position',[-12+HOS 41+VOS 200 20],...
    'String', 'Select Magnification Factor:',...
    'fontsize', 11);

    % Create Okay push button
    btn = uicontrol('Style', 'pushbutton', 'String', 'Okay',...
        'Position', [300+HOS 16+VOS-OKBL OKBS],...
        'fontweight','bold',...
        'horizontalalign','center',...
        'Callback', @Okay2,...
        'fontsize', 11);

    f.Visible = 'on';
    CheckRun = 0;
    CheckOkay = 0; 
    MagFactor = 'Dummy';

    function setMagFactor(hObject, ~)
        items = get(hObject,'String');
        index_selected = get(hObject,'Value');
        MagFactor = items{index_selected};
        CheckRun = 1;
    end
    function Okay2(~, ~)
        if CheckRun == 0
            MagFactor = PossibleMagFactors{1};
            close(f);
        else
            close(f);
        end
        CheckOkay = 1;
    end
    if CheckOkay == 0
        uiwait
    else
        uiresume
    end
    if isempty(MagFactor) == 1 || CheckOkay == 0
        QuitErr = errordlg('No magnification factor selected. Program terminated.',...
                           'Program Terminated');
        return
    end
    % Setting offset based on MagFactor value
    if strcmp(MagFactor, '8X'); Offset2 = 0;
    else; Offset2 = 3;
    end
    
    %% Create figure again to select fluorescent filter type
    f = figure('Visible','off',...
               'numbertitle', 'off',...
               'name', 'Select Fluorescent Filter');
    set(f, 'units', 'centimeters', 'Position', [1 1 11 5])
    movegui(f, 'center');
    
    popup = uicontrol('Style', 'popup',...
           'String', {'TXR', 'GFP', 'Cy5'},...
           'Position', [20+HOS 34+VOS 200 0],...
           'fontweight','bold',...
           'horizontalalign','center',...
           'Callback', @setFluoroFilter,...
           'fontsize', 11);

    % Add a text uicontrol to label chip type
    txt = uicontrol('Style','text',...
    'Position',[-7+HOS 113+VOS 200 20],...
    'String', 'Select the Primary Chip Type',...
    'fontsize', 11);

    % Add a text uicontrol to label chip type selection
    txt = uicontrol('Style','text',...
    'Position',[-4+Offset1+HOS 95+VOS 250 20],...
    'String', sprintf('Chip Selected: %s', ChipType),...
    'fontweight', 'bold',...
    'fontsize', 11);

    % Add a text uicontrol to label magnification factor
    txt = uicontrol('Style','text',...
    'Position',[-13+HOS 76+VOS 200 20],...
    'String', 'Select Magnification Factor:',...
    'fontsize', 11);

    % Add a text uicontrol to label magnification factor selection
    txt = uicontrol('Style','text',...
    'Position',[16+Offset2+HOS 57+VOS 250 20],...
    'String', sprintf('Magnification Factor Selected: %s', MagFactor),...
    'fontweight', 'bold',...
    'fontsize', 11);

    % Add a text uicontrol to label fluorescent filter popup
    txt = uicontrol('Style','text',...
    'Position',[-20+HOS 38+VOS 200 20],...
    'String', 'Select Fluorescent Filter:',...
    'fontsize', 11);

    % Create Okay push button
    btn = uicontrol('Style', 'pushbutton', 'String', 'Okay',...
        'Position', [300+HOS 14+VOS-OKBL OKBS],...
        'fontweight','bold',...
        'horizontalalign','center',...
        'Callback', @Okay3,...
        'fontsize', 11);

    f.Visible = 'on';
    CheckRun = 0;
    CheckOkay = 0; 
    filterUsed = '';

    function setFluoroFilter(hObject, ~)
        items = get(hObject,'String');
        index_selected = get(hObject,'Value');
        filterUsed = items{index_selected};
        CheckRun = 1;
    end
    function Okay3(~, ~)
        if CheckRun == 0
            filterUsed = 'TXR';
            close(f);
        else
            close(f);
        end
        CheckOkay = 1;
    end
    if CheckOkay == 0
        uiwait
    else
        uiresume
    end
    if isempty(filterUsed) == 1
        QuitErr = errordlg('No filter selected. Program terminated.',...
                           'Program Terminated');
        return
    end
    
    % Setting offset based on MagFactor value
    if strcmp(filterUsed, 'Cy5'); Offset3 = -2;
    else; Offset3 = 0;
    end
    
    %% Create figure again to select image file type
    f = figure('Visible','off',...
               'numbertitle', 'off',...
               'name', 'Select Image File Type');
    set(f, 'units', 'centimeters', 'Position', [1 1 11 6])
    movegui(f, 'center');
    
    popup = uicontrol('Style', 'popup',...
           'String', {'tif', 'jpg'},...
           'Position', [20+HOS 32+VOS 200 0],...
           'fontweight','bold',...
           'horizontalalign','center',...
           'Callback', @setImageFileType,...
           'fontsize', 11);

    % Add a text uicontrol to label chip type
    txt = uicontrol('Style','text',...
    'Position',[-7+HOS 147+VOS 200 20],...
    'String', 'Select the Primary Chip Type',...
    'fontsize', 11);

    % Add a text uicontrol to label chip type selection
    txt = uicontrol('Style','text',...
    'Position',[-4+Offset1+HOS 129+VOS 250 20],...
    'String', sprintf('Chip Selected: %s', ChipType),...
    'fontweight', 'bold',...
    'fontsize', 11);

    % Add a text uicontrol to label magnification factor
    txt = uicontrol('Style','text',...
    'Position',[-13+HOS 110+VOS 200 20],...
    'String', 'Select Magnification Factor:',...
    'fontsize', 11);

    % Add a text uicontrol to label magnification factor selection
    txt = uicontrol('Style','text',...
    'Position',[16+Offset2+HOS 91+VOS 250 20],...
    'String', sprintf('Magnification Factor Selected: %s', MagFactor),...
    'fontweight', 'bold',...
    'fontsize', 11);

    % Add a text uicontrol to label fluorescent filter
    txt = uicontrol('Style','text',...
    'Position',[-20+HOS 72+VOS 200 20],...
    'String', 'Select Fluorescent Filter:',...
    'fontsize', 11);

    % Add a text uicontrol to label fluorescent filter selection
    txt = uicontrol('Style','text',...
    'Position',[12+HOS+Offset3 52+VOS 250 20],...
    'String', sprintf('Fluorescent Filter Selected: %s', filterUsed),...
    'fontweight', 'bold',...
    'fontsize', 11);

    % Add a text uicontrol to label image type popup
    txt = uicontrol('Style','text',...
    'Position',[-22+HOS 34+VOS 200 20],...
    'String', 'Select Image File Type:',...
    'fontsize', 11);

    % Create Okay push button
    btn = uicontrol('Style', 'pushbutton', 'String', 'Okay',...
        'Position', [300+HOS 14+VOS-OKBL-2 OKBS],...
        'fontweight','bold',...
        'horizontalalign','center',...
        'Callback', @Okay4,...
        'fontsize', 11);

    f.Visible = 'on';
    CheckRun = 0;
    CheckOkay = 0; 
    TiforJpg = '';

    function setImageFileType(hObject, ~)
        items = get(hObject,'String');
        index_selected = get(hObject,'Value');
        TiforJpg = items{index_selected};
        CheckRun = 1;
    end
    function Okay4(~, ~)
        if CheckRun == 0
            TiforJpg = 'tif';
            close(f);
        else
            close(f);
        end
        CheckOkay = 1;
    end
    if CheckOkay == 0
        uiwait
    else
        uiresume
    end
    if isempty(TiforJpg) == 1
        QuitErr = errordlg('No image file type selected. Program terminated.',...
                           'Program Terminated');
        return
    end
end