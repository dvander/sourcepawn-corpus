// Survivor Starter Pack
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required
#define SSP_PREFIX "[SSP]"
#define SSP_VERSION "1.4"

public Plugin myinfo =
{
	name = "Survivor Starter Pack",
	author = "Psyk0tik (Crasher_3637)",
	description = "Provides starter packs for survivors.",
	version = SSP_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=309990"
};

char g_sDefaultPack[325];
char g_sPlayerPack[MAXPLAYERS + 1][325];
char g_sSavePath[255];
int g_iFileTimeOld;
int g_iFileTimeNew;
int g_iPluginEnabled;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Survivor Starter Pack only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	Format(g_sSavePath, sizeof(g_sSavePath), "cfg/sourcemod/survivor_starter_pack.cfg");
	vLoadConfigs();
	g_iFileTimeOld = GetFileTime(g_sSavePath, FileTime_LastChange);
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_starter", cmdStarterPack, ADMFLAG_ROOT, "Set a survivor's starter pack.");
	CreateConVar("ssp_pluginversion", SSP_VERSION, "Survivor Starter Pack Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_spawn", eEventPlayerSpawn);
}

public void OnConfigsExecuted()
{
	vLoadConfigs();
	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));
	if (IsMapValid(sMapName))
	{
		CreateTimer(1.0, tTimerReloadConfig, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

void vLoadConfigs()
{
	KeyValues kvStarterPack = new KeyValues("Survivor Starter Pack");
	kvStarterPack.ImportFromFile(g_sSavePath);
	if (kvStarterPack.JumpToKey("General", true))
	{
		g_iPluginEnabled = kvStarterPack.GetNum("Plugin Enabled", 1);
		g_iPluginEnabled = iSetCellLimit(g_iPluginEnabled, 0, 1);
		kvStarterPack.GetString("Default Pack", g_sDefaultPack, sizeof(g_sDefaultPack), "smg,pistol,pain_pills");
		kvStarterPack.SetNum("Plugin Enabled", g_iPluginEnabled);
		kvStarterPack.SetString("Default Pack", g_sDefaultPack);
		kvStarterPack.Rewind();
	}
	kvStarterPack.ExportToFile(g_sSavePath);
	delete kvStarterPack;
}

public void eEventPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iSurvivorId = event.GetInt("userid");
	int iSurvivor = GetClientOfUserId(iSurvivorId);
	if (bIsSurvivor(iSurvivor))
	{
		CreateTimer(1.0, tTimerStarterPack, iSurvivorId, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action cmdStarterPack(int client, int args)
{
	if (g_iPluginEnabled == 0)
	{
		ReplyToCommand(client, "\x04%s\x05 Survivor Starter Pack\x01 is disabled.", SSP_PREFIX);
		return Plugin_Handled;
	}
	char target[32];
	GetCmdArg(1, target, sizeof(target));
	char sLoadout[325];
	GetCmdArg(2, sLoadout, sizeof(sLoadout));
	char target_name[32];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int iPlayer = 0; iPlayer < target_count; iPlayer++)
	{
		if (bIsSurvivor(target_list[iPlayer]))
		{
			KeyValues kvStarterPack = new KeyValues("Survivor Starter Pack");
			kvStarterPack.ImportFromFile(g_sSavePath);
			char sSteamID[32];
			GetClientAuthId(target_list[iPlayer], AuthId_Steam2, sSteamID, sizeof(sSteamID));
			if (kvStarterPack.JumpToKey(sSteamID, true))
			{
				kvStarterPack.SetString("Starter Pack", sLoadout);
				kvStarterPack.Rewind();
			}
			kvStarterPack.ExportToFile(g_sSavePath);
			delete kvStarterPack;
			if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
			{
				PrintToChat(client, "\x04%s\x01 Saved\x05 %s\x01 to the config file with this loadout: \x05%s", SSP_PREFIX, sSteamID, sLoadout);
			}
		}
	}
	return Plugin_Handled;
}

bool bIsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

int iSetCellLimit(int value, int min, int max)
{
	if (value < min)
	{
		value = min;
	}
	else if (value > max)
	{
		value = max;
	}
	return value;
}

void vCheatCommand(int client, char[] command, char[] arguments = "", any ...)
{
	int iCmdFlags = GetCommandFlags(command);
	SetCommandFlags(command, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, iCmdFlags|FCVAR_CHEAT);
}

void vRemoveWeapon(int client, int slot)
{
	int iSlot = GetPlayerWeaponSlot(client, slot);
	if (iSlot > 0)
	{
		RemovePlayerItem(client, iSlot);
		AcceptEntityInput(iSlot, "Kill");
	}
}

public Action tTimerStarterPack(Handle timer, any userid)
{
	int iSurvivor = GetClientOfUserId(userid);
	if (g_iPluginEnabled == 0 || !bIsSurvivor(iSurvivor))
	{
		return Plugin_Stop;
	}
	vRemoveWeapon(iSurvivor, 0);
	vRemoveWeapon(iSurvivor, 1);
	vRemoveWeapon(iSurvivor, 2);
	vRemoveWeapon(iSurvivor, 3);
	vRemoveWeapon(iSurvivor, 4);
	KeyValues kvStarterPack = new KeyValues("Survivor Starter Pack");
	kvStarterPack.ImportFromFile(g_sSavePath);
	char sSteamID[32];
	GetClientAuthId(iSurvivor, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	if (kvStarterPack.JumpToKey(sSteamID))
	{
		kvStarterPack.GetString("Starter Pack", g_sPlayerPack[iSurvivor], sizeof(g_sPlayerPack[]), g_sDefaultPack);
		kvStarterPack.Rewind();
	}
	delete kvStarterPack;
	char sItem[5][64];
	char sStarterPack[325];
	sStarterPack = (g_sPlayerPack[iSurvivor][0] != '\0') ? g_sPlayerPack[iSurvivor] : g_sDefaultPack;
	ExplodeString(sStarterPack, ",", sItem, sizeof(sItem), sizeof(sItem[]));
	for (int iItem = 0; iItem < sizeof(sItem); iItem++)
	{
		if (sItem[iItem][0] != '\0')
		{
			vCheatCommand(iSurvivor, "give", sItem[iItem]);
		}
	}
	return Plugin_Continue;
}

public Action tTimerReloadConfig(Handle timer)
{
	if (g_iPluginEnabled == 0)
	{
		return Plugin_Continue;
	}
	g_iFileTimeNew = GetFileTime(g_sSavePath, FileTime_LastChange);
	if (g_iFileTimeOld != g_iFileTimeNew)
	{
		PrintToServer("%s Reloading config file (%s)...", SSP_PREFIX, g_sSavePath);
		KeyValues kvStarterPack = new KeyValues("Survivor Starter Pack");
		kvStarterPack.ImportFromFile(g_sSavePath);
		if (kvStarterPack.JumpToKey("General"))
		{
			g_iPluginEnabled = kvStarterPack.GetNum("Plugin Enabled", 1);
			g_iPluginEnabled = iSetCellLimit(g_iPluginEnabled, 0, 1);
			kvStarterPack.GetString("Default Pack", g_sDefaultPack, sizeof(g_sDefaultPack), "smg,pistol,pain_pills");
			kvStarterPack.Rewind();
		}
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if (bIsSurvivor(iPlayer))
			{
				char sSteamID[32];
				GetClientAuthId(iPlayer, AuthId_Steam2, sSteamID, sizeof(sSteamID));
				if (kvStarterPack.JumpToKey(sSteamID))
				{
					kvStarterPack.GetString("Starter Pack", g_sPlayerPack[iPlayer], sizeof(g_sPlayerPack[]));
					kvStarterPack.Rewind();
				}
			}
		}
		delete kvStarterPack;
		g_iFileTimeOld = g_iFileTimeNew;
	}
	return Plugin_Continue;
}