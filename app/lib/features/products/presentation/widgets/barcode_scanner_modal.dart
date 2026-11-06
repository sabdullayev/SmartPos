import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerModal extends StatefulWidget {
  final Function(String barcode) onScanned;

  const BarcodeScannerModal({super.key, required this.onScanned});

  static Future<String?> show(BuildContext context) async {
    String? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarcodeScannerModal(
        onScanned: (barcode) {
          result = barcode;
          Navigator.of(ctx).pop();
        },
      ),
    );
    return result;
  }

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal> {
  final TextEditingController _manualController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isManualMode = defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        widget.onScanned(barcode.rawValue!);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Text(
                      'Сканирование штрихкода',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Switch between camera & manual input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Камера'),
                  icon: Icon(Icons.camera_alt_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Ввод / Сканер'),
                  icon: Icon(Icons.keyboard_outlined),
                ),
              ],
              selected: {_isManualMode},
              onSelectionChanged: (val) {
                setState(() {
                  _isManualMode = val.first;
                });
              },
            ),
          ),

          // Content area
          Expanded(
            child: _isManualMode ? _buildManualInput(theme) : _buildCameraScanner(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraScanner(ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          errorBuilder: (context, error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Камера недоступна или нет разрешения',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isManualMode = true;
                        });
                      },
                      child: const Text('Перейти на ручной ввод'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Scanner overlay viewfinder
        Container(
          width: 260,
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF14B8A6), width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  Widget _buildManualInput(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Введите штрихкод вручную или отсканируйте подключенным USB-сканером:',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manualController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Штрихкод',
              hintText: 'например, 478001001001',
              prefixIcon: Icon(Icons.barcode_reader),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                widget.onScanned(value.trim());
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              final text = _manualController.text.trim();
              if (text.isNotEmpty) {
                widget.onScanned(text);
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Применить штрихкод'),
          ),
        ],
      ),
    );
  }
}
