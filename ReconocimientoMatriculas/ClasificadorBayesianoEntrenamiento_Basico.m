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

%% SELECCIÓN DE CARACTERÍSTICAS
%%
for prueba=1:13

Nclases=10;
Nmuestras=20*9;
Ncaract=1; 
MatrizPatronesClas=MatrizPatrones(prueba,:,:);

%Probabilidades de cada clase
pC=1/Nclases; %Clases equiprobables = 10%

%Cálculo de media y matrices de covarianza de caracteristicas de cada clase
Mu=zeros(Ncaract,Nclases); %Filas: medias de caracteristicas | Columnas: Clases
V=zeros(Ncaract,Ncaract,Nclases); %Filas y Columnas: Varianza entre caracteristicas | Capas:Clases

for clase=1:Nclases
    Mu(:,clase)=mean(MatrizPatronesClas(:,:,clase)')';
    for muestra=1:Nmuestras
        x=MatrizPatronesClas(:,muestra,clase);
        V(:,:,clase)=V(:,:,clase)+(x-Mu(:,clase))*(x-Mu(:,clase))';
    end
    V(:,:,clase)=V(:,:,clase)/Nmuestras;
end

% Término de función de decisión independiente del patrón e Inversas de matrices de covarianza
F=zeros(1,clase);
Vinv=zeros(Ncaract,Ncaract,Nclases);
for clase=1:Nclases
    F(clase)= log(pC) - 1/2 * log(det(V(:,:,clase)));
    Vinv(:,:,clase)=inv(V(:,:,clase));
end

%Clasificacion de patrones conocidos
fd=zeros(1,Nclases);
acierto=zeros(1,Nclases);
for capas=1:Nclases
    for muestra=1:Nmuestras
        x=MatrizPatronesClas(:,muestra,capas);
        
        for clase=1:Nclases
        % Distancia de Mahalanobis
        rCuad = (x-Mu(:,clase))' * Vinv(:,:,clase) * (x-Mu(:,clase));
        
        % Cálculo de las funciones de decisión:
        fd(clase) = -1/2 * rCuad + F(clase);

        end

        [fdMax, claseRes] = max(fd);

        if(claseRes==capas) %Clasificación correcta
            acierto(capas)=acierto(capas)+1;
        end
    end
end

porcAcierto=(acierto/Nmuestras)*100;

%Ver que caracteristicas son mejores
pruebaAcierto(:,prueba)=porcAcierto;
sumaAcierto(prueba)=sum(pruebaAcierto(:,prueba));

end

disp('Elección de características: '); sumaAcierto


%% CLASIFICADOR BAYESIANO

Nclases=10;
Nmuestras=20*9;
Ncaract=2; 
MatrizPatronesClas=MatrizPatrones([6,8],:,:); %MEJOR OPCION

%Probabilidades de cada clase
pC=1/Nclases; %Clases equiprobables = 10%

%Cálculo de media y matrices de covarianza de caracteristicas de cada clase
Mu=zeros(Ncaract,Nclases); %Filas: medias de caracteristicas | Columnas: Clases
V=zeros(Ncaract,Ncaract,Nclases); %Filas y Columnas: Varianza entre caracteristicas | Capas:Clases

for clase=1:Nclases
    Mu(:,clase)=mean(MatrizPatronesClas(:,:,clase)')';
    for muestra=1:Nmuestras
        x=MatrizPatronesClas(:,muestra,clase);
        V(:,:,clase)=V(:,:,clase)+(x-Mu(:,clase))*(x-Mu(:,clase))';
    end
    V(:,:,clase)=V(:,:,clase)/Nmuestras;
end

% Término de función de decisión independiente del patrón e Inversas de matrices de covarianza
F=zeros(1,clase);
Vinv=zeros(Ncaract,Ncaract,Nclases);
for clase=1:Nclases
    F(clase)= log(pC) - 1/2 * log(det(V(:,:,clase)));
    Vinv(:,:,clase)=inv(V(:,:,clase));
end

%Clasificacion de patrones conocidos
fd=zeros(1,Nclases);
acierto=zeros(1,Nclases);
for capas=1:Nclases
    for muestra=1:Nmuestras
        x=MatrizPatronesClas(:,muestra,capas);
        
        for clase=1:Nclases
        % Distancia de Mahalanobis
        rCuad = (x-Mu(:,clase))' * Vinv(:,:,clase) * (x-Mu(:,clase));
        
        % Cálculo de las funciones de decisión:
        fd(clase) = -1/2 * rCuad + F(clase);

        end

        [fdMax, claseRes] = max(fd);

        if(claseRes==capas) %Clasificación correcta
            acierto(capas)=acierto(capas)+1;
        end
    end
end

disp('El porcentaje de acierto para cada clase con c6 y c8:')
porcAcierto=(acierto/Nmuestras)*100

%% REPRESENTACIÓN CARACTERÍSTICAS USADAS
%%
figure()
hold on
for n=1:10
    c6=MatrizPatrones(6,:,n);
    c8=MatrizPatrones(8,:,n);
    plot(c6,c8,'.')
    text(Mu(1,n),Mu(2,n),num2str(n-1),"FontSize",20)
end
title('Caracteristicas C6 y C8 ')
xlabel('Área Ocupada [C6]')
ylabel('Área Ocupada [C8]')
grid on
grid minor
hold off

















