require 'rubygems'
require 'bundler/setup'
require 'bacon'
require 'mocha-on-bacon'
require 'pretty_bacon'
require 'pathname'

ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$LOAD_PATH.unshift((ROOT + 'lib').to_s)
$LOAD_PATH.unshift((ROOT + 'spec').to_s)

require 'jazzy'

require 'spec_helper/pre_flight'

Bacon.summary_at_exit

module Bacon
  class Context
    include Jazzy::Config::Mixin

    def temporary_directory
      SpecHelper.temporary_directory
    end
  end
end

Mocha::Configuration.prevent(:stubbing_non_existent_method)

module SpecHelper
  def self.temporary_directory
    ROOT + 'tmp'
  end
end
