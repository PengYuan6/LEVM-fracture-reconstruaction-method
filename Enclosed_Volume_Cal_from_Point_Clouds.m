function V_final = Enclosed_Volume_Cal_from_Point_Clouds(zq_1_now,zq_2_now,space)
    % Zq_1_now/Zq_2_now is Matrix-form data rather than three-column (x–y–z) data.
    % space is The distance between two adjacent elements, with equal spacing in both length and width by default.
    
    z_1 = zq_1_now; % Corrected upper surface
    z_2 = zq_2_now; % Initial lower surface
    [rr,cc] = size(z_1); % rr is the number of rows of the z matrix, cc is the number of columns
    % The x and y coordinates can be shifted to the origin; no major changes are needed
    % Only the grid spacing needs to be specified:
    n = space;
    % ABCM–DEFN arrangement, distances as shown in the schematic (file: volume calculation illustration)
    x = [n 0 n 0 n 0 n 0];
    y = [0 0 n n 0 0 n n];
    % Calculate the volume of each grid cell:
    
    tic
    % Very strange behavior: if cal_aperture is not placed inside a function,
    % the following two lines run faster using parfor, but once wrapped as a function,
    % parfor can no longer be used
    for i = 1:(rr-1)*(cc-1) % Total number of grid cells
        col = ceil(i/(rr-1)); % First determine which column the cell is in (round up)
        row = mod(i,(rr-1));  % Then determine which row the cell is in (remainder)
        if row == 0
            row = rr-1; % If divisible exactly, the row is the last row
        end
        % (row, col) is the coordinate of the grid cell,
        % with a total of (rr-1)*(cc-1) small squares
        %  (B)1———————————2(M)
        %     |           |
        %     | (row,col) |
        %     |           |
        %  (A)3———————————4(C)
        % a1, a2, etc. denote the indices of the corner points of each cell, as shown in the figure
        a1 = (col-1)*(rr)+ row;
        a2 = (col)*(rr)+ row;
        a3 = (col-1)*(rr)+ row +1;
        a4 = (col)*(rr)+ row +1;
        % Assign the z-coordinates of the upper and lower surfaces
        % following the corner order 3-1-4-2
        z = [z_1(a3), z_1(a1), z_1(a4), z_1(a2), ...
             z_2(a3), z_2(a1), z_2(a4), z_2(a2)];
        O = ones(1,8);
        M_total = [O;x;y;z]; % Use fixed x, y coordinates for each grid cell
        % Irregular hexahedron, computed by splitting into six tetrahedra:
        M1 = M_total(:,[1,5,6,7]);
        M2 = M_total(:,[1,2,3,6]);
        M3 = M_total(:,[1,3,6,7]);
        M4 = M_total(:,[4,6,7,8]);
        M5 = M_total(:,[2,3,4,6]);
        M6 = M_total(:,[4,3,6,7]);
        % Volume of each tetrahedron
        volumn = (abs(det(M1))+abs(det(M2))+abs(det(M3)) ...
            +abs(det(M4))+abs(det(M5))+abs(det(M6)))/6;
        V_final(i,1) = volumn;
    end
    toc
end
