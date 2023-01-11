clear all;close all;clc;
%% CARACTERÍSTICA DE LAS IMÁGENES
%
%%
Ncolor=6; %Número de colores en la imagen a clasificar
%% MATRIZ DE UMBRALES
% Fila 1 mínimo, fila 2 máximo, columnas H, S y V, capas de color
%%

umbralesHSV = zeros(2,3,Ncolor);

umbralesHSV(:,:,1) = [0.146, 0.587, 0.517; 0.251, 1.000, 1.000]; %Color amarillo
umbralesHSV(:,:,2) = [0.433, 0.309, 0.000; 0.800, 1.000, 1.000]; %Color azul
umbralesHSV(:,:,3) = [0.029, 0.566, 0.710; 0.080, 1.000, 1.000]; %Color naranja
umbralesHSV(:,:,4) = [0.000, 0.000, 0.000; 1.000, 1.000, 0.329]; %Color negro
umbralesHSV(:,:,5) = [0.933, 0.178, 0.378; 0.027, 1.000, 0.976]; %Color rojo
umbralesHSV(:,:,6) = [0.194, 0.294, 0.371; 0.467, 1.000, 1.000]; %Color verde

% Radios para aplicar erosionado y dilatado
radio_open = 1;
radio_close = 2;

% Área para eliminación de objetos no lacasitos
areaLacasito = 800;

%% DIVIDIR CANALES DE COLORES
% Dividimos la imagen original RGB por distintos canales separados
%%
h = imread('imagenDePartida.png');
figure(1); imshow(h);

%%
[M,N,C] = size(h);

f = rgb2hsv(h);
fHue  = f(:,:,1);
fSat = f(:,:,2);
fVal  = f(:,:,3);

figure(2); imshow([fHue,fSat,fVal]);

%% CLASIFICACIÓN E IDENTIFICACIÓN
Ncolor=6; %Número de colores en la imagen a clasificar
for color=1:Ncolor
    %% BINARIZACIÓN POR UMBRALES
    % Creamos plantilla binarizada a partir de umbrales obtenidos con Color
    % Thresholder
    %%
    if(umbralesHSV(1,1,color)<umbralesHSV(2,1,color))
        fHuePlantilla = (umbralesHSV(1,1,color)<=fHue & fHue<=umbralesHSV(2,1,color));
    else
        fHuePlantilla = (umbralesHSV(1,1,color)<=fHue | fHue<=umbralesHSV(2,1,color));
    end
    fSatPlantilla = (umbralesHSV(1,2,color)<=fSat & fSat<=umbralesHSV(2,2,color));
    fValPlantilla = (umbralesHSV(1,3,color)<=fVal & fVal<=umbralesHSV(2,3,color));
    fPlantilla = fHuePlantilla & fSatPlantilla & fValPlantilla;
    if(color==1)
        figure(3); imshow(fPlantilla);
    end
    %% APLICAR DILATACIONES Y EROSIONES
    % Usamos las funciones imopen() y imclose() para conseguir eliminar
    % todo lo que no sean lacasitos y rellenar los mismos. De este modo la
    % plantilla mejora significativamente.
    %%
    se_open = creaPlantillaDisco(radio_open);
    se_close = creaPlantillaDisco(radio_close);

    fPlantillaAfterOpen = procesadoOpen(fPlantilla,se_open);
    fPlantillaAfterClose = procesadoClose(fPlantillaAfterOpen,se_close);
    if(color==1)
        figure(4); imshow(fPlantillaAfterClose);
    end
    %% APLICAR FILTRO DE ÁREA, CALCULAR BOUNDING BOX Y CENTROIDE
    % Como aún quedan restos de imagen no pertenecientes a lacasitos,
    % podemos aplicar un filtrado atendiendo al área de los objetos
    % identificados en la plantilla resultante.
    %%
    fPlantillaEtiq = bwlabel(fPlantillaAfterClose);
    fPlantillaLacasitos = fPlantillaAfterClose;
    x=1; %índice de vector de almacenamiento de propidades de objeto
    bboxSeparated=[]; centroidsSeparated=[]; areaSeparated=[];
    for i=1:max(max(fPlantillaEtiq))
        fPlantillaObjeto = fPlantillaAfterClose & (fPlantillaEtiq == i);
        areaObjeto = regionprops(fPlantillaObjeto,'Area');
        if(areaObjeto.Area < areaLacasito)
            fPlantillaLacasitos = fPlantillaLacasitos & (fPlantillaEtiq ~= i);

        elseif(areaObjeto.Area > 1.7*areaLacasito)
            fPlantillaIndiv = (fPlantillaEtiq == i); %selecciona conjunto de lacasitos con sus Values asociados
            fPlantillaIndiv = procesadoErosion(fPlantillaIndiv,creaPlantillaDisco(10));
            fPlantillaIndiv=bwlabel(fPlantillaIndiv);
            fPlantillaSeparado=zeros(M,N,max(max(fPlantillaIndiv)));
            for j=1:max(max(fPlantillaIndiv))
                fPlantillaSeparado(:,:,j) = fPlantillaIndiv==j; %Lacasito separado reducido
                fPlantillaSeparado(:,:,j) = procesadoDilatado(fPlantillaSeparado(:,:,j),creaPlantillaDisco(10)); %Lacasito separado con tamaño recuperado
                data = regionpropsManual(fPlantillaSeparado(:,:,j));
                bboxSeparated(x,:)= cat(1,data.BoundingBox);
                centroidsSeparated(x,:)= cat(1,data.Centroid);
                areaSeparated(x,:)= cat(1,data.Area);
                x=x+1;
            end
        end
    end
    if(color==1)
        figure(5); imshow(fPlantillaLacasitos,[]);
    end
    %% BOUNDINGBOX Y CENTROS
    % Identificamos los centros de los lacasitos y los dibujamos junto a
    % las boundingbox asociadas a los mismos
    %%
    datos = regionpropsManual(fPlantillaLacasitos);
    bbox = cat(1,datos.BoundingBox,bboxSeparated);
    sizebbox=size(bbox);
    centroids = cat(1,datos.Centroid,centroidsSeparated);
    areaDetect = cat(1,datos.Area,areaSeparated);

    figure();imshow(h);
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
        if(areaDetect(i) >= (areaLacasito*1.7))
            line ([p1(1),p2(1),p3(1),p4(1),p1(1)], [p1(2),p2(2),p3(2),p4(2),p1(2)],'LineWidth',2 ,'Color', 'y');
        else
            line ([p1(1),p2(1),p3(1),p4(1),p1(1)], [p1(2),p2(2),p3(2),p4(2),p1(2)],'LineWidth',2 ,'Color', 'g');
        end
    end
    hold off
end
%autoArrangeFigures();
