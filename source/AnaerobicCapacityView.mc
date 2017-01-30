// W Prime Bal on Connect IQ / 2015 - 2016 Gregory Chanez
// Find details about this software on <www.nakan.ch> (french) or 
// <www.trinakan.com> (english)
// Enjoy your ride !
// *
// * This program is free software: you can redistribute it and/or modify
// * it under the terms of the GNU General Public License as published by
// * the Free Software Foundation, either version 3 of the License, or
// * (at your option) any later version.
// *
// * This program is distributed in the hope that it will be useful,
// * but WITHOUT ANY WARRANTY; without even the implied warranty of
// * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// * GNU General Public License for more details.
// *
// * You should have received a copy of the GNU General Public License
// * along with this program.  If not, see <http://www.gnu.org/licenses/>.
// *
// - Most of the source here is adapted from GoldenCheetah wprime.cpp
// - <http://www.goldencheetah.org> software, also available under GPL.
// - Thanks to their authors, and specially to Mark Liversedge for his
// - blog post about W Prime implementation <http://markliversedge.blogspot.ch/>

using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Application as App;

class AnaerobicCapacityView extends Ui.SimpleDataField {

    // Constants
    var CP;
    var WPRIME;
    var FORMULA;

    // Variables
        // Fit Contributor
    hidden var mFitContributor;
    
    var elapsedSec = 0;
    var pwr = 0;
    var powerValue;
    var I = 0;
    var output;
    var AnaerobicCapacity = 0;
    var AnaerobicCapacitypc = 100;
    var totalBelowCP = 0;
    var countBelowCP = 0;
    var TAUlive = 0;
    var W = 0;
    
    //! Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        CP = App.getApp().getProperty("CP").toNumber();
        WPRIME = App.getApp().getProperty("WPRIME").toNumber();
        FORMULA = App.getApp().getProperty("FORMULA").toNumber();
        
        // If the formula is differential, initial value of w'bal is WPRIME.
        if (FORMULA == 1) {
            AnaerobicCapacity = WPRIME;
        }
        
        // Change the field title with the compute method choosen
        if (FORMULA == 0) {
            label = "%AWC (int)";
        }
        else {
            label = "%AWC (diff)";
        }
        mFitContributor = new MO2FitContributor(self);
    }

    //! The given info object contains all the current workout
    //! information. Calculate a value and return it in this method.
    function compute(info) {
        // See Activity.Info in the documentation for available information.
        
        // Check if the activity is started or not
        if (info.elapsedTime != null && info.elapsedTime != 0) {
            
            // Check if power is negaative or null, and normalize it to 0.
            if (info.currentHeartRate == null) {
                // Power data is null
                pwr = 0;
            }
            else if (info.currentHeartRate < 0) {
                // Power data is below 0
                pwr = 0;
            }
            else {
                // Power data is OK
                pwr = info.currentHeartRate;
            }
            
            // Method by differential equation Froncioni / Clarke
            if (FORMULA == 1) {
                if (pwr < CP) {
                  AnaerobicCapacity = AnaerobicCapacity + (CP-pwr)*(WPRIME-AnaerobicCapacity)/WPRIME.toFloat();
                }
                else {
                  AnaerobicCapacity = AnaerobicCapacity + (CP-pwr);
                }
            }
            
            // Method by integral formula Skiba et al
            else {
                // powerValue
                if (pwr > CP) {
                    powerValue = (pwr - CP);
                }
                else {
                    powerValue = 0;
                }
                // Compute TAU
                if (pwr < CP) {
                    totalBelowCP += pwr;
                    countBelowCP++;
                }
                if (countBelowCP > 0) {
                    TAUlive = 546.00 * Math.pow(Math.E, -0.01*(CP - (totalBelowCP/countBelowCP))) + 316;
                }
                else {
                    TAUlive = 546 * Math.pow(Math.E, -0.01*(CP)) + 316;
                }

                // Start compute W'Bal
                I += Math.pow(Math.E, (elapsedSec.toFloat()/TAUlive.toFloat())) * powerValue;
                output = Math.pow(Math.E, (-elapsedSec.toFloat()/TAUlive.toFloat())) * I;
                AnaerobicCapacity = WPRIME - output;
            }
            
            // Compute a percentage from raw values
            AnaerobicCapacitypc = AnaerobicCapacity * (100/WPRIME.toFloat());
            
            // One more second in life...
            elapsedSec++;
        }
        else {
            // Initial display, before the the session is started
            return CP + "|" + WPRIME;
        }

        // For debug purposes on the simulator only
        //Sys.println(FORMULA + ";" + elapsedSec + ";" + pwr + ";" + AnaerobicCapacity + ";" + TAUlive);
        
        // Return the value to the watch
        mFitContributor.compute(AnaerobicCapacitypc);
        return AnaerobicCapacitypc.format("%.1f");
    }
}