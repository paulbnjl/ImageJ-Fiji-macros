
/*
####################################################################
####################################################################
*/


/*
Macro : assisted collagen orientation and distribution assessment
Version : 0.0.2
Author : Paul Bonijol
License : GNU/GPL v3
May 2016

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

/*
Ask for a recent version of Fiji (Fiji is better suited)
WON'T WORK WITH IMAGEJ (unless you install the required plugins : directionnality and ridge_detection)
*/

requires("1.50a");

macro "Collagen orientation analysis" {
	
	/*
	The mandatory warning message...
	*/
	
	showMessage("Warning !", "This macro is highly EXPERIMENTAL, and thus provided WITHOUT ANY WARRANTY. The author has no liability of any sort, and there is no guarantee that the results are accurate.");
	
	/*
	Source (i.e opened) image selection
	*/

	image = getTitle();
	selectWindow(image);
	
	// IMMPORTANT : depending on the images and the FIJI version, you have to pass by a RGB conversion step
	// And sometimes, it only rename  the original image, whils in some case it duplicate the image
	// for no reason. Comment/uncomment the following lines accordingly
	
	//run("RGB Color");
	//selectWindow(image);
	//run("Close");
	//selectWindow(image + " (RGB)");
	
	rename("image_base");
	image_height = getHeight();
	image_width = getWidth();
	image_area = image_height * image_width;

	/*
	Ask the user to define a directory
	for saving stuff
	*/

	dir = getDirectory("Choose where to save."); 

	/*
	Now, ask the user to define the ROI size
	*/
	
	Dialog.create("Region Of Interest (ROI) dimensions : ");
	Dialog.addNumber("Horizontal size : ", 200);
	Dialog.addNumber("Vertical size : ", 200);  
	Dialog.show();
	ROI_size_dx = Dialog.getNumber();
	ROI_size_dy = Dialog.getNumber();


	/* 
	Epithelium (or any reference angle really) retrieval
	idea : draw a line, measure the angle between this line
	and the normal (x,y) horizontal axis of the image
	the negative value of this angle will serve as a reference
	afterwards		
	*/
	
	setTool("line"); 

	waitForUser( "Draw a line as the reference axis and then press OK.");
	while ((selectionType() !=5)){
		setTool("line");
		}


	/*
	Capture the full image with the reference axis
	*/
	
	run("Capture Image");
	saveAs("png",  dir + image + "_IMG_TOTAL_REF_AXIS" + ".png");
	run("Close");
	
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

	/* 
	If we keep the RGB image, directionality will be applied for each color canal
	and thus add a useless complexity layer to the results
	to avoid that we convert the image to grayscale		
	*/
		
	run("8-bit");

	for (a=1;a<=ROI_number;a++){
		selectWindow("image_base");

		/*
		Ask the user to set the ROI center ; a polygon will be draw around
		*/
		
		setTool("multipoint");

		waitForUser( "ROI " + a + " of " + ROI_number + ". Click on the image to center the ROI and press enter.");
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
		Create a screen capture of the ROI placement
		*/
		
		run("Capture Image");
		saveAs("png",  dir + image + "_IMG_TOTAL_ROI_" + a + ".png");
		run("Close");
		
		/*
		Create a new image from the ROI, and rename it.
		*/
		
		selectWindow("image_base");	
		run("Duplicate...", "title=ROI_temp");
		selectWindow("ROI_temp");
		rename("ROI" + a);

		/*
		Now we will draw a small square centered in the ROI
		This square is smaller, but still in the first one perimeter
		As we want to focus on the important area, which is more likely
		to be located at the center of the initial selection, while the
		most excentered regions of the ROI are more prone to contain 
		unrelated elements
		
		This will allow to calculate an occupation parameter
		Idea : this square will be thresholded (IsoData), then
		an occupation index will be calculated with the black 
		(foreground) / total area ratio
		*/
		
		selectWindow("image_base");
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
		
		
		/* 
		Directionality analysis
		data_points and data_points_start are the min and max bin range values
		Separating these parameters from the base command may be more handy in the future
		*/
		
		selectWindow("ROI" + a);
		data_points = 90;
		data_points_start = -90;
		run("Directionality", "method=[Local gradient orientation] nbins=data_points histogram=data_points_start display_table");
				
		/* 
		Generated data table
		Now we select the generated results table and extract each column as independant arrays
		Since we can't anticipate the number of values (well in this case yes, because we define a range,
		so, as a general rule...), and the arrray functions of the IMJ lacks several features...
		We initiate arrays by one arbitrary value, then we will create new values with values +1 each
		loop passage and after the loop, we split the array from the first value
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
		Another dirty workaround : directionality is sometime too slow and the macro run too fast for the results windows to 
		be displayed in time
		*/		
		
		wait(10);

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
			direction_array_corrected[i] = direction_array[i];
			direction_array_corrected[i] += epth_amount_inv;
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
		
		wait(10);
		selectWindow("ROI_area");
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
		selectWindow("Results");
		run("Close");
		selectWindow("ROI_area");
		run("Close");

		/*
		Ridge detection
		Don't know exactly how it work, but it is doing quite well !
		More information on this : 
		https://en.wikipedia.org/wiki/Ridge_detection
		http://imagej.net/Ridge_Detection
		for collagen detection, we define some parameters like the SLOPE
		and thus we have to only enter the fiber length and the min/max contrast really
		for the length, we will ask the user to draw a line
		and for the contrast, we will evaluate it automatically
		*/

		wait(10);		
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
		run("Set Measurements...", " min redirect=None decimal=3");
		run("Measure");
		REF_FIBER_LENGTH = getResult("Length",0);
		run("Clear Results");
		selectWindow("Results");
		run("Close");
		
		/*
		Ridge detection parameters calculation
		Only setting the min grey and max grey valuues
		seems useful, hence the commented code lines
		*/
		
		//SIGMA = (REF_FIBER_LENGTH/(2 * sqrt(3))) + 0.5;
		//HIGH_CONTRAST = ( 0.17 * (2 * GREY_MAX * (REF_FIBER_LENGTH/2)) / (sqrt(2*PI) * pow(SIGMA,3) ) ) * exp(-(pow((REF_FIBER_LENGTH/2),2))/(2*pow(SIGMA,2)));
		//LOW_CONTRAST = ( 0.17 * (2 * GREY_MIN * (REF_FIBER_LENGTH/2)) / (sqrt(2*PI) * pow(SIGMA,3) ) ) * exp(-(pow((REF_FIBER_LENGTH/2),2))/(2*pow(SIGMA,2)));

		//run("Ridge Detection", "line_width=REF_FIBER_LENGTH high_contrast=GREY_MAX low_contrast=GREY_MIN 
		//darkline correct_position estimate_width extend_line show_ids displayresults add_to_manager 
		//method_for_overlap_resolution=SLOPE sigma=SIGMA lower_threshold=LOW_CONTRAST upper_threshold=HIGH_CONTRAST");

		run("Ridge Detection", "line_width=REF_FIBER_LENGTH high_contrast=GREY_MAX low_contrast=GREY_MIN darkline correct_position estimate_width extend_line show_ids displayresults add_to_manager method_for_overlap_resolution=SLOPE");		
	
		/*
		The plugin results table return multiple entries per contour
		Here we process a little to count only the number of contours
		(assuming it's equal to the number of detected objects)
		*/
		
		selectWindow("Results");
		fiber_width_array = newArray("fiberwidth");
		fiber_length_array = newArray("fiberlength");
		cut_off_calc_array = newArray("cut_off_array");
		NUMBER_OF_FIBER_DETECTED = 0;
		
				
		for (l=0; l<nResults; l++){
			fib_cut_val = getResult("Length", l);
			cut_off_calc_array_temp = newArray(lengthOf(cut_off_calc_array)+1);
			for (x=0; x<lengthOf(cut_off_calc_array); x++){
				cut_off_calc_array_temp[x] = cut_off_calc_array[x];
			}
			cut_off_calc_array_temp[lengthOf(cut_off_calc_array)-1]=fib_cut_val;
			cut_off_calc_array = cut_off_calc_array_temp;	
		}
		cut_off_calc_array = Array.slice(cut_off_calc_array,1);

		Array.getStatistics(cut_off_calc_array, cut_min, cut_max, cut_mean, cut_std);
		//print("cut_min :" + cut_min);
		//print("cut_max :" + cut_max);
		//print("cut_mean :" + cut_mean);
		//print("cut_std :" + cut_std);
		
		for (h=0; h<nResults; h++){
			fiberlength = getResult("Length", h);
			fiberwidth = getResult("Line width", h);
			if (h != 0){
				contour_ID_prev = contourID;			
				}
			else {
				contour_ID_prev = 0;				
				}
			contourID = getResult("Contour ID", h);
			fiber_width_array_temp = newArray(lengthOf(fiber_width_array)+1);
			fiber_length_array_temp = newArray(lengthOf(fiber_length_array)+1);

			for (d=0; d<lengthOf(fiber_width_array);d++){
				fiber_width_array_temp[d]=fiber_width_array[d];
				fiber_length_array_temp[d]=fiber_length_array[d];
				}

			if (contourID != contour_ID_prev){
				fiber_width_array_temp[lengthOf(fiber_width_array)-1]=fiberwidth;
				fiber_length_array_temp[lengthOf(fiber_length_array)-1]=fiberlength;
				NUMBER_OF_FIBER_DETECTED += 1;
				}
			else {
				continue;
				}
			 
			fiber_width_array = fiber_width_array_temp;
			fiber_length_array = fiber_length_array_temp;
		}
		fiber_length_array = Array.slice(fiber_length_array,1);
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
		
		MEAN_FIBER_WIDTH = width_mean;

		/*
		TODO : find a way to close JFRAME windows

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
				else{
					continue;
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
				else{
					continue;
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

				else{
					continue;
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

		
		/*
		A little copy/paste of the GetTime macro
		to format our results with the current date and time
		*/
		
		MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
		DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		TimeString ="Date: "+DayNames[dayOfWeek]+" ";
		if (dayOfMonth<10) {TimeString = TimeString+"0";}
		TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+"\nTime: ";
		if (hour<10) {TimeString = TimeString+"0";}
		TimeString = TimeString+hour+":";
		if (minute<10) {TimeString = TimeString+"0";}
		TimeString = TimeString+minute+":";
		if (second<10) {TimeString = TimeString+"0";}
		TimeString = TimeString+second;
			
		/*
		Now, the results, printed in the log windowcontent
		*/
		
		print("******************************************************************");
		print("******************************************************************");
		print(TimeString);
		print ("ROI number : " + a);
		print("ROI size : " + ROI_size_dx + "x" + ROI_size_dy);
		print("******************************************************************");
		
		print("ANGULAR DISPERSION :");
		print("Peak Mean Value : " + DOM_ANGLE);		
		print("Peak Max Value : " + MAX_ANGLE);
		//print("Average (on total) Angle Value : " + AVG_ANGLE);
		print("% of fibers following dominant direction (peak over total) : " + AMOUNT_RATIO);
		print("Standard deviation (angle max +/- total peak) : +/-" + dir_corr_std);
		print("Deviation around peak max value (STD/3) : +/-" + (dir_corr_std/3));
		print("Amount STD :" + amount_std);
		print("Fit quality : " + FIT_QUALITY);
		print("******************************************************************");

		print("FIBERS :");
		print("Number of fiber objects detected within the ROI : " + NUMBER_OF_FIBER_DETECTED);
		print("Number of fiber junctions detected : " + NUMBER_OF_JUNCTIONS_DETECTED);
		
		print("Fiber maximum width : " + width_max);
		print("Fiber minimum width :" + width_min);
		print("Fiber mean width : " + width_mean);
		print("Fiber width STD : " + width_std);
		print("******************************************************************");

		print("ROI :");
		print("Total ROI area : " + TOTAL_AREA);
		print("Occupied area :" + BLACK_AREA);
		print("Occupation ratio (estim.) : " + OCP_RATIO + " %");
		print("******************************************************************");
		print("******************************************************************");
		
		/*
		PLOT, amount = f(angle)
		*/
		
		angle_plot_name = "Angle_ROI_plot_" + a;
		Plot.create(angle_plot_name, "Angle", "Amount", direction_array_corrected, amount_array);
		Plot.setLimits(dir_corr_min,dir_corr_max,0,amount_max);
		Plot.setColor("green");
		Plot.add("triangles", direction_array_corrected, fit_array);
		Plot.setColor("red");
		Plot.show();
		
		/*
		PLOT, fibers distribution
		*/
		
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
		
		fiber_plot_name = "Fiber_distribution_plot_" + a;
		Plot.create(fiber_plot_name, "Fibers", "Size", val_number_fiber_array, fiber_width_array);
		Plot.setLimits(val_min,val_max,width_min,width_max);
		Plot.setColor("red");
		Plot.show();

		run("Measure"); // pop the results table
		run("Clear Results"); // erase everything in it
		selectWindow("Results"); // select the table
		
		/* 
		Now we just fill the table with our arrays content
		And then we will export the table as a whole in a xls file
		*/
		
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
		for (i=0;i<lengthOf(fiber_width_array);i++){
			setResult("Fiber width", i, fiber_width_array[i]);
		}
		updateResults();
		
		saveAs("Results",  dir + image + "ROI_" + a + ".xls");
		
		/*
		As a trace of what we have done with the macro
		We now save all plots, ROIs and ridge fit images
		*/
		
		selectWindow("Angle_ROI_plot_" + a);
		run("Capture Image");
		saveAs("png",  dir + image + "Angle plot ROI_" + a + ".png");
		
		selectWindow("Fiber_distribution_plot_" + a);
		run("Capture Image");
		saveAs("png",  dir + image + "Fiber distribution ROI_" + a + ".png");	
				
		selectWindow("ROI" + a);
		saveAs("tiff",  dir + image + "ROI_" + a + ".tiff");
		run("Capture Image");
		saveAs("tiff",  dir + image + "Fit_Ridge ROI_" + a + ".tiff");
		
	}
	
	/*
	Macro end by saving in a txt file all the content of the log window
	Then close all images
	And close ImageJ/Fiji quietly
	*/
	
	selectWindow("Log");
	windowcontent = getInfo();
	saveAs("text", dir +image + "results_log" + ".txt");
	 while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      }
	  
	showMessage("Ending...", "End of the evaluation. ImageJ will now close. All results are stored in " + dir);  
	run("Quit");
	
}
