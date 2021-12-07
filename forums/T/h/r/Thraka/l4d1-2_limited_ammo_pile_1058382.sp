/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = 
{
	name = "[L4D1/2] Limited Ammo Piles",
	author = "Thraka",
	description = "Once everyone has used the same ammo pile at least once, it is removed.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=115898"
}

enum ammo_pile_usage
{
	APU_EntityUsed,
	APU_IndividualUses
}
new Handle:ammoPileInfoArray;
new Handle:PlayerMappingAmmosArray[MAXPLAYERS + 1];
new Handle:cvar_pluginOn;

new bool:g_pluginOn = true;
new bool:g_mapFinale = true;

public OnPluginStart()
{
	// Require Left 4 Dead 1 or 2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false))
	{
		SetFailState("Plugin supports Left 4 Dead or Left 4 Dead 2 only.");
	}
		
	CreateConVar("l4d_limited_ammo_pile_ver", PLUGIN_VERSION, "Version of the plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	cvar_pluginOn = CreateConVar("l4d_limited_ammo_pile_on", "1", "If the Limited Ammo Piles plugin is on or off", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookConVarChange(cvar_pluginOn, OnOffCvarChanged);
	
	HookEvent("player_use", Event_PlayerUse);
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{
	g_mapFinale = FindEntityByClassname(-1, "trigger_finale") != -1;
	
	if (g_mapFinale || g_pluginOn == false)
		UnhookEvent("player_use", Event_PlayerUse);
	else
		HookEvent("player_use", Event_PlayerUse);
	
	for (new i = 0; i < MAXPLAYERS + 1; i++)
	{
		new Handle:trie = PlayerMappingAmmosArray[i]
		if (trie != INVALID_HANDLE)
			ClearTrie(trie);
	}
	
	if (ammoPileInfoArray == INVALID_HANDLE)
		ammoPileInfoArray = CreateArray(ammo_pile_usage)
	else
		ClearArray(ammoPileInfoArray);
}

public OnPluginEnd()
{
	ClearArray(ammoPileInfoArray);
	CloseHandle(ammoPileInfoArray);
	
	for (new i = 0; i < MAXPLAYERS + 1; i++)
	{
		new Handle:trie = PlayerMappingAmmosArray[i]
		if (trie != INVALID_HANDLE)
			ClearTrie(trie);
	}	
}

public OnOffCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_pluginOn = GetConVarBool(cvar_pluginOn);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	OnMapStart();
}

public Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_pluginOn == false || g_mapFinale == true)
		return;
	
	new playerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new entityId = GetEventInt(event, "targetid");
	
	decl String:ent_name[64];
	
	if (IsValidEdict(entityId))
	{
		GetEdictClassname(entityId, ent_name, sizeof(ent_name)); //get the entities name
		
		if (StrEqual(ent_name, "weapon_ammo_spawn", false))
		{
			decl String:ent_id_string[10];
			IntToString(entityId, ent_id_string, sizeof(ent_id_string));
			TrimString(ent_id_string);
			new bool:tempValue;
			
			if (PlayerMappingAmmosArray[playerClient] == INVALID_HANDLE)
				PlayerMappingAmmosArray[playerClient] = CreateTrie();
				
			if (GetTrieValue(PlayerMappingAmmosArray[playerClient], ent_id_string, tempValue) == false)
			{
				//PrintToChatAll("Entity-NOT USED BEFORE");
				SetTrieValue(PlayerMappingAmmosArray[playerClient], ent_id_string, true);
			}
			else
			{
				//PrintToChatAll("Entity-USED BEFORE");
				return;
			}
			
			new ammo[ammo_pile_usage];
			new ammoPileArrayIndex;
			new bool:hasBeenUsed = AmmoPileDataExists(entityId, ammo, ammoPileArrayIndex);
			
			if (hasBeenUsed == false)
			{
				//PrintToChatAll("Entity: %i New Use!", entityId);
				
				ammo[APU_EntityUsed] = entityId;
				ammo[APU_IndividualUses] = 1;
				PushArrayArray(ammoPileInfoArray, ammo);
			}
			else
			{
				// Each player has used it
				if (ammo[APU_IndividualUses] == 3)
				{
					//PrintToChatAll("Entity: %i %s DIE", entityId, ent_name);
					AcceptEntityInput(entityId, "Kill")
					if (IsClientInGameHuman(playerClient))
						PrintHintText(playerClient, "Ammunition pile has been depleted.");
				}
				else
				{
					AmmoPileAddUse(ammoPileArrayIndex);
					//PrintToChatAll("Entity: %i TimesUsed %i", entityId, ammo[APU_IndividualUses] + 1);
				}
			}
		}
	}
	return;	
}

stock bool:AmmoPileDataExists(ammoPileEntity, ammoPile[ammo_pile_usage], &ammoPileArrayIndex)
{
	new size = GetArraySize(ammoPileInfoArray);
	for (new i = 0; i < size; i++)
	{
		new ammo[ammo_pile_usage];
		GetArrayArray(ammoPileInfoArray, i, ammo);
		if (ammo[APU_EntityUsed] == ammoPileEntity)
		{
			ammoPile = ammo
			ammoPileArrayIndex = i;
			return true;
		}
	}
	return false;
}

stock AmmoPileAddUse(index)
{
	new size = GetArraySize(ammoPileInfoArray);
	if (index < size)
	{
		new ammo[ammo_pile_usage];
		GetArrayArray(ammoPileInfoArray, index, ammo);
		ammo[APU_IndividualUses]++;
		SetArrayArray(ammoPileInfoArray, index, ammo);
	}
}

// Thx atomic!
stock bool:IsClientInGameHuman(client)
{
	if (client > 0) return IsClientInGame(client) && !IsFakeClient(client);
	else return false;
}

// Thx atomic
stock GetMaxSurvivors()
{
	return GetConVarInt(FindConVar("survivor_limit"));
}
