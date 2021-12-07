#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

new Handle:Website = INVALID_HANDLE;
new Handle:Website01 = INVALID_HANDLE;
new Handle:Other = INVALID_HANDLE;
new Handle:Enabled = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "website",
	author = "gamemann",
	description = "shows my website",
	version = PLUGIN_VERSION,
	url = "http://games223.com/"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	Website = CreateConVar("website_url", "http://", "your first website url");
	Website01 = CreateConVar("website01_url", "", "your 2nd website url");
	Other = CreateConVar("other", "", "other things that you might want to say about your website");
	Enabled = CreateConVar("enabled", "1", "enable the plugin or not");
	AutoExecConfig(true, "any_websites");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(Enabled))
	{
		decl String:website[128];
		decl String:website01[128];
		decl String:other[128];
		GetConVarString(Website, website, 128)
		GetConVarString(Website01, website01, 128);
		GetConVarString(Other, other, 128);
		PrintToChatAll("join \"%s\" and \"%s\" also: \"%s\"", website, website01, other);
	}
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(Enabled))
	{
		decl String:website[128];
		decl String:website01[128];
		decl String:other[128];
		GetConVarString(Website, website, 128)
		GetConVarString(Website01, website01, 128);
		GetConVarString(Other, other, 128);
		PrintToChatAll("join \"%s\" and \"%s\" also: \"%s\"", website, website01, other);
	}
}

public OnMapEnd()
{
	CreateTimer(30.0, Check);
	return;
}

public Action:Check(Handle:timer)
{
	//nothin
	return Plugin_Handled;
}



	