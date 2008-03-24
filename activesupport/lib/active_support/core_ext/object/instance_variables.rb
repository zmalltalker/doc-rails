class Object
  # Available in 1.8.6 and later.
  unless respond_to?(:instance_variable_defined?)
    def instance_variable_defined?(variable)
      instance_variables.include?(variable.to_s)
    end
  end

  # Returns a hash that maps instance variable names without "@" to their
  # corresponding values. Keys are strings both in Ruby 1.8 and 1.9.
  #
  #   class C
  #     def initialize(x, y)
  #       @x, @y = x, y
  #     end
  #   end
  #   
  #   C.new(0, 1).instance_values # => {"x" => 0, "y" => 1}
  def instance_values #:nodoc:
    instance_variables.inject({}) do |values, name|
      values[name.to_s[1..-1]] = instance_variable_get(name)
      values
    end
  end

  # Returns an array of instance variable names including "@". They are strings
  # both in Ruby 1.8 and 1.9.
  #
  #   class C
  #     def initialize(x, y)
  #       @x, @y = x, y
  #     end
  #   end
  #   
  #   C.new(0, 1).instance_variable_names # => ["@y", "@x"]
  def instance_variable_names
    instance_variables.map(&:to_s)
  end

  def copy_instance_variables_from(object, exclude = []) #:nodoc:
    exclude += object.protected_instance_variables if object.respond_to? :protected_instance_variables

    vars = object.instance_variables.map(&:to_s) - exclude.map(&:to_s)
    vars.each { |name| instance_variable_set(name, object.instance_variable_get(name)) }
  end
end
