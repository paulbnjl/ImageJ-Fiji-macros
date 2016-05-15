
/*
####################################################################
####################################################################
*/


/*
Macro : assisted line segmentation and distance calculation for mineral apposition rate estimation
Version : 1-0 - ctr (centroid-to-centroid measurements)
Author : Paul Bonijol
License : GNU/GPL v3
May 2016
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

requires("1.44n");

macro "semi-automatic IHC line segmentation and distance calculation" {

/*
Original image & informations retrieval
*/
image = getTitle();
selectWindow(image);
run("RGB Color");
image_height = getHeight();
image_width = getWidth();
image_area = image_height * image_width;
 
/*
Ask the user to give the number of lines and colors to quantify
*/

Dialog.create("Fluorescent line quantification");
Dialog.addNumber("Number of lines : ", 4);
Dialog.addNumber("Number of colors : ", 2);

Dialog.show();

line_number = Dialog.getNumber();
colour_number = Dialog.getNumber();


/*
Exception to take into account : if the user set the number of line to one
Set back this value to 2 and print a error message
*/

	if (line_number  < 2) {
		print("ERROR. Impossible to work with less than two lines !");
		line_number = 2;
	}

/*
Color thresholding
Duplicate the image and prompt the ImageJ tool 
for each color entered by the user
*/

waitForUser( "Pause","Colour thresholding : threshold in B&W for each color to quantify."); 

	for (i=1; i<=colour_number; i++){
		selectWindow(image);
		run("Duplicate...", "title=img");
		selectWindow("img");
		rename("image_couleur" + i);
		call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W");

		/* 
		Workaround to have B&W set by default
		Note that the colour thresholding tool seems bugged as hell
		It may be a good idea to do automatic threshold and get rid of it
		*/

		run( "Color Threshold..." ); 
		waitForUser( "Threshold and then press OK." );
	}

/*
Image postprocess :
Grayscale, binarisation, then dilatation/closing/filling
This allows to obtain good results with the test image
*/

		selectWindow("Threshold Color");
		run("Close");
		selectWindow("image_couleur" + 1);
		rename("image_postproc");
		for (j=2;j<=colour_number;j++){
			selectWindow("image_couleur" + j);
			rename("img_add");
			imageCalculator("Add create 32-bit", "image_postproc", "img_add");
			selectWindow("img_add");
			run("Close");
			selectWindow("image_postproc");
			run("Close");
			selectWindow("Result of image_postproc");
			run("8-bit");			
			run("Make Binary");
			run("Dilate");
			run("Close-");
			run("Fill Holes");
			rename("image_postproc"); 
		}

	selectWindow("image_postproc");
	
	/* 
	Set the paintbrush color to black (foreground color)
	*/

	setForegroundColor(0, 0, 0);
	setBackgroundColor(255,255,255);
	setTool(17);
	waitForUser("Pause","Correct, if needed, the image using the paintbrush, and press OK."); 

	while ((selectionType() !=-1)){
		setTool(17);
		}

/* 
Line selection with the wand tool
*/
	
	for (i=1; i<=line_number; i++){
			setColor(255,255,255);
			setTool("wand");
			selectWindow("image_postproc");
			waitForUser( "Pause","Selec line with the wand tool and press OK."); 
			
			while ((selectionType() !=4)){
				print("Wrong tool");
				setColor(255,255,255);
				setTool("wand");
				}
			roiManager("Add");
	}
	
/*
Image is duplicated to draw ROIs
This will be used to draw ROIs and then
perform measurments (it is not possible to directly
measure on the overlay)
*/

selectWindow(image);
run("Duplicate...", "title=img_draw_ROI");
selectWindow("image_postproc");
run("Close");
for (i=0; i<(roiManager("count")); i++) {
	selectWindow("img_draw_ROI");
	roiManager("Select", i);
	run("Measure");
}

selectWindow("img_draw_ROI");
run("Close");

/*
Distance calculations
Here we retrieve on the Results window 
centroids (x,y) coordinates
and then we can calculate and draw the diagonal
we also display the labels, all of this on the overlay
*/

selectWindow("Results");
setFont("Monospaced", 16, "antialiased");
maxcount = line_number - 1;

	dist_array = newArray("Distance array");
	distlabel_array = newArray("Distance (label) array");
	
	for (i=maxcount; i>0; i--) {
		for (j=0;j<=i-1; j++){
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
						
			print(distlabel + dist);
			selectWindow(image);
			roiManager("Select", i);
			run("Add Selection...");	
			Overlay.drawLine(pointsXA, pointsYA, pointsXB, pointsYB);
			Overlay.add;
			textline = "Distance : " + dist;
			Overlay.drawString(textline, (pointsXA +(dX/2) + 10), (pointsYB - (dY/2) + 10));
			Overlay.drawString(i+1, (pointsXA+2), (pointsYA+2));
			Overlay.add;
		}		
	}


/*
ImageJ does not give the coordinate of the Feret fit max values
Thus we have to draw a line to obtain these coordinates, as a first
approximation
*/

	for (i=0; i<=maxcount; i++) {
			x = getResult("FeretX", i);
			y = getResult("FeretY", i);
			run("Line Width...", "line=1");
			 diameter = 0.0;
			 roiManager("Select", i);
			 getSelectionCoordinates(xCoordinates, yCoordinates);
			 n = xCoordinates.length;
			 for (j=0; j<n; j++) {
				for (k=j; k<n; k++) {
					dX = xCoordinates[j] - xCoordinates[k];
					dY = yCoordinates[j] - yCoordinates[k];
					d = sqrt(dX*dX + dY*dY);
					if (d>diameter) {
						diameter = d;
						j1 = j;
						j2 = k;
					}	
				}
			}
			setColor(245,230,210);
			Overlay.drawLine(xCoordinates[j1] , yCoordinates[j1] , xCoordinates[j2] , yCoordinates[j2]);
			run("Measure");
			
			ddX = xCoordinates[j2] - xCoordinates[j1];
			ddY = yCoordinates[j2] - yCoordinates[j1];
			textline = "Diameter : " + "line " + (i+1) + " : " + diameter;
			Overlay.drawString(textline, (xCoordinates[j1] +(ddX/2) + 10), (yCoordinates[j2] - (ddY/2) + 10));
			Overlay.add;
	}

/*
Ugly workaround to select the first line
That isn't selected by the loop for some reason
*/

roiManager("Select", 0);
run("Add Selection..."); 
pointsXA = getResult("X", 0);
pointsYA = getResult("Y", 0);
Overlay.drawString(1, (pointsXA+2), (pointsYA+2));
Overlay.add;

Overlay.show;
selectWindow(image);
roiManager("Select", maxcount);
run("Add Selection...");


print("*************************************");
print("************ Results ************");
print("*************************************");

print("Number of quantified colours : " + colour_number); 
print("Number of quantified lines : " +line_number);

	for (i=0; i<=maxcount; i++) {
		line_thickness = getResult("Minor", i);
		print("Line thickness" + (i+1) + " : " + line_thickness);
        line_diameter = getResult("Feret", i);
		print("Line diameter " + (i+1) + " : " + line_diameter);
		line_area = getResult("Area", i);
		print("Line area " + (i+1) + " : " + line_area);
		line_perimeter = getResult("Perimeter", i);
		print("Line perimeter " + (i+1) + " : " + line_area);
		
		relative_surface_percentage = ((line_area * 100) / image_area);
		print("area ratio of line " + (i+1) + "on ROI area : " + relative_surface_percentage + " % ");
		relative_surface_array = newArray(relative_surface_percentage);
		relative_surface_array_temp = newArray(lengthOf(relative_surface_array)+1);
		for (j=0; j<lengthOf(relative_surface_array);j++){
			relative_surface_array_temp[j]=relative_surface_array[j];
			}
			relative_surface_array_temp[lengthOf(relative_surface_array_temp)-1]=relative_surface_percentage;
			relative_surface_array = relative_surface_array_temp;
		
		
		
		line_orientation = getResult("FeretAngle", i);
		print("Line " + (i+1) + " angle with the normal plane : " + line_orientation);
	}	
	for (k=1; k<=lengthOf(dist_array)-1; k++) {
		print(distlabel_array[k] + dist_array[k]);
	}

/*
Display scalebar
*/

run("Scale Bar...", "width=106 height=5 font=18 color=White background=None location=[Lower Right] bold");

/*
Close the ROI Manager
*/

selectWindow("ROI Manager");
run("Close");

/*
Unfinished : save results function
*/

/*

Dialog.create("Results (1)");
choicearray = newArray("Yes", "No");
Dialog.addChoice("Save results ?", choicearray);
Dialog.show();
userchoice = Dialog.getChoice();


if (userchoice == "Oui") {
	saveAs("Results", "C:\\Users\\pb7269\\Desktop\\macros_imageJ\\Results3.xls"); }
else {
	exit();
	}
*/

}
