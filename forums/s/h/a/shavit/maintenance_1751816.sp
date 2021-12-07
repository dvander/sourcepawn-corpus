#include <sourcemod>

#pragma semicolon 1

new Handle:gH_Enabled = INVALID_HANDLE;
new Handle:gH_KickReason = INVALID_HANDLE;
new bool:Enabled = false;

#define PLUGIN_VERSION "1.4"

public Plugin:myinfo = 
{
	name = "Server Maintenance",
	description = "Allows to initiate a server maintenance to allow admins to join only.",
	author = "TimeBomb",
	version = PLUGIN_VERSION,
	url = "http://vgames.co.il/"
}

public OnPluginStart()
{
	gH_Enabled = CreateConVar("sm_maintenance_enabled", "0", "\"Server maintenance\" is enabled?", FCVAR_PLUGIN|FCVAR_REPLICATED, true, _, true, 1.0);
	gH_KickReason = CreateConVar("sm_maintenance_kick_reason", "Hey there {name}, this server is under maintenance and admins are allowed to join only", "Kick reason if the plugin is enabled. [Don't add dot at the end, {name} - Player's name.]", FCVAR_PLUGIN|FCVAR_REPLICATED, true, _, true, 1.0);
	CreateConVar("sm_maintenance_version", PLUGIN_VERSION, "\"Server maintenance\"'s version.", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_REPLICATED);
	AutoExecConfig();
	HookConVarChange(gH_Enabled, cvarchange);
}

public OnClientPostAdminCheck(client)
{
	new String:KickReason[128], String:KickReasonFormat[128], String:Name[MAX_NAME_LENGTH];
	GetClientName(client, Name, MAX_NAME_LENGTH);
	GetConVarString(gH_KickReason, KickReason, sizeof(KickReason));
	ReplaceString(KickReasonFormat, 128, "{name}", Name, false);
	Format(KickReasonFormat, sizeof(KickReasonFormat), "%s", KickReason, client);
	if(Enabled && !CheckCommandAccess(client, "maintenance_allowed", ADMFLAG_GENERIC))
	{
		KickClient(client, "%s", KickReasonFormat, client);
	}
}

public cvarchange(Handle:cvar, const String:oldVal[], const  String:newVal[])
{
	Enabled = GetConVarBool(cvar);
}