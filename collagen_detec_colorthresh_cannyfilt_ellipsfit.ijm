/*
Macro : collagen detection and orientation quantification : color thresholding + canny-derriche contour detection
Version : 1.0
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


requires("1.44n");
macro "collagen detection and orientation quantification : CT+canny" {


/*
Image selection and area calculation
*/

image = getTitle();
selectWindow(image);
run("RGB Color");
image_height = getHeight();
image_width = getWidth();
image_area = image_height * image_width; 

/*
Image copy
*/

selectWindow(image + " (RGB)");
run("Duplicate...", "title=img");
selectWindow("img");
rename("image_modifs");
selectWindow("image_modifs");

/*
Color thresholding
Generated automatically by imageJ
(macro button)
*/

colorthresh_min=newArray(3);
colorthresh_max=newArray(3);
colorthresh_filter=newArray(3);
a=getTitle();
run("HSB Stack");
run("Convert Stack to Images");
selectWindow("Hue");
rename("0");
selectWindow("Saturation");
rename("1");
selectWindow("Brightness");
rename("2");
colorthresh_min[0]=240;
colorthresh_max[0]=255;
colorthresh_filter[0]="pass";
colorthresh_min[1]=40;
colorthresh_max[1]=200;
colorthresh_filter[1]="pass";
colorthresh_min[2]=0;
colorthresh_max[2]=200;
colorthresh_filter[2]="pass";

for (i=0;i<3;i++){
  selectWindow(""+i);
  setThreshold(colorthresh_min[i], colorthresh_max[i]);
  run("Convert to Mask");
  if (colorthresh_filter[i]=="stop")  run("Invert");
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

selectWindow("image_modifs");

/*
Binarisation and contour detection (canny filter)
*/

run("Make Binary");
run("Canny Edge Detector", "gaussian=2 low=2.5 high=7.5");


/*
Contour numbering, using a particle size cut-off 
of 1/6 of the ROI width
*/

cutoff = image_width/6;
run("Set Measurements...", "area centroid fit feret's redirect=None decimal=3");
run("Analyze Particles...", "size=cutoff-infinity show=[Count Masks] display exclude summarize add in_situ");
selectWindow("Results");

/*
Fit quality
*/
selectWindow(image);
run("Duplicate...", "title=img");
selectWindow("img");
rename("image_fit");
selectWindow("image_fit");
roiManager("Select", 0);
roiManager("Update");

/*
Fit diameter calculation and drawing
*/

setFont("Monospaced", 16, "antialiased");
max_mes = (roiManager("count")) - 1 ;
angle_array = newArray("0");
	for (i=0; i<=max_mes; i++) {
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
			makeLine(xCoordinates[j1] , yCoordinates[j1] , xCoordinates[j2] , yCoordinates[j2]);
			run("Measure");
			angle = getResult("Angle",i);

			/* 
			We only want orientations in the (x,y) plane,
			that is to say in the [-90;90] interval
			To achieve that, here is the mandatory if/else loop
			*/

			if (angle>90){
				angle = -(angle-90);
			}
			else if (angle<-90){
					angle = -1 * (angle+90);
			}
			angle_array_temp = newArray(lengthOf(angle_array)+1);
			
			for (k=0; k<lengthOf(angle_array);k++){
				angle_array_temp[k]=angle_array[k];
			}
			angle_array_temp[lengthOf(angle_array_temp)-1]=round(angle);
			angle_array = angle_array_temp;
	}
angle_array = Array.slice(angle_array,1);
Array.sort(angle_array);

selectWindow("Results");			
run("Clear Results");
close();

for (i=1;i<lengthOf(angle_array);i++){
	angle = angle_array[i];
	row = i-1;
	setResult("Angle", row, angle);
	updateResults();
}


Array.getStatistics(angle_array,min,max,mean,std);

print("min : " + min);
print("max : " + max);
print("mean : " + mean);
print("std : " + std);

for (i=0;i<lengthOf(angle_array);i++){
	if (angle_array[i] == max) {
		max_val_pos = i;
	}
}

for (i=max_val_pos; i>0; i--){
	if (angle_array[i] <= (0.659 * max)){
		max_minus_std_pos = i;
	}
}

for (i=max_val_pos; i<lengthOf(angle_array); i++){
	if (angle_array[i] >= (0.659 * max)){
		max_plus_std_pos = i;
	}
}

values_in_std_itv = max_plus_std_pos - max_minus_std_pos ;
sum_val_peak = 0;

for (i=max_minus_std_pos; i<=max_plus_std_pos; i++){
	sum_val_peak += angle_array[i];
}
mean_peak_angle = sum_val_peak/values_in_std_itv;

chr = (values_in_std_itv * 100)/(lengthOf(angle_array));
print ("values in the max +/- std range : " + values_in_std_itv + " corresponding to " + round(chr) + "% of the measured angles");
print("Number of quantified angles : " + lengthOf(angle_array));
print("Average angle (total) : " + round(mean));
print("Aveage angle (of values in peak range) : " + round(mean_peak_angle));
or=lengthOf(angle_array);
run("Distribution...", "parameter=Angle or=or and=-min-max");

}


