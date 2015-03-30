require 'yaml'

class VagrantHelper
  attr_accessor :config

  vagrant_config = File.expand_path(File.join(File.dirname(__FILE__), '..', 'vagrant.yml'))
  @config = File.exists?(vagrant_config) ? YAML.load_file(vagrant_config) : {}

  def self.config=(config_hash = {})
    @config = config_hash if config_hash.class == Hash
  end

  def self.number_of_boxes(machine_type, default)
    @config.has_key?(machine_type.downcase) && @config[machine_type.downcase].has_key?('number_of_boxes') ? @config[machine_type.downcase]['number_of_boxes'] : default
  end

end
