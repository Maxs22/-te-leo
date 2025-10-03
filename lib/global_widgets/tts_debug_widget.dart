import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/data/models/documento.dart';
import '../app/modules/document_reader/simple_document_reader_controller.dart';

/// Widget de debug único y limpio para TTS
class TTSDebugWidget extends StatelessWidget {
  final Documento documento;

  const TTSDebugWidget({
    super.key,
    required this.documento,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SimpleDocumentReaderController>(
      init: Get.put(SimpleDocumentReaderController(), permanent: false),
      initState: (state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.controller?.loadDocument(documento);
        });
      },
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Debug TTS'),
            actions: [
              IconButton(
                onPressed: controller.checkServicesStatus,
                icon: const Icon(Icons.bug_report),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Estado del timer
                Obx(() => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: controller.isUITimerActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Timer UI: ${controller.isUITimerActive ? "ACTIVO" : "INACTIVO"}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )),
                
                const SizedBox(height: 20),
                
                // Botón principal
                Obx(() => ElevatedButton(
                  onPressed: controller.togglePlayback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.isPlaying.value ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    controller.isPlaying.value ? 'PAUSAR' : 'REPRODUCIR',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )),
                
                const SizedBox(height: 30),
                
                // Variables reactivas
                Obx(() => Text('Tiempo: ${controller.formattedTime.value}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                Obx(() => Text('Progreso: ${controller.progress.value.toStringAsFixed(3)}', style: const TextStyle(fontSize: 20))),
                Obx(() => Text('Porcentaje: ${controller.formattedProgressText.value}', style: const TextStyle(fontSize: 20))),
                Obx(() => Text('Palabra: ${controller.currentWordIndexObs.value}', style: const TextStyle(fontSize: 20))),
                
                const SizedBox(height: 20),
                
                // Barra de progreso visual
                Obx(() => LinearProgressIndicator(
                  value: controller.progress.value,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                )),
                
                const SizedBox(height: 30),
                
                // Botones de control
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: controller.restartPlayback,
                      child: const Text('Reiniciar'),
                    ),
                    ElevatedButton(
                      onPressed: controller.checkServicesStatus,
                      child: const Text('Debug Log'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Información adicional
                Obx(() => Text('Estado: ${controller.isPlaying.value ? "Reproduciendo" : "Pausado"}', style: const TextStyle(fontSize: 16))),
                Obx(() => Text('Timer: ${controller.isUITimerActive ? "Activo" : "Inactivo"}', style: const TextStyle(fontSize: 16))),
              ],
            ),
          ),
        );
      },
    );
  }
}
