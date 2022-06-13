/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

output = input;
run("Set Measurements...", "mean display redirect=None decimal=2");
processFolder(input);
print("Done");

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processCells(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], ".tif"))
			processCell(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	//create output folders
	file_output = output + File.separator ;
	mask_output = file_output + file +  "_masks_and_rois";
	File.makeDirectory(mask_output);
	cell_output = file_output + file + "_segmented_cells";
	File.makeDirectory(cell_output);
	analysis_output = file_output + file +  "_analysis";
	File.makeDirectory(analysis_output);
	setBatchMode(false);
	// Open image
	run("Bio-Formats Importer", "open=["+ input + File.separator + file +"] color_mode=Default view=Hyperstack stack_order=XYCZT");
	
	//find nuclei area
	run("Split Channels");
	run("Duplicate...", "title=nuclei.nd2");
	run("Gaussian Blur...", "sigma=10");
	waitForUser("On the next dialogue choose the options: exclude and segment. Press okay.");
	run("Find Maxima...");
	saveAs("Tiff", mask_output + File.separator + file + "_voroni_mask.tif");
	
	//find cell area
	selectWindow("C2-" + file);
	run("Threshold...");
	waitForUser("Set the threshold to encompass all of the cells.Then press okay.");
	run("Convert to Mask");
	saveAs("Tiff", mask_output + File.separator +  file + "_cell_mask.tif");
	
	//Segment cells 
	imageCalculator("AND create", file + "_voroni_mask.tif",file + "_cell_mask.tif");
	run("Fill Holes");
	saveAs("Tiff", mask_output + File.separator + file + "_segmented_cell_mask.tif");
	
	//Create ROIs
	run("Analyze Particles...", "size=20-Infinity add");
	roiManager("Save", mask_output + File.separator + file + "_cell_rois.zip");
	setBatchMode(true);

	
	//save individual cells
	run("Bio-Formats Importer", "open=["+ input + File.separator + file +"] color_mode=Default view=Hyperstack stack_order=XYCZT");
	for (i = 0; i<RoiManager.size; i++) {
		run("Duplicate...", "duplicate");
		roiManager("select", i);
		run("Crop");
		saveAs("Tiff", cell_output + File.separator + file + "_segmented_cell-"+i+".tif");
		close();	
	}
	close();

	roiManager("Deselect");
	roiManager("Delete");
		
	//measure background
	selectWindow(file + "_cell_mask.tif");
	run("Create Selection");
	roiManager("Add");
	selectWindow("C1-" + file);
	roiManager("Select", 0);
	run("Make Inverse");
	run("Enlarge...", "enlarge=-2");
	roiManager("Add");
	roiManager("Select", 1);
	roiManager("Rename", "background");
	run("Measure");
	roiManager("Save", mask_output + File.separator + file + "_background_roi.zip");
	
	//cleanup	
	run("Close All");
	roiManager("Deselect");
	roiManager("Delete");
	
	processCells(cell_output);
	saveAs("Results", analysis_output + File.separator +  file + "_Results.csv");
	run("Clear Results");
}

function processCell(input, output, file) {
	//Open segmented cell
	open(input + File.separator + file);
	selectWindow(file);
	roiManager("Add");
	roiManager("Select", 0);
	roiManager("Rename", "whole_cell");
	run("Duplicate...", "title=split duplicate");
	//find nucleus of the selected cell
	run("Split Channels");
	selectWindow("C3-split");
	roiManager("Select", 0);
	run("Invert");
	setBackgroundColor(255, 255, 255);
	roiManager("Select", 0);
	run("Clear Outside");
	run("Invert");
	run("Gaussian Blur...", "sigma=2");setAutoThreshold("Default dark");
	//run("Threshold...");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Analyze Particles...", "size=20-Infinity add");
	//go on only if there is a nucleus
	if (RoiManager.size>1){
	roiManager("Select", 1);
	roiManager("Rename", "nucleus");
	
	//substract nucleus from whole cell
	roiManager("Deselect");
	roiManager("XOR");
	roiManager("Add");
	roiManager("Select", 2);
	roiManager("Rename", "cytoplasm");
	//measure all ROIs
	selectWindow("C1-split");
	rename(file);
	for (i = 0; i<RoiManager.size; i++) {
		roiManager("select", i);
		roiManager("measure");
	}
	
	roiManager("Show All");
	roiManager("Draw");
	roiManager("Save", cell_output + File.separator + file + "_sub_cell_rois.zip");
		}

	run("Close All");
	roiManager("Deselect");
	roiManager("Delete");
}
