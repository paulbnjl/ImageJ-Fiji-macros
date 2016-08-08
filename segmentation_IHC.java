/*
Macro : assisted line segmentation and distance calculation for mineral apposition rate estimation
Version : 1-0 - ctr (centroid-to-centroid measurements)
Author : Paul Bonijol
License : GNU/GPL v3
May 2016
*/

requires("1.44n");
macro "semi-automatic line segmentation and distance calculation" {
// Récupére l'image ouverte
image = getTitle();
selectWindow(image);
run("RGB Color");
image_height = getHeight();
image_width = getWidth();
image_area = image_height * image_width; 
// Récupérer de l'utilisateur le nombre de lignes et de couleurs à quantifier
Dialog.create("Quantification fluorescence");
Dialog.addNumber("Nombre de lignes", 4); // pour test, l'image ayant 4 lignes et 2 couleurs à quantifier
Dialog.addNumber("Nombre de couleurs", 2);

Dialog.show();

line_number = Dialog.getNumber();
colour_number = Dialog.getNumber();


// il faut minimum 2 lignes pour évaluer une distance donc...
	if (line_number  < 2) {
		print("Impossible de fonctionner avec une seule ligne, nombre de lignes défini sur 2.");
		line_number = 2;
	}

// Seuillage couleur : affiche l'outil un nombre de fois  correspondant au nombre de couleurs entrées
// NB : duplique l'image à chaque fois
waitForUser( "Pause","Seuillage couleur : segmenter en Noir&Blanc pour chaque couleur."); 

	for (i=1; i<=colour_number; i++){
		selectWindow(image);
		run("Duplicate...", "title=img");
		selectWindow("img");
		rename("image_couleur" + i);
		call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W"); // à noter que cela ne marche pas systématiquement... Le color threshold
		run( "Color Threshold..." ); // d'imageJ semble plein de bugs...
		waitForUser( "Seuiller image et appuyez sur OK." );
	}

// léger postprocess des image
// passage en 8bit, binarisation, puis dilatation/fermeture/remplissage
// Donne les meilleurs résultats sur image test
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
	setForegroundColor(0, 0, 0); // après binarisation, plan avant en noir ; le paintbrush aura la couleur noire par défaut
	setBackgroundColor(255,255,255); // plan arrière en blanc
	setTool(17); // paintbrush
	waitForUser("Pause","Corriger si besoin l'image avec le pinceau et appuyez sur OK"); 

	while ((selectionType() !=-1)){ // code selectiontype() du paintbrush visiblement
		setTool(17);
		}

//Selectionner la ligne avec l'outil de segmentation auto
// NB : possible de lui appliquer une tolérance mais inutile sur du binarisé

	
// cas général, plusieurs couleurs
	for (i=1; i<=line_number; i++){
			setColor(255,255,255); // couleur des lignes et du texte en blanc, ressort mieux
			setTool("wand");
			selectWindow("image_postproc");
			waitForUser( "Pause","Selectionner la ligne avec l'outil de sélection automatique et appuyez sur OK"); 
			
			while ((selectionType() !=4)){
				print("Mauvais outil utilisé");
				setColor(255,255,255); // couleur des lignes et du texte en blanc, ressort mieux
				setTool("wand");
				}
			roiManager("Add");
	}
	
// Image dupliquée pour tracer les ROI ; servira à tracer les ROI puis à faire les mesures
// (pas possible de mesurer sur l'overlay)
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

// Calcul des distances
// On récupère sur la fenêtre results les coordonnées X,Y des centroides
// On calcule la diagonale
// Et on trace + ajoute les labels sur l'overlay
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
		
			distlabel = "Distance entre lignes " + (j+1) + " et " + (i+1) + " : ";
			
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


// ImageJ ne donne pas les coordonnées max du fit Feret ; on trace une ligne
// pour récupérer le max de cette ligne, en première approximation
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
			textline = "Diametre : " + "ligne " + (i+1) + " : " + diameter;
			Overlay.drawString(textline, (xCoordinates[j1] +(ddX/2) + 10), (yCoordinates[j2] - (ddY/2) + 10));
			Overlay.add;
	}

//bidouille pas terrible pour segmenter la première ROI, pas récupérée par la boucle ??? A voir

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

// retour valeurs
print("*************************************");
print("************ Resultats ************");
print("*************************************");
print("Nombre de couleurs quantifiees : " + colour_number); // renvoie le nombre de couleurs entrées
print("Nombre de lignes quantifiees : " +line_number); // renvoie le nombre de lignes entrées

	for (i=0; i<=maxcount; i++) {
		line_thickness = getResult("Minor", i);
		print("Epaisseur de la ligne " + (i+1) + " : " + line_thickness);
        line_diameter = getResult("Feret", i);
		print("Diametre de la ligne " + (i+1) + " : " + line_diameter);
		line_area = getResult("Area", i);
		print("Aire de la ligne " + (i+1) + " : " + line_area);
		line_perimeter = getResult("Perimeter", i);
		print("Perimetre de la ligne " + (i+1) + " : " + line_area);
		
		relative_surface_percentage = ((line_area * 100) / image_area);
		print("Rapport de aire ligne " + (i+1) + "sur aire totale (ROI) : " + relative_surface_percentage + " % ");
		relative_surface_array = newArray(relative_surface_percentage);
		relative_surface_array_temp = newArray(lengthOf(relative_surface_array)+1);
		for (j=0; j<lengthOf(relative_surface_array);j++){
			relative_surface_array_temp[j]=relative_surface_array[j];
			}
			relative_surface_array_temp[lengthOf(relative_surface_array_temp)-1]=relative_surface_percentage;
			relative_surface_array = relative_surface_array_temp;
		
		
		
		line_orientation = getResult("FeretAngle", i);
		print("Angle de la  ligne " + (i+1) + " par rapport a la normale : " + line_orientation);
	}	
	for (k=1; k<=lengthOf(dist_array)-1; k++) {
		print(distlabel_array[k] + dist_array[k]);
	}

// afficher échelle
run("Scale Bar...", "width=106 height=5 font=18 color=White background=None location=[Lower Right] bold");

// fermer le gestionnaire de ROI
selectWindow("ROI Manager");
run("Close");

// demande si sauvegarde du xls ou non
// TODO : demander à entrer le dossier de sauvegarde
Dialog.create("Résultats (1)");
choicearray = newArray("Oui", "Non");
Dialog.addChoice("Sauvegarder les résultats ?", choicearray);
Dialog.show();
userchoice = Dialog.getChoice();

if (userchoice == "Oui") {
	saveAs("Results", "C:\\Users\\pb7269\\Desktop\\macros_imageJ\\Results3.xls"); }
else {
	exit();
	}
}