# Reshaping tutorial

For this section, I will use [data from the Global Historical Climatology Network](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/ACW00011604.dly). I got this idea from the [`tidyr` tutorial](https://cran.r-project.org/web/packages/tidyr/vignettes/tidy-data.html). This example assumes you have already worked through the [`Beginner tutorial`](beginner_tutorial.md). Let's take a quick peek at the data.

```jldoctest reshaping
julia> using LightQuery

julia> using Base.Iterators: flatten

julia> using Dates: Date

julia> cd(joinpath(pathof(LightQuery) |> dirname |> dirname, "test"));
```

```jldoctest reshaping
julia> file = open("climate.txt");

julia> line = readline(file)
"ACW00011604194901TMAX  289  X  289  X  283  X  283  X  289  X  289  X  278  X  267  X  272  X  278  X  267  X  278  X  267  X  267  X  278  X  267  X  267  X  272  X  272  X  272  X  278  X  272  X  267  X  267  X  267  X  278  X  272  X  272  X  272  X  272  X  272  X"

julia> close(file)
```

Oh boy this is some messy data. Let's start by parsing the first chunk, which contains within it the year and the month.

```jldoctest reshaping
julia> month_variable = @name (
            year = parse(Int, SubString(line, 12, 15)),
            month = parse(Int, SubString(line, 16, 17)),
            variable = Symbol(SubString(line, 18, 21))
        )
((name"year", 1949), (name"month", 1), (name"variable", :TMAX))
```

The next chucks each represent a day. Let's parse a day. `missing` is represented by `-9999`.

```jldoctest reshaping
julia> function get_day(line, day)
            start = 14 + 8 * day
            value = parse(Int, line[start:start + 4])
            @name (day = day, value =
                if value == -9999
                    missing
                else
                    value
                end
            )
        end;

julia> get_day(line, 1)
((name"day", 1), (name"value", 289))
```

Now, we can get data for every day of the month.

```jldoctest reshaping
julia> days = @> over(1:31, @_ (
            month_variable...,
            get_day(line, _)...
        ));

julia> first(days)
((name"year", 1949), (name"month", 1), (name"variable", :TMAX), (name"day", 1), (name"value", 289))
```

Use [`when`](@ref) to remove missing data;

```jldoctest reshaping
julia> days = @name when(days, @_ _.value !== missing);

julia> first(days)
((name"year", 1949), (name"month", 1), (name"variable", :TMAX), (name"day", 1), (name"value", 289))
```

Use [`transform`](@ref) a true data and [`remove`](@ref) the old fields.

```jldoctest reshaping
julia> get_date(day) =
        @name @> day |>
        transform(_, date = Date(_.year, _.month, _.day)) |>
        remove(_, name"year", name"month", name"day");

julia> get_date(first(days)) == @name (
            variable = :TMAX,
            value = 289,
            date = Date("1949-01-01")
        )
true
```

We can combine these steps to process a whole month.

```jldoctest reshaping
julia> function get_month_variable(line)
            month_variable = @name (
                year = parse(Int, SubString(line, 12, 15)),
                month = parse(Int, SubString(line, 16, 17)),
                variable = Symbol(SubString(line, 18, 21))
            )
            @name @> over(1:31, @_ (
                month_variable...,
                get_day(line, _)...
            )) |>
            when(_, @_ _.value !== missing) |>
            over(_, get_date)
        end;

julia> first(get_month_variable(line)) == @name (
            variable = :TMAX,
            value = 289,
            date = Date("1949-01-01")
        )
true
```

Each line will return several days. Use `flatten` to unnest the data.

```jldoctest reshaping
julia> climate_data =
        @> eachline("climate.txt") |>
        over(_, get_month_variable) |>
        flatten |>
        make_columns |>
        Rows;

julia> Peek(climate_data)
Showing 4 of 1231 rows
| name"variable" | name"value" | name"date" |
| --------------:| -----------:| ----------:|
|          :TMAX |         289 | 1949-01-01 |
|          :TMAX |         289 | 1949-01-02 |
|          :TMAX |         283 | 1949-01-03 |
|          :TMAX |         283 | 1949-01-04 |
```

Let's sort and group the data by date. This will allow us to combine various measures into one row for each date.

```jldoctest reshaping
julia> by_date =
        @> climate_data |>
        order(_, name"date") |>
        Group(By(_, name"date"));

julia> day_variables = first(by_date);

julia> key(day_variables)
1949-01-01

julia> value(day_variables) |> Peek
Showing 4 of 5 rows
| name"variable" | name"value" | name"date" |
| --------------:| -----------:| ----------:|
|          :TMAX |         289 | 1949-01-01 |
|          :TMIN |         217 | 1949-01-01 |
|          :PRCP |           0 | 1949-01-01 |
|          :SNOW |           0 | 1949-01-01 |
```

We can directly convert this group of measurements into a [`named_tuple`](@ref). Do do this, use Use [`Name`](@ref) to make turn variables into true names, and splat the result into a tuple.

```jldoctest reshaping
julia> spread_variables(day_variables) = @name (
            date = key(day_variables),
            over(
                value(day_variables),
                @_ (Name(_.variable), _.value)
            )...
        );

julia> spread_variables(day_variables) == @name (
            date = Date("1949-01-01"),
            TMAX = 289,
            TMIN = 217,
            PRCP = 0,
            SNOW = 0,
            SNWD = 0
        )
true
```

Finally, we can run this reshaping over each day in the data using [`over`](@ref),

```jldoctest reshaping
julia> @> by_date |>
        over(_, spread_variables) |>
        Peek
Showing at most 4 rows
| name"WT16" | name"date" | name"TMAX" | name"TMIN" | name"PRCP" | name"SNOW" | name"SNWD" |
| ----------:| ----------:| ----------:| ----------:| ----------:| ----------:| ----------:|
|    missing | 1949-01-01 |        289 |        217 |          0 |          0 |          0 |
|          1 | 1949-01-02 |        289 |        228 |         30 |          0 |          0 |
|    missing | 1949-01-03 |        283 |        222 |          0 |          0 |          0 |
|          1 | 1949-01-04 |        283 |        233 |          0 |          0 |          0 |
```
