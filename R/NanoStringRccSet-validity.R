setValidity2("NanoStringRccSet", function(object) {
    msg <- NULL
    if (dim(object)[["Samples"]] > 0L) {
        if (!all(grepl("\\.rcc$", sampleNames(object), ignore.case = TRUE))) {
            msg <- c(msg, "'sampleNames' must all have an \".RCC\" file extension")
        }
        protocolDataColNames <- rownames(.rccMetadata[["protocolData"]])
        if (!all(protocolDataColNames %in% varLabels(protocolData(object)))) {
            msg <- c(msg, sprintf("'protocolData' must contain columns %s", paste0("\"", 
                protocolDataColNames, "\"", collapse = ", ")))
        }
        if (!all(protocolData(object)[["FileVersion"]] %in% numeric_version(c("1.7", "2.0")))) {
            msg <- c(msg, "'protocolData' \"FileVersion\" must all be either 1.7 or 2.0")
        }
        if (!all(protocolData(object)[["LaneID"]] %in% 1L:12L)) {
            msg <- c(msg, "'protocolData' \"LaneID\" must all be integers from 1 to 12")
        }
        if (!.validNonNegativeInteger(protocolData(object)[["FovCount"]])) {
            msg <- c(msg, "'protocolData' \"FovCount\" must all be non-negative integers")
        }
        if (!.validNonNegativeInteger(protocolData(object)[["FovCounted"]])) {
            msg <- c(msg, "'protocolData' \"FovCounted\" must all be non-negative integers")
        }
        else if (!all(protocolData(object)[["FovCounted"]] <= protocolData(object)[["FovCount"]])) {
            msg <- c(msg, "'protocolData' \"FovCounted\" must all be less than or equal to \"FovCount\"")
        }
        if (!all(protocolData(object)[["StagePosition"]] %in% 1L:6L)) {
            msg <- c(msg, "'protocolData' \"StagePosition\" must all be integers from 1 to 6")
        }
        if (!.validNonNegativeNumber(protocolData(object)[["BindingDensity"]])) {
            msg <- c(msg, "'protocolData' \"BindingDensity\" must all be non-negative numbers")
        }
    }
    if (dim(object)[["Features"]] > 0L) {
        featureDataColNames <- c("CodeClass", "GeneName", "Accession", "IsControl", "ControlConc")
        if (!all(featureDataColNames %in% varLabels(featureData(object)))) {
            msg <- c(msg, sprintf("'featureData' must contain columns %s", paste0("\"", 
                featureDataColNames, "\"", collapse = ", ")))
        }
        else {
            codeClass <- featureData(object)[["CodeClass"]]
            isControl <- featureData(object)[["IsControl"]]
            controlConc <- featureData(object)[["ControlConc"]]
            endogen <- which(codeClass == "Endogenous")
            posCtrl <- which(codeClass == "Positive")
            negCtrl <- which(codeClass == "Negative")
            housekp <- which(codeClass == "Housekeeping")
            if (length(endogen) > 0L) {
                if (!.allFALSE(isControl[endogen])) {
                  msg <- c(msg, "'featureData': \"IsControl\" must all be FALSE when CodeClass == \"Endogenous\"")
                }
                if (!.allNA(controlConc[endogen])) {
                  msg <- c(msg, "'featureData': \"ControlConc\" must all be NA when CodeClass == \"Endogenous\"")
                }
            }
            if (length(posCtrl) > 0L) {
                if (!.allTRUE(isControl[posCtrl])) {
                  msg <- c(msg, "'featureData': \"IsControl\" must all be TRUE when CodeClass == \"Positive\"")
                }
                if (!.validPositiveNumber(controlConc[posCtrl])) {
                  msg <- c(msg, "'featureData': \"ControlConc\" must be positive numbers when CodeClass == \"Positive\"")
                }
            }
            if (length(negCtrl) > 0L) {
                if (!.allTRUE(isControl[negCtrl])) {
                  msg <- c(msg, "'featureData': \"IsControl\" must all be TRUE when CodeClass == \"Negative\"")
                }
                if (!.allZero(controlConc[negCtrl])) {
                  msg <- c(msg, "'featureData': \"ControlConc\" must all be zero when CodeClass == \"Negative\"")
                }
            }
            if (length(housekp) > 0L) {
                if (!.allTRUE(isControl[housekp])) {
                  msg <- c(msg, "'featureData': \"IsControl\" must all be TRUE when CodeClass == \"Housekeeping\"")
                }
                if (!.allNA(controlConc[housekp])) {
                  msg <- c(msg, "'featureData': \"ControlConc\" must all be NA when CodeClass == \"Housekeeping\"")
                }
            }
        }
    }
    if (sum(dim(object)) > 0L) {
        if (length(annotation(object)) != 1L || is.na(annotation(object)) || !nzchar(annotation(object))) {
            msg <- c(msg, "'annotation' must contain the GeneRLF")
        }
    }
    if (prod(dim(object)) > 0L) {
        if (!.validNonNegativeInteger(exprs(object))) {
            msg <- c(msg, "'exprs' does not contain non-negative integer values")
        }
        if (length(dimLabels(object)) != 2L) {
            msg <- c(msg, "dimLabels must be a character vector of length 2")
        }
        else {
            if (!(dimLabels(object)[1L] %in% fvarLabels(object))) {
                msg <- c(msg, "dimLabels[1] must be in 'fvarLabels'")
            }
            if (!(dimLabels(object)[2L] %in% svarLabels(object))) {
                msg <- c(msg, "dimLabels[2] must be in 'svarLabels'")
            }
        }
    }
    if (any(duplicated(c(fvarLabels(object), svarLabels(object), assayDataElementNames(object), 
        "signatures", "design")))) {
        msg <- c(msg, "'fvarLabels', 'svarLabels', 'assayDataElementNames', \"signatures\", and \"design\" must be unique")
    }
    if (length(signatures(object)) > 0L) {
        numGenes <- lengths(signatures(object))
        if (is.null(names(numGenes)) || any(nchar(names(numGenes)) == 0L)) {
            msg <- c(msg, "'signatures' must be a named NumericList")
        }
        if (any(numGenes == 0L)) {
            msg <- c(msg, "'signatures' vectors must be non-empty")
        }
        else {
            genes <- names(unlist(unname(weights(signatures(object)))))
            if (is.null(genes) || any(nchar(genes) == 0L)) {
                msg <- c(msg, "'signatures' vectors must be named")
            }
            else if (!all(unique(genes) %in% c("(Intercept)", featureData(object)[["GeneName"]]))) {
                msg <- c(msg, "'signatures' vectors must be named with values from 'featureData' \"GeneName\"")
            }
        }
    }
    if (!is.null(design(object))) {
        if (length(design(object)) != 2L) {
            msg <- c(msg, "'design' must be NULL or a one-sided formula")
        }
        if (!all(all.vars(design(object)) %in% varLabels(object))) {
            msg <- c(msg, "'design' must reference columns from 'phenoData'")
        }
    }
    if (is.null(msg)) 
        TRUE
    else msg
})
