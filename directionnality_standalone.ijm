
/*
####################################################################
####################################################################
*/

/*
Macro : assisted collagen orientation and distribution assessment - standalone
Version : 0.0.1
Author : Paul Bonijol
License : GNU/GPL v3
July 2016
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

macro "assisted collagen orientation and distribution assessment - standalone" {	
	requires("1.46");
	showMessage("Warning !", "This macro is highly EXPERIMENTAL, and thus provided WITHOUT ANY WARRANTY. The author has no liability of any sort, and there is no guarantee that the results are accurate.");
	Dialog.create("Menu");
	Dialog.addMessage("Options :");
	Dialog.addCheckbox("Set reference axis ?", false);
	Dialog.addCheckbox("Plot (normal values) ? ", false);
	Dialog.addCheckbox("Plot (corrected values) ? ", false);
	Dialog.addCheckbox("Save results ? ", false);
	Dialog.show();
	
	draw_line = Dialog.getCheckbox();
	plot_norm_val = Dialog.getCheckbox();
	plot_corr_val = Dialog.getCheckbox();
	save_choice = Dialog.getCheckbox();
	
	im_name = getTitle();
	rename ("img_dir");
	selectImage("img_dir");
	image = "img_dir";	
	run("8-bit");
	
	if (draw_line == true) {
		setTool("line"); 
		waitForUser( "Draw a line as the reference axis and then press OK.");
		while ((selectionType() !=5)){
			setTool("line");
		}

		run("Set Measurements...", "  redirect=None decimal=3");
		run("Measure");

		selectWindow(image);
		epth_angle = getResult("Angle", 0);

		if (epth_angle <= -90) {
			epth_angle += 180;
		}
		
		else if (epth_angle >= 90) {
			epth_angle -= 180 ;	
		}
		
		epth_amount_inv = -epth_angle;
		run("Clear Results");
	
	}
	else {
		epth_angle = 0;
		epth_amount_inv = 0;
	}

	data_points = 90;
	data_points_start = -90;

	run("Directionality ", "method=[Local gradient orientation] nbins=data_points histogram=data_points_start display_table");

	direction_array = newArray("dir");
	amount_array = newArray("amt");
	fit_array = newArray("fit");
	for (j=0; j<data_points; j++){
		direction = getResult("Direction", j);
		amount = getResult("Amount", j);
		fit = getResult ("Fit", j);
		
		direction_array_temp = newArray(lengthOf(direction_array)+1);
		amount_array_temp = newArray(lengthOf(amount_array)+1);
		fit_array_temp = newArray(lengthOf(fit_array)+1);
		
		for (k=0; k<lengthOf(direction_array);k++){
			direction_array_temp[k]=direction_array[k];
			amount_array_temp[k]=amount_array[k];
			fit_array_temp[k]=fit_array[k];
		}
		direction_array_temp[lengthOf(direction_array_temp)-1]=direction;	
		direction_array = direction_array_temp;
		
		amount_array_temp[lengthOf(amount_array_temp)-1]=amount;
		amount_array = amount_array_temp;
		
		fit_array_temp[lengthOf(fit_array_temp)-1]=fit;
		fit_array = fit_array_temp;			
	}

	direction_array = Array.slice(direction_array,1);
	amount_array = Array.slice(amount_array,1);
	fit_array = Array.slice(fit_array,1);

	direction_array_corrected = newArray(lengthOf(direction_array));
	for (i=0;i<lengthOf(direction_array_corrected);i++){
		direction_array_corrected[i] = direction_array[i];
		direction_array_corrected[i] += epth_amount_inv;
	}
	
	selectWindow("Results");
	center_val = getResult("Center", data_points);
	amount_val = getResult("Amount", data_points);
	std_val = getResult("Dispersion", data_points);
	fit_val = getResult("Goodness", data_points);	
	
	run("Clear Results");
	
	for (i=0;i<lengthOf(direction_array);i++){
		setResult("Angle", i, direction_array[i]);
		setResult("Angle (Corr.)", i, direction_array_corrected[i]);
	}
	updateResults();
	
	for (i=0;i<lengthOf(amount_array);i++){
		setResult("Amount", i, amount_array[i]);
	}
	updateResults();
	
	for (i=0;i<lengthOf(fit_array);i++){
		setResult("Fit", i, fit_array[i]);
	}
	updateResults();
	

	setResult("#", 0, 0);
	setResult("Dom. Dir. Angle", 0, center_val);
	setResult("Corr. Angle", 0, epth_angle);
	setResult("Amount Dom. Dir.", 0, amount_val);
	setResult("Dispersion",0, std_val);
	setResult("Goodness", 0, fit_val);
	updateResults();
	
	Array.getStatistics(amount_array, amount_min, amount_max, amount_mean, amount_std);
	Array.getStatistics(direction_array, dir_min, dir_max, dir_mean, dir_std);
	Array.getStatistics(direction_array_corrected, dir_corr_min, dir_corr_max, dir_corr_mean, dir_corr_std);
	
	if (plot_norm_val == true) {
		angle_plot_name = "Angle plot";
		Plot.create(angle_plot_name, "Angle", "Amount", direction_array, amount_array);
		Plot.setLimits(dir_corr_min,dir_corr_max,0,amount_max);
		Plot.setColor("blue");
		Plot.add("square", direction_array, fit_array);
		Plot.setColor("red");
		Plot.show();
	}
	
	if (plot_corr_val == true) {
		corr_angle_plot_name = "Corrected angle plot";
		Plot.create(corr_angle_plot_name, "Angle", "Amount", direction_array_corrected, amount_array);
		Plot.setLimits(dir_corr_min,dir_corr_max,0,amount_max);
		Plot.setColor("green");
		Plot.add("triangles", direction_array_corrected, fit_array);
		Plot.setColor("red");
		Plot.show();
	}
	
	if (save_choice == true) {
		dir = getDirectory("Choose where to save."); 
		saveAs("Results",  dir + im_name + ".xls");	
	}
}		