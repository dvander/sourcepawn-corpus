#pragma semicolon 1

#include <sourcemod>
#include <smlib>
#undef REQUIRE_PLUGIN
#include <zombiereloaded>

#define PLUGIN_NAME "ZR Tele Infected"
#define PLUGIN_VERSION "1.2.0"

ArrayList Spawn_Origins;
ArrayList Spawn_Angles;
float OriginBuffer[3];
float AnglesBuffer[3];
 
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "GoD-Tony & Agent Wesker",
	description = "Teleports all infected players back to spawn",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("zr_teleinfected_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("player_death", Event_PlayerDeath);
	
	Spawn_Origins = new ArrayList(32, 0);
	Spawn_Angles = new ArrayList(32, 0);
}

public OnMapStart()
{
	/* Store all of the spawnpoints */
	char sClassName[32];
	int iMaxEntities = GetMaxEntities();
	
	for (new iEntity = 0; iEntity < iMaxEntities; iEntity++)
	{
		if (!IsValidEntity(iEntity))
			continue;
		
		GetEdictClassname(iEntity, sClassName, 32);
		
		if (StrEqual("info_player_counterterrorist", sClassName) || StrEqual("info_player_terrorist", sClassName))
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", OriginBuffer);
			GetEntPropVector(iEntity, Prop_Send, "m_angRotation", AnglesBuffer);
			Spawn_Origins.PushArray(OriginBuffer);
			Spawn_Angles.PushArray(AnglesBuffer);
		}
	}
	if (Spawn_Origins.Length <= 0)
		ThrowError("Array size is null!");
}

public OnMapEnd()
{
	/* Clear our arrays for the next map */
	Spawn_Origins.Clear();
	Spawn_Angles.Clear();
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	/* There is already a Cvar for mother zombies */
	if (!motherInfect)
	{
		if (IsValidClient(client))
			TelePlayer(client);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	/* Adds support for older versions of ZR */
	char weapon[32];
	event.GetString("weapon", weapon, 32);
	
	if (StrEqual("zombie_claws_of_death", weapon))
	{
		int victimId = event.GetInt("userid");
		int victim = GetClientOfUserId(victimId);
		
		if (IsValidClient(victim))
			TelePlayer(victim);
	}
}

public void TelePlayer(int client) {

	int iSpawn = Math_GetRandomInt(0, (Spawn_Origins.Length - 1));
	
	if (iSpawn < 0)
		ThrowError("Random int is less than 0 what happened here?");
	
	Spawn_Origins.GetArray(iSpawn, OriginBuffer);
	Spawn_Angles.GetArray(iSpawn, AnglesBuffer);
	
	TeleportEntity(client, OriginBuffer, AnglesBuffer, NULL_VECTOR);
}

public bool IsValidClient(int client) {
	if ((client <= 0) || (client > MaxClients)) {
		return false;
	}
	if (!IsClientInGame(client)) {
		return false;
	}
	
	return true;
}  

