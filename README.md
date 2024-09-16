# Turtles: Decoders all the way down

Simple helpers and validators to make parsing dynamic data (e.g. JSON) a breeze.

```sh
gleam add turtles@1
```

```gleam
import gleam/dynamic.{type Dynamic}
import gleam/json
import turtles/decode as d
import turtles/validate as v

pub type Flep {
  Flep(foo: Int, bar: String)
}

// Decode a `Dynamic` value into a `Flep` object including validating that
// the `foo` field is at least 10.
fn flep_decoder(obj: Dynamic) -> Result(Flep, List(dynamic.DecodeError)) {
  use foo <- d.decode(obj, dynamic.field("foo", dynamic.int |> v.int_min(10)))
  use bar <- d.decode(obj, dynamic.field("bar", dynamic.string))
  Ok(Flep(foo:, bar:))
}

pub fn main() {
  // Note how such a decoder can directly be used everywhere a
  // `dynamic.Decoder` is expected.
  io.debug(json.decode("{\"foo\": 42, \"bar\": \"baz\"}", flep_decoder))
  // -> Ok(Flep(42, "baz"))

  io.debug(json.decode("{\"foo\": 9, \"bar\": \"baz\"}", flep_decoder))
  // -> Error(UnexpectedFormat([DecodeError("Int >= 10", "9", ["foo"])]))
  // (Note: `UnexpectedFormat` comes from the json library.)
}
```

## Features

Everything is just a [Decoder](https://hexdocs.pm/gleam_stdlib/gleam/dynamic.html#Decoder),
and decoders can be chained to create more elaborate decoders.

For example, one can map a decoded value into another, or add validations.

## Examples

See `test/advanced_test.gleam` for a relatively complex decoding example,
including writing custom decoders and validators.

## Status

The `decode` module is starting to take shape, although real-world feedback is needed.
The validators in the `validate` module are mostly proof-of-concept (although it's pretty
trivial to add other ones).

The nice thing is that because everything is plain decoders, you're not really tied to
this library anyway ;)

## Development

```sh
gleam test  # Run the tests
```

## License

Copyright (C) Martin Poelstra.

MIT license.
