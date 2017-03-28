dir1 = imread('noise1.ppm');
dir2 = imread('noise2.ppm');
dir3 = imread('noise3.ppm');

dim = 256;
FinalDir = zeros(dim, dim, 3);
FinalDir = im2double(FinalDir);
dir1 = im2double(dir1);
dir2 = im2double(dir2);
dir3 = im2double(dir3);
FinalDir(:,:,1) = dir1(:,:,1);
FinalDir(:,:,2) = dir2(:,:,2);
%FinalDir(:,:,3) = dir3(:,:,3);
for i = 1 : dim
    for j = 1 : dim
        tmp(1,1) = FinalDir(j,i, 1);
        tmp(1,2) = FinalDir(j,i, 2);
        tmp(1,3) = FinalDir(j,i, 3);
        FinalDir(j, i, :) = FinalDir(j,i,:) / norm(tmp);
    end
end

imwrite(FinalDir, 'DirFromGaborNoise.bmp', 'bmp');


imshow(FinalDir);