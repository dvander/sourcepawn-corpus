#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "1.1.0"
#define PLUGIN_PREFIX "\x04Auto Skin: \x03"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hDefault = INVALID_HANDLE;
new Handle:g_hForced = INVALID_HANDLE;
new Handle:g_hBots = INVALID_HANDLE;
new Handle:g_hDelay = INVALID_HANDLE;
new Handle:g_hTier[6] = { INVALID_HANDLE, ... };
new Handle:g_hTierT[6] = { INVALID_HANDLE, ... };
new Handle:g_hTierCT[6] = { INVALID_HANDLE, ... };
new Handle:g_hCookie = INVALID_HANDLE;

static const String:g_sModelsCT[4][] = 
{
	"models/player/ct_urban.mdl",
	"models/player/ct_gsg9.mdl",
	"models/player/ct_sas.mdl",
	"models/player/ct_gign.mdl"
};

static const String:g_sModelsT[4][] = 
{
	"models/player/t_phoenix.mdl",
	"models/player/t_leet.mdl",
	"models/player/t_arctic.mdl",
	"models/player/t_guerilla.mdl"
};

#define ACCESS_NO_ACCESS 0
#define ACCESS_TIER_ONE 0
#define ACCESS_TIER_TWO 1
#define ACCESS_TIER_THREE 2
#define ACCESS_TIER_FOUR 3
#define ACCESS_TIER_FIVE 4
#define ACCESS_TIER_NONE 5

new g_iTeam[MAXPLAYERS + 1];
new g_iAccess[MAXPLAYERS + 1];
new bool:g_bAppear[MAXPLAYERS + 1];

new bool:g_bLateLoad, bool:g_bEnabled, bool:g_bModel, g_iBots, bool:g_bDefault, Float:g_fDelay, bool:g_bForced, g_iTier[6], bool:g_bTier[6][2], String:g_sTier[6][2][128];

public Plugin:myinfo =
{
	name = "Auto Skin", 
	author = "Twisted|Panda", 
	description = "Provides simple functionality for applying skins to players automatically.", 
	version = PLUGIN_VERSION, 
	url = "http://ominousgaming.com"
}

public OnPluginStart()
{
	CreateConVar("sm_autoskin_version", PLUGIN_VERSION, "Auto Skin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_autoskin_enable", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hBots = CreateConVar("sm_autoskin_bots", "5", "Default access level for bots. 1 = Tier One, 5 = Tier None, 0 = No Access", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hDefault = CreateConVar("sm_autoskin_default", "1", "Controls how data is assigned for new players. (0 = Skins start disabled, 1 = Skins start enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hDelay = CreateConVar("sm_autoskin_delay", "0.1", "Controls how long after a player spawns that their skin is applied.", FCVAR_NONE, true, 0.0);
	g_hForced  = CreateConVar("sm_autoskin_forced", "1", "Controls skin status for non admins. If enabled, non-admins cannot access !skins and their skin is always visible.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	g_hTier[0] = CreateConVar("sm_autoskin_tier_one", "-1", "Letter flag(s) required to access the tier one model. (\"-1\" Disables)", FCVAR_NONE);
	g_hTierT[0] = CreateConVar("sm_autoskin_tier_one_t", "", "Path to player model, access level == sm_autoskin_tier_one. (\"\" Disables)", FCVAR_NONE);
	g_hTierCT[0] = CreateConVar("sm_autoskin_tier_one_ct", "", "Path to player model, access level == sm_autoskin_tier_one. (\"\" Disables)", FCVAR_NONE);

	g_hTier[1] = CreateConVar("sm_autoskin_tier_two", "-1", "Letter flag(s) required to access the tier two model. (\"-1\" Disables)", FCVAR_NONE);
	g_hTierT[1] = CreateConVar("sm_autoskin_tier_two_t", "", "Path to player model, access level == sm_autoskin_tier_two. (\"\" Disables)", FCVAR_NONE);
	g_hTierCT[1] = CreateConVar("sm_autoskin_tier_two_ct", "", "Path to player model, access level == sm_autoskin_tier_two. (\"\" Disables)", FCVAR_NONE);

	g_hTier[2] = CreateConVar("sm_autoskin_tier_three", "-1", "Letter flag(s) required to access the tier three model. (\"-1\" Disables)", FCVAR_NONE);
	g_hTierT[2] = CreateConVar("sm_autoskin_tier_three_t", "", "Path to player model, access level == sm_autoskin_tier_three. (\"\" Disables)", FCVAR_NONE);
	g_hTierCT[2] = CreateConVar("sm_autoskin_tier_three_ct", "", "Path to player model, access level == sm_autoskin_tier_three. (\"\" Disables)", FCVAR_NONE);

	g_hTier[3] = CreateConVar("sm_autoskin_tier_four", "-1", "Letter flag(s) required to access the tier four model. (\"-1\" Disables)", FCVAR_NONE);
	g_hTierT[3] = CreateConVar("sm_autoskin_tier_four_t", "", "Path to player model, access level == sm_autoskin_tier_four. (\"\" Disables)", FCVAR_NONE);
	g_hTierCT[3] = CreateConVar("sm_autoskin_tier_four_ct", "", "Path to player model, access level == sm_autoskin_tier_four. (\"\" Disables)", FCVAR_NONE);

	g_hTier[4] = CreateConVar("sm_autoskin_tier_five", "-1", "Letter flag(s) required to access the tier five model. (\"-1\" Disables)", FCVAR_NONE);
	g_hTierT[4] = CreateConVar("sm_autoskin_tier_five_t", "", "Path to player model, access level == sm_autoskin_tier_five. (\"\" Disables)", FCVAR_NONE);
	g_hTierCT[4] = CreateConVar("sm_autoskin_tier_five_ct", "", "Path to player model, access level == sm_autoskin_tier_five. (\"\" Disables)", FCVAR_NONE);

	g_hTier[5] = CreateConVar("sm_autoskin_tier_none", "0", "Enables/disables the ability for regular players to have an assigned model.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hTierT[5] = CreateConVar("sm_autoskin_tier_none_t", "", "Path to player model, access level == none. (\"\" Disables)", FCVAR_NONE);
	g_hTierCT[5] = CreateConVar("sm_autoskin_tier_none_ct", "", "Path to player model, access level == none. (\"\" Disables)", FCVAR_NONE);
	AutoExecConfig(true, "sm_autoskin");

	g_hCookie = RegClientCookie("Auto_Skin", "Auto Skin Status", CookieAccess_Protected);

	RegConsoleCmd("sm_skin", Command_Skin);
	RegConsoleCmd("sm_skins", Command_Skin);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	
	HookConVarChange(g_hEnabled, Action_OnSettingsChange);
	HookConVarChange(g_hDelay, Action_OnSettingsChange);
	HookConVarChange(g_hBots, Action_OnSettingsChange);
	HookConVarChange(g_hDefault, Action_OnSettingsChange);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnMapStart()
{
	Void_SetDefaults();
	if(g_bEnabled)
	{
		ReadDownloads();

		for(new i = 0; i <= 3; i++)
		{
			PrecacheModel(g_sModelsT[i], true);
			PrecacheModel(g_sModelsCT[i], true);
		}
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Void_ReadModels();

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					new bool:g_bTemp = false;
					if(!IsFakeClient(i))
					{
						new g_iFlags = GetUserFlagBits(i);
						if(g_iFlags)
						{
							for(new j = ACCESS_TIER_ONE; j < ACCESS_TIER_NONE; j++)
							{
								if(g_iTier[j] == -1)
									continue;
								
								if(g_iFlags & g_iTier[j])
								{
									g_iAccess[i] = (j + 1);
									g_bTemp = true;
								}
							}
						}

						if(!g_bTemp)
						{
							if(g_iTier[ACCESS_TIER_NONE])
							{
								g_iAccess[i] = (ACCESS_TIER_NONE + 1);
								if(g_bForced)
									g_bAppear[i] = true;
							}
							else
								g_iAccess[i] = ACCESS_NO_ACCESS;
						}
					}
					else
						g_iAccess[i] = g_iBots;

					if(IsFakeClient(i))
						g_bAppear[i] = true;
					else
					{
						if(!g_bTemp)
							Void_LoadCookies(i);
					}
					if(IsPlayerAlive(i))
						Void_ProcessModel(i, (g_iAccess[i] - 1), (g_iTeam[i] - 2));
				}
				else
				{
					g_iAccess[i] = 0;
					g_iTeam[i] = 0;
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		g_iAccess[client] = ACCESS_NO_ACCESS;
		
		g_bAppear[client] = false;
		if(AreClientCookiesCached(client))
			Void_LoadCookies(client);
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled)
	{
		if(!IsFakeClient(client))
		{
			new g_iFlags = GetUserFlagBits(client);
			if(g_iFlags)
			{
				for(new i = ACCESS_TIER_ONE; i < ACCESS_TIER_NONE; i++)
				{
					if(g_iTier[i] == -1)
						continue;
					
					if(g_iFlags & g_iTier[i])
					{
						g_iAccess[client] = (i + 1);
						return;
					}
				}
			}

			if(g_iTier[ACCESS_TIER_NONE])
			{
				g_iAccess[client] = (ACCESS_TIER_NONE + 1);
				if(g_bForced)
					g_bAppear[client] = true;
			}
			else
				g_iAccess[client] = ACCESS_NO_ACCESS;
		}
		else
		{
			g_iAccess[client] = g_iBots;
			g_bAppear[client] = true;
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
	}
}

public OnClientCookiesCached(client)
{
	if(g_bEnabled)
	{
		Void_LoadCookies(client);
	}
}

public Action:Command_Skin(client, args)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client))
			return Plugin_Handled;
		else if(!g_iAccess[client] || g_bForced && g_iAccess[client] == ACCESS_TIER_NONE)
		{
			PrintToChat(client, "%sYou do not have appropriate access for this command!", PLUGIN_PREFIX);
			return Plugin_Handled;
		}

		if (g_bAppear[client])
		{
			PrintToChat(client, "%sYou've disabled the auto skin feature; your skin will no longer appear!", PLUGIN_PREFIX);
			SetClientCookie(client, g_hCookie, "0");

			g_bAppear[client] = false;
			/* if(IsPlayerAlive(client))
			{
				if(g_bForced && g_iTier[ACCESS_TIER_NONE])
					Void_ProcessModel(client, ACCESS_TIER_NONE, (g_iTeam[client] - 2));
				else
				{
					switch(g_iTeam[client])
					{
						case 2:
							SetEntityModel(client, g_sModelsT[GetRandomInt(0, 3)]);
						case 3:
							SetEntityModel(client, g_sModelsCT[GetRandomInt(0, 3)]);
					}
				}
			} */
		}
		else
		{
			PrintToChat(client, "%sYou've enabled the auto skin feature; your skin will appear on spawn!", PLUGIN_PREFIX);
			SetClientCookie(client, g_hCookie, "1");

			g_bAppear[client] = true;
			/* if(IsPlayerAlive(client))
				Void_ProcessModel(client, (g_iAccess[client] - 1), (g_iTeam[client] - 2)); */
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_Say(client, args)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client) || !g_iAccess[client])
			return Plugin_Continue;

		decl String:g_sText[256];
		GetCmdArgString(g_sText, sizeof(g_sText));
		StripQuotes(g_sText);

		if(StrEqual(g_sText, "!skin", false) || StrEqual(g_sText, "!skins", false))
			return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !g_iAccess[client])
			return Plugin_Continue;

		if(g_bAppear[client])
			CreateTimer(g_fDelay, Timer_ProcessModel, client);
		else
			if(g_bForced && g_iTier[ACCESS_TIER_NONE])
				Void_ProcessModel(client, ACCESS_TIER_NONE, (g_iTeam[client] - 2));
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !g_iAccess[client])
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(g_bAppear[client] || g_bForced && g_iAccess[client] == ACCESS_TIER_NONE)
			CreateTimer(g_fDelay, Timer_ProcessModel, client);
	}
	
	return Plugin_Continue;
}

public Action:Timer_ProcessModel(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
		Void_ProcessModel(client, (g_iAccess[client] - 1), (g_iTeam[client] - 2));
		
	return Plugin_Continue;
}

bool:Bool_Check(const String:g_sString[])
{
	if(StrEqual(g_sString, ""))
		return false;
	else if(!FileExists(g_sString))
		return false;
		
	return true;
}

void:Void_LoadCookies(client)
{
	decl String:g_sCookie[3];
	GetClientCookie(client, g_hCookie, g_sCookie, sizeof(g_sCookie));
	
	if(StrEqual(g_sCookie, ""))
	{
		IntToString(g_bDefault, g_sCookie, sizeof(g_sCookie));
		SetClientCookie(client, g_hCookie, g_sCookie);

		g_bAppear[client] = g_bDefault;
	}
	else
		g_bAppear[client] = StringToInt(g_sCookie) ? true : false;
}

void:Void_ProcessModel(client, access, team)
{
	if(team >= 0 && access >= 0)
		if(g_bTier[access][team])
			SetEntityModel(client, g_sTier[access][team]);
}

void:Void_SetDefaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_iBots = GetConVarInt(g_hBots);
	g_bDefault = GetConVarInt(g_hDefault) ? true : false;
	g_fDelay = GetConVarFloat(g_hDelay);
	g_bForced = GetConVarInt(g_hForced) ? true : false;
}

void:Void_ReadModels()
{
	decl String:g_sBuffer[256];
	for(new i = ACCESS_TIER_ONE; i < ACCESS_TIER_NONE; i++)
	{
		GetConVarString(g_hTier[i], g_sBuffer, sizeof(g_sBuffer));
		if(!StrEqual(g_sBuffer, "-1", false) || g_iBots == (i - 1))
		{
			g_iTier[i] = ReadFlagString(g_sBuffer);

			GetConVarString(g_hTierT[i], g_sTier[i][0], 128);
			g_bTier[i][0] = Bool_Check(g_sTier[i][0]);

			GetConVarString(g_hTierCT[i], g_sTier[i][1], 128);
			g_bTier[i][1] = Bool_Check(g_sTier[i][1]);
		}
		else
			g_iTier[i] = -1;
	}

	g_iTier[ACCESS_TIER_NONE] = GetConVarInt(g_hTier[ACCESS_TIER_NONE]);
	if(g_iTier[ACCESS_TIER_NONE])
	{
		GetConVarString(g_hTierT[ACCESS_TIER_NONE], g_sTier[ACCESS_TIER_NONE][0], 128);
		g_bTier[ACCESS_TIER_NONE][0] = Bool_Check(g_sTier[ACCESS_TIER_NONE][0]);

		GetConVarString(g_hTierCT[ACCESS_TIER_NONE], g_sTier[ACCESS_TIER_NONE][1], 128);
		g_bTier[ACCESS_TIER_NONE][1] = Bool_Check(g_sTier[ACCESS_TIER_NONE][1]);
	}
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hBots)
		g_iBots = StringToInt(newvalue);
	else if(cvar == g_hDefault)
		g_bDefault = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hDelay)
		g_fDelay = StringToFloat(newvalue);
	else if(cvar == g_hForced)
		g_bForced = StringToInt(newvalue) ? true : false;
}

public ReadDownloads()
{
	new String:g_sBuffer[256];
	BuildPath(Path_SM, g_sBuffer, sizeof(g_sBuffer), "configs/sm_autoskin.ini");
	new Handle:g_hFileName = OpenFile(g_sBuffer, "r");

	if(g_hFileName != INVALID_HANDLE) 
	{
		new g_iLength;
		while (ReadFileLine(g_hFileName, g_sBuffer, sizeof(g_sBuffer)))
		{	
			g_iLength = strlen(g_sBuffer);
			if (g_sBuffer[(g_iLength - 1)] == '\n')
				g_sBuffer[--g_iLength] = '\0';

			TrimString(g_sBuffer);
			if (!StrEqual(g_sBuffer, "", false))
				ReadFileFolder(g_sBuffer);

			if (IsEndOfFile(g_hFileName))
				break;
		}

		CloseHandle(g_hFileName);
	}
}

public ReadFileFolder(String:g_sPath[])
{
	new Handle:g_iDirectory = INVALID_HANDLE;
	new String:g_sBuffer[256], String:g_sLine[256];
	new FileType:g_zFileType = FileType_Unknown;
	new g_iLength;
	
	g_iLength = strlen(g_sPath);
	if (g_sPath[g_iLength-1] == '\n')
		g_sPath[--g_iLength] = '\0';

	TrimString(g_sPath);
	if(DirExists(g_sPath))
	{
		g_iDirectory = OpenDirectory(g_sPath);
		while(ReadDirEntry(g_iDirectory, g_sBuffer, sizeof(g_sBuffer), g_zFileType))
		{
			g_iLength = strlen(g_sBuffer);
			if (g_sBuffer[g_iLength-1] == '\n')
				g_sBuffer[--g_iLength] = '\0';
			TrimString(g_sBuffer);

			if (!StrEqual(g_sBuffer, "") && !StrEqual(g_sBuffer, ".", false) && !StrEqual(g_sBuffer,"..",false))
			{
				strcopy(g_sLine, sizeof(g_sLine), g_sPath);
				StrCat(g_sLine, sizeof(g_sLine), "/");
				StrCat(g_sLine, sizeof(g_sLine), g_sBuffer);

				if(g_zFileType == FileType_File)
					ReadItem(g_sLine);
				else
					ReadFileFolder(g_sLine);
			}
		}
	}
	else
		ReadItem(g_sPath);

	if(g_iDirectory != INVALID_HANDLE)
		CloseHandle(g_iDirectory);
}

public ReadItem(String:g_sBuffer[])
{
	new g_iLength = strlen(g_sBuffer);
	if (g_sBuffer[g_iLength-1] == '\n')
		g_sBuffer[--g_iLength] = '\0';
	TrimString(g_sBuffer);

	if(StrContains(g_sBuffer, "//Model Files Only (Do Not Remove Line)", true) >= 0)
		g_bModel = true;
	else if(StrContains(g_sBuffer, "//All Other Files (Do Not Remove Line)", true) >= 0)
		g_bModel = false;
	else if (FileExists(g_sBuffer) && !StrEqual(g_sBuffer, ""))
	{
		if(g_bModel)
			PrecacheModel(g_sBuffer, true);

		AddFileToDownloadsTable(g_sBuffer);
	}
	else if(!FileExists(g_sBuffer))
		LogError("Format Error: %s Does Not Exist!", g_sBuffer);
	else
		LogError("Format Error: Invalid String: %s", g_sBuffer);
}