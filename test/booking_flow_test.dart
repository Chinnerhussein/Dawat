import 'package:dawat/data/demo/demo_backend.dart';
import 'package:dawat/data/models/app_user.dart';
import 'package:dawat/data/models/booking.dart';
import 'package:dawat/data/models/notification.dart';
import 'package:dawat/data/models/service.dart';
import 'package:dawat/data/repositories/repositories.dart';
import 'package:dawat/logic/booking_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoBackend db;
  late BookingActions actions;
  late Couple shno;
  late Couple dilan;
  late Service henna;

  setUp(() {
    db = DemoBackend();
    actions = BookingActions(db);
    shno = db.users['u_shno']! as Couple;
    dilan = db.users['u_dilan']! as Couple;
    henna = db.services['s_memo_henna']!;
  });

  DateTime day(int d) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).add(Duration(days: d));
  }

  test('a couple can request a free date and the provider is notified', () async {
    final b = await actions.requestBooking(couple: shno, service: henna, date: day(50));
    expect(b.status, BookingStatus.pending);
    expect(b.amount, henna.price);
    final inbox = await db.watchNotifications(henna.providerId).first;
    expect(inbox.first.type, NotificationType.bookingRequested);
    expect(inbox.first.params['couple'], 'Shno & Aram');
  });

  test('blocked dates cannot be requested', () async {
    final hall = db.services['s_lalav_hall']!;
    expect(
      () => actions.requestBooking(couple: dilan, service: hall, date: hall.blockedDates.first),
      throwsA(isA<AppException>()),
    );
  });

  test('per-person prices need a guest count and multiply by it', () async {
    final buffet = db.services['s_zhin_buffet']!;
    expect(() => actions.requestBooking(couple: dilan, service: buffet, date: day(60)), throwsA(isA<AppException>()));
    final b = await actions.requestBooking(couple: dilan, service: buffet, date: day(60), guestCount: 200);
    expect(b.amount, buffet.price * 200);
  });

  test('accepting blocks the date and declines competing requests', () async {
    final a = await actions.requestBooking(couple: shno, service: henna, date: day(50));
    final b = await actions.requestBooking(couple: dilan, service: henna, date: day(50));

    await actions.respond(a, accept: true);

    final service = await db.getService(henna.id);
    expect(service!.checkAvailability(day(50)), isFalse);
    expect(db.bookings[a.id]!.status, BookingStatus.accepted);
    expect(db.bookings[b.id]!.status, BookingStatus.declined);

    final dilanInbox = await db.watchNotifications(dilan.id).first;
    expect(dilanInbox.any((n) => n.type == NotificationType.bookingDeclined), isTrue);
  });

  test('paying a deposit then the balance records expenses', () async {
    final req = await actions.requestBooking(couple: shno, service: henna, date: day(50));
    await actions.respond(req, accept: true);
    var b = db.bookings[req.id]!;
    expect(b.canPay, isTrue);

    final before = (await db.watchExpenses(shno.id).first).length;
    b = await actions.pay(b, PaymentOption.deposit);
    expect(b.paymentStatus, PaymentStatus.depositPaid);
    expect(b.amountPaid, b.depositAmount);
    expect(() => actions.pay(b, PaymentOption.deposit), throwsA(isA<AppException>()));

    b = await actions.pay(b, PaymentOption.balance);
    expect(b.paymentStatus, PaymentStatus.paid);
    expect(b.balanceDue, 0);
    expect(b.canPay, isFalse);

    final expenses = await db.watchExpenses(shno.id).first;
    expect(expenses.length, before + 2);
    expect(expenses.where((e) => e.bookingId == b.id).fold<double>(0, (a, e) => a + e.amount), henna.price);
  });

  test('cancelling an accepted booking opens the date again', () async {
    final req = await actions.requestBooking(couple: shno, service: henna, date: day(50));
    await actions.respond(req, accept: true);
    await actions.cancel(db.bookings[req.id]!);
    expect(db.bookings[req.id]!.status, BookingStatus.cancelled);
    expect((await db.getService(henna.id))!.checkAvailability(day(50)), isTrue);
  });

  test('suspended users cannot sign in', () async {
    await db.setUserActive(shno.id, false);
    expect(() => db.signIn(shno.email, 'demo1234'), throwsA(isA<AppException>()));
  });

  test('wrong password is rejected', () async {
    expect(() => db.signIn(shno.email, 'nope'), throwsA(isA<AppException>()));
  });

  test('approving a provider notifies them', () async {
    final rozh = db.users['p_rozh']! as ServiceProvider;
    await actions.setProviderApproval(rozh, ApprovalStatus.approved);
    expect((db.users['p_rozh']! as ServiceProvider).approval, ApprovalStatus.approved);
    final inbox = await db.watchNotifications(rozh.id).first;
    expect(inbox.single.type, NotificationType.providerApproved);
  });

  test('reminders are created once for tasks due within a week', () async {
    await createDueReminders(db, shno);
    final first = (await db.watchNotifications(shno.id).first).where((n) => n.type == NotificationType.reminder).length;
    await createDueReminders(db, shno);
    final second = (await db.watchNotifications(shno.id).first)
        .where((n) => n.type == NotificationType.reminder)
        .length;
    expect(first, greaterThan(0));
    expect(second, first);
  });
}
