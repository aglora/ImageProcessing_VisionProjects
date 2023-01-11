function figuraImagen(X, Y, M, N,nx,ny)

%  X:  vector datos x
%  Y:  vector datos y

% Creamos figura
figure1 = figure;

% Creamos ejes
axes1 = axes('Parent',figure1);
hold(axes1,'on');

% Creamos plot
plot(X,Y,'k','Marker','*','LineStyle','none');
plot([0,0,N+1,N+1,0],[0,M+1,M+1,0,0],'Color','k', 'LineWidth',2);
plot([X(1),X(nx)],[Y(1),Y(nx)],'g','LineWidth',2); %eje x_w
plot([X(1),X((nx*(ny-1))+1)],[Y(1),Y((nx*(ny-1))+1)],'b','LineWidth',2); %eje y_w

% ylabel
ylabel({'Eje Vertical [pix]'});

% xlabel
xlabel({'Eje Horizontal [pix]'});

%  Título
title({'Imagen del objeto'});

xlim(axes1,[-100 4500]);
ylim(axes1,[-100 3500]);

grid(axes1,'on');
hold(axes1,'off');

set(axes1,'XMinorGrid','on','YMinorGrid','on','ZMinorGrid','on');
set(gca,'YDir', 'reverse');
