%Script to calculate two image diffractogram
%MBe

%Load in the data
data1=read_MkII_data('Data\13-Mar-2021_001.txt');
data2=read_MkII_data('Data\15-Mar-2021_001.txt');

%Flip the images
data1.image=rot90(flipud(data1.image),3);
data2.image=rot90(flipud(data2.image),3);

%Remove spikes
data1.image=spike_im_removal(data1.image,6);
data2.image=spike_im_removal(data2.image,6);

%figure;imagesc(data1.image); colormap gray;axis square equal tight

pixel_size=data1.image_size./data1.num_pixels*1e-6;
if diff(pixel_size)~=0
    warning('Non equal pixel sizes, SML has been here somehow')
else
    pixel_size=pixel_size(1);
end

%Check images are registered to start with
%C = imfuse(Lambda{1},Lambda{3},'falsecolor','Scaling','joint','ColorChannels',[1 2 0]);
%figure;imshow(C)

%Plot one of the images
SHeM_fig_process_Newcastle(data1,0,100, 0)

%
%  exportgraphics(gcf,'..\Figures\13-Mar-2021_001.pdf')
%  savefig(['..\Figures\13-Mar-2021_001.fig'])

%Rotate the images for vertical shift
vert_rot=0;
if vert_rot==1
    data1.image=rot90(data1.image,1);
    data2.image=rot90(data2.image,1);
end


%Set up size of sub images
delta_x=30;
delta_y=0;
start_x=10;
start_y=40;
N_crop=210;%250-max([delta_x delta_y]);

%Crop the two images
img1_raw=data1.image(start_y:start_y+N_crop-1,start_x:start_x+N_crop-1);
img2_raw=data2.image(start_y+delta_y:start_y+N_crop-1+delta_y,start_x+delta_x:start_x+N_crop-1+delta_x);%image_2;
%figure;imagesc(img2_raw); colormap gray;axis square equal tight



%Check fft of the image
img1_windowed=(img1_raw-mean(img1_raw(:)));%.*(hann(N_crop)*hann(N_crop)');
img1_fft=fftshift(fft2(img1_windowed));

x_fft_max=(N_crop/2)/(N_crop*pixel_size);
x_fft_min=-((N_crop/2)+1)/(N_crop*pixel_size);

if vert_rot==1
    figure;imagesc([x_fft_min,x_fft_max]/1e5,[x_fft_max,x_fft_min]/1e5,rot90((abs(img1_fft)),3));colormap gray;axis square equal tight
else
    figure;imagesc([x_fft_min,x_fft_max]/1e5,[x_fft_max,x_fft_min]/1e5,(abs(img1_fft)));colormap gray;axis square equal tight
end
xlabel('k_x /10^5m^{-1}')
ylabel('k_y /10^5m^{-1}')
set(gca,'FontSize',16,'LineWidth',1)
caxis([0 4e5])
% xlim([-1.5 1.5])
% ylim([-1.5 1.5])

%  exportgraphics(gcf,'..\Figures\FFT_single.pdf')
%  savefig(['..\Figures\FFT_single.fig'])


%Combine the images
totI_raw=(img1_raw+img2_raw);

%Apply window function and remove mean value
%window=hann(N_crop)*hann(N_crop)';
window=ones(N_crop,N_crop);
totI_raw=totI_raw-mean(totI_raw(:));
totI=totI_raw.*window;
%totI=totI-mean(totI(:));
%figure;imagesc(totI); colormap gray;axis square equal tight

%N_fft=2.^nextpow2(size(totI));
%N_fft=N_fft(1);

%FFT the superposed images
%totI_fft=fftshift(fft2(totI,N_fft,N_fft));
totI_fft=fftshift(fft2(totI));

%Plot the result
if vert_rot==1
    figure;imagesc([x_fft_min,x_fft_max]/1e5,[x_fft_min,x_fft_max]/1e5,rot90((abs(totI_fft)),3));colormap gray;axis square equal tight
else
    figure;imagesc([x_fft_min,x_fft_max]/1e5,[x_fft_min,x_fft_max]/1e5,(abs(totI_fft)));colormap gray;axis square equal tight
end
%figure;imagesc(log(abs(totI_fft))); colormap gray; axis square equal tight
caxis([0 8e5])
xlabel('k_x /10^5m^{-1}')
ylabel('k_y /10^5m^{-1}')
set(gca,'FontSize',16,'LineWidth',1)

%  exportgraphics(gcf,'..\Figures\FFT_double.pdf')
%  savefig(['..\Figures\FFT_double.fig'])


%Autocorrelation analysis

%Setup the variables
crop_length=18;
crop_offset=4;%4
crop_y_start=floor(N_crop/2)-floor(crop_length/2)+crop_offset;
crop_y_end=floor(N_crop/2)+ceil(crop_length/2)+crop_offset;

osc_period=N_crop/max([delta_x delta_y]);
middle_point=floor(N_crop/2);

% Loop over each fringe up to a maximum of 12
for m=2:12
    
    if delta_y==0
        crop_im=abs(totI_fft(crop_y_start:crop_y_end,middle_point-floor(osc_period)-(m-1)*osc_period:floor(N_crop/2)-(m-1)*osc_period)); %+ceil(osc_period/2)
    elseif delta_x==0
        warning('Are you sure the lines are totally vertical?')
        crop_im=abs(totI_fft(middle_point-floor(osc_period)-(m-1)*osc_period:floor(N_crop/2)-(m-1)*osc_period,crop_y_start:crop_y_end)); %+ceil(osc_period/2)
    else
        error('This part of the code can only deal with shifts in x or y, not both')
    end
    
    
    %Calculate FFT
    crop_fft=fft2(crop_im);
    %figure;imagesc(log(abs(fftshift(crop_fft))));colormap(gray); axis square equal tight
    
    %Calculate ACF (proportional to)
    num_ACF=5;
    g=fftshift(ifft2(abs(crop_fft).^(2*num_ACF)));
    %g=g/max(g(:));
    
    %Take the column average
    col_av=mean(mat2gray(g));
    
    %Check for max value of column average to see if data is alligned
    %vertically
    
    if max(col_av)<0.85
        %disp('hello')
        break
    end
end

%Get the maximum fringe number
m_max=m-1;%6;

%Calculate the resolution
res=(N_crop/(m_max*osc_period))*pixel_size;
