#!/bin/bash
#
# Extract NMOS/PMOS model from MOSIS TestData
#




# SETTINGS
DATADIR="$( dirname $0 )/${1}"
WORK="${DATADIR}/work"

if [ ! -d ${DATADIR} ] || [ "${1}" = "" ]
then
  echo "PATH \"$1\" is not a valid MOSIS data directory!"
  exit 1
else
  echo "Processing \"${DATADIR}\" MOSIS data directory!"
fi

if [ "${2}" = "" ]
then
  TECH="TECH"
else
  TECH="${2}"
fi
echo "Tecnology name set to $TECH!"

# remove workdir
rm -rf ${WORK}

# restore workdir structure
mkdir -p ${WORK}
mkdir -p ${WORK}/pmos_split
mkdir -p ${WORK}/nmos_split
mkdir -p ${WORK}/param_pmos
mkdir -p ${WORK}/param_nmos
mkdir -p ${WORK}/nmos
mkdir -p ${WORK}/pmos
mkdir -p ${WORK}/mod
mkdir -p ${WORK}/altermod


for a in $( ls ${DATADIR}/data )
do
  echo "Extract SPICE model from ${DATADIR}/data/$a:"

  nmosBegin=$( grep -n "MODEL CMOSN NMOS" ${DATADIR}/data/$a | awk -F ":" '{print $1}' )
  nmosEnd=$( grep -n ")" ${DATADIR}/data/$a | tail -n 2 | head -n 1 | awk -F ":" '{print $1}' )
  pmosBegin=$( grep -n "MODEL CMOSP PMOS" ${DATADIR}/data/$a | awk -F ":" '{print $1}' )
  pmosEnd=$( grep -n ")" ${DATADIR}/data/$a | tail -n 1 | awk -F ":" '{print $1}' )

  echo "  - extracting SPICE model from HTML page ..."

  # extract models
  sed -n "${nmosBegin},${nmosEnd}p" ${DATADIR}/data/$a > ${WORK}/nmos/$a
  sed -n "${pmosBegin},${pmosEnd}p" ${DATADIR}/data/$a > ${WORK}/pmos/$a

  # extract models for straight-forward simulation
  modName=$( echo $a | awk -F"_" '{print $1}' )
  sed "s/CMOSN/${modName}_N/g" ${WORK}/nmos/$a > ${WORK}/mod/$a
  echo >> ${WORK}/mod/$a
  echo >> ${WORK}/mod/$a
  sed "s/CMOSP/${modName}_P/g" ${WORK}/pmos/$a >> ${WORK}/mod/$a

  echo "  - split extracted SPICE model parameters ..."
  # split params to occupy single line
  while read -r line
  do
    echo "${line:0:25}" >> ${WORK}/pmos_split/$a
    echo "+${line:26:25}"  >> ${WORK}/pmos_split/$a
    echo "+${line:51}" >> ${WORK}/pmos_split/$a
  done < ${WORK}/pmos/$a

  while read -r line
  do
    echo "${line:0:25}" >> ${WORK}/nmos_split/$a
    echo "+${line:26:25}"  >> ${WORK}/nmos_split/$a
    echo "+${line:51}" >> ${WORK}/nmos_split/$a
  done < ${WORK}/nmos/$a

  echo "  - extract parameter values ..."
  # extract parameters
  cat ${WORK}/pmos_split/$a | grep "^+" | tr -d ")+" | awk 'NF' | awk -F "=" '{print $2}' > ${WORK}/pmos_numbers
  cat ${WORK}/pmos_split/$a | grep "^+" | tr -d ")+" | awk 'NF' | awk -F "=" '{print $1}' > ${WORK}/pmos_names
  cat ${WORK}/nmos_split/$a | grep "^+" | tr -d ")+" | awk 'NF' | awk -F "=" '{print $2}' > ${WORK}/nmos_numbers
  cat ${WORK}/nmos_split/$a | grep "^+" | tr -d ")+" | awk 'NF' | awk -F "=" '{print $1}' > ${WORK}/nmos_names
  
  paste ${WORK}/pmos_names ${WORK}/pmos_numbers | while IFS="$(printf '\t')" read -r name number
  do
      echo "$number" | tr -d " " >> ${WORK}/param_pmos/$name
      
      echo "altermod @${TECH}P[$( echo $name | tr -d " " )] = $( echo "$number" | tr -d " " )" >> ${WORK}/altermod/$a
  done

  paste ${WORK}/nmos_names ${WORK}/nmos_numbers | while IFS="$(printf '\t')" read -r name number
  do
      echo "$number" | tr -d " " >> ${WORK}/param_nmos/$name
      
      echo "altermod @${TECH}N[$( echo $name | tr -d " " )] = $( echo "$number" | tr -d " " )" >> ${WORK}/altermod/$a
  done

  # remove temporary files
  rm ${WORK}/pmos_numbers
  rm ${WORK}/pmos_names
  rm ${WORK}/nmos_numbers
  rm ${WORK}/nmos_names

done

# compute average and std. deviation for all parameters
#
# stdev = sqrt((1/N)*(sum of (value - mean)^2))
# stdev = sqrt((1/N)*((sum of squares) - (((sum)^2)/N)))
echo "Computing statistics: "

for a in $( ls ${WORK}/param_pmos )
do
    filename="${WORK}/param_pmos/$a"
    cntUniq=$( cat $filename | sort | uniq | wc -l )
    cnt=$( cat $filename | wc -l )
    
    echo -ne "  - processing PMOS parameter $a ... "
    # check if parameter varies accros processed models
    if [ "$cntUniq" -le "1" ]
    then
      echo "SKIPPED (no variation)"
      continue
    fi

    sum=$( cat $filename | awk -v PREC=100 '{sum += $1} END {printf "%.30f", sum}' )
    avg=$( cat $filename | awk -v PREC=100 '{sum += $1} END {printf "%.30f", sum/NR}' )
    stdev="$( cat $filename | awk -v PREC=100 '{sum += $1; sumSQ += ($i)^2 } END {printf "%.30f", sqrt((sumSQ-(sum^2)/NR)/NR) }' )"
    lines=$( cat $filename | awk -v PREC=100 'END {printf "%d", NR }' )

    echo "let newParam_${TECH}P_$a = agauss($avg, $stdev)" >> ${WORK}/agauss_p
    echo "echo \"@${TECH}P[$a] = \$&newParam_${TECH}P_$a\"" >> ${WORK}/echo_p
    echo "altermod @${TECH}P[$a] = newParam_${TECH}P_$a"   >> ${WORK}/altermod_p

    echo "EXTRACTED"
done

for a in $( ls ${WORK}/param_nmos )
do
    filename="${WORK}/param_nmos/$a"
    cntUniq=$( cat $filename | sort | uniq | wc -l )
    cnt=$( cat $filename | wc -l )
    
    echo -ne "  - processing NMOS parameter $a ... "
    # check if parameter varies accros processed models
    if [ "$cntUniq" -le "1" ]
    then
      echo "SKIPPED (no variation)"
      continue
    fi

    sum=$( cat $filename | awk -v PREC=100 '{sum += $1} END {printf "%.30f", sum}' )
    avg=$( cat $filename | awk -v PREC=100 '{sum += $1} END {printf "%.30f", sum/NR}' )
    stdev="$( cat $filename | awk -v PREC=100 '{sum += $1; sumSQ += ($i)^2 } END {printf "%.30f", sqrt((sumSQ-(sum^2)/NR)/NR) }' )"
    lines=$( cat $filename | awk -v PREC=100 'END {printf "%d", NR }' )

    echo "let newParam_${TECH}N_$a = agauss($avg, $stdev)" >> ${WORK}/agauss_n
    echo "echo \"@${TECH}N[$a] = \$&newParam_${TECH}N_$a\"" >> ${WORK}/echo_n
    echo "altermod @${TECH}N[$a] = newParam_${TECH}N_$a"   >> ${WORK}/altermod_n
    
    echo "EXTRACTED"
done
