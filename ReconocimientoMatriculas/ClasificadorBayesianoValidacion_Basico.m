%Ejecutar previamente fichero de Entrenamiento
clc;close all;

%% PARÁMETROS DEL PROGRAMA
%%
Nimagenes=3;
aspectRatioLicensePlate = 3.45;
yNorm = 128;
xNorm = 64;
nivel = 2;

%% VARIABLES
%%
%Contador de muestras de cada dígito
muestra = 0;
matricula = 0;
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
% MatrizPatronesVal = zeros(tam,90,10);


%% OBTENCIÓN MATRIZ PATRONES
%%

for imagen = 1:Nimagenes %Utilizar cada una de las imágenes de validación
    figure(imagen)
    hold on

    str_imagen = num2str(imagen-1);
    str_path = strcat('validacion',str_imagen,'.jpg');
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

    matricula=0;

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
            binPlantilla_Rotated = imrotate(binPlantilla,-Orientation.Orientation);
            maskClose = strel('disk',10);
            frameRotated = imclose(frameRotated,maskClose);
            BoundingBox = regionprops(frameRotated,"BoundingBox");
            binPlantilla_LicensePlate = imcrop(binPlantilla_Rotated,BoundingBox.BoundingBox);

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
            matricula=matricula+1;
            %% EXTRAER DÍGITOS Y NORMALIZAR SU TAMAÑO
            %%
            muestra=0; %Reseteo de numero de muestras de cada digito
            binPlantilla_Digits_Etiq = bwlabel(binPlantilla_Digits);
            for j=1:max(max(binPlantilla_Digits_Etiq)) %Analizo cada uno de los dígitos de la matrícula
                SelectedDigit= binPlantilla_Digits_Etiq==j;
                frameDigit = regionprops(SelectedDigit,"BoundingBox");
                muestra=muestra+1;
                SelectedDigit = imcrop(SelectedDigit,frameDigit.BoundingBox);
                plantillaDigito = imresize(SelectedDigit,[yNorm xNorm]);

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

                MatrizPatronesVal(:,muestra) = x; %almaceno patron de caracteristicas
            end

            %% CLASIFICADOR BAYESIANO
            %%
            Nclases=10;
            Ncaract=2;
            MatrizPatronesClasVal=MatrizPatronesVal([6,8],:);

            %Clasificacion de patrones
            fd=zeros(1,Nclases);
            ClaseRes = zeros(1,9);

            for digitos=1:muestra
                x=MatrizPatronesClasVal(:,digitos);

                for clase=1:Nclases
                    % Distancia de Mahalanobis
                    rCuad = (x-Mu(:,clase))' * Vinv(:,:,clase) * (x-Mu(:,clase));

                    % Cálculo de las funciones de decisión:
                    fd(clase) = -1/2 * rCuad + F(clase);

                end

                [fdMax, ClaseRes(digitos)] = max(fd);
                ClaseRes(digitos) = ClaseRes(digitos)-1;

            end

            %Representacion de matricula verificación
            subplot(7,2,matricula)
            hold on
            title(strcat('Matricula :',num2str(matricula)));
            imshow(binPlantilla_LicensePlate)
            centroidInfo = regionprops(binPlantilla_Digits,"centroid");
            for digitos=1:length(centroidInfo)
                characterClaseRes = num2str(ClaseRes(digitos));
                text(centroidInfo(digitos).Centroid(1),centroidInfo(digitos).Centroid(2),characterClaseRes,"Color",[0 1 0],"FontSize",44,"HorizontalAlignment","center","VerticalAlignment","middle")
            end
            hold off
            autoArrangeFigures();
        end
    end
    hold off
end























