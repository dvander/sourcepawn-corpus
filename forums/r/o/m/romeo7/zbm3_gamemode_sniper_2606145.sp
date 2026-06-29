#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

int glowentity[MAXPLAYERS + 1] = {-1,...};
int g_iEntity[MAXPLAYERS + 1];
bool gAwp[MAXPLAYERS+1];

/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Game Mode: Sniper",
    author          = "Romeo",
    version         = "1.1",
    url             = ""
}

/**
 * @section Information about human class.
 **/
#define GAME_MODE_NAME                  "Sniper"
#define GAME_MODE_DESCRIPTION           "Mode sniper" // String has taken from translation file
#define GAME_MODE_SOUND                 "ROUND_SNIPER_SOUNDS" // Sounds has taken from sounds file
#define GAME_MODE_CHANCE                20 // If value has 0, mode will be taken like a default
#define GAME_MODE_MIN_PLAYERS           0
#define GAME_MODE_RATIO                 1.0
#define GAME_MODE_INFECTION             NO
#define GAME_MODE_RESPAWN               NO
#define GAME_MODE_SURVIVOR              NO
#define GAME_MODE_NEMESIS               NO
/**
 * @endsection
 **/

// Initialize game mode index
int gSniper;
#pragma unused gSniper

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initilizate game mode
        gSniper = ZP_RegisterGameMode(GAME_MODE_NAME, 
        GAME_MODE_DESCRIPTION, 
        GAME_MODE_SOUND, 
        GAME_MODE_CHANCE, 
        GAME_MODE_MIN_PLAYERS, 
        GAME_MODE_RATIO, 
        GAME_MODE_INFECTION,
        GAME_MODE_RESPAWN,
        GAME_MODE_SURVIVOR,
        GAME_MODE_NEMESIS);
    }
}

/**
 * Called after a zombie round is started.
 **/
public void ZP_OnZombieModStarted(int modeIndex)
{
	// Validate plague mode
	if(modeIndex == gSniper)
	{
		int clientIndex = ZP_GetRandomHuman();
		
		if(GetConVarBool(FindConVar("zp_sniper_glow")))
		{
			SetLightSniper(clientIndex);
		}
		
		for(int i = 0; i < 5; i++)
		{
			int weapons = -1;
			while((weapons = GetPlayerWeaponSlot(clientIndex, i)) != -1)
			{
				if(IsValidEntity(weapons))
				{
					RemovePlayerItem(clientIndex, weapons);
				}
			}
		}
	
		GivePlayerItem(clientIndex, "weapon_awp");
		GivePlayerItem(clientIndex, "weapon_knife");
		FakeClientCommandEx(clientIndex, "use weapon_awp");
		SetEntData(clientIndex, FindDataMapInfo(clientIndex, "m_iHealth"), ZP_GetZombieAmount()*GetConVarInt(FindConVar("zp_sniper_health")), 4, true);
		gAwp[clientIndex] = true;
		SDKHook(clientIndex,SDKHook_WeaponDrop,Event_WeaponDrop);
    }
}

/**
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
	// Hook player events
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);
	
	// ConVars
	CreateConVar("zp_sniper_ammopack", "1", "Kill award for Sniper", 0, true, 0.0);
	CreateConVar("zp_sniper_health", "100", "Health for Sniper (zombies count * health ratio)", 0);
	CreateConVar("zp_sniper_glow", "1", "Aura & Glow for Sniper", 0, true, 0.0, true, 1.0);
	CreateConVar("zp_sniper_glow_radius", "10", "Aura radius for Sniper", 0, true, 0.0, true, 100.0);
	
	RegConsoleCmd("zweaponmenu", BlockMenu);
	RegConsoleCmd("zitemmenu", BlockMenu);
	
	AutoExecConfig(true, "zombieplague_sniper");
}

public Action EventPlayerSpawn(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get all required event info
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid"));

	#pragma unused clientIndex
	
	// Validate client
	if (!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	gAwp[clientIndex] = false;
	SDKUnhook(clientIndex,SDKHook_WeaponDrop,Event_WeaponDrop);
}

public Action Event_WeaponDrop(int client, int weapon)
{
    return Plugin_Handled;
}

public Action EventPlayerDeath(Event hEvent, const char[] sName, bool dontBroadcast) 
{
	int userid = GetEventInt(hEvent, "userid");
	int clientIndex = GetClientOfUserId(userid);
	
	if((ZP_GetCurrentGameMode() == ZP_GetServerGameMode(GAME_MODE_NAME)) && ZP_IsPlayerHuman(clientIndex))
	{
		if(GetConVarBool(FindConVar("zp_sniper_glow")) && ZP_IsPlayerHuman(clientIndex))
		{
			RemoveLight(clientIndex);
		}
	}
	
	return Plugin_Continue;
}

public void OnClientPutInServer(int clientIndex)
{
	SDKHook(clientIndex, SDKHook_OnTakeDamage, TakeDamageCallback);
	glowentity[clientIndex]=-1;
}

public Action TakeDamageCallback(int victim, int &clientIndex, int &inflictor, float &damage, int &damagetype)
{
	char weaponawp[32];
	
	if(inflictor > 0 && inflictor <= MaxClients)
	{
		int weapon = GetEntPropEnt(inflictor, Prop_Send, "m_hActiveWeapon");
		GetEdictClassname(weapon, weaponawp, 32);
	}
	
	if(StrContains(weaponawp, "awp") == -1 || !IsValidClient(clientIndex) == gAwp[clientIndex] || !IsValidClient(victim))
	{
		return Plugin_Continue;
	}
	
	damage = float(GetClientHealth(victim) + GetClientArmor(victim));
	
	static int nAppliedDamage[MAXPLAYERS+1];
	nAppliedDamage[clientIndex] += RoundFloat(damage);
	int bonusd = GetConVarInt(FindConVar("zp_bonus_damage_human"));
	int bonusk = GetConVarInt(FindConVar("zp_bonus_kill_zombie"));
	int ammo = nAppliedDamage[clientIndex] / bonusd;
	ZP_SetClientAmmoPack(clientIndex, ZP_GetClientAmmoPack(clientIndex) - ammo - bonusk + GetConVarInt(FindConVar("zp_sniper_ammopack")));
	nAppliedDamage[clientIndex] -= ammo * bonusd;
	
	return Plugin_Changed;
}

public Action BlockMenu(int clientIndex, int args) 
{
	if(ZP_GetCurrentGameMode() == ZP_GetServerGameMode(GAME_MODE_NAME))
	{
		FakeClientCommand(clientIndex, "zmainmenu")
		ClientCommand(clientIndex, "play buttons/button11.wav");
	}
}

public Action SetLightSniper(int clientIndex)
{
	// Aura
	int iEntity = CreateEntityByName("light_dynamic");
	glowentity[clientIndex]=iEntity;
	DispatchKeyValue(iEntity, "brightness", "0");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 75.0);
	DispatchKeyValue(iEntity, "style", "1");
	DispatchKeyValue(iEntity, "_light", "0 100 0 100");
	DispatchKeyValueFloat(iEntity, "distance", GetConVarInt(FindConVar("zp_sniper_glow_radius")) * 100.0);
	DispatchSpawn(iEntity);
	
	float m_flClientOrigin[3];
	GetClientAbsOrigin(clientIndex, m_flClientOrigin);
	
	TeleportEntity(iEntity, m_flClientOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(iEntity, MOVETYPE_NONE);
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", clientIndex, iEntity, 0);
	
	// Glow
	char sBuffer[128];
	GetClientModel(clientIndex, sBuffer, sizeof(sBuffer));
	
	int Entity = CreatePlayerModel(clientIndex, sBuffer);
	
	SetEntProp(Entity, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(Entity, Prop_Send, "m_nGlowStyle", 1); // 0 - esp / 1,2 - glow
	SetEntPropFloat(Entity, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow"), 0, _, true);    // Red 
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow") + 1, 150, _, true); // Green 
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow") + 2, 0, _, true); // Blue 
	SetEntData(Entity, GetEntSendPropOffs(Entity, "m_clrGlow") + 3, 100, _, true); // Alpha 
}

public Action RemoveLight(int clientIndex)
{
	if(!(clientIndex<65&&clientIndex>0))
	{
		return;
	}
	
	AcceptEntityInput(glowentity[clientIndex], "kill");
	glowentity[clientIndex]=-1;
}

int CreatePlayerModel(int client, const char[] sBuffer)
{
	RemoveModel(client);
	
	int iEntity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(iEntity, "model", sBuffer);
	DispatchKeyValue(iEntity, "solid", "0");
	DispatchSpawn(iEntity);
	
	SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
	SetEntityRenderColor(iEntity, 255, 255, 255, 0);
	
	SetEntProp(iEntity, Prop_Send, "m_fEffects", (1 << 0)|(1 << 4)|(1 << 6)|(1 << 9));
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", client, iEntity, 0);
	SetVariantString("primary");
	AcceptEntityInput(iEntity, "SetParentAttachment", iEntity, iEntity, 0);
	
	g_iEntity[client] = EntIndexToEntRef(iEntity);
	return iEntity;
}

void RemoveModel(int client)
{
	int iEntity = EntRefToEntIndex(g_iEntity[client]);
	if(iEntity != INVALID_ENT_REFERENCE && iEntity > 0 && IsValidEntity(iEntity)) AcceptEntityInput(iEntity, "Kill");

	g_iEntity[client] = 0;
}

stock bool IsValidClient(int clientIndex, bool bAlive = false)
{
	if(clientIndex >= 1 && clientIndex <= MaxClients && IsClientConnected(clientIndex) && IsClientInGame(clientIndex) && (bAlive == false || IsPlayerAlive(clientIndex)))
	{
		return true;
	}
	
	return false;
}