function figura3d(X, Y, Z, T)

%  X:  vector datos x
%  Y:  vector datos y
%  Z:  vector datos z
%  T: MTH de C respecto W

% Creamos figura
figure1 = figure;

% Creamos ejes
axes1 = axes('Parent',figure1);
hold(axes1,'on');

% Creamos plot3
trplot(T); %Representa ejes de la cámara {C}
plot3(X,Y,Z,'k','Marker','*','LineStyle','none'); %Objeto
plot3([0,7],[0,0],[0,0],'g','LineWidth',2); %eje x de {W}
plot3([0,0],[0,3],[0,0],'b','LineWidth',2); %eje y de {W}
plot3([0,0],[0,0],[0,5],'r','LineWidth',2); %eje z 

% zlabel
zlabel({'Eje Z [m]'});

% ylabel
ylabel({'Eje Y [m]'});

% xlabel
xlabel({'Eje X [m]'});

% Título
title({'Objeto y Cámara en espacio'});

xlim(axes1,[0 8]);
ylim(axes1,[-2 5]);
zlim(axes1,[0 20]);
view(axes1,[-37.5 30]);

grid(axes1,'on');
hold(axes1,'off');

set(axes1,'XMinorGrid','on','YMinorGrid','on','ZMinorGrid','on');
