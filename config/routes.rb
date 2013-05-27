Rails.application.routes.draw do
  get 'sync/refetch', controller: 'sync', action: 'refetch'
end