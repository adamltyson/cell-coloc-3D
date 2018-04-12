function C2_intMean=indv_cell_coloc(segCell, C2_indiv)
%% Adam Tyson | 27/03/2018 | adam.tyson@icr.ac.uk
% function to take segmented images of cells, mask a second channel, and
% return mean fluroescence.

%% TO DO
% remove loops
% check picking cells individually

for obj=1:length(segCell)
    objSeg=segCell{obj};
    C2im=C2_indiv{obj};
     for cell=2:max(objSeg(:)) % first "cell" is oversegmented noise

        tmpIm=objSeg;
        tmpIm(tmpIm~=cell)=0; % not sure why have to use -ve
        tmpIm(tmpIm>0)=1;
        
         mask=zeros(size(tmpIm));
        for z=1:size(tmpIm,3)
          mask(:,:,z) = bwconvhull(tmpIm(:,:,z));
        end
        
        maskedC2=mask.*double(C2im);
        C2_intMean{obj, cell-1}=mean(nonzeros(maskedC2(:))); % non-zero mean
    end
end

end