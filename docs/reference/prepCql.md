# Prepares a CQL query from a character vector

Prepares a CQL query from a character vector

## Usage

``` r
prepCql(...)
```

## Arguments

- ...:

  character vectors with cQL commands

## Value

A well formated CQL query

## See also

[`cypher()`](https://patzaw.github.io/neo2R/reference/cypher.md) and
[`readCql()`](https://patzaw.github.io/neo2R/reference/readCql.md)

## Examples

``` r
prepCql(c(
 "MATCH (n)",
 "RETURN n"
))
#> [1] "MATCH (n) RETURN n"
```
