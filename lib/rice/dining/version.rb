module Rice
  module Dining
    module Version
      VERSION     = '0.2.2'.freeze
      SHORT_NAME  = Rice::Dining.to_s.freeze
      SHORT_IDENT = "#{SHORT_NAME} v#{VERSION}".freeze
      NAME        = SHORT_NAME.freeze
      IDENT       = SHORT_IDENT.freeze
    end

    include Version
  end
end
