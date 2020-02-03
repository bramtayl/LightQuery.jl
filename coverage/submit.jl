if VERSION > v"1.3"
    instantiate()
    using Coverage: process_folder
    using Coverage.Codecov: submit
    submit(process_folder(pwd()))
end
