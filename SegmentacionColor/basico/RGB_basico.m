clear all;close all;clc;
%% VECTORES DE UMBRALES
% (Orden colores: Azul, Verde, Amarillo, Rojo, Negros, Naranja)
%% PARAMETROS

% Umbrales maximos y minimos RGB
channelRedMin = [0,0,166,89,201,0];
channelRedMax = [85,133,255,215,255,99];
channelGreenMin = [51,119,154,0,0,0];
channelGreenMax = [207,255,255,88,198,112];
channelBlueMin = [105,0,0,12,0,0];
channelBlueMax = [252,177,72,255,101,109];

% Radios para aplicar erosionado y dilatado
radio_open = 2;
radio_close = 5;

% Área para eliminación de objetos no lacasitos
areaLacasito = 800;

%% DIVIDIR CANALES DE COLORES
% Dividimos la imagen original RGB por distintos canales separados
%%
f = imread('imagenDePartida.png');
figure(1); imshow(f);

%%
[M,N,C] = size(f);

fRojo  = f(:,:,1);
fVerde = f(:,:,2);
fAzul  = f(:,:,3);

figure(2); imshow([fRojo,fVerde,fAzul]);

%% CLASIFICACIÓN E IDENTIFICACIÓN
Ncolor=6; %Número de colores en la imagen a clasificar
for color=1:Ncolor
    %% BINARIZACIÓN POR UMBRALES
    % Creamos plantilla binarizada a partir de umbrales obtenidos con Color
    % Thresholder
    %%
    fRojoPlantilla = (channelRedMin(color)<=fRojo & fRojo<=channelRedMax(color));
    fVerdePlantilla = (channelGreenMin(color)<=fVerde & fVerde<=channelGreenMax(color));
    fAzulPlantilla = (channelBlueMin(color)<=fAzul & fAzul<=channelBlueMax(color));
    fPlantilla = fRojoPlantilla & fVerdePlantilla & fAzulPlantilla;

    if(color==1)
        figure(3); imshow(fPlantilla);
    end
    %% APLICAR DILATACIONES Y EROSIONES
    % Usamos las funciones imopen() y imclose() para conseguir eliminar
    % todo lo que no sean lacasitos y rellenar los mismos. De este modo la
    % plantilla mejora significativamente.
    %%
    se_open = strel('disk',radio_open);
    se_close = strel('disk',radio_close);

    fPlantillaAfterOpen = imopen(fPlantilla,se_open);
    fPlantillaAfterClose = imclose(fPlantillaAfterOpen,se_close);

    if(color==1)
        figure(4); imshow(fPlantillaAfterClose);
    end
    %% APLICAR FILTRO DE ÁREA
    % Como aún quedan restos de imagen no pertenecientes a lacasitos,
    % podemos aplicar un filtrado atendiendo al área de los objetos
    % identificados en la plantilla resultante.
    %%
    fPlantillaEtiq = bwlabel(fPlantillaAfterClose);
    fPlantillaLacasitos = fPlantillaAfterClose;

    for i=1:max(max(fPlantillaEtiq))
        fPlantillaObjeto = fPlantillaAfterClose & (fPlantillaEtiq == i);
        areaObjeto = regionprops(fPlantillaObjeto,'Area');
        if(areaObjeto.Area < areaLacasito)
            fPlantillaLacasitos = fPlantillaLacasitos & (fPlantillaEtiq ~= i);
        end
    end

    if(color==1)
        figure(5); imshow(fPlantillaLacasitos,[]);
    end
    %% BOUNDINGBOX Y CENTROS
    % Identificamos los centros de los lacasitos y los dibujamos junto a
    % las boundingbox asociadas a los mismos
    %%
    datos = regionprops(fPlantillaLacasitos,'BoundingBox','Centroid','Area');
    bbox = cat(1,datos.BoundingBox);
    sizebbox=size(bbox);
    centroids = cat(1,datos.Centroid);
    areaDetect = cat(1,datos.Area);

    figure();imshow(f);
    hold on
    %Centros
    plot(centroids(:,1),centroids(:,2),'c.','MarkerSize',25);
    %BoundingBox
    for i=1:sizebbox(1)
        pIniBbox = bbox(i,1:2)';
        anchoBbox = bbox(i,3);
        altoBbox = bbox(i,4);
        p1 = pIniBbox;
        p2 = pIniBbox+[anchoBbox,0]';
        p3 = pIniBbox+[anchoBbox,altoBbox]';
        p4 = pIniBbox+[0,altoBbox]';
        if(areaDetect(i) >= (areaLacasito*1.5))
            line ([p1(1),p2(1),p3(1),p4(1),p1(1)], [p1(2),p2(2),p3(2),p4(2),p1(2)],'LineWidth',2 ,'Color', 'y');
        else
            line ([p1(1),p2(1),p3(1),p4(1),p1(1)], [p1(2),p2(2),p3(2),p4(2),p1(2)],'LineWidth',2 ,'Color', 'g');
        end
    end
    hold off
end
%autoArrangeFigures();
