require 'sqlite3'
require 'sinatra/activerecord'

# Configuración de la conexión a la base de datos
configure :development do
  set :database, { adapter: 'sqlite3', database: 'earthquakes.db' }
end