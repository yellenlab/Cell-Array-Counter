%%======================================================================%%
% GitHub Repo: https://github.com/yellenlab/Cell-Array-Counter
%
% Description: Code to identify cells or beads within isolate weirs and
% produce heat maps, efficient data, and if on a Windows OS and if MATLAB
% can access Microsoft Word, an automatically generated report if desired
%
% Author: Sean T. Kelly (GitHub Profile: stkelly; Email: seantk@umich.edu)
% Current Affiliation: Ph.D. Pre-Candidate
%                      Applied Nonlinear Dynamics of Multi-Scale Systems Lab
%                      Mechanical Engineering Department, University of Michigan
%
% Created on: 7/27/17
% Last modified on: 10/31/17
%
% Version: 1.0
%
% MIT License
% 
% Copyright (c) 2019 yellenlab
% 
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the 
% "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions:
% 
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
% OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
% THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%======================================================================%%
%
%% INSTRUCTIONS
% 1. Click "Run" to start the program. Make sure you have run
% ExtractUneditedFiles.m, and if using 8X or 10X, also run through
% IsoCropping.m. If not, run those codes, and then you can run this code.
%
% 2. Follow the dialog boxes. Make sure to read them all fully.
%
% OPTIONAL: If further image alignment is needed for the isolated weirs,
% which is likely depending on the accuracy of the cropping, see the readme
% document outline the instructions for aligning images through ImageJ.
% ImageJ is a free, open-source image processing softward that works across
% all major platforms (download: https://imagej.nih.gov/ij/download.html)
%
%% BEGINNING ON CODE SUBSTANCE
tic
clear; close all; format short
% Checking to see if chip type, magnification factor, fluorescent filter
% used, and if the images are tifs or jpgs have been specified by running
% Code1_Extract_Unedited_Files.m. If not, user will be prompted.

% Initializing variables which will change if they have already been set
ChipType   = '';
MagFactor  = '';
filterUsed = '';
TiforJpg   = '';
if exist('ImDetails.mat', 'file') == 2
    DummyVar      = load('ImDetails.mat');
    ChipType      = DummyVar.Chip;
    MagFactor     = DummyVar.Mag;
    filterUsed    = DummyVar.Filter;
    TiforJpg      = DummyVar.ImType;
else
    if isempty(ChipType) == 1
        % Asking user what chip was used for imaging (Full P-Chip or 7-Condition Chip)
        ChipTypeQ = questdlg('What chip was imaged?',...
                             'Chip Imaged',...
                             'Full P-Chip', '7-Condition Chip', 'Y-Chip', 'Full P-Chip');
        if strcmp(ChipTypeQ, 'Full P-Chip') || strcmp(ChipTypeQ, '7-Condition Chip')
            ChipType = ChipTypeQ;
        elseif strcmp(ChipTypeQ, 'Y-Chip')
            ChipTypeQ = questdlg('What size was the Y-Chip?',...
                                'Chip Imaged',...
                                '50x50', '100x100', '100x100');  
            if strcmp(ChipTypeQ, '50x50') 
               ChipType = 'Y-Chip (50x50)';
            elseif strcmp(ChipTypeQ, '100x100')
               ChipType = 'Y-Chip (100x100)'; 
            end
        end
        if isempty(ChipType) == 1
            QuitErr = errordlg('No chip type file type selected. Program Terminated.',...
                               'Program Terminated');
            return
        end
    end
    if isempty(MagFactor) == 1
        % Based on what chip was used, asking user what magnification was used.
        % Magnication Used for Imaging (Set to '8X', '10X', '16X', '20X', or '32X'). Must be a string
        switch ChipType
            case 'Full P-Chip'
                MagFactor = questdlg('Which magnification factor was used?',...
                                     'Magnification Factor',...
                                     '8X', '16X', '20X', '8X');
                if isempty(MagFactor) == 1
                    return
                end

            case '7-Condition Chip'
                MagFactor = questdlg('Was 10X magnification factor used?',...
                                     'Magnification Factor',...
                                     'Yes', 'No', 'Yes');
                switch MagFactor
                    case 'Yes'
                        MagFactor = '10X';
                    case 'No'
                    errordlg('7-Condition chip processing only valid for 10X. Should be P-Chip Design.',...
                             'Incorrect Magnification');
                    return
                end
                if isempty(MagFactor) == 1
                    return
                end
            case 'Y-Chip (50x50)'
                MagFactor = questdlg('Was 20X magnification factor used?',...
                     'Magnification Factor',...
                     'Yes', 'No', 'Yes');
                switch MagFactor
                    case 'Yes'
                        MagFactor = '20X';
                    case 'No'
                    errordlg('Y-Chip (50x50) chip processing only valid for 20X.',...
                             'Incorrect Magnification');
                    return
                end
                if isempty(MagFactor) == 1
                    return
                end
            case 'Y-Chip (100x100)'
                MagFactor = questdlg('Was 20X magnification factor used?',...
                     'Magnification Factor',...
                     'Yes', 'No', 'Yes');
                switch MagFactor
                    case 'Yes'
                        MagFactor = '20X';
                    case 'No'
                    errordlg('Y-Chip (100x100) chip processing only valid for 20X.',...
                             'Incorrect Magnification');
                    return
                end
                if isempty(MagFactor) == 1
                    return
                end

            case 'Cancel'
                return
        end
    end
    if isempty(filterUsed) == 1
        % Fluorescent filter used? Should match start of name (GFP, TXR, or
        % Cy5)
        filterUsed = questdlg('What fluorescent filter was used?',...
                              'Fluorescent Filter',...
                              'TXR', 'GFP', 'Cy5', 'Cy5');
        if isempty(filterUsed) == 1
            QuitErr = errordlg('No filter type selected. Program Terminated.',...
                               'Program Terminated');
            return
        end
    end
    if isempty(TiforJpg) == 1
        TiforJpg = questdlg('What is the image file type?',...
                            'Image File Type',...
                            'tif', 'jpg', 'Cancel', 'tif');
        if strcmp(TiforJpg, 'Cancel')
            return
        end
        if isempty(TiforJpg) == 1
            QuitErr = errordlg('No image file type selected. Program Terminated.',...
                               'Program Terminated');
            return
        end
    end
end

% Setting number of streets and apartments based on chip imaged
if     strcmp(ChipType, 'Full P-Chip')
    StartStreetJ = 0;
    EndStreetJ   = 95; 
    StartAptJ    = 0;
    EndAptJ      = 39;
    TotalNum     = 3840; 

elseif strcmp(ChipType, '7-Condition Chip')
    StartStreetJ = 0;
    EndStreetJ   = 15; 
    StartAptJ    = 0;
    EndAptJ      = 33;
    TotalNum     = 544; 

elseif strcmp(ChipType, 'Y-Chip (50x50)')
    StartStreetJ = 0;
    EndStreetJ   = 49; 
    StartAptJ    = 0;
    EndAptJ      = 49;
    TotalNum     = 2500; % Really 2475, but used this for code

elseif strcmp(ChipType, 'Y-Chip (100x100)')
    StartStreetJ = 0;
    EndStreetJ   = 99; 
    StartAptJ    = 0;
    EndAptJ      = 99;
    TotalNum     = 10000; % Really 9950, but used this for code
end

if strcmp(MagFactor, '8X') || strcmp(MagFactor, '10X') ||...
   (strcmp(MagFactor, '20X') && strcmp(ChipType, 'Y-Chip (50x50)')) ||...
   (strcmp(MagFactor, '20X') && strcmp(ChipType, 'Y-Chip (100x100)'))
    BFDirContImages     = 'BFIsolated';
    FluoroDirContImages = {'FluoroIsolatedFiltered', 'FluoroIsolatedNoFilter'};
else
    BFDirContImages = 'BFUnedited';
    FluoroDirContImages = 'FluoroUnedited';
end

%% Checking to see if data was already processed
prompt00 = {'Enter Experiment/Condition Number (integers only):'};
name00 = 'Experiment/Condition Number';
defaultans00 = {'1'}; % Default answers
ExpNumberInput = inputdlg(prompt00, name00, [1 65], defaultans00);
waitfor(ExpNumberInput)
if isempty(ExpNumberInput) == 1
    return
else
    while isnan(str2double(ExpNumberInput{1})) == 1 || ~mod(str2double(ExpNumberInput{1}),1) == 0
        ExperimentNumError = errordlg('Experiment/Condition number can be an integer value only!',...
                                      'Experiment/Condition Number Error!');
        waitfor(ExperimentNumError)
        ExperimentNumTake2 = inputdlg({'Enter an integer experiment/condition number:'},...
                                       'Experiment Number', [1 50], {'1'});
        if isempty(ExperimentNumTake2) == 1
            return
        end
        ExpNumberInput{1} =  ExperimentNumTake2{1};
    end
ExpCondNumber = str2double(ExpNumberInput{1});
end

TrapEfficName = sprintf('EfficiencyTrapData_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
               StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
AptEfficName = sprintf('EfficiencyAptData_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
               StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
BypassEfficName = sprintf('EfficiencyBypassData_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
               StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);            
if exist(TrapEfficName, 'file') == 2 && exist(AptEfficName, 'file') == 2 && exist(BypassEfficName, 'file') == 2
    CheckforEfficDataQ = questdlg('This data has been fully run before. Do you want to use previous efficiency results?',...
                                 'Use Previous Results?',...
                                 'Yes', 'No', 'Cancel', 'Yes');
    waitfor(CheckforEfficDataQ)
    if strcmp(CheckforEfficDataQ, 'Yes')
        EfficBypassDataDummy = load(BypassEfficName);
        EfficBypassData = EfficBypassDataDummy.EfficBypassData;
        EfficAptDataDummy = load(AptEfficName);
        EfficAptData = EfficAptDataDummy.EfficAptData;
        EfficTrapDataDummy = load(TrapEfficName);
        EfficTrapData = EfficTrapDataDummy.EfficTrapData;
        CheckforEfficData = 1;
               
        UseCustomRegionQ = questdlg(sprintf('Do you want to view a custom region of the %s chip?', ChipType),...
                                    'Custom Region?',...
                                    'Yes', 'No', 'Cancel', 'No');
                                    
        waitfor(UseCustomRegionQ)
        if strcmp(UseCustomRegionQ, 'Yes')
            UseCustomRegion = 1; % Custom region requested
            
            Rangeprompt = {sprintf('Start Street (range: %d < x < %d; must be integer less than end street):', StartStreetJ, EndStreetJ),...
                           sprintf('End Street (range: %d < x < %d; must be integer greater than start street):', StartStreetJ, EndStreetJ),...
                           sprintf('Start Apartment (range: %d < x < %d; must be integer less than end apartment):', StartAptJ, EndAptJ),...
                           sprintf('End Apartment (range: %d < x < %d; must be integer greater than start apartment):', StartAptJ, EndAptJ)};
            Rangename = 'Custom Range Values';
            Rangedefaultans = {num2str(StartStreetJ+2), num2str(EndStreetJ-2),...
                          num2str(StartAptJ+2), num2str(EndAptJ-2)}; % Default answers
                      
            % Custom range values
            CRVs = inputdlg(Rangeprompt, Rangename, [1 80; 1 80; 1 80; 1 80], Rangedefaultans);
            waitfor(CRVs)
            if isempty(CRVs) == 1
               return
            else
                while str2double(CRVs{1}) < StartStreetJ || str2double(CRVs{1}) > EndStreetJ || str2double(CRVs{1}) >= str2double(CRVs{2}) || str2double(CRVs{2}) < StartStreetJ ||...
                      str2double(CRVs{2}) > EndStreetJ || isnan(str2double(CRVs{1})) == 1 || ~mod(str2double(CRVs{1}),1) == 0 || isnan(str2double(CRVs{2})) == 1 || ~mod(str2double(CRVs{2}),1) == 0
                    if str2double(CRVs{1}) < StartStreetJ || str2double(CRVs{1}) > EndStreetJ || str2double(CRVs{1}) >= str2double(CRVs{2}) ||...
                       isnan(str2double(CRVs{1})) == 1 || ~mod(str2double(CRVs{1}),1) == 0
                        CustStreetErr = errordlg(sprintf('Starting street value must be in range %d < x < %d and integer less than end street.', StartStreetJ, EndStreetJ),...
                                                          'Starting Street Error!');
                    elseif str2double(CRVs{2}) < StartStreetJ || str2double(CRVs{2}) > EndStreetJ || str2double(CRVs{1}) >= str2double(CRVs{2}) ||...
                           isnan(str2double(CRVs{2})) == 1 || ~mod(str2double(CRVs{2}),1) == 0 
                        CustStreetErr = errordlg(sprintf('End street value must be in range %d < x < %d and integer greater than start street.', StartStreetJ, EndStreetJ),...
                                                          'End Street Error!');
                    end
                    waitfor(CustStreetErr)
                    CustStreetTake2 = inputdlg({sprintf('Start Street (range: %d < x < %d; must be integer less than end street):', StartStreetJ, EndStreetJ),...
                                                sprintf('End Street (range: %d < x < %d; must be integer greater than start street):', StartStreetJ, EndStreetJ)},...
                                                'Choose Custom Street Range',...
                                                [1 80; 1 80],...
                                                {num2str(StartStreetJ+2), num2str(EndStreetJ-2)});
                    waitfor(CustStreetTake2)
                    if isempty(CustStreetTake2) == 1
                        return
                    end
                    CRVs{1} =  CustStreetTake2{1};
                    CRVs{2} =  CustStreetTake2{2};
                    
                end
                while str2double(CRVs{3}) < StartAptJ || str2double(CRVs{3}) > EndAptJ || str2double(CRVs{3}) >= str2double(CRVs{4}) || str2double(CRVs{4}) < StartAptJ ||...
                      str2double(CRVs{4}) > EndAptJ || isnan(str2double(CRVs{3})) == 1 || ~mod(str2double(CRVs{3}),1) == 0 || isnan(str2double(CRVs{4})) == 1 || ~mod(str2double(CRVs{4}),1) == 0
                    if str2double(CRVs{3}) < StartAptJ || str2double(CRVs{3}) > EndAptJ || str2double(CRVs{3}) >= str2double(CRVs{4}) ||...
                       isnan(str2double(CRVs{3})) == 1 || ~mod(str2double(CRVs{3}),1) == 0
                        CustAptErr = errordlg(sprintf('Starting apartment value must be an integer in range %d < x < %d and less than end apartment.', StartAptJ, EndAptJ),...
                                                          'Starting Street Error!');
                    elseif str2double(CRVs{4}) < StartAptJ || str2double(CRVs{4}) > EndAptJ || str2double(CRVs{3}) >= str2double(CRVs{4}) ||...
                           isnan(str2double(CRVs{4})) == 1 || ~mod(str2double(CRVs{4}),1) == 0
                        CustAptErr = errordlg(sprintf('End apartment value must be an integer in range %d < x < %d and greater than start apartment.', StartAptJ, EndAptJ),...
                                                          'End Street Error!');
                    end
                    waitfor(CustAptErr)
                    CustAptTake2 = inputdlg({sprintf('Start Apartment (range: %d < x < %d; must be integer less than end apartment):', StartAptJ, EndAptJ),...
                                             sprintf('End Apartment (range: %d < x < %d; must be integer greater than start apartment):', StartAptJ, EndAptJ)},...
                                             'Choose Custom Street Range',...
                                             [1 80; 1 90],...
                                             {num2str(StartAptJ+2), num2str(EndAptJ-2)});
                    waitfor(CustAptTake2)
                    if isempty(CustAptTake2) == 1
                        return
                    end
                    CRVs{3} =  CustAptTake2{1};
                    CRVs{4} =  CustAptTake2{2};
                end
            end
            StartStreet  = str2double(CRVs{1}); % Apartment to start from along a street
            EndStreet    = str2double(CRVs{2}); % Apartment to end along a street
            StartApt     = str2double(CRVs{3}); % Street to start on
            EndApt       = str2double(CRVs{4}); % Street to end on
            
            % Allowing heat maps for custom region allowing them to be made
            openFig4   = 1; % Set to open selected region trap heat map
            openFig5   = 1; % Set to open selected region apartment heat map
            openFig6   = 1; % Set to open selected region bypass heat map
            
            % Asking user if they want to open and resave full heat maps
            OpenandSavefullHMs = questdlg('Do you want to also open and resave full heat maps?',...
                                          'Save Full Heat Maps Again?',...
                                          'Yes', 'No', 'Cancel', 'No');
            if strcmp(OpenandSavefullHMs, 'Yes')   
                openFig1   = 1; % Open full trap heat map
                openFig2   = 1; % Open full apartment heat map
                openFig3   = 1; % Open full bypass heat map
                saveFig1   = 1; % Save full trap heat map
                saveFig2   = 1; % Save full apartment heat map
                saveFig3   = 1; % Save full bypass heat map
            elseif strcmp(OpenandSavefullHMs, 'No') 
                openFig1   = 0; % Do not open full trap heat map
                openFig2   = 0; % Do not open full apartment heat map
                openFig3   = 0; % Do not open full bypass heat map
                saveFig1   = 0; % Do not save full trap heat map
                saveFig2   = 0; % Do not save full apartment heat map
                saveFig3   = 0; % Do not save full bypass heat map
            elseif strcmp(OpenandSavefullHMs, 'Cancel') 
                return
            end    

        elseif strcmp(UseCustomRegionQ, 'No')
            UseCustomRegion = 0; % No custom region requested
            % Not allowing heat maps for custom region allowing them to be made
            openFig4   = 0; % Set to open selected region trap heat map
            openFig5   = 0; % Set to open selected region apartment heat map
            openFig6   = 0; % Set to open selected region bypass heat map
            
            % Asking user if they want to open and resave full heat maps
            OpenandSavefullHMs = questdlg('Do you want to open and resave full heat maps?',...
                                          'Save Full Heat Maps Again?',...
                                          'Yes', 'No', 'Cancel', 'No');
            if strcmp(OpenandSavefullHMs, 'Yes')   
                openFig1   = 1; % Open full trap heat map
                openFig2   = 1; % Open full apartment heat map
                openFig3   = 1; % Open full bypass heat map
                saveFig1   = 1; % Save full trap heat map
                saveFig2   = 1; % Save full apartment heat map
                saveFig3   = 1; % Save full bypass heat map
            elseif strcmp(OpenandSavefullHMs, 'No') 
                openFig1   = 0; % Do not open full trap heat map
                openFig2   = 0; % Do not open full apartment heat map
                openFig3   = 0; % Do not open full bypass heat map
                saveFig1   = 0; % Do not save full trap heat map
                saveFig2   = 0; % Do not save full apartment heat map
                saveFig3   = 0; % Do not save full bypass heat map
            elseif strcmp(OpenandSavefullHMs, 'Cancel') 
                return
            end  
        elseif strcmp(UseCustomRegionQ, 'Cancel')
            return
        end
    elseif strcmp(CheckforEfficDataQ, 'No')
        CheckforEfficDataQ2 = questdlg('Are you sure you want to process images again? Running through again will overwrite current efficiency data.',...
                                       'Overwrite Previous Results?',...
                                       'Yes, process again', 'No, don''t overwrite', 'Cancel', 'No, don''t overwrite');
        waitfor(CheckforEfficDataQ2)
        if strcmp(CheckforEfficDataQ2, 'Yes, process again')
            CheckforEfficData = 0;
           
        elseif strcmp(CheckforEfficDataQ2, 'No, don''t overwrite')
            EfficBypassDataDummy = load(BypassEfficName);
            EfficBypassData = EfficBypassDataDummy.EfficBypassData;
            EfficAptDataDummy = load(AptEfficName);
            EfficAptData = EfficAptDataDummy.EfficAptData;
            EfficTrapDataDummy = load(TrapEfficName);
            EfficTrapData = EfficTrapDataDummy.EfficTrapData;
            CheckforEfficData = 1;
            
        elseif strcmp(CheckforEfficDataQ2, 'Cancel')
            return
        end
    elseif strcmp(CheckforEfficDataQ, 'Cancel')
        return
    end
else
    CheckforEfficData = 0;
end

if exist('ParamDetails.mat', 'file') == 2 && CheckforEfficData == 1
    % input all SData parameters which are saved from first run through code
    DummyDetalVar        = load('ParamDetails.mat');
    CellsorBeads         = DummyDetalVar.CellorBeadData;
    TorA                 = DummyDetalVar.TorAData1;
    TrapOrLoad           = DummyDetalVar.TorAData2;
    useTiff              = DummyDetalVar.TifforJpg;
    MinThreshold         = DummyDetalVar.MinThresh;
    Sensitivity          = DummyDetalVar.Sens;
    RadRange             = DummyDetalVar.RR;
    ExpCondNumber     = DummyDetalVar.ExpNumb;
    Day                  = DummyDetalVar.Day;
    Month                = DummyDetalVar.Month;
    Year                 = DummyDetalVar.Year;
    Experimenter         = DummyDetalVar.Experimenter;
    ChipExposure         = DummyDetalVar.ChipExp;
    DRIECycles           = DummyDetalVar.DRIECyc;
    if strcmp(CellsorBeads, 'Cells')
        CelltypeandConc  = DummyDetalVar.CelltypeandConc;
        DyeUsedandConc   = DummyDetalVar.DyeUsedandConc;
    elseif strcmp(CellsorBeads, 'Beads')
        BeadSizeandConc  = DummyDetalVar.BeadSizeandConc;
    end
    SurfTreatment        = DummyDetalVar.SurfTreatment;
    PrimeDirAndCond      = DummyDetalVar.PrimeDirAndCond;
    TrapDirection        = DummyDetalVar.TrapDirection;
    TrapFlowcond         = DummyDetalVar.TrapFlowcond;
    TrapTime             = DummyDetalVar.TrapTime;
    Temperature          = DummyDetalVar.Temperature;
    AptLoadCond          = DummyDetalVar.AptLoadCond;
    AptLoadTime          = DummyDetalVar.AptLoadTime;
    Acoustics            = DummyDetalVar.Acoustics;
    OtherComments        = DummyDetalVar.OtherComments;
    PrintToWordDoc       = DummyDetalVar.PrintToWordDoc;
    dirNameEdited        = DummyDetalVar.dirNameEdited;
    dirNameFluoroOverlay = DummyDetalVar.dirNameFluoroOverlay;
    dirNameTracked       = DummyDetalVar.dirNameTracked;
end

% Asking user if they used cells or beads
if CheckforEfficData == 0
    CellsorBeads = questdlg('Were cells or beads used in this experiment?',...
                            'Cells or Beads',...
                            'Cells', 'Beads', 'Cancel', 'Cells');
    if strcmp(CellsorBeads, 'Cancel')
        return
    end
    SData.CellorBeadData = CellsorBeads;

    % Asking user if they were attempting to trap only, or load into apartments
    if strcmp(CellsorBeads, 'Cells')
        TorAQ = questdlg('Are cells expected to be in traps or apartments?',...
                         'Cell Location',...
                         'Traps', 'Apartments', 'Cancel', 'Traps');
    elseif strcmp(CellsorBeads, 'Beads')
        TorAQ = questdlg('Are beads expected to be in traps or apartments?',...
                     'Cell Location',...
                     'Traps', 'Apartments', 'Cancel', 'Traps');
    end
    if strcmp(TorAQ, 'Traps')
        TorA = 'T';
        TrapOrLoad = 'Trapped';
    elseif strcmp(TorAQ, 'Apartments')
        TorA = 'A';
        TrapOrLoad = 'Loaded';
    elseif strcmp(TorAQ, 'Cancel')
        return
    end
    SData.TorAData1 = TorA; SData.TorAData2 = TrapOrLoad;

    % Asking user if they want to save tracked images as tif or jpg file type
    useTiffQ = questdlg('Save tracked images as tif or jpg file type?',...
                       'Tracked Image File Type',...
                       'jpg', 'tif', 'Cancel', 'jpg');
    waitfor(useTiffQ)
    if strcmp(useTiffQ, 'tif')
        TifWarning = questdlg({sprintf('You are about to save %d images as uncompressed tif files, and as a result will create a large file size.', TotalNum)...
                                 'Are you sure you want to save as tif file type? (jpg recommended)'},...
                                 'Large File Warning!',...
                                 'No, use jpg', 'Yes, use tif', 'Cancel', 'No, use jpg');
        waitfor(TifWarning)
        if     strcmp(TifWarning, 'Yes, use tif')
            useTiff = 1;
        elseif strcmp(TifWarning, 'No, use jpg')
            useTiff = 0;
        elseif strcmp(TifWarning, 'Cancel')
            return
        end
    elseif strcmp(useTiffQ, 'jpg')
        useTiff = 0; % Images will be saved as jpg
    elseif strcmp(useTiffQ, 'Cancel')
        return
    end
    SData.TifforJpg = useTiff;

    % Asking user for image analysis settings with suggested values as default,
    % and if cells are used, setting normalization to 1 (on), or if beads are
    % used, setting normalization to 0 (off). Defining default vals below:

    if strcmp(CellsorBeads, 'Cells')
        MinThreshold = 0.4; % Setting default min threshold value for cells
    elseif strcmp(CellsorBeads, 'Beads')
        MinThreshold = 0.4; % Setting default min threshold value for beads
    end
    Sensitivity = 0.94;     % Setting default sensitivity value for beads and cells
    RadRange = [8 14];      % Setting default radii range for beads and cells
    
    AutoThreshDummy = load('AutoThreshVal.mat'); % Loading automatic threshold value
    AutoThreshVal = AutoThreshDummy.ThreshAve;
    if AutoThreshVal > 0.4
        AutoThreshVal = num2str(0.4);
    else
        AutoThreshVal = num2str(AutoThreshVal);
    end
    
    prompt = {'Enter minimum threshold (between 0 and 1):',...
              'Enter sensitivity (betweeen 0.9 and 1)',...
              'Enter minimum radius to look for in pixels (greater than 5):',...
              'Enter maximum radius to look for in pixels:'};
    name = 'Image Analysis Settings';
    if strcmp(CellsorBeads, 'Cells')
        defaultans = {AutoThreshVal, '0.94', '8', '14'}; % Default answers
        if strcmp(ChipType, 'Y-Chip (50x50)') || strcmp(ChipType, 'Y-Chip (100x100)')
            defaultans = {AutoThreshVal, '0.945', '15', '22'};
        end
        Normalize = 1; Deblur = 1;
    elseif strcmp(CellsorBeads, 'Beads')
        defaultans = {'0.4', '0.94', '8', '14'};
        if strcmp(ChipType, 'Y-Chip (50x50)') || strcmp(ChipType, 'Y-Chip (100x100)')
            defaultans = {'0.35', '0.945', '15', '22'};
        end
        Normalize = 0; Deblur = 0;
    end
    ImageSettings = inputdlg(prompt, name, [1 50; 1 50; 1 65; 1 50], defaultans);
    if isempty(ImageSettings) == 1
       return
    else
        while str2double(ImageSettings{1}) <= 0 || str2double(ImageSettings{1}) >= 1
            MinThreshError = errordlg('Minimum threshold must be a value greater than 0 and less than 1.',...
                                      'Minimum Threshold Error!');
            waitfor(MinThreshError)

            if strcmp(CellsorBeads, 'Cells')
                MinThressTake2 = inputdlg({'Choose and value between 0 and 1, not including 0 or 1:'},...
                                          'Minimum Threshold', [1 60], {'0.4'});
            elseif strcmp(CellsorBeads, 'Beads')
                MinThressTake2 = inputdlg({'Choose a minimum threshold between 0 and 1, not including 0 or 1:'},...
                                          'Minimum Threshold', [1 60], {'0.4'});        
            end
            waitfor(MinThressTake2)
            if isempty(MinThressTake2) == 1
                return
            end
            ImageSettings{1} =  MinThressTake2{1};
        end
        while str2double(ImageSettings{2}) < 0.9 || str2double(ImageSettings{2}) >= 1
            SensitivityError = errordlg('Sensitivity must be a value greater than 0 and less than 1.',...
                                        'Sensitivity Error!');
            waitfor(SensitivityError)

            SensitivityTake2 = inputdlg({'Choose a sensitivity value between 0 and 1, not including 0 or 1:'},...
                                      'Sensitivity', [1 70], {'0.94'});
            waitfor(SensitivityTake2)
            if isempty(SensitivityTake2) == 1
                return
            end
            ImageSettings{2} =  SensitivityTake2{1};
        end                         
        while str2double(ImageSettings{3}) <= 5
            if strcmp(CellsorBeads, 'Cells')
                MinRadRangeError = errordlg('Minimum radius to look for cells must be greater than 5.',...
                                            'Minimum Radius Error!');
            elseif strcmp(CellsorBeads, 'Beads')
                MinRadRangeError = errordlg('Minimum radius to look for beads must be greater than 5.',...
                                            'Minimum Radius Error!');
            end
            waitfor(MinRadRangeError)

            MinRadRangeTake2 = inputdlg({'Choose a minimum radius greater than 5 in pixels:'},...
                                      'Minimum Radius', [1 60], {'8'});
            waitfor(MinRadRangeTake2)
            if isempty(MinRadRangeTake2) == 1
                return
            end
            ImageSettings{3} =  MinRadRangeTake2{1};
        end   

        MinThreshold = str2double(ImageSettings{1}); % Set minimum threshold for fluorescent images
        Sensitivity  = str2double(ImageSettings{2}); % Set the sensitivity for finding beads/cells
        RadRange     = [str2double(ImageSettings{3}) str2double(ImageSettings{4})]; % Set radii range [min max] *must be in this form* 
    end
    SData.MinThresh = MinThreshold; SData.Sens = Sensitivity; SData.RR = RadRange;

    % Asking user for all things that will go into the generated report
    CurrentDate = datetime('now'); % Gets current data and time
    prompt2 = {'Day of month performed (number only):',...
               'Month performed as number (i.e. enter 8 for August):',...
               'Year performed (number only):',...
               'Experimenter:'};
    name2 = 'Basic Experiment Information';
    defaultans2 = {num2str(CurrentDate.Day), num2str(CurrentDate.Month), num2str(CurrentDate.Year), ''}; % Default answers
    BasicReportParams = inputdlg(prompt2, name2, [1 50; 1 65; 1 30; 1 40], defaultans2);
    if isempty(BasicReportParams) == 1
        return
    else
        while isnan(str2double(BasicReportParams{1})) == 1 || ~mod(str2double(BasicReportParams{1}),1) == 0
            DayNumError = errordlg('Day can be an integer value only!',...
                                   'Day Entry Error!');
            waitfor(DayNumError)
            DayNumTake2 = inputdlg({'Enter the day of experiment as an integer:'},...
                                    'Day', [1 50], {'17'});
            if isempty(DayNumTake2) == 1
                return
            end
            BasicReportParams{1} =  DayNumTake2{1};
        end                         
        while isnan(str2double(BasicReportParams{2})) == 1 || ~mod(str2double(BasicReportParams{2}),1) == 0
            MonthNumError = errordlg('Month can be an integer value only!',...
                                     'Month Entry Error!');
            waitfor(MonthNumError)
            MonthNumTake2 = inputdlg({'Enter the month of experiment as an integer (i.e. enter 8 for august):'},...
                                    'Month', [1 80], {'8'});
            if isempty(MonthNumTake2) == 1
                return
            end
            BasicReportParams{2} =  MonthNumTake2{1};
        end
        while isnan(str2double(BasicReportParams{3})) == 1 || ~mod(str2double(BasicReportParams{3}),1) == 0
            YearNumError = errordlg('Year can be an integer value only!',...
                                    'Day Entry Error!');
            waitfor(YearNumError)
            YearNumTake2 = inputdlg({'Enter the year of experiment as an integer:'},...
                                    'Year', [1 60], {'2017'});
            if isempty(YearNumTake2) == 1
                return
            end
            BasicReportParams{3} =  YearNumTake2{1};
        end
    end
    
    Day   = str2double(BasicReportParams{1});
    Month = str2double(BasicReportParams{2});
    Year  = str2double(BasicReportParams{3});            % Date experiment performed *must be numbers*
    Experimenter = BasicReportParams{4};                 % Experimenter *must be a string*
    SData.ExpNumb = ExpCondNumber; SData.Day = Day; SData.Month = Month; SData.Year = Year;
    SData.Experimenter = Experimenter;

    prompt3 = {'Chip Exposure:','DRIE Cycles:'};
    name3 = 'Chip Production Information';
    defaultans3 = {'11 sec.', '190'}; % Default answers
    ChipReportParams = inputdlg(prompt3, name3, [1 50; 1 50], defaultans3);
    if isempty(ChipReportParams) == 1
        return
    end

    ChipExposure = ChipReportParams{1};    % Exposure time for making chip *must be a string*
    DRIECycles   = ChipReportParams{2};    % Number of DRIE cycles for making chip *must be a string*
    SData.ChipExp = ChipExposure; SData.DRIECyc = DRIECycles;

    if strcmp(CellsorBeads, 'Cells')
        prompt4 = {'Cell type and concentration:', 'Cell dye type and concentration:'};
        name4 = 'Cell Information';
        defaultans4 = {'PC9 (8^5/mL)', 'Red (2uM)'}; % Default answers
        CellorBeadReportParams = inputdlg(prompt4, name4, [1 50; 1 50], defaultans4);
        if isempty(CellorBeadReportParams) == 1
            return
        end

        CelltypeandConc = CellorBeadReportParams{1}; % Cell type and concentration *must be a string*
        DyeUsedandConc = CellorBeadReportParams{2};  % Dye used and concentration *must be a string*
        SData.CelltypeandConc = CelltypeandConc; SData.DyeUsedandConc = DyeUsedandConc; 

    elseif strcmp(CellsorBeads, 'Beads')
        prompt4 = {'Bead size in microns and concentration:'};
        name4 = 'Bead Information';
        defaultans4 = {'10'}; % Default answers
        CellorBeadReportParams = inputdlg(prompt4, name4, [1 50], defaultans4);
        if isempty(CellorBeadReportParams) == 1
            return
        end

        BeadSizeandConc = CellorBeadReportParams{1}; % Bead size and concentration *must be a string*
        SData.BeadSizeandConc = BeadSizeandConc; 
    end

    prompt5 = {'Surface Treatment:',...
               'Priming fluids and direction:',...
               'Trapping Direction:',...
               'Trapping flow conditions:',...
               'Time spent trapping:',...
               'Temperature of chip:',...
               'Apartment loading conditions:',...
               'Apartment loading time:',...
               'Acoustic conditions:'};
    name5 = 'Other Experiment Information';
    defaultans5 = {'None', 'Forward with EtOH, PBS, Media', 'Backwards',...
                  'Forward Only at 25 mbar', '1 Hour', 'Room', 'None', 'None', 'None'}; % Default answers
    OtherReportParams = inputdlg(prompt5, name5, [1 50; 1 50; 1 50; 1 50; 1 50; 1 50; 1 50; 1 50; 1 50], defaultans5);
    if isempty(OtherReportParams) == 1
        return
    end

    SurfTreatment    = OtherReportParams{1};    % Enter surface treatment *must be string*
    PrimeDirAndCond  = OtherReportParams{2};    % Enter Priming direction and with what *must be string*
    TrapDirection    = OtherReportParams{3};    % Enter loading direction *must be string*
    TrapFlowcond     = OtherReportParams{4};    % Enter trapping conditions *must be string* 
    TrapTime         = OtherReportParams{5};    % Enter trapping time *must be string* 
    Temperature      = OtherReportParams{6};    % Enter temperature(s) *must be string*
    AptLoadCond      = OtherReportParams{7};    % Enter apt. loading conditions *must be string*
    AptLoadTime      = OtherReportParams{8};    % Enter apt. loading time *must be string*
    Acoustics        = OtherReportParams{9};    % Enter acoustics used if attempted to get into apts. *must be string*
    SData.SurfTreatment = SurfTreatment; SData.PrimeDirAndCond = PrimeDirAndCond; 
    SData.TrapDirection = TrapDirection; SData.TrapFlowcond = TrapFlowcond; 
    SData.TrapTime = TrapTime; SData.Temperature = Temperature; 
    SData.AptLoadCond = AptLoadCond; SData.AptLoadTime = AptLoadTime; 
    SData.Acoustics = Acoustics; 

    prompt6 = {'Other Comments about experiment:'};
    name6 = 'Other';
    defaultans6 = {''}; % Default answers
    OtherCommentsP = inputdlg(prompt6, name6, [1 50], defaultans6);
    if isempty(OtherCommentsP) == 1
        return
    end

    OtherComments = OtherCommentsP{1};  % Enter any further comments on experiment *must be a string*
    SData.OtherComments = OtherComments; 
end % Ending portion where since CheckforEfficData was not 1 (and hence
    % user didn't want to use previous results)
    
% Asking user if they want to generate a report automatically
if CheckforEfficData == 1
    PrintToWordDoc = 0;
else
    PrinttoWorkDocQ = questdlg('Do you want to automatically generate a report of results (Windows Only)?',...
                               'Print Results',...
                               'Yes', 'No', 'Cancel', 'Yes');
    if strcmp(PrinttoWorkDocQ, 'Yes')
        PrintToWordDoc = 1; % When set to 1 prints results to an automatically generated Word document and save it
    elseif strcmp(PrinttoWorkDocQ, 'No')
        PrintToWordDoc = 0;
    elseif strcmp(PrinttoWorkDocQ, 'Cancel')
        return
    end
    SData.PrintToWordDoc = PrintToWordDoc;
end

% Saving all report and other parameters to struct
if CheckforEfficData == 0
    save('ParamDetails.mat','-struct','SData');
end

%% Runing Through Current Efficiency Data if Data has been Processed Once
if CheckforEfficData == 1
    
%% Creating Color Matrix based on Number found in desired region
Height = (StartAptJ+1):(EndAptJ+1);
Length = (StartStreetJ+1):(EndStreetJ+1);

FigureSizes  = [1 6 32 12]; % Sets full figure window sizes; adjust as necessary
FigureSizesR = [2 2 25 20]; % Sets selected region figure window sizes; adjust as necessary

% Custom colormap
colormap_custom(1, 1:3) = [1 0 0];
colormap_custom(2, 1:3) = [0 1 0];
colormap_custom(3, 1:3) = [0 0.4 0];
colormap_custom(4, 1:3) = [0 0.1 0.3];

% Initiliazing matrices and cells used below
x = {[], []}; y = {[], []}; 
CTrap = {[], []}; CApt = {[], []}; CAll = {[], []};


for ii7 = 1:(EndStreetJ+1)
    for ii8 = 1:(EndAptJ+1)
        x{Length(ii7), Height(ii8)} = ...
            [Length(ii7)-1.5 Length(ii7)-0.5 Length(ii7)-0.5 Length(ii7)-1.5];
        y{Length(ii7), Height(ii8)} = ...
            [Height(ii8)-1.5 Height(ii8)-1.5 Height(ii8)-0.5 Height(ii8)-0.5];
        if     EfficTrapData(ii7, ii8) == 0 
            CTrap{Length(ii7), Height(ii8)} = colormap_custom(1, 1:3);
        elseif EfficTrapData(ii7, ii8) == 1 
            CTrap{Length(ii7), Height(ii8)} = colormap_custom(2, 1:3);
        elseif EfficTrapData(ii7, ii8) == 2 
            CTrap{Length(ii7), Height(ii8)} = colormap_custom(3, 1:3);
        elseif EfficTrapData(ii7, ii8) >= 3 
            CTrap{Length(ii7), Height(ii8)} = colormap_custom(4, 1:3);
        end
        if     EfficAptData(ii7, ii8) == 0 
            CApt{Length(ii7), Height(ii8)} = colormap_custom(1, 1:3);
        elseif EfficAptData(ii7, ii8) == 1 
            CApt{Length(ii7), Height(ii8)} = colormap_custom(2, 1:3);
        elseif EfficAptData(ii7, ii8) == 2 
            CApt{Length(ii7), Height(ii8)} = colormap_custom(3, 1:3);
        elseif EfficAptData(ii7, ii8) >= 3 
            CApt{Length(ii7), Height(ii8)} = colormap_custom(4, 1:3);
        end
        if     EfficBypassData(ii7, ii8) <= 0 
            CAll{Length(ii7), Height(ii8)} = colormap_custom(1, 1:3);
        elseif EfficBypassData(ii7, ii8) == 1 
            CAll{Length(ii7), Height(ii8)} = colormap_custom(2, 1:3);
        elseif EfficBypassData(ii7, ii8) == 2 
            CAll{Length(ii7), Height(ii8)} = colormap_custom(3, 1:3);
        elseif EfficBypassData(ii7, ii8) >= 3 
            CAll{Length(ii7), Height(ii8)} = colormap_custom(4, 1:3);
        end
    end
end

%% Creating heat map for trap of total chip 
if openFig1 == 1
    tStart1 = tic;
    figure(1); clf
    set(gcf, 'units', 'centimeters', 'Position', FigureSizes)
    for ii7 = 1:(EndStreetJ+1)
        for ii8 = 1:(EndAptJ+1)
            patch(x{Length(ii7), Height(ii8)}, y{Length(ii7), Height(ii8)}, CTrap{Length(ii7), Height(ii8)})
            if mod(ii7-1, 10) == 0 && mod(ii8-1, 3) == 0
            end
        end
    end

    hold on;
    h = zeros(4, 1);
    for ii9 = 2:4
        h(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                     'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
        h(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                     'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
    end
    lgd = legend(h, '0', '1', '2', '3+', 'Location', 'Eastoutside');
    lgd.FontSize = 20;
    axis([min(x{Length(1), Height(1)}) max(x{Length(EndStreetJ+1), Height(EndAptJ+1)}) ...
          min(y{Length(1), Height(1)}) max(y{Length(EndStreetJ+1), Height(EndAptJ+1)})])
    set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
    set(gca,'XtickLabel', 0:2:(length(Length)-1))
    set(gca,'YTick', 0:2:(length(Height)-1), 'Fontsize', 10)
    set(gca,'YtickLabel', 0:2:(length(Height)-1))
    xlabel('Street', 'Fontsize', 16)
    ylabel('Apartment', 'Fontsize', 16)
    title('Trap Population Heat Map', 'Fontsize', 16)
    
    if saveFig1 == 1
        % Saving Figure 1
        Fig1NameD = sprintf('Trap_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                           StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
        saveas(figure(1), Fig1NameD)
        Fig1NameD = sprintf('Trap_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
        saveas(figure(1), Fig1NameD)
    end
    toc(tStart1)
end

%% Creating heat map for apartment of total chip 
if openFig2 == 1
    tStart2 = tic;
    figure(2); clf
    set(gcf, 'units', 'centimeters', 'Position', FigureSizes)
    for ii7 = 1:(EndStreetJ+1)
        for ii8 = 1:(EndAptJ+1)
            patch(x{Length(ii7), Height(ii8)}, y{Length(ii7), Height(ii8)}, CApt{Length(ii7), Height(ii8)})
            if mod(ii7-1, 10) == 0 && mod(ii8-1, 3) == 0
            end
        end
    end

    hold on
    h2 = zeros(4, 1);
    for ii9 = 2:4
        h2(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                      'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
        h2(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                      'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
    end
    lgd2 = legend(h2, '0', '1', '2', '3+', 'Location', 'Eastoutside');
    lgd2.FontSize = 20;
    axis([min(x{Length(1), Height(1)}) max(x{Length(EndStreetJ+1), Height(EndAptJ+1)}) ...
          min(y{Length(1), Height(1)}) max(y{Length(EndStreetJ+1), Height(EndAptJ+1)})])
    set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
    set(gca,'XtickLabel', 0:2:(length(Length)-1))
    set(gca,'YTick', 0:2:(length(Height)-1), 'Fontsize', 10)
    set(gca,'YtickLabel', 0:2:(length(Height)-1))
    xlabel('Street', 'Fontsize', 16)
    ylabel('Apartment', 'Fontsize', 16)
    title('Apartment Population Heat Map', 'Fontsize', 16)

    if saveFig2 == 1
        % Saving Figure 2
        Fig2Name = sprintf('Apt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                           StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
        saveas(figure(2), Fig2Name)
        Fig2Name = sprintf('Apt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
        saveas(figure(2), Fig2Name)
    end
    toc(tStart2)
end

%% Creating heat map for bypass of total chip 
if openFig3 == 1
    tStart3 = tic;
    figure(3); clf
    set(gcf, 'units', 'centimeters', 'Position', FigureSizes)
    for ii7 = 1:(EndStreetJ+1)
        for ii8 = 1:(EndAptJ+1)
            patch(x{Length(ii7), Height(ii8)}, y{Length(ii7), Height(ii8)}, CAll{Length(ii7), Height(ii8)})
            if mod(ii7-1, 10) == 0 && mod(ii8-1, 3) == 0
            end
        end
    end

    hold on
    h3 = zeros(4, 1);
    for ii9 = 2:4
        h3(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                      'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
        h3(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                      'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
    end
    lgd2 = legend(h3, '0', '1', '2', '3+', 'Location', 'Eastoutside');
    lgd2.FontSize = 20;
    axis([min(x{Length(1), Height(1)}) max(x{Length(EndStreetJ+1), Height(EndAptJ+1)}) ...
          min(y{Length(1), Height(1)}) max(y{Length(EndStreetJ+1), Height(EndAptJ+1)})])
    set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
    set(gca,'XtickLabel', 0:2:(length(Length)-1))
    set(gca,'YTick', 0:2:(length(Height)-1), 'Fontsize', 10)
    set(gca,'YtickLabel', 0:2:(length(Height)-1))
    xlabel('Street', 'Fontsize', 16)
    ylabel('Apartment', 'Fontsize', 16)
    title('Bypass Population Heat Map', 'Fontsize', 16)

    if saveFig3 == 1
        % Saving Figure 3
        Fig3Name = sprintf('Bypass_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                           StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
        saveas(figure(3), Fig3Name)
        Fig3Name = sprintf('Bypass_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
        saveas(figure(3), Fig3Name)
    end
    
    % Saving not apartment effiency data containing matrix of beads found
    BypassEfficName = sprintf('EfficiencyBypassData_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                       StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
    save(BypassEfficName, 'EfficBypassData')

    toc(tStart3)
end

%% Creating heats maps for selected region from total chip
if UseCustomRegion == 1
    HeightR = (StartApt+1):(EndApt+1);
    LengthR = (StartStreet+1):(EndStreet+1);
    EfficTrapDataR  = EfficTrapData((StartStreet+1):(EndStreet+1), (StartApt+1):(EndApt+1));
    EfficAptDataR   = EfficAptData((StartStreet+1):(EndStreet+1), (StartApt+1):(EndApt+1));
    EfficBypassDataR = EfficBypassData((StartStreet+1):(EndStreet+1), (StartApt+1):(EndApt+1));
    
    if openFig4 == 1
        % Plotting Selected Region Trap Heat Map
        figure(4); clf
        set(gcf, 'units', 'centimeters', 'Position', FigureSizesR)
        for ii7 = 1:length(LengthR)
            for ii8 = 1:length(HeightR)
                patch(x{LengthR(ii7), HeightR(ii8)}, y{LengthR(ii7), HeightR(ii8)}, CTrap{LengthR(ii7), HeightR(ii8)})
                if mod(ii7-1, 10) == 0 && mod(ii8-1, 3) == 0
                end
            end
        end
        hold on;
        h = zeros(4, 1);
        for ii9 = 2:4
            h(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                         'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
            h(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                         'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
        end
        lgd2 = legend(h, '0', '1', '2', '3+', 'Location', 'Eastoutside');
        lgd2.FontSize = 20;
        axis([min(x{LengthR(1), HeightR(1)}) max(x{LengthR(end), HeightR(end)}) ...
              min(y{LengthR(1), HeightR(1)}) max(y{LengthR(end), HeightR(end)})])
        if max(x{LengthR(end), HeightR(end)}) >= 45
            set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
            set(gca,'XtickLabel', 0:2:(length(Length)-1))
        else
            set(gca,'XTick', 0:1:(length(Length)-1), 'Fontsize', 10)
            set(gca,'XtickLabel', 0:1:(length(Length)-1))
        end
        set(gca,'YTick', HeightR-1, 'Fontsize', 10)
        set(gca,'YtickLabel', HeightR-1)
        xlabel('Street', 'Fontsize', 16)
        ylabel('Apartment', 'Fontsize', 16)
        title('Trap Population Heat Map', 'Fontsize', 16)
    end
    
    if openFig5 == 1
        % Plotting Selected Region Apt Heat Map
        figure(5); clf
        set(gcf, 'units', 'centimeters', 'Position', FigureSizesR)
        for ii7 = 1:length(LengthR)
            for ii8 = 1:length(HeightR)
                patch(x{LengthR(ii7), HeightR(ii8)}, y{LengthR(ii7), HeightR(ii8)}, CApt{LengthR(ii7), HeightR(ii8)})
                if mod(ii7-1, 10) == 0 && mod(ii8-1, 3) == 0
                end
            end
        end
        hold on
        h2 = zeros(4, 1);
        for ii9 = 2:4
            h2(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                          'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
            h2(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                          'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
        end
        lgd2 = legend(h2, '0', '1', '2', '3+', 'Location', 'Eastoutside');
        lgd2.FontSize = 20;
        axis([min(x{LengthR(1), HeightR(1)}) max(x{LengthR(end), HeightR(end)}) ...
              min(y{LengthR(1), HeightR(1)}) max(y{LengthR(end), HeightR(end)})])
        if max(x{LengthR(end), HeightR(end)}) >= 45
            set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
            set(gca,'XtickLabel', 0:2:(length(Length)-1))
        else
            set(gca,'XTick', 0:1:(length(Length)-1), 'Fontsize', 10)
            set(gca,'XtickLabel', 0:1:(length(Length)-1))
        end
        set(gca,'YTick', HeightR-1, 'Fontsize', 10)
        set(gca,'YtickLabel', HeightR-1)
        xlabel('Street', 'Fontsize', 16)
        ylabel('Apartment', 'Fontsize', 16)
        title('Apartment Population Heat Map', 'Fontsize', 16)
    end
    
    if openFig6 == 1
        % Plotting Selected Region Bypass Heat Map
        figure(6); clf
        set(gcf, 'units', 'centimeters', 'Position', FigureSizesR)
        for ii7 = 1:length(LengthR)
            for ii8 = 1:length(HeightR)
                patch(x{LengthR(ii7), HeightR(ii8)}, y{LengthR(ii7), HeightR(ii8)}, CAll{LengthR(ii7), HeightR(ii8)})
                if mod(ii7-1, 10) == 0 && mod(ii8-1, 3) == 0
                end
            end
        end
        hold on
        h3 = zeros(4, 1);
        for ii9 = 2:4
            h3(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                          'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
            h3(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                          'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
        end
        lgd2 = legend(h3, '0', '1', '2', '3+', 'Location', 'Eastoutside');
        lgd2.FontSize = 20;
        axis([min(x{LengthR(1), HeightR(1)}) max(x{LengthR(end), HeightR(end)}) ...
              min(y{LengthR(1), HeightR(1)}) max(y{LengthR(end), HeightR(end)})])
        if max(x{LengthR(end), HeightR(end)}) >= 45
            set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
            set(gca,'XtickLabel', 0:2:(length(Length)-1))
        else
            set(gca,'XTick', 0:1:(length(Length)-1), 'Fontsize', 10)
            set(gca,'XtickLabel', 0:1:(length(Length)-1))
        end
        set(gca,'YTick', HeightR-1, 'Fontsize', 10)
        set(gca,'YtickLabel', HeightR-1)
        xlabel('Street', 'Fontsize', 16)
        ylabel('Apartment', 'Fontsize', 16)
        title('Bypass Population Heat Map', 'Fontsize', 16)
    end
end

%% Finding and Printing Out Efficiency Data for All Data
TotalAptNum  = length(Height).*length(Length);

% Correction factors based on chip type
CF = 0;
if strcmp(ChipType, 'Y-chip (50x50)') || strcmp(ChipType, 'Y-chip (100x100)')
    CF = (EndStreetJ+1)./2; % Equals number of streets/2
    TotalAptNum = TotalAptNum - CF;
end

% Finding efficiencies
NumTrap0     = length(find(EfficTrapData <= 0)) - CF; NumTrap0Eff     = NumTrap0/TotalAptNum;
NumTrap1     = length(find(EfficTrapData == 1));      NumTrap1Eff     = NumTrap1/TotalAptNum;
NumTrap2     = length(find(EfficTrapData == 2));      NumTrap2Eff     = NumTrap2/TotalAptNum;
NumTrap3More = length(find(EfficTrapData >= 3));      NumTrap3EffMore = NumTrap3More/TotalAptNum; 

NumApt0     = length(find(EfficAptData <= 0)) - CF; NumApt0Eff     = NumApt0/TotalAptNum;
NumApt1     = length(find(EfficAptData == 1));      NumApt1Eff     = NumApt1/TotalAptNum;
NumApt2     = length(find(EfficAptData == 2));      NumApt2Eff     = NumApt2/TotalAptNum;
NumApt3More = length(find(EfficAptData >= 3));      NumApt3EffMore = NumApt3More/TotalAptNum;

NumBypass0     = length(find(EfficBypassData <= 0)) - CF; NumBypass0Eff     = NumBypass0/TotalAptNum;
NumBypass1     = length(find(EfficBypassData == 1));      NumBypass1Eff     = NumBypass1/TotalAptNum;
NumBypass2     = length(find(EfficBypassData == 2));      NumBypass2Eff     = NumBypass2/TotalAptNum;
NumBypass3More = length(find(EfficBypassData >= 3));      NumBypass3EffMore = NumBypass3More/TotalAptNum;

Num0    = [NumTrap0Eff;         NumApt0Eff;         NumBypass0Eff].*100;
Num1    = [NumTrap1Eff;         NumApt1Eff;         NumBypass1Eff].*100;
Num2    = [NumTrap2Eff;         NumApt2Eff;         NumBypass2Eff].*100;
Num3    = [NumTrap3EffMore;     NumApt3EffMore;     NumBypass3EffMore].*100;
TotPerc = [(NumTrap0Eff   + NumTrap1Eff   + NumTrap2Eff   + NumTrap3EffMore); ...
           (NumApt0Eff    + NumApt1Eff    + NumApt2Eff    + NumApt3EffMore); ...
           (NumBypass0Eff + NumBypass1Eff + NumBypass2Eff + NumBypass3EffMore)].*100;

% Displaying in Table
Name = {'Trap'; 'Apartment'; 'Bypass'};
EfficiencyTab = table(categorical(Name), Num0, Num1, Num2, Num3, TotPerc, ...
    'VariableNames', {'Region' 'None' 'Single' 'Double' 'TripleOrMore' 'Total'});
disp(EfficiencyTab)

% Saving Table
TableName = sprintf('Efficiency_Table_Streets%d-%d_Apts%d-%d_Exp%d',...
                     StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
writetable(EfficiencyTab, TableName,'Delimiter',' ')  

%% Finding and Printing Out Efficiency Data for Selected Region
if UseCustomRegion == 1 
    TotalAptNumR  = length(HeightR).*length(LengthR);

    % Finding efficiencies
    NumTrap0R     = length(find(EfficTrapDataR <= 0)); NumTrap0EffR     = NumTrap0R./TotalAptNumR;
    NumTrap1R     = length(find(EfficTrapDataR == 1)); NumTrap1EffR     = NumTrap1R./TotalAptNumR;
    NumTrap2R     = length(find(EfficTrapDataR == 2)); NumTrap2EffR     = NumTrap2R./TotalAptNumR;
    NumTrap3MoreR = length(find(EfficTrapDataR >= 3)); NumTrap3EffMoreR = NumTrap3MoreR./TotalAptNumR;

    NumApt0R     = length(find(EfficAptDataR <= 0)); NumApt0EffR     = NumApt0R./TotalAptNumR;
    NumApt1R     = length(find(EfficAptDataR == 1)); NumApt1EffR     = NumApt1R./TotalAptNumR;
    NumApt2R     = length(find(EfficAptDataR == 2)); NumApt2EffR     = NumApt2R./TotalAptNumR;
    NumApt3MoreR = length(find(EfficAptDataR >= 3)); NumApt3EffMoreR = NumApt3MoreR./TotalAptNumR;

    NumBypass0R     = length(find(EfficBypassDataR <= 0)); NumBypass0EffR     = NumBypass0R./TotalAptNumR;
    NumBypass1R     = length(find(EfficBypassDataR == 1)); NumBypass1EffR     = NumBypass1R./TotalAptNumR;
    NumBypass2R     = length(find(EfficBypassDataR == 2)); NumBypass2EffR     = NumBypass2R./TotalAptNumR;
    NumBypass3MoreR = length(find(EfficBypassDataR >= 3)); NumBypass3EffMoreR = NumBypass3MoreR./TotalAptNumR;

    Num0R    = [NumTrap0EffR;         NumApt0EffR;         NumBypass0EffR].*100;
    Num1R    = [NumTrap1EffR;         NumApt1EffR;         NumBypass1EffR].*100;
    Num2R    = [NumTrap2EffR;         NumApt2EffR;         NumBypass2EffR].*100;
    Num3R    = [NumTrap3EffMoreR;     NumApt3EffMoreR;     NumBypass3EffMoreR].*100;
    TotPercR = [(NumTrap0EffR   + NumTrap1EffR   + NumTrap2EffR   + NumTrap3EffMoreR); ...
               (NumApt0EffR    + NumApt1EffR    + NumApt2EffR    + NumApt3EffMoreR); ...
               (NumBypass0EffR + NumBypass1EffR + NumBypass2EffR + NumBypass3EffMoreR)].*100;

    % Displaying in Table
    Name = {'Trap'; 'Apartment'; 'Bypass'};
    EfficiencyTab = table(categorical(Name), Num0R, Num1R, Num2R, Num3R, TotPercR, ...
        'VariableNames', {'SelectedRegion' 'None' 'Single' 'Double' 'TripleOrMore' 'Total'});
    disp(EfficiencyTab)
                
    % Asking user if they want to save region efficiency data
    SaveEfficRegData = questdlg('Do you want to save custom region efficiency data?',...
                                  'Save Region Efficiency Data?',...
                                  'Yes', 'No', 'Cancel', 'Yes');
    if strcmp(SaveEfficRegData, 'Yes')   
        saveRegEff = 1; % Save efficiency data from selected region
    elseif strcmp(SaveEfficRegData, 'No')   
        saveRegEff = 0; % Do not save efficiency data from selected region 
    elseif strcmp(SaveEfficRegData, 'Cancel') 
        return
    end 
    if saveRegEff == 1
        % Saving Table
        if StartStreet == StartStreetJ && EndStreet == EndStreetJ && StartApt == StartAptJ && EndApt == EndAptJ
        else
            TableNameR = sprintf('Efficiency_Table_SelectedRegion_Streets%d-%d_Apts%d-%d_Exp%d',...
                                 StartStreet, EndStreet, StartApt, EndApt', ExpCondNumber);
            writetable(EfficiencyTab, TableNameR,'Delimiter',' ')  
        end
    end
end

% Asking user if they want to save the custom region heat maps
if openFig4 == 1 && openFig5 == 1 && openFig6 == 1 
    SaveRegHeatMaps = questdlg('Do you want to save custom region heat maps?',...
                               'Save Region Heat Maps?',...
                               'Yes', 'No', 'Cancel', 'Yes');
    if strcmp(SaveRegHeatMaps, 'Yes')   
    % If user wants to save heat maps from question above
        % Saving Figure 4
    if StartStreet == StartStreetJ && EndStreet == EndStreetJ && StartApt == StartAptJ && EndApt == EndAptJ
    else
        Fig4Name = sprintf('Selected_Trap_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                           StartStreet, EndStreet, StartApt, EndApt', ExpCondNumber);
        saveas(figure(4), Fig4Name)
        Fig5Name = sprintf('Selected_Apt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                           StartStreet, EndStreet, StartApt, EndApt', ExpCondNumber);
        saveas(figure(5), Fig5Name)
        Fig6Name = sprintf('Selected_Bypass_Population_Heat_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                           StartStreet, EndStreet, StartApt, EndApt', ExpCondNumber);
        saveas(figure(6), Fig6Name)
    end
    elseif strcmp(SaveRegHeatMaps, 'Cancel') 
        return
    end
end

%% Easter Egg
NumApt1EffR = 0; % Setting to a value to not cause an error if no custom region is desired
if NumApt1Eff >= 0.87 || NumApt1EffR >= 0.87
    figure(7); clf
    axis([-5 5 -5 5])
    patch([-5 5 5 -5], [-5 -5 5 5], [0 0 0])
    hold on
    for ee = 3:20
        Locx = -3 + (6).*rand(20, 1); Locy = -4 + (8).*rand(20, 1);
        uix = text(Locx(ee), Locy(ee), 'SUSHI!!!');
        uix.FontSize = 30;
        if mod(ee, 3)-1 == -1
            uix.Color = [1 0 0];
        elseif mod(ee, 3)-1 == 0
            uix.Color = [0 1 0];
        else 
            uix.Color = [0 0 1];
        end
        uix.HorizontalAlignment = 'center';
        pause(0.2);
        delete(uix)
    end
    uix = text(0, 0, 'SUSHI!!!');
    uix.FontSize = 80;
    uix.Color = [1 0 0];
    uix.HorizontalAlignment = 'center';
    hold off
end

else

% Making directories to save edited BF, BF Tracked, and overlayed GFP images
dirNameEdited = sprintf('BFEdited_Images_Exp%d', ExpCondNumber);
mkdir(dirNameEdited)
SData.dirNameEdited = dirNameEdited;
dirNameFluoroOverlay = sprintf('FluoroOverlay_Images_Exp%d', ExpCondNumber);
mkdir(dirNameFluoroOverlay)
SData.dirNameFluoroOverlay = dirNameFluoroOverlay;
dirNameTracked = sprintf('Tracked_Images_Exp%d', ExpCondNumber);
mkdir(dirNameTracked)   
SData.dirNameTracked = dirNameTracked;

save('ParamDetails.mat','-struct','SData');

h1 = waitbar(0, 'Loading in images...');
steps1 = TotalNum;
step1 = 1;
StreetNumbers = (StartStreetJ+1):(EndStreetJ+1); % Street numbers to consider

% Initializing cells used below
BFimages = {[], []}; GFPimages = {[], [], []};

for iii = (StartStreetJ+1):(EndStreetJ+1)
    for ii = (StartAptJ+1):(EndAptJ+1)
        if     (ii-1) < 10 && (iii-1) < 10
            BFfilename = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000.jpg', BFDirContImages, MagFactor, iii-1, ii-1);
        elseif (ii-1) >= 10 && (ii-1) < 100 && (iii-1) < 10
            BFfilename = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000.jpg', BFDirContImages, MagFactor, iii-1, ii-1);
        elseif (ii-1) < 10 && (iii-1) >= 10 && (iii-1) < 100
            BFfilename = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000.jpg', BFDirContImages, MagFactor, iii-1, ii-1);
        elseif (ii-1) >= 10 && (ii-1) < 100 && (iii-1) >= 10 && (iii-1) < 100
            BFfilename = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000.jpg', BFDirContImages, MagFactor, iii-1, ii-1);
        end
        if     (ii-1) < 10 && (iii-1) < 10
            GFPfilenameFilt = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000.jpg', FluoroDirContImages{1}, filterUsed, MagFactor, iii-1, ii-1);
            GFPfilenameNoFilt = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000.jpg', FluoroDirContImages{2}, filterUsed, MagFactor, iii-1, ii-1);
        elseif (ii-1) >= 10 && (ii-1) < 100 && (iii-1) < 10
            GFPfilenameFilt = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000.jpg', FluoroDirContImages{1}, filterUsed, MagFactor, iii-1, ii-1);
            GFPfilenameNoFilt = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000.jpg', FluoroDirContImages{2}, filterUsed, MagFactor, iii-1, ii-1);
        elseif (ii-1) < 10 && (iii-1) >= 10 && (iii-1) < 100
            GFPfilenameFilt = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000.jpg', FluoroDirContImages{1}, filterUsed, MagFactor, iii-1, ii-1);
            GFPfilenameNoFilt = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000.jpg', FluoroDirContImages{2}, filterUsed, MagFactor, iii-1, ii-1);
        elseif (ii-1) >= 10 && (ii-1) < 100 && (iii-1) >= 10 && (iii-1) < 100
            GFPfilenameFilt = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000.jpg', FluoroDirContImages{1}, filterUsed, MagFactor, iii-1, ii-1);
            GFPfilenameNoFilt = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000.jpg', FluoroDirContImages{2}, filterUsed, MagFactor, iii-1, ii-1);
        end
        BFimages{iii, ii} = imread(BFfilename);
        GFPimages{iii, ii, 1} = imread(GFPfilenameFilt);
        GFPimages{iii, ii, 2} = imread(GFPfilenameNoFilt);
        
        waitbar(step1/steps1)
        step1 = step1 + 1;
    end
end
close(h1)

hm = waitbar(0, 'Adjusting for second alignment if provided...');
stepsm = TotalNum;
stepm = 1;

% Input .txt filename to pull image J data from
if exist('DisplacementLog.txt', 'file') == 0
    if strcmp(ChipType, 'Y-Chip (50x50)') || strcmp(ChipType, 'Y-Chip (100x100)')
        DispLog = zeros(TotalNum, 4);
    else
        DispLog = zeros(TotalNum-1, 4);
    end
else
    DispLog = load('DisplacementLog.txt');  
end  

% Processing data from Image J
Slice = zeros((EndStreetJ-StartStreetJ+1).*(EndAptJ-StartAptJ+1), 1);
Slice(2:length(DispLog(:, 2))+1) = DispLog(1:length(DispLog(:, 2)), 2); 
Slice = vec2mat(Slice, EndAptJ - StartAptJ + 1);
SliceEdit = Slice(1:EndStreetJ-StartStreetJ+1, 1:EndAptJ-StartAptJ+1);

SliceDx = zeros((EndStreetJ-StartStreetJ+1).*(EndAptJ-StartAptJ+1), 1);
SliceDx(2:length(DispLog(:, 3))+1) = DispLog(1:length(DispLog(:, 3)), 3); 
SliceDx(2:length(DispLog(:, 3))+1) = DispLog(1:length(DispLog(:, 3)), 3); 
SliceDx = vec2mat(SliceDx, EndAptJ - StartAptJ + 1);
SliceDxEdit = SliceDx(1:EndStreetJ-StartStreetJ+1, 1:EndAptJ-StartAptJ+1);

SliceDy = zeros((EndStreetJ-StartStreetJ+1).*(EndAptJ-StartAptJ+1), 1);
SliceDy(2:length(DispLog(:, 4))+1) = DispLog(1:length(DispLog(:, 4)), 4); 
SliceDy(2:length(DispLog(:, 4))+1) = DispLog(1:length(DispLog(:, 4)), 4); 
SliceDy = vec2mat(SliceDy, EndAptJ - StartAptJ + 1);
SliceDyEdit = SliceDy(1:EndStreetJ-StartStreetJ+1, 1:EndAptJ-StartAptJ+1);

% Taking chosen images and applying ImageJ Translations to both BF and GFP Images
tform = {[], []}; BFShifted = {[], []}; GFPShifted = {[], [], []};

for i3 = 1:2
    for iii3 = 1:(EndStreetJ+1)
        for ii3 = 1:(EndAptJ+1)
            T = [1 0 0; 0 1 0; SliceDxEdit(iii3, ii3) SliceDyEdit(iii3, ii3) 1];
            tform{iii3, ii3} = affine2d(T);
            BFShifted{iii3, ii3} = imwarp_same(BFimages{iii3, ii3}, tform{iii3, ii3});
            GFPShifted{iii3, ii3, i3} = imwarp_same(GFPimages{iii3, ii3, i3}, tform{iii3, ii3});
            waitbar((stepm/2)/stepsm)
            stepm = stepm + 1;
        end
    end
end
close(hm)        

%% Selecting Crop Region for Whole Apartment Complex if Necessary
RotCropBFImages = {[], []}; % Initializing cell for rotated and cropped imagas
if strcmp(MagFactor, '8X') || strcmp(MagFactor, '10X') ||...
         (strcmp(MagFactor, '20X') && strcmp(ChipType, 'Y-Chip (50x50)')) ||...
         (strcmp(MagFactor, '20X') && strcmp(ChipType, 'Y-Chip (100x100)'))
    for iii3 = 1:(EndStreetJ+1)
        for ii3 = 1:(EndAptJ+1)
            RotCropBFImages{iii3, ii3} = BFShifted{iii3, ii3};
        end
    end
else
    AptComplexCrop = []; % Initializing apartment complex crop matrix

    AptComplexCropName = sprintf('AptComplexCropMat_Streets%d-%d_Apts%d-%d_1.mat',...
                                 StartStreetJ, EndStreetJ, StartAptJ, EndAptJ);

    % Checking to see if apartment complex is cropped before, and if user
    % wants to use that region again
    if exist(AptComplexCropName, 'file') == 2
        CheckifCropped1 = questdlg('Do you want to use previous cropping apartment complex cropping region?',...
                                  'Use Previous Crop?',...
                                  'Yes', 'No', 'Cancel', 'Yes');
        waitfor(CheckifCropped1);
        if strcmp(CheckifCropped1, 'Cancel')
            return
        end
    end                      

    % Checking to see if the name previously exists 
    if exist(AptComplexCropName, 'file') == 2 && strcmp(CheckifCropped1, 'Yes')
        AptComplexCropDummy = load(AptComplexCropName);
        xTotal = AptComplexCropDummy.AptComplexCrop(:, 1);
        yTotal = AptComplexCropDummy.AptComplexCrop(:, 2);
    else
        imshow(BFShifted{StartStreetJ+1, StartAptJ+1})
        AptCompmsg = msgbox('Please choose top left and bottom right corners for apartment complex.');
        waitfor(AptCompmsg)
        [xTotal, yTotal] = ginput(2);

        AptComplexCrop = [xTotal yTotal];
        AptComplexCropName = sprintf('AptComplexCropMat_Streets%d-%d_Apts%d-%d_1.mat',...
                                     StartStreetJ, EndStreetJ, StartAptJ, EndAptJ);
        save(AptComplexCropName, 'AptComplexCrop')
        CurrentFig = gcf; close(CurrentFig)
        CheckVar = 1; % If this exists, crop region was changed, and other regions need to be selected again
    end

    %% Rotating and Cropping Images
    for iii3 = 1:(EndStreetJ+1)
        for ii3 = 1:(EndAptJ+1)
            RotCropBFImages{iii3, ii3} = imcrop(imrotate(BFShifted{iii3, ii3}, 0),...
                                         [xTotal(1) yTotal(1) (xTotal(2)-xTotal(1)) (yTotal(2)-yTotal(1))]);
        end
    end
end
%% Selecting Crop Regions for Trap Region and Apartment
% Checking to see if trap and apartment are cropped before, and if user
% wants to use that region again. If apartment was cropped, must do both
% trap and apartment cropping again
TrapCrop = []; % Initializing trap crop matrix
TrapCropName = sprintf('TrapCropMat_Streets%d-%d_Apts%d-%d_1.mat',...
                       StartStreetJ, EndStreetJ, StartAptJ, EndAptJ);

if exist(TrapCropName, 'file') == 2 && exist('CheckVar', 'var') == 0 
    CheckifCropped2 = questdlg('Do you want to use previous trap cropping region?',...
                              'Use Previous Crop?',...
                              'Yes', 'No', 'Cancel', 'Yes');
    waitfor(CheckifCropped2);
    if strcmp(CheckifCropped2, 'Cancel')
        return
    end
end  
                   
if exist(TrapCropName, 'file') == 2 && strcmp(CheckifCropped2, 'Yes') && exist('CheckVar', 'var') == 0
    TrapCropDummy = load(TrapCropName);
    xTrap = TrapCropDummy.TrapCrop(:, 1);
    yTrap = TrapCropDummy.TrapCrop(:, 2); 
else
    imshow(RotCropBFImages{StartStreetJ+1, StartAptJ+1}, 'InitialMagnification', 200)
    Trapmsg = msgbox('Please choose top left and bottom right corners for trap region.');
    waitfor(Trapmsg)
    [xTrap, yTrap] = ginput(2);
    
    TrapCrop = [xTrap yTrap];
    TrapCropName = sprintf('TrapCropMat_Streets%d-%d_Apts%d-%d_1.mat',...
                           StartStreetJ, EndStreetJ, StartAptJ, EndAptJ);
    save(TrapCropName, 'TrapCrop')
end

AptCrop = []; % Initializing apartment crop matrix
AptCropName = sprintf('AptCropMat_Streets%d-%d_Apts%d-%d_1.mat',...
                      StartStreetJ, EndStreetJ, StartAptJ, EndAptJ);

if exist(AptCropName, 'file') == 2 && exist('CheckVar', 'var') == 0 
    CheckifCropped3 = questdlg('Do you want to use previous apartment cropping region?',...
                              'Use Previous Crop?',...
                              'Yes', 'No', 'Cancel', 'Yes');
    waitfor(CheckifCropped3);
    if strcmp(CheckifCropped3, 'Cancel')
        return
    end
end                   
                  
if exist(AptCropName, 'file') == 2 && strcmp(CheckifCropped3, 'Yes') && exist('CheckVar', 'var') == 0
    AptCropDummy = load(AptCropName);
    xApt = AptCropDummy.AptCrop(:, 1);
    yApt = AptCropDummy.AptCrop(:, 2); 
else
    imshow(RotCropBFImages{StartStreetJ+1, StartAptJ+1}, 'InitialMagnification', 200)
    Aptmsg = msgbox('Please choose top left and bottom right corners for apartment region.');
    waitfor(Aptmsg)
    [xApt, yApt] = ginput(2);
    
    AptCrop = [xApt yApt];
    AptCropName = sprintf('AptCropMat_Streets%d-%d_Apts%d-%d_1.mat',...
                          StartStreetJ, EndStreetJ, StartAptJ, EndAptJ);
    save(AptCropName, 'AptCrop')
end
close(figure(1))

%% Adding psuedocolor to black and white GFP images, tracking particle location, and tracking
% Initializing matricies and cells needed for this process
RotCropGFPImagesOrig = {[], []}; RotCropGFPImages = {[], []}; RotCropGFPImagesDB = {[], []};
min2 = zeros((EndStreetJ+1), (EndAptJ+1)); max2 = zeros((EndStreetJ+1), (EndAptJ+1));
CenterPositionsAll = {[], []}; RadiiAll = {[], []};
CenterPositionsTrap = {[], []};
CenterPositionsApt = {[], []};
RotCropGFPImagesColorized = {[], []};
RotCropGFPImagesColorized2 = {[], []};

% Initilizing components for brightness detection
CircImages = {[], []};
ImSizes = {[], []};
BrightnessAve = {[], []};
Background = zeros((EndStreetJ+1), (EndAptJ+1));
BrightnessMax = {[], []};
BrightnessAveperIm = zeros((EndStreetJ+1), (EndAptJ+1));
BrightnessSumperIm = zeros((EndStreetJ+1), (EndAptJ+1));
BrightnessSum = {[], []};
Pts = linspace(0, 2.*pi, 1000); % Points to create circle
cir = @(R,Cent) [R*cos(Pts)+Cent(1); R*sin(Pts)+Cent(2)]; % Function for creating circles

% Performing psuedocoloring, tracking, and brightness detection
for iii5 = 1:(EndStreetJ+1)
    for ii5 = 1:(EndAptJ+1)
        % Cropping and rotating GFP images
        if strcmp(ChipType, 'Full P-Chip')
            RotCropGFPImagesOrig{iii5, ii5} = imcrop(imrotate(GFPShifted{iii5, ii5, 2}, 0),...
                     [xTotal(1) yTotal(1) (xTotal(2)-xTotal(1)) (yTotal(2)-yTotal(1))]);
            RotCropGFPImagesDB{iii5, ii5} = imcrop(imrotate(GFPShifted{iii5, ii5, 1}, 0),...
                     [xTotal(1) yTotal(1) (xTotal(2)-xTotal(1)) (yTotal(2)-yTotal(1))]);
        elseif strcmp(ChipType, '7-Condition Chip') || strcmp(ChipType, 'Y-Chip (50x50)') || strcmp(ChipType, 'Y-Chip (100x100)')
            RotCropGFPImagesOrig{iii5, ii5} = GFPShifted{iii5, ii5, 2};
            RotCropGFPImagesDB{iii5, ii5} = GFPShifted{iii5, ii5, 1};
        end
        
        % Performing blind deconvolution to help sharpen image
%         if Deblur == 1
%             [RotCropGFPImagesDB{iii5, ii5},PSF] = deconvblind(RotCropGFPImagesDB{iii5, ii5}, ones(size(RotCropGFPImagesDB{iii5, ii5})));
%         end
        
        % Normalizing intensities in cropped images
        if Normalize == 1
            min1 = min(min(RotCropGFPImagesDB{iii5, ii5}));
            max1 = max(max(RotCropGFPImagesDB{iii5, ii5}));
            RotCropGFPImages{iii5, ii5} = uint8(255.*((double(RotCropGFPImagesDB{iii5, ii5}) - double(min1)))./...
                                                double(max1 - min1));
        end
        
        % Getting BW photos and applying CF for colors
        BW  = imbinarize(RotCropGFPImages{iii5, ii5}, MinThreshold); % For main color
        BW2 = imbinarize(RotCropGFPImages{iii5, ii5}, 0.5); % For aquamarine color
    
        % Finding all circles
        BW3 = imbinarize(RotCropGFPImages{iii5, ii5}, MinThreshold);
        [centers, radii] = imfindcircles(BW3, RadRange,'ObjectPolarity', 'bright', 'Sensitivity', Sensitivity);  % Finding all circles
        centersN = centers; radiiN = radii;
        if isempty(centers) == 0 && length(centers(:, 1)) >= 2
            Lcenters = length(centers(:, 1))-1; 
            for t = Lcenters:-1:1
                if sqrt((centers(t, 1)-centers(t+1, 1)).^2 + (centers(t, 2)-centers(t+1, 2)).^2) <= min(radii)-1.0
                    centersN(t+1,:) = [];
                    radiiN(t+1, :) = [];
                end
            end
        end
        CenterPositionsAll{iii5, ii5} = centersN; % All circles positions
        RadiiAll{iii5, ii5} = radiiN; % All circles positions
%         RadMat1 = RadiiAll(~cellfun('isempty', RadiiAll));
%         RadMat2 = cell2mat(RadMat1);
%         RadMat3 = [min(RadMat2) max(RadMat2) mean(RadMat2) median(RadMat2) std(RadMat2)];
        
        % Finding only circles for beads in trap
        BWTrapCropped = imcrop(imbinarize(RotCropGFPImages{iii5, ii5}, MinThreshold),...
                 [xTrap(1) yTrap(1) (xTrap(2)-xTrap(1)) (yTrap(2)-yTrap(1))]);        
        [centers2, radii2] = imfindcircles(BWTrapCropped, RadRange,'ObjectPolarity', 'bright', 'Sensitivity', Sensitivity);  % Finding Trap circles
        centers2N = centers2; radii2N = radii2;
        if isempty(centers2) == 0 && length(centers2(:, 1)) >= 2
            Lcenters2 = length(centers2(:, 1))-1; 
            for t = Lcenters2:-1:1
                if sqrt((centers2(t, 1)-centers2(t+1, 1)).^2 + (centers2(t, 2)-centers2(t+1, 2)).^2) <= min(radii2)-1.0
                    centers2N(t+1,:) = [];
                    radii2N(t+1, :) = [];
                end
            end
        end
        CenterPositionsTrap{iii5, ii5} = centers2N; % Trap circles positions
    
        % Finding only circles for beads in apartment
        BWAptCropped = imcrop(imbinarize(RotCropGFPImages{iii5, ii5}, MinThreshold),...
                 [xApt(1) yApt(1) (xApt(2)-xApt(1)) (yApt(2)-yApt(1))]);      
        [centers3, radii3] = imfindcircles(BWAptCropped, RadRange,'ObjectPolarity', 'bright', 'Sensitivity', Sensitivity);  % Finding Trap circles
        centers3N = centers3; radii3N = radii3;
        if isempty(centers3) == 0 && length(centers3(:, 1)) >= 2
            Lcenters3 = length(centers3(:, 1))-1; 
            for t = Lcenters3:-1:1
                if sqrt((centers3(t, 1)-centers3(t+1, 1)).^2 + (centers3(t, 2)-centers3(t+1, 2)).^2) <= min(radii3)-1.0
                    centers3N(t+1,:) = [];
                    radii3N(t+1, :) = [];
                end
            end
        end
        CenterPositionsApt{iii5, ii5} = centers3N; % Trap circles positions

        % Overlaying color onto brightfield
        RotCropGFPImagesColorized{iii5, ii5} = imoverlay(RotCropBFImages{iii5, ii5}, BW, [0 1 0]); % Just light green
        RotCropGFPImagesColorized2{iii5, ii5} = imoverlay(RotCropGFPImagesColorized{iii5, ii5}, BW2, [0 0.5 0]); % Both greens
    
        % Showing Figure with Tracked image
        imshow(RotCropGFPImagesColorized2{iii5, ii5}, 'InitialMagnification', 200);
        hi = viscircles(centersN,radiiN);
        if isempty(CenterPositionsTrap{iii5, ii5}) == 1
            rectangle('Position', [xTrap(1) yTrap(1) (xTrap(2)-xTrap(1)) (yTrap(2)-yTrap(1))], ...
                      'EdgeColor', 'r')
        else
            rectangle('Position', [xTrap(1) yTrap(1) (xTrap(2)-xTrap(1)) (yTrap(2)-yTrap(1))], ...
                      'EdgeColor', 'g')  
        end
        if isempty(CenterPositionsApt{iii5, ii5}) == 1
            rectangle('Position', [xApt(1) yApt(1) (xApt(2)-xApt(1)) (yApt(2)-yApt(1))], ...
                      'EdgeColor', 'r')
        else
            rectangle('Position', [xApt(1) yApt(1) (xApt(2)-xApt(1)) (yApt(2)-yApt(1))], ...
                      'EdgeColor', 'g')
        end
        CircImages{iii5, ii5} = gcf;

        % Creating tracked figure name and saving to BFTracked folder
        if     (ii5-1) < 10 && (iii5-1) < 10
            BFwCirclesFilename = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000_Tracked_Exp%d.jpg', dirNameTracked, MagFactor, iii5-1, ii5-1, ExpCondNumber);
        elseif (ii5-1) >= 10 && (ii5-1) < 100 && (iii5-1) < 10
            BFwCirclesFilename = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000_Tracked_Exp%d.jpg', dirNameTracked, MagFactor, iii5-1, ii5-1, ExpCondNumber);
        elseif (ii5-1) < 10 && (iii5-1) >= 10 && (iii5-1) < 100
            BFwCirclesFilename = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000_Tracked_Exp%d.jpg', dirNameTracked, MagFactor, iii5-1, ii5-1, ExpCondNumber);
        elseif (ii5-1) >= 10 && (ii5-1) < 100 && (iii5-1) >= 10 && (iii5-1) < 100
            BFwCirclesFilename = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000_Tracked_Exp%d.jpg', dirNameTracked, MagFactor, iii5-1, ii5-1, ExpCondNumber);
        end
        saveas(CircImages{iii5, ii5}, BFwCirclesFilename)
    
        % Getting RGB image size for creating .tif later and brightness and
        % finding brightness of cells
        ImSizes{iii5, ii5} = size(RotCropGFPImagesOrig{iii5, ii5});
        BrightnessAveTemp = zeros(1, length(RadiiAll{iii5, ii5}));   % Clearing each loop
        IntenseInC     = {[]}; % Clearing each loop
        BackgroundTemp = zeros(ImSizes{iii5, ii5}(1), ImSizes{iii5, ii5}(2));
        BrightnessMaxTemp = zeros(1, length(RadiiAll{iii5, ii5}));
        BrightnessSumTemp = zeros(1, length(RadiiAll{iii5, ii5}));
        C = {[]}; In = {[]}; On = {[]};
        % Finding brightness of cells
        if isempty(CenterPositionsAll{iii5, ii5}) == 1
            BrightnessAve{iii5, ii5} = {0, 0};
            Background(iii5, ii5) = 0;
            BrightnessAveperIm(iii5, ii5) = 0;
        else
            Intensity = 255.*im2double(RotCropGFPImagesOrig{iii5, ii5}); % Converting image pixel intensities to matrix
            [PixelLocsx, PixelLocsy]  = meshgrid(1:1:ImSizes{iii5, ii5}(2), 1:1:ImSizes{iii5, ii5}(1));
            for NumCs = 1:1:length(RadiiAll{iii5, ii5})
                C{NumCs} = cir(RadiiAll{iii5, ii5}(NumCs), CenterPositionsAll{iii5, ii5}(NumCs, :)); % Created circles
                [In{NumCs}, On{NumCs}] = inpolygon(PixelLocsx, PixelLocsy, C{NumCs}(1, :), C{NumCs}(2, :)); % Finding pixels within circles
                IntenseInC{NumCs}      = Intensity(In{NumCs}); % Getting corresponding intensity values
                BackgroundTemp         = BackgroundTemp + In{NumCs};
                BrightnessAveTemp(NumCs)  = mean(IntenseInC{NumCs}); % Getting average of those intensity values
                BrightnessMaxTemp(NumCs)  = max(IntenseInC{NumCs}); % Getting max of those intensity values
                BrightnessSumTemp(NumCs)  = sum(sum((IntenseInC{NumCs}))); % Getting max of those intensity values
            end 
            
            Background(iii5, ii5)  = mean(Intensity(BackgroundTemp == 0));   % Finding background brightness
            BrightnessAve{iii5, ii5} = round(BrightnessAveTemp - Background(iii5, ii5)); % Actual brightness subtracting background
            BrightnessMax{iii5, ii5} = round(BrightnessMaxTemp - Background(iii5, ii5)); % Max brightness
            BrightnessSum{iii5, ii5} = round(BrightnessSumTemp - Background(iii5, ii5));
            BrightnessSumperIm(iii5, ii5) = mean(BrightnessSum{iii5, ii5});
            BrightnessAveperIm(iii5, ii5) = round(mean(BrightnessAve{iii5, ii5}));     % Getting average of mean intensity values from all circles
            
            % Cool visualization tool
%             mesh(1:ImSizes{iii5, ii5}(2), 1:ImSizes{iii5, ii5}(1), BackgroundTemp)
%             mesh(1:ImSizes{iii5, ii5}(2), 1:ImSizes{iii5, ii5}(1), Intensity)
            % Change Intensity and BackgroundTemp with ImSize to get
            % specific image
        
        end
    end
end

% Concatenating individual matlab cells data into single horizontal vector
BrightnessAveAll = horzcat(BrightnessAve{:, :})';
BrightnessMaxAll = horzcat(BrightnessMax{:, :})';
BrightnessSumAll = horzcat(BrightnessSum{:, :})';

% Saving brightness data
BackgroundName = sprintf('Brightness_Background_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
save(BackgroundName, 'Background')
AveBrightnessName = sprintf('Brightness_Average_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
save(AveBrightnessName, 'BrightnessAveAll')
MaxBrightnessName = sprintf('Brightness_Max_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
save(MaxBrightnessName, 'BrightnessMaxAll')
SumBrightnessName = sprintf('Brightness_Sum_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
save(SumBrightnessName, 'BrightnessSumAll')
BrightnessAveperImName = sprintf('Brightness_AvePerIm_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
save(BrightnessAveperImName, 'BrightnessAveperIm')

if Normalize == 1
    MinMatName = sprintf('Image_Min_Pixel_Vals_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                       StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
    save(MinMatName, 'min2')
    MaxMatName = sprintf('Image_Max_Pixel_Vals_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                       StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
    save(MaxMatName, 'max2')
end

%% Saving BF and GFP Images in New Folder
h2 = waitbar(0, 'Saving brightfield and fluorescent images...');
steps2 = TotalNum;  
step2 = 1;

% Initilizing cells used below
RotCropGFPImagesColorizedConv = {[], []};

for iii6 = 1:(EndStreetJ+1)
    for ii6 = 1:(EndAptJ+1)
        if useTiff == 1
            if     (ii6-1) < 10 && (iii6-1) < 10
                BFAlignedname = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000_Aligned_Exp%d.tif', dirNameEdited, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) >= 10 && (ii6-1) < 100 && (iii6-1) < 10
                BFAlignedname = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000_Aligned_Exp%d.tif', dirNameEdited, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) < 10 && (iii6-1) >= 10 && (iii6-1) < 100
                BFAlignedname = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000_Aligned_Exp%d.tif', dirNameEdited, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) >= 10 && (ii6-1) < 100 && (iii6-1) >= 10 && (iii6-1) < 100
                BFAlignedname = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000_Aligned_Exp%d.tif', dirNameEdited, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            end
        else
            if     (ii6-1) < 10 && (iii6-1) < 10
                BFAlignedname = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000_Aligned_Exp%d.jpg', dirNameEdited, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) >= 10 && (ii6-1) < 100 && (iii6-1) < 10
                BFAlignedname = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000_Aligned_Exp%d.jpg', dirNameEdited, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) < 10 && (iii6-1) >= 10 && (iii6-1) < 100
                BFAlignedname = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000_Aligned_Exp%d.jpg', dirNameEdited, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) >= 10 && (ii6-1) < 100 && (iii6-1) >= 10 && (iii6-1) < 100
                BFAlignedname = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000_Aligned_Exp%d.jpg', dirNameEdited, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            end
        end
        if useTiff == 1
            if     (ii6-1) < 10 && (iii6-1) < 10
                GFPAlignedname = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000_Aligned_Exp%d.tif', dirNameFluoroOverlay, filterUsed, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) >= 10 && (ii6-1) < 100 && (iii6-1) < 10
                GFPAlignedname = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000_Aligned_Exp%d.tif', dirNameFluoroOverlay, filterUsed, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) < 10 && (iii6-1) >= 10 && (iii6-1) < 100
                GFPAlignedname = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000_Aligned_Exp%d.tif', dirNameFluoroOverlay, filterUsed, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) >= 10 && (ii6-1) < 100 && (iii6-1) >= 10 && (iii6-1) < 100
                GFPAlignedname = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000_Aligned_Exp%d.tif', dirNameFluoroOverlay, filterUsed, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            end
        else
            if     (ii6-1) < 10 && (iii6-1) < 10
                GFPAlignedname = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000_Aligned_Exp%d.jpg', dirNameFluoroOverlay, filterUsed, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) >= 10 && (ii6-1) < 100 && (iii6-1) < 10
                GFPAlignedname = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000_Aligned_Exp%d.jpg', dirNameFluoroOverlay, filterUsed, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) < 10 && (iii6-1) >= 10 && (iii6-1) < 100
                GFPAlignedname = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000_Aligned_Exp%d.jpg', dirNameFluoroOverlay, filterUsed, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            elseif (ii6-1) >= 10 && (ii6-1) < 100 && (iii6-1) >= 10 && (iii6-1) < 100
                GFPAlignedname = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000_Aligned_Exp%d.jpg', dirNameFluoroOverlay, filterUsed, MagFactor, iii6-1, ii6-1, ExpCondNumber);
            end
        end
        
        if useTiff == 1
            % Saving BF image as .tif
            imwrite(RotCropBFImages{iii6, ii6},  BFAlignedname, 'tif');
            
            % Saving colorized BF image as .tif
            RotCropGFPImagesColorizedConv{iii6, ii6} = im2uint8(RotCropGFPImagesColorized{iii6, ii6});
            GFPcolordata = RotCropGFPImagesColorizedConv{iii6, ii6};
            t = Tiff(GFPAlignedname, 'w');
            t.setTag('Photometric',Tiff.Photometric.RGB);
            t.setTag('Compression',Tiff.Compression.None);
            t.setTag('BitsPerSample',8);
            t.setTag('SamplesPerPixel',3);
            t.setTag('SampleFormat',Tiff.SampleFormat.UInt);
            t.setTag('ImageLength', ImSizes{iii6, ii6}(1));
            t.setTag('ImageWidth',ImSizes{iii6, ii6}(2));
            t.setTag('TileLength',32);
            t.setTag('TileWidth',32);
            t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
    
            % Write the data to the Tiff object.
            t.write(GFPcolordata);
            t.close();
        else
            % Saving BF image as .jpg
            imwrite(RotCropBFImages{iii6, ii6},  BFAlignedname, 'jpg');
            % Saving GFP image as .jpg
            imwrite(RotCropGFPImagesColorized{iii6, ii6},  GFPAlignedname, 'jpg');
        end
        waitbar(step2/steps2)
        step2 = step2 + 1;
    end
end
close(h2)

%% Creating Color Matrix based on Number of value found in trap
Height = (StartAptJ+1):(EndAptJ+1);
Length = (StartStreetJ+1):(EndStreetJ+1);

FigureSizes  = [1 6 32 12]; % Sets full figure window sizes; adjust as necessary

% Custom colormap
colormap_custom(1, 1:3) = [1 0 0];
colormap_custom(2, 1:3) = [0 1 0];
colormap_custom(3, 1:3) = [0 0.4 0];
colormap_custom(4, 1:3) = [0 0.1 0.3];

% Creating heat map of found beads in trap during trapping process
tStart1 = tic;
figure(1); clf
set(gcf, 'units', 'centimeters', 'Position', FigureSizes)
h3 = msgbox('Creating trap heat map. This window will close automatically upon completion.');
% For creating waitbar (will make process take much longer)
%h3 = waitbar(0, 'Creating trap heat map...');
%steps3 = TotalNum;
%step3 = 1;

% Initializing matrices and cells used below
x = {[], []}; y = {[], []}; CTrap = {[], []};

for ii7 = 1:(EndStreetJ+1)
    for ii8 = 1:(EndAptJ+1)
        x{Length(ii7), Height(ii8)} = ...
            [Length(ii7)-1.5 Length(ii7)-0.5 Length(ii7)-0.5 Length(ii7)-1.5];
        y{Length(ii7), Height(ii8)} = ...
            [Height(ii8)-1.5 Height(ii8)-1.5 Height(ii8)-0.5 Height(ii8)-0.5];
        if isempty(CenterPositionsTrap{Length(ii7), Height(ii8)}) == 0 
            if     length(CenterPositionsTrap{Length(ii7), Height(ii8)}(:, 1)) == 1
                CTrap{Length(ii7), Height(ii8)} = colormap_custom(2, 1:3);
                EfficTrapData(ii7, ii8) =...
                    (length(CenterPositionsTrap{Length(ii7), Height(ii8)}(:, 1)));
                
            elseif length(CenterPositionsTrap{Length(ii7), Height(ii8)}(:, 1)) == 2
                CTrap{Length(ii7), Height(ii8)} = colormap_custom(3, 1:3);
                EfficTrapData(ii7, ii8) =...
                    (length(CenterPositionsTrap{Length(ii7), Height(ii8)}(:, 1)));
                
            elseif length(CenterPositionsTrap{Length(ii7), Height(ii8)}(:, 1)) >= 3
                CTrap{Length(ii7), Height(ii8)} = colormap_custom(4, 1:3);
                EfficTrapData(ii7, ii8) =...
                    (length(CenterPositionsTrap{Length(ii7), Height(ii8)}(:, 1)));
                
            end      
        elseif isempty(CenterPositionsTrap{Length(ii7), Height(ii8)}) == 1
            CTrap{Length(ii7), Height(ii8)} = colormap_custom(1, 1:3);
            EfficTrapData(ii7, ii8) = 0;
        end
        if (strcmp(ChipType, 'Y-Chip (50x50)') || strcmp(ChipType, 'Y-Chip (100x100)')) &&...
           ii8 == (EndAptJ+1) && mod(ii7, 2) == 0
            CTrap{Length(ii7), Height(ii8)} = [0 0 0];
            EfficTrapData(ii7, ii8) = 0;
        end
        patch(x{Length(ii7), Height(ii8)}, y{Length(ii7), Height(ii8)}, CTrap{Length(ii7), Height(ii8)});
        % Uncomment if using waitbar
        %waitbar(step3/steps3)
        %step3 = step3 + 1;
    end
end

hold on;
h = zeros(4, 1);
for ii9 = 2:4
    h(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                 'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
    h(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                 'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
end
lgd = legend(h, '0', '1', '2', '3+', 'Location', 'Eastoutside');
lgd.FontSize = 20;
axis([min(x{Length(1), Height(1)}) max(x{Length(EndStreetJ+1), Height(EndAptJ+1)}) ...
      min(y{Length(1), Height(1)}) max(y{Length(EndStreetJ+1), Height(EndAptJ+1)})])
set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
set(gca,'XtickLabel', 0:2:(length(Length)-1))
set(gca,'YTick', 0:2:(length(Height)-1), 'Fontsize', 10)
set(gca,'YtickLabel', 0:2:(length(Height)-1))
xlabel('Street', 'Fontsize', 16)
ylabel('Apartment', 'Fontsize', 16)
title('Trap Population Heat Map', 'Fontsize', 16)
close(h3)

% Saving Figure 1
w3 = waitbar(0, 'Saving trap heat map...');
steps3 = 4;

Fig1NameD = sprintf('Trap_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(1), Fig1NameD);
waitbar(2/steps3)

Fig1NameD = sprintf('Trap_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(1), Fig1NameD)
waitbar(3/steps3)

% Saving trap effiency data containing matrix of beads found
TrapEfficName = sprintf('EfficiencyTrapData_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
save(TrapEfficName, 'EfficTrapData')
close(figure(1));
waitbar(4/steps3)
toc(tStart1)
close(w3)

%% Creating heat map of found beads in apartment during trapping process
tStart2 = tic;
figure(2); clf
set(gcf, 'units', 'centimeters', 'Position', FigureSizes)
h4 = msgbox('Creating apartment heat map. This window will close automatically upon completion.');
% For creating waitbar (will make process take much longer)
%h4 = waitbar(0, 'Creating apartment heat map...');
%steps4 = TotalNum;
%step4 = 1;

% Initializing matrices and cells used below
CApt = {[], []};

for ii7 = 1:(EndStreetJ+1)
    for ii8 = 1:(EndAptJ+1)
        if isempty(CenterPositionsApt{Length(ii7), Height(ii8)}) == 0 
            if     length(CenterPositionsApt{Length(ii7), Height(ii8)}(:, 1)) == 1
                CApt{Length(ii7), Height(ii8)} = colormap_custom(2, 1:3);
                EfficAptData(ii7, ii8) =...
                (length(CenterPositionsApt{Length(ii7), Height(ii8)}(:, 1)));
            
            elseif length(CenterPositionsApt{Length(ii7), Height(ii8)}(:, 1)) == 2
                CApt{Length(ii7), Height(ii8)} = colormap_custom(3, 1:3);
                EfficAptData(ii7, ii8) =...
                (length(CenterPositionsApt{Length(ii7), Height(ii8)}(:, 1)));
            
            elseif length(CenterPositionsApt{Length(ii7), Height(ii8)}(:, 1)) >= 3
                CApt{Length(ii7), Height(ii8)} = colormap_custom(4, 1:3);
                EfficAptData(ii7, ii8) =...
                    (length(CenterPositionsApt{Length(ii7), Height(ii8)}(:, 1)));
                
            end      
        elseif isempty(CenterPositionsApt{Length(ii7), Height(ii8)}) == 1
            CApt{Length(ii7), Height(ii8)} = colormap_custom(1, 1:3);
            EfficAptData(ii7, ii8) = 0;
        end
        if (strcmp(ChipType, 'Y-Chip (50x50)') || strcmp(ChipType, 'Y-Chip (100x100)')) &&...
           ii8 == (EndAptJ+1) && mod(ii7, 2) == 0
            CApt{Length(ii7), Height(ii8)} = [0 0 0];
            EfficAptData(ii7, ii8) = 0;
        end
        patch(x{Length(ii7), Height(ii8)}, y{Length(ii7), Height(ii8)}, CApt{Length(ii7), Height(ii8)});
        % Uncomment if using waitbar
        %waitbar(step4/steps4)
        %step4 = step4 + 1;
    end
end

hold on
h2 = zeros(4, 1);
for ii9 = 2:4
    h2(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                  'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
    h2(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                  'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
end
lgd2 = legend(h2, '0', '1', '2', '3+', 'Location', 'Eastoutside');
lgd2.FontSize = 20;
axis([min(x{Length(1), Height(1)}) max(x{Length(EndStreetJ+1), Height(EndAptJ+1)}) ...
      min(y{Length(1), Height(1)}) max(y{Length(EndStreetJ+1), Height(EndAptJ+1)})])
set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
set(gca,'XtickLabel', 0:2:(length(Length)-1))
set(gca,'YTick', 0:2:(length(Height)-1), 'Fontsize', 10)
set(gca,'YtickLabel', 0:2:(length(Height)-1))
xlabel('Street', 'Fontsize', 16)
ylabel('Apartment', 'Fontsize', 16)
title('Apartment Population Heat Map', 'Fontsize', 16)
close(h4)

% Saving Figure 2
w4 = waitbar(0, 'Saving apartment heat map...');
steps4 = 4;

Fig2Name = sprintf('Apt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(2), Fig2Name)
waitbar(2/steps4)

Fig2Name = sprintf('Apt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(2), Fig2Name)
waitbar(3/steps4)

% Saving apartment effiency data containing matrix of beads found
AptEfficName = sprintf('EfficiencyAptData_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
save(AptEfficName, 'EfficAptData')

close(figure(2));
waitbar(4/steps4)
toc(tStart2)
close(w4)

%% Creating heat map of found beads in bypass during trapping process
tStart3 = tic;
figure(3); clf
set(gcf, 'units', 'centimeters', 'Position', FigureSizes)
h5 = msgbox('Creating bypass heat map. This window will close automatically upon completion.');
% For creating waitbar (will make process take much longer)
%h5 = waitbar(0, 'Creating bypass heat map...');
%steps5 = TotalNum;
%step5 = 1;

% Initializing matrices and cells used below
EfficAllData = zeros((EndStreetJ+1), (EndAptJ+1));
CAll = {[], []};

for ii7 = 1:(EndStreetJ+1)
    for ii8 = 1:(EndAptJ+1)
        if isempty(CenterPositionsAll{Length(ii7), Height(ii8)}) == 0 
            if     length(CenterPositionsAll{Length(ii7), Height(ii8)}(:, 1)) == 1 
                EfficAllData(ii7, ii8) =...
                length(CenterPositionsAll{Length(ii7), Height(ii8)}(:, 1));
            
            elseif length(CenterPositionsAll{Length(ii7), Height(ii8)}(:, 1)) == 2 
                EfficAllData(ii7, ii8) =...
                length(CenterPositionsAll{Length(ii7), Height(ii8)}(:, 1));
            
            elseif length(CenterPositionsAll{Length(ii7), Height(ii8)}(:, 1)) >= 3
                EfficAllData(ii7, ii8) =...
                    length(CenterPositionsAll{Length(ii7), Height(ii8)}(:, 1));
                
            end      
        elseif (isempty(CenterPositionsAll{Length(ii7), Height(ii8)}) == 1)
            EfficAllData(ii7, ii8) = 0;
        end
        if (strcmp(ChipType, 'Y-Chip (50x50)') || strcmp(ChipType, 'Y-Chip (100x100)')) &&...
           ii8 == (EndAptJ+1) && mod(ii7, 2) == 0
            EfficAllData(ii7, ii8) = 0;
        end
    end
end
EfficBypassData = EfficAllData - EfficAptData - EfficTrapData;
for ii7 = 1:(EndStreetJ+1)
    for ii8 = 1:(EndAptJ+1)
        if     EfficBypassData(ii7, ii8) <= 0
            CAll{Length(ii7), Height(ii8)} = colormap_custom(1, 1:3);
        elseif EfficBypassData(ii7, ii8) == 1 
            CAll{Length(ii7), Height(ii8)} = colormap_custom(2, 1:3);
        elseif EfficBypassData(ii7, ii8) == 2 
            CAll{Length(ii7), Height(ii8)} = colormap_custom(3, 1:3);
        elseif EfficBypassData(ii7, ii8) >= 3 
            CAll{Length(ii7), Height(ii8)} = colormap_custom(4, 1:3);
        end
        if (strcmp(ChipType, 'Y-Chip (50x50)') || strcmp(ChipType, 'Y-Chip (100x100)')) &&...
           ii8 == (EndAptJ+1) && mod(ii7, 2) == 0
            CAll{Length(ii7), Height(ii8)} = [0 0 0];
        end
        patch(x{Length(ii7), Height(ii8)}, y{Length(ii7), Height(ii8)}, CAll{Length(ii7), Height(ii8)});
        % Uncomment if using waitbar
        %waitbar(step5/steps5)
        %step5 = step5 + 1;
    end
end

hold on
h3 = zeros(4, 1);
for ii9 = 2:4
    h3(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                  'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
    h3(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                  'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
end
lgd2 = legend(h3, '0', '1', '2', '3+', 'Location', 'Eastoutside');
lgd2.FontSize = 20;
axis([min(x{Length(1), Height(1)}) max(x{Length(EndStreetJ+1), Height(EndAptJ+1)}) ...
      min(y{Length(1), Height(1)}) max(y{Length(EndStreetJ+1), Height(EndAptJ+1)})])
set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
set(gca,'XtickLabel', 0:2:(length(Length)-1))
set(gca,'YTick', 0:2:(length(Height)-1), 'Fontsize', 10)
set(gca,'YtickLabel', 0:2:(length(Height)-1))
xlabel('Street', 'Fontsize', 16)
ylabel('Apartment', 'Fontsize', 16)
title('Bypass Population Heat Map', 'Fontsize', 16)
close(h5)

% Saving Figure 3
w5 = waitbar(0, 'Saving bypass heat map...');
steps5 = 4;

Fig3Name = sprintf('Bypass_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(3), Fig3Name)
waitbar(2/steps5)

Fig3Name = sprintf('Bypass_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(3), Fig3Name)
waitbar(3/steps5)

% Saving not apartment effiency data containing matrix of beads found
BypassEfficName = sprintf('EfficiencyBypassData_Streets%d-%d_Apts%d-%d_Exp%d.mat',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ, ExpCondNumber);
save(BypassEfficName, 'EfficBypassData')

close(figure(3));
waitbar(4/steps5)
toc(tStart3)
close(w5)

%% Finding and Printing Out Efficiency Data
TotalAptNum  = length(Height).*length(Length);

% Correction factors based on chip type
CF = 0;
if strcmp(ChipType, 'Y-chip (50x50)') || strcmp(ChipType, 'Y-chip (100x100)')
    CF = (EndStreetJ+1)./2; % Equals number of streets/2
    TotalAptNum = TotalAptNum - CF;
end

% Finding efficiencies
NumTrap0     = length(find(EfficTrapData <= 0)) - CF; NumTrap0Eff    = NumTrap0/TotalAptNum;
NumTrap1     = length(find(EfficTrapData == 1));      NumTrap1Eff    = NumTrap1/TotalAptNum;
NumTrap2     = length(find(EfficTrapData == 2));      NumTrap2Eff    = NumTrap2/TotalAptNum;
NumTrap3More = length(find(EfficTrapData >= 3));      NumTrap3EffMore = NumTrap3More/TotalAptNum;

NumApt0     = length(find(EfficAptData <= 0)) - CF; NumApt0Eff = NumApt0/TotalAptNum;
NumApt1     = length(find(EfficAptData == 1));      NumApt1Eff = NumApt1/TotalAptNum;
NumApt2     = length(find(EfficAptData == 2));      NumApt2Eff = NumApt2/TotalAptNum;
NumApt3More = length(find(EfficAptData >= 3));      NumApt3EffMore = NumApt3More/TotalAptNum;

NumBypass0     = length(find(EfficBypassData <= 0)) - CF; NumBypass0Eff = NumBypass0/TotalAptNum;
NumBypass1     = length(find(EfficBypassData == 1));      NumBypass1Eff = NumBypass1/TotalAptNum;
NumBypass2     = length(find(EfficBypassData == 2));      NumBypass2Eff = NumBypass2/TotalAptNum;
NumBypass3More = length(find(EfficBypassData >= 3));      NumBypass3EffMore = NumBypass3More/TotalAptNum;

Num0    = [NumTrap0Eff;         NumApt0Eff;         NumBypass0Eff].*100;
Num1    = [NumTrap1Eff;         NumApt1Eff;         NumBypass1Eff].*100;
Num2    = [NumTrap2Eff;         NumApt2Eff;         NumBypass2Eff].*100;
Num3    = [NumTrap3EffMore;     NumApt3EffMore;     NumBypass3EffMore].*100;
TotPerc = [(NumTrap0Eff   + NumTrap1Eff   + NumTrap2Eff   + NumTrap3EffMore); ...
           (NumApt0Eff    + NumApt1Eff    + NumApt2Eff    + NumApt3EffMore); ...
           (NumBypass0Eff + NumBypass1Eff + NumBypass2Eff + NumBypass3EffMore)].*100;

% Displaying in Table
Name = {'Trap'; 'Apartment'; 'Bypass'};
EfficiencyTab = table(categorical(Name), Num0, Num1, Num2, Num3, TotPerc, ...
    'VariableNames', {'Region' 'None' 'Single' 'Double' 'TripleOrMore' 'Total'});
disp(EfficiencyTab)

% Saving Table
TableName = sprintf('Efficiency_Table_Streets%d-%d_Apts%d-%d_Exp%d',...
                     StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
writetable(EfficiencyTab, TableName,'Delimiter',' ')  

%% Plotting (and Saving) Block, Street, and Row Effiencies Over Total Chip
if strcmp(ChipType, 'Full P-Chip')
    TotBlockNum = 8.*40; NumEachBlock = zeros(4, 12);
    TotStNum  = 40;      NumEachRow   = zeros(4, TotStNum);
    TotRowNum = 96;      NumEachSt    = zeros(4, TotRowNum);
    TotBlockNums = 1:12;
    TotalStNums  = 1:TotRowNum;
    TotalRowNums = 1:TotStNum;
    for iv = TotBlockNums-1
        for iv2 = 0:3
            if     iv2 == 0
                if     strcmp(TorA, 'T')
                    NumEachBlock(iv2+1, iv+1) = length(find(EfficTrapData((1:8)+(8.*iv), :) <= iv2))./TotBlockNum;
                elseif strcmp(TorA, 'A')
                    NumEachBlock(iv2+1, iv+1) = length(find(EfficAptData((1:8)+(8.*iv), :) <= iv2))./TotBlockNum;
                end
            elseif iv2 > 0 && iv2 < 3
                if     strcmp(TorA, 'T')
                    NumEachBlock(iv2+1, iv+1) = length(find(EfficTrapData((1:8)+(8.*iv), :) == iv2))./TotBlockNum;
                elseif strcmp(TorA, 'A')
                    NumEachBlock(iv2+1, iv+1) = length(find(EfficAptData((1:8)+(8.*iv), :) == iv2))./TotBlockNum;
                end
            elseif iv2 == 3
                if     strcmp(TorA, 'T')
                    NumEachBlock(iv2+1, iv+1) = length(find(EfficTrapData((1:8)+(8.*iv), :) >= iv2))./TotBlockNum;
                elseif strcmp(TorA, 'A')
                    NumEachBlock(iv2+1, iv+1) = length(find(EfficAptData((1:8)+(8.*iv), :) >= iv2))./TotBlockNum;
                end
            end
        end
    end
elseif strcmp(ChipType, '7-Condition Chip')
    TotStNum  = 34;      NumEachRow   = zeros(4, TotStNum);
    TotRowNum = 16;      NumEachSt    = zeros(4, TotRowNum);
    TotalStNums  = 1:TotRowNum;
    TotalRowNums = 1:TotStNum;
elseif strcmp(ChipType, 'Y-Chip (50x50)')
    TotStNum  = 50;      NumEachRow   = zeros(4, TotStNum);
    TotRowNum = 50;      NumEachSt    = zeros(4, TotRowNum);
    TotalStNums  = 1:TotRowNum;
    TotalRowNums = 1:TotStNum;        
elseif strcmp(ChipType, 'Y-Chip (100x100)') 
    TotStNum  = 100;      NumEachRow   = zeros(4, TotStNum);
    TotRowNum = 100;      NumEachSt    = zeros(4, TotRowNum);
    TotalStNums  = 1:TotRowNum;
    TotalRowNums = 1:TotStNum;        
end
for iw = TotalStNums
    for iw2 = 0:3
        if     iw2 == 0
            if     strcmp(TorA, 'T')
                NumEachSt(iw2+1, iw) = length(find(EfficTrapData(iw, :) <= iw2))./TotStNum;
            elseif strcmp(TorA, 'A')
                NumEachSt(iw2+1, iw) = length(find(EfficAptData(iw, :) <= iw2))./TotStNum;
            end
        elseif iw2 > 0 && iw2 < 3
            if     strcmp(TorA, 'T')
                NumEachSt(iw2+1, iw) = length(find(EfficTrapData(iw, :) == iw2))./TotStNum;
            elseif strcmp(TorA, 'A')
                NumEachSt(iw2+1, iw) = length(find(EfficAptData(iw, :) == iw2))./TotStNum;
            end
        elseif iw2 == 3
            if     strcmp(TorA, 'T')
                NumEachSt(iw2+1, iw) = length(find(EfficTrapData(iw, :) >= iw2))./TotStNum;
            elseif strcmp(TorA, 'A')
                NumEachSt(iw2+1, iw) = length(find(EfficAptData(iw, :) >= iw2))./TotStNum;
            end
        end
    end
end
for ix = TotalRowNums
    for ix2 = 0:3
        if     ix2 == 0
            if     strcmp(TorA, 'T')
                NumEachRow(ix2+1, ix) = length(find(EfficTrapData(:, ix) <= ix2))./TotRowNum;
            elseif strcmp(TorA, 'A')
                NumEachRow(ix2+1, ix) = length(find(EfficAptData(:, ix) <= ix2))./TotRowNum;
            end
        elseif ix2 > 0 && ix2 < 3
            if     strcmp(TorA, 'T')
                NumEachRow(ix2+1, ix) = length(find(EfficTrapData(:, ix) == ix2))./TotRowNum;
            elseif strcmp(TorA, 'A')
                NumEachRow(ix2+1, ix) = length(find(EfficAptData(:, ix) == ix2))./TotRowNum;
            end
        elseif ix2 == 3
            if     strcmp(TorA, 'T')
                NumEachRow(ix2+1, ix) = length(find(EfficTrapData(:, ix) >= ix2))./TotRowNum;
            elseif strcmp(TorA, 'A')
                NumEachRow(ix2+1, ix) = length(find(EfficAptData(:, ix) >= ix2))./TotRowNum;
            end
        end
    end
end    

if strcmp(ChipType, 'Full P-Chip')
    figure(4); clf
    set(gcf, 'units', 'centimeters', 'Position', [2 2 30 22])
    subplot(3, 1, 1)
    grid on
    for ip = 1:4
        hold on
        plot(TotBlockNums, NumEachBlock(ip, 1:12).*100, 'k-o', 'Color', colormap_custom(ip, 1:3),...
             'MarkerFaceColor', colormap_custom(ip, 1:3), 'Markersize', 3, 'LineWidth', 1.5)
        hold off
    end
    set(gca, 'XTick', 1:12)
    set(gca,'XtickLabel', {'0-7',   '8-15',  '16-23', '24-31', '32-39', '40-47',...
                           '48-55', '56-63', '64-71', '72-79', '80-87', '88-95'})
    axis([1 12 0 110])
    xlabel('Block')
    ylabel('Efficiency (%)')
    if     strcmp(TorA, 'T')
        DumTitleVar1 = 'Trap';
        TitleName1 = sprintf('Block Efficiencies (Goal: %s)', DumTitleVar1);
    elseif strcmp(TorA, 'A')
        DumTitleVar1 = 'Loading into Apartments';
        TitleName1 = sprintf('Block Efficiencies (Goal: %s)', DumTitleVar1);
    end
    title(TitleName1)

    subplot(3, 1, 2)
    grid on
    for ip = 1:4
        hold on
        plot(TotalStNums-1, NumEachSt(ip, 1:96).*100, 'k-o', 'Color', colormap_custom(ip, 1:3),...
            'MarkerFaceColor', colormap_custom(ip, 1:3), 'Markersize', 3, 'LineWidth', 1.5)
        hold off
    end
    set(gca, 'XTick', 0:5:95)
    axis([0 95 0 110])
    xlabel('Street')
    ylabel('Efficiency (%)')
    if     strcmp(TorA, 'T')
        DumTitleVar2 = 'Trap';
        TitleName2 = sprintf('Street Efficiencies (Goal: %s)', DumTitleVar2);
    elseif strcmp(TorA, 'A')
        DumTitleVar2 = 'Loading into Apartments';
        TitleName2 = sprintf('Street Efficiencies (Goal: %s)', DumTitleVar2);
    end
    title(TitleName2)

    subplot(3, 1, 3)
    grid on
    for ip = 1:4
        hold on
        plot(TotalRowNums-1, NumEachRow(ip, 1:40).*100, 'k-o', 'Color', colormap_custom(ip, 1:3),...
             'MarkerFaceColor', colormap_custom(ip, 1:3), 'Markersize', 3, 'LineWidth', 1.5)
    end
    h4 = zeros(4, 1);
    for ii9 = 2:4
        h4(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                      'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 14);
        h4(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                      'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 14);
    end
    lgd4 = legend(h4, '0', '1', '2', '3+', 'Location', 'Eastoutside');
    lgd4.FontSize = 14;
    hold off
    set(gca, 'XTick', 0:39)
    axis([0 39 0 110])
    xlabel('Row')
    ylabel('Efficiency (%)')
    if     strcmp(TorA, 'T')
        DumTitleVar3 = 'Trap';
        TitleName3 = sprintf('Row Efficiencies (Goal: %s)', DumTitleVar3);
    elseif strcmp(TorA, 'A')
        DumTitleVar3 = 'Loading into Apartments';
        TitleName3 = sprintf('Row Efficiencies (Goal: %s)', DumTitleVar3);
    end
    title(TitleName3)

elseif strcmp(ChipType, '7-Condition Chip') || strcmp(ChipType, 'Y-Chip (50x50)') ||...
       strcmp(ChipType, 'Y-Chip (100x100)')
    figure(4); clf 
    set(gcf, 'units', 'centimeters', 'Position', [2 2 30 17])
    subplot(2, 1, 1)
    grid on
    for ip = 1:4
        hold on
        plot(TotalStNums-1, NumEachSt(ip, 1:TotRowNum).*100, 'k-o', 'Color', colormap_custom(ip, 1:3),...
            'MarkerFaceColor', colormap_custom(ip, 1:3), 'Markersize', 3, 'LineWidth', 1.5)
        hold off
    end
    set(gca, 'XTick', 0:1:(TotRowNum-1))
    axis([0 (TotRowNum-1) 0 110])
    xlabel('Street')
    ylabel('Efficiency (%)')
    if     strcmp(TorA, 'T')
        DumTitleVar2 = 'Trap';
        TitleName2 = sprintf('Street Efficiencies (Goal: %s)', DumTitleVar2);
    elseif strcmp(TorA, 'A')
        DumTitleVar2 = 'Loading into Apartments';
        TitleName2 = sprintf('Street Efficiencies (Goal: %s)', DumTitleVar2);
    end
    title(TitleName2)

    subplot(2, 1, 2)
    grid on
    for ip = 1:4
        hold on
        plot(TotalRowNums-1, NumEachRow(ip, 1:TotStNum).*100, 'k-o', 'Color', colormap_custom(ip, 1:3),...
             'MarkerFaceColor', colormap_custom(ip, 1:3), 'Markersize', 3, 'LineWidth', 1.5)
    end
    h4 = zeros(4, 1);
    for ii9 = 2:4
        h4(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
                      'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 14);
        h4(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
                      'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 14);
    end
    lgd4 = legend(h4, '0', '1', '2', '3+', 'Location', 'Eastoutside');
    lgd4.FontSize = 14;
    hold off
    set(gca, 'XTick', 0:1:(TotStNum-1))
    axis([0 (TotStNum-1) 0 110])
    xlabel('Row')
    ylabel('Efficiency (%)')
    if     strcmp(TorA, 'T')
        DumTitleVar3 = 'Trap';
        TitleName3 = sprintf('Row Efficiencies (Goal: %s)', DumTitleVar3);
    elseif strcmp(TorA, 'A')
        DumTitleVar3 = 'Loading into Apartments';
        TitleName3 = sprintf('Row Efficiencies (Goal: %s)', DumTitleVar3);
    end
    title(TitleName3)
end

% Saving Figure 4
Fig4Name = sprintf('Block-Street-Row_Efficiencies_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(4), Fig4Name)
Fig4Name = sprintf('Block-Street-Row_Efficiencies_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(4), Fig4Name)

close(figure(4));

%% Creating Figure 5 - Brightness Heat Map
figure(5); clf
set(gcf, 'units', 'centimeters', 'Position', [5 2 25 20])
% Plotting heat map of average brightness values of cells
heatmap(0:1:EndStreetJ, EndAptJ:-1:0, fliplr(BrightnessAveperIm)');
colormap default
colorbar
caxis([1 255]) % Sets colorbar to use full possible range

xlabel('Street')
ylabel('Row')
title('Average Brightness from Within Tracked Cell Region per Image (Heat Map)')

% Saving Figure 5
Fig5Name = sprintf('Brightness_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(5), Fig5Name)
Fig5Name = sprintf('Brightness_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(5), Fig5Name)

%close(figure(5));

%% Creating Figure 6 - Brightness Histograms
figure(6); clf
set(gcf, 'units', 'centimeters', 'Position', [1 7 42 15])
subplot(1, 3, 1)
% Plotting histrogram of average brightness values (rounded to integers)
BrightnessAveNoZero = find(BrightnessAveperIm ~= 0);
histogram(BrightnessAveperIm(BrightnessAveNoZero), 'BinLimits', [0 255], 'NumBins', 100, 'FaceColor', 'm')
grid on;
Ax1 = gca;
axis([0 255 Ax1.YLim(1) Ax1.YLim(2).*1.1])

xlabel('Average Cell Intensity', 'Fontsize', 15)
ylabel('Number of Cells', 'Fontsize', 15)
title({'Average Intensity from Within', 'Tracked Cell Region (Histogram)'}, 'Fontsize', 11)

subplot(1, 3, 2)
BrightnessMaxNoZero = find(BrightnessMaxAll ~= 0);
histogram(BrightnessMaxAll(BrightnessMaxNoZero), 'BinLimits', [0 255], 'NumBins', 100, 'FaceColor', 'r')
grid on
Ax2 = gca;
axis([0 255 Ax2.YLim(1) Ax2.YLim(2).*1.1])

xlabel('Max Cell Intensity', 'Fontsize', 15)
ylabel('Number of Cells', 'Fontsize', 15)
title({'Max Intensity from Within', 'Tracked Cell Region (Histogram)'}, 'Fontsize', 11)

subplot(1, 3, 3)
BrightnessSumNoZero = find(BrightnessSumAll ~= 0);
histogram(BrightnessSumAll(BrightnessSumNoZero), 'BinLimits', [0 max(BrightnessSumAll)], 'NumBins', 100, 'FaceColor', 'r')
grid on
Ax2 = gca;
axis([0 Ax2.XLim(2).*1.1 Ax2.YLim(1) Ax2.YLim(2).*1.1])

xlabel('Max Cell Intensity', 'Fontsize', 15)
ylabel('Number of Cells', 'Fontsize', 15)
title({'Sum of Intensity from Within', 'Tracked Cell Region (Histogram)'}, 'Fontsize', 11)

% Saving Figure 6
Fig6Name = sprintf('Brightness_Histograms_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(6), Fig6Name)
Fig6Name = sprintf('Brightness_Histograms_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                   StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
saveas(figure(6), Fig6Name)

%close(figure(6));

%% Creating Efficiency Tables for Blocks, Streets, and Rows
% Initializing total percentage matrices and filling in
if strcmp(ChipType, 'Full P-Chip')
    TotBlockPerc = zeros(1, 12);
    for it  = TotBlockNums
        TotBlockPerc(1, it) = sum(NumEachBlock(:, it)).*100;
    end
end

TotStPerc = zeros(1, EndStreetJ+1); TotRowPerc = zeros(1, EndAptJ+1);
for it2 = TotalStNums
    TotStPerc(1, it2) = sum(NumEachSt(:, it2)).*100;
end
for it3 = TotalRowNums
    TotRowPerc(1, it3) = sum(NumEachRow(:, it3)).*100;
end

% Displaying in Tables
if strcmp(ChipType, 'Full P-Chip')
    BlockEfficTab = table(TotBlockNums', (NumEachBlock(1, 1:12).*100)', (NumEachBlock(2, 1:12).*100)',...
                         (NumEachBlock(3, 1:12).*100)', (NumEachBlock(4, 1:12).*100)',...
                          TotBlockPerc', ...
        'VariableNames', {'Block' 'None' 'Single' 'Double' 'Triple' 'Total'});
disp(BlockEfficTab)
end
StEfficTab = table((TotalStNums-1)', (NumEachSt(1, 1:EndStreetJ+1).*100)', (NumEachSt(2, 1:EndStreetJ+1).*100)',...
                   (NumEachSt(3, 1:EndStreetJ+1).*100)', (NumEachSt(4, 1:EndStreetJ+1).*100)',...
                    TotStPerc', ...
    'VariableNames', {'StreetNum' 'None' 'Single' 'Double' 'Triple' 'Total'});
disp(StEfficTab)
RowEfficTab = table(flip((TotalRowNums-1)'), flip((NumEachRow(1, 1:EndAptJ+1).*100)'), flip((NumEachRow(2, 1:EndAptJ+1).*100)'),...
                    flip((NumEachRow(3, 1:EndAptJ+1).*100)'), flip((NumEachRow(4, 1:EndAptJ+1).*100)'),...
                    flip(TotRowPerc'), ...
    'VariableNames', {'RowNum' 'None' 'Single' 'Double' 'Triple' 'Total'});
disp(RowEfficTab)

% Saving Tables
if strcmp(ChipType, 'Full P-Chip')
    for tabnames = {'Block', 'Street', 'Row'}
        TableName = sprintf('%s_Efficiency_Table_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                             tabnames{1}, StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
        if     strcmp(tabnames{1}, 'Block')
            writetable(BlockEfficTab, TableName,'Delimiter',' ')  
        elseif strcmp(tabnames{1}, 'Street')
            writetable(StEfficTab, TableName,'Delimiter',' ')  
        elseif strcmp(tabnames{1}, 'Row')
            writetable(RowEfficTab, TableName,'Delimiter',' ')  
        end
    end
elseif strcmp(ChipType, '7-Condition Chip') || strcmp(ChipType, 'Y-Chip (50x50)') ||...
       strcmp(ChipType, 'Y-Chip (100x100)')
    for tabnames = {'Street', 'Row'}
        TableName = sprintf('%s_Efficiency_Table_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
                             tabnames{1}, StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
        if strcmp(tabnames{1}, 'Street')
            writetable(StEfficTab, TableName,'Delimiter',' ')  
        elseif strcmp(tabnames{1}, 'Row')
            writetable(RowEfficTab, TableName,'Delimiter',' ')  
        end
    end    
end

%% Easter Egg
if NumApt1Eff >= 0.87 || NumTrap1Eff >= 0.87
    figure(4); clf
    axis([-5 5 -5 5])
    patch([-5 5 5 -5], [-5 -5 5 5], [0 0 0])
    hold on
    for ee = 3:20
        Locx = -3 + (6).*rand(20, 1); Locy = -4 + (8).*rand(20, 1);
        uix = text(Locx(ee), Locy(ee), 'SUSHI!!!');
        uix.FontSize = 30;
        if mod(ee, 3)-1 == -1
            uix.Color = [1 0 0];
        elseif mod(ee, 3)-1 == 0
            uix.Color = [0 1 0];
        else 
            uix.Color = [0 0 1];
        end
        uix.HorizontalAlignment = 'center';
        pause(0.2);
        delete(uix)
    end
    uix = text(0, 0, 'SUSHI!!!');
    uix.FontSize = 80;
    uix.Color = [1 0 0];
    uix.HorizontalAlignment = 'center';
    hold off
end
    
end

%% Printing to Word Doc
if PrintToWordDoc == 1 && CheckforEfficData ~= 1

% Re-rounding number so they'll be evently spaced on Word Doc.
Num0N = {3, 1}; Num1N = {3, 1}; Num2N = {3, 1}; Num3N = {3, 1}; 
for Numiv0 = 1:3
    if     Num0(Numiv0, 1) == 0
        Num0N{Numiv0, 1} = '0.0000';
    elseif Num0(Numiv0, 1) < 10
        Num0N{Numiv0, 1} = sprintf('%0.4f', Num0(Numiv0, 1));
    elseif Num0(Numiv0, 1) >= 10 && Num0(Numiv0, 1) < 100
        Num0N{Numiv0, 1} = sprintf('%0.3f', Num0(Numiv0, 1));
    elseif Num0(Numiv0, 1) >= 100
        Num0N{Numiv0, 1} = sprintf('%0.2f', Num0(Numiv0, 1));
    end
    if     Num1(Numiv0, 1) == 0
        Num1N{Numiv0, 1} = '0.0000';
    elseif Num1(Numiv0, 1) < 10
        Num1N{Numiv0, 1} = sprintf('%0.4f', Num1(Numiv0, 1));
    elseif Num1(Numiv0, 1) >= 10 && Num1(Numiv0, 1) < 100
        Num1N{Numiv0, 1} = sprintf('%0.3f', Num1(Numiv0, 1));
    elseif Num1(Numiv0, 1) >= 100
        Num1N{Numiv0, 1} = sprintf('%0.2f', Num1(Numiv0, 1));
    end
    if     Num2(Numiv0, 1) == 0
        Num2N{Numiv0, 1} = '0.0000';
    elseif Num2(Numiv0, 1) < 10
        Num2N{Numiv0, 1} = sprintf('%0.4f', Num2(Numiv0, 1));
    elseif Num2(Numiv0, 1) >= 10 && Num2(Numiv0, 1) < 100
        Num2N{Numiv0, 1} = sprintf('%0.3f', Num2(Numiv0, 1));
    elseif Num2(Numiv0, 1) >= 100
        Num2N{Numiv0, 1} = sprintf('%0.2f', Num2(Numiv0, 1));
    end
    if     Num3(Numiv0, 1) == 0
        Num3N{Numiv0, 1} = '0.0000';
    elseif Num3(Numiv0, 1) < 10
        Num3N{Numiv0, 1} = sprintf('%0.4f', Num3(Numiv0, 1));
    elseif Num3(Numiv0, 1) >= 10 && Num3(Numiv0, 1) < 100
        Num3N{Numiv0, 1} = sprintf('%0.3f', Num3(Numiv0, 1));
    elseif Num3(Numiv0, 1) >= 100
        Num3N{Numiv0, 1} = sprintf('%0.2f', Num3(Numiv0, 1));
    end
end

% Getting handles for each image
PicName1 = sprintf('/Trap_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                    StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
PicName2 = sprintf('/Apt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                    StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
PicName3 = sprintf('/Bypass_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                    StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
PicName4 = sprintf('/Block-Street-Row_Efficiencies_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
                    StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);

word = actxserver('Word.Application');      % start Word
word.Visible = 1;                           % make Word Visible
document  = word.Documents.Add;             % create new Document
selection = word.Selection;                 % set Cursor
selection.Font.Name = 'Times New Roman';    % set Font
selection.Font.Size = 11;                   % set Size

selection.Pagesetup.RightMargin    = 28.34646.*2;  % set right Margin to 1cm
selection.Pagesetup.LeftMargin     = 28.34646.*2;  % set left Margin to 1cm
selection.Pagesetup.TopMargin      = 28.34646.*1.1;  % set top Margin to 1cm
selection.Pagesetup.BottomMargin   = 28.34646.*1.1;  % set bottom Margin to 1cm (1cm is circa 28.34646 points)
selection.Paragraphs.LineUnitAfter = 0.02;    % sets the amount of spacing between paragraphs(in gridlines)

% Writing Header
selection.ParagraphFormat.Alignment = 1; % Center-aligns paragraph
selection.Font.Size = 16;                   
selection.Font.Bold = 1;
selection.Font.UnderlineColor = 0; % Give black color for underline of header
selection.Font.Underline = 1; % Underlines headers
selection.TypeText(sprintf('%s Experimental Report', ChipType));

selection.TypeParagraph;

% Writing experimental parameters
selection.Font.Size = 12;                   
selection.ParagraphFormat.Alignment = 0; % Left-aligns paragraph
selection.Font.Underline = 0; % Underlines headers
selection.Font.Underline = 1; % Underlines headers
selection.Font.Bold = 0;
selection.TypeText('Experimental Parameters');
selection.Paragraphs.LineUnitAfter=0.10;
selection.TypeParagraph; selection.Font.Underline = 0;

selection.Font.Size = 10;                   
selection.Font.Bold = 1;
selection.TypeText('Experiment/Condition Number: '); selection.Font.Bold = 0;
selection.TypeText(num2str(ExpCondNumber)); selection.TypeParagraph; 
selection.Font.Bold = 1;
selection.TypeText('Date Performed: '); selection.Font.Bold = 0;
selection.TypeText(num2str(Month)); selection.TypeText('/');
selection.TypeText(num2str(Day)); selection.TypeText('/');
selection.TypeText(num2str(Year)); selection.TypeParagraph;
selection.Font.Bold = 1;
selection.TypeText('Experimenter: '); selection.Font.Bold = 0;
selection.TypeText(Experimenter); selection.TypeParagraph;
selection.Font.Bold = 1; selection.TypeText('Exposure / DRIE Cycles: '); selection.Font.Bold = 0;
selection.TypeText(ChipExposure); selection.TypeText(' / ');
selection.TypeText(DRIECycles); selection.TypeText(' cycles'); selection.TypeParagraph; 
selection.Font.Bold = 1; 
if     strcmp(CellsorBeads, 'Cells')
    selection.TypeText('Cell Type (Conc.): ');  selection.Font.Bold = 0;
    selection.TypeText(CelltypeandConc); selection.TypeParagraph; selection.Font.Bold = 0;
    selection.Font.Bold = 1; 
    selection.TypeText('Cell Dye (Conc.): ');  selection.Font.Bold = 0;
    selection.TypeText(DyeUsedandConc); selection.TypeParagraph; 
    selection.Font.Bold = 1; 
elseif strcmp(CellsorBeads, 'Beads')
    selection.TypeText('Bead Size (Conc.): ');  selection.Font.Bold = 0;
    selection.TypeText(BeadSizeandConc); selection.TypeParagraph; selection.Font.Bold = 0;
    selection.Font.Bold = 1; 
end
selection.TypeText('Surface Treatment: ');  selection.Font.Bold = 0;
selection.TypeText(SurfTreatment); selection.TypeParagraph; 
selection.Font.Bold = 1; 
selection.TypeText('Trapped or Loaded: ');  selection.Font.Bold = 0;
selection.TypeText(TrapOrLoad); selection.TypeParagraph;
selection.Font.Bold = 1; 
selection.TypeText('Priming Conditions: ');  selection.Font.Bold = 0;
selection.TypeText(PrimeDirAndCond); selection.TypeParagraph;
selection.Font.Bold = 1; 
selection.TypeText('Trapping Direction/Conditions/Time: ');  selection.Font.Bold = 0;
selection.TypeText(TrapDirection); selection.TypeText(' / ');
selection.TypeText(TrapFlowcond); selection.TypeText(' / '); 
selection.TypeText(TrapTime); selection.TypeParagraph; 
selection.Font.Bold = 1; 
selection.TypeText('Temperature(s): ');  selection.Font.Bold = 0;
selection.TypeText(Temperature); selection.TypeParagraph; 
selection.Font.Bold = 1; 
selection.TypeText('Apt. Loading Conditions/Time: ');  selection.Font.Bold = 0;
selection.TypeText(AptLoadCond); selection.TypeText(' / ');
selection.TypeText(AptLoadTime); selection.TypeParagraph; 
selection.Font.Bold = 1; 
selection.TypeText('Acoustics Used: ');  selection.Font.Bold = 0;
selection.TypeText(Acoustics); selection.TypeParagraph;
selection.Font.Bold = 1; 
selection.TypeText('Other Comments: ');  selection.Font.Bold = 0;
selection.TypeText(OtherComments); selection.TypeParagraph;
selection.TypeParagraph;

selection.Font.Size = 12;                   
selection.ParagraphFormat.Alignment = 0; % Left-aligns paragraph
selection.Font.Underline = 0; % Underlines headers
selection.Font.Underline = 1; % Underlines headers
selection.TypeText('Image Analysis Parameters');
selection.Paragraphs.LineUnitAfter=0.10;
selection.TypeParagraph; selection.Font.Underline = 0;

selection.Font.Size = 10;                   
selection.Font.Bold = 1;
selection.TypeText('Minimum Threshold: '); selection.Font.Bold = 0;
selection.TypeText(num2str(MinThreshold)); selection.TypeParagraph; 
selection.Font.Bold = 1;
selection.TypeText('Sensitivity: ');  selection.Font.Bold = 0;
selection.TypeText(num2str(Sensitivity)); selection.TypeParagraph;
selection.Font.Bold = 1; 
selection.TypeText('Radii Range: ');  selection.Font.Bold = 0;
selection.TypeText('['); selection.TypeText(num2str(RadRange(1)));
selection.TypeText(' '); selection.TypeText(num2str(RadRange(2))); selection.TypeText(']');
selection.TypeParagraph;
selection.Font.Bold = 1; 
selection.TypeText('Normalized: ');  selection.Font.Bold = 0;
if Normalize == 1
    selection.TypeText('Yes');
else
    selection.TypeText('No');
end
selection.TypeParagraph;

% Inserting Heat Maps
selection.ParagraphFormat.Alignment = 1;
selection.InlineShapes.AddPicture([pwd PicName1], 0, 1);
selection.TypeParagraph;
selection.TypeParagraph;
selection.TypeParagraph;
selection.InlineShapes.AddPicture([pwd PicName2], 0, 1);
selection.InsertNewPage; % Creates new page
selection.InlineShapes.AddPicture([pwd PicName3], 0, 1);
selection.InlineShapes.AddPicture([pwd PicName4], 0, 1);

% Inserting Efficiency Table
selection.ParagraphFormat.Alignment = 1; % Center-aligns 
selection.Font.Bold = 1;
selection.Font.Size = 12;
selection.TypeText('Total Chip Efficiencies'); selection.TypeParagraph;
selection.ParagraphFormat.Alignment = 0; % Lef-aligns 
selection.Font.Size = 11;
selection.TypeText('                    ')
selection.Font.Underline = 1; % Underlines headers
selection.TypeText('Region      '); selection.TypeText('           '); 
selection.TypeText('None        '); selection.TypeText('            '); 
selection.TypeText('Single      '); selection.TypeText('            '); 
selection.TypeText('Double      '); selection.TypeText('            '); 
selection.TypeText('Triple or More'); 
selection.Font.Underline = 0; selection.Font.Bold = 0; selection.TypeParagraph;

selection.TypeText('                      Trap        '); selection.TypeText('          '); 
selection.Font.Size = 6; selection.TypeText(' '); selection.Font.Size = 11; 
selection.TypeText(Num0N{1}); selection.TypeText('                   '); 
selection.TypeText(Num1N{1}); selection.TypeText('                  '); 
selection.TypeText(Num2N{1}); selection.TypeText('                         '); 
selection.TypeText(Num3N{1}); selection.TypeParagraph;

selection.TypeText('                 Apartment   '); selection.TypeText('           '); 
selection.TypeText(Num0N{2}); selection.TypeText('                   '); 
selection.TypeText(Num1N{2}); selection.TypeText('                  '); 
selection.TypeText(Num2N{2}); selection.TypeText('                         '); 
selection.TypeText(Num3N{2}); selection.TypeParagraph;

selection.TypeText('                    Bypass      '); selection.TypeText('          '); 
selection.Font.Size = 6; selection.TypeText(' '); selection.Font.Size = 11; 
selection.TypeText(Num0N{3}); selection.TypeText('                   '); 
selection.TypeText(Num1N{3}); selection.TypeText('                  '); 
selection.TypeText(Num2N{3}); selection.TypeText('                         '); 
selection.TypeText(Num3N{3});

SaveWordDocQ = questdlg('Do you want to save the experimental report?',...
                        'Chip Imaged',...
                        'Yes', 'No', 'Yes');
if strcmp(SaveWordDocQ, 'Yes')
    WordSaveLoc = uigetdir('', 'Choose folder where you want to save report');
    docName = sprintf('%s/%s_Experimental_Report_Exp._%d_(%d-%d-%d)_%s.doc',...
                      WordSaveLoc, ChipType, ExpCondNumber, Month, Day, Year, TorA);
    invoke(document, 'SaveAs', docName, 1);
end
% word.Quit(); % Closing document after it is saved
end

% Run section just to get time
toc

%% Stuff Ben didn't think I could do (allowing user to click and open images)
% Initializing a counter
counter = 1;
InitChoice = 'Yes';

while strcmp(InitChoice, 'Yes')
    close all
    uix = -1; uiy = -1;
    if     counter == 1
        InitChoice = questdlg('Are there any traps or apartments you want to see the images for?',...
                              'See Images?',...
                               'Yes', 'No', 'No');
    elseif counter >= 2
        InitChoice = questdlg('Are there any more traps or apartments you want to see the images for?',...
                              'See Images?',...
                               'Yes', 'No', 'No');
    end
    % Choice switch cases tree
    switch InitChoice
        case 'Yes'
            if     strcmp(TorA, 'T')
            Choice2 = questdlg('Do you want to use the trap or apartment heat map?',...
                               'Traps or Apartments',...
                               'Traps', 'Apartments', 'Traps');
            elseif strcmp(TorA, 'A')
            Choice2 = questdlg('Do you want to use the trap or apartment heat map?',...
                               'Traps or Apartments',...
                               'Traps', 'Apartments', 'Apartments');   
            end
            switch Choice2
                case 'Traps'
                    Fig1NameD = sprintf('Trap_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.fig',...
                       StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);
                    uiwait(msgbox('The figure will open upon clicking okay. Click on the trap you want to see pictures for.'))
                    while  uix < (StartStreetJ-0.5) || uiy < (StartAptJ-0.5) || uix > (EndStreetJ+0.5) || uiy > (EndAptJ+0.5)
                    openfig(Fig1NameD)
                    [uix, uiy] = ginput(1);
                        if uix < (StartStreetJ-0.5) || uiy < (StartAptJ-0.5) || uix > (EndStreetJ+0.5) || uiy > (EndAptJ+0.5)
                            close(figure(1))
                            msgbox('Invalid Choice. Click within the heatmap.', 'Error', 'error')
                        end
                    end
                    close(figure(1))

                case 'Apartments'
                    Fig2NameD = sprintf('Apt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.fig',...
                       StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExpCondNumber);                
                    uiwait(msgbox('The figure will open upon clicking okay. Click on the apartment you want to see pictures for.'))
                    while  uix < (StartStreetJ-0.5) || uiy < (StartAptJ-0.5) || uix > (EndStreetJ+0.5) || uiy > (EndAptJ+0.5)
                    openfig(Fig2NameD)
                    [uix, uiy] = ginput(1);
                        if uix < (StartStreetJ-0.5) || uiy < (StartAptJ-0.5) || uix > (EndStreetJ+0.5) || uiy > (EndAptJ+0.5)
                            close(figure(1))
                            msgbox('Invalid Choice. Click within the heatmap.', 'Error', 'error')
                        end
                    end
                    close(figure(1))
            end
        case 'No'  
    end
    
    if strcmp(InitChoice, 'No')
        break
    end

    if uix >= (StartStreetJ-0.5) && uiy >= (StartAptJ-0.5) && uix <= (EndStreetJ+0.5) && uiy <= (EndAptJ+0.5)
        uix = round(uix); uiy = round(uiy);
        if useTiff == 1
            fileType = 'tif';
        else
            fileType = 'jpg';
        end
        if     uiy < 10 && uix < 10
            ChosenBFIm = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000.%s', BFDirContImages, MagFactor, uix, uiy, fileType);
            ChosenFluoroIm = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000.%s', FluoroDirContImages{2}, filterUsed, MagFactor, uix, uiy, fileType);
            ChosenTrackedIm = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000_Tracked_Exp%d.%s', dirNameTracked, MagFactor, uix, uiy, ExpCondNumber, fileType);
            FluoroOverlayIm = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000_Aligned_Exp%d.%s', dirNameFluoroOverlay, filterUsed, MagFactor, uix, uiy, ExpCondNumber, fileType);

        elseif uiy >= 10 && uiy < 100 && uix < 10
            ChosenBFIm = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000.%s', BFDirContImages, MagFactor, uix, uiy, fileType);
            ChosenFluoroIm = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000.%s', FluoroDirContImages{2}, filterUsed, MagFactor, uix, uiy, fileType);
            ChosenTrackedIm = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000_Tracked_Exp%d.%s', dirNameTracked, MagFactor, uix, uiy, ExpCondNumber, fileType);
            FluoroOverlayIm = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000_Aligned_Exp%d.%s', dirNameFluoroOverlay, filterUsed, MagFactor, uix, uiy, ExpCondNumber, fileType);

        elseif uiy < 10 && uix >= 10 && uix < 100
            ChosenBFIm = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000.%s', BFDirContImages, MagFactor, uix, uiy, fileType);
            ChosenFluoroIm = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000.%s', FluoroDirContImages{2}, filterUsed, MagFactor, uix, uiy, fileType);
            ChosenTrackedIm = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000_Tracked_Exp%d.%s', dirNameTracked, MagFactor, uix, uiy, ExpCondNumber, fileType);
            FluoroOverlayIm = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000_Aligned_Exp%d.%s', dirNameFluoroOverlay, filterUsed, MagFactor, uix, uiy, ExpCondNumber, fileType);

        elseif uiy >= 10 && uiy < 100 && uix >= 10 && uix < 100
            ChosenBFIm = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000.%s', BFDirContImages, MagFactor, uix, uiy, fileType);
            ChosenFluoroIm = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000.%s', FluoroDirContImages{2}, filterUsed, MagFactor, uix, uiy, fileType);
            ChosenTrackedIm = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000_Tracked_Exp%d.%s', dirNameTracked, MagFactor, uix, uiy, ExpCondNumber, fileType);
            FluoroOverlayIm = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000_Aligned_Exp%d.%s', dirNameFluoroOverlay, filterUsed, MagFactor, uix, uiy, ExpCondNumber, fileType);

        end
        
        figure(1); clf
        set(gcf, 'units', 'centimeters', 'Position', [2 2 30 22])
        subplot(2, 2, 1), imshow(imread(ChosenBFIm))
        title('Brightfield Image')
        subplot(2, 2, 2), imshow(imread(ChosenFluoroIm))
        title('Fluorescent Image')
        if strcmp(ChipType, 'Full P-Chip')
            subplot(2, 2, 3), imshow(imcrop(imread(ChosenTrackedIm), [135 48 956 635]))
        elseif strcmp(ChipType, '7-Condition Chip')
            subplot(2, 2, 3), imshow(imcrop(imread(ChosenTrackedIm), [116 38 1294 860]))
        elseif strcmp(ChipType, 'Y-Chip (50x50)')
            subplot(2, 2, 3), imshow(imcrop(imread(ChosenTrackedIm), [52 20 388 388]))
        elseif strcmp(ChipType, 'Y-Chip (100x100)')
            subplot(2, 2, 3), imshow(imcrop(imread(ChosenTrackedIm), [52 20 388 388]))
        end
        title('Brightfield Tracked Image with Overlayed Fluorescent False Coloring')
        subplot(2, 2, 4), imshow(imread(FluoroOverlayIm))
        title('Brightfield with Overlayed Fluorescent False Coloring')
        uiwait(msgbox('Click okay when you want to close figure containing images.'))

    end
    counter = counter + 1;
end
close all
% %% Shit Ben didn't think I could do
% % Initializing a counter
% counter = 1;
% InitChoice = 'Yes';
% 
% FigMergeName = sprintf('Merged_TrapApt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.fig',...
%                    StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExperimentNumber);
%                
% if exist(FigMergeName) ~= 2
% 
%     % Creating super figure
%     Fig1NameD = sprintf('Trap_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.fig',...
%        StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExperimentNumber);
%     Fig2NameD = sprintf('Apt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.fig',...
%        StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExperimentNumber);      
% 
%     Fig1 = hgload(Fig1NameD);
%     Fig2 = hgload(Fig2NameD);
% 
%     figure(3); clf
%     set(gcf, 'units', 'centimeters', 'Position', [2 2 30 22])
%     h(1) = subplot(2,1,1);
%     hold on
%     h3 = zeros(4, 1);
%     for ii9 = 2:4
%         h3(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
%                       'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
%         h3(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
%                       'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
%     end
%     lgd2 = legend(h3, '0', '1', '2', '3+', 'Location', 'Eastoutside');
%     lgd2.FontSize = 20;
%     axis([-0.5 95.5 -0.5 39.5])
%     set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
%     set(gca,'XtickLabel', 0:2:(length(Length)-1))
%     set(gca,'YTick', 0:2:(length(Height)-1), 'Fontsize', 10)
%     set(gca,'YtickLabel', 0:2:(length(Height)-1))
%     xlabel('Street', 'Fontsize', 16)
%     ylabel('Apartment', 'Fontsize', 16)
%     title('Trap Population Heat Map', 'Fontsize', 16)
%     hold off
% 
%     h(2) = subplot(2,1,2);
%     hold on
%     h3 = zeros(4, 1);
%     for ii9 = 2:4
%         h3(ii9) = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(ii9, :),...
%                       'MarkerEdgeColor', colormap_custom(ii9, :), 'MarkerSize', 20);
%         h3(1)   = plot(NaN, NaN, 's', 'MarkerFaceColor', colormap_custom(1, :),...
%                       'MarkerEdgeColor', colormap_custom(1, :), 'MarkerSize', 20);
%     end
%     lgd2 = legend(h3, '0', '1', '2', '3+', 'Location', 'Eastoutside');
%     lgd2.FontSize = 20;
%     axis([-0.5 95.5 -0.5 39.5])
%     set(gca,'XTick', 0:2:(length(Length)-1), 'Fontsize', 10)
%     set(gca,'XtickLabel', 0:2:(length(Length)-1))
%     set(gca,'YTick', 0:2:(length(Height)-1), 'Fontsize', 10)
%     set(gca,'YtickLabel', 0:2:(length(Height)-1))
%     xlabel('Street', 'Fontsize', 16)
%     ylabel('Apartment', 'Fontsize', 16)
%     title('Apartment Population Heat Map', 'Fontsize', 16)
% 
%     hold off
%     
%     copyobj(allchild(get(Fig1, 'CurrentAxes')), h(1));
%     copyobj(allchild(get(Fig2, 'CurrentAxes')), h(2));
%     
% 
%     close(figure(1)); close(figure(2));
% 
% % Saving Merged Figure
%     FigMergeName = sprintf('Merged_TrapApt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d',...
%                        StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExperimentNumber);
%     saveas(figure(3), FigMergeName)
%     FigMergeNameD = sprintf('Merged_TrapApt_Population_Heat_Map_StreetStreets%d-%d_Apts%d-%d_Exp%d.jpg',...
%                        StartStreetJ, EndStreetJ, StartAptJ, EndAptJ', ExperimentNumber);
%     saveas(figure(3), FigMergeNameD)
% 
% else
%     openfig(FigMergeName)
% end
% 
% while strcmp(InitChoice, 'Yes')
%     uix = -1; uiy = -1;
%     if     counter == 1
%         InitChoice = questdlg('Are there any traps or apartments you want to see the images for?',...
%                               'See Images?',...
%                                'Yes', 'No', 'No');
%     elseif counter >= 2
%         InitChoice = questdlg('Are there any more traps or apartments you want to see the images for?',...
%                               'See Images?',...
%                                'Yes', 'No', 'No');
%     end
%     % Choice switch cases tree
%     switch InitChoice
%         case 'Yes'
%             if counter == 1 
%                 uiwait(msgbox('The figure will open upon clicking okay. Click on the trap you want to see pictures for.'))
%             end
% 
%             while  uix(counter, 1) < -0.5 || uiy(counter, 1) < -0.5 || uix(:, 1) > 95.5 || uiy(:, 1) > 39.5
%             [uix, uiy] = ginput;
%                 if uiy(:, 1) < -0.5 || uiy(:, 1) < -0.5 || uiy(:, 1) > 95.5 || uiy(:, 1) > 39.5
%                     msgbox('Invalid Choice. Click within the heatmap.', 'Error', 'error')
%                     uiy(end) = []; uix = [];
%                 end
%             fprintf('Street: %d, Apartment: %d\n', round(uix), round(uiy))
%             end
% 
%         case 'No' 
%             close(gcf)
%     end
%     
%     if strcmp(InitChoice, 'No')
%         break
%     end
% 
%     for sv = 1:length(uix(:, 1))
%         if uix(sv, 1) >= -0.5 && uiy(sv, 1) >= -0.5 && uix(sv, 1) <= 95.5 && uiy(sv, 1) <= 39.5
%             uix(sv, 1) = round(uix(sv, 1)); uiy(sv, 1) = round(uiy(sv, 1));
%         if useTiff == 1
%             fileType = 'tif';
%         else
%             fileType = 'jpg';
%         end
%         if     uiy(sv, 1) < 10 && uix(sv, 1) < 10
%             ChosenBFIm = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000.%s', BFDirContImages, MagFactor, uix(sv, 1), uiy, fileType);
%             ChosenFluoroIm = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000.%s', FluoroDirContImages, filterUsed, MagFactor, uix(sv, 1), uiy, fileType);
%             ChosenTrackedIm = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000_Tracked_Exp%d.%s', dirNameTracked, MagFactor, uix(sv, 1), uiy, ExperimentNumber, fileType);
%             FluoroOverlayIm = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000_Aligned_Exp%d.%s', dirNameFluoroOverlay, filterUsed, MagFactor, uix(sv, 1), uiy, ExperimentNumber, fileType);
% 
%         elseif uiy(sv, 1) >= 10 && uiy(sv, 1) < 100 && uix(sv, 1) < 10
%             ChosenBFIm = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000.%s', BFDirContImages, MagFactor, uix(sv, 1), uiy(sv, 1), fileType);
%             ChosenFluoroIm = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000.%s', FluoroDirContImages, filterUsed, MagFactor, uix(sv, 1), uiy(sv, 1), fileType);
%             ChosenTrackedIm = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000_Tracked_Exp%d.%s', dirNameTracked, MagFactor, uix(sv, 1), uiy(sv, 1), ExperimentNumber, fileType);
%             FluoroOverlayIm = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000_Aligned_Exp%d.%s', dirNameFluoroOverlay, filterUsed, MagFactor, uix(sv, 1), uiy(sv, 1), ExperimentNumber, fileType);
% 
%         elseif uiy(sv, 1) < 10 && uix(sv, 1) >= 10 && uix(sv, 1) < 100
%             ChosenBFIm = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000.%s', BFDirContImages, MagFactor, uix(sv, 1), uiy(sv, 1), fileType);
%             ChosenFluoroIm = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000.%s', FluoroDirContImages, filterUsed, MagFactor, uix(sv, 1), uiy(sv, 1), fileType);
%             ChosenTrackedIm = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000_Tracked_Exp%d.%s', dirNameTracked, MagFactor, uix(sv, 1), uiy(sv, 1), ExperimentNumber, fileType);
%             FluoroOverlayIm = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000_Aligned_Exp%d.%s', dirNameFluoroOverlay, filterUsed, MagFactor, uix(sv, 1), uiy(sv, 1), ExperimentNumber, fileType);
% 
%         elseif uiy(sv, 1) >= 10 && uiy(sv, 1) < 100 && uix(sv, 1) >= 10 && uix(sv, 1) < 100
%             ChosenBFIm = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000.%s', BFDirContImages, MagFactor, uix(sv, 1), uiy(sv, 1), fileType);
%             ChosenFluoroIm = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000.%s', FluoroDirContImages, filterUsed, MagFactor, uix(sv, 1), uiy(sv, 1), fileType);
%             ChosenTrackedIm = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000_Tracked_Exp%d.%s', dirNameTracked, MagFactor, uix(sv, 1), uiy(sv, 1), ExperimentNumber, fileType);
%             FluoroOverlayIm = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000_Aligned_Exp%d.%s', dirNameFluoroOverlay, filterUsed, MagFactor, uix(sv, 1), uiy(sv, 1), ExperimentNumber, fileType);
% 
%         end
% 
%         figure(sv); clf
%         set(gcf, 'units', 'centimeters', 'Position', [2 2 30 22])
%         subplot(2, 2, 1), imshow(imread(ChosenBFIm))
%         title('Brightfield Image')
%         subplot(2, 2, 2), imshow(imread(ChosenFluoroIm))
%         title('Fluorescent Image')
%         subplot(2, 2, 3), imshow(imcrop(imread(ChosenTrackedIm), [135 48 956 635]))
%         title('Brightfield Tracked Image with Overlayed Fluorescent False Coloring')
%         subplot(2, 2, 4), imshow(imread(FluoroOverlayIm))
%         title('Brightfield with Overlayed Fluorescent False Coloring')
%         uiwait(msgbox('Click okay when you want to close figure containing images.'))
%         end
%     end
%     counter = counter + 1;
% end