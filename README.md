# cloud.gov Precompiled CRAN (cflinuxfs3-CRAN)

Due to the 15 minute timeout on buildpacks and the lack of precompiled R packages for linux, R buildpack applications often fail to deploy. To resolve this issue, we have created the cflinuxfs3-CRAN repository.

## How does this work?

Package requests are made via Github issues. There is a Package Request template that applies the correct form and label. Essentially, the request can either be a package name in the cloud.r-project.org CRAN repository, a link to a tarball of an R package (such as one from a CRAN repository), or a zip archive (such as a Github repository archive of an R package). The request must match this form:

```
Package: ggplot2, https://github.com/thomascjohnson/CRANpiled/archive/master.zip, https://cran.r-project.org/src/contrib/quietR_0.1.0.tar.gz
```

Or in other words, a single `Package: ` followed by a comma separated string of package names, tarball URLs and/or zip URLs.

This will kick off a Github action that will try to add the package to the repository. If it is successful, it will close the issue via the commit message. If it is not successful, it will tag the user specified to run the action and add the error output to the issue, and then close the issue.

