#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <mapchooser>

#pragma newdecls required
#pragma semicolon 1

#define PL_VERSION "1.1.1"

public Plugin myinfo =
{
	name        = "HLSW Info",
	author      = "Tsunami",
	description = "Shows next map and time left in HLSW.",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

bool g_bMapChooser;
ConVar g_hNextMap;
ConVar g_hTimeLeft;

public void OnPluginStart()
{
	CreateConVar("sm_hlswinfo_version", PL_VERSION, "Shows next map and time left in HLSW.", FCVAR_NOTIFY);
	g_hNextMap    = CreateConVar("cm_nextmap",  "", "Next map in HLSW",  FCVAR_NOTIFY);
	g_hTimeLeft   = CreateConVar("cm_timeleft", "", "Time left in HLSW", FCVAR_NOTIFY);
	g_bMapChooser = LibraryExists("mapchooser");

	CreateTimer(15.0, Timer_Update, _, TIMER_REPEAT);
	LoadTranslations("basetriggers.phrases");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "mapchooser"))
		g_bMapChooser = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "mapchooser"))
		g_bMapChooser = false;
}

public Action Timer_Update(Handle timer)
{
	char sNextMap[64], sTimeLeft[8];
	int iMins, iSecs, iTimeLeft;

	// Format next map
	if (g_bMapChooser && EndOfMapVoteEnabled() && !HasEndOfMapVoteFinished())
		Format(sNextMap, sizeof(sNextMap), "%t", "Pending Vote");
	else
		GetNextMap(sNextMap, sizeof(sNextMap));

	// Format time left
	if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0)
	{
		iMins = iTimeLeft / 60;
		if (iTimeLeft % 60 > 30)
		{
			iMins += 1;
			iSecs  = 0;
		}
		else
			iSecs  = 30;
	}

	// Set next map
	g_hNextMap.Flags  = FCVAR_NONE;
	g_hNextMap.SetString(sNextMap);
	g_hNextMap.Flags  = FCVAR_NOTIFY;

	// Set time left
	Format(sTimeLeft, sizeof(sTimeLeft), "%d:%02d", iMins, iSecs);
	g_hTimeLeft.Flags = FCVAR_NONE;
	g_hTimeLeft.SetString(sTimeLeft);
	g_hTimeLeft.Flags = FCVAR_NOTIFY;
}
