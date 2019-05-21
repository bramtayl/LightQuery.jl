import SQLite

get_table_names(database::SQLite.DB) = (SQLite.tables(database).name...,)
get_column_names(database::SQLite.DB, table_name) =
    (SQLite.columns(database, table_name).name...,)

struct ExternalTable{Database}
    database::Database
    name::String
end

function show(io::IO, table::ExternalTable)
    show(io, table.database)
    print(io, ".")
    print(io, table.name)
end

struct ExternalColumn{Table}
    table::Table
    name::String
end

function show(io::IO, column::ExternalColumn)
    show(io, column.table)
    print(io, ".")
    print(io, column.name)
end

get_table(database, table_name) = (
    Name(Symbol(table_name)),
    named_tuple(ExternalTable(database, table_name))
)

function named_tuple(database::SQLite.DB)
    get_table_inner(table_name) = get_table(database, table_name)
    map_unrolled(get_table_inner, get_table_names(database))
end

get_column(table, column_name) = (
    Name(Symbol(column_name)),
    Code(ExternalColumn(table, column_name))
)

function named_tuple(table::ExternalTable)
    get_column_inner(column_name) = get_column(table, column_name)
    map_unrolled(get_column_inner, get_column_names(table.database, table.name))
end

struct Code
    filling
end

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

const NamedCode = Tuple{Vararg{Tuple{Name, Code}}}

over(table::NamedCode, call) =
    Code(Expr(:call, :over, table, unwrap(call(table))))
when(table::NamedCode, call) =
    Code(Expr(:call, :when, table, unwrap(call(table))))
By(table::NamedCode, call) =
    Code(Expr(:call, :By, table, unwrap(call(table))))
order(table::NamedCode, call) =
    Code(Expr(:call, :order, table, unwrap(call(table))))
index(table::NamedCode, call) =
    Code(Expr(:call, :index, table, unwrap(call(table))))

Group(table::NamedCode) = Code(Expr(:call, :Group, table, unwrap(table)))
InnerJoin(table1::NamedCode, table2::NamedCode) =
    Code(Expr(:call, :InnerJoin, unwrap(table1), unwrap(table2)))

to_rows(table::NamedCode) = table
to_columns(table::NamedCode) = table
make_columns(table::NamedCode) = table
flatten(table::NamedCode) = table

cd("C:/Users/hp/.julia/packages/SQLite/yKARA/test")

database = named_tuple(SQLite.DB("Chinook_Sqlite.sqlite"))
table = @name database.Customer
result = @name when(table, code -> code.CustomerId >= 100)
result.filling.args[3]
