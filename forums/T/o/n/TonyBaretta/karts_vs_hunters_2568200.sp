#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>
#include <tf2items>
#undef REQUIRE_EXTENSIONS
#include <SteamWorks>
#define REQUIRE_EXTENSIONS
#pragma newdecls required

#define PLUGIN_VERSION	 "1.2"

float initialpos[MAXPLAYERS+1][3];
float currentpos[MAXPLAYERS+1][3];
Handle TimerSpam = INVALID_HANDLE;
ConVar plugin_enable;
int kvsclass = 1;
bool IsHunter[MAXPLAYERS+1] = false;
bool round_start = false;
bool waiting = false;
bool jointeamlocked = false;
int restarts = 0;
bool g_enabled = false;
bool FirstJoin[MAXPLAYERS+1] = false;
bool g_bSteamWorks = false;
ConVar GameDescription;
public Plugin myinfo =
{
	name = "Karts Vs Hunters",
	author = "TonyBaretta",
	description = "Emulation of cars vs hunters GTA5",
	version = PLUGIN_VERSION,
	url = "http://www.wantedgov.it"
};
public void OnPluginStart()
{
	CreateConVar("kvh_version", PLUGIN_VERSION, "Kart VS Hunters version",FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	plugin_enable = CreateConVar("kvh_enable", "1", "Enables/Disables Kart VS Hunters.");
	GameDescription = CreateConVar("kvh_gamedescription", "0", "Change Game description  STEAMWORKS is needed.");
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("player_spawn", OnPlayerSpawned, EventHookMode_PostNoCopy);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_stalemate", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_waiting_begins", WaitingforStart);
	RegConsoleCmd("jointeam",CommandJoinTeam);
	//RegConsoleCmd("join_class",CommandJoinTeam);
	//RegConsoleCmd("joinclass",CommandJoinTeam);
	RegConsoleCmd("kill",CommandJoinTeam);
	//RegConsoleCmd("explode",CommandJoinTeam);
	RegConsoleCmd("sm_kvhhelp", cmd_help);
	AutoExecConfig(true, "kart_vs_hunters");
}
public void OnMapStart()
{
	char map[128];
	GetCurrentMap(map, sizeof(map));
	if (StrContains(map, "kvh_", false) == 0)
	{
		SetConVarBool(plugin_enable, true);
		g_enabled = true;
	}
	if (StrContains(map, "kvh_", false) == -1)
	{
		SetConVarBool(plugin_enable, false);
		g_enabled = false;
		return;
	}
	if(!g_enabled) 
	{
		return;
	}
	if(plugin_enable.BoolValue){
		ServerCommand("sm_cvar tf_halloween_kart_dash_speed 875");
		ServerCommand("sm_cvar tf_halloween_kart_impact_air_scale 1.5f");
	}
	else{
		ServerCommand("sm_cvar tf_halloween_kart_dash_speed 1000");
		ServerCommand("sm_cvar tf_halloween_kart_impact_air_scale 0.75f");
	}
}
public void OnClientPutInServer(int client) {
	FirstJoin[client]= true;
	DisplayHelp(client);
}
public Action CommandJoinTeam(int client, int args)
{
	if(plugin_enable.BoolValue && g_enabled){
		if(IsValidClient(client) && GetClientTeam(client) == 2 && !jointeamlocked){
			if(TF2_IsPlayerInCondition(client, view_as<TFCond>(82)))
			{
				TF2_RemoveCondition(client, view_as<TFCond>(82));
				FakeClientCommand(client,"explode");
			}		
		}
		if(IsValidClient(client) && GetClientTeam(client) == 2 && jointeamlocked){
			PrintToChat(client,"\x03[Karts Vs Hunters] \x06 You can't change team after 20 sec from roundstart");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public Action cmd_help(int client, int args)
{
	if (IsValidClient(client))
	{
		DisplayHelp(client);
	}
	return Plugin_Handled;
}
public Action OnPlayerSpawned(Event event, const char[] name, bool dontBroadcast)
{
	if(plugin_enable.BoolValue && g_enabled){
		int userid = GetEventInt(event, "userid");
		int iClient = GetClientOfUserId(userid);
		if (IsValidClient(iClient) && GetClientTeam(iClient) == 2)
		{
			if(TF2_IsPlayerInCondition(iClient, TFCond_Taunting))
			{
				TF2_RemoveCondition(iClient, TFCond_Taunting);
			}
			if(IsFakeClient(iClient)){
				if (TF2_GetPlayerClass(iClient) != TFClass_Sniper)
				{
					TF2_SetPlayerClass(iClient, TFClass_Sniper, false, true);
					TF2_RespawnPlayer(iClient);
				}
			}
			TF2_AddCondition(iClient, view_as<TFCond>(82), TFCondDuration_Infinite);
			SetEntProp(iClient, Prop_Data, "m_takedamage", 0, 1);
			PrintToChat(iClient,"\x03[Karts Vs Hunters] \x06 Spawn Protection ON");
			SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamageClient);
			CreateTimer(3.0, Backmortal, iClient);
			if(FirstJoin[iClient]){
				DisplayHelp(iClient);
				FirstJoin[iClient] = false;
			}
		}
		if (IsValidClient(iClient) && GetClientTeam(iClient) == 3)
		{
			if(kvsclass == 1){
				if (TF2_GetPlayerClass(iClient) != TFClass_Soldier)
				{
					TF2_SetPlayerClass(iClient, TFClass_Soldier, false, true);
					TF2_RespawnPlayer(iClient);
				}
			}
			if(kvsclass == 2){
				if (TF2_GetPlayerClass(iClient) != TFClass_Sniper)
				{	
					TF2_SetPlayerClass(iClient, TFClass_Sniper, false, true);
					TF2_RespawnPlayer(iClient);
				}
			}
			TF2_RemoveWeaponSlot(iClient, 1);
			TF2_AddCondition(iClient, TFCond_SpeedBuffAlly, TFCondDuration_Infinite);
			SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamageClient);
			GetClientAbsOrigin(iClient, initialpos[iClient]);
			IsHunter[iClient] = false;
			if(FirstJoin[iClient]){
				DisplayHelp(iClient);
				FirstJoin[iClient] = false;
			}
			int TeamCountLm = GetPlayerCountTeam(3);
			if(TeamCountLm >= 2){
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
					{
						TF2_RemoveCondition(i, TFCond_Kritzkrieged);
						TF2_RemoveWeaponSlot(i, 1);
					}
				}
			}
		}
	}
}
public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &hItem) 
{
	switch(iItemDefinitionIndex) 
	{
		case 444: return Plugin_Handled;
		case 133: return Plugin_Handled;
		case 642: return Plugin_Handled; //Cozy Camper
	} 
	return Plugin_Continue;
}
public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(plugin_enable.BoolValue && g_enabled){
		int userid = GetEventInt(event, "userid");
		int iClient = GetClientOfUserId(userid);
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));  
		if (!IsValidClient(iClient))
		{
			return;
		}
		if((waiting) && (!round_start))TF2_RespawnPlayer(iClient);
		if((round_start) && (!waiting)){
			if (GetClientTeam(iClient) == 3)
			{
				ChangeClientTeam(iClient, 2);
				
				IsHunter[iClient] = true;
				int TeamCountLm = GetPlayerCountTeam(3);
				if(TeamCountLm == 1){
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
						{
							CreateTimer(0.5, Timer_LastMan, i);
						}
					}
				}
			}
			if (GetClientTeam(iClient) == 2)
			{
				if(IsValidClient(attacker) && GetClientTeam(attacker) == 3){
					SetEntityHealth(attacker, GetClientHealth(attacker) + 20); 
				}			
			}
			int TeamCount = GetPlayerCountTeam(3);
			if(TeamCount <= 0){
				int Ent_RedWin = -1;
				Ent_RedWin = FindEntityByClassname(Ent_RedWin, "game_round_win");
				if (Ent_RedWin < 1)
				{
					Ent_RedWin = CreateEntityByName("game_round_win");
					DispatchSpawn(Ent_RedWin);
					DispatchKeyValue(Ent_RedWin, "Team", "2");
					DispatchKeyValue(Ent_RedWin, "force_map_reset", "1");
					AcceptEntityInput(Ent_RedWin, "RoundWin");
				}
				else{
					SetVariantInt(2);
					AcceptEntityInput(Ent_RedWin, "SetTeam");
					AcceptEntityInput(Ent_RedWin, "RoundWin");
				}
			}
		}
	}
}
int GetPlayerCountTeam(int team)
{
    int players_team;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == team)
            players_team++;
    }
    return players_team;
}
public void OnClientDisconnect(int client)
{
	if(plugin_enable.BoolValue && g_enabled){
		if(IsValidClient(client) && GetClientTeam(client) == 3){
			int TeamCountLm = GetPlayerCountTeam(3);
			if(TeamCountLm == 1){
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
					{
						CreateTimer(0.5, Timer_LastMan, i);
					}
				}
			}
		}		
		int TeamCountBlue = GetPlayerCountTeam(3);
		int TeamCountRed = GetPlayerCountTeam(2);
		if(TeamCountBlue <= 0){
			int Ent_RedWin = -1;
			Ent_RedWin = FindEntityByClassname(Ent_RedWin, "game_round_win");
			if (Ent_RedWin < 1)
			{
				Ent_RedWin = CreateEntityByName("game_round_win");
				DispatchSpawn(Ent_RedWin);
				DispatchKeyValue(Ent_RedWin, "Team", "2");
				DispatchKeyValue(Ent_RedWin, "force_map_reset", "1");
				AcceptEntityInput(Ent_RedWin, "RoundWin");
			}
			else{
				SetVariantInt(2);
				AcceptEntityInput(Ent_RedWin, "SetTeam");
				AcceptEntityInput(Ent_RedWin, "RoundWin");
			}
		}
		if(TeamCountRed <= 0){
			int Ent_BlueWin = -1;
			Ent_BlueWin = FindEntityByClassname(Ent_BlueWin, "game_round_win");
			if (Ent_BlueWin < 1)
			{
				Ent_BlueWin = CreateEntityByName("game_round_win");
				DispatchSpawn(Ent_BlueWin);
				DispatchKeyValue(Ent_BlueWin, "Team", "3");
				DispatchKeyValue(Ent_BlueWin, "force_map_reset", "1");
				AcceptEntityInput(Ent_BlueWin, "RoundWin");
			}
			else{
				SetVariantInt(2);
				AcceptEntityInput(Ent_BlueWin, "SetTeam");
				AcceptEntityInput(Ent_BlueWin, "RoundWin");
			}
		}
	}
}
public Action Backmortal( Handle timer, any client)
{
	if (IsValidClient(client)){
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(client,"\x03[Karts Vs Hunters] \x06 Spawn Protection OFF");
	}
}
public Action WaitingforStart(Event event, const char[] name, bool dontBroadcast){
	if(plugin_enable.BoolValue && g_enabled){
		restarts = 0;
		round_start = false;
		waiting = true;
	}
}
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
	if(plugin_enable.BoolValue && g_enabled){
		if (restarts == 0 )
		{
			waiting = true;
			restarts++;	
			kvsclass = GetRandomInt(1, 2);
		}
		else{
			waiting = false;
			round_start = true;
			kvsclass = GetRandomInt(1, 2);
			TimerSpam = CreateTimer(0.5, TimerCheck, _, TIMER_REPEAT);
			jointeamlocked = false;
			CreateTimer(20.0, Ct_block);
		}
	}
}
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast){
	if(plugin_enable.BoolValue && g_enabled){
		ClearTimer(TimerSpam);
		round_start = false;
		jointeamlocked = false;
		PrintToChatAll("\x03[Karts Vs Hunters] \x06Teams Unlocked");
		for (int i = 1; i <= MaxClients; i++) {
			if ((IsValidClient(i)) && (GetClientTeam(i) == 2)) {
				TF2_RemoveCondition(i, view_as<TFCond>(82));
				if(IsHunter[i]){
					ChangeClientTeamAlive(i, 3);
					IsHunter[i] = false;
				}
			}
		}
	}
}
stock int ChangeClientTeamAlive(int client, int team)
{
	int currentteam = GetClientTeam(client);
	if((currentteam	 == 1) || (currentteam == 0))return false;
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
	return true;
}
public Action Ct_block(Handle timer)
{
	jointeamlocked = true;
	PrintToChatAll("\x03[Karts Vs Hunters] \x06 Teams Locked");
}
public Action TimerCheck(Handle timer)
{
	PlayersChecks();
}
public Action PlayersChecks()
{
	for (int i = 1; i <= MaxClients; i++) {
		if ((IsValidClient(i)) && (GetClientTeam(i) == 3)) {
			GetClientAbsOrigin(i, currentpos[i]);
			//PrintToChatAll("%f, %f",currentpos[i][2],initialpos[i][2]);
			if((currentpos[i][2] - initialpos[i][2]) <= -200.0)
			{
				if(!round_start){
					TF2_RespawnPlayer(i);
				}
				else{
					SDKHooks_TakeDamage(i, 0, 0, 20000.0, DMG_SLASH);
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action OnTakeDamageClient(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	
	if (IsValidClient(attacker) && IsValidClient(victim))
	{
		if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) == 2)
		{
			//PushEntity(victim, attacker, 100.0);
			float ang[3];
			float vel[3];
			GetClientEyeAngles(attacker, ang);
			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vel);
			vel[0] -= 100.0 * Cosine(DegToRad(ang[1])) * -1.0 * damage*0.01;
			vel[1] -= 100.0 * Sine(DegToRad(ang[1])) * -1.0 * damage*0.01;
			//vel[2] += 50.0;
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);
			return Plugin_Changed;
		}
		if(attacker == victim)
		{
			damage = 0.0;
			return Plugin_Changed;
		} 
		if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3)
		{
			if (TF2_GetPlayerClass(attacker) == TFClass_Sniper)
			{	
				damage = 500.0;
				return Plugin_Changed;
			}
			if (TF2_GetPlayerClass(attacker) == TFClass_Soldier)
			{	
				damage = 500.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}
/* stock int PushEntity(int entity, int client, float strength=10.0)
{
	if(IsValidEntity(entity))
	{
		// get positions of both entity and client 
		float pos1[3]; float pos2[3];
		GetClientAbsOrigin(client, pos1);
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos2);

		// create push velocity
		float vPush[3];
		MakeVectorFromPoints(pos1, pos2, vPush);
		NormalizeVector(vPush, vPush);
		ScaleVector(vPush, strength);

		// push entity
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vPush);
	}
} */
public Action Timer_LastMan(Handle timer, any iClient)
{
	if(IsValidClient(iClient))
	{  
		int lastman_sound = GetRandomInt(1,4);
		char lastman_sound_string[256];
		Format(lastman_sound_string, sizeof(lastman_sound_string), "0%i", lastman_sound);
		char lss_sound[256];
		Format(lss_sound,sizeof(lss_sound),"vo/announcer_am_lastmanalive%s.mp3", lastman_sound_string);
		PrecacheSound(lss_sound, true);
		EmitSoundToClient(iClient, lss_sound);
		TF2_AddCondition(iClient, TFCond_Kritzkrieged, TFCondDuration_Infinite);
		if (TF2_GetPlayerClass(iClient) == TFClass_Sniper)
		{	
			ForceSMG(iClient);
		}
		if (TF2_GetPlayerClass(iClient) == TFClass_Soldier)
		{	
			ForceSGUN(iClient);
		}
		PrintToChat(iClient,"\x03[Karts Vs Hunters] \x06 You are the Last Hunter: Secondary Weapon Enabled!");
	}
	return Plugin_Handled;
}
stock int ForceSMG(int client)
{
	if (IsValidClient(client))
	{
		Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
		TF2Items_SetClassname(hWeapon, "tf_weapon_smg");
		TF2Items_SetItemIndex(hWeapon, 1149);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 1);

		int smg = TF2Items_GiveNamedItem(client, hWeapon);
		CloseHandle(hWeapon);
		EquipPlayerWeapon(client, smg);
	}
}
stock int ForceSGUN(int client)
{
	if (IsValidClient(client))
	{
		Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
		TF2Items_SetClassname(hWeapon, "tf_weapon_shotgun_soldier");
		TF2Items_SetItemIndex(hWeapon, 10);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 1);

		int sgun = TF2Items_GiveNamedItem(client, hWeapon);
		CloseHandle(hWeapon);
		EquipPlayerWeapon(client, sgun);
	}
}
stock bool IsValidClient(int iClient) {
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	if (!IsClientConnected(iClient)) return false;
	return IsClientInGame(iClient);
}
stock int ClearTimer(Handle &timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

public Menu DisplayHelp(int client)
{
	Menu menu = CreateMenu(MenuHandler);
	SetMenuTitle(menu, "Karts VS Hunters\n    Help Menu");
	AddMenuItem(menu, "", "Goal: \n Blue Team must survive from karts enemies \n Red Team must push Blue Team down the playform or kill them.");
	AddMenuItem(menu, "", "More Details:\n Blue Team Class is picked up from the server can be\n Soldier or Sniper\n secondary slot is removed \n only primary and melee are permitted");
	AddMenuItem(menu, "", "Commands: \n !kvhhelp to reopen this menu");
	AddMenuItem(menu, "", "Creator: \n TonyBaretta");
	SetMenuExitButton(menu,true);
	DisplayMenu(menu,client,20);
}
public int MenuHandler(Menu menu,MenuAction action,int param1,int param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("Steam_SetGameDescription");
	return APLRes_Success;
}
public void OnAllPluginsLoaded()
{
	g_bSteamWorks = LibraryExists("SteamWorks");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "SteamWorks", false))
	{
		g_bSteamWorks = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "SteamWorks", false))
	{
		g_bSteamWorks = false;
	}
}
public void OnConfigsExecuted()
{	
	if(GameDescription.BoolValue){
		UpdateGameDescription(true);
	}
}
int UpdateGameDescription(bool bAddOnly=false)
{
	if (g_bSteamWorks)
	{
		char gamemode[64];
		if (bAddOnly)
		{
			if(g_enabled){
				Format(gamemode, sizeof(gamemode), "Karts Vs Hunters v.%s", PLUGIN_VERSION);
			}
			else
			Format(gamemode, sizeof(gamemode), "Team Fortress");
		}
		else
		{
			strcopy(gamemode, sizeof(gamemode), "Team Fortress");
		}
		SteamWorks_SetGameDescription(gamemode);
	}
}