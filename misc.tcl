#   Miscellaneous Tcl routines
#   Copyright (C) 1999 Mads Bak
#
#   This file is part of the SIMPSON General NMR Simulation Package
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version. 
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Given the three principal elements of the chemical shift tensor
# in ppm defined on the shift/spectrometer/deshielding scale,
# returns the isotropic component, the anisotropic component and the asymmetry. 

proc csapar {s1 s2 s3} {
  set iso [expr ($s1+$s2+$s3)/3.0]

  set v [list [expr abs($s1-$iso)] [expr abs($s2-$iso)] [expr abs($s3-$iso)]]
  set a [list $s1 $s2 $s3]
    
  if [expr [lindex $v 0] > [lindex $v 1] ] {
    set v [list [lindex $v 1] [lindex $v 0] [lindex $v 2]]
    set a [list [lindex $a 1] [lindex $a 0] [lindex $a 2]]
  }

  if [expr [lindex $v 1] > [lindex $v 2] ] {
    set v [list [lindex $v 0] [lindex $v 2] [lindex $v 1]]
    set a [list [lindex $a 0] [lindex $a 2] [lindex $a 1]]
  }
  if [expr [lindex $v 0] > [lindex $v 1] ] {
    set v [list [lindex $v 1] [lindex $v 0] [lindex $v 2]]
    set a [list [lindex $a 1] [lindex $a 0] [lindex $a 2]]
  }

  if [expr [lindex $v 1] > [lindex $v 2] ] {
    set v [list [lindex $v 0] [lindex $v 2] [lindex $v 1]]
    set a [list [lindex $a 0] [lindex $a 2] [lindex $a 1]]
  }
  set z [lindex $a 2]
  set y [lindex $a 0]
  set x [lindex $a 1]
  
  set aniso [expr $z-$iso ]
  set eta [expr double($y-$x)/$aniso ];
  return [list $iso $aniso $eta]
}

proc csaprinc {iso aniso eta} {
  set zz [expr $aniso + $iso]
  set xx [expr $iso-$aniso*(1.0+$eta)/2.0]
  set yy [expr $xx + $eta*$aniso]
  return [list $xx $yy $zz]
}


proc putmatrix {m {fm "%9.3g"}} {
   foreach i $m {
     foreach j $i {
        if {[llength $j] == 2} {
          puts -nonewline [format "($fm,$fm) " [lindex $j 0] [lindex $j 1]]
        } else {
          puts -nonewline [format $fm $j]
        }
     }
     puts ""
   }
}



proc contourplot {file xlabel ylabel} {
  set f [open $file.gnu w]
  puts $f "
  set param 
  set view 0,0,1
  set cntrparam bspline
  set cntrparam levels 10
  set nosurface
  set xlabel '$xlabel'
  set ylabel '$ylabel'
  set contour
  set term post
  set output '$file.ps'
  splot '$file' w l
  "
  close $f
  exec gnuplot $file.gnu
  puts "Generated: $file.ps"
}

proc 2dplot {file xlabel ylabel {title {}}} {

  set f [open $file.gnu w]
  puts $f "
  set term post
  set param
  set view 75,20,1
  set contour
  set title  '$title'
  set xlabel '$xlabel'
  set ylabel '$ylabel'
  set output '${file}.ps'
  plot '$file' w l
  "
  close $f
  exec gnuplot $file.gnu
  puts "Generated: ${file}.ps"
}


proc 3dplot {file xlabel ylabel {zrange {}}} {

  set zrng {}
  if {[llength $zrange] == 2} {
     set zrng "set zrange \[[join $zrange :]\]"
  }
  set f [open $file.gnu w]
  puts $f "
  set term post
  set param
  $zrng
  set view 75,20,1
  set contour
  set xlabel '$xlabel'
  set ylabel '$ylabel'
  set output '${file}-3d.ps'
  splot '$file' w l
  "
  close $f
  exec gnuplot $file.gnu
  puts "Generated: ${file}-3d.ps"
}

proc simview {args} {
  puts "Saved files: $args"
}


proc nucNspinsys {N} {
  global spinsys
  set nucs $spinsys(nuclei)
  set num_nucs [llength $nucs]
  if {$num_nucs < $N || $num_nucs <1}  {
    puts "spin_of_spinsys_nuc: nucleus number $N is not between 1 and max nucleus number=$num_nucs"
    exit 1
  }
  return [lindex $nucs [expr $N-1]]
}

proc spin_nucNspinsys {N} {
  set nuc [nucNspinsys $N]
  return [nucspin $nuc]
}

proc nucQIS {nuc Cq eta {n -0.5} {m 0.5}} {
#calculates quadrupolar induced shift from isotope <nuc>, Cq, eta, and transition <n|m>
# CT corresponds to <-0.5|0.5>, ST1 would be <0.5|1.5>
# this requires to know the larmor frequency
  global par
  set I [nucspin $nuc] 
  if {$I == 0.5} {
    puts "Warning $nuc has spin 1/2. QIS is 0"
    return 0
  }
  if  {[array names par -exact proton_frequency] == ""} {
    puts "proton_frequency in par section is required"
    exit 1
  }
  set nu0 [resfreq $nuc $par(proton_frequency)]
  set QIS [expr -pow(3.*$Cq/(2.*$I*(2.*$I-1)),2)*56./(5040.*$nu0)*(3.+$eta*$eta)*($m*($I*($I+1.)-3.*$m*$m)-$n*($I*($I+1.)-3.*$n*$n))]
  return $QIS
}

proc QISspinsys {N {n -0.5} {m 0.5}} {
# calculate QIS for spin N in channel according to quadrupole parameters defined in spinsys  transition <n|m>
#<n|m> default is <-0.5|0.5> corresponding to central transition
  global spinsys
  set nuc [nucNspinsys $N]
  set Cq X
  set eta X
  foreach quad_par [array names spinsys quadrupole] {
    if {[lindex $spinsys($quad_par) 0] == $N} {
      set Cq [lindex $spinsys($quad_par) 2]
      set eta [lindex $spinsys($quad_par) 3]
      break
    }
  }
  if {$Cq == "X"} {
    puts "Warning no quadrupole coupling defined for nucleus $N=$nuc."
    set Cq 0
    set eta 0
  }
  return [nucQIS $nuc $Cq $eta $n $m]
}
