#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_NAME     "Toggle Weapon Sounds clientprefs"
#define PLUGIN_VERSION     "1.0.3 fix m_iWeaponID + new syntax"

bool g_bStopSound[MAXPLAYERS+1] = { true };
bool g_bHooked;

Handle g_hClientCookie = INVALID_HANDLE;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony",
	description = "Allows clients to stop hearing weapon sounds",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	g_hClientCookie = RegClientCookie("sm_stopsound", "Toggle hearing weapon sounds", CookieAccess_Private);

	// Detect game and hook appropriate tempent.
	char sGame[32];
	GetGameFolderName(sGame, sizeof(sGame));

	if (StrEqual(sGame, "cstrike") || StrEqual(sGame, "csgo"))
		AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
	else if (StrEqual(sGame, "dod"))
		AddTempEntHook("FireBullets", DODS_Hook_FireBullets);

	// TF2/HL2:DM and misc weapon sounds will be caught here.
	AddNormalSoundHook(Hook_NormalSound);

	CreateConVar("sm_stopsound_version", PLUGIN_VERSION, "Toggle Weapon Sounds", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("sm_stopsound", Command_StopSound, "Toggle hearing weapon sounds");

	for (int i = 1; i <= MaxClients; ++i)
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
	GetClientCookie(client, g_hClientCookie, sValue, sizeof(sValue));

	g_bStopSound[client] = !(sValue[0] != '\0' && StringToInt(sValue));
	CheckHooks();
}

public Action Command_StopSound(int client, int args)
{
	if(AreClientCookiesCached(client))
	{
		g_bStopSound[client] = !g_bStopSound[client];
		SetClientCookie(client, g_hClientCookie, g_bStopSound[client] ? "0" : "1");
		PrintToChat(client, "[\x0BWeapons\x01] \x06Sound from other players guns is now \x07%s", g_bStopSound[client] ? "Off" : "On");
		CheckHooks();
	}
	else
	{
		ReplyToCommand(client, "[SM] Your Cookies are not yet cached. Please try again later...");
	}

	return Plugin_Handled;
}

public void OnClientDisconnect_Post(int client)
{
	g_bStopSound[client] = true;
	CheckHooks();
}

void CheckHooks()
{
	bool bShouldHook = false;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bStopSound[i])
		{
			bShouldHook = true;
			break;
		}
	}

	// Fake (un)hook because toggling actual hooks will cause server instability.
	g_bHooked = bShouldHook;
}

public Action Hook_NormalSound(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	// Ignore non-weapon sounds.
	if (!g_bHooked || !(strncmp(sample, "weapons", 7) == 0 || strncmp(sample[1], "weapons", 7) == 0))
		return Plugin_Continue;

	int i, j;

	for (i = 0; i < numClients; i++)
	{
		if (g_bStopSound[clients[i]])
		{
			// Remove the client from the array.
			for (j = i; j < numClients-1; j++)
			{
				clients[j] = clients[j+1];
			}

			numClients--;
			i--;
		}
	}

	return (numClients > 0) ? Plugin_Changed : Plugin_Stop;
}

public Action CSS_Hook_ShotgunShot(const char[] te_name, const int[] Players, int numClients, float delay)
{
	if (!g_bHooked)
		return Plugin_Continue;

	// Check which clients need to be excluded.
	int[] newClients = new int[MaxClients];
	int client;
	int newTotal = 0;

	for (int i = 0; i < numClients; i++)
	{
		client = Players[i];

		if (!g_bStopSound[client])
		{
			newClients[newTotal++] = client;
		}
	}

	// No clients were excluded.
	if (newTotal == numClients)
		return Plugin_Continue;

	// All clients were excluded and there is no need to broadcast.
	else if (newTotal == 0)
		return Plugin_Stop;

	// Re-broadcast to clients that still need it.
	float vTemp[3];
	TE_Start("Shotgun Shot");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_weapon", TE_ReadNum("m_weapon"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
	TE_Send(newClients, newTotal, delay);

	return Plugin_Stop;
}

public Action DODS_Hook_FireBullets(const char[] te_name, const int[] Players, int numClients, float delay)
{
	if (!g_bHooked)
		return Plugin_Continue;

	// Check which clients need to be excluded.
	int[] newClients = new int[MaxClients];
	int client;
	int newTotal = 0;

	for (int i = 0; i < numClients; i++)
	{
		client = Players[i];

		if (!g_bStopSound[client])
		{
			newClients[newTotal++] = client;
		}
	}

	// No clients were excluded.
	if (newTotal == numClients)
		return Plugin_Continue;

	// All clients were excluded and there is no need to broadcast.
	else if (newTotal == 0)
		return Plugin_Stop;

	// Re-broadcast to clients that still need it.
	float vTemp[3];
	TE_Start("FireBullets");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_weapon", TE_ReadNum("m_weapon"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_flSpread", TE_ReadFloat("m_flSpread"));
	TE_Send(newClients, newTotal, delay);

	return Plugin_Stop;
}