function unixMove(filepathsFilename)

cdDir                   = fileparts(filepathsFilename);
unix(['cd ' cdDir]);


filepaths               = textread(filepathsFilename, '%s');

for i = 1:length(filepaths)
end


% [status, output]    = unix(['ls ' filePatternFrom '*']);
% tokens              = strsplit(output);
% 
% fromFilenames      = tokens(1:(end-1));
% toFilenames         = strrep(fromFilenames, filePatternFrom, filePatternTo);
% 
% disp('Performing actions: ');
% for i = 1:length(fromFilenames)
%     disp(sprintf('From   %s   to   %s', fromFilenames{i}, toFilenames{i}));
% end
% yesNo = input('Kosher? (y or n)', 's');
% 
% if lower(yesNo(1)) ~= 'y'
%     return;
% end
% 
% for i = 1:length(fromFilenames)
%     
%     unix(['mv ' fromFilenames{i} ' ' toFilenames{i}]);
% end