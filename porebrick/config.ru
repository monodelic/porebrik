# frozen_string_literal: true

app = proc do |_env|
  ['200', { 'Content-type' => 'text/html' }, ['Super Duper']]
end

run app
