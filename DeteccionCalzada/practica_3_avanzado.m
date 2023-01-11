clear; clc; close all;
%% PRÁCTICA 3 AVANZADO:  SEGMENTACIÓN DE CALZADA EN IMAGEN AÉREA
%%

for fotograma = 260:790 %Leer y procesar de la misma manera los distintos fotogramas para probar robustez del algoritmo ante distintas situaciones
    str_fotograma = num2str(fotograma);
    str_path = strcat('secuenciaBicicleta\000',str_fotograma,'.jpg');
    fileImageRGB = imread(str_path);

    %% REDUCCIÓN DE TAMAÑO DE IMAGEN
    %%
    fileImageRGB = imresize(fileImageRGB,0.3); %reducir tamaño de imagen a 1/3
    figure(1);
    hold on
    subplot(3,2,1)
    imshow(fileImageRGB);
    title(str_fotograma);

    %% PREPROCESADO
    %%
    umbralThreshold = [0.106 0.217 0.465; %fila: 1-Mínimo 2-Máximo | columna: 1-Hue 2-Saturation 3-Value
        0.221 1.000 1.000];

    [M,N,C] = size(fileImageRGB);

    fileImage = rgb2hsv(fileImageRGB);
    HueImage  = fileImage(:,:,1);
    SatImage = fileImage(:,:,2);
    ValImage  = fileImage(:,:,3);


    %% BINARIZACIÓN POR UMBRALES
    % Creamos plantilla binarizada a partir de umbrales obtenidos con Color
    % Thresholder
    %%
    if(umbralThreshold(1,1)<umbralThreshold(2,1))
        binHueImage = (umbralThreshold(1,1)<=HueImage & HueImage<=umbralThreshold(2,1));
    else
        binHueImage = (umbralThreshold(1,1)<=HueImage | HueImage<=umbralThreshold(2,1));
    end
    binSatImage = (umbralThreshold(1,2)<=SatImage & SatImage<=umbralThreshold(2,2));
    binValImage = (umbralThreshold(1,3)<=ValImage & ValImage<=umbralThreshold(2,3));
    binImage = binHueImage & binSatImage & binValImage;
    subplot(3,2,2); imshow(binImage,[]);
    subplot(3,2,4); imshow(binImage,[]);
    subplot(3,2,3); imshow(binImage,[]);

    %% TRANSFORMADA DE HOUGH
    %%
    [M_votes,tabTheta,tabRho] = hough(binImage);
    peaks = houghpeaks(M_votes,2,"NHoodSize",[21 21]);
    rho = tabRho(peaks(:,1));
    theta = tabTheta(peaks(:,2));

    for k=1:length(theta)
        if(theta(k)<0) %theta  pertenece a [-90,90) pero nos interesa de
            % [0,180) por las funciones de discretización usadas
            % posteriormente que utilizaran theta y rho
            theta(k) = theta(k)+180;
            rho(k) = -rho(k);
        end
    end

    %Definir en el primer fotograma color de las líneas guardando su valor
    %inicialmente como valor anterior en la secuencia de fotogramas
    if(fotograma==260)
        thetaG_ant=theta(1);
        thetaR_ant=theta(2);
        rhoG_ant=rho(1);
        rhoR_ant=rho(2);
    end

    %Comprobar línea correspodiente mediante parecido en parámetros
    %característicos (theta y rho)
    %inicializar rho y theta de las rectas del fotograma a -1 para marcar
    %cuando no han sido localizadas
    rhoRectasFotograma=-ones(1,length(rho));
    thetaRectasFotograma=-ones(1,length(rho));
    for k=1:length(rho)
        if( abs(rho(k)-rhoG_ant)<20 && abs(theta(k)-thetaG_ant)<10 ) %verde
            rhoRectasFotograma(1)=rho(k);
            thetaRectasFotograma(1)=theta(k);
            rhoG_ant=rhoRectasFotograma(1);
            thetaG_ant=thetaRectasFotograma(1);
        elseif( abs(rho(k)-rhoR_ant)<20 && abs(theta(k)-thetaR_ant)<10 ) %rojo
            rhoRectasFotograma(2)=rho(k);
            thetaRectasFotograma(2)=theta(k);
            rhoR_ant=rhoRectasFotograma(2);
            thetaR_ant=thetaRectasFotograma(2);
        end
    end

    %calcular puntos de intersección con bordes
    %Orden cálculo intersecciones: recta HorizontalSuperior(HS), VerticalDerecha(VD)
    % , HorizontalIzuquierda(HI), VerticalIzquierda(VI)
    rhoMarco = [0,N,M,0];
    thetaMarco = [90,0,90,0];
    x=-ones(2,length(rhoRectasFotograma));y=-ones(2,length(rhoRectasFotograma));
    for k=1:length(rhoRectasFotograma)

        if(thetaRectasFotograma(k)<0) %en caso de detección de línea roja
            % o verde fallida, se obtienen otra vez picos de Hough pero
            % esta vez cogiendo 3 con un área de vecindad menor
            peaks = houghpeaks(M_votes,3,"NHoodSize",[9 9]);
            rho = tabRho(peaks(3,1));
            theta = tabTheta(peaks(3,2));
            if(theta<0)
                theta=theta+180;
                rho=-rho;
            end
            rhoRectasFotograma(k)= rho;
            thetaRectasFotograma(k)= theta;
            if(k==1) %si la fallida era la verde, actualizar esta
                rhoG_ant = rhoRectasFotograma(k);
                thetaG_ant = thetaRectasFotograma(k);
            elseif(k==2) %si la fallida era la roja, actualizar esta
                rhoR_ant = rhoRectasFotograma(k);
                thetaR_ant = thetaRectasFotograma(k);
            end
        end

        a=1;
        for i=1:4
            xIntersec=round((rhoRectasFotograma(k)*sind(thetaMarco(i))-rhoMarco(i)*sind(thetaRectasFotograma(k)))/(cosd(thetaRectasFotograma(k))*sind(thetaMarco(i))-sind(thetaRectasFotograma(k))*cosd(thetaMarco(i))),2);
            yIntersec=round((rhoMarco(i)*cosd(thetaRectasFotograma(k))-rhoRectasFotograma(k)*cosd(thetaMarco(i)))/(cosd(thetaRectasFotograma(k))*sind(thetaMarco(i))-sind(thetaRectasFotograma(k))*cosd(thetaMarco(i))),2);
            if(xIntersec>=0 && yIntersec>=0 && xIntersec<=N && yIntersec<=M)
                if( ~max(x(:,k)==xIntersec & y(:,k)==yIntersec) ) % comprobar que
                    % la intersección no sea la previamente calculada ya que en los
                    % vértices la intersección es doble con los marcos de la imagen
                    x(a,k)=xIntersec;
                    y(a,k)=yIntersec;
                    a=a+1;
                end
            end
        end

        %pintar líneas en imagen binarizada de color azul cyan
        subplot(3,2,3)
        line([x(1,k),x(2,k)],[y(1,k),y(2,k)],'Color','c','LineWidth',5);

        %pintar líneas en imagen binarizada marcadas con su propio
        %color invariante a lo largo de los fotogramas
        subplot(3,2,4)
        switch k
            case 1 %Verde (línea interior de carretera)
                line([x(1,k),x(2,k)],[y(1,k),y(2,k)],'Color','g','LineWidth',5);
            case 2 %Rojo (línea exterior de carretera)
                line([x(1,k),x(2,k)],[y(1,k),y(2,k)],'Color','r','LineWidth',5);
        end
    end




    %% EXTRACCIÓN DE REGIONES
    %%
    if(rhoRectasFotograma(1))
        w1_ = [cosd(thetaRectasFotograma(1)) sind(thetaRectasFotograma(1)) -rhoRectasFotograma(1)]';
        w2_ = -[cosd(thetaRectasFotograma(2)) sind(thetaRectasFotograma(2)) -rhoRectasFotograma(2)]';
        processedImage = uint8(zeros(M,N));
        for y1=1:M
            for x1=1:N
                x_ = [x1 y1 1]';
                fd1 = w1_'*x_; %función de discriminación 1 (línea verde)
                fd2 = w2_'*x_; %función de discriminación 2 (línea roja)
                if(fd1>0 && fd2>0) %si la región es la definida entre las 2 rectas pongo a 1 ese bit de la máscara
                    processedImage(y1,x1) = 1;
                else %caso contrario, se deja a 0
                    processedImage(y1,x1) = 0;
                end
            end
        end
        subplot(3,2,6); imshow(processedImage.*rgb2gray(fileImageRGB),[]);
        subplot(3,2,5); imshow(processedImage,[]);
        hold off
    end
end
return;