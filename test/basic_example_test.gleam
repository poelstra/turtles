import gleam/dynamic.{type Dynamic}
import gleam/json
import gleeunit/should
import turtles/decode as d
import turtles/validate as v

pub type Flep {
  Flep(foo: Int, bar: String)
}

// Uses 'plain' types from `dynamic` to 'prove' that it's just a decoder
fn flep_decoder(obj: Dynamic) -> Result(Flep, List(dynamic.DecodeError)) {
  use foo <- d.decode(obj, dynamic.field("foo", dynamic.int |> v.int_min(10)))
  use bar <- d.decode(obj, dynamic.field("bar", dynamic.string))
  Ok(Flep(foo:, bar:))
}

pub fn basic_example_ok_test() {
  json.decode("{\"foo\": 42, \"bar\": \"baz\"}", flep_decoder)
  |> should.be_ok
  |> should.equal(Flep(42, "baz"))
}

pub fn basic_example_fail_test() {
  json.decode("{\"foo\": 9, \"bar\": \"baz\"}", flep_decoder)
  |> should.be_error
  |> should.equal(
    json.UnexpectedFormat([dynamic.DecodeError("Int >= 10", "9", ["foo"])]),
  )
}
