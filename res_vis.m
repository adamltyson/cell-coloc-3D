function res_vis(cellArray, vars, filename)
%% Adam Tyson | 2018-03-26 | adam.tyson@icr.ac.uk
% displays a heat map of relative intensity of a secondary marker
empties = cellfun('isempty', cellArray);
cellArray(empties)={NaN};
array_vals=cell2mat(cellArray);

figure;
h = heatmap(array_vals);
h.XLabel='Cell';
h.YLabel='Object';
hmTitle=['Intensity per cell: ' filename];
h.Title=hmTitle;
h.MissingDataLabel = 'No data';
h.Colormap = parula;
h.GridVisible = 'off';
h.FontName = 'Calibri Light';
h.FontSize = vars.fontSize;
end