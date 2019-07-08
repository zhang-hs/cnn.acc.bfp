#!/bin/bash
usage()
{
  msg="useage: './run.sh clean' or './run.sh sim'"
  echo -e $msg
  exit 1
}

run()
{
  case $1 in
      "clean" )
        rm_file
        echo -e "INFO: Simulation run files deleted."
        exit 0
      ;;
      "sim")
        rm_file
        rm_file
        bash setup.sh && bash compile.sh && bash elaborate.sh && bash simulate.sh
      ;;
      * )
        usage
      ;;
    esac
}

rm_file()
{
  files_to_remove=(64 ucli.key AN.DB core csrc vcs DVEfiles rd_ddr_op_tb_simv rd_ddr_op_tb_simv.daidir result.bin inter.vpd test.vpd vlogan.log vhdlan.log compile.log elaborate.log simulation.log .vlogansetup.env .vlogansetup.args .vcs_lib_lock scirocco_command.log top.vpd simv simv.daidir vc_hdrs.h hdl.var *.txt)
  for (( i=0; i<${#files_to_remove[*]}; i++ )); do
    file="${files_to_remove[i]}"
    if [[ -e $file ]]; then
      rm -rf $file
    fi
  done
}

if [[ ($1 == "-help" || $1 == "-h") ]]; then
  usage
fi

run $1
