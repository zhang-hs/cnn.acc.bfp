#!/bin/bash

files_to_remove=(64 ucli.key AN.DB core csrc vcs DVEfiles simv simv.daidir inter.vpd vlogan.log vhdlan.log compile.log elaborate.log simulate.log .vlogansetup.env .vlogansetup.args .vcs_lib_lock scirocco_command.log top.vpd board.vpd)
for (( i=0; i<${#files_to_remove[*]}; i++ )); do
  file="${files_to_remove[i]}"
  if [[ -e $file ]]; then
    rm -rf $file
  fi
done
