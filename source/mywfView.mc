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
        // Get and show the current time
        var clockTime = System.getClockTime();
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

        //
        var profile = UserProfile.getProfile();
        var info = ActivityMonitor.getInfo();
        var statOne =  Lang.format("$1$ $2$", [profile.restingHeartRate.format("%d"), info.steps.format("%d")]);
        var statOneLabel = View.findDrawableById("StatOneLabel") as Text;
        statOneLabel.setText(statOne);

        if (info.activeMinutesDay != null && previousActiveMinutesDay != info.activeMinutesDay.total) {
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
            var minutes = (durationTotal / 60).toNumber();
            var statTwo = Lang.format("$1$ $2$", [minutes.format("%d"), timeString]);
            var statTwoLabel = View.findDrawableById("StatTwoLabel") as Text;
            statTwoLabel.setText(statTwo);
            previousActiveMinutesDay = info.activeMinutesDay.total;
        }

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
