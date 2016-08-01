
/*
####################################################################
####################################################################
*/

/*
Macro : Cell counter - Feulgen - advanced
Version : 0.0.1
Author : Paul Bonijol
License : GNU/GPL v3
July 2016

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

macro "Cell counter - Feulgen - advanced" {
	
	requires("1.46");	
	showMessage("Warning !", "This macro is highly EXPERIMENTAL, and thus provided WITHOUT ANY WARRANTY. The author has no liability of any sort, and there is no guarantee that the results are accurate.");
	Dialog.create("Menu");
	Dialog.addMessage("Options :");
	Dialog.addSlider("[Segmentation mask] threshold radius : ", 1, 20, 5);
	Dialog.addSlider("ROI number : ", 10, 100, 10);
	Dialog.addCheckbox("Save results ? ", false);
	Dialog.addCheckbox("Plot area repartition histogram ? ", false);
	Dialog.show();
	radius_val = Dialog.getNumber();
	window_f = Dialog.getNumber();
	save_choice = Dialog.getCheckbox();
	plot_val = Dialog.getCheckbox();
	
	image = getTitle();
	rename("image");
	selectWindow("image");
	run("RGB Color");
	run("Duplicate...", "title=image_copy");
	selectWindow("image");
	image_height = getHeight();
	image_width = getWidth();
	image_area = image_height * image_width;
	
	window_h = (image_height/window_f);
	window_w = (image_width/window_f);
	TOTAL_AREA = window_h * window_w;
	fontsize = window_h/5;
	fontsize2 = 0.8 * fontsize;
	setColor(0);
	setLineWidth(1);
	setJustification("center");
	
	/* 
		Split image in three channels (R,G,B)
		Close G and B
		Given the coloration (Feulgen stained tissues are mostly red/pink/violet), 
		the max intensity will be in the R channel
	*/
	
	run("Split Channels");
	selectWindow("image" +" (blue)");
	close();
	selectWindow("image" +" (green)");
	close();
	selectWindow("image" +" (red)");
	rename("image_red");
	newImage("ROI_MAP", "RGB white", image_width, image_height, 1);
	
	/* 
		Density ranking
		Idea : use a wobbling window system
		to rank image areas by occupation (after autoThresholding using IsoData method)
		1 = 0-25% : Low cell density
		2 = 26-50% : medium cell density
		3 = 51-75% : high cell density
		4 = 76-100% : very high density
	*/
	pos_x = 0;
	pos_y = 0;
	count = 1;
	
	window_occupation_array = newArray("area");
	occupation_class_array = newArray("occupation_class");
	window_x_coord_array = newArray("window_x_start_coord");
	window_y_coord_array = newArray("window_y_start_coord");
	
	for (i=0; i <= ((window_f*window_f)-1); i++) {
		selectWindow("image_red");
		makeRectangle(pos_x,pos_y, window_w, window_h);
		run("Duplicate...", "title=ROI");
		selectWindow("ROI");
		run("Auto Threshold...", "method=IsoData ignore_black ignore_white white");
		run("Set Measurements...", "area redirect=None decimal=3");		
		run("Create Selection");
		run("Measure");
		BLACK_AREA = TOTAL_AREA - getResult("Area", 0);
		OCP_RATIO = ((BLACK_AREA/TOTAL_AREA)*100);
		
		run("Select None");
		selectWindow("ROI_MAP");
		text_string = "ROI " + i + 1; 
		setFont("Arial Narrow", fontsize, "bold");
		drawString(text_string, (pos_x + (window_w/2)), (pos_y +(window_h/2)));
		drawRect(pos_x, pos_y, window_w, window_h);
		run("Select None");
		selectWindow("image_red");
		
		
		
		window_occupation_array_temp = newArray(lengthOf(window_occupation_array)+1);
		occupation_class_array_temp = newArray(lengthOf(occupation_class_array)+1);
		
		for (d=0; d<lengthOf(window_occupation_array);d++){
			window_occupation_array_temp[d]=window_occupation_array[d];
			occupation_class_array_temp[d]=occupation_class_array[d];
		}
		
		window_occupation_array_temp[lengthOf(window_occupation_array)-1]=round(OCP_RATIO);
		
		if (OCP_RATIO < 26) {
			occupation_class_array_temp[lengthOf(occupation_class_array)-1]	= "Low Cell Density";
		}
		else if ((OCP_RATIO >= 26) || (OCP_RATIO < 51)) {
			occupation_class_array_temp[lengthOf(occupation_class_array)-1]	= "Medium Cell Density";
		}
		
		else if ((OCP_RATIO >= 51) || (OCP_RATIO < 76)) {
			occupation_class_array_temp[lengthOf(occupation_class_array)-1]	= "High Cell Density";
		}
		
		else if ((OCP_RATIO >= 76) || (OCP_RATIO <= 100)) {
			occupation_class_array_temp[lengthOf(occupation_class_array)-1]	= "Very High Cell Density";
		}
		
		else {
			occupation_class_array_temp[lengthOf(occupation_class_array)-1]	= "N/A";
		}
		text_string2 = occupation_class_array_temp[lengthOf(occupation_class_array)-1];
		window_occupation_array = window_occupation_array_temp;
		occupation_class_array = occupation_class_array_temp;
		run("Clear Results");
		
		selectWindow("ROI_MAP");
		setFont("Arial Narrow", fontsize2, "normal");
		setJustification("center");
		drawString(text_string2, (pos_x + (window_w/2)), (pos_y + (fontsize2 + 5) + (window_h/2)));
		
		selectWindow("ROI");
		run("Close");
		
		window_x_coord_array_temp = newArray(lengthOf(window_x_coord_array)+1);
		window_y_coord_array_temp = newArray(lengthOf(window_y_coord_array)+1);
		
		for (d=0; d<lengthOf(window_x_coord_array);d++){
			window_x_coord_array_temp[d]=window_x_coord_array[d];
			window_y_coord_array_temp[d]=window_y_coord_array[d];
		}
		
		
		count +=1;
		pos_x += window_w;
		window_x_coord_array_temp[lengthOf(window_x_coord_array)-1]=pos_x;
		
		if (count == window_f + 1) {
			pos_x = 0;
			pos_y += window_h;
			count = 1;
		}

		window_x_coord_array_temp[lengthOf(window_x_coord_array)-1]=pos_x;
		window_y_coord_array_temp[lengthOf(window_y_coord_array)-1]=pos_y;
		window_x_coord_array = window_x_coord_array_temp;
		window_y_coord_array = window_y_coord_array_temp;
		
	}
	run("Select None");
	
	//window_occupation_array = Array.slice(window_occupation_array,1);
	//occupation_class_array = Array.slice(occupation_class_array,1);
	//window_x_coord_array = Array.slice(window_x_coord_array,1);
	//window_y_coord_array = Array.slice(window_y_coord_array,1);
	
	run("Select None");
	selectWindow("image_red");
	run("Select All");
	cell_type_1_area_array = newArray("cell type 1 area");
	cell_type_1_xpos_array = newArray("cell type 1 centroid X");
	cell_type_1_ypos_array = newArray("cell type 1 centroid Y");
	
	run("Duplicate...", "title=mask");
	selectWindow("mask");
	run("8-bit");	
	run("Auto Local Threshold...", "method=Phansalkar radius=radius_val parameter_1=0 parameter_2=0 white");
	
	/*
	Phansalkar Auto Thresholding
	Phansalskar, N; More, S & Sabale, A et al. (2011), "Adaptive local thresholding for detection of nuclei in diversity stained cytology images.", International Conference on Communications and Signal Processing (ICCSP): 218-220
	In this method, the threshold t is computed as:
	t = mean * (1 + p * exp(-q * mean) + k * ((stdev / r) - 1))
	where mean and stdev are the local mean and standard deviation respectively. Phansalkar recommends k = 0.25, r = 0.5, p = 2 and q = 10. In this plugin, k and r are the parameters 1 and 2 respectively, but the values of p and q are fixed.
	Parameter 1: is the k value. The default value is 0.25. Any other number than 0 will change its value.
	Parameter 2: is the r value. The default value is 0.5. This value is different from Sauvola's because it uses the normalised intensity of the image. Any other number than 0 will change its value.
	Implemented from Phansalkar's paper description, although this version uses a circular rather than rectangular local window.
	
	*/
	run("Convert to Mask");
	run("Make Binary");
	run("Set Measurements...", "area centroid redirect=None decimal=3");
	
	/*
		Particle counting
		Here we assume that there is two cell populations : round cells, and others
		So we will run the counter ("analyze particles") twice, with two different circularity parameters
		All results are then stored in arrays and will be retrieved later for the final result table
	*/
	
	run("Analyze Particles...", "size=3-80 circularity=0.86-1.5 display exclude include add");
	
	CELL_TYPE_1_COUNT = nResults;
	CELL_TYPE_1_MEAN_AREA = 0;
	for (g=0; g<nResults; g++){
		cell_type_1_area = getResult("Area", g);
		CELL_TYPE_1_MEAN_AREA += cell_type_1_area;
		cell_type_1_X = (getResult("X", g));
		cell_type_1_Y = (getResult("Y", g));

		cell_type_1_area_array_temp = newArray(lengthOf(cell_type_1_area_array)+1);
		cell_type_1_xpos_array_temp = newArray(lengthOf(cell_type_1_xpos_array)+1);
		cell_type_1_ypos_array_temp = newArray(lengthOf(cell_type_1_ypos_array)+1);
		
		for (a=0; a<lengthOf(cell_type_1_ypos_array);a++){
			cell_type_1_area_array_temp[a]=cell_type_1_area_array[a];
			cell_type_1_xpos_array_temp[a]=cell_type_1_xpos_array[a];
			cell_type_1_ypos_array_temp[a]=cell_type_1_ypos_array[a];
		}
		
		cell_type_1_area_array_temp[lengthOf(cell_type_1_area_array)-1]=cell_type_1_area;
		cell_type_1_xpos_array_temp[lengthOf(cell_type_1_xpos_array)-1]=cell_type_1_X;
		cell_type_1_ypos_array_temp[lengthOf(cell_type_1_ypos_array)-1]=cell_type_1_Y;
		
		cell_type_1_area_array = cell_type_1_area_array_temp; 
		cell_type_1_xpos_array = cell_type_1_xpos_array_temp;
		cell_type_1_ypos_array = cell_type_1_ypos_array_temp;
		
	}
	CELL_TYPE_1_MEAN_AREA = CELL_TYPE_1_MEAN_AREA/CELL_TYPE_1_COUNT;
	run("Clear Results");
	
	cell_type_1_area_array = Array.slice(cell_type_1_area_array,1);
	cell_type_1_xpos_array = Array.slice(cell_type_1_xpos_array,1);
	cell_type_1_ypos_array = Array.slice(cell_type_1_ypos_array,1);
	
	
	newImage("mask_final", "RGB white", image_width, image_height, 1);
	selectWindow("mask_final");
	roiManager("Show All without labels");
	roiManager("Show None");
	
	number_of_rois = (roiManager("count")) - 1;
	// Orange contour
	setForegroundColor(240, 60, 0);
	
	for (i=0; i<=number_of_rois; i++) {
		roiManager("Select", i);
		roiManager("Draw");
	}
	
	selectWindow("image_copy");
	for (i=0; i<=number_of_rois; i++) {
		roiManager("Select", i);
		roiManager("Draw");
	}
	
	
	roiManager("Delete");
	
	selectWindow("mask");
	run("Make Binary");
	cell_type_2_area_array = newArray("cell type 2 area");
	cell_type_2_xpos_array = newArray("cell type 2 centroid X");
	cell_type_2_ypos_array = newArray("cell type 2 centroid Y");
	
	run("Analyze Particles...", "size=3-80 circularity=0.00-0.85 display exclude include add");
	CELL_TYPE_2_COUNT = nResults;
	CELL_TYPE_2_MEAN_AREA = 0;
	for (h=0; h<nResults; h++){
		cell_type_2_area = getResult("Area", h);
		CELL_TYPE_2_MEAN_AREA += cell_type_2_area;
		cell_type_2_X = (getResult("X", h));
		cell_type_2_Y = (getResult("Y", h));
		
		cell_type_2_area_array_temp = newArray(lengthOf(cell_type_2_area_array)+1);
		cell_type_2_xpos_array_temp = newArray(lengthOf(cell_type_2_xpos_array)+1);
		cell_type_2_ypos_array_temp = newArray(lengthOf(cell_type_2_ypos_array)+1);
		
		for (b=0; b<lengthOf(cell_type_2_ypos_array);b++){
			cell_type_2_area_array_temp[b]=cell_type_2_area_array[b];
			cell_type_2_xpos_array_temp[b]=cell_type_2_xpos_array[b];
			cell_type_2_ypos_array_temp[b]=cell_type_2_ypos_array[b];
		}
		
		cell_type_2_area_array_temp[lengthOf(cell_type_2_area_array)-1]=cell_type_2_area;
		cell_type_2_xpos_array_temp[lengthOf(cell_type_2_xpos_array)-1]=cell_type_2_X;
		cell_type_2_ypos_array_temp[lengthOf(cell_type_2_ypos_array)-1]=cell_type_2_Y;
		
		cell_type_2_area_array = cell_type_2_area_array_temp; 
		cell_type_2_xpos_array = cell_type_2_xpos_array_temp;
		cell_type_2_ypos_array = cell_type_2_ypos_array_temp;
	}
	CELL_TYPE_2_MEAN_AREA = CELL_TYPE_2_MEAN_AREA/CELL_TYPE_2_COUNT;
	run("Clear Results");
	
	cell_type_2_area_array = Array.slice(cell_type_2_area_array,1);
	cell_type_2_xpos_array = Array.slice(cell_type_2_xpos_array,1);
	cell_type_2_ypos_array = Array.slice(cell_type_2_ypos_array,1);
	
	selectWindow("mask_final");
	roiManager("Show All without labels");
	roiManager("Show None");
	number_of_rois = (roiManager("count")) - 1 ;
	// Green contour
	setForegroundColor(140, 120, 0);
	
	for (i=0; i<=number_of_rois; i++) {
		roiManager("Select", i);
		roiManager("Draw");
	}
	
	selectWindow("image_copy");
	for (i=0; i<=number_of_rois; i++) {
		roiManager("Select", i);
		roiManager("Draw");
	}
	
	roiManager("Delete");
	selectWindow("mask_final");
	roiManager("Show All without labels");
	roiManager("Show None");
	run("Convert to Mask");
	
	
	for (j=0;j<(lengthOf(cell_type_1_ypos_array)-1);j++){
		setResult("Area (cell type 1 [circular])", j, cell_type_1_area_array[j]);
		//setResult("Centroid X (cell type 1)", j, cell_type_1_xpos_array[j]);
		//setResult("Centroid Y (cell type 1)", j, cell_type_1_ypos_array[j]);
	
		for (jj=0;jj<=window_f;jj++){
			if (cell_type_1_xpos_array[j] < (jj*window_w)) {
				val_x_1 = jj;
				break;
			}
		}

		for (jjj=0;jjj<=window_f;jjj++){
			if (cell_type_1_ypos_array[j] < (jjj*window_h)) {
				val_y_1 = jjj;
				break;
			}
		}

		list_pos_1 = ((val_y_1 - 1) * window_f) + val_x_1 ;
		setResult("Corresponding ROI Occupation [cell type 1]", j, occupation_class_array[list_pos_1 -1]);
		setResult("Position [ROI number] [cell type 1]", j, list_pos_1);
	}
	updateResults();
	
	for (k=0;k<(lengthOf(cell_type_2_ypos_array)-1);k++){
		setResult("Area (cell type 2 [less circular])", k, cell_type_2_area_array[k]);
		//setResult("Centroid X (cell type 2)", k, cell_type_2_xpos_array[k]);
		//setResult("Centroid Y (cell type 2)", k, cell_type_2_ypos_array[k]);
	
		for (kk=0;kk<=window_f;kk++){
			if (cell_type_2_xpos_array[k] < (kk*window_w)) {
				val_x_2 = kk;
				break;
			}
		}

		for (kkk=0;kkk<=window_f;kkk++){
			if (cell_type_2_ypos_array[k] < (kkk*window_h)) {
				val_y_2 = kkk;
				break;
			}
		}

		list_pos_2 = ((val_y_2 -1) * window_f) + val_x_2;
		setResult("Corresponding ROI Occupation [cell type 2]", k, occupation_class_array[list_pos_2 -1]);
		setResult("Position [ROI number] [cell type 2]", k, list_pos_2);
	}
	updateResults();
	
	for (m=0; m<nResults;m++) {
		setResult("#", m, "#");
	}
	for (k=0;k<lengthOf(window_occupation_array)-1;k++){
		setResult("[ROI number]", k, k+1);
		setResult("Occupation ratio (%)", k, window_occupation_array[k]);
		setResult("Occupation index", k, occupation_class_array[k]);
	}
	setResult("Cell type 1 count", 0, CELL_TYPE_1_COUNT);
	setResult("Cell type 1 mean area", 0, CELL_TYPE_1_MEAN_AREA);
	setResult("Cell type 2 count", 0, CELL_TYPE_2_COUNT);
	setResult("Cell type 2 mean area", 0, CELL_TYPE_2_MEAN_AREA);
	updateResults();
	
	selectWindow("Results");
	imageCalculator("Add create 32-bit", "ROI_MAP","image_copy");
	selectWindow("ROI_MAP");
	run("Close");
	selectWindow("ROI Manager");
	run("Close");
	selectWindow("mask");
	run("Close");
	selectWindow("image_red");
	run("Close");
	selectWindow("image_copy");
	rename("Segmentation Mask Fit Quality Review");
	selectWindow("Result of ROI_MAP");
	rename("ROI_MAP");
	
	if (save_choice == true) {
		dir = getDirectory("Choose where to save."); 
		saveAs("Results",  dir + image + ".xls");
		selectWindow("mask_final");
		saveAs("png",  dir + image + "_segmentation_mask_" + ".png");	
		selectWindow("Segmentation Mask Fit Quality Review");
		saveAs("png",  dir + image + "_fit_quality_" + ".png");
		selectWindow("ROI_MAP");
		saveAs("png",  dir + image + "_ROI_MAP_" + ".png");
	}
	
	if (plot_val == true) {
		val_number_cell_type_1_array = newArray("valnumber");
		for (a=0; a<=CELL_TYPE_1_COUNT; a++){
			val_number_cell_type_1_array_temp = newArray(lengthOf(val_number_cell_type_1_array)+1);
			for (b=0; b<(lengthOf(val_number_cell_type_1_array)-1); b++){
			val_number_cell_type_1_array_temp[b] = val_number_cell_type_1_array[b];
			}
			val_number_cell_type_1_array_temp[lengthOf(val_number_cell_type_1_array)-1]=a;
			val_number_cell_type_1_array = val_number_cell_type_1_array_temp;
		}
		//val_number_cell_type_1_array = Array.slice(val_number_cell_type_1_array,1);
		
		Array.getStatistics(val_number_cell_type_1_array, ca1_nb_val_min, ca1_nb_val_max, ca1_nb_val_mean, ca1_nb_val_std);
		Array.getStatistics(cell_type_1_area_array, ca1_val_min, ca1_val_max, ca1_val_mean, ca1_val_std);
			
		cell_type_1_plot_name = "Cell Area Distribution Plot, [Type 1 Cells]";
		Plot.create(cell_type_1_plot_name, "Cells", "Size", val_number_cell_type_1_array, cell_type_1_area_array);
		Plot.setLimits(0,ca1_nb_val_max,0,ca1_val_max);
		Plot.setColor("red");
		Plot.show();
		
		val_number_cell_type_2_array = newArray("valnumber");
		for (c=0; c<=CELL_TYPE_2_COUNT; c++){
			val_number_cell_type_2_array_temp = newArray(lengthOf(val_number_cell_type_2_array)+1);
			for (d=0; d<(lengthOf(val_number_cell_type_2_array)-1); d++){
			val_number_cell_type_2_array_temp[d] = val_number_cell_type_2_array[d];
			}
			val_number_cell_type_2_array_temp[lengthOf(val_number_cell_type_2_array)-1]=c;
			val_number_cell_type_2_array = val_number_cell_type_2_array_temp;
		}
		//val_number_cell_type_2_array = Array.slice(val_number_cell_type_2_array,1);
		
		Array.getStatistics(val_number_cell_type_2_array, ca2_nb_val_min, ca2_nb_val_max, ca2_nb_val_mean, ca2_nb_val_std);
		Array.getStatistics(cell_type_2_area_array, ca2_val_min, ca2_val_max, ca2_val_mean, ca2_val_std);
				
		cell_type_2_plot_name = "Cell Area Distribution Plot, [Type 2 Cells]";
		Plot.create(cell_type_2_plot_name, "Cells", "Size", val_number_cell_type_2_array, cell_type_2_area_array);
		Plot.setLimits(0,ca2_nb_val_max,0,ca2_val_max);
		Plot.setColor("blue");
		Plot.show();	
	}
}