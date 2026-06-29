#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "1.1.0"

new Handle:cf_mode;
new Handle:cf_countries;
new Handle:cf_reject_msg;
new Handle:cf_connect_msg;

public Plugin:myinfo =
{
	name = "Country Filter",
	author = "Knagg0",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.mfzb.de"
};

public OnPluginStart()
{
	CreateConVar("cf_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	cf_mode = CreateConVar("cf_mode", "1", "", FCVAR_PLUGIN);
	cf_countries = CreateConVar("cf_countries", "", "", FCVAR_PLUGIN);
	cf_reject_msg = CreateConVar("cf_reject_msg", "Your country (%s) isn't allowed on this server", "", FCVAR_PLUGIN);
	cf_connect_msg = CreateConVar("cf_connect_msg", "%s (Country: %s) was allowed to connect", "", FCVAR_PLUGIN);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	new String:ip[15];
	new String:code2[3];
	new String:country[45];

	GetClientIP(client, ip, sizeof(ip));
	GeoipCode2(ip, code2);
	GeoipCountry(ip, country, sizeof(country));
	
	if(Reject(code2))
	{
		GetConVarString(cf_reject_msg, rejectmsg, maxlen);
		Format(rejectmsg, maxlen, rejectmsg, country);
		return false;
	}
	
	new String:name[32];
	new String:msg[255];
	
	GetClientName(client, name, 32);
	
	GetConVarString(cf_connect_msg, msg, 255);
	Format(msg, 255, msg, name, country);
	
	PrintToChatAll(msg);
	
	return true;
}

public bool:Reject(const String:code2[])
{
	if(StrEqual("er", code2))
		return false;
		
	new String:str[255];
	new String:arr[100][3];
	
	GetConVarString(cf_countries, str, 255);
	
	new total = ExplodeString(str, " ", arr, 100, 3);
	if(total == 0) strcopy(arr[total++], 3, str);
	
	if(GetConVarInt(cf_mode) == 2)
	{
		for(new i = 0; i < total; i++)
		{
			if(StrEqual(arr[i], code2))
				return true;
		}
	}
	else
	{
		new bool:reject = true;
		
		for(new i = 0; i < total; i++)
		{
			if(StrEqual(arr[i], code2))
				reject = false;
		}
		
		return reject;
	}

	return false;
}
