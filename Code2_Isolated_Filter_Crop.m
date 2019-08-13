%%======================================================================%%
% GitHub Repo: https://github.com/yellenlab/Cell-Array-Counter
%
% Description: Code to crop and isolate individual weirs based on the chip
% type and magnification of the original brightfield and fluroescent images
%
% Author: Sean T. Kelly (GitHub Profile: stkelly; Email: seantk@umich.edu)
% Current Affiliation: Ph.D. Pre-Candidate
%                      Applied Nonlinear Dynamics of Multi-Scale Systems Lab
%                      Mechanical Engineering Department, University of Michigan
%
% Created on: 8/2/17
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
% 1. Make sure you have run "Code1_Extract_Unedited_Files.m" fully. If
% not, go do so and do not continue to step 2. If using 16X, and/or
% pictures of each individual apartment complex already exist, do not run
% this code.
%
% 2. (Optional First Alignment) Open ImageJ, and upload brightfield images
% in BFUnedited folder as an image sequence from the BFUnedted folder. If
% using P-Chip, there should be 320 images. If 7-Condition Chip, there
% should be 136 images. To do this, go to ImageJ and select
% File->Import->Image Sequence.Navigate to BFUnedited folder, and if on
% Mac, click on the folder and select choose. On Windows machine, open the
% folder and select first image in folder when sorted name
% (image with st_000_apt_000). Click Choose. Click okay in following menu
% with only "Sort Name Numerically" checked.
%
% 3. Selected a large rectangle over most of the FIRST image (st_000_apt_000)
% which should have apartment complex 00/00 in the lower left. Go to
% Plugins->Template Matching->Align slices in stack. Clock Ok twice. Let run.
%
% 4. Once finished, save the results table. It will save as an Excel
% file. Open the Excel file (click "Yes" to warning), and resave it as
% "DisplacementLogIso" as a .txt file. Open that .txt file and DELETE THE
% FIRST LINE WITH TEXT. Drag and drop that .txt file into the working
% directory in MATLAB. If no file given or name isn't exactly
% "DisplacementLogIso.txt", no correction will be made and images will not
% be aligned, though the code can still run to completion.
%
% 5. Click "Run" to start the program.
%
% 6. Follow all dialog boxes. Images will load, being aligned, and then
% user will be prompted to select alignment marks on apartment complexes
% 00/00, then 01/00, then 00/01. If images have been cropped previously,
% user will be prompted asking if they want to use this again. If yes, no
% further input required. If no, user will have to go through selecting
% alignment marks (again).
%
% 7. Let program finish isolating and saving images.
%
%% BEGINNING ON CODE SUBSTANCE
tic
clear; close all; format short

% Checking to see if chip type, magnification factor, fluorescent filter
% used, and if the images are tifs or jpgs have been specified by running
% Code1_Extract_Unedited_Files.m. If not, user will be prompted as
% necessary.

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
        ChipUsedQ = questdlg('What chip was imaged?',...
                             'Chip Imaged',...
                             'Full P-Chip', '7-Condition Chip', 'Y-Chip', 'Full P-Chip');
        if strcmp(ChipUsedQ, 'Full P-Chip') || strcmp(ChipUsedQ, '7-Condition Chip')
            ChipType = ChipUsedQ;
        elseif strcmp(ChipUsedQ, 'Y-Chip')
            ChipUsedQ = questdlg('What size was the Y-Chip?',...
                                'Chip Imaged',...
                                '50x50', '100x100', '100x100');  
            if strcmp(ChipUsedQ, '50x50') 
               ChipType = 'Y-Chip (50x50)';
            elseif strcmp(ChipUsedQ, '100x100')
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

% Creating step counters for loading bars, which is same number of total
% images and thus columns of displacement log
if     strcmp(ChipType, 'P-Chip')
    steps = 320;
    Indices = [3 4];
elseif strcmp(ChipType, '7-Condition Chip')
    steps = 136; 
    Indices = [2 2];
elseif strcmp(ChipType, 'Y-Chip (50x50)')
    steps = 221;
    Indices = [4 3];
elseif strcmp(ChipType, 'Y-Chip (100x100)')
    steps = 850; % Change this value later
    Indices = [4 3];
end

% Loading in displacement log from ImageJ. Name must match .txt file.
if exist('DisplacementLogIso.txt', 'file') == 0
    DispLog = zeros(steps, 4);
else
    DispLog = load('DisplacementLogIso.txt');  
end  

% Setting number of streets and apartments based on chip imaged
if     strcmp(ChipType, 'Full P-Chip')
    StartStreet = 0;
    EndStreet   = 95; 
    StartApt    = 0;
    EndApt      = 39;
elseif strcmp(ChipType, '7-Condition Chip')
    StartStreet = 0;
    EndStreet   = 15; 
    StartApt    = 0;
    EndApt      = 33;
elseif strcmp(ChipType, 'Y-Chip (50x50)')
    StartStreet = 0;
    EndStreet   = 49; 
    StartApt    = 0;
    EndApt      = 49;
elseif strcmp(ChipType, 'Y-Chip (100x100)')
    StartStreet = 0;
    EndStreet   = 99; 
    StartApt    = 0;
    EndApt      = 99;
end

%% Loading in Raw Images 
% Names of folders to put BF and fluorescent image
BfDirName = 'BFIsolated';
mkdir(BfDirName);
FluoroDirName = {'FluoroIsolatedNoFilter', 'FluoroIsolatedFiltered'};
mkdir(FluoroDirName{1}); mkdir(FluoroDirName{2});

BFUneditedDir = 'BFUnedited';
FluoroUneditedDir = 'FluoroUnedited';

h1 = waitbar(0, 'Loading in raw images...');
step1 = 1;

% Initilizing (Matlab) cells for images
BFimages = {[], []};
Fluoroimages = {[], []};

for iii = (StartStreet+1):(EndStreet+1)
    for ii = (StartApt+1):(EndApt+1)
        if  mod(iii-1, Indices(1)) == 0 && mod(ii-1, Indices(2)) == 0
            if     (ii-1) < 10 && (iii-1) < 10
                BFfilename = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000.%s',...
                                      BFUneditedDir, MagFactor, iii-1, ii-1, TiforJpg);
                Fluorofilename = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000.%s',...
                                      FluoroUneditedDir, filterUsed, MagFactor, iii-1, ii-1, TiforJpg);
            elseif (ii-1) >= 10 && (ii-1) < 100 && (iii-1) < 10
                BFfilename = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000.%s',...
                                      BFUneditedDir, MagFactor, iii-1, ii-1, TiforJpg);            
                Fluorofilename = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000.%s',...
                                      FluoroUneditedDir, filterUsed, MagFactor, iii-1, ii-1, TiforJpg);  

            elseif (ii-1) < 10 && (iii-1) >= 10 && (iii-1) < 100
                BFfilename = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000.%s',...
                                      BFUneditedDir, MagFactor, iii-1, ii-1, TiforJpg);            
                Fluorofilename = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000.%s',...
                                      FluoroUneditedDir, filterUsed, MagFactor, iii-1, ii-1, TiforJpg);

            elseif (ii-1) >= 10 && (ii-1) < 100 && (iii-1) >= 10 && (iii-1) < 100
                BFfilename = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000.%s',...
                                      BFUneditedDir, MagFactor, iii-1, ii-1, TiforJpg);            
                Fluorofilename = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000.%s',...
                                      FluoroUneditedDir, filterUsed, MagFactor, iii-1, ii-1, TiforJpg); 
            end
            if any(size(dir(['BFUnedited' sprintf('/*.%s',  TiforJpg)]),1)) == 0
                close(h1)
                errordlg(sprintf('No images with %s file type were found in the folder selected. Check image type.', TiforJpg),...
                         sprintf('No %s Images', TiforJpg))
                return
            end
            BFimages{iii, ii} = imread(BFfilename);
            Fluoroimages{iii, ii} = imread(Fluorofilename);
            waitbar(step1/steps)
            step1 = step1 + 1;
        end
    end
end
close(h1)

% Removing empty entries 
BFimages = BFimages(~cellfun('isempty', BFimages));
Fluoroimages = Fluoroimages(~cellfun('isempty', Fluoroimages));

% Specifying number of streets/apts. per image and reshaping cell with BF
% and Fluorescent images
if     strcmp(ChipType, 'Full P-Chip')
    NumStreetPics = 32; % Number of pictures along streets
    StsPerIm      = 3;  % Number of streets in single image
    NumRowPics    = 17; % Number of pictures along rows
    RowsPerIm     = 4;  % Number of rows in single image
    TotalNum      = 3840; % Total number of apts on chip 
    BFimages = reshape(BFimages, NumStreetPics, []);
    Fluoroimages = reshape(Fluoroimages, NumStreetPics, []);
elseif strcmp(ChipType, '7-Condition Chip')
    NumStreetPics = 8;
    StsPerIm      = 2;
    NumRowPics    = 17;
    RowsPerIm     = 2;
    TotalNum      = 544;
    BFimages = reshape(BFimages, NumStreetPics, []);
    Fluoroimages = reshape(Fluoroimages, NumStreetPics, []);
elseif strcmp(ChipType, 'Y-Chip (50x50)')
    NumStreetPics = 13;
    StsPerIm      = 4;
    NumRowPics    = 17;
    RowsPerIm     = 3;
    TotalNum      = 2500; % Really 2475; 2500 used for processing
    BFimages = reshape(BFimages, NumStreetPics, []);
    Fluoroimages = reshape(Fluoroimages, NumStreetPics, []);
elseif strcmp(ChipType, 'Y-Chip (100x100)')
    NumStreetPics = 25;
    StsPerIm      = 4;
    NumRowPics    = 34;
    RowsPerIm     = 3;
    TotalNum      = 10000; % Really 9950; 10000 used for processing
    BFimages = reshape(BFimages, NumStreetPics, []);
    Fluoroimages = reshape(Fluoroimages, NumStreetPics, []);
end

%% Processing Raw Images Using Displacement Log from ImageJ
Slice = zeros(NumStreetPics, 1);
Slice(2:length(DispLog(:, 2))+1) = DispLog(1:length(DispLog(:, 2)), 2); 
Slice = vec2mat(Slice, NumRowPics);
SliceEdit = Slice(1:NumStreetPics, 1:NumRowPics);

SliceDx = zeros(NumStreetPics, 1);
SliceDx(2:length(DispLog(:, 3))+1) = DispLog(1:length(DispLog(:, 3)), 3); 
SliceDx(2:length(DispLog(:, 3))+1) = DispLog(1:length(DispLog(:, 3)), 3); 
SliceDx = vec2mat(SliceDx, NumRowPics);
SliceDxEdit = SliceDx(1:NumStreetPics, 1:NumRowPics);

SliceDy = zeros(NumStreetPics, 1);
SliceDy(2:length(DispLog(:, 4))+1) = DispLog(1:length(DispLog(:, 4)), 4); 
SliceDy(2:length(DispLog(:, 4))+1) = DispLog(1:length(DispLog(:, 4)), 4); 
SliceDy = vec2mat(SliceDy, NumRowPics);
SliceDyEdit = SliceDy(1:NumStreetPics, 1:NumRowPics);

% Taking chosen images and applying ImageJ Translations to both BF and GFP Images
% Initilizing (Matlab) cells for now diplsaced images
tform = {0, 0};
BFShifted = {0, 0};
FluoroShifted = {0, 0}; 

for iii3 = 1:NumStreetPics
    for ii3 = 1:NumRowPics
        T = [1 0 0; 0 1 0; SliceDxEdit(iii3, ii3) SliceDyEdit(iii3, ii3) 1];
        tform{iii3, ii3} = affine2d(T);
        BFShifted{iii3, ii3} = imwarp_same(BFimages{iii3, ii3}, tform{iii3, ii3});
        FluoroShifted{iii3, ii3, 1} = imwarp_same(Fluoroimages{iii3, ii3}, tform{iii3, ii3});
        
        if iii3 == 1 && ii3 == 1
            imshow(FluoroShifted{iii3, ii3, 1});
            FilterQ = 'Yes';
            Filtercounter = 1;
            FilterVals = [120 100 90 80 60 60]; % Filter values
            
            while strcmp(FilterQ, 'Yes')
                if Filtercounter == 1
                    FilterQ = questdlg('Are there any small white dots (speckling) in the fluorescent image shown?',...
                                       'White Dots?',...
                                       'Yes', 'No', 'Cancel', 'Yes');
                elseif Filtercounter > 1 && Filtercounter < 5
                    FilterQ = questdlg('Are there any still small white dots (speckling) in the fluorescent image shown?',...
                                       'White Dots?',...
                                       'Yes', 'No', 'Cancel', 'Yes'); 
                elseif Filtercounter == 5
                    MaxFiltNote = msgbox('Max image filtering allowed. Press OK to continue.');
                    waitfor(MaxFiltNote);
                end
                waitfor(FilterQ);
                switch FilterQ
                    case 'Yes'
                        close all
                        w1 = waitbar(0, 'Filtering image...');
                        IMF = medfilt2(FluoroShifted{iii3, ii3, 1}, [7 7]);
                        % Find the noise in the image.
                        noiseI = (FluoroShifted{iii3, ii3, 1} == 0 | FluoroShifted{iii3, ii3, 1} >= FilterVals(Filtercounter));
                        % Get rid of the noise by replacing with median.
                        waitbar(1/4)
                        noiseFreeI = FluoroShifted{iii3, ii3, 1};
                        waitbar(2/4)
                        noiseFreeI(noiseI) = IMF(noiseI);
                        waitbar(3/4)
                        % Adding to filtercounter
                        Filtercounter = Filtercounter + 1;
                        
                        IMF2 = deconvblind(noiseFreeI, ones(size(noiseFreeI)));
                        waitbar(1, 'Completed.');
                        pause(0.2)
                        close all
                        
                        % Showing filtered image
                        imshow(IMF2);
                    case 'No'
                        close all;
                        IMF2 = FluoroShifted{iii3, ii3, 1};
                    case 'Cancel'
                        close all;
                        return
                end
            end
            h1 = waitbar(0, 'Filtering images...');
            step1 = 1;
        else
            if Filtercounter > 1
                IMF = medfilt2(FluoroShifted{iii3, ii3, 1}, [7 7]);
                % Find the noise in the image.
                noiseI = (FluoroShifted{iii3, ii3, 1} == 0 | FluoroShifted{iii3, ii3, 1} >= FilterVals(Filtercounter));
                % Get rid of the noise by replacing with median.
                noiseFreeI = FluoroShifted{iii3, ii3, 1};
                noiseFreeI(noiseI) = IMF(noiseI);
                IMF2 = deconvblind(noiseFreeI, ones(size(noiseFreeI)));
            elseif Filtercounter == 1
                IMF2 = FluoroShifted{iii3, ii3, 1};
            end
            waitbar(step1/steps)
            step1 = step1 + 1;
        end
        % FluoroShifted{iii3, ii3} = noiseFreeI;
        FluoroShifted{iii3, ii3, 2} = IMF2;
    end
end
close(h1)

%% Saving Aligned Images in Their Own Directory
BfDirName2 = 'BFAligned';
mkdir(BfDirName2);
FluoroDirName2 = {'FluoroAlignedNoFilter', 'FluoroAlignedFiltered'};
mkdir(FluoroDirName2{1}); mkdir(FluoroDirName2{2});

% Initializing cell for normalized images and threshold matrix
FluoroShiftedN = {[], [], []};
AutoThresh = zeros(NumStreetPics, NumRowPics);

h2 = waitbar(0, 'Aligning images...');
step2 = 1;

for FIV = 1:2
    for iii3 = 1:NumStreetPics
        for ii3 = 1:NumRowPics 
            if     (ii3*RowsPerIm-RowsPerIm) < 10 && (iii3*StsPerIm-StsPerIm) < 10
                if FIV == 1 % Only for FIV = 1 so we save them only once
                    BFNewfilename = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000.jpg',...
                                         BfDirName2, MagFactor, (iii3*StsPerIm-StsPerIm), (ii3*RowsPerIm-RowsPerIm));
                end
                FluoroNewfilename = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000.jpg',...
                                      FluoroDirName2{FIV}, filterUsed, MagFactor, (iii3*StsPerIm-StsPerIm), (ii3*RowsPerIm-RowsPerIm));
            elseif (ii3*RowsPerIm-RowsPerIm) >= 10 && (ii3*RowsPerIm-RowsPerIm) < 100 && (iii3*StsPerIm-StsPerIm) < 10
                if FIV == 1
                    BFNewfilename = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000.jpg',...
                                          BfDirName2, MagFactor, (iii3*StsPerIm-StsPerIm), (ii3*RowsPerIm-RowsPerIm));   
                end
                FluoroNewfilename = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000.jpg',...
                                      FluoroDirName2{FIV}, filterUsed, MagFactor, (iii3*StsPerIm-StsPerIm), (ii3*RowsPerIm-RowsPerIm));                              
            elseif (ii3*RowsPerIm-RowsPerIm) < 10 && (iii3*StsPerIm-StsPerIm) >= 10 && (iii3*StsPerIm-StsPerIm) < 100
                if FIV == 1
                    BFNewfilename = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000.jpg',...
                                          BfDirName2, MagFactor, (iii3*StsPerIm-StsPerIm), (ii3*RowsPerIm-RowsPerIm));   
                end
                FluoroNewfilename = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000.jpg',...
                                      FluoroDirName2{FIV}, filterUsed, MagFactor, (iii3*StsPerIm-StsPerIm), (ii3*RowsPerIm-RowsPerIm));                              
            elseif (ii3*RowsPerIm-RowsPerIm) >= 10 && (ii3*RowsPerIm-RowsPerIm) < 100 && (iii3*StsPerIm-StsPerIm) >= 10 && (iii3*StsPerIm-StsPerIm) < 100
                if FIV == 1
                    BFNewfilename = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000.jpg',...
                                        BfDirName2, MagFactor, (iii3*StsPerIm-StsPerIm), (ii3*RowsPerIm-RowsPerIm));    
                end
                FluoroNewfilename = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000.jpg',...
                                      FluoroDirName2{FIV}, filterUsed, MagFactor, (iii3*StsPerIm-StsPerIm), (ii3*RowsPerIm-RowsPerIm));  
            end
            imwrite(BFShifted{iii3, ii3}, BFNewfilename, 'jpg')
            imwrite(FluoroShifted{iii3, ii3, FIV}, FluoroNewfilename, 'jpg')

            % Normalizing image for only finding threshold values when
            % imagse are normalized during primary analysis
            min1 = min(min(FluoroShifted{iii3, ii3, FIV}));
            max1 = max(max(FluoroShifted{iii3, ii3, FIV}));
            FluoroShiftedN{iii3, ii3, FIV} = uint8(255.*((double(FluoroShifted{iii3, ii3, FIV}) - double(min1)))./...
                                                double(max1 - min1));
            % Finding threshold values from greythresh command
            if FIV == 2
                AutoThresh(iii3, ii3) = graythresh(FluoroShiftedN{iii3, ii3, 2});
            end

            waitbar((step2/2)/steps)
            step2 = step2 + 1;           
        end
    end
end
close(h2)

% Finding average threshold from greythresh
ThreshAve = mean(mean(AutoThresh(1:(end-1), 1:(end-1))));
save('AutoThreshVal', 'ThreshAve')

%% Selecting Crop Region for Whole Apartment Complex
AptComplexCrop = []; % Initializing apartment complex crop matrix

AptComplexCropName = sprintf('AptComplexCropMat_Streets%d-%d_Apts%d-%d_1_Isolating.mat',...
                             StartStreet, EndStreet, StartApt, EndApt);
dxdyMatName          = sprintf('dxdyMat_Streets%d-%d_Apts%d-%d_1_Isolating.mat',...
                                 StartStreet, EndStreet, StartApt, EndApt);
                         
% Checking to see if the name previously exists, and asking user if they want to use it
if exist(AptComplexCropName, 'file') == 2 && exist(dxdyMatName, 'file') == 2 
    CheckifCropped = questdlg('Do you want to use previous cropping selections?',...
                              'Use Previous Crop?',...
                              'Yes', 'No', 'Cancel', 'Yes');
    waitfor(CheckifCropped);
    if strcmp(CheckifCropped, 'Cancel')
        return
    end
end

% Initlizing matrices and cells that contain shifting coordinates for
% cropping and will store cropped images, respectively
xTotal = [1, 1];
yTotal = [1, 1];
AptComplexCrop = {1, 1};

% Cropping to allow for 
if exist(AptComplexCropName, 'file') == 2 && exist(dxdyMatName, 'file') == 2 && strcmp(CheckifCropped, 'Yes')
    AptComplexCropDummy = load(AptComplexCropName);
    dxdyDummy   = load(dxdyMatName);
    xTotalDummy = AptComplexCropDummy.AptComplexCrop(:, 1);
    yTotalDummy = AptComplexCropDummy.AptComplexCrop(1, :);
    dx = dxdyDummy.dxdyMat(1, 1:Indices(1));
    dy = dxdyDummy.dxdyMat(2, 1:Indices(2));
    for xv = 1:Indices(1)
        xTotal(xv, 1) = xTotalDummy{xv, 1}(1); 
    end
    for yv = 1:Indices(2)
        yTotal(yv, 1) = yTotalDummy{1, yv}(2);
    end        
else
    imshow(BFShifted{1, 1}, 'InitialMagnification', 100)
    if     strcmp(ChipType, 'Full P-Chip')
        msg1 = msgbox('Please select center of alignement mark in apartment complex 00/00.');
        waitfor(msg1);
        [x00, y00] = ginput(1); x0 = x00 - 208; y0 = y00 + 280;
        msg2 = msgbox('Please select center of alignement marks in apartment complexes 01/00 and 02/00, in that order.');
        waitfor(msg2);
        [x1, y1] = ginput(2); 
        msg3 = msgbox('Please select center of alignement marks in apartment complexes 00/01, 00/02, and 00/03 in that order.\n\n');
        waitfor(msg3);
        [x2, y2] = ginput(3);     

        dx(1) = x1(1) - x00; dx(2) = x1(2) - x1(1); dx(3) = mean(dx); % ~420 for dx
        dy(1) = -(y2(1) - y00); dy(2) = -(y2(2) - y2(1)); dy(3) = -(y2(3) - y2(2)); dy(4) = mean(dy); % ~280 for dy

        xTotal = [x0 x0+dx(1) x0+sum(dx(1:2)) x0+sum(dx(1:3))]';
        yTotal = [y0-dy(1) y0-sum(dy(1:2)) y0-sum(dy(1:3)) y0-sum(dy(1:4))]';

        for iii2 = 1:3
            for ii2 = 1:4
                AptComplexCrop{iii2, ii2} = [xTotal(iii2) yTotal(ii2)];
            end
        end
    elseif strcmp(ChipType, '7-Condition Chip')
        msg1 = msgbox('Please select center of alignement mark in apartment complex 00/00.');       
        waitfor(msg1);
        [x00, y00] = ginput(1); x0 = x00 - 258; y0 = y00 + 338;
        msg2 = msgbox('Please select center of alignement marks in apartment complex 01/00.');
        waitfor(msg2);
        [x1, y1] = ginput(1); 
        msg3 = msgbox('Please select center of alignement marks in apartment complex 00/01.');
        waitfor(msg3);
        [x2, y2] = ginput(1);     

        dx(1) = x1(1) - x00; dx(2) = dx(1);
        dy(1) = -(y2(1) - y00); dy(2) = dy(1);

        xTotal = [x0 x0+dx(1) x0+sum(dx(1:2))]';
        yTotal = [y0-dy(1) y0-sum(dy(1:2))]';

        for iii2 = 1:2
            for ii2 = 1:2
                AptComplexCrop{iii2, ii2} = [xTotal(iii2) yTotal(ii2)];
            end
        end    
    elseif strcmp(ChipType, 'Y-Chip (50x50)') ||  strcmp(ChipType, 'Y-Chip (100x100)')
        msg1 = msgbox('Please select approximate center of apartment complex 00/00 (center of circular area).');       
        waitfor(msg1);
        [x00, y00] = ginput(1); x0 = x00 - 138; y0 = y00 + 138;
        msg2 = msgbox('Please select approximate center of apartment complexes 00/01, 00/02, and 00/03 in that order (Note: apt/street, or top number/bottom number).');
        waitfor(msg2);
        [x1, y1] = ginput(3); 
        msg3 = msgbox('Please select approximate center of apartment complexes 01/00 and 02/00 in that order (Note: apt/street, or top number/bottom number).');
        waitfor(msg3);
        [x2, y2] = ginput(2);     

        dx(1) = x1(1) - x00; dx(2) = x1(2) - x1(1); dx(3) = x1(3) - x1(2); dx(4) = mean(dx);
        dy(1) = -(y2(1) - y00); dy(2) = -(y2(2) - y2(1)); dy(3) = mean(dy);

        xTotal = [x0 x0+dx(1) x0+sum(dx(1:2)) x0+sum(dx(1:3)) x0+sum(dx(1:4))]';
        yTotal = [y0-dy(1) y0-sum(dy(1:2)) y0-sum(dy(1:3));
                  y0-(1.5.*dy(1)) y0-sum(dy(1:2))-(0.5.*mean(dy)) y0-sum(dy(1:3))-(0.5.*mean(dy))]';

        for iii2 = 1:4
            for ii2 = 1:3
                if iii2 == 1 || iii2 == 3
                    AptComplexCrop{iii2, ii2} = [xTotal(iii2) yTotal(ii2, 1)];
                else
                    AptComplexCrop{iii2, ii2} = [xTotal(iii2) yTotal(ii2, 2)];
                end
            end
        end        
    end
    AptComplexCropName = sprintf('AptComplexCropMat_Streets%d-%d_Apts%d-%d_1_Isolating.mat',...
                                 StartStreet, EndStreet, StartApt, EndApt);
    save(AptComplexCropName, 'AptComplexCrop')
    
    dxdyMatName = sprintf('dxdyMat_Streets%d-%d_Apts%d-%d_1_Isolating.mat',...
                                 StartStreet, EndStreet, StartApt, EndApt);
    
    CurrentFig = gcf; close(CurrentFig)
    CheckVar = 1; % If this exists, crop region was changed, and other regions need to be selected again
end

h3 = waitbar(0, 'Isolating and saving images...');
steps3 = TotalNum;
step3 = 1;

for FIV2 = 1:2
    for iii3 = 1:NumStreetPics
        for ii3 = 1:NumRowPics
            for iv3 = 1:StsPerIm
                for v3 = 1:RowsPerIm
                    BFEditedImages = imcrop(imrotate(BFShifted{iii3, ii3}, 0),...
                           [AptComplexCrop{iv3, v3}...
                            dx(iv3) dy(v3)]);  
                    FluoroEditedImages = imcrop(imrotate(FluoroShifted{iii3, ii3, FIV2}, 0),...
                           [AptComplexCrop{iv3, v3}...
                            dx(iv3) dy(v3)]);
                    if iii3 == 1 && ii3 == 1 && iv3 == 1 && v3 == 1
                        [sizeDy, sizeDx] = size(BFEditedImages);
                    end
                    [currentDy, currentDx] = size(BFEditedImages);
                    padY = 0; padX = 0; % Initializing padding matrix
                    if currentDy < sizeDy
                        padY = sizeDy - currentDy;
                    end
                    if currentDx < sizeDx
                        padX  = sizeDx - currentDx;
                    end

                    BFEditedImages = padarray(BFEditedImages, [padY, padX], 'post');    

                    BFEditedImages2 = imcrop(BFEditedImages, [0 0 sizeDx sizeDy]);  
                    FluoroEditedImages2 = imcrop(FluoroEditedImages, [0 0 sizeDx sizeDy]);                  

                    if     (ii3*RowsPerIm-RowsPerIm+v3-1) < 10 && (iii3*StsPerIm-StsPerIm+iv3-1) < 10
                        if FIV2 == 1
                            BFNewfilename = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000.jpg',...
                                                  BfDirName, MagFactor, (iii3.*StsPerIm-StsPerIm+iv3-1), (ii3.*RowsPerIm-RowsPerIm+v3-1));
                        end
                        FluoroNewfilename = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000.jpg',...
                                              FluoroDirName{FIV2}, filterUsed, MagFactor, (iii3.*StsPerIm-StsPerIm+iv3-1), (ii3.*RowsPerIm-RowsPerIm+v3-1));
                    elseif (ii3*RowsPerIm-RowsPerIm+v3-1) >= 10 && (ii3*RowsPerIm-RowsPerIm+v3-1) < 100 && (iii3*StsPerIm-StsPerIm+iv3-1) < 10
                        if FIV2 == 1
                            BFNewfilename = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000.jpg',...
                                                  BfDirName, MagFactor, (iii3.*StsPerIm-StsPerIm+iv3-1), (ii3.*RowsPerIm-RowsPerIm+v3-1));   
                        end
                        FluoroNewfilename = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000.jpg',...
                                              FluoroDirName{FIV2}, filterUsed, MagFactor, (iii3.*StsPerIm-StsPerIm+iv3-1), (ii3.*RowsPerIm-RowsPerIm+v3-1));                              
                    elseif (ii3*RowsPerIm-RowsPerIm+v3-1) < 10 && (iii3*StsPerIm-StsPerIm+iv3-1) >= 10 && (iii3*StsPerIm-StsPerIm+iv3-1) < 100
                        if FIV2 == 1
                            BFNewfilename = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000.jpg',...
                                                 BfDirName, MagFactor, (iii3.*StsPerIm-StsPerIm+iv3-1), (ii3.*RowsPerIm-RowsPerIm+v3-1));   
                        end
                        FluoroNewfilename = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000.jpg',...
                                              FluoroDirName{FIV2}, filterUsed, MagFactor, (iii3.*StsPerIm-StsPerIm+iv3-1), (ii3.*RowsPerIm-RowsPerIm+v3-1));                              
                    elseif (ii3*RowsPerIm-RowsPerIm+v3-1) >= 10 && (ii3*RowsPerIm-RowsPerIm+v3-1) < 100 && (iii3*StsPerIm-StsPerIm+iv3-1) >= 10 && (iii3*StsPerIm-StsPerIm+iv3-1) < 100
                        if FIV2 == 1    
                            BFNewfilename = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000.jpg',...
                                                  BfDirName, MagFactor, (iii3.*StsPerIm-StsPerIm+iv3-1), (ii3.*RowsPerIm-RowsPerIm+v3-1));    
                        end
                        FluoroNewfilename = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000.jpg',...
                                              FluoroDirName{FIV2}, filterUsed, MagFactor, (iii3.*StsPerIm-StsPerIm+iv3-1), (ii3.*RowsPerIm-RowsPerIm+v3-1));  
                    end
                    if     strcmp(ChipType, 'Full P-Chip')
                        imwrite(imsharpen(imresize(BFEditedImages2, 1.5)), BFNewfilename, 'jpg')
                        imwrite(imsharpen(imresize(FluoroEditedImages2, 1.5)), FluoroNewfilename, 'jpg')
                    elseif strcmp(ChipType, '7-Condition Chip')
                        imwrite(imsharpen(imresize(BFEditedImages2, 1.2)), BFNewfilename, 'jpg')
                        imwrite(imsharpen(imresize(FluoroEditedImages2, 1.2)), FluoroNewfilename, 'jpg')  
                    elseif strcmp(ChipType, 'Y-Chip (50x50)')
                        if iv3 == 2 || iv3 == 4  % Accounting for fewer apts. in odd numbered rows
                            Maxapts = 50; % Set to 49 to get only actual images
                        else
                            Maxapts = 50;
                        end
                        if (iii3*StsPerIm-StsPerIm+iv3-1) < 50 && (ii3*RowsPerIm-RowsPerIm+v3-1) < Maxapts
                            imwrite(imsharpen(imresize(BFEditedImages2, 1.5)), BFNewfilename, 'jpg')
                            imwrite(imsharpen(imresize(FluoroEditedImages2, 1.5)), FluoroNewfilename, 'jpg')
                        end
                    elseif strcmp(ChipType, 'Y-Chip (100x100)')
                        if iv3 == 2 || iv3 == 4  % Accounting for fewer apts. in odd numbered rows
                            Maxapts = 100; % Set to 99 to get only actual images
                        else
                            Maxapts = 100;
                        end
                        if (iii3*StsPerIm-StsPerIm+iv3-1) < 100 && (ii3*RowsPerIm-RowsPerIm+v3-1) < Maxapts
                            imwrite(imsharpen(imresize(BFEditedImages2, 1.5)), BFNewfilename, 'jpg')
                            imwrite(imsharpen(imresize(FluoroEditedImages2, 1.5)), FluoroNewfilename, 'jpg')
                        end                       
                    end

                    waitbar((step3/2)/steps3)
                    step3 = step3 + 1;
                end
            end      
        end
    end
end
close(h3)
toc