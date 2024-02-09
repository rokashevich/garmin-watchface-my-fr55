import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Time;
using Toybox.Time.Gregorian;

using Toybox.UserProfile;
using Toybox.System;

using Toybox.ActivityMonitor;

class mywfView extends WatchUi.WatchFace {

    var previousActiveMinutesDay = 0;
    var activeMinutes = -1;

    var nightHRDayNum = -1;
    var nightHR = -1;

    var x = 0;
    var y = 0;

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
        if (nightHRDayNum != date.day
            && ((clockTime.hour == 6 && clockTime.min == 0) || nightHR < 0)) {
            x += 1;
            var iterator = ActivityMonitor.getHeartRateHistory(new Time.Duration(3600*6), false);
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
            }
        }

        if (info.activeMinutesDay != null
                && previousActiveMinutesDay != info.activeMinutesDay.total) {
            y += 1;
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
        }

        var statOneLabel = View.findDrawableById("statOneLabel") as Text;
        statOneLabel.setText(Lang.format("$1$ $2$ $3$", [
            nightHR.format("%d"),
            profile.restingHeartRate.format("%d"),
            activeMinutes.format("%d")
            ]));

        var statTwoLabel = View.findDrawableById("statTwoLabel") as Text;
        statTwoLabel.setText(Lang.format("$1$ $2$ $3$", [info.steps.format("%d"), x.format("%d"), y.format("%d")]));
        previousActiveMinutesDay = info.activeMinutesDay.total;

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
