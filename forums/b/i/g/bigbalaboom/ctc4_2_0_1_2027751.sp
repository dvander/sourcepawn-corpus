#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

new Handle:g_Cvar_CTC4;
new Handle:g_Cvar_Pickup;
new Handle:g_Cvar_Plant;
new Handle:g_Cvar_Bonus;
new Handle:g_Cvar_Penalty;
new Handle:g_Cvar_Health;
new Handle:g_Cvar_Score;
new Handle:g_Timer_ForceAbort = INVALID_HANDLE;
new bool:g_AllowPickup = true;
new bool:g_AllowPlant = true;
new g_PlantedBy = 0;
new g_Planter = 0;
new g_Winner = 0;
new g_AccountOffset = -1;

public Plugin:myinfo =
{
	name = "CTC4",
	author = "bigbalaboom",
	description = "Allows CTs to pickup/drop/plant the C4.",
	version = "2.0.1",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	g_Cvar_CTC4	= CreateConVar("sm_ctc4",		"1",	"Enables/disables CTC4 plugin.");
	g_Cvar_Pickup	= CreateConVar("sm_ctc4_pickup",	"1",	"Enables/disables CTs to pick up the C4.");
	g_Cvar_Plant	= CreateConVar("sm_ctc4_plant",		"1",	"Enables/disables CTs to plant the C4.");
	g_Cvar_Bonus	= CreateConVar("sm_ctc4_cash_bonus",	"3250",	"Amount of money given to the winning team.");
	g_Cvar_Penalty	= CreateConVar("sm_ctc4_cash_penalty",	"5000",	"Amount of money taken from the losing team.");
	g_Cvar_Health	= CreateConVar("sm_ctc4_hp_penalty",	"70",	"Amount of health for punishing the losing CT planter.");
	g_Cvar_Score	= CreateConVar("sm_ctc4_match_score",	"1",	"Enables/disables score changing according to CTC4 winning rule.");
	AutoExecConfig(true, "ctc4");

	g_AccountOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

	HookEvent("round_start",	Event_RoundStart);
	HookEvent("round_end",		Event_RoundEnd);
	HookEvent("bomb_dropped",	Event_Dropped);
	HookEvent("bomb_beginplant",	Event_BeginPlant);
	HookEvent("bomb_planted",	Event_Planted);
	HookEvent("bomb_begindefuse",	Event_BeginDefuse);
	HookEvent("bomb_defused",	Event_KillTimer);
	HookEvent("bomb_exploded",	Event_KillTimer);
	HookEvent("bomb_abortdefuse",	Event_KillTimer);

	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_Touch, OnTouch);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, OnTouch);
}

public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (GetConVarBool(g_Cvar_CTC4) && IsClientInGame(players[0]) && GetClientTeam(players[0]) == CS_TEAM_CT)
	{
		decl String:buffer[64];
		BfReadString(bf, buffer, sizeof(buffer), false);
		if ((!GetConVarBool(g_Cvar_Plant) && (StrContains(buffer, "C4_Plant_At_Bomb_Spot") != -1 || StrContains(buffer, "C4_Plant_Must_Be_On_Ground") != -1)) || (g_PlantedBy == 3 && StrContains(buffer, "C4_Defuse_Must_Be_On_Ground") != -1))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_Winner)
	{
		if (GetConVarBool(g_Cvar_Score))
		{
			if (g_Winner == 3)
			{
				new ScoreT = GetTeamScore(CS_TEAM_T);
				new ScoreCT = GetTeamScore(CS_TEAM_CT);

				CS_SetTeamScore(CS_TEAM_T, ScoreT - 1);
				SetTeamScore(CS_TEAM_T, ScoreT - 1);

				CS_SetTeamScore(CS_TEAM_CT, ScoreCT + 1);
				SetTeamScore(CS_TEAM_CT, ScoreCT + 1);
			}
		}

		if (g_AccountOffset != -1)
		{
			new bonus = GetConVarInt(g_Cvar_Bonus);
			new penalty = GetConVarInt(g_Cvar_Penalty);
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					new current_money = GetEntData(i, g_AccountOffset);

					if ((g_Winner == 2 && GetClientTeam(i) == CS_TEAM_T) || (g_Winner == 3 && GetClientTeam(i) == CS_TEAM_CT))
					{
						SetEntData(i, g_AccountOffset, current_money + bonus + 3250 >= 16000 ? 16000 : current_money + bonus + 3250);
					}

					if (g_Winner == 2 && GetClientTeam(i) == CS_TEAM_CT)
					{
						SetEntData(i, g_AccountOffset, current_money - penalty - 1400 <= 0 ? 0 : current_money - penalty - 1400);
					}
				}
			}
		}

		if (g_Winner == 2 && g_Planter && IsClientInGame(g_Planter) && IsPlayerAlive(g_Planter))
		{
			CreateTimer(0.2, Timer_Slap, g_Planter, TIMER_REPEAT);
		}
	}
	g_PlantedBy = 0;
	g_Planter = 0;
	g_Winner = 0;
	g_AllowPlant = true;
}

public Action:Timer_Slap(Handle:timer, any:client)
{
	static slapped_health = 0;

	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new current_health = GetEntProp(client, Prop_Send, "m_iHealth");
		new health_to_slap = GetConVarInt(g_Cvar_Health);
		if (current_health > 1 && slapped_health < health_to_slap)
		{
			if (current_health - 5 <= 0)
			{
				SlapPlayer(client, current_health - 1, true);
				slapped_health += current_health - 1;
			}
			else
			{
				SlapPlayer(client, 5, true);
				slapped_health += 5;
			}
		}

		if (slapped_health >= health_to_slap || current_health == 1)
		{
			slapped_health = 0;
			return Plugin_Stop;
		}
	}
	return Plugin_Handled;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_AllowPlant = false;
	if (GetConVarBool(g_Cvar_CTC4) && g_PlantedBy == 3)
	{
		new alive_ts = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			StopSound(i, SNDCHAN_STATIC, "radio/ctwin.wav");
			StopSound(i, SNDCHAN_STATIC, "radio/terwin.wav");

			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				alive_ts++;
			}
		}
		if (!alive_ts)
		{
			g_Winner = 3;
			EmitSoundToAll("radio/ctwin.wav");
			PrintCenterTextAll("Counter-Terrorists Win!");
		}
		else
		{
			g_Winner = 2;
			EmitSoundToAll("radio/terwin.wav");
			PrintCenterTextAll("Terrorists Win!");
		}
	}
}

public OnTouch(client, weapon)
{
	if (GetConVarBool(g_Cvar_CTC4) && GetConVarBool(g_Cvar_Pickup) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		decl String:weapon_name[64];
		GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
		if (StrContains(weapon_name, "weapon_c4") != -1 && g_AllowPickup)
		{
			SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_T);
			RemoveEdict(weapon);
			GivePlayerItem(client, "weapon_c4");
			SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_CT);

			decl String:player_name[MAX_NAME_LENGTH];
			GetClientName(client, player_name, sizeof(player_name));
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
				{
					PrintToChat(i, "\x04[CTC4] %s%s \x01picked up the bomb.", "\x079ACDFF", player_name);
				}
			}
		}
	}
}

public Action:Event_Dropped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_CTC4))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			g_AllowPickup = false;
			CreateTimer(2.0, Timer_EnablePickup);

			decl String:player_name[MAX_NAME_LENGTH];
			GetClientName(client, player_name, sizeof(player_name));

			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
				{
					PrintToChat(i, "\x04[CTC4] %s%s \x01dropped the bomb.", "\x079ACDFF", player_name);
				}
			}
		}
	}
}

public Action:Event_BeginPlant(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_CTC4))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if ((!GetConVarBool(g_Cvar_Plant) && GetClientTeam(client) == CS_TEAM_CT) || !g_AllowPlant)
		{
			if (!g_AllowPlant)
			{
				PrintCenterText(client, "Bomb is not allowed to be planted at this moment.");
			}
			else
			{
				PrintCenterText(client, "Only terrorists can plant the bomb.");
			}

			new bomb = -1;
			if ((bomb = GetPlayerWeaponSlot(client, _:4)) != -1)
			{
				g_AllowPickup = false;
				CS_DropWeapon(client, bomb, true, false);
				CreateTimer(2.0, Timer_EnablePickup);
			}
		}
	}
}

public Action:Timer_EnablePickup(Handle:timer)
{
	g_AllowPickup = true;
}

public Action:Event_Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_CTC4))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		g_Planter = client;
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			g_PlantedBy = 3;
			PrintCenterTextAll("A counter-terrorist has planted the bomb.");

			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if (GetClientTeam(i) == CS_TEAM_T)
					{
						PrintToChat(i, "\x04[CTC4] \x01At least one terrorist must survive to win this round.");
					}
					else
					{
						PrintToChat(i, "\x04[CTC4] \x01All terrorists must be eliminated to win this round.");
					}
				}
			}
		}
		else
		{
			g_PlantedBy = 2;
		}
	}
}

public Action:Event_BeginDefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_CTC4) && g_PlantedBy == 3)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		g_Timer_ForceAbort = CreateTimer(GetEntProp(client, Prop_Send, "m_bHasDefuser") ? 4.8 : 9.8, Timer_ForceAbort, any:client);
	}
}

public Action:Timer_ForceAbort(Handle:timer, any:client)
{
        SetEntProp(client, Prop_Send, "m_fFlags", 8);
        PrintToChat(client, "\x04[CTC4] \x01You have entered a wrong passcode.");
	KillTimer(g_Timer_ForceAbort);
	g_Timer_ForceAbort = INVALID_HANDLE;
}

public Action:Event_KillTimer(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_CTC4))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		SetEntProp(client, Prop_Send, "m_fFlags", 1);

		if (g_Timer_ForceAbort != INVALID_HANDLE)
		{
			KillTimer(g_Timer_ForceAbort);
			g_Timer_ForceAbort = INVALID_HANDLE;
		}
	}
}