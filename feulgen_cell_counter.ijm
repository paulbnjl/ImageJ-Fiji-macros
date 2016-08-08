
/*
Macro : Cell counter - Feulgen
Version : 0.0.1
Author : Paul Bonijol
License : GNU/GPL v3
July 2016

*/


macro "Cell counter - Feulgen" {
	rename("image");
	selectWindow("image");
	run("RGB Color");
	selectWindow("image");
	image_height = getHeight();
	image_width = getWidth();
	image_area = image_height * image_width;

	run("Duplicate...", "title=mask");
	selectWindow("mask"); 
	run("8-bit");
	setOption("BlackBackground", false);
	run("Auto Threshold...", "method=IsoData white");
	run("Make Binary");
	setOption("BlackBackground", false);
	run("Convert to Mask");

	run("Set Measurements...", "area perimeter add redirect=None decimal=3");
	run("Analyze Particles...", "size=15-150 display exclude include add");

	selectWindow("image");
	number_of_rois = (roiManager("count")) - 1 ;
	setForegroundColor(240, 60, 0);
	
	for (i=0; i<=number_of_rois; i++) {
		roiManager("Select", i);
		roiManager("Draw");
	}
	
	run("8-bit");
	run("Make Binary");
	run("Outline");
	selectWindow("mask");
	run("Close");
}