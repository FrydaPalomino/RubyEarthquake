require 'net/http'
require 'json'
require 'sqlite3'
require_relative 'Earthquake'

def get_api_data(api_url)
  uri = URI(api_url)
  response = Net::HTTP.get(uri)
  data = JSON.parse(response)
  return data
end

def verify_data(data,db)
  # Verificar si el registro ya existe
  existente = settings.db.get_first_value("SELECT COUNT(*) FROM earthquake WHERE id = ?", data.id)

  # Insertar el registro si no existe
  if existente == 0
    settings.db.execute("INSERT INTO earthquake (id, mag, place, time_earthquake, url_earthquake, tsunami, magType, title, longitud, latitud) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [data.id,data.mag,data.place,data.time,data.url,data.tsunami,data.magType,data.title,data.longitud,data.latitud])
  end
end

def process_data(json,db)
  content = json['features']
  earthquakes_list = []
  for feature in content
    title = feature['properties']['title']
    url = feature['properties']['url']
    place = feature['properties']['place']
    magType = feature['properties']['magType']
    longitud = feature['geometry']['coordinates'][0]
    latitud = feature['geometry']['coordinates'][1]
    if not (title.nil? or url.nil? or place.nil? or magType.nil? or latitud.nil? or longitud.nil?)
      earthquake = Earthqueake.new(feature['id'],feature['properties']['mag'],place,feature['properties']['time'],url,feature['properties']['tsunami'],magType,title,longitud,latitud)
      earthquakes_list << earthquake
      verify_data(earthquake,db)
    end
  end
  return earthquakes_list
end
