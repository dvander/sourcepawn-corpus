#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.30"

/* ChangeLog
1.00	Initial Creation
1.10	Added Ban Time and Min Players
1.20	Prevented Admin from Being Banned
1.21	Renamed GameData File to fix bug with Carrier Mod Plugin
1.30	Fixed Client Index 0 Error
*/

public Plugin:myinfo = {
	name = "Carrier Skip",
	author = "Will2Tango",
	description = "Bans Players who Carrier Skip.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

new Handle:CarrierSkip = INVALID_HANDLE;
new Handle:MinPlayers = INVALID_HANDLE;
new Handle:BanTime = INVALID_HANDLE;
new CarrierOffset = -1;

public OnPluginStart()
{
	new Handle:conf = LoadGameConfigFile("zps_carriermod");
	CarrierOffset = GameConfGetOffset(conf, "IsCarrier");
	CloseHandle(conf);
	
	CreateConVar("zps_carrierskip_version", PLUGIN_VERSION, "Carrier Skip Plugin Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CarrierSkip = CreateConVar("sm_carrierskip", "1", "Carrier Skip off on. (1/0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	MinPlayers = CreateConVar("sm_carrierskip_minplayers", "5", "Min Players Before Carrier Skippers are Banned.", FCVAR_PLUGIN, true, 1.0);
	BanTime = CreateConVar("sm_carrierskip_bantime", "3", "Time to Ban a Carrier Skipper (in hours, 0 for permanent)", FCVAR_PLUGIN, true, 0.0);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!CarrierSkip) {return Plugin_Continue;}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:exitReason[100]; GetEventString(event, "reason", exitReason, sizeof(exitReason));

	if (!IsFakeClient(client) && IsClientInGame(client))
	{
		if (GetClientTeam(client) == 3 && GetEntData(client, CarrierOffset) && GetTeamClientCount(3) < 2)
		{
			new flags = GetUserFlagBits(client);
			if (flags & ADMFLAG_ROOT || flags & ADMFLAG_GENERIC)
			{
				return Plugin_Continue;
			}
			else if (StrEqual(exitReason, "Disconnect by user.", false) && GetClientCount() >= GetConVarInt(MinPlayers))
			{
				SetEventString(event, "reason", "Carrier Skipping Little Shit.");
				new String:clientSteamId[64], String:banReason[64];
				GetClientAuthString(client, clientSteamId, sizeof(clientSteamId));
				banReason = ("Banned for being a Carrier Skipping Little Shit.");
				new banTime = GetConVarInt(BanTime);
				if (banTime > 0) {banTime = banTime * 60;}
				BanIdentity(clientSteamId, banTime, BANFLAG_AUTHID, banReason);
			}
		}
	}
	return Plugin_Continue;
}