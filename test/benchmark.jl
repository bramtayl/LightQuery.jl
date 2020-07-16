using CSV: File
using DataFrames: by, DataFrame
using LightQuery: @>, @_, By, Group, over, make_columns, @name_str, Rows, value
import Base: NamedTuple

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

function process_with_lightquery(file)
    @> file |>
    NamedTuple |>
    # as soon as an unstable column is added, performance goes out the window...
    (name"Column1", name"Column2", name"Column3")(_) |>
    Rows(; _...) |>
    Group(By(_, name"Column1")) |>
    over(_, @_ (Count = length(value(_)),)) |>
    make_columns
end

@time process_with_dataframes_meta(file)

function process_with_dataframes_meta(file)
    subset = DataFrame(file)[:, [:Column1]]
    by(subset, :Column1, :Column1 => length)
end

@time process_with_dataframes_meta(file)
