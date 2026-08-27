import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

import '../models/cart_item.dart';

class PrinterService {
  final PrinterBluetoothManager printerManager = PrinterBluetoothManager();

  void selectPrinter(PrinterBluetooth printer) {
    printerManager.selectPrinter(printer);
  }

  Future<PosPrintResult> printReceipt(
      List<CartItem> items, double total) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    bytes.addAll(
      generator.text(
        'Asal Dairy',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(generator.hr());

    for (final item in items) {
      bytes.addAll(
        generator.row(
          [
            PosColumn(text: item.name, width: 6),
            PosColumn(text: item.qty.toString(), width: 2),
            PosColumn(
              text: item.price.toStringAsFixed(2),
              width: 4,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ],
        ),
      );
    }

    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.text(
        'Total: Rs ${total.toStringAsFixed(2)}',
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    );
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return printerManager.printTicket(bytes);
  }
}
