function separatedIm=segment3D(imCell, vars)
%% Adam Tyson | 26/03/2018 | adam.tyson@icr.ac.uk
%takes a cell array of individual objects, segments and returns a cell
%array of separated cells

%% TO DO
% make ws better

for object=1:length(imCell)
    image=imCell{object};
    im.smoothed=zeros(size(image));
    
    for z=1:size(image,3)
        im.smoothed(:,:,z)=imgaussfilt(image(:,:,z),vars.smoothSigma);
    end
    
    levelOtsu = vars.threshScale*multithresh(im.smoothed);
    im.thresh=im.smoothed;
    im.thresh(im.thresh<levelOtsu)=0;
    im.thresh(im.thresh>0)=1;
    
    for z=1:size(image,3)
        im.closed(:,:,z)=~(bwareaopen(~im.thresh(:,:,z), vars.holeSize));
    end
    
    im.opened=bwareaopen(im.closed,vars.noiseRem); % remove small objs
    im.ws=ws3d(im.opened, vars); %watershed
    im.opened2=bwareaopen(im.ws,vars.noiseRem); % again, after ws
    separatedIm{object} = bwlabeln(im.opened2); %opening removes labels
    
    clear im
end

function separatedImage=ws3d(im3d, vars)
localMaxConn=26;
sze=size(im3d);% size of array for initalising
%% external markers
distTran=bwdist(im3d); % distance transform of positive data
wsExt=double(watershed(distTran)); % watershed to generate ext markers
extMark=zeros(sze); % initialise external markers
extMark(wsExt==0)=1; % markers between cells

%% internal markers
negDistTran=bwdist(~im3d);
intMark = imextendedmax(negDistTran,...
    vars.localMaxThresh,localMaxConn);

%% impose these minima onto the distance transform and run watershed
watershedBasins = imimposemin(distTran, intMark | extMark);
% watershed again based on basins
finalwatershed=double(watershed(watershedBasins));
separatedImage=im3d.*finalwatershed; % apply ws to thresholded image
end
end