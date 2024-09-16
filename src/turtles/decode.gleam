import gleam/dynamic.{type Dynamic}
import gleam/option
import gleam/result

// Convenience re-exports of gleam/dynamic.
// Note: Gleam can't re-export type constructors yet, so not re-exporting DecodeError
// here...

/// Convenience re-export of `dynamic.Decoder(a)`
pub type Decoder(a) =
  dynamic.Decoder(a)

/// Convenience re-export of `dynamic.DecodeErrors`
pub type DecodeErrors =
  dynamic.DecodeErrors

// Additional types and helpers

/// Convenience type for the result of a `Decoder(a)`
pub type DecodeResult(a) =
  Result(a, DecodeErrors)

/// Function that takes a decoder and transforms it to another.
///
/// Useful for mapping the result of a decoder into something,
/// performing validation before/after a decoder, etc.
///
/// ## Example
///
/// ```gleam
/// let uppercase_string = dynamic.string |> map(string.uppercase)
/// uppercase_string(dynamic.from("foo"))
/// // -> Ok("FOO")
/// ```
pub type DecodeTransform(a, b) =
  fn(Decoder(a)) -> Decoder(b)

/// Decode a dynamic value and call the given function with
/// the decoded value, if decoding succeeded.
/// If the decoder or called function returns an error, that
/// error is returned instead.
///
/// ## Example
///
/// ```gleam
/// import turtles/validate as v
///
/// fn flep_decoder(obj: dynamic.Dynamic) -> Result(Flep, List(dynamic.DecodeError)) {
///   use foo <- decode(obj, dynamic.field("foo", dynamic.int |> v.int_min(10)))
///   use bar <- decode(obj, dynamic.field("bar", dynamic.string))
///   Ok(Flep(foo:, bar:))
/// }
///
/// flep(from(Flep(foo: 42, "bar": "baz")))
/// // -> Ok(Flep(42, "baz"))
/// ```
pub fn decode(
  obj: Dynamic,
  decoder: Decoder(a),
  next: fn(a) -> DecodeResult(b),
) -> DecodeResult(b) {
  result.try(decoder(obj), next)
}

/// Turn a decoder into another decoder with a different value.
///
/// If the 'input' decoder returns an error, the function will
/// not be called, and the result of the 'output' decoder will be
/// that error.
///
/// ## Example
///
/// ```gleam
/// let uppercase_string: dynamic.Decoder(String) = dynamic.string |> map(string.uppercase)
/// uppercase_string(dynamic.from("foo"))
/// // -> Ok("FOO")
/// ```
pub fn map(with mapper: fn(a) -> b) -> DecodeTransform(a, b) {
  fn(decoder: Decoder(a)) {
    fn(data: Dynamic) -> DecodeResult(b) { decoder(data) |> result.map(mapper) }
  }
}

/// Turn a decoder into another decoder with a different value.
///
/// If the 'input' decoder returns an error, the function will not be called.
/// If the 'input' decoder or the function returns an error, the result of
/// the 'output' decoder will be that error.
///
/// ## Example
///
/// ```gleam
/// let two_options: dynamic.Decoder(String) =
///   dynamic.string
///   |> d.try_map(fn(value) {
///     case value {
///       "foo" | "bar" -> Ok(value)
///       _ ->
///         Error([
///           dynamic.DecodeError(expected: "foo or bar", found: value, path: []),
///         ])
///     }
///   })
///
/// two_options(dynamic.from("foo"))
/// // -> Ok("foo")
///
/// two_options(dynamic.from("flep"))
/// // -> Error([dynamic.DecodeError("foo or bar", "flep", [])])
/// ```
pub fn try_map(with mapper: fn(a) -> DecodeResult(b)) -> DecodeTransform(a, b) {
  fn(decoder: Decoder(a)) {
    fn(data: Dynamic) -> DecodeResult(b) { decoder(data) |> result.try(mapper) }
  }
}

/// Decode a field that is optional, and of which the value itself
/// is also optional.
///
/// I.e. the field may be missing on the object, or its value can be
/// `null`, `undefined`, etc.
///
/// ## Example
///
/// ```gleam
/// import gleam/dict
/// import gleam/option
/// dict.new()
/// |> dict.insert("foo", "bar")
/// |> dynamic.from
/// |> optional_nullable_field(named: "foo", of: dynamic.string)
/// // -> Ok(Some("bar"))
///
/// import gleam/dict
/// dict.new()
/// |> dict.insert("foo", option.None)
/// |> dynamic.from
/// |> optional_nullable_field(named: "foo", of: dynamic.string)
/// // -> Ok(None)
/// ```
pub fn optional_nullable_field(
  named name: a,
  of inner_type: Decoder(t),
) -> Decoder(option.Option(t)) {
  dynamic.optional_field(name, dynamic.optional(inner_type))
  |> map(option.flatten)
}
