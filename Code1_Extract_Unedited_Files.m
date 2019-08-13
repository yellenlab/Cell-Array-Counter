%%======================================================================%%
% GitHub Repo: https://github.com/yellenlab/Cell-Array-Counter
%
% Description: Code to extract unedited raw Bf and GFP/TXR photos and put
% into respective folders to be used for alignment in ImageJ
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
% 1. Click "Run" to start the program.
%
% 2. Follow the dialog boxes.
%
%% BEGINNING ON CODE SUBSTANCE
clear; close all; format short

% Function that creates user interface in uifigure and asks user for the
% type of chip, magnifcation factor, fluorescent filter used, and the image
% file type directly from Metamorph. 
[ChipType, MagFactor, filterUsed, TiforJpg] = getchipinfo_Windows();

if isempty(ChipType)   == 1 || isempty(MagFactor) == 1 ||...
   isempty(filterUsed) == 1 || isempty(TiforJpg)  == 1    
    return
end

% Put name of raw folder from Metamorph containing all images.
mainDirName = uigetdir('', 'Select Folder with Raw Images from Metamorph:');
if mainDirName == 0
    errordlg('No folder selected.','Folder Error');
    return
end

% Setting number of streets and apartments based on chip imaged
if     strcmp(ChipType, 'Full P-Chip')
    StartStreet = 0;
    EndStreet   = 95; 
    StartApt    = 0;
    EndApt      = 39;
    if strcmp(MagFactor, '8X')
        StreetIndices = (StartStreet+1):3:(EndStreet+1);
        AptIndices    = (StartApt+1):4:(EndApt+1);
    else
        StreetIndices = (StartStreet+1):(EndStreet+1);
        AptIndices    = (StartApt+1):(EndApt+1);  
    end 
elseif strcmp(ChipType, '7-Condition Chip')
    StartStreet = 0;
    EndStreet   = 15; 
    StartApt    = 0;
    EndApt      = 33;
    if strcmp(MagFactor, '10X')
        StreetIndices = (StartStreet+1):2:(EndStreet+1);
        AptIndices    = (StartApt+1):2:(EndApt+1);   
    end         
elseif strcmp(ChipType, 'Y-Chip (50x50)')
    StartStreet = 0;
    EndStreet   = 49; 
    StartApt    = 0;
    EndApt      = 49;
    if strcmp(MagFactor, '20X')
        StreetIndices = (StartStreet+1):4:(EndStreet+1);
        AptIndices    = (StartApt+1):3:(EndApt+1);   
    end  
elseif strcmp(ChipType, 'Y-Chip (100x100)')
    StartStreet = 0;
    EndStreet   = 99; 
    StartApt    = 0;
    EndApt      = 99;
    if strcmp(MagFactor, '20X')
        StreetIndices = (StartStreet+1):4:(EndStreet+1);
        AptIndices    = (StartApt+1):3:(EndApt+1);   
    end  
end

% Names of folders to put BF and GFP/TXR image
BfDirName = 'BFUnedited';
mkdir(BfDirName);
FluoroDirName = 'FluoroUnedited';
mkdir(FluoroDirName);

% Initilizing (Matlab) cells for images
BFimages = {[], []};
Fluoroimages = {[], []};

% Isolating images into respective folders
h1 = waitbar(0, 'Saving brightfield and fluorescent images in own folders...');
steps1 = length(StreetIndices).*length(AptIndices);
step1 = 1;
for iii = StreetIndices
    for ii = AptIndices
        if     (ii-1) < 10 && (iii-1) < 10
            BFfilename = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000.%s',...
                                  mainDirName, MagFactor, iii-1, ii-1, TiforJpg);
            Fluorofilename = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000.%s',...
                                  mainDirName, filterUsed, MagFactor, iii-1, ii-1, TiforJpg);
            BFNewfilename = sprintf('%s/BF_%s_St_00%d_Apt_00%d_F_000.%s',...
                                  BfDirName, MagFactor, iii-1, ii-1, TiforJpg);
            FluoroNewfilename = sprintf('%s/%s_%s_St_00%d_Apt_00%d_F_000.%s',...
                                  FluoroDirName, filterUsed, MagFactor, iii-1, ii-1, TiforJpg);
                                  
        elseif (ii-1) >= 10 && (ii-1) < 100 && (iii-1) < 10
            BFfilename = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000.%s',...
                                  mainDirName, MagFactor, iii-1, ii-1, TiforJpg);            
            Fluorofilename = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000.%s',...
                                  mainDirName, filterUsed, MagFactor, iii-1, ii-1, TiforJpg);
            BFNewfilename = sprintf('%s/BF_%s_St_00%d_Apt_0%d_F_000.%s',...
                                  BfDirName, MagFactor, iii-1, ii-1, TiforJpg);   
            FluoroNewfilename = sprintf('%s/%s_%s_St_00%d_Apt_0%d_F_000.%s',...
                                  FluoroDirName, filterUsed, MagFactor, iii-1, ii-1, TiforJpg);    
                
        elseif (ii-1) < 10 && (iii-1) >= 10 && (iii-1) < 100
            BFfilename = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000.%s',...
                                  mainDirName, MagFactor, iii-1, ii-1, TiforJpg);            
            Fluorofilename = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000.%s',...
                                  mainDirName, filterUsed, MagFactor, iii-1, ii-1, TiforJpg);
            BFNewfilename = sprintf('%s/BF_%s_St_0%d_Apt_00%d_F_000.%s',...
                                  BfDirName, MagFactor, iii-1, ii-1, TiforJpg);   
            FluoroNewfilename = sprintf('%s/%s_%s_St_0%d_Apt_00%d_F_000.%s',...
                                  FluoroDirName, filterUsed, MagFactor, iii-1, ii-1, TiforJpg); 
                
        elseif (ii-1) >= 10 && (ii-1) < 100 && (iii-1) >= 10 && (iii-1) < 100
            BFfilename = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000.%s',...
                                  mainDirName, MagFactor, iii-1, ii-1, TiforJpg);            
            Fluorofilename = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000.%s',...
                                  mainDirName, filterUsed, MagFactor, iii-1, ii-1, TiforJpg);
            BFNewfilename = sprintf('%s/BF_%s_St_0%d_Apt_0%d_F_000.%s',...
                                  BfDirName, MagFactor, iii-1, ii-1, TiforJpg);    
            FluoroNewfilename = sprintf('%s/%s_%s_St_0%d_Apt_0%d_F_000.%s',...
                                  FluoroDirName, filterUsed, MagFactor, iii-1, ii-1, TiforJpg); 
        end
        % Checking to see if correct file type was chosen
        if any(size(dir([sprintf('%s', mainDirName) sprintf('/*.%s',  TiforJpg)]),1)) == 0
            close(h1)
            errordlg(sprintf('No images with %s file type were found in the folder selected. Check image type.', TiforJpg),...
                     sprintf('No %s Images', TiforJpg))
            return
        end
        BFimages{iii, ii} = imread(BFfilename);
        Fluoroimages{iii, ii} = imread(Fluorofilename);
        imwrite(BFimages{iii, ii}, BFNewfilename, TiforJpg)
        imwrite(Fluoroimages{iii, ii}, FluoroNewfilename, TiforJpg)
        
        waitbar(step1/steps1)
        step1 = step1 + 1;
    end
end
close(h1)
RemoveOrigFolder = questdlg({'Do you want to remove original folder with all images?',...
                             'All brightfield images are saved in folder BFUnedited and fluorescent images are saved in folder FluoroUnedited.'},...
                             'Remove Original Folder?',...
                             'Yes', 'No', 'Yes');
if strcmp(RemoveOrigFolder, 'Yes')
    rmdir(mainDirName, 's')
end
    
% Saving choices for ChipTypeQ, MagFactor, filterUsed, and TiforJpg
SV.Chip = ChipType; SV.Mag = MagFactor; SV.Filter = filterUsed; SV.ImType = TiforJpg;
save('ImDetails.mat','-struct','SV');