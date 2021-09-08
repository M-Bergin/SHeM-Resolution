% Script to add scalebar to optical image of tin spheres
% MBe

Sn_optical=imread('Data\Sn_sphere_11.png');

%Crop the image to fit better in the figure
Sn_optical=Sn_optical(:,1:1920,:);

%Plot the image
figure;imagesc(Sn_optical)
axis equal off 
hold on

%Add the scalebar 457px long which is 100um
quiver(200,1800,457,0,'ShowArrowHead','off','Autoscale','off','LineWidth',5,'Color','y')

im_size=size(Sn_optical);

fig_h=gcf;
ax_h=gca;
%fig_h.PaperPositionMode='auto';

set(ax_h,'units','pixels') % set the axes units to pixels
x = get(ax_h,'position'); % get the position of the axes
set(fig_h,'units','pixels') % set the figure units to pixels
y = get(fig_h,'position'); % get the figure position
set(fig_h,'position',[y(1) y(2) (im_size(2)/im_size(1))*x(4) x(4)])% set the position of the figure to the length and width of the axes
set(ax_h,'units','normalized','position',[0 0 1 1]) % set the axes units to pixels



%Set paper size for printing to pdf

set(fig_h,'Units','Inches');
pos = get(fig_h,'Position');
set(fig_h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])


% exportgraphics(gcf,'..\Figures\Sn_sphere_11_sb.pdf')
%  savefig(['..\Figures\Sn_sphere_11_sb.fig'])
