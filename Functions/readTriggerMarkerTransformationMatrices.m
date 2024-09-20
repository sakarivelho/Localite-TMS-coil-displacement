function trigger = readTriggerMarkerTransformationMatrices(filepath)
    % readTriggerMarkerTransformationMatrices
    % Input params:
    % filepath: full path to triggermarker .xml file (from Localite
    % Session TMSTrigger-folder)

    % Output:
    %  trigger: Struct with 3x4 transformation matrix ('Matrix4D') for each trigger found from the data.
    %   Columns 1-3 contain the rotation matrix and column 4 the translational components

    % Todo: add some metadata to the struct?
    

    % readstruct seems to work with .xml files. Much better than readXML
    data = readstruct(filepath);
    datafields = fieldnames(data);
    assert(ismember('TriggerMarker',datafields),'No triggerMarkers found');
    assert(strcmp(data.coordinateSpaceAttribute,'MNI'),'Only MNI coordinate space supported');
    triggerMarkers = data.TriggerMarker;
    trigger = struct();
    for i = 1:length(triggerMarkers)
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
        else
            trigger(end+1).Matrix4D = transformationMatrix;
        end
    end
 
end

