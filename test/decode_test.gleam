import gleam/dict
import gleam/dynamic
import gleam/option
import gleam/string
import gleeunit/should
import turtles/decode as d

pub fn map_test() {
  let uppercase_string = dynamic.string |> d.map(string.uppercase)
  uppercase_string(dynamic.from("foo")) |> should.be_ok |> should.equal("FOO")
}

pub fn try_map_test() {
  let two_options =
    dynamic.string
    |> d.try_map(fn(value) {
      case value {
        "foo" | "bar" -> Ok(value)
        _ ->
          Error([
            dynamic.DecodeError(expected: "foo or bar", found: value, path: []),
          ])
      }
    })

  // Ok
  two_options(dynamic.from("foo")) |> should.be_ok |> should.equal("foo")

  // Error
  two_options(dynamic.from("flep"))
  |> should.be_error
  |> should.equal([dynamic.DecodeError("foo or bar", "flep", [])])
}

pub fn optional_nullable_field_test() {
  dict.new()
  |> dict.insert("foo", "bar")
  |> dynamic.from
  |> d.optional_nullable_field(named: "foo", of: dynamic.string)
  |> should.be_ok
  |> should.equal(option.Some("bar"))

  dict.new()
  |> dict.insert("foo", option.None)
  |> dynamic.from
  |> d.optional_nullable_field(named: "foo", of: dynamic.string)
  |> should.be_ok
  |> should.equal(option.None)

  dict.new()
  |> dynamic.from
  |> d.optional_nullable_field(named: "foo", of: dynamic.string)
  |> should.be_ok
  |> should.equal(option.None)
}
