/**
 * DIRECTIONNALITY FOR IMAGEJ (J-Y TINENEZ)
 * MODIFIED FOR CALOPIX INTEGRATION (REMOVED ALL DISPLAY-RELATED FUNCTIONS AND MODIFIED THE TABLE FUNCTION)
 * DOES NOT DISPLAY GRAPHS AND TABLE, JUST THE RESULTS !
 * WORK WITH IMAGEJ 1.46 (VERSION EMBEDDED IN CALOPIX)
 * - P.B
**/
import ij.IJ;
import ij.ImagePlus;
import ij.WindowManager;
import ij.gui.Line;
import ij.gui.NewImage;
import ij.gui.Roi;
import ij.measure.CurveFitter;
import ij.measure.ResultsTable;
import ij.plugin.Duplicator;
import ij.plugin.PlugIn;
import ij.plugin.filter.Convolver;
import ij.plugin.filter.GaussianBlur;

import ij.process.FloatProcessor;
import ij.process.ImageProcessor;

import java.util.ArrayList;

public class Directionality_ implements PlugIn {	
	public enum AnalysisMethod {
		FOURIER_COMPONENTS,
		LOCAL_GRADIENT_ORIENTATION;
		public String toString() {
			switch (this) {
			case FOURIER_COMPONENTS:
				return "Fourier components";
			case LOCAL_GRADIENT_ORIENTATION:
				return "Local gradient orientation";
			}
			return "Not implemented";
		}
		public String toCommandName() {
			switch (this) {
			case FOURIER_COMPONENTS:
				return "Fourier";
			case LOCAL_GRADIENT_ORIENTATION:
				return "Gradient";
			}
			return "Not implemented";
		}
	}
	private static final float FREQ_THRESHOLD = 5.0f;
	private static final double SIGMA_NUMBER = 2;
	private static final String PLUGIN_NAME = "Directionality analysis";
	private static final String VERSION_STR = "2.0.1";
	private static int setting_nbins = 90;
	private static double setting_bin_start = -90;
	private static AnalysisMethod setting_method = AnalysisMethod.LOCAL_GRADIENT_ORIENTATION;
	private static boolean setting_display_table = true;
	protected ImagePlus imp;
	protected int nbins = 90;
	private double bin_start = -90;
	private AnalysisMethod method = AnalysisMethod.LOCAL_GRADIENT_ORIENTATION;
	private boolean display_table = true;
	private FloatProcessor fip;
	protected FloatProcessor window, r, theta;
	protected int width, height, small_side, long_side, npady, npadx, step, pad_size;
	protected double[] bins;
	protected ArrayList<double[]> histograms;
	private FloatProcessor padded_square_block; 
	private float[] window_pixels;
	protected ArrayList<double[]> params_from_fit;
	protected double[] goodness_of_fit;
	protected String fit_string;
	private int slice_index;
	
	public void run(String arg) {
		imp = WindowManager.getCurrentImage();
		if (null == imp) {
			IJ.error("Directionality", "No images are open.");
			return;
		}
		Roi roi = imp.getRoi();
		if (null != roi)
			imp = new Duplicator().run(imp, 1, imp.getNSlices());
		if (null != arg && arg.length() > 0) {
			String str = parseArgumentString(arg, "nbins=");
			if (null != str) {
				try {
					nbins = Integer.parseInt(str);
				} catch (NumberFormatException nfe) {
					IJ.error("Directionality: bad argument for number of bins: "+str);
					return;
				}
			}
			str = parseArgumentString(arg, "start=");
			if (null != str) {
				try {
					bin_start = Double.parseDouble(str);
				} catch (NumberFormatException nfe) {
					IJ.error("Directionality: bad argument for start point: "+str);
					return;
				}
			}
			str = parseArgumentString(arg, "method=");
			if (null != str) {
				for (AnalysisMethod m : AnalysisMethod.values()) {
					if (m.toCommandName().equalsIgnoreCase(str)) {
						method = m;
					}
				}
			}
		}
		computeHistograms();
		fitHistograms();
		if (display_table) {
			ResultsTable table = displayResultsTable();
			table.show("Results");
		}
	}
	public void computeHistograms() {
		if (null == imp) return;
		params_from_fit = null;
		goodness_of_fit = null;
		bins = prepareBins(nbins);	
		int n_slices = imp.getStackSize();
		histograms = new ArrayList<double[]>(n_slices * imp.getNChannels()); 
		ImageProcessor ip = null;
		double[] dir = null;
		for (int i = 0; i < n_slices; i++) {
			slice_index = i;
			ip = imp.getStack().getProcessor(i+1);
			for (int channel_number = 0; channel_number < ip.getNChannels(); channel_number++) {
				
				fip = ip.toFloat(channel_number, fip);
				dir = local_gradient_orientation(fip);
				
				double sum = dir[0];
				for (int j = 1; j < dir.length; j++) {
					sum += dir[j];
				}
				
				for (int j = 0; j < dir.length; j++) {
					dir[j] = dir[j] / sum;
				}
				
				histograms.add( dir );
			}
		}	
	}
	
	public ResultsTable displayResultsTable() {
		if (null == histograms) 
			return null;
		double wrapped_angle = ((bin_start+90)  % 180 + 180) % 180 - 90;
		int wrap_index = 0;
		for (int i = 0; i < bins.length; i++) {
			if (wrapped_angle <= Math.toDegrees(bins[i])) {
				wrap_index = i;
				break;				
			}
		}
		double[] wrapped_bins = new double[nbins];
		for (int i = 0; i < wrapped_bins.length; i++) {
			wrapped_bins[i] = Math.toDegrees(bins[wrap_index] + (bins[1]-bins[0])*i);
		}
		ResultsTable table = new ResultsTable();
		table.setPrecision(9);
		String[] names = makeNames();
		final ArrayList<double[]> fit_analysis = getFitAnalysis();
		double[] analysis = null;
		double[] dir;
		int index = 0;
		for (int i = wrap_index; i < bins.length; i++) {
			table.incrementCounter();
			table.addValue("Direction", wrapped_bins[index]);
			for (int j = 0; j < names.length; j++) {
				dir = histograms.get(j);
				table.addValue("Amount", dir[i]);
				double val = CurveFitter.f(CurveFitter.GAUSSIAN, params_from_fit.get(j), bins[i]);
				table.addValue("Fit", val);
			}
			index++;
		}
		for (int i = 0; i < wrap_index; i++) {
			table.incrementCounter();
			table.addValue("Direction", wrapped_bins[index]);
			for (int j = 0; j < names.length; j++) {
				dir = histograms.get(j);
				table.addValue("Amount", dir[i]);
				double val = CurveFitter.f(CurveFitter.GAUSSIAN, params_from_fit.get(j), bins[i]);
				table.addValue("Fit", val);
			}
			index++;
		}
		table.incrementCounter();
		for (int i = 0; i < histograms.size(); i++) {
			analysis = fit_analysis.get(i);
			table.addValue("Center", Math.toDegrees(analysis[0]));
			table.addValue("Dispersion", Math.toDegrees(analysis[1]));
			table.addValue("Amount", analysis[2]);
			table.addValue("Goodness", analysis[3]);
			table.incrementCounter();
		}
		return table;		
	}
	
	public ArrayList<double[]> getFitAnalysis() {
		if (null == histograms)
			return null;
		final ArrayList<double[]> fit_analysis = new ArrayList<double[]>(histograms.size());
		double[] gof = getGoodnessOfFit();
		double[] params = null;
		double[] dir = null;
		double[] analysis = null;
		double amount, center, std, xn;
		for (int i = 0; i < histograms.size(); i++) {
			params =  params_from_fit.get(i);
			dir = histograms.get(i);
			analysis = new double[4];
			amount = 0;
			center = params[2];
			std = params[3];
			for (int j = 0; j < dir.length; j++) {
				xn = bins[j];
				if (Math.abs(xn-center) > 90.0 ) {
					if (xn>center) {
						xn = xn - 180.0;							
					} else {
						xn = xn + 180.0;
					}
				}
				if ( (xn<center-SIGMA_NUMBER*std) || (xn>center+SIGMA_NUMBER*std) ) {
					continue;
				}
				amount += dir[j];
			}
			analysis[0] = center;
			analysis[1] = std;
			analysis[2] = amount;
			analysis[3] = gof[i];
			fit_analysis.add(analysis);
		}
		return fit_analysis;
	}
	public void fitHistograms() {
		if (null == histograms)
			return;
		params_from_fit = new ArrayList<double[]>(histograms.size());
		goodness_of_fit = new double[histograms.size()];
		double[] dir;
		double[] init_params = new double[4];
		double[] params = new double[4];
		double[] padded_dir;
		double[] padded_bins;
		double ymax, ymin;
		int imax, shift_index, current_index;
		CurveFitter fitter = null;
		for (int i = 0; i < histograms.size(); i++) {
			dir = histograms.get(i);
			ymax = Double.NEGATIVE_INFINITY;
			ymin = Double.POSITIVE_INFINITY;
			imax = 0;
			for (int j = 0; j < dir.length; j++) {
				if (dir[j] > ymax) {
					ymax = dir[j];
					imax = j;
				}
				if (dir[j]<ymin) {
					ymin = dir[j];
				}
			}			
			padded_dir 	= new double[bins.length];
			padded_bins = new double[bins.length];
			shift_index = bins.length/2 - imax;
			for (int j = 0; j < bins.length; j++) {
				current_index = j - shift_index;
				if (current_index < 0) {
					current_index += bins.length; 
				}
				if (current_index >= bins.length) {
					current_index -= bins.length;
				}
				padded_dir[j] 	= dir[current_index];
				padded_bins[j] 	= bins[j];
			}			
			fitter = new CurveFitter(padded_bins, padded_dir);
			
			init_params[0] = ymin;
			init_params[1] = ymax; 
			init_params[2] = padded_bins[bins.length/2];
			init_params[3] = 2 * ( bins[1] - bins[0]);
			
			fitter.doFit(CurveFitter.GAUSSIAN);
			params = fitter.getParams();
			goodness_of_fit[i] = fitter.getFitGoodness();
			if (shift_index < 0) {
				params[2] += (bins[-shift_index]-bins[0]);
			} else {
				params[2] -= (bins[shift_index]-bins[0]);
			}
			params[3] = Math.abs(params[3]);
			params_from_fit.add(params);
		}
		fit_string = fitter.getFormula();
	}
	
	public void setImagePlus(ImagePlus imp) {
		this.imp = imp;
		histograms = null;
	}
	public ImagePlus getImagePlus() {
		return imp;
	}
	public ArrayList<double[]> getFitParameters() {
		if (null == params_from_fit) {
			fitHistograms();
		}
		return params_from_fit;
	}
	public double[] getGoodnessOfFit() {
		if (null == params_from_fit) {
			fitHistograms();
		}
		return goodness_of_fit;
	}
	public ArrayList<double[]> getHistograms() {
		return histograms;
	}
	public double[] getBins() {
		final double[] degree_bins = new double[nbins];
		for (int i = 0; i < degree_bins.length; i++) {
			degree_bins[i] = bin_start + 180 *  i * (bins[i]+Math.PI/2)/Math.PI ;
		}
		return degree_bins;
	}
	public void setBinNumber(int nbins) {
		this.nbins = nbins;
		prepareBins(nbins);
		histograms = null;
	}
	public int getBinNumber() {
		return nbins;
	}
	public void setBinStart(double bin_start) {
		this.bin_start = bin_start;
		histograms = null;
	}
	public double getBinStart() {
		return bin_start;
	}
	public void setMethod(AnalysisMethod method) {
		this.method = method;
		histograms = null;
	}
	public AnalysisMethod getMethod() {
		return method;
	}

	private final double[] local_gradient_orientation(final FloatProcessor ip) {
		final double[] norm_dir = new double[nbins];
		final FloatProcessor grad_x = (FloatProcessor) ip.duplicate();
		final FloatProcessor grad_y = (FloatProcessor) ip.duplicate();
		final Convolver convolver = new Convolver();
		final float[] kernel_y = new float[] { 
				-2f,  	-1f, 	0f, 	1f, 	2f,
				-3f,  	-2f,  	0f, 	2f, 	3f,
				-4f, 	-3f, 	0f, 	3f, 	4f,
				-3f,  	-2f,  	0f, 	2f, 	3f,
				-2f,  	-1f,  	0f, 	1f, 	2f		} ;
		final float[] kernel_x = new float[] {
				2f, 	3f, 	4f, 	3f, 	2f,
				1f, 	2f, 	3f, 	2f, 	1f,
				0, 		0, 		0, 		0, 		0,
				-1f, 	-2f, 	-3f, 	-2f, 	-1f,
				-2f, 	-3f, 	-4f, 	-3f, 	-2f		};
		convolver.convolveFloat(grad_x, kernel_x, 5, 5);
		convolver.convolveFloat(grad_y, kernel_y, 5, 5);
		final float[] pixels_gx = (float[]) grad_x.getPixels();
		final float[] pixels_gy = (float[]) grad_y.getPixels();
		final float[] pixels_theta = new float[pixels_gx.length];
		final float[] pixels_r = new float[pixels_gx.length];
		double norm, max_norm = 0.0;
		double angle;
		int histo_index;
		float dx, dy;
		for (int i = 0; i < pixels_gx.length; i++) {
			dx = pixels_gx[i];
			dy =  - pixels_gy[i];
			norm = dx*dx+dy*dy;
			if (norm > max_norm) { 
				max_norm = norm;
			}
			angle = Math.atan(dy/dx);
			pixels_theta[i] = (float) (angle * 180.0 / Math.PI);
			pixels_r[i] = (float) norm;
			histo_index = (int) ((nbins/2.0) * (1 + angle / (Math.PI/2)) );
			if (histo_index == nbins) {
				histo_index = 0; 
			}
			norm_dir[histo_index] += norm; 
		}
		return norm_dir;
	}

	private final String[] makeNames() {
		final int n_slices = imp.getStack().getSize();
		String[] names;
		String label;
		if (imp.getType() == ImagePlus.COLOR_RGB) {
			names = new String[3*n_slices];
			for (int i=0; i<n_slices; i++) {
				label = imp.getStack().getShortSliceLabel(i+1);
				if (null == label) {				
					names[0+i*3] = "Slice_"+(i+1)+"R";
					names[1+i*3] = "Slice_"+(i+1)+"G";
					names[2+i*3] = "Slice_"+(i+1)+"B";
				} else {
					names[0+i*3] = label+"_R";
					names[1+i*3] = label+"_G";
					names[2+i*3] = label+"_B";					
				}
			}
		} else {
			if (n_slices <= 1) {
				return new String[] { imp.getShortTitle() };
			}
			names = new String[n_slices];
			for (int i=0; i<n_slices; i++) {
				label = imp.getStack().getShortSliceLabel(i+1);
				if (null == label) {
					names[i] = "Slice_"+(i+1);
				} else {
					names[i] = label;
				}
			}
		}
		return names;		
	}

	protected final static double[] prepareBins(final int n) {
		final double[] bins = new double[n];
		for (int i = 0; i < n; i++) {
			bins[i] = i * Math.PI / n - Math.PI/2;
		}
		return bins;
	}
	protected final static String parseArgumentString(String argument_string, String command_str) {
		if (argument_string.contains(command_str)) {
			int narg = argument_string.indexOf(command_str)+command_str.length();
			int next_arg = argument_string.indexOf(",", narg);
			if (next_arg == -1) {
				next_arg = argument_string.length();
			}
			String str = argument_string.substring(narg, next_arg);
			return str;
		}
		return null;
	}
	protected static final FloatProcessor displayLog(final FloatProcessor ip) {
		final FloatProcessor log10 = new FloatProcessor(ip.getWidth(), ip.getHeight());
		final float[] log10_pixels = (float[]) log10.getPixels();
		final float[] pixels = (float[]) ip.getPixels();
		for (int i = 0; i < pixels.length; i++) {
			log10_pixels[i] = (float) Math.log10(1+pixels[i]); 
		}
		return log10;
	}


	protected static final FloatProcessor makeRMatrix(final int nx, final int ny) {
		final FloatProcessor r = new FloatProcessor(nx, ny);
		final float[] pixels = (float[]) r.getPixels();
		final float xc = nx / 2.0f;
		final float yc = ny / 2.0f;
		int ix, iy;
		for (int i = 0; i < pixels.length; i++) {
			iy = i / nx;
			ix = i % nx;
			pixels[i] = (float) Math.sqrt( (ix-xc)*(ix-xc) + (iy-yc)*(iy-yc));
		}		
		return r;
	}
	protected static final FloatProcessor makeThetaMatrix(final int nx, final int ny) {
		final FloatProcessor theta = new FloatProcessor(nx, ny);
		final float[] pixels = (float[]) theta.getPixels();
		final float xc = nx / 2.0f;
		final float yc = ny / 2.0f;
		int ix, iy;
		for (int i = 0; i < pixels.length; i++) {
			iy = i / nx;
			ix = i % nx;
			pixels[i] = (float) Math.atan2( -(iy-yc), ix-xc);
		}		
		return theta;
	}
	public static void main(String[] args) {
		ImagePlus imp = NewImage.createShortImage("Lines", 400, 400, 1, NewImage.FILL_BLACK);
		ImageProcessor ip = imp.getProcessor();
		ip.setLineWidth(4);
		Line line_30deg 	= new Line(10.0, 412.0, 446.4102, 112.0);
		Line line_30deg2 = new Line(10.0, 312.0, 446.4102, 12.0);
		Line line_m60deg = new Line(10.0, 10, 300.0, 446.4102);
		Line[] rois = new Line[] { line_30deg, line_30deg2, line_m60deg };
		for ( Line roi : rois) {
			ip.draw(roi);
		}		
		GaussianBlur smoother = new GaussianBlur();
		smoother.blurGaussian(ip, 2.0, 2.0, 1e-2);		
		imp.show();
		AnalysisMethod method;
		ArrayList<double[]> fit_results;
		double center;
		Directionality_ da = new Directionality_();
		da.setImagePlus(imp);
		da.setBinNumber(60);
		da.setBinStart(-90);
		method = AnalysisMethod.LOCAL_GRADIENT_ORIENTATION;
		da.setMethod(method);
		da.computeHistograms();
		fit_results = da.getFitParameters();
		center = fit_results.get(0)[2];
		System.out.println("With method: "+method);
		System.out.println(String.format("Found maxima at %.1f, expected it at 30°.\n", center, 30));
		da.displayResultsTable().show("Table");
	}
}
