# frozen_string_literal: true

module Jekyll
  module Compose
    class FileMover
      attr_reader :force, :movement, :root
      def initialize(movement, force = false, root = nil)
        @movement = movement
        @force = force
        @root = root
      end

      def resource_type_from
        "file"
      end

      def resource_type_to
        "file"
      end

      def move
        validate_source
        validate_should_write!
        ensure_directory_exists
        move_file
      end

      def validate_source
        raise ArgumentError, "There was no #{resource_type_from} found at '#{from}'." unless File.exist? from
      end

      def ensure_directory_exists
        dir = File.dirname to
        Dir.mkdir(dir) unless Dir.exist?(dir)
      end

      def validate_should_write!
        raise ArgumentError, "A #{resource_type_to} already exists at #{to}" if File.exist?(to) && !force
      end

      def move_file
        case resource_type
        when 'draft'
          _, frontmatter, *contents = File.read(from).split("---\n")
          yaml = YAML::load(frontmatter)
          yaml["date"] = movement.iso8601
          File.open(to, "w") do |file|
            file << yaml.to_yaml
            file << "---\n"
            file << contents.join("---\n")
          end
          FileUtils.rm(from)
        else
          FileUtils.mv(from, to)
        end
        Jekyll.logger.info "#{resource_type_from.capitalize} #{from} was moved to #{to}"
      end

      private

      def from
        movement.from
      end

      def to
        file_path(movement.to)
      end

      def file_path(path)
        return path if root.nil? || root.empty?

        File.join(root, path)
      end
    end
  end
end
