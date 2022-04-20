# cloud.gov Precompiled CRAN (cflinuxfs3-CRAN)

Due to the 15 minute timeout on buildpacks and the lack of precompiled R packages for linux, R buildpack applications often fail to deploy. To resolve this issue, we have created the cflinuxfs3-CRAN repository.

## How does this work?

Package requests are made via Github issues. There is a Package Request template that applies the correct form and label. Essentially, the request can either be a package name in the cloud.r-project.org CRAN repository, a link to a tarball of an R package (such as one from a CRAN repository), or a zip archive (such as a Github repository archive of an R package). The request must match this form:

```
Package: ggplot2, https://github.com/thomascjohnson/CRANpiled/archive/master.zip, https://cran.r-project.org/src/contrib/quietR_0.1.0.tar.gz
```

Or in other words, a single `Package: ` followed by a comma separated string of package names, tarball URLs and/or zip URLs.

## How to use this CRAN in cloud.gov
To use this, start your r.yml file with the lines:
```
packages:
- cran_mirror: https://raw.githubusercontent.com/USEPA/cflinuxfs3-CRAN/master/cflinuxfs3/
```

# Disclaimer
The United States Environmental Protection Agency (EPA) GitHub project code is provided on an "as is" basis and the user assumes responsibility for its use.  EPA has relinquished control of the information and no longer has responsibility to protect the integrity , confidentiality, or availability of the information.  Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by EPA.  The EPA seal and logo shall not be used in any manner to imply endorsement of any commercial product or activity by EPA or the United States Government.
