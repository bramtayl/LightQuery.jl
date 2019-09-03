using Pkg: instantiate
instantiate()

using Coverage.Codecov: submit, process_folder
submit(process_folder("."))
