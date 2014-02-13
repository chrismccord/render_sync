module Sync
  class ScopeDefinition
    attr_accessor :klass, :name, :lambda, :parameters, :args
    
    def initialize(klass, name, lambda)
      unless (invalid = lambda.parameters.map { |p| p[1] } - klass.column_names.map(&:to_sym) - klass.instance_methods) == []
        raise ArgumentError, "Invalid parameters #{invalid}. Parameter names of the sync_scope lambda definition may only contain ActiveRecord column names or instance methods of #{klass.name}."
      end

      @klass = klass
      @name = name
      @lambda = lambda
      @parameters = lambda.parameters.map { |p| p[1] }
    end
   
  end
end
