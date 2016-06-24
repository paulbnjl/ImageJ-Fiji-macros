/*
Macro : assisted MAR assessment macro
Version : 1-0
Author : Paul Bonijol
License : GNU/GPL v3
June 2016
*/

// Check for a correct ImageJ/Fiji
requires("1.44n");

macro "semi-automatic IHC images line segmentation and distance calculation" {
	
	//The mandatory warning message...
	showMessage("Warning !", "This macro is highly EXPERIMENTAL, and thus provided WITHOUT ANY WARRANTY. \n The author has no liability of any sort, and there is no guarantee that the results are accurate.");
	
	// Retrieve current image
	image = getTitle();
	selectWindow(image);

	// Convert to RGB
	run("RGB Color");
	//selectWindow(image + " (RGB)");
	run("Median...", "radius=2"); // median filter to denoise a bit.
	run("Sharpen"); // not mandatory but this can help a little, since IHC images are really blurred

	// Calculate area
	IMAGE_AREA = getHeight() * getWidth();


	// Ask User to define a number of ROI to draw
	Dialog.create("IHC fluorochrome detection macro");
	Dialog.addNumber("Number of ROI(s) :", 1);
	Dialog.addNumber("Height: ", 200);
	Dialog.addNumber("Width : ", 200);  
	Dialog.show();

	// Retrieve user choices
	ROI_number = Dialog.getNumber()
	ROI_size_dx = Dialog.getNumber();
	ROI_size_dy = Dialog.getNumber();
	ROI_AREA_USERDEF = ROI_size_dx*ROI_size_dy;
	min_OBJ_size = ROI_AREA_USERDEF/100;
	
	// for loop to generate the number of ROIs asked by user.
	for (n=1;n<=ROI_number;n++){
		selectWindow(image);
		//selectWindow(image + " (RGB)");
		DrawROI();
		selectWindow("ROI");
		rename("ROI" + n);
		selectWindow("ROI" + n);
	
		// Ask user to define the type of fluorochromes to detect
		fluo_nb = 0;
		while (fluo_nb == 0) {
			// Dull choice menu
			Dialog.create("Macro main menu");
			Dialog.addMessage("Type of fluorochromes to detect :");
			Dialog.addCheckbox("Manual thresholding ?", false);
			Dialog.addCheckbox("Calcein Green", false);
			Dialog.addCheckbox("Xylenol Orange", false);
			Dialog.addCheckbox("Oxytetracycline", false);
			Dialog.addCheckbox("Post-process ? ", false);
			Dialog.addCheckbox("Length/width evaluation ? ", false);
			Dialog.addCheckbox("Save results ?", true);
			Dialog.addCheckbox("Export results (xls) ?", false);
			Dialog.addNumber("Object minimum size :", min_OBJ_size);
			Dialog.show();
			
			manual_thr = Dialog.getCheckbox();
			CG_val = Dialog.getCheckbox();
			XO_val = Dialog.getCheckbox();
			OTC_val = Dialog.getCheckbox();
			PP_val = Dialog.getCheckbox();
			RD_val = Dialog.getCheckbox();
			save_choice = Dialog.getCheckbox();
			export_choice = Dialog.getCheckbox();
			min_OBJ_size = Dialog.getNumber();
			new_ROI_start_count = 0;	
			
			// Calculation of the total number of fluorochrome selected
			if (CG_val == true) {
				fluo_nb +=1 ;
			}
			
			if (XO_val == true) {
				fluo_nb +=1 ;
			}
			
			if (OTC_val == true) {
				fluo_nb +=1 ;
			}
			
			if (fluo_nb == 0) {
				showMessage("Please select at least one fluorescent compound to detect.");
			}
		}
		
		// Define the save folder
		if (save_choice == true) {
			dir = getDirectory("Choose where to save."); 
		}
		
		// Calcein green case
		if (CG_val == true){
			// manual thr : just run the imageJ color thresholding window
			if (manual_thr == true){
				selectWindow("ROI" + n);
				run("Duplicate...", "title=ROI_CG");
				call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W");
				run( "Color Threshold..." );
				waitForUser( "Manually threshold image (B&W), then press OK." );
				selectWindow("Threshold Color");
				run("Close");
				selectWindow("ROI_CG");
				rename("ROI_CG_MASK");
			}
			
			// Otherwise, we juste split the image in it's three channels (R,G,B)
			// Select the green chanel, get the max intensity of it (should correspond to the fluorochrome)
			// Calculate threshold values and then, threshold
			else {
				// Thresholding : calcein green
				selectWindow("ROI" + n);
				run("Duplicate...", "title=ROI_CG");
				selectWindow("ROI_CG");
				run("Split Channels");
				selectWindow("ROI_CG" + " (red)");
				run("Close");
				selectWindow("ROI_CG" + " (blue)");
				run("Close");
				
				selectWindow("ROI_CG" + " (green)");
				run("Duplicate...", "title=ROI_CG_THR");
				selectWindow("ROI_CG_THR");
				getMinAndMax(min_val_g, max_val_g);
				
				// We will threshold at +/- 20% of the max intensity value
				max_val_g_lower_bin = max_val_g - ((max_val_g/100) * 20);
				max_val_g_upper_bin = max_val_g + ((max_val_g/100) * 20);
				
				if ((max_val_g_upper_bin) > 255) {
					max_val_g_upper_bin = 255;
				}
				
				if ((max_val_g_lower_bin) > 255) {
					max_val_g_lower_bin = 255;
				}
				setThreshold(max_val_g_lower_bin,max_val_g_upper_bin, "black & white");
				run("Convert to Mask");
				
				// also, detect the contour of our image, this will help to refine the mask
				selectWindow("ROI_CG" + " (green)");
				run("Duplicate...", "title=ROI_CG_CONTOUR");
				selectWindow("ROI_CG" + " (green)");
				run("Close");
				selectWindow("ROI_CG_CONTOUR");
				run("8-bit");
				run("Canny Edge Detector", "gaussian=2 low=2.5 high=7.5");
				
				// now, let's add the two generated image
				imageCalculator("Add create", "ROI_CG_CONTOUR","ROI_CG_THR");
				selectWindow("Result of ROI_CG_CONTOUR");
				rename("ROI_CG_MASK");
				selectWindow("ROI_CG_THR");
				run("Close");
				selectWindow("ROI_CG_CONTOUR");
				run("Close");
			}
			
			selectWindow("ROI_CG_MASK");
	
			/* 
			 Make a binary of the image after thresholding
			 This will be needed for the postprocessing step
			 And the particle counter analysis
			*/
	
			// Just in case the threshold doesn't generate a binary image
			run("Make Binary");
		
			Simple_PostProcessing();
			
			break_condition = 0;
			// while loop to detect object, allow the user to manually adjust, and see if it's correct
			// If it is, break; else, reset and repeat
			
			while (break_condition == 0) {
				roiManager("deselect");
				roiManager("Show None");
				run("Select None");
				selectWindow("ROI_CG_MASK");
				run("Select None");
				roiManager("Show None");
				run("Duplicate...", "title=ROI_CG_dtec");
				selectWindow("ROI_CG_dtec");
				run("Select None");
				roiManager("Show None");
				
				// condition to remove all previous entries in the roiManager, just in case...
				for (i=new_ROI_start_count; i <= roiManager("count"); i++) {
					if (roiManager("count") == new_ROI_start_count) {
						break;
					}
					else {
						roiManager("select", 0);
						roiManager("delete");
						roiManager("deselect");
						selectWindow("Results");
						IJ.deleteRows(0, 0);
					}
				}
				roiManager("deselect");
				roiManager("Show None");
				selectWindow("ROI_CG_dtec");
				
				// initial object detection, if not correct, user will have to manually correct
				Detect_Obj();

				selectWindow("ROI_CG_dtec");
				run("Select None");
				Manual_Correction();

				selectWindow("ROI_CG_dtec");
				// Again, remove all ROI if the correction is ok

				for (i=new_ROI_start_count; i <= roiManager("count"); i++) {
					if (roiManager("count") == new_ROI_start_count) {
						break;
					}
					else {
						roiManager("select", 0);
						roiManager("delete");
						roiManager("deselect");
						selectWindow("Results");
						IJ.deleteRows(0, 0);
					}
				}
				selectWindow("ROI_CG_dtec");
				run("Select None");
				roiManager("Show None");
				// user corrected everything, so we perform the real, final object detection (within the loop scope)
				Detect_Obj();
				
				selectWindow("Results");
				CG_AREA = 0;
				CG_WIDTH = 0;
				
				for (i=new_ROI_start_count; i < nResults();i++) {
					label = "Calcein Green, line : " +(i+1);
					setResult("Label",i,label);
					CG_AREA += getResult("Area", i);
					CG_WIDTH += getResult("Minor", i);
				}
				updateResults();
				
				CG_WIDTH = CG_WIDTH/nResults();
				selectWindow("ROI" + n);

				setOption("Show All", true);
				Dialog.create("Fit quality review");

				choice_val = newArray("Yes", "No");
				Dialog.addChoice("Fit correct ?", choice_val);
				Dialog.show();
				user_choice = Dialog.getChoice();

				if (user_choice == "Yes") {
					// quit the loop
					break_condition = 1;
					selectWindow("ROI_CG_dtec");
					run("Close");
					selectWindow("ROI_CG_MASK");
					run("Close");
					break;
				}
				
				else {
					// reset everything
					selectWindow("ROI_CG_dtec");
					run("Close");
					
					for (i=new_ROI_start_count; i <= roiManager("count"); i++) {
						if (roiManager("count") == new_ROI_start_count) {
							break;
						}
						
						else {
							roiManager("select", 0);
							roiManager("delete");
							roiManager("deselect");
							selectWindow("Results");
							IJ.deleteRows(0, 0);

						}
					}
					roiManager("deselect");
					roiManager("Show None");					
				}
			}

			selectWindow("ROI" + n);
			image = "ROI"+ n;
			if (fluo_nb == 1) {
				Process_Results();
				Calc_Draw_Distance_centroid();
				if (RD_val == true) {
					selectWindow("ROI" + n);
					run("Duplicate...", "title=ROI_8bit");
					selectWindow("ROI_8bit");
					run("8-bit");
					getMinAndMax(min_val_g, max_val_g);
					if (CG_WIDTH > 20) {
						CG_WIDTH = 20;
					}
					// Ridge detector, allows to get the object length and width
					// Entries parameters (WIDTH, high and low contrast) are calculated/measured before
					run("Ridge Detection", "line_width=CG_WIDTH high_contrast=max_val_g low_contrast=min_val_g correct_position estimate_width displayresults add_to_manager method_for_overlap_resolution=NONE");
					if (save_choice == true) {

						saveAs("tiff",  dir + "ROI_8bit" + "IHC_ridge_ROI_" + n + ".tiff");
					}
				
				}
				if (save_choice == true) {
					run("Capture Image");
					saveAs("tiff",  dir + image + "IHC_dist_ROI_" + n + ".tiff");
				}
				
				FLUO_AREA = CG_AREA;
				print("Fluorescent area :" + FLUO_AREA);
				print("ROI area : " + ROI_AREA_USERDEF);
				print("Fluo/total ratio : " + (FLUO_AREA*100)/ROI_AREA_USERDEF);	
			}
			
			else {
				new_ROI_start_count = roiManager("count");
				Rs_Table_nb = new_ROI_start_count;
			}
		}	
	
		if (XO_val == true){
			// same as we have seen before with CG
			if (manual_thr == true){
				selectWindow("ROI" + n);
				run("Duplicate...", "title=ROI_XO");
				call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W");
				run( "Color Threshold..." );
				waitForUser( "Manually threshold image (B&W), then press OK." );
				selectWindow("Threshold Color");
				run("Close");
				selectWindow("ROI_XO");
				rename("ROI_XO_MASK");
			}
			
			else {
				selectWindow("ROI" + n);
				run("Duplicate...", "title=ROI_XO");
				selectWindow("ROI_XO");
				run("Split Channels");
				selectWindow("ROI_XO" + " (green)");
				run("Close");
				selectWindow("ROI_XO" + " (blue)");
				run("Close");
				
				selectWindow("ROI_XO" + " (red)");
				run("Duplicate...", "title=ROI_XO_THR");
				selectWindow("ROI_XO_THR");
				getMinAndMax(min_val_o, max_val_o);
				
				// xylenol orange is more tricky to threshold ; thus we will threshold at +/- 5% of the max intensity value
				max_val_o_lower_bin = max_val_o - ((max_val_o/100) * 5);
				max_val_o_upper_bin = max_val_o + ((max_val_o/100) * 5);
				
				if ((max_val_o_upper_bin) > 255) {
					max_val_o_upper_bin = 255;
				}
				
				if ((max_val_o_lower_bin) > 255) {
					max_val_o_lower_bin = 255;
				}
				
				setThreshold(max_val_o_lower_bin,max_val_o_upper_bin, "black & white");
				run("Convert to Mask");
				

				selectWindow("ROI_XO" + " (red)");
				run("Duplicate...", "title=ROI_XO_CONTOUR");
				selectWindow("ROI_XO" + " (red)");
				run("Close");
				run("Duplicate...", "title=ROI_XO_CONTOUR");
				run("8-bit");
				run("Canny Edge Detector", "gaussian=2 low=2.5 high=7.5");
				
				imageCalculator("Add create", "ROI_XO_CONTOUR","ROI_XO_THR");
				selectWindow("Result of ROI_XO_CONTOUR");
				rename("ROI_XO_MASK");
				selectWindow("ROI_XO_THR");
				run("Close");
				selectWindow("ROI_XO_CONTOUR");
				run("Close");
			}
			selectWindow("ROI_XO_MASK");
	
	
			run("Make Binary");
		
			Simple_PostProcessing();
			break_condition = 0;
			loop_counter = 0;
			count = 0;
			while (break_condition == 0) {
				roiManager("deselect");
				roiManager("Show None");
				run("Select None");
				selectWindow("ROI_XO_MASK");
				run("Select None");
				roiManager("Show None");
				run("Duplicate...", "title=ROI_XO_dtec");
				run("Select None");
				roiManager("Show None");
				selectWindow("ROI_XO_dtec");
				run("Select None");
				roiManager("Show None");
				count_nb_next = roiManager("count");
				for (i=new_ROI_start_count; i <= roiManager("count"); i++) {
					if (roiManager("count") == new_ROI_start_count) {
						break;
					}
						
					else {
						roiManager("select", new_ROI_start_count);
						roiManager("delete");
						roiManager("deselect");
						selectWindow("Results");
						IJ.deleteRows(new_ROI_start_count, new_ROI_start_count);						
					}
				}
				
				roiManager("deselect");				
				roiManager("Show None");
				
				selectWindow("ROI_XO_dtec");
				Detect_Obj();

				selectWindow("ROI_XO_dtec");
				Manual_Correction();

				count_nb_next = roiManager("count");
				for (i=new_ROI_start_count; i <= count_nb_next; i++) {
					if (roiManager("count") == new_ROI_start_count) {
						break;
					}
					else {
						roiManager("select", new_ROI_start_count);
						roiManager("delete");
						roiManager("deselect");
						selectWindow("Results");
						IJ.deleteRows(new_ROI_start_count, new_ROI_start_count);
					}
				}
				
				selectWindow("ROI_XO_dtec");
				run("Select None");
				roiManager("Show None");
				Detect_Obj();
				
				selectWindow("Results");
				XO_AREA = 0;
				XO_WIDTH = 0;
				for (i=new_ROI_start_count; i < nResults();i++) {
					label = "Xylenol Orange, line : " +(i+1);
					setResult("Label",i,label);
					XO_AREA += getResult("Area", i);
					XO_WIDTH += getResult("Minor", i);
					if (CG_val == true) {
						for (j=new_ROI_start_count -1; j>=0; j--) {
							label = "Calcein Green, line : " +(j+1);
							setResult("Label",j,label);
						}
					}
				}
				updateResults();
				XO_WIDTH = XO_WIDTH/nResults();
				
				selectWindow("ROI" + n);
				setOption("Show All", true);

				Dialog.create("Fit quality review");
				choice_val = newArray("Yes", "No");
				Dialog.addChoice("Fit correct ?", choice_val);
				Dialog.show();
				user_choice = Dialog.getChoice();
				
				if (user_choice == "Yes") {
					break_condition = 1;
					selectWindow("ROI_XO_dtec");
					run("Close");
					selectWindow("ROI_XO_MASK");
					run("Close");
					selectWindow("ROI_XO_CONTOUR");
					run("Close");
					break;
				}
				
				else {
					selectWindow("ROI_XO_dtec");
					run("Close");
					
					for (i=new_ROI_start_count; i <= roiManager("count"); i++) {
						if (roiManager("count") == new_ROI_start_count) {
							break;
						}
						
						else {
							roiManager("select", new_ROI_start_count);
							roiManager("delete");
							roiManager("deselect");
							selectWindow("Results");
							IJ.deleteRows(new_ROI_start_count, new_ROI_start_count);							
						}
					}
					roiManager("deselect");
				}
			count +=1;
			}
			selectWindow("ROI" + n);
			image = "ROI" + n;
			
			if ((fluo_nb == 1) || ((fluo_nb == 2) && (OTC_val == false) )) {
				Process_Results();
				Calc_Draw_Distance_centroid();
				new_ROI_start_count = roiManager("count");
				if (RD_val == true) {
					selectWindow("ROI" + n);
					run("Duplicate...", "title=ROI_8bit");
					selectWindow("ROI_8bit");
					run("8-bit");
					getMinAndMax(min_val_o, max_val_o);
					if (XO_WIDTH > 20) {
						XO_WIDTH = 20;
					}
					run("Ridge Detection", "line_width=XO_WIDTH high_contrast=max_val_o low_contrast=min_val_o correct_position estimate_width displayresults add_to_manager method_for_overlap_resolution=NONE");
					if (save_choice == true) {
						saveAs("tiff",  dir + "ROI_8bit" + "IHC_ridge_ROI_" + n + ".tiff");
					}
				
				}
				
				
				if (save_choice == true) {
					run("Capture Image");
					saveAs("tiff",  dir + image + "IHC_dist_ROI_" + n + ".tiff");
					}
					
				FLUO_AREA = CG_AREA + XO_AREA;
				print("Fluorescent area :" + FLUO_AREA);
				print("ROI area : " + ROI_AREA_USERDEF);
				print("Fluo/total ratio : " + (FLUO_AREA*100)/ROI_AREA_USERDEF);
			}
			
			else if (((fluo_nb == 2) && (OTC_val == true)) || (fluo_nb == 3)) {
				new_ROI_start_count = roiManager("count");
			}
	}	
		
		if (OTC_val == true){
			// Colour thresholding : OTC
			// same as before...
			if (manual_thr == true){
				selectWindow("ROI" + n);
				run("Duplicate...", "title=ROI_OTC");
				run("Duplicate...", "title=ROI_OTC_CONTOUR");
				selectWindow("ROI_OTC");
				call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W");
				run( "Color Threshold..." );
				waitForUser( "Manually threshold image (B&W), then press OK." );
				selectWindow("Threshold Color");
				run("Close");
				selectWindow("ROI_OTC");
				rename("ROI_OTC_MASK");
			}
			
			else {
				selectWindow("ROI" + n);
				run("Duplicate...", "title=ROI_OTC");
				selectWindow("ROI_OTC");
				run("Duplicate...", "title=ROI_OTC_CONTOUR");
				selectWindow("ROI_OTC_CONTOUR");
				run("Split Channels");
				selectWindow("ROI_OTC_CONTOUR" + " (red)");
				run("Close");
				selectWindow("ROI_OTC_CONTOUR" + " (blue)");
				run("Close");
				
				selectWindow("ROI_OTC");
				run("Color Threshold...");	
				min=newArray(3);
				max=newArray(3);
				filter=newArray(3);
				a=getTitle();
				run("RGB Stack");
				run("Convert Stack to Images");
				selectWindow("Red");
				rename("0");
				selectWindow("Green");
				rename("1");
				selectWindow("Blue");
				rename("2");
				min[0]=130;
				max[0]=255;
				filter[0]="pass";
				min[1]=0;
				max[1]=0;
				filter[1]="stop";
				min[2]=70;
				max[2]=255;
				filter[2]="pass";
				for (i=0;i<3;i++){
				  selectWindow(""+i);
				  setThreshold(min[i], max[i]);
				  run("Convert to Mask");
				  if (filter[i]=="stop")  run("Invert");
				}
				imageCalculator("AND create", "0","1");
				imageCalculator("AND create", "Result of 0","2");
				for (i=0;i<3;i++){
				  selectWindow(""+i);
				  close();
				}
				selectWindow("Result of 0");
				close();
				selectWindow("Result of Result of 0");
				rename(a);

				selectWindow("Threshold Color");
				run("Close");
				
				
				selectWindow("ROI_OTC_CONTOUR" + " (green)");
				rename("ROI_OTC_CONTOUR");

				run("8-bit");
				run("Canny Edge Detector", "gaussian=2 low=2.5 high=7.5");
				

				imageCalculator("Add create", "ROI_OTC_CONTOUR","ROI_OTC");
				selectWindow("Result of ROI_OTC_CONTOUR");
				rename("ROI_OTC_MASK");
				selectWindow("ROI_OTC");
				run("Close");
			}
			
			selectWindow("ROI_OTC_MASK");
			
			run("Make Binary");
		
			Simple_PostProcessing();
			selectWindow("ROI_OTC_MASK");
			break_condition = 0;
			loop_counter = 0;
	
			while (break_condition == 0) {
				roiManager("deselect");
				run("Select None");
				roiManager("Show None");
				selectWindow("ROI_OTC_MASK");
				run("Duplicate...","title=ROI_OTC_dtec");
				run("Select None");
				roiManager("Show None");
				selectWindow("ROI_OTC_dtec");
				run("Select None");
				roiManager("Show None");
				for (i=new_ROI_start_count; i <= roiManager("count"); i++) {
					if (roiManager("count") == new_ROI_start_count) {
						break;
					}
						
					else {
						roiManager("select", new_ROI_start_count);
						roiManager("delete");
						roiManager("deselect");
						selectWindow("Results");
						IJ.deleteRows(new_ROI_start_count, new_ROI_start_count);						
					}
				}
				roiManager("deselect");
				roiManager("Show None");
				
				selectWindow("ROI_OTC_dtec");
				Detect_Obj();
				
				selectWindow("ROI_OTC_dtec");
				Manual_Correction();



				for (i=new_ROI_start_count; i <= roiManager("count"); i++) {
					if (roiManager("count") == new_ROI_start_count) {
						break;
					}
					else {
						roiManager("select", new_ROI_start_count);
						roiManager("delete");
						roiManager("deselect");
						selectWindow("Results");
						IJ.deleteRows(new_ROI_start_count, new_ROI_start_count);						
					}
				}
				
				selectWindow("ROI_OTC_dtec");
				run("Select None");
				roiManager("Show None");
				
				Detect_Obj();
				selectWindow("ROI" + n);
				setOption("Show All", true);
				Dialog.create("Fit quality review");
				choice_val = newArray("Yes", "No");
				Dialog.addChoice("Fit correct ?", choice_val);
				Dialog.show();
				user_choice = Dialog.getChoice();
				
				if (user_choice == "Yes") {
					break_condition = 1;
					break;
				}
				
				else {
					selectWindow("ROI_OTC_dtec");
					run("Close");

					for (i=new_ROI_start_count; i <= roiManager("count"); i++) {

						if (roiManager("count") == new_ROI_start_count) {
							break;
						}
						
						else {
							roiManager("select", new_ROI_start_count);
							roiManager("delete");
							selectWindow("Results");
							IJ.deleteRows(new_ROI_start_count, new_ROI_start_count);							
						}
					}
				}
			}
			
			selectWindow("Results");
			

			OTC_AREA = 0;
			OTC_WIDTH = 0;
			
			// some loops and if/else to set the labels (fluochrome name and line number) in the results table
			// Also, calculate the fluorochrome area and the % relative to the ROI area
			for (i=new_ROI_start_count; i < nResults();i++) {
				label = "Oxytetracycline, line : " +(i+1);
				setResult("Label",i,label);
				OTC_AREA += getResult("Area", i);
				OTC_WIDTH += getResult("Minor", i);
				}
				
			if ((CG_val == true) && (XO_val == false)) {
				for (j=0; j<new_ROI_start_count; j++) {
					label = "Calcein Green, line :" +(j+1);
					setResult("Label",j,label);
					}
				}	
					
			else if ((CG_val == false) && (XO_val == true))	{
				for (j=0; j<new_ROI_start_count; j++) {
					label = "Xylenol Orange, line : " +(j+1);
					setResult("Label",j,label);
					}			
				}
					
			else if ((CG_val == true) && (XO_val == true))	{
				for (j=Rs_Table_nb; j<new_ROI_start_count; j++) {
					label = "Xylenol Orange, line : " +(j+1);
					setResult("Label",j,label);
				}
				for (k=0; k<Rs_Table_nb; k++) {
					label = "Calcein Green, line :" +(k+1);
					setResult("Label",k,label);
					}						
				}
			updateResults();
			OTC_WIDTH = OTC_WIDTH/nResults();	
			
			
			
			selectWindow("ROI_OTC_dtec");
			run("Close");
			selectWindow("ROI" + n);
			image = "ROI" + n;
			Process_Results();
			Calc_Draw_Distance_centroid();
			if (RD_val == true) {
				selectWindow("ROI" + n);
				run("Duplicate...", "title=ROI_8bit");
				selectWindow("ROI_8bit");
				run("8-bit");
				getMinAndMax(min_val_t, max_val_t);
				if (OTC_WIDTH > 20) {
						OTC_WIDTH = 20;
					}

				run("Ridge Detection", "line_width=OTC_WIDTH high_contrast=max_val_t low_contrast=min_val_t correct_position estimate_width displayresults add_to_manager method_for_overlap_resolution=NONE");
				if (save_choice == true) {
					saveAs("tiff",  dir + "ROI_8bit" + "IHC_ridge_ROI_" + n + ".tiff");
					}
				
			}
			
			if (save_choice == true) {
				// if the user said so, do a screencap of the image
				run("Capture Image");
				saveAs("tiff",  dir + image + "IHC_dist_ROI_" + n + ".tiff");
			}
			// some prints...
			FLUO_AREA = CG_AREA + OTC_AREA + XO_AREA;
			print("Fluorescent area :" + FLUO_AREA);
			print("ROI area : " + ROI_AREA_USERDEF);
			print("Fluo/total ratio : " + (FLUO_AREA*100)/ROI_AREA_USERDEF);
		}

	if (export_choice == true) {
		// export the current results table as a .xls file
		selectWindow("Results");
		saveAs("Results",  dir + image + "ROI_" + n + ".xls");
	}
		/*
		Macro end by saving in a txt file all the content of the log window
		*/
	if (save_choice == true) {
		selectWindow("Log");
		windowcontent = getInfo();
		saveAs("text", dir +image + "results_log" + ".txt");
	}
	
	/*
	Then close all images,
	And close ImageJ/Fiji quietly
	*/
	
	while (nImages>0) { 
          selectImage(nImages); 
          close(); 
		}
	  
	showMessage("Ending...", "End of the evaluation. ImageJ will now close. All results are stored in " + dir);  
	run("Quit");
	
	
	
	}
	
	
	function DrawROI(){
		// Ask user to put the center of the ROI on the image
		setTool("multipoint");

		waitForUser( "Click on image to center the ROI, then press OK.");
		while ((selectionType() !=10)){
			setTool("multipoint");
			}
			
		// get the point coordinates
		run("Measure");

		ROI_center_x = getResult("X", 0);
		ROI_center_y = getResult("Y", 0);

		run("Clear Results");
		selectWindow("Results");
		run("Close");

		/* 
		At click, draw a polygon
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

		// Use this polygon as our analysis ROI
		run("Duplicate...", "title=ROI_temp");
		selectWindow("ROI_temp");
		rename("ROI");
		selectWindow("ROI");
	}

	function Simple_PostProcessing() {
		
		/* 
	   Some postprocessing, using morphomathematics standard operation
	   The goal here is to remove smaller objects and fill the gap between
	   Objects that are close enough to be considered as one
		*/

		if (PP_val == true) {
			
			for (i=0; i<1; i++) {
				waitForUser("Erase","Press OK when finished.");
				run("Dilate");
				run("Fill Holes");
			}
			
			waitForUser("Erase","Press OK when finished.");
			
			if ((CG_val == true) && (XO_val == false)) {
				for (i=0; i<2; i++) {
					waitForUser("Erase","Press OK when finished.");
					run("Erode");
				}
			}

			else if ((CG_val == false) && (XO_val == true)) {
				for (i=0; i<4; i++) {
					waitForUser("Erase","Press OK when finished.");
					run("Erode");
				}
			}

			else {
				for (i=0; i<3; i++) {
					waitForUser("Erase","Press OK when finished.");
					run("Erode");
				}
			}			
			
			waitForUser("Erase","Press OK when finished.");
			for (i=0; i<5; i++) {
				waitForUser("Erase","Press OK when finished.");
				run("Dilate");
			}
			waitForUser("Erase","Press OK when finished.");
			run("Close-");
			waitForUser("Erase","Press OK when finished.");			
			run("Dilate");
			waitForUser("Erase","Press OK when finished.");
			run("Fill Holes");
			
		}
	}

	function Manual_Correction(){
		// Allow the user to draw/erase things on the segmentation mask
		choice_val = newArray("Yes", "No");
		Dialog.create("Manual correction");
		Dialog.addChoice("Manually correct the segmentation result ?", choice_val, "No");
		Dialog.show();
		
		user_choice = Dialog.getChoice();
		// Note : beware that the setTool code for the paintbrush may be 17 in imageJ vanilla, and 19 in Fiji !
		
		if (user_choice == "Yes") {
			setForegroundColor(0, 0, 0); // Define the paintbrush color to black
			setBackgroundColor(255,255,255); // Define the background color to white 
			setTool(17); // Select the paintbrush
			waitForUser("Fill gaps between objects","Press OK when finished.");

			setForegroundColor(255, 255, 255); // Define the paintbrush color to white (eraser)
			setBackgroundColor(0,0,0); // Define the background color to black 
			setTool(17); // Select the paintbrush
			waitForUser("Erase","Press OK when finished."); 		

			while ((selectionType() !=-1)) { 
				/* 
				Ensure, using selectiontype(), that the paintbrush is properly selected
				We don't want the user to mess up everything using another tool
				*/	
				setTool(17);
			}
		}
	}

	function Detect_Obj() {
		// Detect each object, then return the area, centroid coordinate, ellipse fit (min and max diameters) for all
		run("Set Measurements...", "area centroid perimeter fit feret's add redirect=None decimal=3");
		run("Analyze Particles...", "size=min_OBJ_size-Infinity show=Nothing display include add"); // min_OBJ_size is user-defined
	}

	function Process_Results(){
		// Remove all objects with an area lower than a totally arbitrary value defined by the user
		selectWindow("ROI Manager");
		maxcount = roiManager("count");
		row_val = 0;
		for (k=0; k<=maxcount-1; k++) {
			selectWindow("Results");
			if (getResult("Area",row_val) < min_OBJ_size) {
				IJ.deleteRows(row_val, row_val);
				selectWindow("ROI Manager");
				roiManager("Select", row_val-1);
				roiManager("Delete");
				maxcount = roiManager("count");
			}
			
			else {
				row_val += 1;
				maxcount = roiManager("count");
			}
			
		}
		updateResults();
	}
	
	function Calc_Draw_Distance_centroid(){
		selectWindow("ROI Manager");
		maxcount = roiManager("count");

		// Draw things if only there is more than one object segmented (ROI) by the analyzer
		if (maxcount > 1) {	

			dist_array = newArray("Distance array");
			distlabel_array = newArray("Distance (label) array");
			setFont("Arial Narrow", 10, "antialiased");
			
			for (i=maxcount-1; i>0; i--) {

				for (j=0;j<=i-1; j++){
					// get centroid coordinates
					selectWindow("Results");
					pointsXA = getResult("X", i);
					pointsYA = getResult("Y", i);
					
					pointsXB = getResult("X",j);	
					pointsYB = getResult("Y",j);
					
					// calculate distance between centrols
					dX = pointsXB - pointsXA; 
					dY = pointsYB - pointsYA;
					dist = sqrt((dX*dX) + (dY*dY));
					
					// store the result in an array
					distarray_temp = newArray(lengthOf(dist_array)+1);
					
					for (k=0; k<lengthOf(dist_array);k++){
						distarray_temp[k]=dist_array[k];
					}
					
					distarray_temp[lengthOf(distarray_temp)-1]=dist;
					dist_array = distarray_temp;
					
					// define the text label
					distlabel = "Distance between lines " + (j+1) + " et " + (i+1) + " : ";
					
					distlabel_array_temp = newArray(lengthOf(distlabel_array)+1);
					
					for (k=0; k<lengthOf(distlabel_array);k++){
						distlabel_array_temp[k]=distlabel_array[k];
					}
					distlabel_array_temp[lengthOf(distlabel_array_temp)-1]=distlabel;
					distlabel_array = distlabel_array_temp;
				

					
					selectWindow("ROI" + n);
					roiManager("Select", i-1);
					run("Add Selection...");
					setOption("Show All", true);
					// On overlay, draw all ROI, lines and text labels
					Overlay.drawLine(pointsXA, pointsYA, pointsXB, pointsYB);
					Overlay.add;
					textline = "Distance : " + dist;
					Overlay.drawString(textline, (pointsXA +(dX/2) + 15), (pointsYB - (dY/2)));
					Overlay.drawString(i+1, (pointsXA+2), (pointsYA+2));
					Overlay.add;
					Overlay.show;
				}		
			}
			for (i=1;i<lengthOf(distarray_temp);i++) {
				// Add results to the Results table
				setResult("Label", nResults,distlabel_array[i]);
				setResult("Distance",nResults-1, dist_array[i]);
				updateResults();
			}
		}

		else {
			// Exception case : only one object (typically, one fluorescent object bigger than the cut-off)
			showMessage("Only one object detected...");
			selectWindow("Results");
			selectWindow("ROI" + n);
			roiManager("Select", 0);
			run("Add Selection...");
		}
	}
	
	function get_Time() {
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
		
	}
}