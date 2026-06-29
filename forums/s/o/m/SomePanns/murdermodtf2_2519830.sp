#pragma semicolon 1

#include <sourcemod>
#include <steamtools>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>
#include <tf2items>
#include <clientprefs>
#include <morecolors>
#include <tf2attributes>
#include <smlib>

#pragma newdecls required

#define PLUGIN_VERSION "0.5.1 BETA"
#define TEAM_UNSIG 0
#define TEAM_SPEC 1
#define TEAM_RED 2
#define TEAM_BLUE 3
#define MURDER_PREFIX "{green}[Murder Mod]{default}"

ConVar g_hCvarSetupTime;
ConVar g_hCvarAntiAFK;

Handle g_Timer_Start = INVALID_HANDLE;
ConVar g_Cvar_FriendlyFire;
Handle g_Cvar_AutoBalance = INVALID_HANDLE;
Handle g_Cvar_Waiting = INVALID_HANDLE;
Handle g_Cvar_Alltalk = INVALID_HANDLE;
Handle g_Timer_ClientWeps[MAXPLAYERS+1] = INVALID_HANDLE;
Handle g_Timer_Waiting[MAXPLAYERS+1] = INVALID_HANDLE;
Handle g_Hud_Timer[MAXPLAYERS+1] = INVALID_HANDLE;
//Handle g_Cvar_Spec = INVALID_HANDLE;
Handle g_Cvar_Freeze = INVALID_HANDLE;
Handle g_Timer_ClientCheck[MAXPLAYERS+1] = INVALID_HANDLE;
Handle g_Timer_MurdererAntiAFK[MAXPLAYERS+1] = INVALID_HANDLE;
Handle g_Timer_ChatAnnounce[MAXPLAYERS+1] = INVALID_HANDLE;

Handle g_MusicCookie = INVALID_HANDLE;

bool b_gIsEnabled = false;
bool b_IsRoundActive = false;
bool b_IsSheriff[MAXPLAYERS+1] = false;
bool b_IsMurderer[MAXPLAYERS+1] = false;
bool b_IsDead[MAXPLAYERS+1] = false;
bool b_HasSentMMReq = false;
bool b_HasSentMMReady = false;
bool b_HasVotedResign[MAXPLAYERS+1] = false;
bool b_MusicOff[MAXPLAYERS+1] = true;

int i_CountMurderer = 0;
int i_CountSheriff = 0;
int Murderer_LastKill[MAXPLAYERS+1] = 0;
int Warnings[MAXPLAYERS+1] = 0;
int ResignVotes = 0;

#define MAX_BUTTONS 25
int g_LastButtons[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[TF2] Murder Mod",
	author = "SomePanns",
	description = "Murder Mod for TF2",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561198082943320"
};

public void OnPluginStart()
{
	char gameDesc[64];
	Format(gameDesc, sizeof(gameDesc), "Murder Mod (%s)", PLUGIN_VERSION);
	Steam_SetGameDescription(gameDesc);
	AddServerTag("mm");
	
	g_hCvarSetupTime = CreateConVar("sm_mm_setuptime", "45.0", "Amount of seconds before sheriff and murderer is chosen. Default is 45.0 seconds.");
	g_hCvarAntiAFK = CreateConVar("sm_mm_antiafk", "180.0", "Amount of seconds after the most recent kill by the murderer before someone else is made into the murderer.");

	HookEvent("teamplay_round_start", Event_RoundStartSoon);
	HookEvent("teamplay_round_active", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("teamplay_win_panel", Event_RoundWin);
	HookEvent("teamplay_round_stalemate", Event_RoundWin);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_PostInventory);
	HookEvent("player_team", Event_TeamsChange); 
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	AddCommandListener(Hook_CommandSay, "say");
	AddCommandListener(Hook_Suicide, "kill");
	AddCommandListener(Hook_Suicide, "explode");
	AddCommandListener(Hook_Suicide, "joinclass");
	
	RegConsoleCmd("sm_mmhelp", Command_MMHelp, "Usage: sm_mmhelp");	
	RegConsoleCmd("sm_newsheriff", Command_NewSheriff, "Usage: sm_newsheriff");	
	RegConsoleCmd("sm_murdermusic", Command_MurderMusic, "Usage: sm_murdermusic");	
	
	g_MusicCookie = RegClientCookie("murder_cookie_moff", "Murder MusicCookie", CookieAccess_Protected); // 1 to disable music and 0 to enable
	
	for (int i = MaxClients; i > 0; --i)
    {
        if (!AreClientCookiesCached(i))
        {
            continue;
        }
        
        OnClientCookiesCached(i);
    }
}

public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, g_MusicCookie, sValue, sizeof(sValue));

	b_MusicOff[client] = (sValue[0] != '\0' && StringToInt(sValue));
}

public void OnConfigsExecuted()
{
	AddFileToDownloadsTable("sound/tfmurder/bgm.wav");
	PrecacheSound("tfmurder/bgm.wav", true);
	
	g_Cvar_Waiting = FindConVar("mp_waitingforplayers_time");
	SetConVarInt(g_Cvar_Waiting, 1);
	
	if(b_gIsEnabled) {
		g_Cvar_FriendlyFire = FindConVar("mp_friendlyfire");
		g_Cvar_AutoBalance = FindConVar("mp_autoteambalance");
		g_Cvar_Alltalk = FindConVar("sv_alltalk");
		//g_Cvar_Spec = FindConVar("mp_allowspectators");
		g_Cvar_Freeze = FindConVar("spec_freeze_time");
		
		SetConVarInt(g_Cvar_Alltalk, 0);
		SetConVarInt(g_Cvar_AutoBalance, 0);
		//SetConVarInt(g_Cvar_Spec, 0);
		SetConVarInt(g_Cvar_Freeze, 10000000);
	}
}

public void OnMapStart()
{
	b_IsRoundActive = false;
	b_HasSentMMReady = false;
	b_HasSentMMReq = false;
	
	ChangeFreeState(false);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity > MaxClients && IsValidEntity(entity))
	{
		int ent = 0; 
		ent = MaxClients+1; 
		while((ent = FindEntityByClassname(ent, "tf_logic_arena")) != -1) 
		{
			AcceptEntityInput(ent, "Kill");
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
	b_IsSheriff[client] = false;
	b_IsMurderer[client] = false;
	
	if(b_IsRoundActive) {
		b_IsDead[client] = true;
	} else {
		b_IsDead[client] = false;
	}
	
	b_HasVotedResign[client] = true;
	
	g_Timer_ChatAnnounce[client] = CreateTimer(70.0, Timer_ChatAnnounce, client, TIMER_REPEAT); 
}

public void OnClientDisconnect_Post(int client)
{
    g_LastButtons[client] = 0;
}


public void OnClientDisconnect(int client) {
	b_IsDead[client] = false;
	Warnings[client] = 0;
	b_HasVotedResign[client] = true;

	if(b_IsSheriff[client]) {
		i_CountSheriff = 0;
		PickSheriff();
		b_IsSheriff[client] = false;
	} else {
		b_IsSheriff[client] = false;
	}
	
	if(b_IsMurderer[client]) {
		i_CountMurderer = 0;
		Murderer_LastKill[client] = 0;
		PickMurderer();
		b_IsMurderer[client] = false;
		KillTimerSafe(g_Timer_MurdererAntiAFK[client]);
	} else {
		b_IsMurderer[client] = false;
	}
	
	if(b_IsRoundActive) {
		b_IsDead[client] = true;
	} else {
		b_IsDead[client] = false;
	}
	
	KillTimerSafe(g_Timer_ClientWeps[client]);
	KillTimerSafe(g_Timer_Waiting[client]);
	KillTimerSafe(g_Hud_Timer[client]);
	KillTimerSafe(g_Timer_ClientCheck[client]);
	KillTimerSafe(g_Timer_ChatAnnounce[client]);
}

stock int TotalTeamCount()
{
	return (GetTeamClientCount(TEAM_RED) + GetTeamClientCount(TEAM_BLUE));
}

public Action Command_MMHelp(int client, int args)
{
	if(!b_gIsEnabled || !IsValidClient(client)) return Plugin_Continue;
	
	Panel panel = new Panel();
	panel.SetTitle("How to play Murder");
	panel.DrawItem("There is one murderer. The murderer has a knife and must kill everyone to win.");
	panel.DrawItem("There is one sheriff. The sheriff has a gun and must kill the murderer to win.");
	panel.DrawItem("Innocents must be protected by the sheriff, from the murderer. They are defenseless.");
	panel.DrawItem("When the sheriff dies, a new one is randomly picked.");
 
	panel.Send(client, MMHelp_Handler, 30);
 
	delete panel;
 
	return Plugin_Handled;
}

public Action Command_MurderMusic(int client, int args)
{
	if(args > 0 || !b_gIsEnabled || !IsValidClient(client)) return Plugin_Continue;
	
	if(b_MusicOff[client]) // turn it off
	{
		SetClientCookie(client, g_MusicCookie, "0");
		CPrintToChat(client, "%s The music will be enabled next round.", MURDER_PREFIX);
		OnClientCookiesCached(client);
	}
	else if(!b_MusicOff[client]) // turn it on
	{
		SetClientCookie(client, g_MusicCookie, "1");
		StopSound(client, SNDCHAN_AUTO, "tfmurder/bgm.wav");
		CPrintToChat(client, "%s The music is now disabled until you do {green}!murdermusic {default}again.", MURDER_PREFIX);
		OnClientCookiesCached(client);
	}
 
	return Plugin_Handled;
}

public Action Command_NewSheriff(int client, int args)
{
	if(args > 0 || !b_gIsEnabled || !IsValidClient(client)) return Plugin_Continue;
	
	if(b_HasVotedResign[client] || !b_IsRoundActive || TF2_GetClientTeam(client) != TFTeam_Red || b_IsMurderer[client] || b_IsSheriff[client])
	{
		CPrintToChat(client, "%s Permission denied. You can not do this yet.", MURDER_PREFIX);
		return Plugin_Continue;
	}
	
	//ResignVotes increase by 1 for each person that votes
	//15 votes = 0.15
	//20 people in red = 1.0
	
	ResignVotes++;
	CPrintToChatAll("%s %N voted for the sheriff to resign.", MURDER_PREFIX, client);
	float VotedFor = view_as<float>(ResignVotes / GetTeamClientCount(TEAM_RED));
	b_HasVotedResign[client] = true;
	
	if(VotedFor >= 0.70)
	{
		for(int i = 0; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(b_IsSheriff[i])
				{
					b_IsSheriff[i] = false;
					i_CountSheriff = 0;
					TF2_RemoveWeaponSlot(i, 0);
					CPrintToChatAll("%s The people have spoken! The sheriff has been fired, picking a new one...", MURDER_PREFIX);
				}
			}
		}
	}
 
	return Plugin_Handled;
}

public int MMHelp_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		
	} else if (action == MenuAction_Cancel) {
		
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float[3] vel, float[3] angles, int &weapon)
{
    for (int i = 0; i < MAX_BUTTONS; i++)
    {
        int button = (1 << i);
        
        if ((buttons & button))
        {
            if (!(g_LastButtons[client] & button))
            {
                OnButtonPress(client, button);
            }
        }
        else if ((g_LastButtons[client] & button))
        {
            OnButtonRelease(client, button);
        }
    }
    
    g_LastButtons[client] = buttons;
    
    return Plugin_Continue;
}

stock int SetSpeed(int client, float flSpeed)
{
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", flSpeed);
}

stock int ResetSpeed(int client)
{
	TF2_StunPlayer(client, 0.0, 0.0, TF_STUNFLAG_SLOWDOWN);
}

int OnButtonPress(int client, int button)
{
	if(b_IsMurderer[client] && button == IN_ATTACK2)
	{
		SetSpeed(client, 400.0);
	}
}

int OnButtonRelease(int client, int button)
{
    if(b_IsMurderer[client] && button == IN_ATTACK2)
	{
		ResetSpeed(client);
	}
}

public Action Event_RoundStartSoon(Event event, const char[] name, bool dontBroadcast) {
	b_IsRoundActive = false;
	
	int iTotalTeamCount = GetTeamClientCount(TEAM_RED) + GetTeamClientCount(TEAM_BLUE);
	if(iTotalTeamCount > 2) {
		b_gIsEnabled = true;
		OnConfigsExecuted();
	}
	
	i_CountSheriff = 0;
	i_CountMurderer = 0;
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			b_IsMurderer[client] = false;
			b_IsSheriff[client] = false;
		}
	}
}

public Action Timer_ChatAnnounce(Handle timer, int client)
{
	int ChatMessages = GetRandomInt(0,7);

	switch(ChatMessages) 
	{
		case 0:
		{
			CPrintToChat(client, "%s {olive}This gamemode was created by SomePanns from AlliedMods.net with help from the contributor SnowTigerVidz.", MURDER_PREFIX);
		}
		
		case 1:
		{
			CPrintToChat(client, "%s {olive}This server is running TF2 Murder (%s) created by SomePanns.", MURDER_PREFIX, PLUGIN_VERSION);
		}
		
		case 2:
		{
			CPrintToChat(client, "%s {olive}New to this gamemode? Type !mmhelp in the chat to bring up the help menu!", MURDER_PREFIX);
		}
		
		case 3:
		{
			CPrintToChat(client, "%s {olive}When the sheriff dies, a new one is randomly chosen after some time.", MURDER_PREFIX);
		}
		
		case 4:
		{
			CPrintToChat(client, "%s {olive}A new murderer will be chosen if the current one does not manage to kill anyone.", MURDER_PREFIX);
		}
		
		case 5:
		{
			CPrintToChat(client, "%s {olive}Want to come with a suggestion? Add the creator on Steam: http://steamcommunity.com/profiles/76561198082943320/", MURDER_PREFIX);
		}
		
		case 6:
		{
			CPrintToChat(client, "%s {olive}You can type {green}!newsheriff {olive}to vote for the current sheriff to resign. A new one will automatically be picked when the votes reach a threshold.", MURDER_PREFIX);
		}
		
		case 7:
		{
			CPrintToChat(client, "%s {olive}Is the music annoying? Turn it off with {green}!murdermusic{olive}.", MURDER_PREFIX);
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{	
	if(IsValidClient(victim) && IsValidClient(attacker)) {
		// Kill the sheriff if he kills in innocent
		if(b_gIsEnabled == true && b_IsRoundActive == true && GetClientTeam(attacker) == TEAM_RED && GetClientTeam(victim) == TEAM_RED) {
			if(b_IsSheriff[attacker] == true) {
				if(b_IsMurderer[victim] == false && b_IsSheriff[victim] == false) {
					if(damage > 125) {
						ForcePlayerSuicide(attacker);
						PrintCenterTextAll("The sheriff has killed an innocent and has been slain...");
					}
				}
			}
		}
		
		// Need to make sure blues cant kill each other when friendly fire is on.
		if(b_gIsEnabled == true && b_IsRoundActive && GetClientTeam(attacker) == TEAM_BLUE && GetClientTeam(victim) == TEAM_BLUE) {
			damage = 0.0;
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public int ChangeFreeState(bool state)
{
	int flags;
	flags = GetConVarFlags(g_Cvar_FriendlyFire);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(g_Cvar_FriendlyFire, flags);

	SetConVarBool(g_Cvar_FriendlyFire, state);
	
	if(state == true)
	{
		b_IsRoundActive = true;
	}
	else
	{
		b_IsRoundActive = false;
	}
}

stock int ForceTeamWin(int team)
{
    int entity=FindEntityByClassname(-1, "team_control_point_master");
    if(entity==-1)
    {
        entity=CreateEntityByName("team_control_point_master");
        DispatchSpawn(entity);
        AcceptEntityInput(entity, "Enable");
    }
    SetVariantInt(team);
    AcceptEntityInput(entity, "SetWinner");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if(!b_gIsEnabled) return Plugin_Continue; // Not enough players to start round
	
	for(int index = 1; index <= MaxClients; index++) {
		b_IsSheriff[index] = false;
		b_IsMurderer[index] = false;
		b_IsDead[index] = false;
	}

	int visul=-1;
	while((visul=FindEntityByClassname(visul, "func_respawnroomvisualizer"))!=-1) 
	{
		AcceptEntityInput(visul, "Disable");
	}

	int cp=-1;
	while((cp=FindEntityByClassname(cp, "team_control_point"))!=-1)
	{
		AcceptEntityInput(cp, "Disable");
    }

	int flag=-1;
	while((flag=FindEntityByClassname(flag, "item_teamflag"))!=-1)
    {
		AcceptEntityInput(flag, "Disable");
	}

	int capzone=-1;
	while((capzone=FindEntityByClassname(capzone, "func_capturezone"))!=-1)
	{
		AcceptEntityInput(capzone, "Disable");
    }
	
	// Disable all resupply lockers
	int locker=-1;
	while((locker=FindEntityByClassname(locker, "func_regenerate"))!=-1)
	{
		AcceptEntityInput(locker, "Disable");
	}

	int caparea=-1;
	while((caparea=FindEntityByClassname(caparea, "trigger_capture_area"))!=-1)
    {
        AcceptEntityInput(caparea, "Disable");
    }
	
	b_IsRoundActive = false;
	
	if(b_IsRoundActive == false) {
		float SetupTime = GetConVarFloat(g_hCvarSetupTime);
		g_Timer_Start = CreateTimer(SetupTime, Timer_StartRound);
		PrintCenterTextAll("Round begins in %i seconds!", RoundFloat(SetupTime));
		//b_IsRoundActive = true;
		
		for(int i = 0; i <= MaxClients; i++) {
			if(IsValidClient(i))
			{
				if(!b_MusicOff[i])
				{
					StopSound(i, SNDCHAN_AUTO, "tfmurder/bgm.wav");
					EmitSoundToClient(i, "tfmurder/bgm.wav", _, _, _, _, 0.3, _, _, _, _, false);
				}
		
				if(GetClientTeam(i) == TEAM_RED) {
					b_HasVotedResign[i] = false;
					KillTimerSafe(g_Timer_ClientWeps[i]);
					float CWTime = SetupTime + 5.0;
					g_Timer_ClientWeps[i] = CreateTimer(CWTime, Timer_ControlWeapons, i, TIMER_REPEAT);
					g_Hud_Timer[i] = CreateTimer(0.1, Timer_Hud, i, TIMER_REPEAT);
					g_Timer_ClientCheck[i] = CreateTimer(1.0, Timer_ClientCheck, i, TIMER_REPEAT);
				}
			}
		}
		
		CreateTimer(0.1, Timer_Doors, TIMER_REPEAT);
	}

	return Plugin_Continue;
}

public Action Timer_Doors(Handle timer)
{
	int doors=-1;
	while((doors=FindEntityByClassname(doors, "func_door"))!=-1)
    {
        AcceptEntityInput(doors, "Open");
    }
	
	KillTimerSafe(timer);
}

public Action Timer_ClientCheck(Handle timer, int client)
{
	if(IsValidClient(client))
	{
		if(!IsPlayerAlive(client))
		{
			if(!b_IsRoundActive && b_IsDead[client] == false)
			{
				TF2_ChangeClientTeam(client, TFTeam_Red);
				TF2_RespawnPlayer(client);
			}
			
			if(GetClientTeam(client) == TEAM_RED && b_IsRoundActive == true)
			{
				TF2_ChangeClientTeam(client, TFTeam_Blue);
			}
			
			if(b_IsMurderer[client])
			{
				b_IsMurderer[client] = false;
				i_CountMurderer = 0;
			}
			
			if(b_IsSheriff[client])
			{
				b_IsSheriff[client] = false;
				i_CountSheriff = 0;
			}
		}
		
		if(TF2_GetClientTeam(client) == TFTeam_Spectator && b_IsDead[client] == false && b_IsRoundActive == false) // Fixes stuck in spectator mode
		{
			TF2_ChangeClientTeam(client, TFTeam_Red);
		}
		
		if(!b_IsMurderer[client] && !b_IsSheriff[client])
		{
			SetWeaponInvis(client);
		}
		else
		{
			SetWeaponInvis(client, false);
		}
	}
}

public Action Timer_Hud(Handle timer, int client)
{
	
	if(IsValidClient(client)) 
	{
		Handle hHudRole = CreateHudSynchronizer();
		SetHudTextParams(0.02, 0.02, 0.1, 0, 255, 0, 255);
		
		if(!b_IsRoundActive)
		{
			ShowSyncHudText(client, hHudRole, "Round pending");
		} 
		else if(b_IsMurderer[client] && !b_IsDead[client])
		{
			ShowSyncHudText(client, hHudRole, "Murderer (hold M2 to run)");
		} 
		else if(b_IsSheriff[client] && !b_IsDead[client])
		{
			ShowSyncHudText(client, hHudRole, "Sheriff");
		} 
		else if(!b_IsSheriff[client] && !b_IsMurderer[client] && !b_IsDead[client])
		{
			ShowSyncHudText(client, hHudRole, "Innocent");
		}
		else if(!IsPlayerAlive(client) && b_IsRoundActive)
		{
			ShowSyncHudText(client, hHudRole, "Dead");
		}
		
		CloseHandle(hHudRole);
	}
}

public Action Event_PostInventory(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!b_gIsEnabled) return Plugin_Continue; // Not enough players to start round
	
	if(GetClientTeam(client) == TEAM_RED && client > 0) {
		// Only spy is allowed in murder mod
		if(TF2_GetPlayerClass(client) != TFClass_Spy) {
			TF2_SetPlayerClass(client, TFClass_Spy);
		}
		
		TF2_RemoveAllWeapons(client);
		SpawnWeapon(client, "tf_weapon_builder", 735, 1, 0, "");
		
		if(GetClientTeam(client) == TEAM_RED && b_IsRoundActive == true) {
			if(b_IsMurderer[client]) {
				SpawnWeapon(client, "tf_weapon_knife", 4, 1, 0, "2 ; 10.0");
			} 
			else if(b_IsSheriff[client]) {
				SpawnWeapon(client, "tf_weapon_revolver", 161, 1, 0, "2 ; 10.0 ; 96 ; 4.0 ; 3 ; 0.1");
			}
		}
		
		//Client_SetHideHud(client, HIDEHUD_MISCSTATUS);
	}
	
	return Plugin_Changed;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client)) {
		// Make sure they dont turn into civilian pose. Set sapper as active weapon for everyone.
		int iWeapon = GetPlayerWeaponSlot(client, 1);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon))
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
			
		if(!b_IsRoundActive) {
			int iTotalTeamCount = GetTeamClientCount(TEAM_RED) + GetTeamClientCount(TEAM_BLUE);
			if(iTotalTeamCount > 2) {
				if(GetClientTeam(client) == TEAM_RED)
				{
					b_IsDead[client] = false;
				}
				
				if(!b_gIsEnabled) {
					if(b_HasSentMMReady == false) {
						CPrintToChat(client, "%s 3 or more players found, starting Murder Mod.", MURDER_PREFIX);
						b_HasSentMMReady = true;
						KillTimerSafe(g_Timer_Waiting[client]);
					}
					
					ForceTeamWin(TEAM_RED);
					
					b_gIsEnabled = true;
					OnConfigsExecuted();
				}
			} else {
				if(b_HasSentMMReq == false) {
					g_Timer_Waiting[client] = CreateTimer(2.0, Timer_WaitingPlayers, client, TIMER_REPEAT);
					b_HasSentMMReq = true;
				}
				b_gIsEnabled = false;
			}
		}
		
		// Make sure they can't play as blue
		// if theyre dead, dont allow them to be red
		if(b_gIsEnabled) {
			if(GetClientTeam(client) == TEAM_BLUE && b_IsDead[client] == false) {
				ForcePlayerSuicide(client);
				ChangeClientTeam(client, TEAM_RED);
			}
			
			if(b_IsRoundActive) {
				if(GetClientTeam(client) == TEAM_BLUE) {
					//TF2_ChangeClientTeam(client, TFTeam_Spectator);
					//TF2_ChangeClientTeam(client, TFTeam_Blue);
					ForcePlayerSuicide(client);
				}
				
				if(GetClientTeam(client) == TEAM_RED && b_IsDead[client] == true) {
					//TF2_ChangeClientTeam(client, TFTeam_Spectator);
					TF2_ChangeClientTeam(client, TFTeam_Blue);
				}
			}
		}
	}
	
	return Plugin_Changed;
}

public Action Event_TeamsChange(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "team");
	
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass")) // Initial living spectator check. A value of 0 means that no class is selected
    {
        SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetPlayerClass(client)>=TFClass_Scout ? (view_as<TFClassType>(TF2_GetPlayerClass(client))) : TFClass_Spy); // So we assign one to prevent living spectators
    }
	
	if(b_IsDead[client] && team == TEAM_RED)
	{
		ForcePlayerSuicide(client);
		ChangeClientTeam(client, TEAM_BLUE);
	}
	
	/*if(team == TEAM_BLUE && IsValidClient(client)) {
		ForcePlayerSuicide(client);
		ChangeClientTeam(client, TEAM_RED);
	}*/
	
	return Plugin_Continue;
}

stock int GetIndexOfWeaponSlot(int iClient, int iSlot)
{
    return GetWeaponIndex(GetPlayerWeaponSlot(iClient, iSlot));
}

stock int GetWeaponIndex(int iWeapon)
{
    return IsValidEntity(iWeapon) ? GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"):-1;
}

public Action Timer_ControlWeapons(Handle timer, int client) 
{
	if(TotalTeamCount() < 3)
	{
		ForceTeamWin(TEAM_RED);
		if(IsValidClient(client) && GetClientTeam(client) == TEAM_RED)
		{
			KillTimerSafe(g_Timer_ClientWeps[client]);
		}
	}
	
	if(GetClientTeam(client) == TEAM_RED && IsValidClient(client) && b_IsRoundActive == true) {
		if(i_CountSheriff <= 0) {
			PickSheriff();
			ChangeFreeState(true);
		}
		
		if(i_CountMurderer <= 0) {
			PickMurderer();
			ChangeFreeState(true);
		}
		
		if(b_IsMurderer[client]) {
			if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) != 4) {
				SpawnWeapon(client, "tf_weapon_knife", 4, 1, 0, "2 ; 10.0");
				int iWeapon = GetPlayerWeaponSlot(client, 1);
				if(iWeapon > MaxClients && IsValidEntity(iWeapon))
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
			}
		}
		
		if(b_IsSheriff[client]) {
			if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary) != 161) {
				SpawnWeapon(client, "tf_weapon_revolver", 161, 1, 0, "2 ; 10.0 ; 96 ; 4.0 ; 3 ; 0.1");
				int iWeapon = GetPlayerWeaponSlot(client, 1);
				if(iWeapon > MaxClients && IsValidEntity(iWeapon))
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
			}
		}
	}
}

public Action Timer_ChooseNewSheriff(Handle timer)
{
	PickSheriff();
	KillTimerSafe(timer);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(b_gIsEnabled && IsValidClient(client)) {
			
		if(b_IsSheriff[client] == true) { // Sheriff has died.
			b_IsSheriff[client] = false;
			CPrintToChatAll("%s The sheriff has been killed.", MURDER_PREFIX);
			PrintCenterTextAll("The sheriff has been killed.");
			i_CountSheriff = 0;
			CreateTimer(10.0, Timer_ChooseNewSheriff);
		}

		if(b_IsMurderer[client] == true) { // Murder died. Innocents win.
			b_IsMurderer[client] = false;
			Warnings[client] = 0;
			Murderer_LastKill[client] = 0;
			
			CPrintToChatAll("%s The murderer this round was %N", MURDER_PREFIX, client);
			PrintCenterTextAll("The murderer has been killed. Innocents win!");
			i_CountMurderer = 0;
			ForceTeamWin(TEAM_RED);
			KillTimerSafe(g_Timer_MurdererAntiAFK[client]);
		}
		
		if(b_IsMurderer[attacker])
		{
			Murderer_LastKill[attacker] = GetTime();
		}
		
		// Put them in blue. Da.
		if(b_IsRoundActive && IsValidClient(client)) {
			SetEventBroadcast(event, true);
			
			if(GetClientTeam(client) == TEAM_RED) {
				b_IsDead[client] = true;
				TF2_ChangeClientTeam(client, TFTeam_Blue);
			}
			
			int AlivePlayers = 0;
			for(int i = 0; i <= MaxClients; i++)
			{
				if(IsValidClient(i) && IsPlayerAlive(i) && !b_IsDead[i] && GetClientTeam(i) == TEAM_RED)
				{
					AlivePlayers++;
				}
			}
			
			if(AlivePlayers < 2) { // To win, all innocent must be dead, including sheriff. So only 1 is alive, assumed to be the murderer.
				ForceTeamWin(TEAM_RED);
			}
		}
	}
	
	Event Escort = CreateEvent("player_escort_score", true);
	SetEventInt(Escort, "player", attacker);
	SetEventInt(Escort, "points", -100);
	FireEvent(Escort);
	
	return Plugin_Handled;
}

stock bool IsValidClient(int client, bool isAlive=false)
{
    if(!client||client>MaxClients||client<1)    return false;
    if(isAlive) return IsClientInGame(client) && IsPlayerAlive(client);
    return IsClientInGame(client);
}

void PickSheriff() {
	if(i_CountSheriff <= 0) { 
		ResignVotes = 0;
		
		ArrayList client_list = new ArrayList(1, MaxClients);
		int count;
		int num_clients;
		
		num_clients = 1; // pick 1 sheriff only
											
		for(int i = 1; i <= MaxClients; i++) {
			if(!b_IsMurderer[i]) {
				b_IsMurderer[i] = false;
				b_IsSheriff[i] = false;
			}
			
			if(IsValidClient(i) && b_IsSheriff[i] == false && b_IsMurderer[i] == false && GetClientTeam(i) == TEAM_RED) {
				client_list.Set(count++, i);
			}
		}

		int index;
		for(int i = 0; i < num_clients; i++) {
			index = GetRandomInt(0, count--);
				
			if(IsValidClient(client_list.Get(index)) && b_IsSheriff[client_list.Get(index)] == false && b_IsMurderer[client_list.Get(index)] == false && GetClientTeam(client_list.Get(index)) == TEAM_RED && b_IsDead[client_list.Get(index)] == false) {
				PrintCenterText(client_list.Get(index), "You are the sheriff this round!");
				CPrintToChat(client_list.Get(index), "%s You are the sheriff this round!", MURDER_PREFIX);
				b_IsSheriff[client_list.Get(index)] = true;
				
				SpawnWeapon(client_list.Get(index), "tf_weapon_revolver", 161, 1, 0, "2 ; 10.0 ; 96 ; 4.0 ; 3 ; 0.1");
				int iWeapon = GetPlayerWeaponSlot(client_list.Get(index), 1);
				if(iWeapon > MaxClients && IsValidEntity(iWeapon))
				SetEntPropEnt(client_list.Get(index), Prop_Send, "m_hActiveWeapon", iWeapon);
				
				i_CountSheriff = 1;
				SetWeaponInvis(client_list.Get(index), false);
			}
			client_list.Erase(index);
		}

		delete client_list;  
	}
}

void PickMurderer() {
	if(i_CountMurderer <= 0) { 
		ArrayList client_list = new ArrayList(1, MaxClients);
		int count;
		int num_clients;
		
		num_clients = 1; // pick 1 murderer only
											
		for(int i = 1; i <= MaxClients; i++) {
			if(!b_IsSheriff[i]) {
				b_IsMurderer[i] = false;
				b_IsSheriff[i] = false;
			}
			
			if(IsValidClient(i) && b_IsMurderer[i] == false && b_IsSheriff[i] == false && GetClientTeam(i) == TEAM_RED) {
				client_list.Set(count++, i);
			}
		}

		int index;
		for(int i = 0; i < num_clients; i++) {
			index = GetRandomInt(0, count--);
				
			if(IsValidClient(client_list.Get(index)) && b_IsMurderer[client_list.Get(index)] == false && b_IsSheriff[client_list.Get(index)] == false && GetClientTeam(client_list.Get(index)) == TEAM_RED) {
				PrintCenterText(client_list.Get(index), "You are the murderer this round!");
				CPrintToChat(client_list.Get(index), "%s You are the murderer this round!", MURDER_PREFIX);
				b_IsMurderer[client_list.Get(index)] = true;
				
				SpawnWeapon(client_list.Get(index), "tf_weapon_knife", 4, 1, 0, "2 ; 10.0");
				int iWeapon = GetPlayerWeaponSlot(client_list.Get(index), 1);
				if(iWeapon > MaxClients && IsValidEntity(iWeapon))
				SetEntPropEnt(client_list.Get(index), Prop_Send, "m_hActiveWeapon", iWeapon);

				i_CountMurderer = 1;
				
				float AntiAFKTime = (GetConVarFloat(g_hCvarAntiAFK) / 3);
				g_Timer_MurdererAntiAFK[client_list.Get(index)] = CreateTimer(AntiAFKTime, Timer_MurdererAntiAFK, client_list.Get(index), TIMER_REPEAT);
				SetWeaponInvis(client_list.Get(index), false);
			}
			client_list.Erase(index);
		}

		delete client_list;  
	}
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, char[] att)
{
    Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
    if (hWeapon == INVALID_HANDLE)
        return -1;
    TF2Items_SetClassname(hWeapon, name);
    TF2Items_SetItemIndex(hWeapon, index);
    TF2Items_SetLevel(hWeapon, level);
    TF2Items_SetQuality(hWeapon, qual);
    char atts[32][32];
    int count = ExplodeString(att, " ; ", atts, 32, 32);
    if (count > 1)
    {
        TF2Items_SetNumAttributes(hWeapon, count/2);
        int i2 = 0;
        for (int i = 0; i < count; i += 2)
        {
            TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
            i2++;
        }
    }  else {
        TF2Items_SetNumAttributes(hWeapon, 0);
	}
    int entity = TF2Items_GiveNamedItem(client, hWeapon);
    CloseHandle(hWeapon);
    EquipPlayerWeapon(client, entity);
    return entity;
}

public void KillTimerSafe(Handle &hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}

public Action Timer_MurdererAntiAFK(Handle timer, int client)
{
	if(!b_IsMurderer[client])
	{
		KillTimerSafe(g_Timer_MurdererAntiAFK[client]);
		return Plugin_Continue;
	}
	
	if(Warnings[client] >= 3)
	{
		Warnings[client] = 0;
	}
	
	float AntiAFKTimeWhole = GetConVarFloat(g_hCvarAntiAFK);
	
	if(GetTime() >= Murderer_LastKill[client]+(RoundToFloor(AntiAFKTimeWhole)))
	{
		Warnings[client]++;
		CPrintToChat(client, "%s {red}If you dont kill someone soon, you will no longer be the murderer.", MURDER_PREFIX);
	}
	else
	{
		Warnings[client] = 0;
	}
	
	if(Warnings[client] >= 3)
	{	
		b_IsMurderer[client] = false;
		i_CountMurderer = 0;
		TF2_RemoveWeaponSlot(client, 2);
		CPrintToChat(client, "%s {red}You took too long and is no longer the murderer!", MURDER_PREFIX);
	}
	
	return Plugin_Continue;
}

public Action Hook_CommandSay(int client, const char[] command, int argc)
{
	if (!b_gIsEnabled) return Plugin_Continue;
	
	if(IsValidClient(client)) {
		if(GetClientTeam(client) == TEAM_BLUE || GetClientTeam(client) == TEAM_SPEC) {
			char sMessage[256];
			GetCmdArgString(sMessage, sizeof(sMessage));
			FakeClientCommand(client, "say_team %s", sMessage);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action Hook_Suicide(int client, const char[] command, int argc)
{
	if (!b_gIsEnabled) return Plugin_Continue;
	
	if(IsValidClient(client)) {
		CPrintToChat(client, "%s You are not allowed to do that.", MURDER_PREFIX);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

stock int SetWeaponInvis(int client, bool set = true) 
{  
    for (int i = 0; i < 5; i++) 
    {  
        int entity = GetPlayerWeaponSlot(client, i);  
        if (entity != -1) 
        {  
            SetEntityRenderMode(entity, RENDER_TRANSCOLOR);  
            SetEntityRenderColor(entity, _, _, _, set ? 50 : 255);  
        }  
    } 
}  

public Action Timer_StartRound(Handle timer) 
{
	PickSheriff();
	PickMurderer();
	
	ChangeFreeState(true);
	
	KillTimerSafe(g_Timer_Start);
	
	//b_IsRoundActive = true;
}

public Action Timer_WaitingPlayers(Handle timer, int client)
{
	int RequiredToStart = (3 - (GetTeamClientCount(TEAM_RED) + GetTeamClientCount(TEAM_BLUE)));
	
	if(RequiredToStart != 0)
	{
		PrintCenterText(client, "Waiting for players! %i more required to start...", RequiredToStart);
	}
	else
	{
		KillTimerSafe(g_Timer_Waiting[client]);
	}
	
	return Plugin_Continue;
}

public void Event_RoundWin(Handle event, const char[] name, bool dontBroadcast)
{
	//int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	ChangeFreeState(false);
	
	//b_gIsEnabled = false;
	b_IsRoundActive = false;
	b_HasSentMMReady = false;
	b_HasSentMMReq = false;
	i_CountSheriff = 0;
	i_CountMurderer = 0;
	ResignVotes = 0;
	
	for(int index = 1; index <= MaxClients; index++) {
		//TF2_RespawnPlayer(index);
		b_IsSheriff[index] = false;
		b_IsMurderer[index] = false;
		b_IsDead[index] = false;
		Warnings[index] = 0;
		Murderer_LastKill[index] = 0;
		
		StopSound(index, SNDCHAN_AUTO, "tfmurder/bgm.wav");
		
		KillTimerSafe(g_Timer_ClientWeps[index]);
		KillTimerSafe(g_Timer_Waiting[index]);
		KillTimerSafe(g_Hud_Timer[index]);
		KillTimerSafe(g_Timer_ClientCheck[index]);
	}
	
	KillTimerSafe(g_Timer_Start);
}