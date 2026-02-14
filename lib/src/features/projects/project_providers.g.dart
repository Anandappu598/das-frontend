// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectRepositoryHash() => r'215e8781b75b9d9877962b300c35e53ed0fff751';

/// See also [projectRepository].
@ProviderFor(projectRepository)
final projectRepositoryProvider =
    AutoDisposeProvider<ProjectRepository>.internal(
  projectRepository,
  name: r'projectRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$projectRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProjectRepositoryRef = AutoDisposeProviderRef<ProjectRepository>;
String _$currentProjectHash() => r'77965f419e9d45028680fca5ad9101a550a38c97';

/// See also [currentProject].
@ProviderFor(currentProject)
final currentProjectProvider =
    AutoDisposeFutureProvider<ProjectWithTasks?>.internal(
  currentProject,
  name: r'currentProjectProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentProjectHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentProjectRef = AutoDisposeFutureProviderRef<ProjectWithTasks?>;
String _$projectsWithTasksHash() => r'6276e764661658d0b8ca8f3e321dab9aa4c0b3f3';

/// All projects with tasks for Activity Catalog
///
/// Copied from [projectsWithTasks].
@ProviderFor(projectsWithTasks)
final projectsWithTasksProvider =
    AutoDisposeFutureProvider<List<ProjectWithTasks>>.internal(
  projectsWithTasks,
  name: r'projectsWithTasksProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$projectsWithTasksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProjectsWithTasksRef
    = AutoDisposeFutureProviderRef<List<ProjectWithTasks>>;
String _$pendingProjectsHash() => r'68f30823de1a41b52ef92f5e194186e317cf70a1';

/// See also [pendingProjects].
@ProviderFor(pendingProjects)
final pendingProjectsProvider =
    AutoDisposeStreamProvider<List<Project>>.internal(
  pendingProjects,
  name: r'pendingProjectsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingProjectsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PendingProjectsRef = AutoDisposeStreamProviderRef<List<Project>>;
String _$pendingProjectClosuresHash() =>
    r'f36548d7b1ba2ede28cd27ee4148ea1764c584d6';

/// See also [pendingProjectClosures].
@ProviderFor(pendingProjectClosures)
final pendingProjectClosuresProvider =
    AutoDisposeStreamProvider<List<Project>>.internal(
  pendingProjectClosures,
  name: r'pendingProjectClosuresProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingProjectClosuresHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PendingProjectClosuresRef = AutoDisposeStreamProviderRef<List<Project>>;
String _$pendingNewTasksHash() => r'bfed6531b92ee57b764f8c736276c8cdb72c4f93';

/// See also [pendingNewTasks].
@ProviderFor(pendingNewTasks)
final pendingNewTasksProvider =
    AutoDisposeStreamProvider<List<TaskWithProject>>.internal(
  pendingNewTasks,
  name: r'pendingNewTasksProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingNewTasksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PendingNewTasksRef
    = AutoDisposeStreamProviderRef<List<TaskWithProject>>;
String _$pendingTaskCompletionsHash() =>
    r'ec6e2a611c564518aaf698e3cda7fb6f171a96cc';

/// See also [pendingTaskCompletions].
@ProviderFor(pendingTaskCompletions)
final pendingTaskCompletionsProvider =
    AutoDisposeStreamProvider<List<TaskWithProject>>.internal(
  pendingTaskCompletions,
  name: r'pendingTaskCompletionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingTaskCompletionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PendingTaskCompletionsRef
    = AutoDisposeStreamProviderRef<List<TaskWithProject>>;
String _$pendingTemplatesHash() => r'5b02aec95d78c21eb0eec48943ccbad8a6254867';

/// See also [pendingTemplates].
@ProviderFor(pendingTemplates)
final pendingTemplatesProvider =
    AutoDisposeStreamProvider<List<ActivityTemplate>>.internal(
  pendingTemplates,
  name: r'pendingTemplatesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingTemplatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PendingTemplatesRef
    = AutoDisposeStreamProviderRef<List<ActivityTemplate>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
