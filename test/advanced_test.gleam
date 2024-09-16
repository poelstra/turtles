import birl
import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/option.{type Option}
import gleam/order
import gleam/result
import gleeunit/should
import turtles/decode as d
import turtles/validate as v

/// Example of a custom decoder, in this case to parse an ISO8601 datetime
/// using the birl library.
pub fn time_decoder(time_value: Dynamic) -> d.DecodeResult(birl.Time) {
  use str <- d.decode(time_value, dynamic.string)
  birl.parse(str)
  |> result.replace_error(v.expected("ISO8601 datetime", found: str))
}

/// Example of a custom validator, in this case to check that the datetime
/// is in the future.
pub fn time_is_future() -> d.DecodeTransform(birl.Time, birl.Time) {
  v.validate(fn(time) {
    case birl.compare(time, birl.now()) {
      order.Gt -> Ok(Nil)
      _ -> Error(v.expected("datetime in future", found: birl.to_http(time)))
    }
  })
}

/// Example of a full-blown decoder to decode a complex type.
///
/// Note that for clarity, it's also trivial to extract the decoders
/// for each field into their own functions, because they're all just
/// plain `dynamic.Decoder`s.
pub fn reservation_decoder(reservation: Dynamic) {
  use person_name <- d.decode(
    reservation,
    dynamic.field("person_name", dynamic.string |> v.string_nonempty()),
  )
  use email <- d.decode(
    reservation,
    dynamic.field("email", dynamic.string |> v.string_email()),
  )
  use datetime <- d.decode(
    reservation,
    dynamic.field("datetime", time_decoder |> time_is_future()),
  )
  use guests <- d.decode(
    reservation,
    dynamic.field(
      "guests",
      dynamic.list(fn(guest) {
        use name <- d.decode(guest, dynamic.field("name", dynamic.string))
        use age <- d.decode(
          guest,
          dynamic.field("age", dynamic.int |> v.int_min(18)),
        )
        use special_needs <- d.decode(
          guest,
          dynamic.optional_field("special_needs", dynamic.string),
        )
        Ok(Guest(name:, age:, special_needs:))
      })
        |> v.list_nonempty(),
    ),
  )
  use table <- d.decode(
    reservation,
    dynamic.field("table", fn(table) {
      use type_ <- d.decode(table, dynamic.field("type", dynamic.string))

      case type_ {
        "specific" -> {
          use table_number <- d.decode(
            table,
            dynamic.field("table_number", dynamic.int),
          )
          Ok(Specific(table_number:))
        }
        "any" -> Ok(Any)
        _ -> Error(v.expected("TableType 'specific' or 'any'", found: type_))
      }
    }),
  )
  use notes <- d.decode(
    reservation,
    d.optional_nullable_field("notes", dynamic.string),
  )
  Ok(Reservation(person_name:, email:, datetime:, guests:, table:, notes:))
}

const data = "
{
  \"person_name\": \"Alice\",
  \"email\": \"alice@example.com\",
  \"datetime\": \"2099-01-01T12:00:00Z\",
  \"guests\": [
    { \"name\": \"Alice\", \"age\": 25 },
    { \"name\": \"Bob\", \"age\": 30, \"special_needs\": \"Vegan\" }
  ],
  \"table\": { \"type\": \"specific\", \"table_number\": 1 },
  \"notes\": null
}
"

pub type Guest {
  Guest(name: String, age: Int, special_needs: Option(String))
}

pub type Table {
  Any
  Specific(table_number: Int)
}

pub type Reservation {
  Reservation(
    person_name: String,
    email: String,
    datetime: birl.Time,
    guests: List(Guest),
    table: Table,
    notes: Option(String),
  )
}

pub fn advanced_test() {
  json.decode(data, reservation_decoder)
  |> should.be_ok
  |> should.equal(Reservation(
    "Alice",
    "alice@example.com",
    birl.parse("2099-01-01T12:00:00Z") |> should.be_ok,
    [Guest("Alice", 25, option.None), Guest("Bob", 30, option.Some("Vegan"))],
    Specific(1),
    option.None,
  ))
}
