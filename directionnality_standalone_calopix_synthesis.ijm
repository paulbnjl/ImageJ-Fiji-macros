	center_val = getResult("Dom. Dir. Angle", 0);
	amount_val = getResult("Amount Dom. Dir.", 0);
	std_val = getResult("Dispersion", 0);
	fit_val = getResult("Goodness", 0);
	epth_amount_inv = getResult("Corr. Angle of Normal", 0);
	
	IJ.deleteRows(0, nResults);
	run("Clear Results");
	
	setResult("Dominant Direction Angle", 0, center_val);
	setResult("Corr. Angle of Normal",0, epth_amount_inv);
	setResult("Dom Dir Angle Corrected", 0, (center_val + epth_amount_inv));
	setResult("Amount of angle in the Dominant Direction", 0, amount_val);
	setResult("Dispersion around the Dominant Angle",0, std_val);
	setResult("Goodness of the Gaussian Fit", 0, fit_val);
	
	updateResults();