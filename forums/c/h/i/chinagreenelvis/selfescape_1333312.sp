/********************************************************************************************
* Plugin	: Self Escape (Left 1 Dead by MI 5)
* Version	: 1.3
* Game		: Left 4 Dead & 2
* Author	: MI 5 (modified by chinagreenelvis)
* Testers	: you
* Website	: www.chinagreenelvis.com
* 
* Purpose	: Automatically breaks free from special infected grasp
* 
* Version 1.3 by chinagreenelvis
*		- Removed button input requirement, escape is automatic and timed
*
* Version 1.2
* 	    - Fixed incapcacitated bug
* 
* Version 1.1
* 		- Added cvars l4dl1d_kick_bots and l4dl1d_escape_delay
* 	    - Fixed bug where the plugin would fail in L4D
* 		- Added hooks for events for which the survivor was freed in alternative way than just doing moves
* 		- Client arrays are now reset when a player disconnects
* 		- Fixed bug when an infected ensares a survivor and then another ensares the same one, preventing the survivor from escaping
* 	    - GetRandomInt is now replaced with GetURandomIntRange
* 
* Version 1.0
* 		- Initial release.
* 
**********************************************************************************************/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.2"
#define DEBUG 0

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "[L4D] & [L4D2] Self Escape",
	author = "MI 5 (modded by chinagreenelvis)",
	description = "Automatically breaks free from special infected grasp",
	version = PLUGIN_VERSION,
	url = "N/A"
}

// Variables



// Booleans

new bool:g_bL4DVersion;
new bool:g_bSurvivorisEnsnared[MAXPLAYERS+1];
new bool:g_bSurvivorisRidden[MAXPLAYERS+1];
new bool:g_bPounceStarted[MAXPLAYERS+1];

// Handles
new Handle:g_hEnable = INVALID_HANDLE;
new Handle:g_hNumberofPlayers = INVALID_HANDLE;
new Handle:g_hEscapeDelay = INVALID_HANDLE;

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
	#else 
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max) 
	#endif  
{
	// Checks to see if the game is a L4D game. If it is, check if its the sequel. L4DVersion is L4D if false, L4D2 if true.
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains("left4dead", "left4dead", false) == -1)
		#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3 
	return APLRes_Failure; 
	#else 
	return false; 
	#endif  
	else if (StrEqual(GameName, "left4dead2", false))
		g_bL4DVersion = true;
	
	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3 
	return APLRes_Success; 
	#else 
	return true; 
	#endif  
}

public OnPluginStart()
{
	g_hEnable = CreateConVar("cvar_selfescape_enable", "1", "1 enables the plugin, 0 disables", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	g_hEscapeDelay = CreateConVar("cvar_selfescape_delay", "6", "Delays a survivor's escape for this many seconds", FCVAR_PLUGIN|FCVAR_SPONLY);
	g_hNumberofPlayers = CreateConVar("cvar_selfescape_maxplayers", "4", "If the number of human players in your game goes higher than this number, it will turn off the plugin", FCVAR_PLUGIN|FCVAR_SPONLY);
	
	HookEvent("item_pickup", Event_RoundStart);
	HookEvent("choke_start", Event_ChokeStart);
	HookEvent("choke_end", Event_ChokeEnd);
	HookEvent("choke_stopped", Event_ChokeEnd);
	HookEvent("lunge_pounce", Event_LungePounce);
	HookEvent("pounce_end", Event_LungeEnd);
	HookEvent("pounce_stopped", Event_LungeEnd);
	if (g_bL4DVersion)
	{
		HookEvent("jockey_ride", Event_JockeyRide);
		HookEvent("jockey_ride_end", Event_JockeyRideEnd);
		HookEvent("charger_pummel_start", Event_ChargerPummel);
		HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
	}
	
	HookConVarChange(g_hEnable, ConVarEnablePlugin);
	
	
	//Autoconfig for plugin
	AutoExecConfig(true, "selfescape");
	
	// We register the version cvar
	CreateConVar("selfescape_version", PLUGIN_VERSION, "Version of Self Escape", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public ConVarEnablePlugin(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(g_hEnable))
	{	
		PrintToChatAll("Left For Dead Plugin has been enabled.");
		
		for (new s=1;s<=MaxClients;s++)
		{
			g_bSurvivorisEnsnared[s] = false;
			g_bPounceStarted[s] = false;
			g_bSurvivorisRidden[s] = false;
		}
	}
	else
	PrintToChatAll("Left For Dead (Single Player) Plugin has been disabled.");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hEnable))
		return;
	
	if (LeftStartArea())
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsFakeClient(client))
		return;
	
	if (!SuitableNumberOfSurvivors())
	{
		SetConVarBool(g_hEnable, false);
		return;
	}
	
	for (new s=1;s<=MaxClients;s++)
	{
		g_bSurvivorisEnsnared[s] = false;
		g_bPounceStarted[s] = false;
		g_bSurvivorisRidden[s] = false;
	}
}

public Action:Event_ChokeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hEnable))
		return;
	
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bPounceStarted[victim] = false;
	g_bSurvivorisRidden[victim] = false;
	g_bSurvivorisEnsnared[victim] = true;
	ShowKeyMessage(victim);
	#if DEBUG
	PrintToChatAll("Choking Started");
	#endif
}

public Action:Event_ChokeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bSurvivorisEnsnared[victim] = false;
	
	#if DEBUG
	PrintToChatAll("Choking Ended");
	#endif
}

public Action:Event_LungePounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hEnable))
		return;
	
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bSurvivorisRidden[victim] = false;
	g_bSurvivorisEnsnared[victim] = true;
	g_bPounceStarted[victim] = true;
	ShowKeyMessage(victim);
	#if DEBUG
	PrintToChatAll("Pounce Started");
	#endif
}

public Action:Event_LungeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (!g_bPounceStarted[victim])
		return;
	
	g_bSurvivorisEnsnared[victim] = false;
	
	#if DEBUG
	PrintToChatAll("Pounce Ended");
	#endif
}

public Action:Event_JockeyRide(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hEnable))
		return;
	
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bPounceStarted[victim] = false;
	g_bSurvivorisEnsnared[victim] = true;
	g_bSurvivorisRidden[victim] = true;
	ShowKeyMessage(victim);
	#if DEBUG
	PrintToChatAll("Riding started");
	#endif
}

public Action:Event_JockeyRideEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new rescuer = GetClientOfUserId(GetEventInt(event, "rescuer"));
	g_bSurvivorisEnsnared[victim] = false;
	
	if (rescuer != 0)
		g_bSurvivorisRidden[victim] = false;
	
	#if DEBUG
	PrintToChatAll("Riding Ended");
	#endif
}

public Action:Event_ChargerPummel(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hEnable))
		return;
	
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bPounceStarted[victim] = false;
	g_bSurvivorisRidden[victim] = false;
	g_bSurvivorisEnsnared[victim] = true;
	ShowKeyMessage(victim);
	#if DEBUG
	PrintToChatAll("Pummel started");
	#endif
}

public Action:Event_ChargerPummelEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	g_bSurvivorisEnsnared[victim] = false;
	
	#if DEBUG
	PrintToChatAll("Pummel Ended");
	#endif
}

public Action:OnPlayerRunCmd(Client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!GetConVarBool(g_hEnable))
		return;
	
	// Check if its a valid player
	if (Client == 0 || !IsClientInGame(Client) || IsFakeClient(Client)) return;
	
	if (GetEntProp(Client, Prop_Send, "m_isIncapacitated"))
		return; 
	
	if (g_bSurvivorisEnsnared[Client])
	{
		#if DEBUG
		PrintToChatAll("");
		#endif
		ShowKeyMessage(Client);
		
		if (GetConVarFloat(g_hEscapeDelay) == 0)
		{
			g_bSurvivorisEnsnared[Client] = false;
			
			SetConVarInt(FindConVar("director_no_death_check"), 1);
			
			if (g_bSurvivorisRidden[Client] == true)
				SetEntData(Client, FindSendPropInfo("CTerrorPlayer", "m_isIncapacitated"), 1, 1, true);
			else
			SetEntData(Client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"), 2, 1, true);
			
			CreateTimer(1.0,Timer_RestoreState, Client);
			CallOnPummelEnded(Client);
			// PrintToChat(Client, "You have escaped!");
			#if DEBUG
			PrintToChatAll("Breaking Free");
			#endif
		}
		else if (GetConVarFloat(g_hEscapeDelay) > 0)
		{
			g_bSurvivorisEnsnared[Client] = false;
			// PrintToChat(Client, "Escaping...");
			CreateTimer(GetConVarFloat(g_hEscapeDelay), Timer_EscapeDelayDetour, Client);
		}
	}
}

public Action:Timer_EscapeDelayDetour(Handle:timer, any:Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isIncapacitated"))
		return; 
	
	g_bSurvivorisEnsnared[Client] = false;
	
	SetConVarInt(FindConVar("director_no_death_check"), 1);
	
	if (g_bSurvivorisRidden[Client] == true)
		SetEntData(Client, FindSendPropInfo("CTerrorPlayer", "m_isIncapacitated"), 1, 1, true);
	else
	SetEntData(Client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"), 2, 1, true);
	
	CreateTimer(1.0,Timer_RestoreState, Client);
	CallOnPummelEnded(Client);
	// PrintToChat(Client, "You have escaped!");
	#if DEBUG
	PrintToChatAll("Breaking Free");
	#endif
}

public Action:Timer_RestoreState(Handle:timer, any:client)
{
	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isIncapacitated"), 0, 1, true);
	SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"), 0, 1, true);
	ResetConVar(FindConVar("director_no_death_check"), true, true);
	if (g_bSurvivorisRidden[client] == true)
		g_bSurvivorisRidden[client] = false;
}

ShowKeyMessage(client)
{
	{
		// PrintToChat(client, "");
	}
}

public OnClientDisconnect(client)
{	
	g_bSurvivorisEnsnared[client] = false;
	g_bPounceStarted[client] = false;
	g_bSurvivorisRidden[client] = false;
}

bool:SuitableNumberOfSurvivors ()
{
	new Survivors;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			if (GetClientTeam(i) == 2)
				Survivors++;
			
		if (Survivors > GetConVarInt(g_hNumberofPlayers))
			return false;
	}
	return true;
}

CallOnPummelEnded(client)
{
	if (!g_bL4DVersion)
		return;
	
	static Handle:hOnPummelEnded=INVALID_HANDLE;
	if (hOnPummelEnded==INVALID_HANDLE){
		new Handle:hConf = INVALID_HANDLE;
		hConf = LoadGameConfigFile("l4dl1d");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded");
		PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
		hOnPummelEnded = EndPrepSDKCall();
		CloseHandle(hConf);
		if (hOnPummelEnded == INVALID_HANDLE){
			SetFailState("Can't get CTerrorPlayer::OnPummelEnded SDKCall!");
			return;
		}            
	}
	SDKCall(hOnPummelEnded,client,true,-1);
}

bool:LeftStartArea()
{
	new ent = -1, maxents = GetMaxEntities();
	for (new i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		new offset = FindSendPropInfo("CTerrorPlayerResource", "m_hasAnySurvivorLeftSafeArea");
		if (offset > 0)
		{
			if (GetEntData(ent, offset))
			{
				if (GetEntData(ent, offset) == 1) return true;
			}
		}
	}
	return false;
}

stock GetURandomIntRange(min, max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}

