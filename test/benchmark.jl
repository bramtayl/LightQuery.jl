using LightQuery: @>, @_, By, Group, over, make_columns, @name_str, Rows, value

using CSV: File
using DataFrames: DataFrame, groupby, combine
using Tables: columntable

cd("/home/brandon/benchmark")
download("http://rapidsai-data.s3-website.us-east-2.amazonaws.com/notebook-mortgage-data/mortgage_2000.tgz", "mortgage_2000.tgz")
run(`tar --gzip --extract --file=mortgage_2000.tgz`)
cd("perf")

file = File(
    "Performance_2000Q1.txt",
    delim = '|',
    header = Symbol.(string.("Column", 1:31)),
    missingstrings = ["NULL", ""],
    dateformat = "mm/dd/yyyy",
    truestrings = ["Y"],
    falsestrings = ["N"],
)

# just the type stable ones
columns = (name"Column1", name"Column2", name"Column4", name"Column6", name"Column10", name"Column11", name"Column12")(columntable(file))

function process_with_lightquery(columns)
    @> Rows(; columns...) |>
    Group(By(_, name"Column1")) |>
    Iterators.map((@_ (Count = length(value(_)),)), _) |>
    make_columns
end

@time process_with_lightquery(columns)
