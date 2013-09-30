module Gub
  class Cache
    def initialize base_dir
      @base_dir = base_dir
    end

    def set key, value
      cached_path = @base_dir + '/' + key
      File.open(cached_path, 'w') do |f|
        f.puts value
      end
    end
    
    def get key
      cached_path = @base_dir + '/' + key
      if File.exists? cached_path
        return IO.read cached_path
      end
    end
  end  
end
