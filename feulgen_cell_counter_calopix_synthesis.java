
/*
Macro : Cell counter - Feulgen - results synthesis
Version : 0.0.1
Author : Paul Bonijol
License : GNU/GPL v3
July 2016



/*
The mandatory warning message...
*/
	
//showMessage("Warning !", "This macro is highly EXPERIMENTAL, and thus provided WITHOUT ANY WARRANTY. The author has no liability of any sort, and there is no guarantee that the results are accurate.");

requires("1.44");

nb_Cell = nResults;
Mean_Cell_Area = 0;
Mean_Cell_Perim = 0;
Total_Cell_Area = 0;

for (row=0; row < nResults; row++) {
	Total_Cell_Area = Total_Cell_Area + getResult("Area", row);
	Mean_Cell_Perim = Mean_Cell_Perim + getResult("Perim.", row);	
}

Mean_Cell_Area = Total_Cell_Area/nb_Cell;
Mean_Cell_Perim = Mean_Cell_Perim/nb_Cell;

setResult("Number of cells", 0, nb_Cell);
setResult("Mean cell area", 0, Mean_Cell_Area);
setResult("Total cell area", 0, Total_Cell_Area);
setResult("Mean cell perimeter", 0, Mean_Cell_Perim);

updateResults();