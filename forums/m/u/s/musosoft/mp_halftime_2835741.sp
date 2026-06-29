#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

ConVar			 mp_halftime;
bool			 firsthalf = false;
bool			 swap	   = false;

public Plugin myinfo =
{
	name		= "[CS:S] mp_halftime",
	author		= "GabenNewell (Bad Kitty), muso.sk",
	description = "Determines whether the match switches sides in a halftime event.",
	version		= "2.0.1",
	url			= "https://forums.alliedmods.net/showthread.php?t=241716"
};

public void OnPluginStart()
{
	mp_halftime = CreateConVar("mp_halftime", "1",
							   "Determines whether the match switches sides in a halftime event.",
							   FCVAR_NOTIFY, true, 0.0, true, 1.0);

	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if ((CS_GetTeamScore(2) + CS_GetTeamScore(3)) == 0)
		firsthalf = true;

	if (GetConVarBool(mp_halftime) && swap)
	{
		SwitchSides();
		swap = false;
	}

	return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(mp_halftime) && firsthalf)
	{
		int maxrounds = GetConVarInt(FindConVar("mp_maxrounds"));
		int timeleft, timelimit;
		GetMapTimeLeft(timeleft);
		GetMapTimeLimit(timelimit);

		if ((maxrounds != 0 && (CS_GetTeamScore(2) + CS_GetTeamScore(3)) == (maxrounds / 2))
			|| (timelimit != 0 && timeleft <= (timelimit * 60 / 2)))
		{
			swap	  = true;
			firsthalf = false;
			CreateTimer(0.0, CountdownEnd);
		}
	}
}

void SwitchSides()
{
	int startmoney = GetConVarInt(FindConVar("mp_startmoney"));

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) > 1)
		{
			for (int weapon, i = 0; i < 5; i++)
			{
				while ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
				{
					if (i == 4)
						CS_DropWeapon(client, weapon, false, true);
					else
						RemovePlayerItem(client, weapon);
				}
			}

			SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
			SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
			SetEntProp(client, Prop_Send, "m_iAccount", startmoney);

			CS_SwitchTeam(client, (GetClientTeam(client) == 2) ? 3 : 2);
			CS_RespawnPlayer(client);
		}
	}

	int tmp = CS_GetTeamScore(2);
	CS_SetTeamScore(2, CS_GetTeamScore(3));
	CS_SetTeamScore(3, tmp);

	SetTeamScore(2, CS_GetTeamScore(2));
	SetTeamScore(3, CS_GetTeamScore(3));

	int foundC4 = 0;

	int ent		= -1;
	while ((ent = FindEntityByClassname(ent, "func_bomb_target")) != -1)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "weapon_c4")) != -1)
		{
			RemoveEntity(entity);
			foundC4 = 1;
		}
	}

	if (foundC4)
	{
		GiveC4ToRandomTerrorist();
	}
}

void GiveC4ToRandomTerrorist()
{
	ArrayList terrorists = new ArrayList();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T)
		{
			terrorists.Push(client);
		}
	}

	int terroristCount = terrorists.Length;

	if (terroristCount > 0)
	{
		int randomIndex		= GetRandomInt(0, terroristCount - 1);
		int chosenTerrorist = terrorists.Get(randomIndex);

		GivePlayerItem(chosenTerrorist, "weapon_c4");
	}

	delete terrorists;
}

public Action CountdownEnd(Handle timer)
{
	FadeMessage(3);
	CreateTimer(1.0, CountdownEnd2);
	return Plugin_Handled;
}

public Action CountdownEnd2(Handle timer)
{
	FadeMessage(2);
	CreateTimer(1.0, CountdownEnd3);
	return Plugin_Handled;
}

public Action CountdownEnd3(Handle timer)
{
	FadeMessage(1);
	CreateTimer(1.0, StartGame);
	return Plugin_Handled;
}

public Action StartGame(Handle timer)
{
	PrintCenterTextAll("The game will start in 1 SECOND");
	return Plugin_Handled;
}

void FadeMessage(int number)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			Handle fade_msg = StartMessageOne("Fade", i);
			if (fade_msg != INVALID_HANDLE)
			{
				BfWriteShort(fade_msg, 500);	   // Duration
				BfWriteShort(fade_msg, 40);		   // Hold time
				BfWriteShort(fade_msg, 0x0003);	   // Fade in/out flags

				switch (GetClientTeam(i))
				{
					case CS_TEAM_T:
					{
						BfWriteByte(fade_msg, 0);	   // Red
						BfWriteByte(fade_msg, 0);	   // Green
						BfWriteByte(fade_msg, 255);	   // Blue
						BfWriteByte(fade_msg, 100);	   // Alpha
					}
					case CS_TEAM_CT:
					{
						BfWriteByte(fade_msg, 255);
						BfWriteByte(fade_msg, 0);
						BfWriteByte(fade_msg, 0);
						BfWriteByte(fade_msg, 100);
					}
					default:
					{
						BfWriteByte(fade_msg, 255);
						BfWriteByte(fade_msg, 255);
						BfWriteByte(fade_msg, 255);
						BfWriteByte(fade_msg, 100);
					}
				}
				EndMessage();

				PrintCenterText(i, "Second Half in %i", number);
			}
		}
	}
}