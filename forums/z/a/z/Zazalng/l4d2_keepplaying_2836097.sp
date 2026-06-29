#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2"
#define DEBUG_LOGGING 1  // Set to 1 to enable logging, 0 to disable

public Plugin myinfo = 
{
    name = "[Left 4 Dead 2] Keep playing!!",
    author = "Zazalng",
    description = "Alternative Versus where everyone start as survivor and once died will become infected team hunt down the remaining survivor team.",
    version = PLUGIN_VERSION,
    url = "https://discord.gg/ZJWuzSy"
};

// Struct to store dead survivor info
enum struct SurvivorData{
    int steamId;
    bool isDead;
}

ArrayList g_Survivors;

// Plugin Initialization
public void OnPluginStart(){
    Trigger_Reset();
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post); // Handle when Survivor death
    HookEvent("defibrillator_used", Event_DefibSuccess, EventHookMode_Post); // Handle when Survivor revive via defib_unit only
    HookEvent("player_activate", Event_PlayerConnect, EventHookMode_Post); // Handle of register Player into dataset for protect exploit disconnected/connected

    LogMessage("Plugin Initialized: %s v%s", "[Left 4 Dead 2] Keep playing!!", PLUGIN_VERSION);
}

public void OnMapStart(){
	Trigger_Reset();
}

// Handles when a survivor successfully revives another
void Event_DefibSuccess(Event event, const char[] name, bool dontBroadcast){
    //TODO
}

// Handles when a new player joins (spawns)
void Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast){
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
    if (!IsValidClient(client)) return;
	LogMessage("Event_PlayerConnect was Trigger by %N (ID: %d)", client, client);

	RequestFrame(AssignClientToTeam,client);
}

// Check if the client is valid
bool IsValidClient(int client){
    return client > 0 && client <= MaxClients && Trigger_Identify(client) != 0 && !IsFakeClient(client);
}

// Assign the client to the appropriate team based on steamId
void AssignClientToTeam(any client){
	int steamId = Trigger_Identify(client);
    if (Trigger_Identify_Exist(steamId)){
        AssignExistingClientToTeam(client, steamId);
    } else{
        RegisterNewClient(client, steamId);
    }
}

// Logic for assigning existing clients
void AssignExistingClientToTeam(int client, int steamId){
    if (Trigger_Identify_Get_Dead(steamId)) {
        ChangeClientTeam(client, 3);
    } else{
        ChangeClientTeam(client, 2);
    }
}

// Register new clients and assign a team
void RegisterNewClient(int client, int steamId) {
    Trigger_Identify_Register(steamId);
    ChangeClientTeam(client, 2);
}

// Handles when a survivor dies
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast){	
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!IsValidClient(client) || GetClientTeam(client) != 2 || GetEventBool(event, "victimisbot")) return;
	
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	float damageType = GetEventFloat(event, "type")
	LogMessage("Event_PlayerDeath was Trigger by %N (ID: %d) \nSlay by (ID: %d) with (DT: %f)", client, client, attacker, damageType);
	ChangeClientTeam(client, 3);
    PrintToChatAll("\x04[INFO]\x01 %N has fallen! Can they be saved?", client);
	
	g_Survivors.Erase(GetSurvivorIndex(Trigger_Identify(client)));
	SurvivorData data;
	CreateSurvivorData(Trigger_Identify(client), true, data);
	g_Survivors.PushArray(data);
}

// Supposed to be called for cleaning Array due to MapChange/RestartRound/SwitchRound
void Trigger_Reset(){
	if (g_Survivors != INVALID_HANDLE){
		CloseHandle(g_Survivors);
	}
	
	g_Survivors = new ArrayList(sizeof(SurvivorData));
}

// Get SteamId once confirm this client was valied
int Trigger_Identify(int clientId){
	return GetSteamAccountID(clientId,IsClientConnected(clientId));
}

// Helper function to create SurvivorData
void CreateSurvivorData(int steamId, bool isDead, SurvivorData data){
    data.steamId = steamId;
    data.isDead = isDead;
}

// Register a fresh player on each map
void Trigger_Identify_Register(int steamId){
    SurvivorData data;
    CreateSurvivorData(steamId, false, data);
    g_Survivors.PushArray(data);
}

// Verify if a steamId exists in SurvivorData and check if they are dead
bool Trigger_Identify_Get_Dead(int steamId){
    int survivorIndex = GetSurvivorIndex(steamId);
	
    if (survivorIndex != -1){
        SurvivorData data;
        g_Survivors.GetArray(survivorIndex, data);
        return data.isDead;
    }
	
    return false;
}

// Check if a player exists in SurvivorData
bool Trigger_Identify_Exist(int steamId){
    return GetSurvivorIndex(steamId) != -1;
}

// Helper function to find the index of a SurvivorData with the given steamId
int GetSurvivorIndex(int steamId){
    for (int i = 0; i < g_Survivors.Length; i++){
        SurvivorData data;
        g_Survivors.GetArray(i, data);
        if (data.steamId == steamId){
            return i; // Return the index if found
        }
    }
    return -1; // Return -1 if not found
}