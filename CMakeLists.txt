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

set(EXEC_POSTFIX "" CACHE STRING "adds a postfix to generated executable name")
#set name of executable 
SET(SIMPSON_EXEC simpson${EXEC_POSTFIX})
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

option(PREFERED_OPENBLAS "Prefered blas library is OpenBLAS" FALSE)
option(PREFERED_MKL "Prefered blas library is intel MKL" FALSE)
option(PREFERED_GSL "Prefered blas library is GSL" FALSE)
option(PREFERED_ATLAS "Prefered blas library is ATLAS" FALSE)
# add vendor option to switch between intel MKL, OpenBLAS, atlas or GSL

if (PREFERED_MKL)
message(STATUS "looking specifically for intelMKL" )
set (BLA_VENDOR Intel10_64lp)
find_package (BLAS REQUIRED)
endif (PREFERED_MKL)

if (PREFERED_ATLAS)
message(STATUS "looking specifically for ATLAS" )
set (BLA_VENDOR "ATLAS")
find_package (LAPACK REQUIRED)
find_package (BLAS REQUIRED)
endif (PREFERED_ATLAS)

if (PREFERED_OPENBLAS)
message(STATUS "looking specifically for OPENBLAS" )
set (BLA_VENDOR "OpenBLAS")
find_package (LAPACK REQUIRED)
find_package (BLAS REQUIRED)
endif (PREFERED_OPENBLAS)

if (PREFERED_GSL)
message(STATUS "looking specifically for GSL" )
find_package (GSL)
 if (GSL_FOUND)
  MESSAGE("adding -DGSL definition")
  add_definitions (-DGSL)
find_package (LAPACK REQUIRED)
  set(BLAS_LIBRARIES  ${GSL_LIBRARY} ${GSL_CBLAS_LIBRARY})
  set(BLAS_FOUND TRUE)
 endif (GSL_FOUND)
endif (PREFERED_GSL)

if( NOT (PREFERED_OPENBLAS OR PREFERED_OPENBLAS OR PREFERED_OPENBLAS OR PREFERED_ATLAS OR PREFERED_GSL))
message("None of BLAS option active")
find_package (BLAS REQUIRED)
endif( NOT (PREFERED_OPENBLAS OR PREFERED_OPENBLAS OR PREFERED_OPENBLAS OR PREFERED_ATLAS OR PREFERED_GSL))


if (BLAS_FOUND)
message("blas libraries: ${BLAS_LIBRARIES}") 
string(TOLOWER "${BLAS_LIBRARIES}${LAPACK_LIBRARIES}" SEARCH_OPENBLAS)
string(REGEX MATCH openblas FOUND_OPENBLAS "${SEARCH_OPENBLAS}" )
endif (BLAS_FOUND)

if (LAPACK_FOUND)
message(STATUS "lapack libraries : ${LAPACK_LIBRARIES}") 
endif (LAPACK_FOUND)


find_package (TCL REQUIRED)
find_package (Threads REQUIRED)

option(ENABLE_MPI "set to activate MPI" FALSE )
if (ENABLE_MPI)
find_package (MPI)
endif (ENABLE_MPI)

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
  MESSAGE("OPENBLAS found so adding -DOPENBLAS definition to limit number of threads to 1")
  add_definitions (-DOPENBLAS)
endif (FOUND_OPENBLAS)

if (MPI_FOUND)
  include_directories (${MPI_C_INCLUDE_PATH})
  add_definitions (-DMPI)
endif (MPI_FOUND)

option(DEBUG "Debug option activated verbose simpson output" FALSE)
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
message("exec file will be ${SIMPSON_EXEC} ")
