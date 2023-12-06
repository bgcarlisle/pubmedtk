# pubmedtk

"Pubmed toolkit," an R package that provides functions for downloading
data via the Pubmed API and interpreting them.

## Installing

This package is not currently on CRAN (maybe later) and so if you want
to use it, you will have to do so via `devtools`:

```
install.packages("devtools")
library(devtools)
install_github("bgcarlisle/pubmedtk")
library(pubmedtk)
```

## Pubmed API

You will need a Pubmed API key to access the Pubmed API. This is a
36-character code that is provided by Pubmed. If you don't have one,
you can generate one by following these instructions:

1. Go to [Pubmed](https://pubmed.ncbi.nlm.nih.gov/)
2. Log in
3. Account > Account settings > API Key Management
4. Generate an API key
5. Save this in a plain-text file called `api_key.txt` in the root of
   your project and read this into your code using something like the
   following: `ak <- readLines("api_key.txt")`
6. Recommended: If you're using git for version control, open the
   `.gitignore` file and add `api_key.txt` to the file, so that you
   don't accidentally expose your Pubmed credentials to the world.
   
For all the examples below, assume that the `api_key.txt` file has
already been written to disk.
   
## Functions provided by `pubmedtk`

This package provides three functions: `download_one_pmid_metadata()`,
`download_pmid_metadata()`, and `intersection_check()`.

### `download_one_pmid_metadata()`

Downloads metadata from the Pubmed API for a single PMID, and returns
a named list of 5 elements:

1. `$pubmed_dl_success`, which is TRUE in the case that a corresponding
Pubmed record was found and metadata downloaded and FALSE otherwise.
2. `$doi`, a character string containing the DOI for the publication with
the PMID in question.
3. `$languages`, a JSON-encoded list of languages corresponding to the
publication with the PMID in question.
4. `$pubtypes`, a JSON-encoded list of publication types corresponding to
the publication with the PMID in question.
5. `$authors`, a JSON-encoded list of authors of the publication with the
PMID in question.

Example:

```
## Read in API key
ak <- readLines("api_key.txt")

## Download Pubmed metadata
mdata <- download_one_pmid_metadata("29559429", ak)

## Extract first author
jsonlite::fromJSON(mdata$authors)[1]
```

### `download_pmid_metadata()`

Downloads metadata from Pubmed API for a column of PMID's in a data
frame, and returns a data frame containing the original columns as
well as five additional columns:

1. The `pubmed_dl_success` column is TRUE in the case that metadata
were successfully downloaded from Pubmed; FALSE in the case that an
error occurred during downloading (e.g. due to a number that is
well-formed but does not correspond to a true PMID); NA in the case
that the supplied PMID is not well-formed (e.g. NA or non-numeric).
2. The `doi` column returns a DOI that corresponds to the PMID
supplied if one is found, NA otherwise.
3. The `languages` column contains a JSON-encoded list of languages
for the article in question.
4. The `pubtypes` column contains a JSON-encoded list of publication
types for the article in question.
5. The `authors` column contains a JSON-encoded list of authors for
the article in question.

Example:

```
library(tidyverse)

## Read in API key
ak <- readLines("api_key.txt")

## Example publications and their corresponding PMID's (some valid and
## some not)
pubs <- tibble::tribble(
  ~pmid,
  "28837722",
  NA,
  "98472657638729",
  "borp",
  "29559429"
)

## Download Pubmed metadata
pm_meta <- download_pmid_metadata(pubs, "pmid", ak)

## Extract DOI's for those that were successfully downloaded
pm_meta %>%
  filter(pubmed_dl_success) %>%
  select(pmid, doi)

## A tibble: 2 × 2
##   pmid     doi                    
##   <chr>    <chr>                  
## 1 28837722 10.1001/jama.2017.11502
## 2 29559429 10.1136/bmj.k959       
```

### `intersection_check()`

This function takes a Pubmed search query and a set of PMID's and
indicates for each PMID whether it would or would not be contained in
the results of the provided search query. The function returns the
original data frame with the column of PMID's to be checked, as well
as two additional columns: `pm_checked` and `found_in_pm_query`.

The new `pm_checked` column is TRUE if Pubmed was successfully queried
and NA if Pubmed was not checked for that PMID (this may occur in
cases where the PMID to be checked is not well-formed).

The new `found_in_pm_query` column is TRUE if the PMID in question
would appear in a search of Pubmed defined by the query provided;
FALSE if it would not appear in such a search and NA if the PMID in
question was not checked (this may occur in cases where the PMID is
not well-formed).

Example:

```
library(tidyverse)

## Read in API key
ak <- readLines("api_key.txt")

## Example publications and their corresponding PMID's (some valid and
## some not)
pubs <- tibble::tribble(
  ~pmid,
  "29559429",
  "28837722",
  "28961465",
  "32278621",
  "one hundred of them",
  "28837722",
  "28961465"
)

## Check which PMID's are authored by someone named "Carlisle"
intersection_check(pubs, "pmid", "Carlisle[Author]", ak)

## # A tibble: 7 × 3
##   pmid                pm_checked found_in_pm_query
##   <chr>               <lgl>      <lgl>            
## 1 29559429            TRUE       TRUE             
## 2 28837722            TRUE       TRUE             
## 3 28961465            TRUE       FALSE            
## 4 32278621            TRUE       FALSE            
## 5 one hundred of them NA         NA               
## 6 28837722            TRUE       TRUE             
## 7 28961465            TRUE       FALSE            
```


