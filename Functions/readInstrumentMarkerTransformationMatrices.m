function instrumentMarkers = readInstrumentMarkerTransformationMatrices(filepath)
    % readInstrumentMarkerTransformationMatrix
    % Reads description and 4d transformation matrix for each
    % instrumentMarker in the .xml file. Only supports MNI-coordinate
    % space.

    % Input params:
    % filepath: full path to instrument marker .xml file
    
    %  Output:
    %  instrumentMarkers struct with fields:
    %  - Matrix4D: 3x4 transformation matrix. Columns 1-3 contain
    %    the rotation matrix and column 4 the translational components
    %  - Description: marker description in localite (char)

    data = readstruct(filepath);
    datafields = fieldnames(data);
    % Check validity
    assert(ismember('InstrumentMarker',datafields),'No InstrumentMarkers found');
    assert(strcmp(data.coordinateSpaceAttribute,'MNI'),'Only MNI coordinate space supported');
    readMarkers = data.InstrumentMarker;
    instrumentMarkers = struct();

    % Read data for each instrumentMarker
    for i = 1:length(readMarkers)
        description = readMarkers(i).Marker.descriptionAttribute;
        if isempty(description) | strcmp(description,"")
            description = 'No description';
        end
        curMat = readMarkers(i).Marker.Matrix4D;
        matField = fieldnames(curMat);
        % Check field size!
        assert(all(size(matField)==[16,1]),'Error reading instrumentMarker file')
        outMat = zeros(1,12);
        % Read only first 12 values
        for j = 1:12
            outMat(j) = curMat.(matField{j});
        end
        transformationMatrix = reshape(outMat,[4,3])';
        if isempty(fieldnames(instrumentMarkers))
            instrumentMarkers(1).Description = char(description);
            instrumentMarkers(1).Matrix4D = transformationMatrix;
        else
            instrumentMarkers(end+1).Description = char(description);
            instrumentMarkers(end).Matrix4D = transformationMatrix;
        end
    end

end

