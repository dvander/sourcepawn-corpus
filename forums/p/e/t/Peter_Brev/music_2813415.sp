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
	PL_NAME[]							= "Map End Music",
	PL_AUTHOR[]							= "Peter Brev",
	PL_DESCRIPTION[]					= "Music at the end of the map",
	PL_VERSION[]						= "1.0.0";

/******************************
PLUGIN STRINGS
******************************/
char g_sMusicPath[6][PLATFORM_MAX_PATH] = {
	"music/hl2_song3.mp3",
	"music/hl2_song31.mp3",
	"music/hl1_song11.mp3",
	"music/hl1_song17.mp3",
	"music/hl1_song10.mp3",
	"music/hl2_song14.mp3"
};

/******************************
PLUGIN HANDLES
******************************/
Handle g_hMusic = null;

/******************************
PLUGIN BOOLEANS
******************************/
// bool once;

/******************************
PLUGIN INTEGERS
******************************/
int	   rdm,
	timeleft;

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

	// once = false;
}

public void OnMapStart()
{
	for (int i = 0; i < 6; i++)
	{
		PrepareSound(g_sMusicPath[i]);
	}
	rdm = GetRandomInt(0, 5);
}

public void OnMapEnd()
{
	// once = false;
	delete g_hMusic;
}

public void OnMapTimeLeftChanged()
{
	GetMapTimeLeft(timeleft);

	if (g_hMusic)
	{
		delete g_hMusic;
	}

	g_hMusic = CreateTimer(1.0, t_mapend, _, TIMER_REPEAT);
}

/*public void OnClientPutInServer(int client)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))return;
		if (!once)
		{
			CheckTimeleft();
			once = true;
		}
	}
}

void CheckTimeleft()
{
	int timeleft;
	GetMapTimeLeft(timeleft);
	g_hMusic = CreateTimer(float(timeleft) + 0.0, t_mapend);
}*/
public Action t_mapend(Handle timer, any data)
{
	timeleft--;
	if (timeleft <= 0)
	{
		char nextmap[128];
		GetNextMap(nextmap, sizeof(nextmap));
		EmitSoundToAll(g_sMusicPath[rdm], _, _, _, _, 0.5);
		PrintToChatAll("[SM] Next Map: %s", nextmap);
		g_hMusic = null;
		return Plugin_Stop;
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