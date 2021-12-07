#pragma semicolon 1

#include <sourcemod>
#include <smlib>
#undef REQUIRE_PLUGIN
#include <zombiereloaded>

#define PLUGIN_NAME "ZR Tele Infected"
#define PLUGIN_VERSION "1.3.0"

//Create ConVar handles
ConVar g_ConVar_SpawnCap;

//Separate ConVar variables to prevent looping in hooks
int g_SpawnCap = 5;

//Global handles
ArrayList Spawn_Origins;
ArrayList Spawn_Angles;
int ctCounter, tCounter;
 
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "GoD-Tony & Agent Wesker",
	description = "Teleports all infected players back to spawn",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() {
	//Version ConVar
	CreateConVar("zr_teleinfected_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	//Spawn Cap ConVar
	g_ConVar_SpawnCap = CreateConVar("zr_teleinfected_spawncap", "5.0", "How many of each teams spawn to save in memory.", _, true, 1.0, true, 30.0);
	g_SpawnCap = GetConVarInt(g_ConVar_SpawnCap);
	HookConVarChange(g_ConVar_SpawnCap, OnConVarChanged);
	
	//Hook player death event
	HookEvent("player_death", Event_PlayerDeath);
	
	//Initialize arrays
	Spawn_Origins = new ArrayList(3, 0);
	Spawn_Angles = new ArrayList(3, 0);
}

public void OnConVarChanged(ConVar convar, const char[] oldVal, const char[] newVal) {
	//Hook ConVar changes
	if (convar == g_ConVar_SpawnCap) {
		g_SpawnCap = StringToInt(newVal);
	}
}

public OnMapStart() {
	//This should be re-hooked every map
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	//Reset counters
	ctCounter = 0;
	tCounter = 0;
}

public OnMapEnd() {
	// Clear our arrays for the next map
	Spawn_Origins.Clear();
	Spawn_Angles.Clear();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	//Get the client
	int userID = event.GetInt("userid");
	int user = GetClientOfUserId(userID);
	
	//Validate the client
	if (!IsValidClient(user)) {
		return;
	}
	
	//They should be alive
	if (!IsPlayerAlive(user)) {
		return;
	}
	
	float pAbsOrigin[3], pAbsAngles[3];
	GetClientAbsOrigin(user, pAbsOrigin); //Player origin
	GetClientAbsAngles(user, pAbsAngles); //Player angles
	
	//Get both team spawns
	if (GetClientTeam(user) == 2 && tCounter < g_SpawnCap) {
		//Count this team
		tCounter++;
		PrintToServer("[TeleInfected] Capturing terrorist spawn.");
	} else if (GetClientTeam(user) == 3 && ctCounter < g_SpawnCap) {
		//Count this team
		ctCounter++;
		PrintToServer("[TeleInfected] Capturing counter-terrorist spawn.");
	} else if (tCounter >= g_SpawnCap && ctCounter >= g_SpawnCap) {
		//We don't need to hook this anymore
		PrintToServer("[TeleInfected] Finished capturing spawns.");
		UnhookEvent("player_spawn", Event_PlayerSpawn);
		//We're done here
		return;
	} else {
		//This team has met the cap
		return;
	}
	
	bool skipVector = false;
	
	//If array is not empty, check for duplicates
	if (Spawn_Origins.Length > 0) {
		int aIndex, bIndex, cIndex;
		aIndex = Spawn_Origins.FindValue(pAbsOrigin[0], 0);
		bIndex = Spawn_Origins.FindValue(pAbsOrigin[1], 1);
		cIndex = Spawn_Origins.FindValue(pAbsOrigin[2], 2);
		if (aIndex != -1 && bIndex != -1 && cIndex != -1) {
			if (aIndex == bIndex && bIndex == cIndex) {
				//This vector is already in the array
				PrintToServer("[TeleInfected] Duplicate spawn, aborting capture.");
				skipVector = true;
			}
		}
	
	}
	
	//Skip vector if it already exists
	if (!skipVector) {
		//Push the vectors to the end of the array list
		Spawn_Origins.PushArray(pAbsOrigin, 3);
		Spawn_Angles.PushArray(pAbsAngles, 3);
		PrintToServer("[TeleInfected] Successfully captured spawn #%i.", Spawn_Origins.Length);
	}
	
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn) {

	// There is already a Cvar for mother zombies
	if (!motherInfect)
	{
		if (IsValidClient(client))
			TelePlayer(client);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	// Adds support for older versions of ZR
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
	//Make sure we have at least one spawn saved in array list
	if (Spawn_Origins.Length > 0) {
		int iSpawn = Math_GetRandomInt(0, (Spawn_Origins.Length - 1));
		
		if (iSpawn < 0)
			ThrowError("Random int is less than 0 what happened here?");
			
		float OriginBuffer[3], AnglesBuffer[3];
		Spawn_Origins.GetArray(iSpawn, OriginBuffer);
		Spawn_Angles.GetArray(iSpawn, AnglesBuffer);
		
		TeleportEntity(client, OriginBuffer, AnglesBuffer, NULL_VECTOR);
	} else {
		PrintToServer("[TeleInfected Error] No spawns saved in array.");
	}
}

public bool IsValidClient(int client) {
	//Client checks
	if ((client <= 0) || (client > MaxClients)) {
		return false;
	}
	if (!IsClientInGame(client)) {
		return false;
	}
	
	return true;
}  

