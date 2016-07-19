
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

Best suited for high resolution, high contrast microscope images
(for instance, 20x magnification <-> 4000x4000px .tif, with tissue 
stained by, for instance, picrosirius red)
*/

/*
In order to work, this macro requires the directionality plugin :
http://imagej.net/Directionality (included in fiji)
And also the ridge detection plugin :
http://imagej.net/Ridge_Detection

For more informations on how these plugin are working, please consult :
Steger, C., 1998. An unbiased detector of curvilinear structures. IEEE Transactions 
on Pattern Analysis and Machine Intelligence, 20(2), pp.113–125.
And the directionality page linked above.

Many thanks to 	Jean-Yves Tinevez (directionality developper)
And Thorsten Wagner/Mark Hiner (Ridge developpers) !
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
	dir = getDirectory("Choose where to save."); 
	image = getTitle();
	selectWindow(image);
	rename ("img_dir");
	image = getTitle();	
	run("8-bit");
	image_height = getHeight();
	image_width = getWidth();
	image_area = image_height * image_width;
		
	setTool("line"); 
	waitForUser( "Draw a line as the reference axis and then press OK.");
	while ((selectionType() !=5)){
		setTool("line");
	}

	run("Set Measurements...", "  redirect=None decimal=3");
	run("Measure");

	selectWindow(image);
	//run("Capture Image");
	//saveAs("png",  dir + image + "_IMG_TOTAL_REF_AXIS" + ".png");
	
	epth_angle = getResult("Angle", 0);

	if (epth_angle <= -90) {
		epth_angle += 180;
	}
	
	else if (epth_angle >= 90) {
		epth_angle -= 180 ;	
	}
	
	epth_amount_inv = -epth_angle;
	run("Clear Results");
	selectWindow(image);
	
	data_points = 90;
	data_points_start = -90;
	run("Directionality ", "method=[Local gradient orientation] nbins=data_points histogram=data_points_start display_table");
				

	selectWindow("Directionality histograms for DUP_" + image + " (using Local gradient orientation)");
	
	direction_array = newArray("dir");
	amount_array = newArray("amt");
	fit_array = newArray("fit");
			
		
	degreechar = fromCharCode(0xB0); 		
		
	wait(10);

	for (j=0; j<data_points; j++){
		selectWindow("Directionality histograms for DUP_" + image + " (using Local gradient orientation)");
		wait(1);
		direction = getResult("Direction (" + degreechar + ")", j);

		
		selectWindow("Directionality histograms for DUP_" + image + " (using Local gradient orientation)");
		wait(1);
		amount = getResult("DUP_" + image, j);

		
		selectWindow("Directionality histograms for DUP_" + image + " (using Local gradient orientation)");
		wait(1);
		fit = getResult ("DUP_" + image + "-fit", j);
		
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


	Array.getStatistics(amount_array, amount_min, amount_max, amount_mean, amount_std);
	//print("Amount min : " + amount_min);
	//print("Amount max : " + amount_max);
	//print("Amount mean : " + amount_mean);
	//print("Amount std : " + amount_std);
	
	Array.getStatistics(direction_array, dir_min, dir_max, dir_mean, dir_std);
	//print("Direction min : " + dir_min);
	//print("Direction max : " + dir_max);
	//print("Direction mean : " + dir_mean);
	//print("Direction std : " + dir_std);

	Array.getStatistics(direction_array_corrected, dir_corr_min, dir_corr_max, dir_corr_mean, dir_corr_std);
	//print("Direction (corrected) min : " + dir_corr_min);
	//print("Direction (corrected) max : " + dir_corr_max);
	//print("Direction (corrected) mean : " + dir_corr_mean);
	//print("Direction (corrected) std : " + dir_corr_std);
	
	Array.getStatistics(fit_array, fit_min, fit_max, fit_mean, fit_std);
	//print("Fit min : " + fit_min);
	//print("Fit max : " + fit_max);
	//print("Fit mean : " + fit_mean);
	//print("Fit std : " + fit_std);
	
	
	count = 0;
	while (count == 0){
		for (i=0;i<lengthOf(amount_array);i++){
			if (amount_array[i] == amount_max){
				amount_array_max_pos = i;
				
				/*
				Little workaround just in case the max amount peak
				is too close to the boundaries (can block the next while loops, if so)
				*/
				
				if (direction_array_corrected[amount_array_max_pos] >= (data_points - 10)){
					amount_std = 0 ;
					print("ERROR : max amount too  close to boundaries, std set to 0!");
				}
				
				else if (direction_array_corrected[amount_array_max_pos] <= (data_points_start + 10)){
					amount_std = 0 ;
					print("ERROR : max amount too  close to boundaries, std set to 0!");
				}
				
				count=1;
				break;
			}

		}
	}

	count = 0;
	while (count == 0){
		for (i=amount_array_max_pos;i>=0;i--){
			if (amount_array[i] <= (amount_max - (amount_std))){
				amount_array_minus_std_pos = i+1;
				count=1;
				break;
			}
		}
	}
	
	count = 0;
	while (count == 0){
		for (i=(lengthOf(amount_array)-1);i>=amount_array_max_pos;i--){
			if (amount_array[i] >= (amount_max - (amount_std))){
				amount_array_plus_std_pos = i+1;
				count=1;
				break;
			}
		}
	}
	
	SUM_ANGLE_PEAK = 0;
	for (i=amount_array_minus_std_pos;i<amount_array_plus_std_pos; i++){
		SUM_ANGLE_PEAK += direction_array_corrected[i]; 
	}
	
	SUM_ANGLE_TOTAL = 0;
	for (i=0;i<lengthOf(direction_array_corrected); i++){
		SUM_ANGLE_TOTAL += direction_array_corrected[i]; 
	}

	DIFF_BTW_MIN_STD_AND_PLUS_STD = (amount_array_plus_std_pos - amount_array_minus_std_pos);
	
	DOM_ANGLE = round(SUM_ANGLE_PEAK/DIFF_BTW_MIN_STD_AND_PLUS_STD);
	MAX_ANGLE = round(direction_array_corrected[amount_array_max_pos]);
	AVG_ANGLE = round(SUM_ANGLE_TOTAL/lengthOf(direction_array_corrected));

	PEAK_AMOUNT = 0;
	
	for (i=amount_array_minus_std_pos;i<amount_array_plus_std_pos; i++){
		PEAK_AMOUNT += amount_array[i]; 
	}

	TOTAL_AMOUNT = 0;
	
	for (i=0;i<lengthOf(amount_array); i++){
		TOTAL_AMOUNT += amount_array[i];
	}
	
	AMOUNT_RATIO = (PEAK_AMOUNT/TOTAL_AMOUNT)*100;
			
	SST = 0;
	for (i=0;i<lengthOf(amount_array); i++){
		SST += pow((amount_array[i]- amount_mean),2); 
	}
	
	SSE = 0;
	for (i=0;i<lengthOf(amount_array); i++){
		SSE += pow((amount_array[i]- fit_array[i]),2); 
	}
	
	FIT_QUALITY = 1 - (SSE/SST);
	
	run("Clear Results");
	selectWindow("Results");
	
	for (i=0;i<lengthOf(direction_array);i++){
		setResult("Angle(NC)", i, direction_array[i]);
	}
	updateResults();
	
	for (i=0;i<lengthOf(direction_array_corrected);i++){
		setResult("Angle(C)", i, direction_array_corrected[i]);
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

	setResult("Angle moyen", 0, AVG_ANGLE);
	setResult("Angle max", 0, MAX_ANGLE);
	setResult("Angle dominant", 0, DOM_ANGLE);
	setResult("Ratio pic/total", 0, AMOUNT_RATIO);
	setResult("Qualite fit gaussien (r2)", 0, FIT_QUALITY);
	updateResults();
	
	saveAs("Results",  dir + image + "direction_" +".xls");		
}		