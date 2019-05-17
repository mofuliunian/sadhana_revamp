import 'package:flutter/material.dart';
import 'package:sadhana/dao/activitydao.dart';
import 'package:sadhana/model/activity.dart';
import 'package:sadhana/model/sadhana.dart';

class CheckmarkButton extends StatefulWidget {
  Function onClick;
  Sadhana sadhana;
  Activity activity;
  CheckmarkButton({@required this.sadhana, @required this.activity, this.onClick});

  @override
  _CheckmarkButtonState createState() => _CheckmarkButtonState();
}

class _CheckmarkButtonState extends State<CheckmarkButton> {
  String title;
  Activity activity;
  Sadhana sadhana;
  Brightness theme;
  ActivityDAO activityDAO = ActivityDAO();
  @override
  Widget build(BuildContext context) {
    activity = widget.activity;
    sadhana = widget.sadhana;
    title = sadhana.name;
    theme = Theme.of(context).brightness;
    return InkWell(
      onTap: () {
        onClicked();
      },
      child: Container(
        width: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (theme == Brightness.light ? widget.sadhana.lColor : widget.sadhana.dColor)
              .withAlpha(widget.activity.sadhanaValue > 0 ? 20 : 0),
          border: Border.all(
            color: theme == Brightness.light ? widget.sadhana.lColor : widget.sadhana.dColor,
            width: 2,
            style: widget.activity.sadhanaValue > 0 ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: AnimatedContainer(
            duration: Duration(seconds: 5),
            width: 48,
            child: widget.activity.sadhanaValue > 0
                ? Icon(
                    Icons.done,
                    size: 20.0,
                    color: theme == Brightness.light ? widget.sadhana.lColor : widget.sadhana.dColor,
                  )
                : Icon(
                    Icons.close,
                    size: 20.0,
                    color: Colors.grey,
                  ),
          ),
        ),
      ),
    );
  }

  onClicked() {
    activity.sadhanaValue = activity.sadhanaValue > 0 ? 0 : 1;
    setState(() {
      sadhana.activitiesByDate[activity.sadhanaDate.millisecondsSinceEpoch] = activity;
    });
    activityDAO.insertOrUpdate(activity).then((dbActivity) {
      setState(() {
        sadhana.activitiesByDate[activity.sadhanaDate.millisecondsSinceEpoch] = dbActivity;
        if (widget.onClick != null)
          widget.onClick(widget.activity);
      });
    });
  }
}