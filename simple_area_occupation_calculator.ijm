
/*
####################################################################
####################################################################
*/


/*
Macro : simple area occupation calculator
Version : 0.0.1
Author : Paul Bonijol
License : GNU/GPL v3
July 2016
*/


/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
####################################################################
####################################################################
*/
macro "Simple Area Occupation Calculator"{		
	requires("1.44");	
	showMessage("Warning !", "This macro is highly EXPERIMENTAL, and thus provided WITHOUT ANY WARRANTY. The author has no liability of any sort, and there is no guarantee that the results are accurate.");
	image = getTitle();
	selectWindow(image);	
	TOTAL_AREA = getHeight()*getWidth();
	run("8-bit");
	run("Auto Threshold", "method=IsoData white");
	run("Set Measurements...", "area redirect=None decimal=3");		
	run("Create Selection");
	run("Make Inverse");
	run("Measure");
	BLACK_AREA = getResult("Area", 0);
	OCP_RATIO = ((BLACK_AREA/TOTAL_AREA)*100);
	run("Clear Results");
	setResult("Occupied area", 0, BLACK_AREA);
	setResult("Total area", 0, TOTAL_AREA);
	setResult("Occupation %", 0, OCP_RATIO);
	saveAs("Results",  dir + image  + "_area_" +  ".xls");
	
	selectWindow(image);
	for (i=0; i<=number_of_rois; i++) {
		roiManager("Select", i);
		roiManager("Draw");
	}
	
	run("8-bit");
	run("Make Binary");
	run("Outline");
}	