
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
	requires("1.46");	
	showMessage("Warning !", "This macro is highly EXPERIMENTAL, and thus provided WITHOUT ANY WARRANTY. The author has no liability of any sort, and there is no guarantee that the results are accurate.");
	Dialog.create("Menu");
	Dialog.addMessage("Options :");
	Dialog.addCheckbox("Polarisation ? ", false);
	Dialog.addCheckbox("Save results ? ", false);
	Dialog.show();
	pola = Dialog.getCheckbox();
	save_choice = Dialog.getCheckbox();
	
	image = getTitle();
	
	selectWindow(image);
	if (pola == true) {
		run("Duplicate...", "title=img_orange");
	}
	
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
	if (pola == true) {
		selectWindow("img_orange");
		run("Split Channels");
		selectWindow("img_orange" + " (blue)");
		run("Close");
		selectWindow("img_orange" + " (green)");
		run("Close");
		selectWindow("img_orange" + " (red)");
		run("Auto Threshold...", "method=IsoData white");
		run("Analyze Particles...", "  show=[Overlay Masks] display exclude include add");
		
		ORANGE_AREA = 0;
		for (i=0; i<nResults; i++) {
		 ORANGE_AREA += getResult("Area", i);
		}
		run("Clear Results");
		
		ORANGE_AREA_PERCENTAGE = ((ORANGE_AREA/TOTAL_AREA)*100);
		
		GREEN_AREA = TOTAL_AREA - (ORANGE_AREA+(TOTAL_AREA-BLACK_AREA));
		GREEN_AREA_PERCENTAGE = ((GREEN_AREA/TOTAL_AREA)*100);
		
		setResult("Orange (collagen I) area", 0, ORANGE_AREA);
		setResult("Orange (collagen I) %", 0, ORANGE_AREA_PERCENTAGE);
		setResult("Green (collagen III) area", 0, GREEN_AREA);
		setResult("Green (collagen III) %", 0, GREEN_AREA_PERCENTAGE);
	}
	
	setResult("Occupied area", 0, BLACK_AREA);
	setResult("Total area", 0, TOTAL_AREA);
	setResult("Occupation %", 0, OCP_RATIO);
	updateResults();
	
	if (save_choice == true) {
		dir = getDirectory("Choose where to save."); 
		saveAs("Results",  dir + image + ".xls");	
	}
}	