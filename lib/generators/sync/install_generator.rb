module RenderSync
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def self.source_root
        File.dirname(__FILE__) + "/templates"
      end

      def copy_files
        template "sync.yml", "config/sync.yml"
        copy_file "sync.ru", "sync.ru"
      end
    end
  end
end
