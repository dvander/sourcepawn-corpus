//note: players in lan will be counted as foreigners


#include <sourcemod>
#include <geoip>

new g_iForeignPlayerCount
new bool:g_bLocalPlayer[MAXPLAYERS + 1]
new Handle:g_hCountryCode = INVALID_HANDLE
new Handle:g_hForeignerLimit = INVALID_HANDLE


public Plugin:myinfo = {
	name = "Nation Limit",
	author = "p3tsin",
	description = "Limits the number of foreign players connected",
	version = "1.0.0.0",
	url = "http://users.pelikaista.net/~p3tsin/"
}

public OnPluginStart() {
	g_hCountryCode = CreateConVar("nl_countrycode","AUTO","Local countrycode, setting to AUTO configures it automagically",FCVAR_NOTIFY|FCVAR_PLUGIN)
	g_hForeignerLimit = CreateConVar("nl_foreignerlimit","15","Number of foreigners allowed, -1 = no limit",FCVAR_NOTIFY|FCVAR_PLUGIN)
	HookConVarChange(g_hCountryCode,CountryCodeChanged)

	//check the value after cvar init
	decl String:szCountry[5]
	GetConVarString(g_hCountryCode,szCountry,sizeof szCountry)
	CountryCodeChanged(g_hCountryCode,"AUTO",szCountry)
}

public OnMapStart() {
	g_iForeignPlayerCount = 0
}

public bool:OnClientConnect(client,String:rejectmsg[],maxlen) {
	decl String:szAddress[32], String:szCountry[4]
	new bool:bLocal, iLimit = GetConVarInt(g_hForeignerLimit)

	if(GetClientIP(client,szAddress,sizeof szAddress,true) && GeoipCode3(szAddress,szCountry)) {
		decl String:szLocalCountry[4]
		GetConVarString(g_hCountryCode,szLocalCountry,sizeof szLocalCountry)
		bLocal = (strcmp(szCountry,szLocalCountry,false) == 0) ? true : false
	}

	g_bLocalPlayer[client] = bLocal

	if(!bLocal && ++g_iForeignPlayerCount > iLimit > -1) {
		FormatEx(rejectmsg,maxlen,"This server has limited the number of foreigners")
		CreateTimer(0.1,TimedKick,client,TIMER_FLAG_NO_MAPCHANGE)
		return false
	}

	return true
}

public OnClientDisconnect(client) {
	if(!g_bLocalPlayer[client]) {
		g_iForeignPlayerCount--
	}

	g_bLocalPlayer[client] = false
}

public CountryCodeChanged(Handle:convar,const String:oldValue[],const String:newValue[]) {
	if(g_hCountryCode == convar) {
		if(strcmp(newValue,"AUTO",false) == 0) {
			decl String:szAddress[32], String:szCountry[4], pieces[4]

			//ip formatting by sskillz
			new longip = GetConVarInt(FindConVar("hostip"))
			pieces[0] = (longip >> 24) & 0x000000FF
			pieces[1] = (longip >> 16) & 0x000000FF
			pieces[2] = (longip >> 8) & 0x000000FF
			pieces[3] = longip & 0x000000FF
			FormatEx(szAddress,sizeof szAddress, "%u.%u.%u.%u",pieces[0],pieces[1],pieces[2],pieces[3])

			GeoipCode3(szAddress,szCountry)
			SetConVarString(convar,szCountry,false,true)
		}
		else if(strlen(newValue) != 3) {
			SetConVarString(convar,oldValue,false,true)
		}
	}
}

public Action:TimedKick(Handle:timer,any:value) {
	new client = _:value

	if(IsClientConnected(client)) {
		KickClient(value,"This server has limited the number of foreigners")
	}
}
