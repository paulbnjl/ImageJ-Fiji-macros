
/*
####################################################################
####################################################################
*/


/*
Macro : assisted collagen orientation and distribution assessment
Version : 0.0.1
Author : Paul Bonijol
License : GNU/GPL v3
May 2016
Best suited for high resolution, high contrast microscope images
(for instance, 20x magnification <-> 4000x4000px .tif, with tissue 
stained by, say, picrosirius red)
*/

/*
In order to work, this need the directionality module :
http://imagej.net/Directionality (included in fiji)
And the ridge detection plugin :
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

/*
Ask for a recent version of imageJ/Fiji (Fiji is better suited)
*/

requires("1.50a");

macro " assisted collagen orientation assessment" {
	
	/*
	Source (i.e opened) image selection
	*/

	image = getTitle();
	selectWindow(image);
	run("RGB Color");
	image_height = getHeight();
	image_width = getWidth();
	image_area = image_height * image_width;



	Dialog.create("Region Of Interest (ROI) dimensions : ");
	Dialog.addNumber("Horizontal size : ", 200);
	Dialog.addNumber("Vertical size : ", 200);  
	Dialog.show();
	ROI_size_dx = Dialog.getNumber();
	ROI_size_dy = Dialog.getNumber();


	/* 
	Epithelium (or any reference angle really) retrieval
	idea : draw a line, measure the angle between this line
	and the normal (x,y) plane of the image
	the negative value of this angle will serve as a reference
	afterwards		
	*/
	
	setTool("line"); 

	waitForUser( "Draw a line in the reference axis and then press OK.");
	while ((selectionType() !=5)){
		setTool("line");
		}

	/*
	Run a measurments with minimal parameters 
	as we only want the angle
	*/

	run("Set Measurements...", "  redirect=None decimal=3");
	run("Measure");

	/*
	Retrieve the angle value from the result table
	*/

	epth_angle = getResult("Angle", 0);

	
	/* 
	We want an angle value in the [-90;90 range]
	for this purpose, we have to anticipate for out of boundaries value
	by adding or removing 180°
	*/

	if (epth_angle <= -90) {
		epth_angle += 180;
	}
	else if (epth_angle >= 90) {
		epth_angle -= 180 ;	
	}
	 else {
		continue;
	}

	/*
	Convert to negative (needed as it is not possible to pass "-variable" as a parameter)
	Then clear and close the measurements table
	*/

	epth_amount_inv = -epth_angle;
	run("Clear Results");
	selectWindow("Results");
	run("Close");

	/*
	Dialog box : ROI placement
	*/

	Dialog.create("Number of ROIs");
	Dialog.addNumber("Number of ROIs : ", 1); 
	Dialog.show();
	ROI_number = Dialog.getNumber();

	for (a=1;a<=ROI_number;a++){
		selectWindow(image);

		/*
		Ask the user to set the ROI center ; a polygon will be draw around
		*/
		
		setTool("multipoint");

		waitForUser( "Click on the image to pinpoint the ROI and press enter.");
		while ((selectionType() !=10)){
			setTool("multipoint");
			}

		/*
		Measure the (x,y) coordinate of the selected point		
		*/

		run("Measure");

		ROI_center_x = getResult("X", 0);
		ROI_center_y = getResult("Y", 0);

		run("Clear Results");
		selectWindow("Results");
		run("Close");

		/* 
		Draw an polygonal ROI around the point
		Height : ROI_size_dy
		Width : ROI_size_dx
		*/

		x1 = ROI_center_x - ((ROI_size_dx)/2);
		y1 = ROI_center_y + ((ROI_size_dy)/2);

		x2 = ROI_center_x + ((ROI_size_dx)/2);
		y2 = ROI_center_y + ((ROI_size_dy)/2);

		x3 = ROI_center_x + ((ROI_size_dx)/2);
		y3 = ROI_center_y - ((ROI_size_dy)/2);

		x4 = ROI_center_x - ((ROI_size_dx)/2);
		y4 = ROI_center_y - ((ROI_size_dy)/2);

		makePolygon(x1,y1,x2,y2,x3,y3,x4,y4);
		
		/*
		Rotate the ROI according to the angle measured before
		*/

		run("Rotate...", "  angle=epth_amount_inv");


		/*
		Create a new image from the ROI, and rename it.
		*/
			
		run("Duplicate...", "title=ROI_temp");
		selectWindow("ROI_temp");
		rename("ROI" + a);

		/*
		Now we will draw a small square centered in the ROI
		This square is smaller, but still in the first one perimeter
		As we want to focus on the important area, which is more likely
		to be located at the center of the initial selection, while the
		most excentered regions of the ROI are more prone to contain unrelated 
		elements
		This will allow to calculate an occupation parameter
		Idea : this square will be thresholded, 
		and after binarizing it an occupation index will be
		calculated with the blank (background) / black (foreground)
		pixels ratio
		*/
		selectWindow(image);
		x5 = ROI_center_x - ((ROI_size_dx)/2);
		y5 = ROI_center_y;

		x6 = ROI_center_x;
		y6 = ROI_center_y + ((ROI_size_dy)/2);

		x7 = ROI_center_x + ((ROI_size_dx)/2);
		y7 = ROI_center_y;

		x8 = ROI_center_x;
		y8 = ROI_center_y - ((ROI_size_dy)/2);

		makePolygon(x5,y5,x6,y6,x7,y7,x8,y8);

		/*
		Create a new image from this second polygon, and rename it
		*/

		run("Duplicate...", "title=ROI_area");
		selectWindow("ROI" + a);

		/* 
		If we keep the RGB image, directionality will be applied for each color canal
		and thus add a useless complexity layer to the results
		to avoid that we convert the image to grayscale		
		*/
		
		run("8-bit");
		
		/* 
		Directionality analysis
		data_points and data_points_inv are the min and max bin range values
		Separating these parameters from the base command may be more handy in the future
		*/
	
		data_points = 90;
		data_points_inv = -90;
		run("Directionality", "method=[Local gradient orientation] nbins=data_points histogram=data_points_inv display_table");
				
		/* 
		Generated data table
		Now we select the generated results table and extract each column as independant arrays		
		*/

		selectWindow("Directionality histograms for DUP_ROI" + a + " (using Local gradient orientation)");
		
		direction_array = newArray("dir");
		amount_array = newArray("amt");
		fit_array = newArray("fit");
			
		/*
		Unicode encoding bug in Microsoft Windows ? This following dirty workaround avoid some trouble with the "°" character...
		*/
		degreechar = fromCharCode(0xB0); 		
		
		/* 
		Another dirty workaround : directionality is sometime too slow and the macro run too fast for the results to be displayed
		*/		
		wait(100);

		for (j=0; j<data_points; j++){
			
			/* 
			A little explanation here is mandatory, because of the mess !
			With this for loop, we select the result table for each data point
			(column length being equal to data_points -1, as it starts with row 1 = O)
			and copy one (column,row) value in a variable (direction, amount, fit)
			at each loop turn, the variable content will be stored to the relative array
			this way : we create a temporary array of size+1 compared to the base array
			in this temporary array we copy all the values from the base array
			then we add the variable content, then we define the temporary array as the base array
			this because the ImageJ Macro Langage does not offer the most basic array management feature
			(value append to an array, that is)
			*/

			selectWindow("Directionality histograms for DUP_ROI" + a + " (using Local gradient orientation)");
			wait(1);
			direction = getResult("Direction (" + degreechar + ")", j);

			
			selectWindow("Directionality histograms for DUP_ROI" + a + " (using Local gradient orientation)");
			wait(1);
			amount = getResult("DUP_ROI" + a, j);

			
			selectWindow("Directionality histograms for DUP_ROI" + a + " (using Local gradient orientation)");
			wait(1);
			fit = getResult ("DUP_ROI" + a + "-fit", j);
			
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

		/* 
		We now generate a new array from the direction_array
		this will be the "corrected angle values" array, where
		from each base angle values will be substracted the angle value
		gathered at the very beginning of the macro by drawing a line
		*/
		
		direction_array_corrected = newArray(lengthOf(direction_array));
		for (i=0;i<lengthOf(direction_array_corrected);i++){
			direction_array_corrected[i] = direction_array[i] + epth_amount_inv;
			}

		/* 
		Now we want to retrieve some statistics from each arrays
		*/

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
		

		/*
		Collagen occupation parameter calculation
		Pass the small ROI_area in grayscale
		then auto-threshold using the MinError method
		then select the white area and calculate the area
		then same with the black area
		then calculate the ratio
		*/
		wait(100);
		selectWindow("ROI_area");
		TOTAL_AREA = getHeight()*getWidth();
		run("8-bit");
		run("Auto Threshold", "method=MinError(I) white");
		run("Set Measurements...", "area redirect=None decimal=3");		
		run("Create Selection");
		run("Make Inverse");
		run("Measure");
		BLACK_AREA = getResult("Area", 0);
		OCP_RATIO = ((BLACK_AREA/TOTAL_AREA)*100);
		run("Clear Results");
		selectWindow("Results");
		run("Close");
		selectWindow("ROI_area");
		run("Close");

		/*
		Ridge detection
		Don't know exactly how it work, but it is !
		More information on this : 
		https://en.wikipedia.org/wiki/Ridge_detection
		http://imagej.net/Ridge_Detection
		for collagen detection, we fix some parameters like the SLOPE
		and we have to only enter the fiber length and the min/max contrast really
		for the length, we will ask the user to draw a line
		and for the contrast, we will evaluate it automatically
		*/

		wait(100);		
		selectWindow("ROI" + a);
		run("Select None");		
		run("8-bit");		
		run("Set Measurements...", "min redirect=None decimal=3");
		run("Measure");
		GREY_MIN = getResult("Min", 0);
		GREY_MAX = getResult("Max",0);
		run("Clear Results");
		selectWindow("Results");
		run("Close");

		selectWindow("ROI" + a);
		setTool("line"); 
		waitForUser( "Fiber length evaluation : measure one fiber thickness by drawing a line, and press OK.");
		while ((selectionType() !=5)){
			setTool("line");
		}
		run("Set Measurements...", "  redirect=None decimal=3");
		run("Measure");
		REF_FIBER_LENGTH = getResult("Length",0);
		run("Clear Results");
		selectWindow("Results");
		run("Close");

		//print("Grey min value : " + GREY_MIN);
		//print("Grey max value : " + GREY_MAX);

		SIGMA = (REF_FIBER_LENGTH/(2 * sqrt(3))) + 0.5;
		HIGH_CONTRAST = ( 0.17 * (2 * GREY_MAX * (REF_FIBER_LENGTH/2)) / (sqrt(2*PI) * pow(SIGMA,3) ) ) * exp(-(pow((REF_FIBER_LENGTH/2),2))/(2*pow(SIGMA,2)));
		LOW_CONTRAST = ( 0.17 * (2 * GREY_MIN * (REF_FIBER_LENGTH/2)) / (sqrt(2*PI) * pow(SIGMA,3) ) ) * exp(-(pow((REF_FIBER_LENGTH/2),2))/(2*pow(SIGMA,2)));
		run("Ridge Detection", "line_width=REF_FIBER_LENGTH high_contrast=GREY_MAX low_contrast=GREY_MIN darkline correct_position estimate_width extend_line show_ids displayresults add_to_manager method_for_overlap_resolution=SLOPE sigma=SIGMA lower_threshold=LOW_CONTRAST upper_threshold=HIGH_CONTRAST");			

		/*
		The plugin results table return multiple entries per contour
		Here we process a little to count only the number of contours
		(assuming it's equal to the number of detected objects)
		*/
		selectWindow("Results");
		fiber_width_array = newArray("fiberwidth");
		NUMBER_OF_FIBER_DETECTED = 0;
		for (h=0; h<nResults; h++){
			fiberwidth = getResult("Line width", h);
			if (h != 0){
				contour_ID_prev = contourID;			
				}
			else {
				contour_ID_prev = 0;				
				}
			contourID = getResult("Contour ID", h);
			fiber_width_array_temp = newArray(lengthOf(fiber_width_array)+1);
			for (d=0; d<lengthOf(fiber_width_array);d++){
				fiber_width_array_temp[d]=fiber_width_array[d];
				}
			if (contourID != contour_ID_prev){
				fiber_width_array_temp[lengthOf(fiber_width_array)-1]=fiberwidth;
				NUMBER_OF_FIBER_DETECTED += 1;
				}
			else {
				continue;
				}
			 
			fiber_width_array = fiber_width_array_temp;
		}

		fiber_width_array = Array.slice(fiber_width_array,1);
		Array.getStatistics(fiber_width_array, width_min, width_max, width_mean, width_std);
		//print("Min fiber width : " + width_min);
		//print("Max fiber width : " + width_max);
		//print("Mean fiber width : " + width_mean);
		//print("Fiber width, standard deviation : " + width_std);

		run("Clear Results");
		selectWindow("Results");
		run("Close");

		selectWindow("Junctions");
		NUMBER_OF_JUNCTIONS_DETECTED = getValue("results.count");		
		FIBER_WIDTH_SUM = 0;
		for (v=0;v<lengthOf(fiber_width_array);v++){
		FIBER_WIDTH_SUM += fiber_width_array[v];
		}		
		AVG_FIBER_WIDTH = FIBER_WIDTH_SUM/lengthOf(fiber_width_array);
		

		/*
		All set, now let's tidy a little bit and close all windows
		TODO : find a way to close JFRAME windows
		*/
		
		//selectWindow("ROI" + a);
		//run("Close");		
	
		/* 
		Beginning of the dull calculation process
		Here, with some loops, we retrieve the position of the
		max value of the amount array (i.e the array[x] where x
		is the maximum amount of the entire array) [first while loop]
		
		Then we do the same for the values at +/- 1 STD from the max [second and third while loops]
		since all list are same-sized, we can use these position values
		on the other arrays to retrieve the max angle and the angles
		at +/- STD

		Then we calculate the amplitude of values between max +/- STD
		with this we can calculate the total amount within this range
		and the mean angle in the peak (mean +/- STD) range
		*/
		
		count = 0;
		while (count == 0){
			for (i=0;i<lengthOf(amount_array);i++){
				if (amount_array[i] == amount_max){
					amount_array_max_pos = i;
					count=1;
					break;
				}
				else{
					continue;
					}
				}
		}
		
		count = 0;
		while (count == 0){
			for (i=amount_array_max_pos;i>0;i--){
				if (amount_array[i] <= (0.65 * amount_max)){
					amount_array_minus_2_std_pos = i;
					count=1;
					break;
				}
				
				else{
					continue;
				}
			}
		}
				
		count = 0;
		while (count == 0){
			for (i=amount_array_max_pos;i<lengthOf(amount_array);i++){
				if (amount_array[i] >= (0.65 * amount_max)){
					amount_array_plus_2_std_pos = i;
					count=1;
					break;
				}
				
				else{
					continue;
				}
			}
		}
		
		SUM_ANGLE = 0;
		
		for (i=amount_array_minus_2_std_pos;i<=amount_array_plus_2_std_pos; i++){
			SUM_ANGLE += direction_array_corrected[i]; 
		}

		
		DIFF_BTW_MIN_STD_AND_PLUS_STD = (amount_array_plus_2_std_pos - amount_array_minus_2_std_pos);
		
		DOM_ANGLE = SUM_ANGLE/DIFF_BTW_MIN_STD_AND_PLUS_STD;
		MAX_ANGLE = direction_array_corrected[amount_array_max_pos];
		AVG_ANGLE = (DOM_ANGLE + MAX_ANGLE)/2;
		print("Dominant angle : " + DOM_ANGLE);		
		print("Maximum angle : " + MAX_ANGLE);
		print("Average angle : " + AVG_ANGLE);

		SUM_AMOUNT = 0 ;
		for (i=amount_array_minus_2_std_pos;i<=amount_array_plus_2_std_pos; i++){
			SUM_AMOUNT += amount_array[i]; 
		}

		print("Amount of fibers following dominant direction +/- STD : " + SUM_AMOUNT); 
		// TODO : check value ! discrepancies between this and the one calculated by the directionality plugin
				


		/* 
		Coefficient of determination (r2) fit value calculation
		Compare the quality of the "fit" datas to the original data
		Calculation are made according to :
		https://en.wikipedia.org/wiki/Coefficient_of_determination
		*/

		SST = 0;
		for (i=0;i<lengthOf(amount_array); i++){
			SST += pow((amount_array[i]- amount_mean),2); 
		}
		
		SSE = 0;
		for (i=0;i<lengthOf(amount_array); i++){
			SSE += pow((amount_array[i]- fit_array[i]),2); 
		}
		
		FIT_QUALITY = 1 - (SSE/SST);
		print("Fit quality : " + FIT_QUALITY);
		
		print("Total ROI area : " + TOTAL_AREA);
		print("Occupation ratio : " + OCP_RATIO + " %");
		print("Number of fiber objects detected within the ROI : " + NUMBER_OF_FIBER_DETECTED);
		print("Number of fiber junctions detected : " + NUMBER_OF_JUNCTIONS_DETECTED);
		print("Average fiber width : " + AVG_FIBER_WIDTH);

		/*
		Plot of the function amount = f(angle)
		0.5 is the arbitrary length of the ordinate axis
		Useless for now, hence the commented block
		*/
		
		//Plot.create("Angle repartition within the ROI", "Angle", "Amount", direction_array_corrected, amount_array);
		//Plot.setLimits(data_points_inv,data_points,0,0.5);
		//Plot.setColor("green");
		//Plot.add("triangles", direction_array_corrected, fit_array);
		//Plot.setColor("red");
		//Plot.show();

	
	/*
	Will be effective after I set a working folder for saving results
	in a xls/csv sheet or something like that
	*/
	//while (nImages>0) { 
	//	selectImage(nImages); 
	//	close(); 
		}
	// selectWindow("ROI Manager");
	//run("Close");
	//selectWindow("Directionality analysis for DUP_ROI" + a + "(using Local gradient orientation)");
	//run("Close");
	//selectWindow("Directionality histograms for DUP_ROI" + a + "(using Local gradient orientation)");
	//run("Close");
	//selectWindow("Directionality for DUP_ROI" + a + "(using Local gradient orientation)");
	//run("Close");
	}
}
