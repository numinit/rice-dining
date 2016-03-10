# rice-dining

Provides a `rice-dining` executable that prints servery offerings at Rice.

## Installation

`gem install rice-dining`

## Invocation

Run `rice-dining` to print status for everything, or `rice-dining <regex>` to print status
for locations matching `<regex>`.

For example, `rice-dining 'baker|seibel'` would display information for the Baker and
Seibel serveries.

## Screenshot

![Screenshot](/png/screenshot.png?raw=true)

## Class hierarchy

```ruby
Rice::Dining::Manifest {
  locations: [Rice::Dining::Location, ...], # Array
  allergens: [Rice::Dining::Allergen, ...]  # Set
}

Rice::Dining::Location {
  name: String,
  items: [Rice::Dining::Item, ...] # Array
}

Rice::Dining::Item {
  name: String,
  allergens: [Rice::Dining::Allergen, ...] # Set
}

Rice::Dining::Allergen {
  id: Symbol,
  shortcode: Symbol
}
```
