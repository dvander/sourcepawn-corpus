#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "1.1.2"

new Handle:cf_mode;
new Handle:cf_countries;

new String:country[45];

public Plugin:myinfo = {
	name = "Country Filter",
	author = "Knagg0. Fixed by Lebson506th",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.mfzb.de"
};

public OnPluginStart() {
	LoadTranslations("countryfilter.phrases");
	CreateConVar("cf_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);

	cf_mode = CreateConVar("cf_mode", "1", "", FCVAR_PLUGIN);
	cf_countries = CreateConVar("cf_countries", "", "", FCVAR_PLUGIN);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
	new String:ip[16];
	new String:code2[3];

	GetClientIP(client, ip, sizeof(ip));
	GeoipCode2(ip, code2);
	GeoipCountry(ip, country, sizeof(country));
	
	if(Reject(code2)) {
		CreateTimer(0.1, cfTimer, client);
		return false;
	}
	
	new String:name[32];
	new String:msg[255];
	
	GetClientName(client, name, 32);

	PrintToChatAll("%t", "Connect", name, country);
	
	return true;
}

public bool:Reject(const String:code2[]) {
	if(StrEqual("", code2))
		return false;

	new String:str[255];
	new String:arr[100][3];
	
	GetConVarString(cf_countries, str, 255);
	
	new total = ExplodeString(str, " ", arr, 100, 3);
	if(total == 0)
		strcopy(arr[total++], 3, str);
	
	if(GetConVarInt(cf_mode) == 2) {
		for(new i = 0; i < total; i++) {
			if(StrEqual(arr[i], code2))
				return true;
		}
	}
	else {
		new bool:reject = true;

		for(new i = 0; i < total; i++) {
			if(StrEqual(arr[i], code2))
				reject = false;
		}

		return reject;
	}

	return false;
}

public Action:cfTimer(Handle:timer, any:client) {
	if(IsClientInGame(client))
		KickClient(client, "%t", "Reject", country);
}