#include <sourcemod>
#include <sdktools>

#define PREFIX "\x01[\x03SM\x01]"

float gf_UsedVAR[32];
Handle ARVEnabled = INVALID_HANDLE, gHud;
bool gb_AutoRespawn = false, gb_ARVoted[32] =  { false, ... };
int gi_ARVoters = 0, gi_ARVotes = 0, gi_ARVotesNeeded = 0, gVAR, TimeAR, SpawnProtection, ARTime;

public Plugin myinfo = 
{
	name = "[CSGO] Advanced Auto Respawn", 
	author = "BaroNN", 
	description = "", 
	version = "1.5", 
	url = "http://steamcommunity.com/id/BaRoNN-Main"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_votear", PlayerVoting);
	RegAdminCmd("sm_ar", AR, ADMFLAG_GENERIC);
	ARVEnabled = CreateConVar("sm_autorespawn_playervote", "0", "Player vote Enabled?");
	HookConVarChange(ARVEnabled, OnCvarChanged);
	HookEvent("player_spawn", Hook);
	gHud = CreateHudSynchronizer();
}

public void OnMapStart()
{
	ServerCommand("sm_cvar mp_autokick 0")
}

public Action AR(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	char String1[128];
	Handle menu = CreateMenu(MenuHandelr);
	SetMenuTitle(menu, "[AutoRespawn] Main Menu");
	
	if (!gVAR)AddMenuItem(menu, "", "Enable AutoRespawn");
	else AddMenuItem(menu, "", "Disable AutoRespawn");
	
	Format(String1, 128, "Time: %d minutes", ARTime);
	if (ARTime != 0)AddMenuItem(menu, "", String1);
	else AddMenuItem(menu, "", "Time: Unlimted");
	
	Format(String1, 128, "Spawn Protection - %s", SpawnProtection ? ("Yes"):("No"));
	AddMenuItem(menu, "", String1);
	
	if (!gVAR)AddMenuItem(menu, "", "Vote For AutoRespawn");
	else AddMenuItem(menu, "", "Vote For AutoRespawn", ITEMDRAW_DISABLED);
	
	DisplayMenu(menu, client, 15);
	return Plugin_Continue;
}

public int MenuHandelr(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action != MenuAction_Select || !IsClientConnected(client))
		return 1;
	
	switch (itemNum)
	{
		case 0:
		{
			if (gVAR)
			{
				gVAR = 0;
				TimeAR = false;
				AR(client, 0);
				ServerCommand("mp_respawn_on_death_t 0"), ServerCommand("mp_respawn_on_death_ct 0");
				PrintToChatAll("%s \x01%N \x02Disabled \x04Auto Respawn!", PREFIX, client);
				SetHudTextParams(0.3, 0.150, 5.0, 255, 0, 0, 255, 1, 0.1, 0.1, 0.1);
				for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))ShowSyncHudText(i, gHud, "%N Disabled Auto Respawn!", client);
			}
			else
			{
				gVAR = 1;
				AR(client, 0);
				ServerCommand("mp_respawn_on_death_t 1"), ServerCommand("mp_respawn_on_death_ct 1");
				
				if (ARTime != 0)
				{
					TimeAR = true;
					int sec = ARTime * 60;
					CreateTimer(float(sec), DisableAutoRespawn, client);
					PrintToChatAll("%s \x01%N \x04Enabled\x03 Auto Respawn for %d minutes!", PREFIX, client, ARTime);
					SetHudTextParams(0.3, 0.150, 5.0, 0, 250, 0, 255, 1, 0.1, 0.1, 0.1);
					for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))ShowSyncHudText(i, gHud, "%N Enabled Auto Respawn for %d minutes!", client, ARTime);
				}
				else
				{
					PrintToChatAll("%s \x01%N \x04Enabled\x03 Auto Respawn!", PREFIX, client);
					SetHudTextParams(0.3, 0.150, 5.0, 0, 255, 0, 255, 1, 0.1, 0.1, 0.1);
					for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))ShowSyncHudText(i, gHud, "%N Enabled Auto Respawn!", client);
				}
			}
		}
		case 1:
		{
			ARTime += 5;
			if (ARTime > 60)ARTime = 0;
			AR(client, 0);
		}
		case 2:
		{
			SpawnProtection = !SpawnProtection;
			SetHudTextParams(0.3, 0.150, 5.0, 255, 215, 0, 255, 1, 0.1, 0.1, 0.1);
			for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))ShowSyncHudText(i, gHud, "%N %s Spawn Protection!", client, SpawnProtection ? ("Enabled"):("Disabled"));
			AR(client, 0);
		}
		case 3:
		{
			gVAR = 1;
			ShowMenu();
			PrintToChatAll("%s \x01%N \x04Started a\x03 Vote for Auto Respawn", PREFIX, client);
			SetHudTextParams(0.3, 0.150, 5.0, 0, 0, 255, 255, 1, 0.1, 0.1, 0.1);
			for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))ShowSyncHudText(i, gHud, "%N Started a Vote for Auto Respawn", client);
		}
	}
	return 0;
}

public Action PlayerVoting(int client, int args)
{
	if (GetConVarBool(ARVEnabled))
	{
		if (GetEngineTime() - gf_UsedVAR[client] < 5)
		{
			PrintToChat(client, "%s \x02Vote AutoRespawn\x04 Is allowed once in 5 seconds", PREFIX);
			return Plugin_Handled;
		}
		gf_UsedVAR[client] = GetEngineTime();
		
		char name[64];
		GetClientName(client, name, sizeof(name));
		if (!gb_ARVoted[client])
		{
			gi_ARVotes++;
			PrintToChatAll("%s \x02%s\x04 Wants To \x02%s%\x04 AutoRespawn (%d votes, %d required)", PREFIX, name, gb_AutoRespawn ? "Disable":"Enable", gi_ARVotes, gi_ARVotesNeeded);
		}
		else
		{
			gi_ARVotes--;
			PrintToChatAll("%s \x02%s\x04 devoted (%d votes, %d required)", PREFIX, name, gi_ARVotes, gi_ARVotesNeeded);
		}
		
		SetConVarInt(ARVEnabled, 1);
		gb_ARVoted[client] = !gb_ARVoted[client];
		
		if (gi_ARVotes >= gi_ARVotesNeeded)
		{
			EnableAutoRespawn();
		}
		return Plugin_Handled;
	}
	else
	{
		SetConVarInt(ARVEnabled, 0);
		PrintToChat(client, "%s \x02Player Voting is Currently Disabled!", PREFIX)
	}
	return Plugin_Handled;
}

public void ShowMenu()
{
	if (IsVoteInProgress())
	{
		return;
	}
	
	Handle vote = CreateMenu(VoteCT_Handler);
	SetMenuTitle(vote, "[SM] Enable AutoRespawn?");
	AddMenuItem(vote, "Yes", "Yes");
	AddMenuItem(vote, "No", "No");
	SetMenuExitButton(vote, false);
	
	VoteMenuToAll(vote, 20);
}

public VoteCT_Handler(Handle menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_VoteEnd)
	{
		char info[32];
		GetMenuItem(menu, param1, info, 32);
		
		if (StrEqual(info, "Yes"))
		{
			gVAR = 1;
			ServerCommand("mp_respawn_on_death_ct 1");
			ServerCommand("mp_respawn_on_death_t 1");
			PrintToChatAll("%s \x04Vote has been Success\x10 AutoRespawn Has been \x04Enabled", PREFIX);
			SetHudTextParams(0.3, 0.150, 5.0, 0, 240, 0, 255, 1, 0.1, 0.1, 0.1);
			for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))ShowSyncHudText(i, gHud, "Vote has been Success, AutoRespawn Has been Enabled!");
		}
		else if (StrEqual(info, "No"))
		{
			gVAR = 0;
			ServerCommand("mp_respawn_on_death_ct 0");
			ServerCommand("mp_respawn_on_death_t 0");
			PrintToChatAll("%s \x02Vote Failed\x10 AutoRespawn Will Be \x02Disabled", PREFIX);
			SetHudTextParams(0.3, 0.150, 5.0, 240, 0, 0, 255, 1, 0.1, 0.1, 0.1);
			for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))ShowSyncHudText(i, gHud, "Vote Failed, AutoRespawn Will Be Disabled!");
		}
	}
	return 0;
}

public Action DisableAutoRespawn(Handle timer, any client)
{
	if (TimeAR)
	{
		gVAR = 0;
		SetHudTextParams(0.3, 0.150, 5.0, 0, 230, 0, 255, 1, 0.1, 0.1, 0.1);
		for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))ShowSyncHudText(i, gHud, "AutoRespawn Has Been Disabled Automatically!");
		PrintToChatAll("%s \x02Auto Respawn has been \x02Disabled \x10Automatically!", PREFIX);
		ServerCommand("mp_respawn_on_death_ct 0");
		ServerCommand("mp_respawn_on_death_t 0");
	}
}

EnableAutoRespawn()
{
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		gb_ARVoted[i] = false;
	}
	gi_ARVotes = 0;
	gi_ARVotesNeeded = RoundToFloor(float(gi_ARVoters) * 0.5);
	gb_AutoRespawn = !gb_AutoRespawn;
	
	if (gb_AutoRespawn)
	{
		gVAR = 1;
		gb_AutoRespawn = true;
		ServerCommand("mp_respawn_on_death_ct 1");
		ServerCommand("mp_respawn_on_death_t 1");
	}
	else
	{
		gVAR = 0;
		gb_AutoRespawn = false;
		ServerCommand("mp_respawn_on_death_ct 0");
		ServerCommand("mp_respawn_on_death_t 0");
	}
	PrintToChatAll("%s \x03AutoRespawn Has been \x02%s", PREFIX, gb_AutoRespawn ? "Enabled":"Disabled");
	SetHudTextParams(0.3, 0.150, 5.0, 255, 215, 0, 255, 1, 0.1, 0.1, 0.1);
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))ShowSyncHudText(i, gHud, "AutoRespawn Has been %s", gb_AutoRespawn ? "Enabled":"Disabled");
}

public OnCvarChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if (cvar == ARVEnabled)
	{
		if (GetConVarBool(ARVEnabled))
		{
			PrintToChatAll("[SM] \x04Player Auto Respawn Voting is now \x03%sabled", StringToInt(newVal) ? "En":"Dis");
		}
	}
}

public Action Hook(Handle event, const char[] name, bool dontBroadcast)
{
	if (SpawnProtection)
	{
		SpawnProtection = 1;
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(5.0, Timer_GodMode, GetClientSerial(client));
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
	}
}

public Action Timer_GodMode(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (client == 0) { return Plugin_Stop; }
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
	return Plugin_Handled;
}

stock bool IsValidClient(int client, bool bAlive = false)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	return false;
}
