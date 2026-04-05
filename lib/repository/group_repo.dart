import 'dart:async';
import 'package:carsbuzz/network/data_state.dart';
import 'package:carsbuzz/models/get_all_groups_response.dart';
import '../network/repository_api.dart';
import '../storage/app_shared_preferences.dart';

class GroupRepo {
  final RepositoryApi retrofit;
  final AppSharedPreferences sharedPreferences;

  GroupRepo({
    required this.retrofit,
    required this.sharedPreferences,
  });

  /// Fetches all category groups from the API
  /// Returns a stream of DataState containing list of groups
  Stream<DataState<List<GetAllGroupsResponse>>> getGroups() async* {
    try {
      final networkCall = await retrofit.getGroup();
      yield Success(networkCall);
    } catch (e) {
      yield Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}