/***************ABOUT**********************
* ClanMatch Server Player Manager by Dionys
* For Sourcemod 1.2.0
******************************************/

#pragma semicolon 1
#include <sourcemod>
#define Version "1.1.2"

new Handle:Allowed = INVALID_HANDLE;
new Handle:AdminAllowed = INVALID_HANDLE;
new Handle:Debug = INVALID_HANDLE;
new Handle:DType = INVALID_HANDLE;
new Handle:BTime = INVALID_HANDLE;
new Handle:hKVSettings = INVALID_HANDLE;

new String:CMSPM_FileSettings[128];

new String:player_clanid[64];
new String:player_playerid[64];
new String:player_clanid_def[64] = "none";
new String:player_playerid_def[64] = "none";

new player_bantime;

public Plugin:myinfo = 
{
	name = "ClanMatch Server Player Manager",
	author = "Dionys",
	description = "Check player for access on ClanMatch Server.",
	version = Version,
	url = "skiner@inbox.ru"
};

public OnPluginStart()
{
	CreateConVar("sm_spm_version", Version, "Version of ClanMatch Server Player Manager plugin.", FCVAR_NOTIFY);
	Allowed = CreateConVar("sm_spm_enable", "0", "0-Disable/1-Enables ClanMatch Server Player Manager.");
	AdminAllowed = CreateConVar("sm_spm_admin", "0", "0-Disable/1-Enables always admin allow.");
	Debug = CreateConVar("sm_spm_debug", "0", "0-Disable/1-Enables ClanMatch Server Player Manager Debug.");
	DType = CreateConVar("sm_spm_type", "0", "Disallow type. 0-Off/1-BanIP/2-BanID/3-Kick.");
	BTime = CreateConVar("sm_spm_btime", "60", "Ban time in min.");

/************DISABLE***************
	// Execute the config file
	AutoExecConfig(true, "sm_spm");
**********************************/
	LoadTranslations("plugin.sm_spm_lang");
	
	hKVSettings=CreateKeyValues("CMSPMSettings");	
	
	BuildPath(Path_SM, CMSPM_FileSettings, 128, "data/sm_spm_reg.txt");
	if (!FileToKeyValues(hKVSettings, CMSPM_FileSettings))
		SetFailState("ClanMatch Server Player Manager settings not found!");

	RegAdminCmd("sm_spm_add", SPM_ADD_USER, ADMFLAG_ROOT, "ADD User to registration. Usage: sm_spm_add <IP or STEAM> <PlayerID> <ClanID>");
	RegAdminCmd("sm_spm_del", SPM_DEL_USER, ADMFLAG_ROOT, "DEL User from registration. Usage: sm_spm_del <IP or STEAM>");
	RegAdminCmd("sm_spm_list", SPM_LIST_USER, ADMFLAG_ROOT, "List of registration");
	RegAdminCmd("sm_spm_reload", SPM_REFRESH_USER, ADMFLAG_ROOT, "Reload registration");
}

public OnMapStart()
{
	if (GetConVarInt(Allowed) == 1)
	{
		ClearKV(hKVSettings);
		if (!FileToKeyValues(hKVSettings, CMSPM_FileSettings))
			SetFailState("ClanMatch Server Player Manager settings not found!");
	}
}

public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client) && GetConVarInt(Allowed) == 1)
	{
		decl String:player_name[64];
		decl String:steam_id[64];
		decl String:player_ip[64];

		player_clanid = "none";
		player_playerid = "none";

		// Get BanTime
		player_bantime = GetConVarInt(BTime);
		// Get Client Name
		GetClientName(client, player_name, sizeof(player_name));
		// Get Client IP
		GetClientIP(client, player_ip, sizeof(player_ip));
		// Get Client SteamID
		GetClientAuthString(client, steam_id, sizeof(steam_id));

		KvRewind(hKVSettings);
		if (KvJumpToKey(hKVSettings, steam_id, false))
		{
			KvGetString(hKVSettings, "PlayerID", player_playerid, 64, player_playerid_def);
			KvGetString(hKVSettings, "ClanID", player_clanid, 64, player_clanid_def);
		}
		else if (KvJumpToKey(hKVSettings, player_ip, false))
		{
			KvGetString(hKVSettings, "PlayerID", player_playerid, 64, player_playerid_def);
			KvGetString(hKVSettings, "ClanID", player_clanid, 64, player_clanid_def);
		}

		if (GetConVarInt(Debug) == 1)
		{
			PrintToChat(client, "\x04[CMSPM] \x03%s|%s|%s", player_name, steam_id, player_ip);
			PrintToChat(client, "\x04[CMSPM] \x03%s|%s", player_playerid, player_clanid);
			PrintToChat(client, "\x04[CMSPM] BanTime: \x03%d min", player_bantime);
		}

		if (StrEqual(player_clanid, "none") == true && StrEqual(player_playerid, "none") == true && GetUserAdmin(client) != INVALID_ADMIN_ID && GetConVarInt(AdminAllowed) == 1)
			PrintToChatAll("%t", "wellcome admin notreg", 4, 3, player_name, 4, 3, player_ip, 4, 3, steam_id);
		else if (StrEqual(player_clanid, "none") != true && StrEqual(player_playerid, "none") != true && GetUserAdmin(client) != INVALID_ADMIN_ID)
			PrintToChatAll("%t", "wellcome admin", 4, 3, player_name, 4, 3, player_playerid, 4, 3, player_clanid);
		else if (StrEqual(player_clanid, "none") != true && StrEqual(player_playerid, "none") != true)
			PrintToChatAll("%t", "wellcome player", 4, 3, player_name, 4, 3, player_playerid, 4, 3, player_clanid);
		else
		{
			if (GetConVarInt(DType) == 1)
			{
				// BanIP
				ServerCommand("addip %d %s", player_bantime, player_ip);
				PrintToChatAll("\x04[CMSPM] %t \x03%s\x04 IP: \x03%s\x04 STEAM: \x03%s\x04. %t", "ban player", player_name, player_ip, steam_id, "kick message");
			}
			else if (GetConVarInt(DType) == 2)
			{
				// BanID
				ServerCommand("banid %d %s", player_bantime, steam_id);
				PrintToChatAll("\x04[CMSPM] %t \x03%s\x04 IP: \x03%s\x04 STEAM: \x03%s\x04. %t", "ban player", player_name, player_ip, steam_id, "kick message");
			}
			else if (GetConVarInt(DType) == 3)
			{
				// Kick
				ServerCommand("sm_kick %s %t", player_name, "kick message");
				PrintToChatAll("\x04[CMSPM] %t \x03%s\x04 IP: \x03%s\x04 STEAM: \x03%s\x04. %t", "kick player", player_name, player_ip, steam_id, "kick message");
			}
			else
			{
				// Message
				if (GetUserAdmin(client) != INVALID_ADMIN_ID)
					PrintToChatAll("%t", "wellcome admin notreg", 4, 3, player_name, 4, 3, player_ip, 4, 3, steam_id);
				else
					PrintToChatAll("%t", "wellcome player notreg", 4, 3, player_name, 4, 3, player_ip, 4, 3, steam_id);
			}
		}
	}
}

public Action:SPM_ADD_USER(client, args)
{
	if (GetConVarInt(Allowed) == 1)
	{
		if (args < 3 || args > 3)
		{
			if (client == 0)
				PrintToServer("[CMSPM] ADD Error! Usage: sm_spm_add <IP or STEAM> <PlayerID> <ClanID>");
			else
			{
				PrintToConsole(client, "[CMSPM] ADD Error! Usage: sm_spm_add <IP or STEAM> <PlayerID> <ClanID>");
				PrintToChat(client, "\x04[CMSPM] ADD Error!");
				PrintToChat(client, "\x03[CMSPM] Usage: sm_spm_add <IP or STEAM> <PlayerID> <ClanID>");
			}
		}
		else
		{
			new String:add_acc_id[64];
			new String:player_id[64];
			new String:clan_id[64];
			GetCmdArg(1, add_acc_id, sizeof(add_acc_id));
			GetCmdArg(2, player_id, sizeof(player_id));
			GetCmdArg(3, clan_id, sizeof(clan_id));

			KvRewind(hKVSettings);
			if (KvJumpToKey(hKVSettings, add_acc_id, false))
			{
				if (client == 0)
					PrintToServer("[CMSPM] User Exist!");
				else
				{
					PrintToConsole(client, "[CMSPM] User Exist!");
					PrintToChat(client, "\x03[CMSPM] User Exist!");
				}
			}
			else
			{
				KvJumpToKey(hKVSettings, add_acc_id, true);
				KvSetString(hKVSettings, "PlayerID", player_id);
				KvSetString(hKVSettings, "ClanID", clan_id);
				KvRewind(hKVSettings);
				KeyValuesToFile(hKVSettings, CMSPM_FileSettings);

				if (client == 0)
					PrintToServer("[CMSPM] ADD User Done!");
				else
				{
					PrintToConsole(client, "[CMSPM] ADD User Done!");
					PrintToChat(client, "\x03[CMSPM] ADD User Done!");
				}
			}
		}
	}
	else
	{
		if (client == 0)
			PrintToServer("[CMSPM] Plug-in is a disable!");
		else
		{
			PrintToConsole(client, "[CMSPM] Plug-in is a disable!");
			PrintToChat(client, "\x03[CMSPM] Plug-in is a disable!");
		}
	}
	return Plugin_Handled;
}

public Action:SPM_DEL_USER(client, args)
{
	if (GetConVarInt(Allowed) == 1)
	{

		if (args < 1 || args > 1)
		{
			if (client == 0)
				PrintToServer("[CMSPM] DEL Error! Usage: sm_spm_del <IP or STEAM>");
			else
			{
				PrintToConsole(client, "[CMSPM] DEL Error! Usage: sm_spm_del <IP or STEAM>");
				PrintToChat(client, "\x04[CMSPM] DEL Error!");
				PrintToChat(client, "\x03[CMSPM] Usage: sm_spm_del <IP or STEAM>");
			}
		}
		else
		{
			new String:del_acc_id[64];
			GetCmdArg(1, del_acc_id, sizeof(del_acc_id));

			KvRewind(hKVSettings);
			if (KvJumpToKey(hKVSettings, del_acc_id, false))
			{
				KvDeleteThis(hKVSettings);
				KvRewind(hKVSettings);
				KeyValuesToFile(hKVSettings, CMSPM_FileSettings);

				if (client == 0)
					PrintToServer("[CMSPM] DEL User Done!");
				else
				{
					PrintToConsole(client, "[CMSPM] DEL User Done!");
					PrintToChat(client, "\x03[CMSPM] DEL User Done!");
				}
			}
			else
			{
				if (client == 0)
					PrintToServer("[CMSPM] DEL Error! This USER is not found!");
				else
				{
					PrintToConsole(client, "[CMSPM] DEL Error! This USER is not found!");
					PrintToChat(client, "\x04[CMSPM] DEL Error! This USER is not found!");
				}
			}
		}
	}
	else
	{
		if (client == 0)
			PrintToServer("[CMSPM] Plug-in is a disable!");
		else
		{
			PrintToConsole(client, "[CMSPM] Plug-in is a disable!");
			PrintToChat(client, "\x03[CMSPM] Plug-in is a disable!");
		}
	}
	return Plugin_Handled;
}

public Action:SPM_LIST_USER(client, args)
{
	if (GetConVarInt(Allowed) == 1)
		ListKV(hKVSettings, client);
	else
	{
		if (client == 0)
		{
			PrintToServer("[CMSPM] Plug-in is a disable!");
		}
		else
		{
			PrintToConsole(client, "[CMSPM] Plug-in is a disable!");
			PrintToChat(client, "\x03[CMSPM] Plug-in is a disable!");
		}
	}
	return Plugin_Handled;
}

public Action:SPM_REFRESH_USER(client, args)
{
	if (GetConVarInt(Allowed) == 1)
	{
		//ServerCommand("sm plugins reload sm_spm");

		ClearKV(hKVSettings);
		if (!FileToKeyValues(hKVSettings, CMSPM_FileSettings))
			SetFailState("ClanMatch Server Player Manager settings not found!");
	
		if (client == 0)
			PrintToServer("[CMSPM] Registration reloaded!");
		else
		{
			PrintToConsole(client, "[CMSPM] Registration reloaded!");
			PrintToChat(client, "\x04[CMSPM] Registration reloaded!");
		}
	}
	else
	{
		if (client == 0)
			PrintToServer("[CMSPM] Plug-in is a disable!");
		else
		{
			PrintToConsole(client, "[CMSPM] Plug-in is a disable!");
			PrintToChat(client, "\x03[CMSPM] Plug-in is a disable!");
		}
	}
	return Plugin_Handled;
}

/********************DISABLE**********************
ClearKV(Handle:kvhandle)
{
	if (!KvGotoFirstSubKey(kvhandle)) return;
 	for (;;)
	{
		if (KvDeleteThis(kvhandle) < 1) break;
		else if (!KvGotoNextKey(kvhandle)) break;
	}
}
************************************************/

ClearKV(Handle:kvhandle)
{
	KvRewind(kvhandle);
	if (KvGotoFirstSubKey(kvhandle))
	{
		do
		{
			KvDeleteThis(kvhandle);
			KvRewind(kvhandle);
		}
		while (KvGotoFirstSubKey(kvhandle));
		KvRewind(kvhandle);
	}
	
	if (GetConVarInt(Debug) == 1)
		ListKV(kvhandle, 0);
}

ListKV(Handle:kvhandle, client)
{
	KvRewind(kvhandle);
	if (KvGotoFirstSubKey(kvhandle))
	{
		new String:list_acc_id[64];
		new String:list_player_id[64];
		new String:list_player_id_def[64] = "none";
		new String:list_clan_id[64];
		new String:list_clan_id_def[64] = "none";

		if (client == 0)
		{
			PrintToServer("[CMSPM] Registration list:");
			PrintToServer("AccID : PlayerID : ClanID");
		}
		else
		{
			PrintToConsole(client, "[CMSPM] Registration list:");
			PrintToConsole(client, "AccID : PlayerID : ClanID");
		}

		do
		{
			KvGetSectionName(kvhandle, list_acc_id, sizeof(list_acc_id));
			KvGetString(kvhandle, "PlayerID", list_player_id, 64, list_player_id_def);
			KvGetString(kvhandle, "ClanID", list_clan_id, 64, list_clan_id_def);		

			if (client == 0)
				PrintToServer("%s : %s : %s", list_acc_id, list_player_id, list_clan_id);
			else
				PrintToConsole(client, "%s : %s : %s", list_acc_id, list_player_id, list_clan_id);
		}
		while (KvGotoNextKey(kvhandle));
		
		KvRewind(kvhandle);
	}
	else
	{
		if (client == 0)
		{
			PrintToServer("[CMSPM] Registration list empty!");
		}
		else
		{
			PrintToConsole(client, "[CMSPM] Registration list empty!");
		}
	}
}