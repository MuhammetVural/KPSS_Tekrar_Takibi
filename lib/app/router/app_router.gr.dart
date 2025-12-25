// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [ExamListPage]
class ExamListRoute extends PageRouteInfo<void> {
  const ExamListRoute({List<PageRouteInfo>? children})
    : super(ExamListRoute.name, initialChildren: children);

  static const String name = 'ExamListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ExamListPage();
    },
  );
}

/// generated route for
/// [SubjectsPage]
class SubjectsRoute extends PageRouteInfo<SubjectsRouteArgs> {
  SubjectsRoute({
    Key? key,
    required String examId,
    List<PageRouteInfo>? children,
  }) : super(
         SubjectsRoute.name,
         args: SubjectsRouteArgs(key: key, examId: examId),
         initialChildren: children,
       );

  static const String name = 'SubjectsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SubjectsRouteArgs>();
      return SubjectsPage(key: args.key, examId: args.examId);
    },
  );
}

class SubjectsRouteArgs {
  const SubjectsRouteArgs({this.key, required this.examId});

  final Key? key;

  final String examId;

  @override
  String toString() {
    return 'SubjectsRouteArgs{key: $key, examId: $examId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SubjectsRouteArgs) return false;
    return key == other.key && examId == other.examId;
  }

  @override
  int get hashCode => key.hashCode ^ examId.hashCode;
}

/// generated route for
/// [TopicsPage]
class TopicsRoute extends PageRouteInfo<TopicsRouteArgs> {
  TopicsRoute({
    Key? key,
    required String subjectId,
    required String subjectName,
    List<PageRouteInfo>? children,
  }) : super(
         TopicsRoute.name,
         args: TopicsRouteArgs(
           key: key,
           subjectId: subjectId,
           subjectName: subjectName,
         ),
         initialChildren: children,
       );

  static const String name = 'TopicsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TopicsRouteArgs>();
      return TopicsPage(
        key: args.key,
        subjectId: args.subjectId,
        subjectName: args.subjectName,
      );
    },
  );
}

class TopicsRouteArgs {
  const TopicsRouteArgs({
    this.key,
    required this.subjectId,
    required this.subjectName,
  });

  final Key? key;

  final String subjectId;

  final String subjectName;

  @override
  String toString() {
    return 'TopicsRouteArgs{key: $key, subjectId: $subjectId, subjectName: $subjectName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TopicsRouteArgs) return false;
    return key == other.key &&
        subjectId == other.subjectId &&
        subjectName == other.subjectName;
  }

  @override
  int get hashCode => key.hashCode ^ subjectId.hashCode ^ subjectName.hashCode;
}
