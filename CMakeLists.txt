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

find_package (BLAS REQUIRED)
find_package (LAPACK REQUIRED)
find_package (TCL REQUIRED)
find_package (Threads REQUIRED)
find_package (GSL)
find_package (MPI)

#set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror")

# fftw3
find_library (FFTW3_LIBRARIES fftw3)
find_path (FFTW3_INCLUDE_DIRS "fftw3.h" PATH_SUFFIXES "fftw3")
include_directories ("${FFTW3_INCLUDE_DIRS}")
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
include_directories ("${NFFT3_INCLUDE_DIRS}" ${TCL_INCLUDE_PATH})

# GSL
if (GSL_FOUND)
  add_definitions (-DGSL)
endif ()
if (MPI_FOUND)
  include_directories (${MPI_C_INCLUDE_PATH})
  add_definitions (-DMPI)
endif ()

if (UNIX)
  add_definitions (-DUNIX)
endif (UNIX)
if (WIN32)
  add_definitions (-DWIN32)
endif (WIN32)

#
# Simpson executable
#
add_executable (SIMPSON
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
  tclcode.c
  tclutil.c
  wigner.c)

target_link_libraries (SIMPSON ${NFFT3_LIBRARIES})
target_link_libraries (SIMPSON ${TCL_LIBRARY})
target_link_libraries (SIMPSON ${FFTW3_LIBRARIES})
target_link_libraries (SIMPSON ${GSL_LIBRARY} ${GSL_CBLAS_LIBRARY})
target_link_libraries (SIMPSON ${BLAS_LIBRARIES} ${LAPACK_LIBRARIES})
target_link_libraries (SIMPSON ${MPI_LIBRARIES})
target_link_libraries (SIMPSON m )
add_dependencies (SIMPSON nfft3)
if (THREADS_HAVE_PTHREAD_ARG)
  target_compile_options (PUBLIC SIMPSON "-pthread")
endif()
if (CMAKE_THREAD_LIBS_INIT)
  target_link_libraries (SIMPSON "${CMAKE_THREAD_LIBS_INIT}")
endif()
