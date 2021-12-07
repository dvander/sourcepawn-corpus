#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "2.2.2"

#define MAXCLIENTS 255
#define ARRAYS_SIZE 128

new g_iChannels;
new g_iChannelsMode[64];
new g_iChannelsTeams[64];
new String:g_sChannelsName[64][ARRAYS_SIZE];
new String:g_sChannelsPass[64][ARRAYS_SIZE];
new String:g_sChannelsFlag[64][ARRAYS_SIZE];

new g_iClientChannel[MAXCLIENTS+1];

public Plugin:myinfo = {
	name = "VoiceMgr",
	author = "s1dex",
	description = "Advanced Voice Manager [CS:S]",
	version = PLUGIN_VERSION,
	url = "http://www.adminexe.ru/"
};

public OnPluginStart()
{	
	LoadTranslations("voicemgr.phrases");
	
	RegConsoleCmd("channels", VCGui);
	RegConsoleCmd("vc_sc", VCSetChnl);
	RegConsoleCmd("vc_list", VCList);
	
	CreateConVar("voicemgr_version", PLUGIN_VERSION, "VoiceMgr Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("player_team", EventPlayerTeam);
}

public OnClientPutInServer(client)
{
	for (new i=0;i<=g_iChannels;i++)
	{
		if (g_iChannelsMode[i] != 0)
			continue;
		
		decl String:name[64];
		GetClientName(client, name, sizeof(name));
		
		g_iClientChannel[client] = i;
		RefreshClientChannel(client);
		CPrintToChatAll("%t", "ChangeChannel", name, g_sChannelsName[i]);
		break;
	}
}

public OnMapStart()
{
	g_iChannels = -1;
	//Путь к кфг каналов
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/voicemgr.channels.cfg");
	
	//создаем кейвалуи
	new Handle:kv = CreateKeyValues("Channels");
	FileToKeyValues(kv, file);
	if (KvGotoFirstSubKey(kv))
	{
		do
		{
			g_iChannels++;
			
			decl String:buffer[32];
			KvGetSectionName(kv, g_sChannelsName[g_iChannels], ARRAYS_SIZE);
			KvGetString(kv, "mode", buffer, sizeof(buffer), "public");
			if (StrEqual(buffer, "private"))
				g_iChannelsMode[g_iChannels] = 1;
			else if (StrEqual(buffer, "admins"))
				g_iChannelsMode[g_iChannels] = 2;
			else
				g_iChannelsMode[g_iChannels] = 0;
			
			if (g_iChannelsMode[g_iChannels] == 1)
				KvGetString(kv, "password", g_sChannelsPass[g_iChannels], ARRAYS_SIZE, "pw");
			if (g_iChannelsMode[g_iChannels] == 2)
				KvGetString(kv, "flag", g_sChannelsFlag[g_iChannels], ARRAYS_SIZE, "slay");
			
			g_iChannelsTeams[g_iChannels] = KvGetNum(kv, "teams", 0);
		}
		while (KvGotoNextKey(kv))
	}
}

public Action:EventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RefreshClientChannel(client);
}

public Action:VCGui(client, args)
{
	new Handle:menu = CreateMenu(MenuChooseChannel);
	SetMenuTitle(menu, "Choose channel [current: %s]", g_sChannelsName[g_iClientChannel[client]]);
	
	decl String:buffer[5];
	for (new i=0;i<=g_iChannels;i++)
	{
		if (i != g_iClientChannel[client])
		{
			IntToString(i, buffer, sizeof(buffer));
			AddMenuItem(menu, buffer, g_sChannelsName[i]);
		}
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

public Action:VCSetChnl(client, args)
{
	decl String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	new chnl = StringToInt(arg);
	if (chnl > g_iChannels)
	{
		CPrintToChat(client, "%t", "NotRegistered", chnl);
		return Plugin_Handled;
	}
	else if (chnl == g_iClientChannel[client])
	{
		CPrintToChat(client, "%t", "AlreadyIn");
		return Plugin_Handled;
	}
	else
	{
		if (g_iChannelsMode[chnl] == 2)
		{
			new AdminId:admin;
			if ((admin = GetUserAdmin(client)) == INVALID_ADMIN_ID)
			{
				CPrintToChat(client, "%t", "AdminsOnly");
				return Plugin_Handled;
			}
			else
			{
				new AdminFlag:flag;
				FindFlagByName(g_sChannelsFlag[chnl], flag);
				
				if (!GetAdminFlag(admin, flag))
				{
					CPrintToChat(client, "%t", "InvalidFlag", g_sChannelsFlag[chnl]);
					return Plugin_Handled;
				}
			}
		}
		else if (g_iChannelsMode[chnl] == 1)
		{
			decl String:info[128];
			GetClientInfo(client, "_vcpass", info, sizeof(info));
			if (!StrEqual(info, g_sChannelsPass[chnl]))
			{
				CPrintToChat(client, "%t", "Private1");
				CPrintToChat(client, "%t", "Private2");
				return Plugin_Handled;
			}
		}
		
		decl String:name[64];
		GetClientName(client, name, sizeof(name));
		
		g_iClientChannel[client] = chnl;
		RefreshClientChannel(client);
		CPrintToChatAll("%t", "ChangeChannel", name, g_sChannelsName[chnl]);
	}
	
	return Plugin_Handled;
}

public Action:VCList(client, args)
{
	PrintToConsole(client, "[VoiceMgr 2.0] Channels:");
	for (new i=0;i<=g_iChannels;i++)
		PrintToConsole(client, "ID: %d - %s", i, g_sChannelsName[i]);
	
	CPrintToChat(client, "%t", "ListChannels");
	return Plugin_Handled;
}

public MenuChooseChannel(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[5];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new chnl = StringToInt(info);
		if (g_iChannelsMode[chnl] == 2)
		{
			new AdminId:admin;
			if ((admin = GetUserAdmin(client)) == INVALID_ADMIN_ID)
			{
				CPrintToChat(client, "%t", "AdminsOnly");
				return;
			}
			else
			{
				new AdminFlag:flag;
				FindFlagByName(g_sChannelsFlag[chnl], flag);
				
				if (!GetAdminFlag(admin, flag))
				{
					CPrintToChat(client, "%t", "InvalidFlag", g_sChannelsFlag[chnl]);
					return;
				}
			}
		}
		else if (g_iChannelsMode[chnl] == 1)
		{
			GetClientInfo(client, "_vcpass", info, sizeof(info));
			if (!StrEqual(info, g_sChannelsPass[chnl]))
			{
				CPrintToChat(client, "%t", "Private1");
				CPrintToChat(client, "%t", "Private2");
				return;
			}
		}
		
		decl String:name[64];
		GetClientName(client, name, sizeof(name));
		
		g_iClientChannel[client] = chnl;
		RefreshClientChannel(client);
		CPrintToChatAll("%t", "ChangeChannel", name, g_sChannelsName[chnl]);
	}
}

stock RefreshClientChannel(client)
{
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
		{
			if (g_iClientChannel[client] == g_iClientChannel[i])
			{
				if (g_iChannelsTeams[g_iClientChannel[client]])				
				{
					if (GetClientTeam(client) == GetClientTeam(i))
					{
						SetListenOverride(client, i, Listen_Yes);
						SetListenOverride(i, client, Listen_Yes);
					}
					else
					{
						SetListenOverride(client, i, Listen_No);
						SetListenOverride(i, client, Listen_No);
					}
				}
				else
				{
					SetListenOverride(client, i, Listen_Yes);
					SetListenOverride(i, client, Listen_Yes);
				}
			}
			else
			{
				SetListenOverride(client, i, Listen_No);
				SetListenOverride(i, client, Listen_No);
			}
		}
	}
}