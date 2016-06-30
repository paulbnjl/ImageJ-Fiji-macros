/*
Macro : assisted MAR assessment macro
Version : 1-0
Author : Paul Bonijol
License : GNU/GPL v3
June 2016
*/
requires("1.44n");
var	len_fin_array = newArray("length2");
var	wth_fin_array =  newArray("width2");
var	name_fin_array = newArray("name2");

macro "semi-automatic IHC images line segmentation and distance calculation" {
	IMAGE_AREA = 0;
	timestring = get_Time();
	ROI_number = 1;
	ROI_size_dx = 200;
	ROI_size_dy = 200;
	ROI_AREA_USERDEF = ROI_size_dx * ROI_size_dy;
	min_OBJ_size = ROI_AREA_USERDEF/100;
	AR_val = false;
	DI_val = false;
	RD_val = false;
	fluo_nb = 0;
	CG_val = false;
	XO_val = false;
	auto_thr = true;
	man_thr = false;
	post_proc = false;
	segm_type = 0;
	er_nb = 0;
	dil_nb = 0;
	cl_nb = 0;
	fl_user_choice = false;
	man_cor = true;
	new_ROI_start_count = 0;
	line_area_array = newArray("line area");
	fluo_array = newArray("fluorochrome");
	area_percent_array = newArray("line area/total area");
	distlabel_array = newArray("distlabel");
	dist_array = newArray("dist");
	object_length_array = newArray("length");
	object_width_array = newArray("width");
	object_name_array = newArray("name");
	object_contour_pos_array = newArray("position");	
	showMessage("Warning !", "This macro is highly EXPERIMENTAL, and thus provided WITHOUT ANY WARRANTY. \n The author has no liability of any sort, and there is no guarantee that the results are accurate.");
	image = getTitle();
	selectWindow(image);
	run("RGB Color");
	run("Median...", "radius=2");
	run("Sharpen");
	IMAGE_AREA = getHeight() * getWidth();
	Dialog.create("ROI");
	Dialog.addNumber("Number of ROI(s) :", 1);
	Dialog.addNumber("Width: ", 200);
	Dialog.addNumber("Height : ", 200);  
	Dialog.show();
	ROI_number = Dialog.getNumber();
	ROI_size_dx = Dialog.getNumber();
	ROI_size_dy = Dialog.getNumber();
	ROI_AREA_USERDEF = ROI_size_dx*ROI_size_dy;
	min_OBJ_size = ROI_AREA_USERDEF/100;
	for (n=1;n<=ROI_number;n++) {
		selectWindow(image);
		DrawROI();
		selectWindow("ROI");
		ROI_name = "ROI" +n;
		rename(ROI_name);
		selectWindow(ROI_name);
		choice_analysis_pass = 0;
		while (choice_analysis_pass == 0) {
			Dialog.create("Analysis");
			Dialog.addMessage("Type of analysis to perform : ");
			Dialog.addCheckbox("Area evalutation ? ", false);
			Dialog.addCheckbox("Distance evaluation ? ", false);
			Dialog.addCheckbox("Length/width evaluation ? ", false);
			Dialog.addCheckbox("Save results ? ", false);
			Dialog.show();
			AR_val = Dialog.getCheckbox();
			DI_val = Dialog.getCheckbox();
			RD_val = Dialog.getCheckbox();
			save_choice = Dialog.getCheckbox();
			if (((AR_val + DI_val + RD_val) > 1) || ((AR_val + DI_val + RD_val) == 0)) {
				choice_analysis_pass = 0;
			}
			else {
				choice_analysis_pass = 1;
			}
		}
		if (save_choice == true) {
			dir = getDirectory("Choose where to save."); 
		}

			fluo_nb = 0;
			while (fluo_nb == 0) {
				Dialog.create("Fluorochrome(s)");
				Dialog.addMessage("Type of fluorochromes to detect :");
				Dialog.addCheckbox("Calcein Green", false);
				Dialog.addCheckbox("Xylenol Orange", false);
				Dialog.show();
				CG_val = Dialog.getCheckbox();
				XO_val = Dialog.getCheckbox();
				if ((CG_val == true )) {
					fluo_nb +=1;
				}
				if ((XO_val == true)) {
					fluo_nb +=1;
				}
				if (fluo_nb == 0) {
					showMessage("Please select at least one fluorescent compound to detect.");
				}
			}
		if (RD_val == false) {	
			segm_type = 0;
			while (segm_type == 0) { 	
				Dialog.create("Segmentation method");
				Dialog.addMessage("Segmentation method to use : ");
				Dialog.addCheckbox("Automatic (IsoData)", false);
				Dialog.addCheckbox("Manual", false);
				Dialog.addMessage("Postprocessing : ");
				Dialog.addCheckbox("Use PostProcessing ?", false);
				Dialog.show();
				auto_thr = Dialog.getCheckbox();
				man_thr = Dialog.getCheckbox();
				post_proc = Dialog.getCheckbox();
				if ((auto_thr == true) ) {		
				segm_type += 1;
				}
				if ((man_thr == true)) {
					segm_type +=1;
				}
				if (segm_type == 1) {
					break;
				}
				else {
					segm_type = 0;
				}
			}
			if (post_proc == true) {
				min_OBJ_size = ROI_AREA_USERDEF/100;
				Dialog.create("Detection & PostProcessing :");
				Dialog.addMessage("Detection :");
				Dialog.addSlider("Min object size",(min_OBJ_size/100),(min_OBJ_size*100),min_OBJ_size);
				Dialog.addSlider("Erode",0,8,0);
				Dialog.addSlider("Dilate",0,8,0);
				Dialog.addSlider("Close",0,8,0);
				Dialog.addCheckbox("Fill Holes ?", false);
				Dialog.addCheckbox("Manual correction ?", false);
				Dialog.show();
				min_obj_size_user = Dialog.getNumber();
				er_nb = Dialog.getNumber();
				dil_nb = Dialog.getNumber();
				cl_nb = Dialog.getNumber();
				fl_user_choice = Dialog.getCheckbox();
				man_cor = Dialog.getCheckbox();
			}
			else {
				min_OBJ_size = ROI_AREA_USERDEF/100;
				Dialog.create("Detection :");
				Dialog.addMessage("Detection :");
				Dialog.addSlider("Min object size",(min_OBJ_size/100),(min_OBJ_size*100),min_OBJ_size);
				Dialog.addCheckbox("Manual correction ?", false);
				Dialog.show();
				min_obj_size_user = Dialog.getNumber();
				man_cor = Dialog.getCheckbox();
			}
		}	
			if (CG_val == true){
				if (RD_val == false) {
					if (man_thr == true){
						Manual_Segmentation(ROI_name);
					}
					else if (auto_thr == true){
						Auto_Segmentation(ROI_name, "green");	
					}
					Detect_Contour(ROI_name);
					Add_Images("THR","CONTOUR");
					selectWindow("MASK");
					run("Make Binary");
					break_condition = 0;
					while (break_condition ==0) {
						roiManager("deselect");
						roiManager("Show None");
						run("Select None");
						selectWindow("MASK");
						run("Select None");
						roiManager("Show None");
						run("Duplicate...", "title=ROI_CG_dtec");
						selectWindow("ROI_CG_dtec");
						run("Select None");
						roiManager("Show None");
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
						Detect_Obj();
						selectWindow("ROI_CG_dtec");
						run("Select None");
						Simple_PostProcessing();
						Manual_Correction();
						selectWindow("ROI_CG_dtec");
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
						Detect_Obj();
						selectWindow("Results");
						CG_AREA = 0;
						CG_WIDTH = 0;
						for (i=new_ROI_start_count; i < nResults();i++) {
							selectWindow("Results");
							label = "Calcein Green, line : " +(i+1);
							fluo_array_temp = newArray(lengthOf(fluo_array)+1);
							line_area_array_temp = newArray(lengthOf(line_area_array)+1);
							area_percent_array_temp = newArray(lengthOf(area_percent_array)+1);
							for (k=0; k<lengthOf(line_area_array);k++){
								line_area_array_temp[k]=line_area_array[k];
								area_percent_array_temp[k]=area_percent_array[k];
								fluo_array_temp[k]=fluo_array[k];
							}
							fluo_array_temp[lengthOf(fluo_array_temp)-1]=label;
							line_area_array_temp[lengthOf(line_area_array_temp)-1]=getResult("Area", i);
							area_percent_array_temp[lengthOf(area_percent_array_temp)-1]=(getResult("Area", i)*100)/ROI_AREA_USERDEF;
							fluo_array = fluo_array_temp;
							area_percent_array = area_percent_array_temp;
							line_area_array = line_area_array_temp;
							setResult("Label",i,label);
							CG_AREA += getResult("Area", i);
							CG_WIDTH += getResult("Minor", i);
						}
						updateResults();
						fluo_array = Array.slice(fluo_array,1);
						area_percent_array = Array.slice(area_percent_array,1);						
						line_area_array = Array.slice(line_area_array,1);
						CG_WIDTH = CG_WIDTH/nResults();
						selectWindow("ROI" + n);
						setOption("Show All with labels", true);
						Dialog.create("Fit quality review");
						choice_val = newArray("Yes", "No");
						Dialog.addChoice("Fit correct ?", choice_val);
						Dialog.show();
						user_choice = Dialog.getChoice();
						if (user_choice == "Yes") {
							break_condition = 1;
							selectWindow("ROI_CG_dtec");
							run("Close");
							selectWindow("MASK");
							run("Close");
							break;
						}
						else {
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
						if (DI_val == true) {
							Calc_Draw_Distance_Centroid();
							if (save_choice == true) {
								selectWindow("ROI" + n);
								run("Capture Image");
								saveAs("tiff",  dir + image + "Distance_Between_Lines_Evaluation_Results_ROI_" + n + "_" + timestring + ".tiff");
								run("Close");
								selectWindow("Results");
								saveAs("Distance_Between_Lines_Evaluation_Results",  dir + image + "Distance_Between_Lines_Evaluation_Results_ROI_" + n + "_" + timestring + ".xls");
								
							}	
						}						
						FLUO_AREA = CG_AREA;
						if (AR_val == true) {
							selectWindow("Results");
							setResult("Fluorescent area",nResults(),FLUO_AREA);
							setResult("Label",nResults()-1,"Fluorescent area");
							setResult("ROI area",nResults(),ROI_AREA_USERDEF);
							setResult("Label",nResults()-1,"ROI area");
							setResult("Fluo/total ratio",nResults(), ((FLUO_AREA*100)/ROI_AREA_USERDEF));
							setResult("Label",nResults()-1, "Fluo/total ratio");
							if (save_choice == true) {
								selectWindow("ROI" + n);
								setOption("Show All with labels", true);
								run("Capture Image");
								saveAs("tiff",  dir + "IHC_AREA_Results_ROI_CG_" + n + "_" + timestring + ".tiff");
								run("Close");
								saveAs("Area_Evaluation_Results",  dir + image + "Area_Evaluation_Results_ROI_" + n + "_" + timestring + ".xls");
							}
						}
						else {
							selectWindow("Results");
							run("Close");
						}
					}
					else {
						new_ROI_start_count = roiManager("count");
						Rs_Table_nb = new_ROI_start_count;
					}
				}
				else if (RD_val == true) {
					selectWindow("ROI" + n);
					run("Duplicate...", "title=IMG_TO_SPLIT");
					selectWindow("IMG_TO_SPLIT");
					run("Split Channels");
					selectWindow("IMG_TO_SPLIT" + " (red)");
					run("Close");
					selectWindow("IMG_TO_SPLIT" + " (blue)");
					run("Close");
					selectWindow("IMG_TO_SPLIT" + " (green)");
					rename("ROI_GREEN");
					run("Duplicate...", "title=ROI_GREEN_8bit");
					selectWindow("ROI_GREEN_8bit");
					run("8-bit");
					selectWindow("ROI_GREEN_8bit");
					getMinAndMax(min_val, max_val);
					run("Ridge Detection", "line_width=15 high_contrast=max_val low_contrast=min_val correct_position estimate_width displayresults add_to_manager method_for_overlap_resolution=NONE");
					result_entry_start = 0;
					Process_Ridge_Results("_CG");
					if (XO_val == false) {
						Display_Ridge_Results();
						if (save_choice == true) {
							selectWindow("ROI" + n);
							selectWindow("ROI Manager");
							setOption("Show All with labels", true);
							selectWindow("ROI" + n);
							run("Capture Image");
							saveAs("tiff",  dir + "IHC_ridge_ROI_CG_" + n + "_" + timestring + ".tiff");
							selectWindow("IHC_ridge_ROI_CG_" + n + "_" + timestring +".tiff");
							rename("RS");
							selectWindow("Results");
							saveAs("Length_width_detection_Results",  dir + image + "Length_width_detection_Results_ROI_" + n + "_" + timestring + ".xls");
							selectWindow("Results");
							run("Close");
							selectWindow("RS");
							run("Close");
						}			
					}
					selectWindow("ROI_GREEN");
					run("Close");
					selectWindow("ROI_GREEN_8bit");
					run("Close");
				}	
			}
			
			if (XO_val == true){
				if (RD_val == false) {
					if (man_thr == true){
						Manual_Segmentation(ROI_name);
					}
					else if (auto_thr == true){
						Auto_Segmentation(ROI_name, "red");	
					}
					Detect_Contour(ROI_name);
					Add_Images("THR", "CONTOUR");
					selectWindow("MASK");
					run("Make Binary");
					break_condition = 0;
					count = 0;
					while (break_condition == 0) {
						roiManager("deselect");
						roiManager("Show None");
						run("Select None");
						selectWindow("MASK");
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
						Simple_PostProcessing();
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
							fluo_array_temp = newArray(lengthOf(fluo_array)+1);
							line_area_array_temp = newArray(lengthOf(line_area_array)+1);
							area_percent_array_temp = newArray(lengthOf(area_percent_array)+1);
							for (k=0; k<lengthOf(line_area_array);k++){
								line_area_array_temp[k]=line_area_array[k];
								area_percent_array_temp[k]=area_percent_array[k];
								fluo_array_temp[k]=fluo_array[k];
							}
							fluo_array_temp[lengthOf(fluo_array_temp)-1]=label;
							line_area_array_temp[lengthOf(line_area_array_temp)-1]=getResult("Area", i);
							area_percent_array_temp[lengthOf(area_percent_array_temp)-1]=(getResult("Area", i)*100)/ROI_AREA_USERDEF;
							fluo_array = fluo_array_temp;
							area_percent_array = area_percent_array_temp;
							line_area_array = line_area_array_temp;				
						}
						fluo_array = Array.slice(fluo_array,1);
						area_percent_array = Array.slice(area_percent_array,1);						
						line_area_array = Array.slice(line_area_array,1);
						updateResults();
						XO_WIDTH = XO_WIDTH/nResults();
						selectWindow("ROI" + n);
						setOption("Show All with labels", true);
						Dialog.create("Fit quality review");
						choice_val = newArray("Yes", "No");
						Dialog.addChoice("Fit correct ?", choice_val);
						Dialog.show();
						user_choice = Dialog.getChoice();
						if (user_choice == "Yes") {
							break_condition = 1;
							selectWindow("ROI_XO_dtec");
							run("Close");
							selectWindow("MASK");
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
					if (DI_val == true) {
						Calc_Draw_Distance_Centroid();
						if (save_choice == true) {
							selectWindow("ROI" + n);
							run("Capture Image");
							saveAs("tiff",  dir + image + "IHC_Distance_Between_Lines_Evaluation_Results_ROI_" + n + "_" + timestring + ".tiff");
							run("Close");
							selectWindow("Results");	
							saveAs("Distance_Between_Lines_Evaluation_Results",  dir + image + "Distance_Between_Lines_Evaluation_Results_ROI_" + n + "_" + timestring + ".xls");
						}
					}

					if (CG_val == true) {
						FLUO_AREA = CG_AREA + XO_AREA;
					}
					else if (CG_val == false) {
						FLUO_AREA = XO_AREA;
					}
					
					if (AR_val == true) {
						selectWindow("Results");
						setResult("Fluorescent area",nResults(),FLUO_AREA);
						setResult("Label",nResults()-1,"Fluorescent area");
						setResult("ROI area",nResults(),ROI_AREA_USERDEF);
						setResult("Label",nResults()-1,"ROI area");
						setResult("Fluo/total ratio",nResults(), ((FLUO_AREA*100)/ROI_AREA_USERDEF));
						setResult("Label",nResults()-1, "Fluo/total ratio");
						if (save_choice == true) {
							selectWindow("ROI"+n);
							setOption("Show All with labels", true);
							run("Capture Image");
							saveAs("tiff",  dir + "IHC_AREA_Results_ROI_" + n + "_" + timestring + ".tiff");
							run("Close");
							saveAs("Area_Evaluation_Results",  dir + image + "Area_Evaluation_Results_ROI_" + n + "_" + timestring + ".xls");
						}						
					}
				}
				else if (RD_val == true) {
					selectWindow("ROI" + n);
					run("Duplicate...", "title=IMG_TO_SPLIT");
					selectWindow("IMG_TO_SPLIT");
					run("Split Channels");
					selectWindow("IMG_TO_SPLIT" + " (green)");
					run("Close");
					selectWindow("IMG_TO_SPLIT" + " (blue)");
					run("Close");
					selectWindow("IMG_TO_SPLIT" + " (red)");
					rename("ROI_RED");
					run("Duplicate...", "title=ROI_RED_8bit");
					selectWindow("ROI_RED_8bit");
					run("8-bit");
					selectWindow("ROI_RED_8bit");
					getMinAndMax(min_val, max_val);
					if (isOpen("Results") == true) {
						selectWindow("Results");
						result_entry_start = nResults() +1;
					}
					else {
						result_entry_start = 0;
					}
					run("Ridge Detection", "line_width=15 high_contrast=max_val low_contrast=min_val correct_position estimate_width displayresults add_to_manager method_for_overlap_resolution=NONE");
					
					Process_Ridge_Results("_XO");
					Display_Ridge_Results();
					if (save_choice == true) {
						selectWindow("ROI" + n);
						selectWindow("ROI Manager");
						setOption("Show All with labels", true);
						selectWindow("ROI" + n);
						run("Capture Image");
						if (CG_val == false) {
							saveAs("tiff",  dir + "IHC_length_width_detection_Results_XO_ROI_" + n + "_" + timestring + ".tiff");
							selectWindow("IHC_length_width_detection_Results_XO_ROI_" + n + "_" + timestring + ".tiff");
							rename("RS");
						}
						else {
							saveAs("tiff",  dir + "IHC_length_width_detection_Results_CG_XO_ROI_" + n + "_" + timestring + ".tiff");
							selectWindow("IHC_length_width_detection_Results_CG_XO_ROI_" + n + "_" + timestring + ".tiff");
							rename("RS");
						}
						selectWindow("RS");
						run("Close");
						selectWindow("Results");
						saveAs("Length_width_detection_Results",  dir + image + "Length_width_detection_Results_ROI_" + n + "_" + timestring + ".xls");
						selectWindow("Results");
						run("Close");
					}
				
					selectWindow("ROI_RED");
					run("Close");
					selectWindow("ROI_RED_8bit");
					run("Close");
				}
			}
			selectWindow("ROI" + n);
			run("Close");
			selectWindow("ROI Manager");
			run("Close");
		}	
	}
	function Calc_Draw_Distance_Centroid(){
		selectWindow("ROI Manager");
		maxcount = roiManager("count");
		if (maxcount > 1) {	
			dist_array = newArray("Distance array");
			distlabel_array = newArray("Distance (label) array");
			setFont("Arial Narrow", 10, "antialiased");
			for (i=maxcount-1; i>0; i--) {
				for (j=0;j<=i-1; j++){
					selectWindow("Results");
					pointsXA = getResult("X", i);
					pointsYA = getResult("Y", i);
					pointsXB = getResult("X",j);	
					pointsYB = getResult("Y",j);
					dX = pointsXB - pointsXA; 
					dY = pointsYB - pointsYA;
					dist = sqrt((dX*dX) + (dY*dY));
					distarray_temp = newArray(lengthOf(dist_array)+1);
					for (k=0; k<lengthOf(dist_array);k++){
						distarray_temp[k]=dist_array[k];
					}
					distarray_temp[lengthOf(distarray_temp)-1]=dist;
					dist_array = distarray_temp;
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
					setOption("Show All with labels", true);
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
				setResult("Label", nResults,distlabel_array[i]);
				setResult("Distance",nResults-1, dist_array[i]);
				updateResults();
			}
		}
		else {
			showMessage("Only one object detected...");
			selectWindow("Results");
			selectWindow("ROI" + n);
			roiManager("Select", 0);
			run("Add Selection...");
		}
	}
	function Detect_Obj() {
		run("Set Measurements...", "area centroid perimeter fit feret's add redirect=None decimal=3");
		run("Analyze Particles...", "size=min_OBJ_size-Infinity show=Nothing display include add");
	}
	function Manual_Correction(){
		if (man_cor == true) { 
			choice_val = newArray("Yes", "No");
			Dialog.create("Manual correction");
			Dialog.addChoice("Manually correct the segmentation result ?", choice_val, "No");
			Dialog.show();
			user_choice = Dialog.getChoice();
			if (user_choice == "Yes") {
				setForegroundColor(0, 0, 0);
				setBackgroundColor(255,255,255);  
				setTool(17);
				waitForUser("Fill gaps between objects","Press OK when finished.");
				setForegroundColor(255, 255, 255);
				setBackgroundColor(0,0,0);
				setTool(17);
				waitForUser("Erase","Press OK when finished."); 		
				while ((selectionType() !=-1)) { 
					setTool(17);
				}
			}
		}
	}		
	function Simple_PostProcessing() {
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
	function Manual_Segmentation(img){
		selectWindow(img);
		run("Duplicate...", "title=ROI_MASK");
		selectWindow("ROI_MASK");
		call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W");
		run( "Color Threshold..." );
		waitForUser( "Manually threshold image (B&W), then press OK." );
		selectWindow("Threshold Color");
		run("Close");
		selectWindow("ROI_MASK");
		rename("THR");
	}
	function Auto_Segmentation(img, canal){
		selectWindow(img);
		run("Duplicate...", "title=IMG_TO_SPLIT");
		selectWindow("IMG_TO_SPLIT");
		run("Split Channels");
		if (canal == "green") {
			selectWindow("IMG_TO_SPLIT" + " (blue)");
			run("Close");
			selectWindow("IMG_TO_SPLIT" + " (red)");
			run("Close");
			selectWindow("IMG_TO_SPLIT" + " (green)");
			rename("THR");
		}
		else if (canal == "red") {
			selectWindow("IMG_TO_SPLIT" + " (green)");
			run("Close");
			selectWindow("IMG_TO_SPLIT" + " (blue)");
			run("Close");
			selectWindow("IMG_TO_SPLIT" + " (red)");
			rename("THR");
		}
		else {
			selectWindow("IMG_TO_SPLIT" + " (red)");
			run("Close");
			selectWindow("IMG_TO_SPLIT" + " (green)");
			run("Close");
			selectWindow("IMG_TO_SPLIT" + " (blue)");
			rename("THR");
		}
		run("Auto Threshold...", "method=IsoData white");
	}
	function Detect_Contour(img) {
		selectWindow(img);
		run("Duplicate...", "title=CONTOUR");
		selectWindow("CONTOUR");
		run("8-bit");
		run("Canny Edge Detector", "gaussian=2 low=2.5 high=7.5");
	}	
	function Add_Images(img1, img2){
		imageCalculator("Add create", img1,img2);
		selectWindow("Result of " + img1);
		rename("MASK");
		selectWindow(img1);
		run("Close");
		selectWindow(img2);
		run("Close");
	}	
	function Simple_PostProcessing() {
		if (post_proc == true) {
			if (dil_nb != 0) {
				for (i=1; i<=dil_nb; i++) {
					run("Dilate");
				}
			}
			if (er_nb != 0) {
				for (i=1; i<=er_nb; i++) {
					run("Erode");
				}
			}
			if (cl_nb != 0) {
				for (i=1; i<=cl_nb; i++) {
					run("Close-");
				}
			}
			if (fl_user_choice == true) {
				run("Fill Holes");
			}
		}
	}
	function DrawROI(){
		setTool("multipoint");
		waitForUser( "Click on image to center the ROI, then press OK.");
		while ((selectionType() !=10)){
			setTool("multipoint");
		}
		run("Measure");
		ROI_center_x = getResult("X", 0);
		ROI_center_y = getResult("Y", 0);
		run("Clear Results");
		selectWindow("Results");
		run("Close");
		x1 = ROI_center_x - ((ROI_size_dx)/2);
		y1 = ROI_center_y + ((ROI_size_dy)/2);
		x2 = ROI_center_x + ((ROI_size_dx)/2);
		y2 = ROI_center_y + ((ROI_size_dy)/2);
		x3 = ROI_center_x + ((ROI_size_dx)/2);
		y3 = ROI_center_y - ((ROI_size_dy)/2);
		x4 = ROI_center_x - ((ROI_size_dx)/2);
		y4 = ROI_center_y - ((ROI_size_dy)/2);
		makePolygon(x1,y1,x2,y2,x3,y3,x4,y4);
		run("Duplicate...", "title=ROI_temp");
		selectWindow("ROI_temp");
		rename("ROI");
		selectWindow("ROI");
	}
	function Process_Ridge_Results(obj_type) {
		selectWindow("Junctions");
		run("Close");
		selectWindow("Results");
		result_entry_start = 0;
		for (p=0; p<nResults(); p++) {
			object_length = getResult("Length",p);
			object_width = getResult("Line width", p);
			object_length_array_temp = newArray(lengthOf(object_length_array)+1);
			object_width_array_temp = newArray(lengthOf(object_width_array)+1);
			for (q=0; q<lengthOf(object_length_array);q++){
				object_length_array_temp[q]=object_length_array[q];
				object_length_array_temp[lengthOf(object_length_array_temp)-1]=object_length;
				object_width_array_temp[q]=object_width_array[q];
				object_width_array_temp[lengthOf(object_width_array_temp)-1]=object_width;
			}
			object_length_array = object_length_array_temp;
			object_width_array = object_width_array_temp;
			object_contour_ID = getResult("Contour ID", p);
			if (p == 0) {
				object_contour_pos_array_temp = newArray(lengthOf(object_contour_pos_array)+1);
				object_name_array_temp = newArray(lengthOf(object_name_array)+1);
					for (h=0; h<lengthOf(object_name_array);h++){
						object_name_array_temp[h] = object_name_array[h];
						object_name_array_temp[lengthOf(object_name_array_temp)-1]=object_contour_ID;
					}
					object_name_array = object_name_array_temp;
					for (hh=0; hh<lengthOf(object_contour_pos_array);hh++){
						object_contour_pos_array_temp[hh] = object_contour_pos_array[hh];
						object_contour_pos_array_temp[lengthOf(object_contour_pos_array_temp)-1]=p;
					}
					object_contour_pos_array = object_contour_pos_array_temp;		
				}
			else if (p > 0) {
				if (object_contour_ID != object_name_array[lengthOf(object_name_array)-1]) {
					object_contour_pos_array_temp = newArray(lengthOf(object_contour_pos_array)+1);
					object_name_array_temp = newArray(lengthOf(object_name_array)+1);
					for (h=0; h<lengthOf(object_name_array);h++){
						object_name_array_temp[h] = object_name_array[h];
						object_name_array_temp[lengthOf(object_name_array_temp)-1]=object_contour_ID;
					}
					object_name_array = object_name_array_temp;
					for (hh=0; hh<lengthOf(object_contour_pos_array);hh++){
						object_contour_pos_array_temp[hh] = object_contour_pos_array[hh];
						object_contour_pos_array_temp[lengthOf(object_contour_pos_array_temp)-1]=p;
					}
					object_contour_pos_array = object_contour_pos_array_temp;					
				}
			}
		}
		object_length_array = Array.slice(object_length_array,1);
		object_width_array = Array.slice(object_width_array,1);
		object_name_array = Array.slice(object_name_array,1);
		object_contour_pos_array = Array.slice(object_contour_pos_array,1);
		selectWindow("Results");
		run("Clear Results");
		IJ.deleteRows(result_entry_start, nResults());
		for (uuu = 0 ; uuu < lengthOf(object_name_array); uuu++) {
			obj_len = 0;
			obj_wth = 0;
			max = uuu +1;
			if (max == lengthOf(object_name_array)) {
				for (uu = lengthOf(object_length_array)-1 ; uu >= object_contour_pos_array[lengthOf(object_contour_pos_array)-1] ; uu--) {
					obj_len += object_length_array[uu];
					obj_wth +=  object_width_array[uu];
				}
			}
			else {
				for (uu=object_contour_pos_array[uuu];uu<object_contour_pos_array[uuu+1];uu++) {
					obj_len += object_length_array[uu];
					obj_wth +=  object_width_array[uu];
				}
			}
			if (max == lengthOf(object_name_array)) {
				obj_len = obj_len / ((lengthOf(object_length_array)-1) - (object_contour_pos_array[lengthOf(object_contour_pos_array)-1]));
				obj_wth = obj_wth / ((lengthOf(object_width_array)-1) - (object_contour_pos_array[lengthOf(object_contour_pos_array)-1]));
			}
			else {
				obj_len = obj_len / (object_contour_pos_array[uuu+1] - object_contour_pos_array[uuu]);
				obj_wth = obj_wth / (object_contour_pos_array[uuu+1] - object_contour_pos_array[uuu]);
			}
			len_fin_array_temp = newArray(lengthOf(len_fin_array)+1);
			for (aa=0; aa<lengthOf(len_fin_array);aa++){
				len_fin_array_temp[aa] = len_fin_array[aa];
				len_fin_array_temp[lengthOf(len_fin_array_temp)-1]=obj_len;
			}
			len_fin_array = len_fin_array_temp;
			wth_fin_array_temp = newArray(lengthOf(wth_fin_array)+1);
			for (bb=0; bb<lengthOf(wth_fin_array);bb++){
				wth_fin_array_temp[bb] =  wth_fin_array[bb];
				wth_fin_array_temp[lengthOf(wth_fin_array_temp)-1]=obj_wth;
			}
			wth_fin_array = wth_fin_array_temp;
			name_fin_array_temp = newArray(lengthOf(name_fin_array)+1);
			for (cc=0; cc<lengthOf(name_fin_array);cc++){
				name_fin_array_temp[cc] =  name_fin_array[cc];
				name_fin_array_temp[lengthOf(name_fin_array_temp)-1]= d2s(object_name_array[uuu],0) + obj_type;
			}
			name_fin_array = name_fin_array_temp;
			for (r=0; r<lengthOf(name_fin_array);r++){
			}
		}	
	}
	function Display_Ridge_Results(){	
		for (r=0; r<lengthOf(name_fin_array);r++){
		}
		name_fin_array = Array.slice(name_fin_array,1);
		len_fin_array = Array.slice(len_fin_array,1);
		wth_fin_array = Array.slice(wth_fin_array,1);
		
		for (r=0; r<lengthOf(name_fin_array);r++){
		}
		selectWindow("Results");
		run("Clear Results");
		for (vv = 0; vv < lengthOf(name_fin_array) ; vv++) {
			setResult("Object name",(vv),name_fin_array[vv]);
			setResult("Object length",(vv),len_fin_array[vv]);
			setResult("Object width",(vv),wth_fin_array[vv]);
		}
	}

	function get_Time() {
		/*
		A little copy/paste of the GetTime macro
		to format our results with the current date and time
		*/
		
		MonthNames=newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
		DayNames=newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
		getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
		TimeString=DayNames[dayOfWeek];
		if (dayOfMonth<10) {TimeString = TimeString+"0";}
		TimeString=TimeString+dayOfMonth+"_"+MonthNames[month]+"-"+year+"Time_";
		if (hour<10) {TimeString = TimeString+"0";}
		TimeString=TimeString+hour+"_";
		if (minute<10) {TimeString = TimeString+"0";}
		TimeString=TimeString+minute+"_";
		if (second<10) {TimeString = TimeString+"0";}
		TimeString=TimeString+second;
		return TimeString;
	}	


		