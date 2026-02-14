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
String _$dashboardProjectsHash() => r'f23113dc1d3859fb8be0b59f2cb0e9e490e3ab44';

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
String _$usersForStatsHash() => r'd4ec6e2a42c11dfbb5e52af14f3cfd404ffd5480';

/// Provider for fetching users list for stats dropdown
///
/// Copied from [usersForStats].
@ProviderFor(usersForStats)
final usersForStatsProvider = AutoDisposeFutureProvider<List<dynamic>>.internal(
  usersForStats,
  name: r'usersForStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$usersForStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UsersForStatsRef = AutoDisposeFutureProviderRef<List<dynamic>>;
String _$projectWorkStatsHash() => r'84584edf664b1de97ce345908ed28e199d753a27';

/// Provider for fetching project work statistics
///
/// Copied from [projectWorkStats].
@ProviderFor(projectWorkStats)
final projectWorkStatsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  projectWorkStats,
  name: r'projectWorkStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$projectWorkStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProjectWorkStatsRef
    = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
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
