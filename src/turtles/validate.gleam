import gleam/dynamic.{type DecodeError, type DecodeErrors, DecodeError}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import turtles/decode as d

/// Validate a decoded value. If the validator returns
/// any non-error value, the result is considered valid and
/// the decoded value is returned.
/// If the validator returns one or more DecodeErrors, these
/// errors are returned instead.
pub fn validate(
  validator: fn(a) -> Result(_, DecodeErrors),
) -> d.DecodeTransform(a, a) {
  d.try_map(fn(a) { validator(a) |> result.replace(a) })
}

/// Convenience shorthand for returning a validation error of
/// single decoded value.
pub fn expected(expected expected: String, found found: String) -> DecodeErrors {
  [DecodeError(expected:, found:, path: [])]
}

pub fn string_nonempty() -> d.DecodeTransform(String, String) {
  validate(fn(str) {
    case string.is_empty(str) {
      False -> Ok(Nil)
      _ -> Error(expected("non-empty String", found: str))
    }
  })
}

pub fn string_email() -> d.DecodeTransform(String, String) {
  validate(fn(str) {
    case string.contains(str, "@") {
      True -> Ok(Nil)
      _ -> Error(expected("email address", found: str))
    }
  })
}

pub fn int_min(min_value: Int) -> d.DecodeTransform(Int, Int) {
  validate(fn(value) {
    case value >= min_value {
      True -> Ok(Nil)
      False ->
        Error(expected(
          "Int >= " <> int.to_string(min_value),
          found: int.to_string(value),
        ))
    }
  })
}

pub fn list_nonempty() -> d.DecodeTransform(List(a), List(a)) {
  validate(fn(l) {
    case list.is_empty(l) {
      False -> Ok(Nil)
      _ -> Error(expected("non-empty List", found: "empty list"))
    }
  })
}
