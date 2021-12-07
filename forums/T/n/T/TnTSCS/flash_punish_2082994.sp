#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors>

#define PLUGIN_VERSION "1.0.0.1"

new Handle:Enabled;
new Handle:Duration;
new Handle:MinFlAmount;
new Handle:PunishTime;
new Handle:MaxFlashedPlayers;
new NumFlashed[MAXPLAYERS+1];
new bool:g_bFlashed[MAXPLAYERS+1];
new bool:IsAdmin[MAXPLAYERS+1];
new bool:CanBuyFlash[MAXPLAYERS+1];
new bool:PlayerHasFlashEquipped[MAXPLAYERS+1];
new LastNotification[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Flash Punish",
	author = "TnTSCS aka ClarkKent",
	description = "Punish Team Flashers",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_flashpunish_version", PLUGIN_VERSION, "Flash Punish Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Enabled = CreateConVar("sm_flashpunish_enabled", "1", "Enable/Disable the plugin", _, true, 0.0, true, 1.0);
	Duration = CreateConVar("sm_flashpunish_duration", "1.5", "Maximum duration that a flash can last for before it's considered team flash", _, true, 0.0, true, 7.0);
	MinFlAmount = CreateConVar("sm_flashpunish_amount", "180.0", "Minimum amount of flash amount before considering teammate flashed", _, true, 0.0, true, 255.0);
	PunishTime = CreateConVar("sm_flashpunish_time", "30.0", "Number of seconds to punish team flasher", _, true, 0.0);
	MaxFlashedPlayers = CreateConVar("sm_flashpunish_players", "3.0", "Number of players a team flasher flashes before acted on", _, true, 0.0);
	
	HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Pre);
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	
	LoadTranslations("flashpunish.phrases");
}

public OnConfigsExecuted()
{
	new Handle:version = INVALID_HANDLE;
	version = FindConVar("sm_flashpunish_version");
	
	if (version != INVALID_HANDLE)
	{
		SetConVarString(version, PLUGIN_VERSION);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				ResetPlayerVariables(i);
				IsAdmin[i] = CheckCommandAccess(i, "flash_protect_admin", ADMFLAG_GENERIC);
			}
		}
	}
	
	return APLRes_Success;
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ResetPlayerVariables(i);
		}
	}
}

ResetPlayerVariables(client)
{
	g_bFlashed[client] = false;
	NumFlashed[client] = 0;
	CanBuyFlash[client] = true;
	PlayerHasFlashEquipped[client] = false;
	LastNotification[client] = 0;
}

public OnClientConnected(client)
{
	ResetPlayerVariables(client);
	IsAdmin[client] = CheckCommandAccess(client, "flash_protect_admin", ADMFLAG_GENERIC);
	LastNotification[client] = GetTime();
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		ResetPlayerVariables(client);
	}
}

public Action:Timer_UnHook(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	CanBuyFlash[client] = true;
	return Plugin_Continue;
}

public Action:Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(Enabled))
	{
		return;
	}
	
	/* The client that was blinded */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	/* Check and see if the flash magnitude is high enough */
	if (GetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha") >= GetConVarFloat(MinFlAmount))
	{
		/* Get the max limited flash time without punishment */
		new Float:durationLimit = GetConVarFloat(Duration);
		
		/* If the player was flashed for longer than the allowed time, mark this player as being flashed for later processing. */
		if (GetEntPropFloat(client, Prop_Send, "m_flFlashDuration") >= durationLimit)
		{
			/* Mark player as flashed, handle in Event_FlashbangDetonate */
			g_bFlashed[client] = true;
		}
	}
}

/* Called when a flashbang has detonated (after the players have already been blinded) */
public Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(Enabled))
	{
		return;
	}

	/* The number of flashed players (i), and the player (client) that threw the flashbang */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	for (new i = 1; i <= MaxClients; i++)
	{
		/* Not a self flash, other player (i) marked as being flashed, in game, on same team, and alive */
		if (i != client && g_bFlashed[i] && IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && IsPlayerAlive(i))
		{
			NumFlashed[client]++; // Increment number of players the client flashed
			
			g_bFlashed[i] = false;
		}
	}
	
	if (IsAdmin[client])
	{
		NumFlashed[client] = 0;
	}
	
	/* If the number of flashed players is equal to or greater than the max allowed, let's restrict the player */
	if (NumFlashed[client] >= GetConVarInt(MaxFlashedPlayers))
	{
		CanBuyFlash[client] = false;
		CreateTimer(GetConVarFloat(PunishTime), Timer_UnHook, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		
		new spam = GetTime();
		if (spam - LastNotification[client] > 3)
		{
			LastNotification[client] = spam;
			CPrintToChatAll("%t", "Notify Punish", client, GetConVarInt(MaxFlashedPlayers));
		}
	}
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if (CanBuyFlash[client])
	{
		return Plugin_Continue;
	}
	
	/* Check if weapon is a flashbang, if so, do not allow player to use it */
	if (StrContains(weapon, "flashbang", false) != -1)
	{
		new spam = GetTime();
		if (spam - LastNotification[client] > 3)
		{
			LastNotification[client] = spam;
			CPrintToChat(client, "%t", "Notify Cant Buy");
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if (CanBuyFlash[client])
	{
		return Plugin_Continue;
	}
	
	// At this point, they cannot buy a flash, but may be switching to a flashbang
	
	if (weapon != 0) // They're switching weapons
	{
		/* Let's check if they're equipping a flash, so we know next time */
		decl String:weaponName[80];
		weaponName[0] = '\0';
		
		GetEntityClassname(weapon, weaponName, sizeof(weaponName));
		
		if (StrContains(weaponName, "flashbang", false) != -1)
		{ // They equipped a flashbang
			PlayerHasFlashEquipped[client] = true;
		}
		else
		{ // They did not equip a flashbang
			PlayerHasFlashEquipped[client] = false;
		}
		
		return Plugin_Continue; // We're done handling the weapon equip, finish here
	}
	
	if (PlayerHasFlashEquipped[client] && buttons & IN_ATTACK)
	{ // Do not allow them to use the flashbang, and notify them if 3 seconds has passed since this plugin last sent them a message.
		new spam = GetTime();
		if (spam - LastNotification[client] > 3)
		{
			LastNotification[client] = spam;
			CPrintToChat(client, "%t", "Notify Cant Use");
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}