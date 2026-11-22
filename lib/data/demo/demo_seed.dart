// Sample data for demo mode. Names and businesses are fictional.

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/notification.dart';
import '../models/planner.dart';
import '../models/service.dart';
import 'demo_backend.dart';

/// Demo sign-in accounts, shown on the welcome screen in demo mode.
class DemoAccounts {
  static const couple = ('shno@dawat.app', 'demo1234');
  static const provider = ('lalav@dawat.app', 'demo1234');
  static const admin = ('admin@dawat.app', 'demo1234');
}

class DemoSeed {
  static void apply(DemoBackend db) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime inDays(int d) => today.add(Duration(days: d));
    final wedding = inDays(84);

    // ---------------------------------------------------------- Accounts
    void addUser(AppUser u, String password) {
      db.users[u.id] = u;
      db.passwords[u.email] = password;
    }

    addUser(
      Couple(
        id: 'u_shno',
        name: 'Shno Karim',
        partnerName: 'Aram Ali',
        email: DemoAccounts.couple.$1,
        phone: '+964 750 123 4567',
        city: 'erbil',
        weddingDate: wedding,
        totalBudget: 25000,
        createdAt: inDays(-40),
      ),
      DemoAccounts.couple.$2,
    );
    addUser(
      Couple(
        id: 'u_dilan',
        name: 'Dilan Omar',
        partnerName: 'Karwan Aziz',
        email: 'dilan@dawat.app',
        city: 'duhok',
        weddingDate: inDays(120),
        totalBudget: 18000,
        createdAt: inDays(-12),
      ),
      'demo1234',
    );
    addUser(
      Admin(id: 'u_admin', name: 'Dawat Admin', email: DemoAccounts.admin.$1, createdAt: inDays(-200)),
      DemoAccounts.admin.$2,
    );

    final providers = <ServiceProvider>[
      ServiceProvider(
        id: 'p_lalav',
        name: 'Hemin Rasul',
        businessName: 'Lalav Hall',
        email: DemoAccounts.provider.$1,
        phone: '+964 750 222 1100',
        city: 'erbil',
        rating: 4.8,
        ratingCount: 120,
        approval: ApprovalStatus.approved,
        bio: 'Wedding hall and garden terrace on 100m Road, serving Erbil since 2012.',
        createdAt: inDays(-180),
      ),
      ServiceProvider(
        id: 'p_zhin',
        name: 'Zhin Hassan',
        businessName: 'Zhin Catering',
        email: 'zhin@dawat.app',
        city: 'duhok',
        rating: 4.8,
        ratingCount: 98,
        approval: ApprovalStatus.approved,
        createdAt: inDays(-160),
      ),
      ServiceProvider(
        id: 'p_memo',
        name: 'Mahmood Salih',
        businessName: 'Memo Studio',
        email: 'memo@dawat.app',
        city: 'erbil',
        rating: 4.9,
        ratingCount: 156,
        approval: ApprovalStatus.approved,
        createdAt: inDays(-150),
      ),
      ServiceProvider(
        id: 'p_gul',
        name: 'Gulala Ahmed',
        businessName: 'Gul Decor',
        email: 'gul@dawat.app',
        city: 'sulaymaniyah',
        rating: 4.7,
        ratingCount: 64,
        approval: ApprovalStatus.approved,
        createdAt: inDays(-140),
      ),
      ServiceProvider(
        id: 'p_awaz',
        name: 'Awaz Jamal',
        businessName: 'Awaz Band',
        email: 'awaz@dawat.app',
        city: 'erbil',
        rating: 4.6,
        ratingCount: 41,
        approval: ApprovalStatus.approved,
        createdAt: inDays(-130),
      ),
      ServiceProvider(
        id: 'p_nishtiman',
        name: 'Nishtiman Faraj',
        businessName: 'Nishtiman Bridal',
        email: 'nishtiman@dawat.app',
        city: 'sulaymaniyah',
        rating: 4.8,
        ratingCount: 77,
        approval: ApprovalStatus.approved,
        createdAt: inDays(-120),
      ),
      ServiceProvider(
        id: 'p_glow',
        name: 'Shilan Kamal',
        businessName: 'Glow Salon',
        email: 'glow@dawat.app',
        city: 'duhok',
        rating: 4.5,
        ratingCount: 52,
        approval: ApprovalStatus.approved,
        createdAt: inDays(-100),
      ),
      ServiceProvider(
        id: 'p_royal',
        name: 'Rebwar Sami',
        businessName: 'Royal Wedding Cars',
        email: 'royal@dawat.app',
        city: 'erbil',
        rating: 4.4,
        ratingCount: 23,
        approval: ApprovalStatus.approved,
        createdAt: inDays(-90),
      ),
      ServiceProvider(
        id: 'p_rozh',
        name: 'Rozh Anwar',
        businessName: 'Rozh Photography',
        email: 'rozh@dawat.app',
        city: 'zakho',
        approval: ApprovalStatus.pending,
        createdAt: inDays(-2),
      ),
      ServiceProvider(
        id: 'p_shar',
        name: 'Sharo Mustafa',
        businessName: 'Shar Palace',
        email: 'shar@dawat.app',
        city: 'sulaymaniyah',
        approval: ApprovalStatus.pending,
        createdAt: inDays(-1),
      ),
    ];
    for (final p in providers) {
      addUser(p, 'demo1234');
    }

    // ---------------------------------------------------------- Services
    void addService(Service s) => db.services[s.id] = s;

    addService(
      Service(
        id: 's_lalav_hall',
        providerId: 'p_lalav',
        providerName: 'Lalav Hall',
        title: 'Lalav Grand Hall',
        category: ServiceCategory.hall,
        price: 3500,
        city: 'erbil',
        capacity: 600,
        rating: 4.8,
        ratingCount: 120,
        description: 'Main ballroom for up to 600 guests, with stage, dance floor, bridal room and valet parking. Price covers the hall from 6 pm to midnight.',
        blockedDates: [inDays(5), inDays(12), inDays(13), inDays(26), wedding, inDays(98)],
      ),
    );
    addService(
      Service(
        id: 's_lalav_garden',
        providerId: 'p_lalav',
        providerName: 'Lalav Hall',
        title: 'Lalav Garden Terrace',
        category: ServiceCategory.hall,
        price: 2200,
        city: 'erbil',
        capacity: 250,
        rating: 4.7,
        ratingCount: 38,
        description: 'Open-air terrace for henna nights and smaller weddings, with string lights and a covered area in case of rain.',
        blockedDates: [inDays(7), inDays(21)],
      ),
    );
    addService(
      Service(
        id: 's_zhin_buffet',
        providerId: 'p_zhin',
        providerName: 'Zhin Catering',
        title: 'Kurdish Wedding Buffet',
        category: ServiceCategory.catering,
        price: 18,
        priceUnit: PriceUnit.perPerson,
        city: 'duhok',
        rating: 4.8,
        ratingCount: 98,
        description:
            'Dolma, kubba, quzi with rice, kebab, salads and baklava. Minimum 150 guests. Staff and serving included.',
      ),
    );
    addService(
      Service(
        id: 's_memo_full',
        providerId: 'p_memo',
        providerName: 'Memo Studio',
        title: 'Full-Day Photo & Video',
        category: ServiceCategory.photography,
        price: 1800,
        city: 'erbil',
        rating: 4.9,
        ratingCount: 156,
        description: 'Two photographers and one videographer from the bride\'s preparation to the last dance. Edited album of 300 photos and a 5-minute film.',
        blockedDates: [inDays(12), inDays(40)],
      ),
    );
    addService(
      Service(
        id: 's_memo_henna',
        providerId: 'p_memo',
        providerName: 'Memo Studio',
        title: 'Henna Night Coverage',
        category: ServiceCategory.photography,
        price: 650,
        city: 'erbil',
        rating: 4.8,
        ratingCount: 44,
        description: 'Four hours of photo coverage for the henna night, 120 edited photos.',
      ),
    );
    addService(
      Service(
        id: 's_gul_stage',
        providerId: 'p_gul',
        providerName: 'Gul Decor',
        title: 'Stage & Flower Decoration',
        category: ServiceCategory.decoration,
        price: 2000,
        city: 'sulaymaniyah',
        rating: 4.7,
        ratingCount: 64,
        description: 'Bride and groom stage, fresh flower arch, table centrepieces and entrance decoration.',
      ),
    );
    addService(
      Service(
        id: 's_awaz_band',
        providerId: 'p_awaz',
        providerName: 'Awaz Band',
        title: 'Live Band with Dengbêj',
        category: ServiceCategory.music,
        price: 1000,
        city: 'erbil',
        rating: 4.6,
        ratingCount: 41,
        description:
            'Five musicians with daf, zurna and keyboard, plus a singer for traditional halparke and modern songs.',
      ),
    );
    addService(
      Service(
        id: 's_nishtiman_dress',
        providerId: 'p_nishtiman',
        providerName: 'Nishtiman Bridal',
        title: 'Bridal Dress & Kurdish Jli',
        category: ServiceCategory.dress,
        price: 1500,
        city: 'sulaymaniyah',
        rating: 4.8,
        ratingCount: 77,
        description:
            'White gown rental plus a tailored Kurdish dress (jli kurdî) for the second evening. Fittings included.',
      ),
    );
    addService(
      Service(
        id: 's_glow_makeup',
        providerId: 'p_glow',
        providerName: 'Glow Salon',
        title: 'Bridal Makeup & Hair',
        category: ServiceCategory.makeup,
        price: 450,
        city: 'duhok',
        rating: 4.5,
        ratingCount: 52,
        description: 'Trial session, wedding day makeup, hair styling and touch-up kit.',
      ),
    );
    addService(
      Service(
        id: 's_royal_car',
        providerId: 'p_royal',
        providerName: 'Royal Wedding Cars',
        title: 'Decorated Wedding Car',
        category: ServiceCategory.cars,
        price: 300,
        city: 'erbil',
        rating: 4.4,
        ratingCount: 23,
        description: 'White luxury car with driver and flower decoration for the zaffa convoy.',
      ),
    );

    // ---------------------------------------------------------- Bookings
    void addBooking(Booking b) => db.bookings[b.id] = b;

    addBooking(
      Booking(
        id: 'b1',
        coupleId: 'u_shno',
        coupleName: 'Shno & Aram',
        serviceId: 's_lalav_hall',
        serviceTitle: 'Lalav Grand Hall',
        providerId: 'p_lalav',
        eventDate: wedding,
        amount: 3500,
        amountPaid: 700,
        status: BookingStatus.accepted,
        paymentStatus: PaymentStatus.depositPaid,
        guestCount: 450,
        createdAt: inDays(-30),
      ),
    );
    addBooking(
      Booking(
        id: 'b2',
        coupleId: 'u_shno',
        coupleName: 'Shno & Aram',
        serviceId: 's_memo_full',
        serviceTitle: 'Full-Day Photo & Video',
        providerId: 'p_memo',
        eventDate: wedding,
        amount: 1800,
        status: BookingStatus.pending,
        createdAt: inDays(-3),
        note: 'Can you also cover the zaffa outside the hall?',
      ),
    );
    addBooking(
      Booking(
        id: 'b3',
        coupleId: 'u_shno',
        coupleName: 'Shno & Aram',
        serviceId: 's_zhin_buffet',
        serviceTitle: 'Kurdish Wedding Buffet',
        providerId: 'p_zhin',
        eventDate: wedding,
        amount: 8100,
        guestCount: 450,
        status: BookingStatus.accepted,
        createdAt: inDays(-10),
      ),
    );
    addBooking(
      Booking(
        id: 'b4',
        coupleId: 'u_dilan',
        coupleName: 'Dilan & Karwan',
        serviceId: 's_lalav_hall',
        serviceTitle: 'Lalav Grand Hall',
        providerId: 'p_lalav',
        eventDate: inDays(120),
        amount: 3500,
        guestCount: 380,
        status: BookingStatus.pending,
        createdAt: inDays(-1),
        note: 'We would like to visit the hall first.',
      ),
    );
    addBooking(
      Booking(
        id: 'b5',
        coupleId: 'u_dilan',
        coupleName: 'Dilan & Karwan',
        serviceId: 's_lalav_garden',
        serviceTitle: 'Lalav Garden Terrace',
        providerId: 'p_lalav',
        eventDate: inDays(116),
        amount: 2200,
        guestCount: 150,
        status: BookingStatus.pending,
        createdAt: inDays(-1),
        note: 'For our henna night.',
      ),
    );
    addBooking(
      Booking(
        id: 'b6',
        coupleId: 'u_dilan',
        coupleName: 'Dilan & Karwan',
        serviceId: 's_lalav_hall',
        serviceTitle: 'Lalav Grand Hall',
        providerId: 'p_lalav',
        eventDate: inDays(-20),
        amount: 3200,
        amountPaid: 3200,
        status: BookingStatus.completed,
        paymentStatus: PaymentStatus.paid,
        createdAt: inDays(-90),
      ),
    );

    db.wishlists['u_shno'] = {'s_gul_stage', 's_nishtiman_dress', 's_awaz_band'};

    // ---------------------------------------------------------- Planner
    var n = 0;
    String id(String p) => '${p}_${n++}';

    for (final e in [
      ('Lalav Grand Hall deposit', 700.0, ServiceCategory.hall),
      ('Engagement rings', 2400.0, ServiceCategory.other),
      ('Invitation cards (500)', 350.0, ServiceCategory.other),
      ('Henna night sweets', 220.0, ServiceCategory.catering),
      ('Groom\'s suit', 600.0, ServiceCategory.dress),
    ]) {
      final i = id('e');
      db.expenses[i] = BudgetExpense(
        id: i,
        userId: 'u_shno',
        title: e.$1,
        amount: e.$2,
        category: e.$3,
        createdAt: inDays(-n * 3),
      );
    }

    for (final g in [
      ('Kawa Karim', GuestSide.bride, 4, RsvpStatus.attending, 1),
      ('Bayan Mohammed', GuestSide.bride, 2, RsvpStatus.attending, 1),
      ('Sirwan Ali', GuestSide.groom, 5, RsvpStatus.attending, 2),
      ('Nazdar Hussein', GuestSide.groom, 3, RsvpStatus.pending, null),
      ('Hawre Othman', GuestSide.groom, 2, RsvpStatus.declined, null),
      ('Lana Rashid', GuestSide.bride, 1, RsvpStatus.attending, 3),
      ('Dara Fatah', GuestSide.both, 4, RsvpStatus.pending, null),
      ('Chiman Saeed', GuestSide.bride, 6, RsvpStatus.attending, 2),
      ('Rebin Qadir', GuestSide.groom, 2, RsvpStatus.pending, null),
      ('Avin Jalal', GuestSide.bride, 3, RsvpStatus.attending, 3),
      ('Soran Ibrahim', GuestSide.groom, 4, RsvpStatus.attending, 4),
      ('Tara Abdullah', GuestSide.both, 2, RsvpStatus.declined, null),
    ]) {
      final i = id('g');
      db.guests[i] = Guest(
        id: i,
        userId: 'u_shno',
        fullName: g.$1,
        side: g.$2,
        partySize: g.$3,
        rsvpStatus: g.$4,
        tableNo: g.$5,
      );
    }

    for (final t in [
      ('Set the wedding date', TaskPhase.planning, -60, true),
      ('Agree on the total budget', TaskPhase.planning, -55, true),
      ('Book the wedding hall', TaskPhase.vendors, -30, true),
      ('Choose the caterer', TaskPhase.vendors, -10, true),
      ('Hire a photographer', TaskPhase.vendors, 6, false),
      ('Book the band', TaskPhase.vendors, 14, false),
      ('Choose the bridal dress and jli kurdî', TaskPhase.ceremony, 21, false),
      ('Send invitations', TaskPhase.planning, 30, false),
      ('Book makeup and hair trial', TaskPhase.ceremony, 45, false),
      ('Plan the seating arrangement', TaskPhase.reception, 70, false),
      ('Arrange the wedding car for the zaffa', TaskPhase.ceremony, 75, false),
      ('Confirm the final guest count with the caterer', TaskPhase.reception, 77, false),
    ]) {
      final i = id('t');
      db.tasks[i] = ChecklistTask(id: i, userId: 'u_shno', title: t.$1, phase: t.$2, dueDate: inDays(t.$3), done: t.$4);
    }

    // ---------------------------------------------------- Notifications
    void notify(String user, NotificationType type, Map<String, String> params, int daysAgo, {bool read = false}) {
      final i = id('n');
      db.notifications[i] = AppNotification(
        id: i,
        userId: user,
        type: type,
        params: params,
        read: read,
        createdAt: now.subtract(Duration(days: daysAgo, hours: n)),
      );
    }

    notify('u_shno', NotificationType.reminder, {'task': 'Hire a photographer', 'date': dateKey(inDays(6))}, 0);
    notify('u_shno', NotificationType.bookingAccepted, {
      'service': 'Kurdish Wedding Buffet',
      'date': dateKey(wedding),
    }, 8);
    notify(
      'u_shno',
      NotificationType.bookingAccepted,
      {'service': 'Lalav Grand Hall', 'date': dateKey(wedding)},
      28,
      read: true,
    );
    notify('p_lalav', NotificationType.bookingRequested, {
      'service': 'Lalav Grand Hall',
      'couple': 'Dilan & Karwan',
      'date': dateKey(inDays(120)),
    }, 1);
    notify('p_lalav', NotificationType.bookingRequested, {
      'service': 'Lalav Garden Terrace',
      'couple': 'Dilan & Karwan',
      'date': dateKey(inDays(116)),
    }, 1);
    notify(
      'p_lalav',
      NotificationType.paymentReceived,
      {'service': 'Lalav Grand Hall', 'couple': 'Shno & Aram', 'amount': '700'},
      27,
      read: true,
    );
  }
}
