# frozen_string_literal: true

require "pathname"
require_relative "base_recipe"

module LibarchiveBinary
  class ZLibRecipe < BaseRecipe
    def initialize
      super("zlib")
    end

    def configure_defaults
      [
        "--static",
      ]
    end

    def configure_windows
      mk = File.read("win32/Makefile.gcc")
      File.open("win32/Makefile.gcc", "wb") do |f|
        f.puts "BINARY_PATH = #{path}/bin"
        f.puts "LIBRARY_PATH = #{path}/lib"
        f.puts "INCLUDE_PATH = #{path}/include"
        f.puts "SHARED_MODE = 0"
        f.puts "LOC = -fPIC"
        f.puts mk
      end
    end

    def configure
      if MiniPortile::windows?
        Dir.chdir(work_path) do
          configure_windows
        end
      else
        cmd = ["env", cflags(host), ldflags(host),
               "./configure"] + computed_options
        execute("configure", cmd)
      end
    end

    def configured?
      if MiniPortile::windows?
        Dir.chdir(work_path) do
          !!(File.read("win32/Makefile.gcc") =~ /^BINARY_PATH/)
        end
      else
        super
      end
    end

    def compile
      if MiniPortile::windows?
        execute("compile", "make -f win32/Makefile.gcc libz.a")
      else
        super
      end
    end

    def install
      if MiniPortile::windows?
        execute("install", "make -f win32/Makefile.gcc install")
      else
        super
      end
    end

    def checkpoint
      File.join(@target, "#{name}-#{version}-#{host}.installed")
    end

    def cook_if_not
      cook unless File.exist?(checkpoint)
    end

    def cook
      super

      FileUtils.touch(checkpoint)
    end
  end
end
