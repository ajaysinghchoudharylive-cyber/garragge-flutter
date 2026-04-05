import 'package:carsbuzz/repository/group_repo.dart';
import 'package:carsbuzz/network/repository_api.dart';
import 'package:carsbuzz/storage/app_shared_preferences.dart';
import 'package:carsbuzz/network/data_state.dart';
import 'package:carsbuzz/models/get_all_groups_response.dart';

/// Example usage of the GroupRepo to test the API implementation
class GroupService {
  late final GroupRepo _groupRepo;
  
  GroupService(RepositoryApi api, AppSharedPreferences preferences) {
    _groupRepo = GroupRepo(retrofit: api, sharedPreferences: preferences);
  }

  /// Test method to fetch groups
  Future<void> testFetchGroups() async {
    print('Testing Group API...');
    
    await for (final state in _groupRepo.getGroups()) {
      if (state is Success<List<GetAllGroupsResponse>>) {
        final groups = state.data;
        print('✅ Success! Fetched ${groups.length} groups');
        
        for (final group in groups) {
          print('Group: ${group.groupName} (ID: ${group.id})');
          print('  - Attached: ${group.attached}');
          print('  - Launched: ${group.launched}');
          print('  - Categories: ${group.categories.length}');
          
          for (final category in group.categories) {
            print('    • ${category.itemCategory} (${category.items.length} items)');
          }
        }
        break;
      } else if (state is Failure) {
        final failure = state as Failure;
        print('❌ Error: ${failure.exception}');
        break;
      }
    }
  }
}

/// You can use this service like this:
/// 
/// ```dart
/// final dio = Dio();
/// dio.options.baseUrl = ApiConstants.baseUrl;
/// final api = RepositoryApi(dio);
/// final preferences = AppSharedPreferences();
/// 
/// final service = GroupService(api, preferences);
/// await service.testFetchGroups();
/// ```