import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:sadhana/attendance/attendance_utils.dart';
import 'package:sadhana/attendance/model/attendance_summary.dart';
import 'package:sadhana/attendance/model/user_role.dart';
import 'package:sadhana/auth/registration/Inputs/text-input.dart';
import 'package:sadhana/comman.dart';
import 'package:sadhana/constant/constant.dart';
import 'package:sadhana/constant/wsconstants.dart';
import 'package:sadhana/model/cachedata.dart';
import 'package:sadhana/service/apiservice.dart';
import 'package:sadhana/utils/app_response_parser.dart';
import 'package:sadhana/utils/appsharedpref.dart';
import 'package:sadhana/utils/apputils.dart';
import 'package:sadhana/widgets/base_state.dart';
import 'package:sadhana/widgets/title_with_subtitle.dart';
import 'package:sadhana/wsmodel/appresponse.dart';

class SubmitAttendancePage extends StatefulWidget {
  static const String routeName = '/submit_attendance';
  final DateTime month;
  SubmitAttendancePage(this.month);
  @override
  _SubmitAttendancePageState createState() => _SubmitAttendancePageState();
}

class _SubmitAttendancePageState extends BaseState<SubmitAttendancePage> {
  ApiService _api = ApiService();
  List<AttendanceSummary> summary = new List();
  final GlobalKey<FormState> _submitForm = GlobalKey<FormState>();
  UserRole _userRole;
  Color textColor;
  String wsMonth;
  String strMonth;
  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void loadData() async {
    startLoading();
    try {
      _userRole = await AppSharedPrefUtil.getUserRole();
      if (_userRole != null) {
        setState(() {
          wsMonth = WSConstant.wsDateFormat.format(widget.month);
          strMonth = DateFormat.yMMM().format(widget.month);
        });
        if (!CacheData.isSubmittedCurrentMonthAttendance) {
          Response res = await _api.getMonthlySummary(wsMonth, _userRole.groupName);
          AppResponse appResponse = AppResponseParser.parseResponse(res, context: context);
          if (appResponse.status == WSConstant.SUCCESS_CODE) {
            setState(() {
              summary = AttendanceSummary.fromJsonList(appResponse.data['details']);
              int totalSessionDates = appResponse.data['total_attendance_dates'];
              summary.forEach((s) => s.totalAttendanceDates = totalSessionDates);
              print(summary);
            });
          }
        } else {
          stopLoading();
          CommonFunction.alertDialog(
              closeable: false,
              context: context,
              msg: "You have already sumbitted current month attendance",
              doneButtonFn: () {
                Navigator.pop(context);
                Navigator.pop(context);
              });
        }
      }
    } catch (e, s) {
      print(s);
      CommonFunction.displayErrorDialog(context: context);
    }
    stopLoading();
  }

  @override
  Widget pageToDisplay() {
    textColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.white;
    Widget _buildCardView(AttendanceSummary data) {
      return Container(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Card(
            elevation: 5,
            child: Column(
              children: <Widget>[
                ListTile(
                  dense: true,
                  title: Text(data.name),
                  trailing: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.message),
                        onPressed: () => setState(() => data.showRemarks = !data.showRemarks),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment(1, 0),
                        child: Text('${data.percentage.toString()} %'),
                      ),
                    ],
                  ),
                ),
                (data.percentage < 50) || data.showRemarks
                    ? Column(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.fromLTRB(15, 0, 15, 5),
                            child: TextInputField(
                              isRequiredValidation: true,
                              labelText: "Reason for Absent",
                              valueText: data.lessAttendanceReason,
                              onSaved: (val) => data.lessAttendanceReason = val,
                              padding: EdgeInsets.all(0),
                              contentPadding: EdgeInsets.all(13),
                            ),
                          ),
                        ],
                      )
                    : Container()
              ],
            )),
      );
    }

    Widget _buildListView() {
      return Container(
        padding: EdgeInsets.only(top: 15),
        child: ListView.builder(
          itemCount: summary.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildCardView(summary[index]);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        centerTitle: true,
        title: AppTitleWithSubTitle(
          title: 'Submit Attendance',
          subTitle: '${_userRole.groupTitle} , $strMonth',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _submitForm,
          child: summary != null ? _buildListView() : Container(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _onSubmit,
      //backgroundColor: Colors.white,
      icon: Icon(Icons.check, color: Colors.white),
      label: Text('Save', style: TextStyle(color: Colors.white)),
    );
  }

  void _onSubmit() async {
    if (_submitForm.currentState.validate()) {
      _submitForm.currentState.save();
      summary = summary.where((s) => !AppUtils.isNullOrEmpty(s.lessAttendanceReason)).toList();
      CommonFunction.alertDialog(
          context: context,
          msg: "Are you sure you want to submit attendance?",
          doneButtonFn: () async {
            Navigator.pop(context);
            await submitAttendance();
          });
    }
  }

  Future<void> submitAttendance() async {
    try {
      startLoading();
      Response res = await _api.submitMontlyReport(wsMonth, _userRole.groupName, summary);
      stopLoading();
      AppResponse appResponse = AppResponseParser.parseResponse(res, context: context);
      if (appResponse.status == WSConstant.SUCCESS_CODE) {
        if (widget.month.month == Constant.today.month) CacheData.isSubmittedCurrentMonthAttendance = true;
        CommonFunction.alertDialog(
            context: context,
            msg: "Attendance submitted successfully.",
            doneButtonFn: () {
              Navigator.pop(context);
              Navigator.pop(context);
            });
      }
    } catch (e, s) {
      print(s);
      stopLoading();
    }
  }
}
