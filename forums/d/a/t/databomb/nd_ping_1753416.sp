#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "[ND] Player Ping",
	author = "databomb",
	description = "Players can use the /ping or bind to sm_ping to send a notification to the commander.",
	version = PLUGIN_VERSION,
	url = "vintagejailbreak.org"
};

new Handle:gH_Cvar_Type = INVALID_HANDLE;

enum MinimapBlipType
{
	MINIMAP_BLIP_NONE = -1,
	MINIMAP_BLIP_NORMAL = 0,
	MINIMAP_BLIP_URGENT,
	MINIMAP_BLIP_ANGRY,
	MINIMAP_BLIP_PLAYER, // small, white
	MINIMAP_BLIP_ENEMY,  // small, red
}; 

public OnPluginStart()
{
	RegConsoleCmd("sm_ping", Command_Ping);
	gH_Cvar_Type = CreateConVar("sm_ping_type", "3", "The type of map blip to use. Check the source for details.", FCVAR_PLUGIN, true, 0.0);
	CreateConVar("sm_ping_version", PLUGIN_VERSION, "Player Ping Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
}

public Action:Command_Ping(client, args)
{
	if (!client)
	{
		ReplyToCommand(client, "Console disallowed");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) <= 1)
	{
		ReplyToCommand(client, "Invalid team");
		return Plugin_Handled;
	}
	
	new Handle:bf = StartMessageAll("MapBlip");
	
	BfWriteByte(bf, GetConVarInt(gH_Cvar_Type));
	new Float:v[3];
	GetClientEyePosition(client, v);
	BfWriteVecCoord(bf, v);
	EndMessage();
	
	ReplyToCommand(client, "Sent a ping to the commander for this location.");
	
	return Plugin_Handled;
}