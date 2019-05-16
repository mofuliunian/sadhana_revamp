import 'package:sadhana/constant/constant.dart';
import 'package:sadhana/constant/sadhanatype.dart';
import 'package:sadhana/dao/activitydao.dart';
import 'package:sadhana/dao/basedao.dart';
import 'package:sadhana/main.dart';
import 'package:sadhana/model/activity.dart';
import 'package:sadhana/model/cachedata.dart';
import 'package:sadhana/model/entity.dart';
import 'package:sadhana/model/sadhana.dart';

class SadhanaDAO extends BaseDAO<Sadhana> {
  static final createSadhanaTable = ''' create table ${Sadhana.tableSadhana} ( 
  ${Entity.columnId} integer primary key autoincrement, 
  ${Sadhana.columnName} text not null,
  ${Sadhana.columnDescription} text,
  ${Sadhana.columnIndex} integer not null,
  ${Sadhana.columnLColor} integer not null,
  ${Sadhana.columnDColor} integer not null,
  ${Sadhana.columnType} integer not null,
  ${Sadhana.columnIsPreloaded} boolean,
  ${Sadhana.columnReminderTime} date,
  ${Sadhana.columnReminderDays} text)
''';
  static ActivityDAO _activityDAO = ActivityDAO();

  @override
  getDefaultInstance() {
    return Sadhana(name: "",type:SadhanaType.BOOLEAN,lColor: Constant.colors[0][0], dColor: Constant.colors[0][1]);
  }

  @override
  getTableName() {
    return Sadhana.tableSadhana;
  }

  Future<Sadhana> insertOrUpdate(Sadhana entity) async {
      Sadhana sadhana = await super.insertOrUpdate(entity);
      return sadhana;
  }

  @override
  Future<List<Sadhana>> getAll() async {
    List<Sadhana> sadhanas = await super.getAll();
    for (Sadhana sadhana in sadhanas) {
      List<Activity> activities = await _activityDAO.getActivityBySadhanaId(sadhana.id);
      if (activities != null && activities.isNotEmpty) {
        sadhana.activitiesByDate = new Map.fromIterable(activities, key: (v) => (v as Activity).sadhanaDate.millisecondsSinceEpoch, value: (v) => v);
      } else {
        sadhana.activitiesByDate = new Map();
      }
    }
    return sadhanas;
  }

  Future<int> delete(int id) async {
    int i = await super.delete(id);
    if(i > 0) {
      await _activityDAO.deleteBySadhanaId(id);
      CacheData.removeSadhana(id);
      main();
    }
    return i;
  }


}