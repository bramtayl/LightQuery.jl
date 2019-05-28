struct Code
    expression::Expr
end

unwrap(code::Code) = code.expression
unwrap(something) = something

make_argument(number) = Symbol(string("argument", number))
assert_argument(argument, type) = Expr(:(::), argument, type)
unwrap_argument(argument) = Expr(:call, unwrap, argument)

function lift(location, a_function, types...)
    arguments = ntuple(make_argument, length(types))
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
                    map_unrolled(unwrap_argument, arguments)...
                )
            )
        )
    )
end

macro lift(a_function, types...)
    lift(__source__, a_function, types...) |> esc
end

@lift (==) Code Any
@lift (==) Any Code
@lift (==) Code Code

@lift (!=) Code Any
@lift (!=) Any Code
@lift (!=) Code Code

@lift (!) Code

@lift (&) Code Any
@lift (&) Any Code
@lift (&) Code Code

@lift (|) Code Any
@lift (|) Any Code
@lift (|) Code Code

@lift By Code Any

@lift coalesce Code Vararg{Any}

@lift distinct Code
@lift distinct Code Any

@lift Drop

@lift flatten

@lift Group Code

@lift if_else Code Any Any
@lift if_else Any Code Any
@lift if_else Any Any Code
@lift if_else Any Code Code
@lift if_else Code Any Code
@lift if_else Code Code Any
@lift if_else Code Code Code

@lift in Code Any
@lift in Any Code
@lift in Code Code

@lift InnerJoin Code Code

@lift isequal Code Any
@lift isequal Any Code
@lift isequal Code Code

@lift isless Code Any
@lift isless Any Code
@lift isless Code Code

@lift ismissing Code

@lift LeftJoin Code Code

@lift occursin Code Any
@lift occursin Any Code
@lift occursin Code Code

@lift order Code Any

@lift OuterJoin Code Code

@lift over Code Any

@lift RightJoin Code Code

@lift startswith Code Any
@lift startswith Any Code
@lift startswith Code Code

@lift take

@lift to_columns Code
@lift to_rows Code

@lift when Code Any

# coalesce

struct Database{External}
    external::External
end

get_table(database, name) = name, Code(:($database[$name]))

named_tuple(database::Database) =
    partial_map(
        get_table,
        database,
        get_tables(database.external)
    )

model_call(::typeof(when), outer, inner) = build_model(outer)
model_call(::typeof(distinct), outer, inner) = build_model(outer)
model_call(::typeof(distinct), outer) = build_model(outer)
model_call(::typeof(to_rows), outer) = build_model(outer)
model_call(::typeof(to_columns), outer) = build_model(outer)

model_call(::typeof(over), outer, inner) = inner(build_model(outer))
function model_call(::Type{By}, outer, inner)
    outer_model = build_model(outer)
    inner(outer_model), outer_model
end

function join_models(source1, source2)
    key1, value1 = build_model(source1)
    key2, value2 = build_model(source2)
    value1, value2
end

model_call(::Type{InnerJoin}, source1, source2) = join_models(source1, source2)
model_call(::Type{LeftJoin}, source1, source2) = join_models(source1, source2)
model_call(::Type{RightJoin}, source1, source2) = join_models(source1, source2)
model_call(::Type{OuterJoin}, source1, source2) = join_models(source1, source2)

dummy_column(::Name{table_name}, name) where {table_name} =
    get_table(table_name, name)

build_model(expression::Expr) =
    if @capture expression source_Database[name_]
        partial_map(dummy_column, name, get_columns(source.external, name))
    elseif @capture expression call_(args__)
        model_call(call, args...)
    else
        error("Cannot build a model row for $expression")
    end

import SQLite

to_names(them) = map_unrolled(Name ∘ Symbol, (them...,))

get_tables(database::SQLite.DB) = to_names(SQLite.tables(database).name)
get_columns(database::SQLite.DB, table) =
    to_names(SQLite.columns(database, String(unname(table))).name)

cd("C:/Users/hp/.julia/packages/SQLite/yKARA/test")

database = SQLite.DB("Chinook_Sqlite.sqlite") |> Database |> named_tuple

@name @> InnerJoin(
    By(database.Album, :ArtistId),
    By(database.Artist, :ArtistId)
) |>
    over(_, @_ merge(key(_), value(_))) |>
    build_model(_.expression)
