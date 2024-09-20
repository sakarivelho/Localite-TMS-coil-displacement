function [xAxixRotation,yAxisRotation,zAxisRotation,translation,xDiff,yDiff,zDiff] = calculateTransAndRot(transMat1,transMat2)
    %calculateTransAndRot 
    %  Calculates translation and euler angles [yaw, pitch, and roll] between
    %  two transformation matrices. 
    %  Requires quaternion library
    %  (https://www.mathworks.com/matlabcentral/fileexchange/35475-quaternions)
    
    % Input params:
    % transMat1: 3x4 transformation matrix
    % transMat2: 3x4 transformation matrix
    
    % Output params:
    % yaw, pitch, roll: euler angles (in deg) between the two transformation
    % matrices
    % translation: euclidean distance between the two transformation matrices
    % xDiff, yDiff, zDiff: X, Y and Z axis distances (in LCS of transMat1)
    assert(size(transMat1,1) == 3 & size(transMat1,2) == 4)
    assert(size(transMat2,1) == 3 & size(transMat2,2) == 4)

    % Extract translational parts
    t1 = transMat1(:,4);
    t2 = transMat2(:,4);
    % Extract rotation matrices
    m1 = transMat1(:,1:3);
    m2 = transMat2(:,1:3);

    % Calculate euclidean distance 
    translation = sqrt(sum((t1 - t2).^2));
   
    % Calculate X, Y and Z axis distance (in GCS)
    distGlobal = t2-t1;
    % Transform to m1 coordinate system
    distLocal = m1'*distGlobal;
    xDiff = distLocal(1);
    yDiff = distLocal(2);
    zDiff = distLocal(3);
    
    % Rotations with quaternions
    % Convert to quaternions
    q1 = qGetQ(m1);
    q2 = qGetQ(m2);

    % Conjugate of first quaternion
    cQ1 = qConj(q1);

    % Relative quaternion rotation
    quatRelative = qMul(cQ1,q2);
    % Convert to euler
    [xAxixRotation,yAxisRotation,zAxisRotation] = quaternionToEuler(quatRelative);

    % Convert to degress
    xAxixRotation = rad2deg(xAxixRotation);
    yAxisRotation = rad2deg(yAxisRotation);
    zAxisRotation = rad2deg(zAxisRotation);

end

