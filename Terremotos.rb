require 'sinatra'
require 'net/http'
require 'json'
require 'sqlite3'
require_relative 'Earthquake'
require_relative 'Modelo'
require 'sinatra'
require 'rack/cors'

use Rack::Cors do
  allow do
    origins '*' # Permitir solicitudes desde cualquier origen
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
  end
end

# Resto de la configuración y rutas de tu aplicación Sinatra


# Main:
api_url = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson'
api_data = get_api_data(api_url)

# Configuration for the database connection
configure do
  set :db, SQLite3::Database.new("earthquakes.db")
end

# Crear una tabla si no existe
settings.db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS earthquake (
    id VARCHAR(15) PRIMARY KEY,
    mag VARCHAR(50),
    place VARCHAR(50),
    time_earthquake VARCHAR(50),
    url_earthquake VARCHAR(255),
    tsunami VARCHAR(10), 
    magType VARCHAR(255), 
    title VARCHAR(200), 
    longitud FLOAT, 
    latitud FLOAT,
    comment VARCHAR(255) NULL
  );
SQL

content = process_data(api_data,settings.db)

#Crear endpoints--------------------------------------------
get '/api/features' do

  # Get the filter parameter from the query
  filter = params['filter']

  # Obtener los parámetros de consulta para la paginación
  pagina = (params['pagina'] || 1).to_i
  tamaño_pagina = (params['tamaño_pagina'] || 10).to_i

  # Calcular el índice de inicio y el índice final para la paginación
  indice_inicio = (pagina - 1) * tamaño_pagina
  indice_fin = indice_inicio + tamaño_pagina - 1

  # Obtener la información de la base de datos
  # If no filter parameter is provided, return an error
  if filter.nil? || filter.empty?
    earthquakes = settings.db.execute("SELECT * FROM earthquake LIMIT ?, ?", indice_inicio, tamaño_pagina)
    total_info = settings.db.execute("SELECT COUNT(*) FROM earthquake")[0][0]
  else 
    earthquakes = settings.db.execute("SELECT * FROM earthquake WHERE magType = ?  LIMIT ?, ?", filter, indice_inicio, tamaño_pagina)
    total_info = settings.db.execute("SELECT COUNT(*) FROM earthquake WHERE magType = ?",filter)[0][0]
  end

  # Convertir los productos a un arreglo de objetos
  earthquakes_format = earthquakes.map do |data|
    { id: data[0], type: 'feature', attributes: {external_id: data[0], magnitude: data[1].to_f, place: data[2], time: data[3], tsunami: data[5].to_i == 1, mag_type: data[6], title: data[7], coordinates: {longitude: data[8].to_f, latitude: data[9].to_f}}, links:{external_url:data[4]}}
  end

  respuesta = {
  data: earthquakes_format,
  pagination: {
    current_page: pagina,
    total: total_info,
    per_page: tamaño_pagina
    }
  }
  respuesta.to_json
end

post '/api/features' do
  # Retrieve the product ID from the URL parameters
  request.body.rewind
  data = JSON.parse(request.body.read)
  feature_id = data['id']
  
  # Check if the product exists
  info = settings.db.execute("SELECT * FROM earthquake WHERE id = ?", feature_id).to_json 
  puts info
  total_info = settings.db.execute("SELECT COUNT(*) FROM earthquake WHERE id = ?", feature_id)[0][0]
  puts total_info
  if total_info == 0
    status 404  # Not Found
    return { error: "Feature with ID #{feature_id} not found" }.to_json
  else
    settings.db.execute('UPDATE earthquake SET comment = ? WHERE id = ?', [data['comment'], feature_id])
    status 200  # OK
  end
end

