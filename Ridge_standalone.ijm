
/*
####################################################################
####################################################################
*/


/*
Macro : ridge detection - standalone
Version : 0.0.1
Author : Paul Bonijol
License : GNU/GPL v3
July 2016

Best suited for high resolution, high contrast microscope images
(for instance, 20x magnification <-> 4000x4000px .tif, with tissue 
stained by, for instance, picrosirius red)
*/

/*
In order to work, this macro the ridge detection plugin :
http://imagej.net/Ridge_Detection
And all of it's dependecies.

For more informations on how these plugin are working, please consult :
Steger, C., 1998. An unbiased detector of curvilinear structures. IEEE Transactions 
on Pattern Analysis and Machine Intelligence, 20(2), pp.113–125.
And the directionality page linked above.

Many thanks to Thorsten Wagner/Mark Hiner (Ridge developpers) !
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
macro "Ridge detection results processing - standalone "{
	requires("1.48");	
	showMessage("Warning !", "This macro is highly EXPERIMENTAL, and thus provided WITHOUT ANY WARRANTY. The author has no liability of any sort, and there is no guarantee that the results are accurate.");
	
	Dialog.create("Menu");
	Dialog.addMessage("Options :");
	Dialog.addCheckbox("Plot values ? ", false);
	Dialog.addCheckbox("Save results ? ", false);
	Dialog.show();
	
	plot_val = Dialog.getCheckbox();
	save_choice = Dialog.getCheckbox();
	
	
	
	image = getTitle();
	selectWindow(image);

	run("RGB Color");
	selectWindow(image);
	image_height = getHeight();
	image_width = getWidth();
	image_area = image_height * image_width;

	run("8-bit");
	setOption("BlackBackground", false);

	selectWindow(image);
	run("Set Measurements...", "min redirect=None decimal=3");
	run("Measure");
	GREY_MIN = getResult("Min", 0);
	GREY_MAX = getResult("Max",0);
	run("Clear Results");
	selectWindow("Results");
	run("Close");

	selectWindow(image);
	REF_FIBER_LENGTH = 15 // 15 px
	run("Ridge Detection", "line_width=REF_FIBER_LENGTH high_contrast=GREY_MAX low_contrast=GREY_MIN darkline estimate_width displayresults add_to_manager method_for_overlap_resolution=SLOPE");		

	selectWindow("Results");

	fiber_width_array = newArray("fiberwidth");
	fiber_length_array = newArray("fiberlength");
	fiber_angle_array = newArray("fiberangle");

	for (h=0; h<nResults; h++){
		fiberlength = getResult("Length", h);
		fiberwidth = getResult("Line width", h);
		fiberangle = getResult("Angle of normal", h);
		
		if (h != 0){
			contour_ID_prev = contourID;			
		}
	
		else {
			contour_ID_prev = 0;				
		}
	
		contourID = getResult("Contour ID", h);
		fiber_width_array_temp = newArray(lengthOf(fiber_width_array)+1);
		fiber_length_array_temp = newArray(lengthOf(fiber_length_array)+1);
		fiber_angle_array_temp = newArray(lengthOf(fiber_angle_array)+1);

		for (d=0; d<lengthOf(fiber_width_array);d++){
			fiber_width_array_temp[d]=fiber_width_array[d];
			fiber_length_array_temp[d]=fiber_length_array[d];
			fiber_angle_array_temp[d]=fiber_angle_array[d];
		}

		if (contourID != contour_ID_prev){
			fiber_width_array_temp[lengthOf(fiber_width_array)-1]=fiberwidth;
			fiber_length_array_temp[lengthOf(fiber_length_array)-1]=fiberlength;
			fiber_angle_array_temp[lengthOf(fiber_angle_array)-1]=fiberangle;
		}
		
		fiber_width_array = fiber_width_array_temp;
		fiber_length_array = fiber_length_array_temp;
		fiber_angle_array = fiber_angle_array_temp;
	
	}
	
	fiber_length_array = Array.slice(fiber_length_array,1);
	fiber_width_array = Array.slice(fiber_width_array,1);
	fiber_angle_array = Array.slice(fiber_angle_array,1);

	run("Clear Results");
	selectWindow("Results");
	run("Close");

	selectWindow("Junctions");
	Nb_of_junctions_detected = getValue("results.count");
	run("Close");

	val_count = 0;
	for (i=0;i<lengthOf(fiber_length_array);i++){
		if (fiber_length_array[i] != 0) {
			if (fiber_width_array[i] > 1) {
				setResult("Length", val_count, fiber_length_array[i]);
				setResult("Width", val_count, fiber_width_array[i]);
				setResult("Angle", val_count, fiber_angle_array[i]);
				val_count +=1;
			}
		}	
	}
	updateResults();
	
	nb_obj = nResults;
	Mean_obj_length = 0;
	Mean_obj_width = 0;
	Mean_obj_angle = 0;

	for (row=0; row < nb_obj; row++) {
		Mean_obj_length = Mean_obj_length + getResult("Length", row);
		Mean_obj_width = Mean_obj_width + getResult("Width", row);
		Mean_obj_angle = Mean_obj_angle + getResult("Angle", row);		
	}

	Mean_obj_length = Mean_obj_length/nb_obj;
	Mean_obj_width = Mean_obj_width/nb_obj;
	Mean_obj_angle = Mean_obj_angle/nb_obj;

	setResult("Number of objects", 0, nb_obj);
	setResult("Mean length", 0, Mean_obj_length);
	setResult("Mean width", 0, Mean_obj_width);
	setResult("Mean angle", 0, Mean_obj_angle);
	setResult("Number of junctions", 0, Nb_of_junctions_detected);
	updateResults();
	
	if (plot_val == true) {
		val_number_fiber_array = newArray("valnumber");
		for (bb=0; bb<lengthOf(fiber_width_array); bb++){
			val_number_fiber_array_temp = newArray(lengthOf(val_number_fiber_array)+1);
			for (b=0; b<lengthOf(val_number_fiber_array); b++){
			val_number_fiber_array_temp[b] = val_number_fiber_array[b];
			}
			val_number_fiber_array_temp[lengthOf(val_number_fiber_array)-1]=bb;
			val_number_fiber_array = val_number_fiber_array_temp;
		}
			
		val_number_fiber_array	= Array.slice(val_number_fiber_array,1);
		Array.getStatistics(val_number_fiber_array, val_min, val_max, val_mean, val_std);
		Array.getStatistics(fiber_width_array, width_min, width_max, width_mean, width_std);
		
		fiber_plot_name = "Fiber distribution plot";
		Plot.create(fiber_plot_name, "Fibers", "Size", val_number_fiber_array, fiber_width_array);
		Plot.setLimits(val_min,val_max,width_min,width_max);
		Plot.setColor("red");
		Plot.show();
	}	
	
	if (save_choice == true) {
		dir = getDirectory("Choose where to save."); 
		saveAs("Results",  dir + image + ".xls");	
	}
}