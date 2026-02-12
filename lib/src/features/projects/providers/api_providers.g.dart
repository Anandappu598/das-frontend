// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dioHash() => r'e99d678f5bd7dcac0bf5e3392ef59b8f614f11b7';

/// Dio provider for HTTP requests
///
/// Copied from [dio].
@ProviderFor(dio)
final dioProvider = AutoDisposeProvider<Dio>.internal(
  dio,
  name: r'dioProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DioRef = AutoDisposeProviderRef<Dio>;
String _$taskApiServiceHash() => r'c6791f3f5b2d6577d5ec02adeabf95c6b9eb1913';

/// Task API service provider
///
/// Copied from [taskApiService].
@ProviderFor(taskApiService)
final taskApiServiceProvider = AutoDisposeProvider<TaskApiService>.internal(
  taskApiService,
  name: r'taskApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$taskApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TaskApiServiceRef = AutoDisposeProviderRef<TaskApiService>;
String _$apiProjectsHash() => r'4ef70f48be79d26c13e1e23430d6fba95ee62c26';

/// Fetch all projects from API
///
/// Copied from [apiProjects].
@ProviderFor(apiProjects)
final apiProjectsProvider =
    AutoDisposeFutureProvider<List<ProjectModel>>.internal(
  apiProjects,
  name: r'apiProjectsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiProjectsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiProjectsRef = AutoDisposeFutureProviderRef<List<ProjectModel>>;
String _$apiTasksHash() => r'8af417f3f922846d9fa3d6f0e2959b8cb14c4665';

/// Fetch all tasks from API
///
/// Copied from [apiTasks].
@ProviderFor(apiTasks)
final apiTasksProvider = AutoDisposeFutureProvider<List<TaskModel>>.internal(
  apiTasks,
  name: r'apiTasksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiTasksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiTasksRef = AutoDisposeFutureProviderRef<List<TaskModel>>;
String _$apiProjectHash() => r'a7122817212e17cc88351fb4c88314840396dc35';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Fetch specific project by ID from API
///
/// Copied from [apiProject].
@ProviderFor(apiProject)
const apiProjectProvider = ApiProjectFamily();

/// Fetch specific project by ID from API
///
/// Copied from [apiProject].
class ApiProjectFamily extends Family<AsyncValue<ProjectModel>> {
  /// Fetch specific project by ID from API
  ///
  /// Copied from [apiProject].
  const ApiProjectFamily();

  /// Fetch specific project by ID from API
  ///
  /// Copied from [apiProject].
  ApiProjectProvider call(
    int projectId,
  ) {
    return ApiProjectProvider(
      projectId,
    );
  }

  @override
  ApiProjectProvider getProviderOverride(
    covariant ApiProjectProvider provider,
  ) {
    return call(
      provider.projectId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'apiProjectProvider';
}

/// Fetch specific project by ID from API
///
/// Copied from [apiProject].
class ApiProjectProvider extends AutoDisposeFutureProvider<ProjectModel> {
  /// Fetch specific project by ID from API
  ///
  /// Copied from [apiProject].
  ApiProjectProvider(
    int projectId,
  ) : this._internal(
          (ref) => apiProject(
            ref as ApiProjectRef,
            projectId,
          ),
          from: apiProjectProvider,
          name: r'apiProjectProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$apiProjectHash,
          dependencies: ApiProjectFamily._dependencies,
          allTransitiveDependencies:
              ApiProjectFamily._allTransitiveDependencies,
          projectId: projectId,
        );

  ApiProjectProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final int projectId;

  @override
  Override overrideWith(
    FutureOr<ProjectModel> Function(ApiProjectRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ApiProjectProvider._internal(
        (ref) => create(ref as ApiProjectRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ProjectModel> createElement() {
    return _ApiProjectProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ApiProjectProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ApiProjectRef on AutoDisposeFutureProviderRef<ProjectModel> {
  /// The parameter `projectId` of this provider.
  int get projectId;
}

class _ApiProjectProviderElement
    extends AutoDisposeFutureProviderElement<ProjectModel> with ApiProjectRef {
  _ApiProjectProviderElement(super.provider);

  @override
  int get projectId => (origin as ApiProjectProvider).projectId;
}

String _$apiCatalogHash() => r'8cb0ae791aad96a401922675410977b68320e033';

/// Fetch all catalog items from API
///
/// Copied from [apiCatalog].
@ProviderFor(apiCatalog)
final apiCatalogProvider =
    AutoDisposeFutureProvider<List<CatalogModel>>.internal(
  apiCatalog,
  name: r'apiCatalogProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiCatalogHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiCatalogRef = AutoDisposeFutureProviderRef<List<CatalogModel>>;
String _$apiCoursesHash() => r'7863aaeb09ecf5220362ad00083488a70712c752';

/// Fetch courses from catalog API
///
/// Copied from [apiCourses].
@ProviderFor(apiCourses)
final apiCoursesProvider =
    AutoDisposeFutureProvider<List<CatalogModel>>.internal(
  apiCourses,
  name: r'apiCoursesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiCoursesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiCoursesRef = AutoDisposeFutureProviderRef<List<CatalogModel>>;
String _$apiRoutinesHash() => r'697f844c446f9138cebcf881fcc6217538060413';

/// Fetch routines from catalog API
///
/// Copied from [apiRoutines].
@ProviderFor(apiRoutines)
final apiRoutinesProvider =
    AutoDisposeFutureProvider<List<CatalogModel>>.internal(
  apiRoutines,
  name: r'apiRoutinesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiRoutinesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiRoutinesRef = AutoDisposeFutureProviderRef<List<CatalogModel>>;
String _$apiWorkItemsHash() => r'ff7a4143193bcebc98fa3ddde6253ff4fa945c37';

/// Fetch work items from catalog API (CUSTOM type)
///
/// Copied from [apiWorkItems].
@ProviderFor(apiWorkItems)
final apiWorkItemsProvider =
    AutoDisposeFutureProvider<List<CatalogModel>>.internal(
  apiWorkItems,
  name: r'apiWorkItemsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiWorkItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiWorkItemsRef = AutoDisposeFutureProviderRef<List<CatalogModel>>;
String _$apiTodayPlanHash() => r'da8b3c0d8e9b0d0136212b65556a2fc05db507ef';

/// Fetch today's planned items from API
///
/// Copied from [apiTodayPlan].
@ProviderFor(apiTodayPlan)
final apiTodayPlanProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
  apiTodayPlan,
  name: r'apiTodayPlanProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiTodayPlanHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiTodayPlanRef
    = AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
