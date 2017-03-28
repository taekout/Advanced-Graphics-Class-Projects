x=[0.01:0.01:1.00];
loop_count = 100;

mean=2.0;
s_d= 0.1;
% Extreme Case (low) mean = -1.0, standard deviation = 0.2
% Extreme Case (High) mean = 2.0, standard deviation = 0.1
% Extreme Case (High) mean = 0.0, standard deviation = 0.3
result = normcdf(x, mean, s_d);
%phi_input = (log(x)-mean) / s_d;

%http://www.mpch-mainz.mpg.de/~eustach/news/jgr/zhou.pdf
%http://en.wikipedia.org/wiki/File:Bahco_Example.JPG
%http://annhyg.oxfordjournals.org/content/38/1/45.abstract
%http://www.opticsinfobase.org/view_article.cfm?gotourl=http%3A%2F%2Fwww%2Eopticsinfobase%2Eorg%2FDirectPDFAccess%2F33857F5C-B275-C89A-537991E6A1AC976C_76250%2Epdf%3Fda%3D1%26id%3D76250%26seq%3D0%26mobile%3Dno&org=University%20of%20Maryland%20Baltimore%20County%20Library
%result = (1 / sqrt(2 * pi)) * exp(-1/2 * phi_input .* phi_input);
%result = result .* 255;

result = (1.0 / max(result)) .* result;
result2 = zeros(loop_count, loop_count);
for i = 1 : loop_count
    result2(i,:) = result;
end
plot(result);

imwrite(result2, 'cdf.bmp', 'bmp');

%PDF function
result_pdf = (1 ./ (x .* s_d .* sqrt(2 * pi))) .* exp(-( ((log(x) - mean) .^ 2) ./ ((2*s_d) .^ 2) ) ) ;
%result_pdf = 1 ./ (x .* s_d .* sqrt(2 * pi)) * exp(-( (log(x) - mean) ./ (2*s_d) ) ) ;
%result = result .* 255;

result2_pdf = zeros(loop_count, loop_count);
for i = 1 : loop_count
    result2_pdf(i,:) = result_pdf;
end

imwrite(result2_pdf, 'pdf.bmp', 'bmp');

%Get random particle density distribution based on CDF
rndSeed = zeros(256,256);
rndSeed = randi(100, 256);
particleDensityDist = zeros(256,256);
particleDensityDist(:) = result(1, rndSeed);
imwrite(particleDensityDist, 'particleDensityDist.bmp', 'bmp');

%random Vector
dim = 256;
rndImage = rand(dim, dim, 3);
tmp = zeros(1,3);
for i = 1 : dim
    for j = 1 : dim
        tmp(1,1) = rndImage(j,i, 1);
        tmp(1,2) = rndImage(j,i, 2);
        tmp(1,3) = rndImage(j,i, 3);
        rndImage(j, i, :) = rndImage(j,i,:) / norm(tmp);
    end
end
imwrite(rndImage, 'dir.bmp', 'bmp');

Fdata = xlsread('F_512.csv');
Fdata = Fdata .* 0.5;
imwrite(Fdata, 'ftnF.bmp', 'bmp');

Gdata = xlsread('G0_pi_2_64.csv');
Gdata = Gdata ./ 8.0676;
imwrite(Gdata, 'Gftn.bmp', 'bmp');

Gdata10 = xlsread('G20_pi_2_64.csv');
Gdata10 = Gdata10 ./ 2.5721;
imwrite(Gdata10, 'Gftn10.bmp', 'bmp');





