instantiate()
using Coverage: process_folder
using Coverage.Codecov: submit
submit(process_folder(pwd()))
