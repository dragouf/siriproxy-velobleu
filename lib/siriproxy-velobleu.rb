# -*- encoding: utf-8 -*-
require 'cora'
require 'siri_objects'
require 'pp'
require 'timeout'
require 'json'
require 'open-uri'
require 'uri'
require 'xmlrpc/client'

class SiriProxy::Plugin::VeloBleu < SiriProxy::Plugin   
    def initialize(config)
      #if you have custom configuration options, process them here!
    end

    def userLongitude
    end
    def userLatitude
    end

	filter "SetRequestOrigin", direction: :from_iphone do |object|
    	puts "[Info - User Location] lat: #{object["properties"]["latitude"]}, long: #{object["properties"]["longitude"]}"
    	$userLongitude = object["properties"]["longitude"]
    	$userLatitude = object["properties"]["latitude"]
	end 

	# Where am i - shows map with current location
listen_for /(station velo bleu (.*) proche)/i do
	if $userLongitude == NIL
    	say "J'aime aussi le savoir, mais sans les données GPS, je suis juste un téléphone stupide."
    else
    	add_views = SiriAddViews.new
    	add_views.make_root(last_ref_id)
    	map_snippet = SiriMapItemSnippet.new(true)
 		siri_location = SiriLocation.new("", "Autour de vous", "", "", "", "", $userLatitude.to_f, $userLongitude.to_s) 
	    map_snippet.items << SiriMapItem.new(label="Vous êtes ici", location=siri_location, detailType="BUSINESS_ITEM")
	    print map_snippet.items
	    utterance = SiriAssistantUtteranceView.new("Très bien, je vous localise.")
		add_views.views << utterance
    	add_views.views << map_snippet
    
   		#you can also do "send_object object, target: :guzzoni" in order to send an object to guzzoni
    	send_object add_views #send_object takes a hash or a SiriObject object
    end
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end
  
# Where am i - shows map with current location
listen_for /(Où suis-je|Où je suis|Localise-moi|Trouve moi|Trouve où je suis)/i do
	if $userLongitude == NIL
    	say "J'aime aussi le savoir, mais sans les données GPS, je suis juste un téléphone stupide."
    else
    	add_views = SiriAddViews.new
    	add_views.make_root(last_ref_id)
    	map_snippet = SiriMapItemSnippet.new(true)
 		siri_location = SiriLocation.new("", "Autour de vous", "", "", "", "", $userLatitude.to_f, $userLongitude.to_s) 
	    map_snippet.items << SiriMapItem.new(label="Vous êtes ici", location=siri_location, detailType="BUSINESS_ITEM")
	    print map_snippet.items
	    utterance = SiriAssistantUtteranceView.new("Très bien, je vous localise.")
		add_views.views << utterance
    	add_views.views << map_snippet
    
   		#you can also do "send_object object, target: :guzzoni" in order to send an object to guzzoni
    	send_object add_views #send_object takes a hash or a SiriObject object
    end
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

# safes position in the file "locsave.txt"
listen_for /(Position en mémoire|Enregistre la position|Sauvegarde la position|Enregistre ce lieu|Sauvegarde ce lieu|Enregistre cet endroit|Sauvegarde cet endroit)/i do   
	lat = $userLatitude
	lon = $userLongitude
	if lat == nil
		say "S'il vous plaît activer le service de suivi."
	else
		lats = lat.to_s
		latt = lats.match(/[.]/)
		latt = latt.post_match.strip.size
		mystr = lat.to_s + "," + lon.to_s
		aFile = File.new("plugins/siriproxy-velobleu/locsave.txt", "w")
		aFile.write(mystr)
		aFile.close
		if latt < 13
			say "Signal trop faible, sauvegardez la position" 
		else
			say "Emplacement enregistré, pour le chargez dites :'Charge la destination'", spoken: "Emplacement actuel enregistré"
		end
	end
	#say "lat:" + $ortla.to_s + "  long:" + $ortlo.to_s , spoken: "" 
	request_completed 
end

# loads position from a global variable
listen_for /(Mes emplacements|Montre-moi la positon|Positions enregistrées|Affiche la position|Charger la position|Charge la destination)/i do 
	aFile = File.new("plugins/siriproxy-velobleu/locsave.txt", "r")
	str = aFile.gets.to_s
	aFile.close
	if str.match(/(,)/)
		strloc = str.match(/(,)/)
		lat = strloc.pre_match
		lon = strloc.post_match
	end
	if lat.to_s == ""
		say "Fichier vide, veuillez dire : 'Enregistrer la position'", spoken: "Veuillez enregistrer votre position."
	else
	lon1 = lon.to_f
	lat1 = lat.to_f
	lon2 = $userLongitude
	lat2 = $userLatitude
	if lon2 == NIL
		say "S'il vous plaît activez les services de localisation."
	else
		haversine_distance( lat1, lon1, lat2, lon2 )
		entf = @distances['km']
		entf = (entf * 10**3).round.to_f / 10**3
		if entf.to_s == "0.0"
			say "Vous êtes arrivé à destination"
			print entf
		elsif entf > 0.0 and entf < 1.000
			entf = (entf * 10**3).round.to_f / 10**3
			ent = ent.to_f
			ent = (entf * 1000)
			ent = ent.to_s
			ent = ent.match(/(.)/)
			say "Distance de l'objectif: " + ent.to_s + " m", spoken: "Distance restante : " + ent.to_s + " Metres"
	
		else
			say "Distance restante : " + entf.to_s + " km"
		end
	
		add_views = SiriAddViews.new
    	add_views.make_root(last_ref_id)
    	map_snippet = SiriMapItemSnippet.new(true)
    	siri_location = SiriLocation.new("Localisations stockées" , "Plan de votre destination", "Traduction 2", "Traduction 3", "durt", "wo", lat.to_f, lon.to_s) 
    	map_snippet.items << SiriMapItem.new(label="Localisation de votre destination", location=siri_location, detailType="BUSINESS_ITEM")
    	print map_snippet.items
    	utterance = SiriAssistantUtteranceView.new("Hourra, je me suis trouvé !")
    #add_views.views << utterance
    	add_views.views << map_snippet
    	send_object add_views #send_object takes a hash or a SiriObject object
		end
	end
  request_completed
end

# get json data from proxy
listen_for /Trouve les stations/i do 
	server = XMLRPC::Client.new( "localhost", "/VeloBleuProxy/index.php/iphoneXmlRpc/")
	# Recupere les stations
	jsonText = server.call("get.stations")
	
	# parse la reponse
	empl = jsonText
  empl.chop
  empl.reverse
  empl.chop
  empl.reverse
  empl.gsub('\"', '"')
  jsonObject = JSON.parse(empl)	
	
	add_views = SiriAddViews.new
  add_views.make_root(last_ref_id)
  map_snippet = SiriMapItemSnippet.new(true)
  
	# Parcours les stations
	indexStation = 0
	#bestStation = Array.new
	jsonObject['stations'].each do |station|
	  isDisplay = station['EstAfficher']
	  stationLong = station['Longitude']
	  stationLat = station['Latitude']
	  freeBike = station['VelosDisponibles']
	  totalDocks = station['EmplacamentTotal']
	  freeDocks = station['EmplacementLibre']
	  nomStation = "Station " + station['IdStation']
	  
	  # Calcul la distance avec l'utilisateur et cree un tableau des 3 meilleurs
	  # ajoute les 3 meilleurs resultats (les plus proches) sur la carte
	  
    siri_location = SiriLocation.new(nomStation, "", "Nice", "", "FR", "", stationLat, stationLong) 
    map_snippet.items << SiriMapItem.new(label=nomStation , location=siri_location, detailType="BUSINESS_ITEM")
	
	  indexStation += 1
	  if(indexStation > 3)
	    break
    end
  end
	  say "Voici les stations que j'ai trouvé"
	  print map_snippet.items
    utterance = SiriAssistantUtteranceView.new("Choisissez dans la liste")
    add_views.views << utterance
    add_views.views << map_snippet
    send_object add_views #send_object takes a hash or a SiriObject object
    
    request_completed
end

# for the distance calculation code
def haversine_distance( lat1, lon1, lat2, lon2 )
	self::class::const_set(:RAD_PER_DEG, 0.017453293)
	self::class::const_set(:Rkm, 6371)              # radius in kilometers...some algorithms use 6367
	self::class::const_set(:Rmeters, 6371000)    # radius in meters
	@distances = Hash.new
	dlon = lon2 - lon1
	dlat = lat2 - lat1
	dlon_rad = dlon * RAD_PER_DEG
	dlat_rad = dlat * RAD_PER_DEG
	lat1_rad = lat1 * RAD_PER_DEG
	lon1_rad = lon1 * RAD_PER_DEG
	lat2_rad = lat2 * RAD_PER_DEG
	lon2_rad = lon2 * RAD_PER_DEG
	a = (Math.sin(dlat_rad/2))**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * (Math.sin(dlon_rad/2))**2
	c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a))
	dKm = Rkm * c             # delta in kilometers
	dMeters = Rmeters * c     # delta in meters
	@distances["km"] = dKm
	@distances["m"] = dMeters
end
end