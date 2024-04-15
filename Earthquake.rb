class Earthqueake
  attr_accessor :id, :mag, :place, :time, :url, :tsunami, :magType, :title, :longitud, :latitud

  def initialize(id, mag, place, time, url, tsunami, magType, title, longitud, latitud)
    @id = id
    @mag = mag
    @place = place
    @time = time
    @url = url
    @tsunami = tsunami
    @magType = magType
    @title = title
    @longitud = longitud
    @latitud = latitud
  end

  def self.metodo_de_prueba
    puts "Esto es una prueba desde otro archivo."
  end

end