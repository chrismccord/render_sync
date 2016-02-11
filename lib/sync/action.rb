module RenderSync
  class Action
    include Actions
    
    attr_accessor :record, :name, :scope
    
    def initialize(record, name, *args)
      options = args.extract_options!
      @record = record
      @name = name
      @scope = get_scope_from_options(options)
    end
    
    def perform
      case name
      when :new
        sync_new record, scope: scope
      when :update
        sync_update record, scope: scope
      when :destroy
        sync_destroy record, scope: scope
      end
    end
    
    # Just for testing purposes (see test/sync/model_test.rb)
    def test_path
      Resource.new(record, scope).polymorphic_path.to_s
    end
    
    private

    # Merge default_scope and scope from options Hash
    # compact array to remove nil elements
    def get_scope_from_options(options)
      [options[:default_scope], options[:scope]].compact
    end
    
  end
end
