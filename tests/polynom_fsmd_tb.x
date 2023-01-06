echo "cleaning..."
rm -rf *.o polynom_fsmd_tb *.cf

echo "compiling..."
ghdl -a --work=polynom_lib polynom_pkg.vhd
ghdl -a --work=polynom_lib polynom_controler.vhd
ghdl -a --work=polynom_lib polynom_datapath.vhd
ghdl -a --work=polynom_lib polynom_fsmd.vhd
ghdl -a --work=polynom_lib polynom_fsmd_tb.vhd
ghdl -e --work=polynom_lib polynom_fsmd_tb
ghdl -r --work=polynom_lib polynom_fsmd_tb  --wave=polynom_fsmd_tb.ghw

echo "viewing..."
gtkwave polynom_fsmd_tb.ghw polynom_fsmd_tb.sav
