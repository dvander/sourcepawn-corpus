#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <csgocolors_fix>

#define VERSION "1.2.0"

public Plugin myinfo =
{
	name			= "ZProp",
	author		= "Darkthrone, Greyscale, kurumi",
	description = "Spawn props in game. Rewrited by kurumi.",
	version		= VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=1893141"
};

int g_iCredits[MAXPLAYERS];
int offsEyeAngle0;

Handle kvProps;

ConVar cvarCreditsMax;
ConVar cvarCreditsConnect;
ConVar cvarCreditsSpawn;
ConVar cvarCreditsInfect;
ConVar cvarCreditsKill;
ConVar cvarCreditsRoundStart;

public void OnPluginStart()
{
	LoadTranslations("zprop.phrases");

	HookEvent("player_spawn", PlayerSpawn_Event);
	HookEvent("player_death", PlayerDeath_Event);
	HookEvent("player_team", PlayerTeam_Event);
	HookEvent("round_start", RoundStart_Event);

	offsEyeAngle0 = FindSendPropInfo("CCSPlayer", "m_angEyeAngles[0]");
	if (offsEyeAngle0 == -1)
	{
		SetFailState("Couldn't find \"m_angEyeAngles[0]\"!");
	}

	RegConsoleCmd("sm_zprops", Zprops_Command, "ZProp command.");

	cvarCreditsMax = CreateConVar("zprop_credits_max", "15", "Max credits that can be attained (0: No limit).");
	cvarCreditsConnect = CreateConVar("zprop_credits_connect", "4", "The number of free credits a player received when they join the game.");
	cvarCreditsSpawn = CreateConVar("zprop_credits_spawn", "1", "The number of free credits given on spawn.");
	cvarCreditsInfect = CreateConVar("zprop_credits_infect", "1", "The number of credits given for infecting a human as zombie.");
	cvarCreditsKill = CreateConVar("zprop_credits_kill", "5", "The number of credits given for killing a zombie as human.");
	cvarCreditsRoundStart = CreateConVar("zprop_credits_roundstart", "2", "The number of free credits given on start of the round.");

	CreateConVar("gs_zprop_version", VERSION, "[ZProp] Current version of this plugin", FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	AutoExecConfig(true, "zprop");
}

public void OnMapStart()
{
	if(kvProps != INVALID_HANDLE)
	{
		delete kvProps;
	}

	kvProps = CreateKeyValues("zprops");

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/zprops.txt");
	if (!FileToKeyValues(kvProps, path))
	{
		SetFailState("\"%s\" missing from server", path);
	}
}

public void OnClientPutInServer(int iClient)
{
	g_iCredits[iClient] = -1;
}

public Action Zprops_Command(int iClient, int args)
{
	if(IsPlayerAlive(iClient))
	{
		MainMenu(iClient);
	}
	
	return Plugin_Handled;
}

public void GetViewVector(float vecAngle[3], float output[3])
{
	output[0] = Cosine(vecAngle[1] / (180 / FLOAT_PI));
	output[1] = Sine(vecAngle[1] / (180 / FLOAT_PI));
	output[2] = -Sine(vecAngle[0] / (180 / FLOAT_PI));
}

public void AddInFrontOf(float vecOrigin[3], float vecAngle[3], int units, float output[3])
{
	float vecView[3];

	GetViewVector(vecAngle, vecView);
	
	output[0] = vecView[0] * units + vecOrigin[0];
	output[1] = vecView[1] * units + vecOrigin[1];
	output[2] = vecView[2] * units + vecOrigin[2];
}

public int MainMenu_Handle(Handle menu_main, MenuAction action, int iClient, int slot)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char propname[MAX_MESSAGE_LENGTH];
			if(GetMenuItem(menu_main, slot, propname, sizeof(propname)))
			{
				KvRewind(kvProps);

				if(KvJumpToKey(kvProps, propname))
				{
					int cost = KvGetNum(kvProps, "cost");

					if(g_iCredits[iClient] < cost)
					{
						CPrintToChat(iClient, "%t%t", "ZProp", "Insufficient credits", g_iCredits[iClient], cost);
						MainMenu(iClient);

						return 0;
					}

					float vecOrigin[3];
					float vecAngles[3];

					GetClientAbsOrigin(iClient, vecOrigin);
					GetClientAbsAngles(iClient, vecAngles);

					vecAngles[0] = GetEntDataFloat(iClient, offsEyeAngle0);
					vecOrigin[2] += 50;

					float vecFinal[3];
					AddInFrontOf(vecOrigin, vecAngles, 35, vecFinal);

					char propmodel[PLATFORM_MAX_PATH];
					KvGetString(kvProps, "model", propmodel, sizeof(propmodel));
					char proptype[PLATFORM_MAX_PATH];
					KvGetString(kvProps, "type", proptype, sizeof(proptype), "prop_physics");

					int prop = CreateEntityByName(proptype);
					PrecacheModel(propmodel);
					SetEntityModel(prop, propmodel);
					DispatchSpawn(prop);
					TeleportEntity(prop, vecFinal, NULL_VECTOR, NULL_VECTOR);

					g_iCredits[iClient] -= cost;
					ZProp_HudHint(iClient, "Credits left spend", cost, g_iCredits[iClient]);
					CPrintToChat(iClient, "%t%t", "ZProp", "Spawn prop", propname);
				}
			}

			return 0;
		}

		case MenuAction_End:
		{
			delete menu_main;
		}
	}

	return 0;
}

public void MainMenu(int iClient)
{
	Menu menu_main = CreateMenu(MainMenu_Handle);

	SetGlobalTransTarget(iClient);
	SetMenuTitle(menu_main, "%t\n ", "Menu title", g_iCredits[iClient]);

	char propname[PLATFORM_MAX_PATH];
	char display[MAX_MESSAGE_LENGTH];

	KvRewind(kvProps);

	if(KvGotoFirstSubKey(kvProps))
	{
		do
		{
			KvGetSectionName(kvProps, propname, sizeof(propname));
			int cost = KvGetNum(kvProps, "cost");
			Format(display, sizeof(display), "%t", "Menu option", propname, cost);

			if (g_iCredits[iClient] >= cost)
			{
				AddMenuItem(menu_main, propname, display);
			}
			else
			{
				AddMenuItem(menu_main, propname, display, ITEMDRAW_DISABLED);
			}
		}
		while(KvGotoNextKey(kvProps));
	}

	DisplayMenu(menu_main, iClient, MENU_TIME_FOREVER);

}

public Action PlayerSpawn_Event(Handle event, const char[] command, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetClientTeam(iClient);
	if(team != CS_TEAM_T && team != CS_TEAM_CT)
	{
		return Plugin_Handled;
	}

	int credits_max = GetConVarInt(cvarCreditsMax);
	int credits_spawn = GetConVarInt(cvarCreditsSpawn);
	g_iCredits[iClient] += credits_spawn;

	if(g_iCredits[iClient] < credits_max)
	{
		ZProp_HudHint(iClient, "Credits left gain", credits_spawn, g_iCredits[iClient]);
		return Plugin_Handled;
	}

	g_iCredits[iClient] = credits_max;
	ZProp_HudHint(iClient, "Credits left max", credits_spawn, g_iCredits[iClient]);

	return Plugin_Handled;
}

public Action PlayerDeath_Event(Handle event, const char[] command, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!attacker)
	{
		return Plugin_Handled;
	}

	char weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	int credits_earned = StrEqual(weapon, "zombie_claws_of_death") ? GetConVarInt(cvarCreditsInfect) : GetConVarInt(cvarCreditsKill);
	int credits_max = GetConVarInt(cvarCreditsMax);
	g_iCredits[attacker] += credits_earned;
	
	if(g_iCredits[attacker] < credits_max)
	{
		ZProp_HudHint(attacker, "Credits left gain", credits_earned, g_iCredits[attacker]);
		return Plugin_Handled;
	}

	g_iCredits[attacker] = credits_max;
	ZProp_HudHint(attacker, "Credits left max", credits_earned, g_iCredits[attacker]);

	return Plugin_Handled;
}

public Action PlayerTeam_Event(Handle event, const char[] command, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!iClient)
	{
		return Plugin_Handled;
	}

	if(g_iCredits[iClient] == -1)
	{
		g_iCredits[iClient] = GetConVarInt(cvarCreditsConnect);
		CPrintToChat(iClient, "%t", "Join message");
	}

	return Plugin_Handled;
}

public Action RoundStart_Event(Handle event, const char[] command, bool dontBroadcast)
{
	for(int iClient = 1; iClient < MaxClients; ++iClient)
	{
		if(IsClientInGame(iClient) && GetClientTeam(iClient) > 1)
		{
			int credits_max = GetConVarInt(cvarCreditsMax);
			int credits_roundstart = GetConVarInt(cvarCreditsRoundStart);
			g_iCredits[iClient] += credits_roundstart;

			if(g_iCredits[iClient] < credits_max)
			{
				ZProp_HudHint(iClient, "Credits left gain", credits_roundstart, g_iCredits[iClient]);
				return Plugin_Handled;
			}

			g_iCredits[iClient] = credits_max;
			ZProp_HudHint(iClient, "Credits left max", credits_roundstart, g_iCredits[iClient]);
		}
	}

	return Plugin_Handled;
}

public void ZProp_HudHint(int iClient, any ...)
{
	SetGlobalTransTarget(iClient);

	char phrase[MAX_MESSAGE_LENGTH];
	VFormat(phrase, sizeof(phrase), "%t", 2);

	PrintHintText(iClient, phrase);
}