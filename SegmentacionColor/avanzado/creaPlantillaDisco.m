function plantilla = creaPlantillaDisco(radio)
tamPlantilla = 2*radio+1;
plantilla = zeros(tamPlantilla,tamPlantilla);
for i=1:tamPlantilla
    for j=1:tamPlantilla
        if(sqrt((i-(radio+1))^2+(j-(radio+1))^2)<=radio)
            plantilla(i,j)=1;
        else
            plantilla(i,j)=0;
        end
    end
end
end