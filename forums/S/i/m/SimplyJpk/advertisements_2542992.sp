#pragma semicolon 1

#include <sourcemod>
#include <morecolors>

#define MAXADS 32
#define MAXAD_LENGTH 256

new String:s_Type[MAXADS][6];
new String:s_Text[MAXADS][MAXAD_LENGTH];
new String:s_Flags[MAXADS][16];
new AdCount = 0;

#define PL_VERSION    "0.8.0"
#define CVAR_DISABLED "OFF"
#define CVAR_ENABLED  "ON"

public Plugin:myinfo =
{
	name        = "Advertisements",
	author      = "Tsunami, Edit By SimplyJpk",
	description = "Display advertisements",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

// Allows Advertisements to be called using '!advertisment #'
// Makes advertisements random, and no longer linear, constantly opening and closing files when needed. (CPU Waste)

new Handle:g_hCenterAd[MAXPLAYERS + 1];
new Handle:g_hEnabled;
new Handle:g_hFile;
new Handle:g_hInterval;
new Handle:g_hTimer;

static g_iTColors[13][3]         = {{255, 255, 255}, {255, 0, 0},    {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {255, 128, 0}, {255, 0, 128}, {128, 255, 0}, {0, 255, 128}, {128, 0, 255}, {0, 128, 255}};
static String:g_sTColors[13][12] = {"{WHITE}",       "{RED}",        "{GREEN}",   "{BLUE}",    "{YELLOW}",    "{PURPLE}",    "{CYAN}",      "{ORANGE}",    "{PINK}",      "{OLIVE}",     "{LIME}",      "{VIOLET}",    "{LIGHTBLUE}"};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetUserMessageType");
	
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_advertisements_version", PL_VERSION, "Display advertisements", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled        = CreateConVar("sm_advertisements_enabled",  "1",                  "Enable/disable displaying advertisements.");
	g_hFile           = CreateConVar("sm_advertisements_file",     "advertisements.txt", "File to read the advertisements from.");
	g_hInterval       = CreateConVar("sm_advertisements_interval", "30",                 "Amount of seconds between advertisements.");
	AutoExecConfig(true, "advertisements");
	
	HookConVarChange(g_hInterval, ConVarChange_Interval);
	RegAdminCmd("sm_advertisements_reload", Command_ReloadAds, ADMFLAG_GENERIC, "Reload the advertisements");
	
	//Jpk Added
	RegAdminCmd("sm_advertise",	cmd_Advertise,	ADMFLAG_GENERIC,	"Display an advertisement.");
	ParseAds();
}

public OnMapStart()
{
	g_hTimer          = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(g_hTimer)
		KillTimer(g_hTimer);
	
	g_hTimer          = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

public Action:cmd_Advertise(client, args)
{
	if (args == 0)
	{
		AdvertisePlz(-1);
	}
	else
	{
		decl String:Arg[3];
		GetCmdArg(1, Arg, sizeof(Arg));
		new ArgVal = StringToInt(Arg, 10);
		AdvertisePlz(ArgVal);
	}
	return Plugin_Handled;
}

public Action:Command_ReloadAds(client, args)
{
	ParseAds();
	return Plugin_Handled;
}

public Action:Timer_DisplayAds(Handle:timer)
{
	if(!GetConVarBool(g_hEnabled))
		return;
		
	AdvertisePlz(-1);
}

AdvertisePlz(ADSET)
{
	decl AdminFlag:fFlagList[16], String:sBuffer[256], String:sFlags[16], String:sText[256], String:sType[6];
	new CurrentAd = GetRandomInt(0, AdCount - 1);
	if (ADSET >= 0 && ADSET < AdCount)
		CurrentAd = ADSET;
	sFlags = s_Flags[CurrentAd];
	sText = s_Text[CurrentAd];
	sType = s_Type[CurrentAd];
	
	new bool:bAdmins = StrEqual(sFlags, ""), bool:bFlags = !StrEqual(sFlags, "none");
	if(bFlags)
		FlagBitsToArray(ReadFlagString(sFlags), fFlagList, sizeof(fFlagList));
	
	if(StrContains(sText, "{CURRENTMAP}") != -1)
	{
		GetCurrentMap(sBuffer, sizeof(sBuffer));
		ReplaceString(sText, sizeof(sText), "{CURRENTMAP}", sBuffer);
	}
	
	if(StrContains(sText, "{DATE}")       != -1)
	{
		FormatTime(sBuffer, sizeof(sBuffer), "%m/%d/%Y");
		ReplaceString(sText, sizeof(sText), "{DATE}",       sBuffer);
	}
	
	if(StrContains(sText, "{TIME}")       != -1)
	{
		FormatTime(sBuffer, sizeof(sBuffer), "%I:%M:%S%p");
		ReplaceString(sText, sizeof(sText), "{TIME}",       sBuffer);
	}
	
	if(StrContains(sText, "{TIME24}")     != -1)
	{
		FormatTime(sBuffer, sizeof(sBuffer), "%H:%M:%S");
		ReplaceString(sText, sizeof(sText), "{TIME24}",     sBuffer);
	}
	
	if(StrContains(sText, "{TIMELEFT}")   != -1)
	{
		new iMins, iSecs, iTimeLeft;
		
		if(GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0)
		{
			iMins = iTimeLeft / 60;
			iSecs = iTimeLeft % 60;
		}
		
		Format(sBuffer, sizeof(sBuffer), "%d:%02d", iMins, iSecs);
		ReplaceString(sText, sizeof(sText), "{TIMELEFT}",   sBuffer);
	}
	
	if(StrContains(sText, "\\n")          != -1)
	{
		Format(sBuffer, sizeof(sBuffer), "%c", 13);
		ReplaceString(sText, sizeof(sText), "\\n",          sBuffer);
	}
	
	decl Handle:hConVar, String:sConVar[64], String:sName[64];
	new iStart = StrContains(sText, "{BOOL:");
	while(iStart != -1)
	{
		new iEnd = StrContains(sText[iStart + 6], "}");
		if(iEnd != -1)
		{
			strcopy(sConVar, iEnd + 1, sText[iStart + 6]);
			Format(sName, sizeof(sName), "{BOOL:%s}", sConVar);
			
			if((hConVar = FindConVar(sConVar)))
				ReplaceString(sText, sizeof(sText), sName, GetConVarBool(hConVar) ? CVAR_ENABLED : CVAR_DISABLED);
		}
		
		new iStart2 = StrContains(sText[iStart + 1], "{BOOL:") + iStart + 1;
		if(iStart == iStart2)
			break;
		
		iStart = iStart2;
	}
	
	iStart = StrContains(sText, "{");
	while(iStart != -1)
	{
		new iEnd = StrContains(sText[iStart + 1], "}");
		if(iEnd != -1)
		{
			strcopy(sConVar, iEnd + 1, sText[iStart + 1]);
			Format(sName, sizeof(sName), "{%s}", sConVar);
			
			if((hConVar = FindConVar(sConVar)))
			{
				GetConVarString(hConVar, sBuffer, sizeof(sBuffer));
				ReplaceString(sText, sizeof(sText), sName, sBuffer);
			}
		}
		
		new iStart2 = StrContains(sText[iStart + 1], "{") + iStart + 1;
		if (iStart == iStart2) {
			break;
		} else {
			iStart = iStart2;
		}
	}
	
	if(StrContains(sType, "C") != -1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
			    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
			{
				PrintCenterText(i, sText);
				
				new Handle:hCenterAd;
				g_hCenterAd[i] = CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				WritePackCell(hCenterAd,   i);
				WritePackString(hCenterAd, sText);
			}
		}
	}
	if(StrContains(sType, "H") != -1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
			    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				PrintHintText(i, sText);
		}
	}
	if(StrContains(sType, "M") != -1)
	{
		new Handle:hPl = CreatePanel();
		DrawPanelText(hPl, sText);
		SetPanelCurrentKey(hPl, 10);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
			    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				SendPanelToClient(hPl, i, Handler_DoNothing, 10);
		}
		
		CloseHandle(hPl);
	}
	if(StrContains(sType, "S") != -1)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
				bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				CPrintToChat(i, sText);
		}
	}
	if(StrContains(sType, "T") != -1)
	{
		decl String:sColor[16];
		new iColor = -1, iPos = BreakString(sText, sColor, sizeof(sColor));
		
		for(new i = 0; i < sizeof(g_sTColors); i++)
		{
			if(StrEqual(sColor, g_sTColors[i]))
				iColor = i;
		}
		
		if(iColor == -1)
		{
			iPos     = 0;
			iColor   = 0;
		}
		
		new Handle:hKv = CreateKeyValues("Stuff", "title", sText[iPos]);
		KvSetColor(hKv, "color", g_iTColors[iColor][0], g_iTColors[iColor][1], g_iTColors[iColor][2], 255);
		KvSetNum(hKv,   "level", 1);
		KvSetNum(hKv,   "time",  10);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
			    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				CreateDialog(i, hKv, DialogType_Msg);
		}
		
		CloseHandle(hKv);
	}
	return;
}

public Action:Timer_CenterAd(Handle:timer, Handle:pack)
{
	decl String:sText[256];
	static iCount          = 0;
	
	ResetPack(pack);
	new iClient            = ReadPackCell(pack);
	ReadPackString(pack, sText, sizeof(sText));
	
	if(IsClientInGame(iClient) && ++iCount < 5)
	{
		PrintCenterText(iClient, sText);
		
		return Plugin_Continue;
	}
	else
	{
		iCount               = 0;
		g_hCenterAd[iClient] = INVALID_HANDLE;
		
		return Plugin_Stop;
	}
}

ParseAds()
{
	new Handle:kv;
	kv = CreateKeyValues("Advertisements");
	decl String:sFile[256], String:sPath[256];
	GetConVarString(g_hFile, sFile, sizeof(sFile));
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	if(!FileExists(sPath))
		SetFailState("File Not Found: %s", sPath);
	AdCount = 0;
	FileToKeyValues(kv, sPath);
	KvGotoFirstSubKey(kv);
	do {
			KvGetString(kv, "type",  s_Type[AdCount],  6);
			KvGetString(kv, "text",  s_Text[AdCount],  MAXAD_LENGTH);
			KvGetString(kv, "flags", s_Flags[AdCount], 16, "none");
			AdCount++;
	} while ( KvGotoNextKey( kv ) );
	CloseHandle(kv);
	PrintToServer("Advertisements Parsed Successfully, Loaded %i Ads", AdCount);
	return;
}


bool:HasFlag(iClient, AdminFlag:fFlagList[16])
{
	new iFlags = GetUserFlagBits(iClient);
	if(iFlags & ADMFLAG_ROOT)
		return true;
	
	for(new i = 0; i < sizeof(fFlagList); i++)
	{
		if(iFlags & FlagToBit(fFlagList[i]))
			return true;
	}
	
	return false;
}