#
#   In slaves we do not need to evaluate spinsys nor par
#

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


proc par {data} {  

}

proc spinsys {data} {  

}
