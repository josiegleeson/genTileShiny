
# genTile

A tool for designing optimally spaced CRISPR guide libraries for precise dosage modulation across gene targets.

Developed by Nathanael Andrews and Josie Gleeson in the Lappalainen Lab.

## Overview

genTile is a pipeline, primarily intended for internal use in the Lappalainen lab, for designing CRISPR guide RNAs with optimal spacing for CRISPRi/a applications. It extracts sequences from target genomic regions, designs candidate guides, and selects high-scoring guides with appropriate spacing for effective tiling.

## Acknowledgments

genTile relies heavily on the excellent FlashFry tool for guide RNA design and scoring. FlashFry provides the core functionality for guide identification and off-target analysis.

**FlashFry Citation**:
McKenna A, Shendure J. FlashFry: a fast and flexible tool for large-scale CRISPR target design. *BMC Biology* 16, 74 (2018). https://doi.org/10.1186/s12915-018-0545-0

FlashFry is a fast, flexible, and comprehensive CRISPR target design tool that scales to analyze entire genomes. It outperforms existing tools in speed while maintaining accuracy, and offers extensive customization for various CRISPR applications. Please visit [FlashFry on GitHub](https://github.com/mckennalab/FlashFry) for more information.

## Contact

For issues or questions, please contact [GitHub: nathanaelandrews](https://github.com/nathanaelandrews)
