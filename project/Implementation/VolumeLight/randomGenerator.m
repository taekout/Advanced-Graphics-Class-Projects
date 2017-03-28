randNum1 = xlsread('randomNumber.xlsx');
randNum2 = xlsread('randomNumber6.xlsx');
randNum3 = xlsread('randomNumber2.xlsx');
randNum4 = xlsread('randomNumber5.xlsx');
randNum5 = xlsread('randomNumber3.xlsx');
randNum6 = xlsread('randomNumber4.xlsx');

dim = 256;
randImg1 = zeros(dim, dim, 3);
randImg2 = zeros(dim, dim, 3);

randImg1 = rand(dim, dim, 3);
tmp = zeros(1,3);
for i = 1 : dim
    for j = 1 : dim
        tmp(1,1) = randImg1(j,i, 1);
        tmp(1,2) = randImg1(j,i, 2);
        tmp(1,3) = randImg1(j,i, 3);
        randImg1(j, i, :) = randImg1(j,i,:) / norm(tmp);
    end
end

imwrite(randImg1, 'normalMap.bmp', 'bmp');

randImg2 = rand(dim, dim, 3);
for i = 1 : dim
    for j = 1 : dim
        tmp(1,1) = randImg2(j,i, 1);
        tmp(1,2) = randImg2(j,i, 2);
        tmp(1,3) = randImg2(j,i, 3);
        randImg2(j, i, :) = randImg2(j,i,:) / norm(tmp);
    end
end
imwrite(randImg2, 'scatteringReflectionMap.bmp' , 'bmp');