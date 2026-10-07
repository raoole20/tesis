/// Modelo de datos para turnos y opciones de transporte estudiantil.
class TransportShift {
  const TransportShift({
    required this.id,
    required this.driverName,
    required this.driverInitials,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.rating,
    required this.ratingCount,
    required this.departureTime,
    required this.arrivalTime,
    required this.returnTime,
    required this.weeklyPrice,
    required this.singleTripPrice,
    required this.availableSeats,
    required this.totalSeats,
    required this.walkingDistanceMeters,
    required this.hasAirConditioning,
    required this.isVerified,
    required this.yearsOnRoute,
    required this.activePassengersCount,
    required this.paymentCycleDescription,
    required this.stopsCount,
    required this.durationMinutes,
    required this.plateNumber,
  });

  final String id;
  final String driverName;
  final String driverInitials;
  final String vehicleModel;
  final String vehicleColor;
  final double rating;
  final int ratingCount;
  final String departureTime;
  final String arrivalTime;
  final String returnTime;
  final double weeklyPrice;
  final double singleTripPrice;
  final int availableSeats;
  final int totalSeats;
  final int walkingDistanceMeters;
  final bool hasAirConditioning;
  final bool isVerified;
  final int yearsOnRoute;
  final int activePassengersCount;
  final String paymentCycleDescription;
  final int stopsCount;
  final int durationMinutes;
  final String plateNumber;

  /// Lista de turnos de ejemplo fiel a las diapositivas de diseño (06-10).
  static const List<TransportShift> mockShifts = [
    TransportShift(
      id: 'shift-chacon',
      driverName: 'Luis Chacón',
      driverInitials: 'LC',
      vehicleModel: 'Toyota Hiace',
      vehicleColor: 'blanca',
      rating: 4.8,
      ratingCount: 23,
      departureTime: '12:10 pm',
      arrivalTime: '12:52 pm',
      returnTime: '5:15 pm',
      weeklyPrice: 5.0,
      singleTripPrice: 1.20,
      availableSeats: 4,
      totalSeats: 14,
      walkingDistanceMeters: 320,
      hasAirConditioning: true,
      isVerified: true,
      yearsOnRoute: 3,
      activePassengersCount: 11,
      paymentCycleDescription: 'cobra semanal',
      stopsCount: 6,
      durationMinutes: 42,
      plateNumber: 'AB123CD',
    ),
    TransportShift(
      id: 'shift-fuenmayor',
      driverName: 'Yorman Fuenmayor',
      driverInitials: 'YF',
      vehicleModel: 'Van',
      vehicleColor: 'azul',
      rating: 4.3,
      ratingCount: 18,
      departureTime: '12:00 m',
      arrivalTime: '12:45 pm',
      returnTime: '5:15 pm',
      weeklyPrice: 3.50,
      singleTripPrice: 1.00,
      availableSeats: 6,
      totalSeats: 12,
      walkingDistanceMeters: 550,
      hasAirConditioning: false,
      isVerified: true,
      yearsOnRoute: 2,
      activePassengersCount: 9,
      paymentCycleDescription: 'cobra semanal',
      stopsCount: 8,
      durationMinutes: 45,
      plateNumber: 'BC456EF',
    ),
    TransportShift(
      id: 'shift-pirela',
      driverName: 'Nairobis Pirela',
      driverInitials: 'NP',
      vehicleModel: 'Chevrolet Spark',
      vehicleColor: 'plateado',
      rating: 4.6,
      ratingCount: 41,
      departureTime: '12:25 pm',
      arrivalTime: '12:55 pm',
      returnTime: '5:20 pm',
      weeklyPrice: 4.50,
      singleTripPrice: 1.20,
      availableSeats: 1,
      totalSeats: 4,
      walkingDistanceMeters: 180,
      hasAirConditioning: true,
      isVerified: true,
      yearsOnRoute: 5,
      activePassengersCount: 3,
      paymentCycleDescription: 'cobra \$9,00 quincenal',
      stopsCount: 4,
      durationMinutes: 30,
      plateNumber: 'CD789GH',
    ),
  ];
}
