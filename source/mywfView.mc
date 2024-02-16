import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Application.Storage;
using Toybox.Time;
using Toybox.Time.Gregorian;

using Toybox.UserProfile;
using Toybox.System;

using Toybox.ActivityMonitor;

class mywfView extends WatchUi.WatchFace {

    var previousActiveMinutesDay = 0;
    var activeMinutes = -1;

    var nightHR = null;

    // var p = 0;
    // var q = 0;
    // var z = 0;
    // var v = 0;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var profile = UserProfile.getProfile();
        var info = ActivityMonitor.getInfo();


        // Get and show the current time
        var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
        var viewTime = View.findDrawableById("TimeLabel") as Text;
        viewTime.setText(timeString);

        // Get and show the current date
        var date = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateString = Lang.format("$1$/$2$", [date.month.format("%02d"), date.day.format("%02d")]);
        var viewDate = View.findDrawableById("DateLabel") as Text;
        viewDate.setText(dateString);

        // Get and show the current battery
        var battString = Lang.format("$1$%", [System.getSystemStats().battery.format("%d")]);
        var battView = View.findDrawableById("BattLabel") as Text;
        battView.setText(battString);

        // NightAverageHRLabel
        if (nightHR == null) {
            nightHR = Storage.getValue("nightHR");
            if (nightHR == null) {
                nightHR = -1;
            }
        }
        if (clockTime.hour == 6 && clockTime.min == 0) {
            var iterator = ActivityMonitor.getHeartRateHistory(null, false); // new Time.Duration(3600*24)
            var sum = 0;
            var count = 0;
            for (var sample = iterator.next(); sample != null; sample = iterator.next()) {
                if (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    sum += sample.heartRate;
                    count += 1;
                }
            }
            if (count > 0) {
                nightHR = sum/count;
                Storage.setValue("nightHR", nightHR);
            } else {
                nightHR = -2;
            }
        }

        if (info.activeMinutesDay != null
                && previousActiveMinutesDay != info.activeMinutesDay.total) {
            var userActivityIterator = UserProfile.getUserActivityHistory();
            var activity = userActivityIterator.next();
            var today = Time.today();

            var durationTotal = 0;
            while (activity != null) {
                if (activity.startTime != null && activity.duration != null) {
                    var startTime = activity.startTime.add(new Time.Duration(631065600));
                    if (startTime.greaterThan(today)) {
                        durationTotal += activity.duration.value();
                    }
                }
                activity = userActivityIterator.next();
            }
            activeMinutes = (durationTotal / 60).toNumber();
            previousActiveMinutesDay = info.activeMinutesDay.total;
        }

        var statOneLabel = View.findDrawableById("statOneLabel") as Text;
        statOneLabel.setText(Lang.format("$1$ $2$ $3$", [
            nightHR.format("%d"),
            profile.restingHeartRate.format("%d"),
            activeMinutes.format("%d")
            ]));

        var statTwoLabel = View.findDrawableById("statTwoLabel") as Text;
        statTwoLabel.setText(Lang.format("$1$", [info.steps.format("%d")]));

        // Debug
        //var statOneInfo = View.findDrawableById("statOneInfo") as Text;
        //statOneInfo.setText(Lang.format("night rhr act", [nightHRHour.format("%02d"), nightHRMin.format("%02d"), p.format("%02d"), q.format("%02d")]));
        //var statTwoInfo = View.findDrawableById("statTwoInfo") as Text;
        //statTwoInfo.setText(Lang.format("cnt $1$ diff $2$", [z.format("%d"), v.format("%d")]));
        // z.format("%d"), v.format("%d")
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
