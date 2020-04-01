# Open CMOS SPICE Model Collections
  * This repository aims to deliver an open CMOS SPICE model collections (see detailed description below)
  * This repository aggregates wafer-related data originally provided by MOSIS in the form of technical reports
    * historically, MOSIS provided "electrical test data and SPICE parameters from MOSIS measurements on most MPW (multi-project wafer) runs"
    * the reports contain results obtained by MOSIS from measurements of MOSIS test structures on wafers 
    * SPICE parameters obtained from similar measurements on a selected wafer are also attached
    * the origin of the oldest reports goes back to 2001, so the provided data are currently a bit outdated, but they still provide a valuable study material available to anyone
    * some of the reports can be found online on several places (private webpages of educators, etc.)

  * After removing those reports from the MOSIS webpages, the most complete collection of those MOSIS data available online was offered by the [WebArchive](https://web.archive.org)
    * the content of this repository comes from there
    * many original files were not archived by [WebArchive](https://web.archive.org), but more than 30% of original files is now available for every technology here (and also on the [WebArchive](https://web.archive.org))

  * This repository provides simple postprocessing of MOSIS reports and offers:
    * ngSPICE-ready models extracted from HTML pages
    * computed Gaussian Distribution parameters for available model parameters (note, that Gaussian Distributions are not constrained, thus parameters generated this way may - sometimes - lead to misleading results)
    * ngSPICE-ready "altermod" structures for usage in MonteCarlo simulation
    
# Data Collections
  * This repository contains 4 collections of open data for IBM technology nodes:
    * [IBM90nm](MOSIS_waferTestData_IBM_90nm) - 7 reports; no SPICE models available
    * [IBM130nm](MOSIS_waferTestData_IBM_130nm) - 67 reports
    * [IBM180nm](MOSIS_waferTestData_IBM_180nm) - 125 reports
    * [IBM250nm](MOSIS_waferTestData_IBM_250nm) - 14 reports
  * This repository contains 1 collection of open data for TSMC technology node:
    * [TSMC180nm](MOSIS_waferTestData_TSMC_180nm) - 36 reports

## Data Collection Basic Structure
  * every collection is located in its directory
  * the directory structure is as follows:
    * data - directory containing report files itself
    * README.md - file contains notes related to the collection
    * the HTML file is the original MOSIS website containing the list of all reports originally provided in the collection

## Data Collection Purpose
  * the main aim of this repository is to deliver an open CMOS model collection allowing to produce replicable results
    * this model collection may potentially replace proprietary models (under NDA) used in many publications. Especially in the case where e.g. the first-round evaluation of new CMOS structure is provided
    * this collection represents data for technology nodes, whose are still relevant for certain product families (e.g. embedded/low power devices)
  * model collections from this repository allow performing Monte Carlo simulation with real and open CMOS models
    * the collections allow "to get some idea" about how the CMOS-based circuit behaves when (real) manufacturing variations are taken into account
    * no real corner-like simulation is possible, because detailed information about manufacturing processes are not publicly available (or known to us - we just have some real-data reports) - thus **to get some idea** is currently the right characteristic
  
## Data Collection Limitations/Controversies
 * Currently, we don't know how representative are the data collections
   * obtained model parameter distributions are a subset of real distributions (coming from manufactured wafers (MPWs)!), however technology corner cases may be far away - true corner simulation is not possible
 * BSIM3v1 models are relatively old - today BSIM3v2/3v3 are used
 * Gaussian distributions may sometime generate nonsensical parameters 
   * for now, we include no constraints
   * e.g. "DROUT" should be always positive, however, the random process - based on average and deviation - sometimes generates negative value
   * this could be solved by the simulator (assertion/BSIM model parameter checks/constraints), by user-defined in-simulation checks or by manual results inspection
 
# Data Collection Processing
  * MOSIS reports were originally provided in the form of HTML pages
  * the bash script "extractModels.sh" extracts useful model-related data from original reports
    * it generates a "work" directory in the collection directory, where all output files are stored
    * it accepts two parameters:
      * the 1st parameter is the name of the report collection (e.g. "MOSIS_waferTestData_IBM_90nm")
      * the 2nd parameter is the technology name, which is used for naming models and variables in generated data (e.g "IBM90nm")
      * the data collection must be placed in the same directory as the "extractModels.sh"
    * "extractModels.sh" requires standard UNIX tools like sed, awk, ...
  
## The Single Collection Generated "work" Directory Structure
  * directories contain models data in different arrangements:
    * nmos - directory containing extracted NMOS SPICE models (one file per original report)
    * pmos - directory containing extracted PMOS SPICE models (one file per original report)
    * mod - directory containing extracted SPICE NMOS/PMOS models (one file per original report)
    * nmos_split - directory containing extracted NMOS SPICE models with parameters placed one per line (one file per original report)
    * pmos_split - directory containing extracted PMOS SPICE models with parameters placed one per line (one file per original report)
  
  * files and directories containing resources for use in the ngSPICE Monte Carlo simulation flow:
    * altermod - directory files (one per original report) contain altermod commands allowing to use these file as the direct input for MC simulation
    * agaus_n - file contains Gaussian distribution description for all relevant NMOS parameters
    * agaus_p - file contains Gaussian distribution description for all relevant PMOS parameters
    * altermod_n - file contains altermod command for all relevant NMOS parameters
    * altermod_p - file contains altermod command for all relevant PMOS parameters
    * echo_n - file contains echo command for printing NMOS parameter values 
    * echo_p - file contains echo command for printing PMOS parameter values
    
  * intermediate (helper) files (may be useful for further analyzes):
    * param_nmos - directory containing extracted NMOS SPICE model parameters from all reports (one file per SPICE parameter)
    * param_pmos - directory containing extracted PMOS SPICE model parameters from all reports (one file per SPICE parameter)
  
## Usage Example
  * to process available IBM data (generate "work" directories for all collections):

```bash
$ bash extractModels.sh MOSIS_waferTestData_IBM_130nm IBM130nm
$ bash extractModels.sh MOSIS_waferTestData_IBM_180nm IBM180nm
$ bash extractModels.sh MOSIS_waferTestData_IBM_250nm IBM250nm
```

  * to process available TSMC data:

```bash
$ bash extractModels.sh MOSIS_waferTestData_TSMC_180nm TSMC180nm
```

# ngSPICE Examples

  * using extracted SPICE models directly for simulations to exercise the circuit with all available models (in ngSPICE):

```spice
* # of runs for MonteCarlo simulation with TSMC180nm
let mc_runs = 36

...

dowhile run <= mc_runs
    setplot $vars
    * first run with nominal parameters
    if run > 0
      * select model based on SOMECONDITION
      if SOMECONDITION = 1
        .include ./mc_models/t4bk_lo_epi-params.txt
      end
      if SOMECONDITION = 2
        .include ./mc_models/t4bk_mm_non_epi-params.txt
      end
      
      ...
      
      if SOMECONDITION > 35
        .include ./mc_models/t92y_mm_non_epi_thk_mtl-params.txt
      end
    end
 
    ...
    
end
```

  * using Gaussian Distributions obtained from available data collection to exercise the circuit in a classical MonteCarlo simulation:

```spice
* # of runs for MonteCarlo simulation with TSMC180nm
let mc_runs = 36

...

* define agauss function used in agauss_p/agauss_n
define agauss(nom, avar) (nom + avar * sgauss(0))

dowhile run <= mc_runs
    setplot $vars
    * first run with nominal parameters
    if run > 0
      * generate new parameters only if SOMECONDITION holds
      if SOMECONDITION
        echo "Generating new MC model parameters: "
        * parameters are stored to variables
        .include ./mc_gauss/agauss_p
        .include ./mc_gauss/agauss_n
        
        * Echo new parameters once here
        .include ./mc_gauss/echo_p
        .include ./mc_gauss/echo_n
      end
        * change used model parameters - variables are used as altermod parameters
        .include ./mc_gauss/altermod_p
        .include ./mc_gauss/altermod_n
    end
    
    ...
    
end
```

# License
  * MOSIS Wafer Test Data come (originally) from [MOSIS webpages](https://www.mosis.com/), later they were removed, however, some of them are still available through several webpages (namely [WebArchive](https://web.archive.org)). As deduced from the archived MOSIS webpages, at the time of publication, the data were simply provided "as is" to anyone. We assume, that mentioning MOSIS as the data source is appropriate.
  
  * This collection itself and the content added by the collection authors is released under the (MIT-like) University of Illinois/NCSA Open Source License. See the [LICENSE](LICENSE) file.

# Papers
This repository has been originally created to support the research described in the following paper:
  * [A] Bělohoubek, J.; Fišer, P.; Schmidt, J.: “Standard Cell Tuning Enables Data-Independent Static Power Consumption”. In: IEEE 23rd International Symposium on Design and Diagnostics of Electronic Circuits and Systems (DDECS 2020).
 
**If you use data released in the project repository for your research, please include the mentioned paper into the list of references.**
  
# Additional Comments
  * the [author](https://users.fit.cvut.cz/~belohja4/) would be grateful for any comments related to this repository.
  
