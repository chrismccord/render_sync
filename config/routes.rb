Rails.application.routes.draw do
  get 'sync/refetch', controller: 'sync/refetches', action: 'show'
end