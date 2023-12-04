#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>

#include <csgocolors_fix>

#define MAX_ENT	2010	// Limiting entities on the map to avoid error "ED_Alloc: no free edicts" (max: 2048).

static const char
	PL_NAME[]	= "ZProp",
	PL_VER[]	= "1.2.1 (rewritten by Grey83)";

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Spawn props in game. Rewrited by kurumi.",
	author		= "Darkthrone, Greyscale, kurumi",
	url			= "https://forums.alliedmods.net/showthread.php?t=342420"
}

ConVar
	hMax,
	hConnect,
	hSpawn,
	hInfect,
	hKill,
	hRound;
Handle
	kvProps;
int
	offsEyeAngle0,
	g_iCredits[MAXPLAYERS+1] = {-1, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if((offsEyeAngle0 = FindSendPropInfo("CCSPlayer", "m_angEyeAngles[0]")) < 1)
	{
		FormatEx(error, err_max, "Couldn't find offset \"CCSPlayer::m_angEyeAngles[0]\"!");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("zprop.phrases");

	CreateConVar("gs_zprop_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	hMax	= CreateConVar("zprop_credits_max", "15", "Max credits that can be attained (0: No limit).");
	hConnect= CreateConVar("zprop_credits_connect", "4", "The number of free credits a player received when they join the game.");
	hSpawn	= CreateConVar("zprop_credits_spawn", "1", "The number of free credits given on spawn.");
	hInfect	= CreateConVar("zprop_credits_infect", "1", "The number of credits given for infecting a human as zombie.");
	hKill	= CreateConVar("zprop_credits_kill", "5", "The number of credits given for killing a zombie as human.");
	hRound	= CreateConVar("zprop_credits_roundstart", "2", "The number of free credits given on start of the round.");

	AutoExecConfig(true, "zprop");

	HookEvent("player_spawn", PlayerSpawn_Event);
	HookEvent("player_death", PlayerDeath_Event);
	HookEvent("player_team", PlayerTeam_Event);
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);

	RegConsoleCmd("sm_zprops", Zprops_Command, "ZProp command.");
}

public void OnMapStart()
{
	if(kvProps) CloseHandle(kvProps);
	kvProps = CreateKeyValues("zprops");

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/zprops.txt");
	if(!FileToKeyValues(kvProps, path)) SetFailState("\"%s\" missing from server", path);
}

public void OnClientDisconnect(int iClient)
{
	g_iCredits[iClient] = -1;
}

public Action Zprops_Command(int iClient, int args)
{
	if(iClient && IsClientInGame(iClient) && IsPlayerAlive(iClient)) MainMenu(iClient);

	return Plugin_Handled;
}

public void MainMenu(int iClient)
{
	Menu menu_main = CreateMenu(MainMenu_Handle);
	SetMenuTitle(menu_main, "%t\n ", "Menu title", g_iCredits[iClient]);

	KvRewind(kvProps);
	if(KvGotoFirstSubKey(kvProps))
	{
		SetGlobalTransTarget(iClient);
		char propname[PLATFORM_MAX_PATH], display[MAX_MESSAGE_LENGTH];
		do
		{
			KvGetSectionName(kvProps, propname, sizeof(propname));
			int cost = KvGetNum(kvProps, "cost");
			FormatEx(display, sizeof(display), "%t", "Menu option", propname, cost);
			AddMenuItem(menu_main, propname, display, g_iCredits[iClient] >= cost ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		while(KvGotoNextKey(kvProps));
	}

	DisplayMenu(menu_main, iClient, MENU_TIME_FOREVER);
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

					char buffer[PLATFORM_MAX_PATH];
					KvGetString(kvProps, "type", buffer, sizeof(buffer), "prop_physics");
					int prop = CreateEntityByName(buffer);
					if(prop == -1)
					{
						LogError("Can't create entity '%s'!", propname);
						MainMenu(iClient);

						return 0;
					}

					if(prop > MAX_ENT)
					{
						RemoveEdict(prop);
						CPrintToChat(iClient, "Sorry. Unable to create prop \"%s\": too much entities on the map!");

						return 0;
					}

					KvGetString(kvProps, "model", buffer, sizeof(buffer));
					int len = strlen(buffer) - 4;
					if(len < 1 || strcmp(buffer[len], ".mdl", false))
					{
						KvRewind(kvProps);
						KvDeleteKey(kvProps, propname);

						LogError("Entity '%s' has invalid model '%s'!", propname, buffer);
						MainMenu(iClient);

						return 0;
					}

					PrecacheModel(buffer);
					SetEntityModel(prop, buffer);

					float vecOrigin[3], vecAngles[3], vecFinal[3];
					GetClientAbsOrigin(iClient, vecOrigin);
					GetClientAbsAngles(iClient, vecAngles);
					vecAngles[0] = GetEntDataFloat(iClient, offsEyeAngle0);
					vecOrigin[2] += 50;
					AddInFrontOf(vecOrigin, vecAngles, 35, vecFinal);
					TeleportEntity(prop, vecFinal, NULL_VECTOR, NULL_VECTOR);

					if(DispatchSpawn(prop))
					{
						g_iCredits[iClient] -= cost;
						ZProp_HudHint(iClient, "Credits left spend", cost, g_iCredits[iClient]);
						CPrintToChat(iClient, "%t%t", "ZProp", "Spawn prop", propname);
					}
				}
			}
		}
		case MenuAction_End:	delete menu_main;
	}

	return 0;
}

stock void AddInFrontOf(float vecOrigin[3], float vecAngle[3], int units, float output[3])
{
	output[0] =  Cosine(DegToRad(vecAngle[1])) * units + vecOrigin[0];
	output[1] =  Sine(DegToRad(vecAngle[1]))   * units + vecOrigin[1];
	output[2] = -Sine(DegToRad(vecAngle[0]))   * units + vecOrigin[2];
}

public void PlayerSpawn_Event(Event event, const char[] command, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if(!iClient || IsFakeClient(iClient) || GetClientTeam(iClient) < 2)
		return;

	int credits_spawn = GetConVarInt(hSpawn);
	g_iCredits[iClient] += credits_spawn;

	int credits_max = GetConVarInt(hMax);
	if(g_iCredits[iClient] < credits_max)
	{
		ZProp_HudHint(iClient, "Credits left gain", credits_spawn, g_iCredits[iClient]);
		return;
	}

	g_iCredits[iClient] = credits_max;
	ZProp_HudHint(iClient, "Credits left max", credits_spawn, g_iCredits[iClient]);
}

public void PlayerDeath_Event(Event event, const char[] command, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!attacker || attacker == GetClientOfUserId(event.GetInt("userid")) || IsFakeClient(attacker))
		return;

	char weapon[24];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	int credits_earned = !strcmp(weapon, "zombie_claws_of_death") ? GetConVarInt(hInfect) : GetConVarInt(hKill);
	g_iCredits[attacker] += credits_earned;

	int credits_max = GetConVarInt(hMax);
	if(g_iCredits[attacker] < credits_max)
	{
		ZProp_HudHint(attacker, "Credits left gain", credits_earned, g_iCredits[attacker]);
		return;
	}

	g_iCredits[attacker] = credits_max;
	ZProp_HudHint(attacker, "Credits left max", credits_earned, g_iCredits[attacker]);
}

public void PlayerTeam_Event(Event event, const char[] command, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if(iClient && g_iCredits[iClient] == -1)
	{
		g_iCredits[iClient] = GetConVarInt(hConnect);
		CPrintToChat(iClient, "%t", "Join message");
	}
}

public void RoundStart_Event(Event event, const char[] command, bool dontBroadcast)
{
	for(int i = 1, max = GetConVarInt(hMax), round = GetConVarInt(hRound); i < MaxClients; ++i)
		if(IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			if((g_iCredits[i] += round) < max)
			{
				ZProp_HudHint(i, "Credits left gain", round, g_iCredits[i]);
				continue;
			}

			g_iCredits[i] = max;
			ZProp_HudHint(i, "Credits left max", round, g_iCredits[i]);
		}
}

public void ZProp_HudHint(int iClient, any ...)
{
	SetGlobalTransTarget(iClient);

	char phrase[MAX_MESSAGE_LENGTH];
	VFormat(phrase, sizeof(phrase), "%t", 2);

	PrintHintText(iClient, phrase);
}