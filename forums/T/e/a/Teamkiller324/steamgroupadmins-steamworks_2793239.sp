#pragma semicolon 1
#pragma newdecls required

#include <steamworks>

#define VERSION "1.3.1"

public Plugin myinfo = {
	name = "Steam Group Admins | SteamWorks Version",
	author = "psychonic | Edited by SlidyBat",
	description = "Lookup admin status via steam community group",
	version = VERSION,
	url = "http://www.nicholashastings.com/"
}

bool g_bPlayerProcessed[MAXPLAYERS + 1] = { false, ... };
int g_PlayerLastCheck[MAXPLAYERS + 1] = { 0, ... };
bool g_bPlayerAuthed[MAXPLAYERS + 1] = { false, ... };
ArrayList g_SteamGroups;

enum struct SteamGroup
{
	int SGgroupId;
	ArrayList SGofficerGrps;
	ArrayList SGmemberGrps;
}
#define SGSIZE sizeof(SteamGroup)

#define GROUP_NAME_LEN 256

enum struct SGConfigInfo
{
	int conf_groupId;
	GroupId conf_mGrp;
	char conf_mGrpFlags[32];
	int conf_mGrpImmunity;
	GroupId conf_oGrp;
	char conf_oGrpFlags[32];
	int conf_oGrpImmunity;
	ArrayList conf_mGrpNames;
	ArrayList conf_oGrpNames;
}
#define CONFIGSIZE 23

public void OnPluginStart()
{
	CreateConVar("sgadmins_version", VERSION, _, FCVAR_NOTIFY);
	
	RegAdminCmd("sm_sgadmins_reload", ParseConfig, ADMFLAG_ROOT, "Reloads Steam Group Admins config file");
	
	ParseConfig(0,0);
	
	CreateTimer(5.0, RecheckPlayers, _, TIMER_REPEAT);
}

public Action RecheckPlayers(Handle hTimer)
{
	DoFullCheck();
	
	return Plugin_Continue;
}

void DoFullCheck()
{
	int time = GetTime()-5;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bPlayerProcessed[i] || !g_bPlayerAuthed[i] || g_PlayerLastCheck[i] > time)
			continue;
		
		LookupPlayerGroups(i);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
		return;
	
	g_bPlayerAuthed[client] = true;
	
	LookupPlayerGroups(client);
}

public void OnClientDisconnect(int client)
{
	g_bPlayerAuthed[client] = false;
	g_bPlayerProcessed[client] = false;
	g_PlayerLastCheck[client] = 0;
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	ParseConfig(0,0);
}

public void LookupPlayerGroups(int client)
{
	int cnt = g_SteamGroups.Length;
	for (int i = 0; i < cnt; i++)
	{
		SteamGroup group;
		g_SteamGroups.GetArray(i, group, SGSIZE);
		SteamWorks_GetUserGroupStatus(client, group.SGgroupId);
		g_PlayerLastCheck[client] = GetTime();
	}
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupAccountID, bool groupMember, bool groupOfficer)
{
	int clientId = -1;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (g_bPlayerAuthed[i] && authid == GetSteamAccountID(i))
		{
			clientId = i;
			break;
		}
	}
	
	Steam_GroupStatusResult(clientId, groupAccountID, groupMember, groupOfficer);
}

public void Steam_GroupStatusResult(int client, int groupAccountID, bool groupMember, bool groupOfficer)
{
	if (client <= 0 || !IsClientInGame(client))
		return;
	
	g_bPlayerProcessed[client] = true;
	
	if (!groupMember)
		return;
	
	SteamGroup group;
	
	if (!GetSteamGroupById(groupAccountID, group))
	{
		return;
	}
	
	AdminId admid = GetUserAdmin(client);
	
	int mgroupcnt = group.SGmemberGrps.Length;
	if (mgroupcnt > 0)
	{
		if (admid == INVALID_ADMIN_ID)
		{
			char auth[32];
			GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth), true);
			admid = CreateAdmin(auth);
			SetUserAdmin(client, admid, true);
		}
		
		for (int i = 0; i < mgroupcnt; i++)
		{
			GroupId id = view_as<GroupId>(group.SGmemberGrps.Get(i));
			AdminInheritGroup(admid, id);
		}
	}
	
	if (!groupOfficer)
		return;
	
	int ogroupcnt = group.SGofficerGrps.Length;
	if (ogroupcnt > 0)
	{
		if (admid == INVALID_ADMIN_ID)
		{
			char auth[32];
			GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth), true);
			admid = CreateAdmin(auth);
			SetUserAdmin(client, admid, true);
		}
		
		for (int i = 0; i < ogroupcnt; i++)
		{
			GroupId id = view_as<GroupId>(group.SGofficerGrps.Get(i));
			AdminInheritGroup(admid, id);
		}
	}
}

bool GetSteamGroupById(int id, SteamGroup buffer)
{
	int cnt = g_SteamGroups.Length;
	for (int i = 0; i < cnt; i++)
	{
		SteamGroup group;
		g_SteamGroups.GetArray(i, group, SGSIZE);
		if (group.SGgroupId == id)
		{
			buffer = group;
			return true;
		}
	}
	
	return false;
}

enum ConfigState {
	CS_Nowhere,
	CS_InGroup,
	CS_InMembers,
	CS_InOfficers
}

ConfigState g_ConfigState;
SGConfigInfo g_ConfigGroup;

public Action ParseConfig(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
		g_bPlayerProcessed[i] = false;
	
	if (g_SteamGroups != null)
	{
		int cnt = g_SteamGroups.Length;
		for (int i = 0; i < cnt; i++)
		{
			SteamGroup group;
			g_SteamGroups.GetArray(i, group, SGSIZE);
			if (group.SGofficerGrps != null)
				delete group.SGofficerGrps;
			if (group.SGmemberGrps != null)
				delete group.SGmemberGrps;
		}
		delete g_SteamGroups;
	}
	g_SteamGroups = new ArrayList(SGSIZE);
	
	g_ConfigState = CS_Nowhere;
	SMCParser hParser = new SMCParser();
	char configPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/sgadmins.txt");
	SMC_SetReaders(hParser, SMC_NewSection, SMC_KeyValue, SMC_EndSection);
	ResetConfigGroup();
	SMCError err = hParser.ParseFile(configPath);
	
	if (err != SMCError_Okay)
	{
		LogError("Steam Group Admins: Warning! Error parsing configs/sgadmins.txt");
		ReplyToCommand(client, "Steam Group Admins: Warning! Error parsing configs/sgadmins.txt");
	}
	
	delete hParser;
	
	DoFullCheck();
	
	return Plugin_Handled;
}

public SMCResult SMC_KeyValue(Handle smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (value[0] == '\0')
		return SMCParse_Continue;
	
	switch (g_ConfigState)
	{
		case CS_InMembers:
		{
			if (!strcmp(key, "flags", false))
			{
				strcopy(g_ConfigGroup.conf_mGrpFlags, 32, value);
			}
			else if (!strcmp(key, "immunity", false))
			{
				g_ConfigGroup.conf_mGrpImmunity = StringToInt(value);
			}
			else if (!strcmp(key, "group", false))
			{
				g_ConfigGroup.conf_mGrpNames.PushString(value);
			}
		}
		case CS_InOfficers:
		{
			if (!strcmp(key, "flags", false))
			{
				strcopy(g_ConfigGroup.conf_oGrpFlags, 32, value);
			}
			else if (!strcmp(key, "immunity", false))
			{
				g_ConfigGroup.conf_oGrpImmunity = StringToInt(value);
			}
			else if (!strcmp(key, "group", false))
			{
				g_ConfigGroup.conf_mGrpNames.PushString(value);
			}
		}
		default:
		{
			LogError("KeyValue in invalid section");
			return SMCParse_HaltFail;
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult SMC_NewSection(Handle smc, const char[] name, bool opt_quotes)
{
	if (!strcmp(name, "SteamGroupAdmins", false))
	{
		return SMCParse_Continue;
	}
	
	switch (g_ConfigState)
	{
		case CS_Nowhere:  //entering group
		{
			g_ConfigGroup.conf_groupId = StringToInt(name);
			if (g_ConfigGroup.conf_groupId > 0)
			{
				g_ConfigState = CS_InGroup;
			}
			else
			{
				LogError("Invalid group \"%s\" in config", name);
				return SMCParse_HaltFail;
			}	
		}
		case CS_InGroup:
		{
			if (!strcmp(name, "members", false))
			{
				g_ConfigState = CS_InMembers;
				g_ConfigGroup.conf_mGrpNames = new ArrayList(ByteCountToCells(GROUP_NAME_LEN));
			}
			else if (!strcmp(name, "officers", false))
			{
				g_ConfigState = CS_InOfficers;
				g_ConfigGroup.conf_oGrpNames = new ArrayList(ByteCountToCells(GROUP_NAME_LEN));
			}
			else
			{
				LogError("Invalid section (\"%s\") in group. Should only be \"members\" or \"officers\".", name);
				return SMCParse_HaltFail;
			}
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult SMC_EndSection(Handle smc)
{
	switch(g_ConfigState)
	{
		case CS_InGroup:
		{
			// Finalize group
			SteamGroup group;
			group.SGgroupId = g_ConfigGroup.conf_groupId;
			group.SGmemberGrps = new ArrayList();
			group.SGofficerGrps = new ArrayList();
			
			if (g_ConfigGroup.conf_mGrpFlags[0] != '\0' || g_ConfigGroup.conf_mGrpImmunity > -1)
			{
				char grpname[GROUP_NAME_LEN];
				Format(grpname, sizeof(grpname), "%dmembers", g_ConfigGroup.conf_groupId);
				
				g_ConfigGroup.conf_mGrp = FindAdmGroup(grpname);
				if (g_ConfigGroup.conf_mGrp == INVALID_GROUP_ID)
				{
					g_ConfigGroup.conf_mGrp = CreateAdmGroup(grpname);
				}
				else
				{
					ResetAdmGroup(g_ConfigGroup.conf_mGrp);
				}
				
				SetAdmGroupAddFlagString(g_ConfigGroup.conf_mGrp, g_ConfigGroup.conf_mGrpFlags);
				
				if (g_ConfigGroup.conf_mGrpImmunity > -1)
				{
					SetAdmGroupImmunityLevel(g_ConfigGroup.conf_mGrp, g_ConfigGroup.conf_mGrpImmunity);
				}
				group.SGmemberGrps.Push(g_ConfigGroup.conf_mGrp);
			}
			
			if (g_ConfigGroup.conf_oGrpFlags[0] != '\0' || g_ConfigGroup.conf_oGrpImmunity > -1)
			{
				char grpname[GROUP_NAME_LEN];
				Format(grpname, sizeof(grpname), "%dofficers", g_ConfigGroup.conf_groupId);
				
				g_ConfigGroup.conf_oGrp = FindAdmGroup(grpname);
				if (g_ConfigGroup.conf_oGrp == INVALID_GROUP_ID)
				{
					g_ConfigGroup.conf_oGrp = CreateAdmGroup(grpname);
				}
				else
				{
					ResetAdmGroup(g_ConfigGroup.conf_oGrp);
				}
				
				SetAdmGroupAddFlagString(g_ConfigGroup.conf_oGrp, g_ConfigGroup.conf_oGrpFlags);
				
				if (g_ConfigGroup.conf_oGrpImmunity > -1)
				{
					SetAdmGroupImmunityLevel(g_ConfigGroup.conf_oGrp, g_ConfigGroup.conf_oGrpImmunity);
				}
				group.SGofficerGrps.Push(g_ConfigGroup.conf_oGrp);
			}
			
			int mcnt = 0;
			if (g_ConfigGroup.conf_mGrpNames != null)
			{
				mcnt = g_ConfigGroup.conf_mGrpNames.Length;
			}
			for (int i = 0; i < mcnt; i++)
			{
				char grpname[GROUP_NAME_LEN];
				g_ConfigGroup.conf_mGrpNames.GetString(i, grpname, sizeof(grpname));
				GroupId grp = FindAdmGroup(grpname);
				if (grp == INVALID_GROUP_ID)
				{
					grp = CreateAdmGroup(grpname);
				}
				group.SGmemberGrps.Push(grp);
			}
			
			int ocnt = 0;
			if (g_ConfigGroup.conf_oGrpNames != null)
			{
				ocnt = g_ConfigGroup.conf_oGrpNames.Length;
			}
			for (int i = 0; i < ocnt; i++)
			{
				char grpname[GROUP_NAME_LEN];
				g_ConfigGroup.conf_oGrpNames.GetString(i, grpname, sizeof(grpname));
				GroupId grp = FindAdmGroup(grpname);
				if (grp == INVALID_GROUP_ID)
				{
					grp = CreateAdmGroup(grpname);
				}
				group.SGofficerGrps.Push(grp);
			}
			
			g_SteamGroups.PushArray(group);
			ResetConfigGroup();
			g_ConfigState = CS_Nowhere;
		}
		case CS_InMembers, CS_InOfficers:
		{
			g_ConfigState = CS_InGroup;
		}
	}
}

void ResetConfigGroup()
{
	g_ConfigGroup.conf_groupId = 0;
	g_ConfigGroup.conf_mGrp = INVALID_GROUP_ID;
	g_ConfigGroup.conf_oGrp = INVALID_GROUP_ID;
	g_ConfigGroup.conf_mGrpFlags[0] = '\0';
	g_ConfigGroup.conf_mGrpImmunity = -1;
	g_ConfigGroup.conf_oGrpFlags[0] = '\0';
	g_ConfigGroup.conf_oGrpImmunity = -1;
	delete g_ConfigGroup.conf_mGrpNames;
	delete g_ConfigGroup.conf_oGrpNames;
}

void ResetAdmGroup(GroupId grp)
{
	SetAdmGroupImmunityLevel(grp, 0);
	for (int i = 0; i < AdminFlags_TOTAL; i++)
	{
		SetAdmGroupAddFlag(grp, view_as<AdminFlag>(i), false);
	}
}

void SetAdmGroupAddFlagString(GroupId grp, const char[] flags)
{
	for (int i = 0;; i++)
	{
		if (flags[i] == '\0')
			return;
		
		AdminFlag flag;
		if (FindFlagByChar(flags[i], flag))
		{
			SetAdmGroupAddFlag(grp, flag, true);
		}
	}
}
