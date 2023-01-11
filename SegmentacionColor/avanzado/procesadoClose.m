function  processedImage = procesadoClose(originalImage,plantilla)
   processedImage = procesadoDilatado(originalImage,plantilla);
   processedImage = procesadoErosion(processedImage,plantilla);
end