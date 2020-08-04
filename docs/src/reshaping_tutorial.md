# Reshaping tutorial

For this section, I will use [data from the Global Historical Climatology Network](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/ACW00011604.dly). I got this idea from the [`tidyr` tutorial](https://cran.r-project.org/web/packages/tidyr/vignettes/tidy-data.html). This example assumes you have already worked through the [`Beginner tutorial`](beginner_tutorial.md). Let's take a quick peek at the data.

```jldoctest reshaping
julia> using LightQuery

julia> using Base.Iterators: flatten

julia> using Dates: Date

julia> cd(joinpath(pkgdir(LightQuery), "test"));
```

```jldoctest reshaping
julia> file = open("climate.txt");

julia> line = readline(file)
"ACW00011604194901TMAX  289  X  289  X  283  X  283  X  289  X  289  X  278  X  267  X  272  X  278  X  267  X  278  X  267  X  267  X  278  X  267  X  267  X  272  X  272  X  272  X  278  X  272  X  267  X  267  X  267  X  278  X  272  X  272  X  272  X  272  X  272  X"

julia> close(file)
```

Oh boy this is some messy data. Let's start by parsing the first chunk, which contains within it the year and the month.

```jldoctest reshaping
julia> month_variable = (
            year = parse(Int, SubString(line, 12, 15)),
            month = parse(Int, SubString(line, 16, 17)),
            variable = Symbol(SubString(line, 18, 21))
        )
(year = 1949, month = 1, variable = :TMAX)
```

The next chucks each represent a day. Let's parse a day. `missing` is represented by `-9999`.

```jldoctest reshaping
julia> function get_day(line, day)
            start = 14 + 8 * day
            value = parse(Int, line[start:start + 4])
            (day = day, value =
                if value == -9999
                    missing
                else
                    value
                end
            )
        end;


julia> get_day(line, 1)
(day = 1, value = 289)
```

Now, we can get data for every day of the month.

```jldoctest reshaping
julia> days = Iterators.map((@_ merge(month_variable, get_day(line, _))), 1:31);

julia> first(days)
(year = 1949, month = 1, variable = :TMAX, day = 1, value = 289)
```

Use `Iterators.filter` to remove missing data;

```jldoctest reshaping
julia> days = Iterators.filter((@_ _.value !== missing), days);


julia> first(days)
(year = 1949, month = 1, variable = :TMAX, day = 1, value = 289)
```

Use [`transform`](@ref) a true data and [`remove`](@ref) the old fields.

```jldoctest reshaping
julia> get_date(day) =
        @> day |>
        transform(_, date = Date(_.year, _.month, _.day)) |>
        remove(_, name"year", name"month", name"day");


julia> get_date(first(days)) == (
            variable = :TMAX,
            value = 289,
            date = Date("1949-01-01")
        )
true
```

We can combine these steps to process a whole month.

```jldoctest reshaping
julia> function get_month_variable(line)
            month_variable = (
                year = parse(Int, SubString(line, 12, 15)),
                month = parse(Int, SubString(line, 16, 17)),
                variable = Symbol(SubString(line, 18, 21))
            )
            @> Iterators.map((@_ merge(month_variable, get_day(line, _))), 1:31) |>
            Iterators.filter((@_ _.value !== missing), _) |>
            Iterators.map(get_date, _)
        end;


julia> first(get_month_variable(line)) == (
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
        Iterators.map(get_month_variable, _) |>
        flatten |>
        make_columns |>
        Rows(; _...);

julia> Peek(climate_data)
Showing 4 of 1231 rows
| variable | value |       date |
| --------:| -----:| ----------:|
|    :TMAX |   289 | 1949-01-01 |
|    :TMAX |   289 | 1949-01-02 |
|    :TMAX |   283 | 1949-01-03 |
|    :TMAX |   283 | 1949-01-04 |
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
| variable | value |       date |
| --------:| -----:| ----------:|
|    :TMAX |   289 | 1949-01-01 |
|    :TMIN |   217 | 1949-01-01 |
|    :PRCP |     0 | 1949-01-01 |
|    :SNOW |     0 | 1949-01-01 |
```

Use [`transform`](@ref) to add all the new variables to the day key.

```jldoctest reshaping
julia> spread_variables(day_variables) = transform((date = key(day_variables),);
            Iterators.map(
                (@_ _.variable => _.value),
                value(day_variables)
            )...
        );


julia> spread_variables(day_variables) == (
            date = Date("1949-01-01"),
            TMAX = 289,
            TMIN = 217,
            PRCP = 0,
            SNOW = 0,
            SNWD = 0
        )
true
```

Finally, we can run this reshaping over each day in the data using `Iterators.map`.

```jldoctest reshaping
julia> @> by_date |>
        Iterators.map(spread_variables, _) |>
        Peek
Showing at most 4 rows
|    WT16 |       date | TMAX | TMIN | PRCP | SNOW | SNWD |
| -------:| ----------:| ----:| ----:| ----:| ----:| ----:|
| missing | 1949-01-01 |  289 |  217 |    0 |    0 |    0 |
|       1 | 1949-01-02 |  289 |  228 |   30 |    0 |    0 |
| missing | 1949-01-03 |  283 |  222 |    0 |    0 |    0 |
|       1 | 1949-01-04 |  283 |  233 |    0 |    0 |    0 |
```
