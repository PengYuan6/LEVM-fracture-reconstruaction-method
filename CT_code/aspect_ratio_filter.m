function bf_intact_img_2=aspect_ratio_filter(bf_intact_img,ratio_min)

region_datas=regionprops(bf_intact_img,'MajorAxisLength', 'MinorAxisLength', 'PixelIdxList');
bf_intact_img_2 =false(size(bf_intact_img));
    for i = 1:length(region_datas)
        majorAxisLength = region_datas(i).MajorAxisLength;
        minorAxisLength = region_datas(i).MinorAxisLength;
        ratio = majorAxisLength / minorAxisLength;
        if ratio>ratio_min
            bf_intact_img_2(region_datas(i).PixelIdxList) = true;
        end
    end
end