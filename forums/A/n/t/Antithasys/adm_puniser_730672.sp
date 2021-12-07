#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"

new	Handle:admpun_enabled = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Non-Admin Punisher",
	author = "Antithasys",
	description = "Punishes non admins for saying !admin",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	CreateConVar("admpun_version", PLUGIN_VERSION, "Non-Admin Punisher", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	admpun_enabled = CreateConVar("admpun_enabled", "1", "Enables/Disables Non-Admin Punisher", _, true, 0.0, true, 1.0);
	RegConsoleCmd("say", Command_SayChat);
	RegConsoleCmd("say_team", Command_SayChat);
}

public Action:Command_SayChat(client, args)
{
	if (!GetConVarBool(admpun_enabled) && GetUserAdmin(client) == INVALID_ADMIN_ID) {
		new String:SayText[192];
		GetCmdArgString(SayText,sizeof(SayText));
		StripQuotes(SayText);
		if(StrEqual(SayText,"!admin"))
			ServerCommand("sm_timebomb #%i 1", GetClientUserId(client));
		return Plugin_Handled;
	}
	return Plugin_Continue;
}  
