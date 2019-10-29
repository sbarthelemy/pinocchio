# run from a powershell terminal as
# & C:/Vagrant/runcmake.ps1

$ErrorActionPreference = "Stop"
Set-PSDebug -Trace 1

$SourceDir = "C:/Vagrant"
if (Test-Path Env:/GITHUB_ACTIONS) {
  $SourceDir = $Env:GITHUB_WORKSPACE
}
$BuildDir = "$SourceDir/build-win2016"
if (-not (Test-Path -PathType Container $BuildDir)) {
  New-Item -ItemType "directory" -Force -Path "$BuildDir"
}
Set-Location -Path $BuildDir

$BuildType = "Debug"
# pinocchio uses
# * pkg-config to locate eigen3
# * raw cmake to locate boost
#
# Because pinocchio uses boost test as a shared library,
# we need to install the shared version with the same build_type
# (Debug/Release), otherwise the tests will crash.
conan install --install-folder "$BuildDir" -s compiler="Visual Studio" -s compiler.version=15 -s compiler.toolset=v140 -s build_type="$BuildType" --generator pkg_config boost/1.64.0@conan/stable -o boost:shared=True
conan install --install-folder "$BuildDir" -s compiler="Visual Studio" -s compiler.version=15 -s compiler.toolset=v140 -s build_type="$BuildType" --generator pkg_config eigen/3.3.7@conan/stable

# conan creates the .pc files in its install-folder,
# let add it to pkg-config's search path
$Env:PKG_CONFIG_PATH = "$BuildDir"
$BoostRoot = pkg-config --variable=prefix "boost = 1.64.0"

# The Boost_ROOT environment variable is normally ignored by cmake,
# but let remove it to avoid confusion and warnings
if (Test-Path Env:/Boost_ROOT) {
  Remove-Item Env:/Boost_ROOT
}
cmake -G "Visual Studio 15" -T "v140" -DCMAKE_GENERATOR_PLATFORM=x64 -DBOOST_ROOT="$BoostRoot" -DBoost_USE_STATIC_LIBS=OFF -DCMAKE_CXX_STANDARD=11 -DBUILD_WITH_URDF_SUPPORT=OFF -DBUILD_WITH_COLLISION_SUPPORT=OFF -DBUILD_WITH_LUA_SUPPORT=OFF -DBUILD_PYTHON_INTERFACE=OFF -DCMAKE_CXX_FLAGS="/EHsc /bigobj -DBOOST_ALL_NO_LIB -DBOOST_LIB_DIAGNOSTIC" $SourceDir
cmake --build . --config "$BuildType"
cmake --build . --config "$BuildType" --target build_tests
# alter the path to ensure the tests can find boost DLL files
$Env:Path += ";$BoostRoot/bin"
cmake --build . --config "$BuildType" --target RUN_TESTS
