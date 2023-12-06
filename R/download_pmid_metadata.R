#' Downloads metadata from Pubmed API for provided PMID's
#'
#' @param df A dataframe containing a column of PMID's
#'
#' @param column The name of the column containing PMID's
#'
#' @param api_key A valid Pubmed API key
#'
#' @return A data frame containing the original columns as well as
#'     five additional columns:
#'
#'     The `pubmed_dl_success` column is TRUE in the case that
#'     metadata were successfully downloaded from Pubmed; FALSE in the
#'     case that an error occurred during downloading (e.g. due to a
#'     number that is well-formed but does not correspond to a true
#'     PMID); NA in the case that the supplied PMID is not well-formed
#'     (e.g. NA or non-numeric).
#'
#'     The `doi` column returns a DOI that corresponds to the PMID
#'     supplied if one is found, NA otherwise.
#'
#'     The `languages` column contains a JSON-encoded list of
#'     languages for the article in question.
#'
#'     The `pubtypes` column contains a JSON-encoded list of
#'     publication types for the article in question.
#'
#'     The `authors` column contains a JSON-encoded list of authors
#'     for the article in question.
#'
#' @export
#'
#' @importFrom magrittr %>%
#' @importFrom rlang .data

download_pmid_metadata <- function(df, column, api_key) {
    
    out <- tryCatch({

        ## Check that the column exists in the supplied df
        assertthat::assert_that(
                        column %in% colnames(df),
                        msg = paste(
                            "Column", column,
                            "is not present in supplied data frame"
                        )
                    )

        ## Check that the supplied data frame does not already have
        ## the columns that this function will add
        assertthat::assert_that(
                        mean(
                            c(
                                "pubmed_dl_success",
                                "doi",
                                "languages",
                                "pubtypes",
                                "authors"
                            )
                            %in%
                            colnames(df)
                        ) == 0,
                        msg = paste(
                            "The supplied data frame cannot contain",
                            "columns with the following names:",
                            "pubmed_dl_success, doi, languages,",
                            "pubtypes, authors"
                            
                        )
                    )

        ## Pull out the well formed PMID's to be checked
        pmids <- df %>%
            dplyr::filter(
                grepl("^[0-9]+\\.?[0-9]+$", !!dplyr::sym(column))
            ) %>%
            dplyr::pull(column)

        ## Add the new columns
        df$pubmed_dl_success <- as.logical(NA)
        df$doi <- as.character(NA)
        df$languages <- as.character(NA)
        df$pubtypes <- as.character(NA)
        df$authors <- as.character(NA)

        for (id in pmids) {

            ## Download the metadata
            pm_metadata <- download_one_pmid_metadata(id, api_key)

            ## Apply it to the data frame

            df <- df %>%
                dplyr::mutate(
                    pubmed_dl_success = ifelse(
                        .data$pmid == id,
                        pm_metadata$pubmed_dl_success,
                        .data$pubmed_dl_success
                    )
                )
            
            df <- df %>%
                dplyr::mutate(
                    doi = ifelse(
                        .data$pmid == id,
                        pm_metadata$doi,
                        .data$doi
                    )
                )

            df <- df %>%
                dplyr::mutate(
                    languages = ifelse(
                        .data$pmid == id,
                        pm_metadata$languages,
                        .data$languages
                    )
                )

            df <- df %>%
                dplyr::mutate(
                    pubtypes = ifelse(
                        .data$pmid == id,
                        pm_metadata$pubtypes,
                        .data$pubtypes
                    )
                )

            df <- df %>%
                dplyr::mutate(
                    authors = ifelse(
                        .data$pmid == id,
                        pm_metadata$authors,
                        .data$authors
                    )
                )
            
        }

        out <- df

    },
    error = function(cond) {
        message("Error downloading Pubmed metadata")
        message("Here's the original error message:")
        message(paste(cond, "\n"))
        ## Choose a return value in case of error
        return(FALSE)
    },
    warning = function(cond) {
        message("Warning downloading Pubmed metadata")
        message("Here's the original error message:")
        message(paste(cond, "\n"))
        ## Choose a return value in case of error
        return(TRUE)
    },
    finally = {
        ## To execute regardless of success or failure
    })

    return(out)
}
