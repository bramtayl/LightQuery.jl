struct ExternalTable{Database}
    database::Database
    name::Symbol
end

struct Code
    filling::Expr
end

struct ExternalCall
    function_name::Symbol
    arguments
    result
end

import SQLite
get_table_names(database::SQLite.DB) =
    map_unrolled(Symbol, (SQLite.tables(database).name...,))
get_column_names(table::ExternalTable{SQLite.DB}) =
    map_unrolled(Symbol, (SQLite.columns(
        table.database,
        string(table.name)
    ).name...,))

function show(io::IO, table::ExternalTable)
    show(io, table.database)
    print(io, ".")
    print(io, table.name)
end

get_table(database, table_name) = (
    Name{table_name}(),
    ExternalCall(ExternalTable(database, table_name))
)

named_tuple(database::SQLite.DB) =
    partial_map(get_table, database, get_table_names(database))

dummy_column(name::Symbol) = Name{name}(), Code(:(row.$name))
dummy_column(::Name{name}) where {name} = Name{name}(), Code(:(row.$name))
dummy_column((name, value)) = dummy_column(name)

ExternalCall(table::ExternalTable) =
    ExternalCall(
        :query,
        (table,),
        map_unrolled(dummy_column, get_column_names(table))
    )

unwrap(code::Code) = code.filling

getindex(code::Code, a_name::Name) = getindex(unwrap(code), a_name)

==(code1::Code, code2) = Code(Expr(:call, :(==), unwrap(code1), code2))
==(code1, code2::Code) = Code(Expr(:call, :(==), code1, unwrap(code2)))
==(code1::Code, code2::Code) =
    Code(Expr(:call, :(==), unwrap(code1), unwrap(code2)))

!=(code1::Code, code2) = Code(Expr(:call, :(!=), unwrap(code1), code2))
!=(code1, code2::Code) = Code(Expr(:call, :(!=), code1, unwrap(code2)))
!=(code1::Code, code2::Code) =
    Code(Expr(:call, :(!=), unwrap(code1), unwrap(code2)))

isless(code1::Code, code2) = Code(Expr(:call, :<, unwrap(code1), code2))
isless(code1, code2::Code) = Code(Expr(:call, :<, code1, unwrap(code2)))
isless(code1::Code, code2::Code) =
    Code(Expr(:call, :<, unwrap(code1), unwrap(code2)))

startswith(code1::Code, code2) =
    Code(Expr(:call, :startswith, unwrap(code1), code2))
startswith(code1, code2::Code) =
    Code(Expr(:call, :startswith, code1, unwrap(code2)))
startswith(code1::Code, code2::Code) =
    Code(Expr(:call, startswith, unwrap(code1), unwrap(code2)))

occursin(code1::Code, code2) =
    Code(Expr(:call, :occursin, unwrap(code1), code2))
occursin(code1, code2::Code) =
    Code(Expr(:call, :occursin, code1, unwrap(code2)))
occursin(code1::Code, code2::Code) =
    Code(Expr(:call, occursin, unwrap(code1), unwrap(code2)))

in(code1::Code, code2) = Code(Expr(:call, :in, unwrap(code1), code2))
in(code1, code2::Code) = Code(Expr(:call, :in, code1, unwrap(code2)))
in(code1::Code, code2::Code) =
    Code(Expr(:call, :in, unwrap(code1), unwrap(code2)))

ismissing(code::Code) = Code(Expr(:call, :ismissing, unwrap(code)))
isequal(code1::Code, code2) = Code(Expr(:call, :isequal, unwrap(code1), code2))
isequal(code1, code2::Code) = Code(Expr(:call, :isequal, code1, unwrap(code2)))
isequal(code1::Code, code2::Code) =
    Code(Expr(:call, :isequal, unwrap(code1), unwrap(code2)))

if_else(switch, yes, no) = ifelse(switch, yes, no)
if_else(code1::Code, code2, code3) =
    Code(Expr(:if, unwrap(code1), code2, code3))
if_else(code1::Code, code2::Code, code3) =
    Code(Expr(:if, unwrap(code1), unwrap(code2), code3))
if_else(code1::Code, code2, code3::Code) =
    Code(Expr(:if, unwrap(code1), code2, unwrap(code3)))
if_else(code1::Code, code2::Code, code3::Code) =
    Code(Expr(:if, unwrap(code1), unwrap(code2), unwrap(code3)))

export if_else

coalesce(code::Code, next, rest...) = coalesce(code, coalesce(next, rest...))
coalesce(code::Code, next::Code, rest...) = coalesce(
    Expr(:call, coalesce, unwrap(code), unwrap(next)),
    coalesce(rest...)
)

coalesce(code::Code, ::Missing) = code
coalesce(code::Code, next) = coalesce(Expr(:call, coalesce, unwrap(code), next))

!(code::Code) = Expr(:call, :!, code)

(&)(code1::Code, code2) =
    if code2
        code1
    else
        false
    end
(&)(code1, code2::Code) =
    if code1
        true
    else
        code2
    end
(&)(code1::Code, code2::Code) = Code(Expr(:&&, unwrap(code1), unwrap(code2)))

|(code1::Code, code2) =
    if code2
        true
    else
        code1
    end
|(code1, code2::Code) =
    if code1
        true
    else
        code2
    end
|(code1::Code, code2::Code) = Code(Expr(:||, unwrap(code1), unwrap(code2)))

function over(call::ExternalCall, call)
    new_result = call(call.result)
    ExternalCall(
        :over,
        (call, new_result),
        map_unrolled(dummy_column, new_result)
    )
end

function when(call::ExternalCall, call)
    new_result = call(call.result)
    ExternalCall(
        :when,
        (call, new_result),
        call.result
    )
end

distinct(call::ExternalCall) =
    ExternalCall(
        :distinct,
        (call,),
        call.result
    )

function By(call::ExternalCall, call)
    new_result = call(call.model)
    ExternalCall(
        :By,
        (call, new_result),
        (map(dummy_unrolled, new_result), call.model)
    )
end
order(call::ExternalCall, call) =
    ExternalCall(
        :order,
        (call, call(call.model)),
        call.model
    )

Group(call::ExternalCall) =
    ExternalCall(
        :Group,
        call,
        call.model
    )
InnerJoin(call1::ExternalCall, call2::ExternalCall) =
    ExternalCall(
        :InnerJoin,
        (call1, call2),
        (call1.model, call2.model)
    )

LeftJoin(call1::ExternalCall, call2::ExternalCall) =
    ExternalCall(
        :LeftJoin,
        (call1, call2),
        (call1.model, call2.model)
    )

RightJoin(call1::ExternalCall, call2::ExternalCall) =
    ExternalCall(
        :RightJoin,
        (call1, call2),
        (call1.model, call2.model)
    )

OuterJoin(call1::ExternalCall, call2::ExternalCall) =
    ExternalCall(
        :OuterJoin,
        (call1, call2),
        (call1.model, call2.model)
    )

to_rows(call::ExternalCall) = call
to_columns(call::ExternalCall) = call
flatten(call::ExternalCall) = call

cd("C:/Users/hp/.julia/packages/SQLite/yKARA/test")

database = named_tuple(SQLite.DB("Chinook_Sqlite.sqlite"))

@name @> database.tracks |>
    over(_, (:trackid, :name, :composer, :unitprice))

@name @> row |>
    when(_, @_ _.CustomerId >= 100)
