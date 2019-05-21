struct ExternalTable{Database}
    database::Database
    name::Symbol
end

struct Code
    filling::Expr
end

struct TableOperation
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
    TableOperation(ExternalTable(database, table_name))
)

named_tuple(database::SQLite.DB) =
    partial_map(get_table, database, get_table_names(database))

dummy_column(name::Symbol) = Name{name}(), Code(:(row.$name))
dummy_column(::Name{name}) where {name} = Name{name}(), Code(:(row.$name))
dummy_column((name, value)) = dummy_column(name)

TableOperation(table::ExternalTable) =
    TableOperation(
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
operation = row
call = @name @_ rename(_, customer_id = :CustomerId)
function over(operation::TableOperation, call)
    new_result = call(operation.result)
    TableOperation(
        :over,
        (operation, new_result),
        map_unrolled(dummy_column, new_result)
    )
end

function when(operation::TableOperation, call)
    new_result = call(operation.result)
    TableOperation(
        :when,
        (operation, new_result),
        operation.result
    )
end

By(operation::TableOperation, call) =
    TableOperation(
        :By,
        operation,
        (call(operation.model), operation.model)
    )
order(operation::TableOperation, call) =
    TableOperation(
        :order,
        operation,
        call(operation.model)
    )

Group(operation::TableOperation) =
    TableOperation(
        :Group,
        operation,
        operation.model
    )
InnerJoin(operation1::TableOperation, operation2::TableOperation) =
    TableOperation(
        :InnerJoin,
        (operation1, operation2),
        (operation1.model, operation2.model)
    )

to_rows(operation::TableOperation) = operation
to_columns(operation::TableOperation) = operation
make_columns(operation::TableOperation) = operation
flatten(operation::TableOperation) = operation

cd("C:/Users/hp/.julia/packages/SQLite/yKARA/test")

database = named_tuple(SQLite.DB("Chinook_Sqlite.sqlite"))

row = @name database.Customer

@name @> row |>
    when(_, @_ _.CustomerId >= 100)
