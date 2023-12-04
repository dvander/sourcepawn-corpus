#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sdktools_functions>
#include <sdktools_gamerules>

int
	iTime = 2,
	iWinner;
bool
	bEnabled,
	Knife_Round;
static const char
	PL_NAME[]	= "",
	PL_VER[]	= "";

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "",
	author		= "Grey83",
	url			= "https://steamcommunity.com/groups/grey83ds"
}
public Plugin myinfo =
{
	name	= "Knife Round",
	version	= "1.1.0_19.03.2023",
	author	= "Swolly, Grey83",
	url		= "https://forums.alliedmods.net/showthread.php?t=342064"
}

public void OnPluginStart()
{
	LoadTranslations("csgo_knife_round.phrases");
}

public void OnMapStart()
{
	char map[4];
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, map, sizeof(map));

	if((bEnabled = !strncmp(map, "de_", 3, false) || !strncmp(map, "cs_", 3, false)))
	{
		SetCvar("mp_give_player_c4", 0);
		ConVar cvar;
		if((cvar = FindConVar("mp_roundtime"))) iTime = cvar.IntValue;
		SetCvar("mp_roundtime", 1);

		Knife_Round = true;
	}

	static bool hooked;
	if(bEnabled == hooked)
		return;

	if((hooked ^= true))
	{
		HookEvent("round_freeze_end", Event_Start, EventHookMode_PostNoCopy);
		HookEvent("player_spawn", Event_Spawn);
	}
	else
	{
		UnhookEvent("round_freeze_end", Event_Start, EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn", Event_Spawn);
	}
}

public void Event_Start(Handle event, const char[] name, bool dontBroadcast)
{
	if(IsKnifeRound())
	{
		PrintHintTextToAll("%t", "RoundStart_Hint");
		PrintToChatAll("%t", "RoundStart_Chat");

		for(int i = 1; i <= MaxClients; i++) DisarmPlayer(i);
	}
}

public void Event_Spawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(IsKnifeRound()) DisarmPlayer(GetClientOfUserId(GetEventInt(event, "userid")));
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if(!IsKnifeRound() || reason == CSRoundEnd_GameStart)
		return Plugin_Continue;

	switch(reason)
	{
		case CSRoundEnd_TargetBombed, CSRoundEnd_VIPKilled, CSRoundEnd_TerroristsEscaped, CSRoundEnd_TerroristWin, CSRoundEnd_HostagesNotRescued, CSRoundEnd_VIPNotEscaped, CSRoundEnd_CTSurrender:
			iWinner = 2;
		case CSRoundEnd_VIPEscaped, CSRoundEnd_CTStoppedEscape, CSRoundEnd_TerroristsStopped, CSRoundEnd_BombDefused, CSRoundEnd_CTWin, CSRoundEnd_HostagesRescued, CSRoundEnd_TargetSaved, CSRoundEnd_TerroristsNotEscaped, CSRoundEnd_TerroristsSurrender:
			iWinner = 3;
		default:
			iWinner = 0;
	}

	if(iWinner)
	{
		PrintHintTextToAll("%t", "RoundEnd_Hint");
		PrintToChatAll("%t", "RoundEnd_Chat");

		Menu menu = CreateMenu(Menu_Vote, MenuAction_Display|MenuAction_DisplayItem);
		SetMenuTitle(menu, "VoteMenuTitle\n ");
		AddMenuItem(menu, "", "CT");
		AddMenuItem(menu, "", "T\n ");
		SetMenuExitButton(menu, false);

		int[] clients = new int[MaxClients];
		int num;
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == iWinner)
			clients[num++] = i;
		VoteMenu(menu, clients, num, 7);

		delay = 10.0;
	}

	SetCvar("mp_give_player_c4", 1);
	SetCvar("mp_roundtime", iTime);
	Knife_Round = false;

	return iWinner ? Plugin_Changed : Plugin_Continue;
}

public int Menu_Vote(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
			SetMenuTitle(menu, "%t\n ", "VoteMenu_Title");
		case MenuAction_DisplayItem:
		{
			char buffer[32];
			FormatEx(buffer, sizeof(buffer), "%T%s", param2 ? "VoteMenu_T" : "VoteMenu_CT", param1, param2 ? "\n " : "");
			return RedrawMenuItem(buffer);
		}
		case MenuAction_VoteEnd:
		{
			SetCvar("mp_restartgame", 3);

			PrintToChatAll("%t", "TeamChoosed", param1 ? "VoteMenu_T" : "VoteMenu_CT");	// 0 = CT, 1 = T

			int dest = 3 - param1;
			if(dest == iWinner)
				return 0;

			for(int i = 1, team; i <= MaxClients; i++) if(IsClientInGame(i) && (team = GetClientTeam(i)) > 1)
				ChangeClientTeam(i, team == dest ? (5 - dest) : dest);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

void DisarmPlayer(int client)
{
	if(!client || !IsClientInGame(client) || GetClientTeam(client) < 2)
		return;

	for(int j, weapon; j < 5; j++) while((weapon = GetPlayerWeaponSlot(client, j)) != -1)
	{
		RemovePlayerItem(client, weapon);
#if SOURCEMOD_V_MAJOR == 1 && SOURCEMOD_V_MINOR < 10
		AcceptEntityInput(weapon, "Kill");
#else
		RemoveEntity(weapon);
#endif
	}

	SetEntProp(client, Prop_Send, "m_iAccount", 0);
	GivePlayerItem(client, "weapon_knife");
}

bool IsKnifeRound()
{
	return bEnabled && Knife_Round && !GameRules_GetProp("m_bWarmupPeriod");
}

void SetCvar(char[] name, int value)
{
	ConVar cvar = FindConVar(name);
	if(!cvar)
		return;

	int flags = GetConVarFlags(cvar);
	SetConVarFlags(cvar, (flags & ~FCVAR_NOTIFY));
	SetConVarInt(cvar, value);
	SetConVarFlags(cvar, flags);
}