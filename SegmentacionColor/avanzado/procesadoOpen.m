function  processedImage = procesadoOpen(originalImage,plantilla)
   processedImage = procesadoErosion(originalImage,plantilla);
   processedImage = procesadoDilatado(processedImage,plantilla);
end