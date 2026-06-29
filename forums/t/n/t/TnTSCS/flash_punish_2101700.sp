#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.1.3"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hMinFlashDuration = INVALID_HANDLE;
new Handle:g_hMinFlashAmount = INVALID_HANDLE;
new Handle:g_hPunishTime = INVALID_HANDLE;
new Handle:g_hMaxFlashedPlayers = INVALID_HANDLE;
new Handle:g_hUseAdminImmunity = INVALID_HANDLE;
new Handle:g_hDebug = INVALID_HANDLE;

new g_iNumFlashed[MAXPLAYERS+1];
new g_iLastNotificationTime[MAXPLAYERS+1];

new bool:g_bFlashed[MAXPLAYERS+1];
new bool:g_bIsPlayerAdmin[MAXPLAYERS+1];
new bool:g_bCanPlayerBuyUseFlash[MAXPLAYERS+1];
new bool:g_bPlayerHasFlashEquipped[MAXPLAYERS+1];
new bool:g_bDebug;

new Float:g_flFlashAlpha;
new Float:g_flFlashDuration;

new String:g_sDebugMsg[MAX_MESSAGE_LENGTH];
new String:g_sWeaponName[80];

new Handle:AllowClientMessage[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

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
	
	g_hEnabled = CreateConVar("sm_flashpunish_g_hEnabled", "1", "Enable/Disable the plugin", _, true, 0.0, true, 1.0);
	g_hMinFlashDuration = CreateConVar("sm_flashpunish_g_hMinFlashDuration", "1.5", "Maximum g_hMinFlashDuration that a flash can last for before it's considered team flash", _, true, 0.0, true, 7.0);
	g_hMinFlashAmount = CreateConVar("sm_flashpunish_amount", "180.0", "Minimum amount of flash amount before considering teammate flashed", _, true, 0.0, true, 255.0);
	g_hPunishTime = CreateConVar("sm_flashpunish_time", "30.0", "Number of seconds to punish team flasher", _, true, 0.0);
	g_hMaxFlashedPlayers = CreateConVar("sm_flashpunish_players", "3.0", "Number of players a team flasher flashes before acted on", _, true, 0.0);
	g_hUseAdminImmunity = CreateConVar("sm_flashpunish_immunity", "1.0", "Use admin immunity?  Default admin flag can be overriden with command \"flash_punish_admin\"", _, true, 0.0);
	g_hDebug = CreateConVar("sm_flashpunish_debug", "0", "Debug mode on (1) or off (0)", _, true, 0.0, true, 1.0);
	HookConVarChange(g_hDebug, OnConVarChanged);
	g_bDebug = GetConVarBool(g_hDebug);
	
	HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Pre);
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	
	LoadTranslations("flashpunish.phrases");
}

public OnConfigsExecuted()
{
	if (g_bDebug)
	{
		LogMessage("*** All configs have been executed ***");
	}
	
	new Handle:version = FindConVar("sm_flashpunish_version");
	if (version != INVALID_HANDLE)
	{
		SetConVarString(version, PLUGIN_VERSION);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
	{
		if (g_bDebug)
		{
			LogMessage("*** Plugin was late loaded ***");
		}
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				ResetPlayerVariables(i);
				g_bIsPlayerAdmin[i] = CheckCommandAccess(i, "flash_punish_admin", ADMFLAG_GENERIC);
			}
		}
	}
	
	return APLRes_Success;
}

public OnPluginEnd()
{
	if (g_bDebug)
	{
		LogMessage("*** Plugin Ended ***");
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ResetPlayerVariables(i);
		}
	}
}

public OnMapEnd()
{
	if (g_bDebug)
	{
		LogMessage("*** Map Ended ***");
	}
	
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
	if (g_bDebug)
	{
		LogMessage("Reset variables for %L", client);
	}
	
	g_bFlashed[client] = false;
	g_iNumFlashed[client] = 0;
	g_bCanPlayerBuyUseFlash[client] = true;
	g_bPlayerHasFlashEquipped[client] = false;
	g_iLastNotificationTime[client] = 0;
	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, SDK_WeaponCanSwitchTo);
	
	if (AllowClientMessage[client] != INVALID_HANDLE)
	{
		KillTimer(AllowClientMessage[client]);
		AllowClientMessage[client] = INVALID_HANDLE;
	}
}

public OnClientConnected(client)
{
	ResetPlayerVariables(client);
	g_bIsPlayerAdmin[client] = CheckCommandAccess(client, "flash_punish_admin", ADMFLAG_GENERIC);
	g_iLastNotificationTime[client] = GetTime();
	
	if (g_bDebug)
	{
		LogMessage("%L connected at %i", client, g_iLastNotificationTime[client]);
	}
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		if (g_bDebug)
		{
			LogMessage("%L Disconnected", client);
		}
		
		ResetPlayerVariables(client);
	}
}

public Action:Timer_UnHook(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (client == 0)
	{
		if (g_bDebug)
		{
			LogMessage("Client with serial [%i] disconnected before Timer_UnHook ended", serial);
		}
		
		return Plugin_Handled;
	}
	
	/* Let's reset this variable and mark them as able to buy/use flash */
	g_bCanPlayerBuyUseFlash[client] = true;
	
	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, SDK_WeaponCanSwitchTo);
	
	if (g_bDebug)
	{
		LogMessage("Timer_UnHook ended for %L, they are now allowed to buy/use flashbangs", client);
	}
	
	return Plugin_Continue;
}

public Action:SDK_WeaponCanSwitchTo(client, weapon)
{
	g_sWeaponName[0] = '\0';

	if (!GetEntityClassname(weapon, g_sWeaponName, sizeof(g_sWeaponName)))
	{ /* Something happened, cannot get the classname for the weapon entity index even though it should be valid. */
		return Plugin_Continue;
	}
	
	if (StrContains(g_sWeaponName, "flashbang", false) != -1)
	{
		if (g_bDebug)
		{
			LogMessage("%L tried to switch to a flashbang", client);
		}
		
		if (AllowClientMessage[client] == INVALID_HANDLE)
		{
			CPrintToChat(client, "%t", "Notify Cant Use");
			AllowClientMessage[client] = CreateTimer(1.5, Timer_ResetAllowClientMessage, client);
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Timer_ResetAllowClientMessage(Handle:timer, any:client)
{
	AllowClientMessage[client] = INVALID_HANDLE;
}

/* Players are blinded just prior to the flashbang_detonate event firing */
public Action:Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hEnabled))
	{
		return;
	}
	
	/* The client that was blinded */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_bDebug)
	{
		Format(g_sDebugMsg, sizeof(g_sDebugMsg), "%L was blinded.", client);
	}
	
	g_flFlashAlpha = GetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha");
	g_flFlashDuration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
	
	/* Check and see if the flash magnitude is high enough */
	if (g_flFlashAlpha >= GetConVarFloat(g_hMinFlashAmount))
	{
		if (g_bDebug)
		{
			Format(g_sDebugMsg, sizeof(g_sDebugMsg), "%s FlashMaxAlpha=%.2f", g_sDebugMsg, g_flFlashAlpha);
		}
		
		/* If the player was flashed for longer than the allowed time, mark this player as being flashed for later processing. */
		if (g_flFlashDuration >= GetConVarFloat(g_hMinFlashDuration))
		{
			/* Mark player as flashed, handle in Event_FlashbangDetonate */
			g_bFlashed[client] = true;
			
			if (g_bDebug)
			{
				Format(g_sDebugMsg, sizeof(g_sDebugMsg), "%s, FlashDuration=%.2f.  Marking as blinded.", g_sDebugMsg, g_flFlashDuration);
			}
			
		}
		else
		{
			if (g_bDebug)
			{
				Format(g_sDebugMsg, sizeof(g_sDebugMsg), "%s. However, FlashDuration was not enough to be marked as flashed.  FlashAlpha=%.2f, FlashDuration=%.2f", g_sDebugMsg, g_flFlashAlpha, g_flFlashDuration);
			}
		}
	}
	else
	{
		if (g_bDebug)
		{
			Format(g_sDebugMsg, sizeof(g_sDebugMsg), "%s  However, FlashAlpha was not enough to be marked as flashed.  FlashAlpha=%.2f, FlashDuration=%.2f", g_sDebugMsg, g_flFlashAlpha, g_flFlashDuration);
		}
	}
	
	if (g_bDebug)
	{
		LogMessage("%s", g_sDebugMsg);
	}
}

/* Called when a flashbang has detonated (after the players have already been blinded) */
public Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hEnabled))
	{
		return;
	}
	
	/* The number of flashed players (i), and the player (client) that threw the flashbang */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_bDebug)
	{
		Format(g_sDebugMsg, sizeof(g_sDebugMsg), "%L detonated a flashbang.", client);
	}
	
	new String:g_sPlayerList[MAX_MESSAGE_LENGTH];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		/* Not a self flash, other player (i) marked as being flashed, in game, on same team, and alive */
		if (i != client && g_bFlashed[i] && IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && IsPlayerAlive(i))
		{
			/* Increment number of players the client flashed */
			g_iNumFlashed[client]++;
			
			/* Mark player (i) as no longer flashed */
			g_bFlashed[i] = false;
			
			if (g_bDebug)
			{
				LogMessage("%N flashed %N", client, i);
				Format(g_sPlayerList, sizeof(g_sPlayerList), "%s[%N] ", g_sPlayerList, i);
			}
		}
	}
	
	if (GetConVarBool(g_hUseAdminImmunity) && g_bIsPlayerAdmin[client])
	{
		/* Admin threw the flash, make them immune from punishment */
		g_iNumFlashed[client] = 0;
		if (g_bDebug)
		{
			Format(g_sDebugMsg, sizeof(g_sDebugMsg), "%s They are an admin.", g_sDebugMsg);
		}
	}
	
	/* If the number of flashed players is equal to or greater than the max allowed, let's restrict the player */
	if (g_iNumFlashed[client] >= GetConVarInt(g_hMaxFlashedPlayers))
	{
		SDKHook(client, SDKHook_WeaponCanSwitchTo, SDK_WeaponCanSwitchTo);
		
		g_bCanPlayerBuyUseFlash[client] = false;
		CreateTimer(GetConVarFloat(g_hPunishTime), Timer_UnHook, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		
		new spam = GetTime();
		if (spam - g_iLastNotificationTime[client] > 3)
		{
			g_iLastNotificationTime[client] = spam;
			CPrintToChatAll("%t", "Notify Punish", client, GetConVarInt(g_hMaxFlashedPlayers));
		}
		
		if (g_bDebug)
		{
			Format(g_sDebugMsg, sizeof(g_sDebugMsg), "%s And flashed %i teammates.", g_sDebugMsg, g_iNumFlashed[client]);
			LogMessage("%s", g_sDebugMsg);
			LogMessage("Player List:");
			LogMessage("%s", g_sPlayerList);
		}
		
		g_iNumFlashed[client] = 0;
	}
	else
	{
		if (g_bDebug)
		{
			Format(g_sDebugMsg, sizeof(g_sDebugMsg), "%s Had zero team flashes", g_sDebugMsg);
		}
	}
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if (g_bCanPlayerBuyUseFlash[client])
	{
		return Plugin_Continue;
	}
	
	/* Check if weapon is a flashbang, if so, do not allow player to use it */
	if (StrContains(weapon, "flashbang", false) != -1)
	{
		new spam = GetTime();
		if (spam - g_iLastNotificationTime[client] > 3)
		{
			g_iLastNotificationTime[client] = spam;
			CPrintToChat(client, "%t", "Notify Cant Buy");
		}
		
		if (g_bDebug)
		{
			LogMessage("%L tried to buy a flashbang while restricted", client);
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == g_hDebug)
	{
		g_bDebug = GetConVarBool(cvar);
	}
}