#========================================================================================================================
# Copyright (c) 2017 by Bitvis AS.  All rights reserved.
# You should have received a copy of the license file containing the MIT License (see LICENSE.TXT), if not, 
# contact Bitvis AS <support@bitvis.no>.
#
# UVVM AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH UVVM OR THE USE OR
# OTHER DEALINGS IN UVVM.
#========================================================================================================================

# This file may be called with an argument
# arg 1: Part directory of this library/module

# Overload quietly (Modelsim specific command) to let it work in Riviera-Pro
proc quietly { args } {
  if {[llength $args] == 0} {
    puts "quietly"
  } else {
    # this works since tcl prompt only prints the last command given. list prints "".
    uplevel $args; list;
  }
}

if {[batch_mode]} {
  onerror {abort all; exit -f -code 1}
} else {
  onerror {abort all}
}
#Just in case...
quietly quit -sim   

# Detect simulator
if {[catch {eval "vsim -version"} message] == 0} { 
  quietly set simulator_version [eval "vsim -version"]
  # puts "Version is: $simulator_version"
  if {[regexp -nocase {modelsim} $simulator_version]} {
    quietly set simulator "modelsim"
  } elseif {[regexp -nocase {aldec} $simulator_version]} {
    quietly set simulator "rivierapro"
  } else {
    puts "Unknown simulator. Attempting use use Modelsim commands."
    quietly set simulator "modelsim"
  }  
} else { 
    puts "vsim -version failed with the following message:\n $message"
    abort all
}

if { [string equal -nocase $simulator "modelsim"] } {
  ###########
  # Fix possible vmap bug
  do fix_vmap.tcl 
  ##########
}

# Set up uvvm_vvc_framework_part_path and lib_name
#------------------------------------------------------
quietly set lib_name "uvvm_vvc_framework"
quietly set part_name "uvvm_vvc_framework"
# path from mpf-file in sim
quietly set uvvm_vvc_framework_part_path "../..//$part_name"

# argument number 1
if { [info exists 1] } {
  # path from this part to target part
  quietly set uvvm_vvc_framework_part_path "$1/..//$part_name"
  unset 1
}

# (Re-)Generate library and Compile source files
#--------------------------------------------------
echo "\n\nRe-gen lib and compile $lib_name source\n"
if {[file exists $uvvm_vvc_framework_part_path/sim/$lib_name]} {
  file delete -force  $uvvm_vvc_framework_part_path/sim/$lib_name
}
if {![file exists $uvvm_vvc_framework_part_path/sim]} {
  file mkdir $uvvm_vvc_framework_part_path/sim
}

vlib $uvvm_vvc_framework_part_path/sim/$lib_name
vmap $lib_name $uvvm_vvc_framework_part_path/sim/$lib_name

if { [string equal -nocase $simulator "modelsim"] } {
  set compdirectives "-2008 -suppress 1346 -work $lib_name"
} elseif { [string equal -nocase $simulator "rivierapro"] } {
  set compdirectives "-2008 -nowarn COMP96_0564 -dbg -work $lib_name"
}

echo "\n\n\n=== Compiling $lib_name source\n"
eval vcom  $compdirectives   $uvvm_vvc_framework_part_path/src/ti_vvc_framework_support_pkg.vhd
eval vcom  $compdirectives   $uvvm_vvc_framework_part_path/src/ti_generic_queue_pkg.vhd
eval vcom  $compdirectives   $uvvm_vvc_framework_part_path/src/ti_data_queue_pkg.vhd
eval vcom  $compdirectives   $uvvm_vvc_framework_part_path/src/ti_data_fifo_pkg.vhd
eval vcom  $compdirectives   $uvvm_vvc_framework_part_path/src/ti_data_stack_pkg.vhd
eval vcom  $compdirectives   $uvvm_vvc_framework_part_path/src/ti_uvvm_engine.vhd
