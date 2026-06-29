#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools_functions>
#include <CustomPlayerSkins>

#define PLUGIN_NAME    "Cheaters Strike"
#define PLUGIN_VERSION "1.0"

// Convars
ConVar cColor[2];
ConVar csEnable;
ConVar csESPTime;
ConVar csCTMoney;
ConVar sv_force_transmit_players;

// Internal variables
int colors[2][4];
bool isUsingESP[MAXPLAYERS+1];
int playersInESP = 0;

// Timer
Handle ESPTimer;
bool ESPTimerActive = false;

// Plugin Info
public Plugin myinfo = {
	name        = PLUGIN_NAME,
	author      = "lordpollution",
	description = "Cheaters Strike",
	version     = PLUGIN_VERSION,
	url         = "gofreaks.eu"
};

// ####################################################################################
//
// Plugin start and default event handlers (by lordpollution & Mitchell)
//
// ####################################################################################
public OnPluginStart() {
	
	// Load existing server ConVars
	sv_force_transmit_players = FindConVar("sv_force_transmit_players");
	
	// Create plugin console variables on success
	csEnable = CreateConVar("cs_enable", "1", "Enable or disable CS:GO Cheaters Strike Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	csESPTime = CreateConVar("cs_esp_time", "35", "Sets the time, when ESP is given to the CT team.", FCVAR_NOTIFY, true, 5.0, true, 60.0);
	csCTMoney = CreateConVar("cs_ct_money", "1000", "Sets the money, CTs have every round.", FCVAR_NOTIFY);
	cColor[0] = CreateConVar("sm_advanced_esp_tcolor",  "192 160 96 64", "Determines R G B A glow colors for Terrorists team\nSet to \"0 0 0 0\" to disable", 0);
	//cColor[1] = CreateConVar("sm_advanced_esp_ctcolor", "96 128 192 64", "Determines R G B A glow colors for Counter-Terrorists team\nFormat should be \"R G B A\" (with spaces)", 0); // visible to CT team
	cColor[1] = CreateConVar("sm_advanced_esp_ctcolor", "0 0 0 0", "Determines R G B A glow colors for Counter-Terrorists team\nFormat should be \"R G B A\" (with spaces)", 0);
	
	// Add ConVar Change Notifiactions
	//csEnable.AddChangeHook(ConVarChange); 	// currently not required
	//csESPTime.AddChangeHook(ConVarChange); 	// currently not required
	//csCTMoney.AddChangeHook(ConVarChange); 	// currently not required
	cColor[0].AddChangeHook(ConVarChange);
	cColor[1].AddChangeHook(ConVarChange);

	for(int i = 0; i <= 1; i++) {
		retrieveColorValue(i);
	}

	// Hook up events
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("bomb_planted", Event_BombPlanted);
	
	playersInESP = 0;
}

// Handle Default Plugin Actions
public OnPluginEnd() {
	destoryGlows();
}

public void OnMapStart() {
	resetPlayerVars(0);
}

public void OnClientDisconnect(int client) {
	resetPlayerVars(client);
}

// ####################################################################################
//
// Event Hooks / Cheater Strike Mod Source Code (by lordpollution)
//
// ####################################################################################
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Apply round rules
	if (GetConVarBool(csEnable))
	{
		// Check if currently in pistol round or even before
		if (!pistolInProgress())
		{
			// Set money, kevlar, kit on CT players; Remove primary weapons from CTs
			for (new i = 1; i <= MaxClients; i++) 
			{ 
				if (IsValidClient(i)) 
				{ 
					// Only trigger for CT players (CS_TEAM_NONE 0, CS_TEAM_SPECTATOR 1, CS_TEAM_T 2, CS_TEAM_CT 3)
					if (GetClientTeam(i) == CS_TEAM_CT)
					{
						SetEntProp(i, Prop_Send, "m_iAccount", GetConVarInt(csCTMoney));	// Money
						SetEntProp(i, Prop_Send, "m_bHasHelmet", 1);						// Enable helmet
						SetEntProp(i, Prop_Send, "m_ArmorValue", 100);						// Set armor to 100
						SetEntProp(i, Prop_Send, "m_bHasDefuser", 1);						// Give kit
						
						// Remove primary weapon
						new ent = GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
						if (ent > -1)
						{
							RemovePlayerItem(i, ent);
						}
					}
				} 
			}
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(csEnable))
	{
		// If timer is still running, kill timer
		if (ESPTimerActive)
		{
			KillTimer(ESPTimer);
			ESPTimerActive = false;
		}
	
		// Remove ESP and rifles from CTs
		for (new i = 1; i <= MaxClients; i++) 
		{ 
			if (IsValidClient(i)) 
			{ 
				toggleGlow(i, false);
			} 
		}
	}
}

public void Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(csEnable))
	{
		// Check if currently in pistol round, if not activate timer
		if (!pistolInProgress())
		{
			// Setup timer for ESP enable
			ESPTimer = CreateTimer(GetConVarFloat(csESPTime), espEnable);
			ESPTimerActive = true;
		}
	}
}

public void Event_BombPlanted(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(csEnable))
	{
		// Enable ESP if timer is still running
		if (ESPTimerActive)
		{
			//TriggerTimer(ESPTimer);
			KillTimer(ESPTimer)
			ESPTimerActive = false;
		}
		espEnable(ESPTimer);
	}
}

// Function to enable ESP, usually to be called from ESPTimer
public Action espEnable(Handle timer)
{
	if (GetConVarBool(csEnable))
	{
		ESPTimerActive = false;
		if (GetConVarBool(csEnable))
		{
			// Immediatelly enable ESP for all CTs
			for (new i = 1; i <= MaxClients; i++) 
			{ 
				if (IsValidClient(i)) 
				{ 
					// Only trigger for CT players (CS_TEAM_NONE 0, CS_TEAM_SPECTATOR 1, CS_TEAM_T 2, CS_TEAM_CT 3)
					if (GetClientTeam(i) == CS_TEAM_CT) {
						toggleGlow(i, true);
					}
				} 
			}
			
			// Chat info
			PrintToChatAll("[CSMod] ----------------------------------");
			PrintToChatAll("[CSMod] The cheaters are among us...");
			PrintToChatAll("[CSMod] ----------------------------------");
		}
	}
}

// Function to check if a pistol round is in progress
public bool pistolInProgress()
{
	int score = CS_GetTeamScore(CS_TEAM_CT) + CS_GetTeamScore(CS_TEAM_T);
	if (score <= 0 || score == 15)
	{
		return true;
	}
	else
	{
		return false;
	}
}

// ####################################################################################
//
// ESP Module (by Mitchell, https://forums.alliedmods.net/showthread.php?t=291374)
//
// ####################################################################################
public void ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue) {
	for(int i = 0; i <= 1; i++) {
		if(convar == cColor[i]) {
			retrieveColorValue(i);
		}
	}
	checkGlows();
}

public void retrieveColorValue(int index) {
	char pieces[4][16];
	char color[64];
	cColor[index].GetString(color, sizeof(color));
	if(ExplodeString(color, " ", pieces, sizeof(pieces), sizeof(pieces[])) == 4) {
		for(int j = 0; j <= 3; j++) {
			colors[index][j] = StringToInt(pieces[j]);
		}
	}
}

public void toggleGlow(int client, bool value) {
	isUsingESP[client] = value;
	checkGlows();
}

public void resetPlayerVars(int client) {
	if(client == 0) {
		for(int i = 1; i <= MaxClients; i++) {
			resetPlayerVars(i);
		}
		return;
	}
	if(isUsingESP[client]) {
		isUsingESP[client] = false;
		playersInESP--;
	}
}

public void checkGlows() {
	//Check to see if some one has a glow enabled.
	playersInESP = 0;
	for(int client = 1; client <= MaxClients; client++) {
		if(isUsingESP[client]) {
			playersInESP++;
		}
	}
	//Force transmit makes sure that the players can see the glow through wall correctly.
	//This is usually for alive players for the anti-wallhack made by valve.
	destoryGlows();
	if(playersInESP > 0) {
		sv_force_transmit_players.SetString("1", true, false);
		createGlows();
	} else {
		sv_force_transmit_players.SetString("0", true, false);
	}
}

public void destoryGlows() {
	for(int client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client)) {
			CPS_RemoveSkin(client);
		}
	}
}

public void createGlows() {
	char model[PLATFORM_MAX_PATH];
	int skin = -1;
	int team = 0;
	//Loop and setup a glow on alive players.
	for(int client = 1; client <= MaxClients; client++) {
		//Ignore dead
		if(!IsClientInGame(client) || !IsPlayerAlive(client)) {
			continue;
		}
		//Create Skin
		GetClientModel(client, model, sizeof(model));
		skin = CPS_SetSkin(client, model, CPS_RENDER|CPS_TRANSMIT);
		if(skin > MaxClients && SDKHookEx(skin, SDKHook_SetTransmit, OnSetTransmit)) {
			team = GetClientTeam(client)-2;
			if(team >= 0) {
				SetupGlow(skin, colors[team]);
			}
		}
	}
}

public Action OnSetTransmit(int entity, int client) {
	if(isUsingESP[client] && EntRefToEntIndex(CPS_GetSkin(client)) != entity) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public void SetupGlow(int entity, int color[4]) {
	static offset;
	// Get sendprop offset for prop_dynamic_override
	if (!offset && (offset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1) {
		LogError("Unable to find property offset: \"m_clrGlow\"!");
		return;
	}

	// Enable glow for custom skin
	SetEntProp(entity, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(entity, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist", 10000.0);

	// So now setup given glow colors for the skin
	for(int i=0;i<4;i++) {
		SetEntData(entity, offset + i, color[i], _, true); 
	}
}

public bool IsValidClient(int client) {
	return (1 <= client && client <= MaxClients && IsClientInGame(client));
}