MAPS = {}

MAPS.search_and_set = function(search_text){
	var geo = new GClientGeocoder();
	geo.getLocations(search_text, MAPS.search_results )
}

MAPS.search_results = function (results ) {
	if (results.Status.code == G_GEO_SUCCESS) {
		var a = 1;
		lat=results.Placemark[0].Point.coordinates[1];
		lng=results.Placemark[0].Point.coordinates[0];
		var map = new GMap2(document.getElementById("map"));
		map.addControl(new GSmallMapControl());
      map.setCenter(new GLatLng(lat, lng), 13);
	} else if(results.Status.code == G_GEO_UNKNOWN_ADDRESS) {
		$('map').hide();
	} else {
		$('map').hide();
	}
}

	