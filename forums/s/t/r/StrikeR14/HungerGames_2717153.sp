#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>

#define TAG "{red}[{default}HG{red}]{default}"
#define TAG2 "{red}[{default}HG{red}]{default} "
#define TEAM_SPEC 1

int bluePresident = -1, redPresident = -1;
int timeLeft;
bool running;
Handle g_timer;

ConVar cvar_time, cvar_supply, cvar_hp;

public Plugin myinfo = 
{
	name = "[TF2] Kill the President", 
	author = "Striker14", 
	description = "Temporary minigame for breaking the routine.", 
	version = "1.0", 
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
	HookEvent("post_inventory_application", OnRegen, EventHookMode_Pre);
	
	RegAdminCmd("sm_president", Cmd_Menu, ADMFLAG_CHEATS);
	
	RegConsoleCmd("autoteam", Command_Autoteam);
	RegConsoleCmd("jointeam", Command_JoinTeam);
	
	cvar_time = CreateConVar("sm_hg_waittime", "5", "Amount of seconds to settle down before the minigame starts.", _, true, 5.0);
	cvar_supply = CreateConVar("sm_hg_supplytime", "30", "Every x seconds, every player receives ammo.", _, true, 5.0);
	cvar_hp = CreateConVar("sm_hg_presidenthp", "1000", "x HP per player in the opposite team.", _, true, 0.0);
	CreateTimer(0.49, ShowPreisdentHP, _, TIMER_REPEAT);
}

public void OnMapStart()
{
	PrecacheSound("vo/announcer_begins_1sec.mp3");
	PrecacheSound("vo/announcer_begins_2sec.mp3");
	PrecacheSound("vo/announcer_begins_3sec.mp3");
	PrecacheSound("vo/announcer_begins_4sec.mp3");
	PrecacheSound("vo/announcer_begins_5sec.mp3");
	PrecacheSound("vo/announcer_dec_missionbegins10s01.mp3");
	PrecacheSound("vo/spy_laughevil01.mp3");
	PrecacheSound("vo/spy_laughevil02.mp3");
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public void OnClientDisconnect(int client)
{
	if (client == bluePresident)
	{
		SetHudTextParams(-1.0, 0.15, 5.0, 255, 0, 0, 255);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				ShowHudText(i, 9, "President %N has disconnected!", client);
			}
		}
		
		CPrintToChatAll("%s The blue president has disconnected!", TAG);
		SDKUnhook(bluePresident, SDKHook_GetMaxHealth, OnGetMaxHealth);
		SDKUnhook(redPresident, SDKHook_GetMaxHealth, OnGetMaxHealth);
		ForceTeamWin(2);
	}
	else if (client == redPresident)
	{
		SetHudTextParams(-1.0, 0.15, 5.0, 255, 0, 0, 255);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				ShowHudText(i, 9, "President %N has disconnected!", client);
			}
		}
		
		CPrintToChatAll("%s The red president has disconnected!", TAG);
		SDKUnhook(bluePresident, SDKHook_GetMaxHealth, OnGetMaxHealth);
		SDKUnhook(redPresident, SDKHook_GetMaxHealth, OnGetMaxHealth);
		ForceTeamWin(3);
	}
}

public Action OnRegen(Event event, const char[] name, bool dontBroadcast)
{
	if (!running)
	{
		return Plugin_Continue;
	}
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientInGame(client) && (client == bluePresident || client == redPresident))
	{
		CreateTimer(0.1, Strip, GetClientUserId(client));
	}
	
	return Plugin_Continue;
}

public Action Strip(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (IsPlayerAlive(client))
	{
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
	}
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientInGame(client) && (client == bluePresident))
	{
		SetHudTextParams(-1.0, 0.15, 5.0, 255, 0, 0, 255);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				ShowHudText(i, 9, "President %N has been defeated! The red team won!", client);
			}
		}
		
		CPrintToChatAll("%s The blue president has been defeated!", TAG);
		SDKUnhook(bluePresident, SDKHook_GetMaxHealth, OnGetMaxHealth);
		SDKUnhook(redPresident, SDKHook_GetMaxHealth, OnGetMaxHealth);
		ForceTeamWin(2);
	}
	else if (IsClientInGame(client) && (client == redPresident))
	{
		SetHudTextParams(-1.0, 0.15, 5.0, 255, 0, 0, 255);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				ShowHudText(i, 9, "President %N has been defeated! The blue team won!", client);
			}
		}
		
		CPrintToChatAll("%s The red president has been defeated!", TAG);
		SDKUnhook(bluePresident, SDKHook_GetMaxHealth, OnGetMaxHealth);
		SDKUnhook(redPresident, SDKHook_GetMaxHealth, OnGetMaxHealth);
		ForceTeamWin(3);
	}
	
	return Plugin_Continue;
}

public Action Command_JoinTeam(int client, int args)
{
	if (running && GetClientTeam(client) != TEAM_SPEC)
	{
		char strTeam[8];
		GetCmdArg(1, strTeam, 8);
		if (!strcmp(strTeam, "blue", true) || !strcmp(strTeam, "red", true))
		{
			PrintCenterText(client, "Please wait until the minigame ends.");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action Command_Autoteam(int client, int args)
{
	if (running && GetClientTeam(client) == TEAM_SPEC)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Cmd_Menu(int client, int args)
{
	if (GetClientCount() < 4)
	{
		CReplyToCommand(client, "%s There are not enough players (4) to start the minigame.", TAG);
		return Plugin_Handled;
	}
	
	if (client)
	{
		Menu menu = CreateMenu(Handler_President);
		menu.SetTitle("Minigame # President");
		menu.AddItem("enable", "Enable");
		menu.AddItem("disable", "Disable");
		menu.Display(client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}

public int Handler_President(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if (!param2)
		{
			if (running)
			{
				CPrintToChat(client, "%s President Day is already running.", TAG);
			}
			else
			{
				timeLeft = cvar_time.IntValue;
				running = true;
				CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
				CShowActivity2(client, TAG2, "Enabled President Day.");
			}
		}
		else if (running)
		{
			if (g_timer != INVALID_HANDLE)
			{
				KillTimer(g_timer);
				g_timer = INVALID_HANDLE;
			}
			
			running = false;
			redPresident = -1;
			bluePresident = -1;
			
			CShowActivity2(client, TAG2, "Disabled President Day.");
		}
		else
			CPrintToChat(client, "%s President Day isn't running.", TAG);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action Timer_Countdown(Handle timer)
{
	if (!running)
	{
		return Plugin_Stop;
	}
	
	PrintCenterTextAll("%02d:%02d", timeLeft / 60, timeLeft % 60);
	
	if (timeLeft == 10)
	{
		EmitSoundToAll("vo/announcer_dec_missionbegins10s01.mp3", -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	else if (1 <= timeLeft <= 5)
	{
		char buffer[32];
		FormatEx(buffer, 32, "vo/announcer_begins_%dsec.mp3", timeLeft);
		EmitSoundToAll(buffer, -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	
	if (timeLeft == 1)
	{
		timeLeft = cvar_supply.IntValue;
		CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
		
		if (redPresident == -1)
		{
			MakePresidents();
			g_timer = CreateTimer(float(cvar_supply.IntValue), Timer_Supply, _, TIMER_REPEAT);
		}
		
		return Plugin_Stop;
	}
	
	timeLeft--;
	return Plugin_Continue;
}

public Action Timer_Supply(Handle timer)
{
	int health;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == bluePresident || i == redPresident)
			continue;
		
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			health = GetClientHealth(i);
			TF2_RegeneratePlayer(i);
			SetEntityHealth(i, health);
		}
	}
	
	CPrintToChatAll("%s Supply has been given to all the players.", TAG);
	return Plugin_Continue;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (1 <= attacker <= MaxClients && IsClientInGame(attacker) && damagecustom == TF_CUSTOM_BACKSTAB && (victim == bluePresident || victim == redPresident))
	{
		// code taken from official FF2
		
		if (GetClientHealth(victim) > cvar_hp.IntValue)
			damage = GetClientHealth(victim) / 3.0;
		else
			damage = float(cvar_hp.IntValue);
		
		damagetype |= DMG_CRIT;
		damagecustom = 0;
		
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);
		SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime() + 2.0);
		SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime() + 2.0);
		
		int viewmodel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
		if (viewmodel > MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker) == TFClass_Spy)
		{
			int melee = GetEntProp(GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee), Prop_Send, "m_iItemDefinitionIndex");
			int animation = 41;
			switch (melee)
			{
				case 225, 356, 423, 461, 574, 649, 1071: //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan
				{
					animation = 15;
				}
				case 638: //Sharp Dresser
				{
					animation = 31;
				}
			}
			
			SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
		}
		
		char buffer[32];
		FormatEx(buffer, 32, "vo/spy_laughevil0%d.mp3", GetRandomInt(1, 2));
		EmitSoundToAll(buffer, -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		
		SetHudTextParams(-1.0, 0.15, 5.0, 255, 0, 0, 255);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				ShowHudText(i, 8, "President %N has been backstabbed by %N!", victim, attacker);
			}
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action ShowPreisdentHP(Handle timer)
{
	if (running && bluePresident != -1 && redPresident != -1)
	{
		SetHudTextParams(0.01, 0.01, 0.5, 255, 255, 255, 255);
		char hp_report[128];
		Format(hp_report, sizeof(hp_report), "%N - %d\n%N - %d", bluePresident, GetClientHealth(bluePresident), redPresident, GetClientHealth(redPresident));
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				ShowHudText(i, 9, hp_report);
		}
	}
	
	return Plugin_Continue;
}

public Action OnGetMaxHealth(int client, int &maxHealth)
{
	if (running && (client == bluePresident))
	{
		maxHealth = cvar_hp.IntValue * GetTeamClientCount(2);
		return Plugin_Changed;
	}
	else if (running && (client == redPresident))
	{
		maxHealth = cvar_hp.IntValue * GetTeamClientCount(3);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

void ForceTeamWin(int team)
{
	if (g_timer != INVALID_HANDLE)
	{
		KillTimer(g_timer);
		g_timer = INVALID_HANDLE;
	}
	
	running = false;
	redPresident = -1;
	bluePresident = -1;
	
	int ent = FindEntityByClassname(-1, "team_control_point_master");
	
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");
}

void MakePresidents()
{
	do
	{
		redPresident = GetRandomInt(1, MaxClients);
	}
	while (!IsClientInGame(redPresident) || GetClientTeam(redPresident) != 2);
	
	SDKHook(redPresident, SDKHook_GetMaxHealth, OnGetMaxHealth);
	TF2_RegeneratePlayer(redPresident);
	CreateTimer(0.1, Strip, GetClientUserId(redPresident));
	
	do
	{
		bluePresident = GetRandomInt(1, MaxClients);
	}
	while (!IsClientInGame(bluePresident) || GetClientTeam(bluePresident) != 3);
	
	SDKHook(bluePresident, SDKHook_GetMaxHealth, OnGetMaxHealth);
	TF2_RegeneratePlayer(bluePresident);
	CreateTimer(0.1, Strip, GetClientUserId(bluePresident));
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == bluePresident || i == redPresident)
		{
			CPrintToChat(i, "%s YOU ARE THE PRESIDENT, you must survive at any cost!", TAG);
		}
		else if (IsClientInGame(i) && GetClientTeam(i) != TEAM_SPEC)
		{
			CPrintToChat(i, "%s %N (%d HP) is your president, you must defend him at any cost!", TAG, GetClientTeam(i) == 2 ? redPresident : bluePresident, 
				GetClientTeam(i) == 2 ? GetClientHealth(redPresident) : GetClientHealth(bluePresident));
		}
	}
} 