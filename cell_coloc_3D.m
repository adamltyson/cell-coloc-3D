%% Adam Tyson | 26/03/2018 | adam.tyson@icr.ac.uk
% loads C0 image (e.g. DAPI), displays, and allows manual seg of each object
% each cell is then segmented, and colocalisation with C2 marker assessed

%% TO DO
% add looping through images - all at beginning
% add option to only analyse certain images
% manually segment all at beginning, then do other loading and processing
% add segmentation export
% add results export
%% IMPROVE SEGMENTATION
% assess colocalisation - all, binary and intensity based

clear
close

vars=getVars;
tic
cd(vars.directory) 


files=dir('*C0.tif'); % all tif's in this folder
numImages=length(files);
imCount=0;

% vars.C0file='Im1_C0.tif';
for file=files' % go through all images
    vars.C0file=file.name;
     imCount=imCount+1; 
%% Load images and separate objects
tmpIm=loadFile(vars.C0file);
rawIm.C0=tmpIm(1:2:end, 1:2:end,:);
[analyseIm.binary_C0, objNum] = manSeg(rawIm.C0);

vars.C2file = replace(vars.C0file,'C0','C2');
tmpIm=loadFile(vars.C2file);
rawIm.C2=tmpIm(1:2:end, 1:2:end,:);
clear tmpIm
%% Analyse


[rawIm.C0_indiv, rawIm.C2_indiv] = maskObj(rawIm.C0, rawIm.C2,...
                            analyseIm.binary_C0, objNum); % mask images

analyseIm.segmentedC0=segment3D(rawIm.C0_indiv, vars); % segment

C2_intMean=indv_cell_coloc(analyseIm.segmentedC0,...
    rawIm.C2_indiv); % mean C2 fluro per cell, per object


if vars.plot
    res_vis(C2_intMean, vars)
end

% for export/save
C2means{imCount}=C2_intMean;
segmentedImages{imCount}=analyseIm.segmentedC0;
end
toc
%% Internal functions
function image=loadFile(file)
    disp(['Loading: ' file])
    info = imfinfo(file);
    numZ = numel(info);
    
    image=uint16(zeros(info(1).Height, info(1).Width, numZ)); %initalise

    for k = 1:numZ
        image(:,:,k) = imread(file, k, 'Info', info); % load frame by frame  
    end
   
end 

function [binaryImages, objNum]=manSeg(image)

    scrsz = get(0,'ScreenSize');
    imSize=size(image);
    dispScale=(scrsz(4)/imSize(1))*0.8;
    screenSize=[10 10 dispScale*imSize(2) dispScale*imSize(1)];
    % Plot intensity projection.
    image_max = max(image, [], 3);
    figure('position', screenSize,'Name','Manually segment objects')
    imagesc(image_max)
    colormap gray

    continueSeg=1;
    objNum=1;
    while continueSeg==1

    hFH = imfreehand(); % manually segment
        tmpBin = hFH.createMask(); % make binary image
        repSeg = questdlg('Redo last segmentation?',...
            'Error catch','Yes','No','No'); % yes, no and default 
        if strcmp(repSeg, 'No')  
            binaryImages(:,:,objNum) = tmpBin;
            finSeg = questdlg('All objects segmented?',...
                'Error catch','Yes','No','No');

            if strcmp(finSeg, 'No') 
                objNum = objNum+1;
            elseif strcmp(finSeg, 'Yes')
                continueSeg = 0;
                close all
            end
        end
    end
end

function imageCrop=deleteZeros(image)
    image_max = max(image, [], 3);
        for z=1:size(image,3)
            imagetmp=image(:,:,z);
            imagetmp( all(~image_max,2), :) = []; % remove zero rows
            imagetmp( :, all(~image_max,1)) = []; % remove zero columns
            imageCrop(:,:,z)=imagetmp;
        end
end

function [C0_indiv, C2_indiv] = maskObj(C0_image,...
                                C2_image, binaryImages, objNum)

    C0_indiv = cell(objNum, 1) ;
    C2_indiv = cell(objNum, 1) ;
    
    for object=1:objNum
        
        for z=1:size(C0_image,3)
            C0_indv_tmp(:,:,z)=C0_image(:,:,z).*...
                uint16(binaryImages(:,:,object));
            C2_indv_tmp(:,:,z)=C2_image(:,:,z).*...
                uint16(binaryImages(:,:,object));
        end
        
        imageCrop_C0=deleteZeros(C0_indv_tmp);
        C0_indiv{object}=imageCrop_C0;

        imageCrop_C2=deleteZeros(C2_indv_tmp);
        C2_indiv{object}=imageCrop_C2;
    end
end

function vars=getVars
    vars.directory = uigetdir('', 'Choose directory containing images');
    
        vars.saveTrace = questdlg('Save results as .csv?', ...
	'Exporting', ...
	'Yes', 'No', 'Yes');

        vars.plot = questdlg('Plot individual heat maps? ', ...
	'Plotting', ...
	'Yes', 'No', 'Yes');

    vars.saveSegmentation= questdlg('Save segmentation as.tif?', ...
	'Saving segmentation', ...
	'Yes', 'No', 'No');

   prompt = {'Segmentation threshold (a.u.):',...
       'Smoothing width (pixels):',...
       'Maximum hole size to fill (pixels):',...
       'Largest false cell to remove (pixels):',...
       'Watershed threshold (a.u.):'};
   
    dlg_title = 'Analysis variables';
    num_lines = 1;
    defaultans = {'1.2', '3', '1000', '1000', '4'};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    vars.threshScale=str2double(answer{1});%change sensitivity of threshold
    vars.smoothSigma=str2double(answer{2});% smoothing kernel
    vars.holeSize=str2double(answer{3});% largest hole to fill
    vars.noiseRemoval=str2double(answer{4}); % smallest obj to remove 
    vars.localMaxThresh=str2double(answer{5});% ws int marker threshold

    vars.stamp=num2str(fix(clock)); % date and time 
    vars.stamp(vars.stamp==' ') = '';%remove spaces
    
    vars.fontSize=14;
end