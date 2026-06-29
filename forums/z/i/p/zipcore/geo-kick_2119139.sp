#include <sourcemod>
#include <geoip>

public Plugin:myinfo = 
{
	name = "Geo Kick",
	author = "Zipcore",
	description = "Kick Players without a resolveable GeoIP",
	version = "1.0",
	url = "https://forums.alliedmods.net/showpost.php?p=2119139&postcount=2"
}

public OnClientPutInServer(client)
{
	new String:sBuffer[64]; 
	GetClientIP(client, sBuffer, 64);
	
	if(!GeoipCountry(sBuffer, sBuffer, 64))
		KickClient(client, "You country could not be resolved.");
	
}
