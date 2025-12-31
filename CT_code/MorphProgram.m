function result_img = MorphProgram(binaryImage)

med_img = medfilt2(binaryImage,[3 3]); 

se1 = strel('line',3,30);            
erode_Image = imerode(med_img,se1);  
bwae_Image = bwareaopen(~erode_Image,10);         
bwae_Image_2 = aspect_ratio_filter(bwae_Image,1); 
se2 = strel('line',4,30);
dilate_img = imdilate(~bwae_Image_2,se2);
result_img = dilate_img;
