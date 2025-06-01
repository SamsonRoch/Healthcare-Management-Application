import 'package:get_it/get_it.dart';
import 'package:patient_management_app/data/repositories/appointment_repository.dart';
import 'package:patient_management_app/data/repositories/auth_repository.dart';
import 'package:patient_management_app/data/repositories/patient_repository.dart';
import 'package:patient_management_app/data/repositories/user_repository.dart';
import 'package:patient_management_app/services/api_service.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/services/database_service.dart';
import 'package:patient_management_app/services/navigation_service.dart';
import 'package:patient_management_app/services/rbac_service.dart';
import 'package:patient_management_app/services/staff_service.dart';
import 'package:patient_management_app/services/sync_service.dart';

final locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register NavigationService first since other services depend on it
  locator.registerLazySingleton<NavigationService>(() => NavigationService());

  locator.registerSingletonAsync<DatabaseService>(() async {
    final dbService = DatabaseService();
    await dbService.database; // Ensure DB is initialized
    return dbService;
  });
  locator.registerLazySingleton<RBACService>(() => RBACService());
  locator.registerLazySingleton<AuthRepository>(() => AuthRepository());
  locator.registerLazySingleton<UserRepository>(() => UserRepository());
  locator.registerLazySingleton<PatientRepository>(() => PatientRepository());
  locator.registerLazySingleton<ApiService>(() => ApiService());
  locator.registerLazySingleton<AuthService>(() => AuthService());
  locator.registerLazySingleton<StaffService>(() => StaffService());
  locator.registerLazySingleton<SyncService>(() => SyncService());
  locator.registerLazySingleton<AppointmentRepository>(() => AppointmentRepository());
  await locator.allReady();
}