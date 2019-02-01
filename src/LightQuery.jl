module LightQuery

# re-export CSV
import CSV
export CSV
using Base: diff_names, SizeUnknown, HasEltype, HasLength, HasShape, Generator, promote_op, EltypeUnknown, StepRange, @propagate_inbounds, _collect, @default_eltype
import Base: iterate, IteratorEltype, eltype, IteratorSize, axes, size, length, IndexStyle, getindex, setindex!, push!, similar, merge, view, isless, setindex_widen_up_to, collect, empty, push_widen, getproperty, _nt_names
import IterTools: @ifsomething
using MacroTools: @capture
using Base.Meta: quot
using Base.Iterators: product, flatten, Zip, Filter
using MappedArrays: mappedarray
import DataFrames: DataFrame

include("Nameless.jl")
include("Unzip.jl")
include("iterators.jl")

export pretty
"""
    pretty(x)

Pretty display.

```jldoctest
julia> using LightQuery

julia> pretty((a = [1, 2], b = [1.0, 2.0]))
2×2 DataFrames.DataFrame
│ Row │ a     │ b       │
│     │ Int64 │ Float64 │
├─────┼───────┼─────────┤
│ 1   │ 1     │ 1.0     │
│ 2   │ 2     │ 2.0     │
```
"""
pretty(x) = DataFrame(; x...)

export Name
"""
    Name(x)

Force into the type domain. Can also be used as a function.

```jldoctest
julia> using LightQuery

julia> Name(:a)((a = 1,))
1
```
"""
struct Name{N} end
@inline Name(N) = Name{N}()
@inline inner_name(n::Name{N}) where N = N
@inline inner_name(x) = x
(::Name{N})(x) where N = getproperty(x, N)

@inline function get_names(data, names...)
    @inline inner(name) = getproperty(data, inner_name(name))
    map(inner, names)
end

@inline set_names(data::Tuple, names...) = NamedTuple{inner_name.(names)}(data)

export named_tuple
"""
    named_tuple(x)

Coerce to a `named_tuple`. For performance with working with arbitrary structs,
explicitly define public `propertynames`.

```jldoctest
julia> using LightQuery

julia> Base.propertynames(p::Pair) = (:first, :second);

julia> named_tuple(:a => 1)
(first = :a, second = 1)
```
"""
function named_tuple(x)
    names = propertynames(x)
    set_names(get_names(x, names...), names...)
end

export transform
"""
    transform(data; assignments...)

Merge `assignments` into `data`.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred transform((a = 1, b = 2.0), c = "3")
(a = 1, b = 2.0, c = "3")
```
"""
transform(data::NamedTuple; assignments...) =
    merge(data, assignments)

export gather
"""
    gather(data, name, names...)

Gather all the data in `names` into a single `name`. Inverse of
[`spread`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = gather(x, :d, :a, :c);

julia> @inferred test((a = 1, b = 2.0, c = "c"))
(b = 2.0, d = (a = 1, c = "c"))
```
"""
@inline gather(data, name, names...) = merge(
    remove(data, names...),
    set_names((select(data, names...),), name)
)

export spread
"""
    spread(data::NamedTuple, name)

Unnest nested data in `name`. Inverse of [`gather`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = spread(x, :d);

julia> @inferred test((b = 2.0, d = (a = 1, c = "c")))
(b = 2.0, a = 1, c = "c")
```
"""
@inline spread(data, name) = merge(
    remove(data, name),
    getproperty(data, name)
)

export select
"""
    select(data::NamedTuple, names...)

Select `names`.

    select(ss::Symbol...)

Curried form.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = select(x, :a);

julia> @inferred test((a = 1, b = 2.0))
(a = 1,)

julia> test(x) = select(:a)(x);

julia> @inferred test((a = 1, b = 2.0))
(a = 1,)
```
"""
@inline select(data, names...) =
    set_names(get_names(data, names...), names...)

@inline function select(ss::Symbol...)
    @inline inner(x) = select(x, ss...)
end

export remove
"""
    remove(data, names...)

Remove `names`. Inverse of [`transform`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = remove(x, :b);

julia> @inferred test((a = 1, b = 2.0))
(a = 1,)
```
"""
@inline remove(data, names...) =
    select(data, diff_names(propertynames(data), names)...)

export rename
"""
    rename(data; renames...)

Rename data. Currently unstable without [`Name`](@ref)

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = rename(x, c = Name(:a));

julia> @inferred test((a = 1, b = 2.0))
(b = 2.0, c = 1)
```
"""
@inline function rename(data; renames...)
    old_names = inner_name.(Tuple(renames.data))
    new_names = propertynames(renames.data)
    merge(
        remove(data, old_names...),
        set_names(get_names(data, old_names...), new_names...)
    )
end

export in_common
"""
    in_common(data1, data2)

Find the names in common between `data1` and `data2`.

```jldoctest
julia> using LightQuery

julia> in_common((a = 1, b = 2.0), (a = 1, c = 3.0))
(:a,)
```
"""
@inline in_common(data1, data2) = diff_names(propertynames(data1), diff_names(propertynames(data1), propertynames(data2)))

export rows
"""
    rows(n::NamedTuple)

Iterator over rows of a `NamedTuple` of names. Inverse of [`columns`](@ref).

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> @inferred first(rows((a = [1, 2], b = [2, 1])))
(a = 1, b = 2)
```
"""
function rows(x)
    names = propertynames(x)
    Generator(NamedTuple{propertynames(x)}, zip(get_names(x, names...)...))
end

export columns
"""
    columns(it, names...)

Collect into columns. Inverse of [`rows`](@ref). Unfortunately, you must specity names;
sometimes, `autocolumns` will be able to detect them for you and run
column-wise optimizations.

```jldoctest
julia> using LightQuery

julia> using Test: @inferred

julia> test(x) = columns(x, :b, :a);

julia> @inferred test([(a = 1, b = 1.0)])
(b = [1.0], a = [1])
```
"""
@inline function columns(it, names...)
    typed_names = Name.(names)
    @inline inner(x) = get_names(x, typed_names...)
    set_names(unzip(Generator(inner, it), length(typed_names)), names...)
end

export autocolumns
"""
    autocolumns(it)

Instead of using [`columns`](@ref), you can use `autocolumns` to convert an iterator to
named-tuple form. You need not specify names, but this function is fragile because it relies on
inference.

```jldoctest
julia> using LightQuery

julia> autocolumns([(a = 1, b = 1.0), (a = 2, b = 2.0)])
(a = [1, 2], b = [1.0, 2.0])

julia> autocolumns(rows((a = [1, 1.0], b = [2, 2.0])))
(a = [1.0, 1.0], b = [2.0, 2.0])
```
"""
autocolumns(x) = columns(x, item_names(x)...)

@inline item_names(g::Generator{I, F} where {I, F <: Type{T} where T <: NamedTuple}) = _nt_names(g.f)
@inline item_names(f::Filter) = item_names(f.itr)
@inline item_names(x) = item_names(x, IteratorEltype(x))
@inline item_names(x, ::HasEltype) = _nt_names(eltype(x))
@inline item_names(x, ::EltypeUnknown) = _nt_names(@default_eltype(x))
using InteractiveUtils

_nt_names(::Type{Any}) = error("Failed to infer names; try specifying them explicitly")
_nt_names(::Type{Union{}}) = error("Items have no names, likely due to an inner function error. Try `first` to see what's up")
# special cases
@inline autocolumns(g::Generator{It, F} where {It <: Zip, F <: Type{T} where T <: NamedTuple}) =
    g.f(g.iter.is)

@inline function autocolumns(f::Filter{F2, It} where {F2, It <: Generator{It, F} where {It <: Zip, F <: Type{T} where T <: NamedTuple}})
    template = map(f.flt, f.itr)
    map(
        let template = template
            x -> view(x, template)
        end,
        f.itr.f(f.itr.iter.is)
    )
end

export group_by
"""
    group_by(it)

A handy wrapper for grouping.

    @inline function group_by(it, columns...)
        selector = select(columns...)
        collect(Group(By(order(rows(it), selector), selector)))
    end

```jldoctest
julia> using LightQuery

julia> data = (a = [:A, :A, :B, :B], b = [1, 2, 3, 4]);

julia> pair = first(group_by(data, :a));

julia> pair.first
(a = :A,)

julia> autocolumns(pair.second)
(a = Symbol[:A, :A], b = [1, 2])
```
"""
@inline function group_by(it, columns...)
    selector = select(columns...)
    collect(Group(By(order(rows(it), selector), selector)))
end

export summarize
"""
    summarize(it; assignments...)

A handy wrapper for summarizing groups. Assignments will be passed subtables,
and will merge into the grouping keys.

    function summarize(it; assignments...)
        function inner(pair)
            transform(pair.first; map(
                f -> f(pair.second), assignments.data
            )...)
        end
        over(it, inner)
    end

```jldoctest
julia> using LightQuery

julia> grouped = group_by((a = [:A, :A, :B, :B], b = [1, 2, 3, 4]), :a);

julia> summarize(grouped, b = @_ sum(autocolumns(_).b)) |> autocolumns
(a = Symbol[:A, :B], b = [3, 7])
```
"""
function summarize(it; assignments...)
    function inner(pair)
        transform(pair.first; map(
            f -> f(pair.second), assignments.data
        )...)
    end
    over(it, inner)
end

export left_join
"""
    left_join(data1, data2)

Conduct a natural, many-to-one left join by combining several exported
functions.

    function left_join(data1, data2)
        names_in_common = in_common(data1, data2)
        empty_data2_row = map(x -> missing, remove(data2, names_in_common...))
        selector = select(names_in_common...)
        function inner(pair)
            right_row = pair.second
            if right_row === missing
                right_row = empty_data2_row
            end
            over(
                pair.first.second,
                left_row -> merge(left_row, right_row),
            )
        end
        flatten(over(
            LeftJoin(
                By(group_by(data1, names_in_common...), first),
                By(rows(autocolumns(order(rows(data2), selector))), selector)
            ),
            inner
        ))
    end

```jldoctest
julia> using LightQuery

julia> data1 = (a = [:A, :A, :B, :B], b = [1, 2, 3, 4]);

julia> data2 = (a = [:A], c = [1.0]);

julia> columns(left_join(data1, data2), :a, :b, :c)
(a = Symbol[:A, :A, :B, :B], b = [1, 2, 3, 4], c = Union{Missing, Float64}[1.0, 1.0, missing, missing])
```
"""
function left_join(data1, data2)
    names_in_common = in_common(data1, data2)
    empty_data2_row = map(x -> missing, remove(data2, names_in_common...))
    selector = select(names_in_common...)
    function inner(pair)
        right_row = pair.second
        if right_row === missing
            right_row = empty_data2_row
        end
        over(
            pair.first.second,
            left_row -> merge(left_row, right_row),
        )
    end
    flatten(over(
        LeftJoin(
            By(group_by(data1, names_in_common...), first),
            By(rows(autocolumns(order(rows(data2), selector))), selector)
        ),
        inner
    ))
end

end
