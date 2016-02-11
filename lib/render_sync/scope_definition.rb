module RenderSync
  class ScopeDefinition
    attr_accessor :klass, :name, :lambda, :parameters, :args
    
    def initialize(klass, name, lambda)
      self.class.ensure_valid_params!(klass, lambda)
      
      @klass = klass
      @name = name
      @lambda = lambda
      @parameters = lambda.parameters.map { |p| p[1] }
    end
    
    # Checks the validity of the parameter names contained in the lambda definition.
    # E.g. if the lambda looks like this:
    #
    # ->(user) { where(user_id: user.id) }
    #
    # The name of the passed argument (user) must be present as a column name or an
    # instance method (e.g. an association) of the ActiveRecord object.
    #
    def self.ensure_valid_params!(klass, lambda)
      unless (invalid = lambda.parameters.map { |p| p[1] } - klass.column_names.map(&:to_sym) - klass.instance_methods) == []
        raise ArgumentError, "Invalid parameters #{invalid}. Parameter names of the sync_scope lambda definition may only contain ActiveRecord column names or instance methods of #{klass.name}."
      end
      true
    end
   
  end
end
