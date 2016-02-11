module RenderSync
  class Scope
    attr_accessor :scope_definition, :args, :valid
    
    def initialize(scope_definition, args)
      @scope_definition = scope_definition
      @args = args
    end
    
    # Return a new sync scope by passing a scope definition (containing a lambda and parameter names)
    # and a set of arguments to be handed over to the lambda
    def self.new_from_args(scope_definition, args)
      if args.length != scope_definition.parameters.length
        raise ArgumentError, "wrong number of arguments (#{args.length} for #{scope_definition.parameters.length})"
      end

      # Classes currently supported as Arguments for the sync scope lambda
      supported_arg_types = [Fixnum, Integer, ActiveRecord::Base]

      # Check passed args for types. Raise ArgumentError if arg class is not supported
      args.each_with_index do |arg, i|

        unless supported_arg_types.find { |klass| break true if arg.is_a?(klass) }
          param = scope_definition.parameters[i]
          raise ArgumentError, "invalid argument '#{param}' (#{arg.class.name}). Currently only #{supported_arg_types.map(&:name).join(", ")} are supported"
        end
      end
      
      new(scope_definition, args)
    end
    
    # Return a new sync scope by passing a scope definition (containing a lambda and parameter names)
    # and an ActiveRecord model object. The args List will be filled with the model attributes
    # corrensponding to the parameter names defined in the scope_definition
    def self.new_from_model(scope_definition, model)
      new(scope_definition, scope_definition.parameters.map { |p| model.send(p) })
    end
    
    # Return the ActiveRecord Relation by calling the lamda with the given args.
    #
    def relation
      scope_definition.lambda.call(*args)
    end

    # Check if the combination of stored AR relation and args is valid by calling exists? on it.
    # This may raise an exception depending on the args, so we have to rescue the block
    #
    def valid?
      @valid ||= begin 
        relation.exists?
        true # set valid to true, if relation.exists?(model) does not throw any exception
      rescue
        false
      end
    end
    
    def invalid?
      !valid?
    end

    # Check if the given record falls under the narrowing by the stored ActiveRecord Relation.
    # Depending on the arguments set in args this can lead to an exception (e.g. when a nil is passed)
    # Also set the value of valid to avoid another DB query.
    #
    def contains?(record)
      begin
        val = relation.exists?(record.id)
        @valid = true # set valid to true, if relation.exists?(model) does not throw any exception
        val
      rescue
        @valid = false
      end
    end

    # Generates an Array of path elements based on the given lambda args and their
    # name which is saved in scope_definition.parameters
    #
    def args_path
      scope_definition.parameters.each_with_index.map do |parameter, i| 
        if args[i].is_a? ActiveRecord::Base
          [parameter.to_s, args[i].send(args[i].class.primary_key).to_s]
        else
          [parameter.to_s, args[i].to_s] 
        end
      end.flatten
    end

    # Returns the Pathname for this scope
    # Example:
    #   class User < ActiveRecord::Base
    #     sync :all
    #     belongs_to :group
    #     sync_scope :in_group, ->(group) { where(group_id: group.id) }
    #   end
    #       
    #   group = Group.first
    #   User.in_group(group).polymorphic_path.to_s
    #   # => "/in_group/group/1"
    #  
    def polymorphic_path
      Pathname.new('/').join(*([scope_definition.name.to_s, args_path].flatten))
    end
    
    # Delegate all undefined methods to the relation, so that
    # the scope behaves like an ActiveRecord::Relation, e.g. call count
    # on the relation (User.in_group(group).count)
    #
    def method_missing(method, *args, &block)
      relation.send(method, *args, &block)
    end

  end
end
