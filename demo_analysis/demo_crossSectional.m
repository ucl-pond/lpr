function metrics                        = demo_crossSectional(runMode, logFilename) 

inDir                                   = '../demo_data';                                         %the directory with where all data lives
outMetricsFilename                    	= ''; % fullfile(inDir, 'outDir', 'metrics_ltcpca.mat');  %the location of the output metrics filename - currently not specified

addpath '../utils';
addpath '../predictionLib';
addpath '../PRoNTo_v.1.1_r740/machines'; 

%runMode is 'std' (standard) or 'debug', which won't tune explained variance
if nargin == 0
    runMode                             = 'std';
end

%logger - not used much here, but useful
if nargin == 2
    logger                              = log4m.getLogger(logFilename);
    logger.setCommandWindowLevel(logger.ALL);
    logger.setLogLevel(logger.ALL);
end

in.DEBUG                                = conditional(strcmp(runMode, 'debug'), true, false); %if 'debug' argument, set debug mode

in.metricsFilename                     	= outMetricsFilename;
in.analysisName                         = 'OASIS Cross-Sectional';

in.algo.input.minClassificationSetSamples   = 3;                                    %minimum number of samples per subject (longitudinally)
in.algo.input.P                             = 1;                                    %the polynomial model order in LTC-PCA
in.algo.input.samplesChosen                 = 'all';                                %how many samples to use from each subject - 'all'/'lastTwo'/'firstLast' 

in.algo.input.ltcPCA                    = false;                                    %if true create LTC-PCA projection and project cross-sectional data onto the subspace
%in.algo.input.explainedVar             	= conditional(~in.DEBUG, 0.05:0.05:0.95, 0.9);     %if debug fix explained variance (commented here as we don't use LTC-PCA)


%***************************************************
%the pattern recognition algorithm's parameters
%currently an SVM is used here, specifically the LIBSVM implementation with wrapper from PRoNTo
%
%can also be used with the Gaussian Process classifier from the GPML toolbox, wrapped with PRoNTo here

% algo choice

%*** SVM: LibSVM version
in.algo.name                             = 'libsvm';
in.algo.isProbabilistic                  = false;
in.algo.fnHandle                         = @prt_machine_svm_bin;
in.algo.fnHandle_weights_cv              = @weights_svm_cv;  
in.algo.fnHandle_weights_full            = @weights_svm_full;  
in.algo.formKernel                       = true;
in.algo.args                             = '-s 0 -t 4 -c 1';
in.algo.evalStyle                        = 'bacc';


%***** GPC
% in.algo.name                             = 'gpc';
% in.algo.isProbabilistic                  = true;
% in.algo.fnHandle                         = @prt_machine_gpml; 
% in.algo.fnHandle_weights_cv              = [];  
% in.algo.fnHandle_weights_full            = [];  
% in.algo.formKernel                       = true;
% in.algo.args                             = '-l erf -h';       
% in.algo.evalStyle                        = 'bacc';          %'deviance';        

%**************************************************************%
  
%************* setup: analysis parameters

in.algo.cv.fnHandle                      = @cvPrediction;                           %function handle for cross-validation function to use - this is the basic version that works for everything
in.algo.cv.parallelize                   = false;                                   %we don't need parallelization (used for nested CV) in this case
in.algo.cv.numWorkers                    = 12;                                      %how many parallel workers to use
in.algo.cv.outerParams                   = {'Leaveout'};                            %cross-validation style for outer CV folds, used in cvpartition function
in.algo.cv.innerParams                 	 = {'Leaveout'};                            %cross-validation style for inner CV folds, used in cvpartition function
in.algo.cv.nestedField                   = '';                                      %which field we are tuning with inner (nested) CV, set as '' when no inner CV   

in.algo.input.pred_type                  = 'classification';
in.algo.input.formKernel                 = true;
in.algo.input.intraSampleNormStyle       = 'none';        
in.algo.input.interSampleNormStyle       = 'none';        
in.algo.input.fnHandle                   = @formAlgoInputStruct;                    %function handle for forming input data to algorithm - the basic version without LTC-PCA projection
in.algo.input.lmPCA.setOperation         = 'intersect';                             %intersect longitudinal subject set with classification subject set
                                                                                    %can have 'setdiff' for information transfer style, not currently supported

in.algo.input.constants.TRAINING_AND_TEST 	= 0;
in.algo.input.constants.TRAINING_ONLY      	= 1;
in.algo.input.pruningStyle                 	= in.algo.input.constants.TRAINING_ONLY;

%************* setup: input

in.maskFilename                         = fullfile(inDir, 'mask.nii');              %mask to apply to all images
in.maskValidIndeces                     = [];                                   

in.crossSectionalMapping             	= fullfile(inDir, 'allFields_lastTP.txt');  %all image filepaths and corresponding informationg: mr id, subject id, time of scan (from baseline here), class label at time of scan
in.longitudinalMapping               	= fullfile(inDir, 'allFields_allTPs.txt');  %same as above for longitudinal data

in.delays                               = [];                                       %can restrict times to certain range
in.intersectWithLongitudinal            = true;                                     %intersect longitudinal subjects with classification subjects


in.diseaseStates                        = {'0', '0.5', '1', '2'};                   %all possible disease states

%************* setup: classify
in.label                                = 'CDR 1.0/0.5 vs CDR 0';                   %label for this classification problem
in.classLabels                          = {'1.0/0.5',   '0'};                       %which two classes are being discriminated
in.groupings                            = {[3 2],       [1]};                       %form first class by combining group 3 (1.0 CDR) and group 2 (0.5 CDR), discrminated againt group 1 (0 CDR)


%************* setup: function handles
in.fnLoad                               = @loadLongitudinalData_general;            %function handle for longitudinal data loading function
in.fnAnalyze                            = @classify;                                %function handle for classification
in.fnEvaluate                           = @evaluate;                                %function handle for evaluation of classifier performance


%************* run analysis
metrics                                 = runAnalysis(in);                          %run the analysis, passing in the structure ('in') we've setup here
