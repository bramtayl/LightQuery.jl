struct OutsideCode{Outside}
    outside::Outside
    code::Expr
end

# database import

"""
    abstract type OutsideTables{Outside} end

`Outside` must support [`get_table_names`](@ref), [`get_column_names`](@ref), and [`submit_to`](@ref).
"""
struct OutsideTables{Outside}
    outside::Outside
end

struct OutsideTable{Outside}
    outside::Outside
    table_name::Symbol
end

struct OutsideRow{Outside}
    outside::Outside
    table_name::Symbol
end

OutsideRow(outside_table::OutsideTable) =
    OutsideRow(outside_table.outside, outside_table.table_name)

make_outside_table(outside_tables, table_name) =
    Name(table_name), OutsideCode(
        outside_tables.outside,
        Expr(:call, Name(table_name), outside_tables)
    )

named_tuple(outside_tables::OutsideTables) = partial_map(
    make_outside_table,
    outside_tables,
    get_table_names(outside_tables.outside)
)

# code_insteading

function unwrap!(outsides, outside_code::OutsideCode)
    push!(outsides, outside_code.outside)
    outside_code.code
end
unwrap!(outsides, something) = something
function one_outside(a_function, arguments...)
    outsides = Set(Any[])
    unwrapped_arguments = partial_map(unwrap!, outsides, arguments)
    OutsideCode(
        if length(outsides) == 0
            error("No outside")
        elseif length(outsides) > 1
            error("Too many outsides")
        else
            first(outsides)
        end, Expr(:call, a_function, unwrapped_arguments...)
    )
end

numbered_argument(number) = Symbol(string("argument", number))
assert_argument(argument, type) = Expr(:(::), argument, type)
maybe_splat(argument, a_type) =
    if @capture a_type Vararg{AType_}
        Expr(:(...), argument)
    else
        argument
    end

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
                one_outside,
                a_function,
                map_unrolled(maybe_splat, arguments, types)...
            )
        )
    )
end

macro code_instead(a_function, types...)
    code_instead(__source__, a_function, types...) |> esc
end

# function library

@code_instead (==) OutsideCode Any
@code_instead (==) Any OutsideCode
@code_instead (==) OutsideCode OutsideCode
translate_call(::typeof(==), left, right) =
    string(translate(left), " = ", translate(right))

@code_instead (!=) OutsideCode Any
@code_instead (!=) Any OutsideCode
@code_instead (!=) OutsideCode OutsideCode
translate_call(::typeof(!=), left, right) =
    string(translate(left), " <> ", translate(right))

@code_instead (!) OutsideCode
translate_call(::typeof(!), wrong) = string("NOT ", translate(wrong))

@code_instead (&) OutsideCode Any
@code_instead (&) Any OutsideCode
@code_instead (&) OutsideCode OutsideCode
translate_call(::typeof(&), left, right) =
    string(translate(left), " AND ", translate(right))

@code_instead (|) OutsideCode Any
@code_instead (|) Any OutsideCode
@code_instead (|) OutsideCode OutsideCode
translate_call(::typeof(|), left, right) =
    string(translate(left), " OR ", translate(right))

@code_instead backwards OutsideCode
translate_call(::typeof(backwards), column) =
    string(translate(column), " DESC")

@code_instead coalesce OutsideCode Vararg{Any}

@code_instead distinct OutsideCode
translate_call(::typeof(distinct), repeated) =
    replace(translate(repeated), r"\bSELECT\b" => "SELECT DISTINCT")

@code_instead drop OutsideCode Integer
translate_call(::typeof(drop), iterator, number) =
    string(translate(iterator), " OFFSET ", number)

@code_instead if_else OutsideCode Any Any
@code_instead if_else Any OutsideCode Any
@code_instead if_else Any Any OutsideCode
@code_instead if_else Any OutsideCode OutsideCode
@code_instead if_else OutsideCode Any OutsideCode
@code_instead if_else OutsideCode OutsideCode Any
@code_instead if_else OutsideCode OutsideCode OutsideCode
translate_call(::typeof(if_else), test, right, wrong) = string(
    "CASE WHEN ",
    translate(test),
    " THEN ",
    translate(right),
    " ELSE ",
    translate(wrong),
    " END"
)

@code_instead in OutsideCode Any
@code_instead in Any OutsideCode
@code_instead in OutsideCode OutsideCode
translate_call(::typeof(in), item, collection) =
    string(translate(item), " IN ", translate(collection))

@code_instead isequal OutsideCode Any
@code_instead isequal Any OutsideCode
@code_instead isequal OutsideCode OutsideCode

translate_call(::typeof(isequal), left, right) =
    string(translate(left), " IS NOT DISTINCT FROM ", translate(right))

@code_instead isless OutsideCode Any
@code_instead isless Any OutsideCode
@code_instead isless OutsideCode OutsideCode

translate_call(::typeof(isless), left, right) =
    string(translate(left), " < ", translate(right))

@code_instead ismissing OutsideCode
translate_call(::typeof(ismissing), maybe) =
    string(translate(maybe), " IS NULL")

@code_instead LeftJoin OutsideCode OutsideCode
change_row(::Type{LeftJoin}, left, right) = join_model_rows(left, right)

outside_column(outside_row, column_name) =
    Name(column_name), OutsideCode(
        outside_row.outside,
        Expr(:call, Name(column_name), outside_row)
    )

change_row(::Name{table_name}, outside_tables::OutsideTables) where {table_name} =
    partial_map(
        outside_column,
        OutsideRow(outside_tables.outside, table_name),
        get_column_names(outside_tables.outside, table_name)
    )
translate_call(::Name{column_name}, ouside_tables::OutsideTables) where {column_name} =
    string("SELECT * FROM ", column_name)

translate_call(::Name{column_name}, ::OutsideRow) where {column_name} =
    column_name

make_outside_column(outside_table, column_name) =
    Name{column_name}(), OutsideCode(
        outside_table.outside,
        Expr(:call, Name{column_name}(), OutsideRow(outside_table))
    )

model_row(outside_table::OutsideTable) =
    partial_map(
        make_outside_column,
        outside_table,
        get_column_names(outside_table.outside, outside_table.table_name)
    )

@code_instead occursin AbstractString OutsideCode
@code_instead occursin Regex OutsideCode
translate_call(::typeof(occursin), needle::AbstractString, haystack) = string(
    translate(haystack),
    " LIKE '%",
    needle,
    "%'"
)
translate_call(::typeof(occursin), needle::Regex, haystack) = string(
    translate(haystack),
    " LIKE ",
    replace(replace(needle.pattern, r"(?<!\\)\.\*" => "%"), r"(?<!\\)\." => "_")
)
translate_call(::typeof(occursin), needle, haystack) = string(
    translate(haystack),
    " LIKE ",
    translate(needle)
)

@code_instead order OutsideCode Any
translate_call(::typeof(order), unordered, key_function) = string(
    translate(unordered),
    " ORDER BY ",
    join(column_or_columns(key_function(model_row(unordered))), ", ")
)

@code_instead over OutsideCode Any
change_row(::typeof(over), iterator, call) = call(model_row(iterator))
select_as((new_name, model)::Tuple{Name{name}, OutsideCode}) where name =
    string(translate(model.code), " AS ", name)
translate_call(::typeof(over), select_table, call) =
    if @capture select_table name_Name(outsidetables_OutsideTables)
        string(
            "SELECT ",
            join(map_unrolled(select_as, call(model_row(select_table))), ", "),
            " FROM ",
            unname(name)
        )
    else
        error("over can only be called directly on SQL tables")
    end

translate(outside_table::OutsideTable) =
    string("SELECT * FROM ", check_table)

@code_instead startswith OutsideCode Any
@code_instead startswith Any OutsideCode
@code_instead startswith OutsideCode OutsideCode
translate_call(::typeof(startswith), full, prefix::AbstractString) = string(
    translate(full),
    " LIKE '",
    prefix,
    "%'"
)

@code_instead take OutsideCode Integer
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

@code_instead when OutsideCode Any
translate_call(::typeof(when), iterator, call) = string(
    translate(iterator),
    " WHERE ",
    translate(call(model_row(iterator)).code)
)

# utilities

change_row(arbitrary_function, iterator, arguments...) = model_row(iterator)

ignore_name((new_name, model)::Tuple{Name, OutsideCode}) =
    translate(model.code)

column_or_columns(row::Some{Named}) = map_unrolled(ignore_name, row)
column_or_columns(outside_code::OutsideCode) = (translate(outside_code.code),)

# SQLite interface

import SQLite: DB
using DataFrames: DataFrame

to_symbols(them) = map_unrolled(Symbol, (them...,))

get_table_names(database::DB) = to_symbols(SQLite.tables(database).name)
get_column_names(database::DB, table_name) =
    to_symbols(SQLite.columns(database, String(table_name)).name)
submit_to(database::DB, text) = DataFrame(SQLite.Query(database, text))

# dispatch

model_row(code::Expr) =
    if @capture code call_(arguments__)
        change_row(call, arguments...)
    else
        error("Cannot build a model_row row for $code")
    end

translate(something) = something

translate(code::Expr) =
    if @capture code call_(arguments__)
        translate_call(call, arguments...)
    elseif @capture code left_ && right_
        translate_call(&, left, right)
    elseif @capture code left_ | right_
        translate_call(|, left, right)
    elseif @capture code if condition_ yes_ else no_ end
        translate_call(if_else, condition, left, right)
    else
        error("Cannot translate code $code")
    end

# submit

make_columns(outside_code::OutsideCode) =
    submit_to(
        outside_code.outside,
        translate(outside_code.code)
    )

# test

using Test

cd("C:/Users/hp/.julia/packages/SQLite/yKARA/test")

database = DB("Chinook_Sqlite.sqlite") |> OutsideTables |> named_tuple

using Query

@test names(@name @> database.Track |>
    over(_, (:TrackId, :Name, :Composer, :UnitPrice)) |>
    make_columns) == [:TrackId, :Name, :Composer, :UnitPrice]

@test (@name @> database.Customer |>
    over(_, (:City, :Country)) |>
    order(_, :Country) |>
    make_columns).Country[1] == "Argentina"

@test length((@name @> database.Customer |>
    over(_, (:City,)) |>
    distinct |>
    make_columns).City) == 53

@test length((@name @> database.Track |>
    over(_, (:TrackId, :Name,)) |>
    take(_, 10) |>
    make_columns).Name) == 10

@test first((@name @> database.Track |>
    over(_, (:TrackId, :Name,)) |>
    drop(_, 10) |>
    take(_, 10) |>
    make_columns).Name) == "C.O.D."

@test first((@name @> database.Track |>
    over(_, (:TrackId, :Name, :Bytes)) |>
    order(_, backwards ∘ :Bytes) |>
    make_columns).Bytes) == 1059546140

@test length((@name @> database.Track |>
    over(_, (:Name, :Milliseconds, :Bytes, :AlbumId)) |>
    when(_, @_ _.AlbumId == 1) |>
    make_columns).AlbumId) == 10

@test (@name @> database.Track |>
    over(_, (:Name, :Milliseconds, :Bytes, :AlbumId)) |>
    when(_, @_ (_.AlbumId == 1) & (_.Milliseconds > 250000)) |>
    make_columns).Milliseconds[1] == 343719

@test (@name @> database.Track |>
    over(_, (:Name, :AlbumId, :Composer)) |>
    when(_, @_ occursin("Smith", _.Composer)) |>
    make_columns).Composer[1] ==
    "F. Baltes, R.A. Smith-Diesel, S. Kaufman, U. Dirkscneider & W. Hoffman"

@test (@name @> database.Track |>
    over(_, (:Name, :AlbumId, :MediaTypeId)) |>
    when(_, @_ in(_.MediaTypeId, (2, 3))) |>
    make_columns).MediaTypeId[1] == 2
