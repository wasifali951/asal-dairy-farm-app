import 'package:flutter/material.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/printer_service.dart';

class PrinterPairingScreen extends StatefulWidget {
  final PrinterService printerService;

  const PrinterPairingScreen({super.key, required this.printerService});

  @override
  State<PrinterPairingScreen> createState() => _PrinterPairingScreenState();
}

class _PrinterPairingScreenState extends State<PrinterPairingScreen> {
  List<PrinterBluetooth> _printers = [];
  bool _scanning = false;
  PrinterBluetooth? _selectedPrinter;

  Future<void> _requestPermissionsAndScan() async {
    // Required on Android 12+ (API 31+)
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // some devices still need this for BT scan
    ].request();

    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _printers = [];
    });

    widget.printerService.printerManager.scanResults.listen((results) {
      setState(() => _printers = results);
    });

    widget.printerService.printerManager.startScan(const Duration(seconds: 4));

    setState(() => _scanning = false);
  }

  void _selectPrinter(PrinterBluetooth printer) {
    widget.printerService.selectPrinter(printer);
    setState(() => _selectedPrinter = printer);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected ${printer.name}')),
    );
  }

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Thermal Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scanning ? null : _startScan,
          ),
        ],
      ),
      body: _scanning
          ? const Center(child: CircularProgressIndicator())
          : _printers.isEmpty
              ? const Center(
                  child: Text(
                      'No printers found. Make sure Bluetooth is on and printer is paired in phone settings.'))
              : ListView.builder(
                  itemCount: _printers.length,
                  itemBuilder: (context, index) {
                    final printer = _printers[index];
                    final isSelected =
                        _selectedPrinter?.address == printer.address;
                    return ListTile(
                      leading: Icon(
                        Icons.print,
                        color: isSelected ? Colors.green : null,
                      ),
                      title: Text(printer.name ?? 'Unknown Printer'),
                      subtitle: Text(printer.address ?? ''),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () => _selectPrinter(printer),
                    );
                  },
                ),
    );
  }
}
