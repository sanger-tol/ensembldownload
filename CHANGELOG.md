# sanger-tol/ensembldownload: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[3.0.0](https://github.com/sanger-tol/ensembldownload/releases/tag/3.0.0)] - Flamboyant Smaug - [2026-11-23]

_This first version is an hybrid between the now-retired sanger-tol/ensemblgenedownload and
sanger-tol/ensemblrepeatdownload pipelines.
We version it as the successor of both original pipelines, hence v3.0.0._

- Support Ensembl's new FTP structure <https://ftp.ebi.ac.uk/pub/ensemblorganisms/GCA/> which
  provides data _already compressed with `bgzip` and indexed_ !
  - The pipeline now merely downloads and renames the files to comply with the standard
    Genome After-Party file nomenclature.
  - Downloads happen with the rsync protocol.
  - The pipeline will add extra analyses such as gene and repeat density tracks in a later release.
- Built with the nf-core template v4.2.0

### Parameters

_The comparison below refers to sanger-tol/ensemblgenedownload 2.0.2._

| Old parameter          | New parameter |
| ---------------------- | ------------- |
| --ensembl_species_name |               |

_In the samplesheet_

| Old parameter        | New parameter |
| -------------------- | ------------- |
| ensembl_species_name |               |

> **NB:** Parameter has been **updated** if both old and new parameter information is present. </br> **NB:** Parameter has been **added** if just the new parameter information is present. </br> **NB:** Parameter has been **removed** if new parameter information isn't present.
