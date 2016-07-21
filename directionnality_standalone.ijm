
/*
####################################################################
####################################################################
*/

/*
Macro : assisted collagen orientation and distribution assessment - standalone (calopix)
Version : 0.0.1
Author : Paul Bonijol
License : GNU/GPL v3
July 2016
*/

/*
In order to work, this macro requires the directionality plugin :
http://imagej.net/Directionality (included in fiji)

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
	rename ("img_dir");
	selectImage("img_dir");
	image = "img_dir";	
	run("8-bit");
	
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
	setResult("Corr. Angle", 0, epth_angle );
	setResult("Amount Dom. Dir.", 0, amount_val);
	setResult("Dispersion",0, std_val);
	setResult("Goodness", 0, fit_val);
	updateResults();	
}		