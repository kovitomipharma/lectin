//select folder
f = File.openDialog("Choose the picture of Isolectin-B4 staining");
open(f);
id00=getImageID();

//isolectin folder
ilf = File.getParent(f);

//main folder
mf=File.getParent(ilf);

//WGA folder
wgf=mf+"\\WGA\\"
ilf=ilf+"\\";

selectImage(id00);
run("Close");

//isolectin file list
ilfL=getFileList(ilf);

//WGA file list
wgfL=getFileList(wgf);

//arrays for results
WGA_area=newArray(ilfL.length);
cap_count=newArray(ilfL.length);
cap_dens=newArray(ilfL.length);
name=newArray(ilfL.length);


for (i = 0; i < ilfL.length; i++) {
	//isolectin image analysis
	open(ilf+ilfL[i]);
	id0i=getImageID();
	title1=ilfL[i];
	t1=split(title1,".");
	th= t1[0].length;
	name[i]=substring(t1[0], 0, th-5);
	
	
	run("Set Scale...", "distance=310 known=100 unit=um global");	
	run("Subtract Background...", "rolling=15");
	run("Sharpen");
	run("Find Edges");
	run("8-bit");
	setMinAndMax(0, 100);
	//with thresholding parameters you can refine the analysis to your images based on exposure
	setThreshold(30, 255, "raw");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Despeckle");
	run("Remove Outliers...", "radius=3 threshold=254 which=Dark");
	run("Despeckle");
	run("Remove Outliers...", "radius=10 threshold=0 which=Bright");
	run("Fill Holes");
	run("Set Measurements...", "area bounding shape display add redirect=["+title1+"] decimal=3");
	//with size (in um^2) and circularity (between 0.0 and 1.0 whereas 1.0 denotes a perfect circle)
	//parameters you can refine the analysis to your sample, circularity is more important here
	//here we exclude longitudinal cutted capillaries and bigger vessels
	run("Analyze Particles...", "size=10-100 circularity=0.20-1.00 show=[Overlay Masks] display clear summarize");
	
	cap_count[i]=nResults;

	//WGA image analysis
	open(wgf+wgfL[i]);
	id0w=getImageID();
	title2=wgfL[i];

	//set scaling properly for area measurement
	run("Set Scale...", "distance=310 known=100 unit=um global");
	run("Enhance Contrast...", "saturated=0.05");
	run("Subtract Background...", "rolling=15");
	run("Sharpen");
	run("8-bit");
	setMinAndMax(0, 100);
	//with thresholding parameters you can refine the analysis to your images based on exposure
	setThreshold(10, 255, "raw");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Despeckle");
	run("Despeckle");
	run("Remove Outliers...", "radius=10 threshold=0 which=Bright");
	run("Invert LUT");
	run("Fill Holes");
	run("Set Measurements...", "area bounding shape display add redirect=[title2] decimal=3");
	//with size (in um^2) and circularity (between 0.0 and 1.0 whereas 1.0 denotes a perfect circle)
	//parameters you can refine the analysis to your sample, size is more important here
	//here we exclude the fibrotic areas and non-tissue background from analysis
	run("Analyze Particles...", "size=50-1000 circularity=0.00-1.00 show=[Overlay Masks] display clear summarize");
						
	selectWindow("Summary");
	IJ.renameResults("Summary","Results");
	WGA_area[i] = getResult("Average Size", 1);
	
	//Calculate capillary density
	cap_dens[i]=cap_count[i]/WGA_area[i];
	
	
	
	selectImage(id0i);
	run("Close");
	selectImage(id0w);
	run("Close");
	
}

run("Close All");

Array.show(name, WGA_area,cap_count,cap_dens);

//Save results to csv file
selectWindow("Arrays");
fname = mf+"_CapillaryDensity.csv";
saveAs("Text", fname);
