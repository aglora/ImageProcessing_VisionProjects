clear;clc;close all;

%% PARÁMETROS DEL PROGRAMA
%%
aspectRatioLicensePlate = 3.45;
yNorm = 128;
xNorm = 64;
nivel = 2;

%% VARIABLES
%%
%Contador de muestras de cada dígito
muestra = 0;
%Tamaño necesario patrones
tam = 1;
if(nivel>0)
    tam = 1;
    for i=1:nivel
        tam = tam+2^(i+1);
    end
end
%Patrones de caracteristicas
x = zeros(tam,1);
%Almacenamiento patrones(filas:características | columnas:muestras | capas:dígitos asociados)
MatrizPatrones = zeros(tam,180,10);


%% OBTENCIÓN MATRIZ PATRONES
%%

for imagen = 0:9 %Utilizar cada una de las imágenes de entrenamiento
    str_imagen = num2str(imagen);
    str_path = strcat('entrenamiento',str_imagen,'.jpg');
    fileImageRGB = imread(str_path);

    %% CONVERSIÓN A MODELO DE COLOR HSV
    %%
    [M,N,C] = size(fileImageRGB);
    fileImage = rgb2hsv(fileImageRGB);

    %% BINARIZACIÓN POR UMBRAL
    %%
    ValImage  = fileImage(:,:,3);
    MaxValue = 0.3;
    binPlantilla = ValImage<MaxValue;

    muestra=0; %Reseteo de numero de muestras de cada digito

    %% ETIQUETADO PARA DETECCIÓN DE MARCO DE MATRÍCULAS
    %%
    binPlantillaEtiq = bwlabel(binPlantilla);
    for i=1:max(max(binPlantillaEtiq)) %Analizo cada uno de los objetos de la plantilla
        EtiqSel = (binPlantillaEtiq == i);
        stats = regionprops(EtiqSel,"MajorAxisLength","MinorAxisLength");
        aspectRatio = stats.MajorAxisLength/stats.MinorAxisLength;

        %selecciono aquellos que cumplen la relación de aspecto del marco de la matrícula
        if( ((aspectRatioLicensePlate*0.9)<aspectRatio) && (aspectRatio<(aspectRatioLicensePlate*1.1)) )
            %% DESHACER ROTACIÓN Y RECORTAR
            %%
            Orientation = regionprops(EtiqSel,"Orientation");
            frameRotated = imrotate(EtiqSel,-Orientation.Orientation);
            binPlantilla_LicensePlate = imrotate(binPlantilla,-Orientation.Orientation);
            maskClose = strel('disk',10);
            frameRotated = imclose(frameRotated,maskClose);
            BoundingBox = regionprops(frameRotated,"BoundingBox");
            binPlantilla_LicensePlate = imcrop(binPlantilla_LicensePlate,BoundingBox.BoundingBox);

            % Comprobar si está girada más de 90º
            frameFocus = imcrop(frameRotated,BoundingBox.BoundingBox);
            CentroidMat = regionprops(frameFocus,"centroid");
            enfoqueMatricula = imrotate(fileImage,-Orientation.Orientation);
            enfoqueMatricula = imcrop(enfoqueMatricula,BoundingBox.BoundingBox);
            rectAzul = enfoqueMatricula(:,:,2)>0.9 & enfoqueMatricula(:,:,3)>0.5;
            mask = strel('disk',50);
            rectAzul = imclose(rectAzul,mask);
            caractRectAzul = regionprops(rectAzul,"centroid");
            flagInv = 0;
            if(caractRectAzul.Centroid(1)>CentroidMat.Centroid(1))
                binPlantilla_LicensePlate = imrotate(binPlantilla_LicensePlate,180);
            end

            %% ELIMINAR MARCO DE LA MATRÍCULA
            %%
            binPlantilla_LicensePlate_Etiq= bwlabel(binPlantilla_LicensePlate);
            ConvexAreaMax = 0;
            binPlantilla_LicensePlate_Etiq_Copy = binPlantilla_LicensePlate_Etiq;
            for j=1:max(max(binPlantilla_LicensePlate_Etiq)) %Analizo cada uno de los objetos de la plantilla
                binPlantilla_LicensePlate_Etiq_Sel = (binPlantilla_LicensePlate_Etiq == j);
                data = regionprops(binPlantilla_LicensePlate_Etiq_Sel,"ConvexArea","Area");
                if(ConvexAreaMax<data.ConvexArea) %elimina marco
                    indiceMaxConvexArea = j;
                    ConvexAreaMax = data.ConvexArea;
                end
                if(data.Area<20) %elimina pequeñas zonas de píxeles sin interés
                    binPlantilla_LicensePlate_Etiq_Copy = binPlantilla_LicensePlate_Etiq_Copy & (binPlantilla_LicensePlate_Etiq_Copy ~= j);
                end
            end
            binPlantilla_Digits = binPlantilla_LicensePlate_Etiq & (binPlantilla_LicensePlate_Etiq ~= indiceMaxConvexArea);
            binPlantilla_Digits = binPlantilla_Digits & binPlantilla_LicensePlate_Etiq_Copy;

            %% EXTRAER DÍGITOS Y NORMALIZAR SU TAMAÑO
            %%
            binPlantilla_Digits_Etiq = bwlabel(binPlantilla_Digits);
            for j=1:max(max(binPlantilla_Digits_Etiq)) %Analizo cada uno de los dígitos de la matrícula
                SelectedDigit= binPlantilla_Digits_Etiq==j;
                frameDigit = regionprops(SelectedDigit,"BoundingBox");
                SelectedDigit = imcrop(SelectedDigit,frameDigit.BoundingBox);
                plantillaDigito = imresize(SelectedDigit,[yNorm xNorm]);
                muestra=muestra+1;
                %% EXTRAER CARACTERÍSTICAS DÍGITO C1 - C13
                %%
                OccupiedArea = regionprops(plantillaDigito,"Area");
                x(1,1) = max(OccupiedArea.Area)/(yNorm*xNorm); %ratio de ocupación (Caracteristica 1) %Uso max() para evitar posibles areas pequeñas sueltas

                %% SUBDIVIDIR REGIÓN
                %%
                if(nivel>=1) %C2-C5
                    tamX=(xNorm/2);
                    tamY=(yNorm/2);
                    regionDigito=zeros(yNorm/2,xNorm/2,4);
                    %Division 4 regiones
                    regionDigito(:,:,1) = imcrop(plantillaDigito,[1 1 tamX-1 tamY-1]);
                    regionDigito(:,:,2) = imcrop(plantillaDigito,[tamX 1 tamX-1 tamY-1]);
                    regionDigito(:,:,3) = imcrop(plantillaDigito,[1 tamY tamX-1 tamY-1]);
                    regionDigito(:,:,4) = imcrop(plantillaDigito,[tamX tamY tamX-1 tamY-1]);
                    for k=1:4
                        if(~max(max(regionDigito(:,:,k))))
                            OccupiedArea.Area=0;
                        else
                            OccupiedArea = regionprops(regionDigito(:,:,k),"Area");
                        end
                        x(k+1,1) = max(OccupiedArea.Area)/(tamX*tamY); %ratio de ocupación (Caracteristicas 2-5)
                    end
                end

                if(nivel>=2) %C6-C13
                    tamX=(xNorm/2);
                    tamY=(yNorm/4);
                    regionDigito=zeros(yNorm/4,xNorm/2,8);
                    %Division 8 regiones
                    regionDigito(:,:,1) = imcrop(plantillaDigito,[1 1 tamX-1 tamY-1]);
                    regionDigito(:,:,2) = imcrop(plantillaDigito,[tamX 1 tamX-1 tamY-1]);
                    regionDigito(:,:,3) = imcrop(plantillaDigito,[1 tamY tamX-1 tamY-1]);
                    regionDigito(:,:,4) = imcrop(plantillaDigito,[tamX tamY tamX-1 tamY-1]);
                    regionDigito(:,:,5) = imcrop(plantillaDigito,[1 2*tamY tamX-1 tamY-1]);
                    regionDigito(:,:,6) = imcrop(plantillaDigito,[tamX 2*tamY tamX-1 tamY-1]);
                    regionDigito(:,:,7) = imcrop(plantillaDigito,[1 3*tamY tamX-1 tamY-1]);
                    regionDigito(:,:,8) = imcrop(plantillaDigito,[tamX 3*tamY tamX-1 tamY-1]);
                    for k=1:8
                        if(~max(max(regionDigito(:,:,k))))
                            OccupiedArea.Area=0;
                        else
                            OccupiedArea = regionprops(regionDigito(:,:,k),"Area");
                        end
                        x(k+5,1) = max(OccupiedArea.Area)/(tamX*tamY); %ratio de ocupación (Caracteristicas 6-13)
                    end
                end

                MatrizPatrones(:,muestra,imagen+1) = x; %almaceno patron de caracteristicas
            end
        end
    end
end

%% REPRESENTACIÓN CARACTERÍSTICAS
%%
close all;

ndig=1:1:1800;
figure()
hold on
for caract=1:13
    c=MatrizPatrones(caract,:,1);
    for n=2:10
        c=[c,MatrizPatrones(caract,:,n)];
    end
    subplot(4,4,caract)
    hold on
    plot(c,ndig,'.')
    for dig=0:10
        plot([0 1],[dig*180 dig*180])
    end
    title(strcat('Caracteristica ',num2str(caract)))
    xlabel('Área Ocupada [%]')
    ylabel('Clases Dígitos')
    hold off
hold off
end


%% ENTRENAMIENTO

Nclases=10;
Nmuestras=20*9;
Ncaract=3;
MatrizPatronesClas=MatrizPatrones([6,8,10],:,:); %MEJOR OPCION

prototipos = cell(1,Nclases);
distancias = zeros(1,Nclases);

%Cálculo de prototipos como valores medios (centroides) de cada clase:
for clase=1:Nclases
    suma = zeros(1,Ncaract);
    % prototipos(:,clase) = mean(MatrizPatronesClas(:,:,clase);
    for muestra=1:Nmuestras
        x = MatrizPatronesClas(:,muestra,clase)'; %Patrón
        suma = suma + x;
    end
    prototipos{clase} = suma/Nmuestras;
end

%% REPRESENTACIÓN CARACTERÍSTICAS USADAS
%%
figure()
hold on
for n=1:10
    c6=MatrizPatrones(6,:,n);
    c8=MatrizPatrones(8,:,n);
    c10=MatrizPatrones(10,:,n);
    view([130 30])
    plot3(c6,c8,c10,'.')
    plot3(prototipos{n}(1),prototipos{n}(2),prototipos{n}(3),'gx','MarkerSize',20,'LineWidth',5);
    text(prototipos{n}(1),prototipos{n}(2),prototipos{n}(3),num2str(n-1),"FontSize",20)
end
title('Caracteristicas C6, C8 y C10')
xlabel('Área Ocupada [C6]')
ylabel('Área Ocupada [C8]')
zlabel('Área Ocupada [C10]')
grid on
grid minor
hold off

%% CLASIFICADOR MÍNIMA DISTANCIA

% Cálculo las distancias del patrón a cada prototipo:
acierto = zeros(1,Nclases);
for imagen=1:Nclases
    for muestra=1:Nmuestras
        x=MatrizPatronesClas(:,muestra,imagen)'; %Patrón

        %Cálculo de las distancias del patrón a cada prototipo de cada clase
        for clase = 1:Nclases
            z = prototipos{clase};
            distancias(clase) = norm (z-x);
        end

        %Búsqueda de mínima distancia
        [minDist,claseRes] = min(distancias);

        if(claseRes==imagen)
            acierto(imagen) = acierto(imagen)+1;
        end
    end
end
tasaAcierto = acierto/Nmuestras;
disp("La tasa de acierto es de: "); tasaAcierto