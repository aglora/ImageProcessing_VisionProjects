function [out] = regionpropsManual(Plantilla)
%Función regionprops() desarrollada manualmente

[M,N] = size(Plantilla);
PlantillaEtiq = bwlabel(Plantilla);

%Areas y Centroids
Areas=zeros(max(max(PlantillaEtiq)),1);
Centroids=zeros(max(max(PlantillaEtiq)),2);
BoundingBox=zeros(max(max(PlantillaEtiq)),4);
BoundingBox(:,1)=ones(max(max(PlantillaEtiq)),1)*N; %Inicializo valor máximo
BoundingBox(:,2)=ones(max(max(PlantillaEtiq)),1)*M; %Inicializo valor máximo

for k=1:max(max(PlantillaEtiq))
    for y=1:M
        for x=1:N
            if(PlantillaEtiq(y,x)==k)
                Areas(k)=Areas(k)+1; % Areas
                Centroids(k,1)=Centroids(k,1)+x;
                Centroids(k,2)=Centroids(k,2)+y;
                %Xmin
                if(x<BoundingBox(k,1))
                    BoundingBox(k,1)=x; %Xmin Bbox
                end
                %Ymin
                if(y<BoundingBox(k,2))
                    BoundingBox(k,2)=y; %Ymin Bbox
                end
                %Xmax
                if(x>BoundingBox(k,3))
                    BoundingBox(k,3)=x;
                end
                %Ymax
                if(y>BoundingBox(k,4))
                    BoundingBox(k,4)=y;
                end
            end
        end
    end
    Centroids(k,1)=Centroids(k,1)/Areas(k); % Posicion X Centros
    Centroids(k,2)=Centroids(k,2)/Areas(k); % Posicion Y Centros
    BoundingBox(k,3)=BoundingBox(k,3)-BoundingBox(k,1)+1; %Ancho Bbox
    BoundingBox(k,4)=BoundingBox(k,4)-BoundingBox(k,2)+1; %Alto Bbox
end

out.BoundingBox=BoundingBox;
out.Centroid=Centroids;
out.Area=Areas;

end


