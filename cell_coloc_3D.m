function cell_coloc_3D
%% Adam Tyson | 2018-03-26 | adam.tyson@icr.ac.uk
% loads C0 image (e.g. DAPI), displays, and allows manual seg of each object
% each cell is then segmented, and intensity of a secondary marker C2
% (within C0) is measured.

%% TO DO
% add option to only analyse certain images
% removal of any big (double) cells
% update README for new outputs
% remove multiple (slow) calls to bwconvhull
% only load subsampled data, rather than loading all first, to not use
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
    rawC0{imCount}=imresize(tmpIm, vars.zScale);
    [bin_C0{imCount}, objNum{imCount}] = manSeg(rawC0{imCount});
end

objInf=cell(2, imCount);
objInf{2,1}= "Number of cells per object";
objInf{3,1}= "Total volume of object (nuclei only)";
objInf{4,1}= "Total volume of object (convex bounding)";
objInf{5,1}= "Object density";
objInf{6,1}= "Mean marker intensity per object";
objInf{7,1}= "Mean cell size per object";

% Load C2 and analyse each object
f = waitbar(0,'1','Name','Analysing images...');
count=0;

for im=1:imCount
    count=count+1;
    waitbar((count-1)/numImages,f,strcat("Analysing Image: ", num2str(count)))

    C2file{im} = replace(C0file{im},'C0','C2');
    tmpIm=loadFile(C2file{im});
    rawC2=imresize(tmpIm, vars.zScale);
    clear tmpIm
    
    [rawC0_ind, rawC2_ind] = maskObj(rawC0{im}, rawC2,...
        bin_C0{im}, objNum{im}); % mask images
    
    segC0=segment3D(rawC0_ind, vars); % segment
    
    % mean C2 fluro per cell, per object
    [C0sizes, C2means, objBoundVol]=indv_cell_coloc(segC0, rawC2_ind);
    
    %% summary results
    [~, nametmp,~] = fileparts(C0file{im});
    objInf{1, im+1}= strcat("Image_", nametmp);
    objInf{2, im+1} = cellfun(@(x) max(x(:)), segC0); % no cells per obj
    objInf{3, im+1} = cellfun(@(x) nnz(x>0), segC0); % vol obj (cells)
    objInf{4, im+1} = objBoundVol; % vol obj (convex) 
    objInf{5, im+1} = objInf{3, im+1}./objInf{4, im+1}; % density
    
    % get mean vals
    objC2Means=[];
    objSizeMeans=[];   
    
    for obj=1:objNum{im}
        objC2Means=[objC2Means mean(cell2mat(C0sizes(obj,:)))];     
        objSizeMeans=[objSizeMeans mean(cell2mat(C2means(obj,:)))];
    end
    
    objInf{6, im+1} = objC2Means;
    objInf{7, im+1} = objSizeMeans; 
    
    if strcmp(vars.plot, 'Yes')
        res_vis(C2means, vars, C0file{im});
    end
    
    if strcmp(vars.saveSegmentation, 'Yes')
        saveSegmentation(objNum, rawC0_ind, rawC2_ind, segC0,...
            im, C0file, C2file)
    end
    
    if strcmp(vars.savecsv, 'Yes')
        save_raw_res(C0file, C0sizes, C2means, im)
    end
    
end

if strcmp(vars.savecsv, 'Yes')
    save_summary_res(objInf)
end
delete(f)
toc
end

%% Internal functions

function save_summary_res(objectInfo)
csvname="summary_results.csv";
results_Table=cell2table(objectInfo);
writetable(results_Table, csvname, 'WriteVariableNames', 0)
end

function save_raw_res(C0file, C0sizes, C2means, im)
% tidy up

%% mean marker intensities
[~, nametmp,~] = fileparts(C0file{im});
csvname = ['marker_mean_intensity_' nametmp '.csv'];

% add labels
sze=size(C2means);
blankY=cell(sze(1),1);
blankX=cell(1, sze(2)+1);
C2means=[blankY C2means];
C2means=[blankX; C2means];

for cellnum=1:sze(2)
    C2means{1, cellnum+1}=strcat("Cell_", num2str(cellnum));
end

for obj=1:sze(1)
    C2means{obj+1,1}=strcat("Object_", num2str(obj));
end

results_Table=cell2table(C2means);
writetable(results_Table, csvname, 'WriteVariableNames', 0)

%% mean cell sizes
csvname2 = ['cell_sizes_' nametmp '.csv'];

% add labels
sze=size(C0sizes);
blankY=cell(sze(1),1);
blankX=cell(1, sze(2)+1);
C0sizes=[blankY C0sizes];
C0sizes=[blankX; C0sizes];

for cellnum=1:sze(2)
    C0sizes{1, cellnum+1}=strcat("Cell_", num2str(cellnum));
end

for obj=1:sze(1)
    C0sizes{obj+1,1}=strcat("Object_", num2str(obj));
end

results_Table2=cell2table(C0sizes);
writetable(results_Table2, csvname2, 'WriteVariableNames', 0)

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
    'Yes', 'No', 'No');

vars.saveSegmentation= questdlg('Save segmentation as.tif?', ...
    'Saving segmentation', ...
    'Yes', 'No', 'No');

vars.edgeRem= questdlg('Remove edge objects?', ...
    'Clear edges', ...
    'Yes', 'No', 'Yes');

prompt = {'Segmentation threshold (a.u.):',...
    'Smoothing width (pixels):',...
    'Maximum hole size to fill (pixels):',...
    'Largest false cell to remove (pixels):',...
    'Watershed threshold (a.u.):',...
    'Voxel size - XY (um):',...
    'Voxel size - Z (um):'};

dlg_title = 'Analysis variables';
num_lines = 1;
defaultans = {'1.4', '2', '50', '30', '3.5', '0.065', '0.34'};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
vars.threshScale=str2double(answer{1});%change sensitivity of threshold
vars.smoothSigma=str2double(answer{2});% smoothing kernel
vars.holeSize=str2double(answer{3});% largest hole to fill
vars.noiseRem=str2double(answer{4}); % smallest obj to remove
vars.localMaxThresh=str2double(answer{5});% ws int marker threshold
vars.xySamp=str2double(answer{6});% vox size
vars.zSamp=str2double(answer{7});% vox size

vars.zScale=vars.xySamp/vars.zSamp;

vars.stamp=num2str(fix(clock)); % date and time
vars.stamp(vars.stamp==' ') = '';%remove spaces

vars.fontSize=14;
end
