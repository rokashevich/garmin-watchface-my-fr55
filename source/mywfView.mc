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

    var morningSet = false;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function morningDraw(topLongText as String, bottomLongText as String) {
        var topLong = View.findDrawableById("topLong") as Text;
        topLong.setText(topLongText);

        var bottomLong = View.findDrawableById("bottomLong") as Text;
        bottomLong.setText(bottomLongText);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        var clockTime = System.getClockTime();
        var activeCount = 0;
        var activeMinutes = 0;
        var userActivityIterator = UserProfile.getUserActivityHistory();
        var activity = userActivityIterator.next();
        var today = Time.today();

        var durationTotal = 0;
        activeCount = 0;
        while (activity != null) {
            activeCount += 1;
            if (activity.startTime != null && activity.duration != null) {
                var startTime = activity.startTime.add(new Time.Duration(631065600));
                if (startTime.greaterThan(today)) {
                    durationTotal += activity.duration.value();
                }
            }
            activity = userActivityIterator.next();
        }
        activeMinutes = (durationTotal / 60).toNumber();

        var topShort = View.findDrawableById("topShort") as Text;
        topShort.setText(Lang.format("$1$ $2$:$3$/$4$", [
            activeMinutes.format("%d"),
            clockTime.hour.format("%d"),
            clockTime.min.format("%02d"),
            activeCount.format("%d")]));

        if (morningSet == false) {
            var topLongText = Storage.getValue("topLongText");
            var bottomLongText = Storage.getValue("bottomLongText");
            if (topLongText == null || bottomLongText == null) {
                return;
            }
            morningDraw(topLongText, bottomLongText);
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();

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

        if (clockTime.hour == 6 && clockTime.min == 0) {
        //if (clockTime.hour == 23) {
        //if (clockTime.hour == 14 && clockTime.min == 0) {
            var avg = 0;
            var min = 9999;
            var max = 0;
            var sum = 0;
            var count = 0;

            var iterator = ActivityMonitor.getHeartRateHistory(null, false); // new Time.Duration(3600*24)
            for (var sample = iterator.next(); sample != null; sample = iterator.next()) {
                if (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    if (sample.heartRate < min) { min = sample.heartRate; }
                    else if (sample.heartRate > max) { max = sample.heartRate; }
                    sum += sample.heartRate;
                    count += 1;
                }
            }
            if (count > 0) {
                avg = sum/count;
            }

            var topLongText = Lang.format("$1$-$2$ $3$ $4$", [
                min.format("%d"),
                max.format("%d"),
                avg.format("%d"),
                UserProfile.getProfile().restingHeartRate.format("%d")]);

            var precipitation = 0;
            var temperatureNow = Toybox.Weather.getCurrentConditions().temperature;
            var temperatureMid = 0;
            var temperatureLate = 0;
            var forecast = Toybox.Weather.getHourlyForecast();
            if(forecast != null)
            {

                for (var i = 0; i < forecast.size(); ++i)
                {
                    if (forecast[i].precipitationChance > precipitation) {
                        precipitation = forecast[i].precipitationChance;
                    }
                    if (i == 5) { temperatureMid = forecast[i].temperature; }
                    if (i == 11) { temperatureLate = forecast[i].temperature; break;}

                }
            }
            var bottomLongText = Lang.format("$1$$2$$3$%$4$", [temperatureNow.format("%+d"), temperatureMid.format("%+d"), temperatureLate.format("%+d"), precipitation.format("%d")]);

            Storage.setValue("topLongText", topLongText);
            Storage.setValue("bottomLongText", bottomLongText);
            morningDraw(topLongText, bottomLongText);
            morningSet = true;
        }

        var info = ActivityMonitor.getInfo();
        var bottomShort = View.findDrawableById("bottomShort") as Text;
        bottomShort.setText(Lang.format("$1$", [info.steps.format("%d")]));

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
