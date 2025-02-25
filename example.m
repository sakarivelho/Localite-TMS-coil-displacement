clc
clear;
% Add functions and quaternion library to path
addpath(genpath("Functions\"));


%% First we need the specify the triggerMarker and instrumentMarker files we want to use!

%% Option 1: Speficy file locations
instrumentFilePath = 'ExampleData\Session_20240902115517938\InstrumentMarkers\InstrumentMarker20240902120310221.xml';
triggerFilePath = 'ExampleData\Session_20240902115517938\TMSTrigger\TriggerMarkers_Coil0_20240902120533402.xml';

%% Option 2: Choose files with uigetfile
[f,p] = uigetfile('*.xml','Choose InstrumentMarker file')
instrumentFilePath = fullfile(p,f);
[f,p] = uigetfile([p '\..\*.xml'],'Choose TriggerMarker file')
triggerFilePath = fullfile(p,f);

%% Option 3: use getLastMarkersFromSession-function
% Optionally, you can get instrumentFilePath and triggerFilePath with
% getLastMarkersFromSession function. It returns paths for last modified 
% InstrumentMarker and TriggerMarkers file of a given session, which are in
% most cases the files you want to use.
coilNumber = 1; %Specify the coil you want get the markers from (1 or 2)
sessionPath = uigetdir(pwd,"Choose session folder") %Path for the session data
[triggerFilePath,instrumentFilePath] = getLastMarkersFromSession(sessionPath,coilNumber)


%% Read the instrument marker transformation matrices
instrumentMarkers = readInstrumentMarkerTransformationMatrices(instrumentFilePath);
% Print available descriptions
fprintf("\n........................\n");
fprintf("Available instrument markers descriptions: \n\n");
arrayfun(@(x) fprintf('%s \n', x.Description),instrumentMarkers)
fprintf("\n........................\n");


%% Specify the description for the instrument marker of interest 
description = 'hotspot';

% Find instrument marker with the description (not case sensitive)
hotspotInd = find(strcmpi({instrumentMarkers.Description},description));
assert(length(hotspotInd) == 1,'Zero or more than one instrument markers found');

% 3x4 transformation matrix for the instrument marker of interest
instrumentMatrix = instrumentMarkers(hotspotInd).Matrix4D;

% Read all triggerMarker transformation matrices of the .xml file
triggers = readTriggerMarkerTransformationMatrices(triggerFilePath);

%% Get translation, yaw, pitch, and roll for each triggerMarkers
%  (relative to the instrument marker)
for i  = 1:length(triggers)
    % If the camera did not see the coil, the rotation matrix will equal
    % eye(3). Set values to NaN for these triggers.
    if isequal(triggers(i).Matrix4D(:,1:3), eye(3))
        [xRot,yRot,zRot,trans,xDiff,yDiff,zDiff] = deal(nan);
        fprintf("Trigger %i not detected by the Localite camera at the time of TMS stimulation\n",i);
    else
        [xRot,yRot,zRot,trans,xDiff,yDiff,zDiff]= calculateTransAndRot(instrumentMatrix, triggers(i).Matrix4D);
    end
    triggers(i).xAxisRotation = xRot;
    triggers(i).yAxisRotation = yRot;
    triggers(i).zAxisRotation = zRot;
    triggers(i).distance = trans;
    triggers(i).xDiff = xDiff;
    triggers(i).yDiff = yDiff;
    triggers(i).zDiff = zDiff;
end
%% Plot data

% Remove trigggermarkers where camera didn't see the coil
plotTriggers = triggers;
missingInd = find(arrayfun(@(x) isequal(x.Matrix4D(:,1:3),eye(3)), triggers));
plotTriggers(missingInd) = [];
figure('Color','white','Name','Coil displacement plot');
displacementAxes = subplot(3,1,1);
translationAxes = subplot(3,1,2);
angularAxes = subplot(3,1,3);

numTriggers = length(plotTriggers);

displacementAxes.Box = 'off';
translationAxes.Box = 'off';
angularAxes.Box = 'off';

% translational displacement
plot(displacementAxes, [plotTriggers.distance],...
    'DisplayName', 'Euclidean (3-dimensional)');
xlabel(displacementAxes, 'Trigger');
ylabel(displacementAxes, 'Distance [mm]');
legend(displacementAxes, 'Location', 'northwest');

% X-Y-Z translational displacement
plot(translationAxes, [plotTriggers.xDiff], 'r', 'DisplayName', 'X-axis');
hold(translationAxes, 'on');
plot(translationAxes, [plotTriggers.yDiff], 'g', 'DisplayName', 'Y-axis');
plot(translationAxes, [plotTriggers.zDiff], 'b', 'DisplayName', 'Z-axis');
xlabel(translationAxes, 'Trigger');
ylabel(translationAxes, 'Distance [mm]');
legend(translationAxes, 'Location', 'northwest');
hold(translationAxes, 'off');

% angular displacement
plot(angularAxes, [plotTriggers.xAxisRotation], 'r', 'DisplayName', 'X-axis');
hold(angularAxes, 'on');
plot(angularAxes, [plotTriggers.yAxisRotation], 'g', 'DisplayName', 'Y-axis');
plot(angularAxes, [plotTriggers.zAxisRotation], 'b', 'DisplayName', 'Z-axis');
xlabel(angularAxes, 'Trigger');
ylabel(angularAxes, 'Rotation [deg]');
legend(angularAxes, 'Location', 'northwest');
hold(angularAxes, 'off');

% set lims
xLimits = [1, numTriggers];
displacementAxes.XLim = xLimits;
translationAxes.XLim = xLimits;
angularAxes.XLim = xLimits;