#pragma semicolon 1

#include <sourcemod>
#include <advertisements>
#include <morecolors>

#define PLUGIN_NAME "Modular Advertisements"
#define PLUGIN_VERSION "1.0"
#define CVAR_DISABLED "OFF"
#define CVAR_ENABLED "ON"
#define MAX_ADVERTS 255

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "ReFlex",
	description = "Display advertisements in your server",
	version = PLUGIN_VERSION,
	url = "http://www.intoxgaming.com/"
}

new g_iFrames;
new g_iTickrate;
new g_iAdvert;
new g_iAdvertCount;
new bool:g_bTickrate = true;
new Float:g_flTime;
new String:g_strType[MAX_ADVERTS][255];
new String:g_strText[MAX_ADVERTS][255];
new String:g_strFlags[MAX_ADVERTS][255];
new Handle:g_hEnabled;
new Handle:g_hFile;
new Handle:g_hInterval;
new Handle:g_hTimer;
new Handle:g_hForwardConfigLoaded;

static g_iTColors[13][3] = 
{
	{255, 255, 255},
	{255, 0, 0},
	{0, 255, 0},
	{0, 0, 255},
	{255, 255, 0},
	{255, 0, 255},
	{0, 255, 255},
	{255, 128, 0},
	{255, 0, 128},
	{128, 255, 0},
	{0, 255, 128},
	{128, 0, 255},
	{0, 128, 255}
};

static String:g_sTColors[13][12] =
{
	"{WHITE}",
	"{RED}",
	"{GREEN}",
	"{BLUE}",
	"{YELLOW}",
	"{PURPLE}",
	"{CYAN}",
	"{ORANGE}",
	"{PINK}",
	"{OLIVE}",
	"{LIME}",
	"{VIOLET}",
	"{LIGHTBLUE}"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("RegisterAdvertisement", Native_RegisterAdvertisement);
	RegPluginLibrary("advertisements");
	return APLRes_Success;
}

// ====[ NATIVES ]=============================================================
public Native_RegisterAdvertisement(Handle:hPlugin, iParams)
{
	GetNativeString(1, g_strType[g_iAdvertCount], sizeof(g_strType[]));
	GetNativeString(2, g_strText[g_iAdvertCount], sizeof(g_strText[]));
	GetNativeString(3, g_strFlags[g_iAdvertCount], sizeof(g_strFlags[]));
	if(!g_strFlags[g_iAdvertCount][0])
		strcopy(g_strFlags[g_iAdvertCount], sizeof(g_strFlags[]), "none");

	g_iAdvertCount++;
	return true;
}

public OnPluginStart()
{
	CreateConVar("sm_advertisements_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_advertisements_enabled", "1", PLUGIN_NAME);
	g_hFile = CreateConVar("sm_advertisements_file", "advertisements.txt", "File to read the advertisements from.");
	g_hInterval = CreateConVar("sm_advertisements_interval", "30", "Amount of seconds between advertisements.");
	AutoExecConfig(true, "advertisements");
	
	HookConVarChange(g_hInterval, ConVarChange_Interval);
	RegServerCmd("sm_advertisements_reload", Command_ReloadAds, "Reload the advertisements");
	g_hForwardConfigLoaded = CreateGlobalForward("OnAdvertisementsLoaded", ET_Ignore);
}

public OnMapStart()
{
	LoadConfig();
	g_hTimer = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnGameFrame()
{
	if(g_bTickrate)
	{
		g_iFrames++;
		
		new Float:flTime = GetEngineTime();
		if(flTime >= g_flTime)
		{
			if(g_iFrames == g_iTickrate)
			{
				g_bTickrate = false;
			}
			else
			{
				g_iTickrate = g_iFrames;
				g_iFrames   = 0;    
				g_flTime    = flTime + 1.0;
			}
		}
	}
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(g_hTimer)
		KillTimer(g_hTimer);
	
	g_hTimer = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

public Action:Command_ReloadAds(iArgs)
{
	LoadConfig();
	return Plugin_Handled;
}

public Action:Timer_DisplayAds(Handle:timer)
{
	if(!GetConVarBool(g_hEnabled))
		return;

	g_iAdvert++;
	if(g_iAdvert >= g_iAdvertCount)
		g_iAdvert = 0;
	
	decl AdminFlag:fFlagList[16];
	decl String:strBuffer[256];
	new bool:bAdmins = StrEqual(g_strFlags[g_iAdvert], ""), bool:bFlags = !StrEqual(g_strFlags[g_iAdvert], "none");
	if(bFlags)
		FlagBitsToArray(ReadFlagString(g_strFlags[g_iAdvert]), fFlagList, sizeof(fFlagList));
	
	if(StrContains(g_strText[g_iAdvert], "{CURRENTMAP}") != -1)
	{
		GetCurrentMap(strBuffer, sizeof(strBuffer));
		ReplaceString(g_strText[g_iAdvert], sizeof(g_strText[]), "{CURRENTMAP}", strBuffer);
	}
	
	if(StrContains(g_strText[g_iAdvert], "{DATE}") != -1)
	{
		FormatTime(strBuffer, sizeof(strBuffer), "%m/%d/%Y");
		ReplaceString(g_strText[g_iAdvert], sizeof(g_strText[]), "{DATE}", strBuffer);
	}
	
	if(StrContains(g_strText[g_iAdvert], "{TICKRATE}") != -1)
	{
		IntToString(g_iTickrate, strBuffer, sizeof(strBuffer));
		ReplaceString(g_strText[g_iAdvert], sizeof(g_strText[]), "{TICKRATE}", strBuffer);
	}
	
	if(StrContains(g_strText[g_iAdvert], "{TIME}")       != -1)
	{
		FormatTime(strBuffer, sizeof(strBuffer), "%I:%M:%S%p");
		ReplaceString(g_strText[g_iAdvert], sizeof(g_strText[]), "{TIME}", strBuffer);
	}
	
	if(StrContains(g_strText[g_iAdvert], "{TIME24}") != -1)
	{
		FormatTime(strBuffer, sizeof(strBuffer), "%H:%M:%S");
		ReplaceString(g_strText[g_iAdvert], sizeof(g_strText[]), "{TIME24}", strBuffer);
	}
	
	if(StrContains(g_strText[g_iAdvert], "{TIMELEFT}") != -1)
	{
		new iMins, iSecs, iTimeLeft;
		
		if(GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0)
		{
			iMins = iTimeLeft / 60;
			iSecs = iTimeLeft % 60;
		}
		
		Format(strBuffer, sizeof(strBuffer), "%d:%02d", iMins, iSecs);
		ReplaceString(g_strText[g_iAdvert], sizeof(g_strText[]), "{TIMELEFT}",   strBuffer);
	}
	
	if(StrContains(g_strText[g_iAdvert], "\\n") != -1)
	{
		Format(strBuffer, sizeof(strBuffer), "%c", 13);
		ReplaceString(g_strText[g_iAdvert], sizeof(g_strText[]), "\\n", strBuffer);
	}
	
	decl Handle:hConVar, String:sConVar[64], String:sName[64];
	new iStart = StrContains(g_strText[g_iAdvert], "{BOOL:");
	while(iStart != -1)
	{
		new iEnd = StrContains(g_strText[g_iAdvert][iStart + 6], "}");
		if(iEnd != -1)
		{
			strcopy(sConVar, iEnd + 1, g_strText[g_iAdvert][iStart + 6]);
			Format(sName, sizeof(sName), "{BOOL:%s}", sConVar);
			
			if((hConVar = FindConVar(sConVar)))
				ReplaceString(g_strText[g_iAdvert], sizeof(g_strText[]), sName, GetConVarBool(hConVar) ? CVAR_ENABLED : CVAR_DISABLED);
		}
		
		new iStart2 = StrContains(g_strText[g_iAdvert][iStart + 1], "{BOOL:") + iStart + 1;
		if(iStart == iStart2)
			break;
		
		iStart = iStart2;
	}
	
	iStart = StrContains(g_strText[g_iAdvert], "{");
	while(iStart != -1)
	{
		new iEnd = StrContains(g_strText[g_iAdvert][iStart + 1], "}");
		if(iEnd != -1)
		{
			strcopy(sConVar, iEnd + 1, g_strText[g_iAdvert][iStart + 1]);
			Format(sName, sizeof(sName), "{%s}", sConVar);
			
			if((hConVar = FindConVar(sConVar)))
			{
				GetConVarString(hConVar, strBuffer, sizeof(strBuffer));
				ReplaceString(g_strText[g_iAdvert], sizeof(g_strText[]), sName, strBuffer);
			}
		}
		
		new iStart2 = StrContains(g_strText[g_iAdvert][iStart + 1], "{") + iStart + 1;
		if(iStart == iStart2)
			break;

		iStart = iStart2;
	}
	
	if(StrContains(g_strType[g_iAdvert], "C") != -1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
			    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				PrintCenterText(i, g_strText[g_iAdvert]);
		}
	}
	if(StrContains(g_strType[g_iAdvert], "H") != -1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
			    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				PrintHintText(i, g_strText[g_iAdvert]);
		}
	}
	if(StrContains(g_strType[g_iAdvert], "M") != -1)
	{
		new Handle:hPl = CreatePanel();
		DrawPanelText(hPl, g_strText[g_iAdvert]);
		SetPanelCurrentKey(hPl, 10);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
			    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC | ADMFLAG_ROOT))))
				SendPanelToClient(hPl, i, Handler_DoNothing, 10);
		}
		
		CloseHandle(hPl);
	}
	if(StrContains(g_strType[g_iAdvert], "S") != -1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
				bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				CPrintToChat(i, g_strText[g_iAdvert]);
		}
	}
	if(StrContains(g_strType[g_iAdvert], "T") != -1)
	{
		decl String:sColor[16];
		new iColor = -1, iPos = BreakString(g_strText[g_iAdvert], sColor, sizeof(sColor));
		
		for(new i = 0; i < sizeof(g_sTColors); i++)
		{
			if(StrEqual(sColor, g_sTColors[i]))
				iColor = i;
		}
		
		if(iColor == -1)
		{
			iPos = 0;
			iColor = 0;
		}
		
		new Handle:hKv = CreateKeyValues("Stuff", "title", g_strText[g_iAdvert][iPos]);
		KvSetColor(hKv, "color", g_iTColors[iColor][0], g_iTColors[iColor][1], g_iTColors[iColor][2], 255);
		KvSetNum(hKv, "level", 1);
		KvSetNum(hKv, "time",  10);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
			    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				CreateDialog(i, hKv, DialogType_Msg);
		}
		
		CloseHandle(hKv);
	}
}

public LoadConfig()
{
	g_iAdvert = 0;
	g_iAdvertCount = 0;
	
	decl String:strFile[256];
	decl String:strPath[256];
	GetConVarString(g_hFile, strFile, sizeof(strFile));
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/%s", strFile);
	if(!FileExists(strPath))
	{
		SetFailState("File Not Found: %s", strPath);
		return;
	}

	for(new i = 0; i < MAX_ADVERTS; i++)
	{
		strcopy(g_strType[i], sizeof(g_strType[]), "");
		strcopy(g_strText[i], sizeof(g_strText[]), "");
		strcopy(g_strFlags[i], sizeof(g_strFlags[]), "");
	}
	
	new Handle:hKeyValues = CreateKeyValues("Advertisements");
	FileToKeyValues(hKeyValues, strPath);
	KvGotoFirstSubKey(hKeyValues);

	do
	{
		KvGetString(hKeyValues, "type", g_strType[g_iAdvertCount], sizeof(g_strType[]));
		KvGetString(hKeyValues, "text", g_strText[g_iAdvertCount], sizeof(g_strText[]));
		KvGetString(hKeyValues, "flags", g_strFlags[g_iAdvertCount], sizeof(g_strFlags[]), "none");
		g_iAdvertCount++;
	}
	while(KvGotoNextKey(hKeyValues, false));
	CloseHandle(hKeyValues);

	Call_StartForward(g_hForwardConfigLoaded);
	Call_Finish();
}

stock bool:HasFlag(iClient, AdminFlag:iFlagList[16])
{
	new iFlags = GetUserFlagBits(iClient);
	if(iFlags & ADMFLAG_ROOT)
		return true;
	
	for(new i = 0; i < sizeof(iFlagList); i++)
	{
		if(iFlags & FlagToBit(iFlagList[i]))
			return true;
	}
	
	return false;
}