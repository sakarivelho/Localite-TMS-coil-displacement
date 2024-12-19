function [triggerPath,instrumentPath] = getLastMarkersFromSession(sessionPath,coilNumber)
%UNTITLED Summary of this function goes here
%   returns paths for last modified InstrumentMarker and TriggerMarkers file of a given
%   session

% Input:
% sessionPath = path to session
% coilNumber = coil number used for the session (1 or 2) -> defaults to 1

% Output:
% triggerPath = path to the last TriggerMarker in the session 
% instrumentPath = path to the last InstrumentMarker of the session


arguments
    sessionPath {mustBeFolder};
    coilNumber {mustBeInteger,mustBeInRange(coilNumber,1,2)} = 1; 
end

d = dir(sessionPath);
% Check that we have InstrumentMarkers and TMSTriggers folders
assert(sum(arrayfun(@(x) strcmp(x.name,'InstrumentMarkers'),d)) ==1,...
    'Zero of multiple InstrumentMarkers-folders found')
assert(sum(arrayfun(@(x) strcmp(x.name,'TMSTrigger'),d)) ==1,...
    'Zero of multiple TMSTrigger-folders found')

% Look for last TriggerMarker file
dTrigMark = dir(fullfile(sessionPath,'TMSTrigger'));
% Coil are zero-indexed in TriggerMarker files, subtract 1
coilSpecifier = sprintf("TriggerMarkers_Coil%i_",coilNumber-1);
% Remove all other markers
markInd = arrayfun(@(x) contains(x.name,coilSpecifier),dTrigMark);
dTrigMark(~markInd) = [];

dates = [];
for i = 1:numel(dTrigMark)
   fname = string(dTrigMark(i).name);
   % Remove coilspec and .xml suffix
   dateAsString = erase(fname,[coilSpecifier,".xml"]);
   date = datetime(dateAsString,"InputFormat",'yyyyMMddHHmmssSSS');
   dates = [dates,date];
end
% Get index for latest datetime.
[~,maxInd] = max(dates);
triggerPath = fullfile(sessionPath,"TMSTrigger",dTrigMark(maxInd).name);


% Look for last InstrumentMarker file
dInstMark = dir(fullfile(sessionPath,'InstrumentMarkers'));
instSpecifier = "InstrumentMarker";
% Remove all other markers
markInd = arrayfun(@(x) contains(x.name,instSpecifier),dInstMark);
dInstMark(~markInd) = [];

dates = [];
for i = 1:numel(dInstMark)
   fname = string(dInstMark(i).name);
   % Remove coilspec and .xml suffix
   dateAsString = erase(fname,[instSpecifier,".xml"]);
   date = datetime(dateAsString,"InputFormat",'yyyyMMddHHmmssSSS');
   dates = [dates,date];
end
% Get index for latest datetime.
[~,maxInd] = max(dates);
instrumentPath = fullfile(sessionPath,"InstrumentMarkers",dInstMark(maxInd).name);


end

