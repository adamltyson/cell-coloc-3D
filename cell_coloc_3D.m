% function cell_coloc_3D
%% Adam Tyson | 26/03/2018 | adam.tyson@icr.ac.uk
% loads C0 image (e.g. DAPI), displays, and allows manual seg of each object
% each cell is then segmented, and colocalisation with C2 marker assessed

%% TO DO
% add option to only analyse certain images
% option to remove cells at edge
% save volume of object (convex bounding)
% save volumes of cells
% add readme
%% IMPROVE SEGMENTATION
vars=getVars;
tic
cd(vars.directory) 

files=dir('*C0.tif'); % all tif's in this folder
numImages=length(files);
imCount=0;

% manually segment objects (e.g spheroids)
for file=files' % go through all images
    imCount=imCount+1; 
    C0file{imCount}=file.name;
    
    % Load images and separate objects
    tmpIm=loadFile(C0file{imCount});
    rawC0{imCount}=tmpIm(1:2:end, 1:2:end,:);
    [bin_C0{imCount}, objNum{imCount}] = manSeg(rawC0{imCount});
end
objInf=cell(2, imCount);
objInf{2,1}= "Number of cells per object";
objInf{3,1}= "Total volume of object (nuclei only)";

% Load C2 and analyse each object
progressbar('Analysing images') % Init prog bar

count=0;
for im=1:imCount 
    count=count+1; 
    C2file{im} = replace(C0file{im},'C0','C2');
    tmpIm=loadFile(C2file{im});
    rawC2=tmpIm(1:2:end, 1:2:end,:);
    clear tmpIm 

    [rawC0_ind, rawC2_ind] = maskObj(rawC0{im}, rawC2,...
                                bin_C0{im}, objNum{im}); % mask images
                            
    segC0=segment3D(rawC0_ind, vars); % segment
    
    %% summary results
    
    % get number of cells in each object, per image
    [~, nametmp,~] = fileparts(C0file{im});
    objInf{1, im+1}= strcat("Image_", nametmp);
    objInf{2, im+1} = cellfun(@(x) max(x(:)), segC0); % no cells per obj
    objInf{3, im+1} = cellfun(@(x) sum(sum(sum(x>0))), segC0); % vol obj

    %%
    
    C2means=indv_cell_coloc(segC0, rawC2_ind); % mean C2 fluro per cell, 
                                                %per object

    if strcmp(vars.plot, 'Yes')  
        res_vis(C2means, vars, C0file{im});
    end

    if strcmp(vars.saveSegmentation, 'Yes')  
        saveSegmentation(objNum, rawC0_ind, rawC2_ind, segC0,...
                                                    im, C0file, C2file) 
    end
    
    if strcmp(vars.savecsv, 'Yes')  
        save_raw_res(C0file, C2means, im)
    end
    
    % progress bar
    frac1 =count/numImages;
    progressbar(frac1)
end

if strcmp(vars.savecsv, 'Yes')  
    save_summary_res(objInf)
end
    
toc
% end

%% Internal functions

function save_summary_res(objectInfo)
    csvname="summary_results.csv";
    results_Table=cell2table(objectInfo);
    writetable(results_Table, csvname, 'WriteVariableNames', 0)
end

function save_raw_res(C0file, results, im)
    [~, nametmp,~] = fileparts(C0file{im});
    csvname = ['obj_cell_means_' nametmp '.csv'];
    
    % add labels 
    sze=size(results);
    blankY=cell(sze(1),1);
    blankX=cell(1, sze(2)+1);
    results=[blankY results];
    results=[blankX; results];

    for cellnum=1:sze(2)
        results{1, cellnum+1}=strcat("Cell_", num2str(cellnum));
    end
    
    for obj=1:sze(1)
        results{obj+1,1}=strcat("Object_", num2str(obj));
    end
        
    results_Table=cell2table(results);
    writetable(results_Table, csvname, 'WriteVariableNames', 0)
end

function saveSegmentation(objNum, rawC0_ind, rawC2_ind, segC0,...
                                                     im, C0file, C2file)

    for obj=1:objNum{im}

        C0raw_tmp=rawC0_ind{obj};
        C2raw_tmp=rawC2_ind{obj};
        C0seg_tmp=segC0{obj};

        outC0_raw=['raw_obj_' num2str(obj) '_' C0file{im}];
        outC2_raw=['raw_obj_' num2str(obj) '_' C2file{im}];
        outC0_seg=['seg_obj_' num2str(obj) '_' C0file{im}];

        for frame=1:size(C0raw_tmp,3)
            imwrite(C0raw_tmp(:,:,frame),outC0_raw,...
                'tif','WriteMode', 'append', 'compression', 'none');
            imwrite(C2raw_tmp(:,:,frame),outC2_raw,...
                'tif', 'WriteMode', 'append', 'compression', 'none');
            imwrite(C0seg_tmp(:,:,frame),outC0_seg,...
                'tif', 'WriteMode', 'append', 'compression', 'none');
        end
    end
end

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
    
        vars.savecsv = questdlg('Save results as .csv?', ...
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


