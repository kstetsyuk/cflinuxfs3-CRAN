get_issues <- function(owner, repo, labels = NULL,
                       state = c("open", "closed", "all"),
                       username = Sys.getenv("GITHUB_USER"),
                       token = Sys.getenv("GITHUB_TOKEN")) {
  state <- match.arg(state)

  uri <- sprintf("/repos/%s/%s/issues", owner, repo)

  if (!is.null(labels)) labels <- paste0(labels, collapse = ",")

  issues_req <- httr::GET(
    paste0("https://api.github.com", uri),
    query = list(labels = labels, state = state),
    httr::add_headers(authorization = paste("Bearer ", token))
  )

  httr::content(issues_req, as = "parsed")
}

get_members <- function(github_org,
                        username = Sys.getenv("GITHUB_USER"),
                        token = Sys.getenv("GITHUB_TOKEN")) {
  c(lapply(1:10, function(i) {
    response <- httr::GET(
      sprintf(
        "https://api.github.com/orgs/%s/members?per_page=100&page=%s",
        github_org,
        i),
      httr::add_headers(authorization = paste("Bearer ", token))
    )
    sapply(httr::content(response, as = "parsed"), `[[`, "login")
  }), recursive=TRUE)
}

filter_issues <- function(
  issues,
  github_org = Sys.getenv("GITCRAN_FILTER_ORG"),
  username = Sys.getenv("GITHUB_USER"),
  token = Sys.getenv("GITHUB_TOKEN")
) {
  if (github_org == username || github_org == "")
    organization_members <- username
  else
    organization_members <- get_members(github_org, username, token)

  Filter(function(x) x$user$login %in% organization_members, issues)
}

get_package_requests <- function(
  owner,
  repo,
  labels = "package-request",
  state = "open",
  filter_org = Sys.getenv("GITCRAN_FILTER_ORG"),
  username = Sys.getenv("GITHUB_USER"),
  token = Sys.getenv("GITHUB_TOKEN")
) {
  issues <- filter_issues(
    issues = get_issues(owner, repo, labels, state, username, token),
    github_org = filter_org,
    username = username,
    token = token
  )

  raw_requests <- lapply(
    issues,
    function(issue) parse_package_request(issue$body)
  )

  issue_ids <- sapply(issues, `[[`, "number")

  setNames(raw_requests, issue_ids)
}

read_dcf_text <- function(txt, fields = NULL, all = FALSE, keep.white = NULL) {
  tf <- tempfile()
  on.exit(file.remove(tf))
  writeLines(txt, tf)
  read.dcf(tf, fields, all, keep.white)
}

parse_package_request <- function(issue_body) {
  issue_dcf <- read_dcf_text(issue_body)[1, 1]

  if (!setequal("Package", names(issue_dcf)))
    stop("Missing 'Package' field from request. Aborting.")

  packages_csv <- issue_dcf[["Package"]]

  unique(strsplit(packages_csv, ",\\s*")[[1]])
}

#' Handle Package Requests from Issues Automatically
#'
#' This pipeline fetches issues from a Github repository and if they follow
#' the form of a package request, the pipeline will try to automatically add
#' the pakges to the repository. If the additions fail, it will comment on the
#' issue with the error message, tag the provided username and close the issue.
#'
#' @param owner character - Github organization/user name, defaults to the
#' environment variable GITCRAN_REPO_OWNER
#' @param gh_repository character - the repository name, defaults to the
#' environment variable GITCRAN_REPO
#' @param subpath character - a path relative to the gh_repository root that
#' contains a CRAN repository. Defaults to "": the root of the repository.
#' @param labels character vector - Github issue labels to search for package
#' requests, defaults to the environment variable GITCRAN_LABELS
#' @param state character - Issue state, "open" or "closed", defaults to the
#' environment variable GITCRAN_STATE or "open"
#' @param username character - Github username that has access to repository
#' issues, defaults to the environment variable GITHUB_USER
#' @param token character - Github Personal Access TOKEN (PAT) for the provided
#' username with repository read and write permissions, defaults to the
#' environment variable GITHUB_TOKEN
#'
#' @export
package_request_pipeline <- function(
  package_request_raw,
  owner = Sys.getenv("GITCRAN_REPO_OWNER"),
  gh_repository = Sys.getenv("GITCRAN_REPO"),
  subpath = Sys.getenv("GITCRAN_SUBDIR", ""),
  labels = Sys.getenv("GITCRAN_LABELS", "package-request"),
  state = Sys.getenv("GITCRAN_STATE", "open"),
  username = Sys.getenv("GITHUB_USER"),
  token = Sys.getenv("GITHUB_TOKEN")
) {
  stopifnot(nchar(owner) > 0)
  stopifnot(nchar(gh_repository) > 0)
  stopifnot(all(nchar(labels) > 0))
  stopifnot(nchar(state) > 0)
  stopifnot(nchar(username) > 0)
  stopifnot(nchar(token) > 0)

  CRAN_repo <- Sys.getenv("CRAN_REPO", "https://cloud.r-project.org")

  local_repository <- getwd()
  git2r_repo <- git2r::repository(local_repository)

  git2r::config(git2r_repo, user.name = "github-actions",
                user.email = "github-actions@github.com")

  if (nchar(subpath) > 0)
    local_repository <- file.path(local_repository, subpath)

  CRANpiled::create_repository(local_repository)

  available_packages <- available.packages(repos = CRAN_repo)

  ### Deal with nloptr (needs to install v 2.0.1):
  nloptr_row = which(available_packages == "nloptr")[1]
  if (!is.na(nloptr_row)) {
    available_packages[nloptr_row, 2] = "2.0.1"
  }
  
  package_request <- unique(strsplit(package_request_raw, ",\\s*")[[1]])

  cat(paste0("Adding package request", package_request))
  packages_added <- CRANpiled::add_packages(
    package_request,
    local_repository,
    available_packages,
    compile = TRUE,
    quiet = FALSE
  )

  git2r::add(git2r_repo, local_repository)

  git2r::commit(
    git2r_repo,
    paste0(
      "Adds:\n ",
      paste(packages_added, collapse = ", ")
    )
  )

  git2r::push(
    git2r_repo,
    credentials = git2r::cred_token("GITHUB_TOKEN")
  )


  cat("Pipeline finished.")
}

create_comment <- function(owner, repository, issue_id, comment, username,
                           token) {
  httr::POST(
    sprintf(
      "https://api.github.com/repos/%s/%s/issues/%s/comments",
      owner, repository, issue_id
    ),
    body = jsonlite::toJSON(list(body = comment), auto_unbox = TRUE),
    httr::add_headers(authorization = paste("Bearer ", token))
  )
}

close_issue <- function(owner, repository, issue_id, username, token) {
  httr::PATCH(
    sprintf(
      "https://api.github.com/repos/%s/%s/issues/%s",
      owner, repository, issue_id
    ),
    body = jsonlite::toJSON(list(state = "closed"), auto_unbox = TRUE),
    httr::add_headers(authorization = paste("Bearer ", token))
  )
}
