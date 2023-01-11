function processedImage = procesadoErosion(originalImage,plantilla)
M=size(originalImage,1);
N=size(originalImage,2);
tamM_Plantilla=size(plantilla,1);
tamN_Plantilla=size(plantilla,2);
processedImage=zeros(M,N);
for i=1:M
    for j=1:N
        minimo=originalImage(i,j);
        %bucle recorriendo entorno de vecindad con índices relativos
        for iPlantilla=1:tamM_Plantilla
            for jPlantilla=1:tamN_Plantilla
                if(plantilla(iPlantilla,jPlantilla)==1 & (i-floor(tamM_Plantilla/2)+iPlantilla-1)>0 & (i-floor(tamM_Plantilla/2)+iPlantilla-1)<=M & (j-floor(tamN_Plantilla/2)+jPlantilla-1)>0 & (j-floor(tamN_Plantilla/2)+jPlantilla-1)<=N)
                    if(originalImage(i-floor(tamM_Plantilla/2)+iPlantilla-1,j-floor(tamN_Plantilla/2)+jPlantilla-1)<minimo)
                        minimo=originalImage(i-floor(tamM_Plantilla/2)+iPlantilla-1,j-floor(tamN_Plantilla/2)+jPlantilla-1);
                    end
                end
            end
        end
        processedImage(i,j)=minimo;
    end
end
end