function [xAx,yAx,zAx] = quaternionToEuler(q)
    % quaternionToEuler 
    % Converts a quaternion to Euler angles
    % Input params:
    % q : quaternion [w, x, y, z] 
    % Output params:
    % [yaw,pitch,roll]: euler angles in radians

    % Normalize quat
    q = q / norm(q);
    assert(sum(size(q)==4 & max(size(q)) == 4),'Check quat size')
    % extract the values from the quaternion
    w = q(1);
    x = q(2);
    y = q(3);
    z = q(4);
    % calculate euler angles 

    % CHECK AXES!
    % Around z-axis
    zAx = atan2(2*(w*z + x*y), 1 - 2*(y^2 + z^2));
    % Around y-axis
    sinp = 2*(w*y - z*x);
    if abs(sinp) >= 1
        yAx = sign(sinp) * pi/2; % uses 90 degrees if out of range
    else
        yAx = asin(sinp);
    end
    % around x-axis
    xAx = atan2(2*(w*x + y*z), 1 - 2*(x^2 + y^2));
end