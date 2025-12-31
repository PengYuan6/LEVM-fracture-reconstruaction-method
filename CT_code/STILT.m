%%  STILT/Pengyuan Liu 
%%% the method is modified from 
%%% Deng H, Fitts JP, Peters CA. 
%%% Quantifying fracture geometry with X-ray tomography: Technique of Iterative
%%% Local Thresholding (TILT) for 3D image segmentation. Comput Geosci. 2016;20(1):231-244.
%%% http://doi:10.1007/s10596-016-9560-9
%% 
clear;clc;close all;
%% Step 1 Select the image and extract it as a circle
% Read images in TIFF format. Return to its address
[filename, pathname] = uigetfile('*.tif');        
if isequal(filename,0) || isequal(pathname,0)
    disp('User canceled the operation');
    return;
else
    fullpath = fullfile(pathname, filename);
    I= imread(fullpath);
end

f1 = figure('Units', 'inches', 'Position', [1 1 12 8], 'PaperPositionMode', 'auto');
f1.Name = sprintf('No.%s Original Picture',filename);

subplot(1,2,1);
imshow(I);title('Initial original image');

% The first cut and finally the ultimate rectangular shape with equal and tangent length
subplot(1,2,2); 
crop_img_1 = I; 
% Circular filling
[rows, cols] = size(crop_img_1); 
centerX = cols/2; 
centerY = rows/2; 
radius  = min(rows, cols)/2; 
[x, y]  = meshgrid(1:cols, 1:rows); % Create coordinate grid
circleMask = ((x - centerX).^2 + (y - centerY).^2) <= radius^2; 
crop_img_1(~circleMask) = 65535;
imshow(crop_img_1);  title('Preliminary cropping of images');
%% Step 2 Cutting and other pre-processing
I_clahe    = adapthisteq(crop_img_1, 'ClipLimit', 0.0005); % 较低的剪裁限制,0.0005有可能好用

% choose parameter x0 x1 y0 y1 to crop:
x0 = 18  ;  
x1 = 1080; 
y0 = 460 ;
y1 = 660 ;
crop_img_2 = I_clahe(x0:x1,y0:y1); % 除了C3:18 1080/460 660;
imshow(crop_img_2);title('Local Image');
%% Step3 Iterative segmentation

threshold00 = graythresh(crop_img_2);
binaryImage = imbinarize(crop_img_2, threshold00);

figure 
subplot(1,6,1); imshow(binaryImage); title('initail segmentation');
subplot(1,6,2); imshow(crop_img_2);  title('Original Image');

% Assign initial value ：
threshold(1,1) = threshold00;
logic_index = 1;
sum_matrix  = [];
i = 0;
while 1
    i = i+1;
    % Erosion connection mask making
    se1 = strel('disk',5);    
    mask1 = imerode(binaryImage,se1);
    subplot(1,6,3); imshow(mask1); title('Erosion connection'); 
    
    % Process the mask to ensure that only the largest one remains
    AA = bwconncomp(~mask1);
    mask1_after = bwareaopen(~mask1, 301); 
    mask2_after = aspect_ratio_filter(mask1_after,1); 
    subplot(1,6,4);imshow(~mask2_after);title('Processing Mask');
    
    % Obtain cracks in areas with only masks
    transition_matrix_1 = crop_img_2(mask2_after == 1); 
    transition_matrix_1_new = double(transition_matrix_1)/65535;
    transition_matrix_1_new(transition_matrix_1_new>0.6) = [];
   
    % Obtain a new threshold
    threshold(1,i+1) = graythresh(transition_matrix_1_new);
    
    % New threshold segmentation result
    binaryImage = imbinarize(crop_img_2,threshold(1,i+1));
    subplot(1,6,5);imshow(binaryImage);title('iteration result')
  
    % Morphological processing
    BB = bwconncomp(~binaryImage); 
    result_image = MorphProgram(binaryImage); 
    subplot(1,6,6);imshow(result_image);title('final result')
    binaryImage = result_image;
    % Determine whether the new image should jump out of the loop
    if  abs((threshold(1,i+1)-threshold(1,i))) < 0.00001
        break
    elseif (i>=3) && ((threshold(1,i+1))-threshold(1,i-1) < 0.00001)
        threshold(1,i+2) = min(threshold); 
        binaryImage = imbinarize(crop_img_2,threshold(1,i+2));
        BB = bwconncomp(~binaryImage); 
        result_image = MorphProgram(binaryImage);
        break
    end
end
sum_pixal = sum(~result_image(:));
width = sum_pixal*0.04512*0.04512/48;
fprintf('The total number of pixel blocks is %04d/ Width is %04d\n', sum_pixal,width);