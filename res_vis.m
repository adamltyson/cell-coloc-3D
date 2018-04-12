function res_vis(cellArray, vars, filename)

empties = cellfun('isempty', cellArray);
cellArray(empties)={NaN};
array_vals=cell2mat(cellArray);

figure;
h = heatmap(array_vals);
h.XLabel='Cell';
h.YLabel='Object';
hmTitle=['Relative expression per cell: ' filename];
h.Title=hmTitle;
h.MissingDataLabel = 'No data';
h.Colormap = parula;
h.GridVisible = 'off';
h.FontName = 'Calibri Light';
h.FontSize = vars.fontSize;
end