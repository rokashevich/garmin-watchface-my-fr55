import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Application.Storage;
using Toybox.Time;
using Toybox.Time.Gregorian;

using Toybox.UserProfile;
using Toybox.System;
using Toybox.SensorHistory;

using Toybox.Activity;
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

    function morningDraw(topLongText as String, bottomLongText as String, stressText as String) {
        var label = View.findDrawableById("topLong") as Text;
        label.setText(topLongText);

        label = View.findDrawableById("bottomLong") as Text;
        label.setText(bottomLongText);

        label = View.findDrawableById("stressLabel") as Text;
        label.setText(stressText);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        var activeCount = 0;
        var userActivityIterator = UserProfile.getUserActivityHistory();
        var activity = userActivityIterator.next();
        var today = Time.today();
        var week = Gregorian.info(today, Time.FORMAT_SHORT).day_of_week;
        if (week == 1) { week = 8; }
        week = week - 2;
        week = today.subtract(new Time.Duration(86400*week));
        //System.println(today);
        //System.println(week);
        //week = week.day_of_week;

        var durationTotal = 0;
        var weekTotal = 0;
        activeCount = 0;
        //var curDay = -1;
        while (activity != null) {
            activeCount += 1;
            if (activity.startTime != null && activity.duration != null) {
                var startTime = activity.startTime.add(new Time.Duration(631065600));
                if (startTime.greaterThan(today)) {
                    durationTotal += activity.duration.value();
                    //curDay = activeCount;
                }
                if (startTime.greaterThan(week)) {
                    weekTotal += activity.duration.value();
                }
            }
            activity = userActivityIterator.next();
        }
        durationTotal = (durationTotal / 60).toNumber();
        weekTotal = (weekTotal / 60).toNumber();

        var topShort = View.findDrawableById("topShort") as Text;
        topShort.setText(Lang.format("$1$/$2$/$3$", [
            durationTotal.format("%d"),
            weekTotal.format("%d"),
            activeCount.format("%d")]));
            //curDay.format("%d")]));

        if (morningSet == false) {
            var topLongText = Storage.getValue("topLongText");
            var bottomLongText = Storage.getValue("bottomLongText");
            var stressText = Storage.getValue("stressText");
            if (topLongText == null || bottomLongText == null || stressText == null) {
                return;
            }
            morningDraw(topLongText, bottomLongText, stressText);
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // При каждом обновлении выводим текущий пульс
        var curHR = Activity.getActivityInfo().currentHeartRate;
        if (curHR != null) {
            var currentHRLabel = View.findDrawableById("CurrentHRLabel") as Text;
            currentHRLabel.setText(Lang.format("$1$", [curHR.format("%d")]));
        }

        // Get and show the current time
        var clockTime = System.getClockTime();
        var viewTime = View.findDrawableById("TimeLabel") as Text;
        viewTime.setText(Lang.format("$1$$2$", [clockTime.hour, clockTime.min.format("%02d")]));
        var secondsLabel = View.findDrawableById("SecondsLabel") as Text;
        secondsLabel.setText(Lang.format("$1$", [clockTime.sec.format("%d")]));

        // Get and show the current date
        var date = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateString = Lang.format("$1$/$2$", [date.month.format("%02d"), date.day.format("%02d")]);
        var viewDate = View.findDrawableById("DateLabel") as Text;
        viewDate.setText(dateString);

        // Get and show the current battery
        var battString = Lang.format("$1$%", [System.getSystemStats().battery.format("%d")]);
        var battView = View.findDrawableById("BattLabel") as Text;
        battView.setText(battString);

        // var a = null;
        // var b = 0;
        // if (a>b){System.println(1);} else {System.println(2);}

        if (clockTime.hour == 6 && clockTime.min == 0) {
        //if (clockTime.hour == 21) {
        //if (clockTime.hour == 14 && clockTime.min == 0) {

            // HRV
            var stressIt = Toybox.SensorHistory.getStressHistory({});
            var stressDat = stressIt.next();
            var stressAvg = 0;
            var stressCnt = 0;
            while (stressDat != null) {
                stressAvg += stressDat.data;
                stressCnt += 1;
                stressDat = stressIt.next();
            }
            if (stressCnt != 0) {stressAvg = (stressAvg / stressCnt).toNumber();}
            stressDat = Lang.format("$1$", [stressAvg.format("%d")]);


            var avg = 0;
            var min1 = 999;
            var min2 = 999;
            var max1 = 0;
            var max2 = 0;
            var sum = 0;
            var count = 0;

            var iterator = ActivityMonitor.getHeartRateHistory(null, false); // new Time.Duration(3600*24)
            for (var sample = iterator.next(); sample != null; sample = iterator.next()) {
                if (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    if (sample.heartRate < min1) {
                        min2 = min1;
                        min1 = sample.heartRate;
                    } else if (sample.heartRate < min2) {
                        min2 = sample.heartRate;
                    }
                    if (sample.heartRate > max1) {
                        max2 = max1;
                        max1 = sample.heartRate;
                    } else if (sample.heartRate > max2) {
                        max2 = sample.heartRate;
                    }
                    sum += sample.heartRate;
                    count += 1;
                }
            }
            if (count > 0) {
                avg = sum/count;
            }
            var topLongText = Lang.format("$1$-$2$ $3$ $4$", [
                min2.format("%d"),
                max2.format("%d"),
                avg.format("%d"),
                UserProfile.getProfile().restingHeartRate.format("%d")]);

            var bottomLongText = "-";
            var forecast = Toybox.Weather.getHourlyForecast();
            if(forecast != null)
            {
                var temperatureNow = Toybox.Weather.getCurrentConditions();
                if (temperatureNow != null) {
                    temperatureNow = temperatureNow.temperature;
                }

                var precipitation = 0;
                var temperatureLast = 88;
                for (var i = 0; i < forecast.size(); ++i)
                {
                    if (forecast[i].precipitationChance != null &&
                        forecast[i].precipitationChance > precipitation) {
                        precipitation = forecast[i].precipitationChance;
                    }
                    temperatureLast = forecast[i].temperature;

                }
                if (temperatureNow != null) {
                    bottomLongText = Lang.format("$1$$2$%$3$", [temperatureNow.format("%+d"), temperatureLast.format("%+d"), precipitation.format("%d")]);
                }
            }

            Storage.setValue("topLongText", topLongText);
            Storage.setValue("bottomLongText", bottomLongText);
            Storage.setValue("stressText", stressDat);
            morningDraw(topLongText, bottomLongText, stressDat);
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
