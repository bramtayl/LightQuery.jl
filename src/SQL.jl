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
expression_inside_expression(argument) =
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
                    map_unrolled(expression_inside_expression, arguments)...
                )
            )
        )
    )
end

macro code_instead(a_function, types...)
    code_instead(__source__, a_function, types...) |> esc
end

# function library

build_model_row_call(columns::Some{Name}, data) =
    columns(build_model_row(data))

@code_instead (names::Some{Name}) Code
function translate_code_call(columns::Some{Name}, data; maybe_distinct = "")
    check_table = value(first(seek_external_tables(data)))
    string(
        "SELECT $maybe_distinct",
        join(column_or_columns(check_table, build_model_row_call(columns, data)), ", "),
        " FROM ",
        check_table
    )
end

function join_model_rows(left, right)
    key1, value1 = build_model_row(left)
    key2, value2 = build_model_row(right)
    value1, value2
end

(Descending{Name{name}})(argument1::Code) where {name} =
      Code(Expr, :call, Descending{Name{name}}, expression_inside(argument1))

@code_instead (==) Code Any
@code_instead (==) Any Code
@code_instead (==) Code Code

translate_code_call(::typeof(==), left, right) =
    string(translate_code(left), " == ", translate_code(right))

@code_instead (!=) Code Any
@code_instead (!=) Any Code
@code_instead (!=) Code Code

@code_instead (!) Code

@code_instead (&) Code Any
@code_instead (&) Any Code
@code_instead (&) Code Code

translate_code_call(::typeof(&), left, right) =
    string(translate_code(left), " AND ", translate_code(right))

@code_instead (|) Code Any
@code_instead (|) Any Code
@code_instead (|) Code Code

@code_instead By Code Any
function build_model_row_call(::Type{By}, sorted, a_Key)
    outer_model_row = build_model_row(sorted)
    a_Key(outer_model_row), outer_model_row
end

@code_instead coalesce Code Vararg{Any}

@code_instead distinct Code
build_model_row_call(::typeof(distinct), repeated) = build_model_row(repeated)
translate_code_call(::typeof(distinct), repeated) =
    replace(translate_code(repeated), r"\bSELECT\b" => "SELECT DISTINCT")

@code_instead distinct Code Any

@code_instead drop Code Integer
build_model_row_call(::typeof(drop), iterator, number) =
    build_model_row(unordered)

translate_code_call(::typeof(drop), iterator, number) =
    string(translate_code(iterator), " OFFSET ", number)

@code_instead flatten

build_model_row_call(::Name{name}, source::Database, ) where {name} =
    partial_map(named_code, name, get_column_names(source.external, name))

@code_instead Group Code

@code_instead if_else Code Any Any
@code_instead if_else Any Code Any
@code_instead if_else Any Any Code
@code_instead if_else Any Code Code
@code_instead if_else Code Any Code
@code_instead if_else Code Code Any
@code_instead if_else Code Code Code

@code_instead in Code Any
@code_instead in Any Code
@code_instead in Code Code

@code_instead InnerJoin Code Code
build_model_row_call(::Type{InnerJoin}, left, right) = join_model_rows(left, right)

@code_instead isequal Code Any
@code_instead isequal Any Code
@code_instead isequal Code Code

@code_instead isless Code Any
@code_instead isless Any Code
@code_instead isless Code Code

translate_code_call(::typeof(isless), left, right) =
    string(translate_code(left), " < ", translate_code(right))

@code_instead ismissing Code

@code_instead LeftJoin Code Code
build_model_row_call(::Type{LeftJoin}, left, right) = join_model_rows(left, right)

translate_code_call(::Name{name}, table) where {name} = name

@code_instead occursin Code Any
@code_instead occursin Any Code
@code_instead occursin Code Code

@code_instead order Code Any

build_model_row_call(::typeof(order), unordered, key_function) =
    build_model_row(unordered)
translate_code_call(::typeof(order), unordered, key_function) = string(
    translate_code(unordered),
    " ORDER BY ",
    join(column_or_columns(
        value(first(seek_external_tables(unordered))),
        key_function(build_model_row(unordered))
    ), ", ")
)

@code_instead OuterJoin Code Code
build_model_row_call(::Type{OuterJoin}, left, right) = join_model_rows(left, right)

@code_instead over Code Any
build_model_row_call(::typeof(over), iterator, call) = call(build_model_row(iterator))

@code_instead RightJoin Code Code
build_model_row_call(::Type{RightJoin}, left, right) = join_model_rows(left, right)

@code_instead startswith Code Any
@code_instead startswith Any Code
@code_instead startswith Code Code

@code_instead take Code Integer
build_model_row_call(::typeof(take), iterator, number) = build_model_row(iterator)
translate_code_call(::typeof(take), iterator, number) =
    if @capture iterator $drop(inneriterator_, offset_)
        string(
            translate_code(inneriterator),
            " LIMIT ",
            number,
            " OFFSET ",
            offset
        )
    else
        string(translate_code(iterator), " LIMIT ", number)
    end

@code_instead to_columns Code
build_model_row_call(::typeof(to_columns), rows) = build_model_row(rows)
@code_instead to_rows Code
build_model_row_call(::typeof(to_rows), columns) = build_model_row(columns)

@code_instead when Code Any
build_model_row_call(::typeof(when), iterator, call) = build_model_row(iterator)
translate_code_call(::typeof(when), iterator, call) = string(
    translate_code(iterator),
    " WHEN ",
    translate_code(call(build_model_row(iterator)).expression)
)

# utilities

one_column(check_table, model::Descending) =
    string(one_column(check_table, model.increasing), " DESC")

function one_column(check_table, model)
    expression = model.expression
    if @capture expression oldname_Name(source_)
        if source == check_table
            unname(oldname)
        else
            error("table mismatch between $source and $check_table")
        end
    else
        error("Error parsing simple column $expression")
    end
end

column_or_columns(check_table, model) = (one_column(check_table, model),)

ignore_new_name(check_table, (new_name, model)) =
    one_column(check_table, model)

column_or_columns(check_table, row::Some{Named}) = partial_map(
    ignore_new_name,
    check_table,
    row
)

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

build_model_row(expression::Expr) =
    if @capture expression call_(arguments__)
        build_model_row_call(call, arguments...)
    else
        error("Cannot build a model_row row for $expression")
    end

translate_code(something) = something
translate_code(expression::Expr; options...) =
    if @capture expression call_(arguments__)
        translate_code_call(call, arguments...; options...)
    else
        error("Cannot translate code $expression")
    end

# submit

function submit(code::Code)
    expression = code.expression
    submit_to(
        key(first(seek_external_tables(expression))).external,
        translate_code(expression)
    )
end

# test

cd("C:/Users/hp/.julia/packages/SQLite/yKARA/test")

database = SQLite.DB("Chinook_Sqlite.sqlite") |> Database |> named_tuple
using Test

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
    order(_, Descending ∘ :Bytes) |>
    submit).Bytes) == 1059546140

expression = @name @> database.Track |>
    (:Name, :Milliseconds, :Bytes, :AlbumId)(_) |>
    when(_, @_ _.AlbumId == 1) |>
    _.expression |>
    translate_code

expression = @name @> database.Track |>
    (:Name, :Milliseconds, :Bytes, :AlbumId)(_) |>
    when(_, @_ (_.AlbumId == 1) & (_.Milliseconds > 250000)) |>
    _.expression |>
    translate_code
