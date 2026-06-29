/******************************
COMPILE OPTIONS
******************************/

#pragma semicolon 1
#pragma newdecls required

/******************************
NECESSARY INCLUDES
******************************/

#include <sourcemod>
#include <sdktools>

/******************************
PLUGIN DEFINES
******************************/

/*Setting static strings*/
static const char
	/*Plugin Info*/
	PL_NAME[]		 = "Player Sounds",
	PL_AUTHOR[]		 = "Peter Brev",
	PL_DESCRIPTION[] = "Player Sounds",
	PL_VERSION[]	 = "1.0.0";

/******************************
PLUGIN BOOLEANS
******************************/
bool   g_bIsOn[MAXPLAYERS + 1]			= { true, ... };

/******************************
PLUGIN STRINGS
******************************/
char   g_sSounds[36][PLATFORM_MAX_PATH] = {

	  "vo/npc/male01/pain01.wav",
	  "vo/npc/male01/pain02.wav",
	  "vo/npc/male01/pain03.wav",
	  "vo/npc/male01/pain04.wav",
	  "vo/npc/male01/pain05.wav",
	  "vo/npc/male01/pain06.wav",
	  "vo/npc/male01/pain07.wav",
	  "vo/npc/male01/pain08.wav",
	  "vo/npc/male01/pain09.wav",
	  "vo/npc/female01/pain01.wav",
	  "vo/npc/female01/pain02.wav",
	  "vo/npc/female01/pain03.wav",
	  "vo/npc/female01/pain04.wav",
	  "vo/npc/female01/pain05.wav",
	  "vo/npc/female01/pain06.wav",
	  "vo/npc/female01/pain07.wav",
	  "vo/npc/female01/pain08.wav",
	  "vo/npc/female01/pain09.wav",
	  "vo/npc/female01/likethat.wav",
	  "vo/npc/female01/letsgo02.wav",
	  "vo/npc/female01/gotone01.wav",
	  "vo/npc/female01/gotone02.wav",
	  "vo/npc/female01/yeah02.wav",
	  "vo/npc/male01/likethat.wav",
	  "vo/npc/male01/letsgo02.wav",
	  "vo/npc/male01/gotone01.wav",
	  "vo/npc/male01/gotone02.wav",
	  "vo/npc/male01/yeah02.wav",
	  "npc/metropolice/pain2.wav",
	  "npc/metropolice/pain3.wav",
	  "npc/metropolice/pain4.wav",
	  "npc/metropolice/knockout2.wav",
	  "npc/metropolice/vo/chuckle.wav",
	  "npc/combine_soldier/pain1.wav",
	  "npc/combine_soldier/pain2.wav",
	  "npc/combine_soldier/pain3.wav"
};

/******************************
PLUGIN INTEGERS
******************************/
int rdm_male_pain,
	rdm_male_kill,
	rdm_female_pain,
	rdm_female_kill,
	rdm_combine_pain,
	rdm_police,
	g_iLastUsed[MAXPLAYERS + 1],
	cooldown[MAXPLAYERS + 1],
	cooldown_kill[MAXPLAYERS + 1],
	frags[MAXPLAYERS + 1],
	ihealth;

/******************************
PLUGIN INFO
******************************/
public Plugin myinfo =
{
	name		= PL_NAME,
	author		= PL_AUTHOR,
	description = PL_DESCRIPTION,
	version		= PL_VERSION
};

/******************************
INITIATE THE PLUGIN
******************************/
public void OnPluginStart()
{
	/*GAME CHECK*/
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_HL2DM)
	{
		SetFailState("[HL2MP] This plugin is intended for Half-Life 2: Deathmatch only.");
	}

	/*Hook Events*/
	HookEvent("player_hurt", player_hurt, EventHookMode_Pre);
	HookEvent("player_death", player_death, EventHookMode_Pre);
}

/******************************
PLUGIN FUNCTIONS
******************************/
public void OnMapStart()
{
	for (int i = 0; i < 36; i++)
	{
		PrepareSound(g_sSounds[i]);
	}
}

public void OnMapEnd()
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (i < 1 || i > MaxClients || !IsClientInGame(i) || IsFakeClient(i)) return;

		frags[i] = 0;
	}
}

public void OnClientPutInServer(int client)
{
	frags[client] = 0;
}

public Action player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client)) return Plugin_Continue;

	if (!g_bIsOn[client]) return Plugin_Continue;

	cooldown[client] = GetRandomInt(2, 5);

	if (!client || !IsClientInGame(client) || IsFakeClient(client)) return Plugin_Continue;

	char model[512];
	GetClientModel(client, model, sizeof(model));
	ihealth = GetClientHealth(client);

	if (ihealth < 1) return Plugin_Continue;

	if (StrContains(model, "models/humans/group03/female", false) != -1)
	{
		int iNow = GetTime(), iCooldown = cooldown[client];

		if (iCooldown > 0)
		{
			int iTimeLeft = g_iLastUsed[client] + iCooldown - iNow;
			if (iTimeLeft > 0)
			{
				return Plugin_Continue;
			}
		}

		g_iLastUsed[client] = iNow;

		rdm_female_pain		= GetRandomInt(9, 17);
		EmitSoundToClient(client, g_sSounds[rdm_female_pain]);
	}

	else if (StrContains(model, "models/humans/group03/male", false) != -1)
	{
		int iNow = GetTime(), iCooldown = cooldown[client];

		if (iCooldown > 0)
		{
			int iTimeLeft = g_iLastUsed[client] + iCooldown - iNow;
			if (iTimeLeft > 0)
			{
				return Plugin_Continue;
			}
		}

		g_iLastUsed[client] = iNow;

		rdm_male_pain		= GetRandomInt(0, 8);
		EmitSoundToClient(client, g_sSounds[rdm_male_pain], _, _, _, _, 0.5);
	}

	else if (StrContains(model, "models/police", false) != -1)
	{
		int iNow = GetTime(), iCooldown = cooldown[client];

		if (iCooldown > 0)
		{
			int iTimeLeft = g_iLastUsed[client] + iCooldown - iNow;
			if (iTimeLeft > 0)
			{
				return Plugin_Continue;
			}
		}

		g_iLastUsed[client] = iNow;

		rdm_police			= GetRandomInt(33, 35);
		EmitSoundToClient(client, g_sSounds[rdm_police], _, _, _, _, 0.5);
	}

	else if (StrContains(model, "models/combine", false) != -1)
	{
		int iNow = GetTime(), iCooldown = cooldown[client];

		if (iCooldown > 0)
		{
			int iTimeLeft = g_iLastUsed[client] + iCooldown - iNow;
			if (iTimeLeft > 0)
			{
				return Plugin_Continue;
			}
		}

		g_iLastUsed[client] = iNow;

		rdm_combine_pain	= GetRandomInt(28, 31);
		EmitSoundToClient(client, g_sSounds[rdm_combine_pain], _, _, _, _, 0.5);
	}

	return Plugin_Continue;
}

public Action player_death(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!attacker || !IsClientInGame(attacker) /*|| IsFakeClient(attacker)*/) return Plugin_Continue;

	cooldown_kill[attacker] = GetRandomInt(5, 25);
	char model[512];
	GetClientModel(attacker, model, sizeof(model));
	ihealth = GetClientHealth(attacker);

	if (ihealth < 1)
	{
		return Plugin_Continue;
	}

	frags[attacker]++;
	if (frags[attacker] > 1)
	{
		frags[attacker] = 0;
		return Plugin_Continue;
	}

	if (StrContains(model, "models/humans/group03/female", false) != -1)
	{
		int iNow = GetTime(), iCooldown = cooldown_kill[attacker];

		if (iCooldown > 0)
		{
			int iTimeLeft = g_iLastUsed[attacker] + iCooldown - iNow;
			if (iTimeLeft > 0)
			{
				return Plugin_Continue;
			}
		}

		g_iLastUsed[attacker] = iNow;

		rdm_female_kill = GetRandomInt(18, 22);
		EmitSoundToClient(attacker, g_sSounds[rdm_female_kill], _, _, _, _, 0.5);
	}

	if (StrContains(model, "models/humans/group03/male", false) != -1)
	{
		int iNow = GetTime(), iCooldown = cooldown_kill[attacker];

		if (iCooldown > 0)
		{
			int iTimeLeft = g_iLastUsed[attacker] + iCooldown - iNow;
			if (iTimeLeft > 0)
			{
				return Plugin_Continue;
			}
		}

		g_iLastUsed[attacker] = iNow;

		rdm_male_kill = GetRandomInt(23, 27);
		EmitSoundToClient(attacker, g_sSounds[rdm_male_kill], _, _, _, _, 0.5);
	}

	if (StrContains(model, "models/police", false) != -1)
	{
		int iNow = GetTime(), iCooldown = cooldown_kill[attacker];

		if (iCooldown > 0)
		{
			int iTimeLeft = g_iLastUsed[attacker] + iCooldown - iNow;
			if (iTimeLeft > 0)
			{
				return Plugin_Continue;
			}
		}

		g_iLastUsed[attacker] = iNow;

		EmitSoundToClient(attacker, g_sSounds[32], _, _, _, _, 0.5);
	}

	if (StrContains(model, "models/combine", false) != -1)
	{
		int iNow = GetTime(), iCooldown = cooldown_kill[attacker];

		if (iCooldown > 0)
		{
			int iTimeLeft = g_iLastUsed[attacker] + iCooldown - iNow;
			if (iTimeLeft > 0)
			{
				return Plugin_Continue;
			}
		}

		g_iLastUsed[attacker] = iNow;

		EmitSoundToClient(attacker, g_sSounds[32], _, _, _, _, 0.5);
	}

	return Plugin_Continue;
}

void PrepareSound(const char[] sName)
{
	char sPath[PLATFORM_MAX_PATH];

	Format(sPath, sizeof(sPath), "sound/%s", sName);
	PrecacheSound(sName);
	AddFileToDownloadsTable(sPath);
}