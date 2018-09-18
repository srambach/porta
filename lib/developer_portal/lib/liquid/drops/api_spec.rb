# frozen_string_literal: true
module Liquid
  module Drops
    class ApiSpec < Drops::Model
      def initialize(spec)
        @spec = spec
      end

      desc 'Returns the url of the API spec.'
      def url
        cms_url_helpers.swagger_spec_path(system_name, format: :json)
      end

      desc 'Returns the name of the spec.'
      def system_name
        @spec.system_name
      end
    end
  end
end
