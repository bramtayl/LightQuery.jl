# LightQuery.jl

For an example of how to use this package, see the demo below, which follows the
tutorial [here](https://julia-data-query.readthedocs.io/en/latest/index.html).

```jldoctest
julia> using LightQuery

julia> import CSV

julia> flights =
          @> CSV.read("flights.csv", missingstring = "NA") |>
          named_tuple |>
          remove(_, Symbol(""));

julia> @> flights |>
          rows |>
          when(_, @_ _.month == 1 && _.day == 1);

julia> @> flights |>
          rows |>
          when(_, @_ _.month == 1 || _.month == 2);

julia> @> flights |>
          rows |>
          _[1:10];

julia> @> flights |>
          rows |>
          order_by(_, select(:arr_delay));

julia> @> flights |>
          select(_, :year, :month, :day);

julia> @> flights |>
          remove(_, :year, :month, :day);

julia> @> flights |>
          rename(_, tail_num = :tailnum);

julia> @> flights |>
          transform(_,
            gain = _.arr_delay .- _.dep_delay,
            speed = _.distance ./ _.air_time .* 60
          ) |>
          transform(_,
            gain_per_hour = _.gain ./ (_.air_time / 60)
          );

julia> using Statistics: mean;

julia> mean(skipmissing(flights.dep_delay));

julia> @> flights |>
          rows |>
          order_by(_, select(:tailnum)) |>
          Group |>
          over(_,  @_ transform(_.first,
                    count = length(_.second),
                    distance = column(_.second, :distance) |> skipmissing |> mean,
                    delay = column(_.second, :arr_delay) |> skipmissing |> mean
          )) |>
          columns(_, :tailnum, :count, :distance, :delay);

julia> per_day =
          @> flights |>
          rows |>
          order_by(_, select(:year, :month, :day)) |>
          Group |>
          over(_, @_ transform(_.first, flights = length(_.second))) |>
          columns(_, :year, :month, :day, :flights);

julia> per_month =
          @> per_day|>
          rows |>
          By(_, select(:year, :month)) |>
          Group |>
          over(_, @_ transform(_.first, flights = sum(column(_.second, :flights)))) |>
          columns(_, :year, :month, :flights);

julia> per_year =
          @> per_month |>
          rows |>
          By(_, select(:year)) |>
          Group |>
          over(_, @_ transform(_.first, flights = sum(column(_.second, :flights)))) |>
          columns(_, :year, :flights);

julia> @> flights |>
          select(_, :year, :month, :day, :arr_delay, :dep_delay) |>
          rows |>
          order_by(_, select(:year, :month, :day)) |>
          Group |>
          over(_, @_ transform(_.first,
                    arr = column(_.second, :arr_delay) |> skipmissing |> mean,
                    dep = column(_.second, :dep_delay) |> skipmissing |> mean,
          )) |>
          when(_, @_ _.arr > 30 || _.dep > 30) |>
          columns(_, :year, :month, :day, :arr, :dep);
```


```@index
```

```@autodocs
Modules = [LightQuery]
```
