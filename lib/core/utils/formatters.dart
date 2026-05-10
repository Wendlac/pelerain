import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String price(double amount) {
    final f = NumberFormat('#,###', 'fr_FR');
    return '${f.format(amount)} FCFA';
  }

  static String time(DateTime dt) => DateFormat('HH:mm').format(dt);

  static String date(DateTime dt) => DateFormat('EEE d MMM', 'fr_FR').format(dt);

  static String dateShort(DateTime dt) => DateFormat('d MMM', 'fr_FR').format(dt);

  static String dateLong(DateTime dt) => DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(dt);
}
