struct Code
    expression::Expr
end

# database import

struct Database{External}
    external::External
end

function named_code(outer, inner)
    name = Name{inner}()
    name, Code(Expr(:call, name, outer))
end

named_tuple(database::Database) =
    partial_map(
        named_code,
        database,
        get_tables(database.external)
    )

# code_insteading

expression_inside(code::Code) = code.expression
expression_inside(something) = something

numbered_argument(number) = Symbol(string("argument", number))
assert_argument(argument, type) = Expr(:(::), argument, type)
call_expression_inside(argument) =
    Expr(:call, expression_inside, argument)

function code_instead(location, a_function, types...)
    arguments = ntuple(numbered_argument, length(types))
    Expr(:function,
        Expr(:call,
            a_function,
            map_unrolled(assert_argument, arguments, types)...
        ),
        Expr(:block,
            location,
            Expr(:call,
                Code,
                Expr(:call,
                    Expr,
                    quot(:call),
                    a_function,
                    map_unrolled(call_expression_inside, arguments)...
                )
            )
        )
    )
end

macro code_instead(a_function, types...)
    code_instead(__source__, a_function, types...) |> esc
end

# function library

function join_model_rows(left, right)
    key1, value1 = model_row(left)
    key2, value2 = model_row(right)
    value1, value2
end

@code_instead backwards Code
translate_call(::typeof(backwards), column) =
    string(translate(column), " DESC")

@code_instead (==) Code Any
@code_instead (==) Any Code
@code_instead (==) Code Code

translate_call(::typeof(==), left, right) =
    string(translate(left), " = ", translate(right))

@code_instead (!=) Code Any
@code_instead (!=) Any Code
@code_instead (!=) Code Code

translate_call(::typeof(==), left, right) =
    string(translate(left), " <> ", translate(right))

@code_instead (!) Code

@code_instead (&) Code Any
@code_instead (&) Any Code
@code_instead (&) Code Code
translate_call(::typeof(&), left, right) =
    string(translate(left), " AND ", translate(right))

@code_instead (|) Code Any
@code_instead (|) Any Code
@code_instead (|) Code Code
translate_call(::typeof(&), left, right) =
    string(translate(left), " OR ", translate(right))

@code_instead By Code Any
function model_row_call(::Type{By}, sorted, a_Key)
    outer_model_row = model_row(sorted)
    a_Key(outer_model_row), outer_model_row
end

@code_instead coalesce Code Vararg{Any}

@code_instead distinct Code
model_row_call(::typeof(distinct), repeated) = model_row(repeated)
translate_call(::typeof(distinct), repeated) =
    replace(translate(repeated), r"\bSELECT\b" => "SELECT DISTINCT")

@code_instead drop Code Integer
model_row_call(::typeof(drop), iterator, number) = model_row(unordered)
translate_call(::typeof(drop), iterator, number) =
    string(translate(iterator), " OFFSET ", number)

@code_instead flatten

model_row_call(::Name{name}, source::Database) where {name} =
    partial_map(named_code, name, get_column_names(source.external, name))

@code_instead Group Code

@code_instead if_else Code Any Any
@code_instead if_else Any Code Any
@code_instead if_else Any Any Code
@code_instead if_else Any Code Code
@code_instead if_else Code Any Code
@code_instead if_else Code Code Any
@code_instead if_else Code Code Code
translate_call(::typeof(ifelse), test, right, wrong) = string(
    "CASE WHEN ",
    translate(test),
    " THEN ",
    translate(right),
    " ELSE ",
    translate(wrong),
    " END"
)

@code_instead in Code Any
@code_instead in Any Code
@code_instead in Code Code
translate_call(::typeof(in), item, collection) =
    string(translate(item), " IN ", collection)

@code_instead InnerJoin Code Code
model_row_call(::Type{InnerJoin}, left, right) = join_model_rows(left, right)

@code_instead isequal Code Any
@code_instead isequal Any Code
@code_instead isequal Code Code

translate_call(::typeof(isequal), left, right) =
    string(translate(left), " IS NOT DISTINCT FROM ", translate(right))

@code_instead isless Code Any
@code_instead isless Any Code
@code_instead isless Code Code

translate_call(::typeof(isless), left, right) =
    string(translate(left), " < ", translate(right))

@code_instead ismissing Code
translate_call(::typeof(ismissing), maybe) =
    string(translate(maybe), " IS NULL")

@code_instead LeftJoin Code Code
model_row_call(::Type{LeftJoin}, left, right) = join_model_rows(left, right)

translate_call(::Name{name}, table) where {name} = name

@code_instead occursin Regex Code
translate_call(::typeof(occursin), needle::String, haystack) = string(
    translate(haystack),
    " LIKE '%",
    needle,
    "%'"
)

@code_instead order Code Any
model_row_call(::typeof(order), unordered, key_function) =
    model_row(unordered)
translate_call(::typeof(order), unordered, key_function) = string(
    translate(unordered),
    " ORDER BY ",
    join(column_or_columns(key_function(model_row(unordered))), ", ")
)

@code_instead OuterJoin Code Code
model_row_call(::Type{OuterJoin}, left, right) = join_model_rows(left, right)

@code_instead over Code Any
model_row_call(::typeof(over), iterator, call) =
    call(model_row(iterator))

@code_instead RightJoin Code Code
model_row_call(::Type{RightJoin}, left, right) = join_model_rows(left, right)

@code_instead (names::Some{Name}) Code
model_row_call(the_names::Some{Name}, iterator) =
    the_names(model_row(iterator))
function translate_call(columns::Some{Name}, data; maybe_distinct = "")
    check_table = value(first(seek_external_tables(data)))
    string(
        "SELECT $maybe_distinct",
        join(map(ignore_name, columns(model_row(data))), ", "),
        " FROM ",
        check_table
    )
end

@code_instead startswith Code Any
@code_instead startswith Any Code
@code_instead startswith Code Code
translate_call(::typeof(startswith), full, prefix) = string(
    translate(full),
    " LIKE '",
    prefix,
    "%'"
)


@code_instead take Code Integer
model_row_call(::typeof(take), iterator, number) = model_row(iterator)
translate_call(::typeof(take), iterator, number) =
    if @capture iterator $drop(inneriterator_, offset_)
        string(
            translate(inneriterator),
            " LIMIT ",
            number,
            " OFFSET ",
            offset
        )
    else
        string(translate(iterator), " LIMIT ", number)
    end

@code_instead to_columns Code
model_row_call(::typeof(to_columns), rows) = model_row(rows)
@code_instead to_rows Code
model_row_call(::typeof(to_rows), columns) = model_row(columns)

@code_instead when Code Any
model_row_call(::typeof(when), iterator, call) = model_row(iterator)
translate_call(::typeof(when), iterator, call) = string(
    translate(iterator),
    " WHERE ",
    translate(call(model_row(iterator)).expression)
)

# utilities

ignore_name((new_name, model)::Tuple{Name, Code}) =
    translate(model.expression)

column_or_columns(row::Some{Named}) = map_unrolled(ignore_name, row)
column_or_columns(code::Code) = (translate(code.expression),)

# SQLite interface

import SQLite
using DataFrames: DataFrame

to_symbols(them) = map_unrolled(Symbol, (them...,))

get_tables(database::SQLite.DB) = to_symbols(SQLite.tables(database).name)
get_column_names(database::SQLite.DB, table_name) =
    to_symbols(SQLite.columns(database, String(table_name)).name)
submit_to(database::SQLite.DB, text) = DataFrame(SQLite.Query(database, text))

# dispatch

seek_external_tables!(tables, something) = nothing
function seek_external_tables!(tables, expression::Expr)
    if @capture expression name_Name(source_Database)
        push!(tables, (source, unname(name)))
    else
        foreach(let tables = tables
            seek_external_tables_capture!(argument) =
                seek_external_tables!(tables, argument)
        end, expression.args)
    end
    nothing
end

function seek_external_tables(expression)
    tables = Set{Tuple{Database, Symbol}}()
    seek_external_tables!(tables, expression)
    tables
end

model_row(expression::Expr) =
    if @capture expression call_(arguments__)
        model_row_call(call, arguments...)
    else
        error("Cannot build a model_row row for $expression")
    end

translate(something) = something
translate(expression::Expr; options...) =
    if @capture expression call_(arguments__)
        translate_call(call, arguments...; options...)
    elseif @capture expression left_ && right_
        translate_call(&, left, right)
    else
        error("Cannot translate code $expression")
    end

# submit

function submit(code::Code)
    expression = code.expression
    submit_to(
        key(first(seek_external_tables(expression))).external,
        translate(expression)
    )
end

# test

using Test

cd("C:/Users/hp/.julia/packages/SQLite/yKARA/test")

database = SQLite.DB("Chinook_Sqlite.sqlite") |> Database |> named_tuple

@test names(@name @> database.Track |>
    (:TrackId, :Name, :Composer, :UnitPrice)(_) |>
    submit) == [:TrackId, :Name, :Composer, :UnitPrice]

@test (@name @> database.Customer |>
    (:City, :Country)(_) |>
    order(_, :Country) |>
    submit).Country[1] == "Argentina"

@test length((@name @> database.Customer |>
    (:City,)(_) |>
    distinct |>
    submit).City) == 53

@test length((@name @> database.Track |>
    (:TrackId, :Name,)(_) |>
    take(_, 10) |>
    submit).Name) == 10

@test first((@name @> database.Track |>
    (:TrackId, :Name,)(_) |>
    drop(_, 10) |>
    take(_, 10) |>
    submit).Name) == "C.O.D."

@test first((@name @> database.Track |>
    (:TrackId, :Name, :Bytes)(_) |>
    order(_, backwards ∘ :Bytes) |>
    submit).Bytes) == 1059546140

@test (@name @> database.Track |>
    (:Name, :Milliseconds, :Bytes, :AlbumId)(_) |>
    when(_, @_ _.AlbumId == 1) |>
    submit).AlbumId[1] == 1

@test (@name @> database.Track |>
    (:Name, :Milliseconds, :Bytes, :AlbumId)(_) |>
    when(_, @_ (_.AlbumId == 1) & (_.Milliseconds > 250000)) |>
    submit).Milliseconds[1] == 343719

@test (@name @> database.Track |>
    (:Name, :AlbumId, :Composer)(_) |>
    when(_, @_ occursin(r".*Smith.*", _.Composer)) |>
    submit).Composer[1] ==
    "F. Baltes, R.A. Smith-Diesel, S. Kaufman, U. Dirkscneider & W. Hoffman"

@test (@name @> database.Track |>
    (:Name, :AlbumId, :MediaTypeId)(_) |>
    when(_, @_ in(_.MediaTypeId, (2, 3))) |>
    submit).MediaTypeId[1] == 2
