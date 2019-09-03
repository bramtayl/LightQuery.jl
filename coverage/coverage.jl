using Pkg: instantiate
instantiate()

using Coverage.Codecov: submit
using Coverage.LCOV: readfolder
submit(readfolder("."))
