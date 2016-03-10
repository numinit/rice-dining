require 'set'
require 'uri'
require 'net/http'
require 'nokogiri'

require 'rice/dining/version'

module Rice
  module Dining
    BASE = URI('http://dining.rice.edu').freeze

    class Manifest
      attr_reader :locations, :allergens
      def initialize locations, allergens
        raise ArgumentError unless locations.is_a? Enumerable and allergens.is_a? Enumerable
        @locations, @allergens = [], Set.new
        locations.each do |location|
          raise ArgumentError unless location.is_a?(Rice::Dining::Location)
          @locations << location
        end
        @locations.freeze

        allergens.each do |allergen|
          raise ArgumentError unless allergen.is_a?(Rice::Dining::Allergen)
          @allergens << allergen
        end
        @allergens.freeze

        self.freeze
      end
    end

    class Location
      attr_reader :name, :items
      def initialize name, *items
        raise ArgumentError unless name.is_a? String
        @name = name.dup.freeze
        @items = []
        items.each do |item|
          raise ArgumentError unless item.is_a?(Rice::Dining::Item)
          @items << item
        end

        @items.freeze
        self.freeze
      end

      def closed?
        @items.empty?
      end

      def open?
        !closed?
      end
    end

    class Item
      attr_reader :name, :allergens
      def initialize name, *allergens
        raise ArgumentError unless name.is_a? String
        @name = name.dup.freeze
        @allergens = Set.new
        allergens.each do |allergen|
          raise ArgumentError unless allergen.is_a?(Rice::Dining::Allergen)
          @allergens << allergen
        end
        @allergens.freeze
        self.freeze
      end
    end

    class Allergen
      attr_reader :id, :shortcode
      def initialize id, shortcode
        raise ArgumentError if !id.is_a? Symbol or !shortcode.is_a? Symbol
        @id, @shortcode = id, shortcode
        self.freeze
      end

      def == other
        (self <=> other) == 0
      end

      def != other
        (self <=> other) != 0
      end

      def <=> other
        self.id <=> other.id
      end

      def hash
        self.id.hash
      end
    end

    class ManifestFetcher
      def initialize
        @allergen_map = {}
        @allergen_shortcodes = Set.new
      end

      def fetch
        @allergen_map.clear
        @allergen_shortcodes.clear

        # Make the request
        req = Net::HTTP::Get.new Rice::Dining::BASE
        req['User-Agent'.freeze] = Rice::Dining::IDENT
        res = Net::HTTP.start(Rice::Dining::BASE.hostname, Rice::Dining::BASE.port,
                              use_ssl: Rice::Dining::BASE.scheme == 'https'.freeze) {|h| h.request(req)}

        if res.is_a? Net::HTTPSuccess
          doc = Nokogiri::HTML(res.body)

          # stash allergen references in the "key" section
          doc.css('div#key div.diet'.freeze).each do |allergen_node|
            self.allergen_reference allergen_node['class'.freeze]
          end

          # build each location
          locations = []
          location_nodes = doc.css('div.item'.freeze)
          raise ManifestCreateError, "couldn't find locations".freeze if location_nodes.empty?
          location_nodes.each do |location_node|
            # get the servery name
            name_nodes = location_node.css('div.servery-title h1'.freeze)
            next if name_nodes.empty?
            name = name_nodes.first.text
            name.strip!

            # might be closed
            closed = !location_node.css('div.nothere'.freeze).empty?
            if closed
              locations << Rice::Dining::Location.new(name)
            else
              # grab the items
              items = []
              item_nodes = location_node.css('div.menu-item'.freeze)
              item_nodes.each do |item_node|
                item_allergens, item_name = [], item_node.text
                item_name.strip!
                item_node.parent.css('div.allergen div.diet'.freeze).each do |allergen_node|
                  allergen = self.allergen_reference allergen_node['class'.freeze]
                  item_allergens << allergen if allergen
                end

                items << Rice::Dining::Item.new(item_name, *item_allergens.sort)
              end

              locations << Rice::Dining::Location.new(name, *items)
            end
          end

          locations.sort! do |a, b|
            if a.closed? and b.open?
              1
            elsif a.open? and b.closed?
              -1
            else
              a.name <=> b.name
            end
          end

          Rice::Dining::Manifest.new locations, @allergen_map.values
        else
          # Problem with the response
          raise ManifestCreateError, "got HTTP #{res.code} from #{Rice::Dining::BASE}"
        end
      end

      def allergen_reference allergen_class
        # build the allergen key
        key = allergen_cleanup allergen_class
        return nil if key.nil?

        if !@allergen_map.include? key
          # find a unique value for the shortcode
          shortcode = key[0].to_sym
          if @allergen_shortcodes.include? shortcode
            shortcode = shortcode.swapcase

            while @allergen_shortcodes.include? shortcode
              shortcode = shortcode.downcase.succ
            end
          end

          # create the allergen
          allergen = @allergen_map[key] = Rice::Dining::Allergen.new(key, shortcode)
          @allergen_shortcodes << shortcode
        else
          allergen = @allergen_map[key]
        end
      end

      def allergen_cleanup allergens
        ret = allergens.match(/\Adiet\s+(?<type>[a-z]+)/i)
        return nil if ret.nil?
        ret[:type].downcase.to_sym
      end
    end

    def self.manifest
      ManifestFetcher.new.fetch
    end
  end
end

