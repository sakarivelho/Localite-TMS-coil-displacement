classdef CoilDisplacementUI < handle
    properties
        fig
        instrumentFileInput
        instrumentFileLabel
        triggerFileInput
        triggerFileLabel
        descriptionDropdown
        plotButton
        instrumentFilePath
        triggerFilePath
        description
        % Plot axes
        displacementAxes
        translationAxes
        angularAxes
        visualAxes

        instrumentMarkers
        triggerMarkers
    end

    methods
        function obj = CoilDisplacementUI()
            % Make sure we have 'Functions'-folder and add it to path
            functionDir = fullfile(fileparts(mfilename('fullpath')),'\..\Functions');
            if exist(functionDir,'dir')
                addpath(genpath(functionDir));
            else
                error('Required function directory "Functions" not found.');
            end

            % Construct fig
            obj.fig = uifigure('Name', 'Localite Coil Displacement', 'Position', [100 100 800 600], 'Color', 'white');

            % grid layout with 9 rows and 2 columns
            gl = uigridlayout(obj.fig, [9, 2],'BackgroundColor','white');
            gl.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', '1x'};
            gl.ColumnWidth = {'1x', '1x'};
            gl.Padding = [10 10 10 10];
            gl.RowSpacing = 5;
            gl.ColumnSpacing = 10;

            
            lbl1 = uilabel(gl, 'Text', 'Instrument Marker File:');
            lbl1.Layout.Row = 1;
            lbl1.Layout.Column = 1;

            obj.instrumentFileInput = uibutton(gl, 'Text', 'Select File', 'BackgroundColor','White',...
                'ButtonPushedFcn', @(src, event) obj.selectInstrumentFile());
            obj.instrumentFileInput.Layout.Row = 1;
            obj.instrumentFileInput.Layout.Column = 2;

           
            obj.instrumentFileLabel = uilabel(gl, 'Text', 'No file selected');
            obj.instrumentFileLabel.Layout.Row = 2;
            obj.instrumentFileLabel.Layout.Column = [1 2]; 
    
            lbl2 = uilabel(gl, 'Text', 'Marker Description:');
            lbl2.Layout.Row = 3;
            lbl2.Layout.Column = 1;

            obj.descriptionDropdown = uidropdown(gl, ...
                'Items', {'Select Instrument File First'}, 'Enable', 'off',...
                'ValueChangedFcn', @(src,event) obj.dropDownValueChanged());
            obj.descriptionDropdown.Layout.Row = 3;
            obj.descriptionDropdown.Layout.Column = 2;

            % empty row for spacing
            spacer1 = uilabel(gl, 'Text', '');
            spacer1.Layout.Row = 4;
            spacer1.Layout.Column = [1 2];

          
            lbl3 = uilabel(gl, 'Text', 'Trigger Marker File:');
            lbl3.Layout.Row = 5;
            lbl3.Layout.Column = 1;


            obj.triggerFileInput = uibutton(gl, 'Text', 'Select File', 'BackgroundColor','White',...
                'ButtonPushedFcn', @(src, event) obj.selectTriggerFile());
            obj.triggerFileInput.Layout.Row = 5;
            obj.triggerFileInput.Layout.Column = 2;

       
            obj.triggerFileLabel = uilabel(gl, 'Text', 'No file selected');
            obj.triggerFileLabel.Layout.Row = 6;
            obj.triggerFileLabel.Layout.Column = [1 2];

            
            spacer2 = uilabel(gl, 'Text', '');
            spacer2.Layout.Row = 7;
            spacer2.Layout.Column = [1 2];
            exportDataBtn = uibutton(gl,'Text','Export data','BackgroundColor','White',...
                'ButtonPushedFcn',@(src,event) obj.exportDataButtonPushed());
            exportDataBtn.Layout.Row = 8;
            exportDataBtn.Layout.Column = 1;


            axesLayout = uigridlayout(gl, [3, 2],'BackgroundColor','white');
            axesLayout.Layout.Row = 9;
            axesLayout.Layout.Column = [1 2]; 
            axesLayout.RowHeight = {'1x', '1x', '1x'};
            axesLayout.ColumnWidth = {'1x','1x'};
            axesLayout.ColumnSpacing = 10;
            axesLayout.Padding = [0 0 0 0];

           
            obj.displacementAxes = uiaxes(axesLayout);
            title(obj.displacementAxes, 'Translational Displacement - 3D (euclidean)');
            obj.displacementAxes.Layout.Row = 1;
            obj.displacementAxes.Layout.Column = 1;

            
            obj.translationAxes = uiaxes(axesLayout);
            title(obj.translationAxes, 'Translation X/Y/Z');
            obj.translationAxes.Layout.Row = 2;
            obj.translationAxes.Layout.Column = 1;

           
            obj.angularAxes = uiaxes(axesLayout);
            title(obj.angularAxes, 'Angular Displacement');
            obj.angularAxes.Layout.Row = 3;
            obj.angularAxes.Layout.Column = 1;

            obj.visualAxes = uiaxes(axesLayout);
            title(obj.visualAxes, '3D visualisation');
            obj.visualAxes.Layout.Row = [1 3];
            obj.visualAxes.Layout.Column = 2;

        end

  

        function selectInstrumentFile(obj)
            % Check if file is already selected and choose folder
            % accordingly
            if isempty(obj.instrumentFilePath) & isempty(obj.triggerFilePath)
                [file, path] = uigetfile('*.xml', 'Choose TriggerMarker file');
            elseif ~isempty(obj.instrumentFilePath)
                prevPath = fileparts(obj.instrumentFilePath);
                [file, path] = uigetfile([prevPath ,'\..\*.xml'], 'Choose TriggerMarker file');
            else
                prevPath = fileparts(obj.triggerFilePath);
                [file, path] = uigetfile([prevPath ,'\..\*.xml'], 'Choose TriggerMarker file');
            end
            % Restore fig to top
            figure(obj.fig);

            if isequal(file, 0)
                return;
            end

            filepath = fullfile(path,file);
            try
                obj.instrumentMarkers = readInstrumentMarkerTransformationMatrices(filepath);
            catch ME
                uialert(obj.fig,ME.message,'File error')
                return
            end
            obj.instrumentFilePath = filepath;
            obj.instrumentFileLabel.Text = ['Selected: ', file];

            % add data to dropdown
            descriptions = {obj.instrumentMarkers.Description};
            obj.descriptionDropdown.Items = descriptions;
            obj.descriptionDropdown.Enable = 'on';

            if ~isempty(obj.triggerFilePath) && ~isempty(obj.instrumentFilePath)
                obj.plotData();
            end
        end

        function dropDownValueChanged(obj)
            if ~isempty(obj.triggerFilePath) && ~isempty(obj.instrumentFilePath)
                obj.plotData();
            end
        end

        function selectTriggerFile(obj)
            % Check if file is already selected and choose folder
            % accordingly
            if isempty(obj.instrumentFilePath) & isempty(obj.triggerFilePath)
                [file, path] = uigetfile('*.xml', 'Choose TriggerMarker file');
            elseif ~isempty(obj.instrumentFilePath)
                prevPath = fileparts(obj.instrumentFilePath);
                [file, path] = uigetfile([prevPath ,'\..\*.xml'], 'Choose TriggerMarker file');
            else
                prevPath = fileparts(obj.triggerFilePath);
                [file, path] = uigetfile([prevPath ,'\..\*.xml'], 'Choose TriggerMarker file');
            end
            % Restore fig to top
            figure(obj.fig);
            if isequal(file, 0)
                return;
            end

            filepath = fullfile(path, file);
            % read all triggerMarker transformation matrices from the XML file
            try
                obj.triggerMarkers = readTriggerMarkerTransformationMatrices(filepath);
            catch ME
                 uialert(obj.fig, ME.message, 'File error');
                 return
            end
            obj.triggerFilePath = filepath;
            obj.triggerFileLabel.Text = ['Selected: ', file];
            if ~isempty(obj.triggerFilePath) && ~isempty(obj.instrumentFilePath)
                obj.plotData();
            end
        end

        function plotData(obj)
            instrumentFilePath = obj.instrumentFilePath;
            triggerFilePath = obj.triggerFilePath;
            description = obj.descriptionDropdown.Value;

            if isempty(instrumentFilePath) || isempty(triggerFilePath) || strcmp(description, 'Select Instrument File First')
                uialert(obj.fig, 'Select both files and provide a valid marker description.', 'Input Error');
                return;
            end

            % find instrument marker with the selected description
            hotspotInd = find(arrayfun(@(x) strcmpi(x.Description, description), obj.instrumentMarkers));
            if length(hotspotInd) ~= 1
                uialert(obj.fig, 'Zero or multiple instrument markers with the selected description found', 'Input error');
                return;
            end

            % 3x4 transformation matrix for the instrument marker of interest
            try
                 instrumentMatrix = obj.instrumentMarkers(hotspotInd).Matrix4D;
            catch ME
                 uialert(obj.fig, ME.message, 'File error');
                 return
            end

            triggers = obj.triggerMarkers;
            % get translation, yaw, pitch, and roll for each triggerMarker
            for i = 1:length(triggers)
                % If camera didn't see the coil, rotation matrix will equal eye(3)
                if isequal(triggers(i).Matrix4D(:, 1:3), eye(3))
                    [xRot, yRot, zRot, trans, xDiff, yDiff, zDiff] = deal(nan);
                    fprintf("Trigger %i not seen by Localite camera\n", i);
                else
                    [xRot, yRot, zRot, trans, xDiff, yDiff, zDiff] = calculateTransAndRot(instrumentMatrix, triggers(i).Matrix4D);
                end
                triggers(i).xAxisRotation = xRot;
                triggers(i).yAxisRotation = yRot;
                triggers(i).zAxisRotation = zRot;
                triggers(i).distance = trans;
                triggers(i).xDiff = xDiff;
                triggers(i).yDiff = yDiff;
                triggers(i).zDiff = zDiff;
            end
            obj.triggerMarkers = triggers;

            obj.plotDisplacementResults(instrumentMatrix);
        end
        
        function exportDataButtonPushed(obj)
            if ~isfield(obj.triggerMarkers,'zDiff')
                uialert(obj.fig,'No data available for export','Export error')
                return
            end
            toExport = rmfield(obj.triggerMarkers,'Matrix4D');

            outTable = struct2table(toExport);
            % Add trigger indices to table;
            trigInd = 1:max(size(toExport));
            outTable = addvars(outTable,trigInd','Before',1);
            outTable.Properties.VariableNames(1) = {'Index'};

            [~,instName] = fileparts(obj.instrumentFilePath);
            [~,trigName] = fileparts(obj.triggerFilePath);
            description = obj.descriptionDropdown.Value;
            
            fileName = sprintf("Coil_displacement_%s_DESCRIPTION_%s_%s.xlsx",instName,description,trigName);
            [f,p] = uiputfile('*.xlsx','Save as',fileName);
            if isequal(f, 0)
                return;
            end

            outfilepath = fullfile(p,f);
            if ~endsWith(outfilepath,'.xlsx')
              uialert(obj.fig,"Only .xlsx format supported for export","Export error");
              return
            end
            writetable(outTable,outfilepath)
        end

        function plotDisplacementResults(obj,instrumentMatrix)
             f = uiprogressdlg(obj.fig,'Title','Pelase wait','Message','Plotting data..');
            % Remove trigggermarkers where camera didn't see the coil
            triggerMarks = obj.triggerMarkers;
            missingInd = find(arrayfun(@(x) isequal(x.Matrix4D(:,1:3),eye(3)), obj.triggerMarkers));
            triggerMarks(missingInd) = [];
            
            numTriggers = length(triggerMarks);
            xLimits = [1, numTriggers];
            obj.displacementAxes.XLim = xLimits;
            obj.translationAxes.XLim = xLimits;
            obj.angularAxes.XLim = xLimits;


            obj.displacementAxes.Box = 'off';
            obj.translationAxes.Box = 'off';
            obj.angularAxes.Box = 'off';

            % translational displacement
            plot(obj.displacementAxes, [triggerMarks.distance],...
                'DisplayName', 'Euclidean (3-dimensional)');
            xlabel(obj.displacementAxes, 'Trigger');
            ylabel(obj.displacementAxes, 'Distance [mm]');
            % legend(obj.displacementAxes, 'Location', 'northwest');

            % X-Y-Z translational displacement
            plot(obj.translationAxes, [triggerMarks.xDiff], 'r', 'DisplayName', 'X-axis');
            hold(obj.translationAxes, 'on');
            plot(obj.translationAxes, [triggerMarks.yDiff], 'g', 'DisplayName', 'Y-axis');
            plot(obj.translationAxes, [triggerMarks.zDiff], 'b', 'DisplayName', 'Z-axis');
            xlabel(obj.translationAxes, 'Trigger');
            ylabel(obj.translationAxes, 'Distance [mm]');
            % legend(obj.translationAxes, 'Location', 'northwest');
            hold(obj.translationAxes, 'off');

            % angular displacement
            plot(obj.angularAxes, [triggerMarks.xAxisRotation], 'r', 'DisplayName', 'X-axis');
            hold(obj.angularAxes, 'on');
            plot(obj.angularAxes, [triggerMarks.yAxisRotation], 'g', 'DisplayName', 'Y-axis');
            plot(obj.angularAxes, [triggerMarks.zAxisRotation], 'b', 'DisplayName', 'Z-axis');
            xlabel(obj.angularAxes, 'Trigger');
            ylabel(obj.angularAxes, 'Rotation [deg]');
            % legend(obj.angularAxes, 'Location', 'northwest');
            hold(obj.angularAxes, 'off');
     
            f.Value = .33;
            % 3D plot
            cla(obj.visualAxes);
            
            hold(obj.visualAxes, 'on');

            % scales for plots
            triggerScale = 20;
            instrumentScale = 50;
            
            points = zeros(3, numTriggers);
            xAxes = zeros(3, numTriggers);
            yAxes = zeros(3, numTriggers);
            zAxes = zeros(3, numTriggers);
           
            for i = 1:numTriggers
                matrix4D = triggerMarks(i).Matrix4D;
                point = matrix4D(:, 4);
                rotMat = matrix4D(:, 1:3);               
                points(:, i) = point;
                xAxes(:, i) = rotMat(:, 1) * triggerScale;
                yAxes(:, i) = rotMat(:, 2) * triggerScale;
                zAxes(:, i) = rotMat(:, 3) * triggerScale;
            end
            % X-ax lines
            line(obj.visualAxes, ...
                [points(1, :); points(1, :) + xAxes(1, :)], ...
                [points(2, :); points(2, :) + xAxes(2, :)], ...
                [points(3, :); points(3, :) + xAxes(3, :)], ...
                'Color', 'r');
            % Y-ax lines
            line(obj.visualAxes, ...
                [points(1, :); points(1, :) + yAxes(1, :)], ...
                [points(2, :); points(2, :) + yAxes(2, :)], ...
                [points(3, :); points(3, :) + yAxes(3, :)], ...
                'Color', 'g');
            % Z-ax lines
            line(obj.visualAxes, ...
                [points(1, :); points(1, :) + zAxes(1, :)], ...
                [points(2, :); points(2, :) + zAxes(2, :)], ...
                [points(3, :); points(3, :) + zAxes(3, :)], ...
                'Color', 'b');

            % Instrument marker quiver plot
            rotMat = instrumentMatrix(:, 1:3);
            point = instrumentMatrix(:, 4);
            xAx = rotMat(:, 1) * instrumentScale;
            yAx = rotMat(:, 2) * instrumentScale;
            zAx = rotMat(:, 3) * instrumentScale;
            % set(obj.visualAxes.Children, 'HandleVisibility', 'off');
          
           q1=  quiver3(obj.visualAxes, point(1), point(2), point(3),...
                xAx(1), xAx(2), xAx(3), 'r', 'HandleVisibility', 'on');
            q2 = quiver3(obj.visualAxes, point(1), point(2), point(3),...
                yAx(1), yAx(2), yAx(3), 'g', 'HandleVisibility', 'on');
            q3 = quiver3(obj.visualAxes, point(1), point(2), point(3),...
                zAx(1), zAx(2), zAx(3), 'b', 'HandleVisibility', 'on');
            
            legend([q1,q2,q3], 'X-axis', 'Y-axis', 'Z-axis', 'Location', 'eastoutside','autoupdate','off');
            f.Value = .88;
            view(obj.visualAxes, [0 0 1]);
            axis(obj.visualAxes,'equal');
            drawnow;
            close(f)
            if ~isempty(missingInd)
                erMsg = sprintf("%i data points were omitted from the plot. These data points were not detected by the Localite camera at the time of TMS stimulation.", length(missingInd));
                uialert(obj.fig, erMsg, 'Data Omitted from Plot');
            end
            
        end
    end
end
