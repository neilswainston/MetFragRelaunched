#' @import rcdk
#' @import rJava
NULL

.packageName <- "metfRag"

require(rJava, quietly=TRUE)

.onLoad<-function(libname, pkgname) {
	jar.metfrag <- paste(libname, pkgname, "java", "MetFragR-2.3-jar-with-dependencies.jar", sep=.Platform$file.sep)	
	.jinit(classpath=c(jar.metfrag))
}

#' Run MetFrag by specifying all parameters given with the settings object as list
#' 
#' The function uses defined settings like database, fragmentation and scoring
#' parameters to initialise and run the MetFrag process. The FragmenterScore 
#' calculation is based on the match of in silico generated fragments of the
#' candidate molecules to the given tandem mass spectrum. A data.frame of candidates
#' molecules is returned sorted by their final score.
#' 
#' 
#' @param list of settings 
#' @author Christoph Ruttkies (\email{cruttkie@ipb-halle.de})
#' @export
run.metfrag<-function(settingsObject) {

	if(missing(settingsObject)) stop("Error: Settings object is missing!")
	
	if(class(settingsObject) != "list") stop("Error: Settings object must be of type list!")
	if(is.null(names(settingsObject))) stop("Error: Settings object does not contain valid names!")
	if(length(settingsObject) == 0) stop("Error: Settings object does not contain valid values!")
      
	javaSettings=.jnew("de/ipbhalle/metfraglib/settings/MetFragGlobalSettings")
	
	getDatatype<-function(name, value) {
	  vector = FALSE;
	  if(class(value) != "character" & length(value) > 1) {vector = TRUE}
	  if(name == "NeutralPrecursorMass") {return("double")}
	  else if(name == "KeggProxyPort") {return("integer")}
	  else if(name == "MoNAProxyPort") {return("integer")}
	  else if(name == "MetaCycProxyPort") {return("integer")}
	  else if(name == "NeutralPrecursorMass") {return("double")}
	  else if(name == "DatabaseSearchRelativeMassDeviation") {return("double")}
	  else if(name == "FragmentPeakMatchAbsoluteMassDeviation") {return("double")}
	  else if(name == "FragmentPeakMatchRelativeMassDeviation") {return("double")}
	  else if(name == "MaximumTreeDepth") {return("integer")}
	  else if(name == "PrecursorIonMode") {return("integer")}
	  else if(name == "IonizedPrecursorMass") {return("double")}
	  else if(name == "ExperimentalRetentionTimeValue") {return("double")}
	  else if(name == "MinimumAbsolutePeakIntensity") {return("double")}
	  else if(name == "SmartsSubstructureExclusionScoreSmartsList") {return("string[]")}
	  else if(name == "SmartsSubstructureInclusionScoreSmartsList") {return("string[]")}
	  else if(name == "ScoreSmartsInclusionList") {return("string[]")}
	  else if(name == "ScoreSmartsExclusionList") {return("string[]")}
	  else if(name == "FilterSmartsInclusionList") {return("string[]")}
	  else if(name == "FilterSmartsExclusionList") {return("string[]")}
	  else if(name == "FilterSuspectLists") {return("string[]")}
	  else if(name == "ScoreSuspectLists") {return("string[]")}
	  else if(name == "FilterExcludedElements") {return("string[]")}
	  else if(name == "FilterIncludedElements") {return("string[]")}
	  else if(name == "CombinedReferenceScoreValues") {return("string[]")}
	  else if(name == "MetFragPreProcessingCandidateFilter") {return("string[]")}
	  else if(name == "MetFragPostProcessingCandidateFilter") {return("string[]")}
	  else if(name == "MetFragScoreTypes") {return("string[]")}
	  else if(name == "MetFragCandidateWriter") {return("string[]")}
	  else if(vector) {
	    if(class(value) == "numeric" && value == round(value)) {return("integer[]")}
	    else if(class(value) == "numeric" && value != round(value)) {return("double[]")}
	    else if(class(value) == "character") {return("string[]")}
	    else if(class(value) == "logical") {return("boolean[]")}
	    else {return("unknown")}
	  }
	  else if(!vector) {
	    if(class(value) == "numeric" && value == round(value)) {return("integer")}
	    else if(class(value) == "numeric" && value != round(value)) {return("double")}
	    else if(class(value) == "character") {return("string")}
	    else if(class(value) == "logical") {return("boolean")}
	    else {return("unknown")}
	  }

	}

	#write all properties into Java settings object
	sapply(names(settingsObject), function(name) {
	  #check the peak list
	  if(name == "PeakList") {
	    if(is.null(settingsObject[[name]])) {
	      .jcall(javaSettings, "V", 'set', "PeakListString", .jnew("java.lang.String", as.character(paste(settingsObject[[name]][1], settingsObject[[name]][1], sep=" "))))
	    }
	    else {
	      .jcall(javaSettings, "V", 'set', "PeakListString", paste(apply(settingsObject[[name]], 1, function(x) paste(x[1], x[2])), collapse="\n"))
	    }
	    .jcall(javaSettings, "V", 'set', "MetFragPeakListReader", .jnew("java.lang.String", as.character("de.ipbhalle.metfraglib.peaklistreader.FilteredStringTandemMassPeakListReader")))
	  }
	  #check further settings
	  else if(length(settingsObject[[name]]) == 1) {
	    #in case it a single value
	    if(getDatatype(name, settingsObject[[name]]) == "integer") {
	      .jcall(javaSettings, "V", 'set', name, .jnew("java.lang.Integer", as.integer(settingsObject[[name]])))
	    }
	    else if(getDatatype(name, settingsObject[[name]]) == "double") {
	      .jcall(javaSettings, "V", 'set', name, .jnew("java.lang.Double", as.double(settingsObject[[name]])))
	    }
	    else if(getDatatype(name, settingsObject[[name]]) == "string") {
	      .jcall(javaSettings, "V", 'set', name, .jnew("java.lang.String", as.character(settingsObject[[name]])))
	    }
	    else if(getDatatype(name, settingsObject[[name]]) == "logical") {
	      .jcall(javaSettings, "V", 'set', name, .jnew("java.lang.Boolean", as.logical(settingsObject[[name]])))
	    }
	    #vectors
	    else if(getDatatype(name, settingsObject[[name]]) == "string[]") {
	      .jcall(javaSettings, "V", 'set', name, .jnew("[java.lang.String", as.character(settingsObject[[name]])))
	    }
	    else if(getDatatype(name, settingsObject[[name]]) == "double[]") {
	      .jcall(javaSettings, "V", 'set', name, .jnew("[java.lang.Double", as.double(settingsObject[[name]])))
	    }
	    else if(getDatatype(name, settingsObject[[name]]) == "integer[]") {
	      .jcall(javaSettings, "V", 'set', name, .jnew("[java.lang.Integer", as.integer(settingsObject[[name]])))
	    }
	    else if(getDatatype(name, settingsObject[[name]]) == "logical[]") {
	      .jcall(javaSettings, "V", 'set', name, .jnew("[java.lang.Boolean", as.logical(settingsObject[[name]])))
	    }
	    else {
	      print(paste("Unknown type of parameter", name, "(", class(settingsObject[[name]]), ")"))
	    }
	  }
	  if(name == "PeakListString") {
	    .jcall(javaSettings, "V", 'set', "MetFragPeakListReader", .jnew("[java.lang.String", as.character("de.ipbhalle.metfraglib.peaklistreader.FilteredStringTandemMassPeakListReader")))
	  }
	})

	obj=.jnew("de/ipbhalle/metfrag/r/MetfRag")
	candidateList=.jcall(obj, "Lde/ipbhalle/metfraglib/list/CandidateList;", "runMetFrag", javaSettings)
	candidateList=.jcast(candidateList, "de/ipbhalle/metfraglib/list/ScoredCandidateList")
	numberPeaksUsed<-.jcall(candidateList, "I", "getNumberPeaksUsed")
	numberCandidates<-.jcall(candidateList, "I", "getNumberElements")
	propertyNames<-c()
	datatypes<-list()
	
	if(numberCandidates >= 1) {
	  candidate <- .jcall(candidateList, "Lde/ipbhalle/metfraglib/interfaces/ICandidate;", "getElement", as.integer(0))
	  propertyNames <- .jcall(candidate, "[S", "getPropertyNames")
	  sapply(1:length(propertyNames), function(propertyIndex) {
	    datatypes[[propertyNames[propertyIndex]]]<<-.jcall(candidate, "Ljava/lang/Object;", "getProperty", propertyNames[propertyIndex])$getClass()$getName()
	  })
	}

	candidateProperties<-list()
	datatypes[["NoExplPeaks"]] <- "java.lang.Integer"
	candidateProperties[["NoExplPeaks"]] <- vector(mode = "numeric", length = 0)	

	sapply(1:length(propertyNames), function(propertyIndex) {
	  candidateProperties[[propertyNames[propertyIndex]]] <<- vector(mode = "character", length = 0)
	})
	sapply(1:numberCandidates, function(candidateIndex) {
	  candidate <- .jcall(candidateList, "Lde/ipbhalle/metfraglib/interfaces/ICandidate;", "getElement", as.integer(candidateIndex - 1))
	  sapply(1:length(propertyNames), function(propertyIndex) {
	    value <- .jcall(candidate, "Ljava/lang/Object;", "getProperty", propertyNames[propertyIndex])$toString()
	    candidateProperties[[propertyNames[propertyIndex]]] <<- c(candidateProperties[[propertyNames[propertyIndex]]], value)
	  })
	  candidateProperties[["NoExplPeaks"]] <<- c(candidateProperties[["NoExplPeaks"]], .jcall(candidate, "I", "getNumberPeaksExplained"))
	})
	
	sapply(1:length(propertyNames), function(propertyIndex) {
	  datatype<-datatypes[[propertyNames[propertyIndex]]]
	  if(datatype == "java.lang.Double" || datatype == "java.lang.Byte" || datatype == "java.lang.Integer" || datatype == "java.lang.Float") {
	    candidateProperties[[propertyNames[propertyIndex]]]<<-as.numeric(candidateProperties[[propertyNames[propertyIndex]]])
	  }
	})

	datatypes[["NumberPeaksUsed"]]<-"java.lang.Integer"
	candidateProperties[["NumberPeaksUsed"]] <- rep(numberPeaksUsed, numberCandidates)

	return(as.data.frame(candidateProperties))
}


#' Calculate MetFrag scores for molecules and a given tandem mass spectrum
#' 
#' The function calculates scores for molecules given in a SD file. The score
#' calculation is based on the match of in silico generated fragments of the
#' candidate molecules to the given tandem mass spectrum. A list of candidate
#' molecules is returned sorted by their MetFrag score.
#' 
#' 
#' @param sdf The name of the SD file containing candidate molecules
#' @param mzs A \code{vector} mass to charge ratio values
#' @param ints A \code{vector} of intensity values
#' @param exact.mass The neutral exact mass of the precursor molecule
#' @param number.threads Number threads for parallel execution (max. 8)
#' @param mz.abs Absolute mass deviation (Da) allowed to match theoretical
#' fragment massed to the given mz values
#' @param mz.ppm Relative mass deviation (ppm) allowed to match theoretical
#' fragment massed to the given mz values
#' @param search.ppm The relative mass deviation (ppm) from \code{exact.mass}
#' for candidate molecules in \code{sdf}
#' @param pos.charge If \code{TRUE} the given tandem mass spectrum is assumed
#' to be measured in positive mode
#' @param mode Type of the measured molecule: -1 -> [M-H], 0 -> [M], 1 -> [M+H]
#' @param tree.depth Maximal tree depth of MetFrag to generate fragments
#' @author Christoph Ruttkies (\email{cruttkie@ipb-halle.de})
#' @export score.molecules.from.sdf
score.molecules.from.sdf<-function(sdf, mzs, ints, exact.mass, number.threads=1, mz.abs=0.01, mz.ppm=10, search.ppm=10, pos.charge=TRUE, mode=1, tree.depth=2, score.names=c("FragmenterScore"), scoreWeights=c(1.0)) {
	
	if(missing(sdf)) stop("Error: SDF is missing!")
	if(missing(mzs)) stop("Error: Vector of mass to charge ratios is missing!")
	if(missing(ints)) stop("Error: Vector of intensities is missing!")
	if(missing(exact.mass)) stop("Error: Neutral exact mass of parent molecule is missing!")

	if(file.access(sdf, 4) != 0) stop("Error: Cannot access SDF! Either it does not exist or is not readable.");
	if(!is.vector(mzs) || !is.numeric(mzs) || any(mzs < 0)) stop("Error: The argument mzs must be a vector of numerals!")
	if(!is.vector(ints) || !is.numeric(ints) || any(ints < 0)) stop("Error: The argument ints must be a vector of positive numerals!")
	if(exact.mass < 0) stop("Error: The argument exact.mass must be a positive numeral!")	
	if(number.threads < 0 || number.threads > 8) stop("Error: The argument number.threads must get values from 0 till 8!")
	if(mz.abs < 0) stop("Error: The argument mz.abs must be positive!")	
	if(mz.ppm < 0) stop("Error: The argument mz.ppm must be positive!")
	if(search.ppm < 0) stop("Error: The argument search.ppm must be positive!")
	if(!is.logical(pos.charge)) stop("Error: The argument pos.charge must be a logical value!")
	if(!is.element(mode, c(-1,0,1))) stop("Error: The argument mode must be a value of -1, 0 or 1")
	if(tree.depth < 1 || tree.depth > 5) stop("Error: The argument tree.depth must get values from 1 till 5!")
	
	obj=.jnew("de/ipbhalle/metfrag/r/MetfRag")
	mols<-.jcall(obj, '[Lorg/openscience/cdk/interfaces/IAtomContainer;', 
               'scoreMoleculesAgainstSpectrum', sdf, 
               .jarray(as.double(mzs),"[D"), 
               .jarray(as.double(ints),"[D"), 
               as.double(exact.mass), as.integer(number.threads), as.double(mz.abs), as.double(mz.ppm), 
               as.double(search.ppm), as.logical(pos.charge), as.integer(mode), as.integer(tree.depth), .jarray(score.names,"[S"), .jarray(as.double(scoreWeights),"[D"))
	obj = .jnull()
	
  if(length(mols) == 0) 
    cat("No results generated!","\n")
	
  return(mols)
}

#' Calculate MetFrag scores for molecules and a given tandem mass spectrum
#' 
#' The function calculates scores for molecules given by a vector of rcdk atomcontainers. 
#' The score calculation is based on the match of in silico generated fragments 
#' of the candidate molecules to the given tandem mass spectrum. A list of candidate
#' molecules is returned sorted by their MetFrag score.
#' 
#' 
#' @param molecules candidate molecules as vector of rcdk atomcontainers
#' @param mzs A \code{vector} mass to charge ratio values
#' @param ints A \code{vector} of intensity values
#' @param exact.mass The neutral exact mass of the precursor molecule
#' @param number.threads Number threads for parallel execution (max. 8)
#' @param mz.abs Absolute mass deviation (Da) allowed to match theoretical
#' fragment massed to the given mz values
#' @param mz.ppm Relative mass deviation (ppm) allowed to match theoretical
#' fragment massed to the given mz values
#' @param pos.charge If \code{TRUE} the given tandem mass spectrum is assumed
#' to be measured in positive mode
#' @param mode Type of the measured molecule: -1 -> [M-H], 0 -> [M], 1 -> [M+H]
#' @param tree.depth Maximal tree depth of MetFrag to generate fragments
#' @author Christoph Ruttkies (\email{cruttkie@ipb-halle.de})
#' @export score.molecules.from.container
score.molecules.from.container<-function(molecules, mzs, ints, exact.mass, 
                                         number.threads=1, mz.abs=0.01, 
                                         mz.ppm=10, pos.charge=TRUE, 
                                         mode=1, tree.depth=2, score.names=c("FragmenterScore"), scoreWeights=c(1.0)) 
{
  if(missing(molecules)) stop("Error: Molecules are missing!")
  if(missing(mzs)) stop("Error: Vector of mass to charge ratios is missing!")
  if(missing(ints)) stop("Error: Vector of intensities is missing!")
  if(missing(exact.mass)) stop("Error: Neutral exact mass of parent molecule is missing!")
  
  if(!is.vector(mzs) || !is.numeric(mzs) || any(mzs < 0)) stop("Error: The argument mzs must be a vector of numerals!")
  if(!is.vector(ints) || !is.numeric(ints) || any(ints < 0)) stop("Error: The argument ints must be a vector of positive numerals!")
  if(exact.mass < 0) stop("Error: The argument exact.mass must be a positive numeral!")	
  if(number.threads < 0 || number.threads > 8) stop("Error: The argument number.threads must get values from 0 till 8!")
  if(mz.abs < 0) stop("Error: The argument mz.abs must be positive!")	
  if(mz.ppm < 0) stop("Error: The argument mz.ppm must be positive!")
  if(!is.logical(pos.charge)) stop("Error: The argument pos.charge must be a logical value!")
  if(!is.element(mode, c(-1,0,1))) stop("Error: The argument mode must be a value of -1, 0 or 1")
  if(tree.depth < 1 || tree.depth > 5) stop("Error: The argument tree.depth must get values from 1 till 5!")
  
  obj = .jnew("de/ipbhalle/metfrag/r/MetfRag")
  mols<- .jcall(obj, '[Lorg/openscience/cdk/interfaces/IAtomContainer;',
               'scoreMoleculesAgainstSpectrum', 
               .jarray(molecules, contents.class = "org/openscience/cdk/interfaces/IAtomContainer"),
               .jarray(as.double(mzs),"[D"), 
               .jarray(as.double(ints),"[D"), 
               exact.mass, as.integer(number.threads), as.double(mz.abs), as.double(mz.ppm), 
               as.logical(pos.charge), as.integer(mode), as.integer(tree.depth), .jarray(score.names,"[S"), .jarray(as.double(scoreWeights),"[D"))
  obj = .jnull()
  
  if(length(mols) == 0) 
    cat("No results generated!","\n")
  
  return(mols)
}