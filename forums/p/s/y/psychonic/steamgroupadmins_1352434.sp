#pragma semicolon 1

#include <sourcemod>
#include <steamtools>

#define VERSION "1.2.0"

public Plugin:myinfo = 
{
	name = "Steam Group Admins",
	author = "psychonic",
	description = "Lookup admin status via steam community group",
	version = VERSION,
	url = "http://www.nicholashastings.com/"
};

new bool:g_bPlayerProcessed[MAXPLAYERS+1] = { false, ... };
new g_PlayerLastCheck[MAXPLAYERS+1] = { 0, ... };
new g_bPlayerAuthed[MAXPLAYERS+1] = { false, ... };
new Handle:g_SteamGroups = INVALID_HANDLE;

enum SteamGroup {
	SGgroupId,
	Handle:SGofficerGrps,
	Handle:SGmemberGrps,
};
#define SGSIZE 3

#define GROUP_NAME_LEN 256

enum SGConfigInfo {
	conf_groupId,
	GroupId:conf_mGrp,
	String:conf_mGrpFlags[32],
	conf_mGrpImmunity,
	GroupId:conf_oGrp,
	String:conf_oGrpFlags[32],
	conf_oGrpImmunity,
	Handle:conf_mGrpNames,
	Handle:conf_oGrpNames
}
#define CONFIGSIZE 23

public OnPluginStart()
{
	CreateConVar("sgadmins_version", VERSION, _, FCVAR_NOTIFY);
	
	RegAdminCmd("sm_sgadmins_reload", ParseConfig, ADMFLAG_ROOT, "Reloads Steam Group Admins config file");
	
	ParseConfig(0,0);
	
	CreateTimer(5.0, RecheckPlayers, _, TIMER_REPEAT);
}

public Action:RecheckPlayers(Handle:hTimer)
{
	DoFullCheck();
	
	return Plugin_Continue;
}

DoFullCheck()
{
	new time = GetTime()-5;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_bPlayerProcessed[i] || !g_bPlayerAuthed[i] || g_PlayerLastCheck[i] > time)
			continue;
		
		LookupPlayerGroups(i);
	}
}

public OnClientPostAdminCheck(client)
{
	if (IsFakeClient(client))
		return;
	
	g_bPlayerAuthed[client] = true;
	
	LookupPlayerGroups(client);
}

public OnClientDisconnect(client)
{
	g_bPlayerAuthed[client] = false;
	g_bPlayerProcessed[client] = false;
	g_PlayerLastCheck[client] = 0;
}

public OnRebuildAdminCache(AdminCachePart:part)
{
	ParseConfig(0,0);
}

public LookupPlayerGroups(client)
{
	new cnt = GetArraySize(g_SteamGroups);
	for (new i = 0; i < cnt; i++)
	{
		decl group[SteamGroup];
		GetArrayArray(g_SteamGroups, i, group[0], sizeof(group));
		Steam_RequestGroupStatus(client, group[SGgroupId]);
		g_PlayerLastCheck[client] = GetTime();
	}
}

public Steam_GroupStatusResult(client, groupAccountID, bool:groupMember, bool:groupOfficer)
{
	if (client <= 0 || !IsClientInGame(client))
		return;
	
	g_bPlayerProcessed[client] = true;
	
	if (!groupMember)
		return;
	
	decl group[SteamGroup];
	
	if (!GetSteamGroupById(groupAccountID, group))
	{
		return;
	}
	
	new AdminId:admid = GetUserAdmin(client);
	
	new mgroupcnt = GetArraySize(group[SGmemberGrps]);
	if (mgroupcnt > 0)
	{
		if (admid == INVALID_ADMIN_ID)
		{
			decl String:auth[32];
			GetClientAuthString(client, auth, sizeof(auth));
			admid = CreateAdmin(auth);
			SetUserAdmin(client, admid, true);
		}
		
		for (new i = 0; i < mgroupcnt; i++)
		{
			new GroupId:id = GroupId:GetArrayCell(group[SGmemberGrps], i);
			AdminInheritGroup(admid, id);
		}
	}
	
	if (!groupOfficer)
		return;
	
	new ogroupcnt = GetArraySize(group[SGofficerGrps]);
	if (ogroupcnt > 0)
	{
		if (admid == INVALID_ADMIN_ID)
		{
			decl String:auth[32];
			GetClientAuthString(client, auth, sizeof(auth));
			admid = CreateAdmin(auth);
			SetUserAdmin(client, admid, true);
		}
		
		for (new i = 0; i < ogroupcnt; i++)
		{
			new GroupId:id = GroupId:GetArrayCell(group[SGofficerGrps], i);
			AdminInheritGroup(admid, id);
		}
	}
}

GetSteamGroupById(id, buffer[SteamGroup])
{
	new cnt = GetArraySize(g_SteamGroups);
	for (new i = 0; i < cnt; i++)
	{
		decl group[SteamGroup];
		GetArrayArray(g_SteamGroups, i, group[0], sizeof(group));
		if (group[SGgroupId] == id)
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

new ConfigState:g_ConfigState;
new g_ConfigGroup[SGConfigInfo];

public Action:ParseConfig(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
		g_bPlayerProcessed[i] = false;
	
	if (g_SteamGroups != INVALID_HANDLE)
	{
		new cnt = GetArraySize(g_SteamGroups);
		for (new i = 0; i < cnt; i++)
		{
			decl group[SteamGroup];
			GetArrayArray(g_SteamGroups, i, group[0], SGSIZE);
			if (group[SGofficerGrps] != INVALID_HANDLE)
				CloseHandle(group[SGofficerGrps]);
			if (group[SGmemberGrps] != INVALID_HANDLE)
				CloseHandle(group[SGmemberGrps]);
		}
		CloseHandle(g_SteamGroups);
	}
	g_SteamGroups = CreateArray(SGSIZE);
	
	g_ConfigState = CS_Nowhere;
	new Handle:hParser = SMC_CreateParser();
	decl String:configPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/sgadmins.txt");
	SMC_SetReaders(hParser, SMC_NewSection, SMC_KeyValue, SMC_EndSection);
	ResetConfigGroup();
	new SMCError:err = SMC_ParseFile(hParser, configPath);
	if (err != SMCError_Okay)
	{
		LogError("Steam Group Admins: Warning! Error parsing configs/sgadmins.txt");
		ReplyToCommand(client, "Steam Group Admins: Warning! Error parsing configs/sgadmins.txt");
	}
	if (hParser != INVALID_HANDLE)
	{
		CloseHandle(hParser);
	}
	
	DoFullCheck();
	
	return Plugin_Handled;
}

public SMCResult:SMC_KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if (value[0] == '\0')
		return SMCParse_Continue;
	
	switch (g_ConfigState)
	{
		case CS_InMembers:
		{
			if (!strcmp(key, "flags", false))
			{
				strcopy(g_ConfigGroup[conf_mGrpFlags], 32, value);
			}
			else if (!strcmp(key, "immunity", false))
			{
				g_ConfigGroup[conf_mGrpImmunity] = StringToInt(value);
			}
			else if (!strcmp(key, "group", false))
			{
				PushArrayString(g_ConfigGroup[conf_mGrpNames], value);
			}
		}
		case CS_InOfficers:
		{
			if (!strcmp(key, "flags", false))
			{
				strcopy(g_ConfigGroup[conf_oGrpFlags], 32, value);
			}
			else if (!strcmp(key, "immunity", false))
			{
				g_ConfigGroup[conf_oGrpImmunity] = StringToInt(value);
			}
			else if (!strcmp(key, "group", false))
			{
				PushArrayString(g_ConfigGroup[conf_oGrpNames], value);
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

public SMCResult:SMC_NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	if (!strcmp(name, "SteamGroupAdmins", false))
	{
		return SMCParse_Continue;
	}
	
	switch (g_ConfigState)
	{
		case CS_Nowhere:  //entering group
		{
			g_ConfigGroup[conf_groupId] = StringToInt(name);
			if (g_ConfigGroup[conf_groupId] > 0)
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
				g_ConfigGroup[conf_mGrpNames] = CreateArray(ByteCountToCells(GROUP_NAME_LEN));
			}
			else if (!strcmp(name, "officers", false))
			{
				g_ConfigState = CS_InOfficers;
				g_ConfigGroup[conf_oGrpNames] = CreateArray(ByteCountToCells(GROUP_NAME_LEN));
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

public SMCResult:SMC_EndSection(Handle:smc)
{
	switch(g_ConfigState)
	{
		case CS_InGroup:
		{
			// Finalize group
			decl group[SteamGroup];
			group[SGgroupId] = g_ConfigGroup[conf_groupId];
			group[SGmemberGrps] = CreateArray();
			group[SGofficerGrps] = CreateArray();
			
			if (g_ConfigGroup[conf_mGrpFlags][0] != '\0' || g_ConfigGroup[conf_mGrpImmunity] > -1)
			{
				decl String:grpname[GROUP_NAME_LEN];
				Format(grpname, sizeof(grpname), "%dmembers", g_ConfigGroup[conf_groupId]);
				
				g_ConfigGroup[conf_mGrp] = FindAdmGroup(grpname);
				if (g_ConfigGroup[conf_mGrp] == INVALID_GROUP_ID)
				{
					g_ConfigGroup[conf_mGrp] = CreateAdmGroup(grpname);
				}
				else
				{
					ResetAdmGroup(g_ConfigGroup[conf_mGrp]);
				}
				
				SetAdmGroupAddFlagString(g_ConfigGroup[conf_mGrp], g_ConfigGroup[conf_mGrpFlags]);
				
				if (g_ConfigGroup[conf_mGrpImmunity] > -1)
				{
					SetAdmGroupImmunityLevel(g_ConfigGroup[conf_mGrp], g_ConfigGroup[conf_mGrpImmunity]);
				}
				PushArrayCell(group[SGmemberGrps], g_ConfigGroup[conf_mGrp]);
			}
			
			if (g_ConfigGroup[conf_oGrpFlags][0] != '\0' || g_ConfigGroup[conf_oGrpImmunity] > -1)
			{
				decl String:grpname[GROUP_NAME_LEN];
				Format(grpname, sizeof(grpname), "%dofficers", g_ConfigGroup[conf_groupId]);
				
				g_ConfigGroup[conf_oGrp] = FindAdmGroup(grpname);
				if (g_ConfigGroup[conf_oGrp] == INVALID_GROUP_ID)
				{
					g_ConfigGroup[conf_oGrp] = CreateAdmGroup(grpname);
				}
				else
				{
					ResetAdmGroup(g_ConfigGroup[conf_oGrp]);
				}
				
				SetAdmGroupAddFlagString(g_ConfigGroup[conf_oGrp], g_ConfigGroup[conf_oGrpFlags]);
				
				if (g_ConfigGroup[conf_oGrpImmunity] > -1)
				{
					SetAdmGroupImmunityLevel(g_ConfigGroup[conf_oGrp], g_ConfigGroup[conf_oGrpImmunity]);
				}
				PushArrayCell(group[SGofficerGrps], g_ConfigGroup[conf_oGrp]);
			}
			
			new mcnt = 0;
			if (g_ConfigGroup[conf_mGrpNames] != INVALID_HANDLE)
			{
				mcnt = GetArraySize(g_ConfigGroup[conf_mGrpNames]);
			}
			for (new i = 0; i < mcnt; i++)
			{
				decl String:grpname[GROUP_NAME_LEN];
				GetArrayString(g_ConfigGroup[conf_mGrpNames], i, grpname, sizeof(grpname));
				new GroupId:grp = FindAdmGroup(grpname);
				if (grp == INVALID_GROUP_ID)
				{
					grp = CreateAdmGroup(grpname);
				}
				PushArrayCell(group[SGmemberGrps], grp);
			}
			
			new ocnt = 0;
			if (g_ConfigGroup[conf_oGrpNames] != INVALID_HANDLE)
			{
				ocnt = GetArraySize(g_ConfigGroup[conf_oGrpNames]);
			}
			for (new i = 0; i < ocnt; i++)
			{
				decl String:grpname[GROUP_NAME_LEN];
				GetArrayString(g_ConfigGroup[conf_oGrpNames], i, grpname, sizeof(grpname));
				new GroupId:grp = FindAdmGroup(grpname);
				if (grp == INVALID_GROUP_ID)
				{
					grp = CreateAdmGroup(grpname);
				}
				PushArrayCell(group[SGofficerGrps], grp);
			}
			
			PushArrayArray(g_SteamGroups, group[0]);
			ResetConfigGroup();
			g_ConfigState = CS_Nowhere;
		}
		case CS_InMembers, CS_InOfficers:
		{
			g_ConfigState = CS_InGroup;
		}
	}
}

ResetConfigGroup()
{
	g_ConfigGroup[conf_groupId] = 0;
	g_ConfigGroup[conf_mGrp] = INVALID_GROUP_ID;
	g_ConfigGroup[conf_oGrp] = INVALID_GROUP_ID;
	g_ConfigGroup[conf_mGrpFlags][0] = '\0';
	g_ConfigGroup[conf_mGrpImmunity] = -1;
	g_ConfigGroup[conf_oGrpFlags][0] = '\0';
	g_ConfigGroup[conf_oGrpImmunity] = -1;
	if (g_ConfigGroup[conf_mGrpNames] != INVALID_HANDLE)
	{
		CloseHandle(g_ConfigGroup[conf_mGrpNames]);
		g_ConfigGroup[conf_mGrpNames] = INVALID_HANDLE;
	}
	
	if (g_ConfigGroup[conf_oGrpNames] != INVALID_HANDLE)
	{
		CloseHandle(g_ConfigGroup[conf_oGrpNames]);
		g_ConfigGroup[conf_oGrpNames] = INVALID_HANDLE;
	}
}

ResetAdmGroup(GroupId:grp)
{
	SetAdmGroupImmunityLevel(grp, 0);
	for (new i = 0; i < AdminFlags_TOTAL; i++)
	{
		SetAdmGroupAddFlag(grp, AdminFlag:i, false);
	}
}

SetAdmGroupAddFlagString(GroupId:grp, const String:flags[])
{
	for (new i = 0;; i++)
	{
		if (flags[i] == '\0')
			return;
		
		new AdminFlag:flag;
		if (FindFlagByChar(flags[i], flag))
		{
			SetAdmGroupAddFlag(grp, flag, true);
		}
	}
}
