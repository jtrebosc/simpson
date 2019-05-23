#
# CMake Build for SIMPSON
#
cmake_minimum_required (VERSION 2.6.8)

# default build mode
if (NOT CMAKE_BUILD_TYPE)
  set (CMAKE_BUILD_TYPE "Release")
  message ("CMake build mode: Release")
endif (NOT CMAKE_BUILD_TYPE)

project (SIMPSON C)

#set name of executable 
SET(SIMPSON_EXEC simpson)
# lists source .c files
SET(SRC_FILES_C
  allocation.c
  auxmath.c
  averaging.c
  B0inhom.c
  blockdiag.c
  cm.c
  complx.c
  cryst.c
  crystdat.c
  distortions.c
  fft.c
  fidcalc.c
  ftools.c
  ham.c
  iodata.c
  isotopes.c
  lbfgs.c
  main.c
  matrix.c
  OCroutines.c
  pthread_barrier_mac.c
  pulse.c
  readsys.c
  relax.c
  rfprof.c
  rfshapes.c
  sim.c
  simpson.c
  spinach.c
  spinsys.c
  wigner.c
  tclutil.c
  tclcode.c
)

#lists .tcl source files used to generate tclcode.c
SET(SRC_FILES_TCL
simpson.tcl ftools.tcl misc.tcl rfshapes.tcl relax.tcl slave.tcl 
)

# add vendor option to switch between intel MKL, OpenBLAS, atlas or GSL
if(NOT DEFINED ENV{PREFERED_BLAS}  )
 message(STATUS "No PREFERED_BLAS environment variable defined\n\
 You can set PREFERED_BLAS to intelMKL, OPENBLAS, GSL or ATLAS\n\
 cmake will select it if it founds it")
 set(PREFERED_BLAS _ )
else(NOT DEFINED ENV{PREFERED_BLAS}  )
 set(PREFERED_BLAS $ENV{PREFERED_BLAS})
endif(NOT DEFINED ENV{PREFERED_BLAS}  )

if (${PREFERED_BLAS} STREQUAL "intelMKL")
set (BLA_VENDOR Intel10_64lp)
message(STATUS "looking specifically for intelMKL" )
find_package (BLAS REQUIRED)
elseif (${PREFERED_BLAS} STREQUAL "ATLAS")
message(STATUS "looking specifically for ATLAS" )
set (BLA_VENDOR "ATLAS")
find_package (BLAS REQUIRED)
elseif (${PREFERED_BLAS} STREQUAL "OPENBLAS")
message(STATUS "looking specifically for OPENBLAS" )
set (BLA_VENDOR "OpenBLAS")
find_package (BLAS REQUIRED)
elseif (${PREFERED_BLAS} STREQUAL "GSL")
message(STATUS "looking specifically for GSL" )
find_package (GSL)
else(${PREFERED_BLAS} STREQUAL "intelMKL")
find_package (BLAS REQUIRED)
endif(${PREFERED_BLAS} STREQUAL "intelMKL")

if (BLAS_FOUND)
message(STATUS "blas libraries : ${BLAS_LIBRARIES}") 
endif (BLAS_FOUND)

find_package (LAPACK REQUIRED)
if (LAPACK_FOUND)
message(STATUS "lapack libraries : ${LAPACK_LIBRARIES}") 
endif (LAPACK_FOUND)


find_package (TCL REQUIRED)
find_package (Threads REQUIRED)
if (ENV{ENABLE_MPI})
find_package (MPI)
endif (ENV{ENABLE_MPI})

#message(STATUS BLAS_LIBRARIES=${BLAS_LIBRARIES})

#set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror")

# fftw3
find_library (FFTW3_LIBRARIES fftw3)
find_path (FFTW3_INCLUDE_DIRS "fftw3.h" PATH_SUFFIXES "fftw3")
get_filename_component (FFTW3_LIB_DIR "${FFTW3_LIBRARIES}" DIRECTORY)

# nfft3
include (ExternalProject)
ExternalProject_Add (nfft3
  PREFIX nfft3
  URL https://www-user.tu-chemnitz.de/~potts/nfft/download/nfft-3.3.2.tar.gz
  URL_HASH MD5=550737c06f4d6ea6c156800169d8f0d9
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR> --with-fftw3-libdir=${FFTW3_LIB_DIR} --enable-all
  BUILD_COMMAND make
  INSTALL_COMMAND make install
  )
ExternalProject_Get_Property (nfft3 install_dir)
set (NFFT3_INCLUDE_DIRS "${install_dir}/include")
set (NFFT3_LIBRARIES "${install_dir}/lib/libnfft3.a")

include_directories (${NFFT3_INCLUDE_DIRS})
include_directories (${TCL_INCLUDE_PATH})

MESSAGE("blas libs are :  ${BLAS_LIBRARIES}")
string(TOLOWER ${BLAS_LIBRARIES} SEARCH_OPENBLAS)
string(REGEX MATCH openblas FOUND_OPENBLAS ${SEARCH_OPENBLAS} )
if (FOUND_OPENBLAS)
# with openblas one calls a function that 
# sets OPENBLAS_NUM_THREADS through an array entry
  MESSAGE("adding -DOPENBLAS definition")
  add_definitions (-DOPENBLAS)
endif (FOUND_OPENBLAS)

# GSL
if (GSL_FOUND)
  MESSAGE("adding -DGSL definition")
  add_definitions (-DGSL)
endif (GSL_FOUND)
if (MPI_FOUND)
  include_directories (${MPI_C_INCLUDE_PATH})
  add_definitions (-DMPI)
endif (MPI_FOUND)

if (DEBUG)
add_definitions (-DDEBUG)
endif (DEBUG)

if (UNIX)
  add_definitions (-DUNIX)
endif (UNIX)
if (WIN32)
  add_definitions (-DWIN32)
endif (WIN32)

include_directories ("${FFTW3_INCLUDE_DIRS}")
include_directories (${NFFT3_INCLUDE_DIRS})
include_directories (${TCL_INCLUDE_PATH})

#
# Simpson executable
#
ADD_EXECUTABLE (${SIMPSON_EXEC}
${SRC_FILES_C}
)

# generate tclcode.c from .tcl files 
add_custom_command(OUTPUT ${PROJECT_SOURCE_DIR}/tclcode.c
COMMAND bash -c "./zt_make_tclcode.sh"
DEPENDS ${SRC_FILES_TCL}
WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
COMMENT "Generating tclcode.c from ${SRC_FILES_TCL}"
)

add_dependencies (${SIMPSON_EXEC} nfft3)

target_link_libraries (${SIMPSON_EXEC} ${NFFT3_LIBRARIES})
target_link_libraries (${SIMPSON_EXEC} ${TCL_LIBRARY})
target_link_libraries (${SIMPSON_EXEC} ${FFTW3_LIBRARIES})
if (GSL_FOUND)
target_link_libraries (${SIMPSON_EXEC} ${GSL_LIBRARY} ${GSL_CBLAS_LIBRARY})
endif ()
target_link_libraries (${SIMPSON_EXEC} ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES})
if (MPI_FOUND)
target_link_libraries (${SIMPSON_EXEC} ${MPI_LIBRARIES})
endif ()
target_link_libraries (${SIMPSON_EXEC} m )

if (THREADS_HAVE_PTHREAD_ARG)
  target_compile_options (PUBLIC SIMPSON "-pthread")
endif()

if (CMAKE_THREAD_LIBS_INIT)
  target_link_libraries (${SIMPSON_EXEC} "${CMAKE_THREAD_LIBS_INIT}")
endif()
