/*
####################################################################
####################################################################
*/

/*
Macro : Local Orientation Detector
Version : 0.0.1
Author : Paul Bonijol
License : GNU/GPL v3
August 2016

*/


/*
In order to work, this macro requires the directionality plugin :
http://imagej.net/Directionality (included in fiji)
Modified to remove all except the result table (and pool some parameters in it also) :
https://github.com/paulbnjl/ImageJ-Fiji-macros/tree/master/Directionnality_recomp_pour_calopix
Many thanks to 	Jean-Yves Tinevez (directionality developper) !
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


macro "Local Orientation detector" {
	
	requires("1.46");	
	showMessage("Warning !", "This macro is highly EXPERIMENTAL, and thus provided WITHOUT ANY WARRANTY. The author has no liability of any sort, and there is no guarantee that the results are accurate.");
	Dialog.create("Menu");
	Dialog.addMessage("Options :");
	Dialog.addSlider("ROI number per line/column (LxC): ", 1, 25, 3);
	Dialog.addCheckbox("Save results ? ", false);
	Dialog.show();
	window_f = Dialog.getNumber();
	save_choice = Dialog.getCheckbox();
	degreechar = fromCharCode(0xB0);
	image = getTitle();
	rename("image");
	selectWindow("image");
	image_height = getHeight();
	image_width = getWidth();
	image_area = image_height * image_width;
	
	window_h = (image_height/window_f);
	window_w = (image_width/window_f);
	TOTAL_AREA = window_h * window_w;
	fontsize = window_h/5;
	fontsize2 = 0.5 * fontsize;
	setColor(0);
	setLineWidth(1);
	setJustification("center");
	
	newImage("ORIENTATION_MAP", "RGB white", image_width, image_height, 1);
	
	pos_x = 0;
	pos_y = 0;
	count = 1;
	epth_angle = 0;
	epth_amount_inv = 0;
	data_points = 90;
	data_points_start = -90;
	window_max_angle_array = newArray("window_max_angle_array");
	window_amount_angle_array = newArray("window_amount_angle_array");
	window_fit_quality_array = newArray("window_fit_quality_array");
	window_angle_dispersion_array = newArray("window_angle_dispersion_array");
	orientation_class_array = newArray("orientation_class_array");
	
	for (i=0; i <= ((window_f*window_f)-1); i++) {
		selectWindow("image");
		makeRectangle(pos_x,pos_y, window_w, window_h);
		run("Duplicate...", "title=ROI");
		selectWindow("ROI");
		run("8-bit");
		run("Directionality ", "method=[Local gradient orientation] nbins=data_points histogram=data_points_start display_table");
		
		center_val = getResult("Center", data_points);
		amount_val = getResult("Amount", data_points);
		std_val = getResult("Dispersion", data_points);
		fit_val = getResult("Goodness", data_points);
		
		window_max_angle_array_temp = newArray(lengthOf(window_max_angle_array)+1);
		window_amount_angle_array_temp = newArray(lengthOf(window_amount_angle_array)+1);
		window_fit_quality_array_temp = newArray(lengthOf(window_fit_quality_array)+1);
		window_angle_dispersion_array_temp = newArray(lengthOf(window_angle_dispersion_array)+1);
		orientation_class_array_temp = newArray(lengthOf(orientation_class_array)+1);
		
		for (d=0; d<lengthOf(window_max_angle_array);d++){
			window_max_angle_array_temp[d] = window_max_angle_array[d];
			window_amount_angle_array_temp[d] = window_amount_angle_array[d];
			window_fit_quality_array_temp[d] = window_fit_quality_array[d];
			window_angle_dispersion_array_temp[d] = window_angle_dispersion_array[d];
			orientation_class_array_temp[d] = orientation_class_array[d];
		}
		
		window_max_angle_array_temp[lengthOf(window_max_angle_array)-1]=center_val;
		window_amount_angle_array_temp[lengthOf(window_amount_angle_array)-1]=amount_val;
		window_angle_dispersion_array_temp[lengthOf(window_angle_dispersion_array)-1]=std_val;
		window_fit_quality_array_temp[lengthOf(window_fit_quality_array)-1]=fit_val;
		
		if (std_val < 5) {
			orientation_class_array_temp[lengthOf(orientation_class_array)-1]	= "Highly oriented (dispersion <5" + degreechar + ")";
			text_string_ocp = "Highly oriented (dispersion <5" + degreechar + ")";
		}
		
		else if ((std_val >= 5) && (std_val < 11)) {
			orientation_class_array_temp[lengthOf(orientation_class_array)-1]	= "Oriented (5" + degreechar + " < dispersion < 11" + degreechar + ")";
			text_string_ocp = "Oriented (5" + degreechar + " < dispersion < 11" + degreechar + ")";
		}
		
		else if ((std_val >= 11) && (std_val < 31)) {
			orientation_class_array_temp[lengthOf(orientation_class_array)-1]	= "Oriented (11" + degreechar + " < dispersion < 31" + degreechar + ")";
			text_string_ocp = "Oriented (11" + degreechar + " < dispersion < 31" + degreechar + ")";
		}
		
		else if (std_val >= 31) {
			orientation_class_array_temp[lengthOf(orientation_class_array)-1]	= "Not oriented (dispersion > 31" + degreechar + ")";
			text_string_ocp = "Not oriented (dispersion > 31" + degreechar + ")";
		}
		
		else if (std_val == 0) {
			orientation_class_array_temp[lengthOf(orientation_class_array)-1]	= "N/A";
			text_string_ocp = "N/A";
		}
		
		window_angle_dispersion_array = window_angle_dispersion_array_temp;
		orientation_class_array = orientation_class_array_temp;
		window_max_angle_array = window_max_angle_array_temp;
		window_amount_angle_array = window_amount_angle_array_temp;
		window_fit_quality_array = window_fit_quality_array_temp;
				
		text_string_params_1 = "Max angle :" + round(center_val) + degreechar;
		text_string_params_2 = "Dispersion around max :" + round(std_val) ;
		text_string_params_3 = "Fit quality : " + fit_val;

		selectWindow("ORIENTATION_MAP");
		
		text_string = "ROI " + i + 1; 
		setFont("Arial Narrow", fontsize, "bold");
		drawString(text_string, (pos_x + (window_w/2)), (pos_y +(window_h/2)));
		drawRect(pos_x, pos_y, window_w, window_h);
				
		init_pos_arrow_x = pos_x + (0.4 * floor(window_w));
		init_pos_arrow_y = pos_y  + (0.15 * floor(window_h));
		final_pos_arrow_x = pos_x + (0.6 * floor(window_w));
		final_pow_arrow_y = init_pos_arrow_y - (tan((round(center_val) * PI)/180) * (final_pos_arrow_x - init_pos_arrow_x));
		
		makeArrow(init_pos_arrow_x, init_pos_arrow_y, final_pos_arrow_x, final_pow_arrow_y , "width=1 size=5 color=Black style=Filled");
		run("Draw");
		run("Select None");
		
		selectWindow("ORIENTATION_MAP");
		setFont("Arial Narrow", fontsize2, "normal");
		setJustification("center");
		drawString(text_string_ocp, (pos_x + (window_w/2)), (pos_y + (fontsize2 + 5) + (window_h/2)));
		drawString(text_string_params_1, (pos_x + (window_w/2)), (pos_y + ((2*fontsize2)+5) + (window_h/2)));
		drawString(text_string_params_2, (pos_x + (window_w/2)), (pos_y + ((3*fontsize2)+5) + (window_h/2)));
		drawString(text_string_params_3, (pos_x + (window_w/2)), (pos_y + ((4*fontsize2)+5) + (window_h/2)));
		
		selectWindow("ROI");
		run("Close");
		count +=1;
		pos_x += window_w;
		
		if (count == window_f + 1) {
			pos_x = 0;
			pos_y += window_h;
			count = 1;
		}
		run("Clear Results");
		selectWindow("image");
	}
	max_angle_avg = 0;
	amount_avg = 0;
	dispersion_avg = 0;
	fit_quality_avg = 0;
	
	for (i=1; i<(window_f*window_f)+1; i++) {
		setResult("ROI number", i-1, i);
		
		setResult("Max angle", i-1, window_max_angle_array[i-1]);
		max_angle_avg += window_max_angle_array[i];
		
		setResult("Amount of vectors following max angle", i-1,window_amount_angle_array[i-1]);
		amount_avg += window_amount_angle_array[i];
		
		setResult("Dispersion around max angle (STDev)", i-1,window_angle_dispersion_array[i-1]);
		dispersion_avg += window_angle_dispersion_array[i-1];
		
		setResult("Goodness of fit (gaussian)", i-1, window_fit_quality_array[i-1]);
		fit_quality_avg += window_fit_quality_array[i-1];
		
		setResult("Orientation",i-1, orientation_class_array[i-1]);
	}
	
	max_angle_avg = max_angle_avg/(window_f*window_f);
	amount_avg = amount_avg/(window_f*window_f);
	dispersion_avg = dispersion_avg/(window_f*window_f);
	fit_quality_avg = fit_quality_avg/(window_f*window_f);
	last_RS_table_POS = (window_f*window_f);
	
	setResult("ROI number",last_RS_table_POS, "Average");
	setResult("Max angle", last_RS_table_POS, max_angle_avg);
	setResult("Amount of vectors following max angle", last_RS_table_POS, amount_avg);
	setResult("Dispersion around max angle (STDev)", last_RS_table_POS, dispersion_avg);
	setResult("Goodness of fit (gaussian)", last_RS_table_POS, fit_quality_avg);
	setResult("Orientation", last_RS_table_POS, "N/A");
	
	updateResults();
	run("Select None");
	
	imageCalculator("Add create 32-bit", "ORIENTATION_MAP","image");
	selectWindow("ORIENTATION_MAP");
	run("Close");
	selectWindow("Result of ORIENTATION_MAP");
	rename("ORIENTATION_MAP");
	
	if (save_choice == true) {
		dir = getDirectory("Choose where to save.");
		selectWindow("Results");		
		saveAs("Results",  dir + image + ".xls");
		selectWindow("ORIENTATION_MAP");
		saveAs("png",  dir + image + "_ROI_MAP_" + ".png");
	}
}	