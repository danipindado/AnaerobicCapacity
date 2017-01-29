//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.FitContributor as Fit;

const CURR_HEMO_PERCENT_FIELD_ID = 3;
const LAP_HEMO_PERCENT_FIELD_ID = 4;
const AVG_HEMO_PERCENT_FIELD_ID = 5;

class MO2FitContributor {
    // Variables for computing averages
    hidden var mHPLapAverage = 0.0;
    hidden var mHPSessionAverage = 0.0;
    hidden var mLapRecordCount = 0;
    hidden var mSessionRecordCount = 0;
    hidden var mTimerRunning = false;

    // FIT Contributions variables
    hidden var mCurrentHPField = null;
    hidden var mLapAverageHPField = null;
    hidden var mSessionAverageHPField = null;

    // Constructor
    function initialize(dataField) {
        mCurrentHPField = dataField.createField("currHemoPerc", CURR_HEMO_PERCENT_FIELD_ID, Fit.DATA_TYPE_UINT16, { :nativeNum=>57, :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"%" });
        mLapAverageHPField = dataField.createField("lapHemoConc", LAP_HEMO_PERCENT_FIELD_ID, Fit.DATA_TYPE_UINT16, { :nativeNum=>87, :mesgType=>Fit.MESG_TYPE_LAP, :units=>"%" });
        mSessionAverageHPField = dataField.createField("avgHemoConc", AVG_HEMO_PERCENT_FIELD_ID, Fit.DATA_TYPE_UINT16, { :nativeNum=>98, :mesgType=>Fit.MESG_TYPE_SESSION, :units=>"%" });

        mCurrentHPField.setData(0);
        mLapAverageHPField.setData(0);
        mSessionAverageHPField.setData(0);

    }

    function compute(currentHemoPercent) {
            var HemoPerc = currentHemoPercent;

            // Saturated Hemoglobin Percent is stored in 1/10ths % fixed point
            mCurrentHPField.setData( HemoPerc  );

            if( mTimerRunning ) {
                // Update lap/session data and record counts
                mLapRecordCount++;
                mSessionRecordCount++;
                mHPLapAverage += HemoPerc;
                mHPSessionAverage += HemoPerc;

                // Updatea lap/session FIT Contributions
                mLapAverageHPField.setData( mHPLapAverage/mLapRecordCount );
                mSessionAverageHPField.setData( mHPSessionAverage/mSessionRecordCount );
            }
        
    }


    function setTimerRunning(state) {
        mTimerRunning = state;
    }

    function onTimerLap() {
        mLapRecordCount = 0;
        mHCLapAverage = 0.0;
        mHPLapAverage = 0.0;
    }

    function onTimerReset() {
        mSessionRecordCount = 0;
        mHCSessionAverage = 0.0;
        mHPSessionAverage = 0.0;
    }

}