
/*
################################
################################
*/


/*
 * Macro : assisted photo album creator
 * Version : 1.0
 * Author : Paul Bonijol
 * License : GNU/GPL v3
 * June 2016
*/

/*
 * Just a simple macro to help organise 
 * a batch of pictures in a 2*4 grid...
 */

/*
################################
################################
*/


//Ask for a recent version of imageJ/Fiji 
requires("1.40");

macro " Assisted photo album creator" {
	
	// First, close everything to avoid some bugs !
	run("Close All");
	
	// Ask for the page orientiation : portrait or landscape
	Dialog.create("Assisted photo album creator");
	orientation_type_array = newArray("Portrait", "Landscape");
	Dialog.addChoice("Album orientation : ", orientation_type_array);
	Dialog.show();
	
	orientation = Dialog.getChoice();
	
	/*
	 * Height/width correspond to a A4 format 
	 * at 300 DPI
	 */
	 
	if (orientation == "Portrait"){
		newImage("A4_photo_grid", "RGB white", 2500, 3500, 1);
	}
	
	else if (orientation == "Landscape"){
		newImage("A4_photo_grid", "RGB white", 3500, 2500, 1);
	
	}
	
	/* 
	 * Then, determine the dimensions properly
	 *  Yes, we defined them just above, but with
	 *  ImageJ you are never sure in term of
	 *  behaviour...
	 */
	
	selectWindow("A4_photo_grid");
	album_h = getHeight();
	album_w = getWidth();
	
	/* 
	 * Finally, ask the user the number of pictures
	 * he plan to use, then the number of lines
	 * and columns he wants
	 * If the orientation is landscape, we invert
	 * the max values for lines and columns
	 * Also, we ask for some other things, like
	 * if user want to add a scale bar, annotations, a title...
	 */ 
	
	nb_check = 0;
	while (nb_check == 0) {
			Dialog.create("Album definition :");
			Dialog.addSlider("Number of pictures",1,8, 8);
			
			if (orientation == "Portrait"){
				Dialog.addSlider("Number of lines", 0, 4, 4);
				Dialog.addSlider("Number of columns", 0, 2, 2);
			}
			
			else if (orientation == "Landscape"){
				Dialog.addSlider("Number of lines", 0, 2, 2);
				Dialog.addSlider("Number of columns", 0, 4, 4);
			}
			
			Dialog.addSlider("Space between column : ", 10, 200, 10);
			Dialog.addSlider("Space between lines :", 10, 200, 10);
			Dialog.addCheckbox("Insert scale bar ?", false);
			Dialog.addCheckbox("Add annotations ?", false);
			Dialog.addCheckbox("Insert picture(s) title(s) ?", true);
			Dialog.addCheckbox("Center the last line (odd img number) ?", true);
			//Dialog.addCheckbox("Crop final album [portrait only] ?",  true);
			Dialog.addCheckbox("Show album title ?", true);
			Dialog.addString("Album title : ", "album_title");
			Dialog.show();
			
			// Retrieve the sliders values
			pic_nb = Dialog.getNumber();
			line_nb = Dialog.getNumber();
			col_nb = Dialog.getNumber();
			sp_vt_sz = Dialog.getNumber();
			sp_hz_sz = Dialog.getNumber();
			scale = Dialog.getCheckbox();
			pic_ant = Dialog.getCheckbox();
			show_pic_name = Dialog.getCheckbox();
			center_last_images = Dialog.getCheckbox();
			//crop_album = Dialog.getCheckbox();
			show_title = Dialog.getCheckbox();
			title = Dialog.getString();
			
			// If the number is lower than the number of col * lines, then break the loop
			if (pic_nb <= line_nb*col_nb){
				nb_check =1;
				break;
			}
			// Else, display an annoying pop-up message, and loop
			else {
			showMessage("Too many images for this amount of lines/columns !");
			}	
	}
	
	/*
	 * We want to add some space between images
	 * For this we calculate the number of spacers
	 * Then we define that the spacer size must
	 * be 1/20 of the width/height, for no reason.
	 * And finally after the calculation of the total
	 * space taken by spacer, we can calculate
	 * the max width/height of our images
	 */
	
	title_pos_x = album_w/2;
	title_pos_y = album_h/20;
	
	spacers_hz_nb = 2 + (col_nb - 1);
	spacers_hz_size = sp_hz_sz;
	
	hz_space_taken_by_spacers = spacers_hz_nb * spacers_hz_size;
	hz_space_left = album_w - hz_space_taken_by_spacers;

	spacers_vt_nb = 2 + (line_nb-1);
	spacers_vt_size = sp_vt_sz;
	
	vt_space_taken_by_spacers = spacers_vt_nb * spacers_vt_size;
	vt_space_left = album_h - vt_space_taken_by_spacers;
	
	pic_max_w = (hz_space_left / col_nb);
	pic_max_h = (vt_space_left / line_nb);
	
	// Add the title and borders around it (in fact, a rectangle)
	if(show_title==true){
		setColor(0);
		fontsize = album_h/30;
		title_size = round(lengthOf(title) * (fontsize/2)); 
		setFont("Arial Narrow", fontsize, "bold");
		setJustification("center");
		drawString(title, title_pos_x, title_pos_y);
		setLineWidth(10);
		drawRect((title_pos_x - (title_size/2)), (title_pos_y - fontsize), title_size+5, fontsize+5);
		
		offset_induced_by_the_title = (title_pos_y - fontsize) + (fontsize+5) + sp_vt_sz;
		pic_max_h = ((vt_space_left - offset_induced_by_the_title) / line_nb);
	}
	
	else {
		offset_induced_by_the_title = 0;
	}
	
	
	// Some variables used by the for loop below
	pos_x = 0;
	prev_x_pos = 0;
	pos_y = 0;
	prev_y_pos = 0;
	count = 1;
	current_line = 0;
		
	/* 
	 * The following for loop will do, for each
	 * pictures, open a window to select a picture,
	 * test if it is a correct image, allow the user
	 * to anotate it, then scale it to fit in the album
	 * and finally copy the image to paste it in
	 * a rectangle made in the album
	 */
	
	for (i=1; i <= pic_nb; i++) {
		// Always nice to know where we are...
		// Hence the status and progress bar
		status_message = "Image number : " +  i;
		showStatus(status_message);
		
		progress = (i/pic_nb);
		showProgress(progress);
		
		
		/* 
		 * Test if the file opened is a image or not
		 * in form of a if condition intricated 
		 * in a while loop.
		 * If it is an image, then it returns an height
		 * and an width value and thus we break the
		 * loop ;
		 */
		  
		IsImage = 0;
		while (IsImage == 0) { 
			filepath=File.openDialog("Select a picture"); 
			open(filepath);
			file = getTitle();
			run("RGB Color");
			//selectWindow(file + ' (RGB)');
			//rename(file);
			
			img_w = getWidth();
			img_h = getHeight();
			
			// Picture titles
			if (show_pic_name == true) {
				Dialog.create("Picture title : ");
				Dialog.addString("Picture title :", file);
				Dialog.show();
				
				pic_title = Dialog.getString();
				fontsize = img_h/20;
				rec_size = round(lengthOf(pic_title) * (fontsize/2));
				setColor(255,255,255);
				//drawRect(0,(img_h-fontsize),rec_size,fontsize);
				fillRect(0,(img_h-fontsize),rec_size,fontsize);
				setColor(0,0,0);
				setJustification("left");
				setFont("Arial Narrow", fontsize, "bold");
				drawString(pic_title,0, img_h);
			}
			
			if (img_w == 0 && img_h == 0) {
				isImage = 0;
			}
			
			else {
				isImage = 1;
				break;
			}
		}
		
		/*
		 * Select the image, than show a pop-up
		 * While the latter is open, the user can
		 * anotate the image using the standard Fiji
		 * tools
		 * TODO : can be nice to display a modified
		 * Toolbar during this also...
		 */
		  	
		selectWindow(file);
		
		// Add a scale bar if the user checked the corresponding box
		if (scale == true) {
			run("Set Scale...");
			run("Scale Bar...", "width=106 height=5 font=18 color=Black background=White location=[Lower Right] bold");
		}
		
		// Allow to add annotations using the basic imageJ tools, if the user checked the corresponding box.
		if (pic_ant == true) {
			waitForUser("Annotate image", "Add annotations to the image if needed, then press enter. \n Note : ctrl+D to draw, double-click on the selected tool to access options.");
			run("Select None");
		}
		
		// Image rescaling to fit the album
		selectWindow(file);
		run("Scale...", "x=- y=- width=" + pic_max_w + " height=" + pic_max_h + " interpolation=Bicubic average create title=" + i);
		
				
		// Draw a rectangle around the image, then perform a copy
		selectWindow(i);
		makeRectangle(0,0, pic_max_w, pic_max_h);
		run("Copy");
		
		/* 
		 * Our counter start with 1, for "first column"
		 * If we are under the max column number
		 * then the y position won't change between
		 * pictures, only the x dimension
		 * but if it is not the case, we reset our counter
		 * and jump line
		 */ 
		if (count <= col_nb){
			if (i == pic_nb && center_last_images == true && col_nb != 1){
				if (pic_nb % 2 != 0) {
					if (orientation == "Portrait") {
						pos_x = prev_x_pos + spacers_hz_size + (pic_max_w/2);					
					}
					else {
						pos_x = prev_x_pos + spacers_hz_size;
					}
				}
				else {
					pos_x = prev_x_pos + spacers_hz_size;
				}
			}
			
			else {
				pos_x = prev_x_pos + spacers_hz_size;
			}
			
			prev_x_pos = pos_x + pic_max_w;
			
			if (i == 1) {
				pos_y = spacers_vt_size + prev_y_pos + offset_induced_by_the_title;
			}
				
			else {
				pos_y = spacers_vt_size + prev_y_pos;	
			}
			
			prev_y_pos = pos_y - spacers_vt_size ;
			
			count +=1;
		}
		
		else {			
			prev_y_pos = (spacers_vt_size + pic_max_h + offset_induced_by_the_title ) + (current_line)*(spacers_vt_size + pic_max_h);
			pos_y = spacers_vt_size + prev_y_pos;
			
			if (i == pic_nb && center_last_images == true && col_nb !=1){
				if (pic_nb % 2 != 0) {
					if (orientation == "Portrait") {
						pos_x = spacers_hz_size + (pic_max_w/2);	
					}
					else {
						pos_x = spacers_hz_size;
					}
				}
				else {
					pos_x = spacers_hz_size;
				}
			}
			
			else {
				pos_x = spacers_hz_size;
			}
			
			prev_x_pos = pos_x + pic_max_w;

			current_line += 1;
			count = 2;
			}
			
		// Draw a rectangle at the calculated position	
		selectWindow("A4_photo_grid");
		makeRectangle(pos_x, pos_y, pic_max_w, pic_max_h);
		
		// Paste the resized image in this rectangle
		run("Paste");
		run("Select None");
		
		// Refresh the image
		selectWindow("A4_photo_grid");
		updateDisplay();
		run("Select None");
		
		// Close all images opened during execution of the loop iteration
		selectWindow(i);
		run("Close");
		selectWindow(file);
		run("Close");
	}
	selectWindow("A4_photo_grid");
	// Last annotation step for the whole grid
	if (pic_ant == true) {
		waitForUser("Annotate image", "Add annotations to the image if needed, then press enter. \n Note : ctrl+D to draw, double-click on the selected tool to access options.");
		run("Select None");
	}
	selectWindow("A4_photo_grid");
	
	// BUGGED AND USELESS : crop the final album
	//if (orientation == "Portrait") {
	//	if (crop_album == true) {
	//		height_final = (line_nb*pic_max_h) + (spacers_vt_size * (line_nb+1));
	//		width_final = (col_nb*pic_max_w) + (spacers_hz_size * (col_nb+1));
	//		makeRectangle(0, 0, height_final, width_final);
	//		run("Crop");
	//	}
	//}
	//selectWindow("A4_photo_grid");	
		
	//Select the output image format, then save the image once the album is made
	no_image_format_selected = 0;
	
	while (no_image_format_selected == 0) {
		nb_checked = 0;
		Dialog.create("Photo album format :");
		Dialog.addMessage("Output format :");
		Dialog.addCheckbox("TIFF", false);
		Dialog.addCheckbox("JPEG", false);
		Dialog.addCheckbox("PNG", false);
		Dialog.show();
		
		tiff_s = Dialog.getCheckbox();
		jpeg_s = Dialog.getCheckbox();
		png_s = Dialog.getCheckbox();
		
		if (tiff_s == true) {
			nb_checked += 1;
			format = "tiff"; 	
		}
		
		if (jpeg_s == true) {
			nb_checked += 1;
			format = "jpeg";
		}
		
		if (png_s == true) {
			nb_checked += 1;
			format = "png";
		}
		
		if (nb_checked == 1) {
			no_image_format_selected = 1;
			break;
		}
		
		else if (nb_checked == 0) {
			showMessage("Check at least one format !");
		}
		
		else if (nb_checked >1) {
			showMessage("Check only one format !");
		}
	}
	
	selectWindow("A4_photo_grid");
	
	saveAs(format);
	run("Select None");
}
