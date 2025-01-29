function trigger = readTriggerMarkerTransformationMatrices(filepath)
    % readTriggerMarkerTransformationMatrices
    % Input params:
    % filepath: full path to triggermarker .xml file (from Localite
    % Session TMSTrigger-folder)

    % Output:
    %  trigger: Struct with fields:
    %   Matrix4D = 3x4 transformation matrix  for each trigger found from the data.
    %       Columns 1-3 contain the rotation matrix and column 4 the translational components
    %   recordingTime'= recordingTime for the trigger

    % readstruct seems to work with .xml files. Much better than readXML
    data = readstruct(filepath);
    datafields = fieldnames(data);
    assert(ismember('TriggerMarker',datafields),'No triggerMarkers found');
    assert(strcmp(data.coordinateSpaceAttribute,'MNI'),'Only MNI coordinate space supported');
    triggerMarkers = data.TriggerMarker;
    trigger = struct();
    for i = 1:length(triggerMarkers)
        recordingTime = triggerMarkers(i).recordingTimeAttribute;
        curMat = triggerMarkers(i).Matrix4D;
        matField = fieldnames(curMat);
        % Check field size!
        assert(all(size(matField)==[16,1]))
        outMat = zeros(1,12);
        % Read only first 12 values
        for j = 1:12
            outMat(j) = curMat.(matField{j});
        end
        transformationMatrix = reshape(outMat,[4,3])';
         if isempty(fieldnames(trigger))
            trigger(1).Matrix4D = transformationMatrix;
            trigger(1).recordingTime = recordingTime;
        else
            trigger(end+1).Matrix4D = transformationMatrix;
            trigger(end).recordingTime = recordingTime;
        end
    end
 
end

