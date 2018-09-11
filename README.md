# rice-dining

Provides a `rice-dining` executable that prints servery offerings at Rice,
with an API that you can use to extract semi-structured data from the
servery menu.

If you don't like Ruby, shell out from nodejs or something.

## Installation

`gem install rice-dining`

## Using it in your HackRice party planning app

Everyone loves CSV, right?

```ruby
require 'rice/dining'
require 'csv'

manifest = Rice::Dining.manifest

CSV.open('dining.csv', 'w') do |csv|
  manifest.locations.each do |loc|
    loc.items.each do |item|
      csv << [loc.name, loc.open?, item.name, item.allergens.map(&:id).join(' ')]
    end
  end
end
```

```csv
<...>

Baker,true,Roasted red potatoes,vegan
Baker,true,Buffalo chicken drumsticks with bleu cheese,milk
Baker,true,Cod loin with roasted asparagus and corn,fish
Baker,true,Grilled tofu steaks with chimichurri,soy vegan
Baker,true,Roasted cauliflower & crispy garbanzos,soy vegan
Baker,true,Margherita pizza,gluten milk soy vegetarian
Baker,true,Pinto bean soup with pico de gallo,soy vegan
```

Note that this query was performed at like 4AM Houston time and all the
locations were "open" according to dining.rice.edu `¯\_(ツ)_/¯`

## Invocation

Run `rice-dining` to print status for everything, or `rice-dining <regex>` to
print status for locations matching `<regex>`.

For example, `rice-dining 'baker|seibel'` would display information for the
Baker and Seibel serveries.

## Unicode

If the unicode arrows bug you, export `RICE_DINING_NO_UNICODE` and they will
go away.

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
