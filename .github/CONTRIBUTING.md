---
editor_options: 
  markdown: 
    wrap: sentence
---

# Contributing to rangr

This outlines how to propose a change to rangr.

Note that this package is in an initially stable state of development, with a great deal of active subsequent development envisioned.

## Fixing typos

You can fix typos, spelling mistakes, or grammatical errors in the documentation directly using the GitHub web interface, as long as the changes are made in the *source* file.
This generally means you'll need to edit [roxygen2 comments](https://roxygen2.r-lib.org/articles/roxygen2.html) in an `.R`, not a `.Rd` file.
You can find the `.R` file that generates the `.Rd` in the comment in the first line of code.

## Bigger changes

If you want to make a bigger change, it's a good idea to first file an issue and make sure someone from the team agrees that it's needed.
If you've found a bug, please file an issue that illustrates the bug with a minimal [reprex](https://www.tidyverse.org/help/#reprex) (this will also help you write a unit test, if needed).

### Pull request process

-   Fork the package and clone it onto your computer.
    If you haven't done this before, we recommend using `usethis::create_from_github("popecol/rangr", fork = TRUE)`.

-   Install all development dependencies with `devtools::install_dev_deps()`, and then make sure the package passes R CMD check by running `devtools::check()`.
    If R CMD check doesn't pass cleanly, it's a good idea to ask for help before continuing.

-   Create a Git branch for your pull request (PR).
    We recommend using `usethis::pr_init("brief-description-of-change")`.

-   Make your changes, commit to git, and then create a PR by running `usethis::pr_push()`, and following the prompts in your browser.
    The title of your PR should briefly describe the change.
    The body of your PR should contain `Fixes #issue-number`.


### Code style

-   New code should follow the rOpenSci [style suggestions](https://devguide.ropensci.org/building.html#code-style).
    You can use the [styler](https://CRAN.R-project.org/package=styler) package to apply these styles, but please don't restyle code that has nothing to do with your PR.

-   We use [roxygen2](https://cran.r-project.org/package=roxygen2), with [Markdown syntax](https://cran.r-project.org/web/packages/roxygen2/vignettes/rd-formatting.html), for documentation.

-   We use [testthat](https://cran.r-project.org/package=testthat) for unit tests.
    Contributions with test cases included are easier to accept.

## Code of Conduct

Please note that the rangr project is released with a [Contributor Code of Conduct](https://ropensci.org/code-of-conduct/).
By contributing to this project you agree to abide by its terms.
