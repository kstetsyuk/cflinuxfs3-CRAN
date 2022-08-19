# cloud.gov Precompiled CRAN (cflinuxfs3-CRAN)

Due to the 15 minute timeout on buildpacks and the lack of precompiled R packages for linux, R buildpack applications often fail to deploy. To resolve this issue, we have created the cflinuxfs3-CRAN repository.

## Requesting new packages

Request any packages you need added in an [issue](../../issues) and a maintainer will review your request. If a package is not in the standard CRAN, please provide its location.

Licensed members of the USEPA org can also request packages using the workflow dispatch in the Actions tab.

## How to use this CRAN in cloud.gov
To use this, start your r.yml file with the lines:
```
packages:
- cran_mirror: https://raw.githubusercontent.com/USEPA/cflinuxfs3-CRAN/master/cflinuxfs3/
```

# Disclaimer
The United States Environmental Protection Agency (EPA) GitHub project code is provided on an "as is" basis and the user assumes responsibility for its use.  EPA has relinquished control of the information and no longer has responsibility to protect the integrity , confidentiality, or availability of the information.  Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by EPA.  The EPA seal and logo shall not be used in any manner to imply endorsement of any commercial product or activity by EPA or the United States Government.
