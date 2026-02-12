// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardRepositoryHash() =>
    r'422c46c941bd77941e968858711ca3db7472c6e6';

/// See also [dashboardRepository].
@ProviderFor(dashboardRepository)
final dashboardRepositoryProvider =
    AutoDisposeProvider<DashboardRepository>.internal(
  dashboardRepository,
  name: r'dashboardRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DashboardRepositoryRef = AutoDisposeProviderRef<DashboardRepository>;
String _$dashboardProjectsHash() => r'4282024c0a59dc6819de7319452bacc37bfcbc4d';

/// See also [dashboardProjects].
@ProviderFor(dashboardProjects)
final dashboardProjectsProvider =
    AutoDisposeFutureProvider<List<ProjectWithTasks>>.internal(
  dashboardProjects,
  name: r'dashboardProjectsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardProjectsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DashboardProjectsRef
    = AutoDisposeFutureProviderRef<List<ProjectWithTasks>>;
String _$dashboardServiceHash() => r'da21473931a480e0ac60a906d9fe0175470d5b61';

/// See also [dashboardService].
@ProviderFor(dashboardService)
final dashboardServiceProvider = AutoDisposeProvider<DashboardService>.internal(
  dashboardService,
  name: r'dashboardServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DashboardServiceRef = AutoDisposeProviderRef<DashboardService>;
String _$dashboardMetricsHash() => r'5e2f47b4dbc128988dd42436b90d84c556dd4cb7';

/// See also [dashboardMetrics].
@ProviderFor(dashboardMetrics)
final dashboardMetricsProvider =
    AutoDisposeFutureProvider<DashboardMetrics>.internal(
  dashboardMetrics,
  name: r'dashboardMetricsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardMetricsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DashboardMetricsRef = AutoDisposeFutureProviderRef<DashboardMetrics>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
