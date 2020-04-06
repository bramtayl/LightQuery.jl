using LightQuery: @>, By, Group, @name, make_columns, over, row_info, Rows, value
using CSV: File
import CSV
using DataFrames: by, DataFrame
using Tables: schema
using BenchmarkTools: @btime

cd("/home/brandon/perf")

filename =
    file = File(
        "Performance_2000Q1.txt_0",
        delim = '|',
        header = Symbol.(string.("Column", 1:31)),
        missingstrings = ["NULL", ""],
        dateformat = "mm/dd/yyyy",
        truestrings = ["Y"],
        falsestrings = ["N"],
    )

function process_with_lightquery(file)
    Line = row_info(schema(file))

    @name @> file |>
             over(_, @_ (:Column1,)(Line(_))) |>
             make_columns |>
             Rows |>
             Group(By(_, :Column1)) |>
             over(_, @_ (Count = length(value(_)),)) |>
             make_columns
end

println("LightQuery")
@btime process_with_lightquery(file)

function process_with_dataframes_meta(file)
    by(DataFrame(file), :Column1, :Column1 => length)
end

println("DataFrames")
@btime process_with_dataframes_meta(file)
