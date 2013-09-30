module Gub
  class Config
    attr_accessor :data
    
    def rc
      File.expand_path("~/.gubrc")
    end
    
    def initialize
      read
    end
    
    def add key, value
      self.data ||= {}
      self.data[key] = value
      self.write
    end
    
    def read
      if File.exists?(self.rc)
        self.data = YAML.load_file(self.rc)
      else
        self.data = {}
      end
    end
    
    def write
      puts data.inspect
      File.open(self.rc, 'w') { |f| YAML.dump(self.data, f) }
    end
    
    def method_missing meth, *args, &block
      self.data[meth.to_s] if self.data && self.data.has_key?(meth.to_s)
    end
  end
end