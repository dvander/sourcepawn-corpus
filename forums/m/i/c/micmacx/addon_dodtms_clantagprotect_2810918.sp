//////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Addon - ClanTag Protection
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <dodtms_base>

public Plugin:myinfo = 
{
	name = "[DoD TMS] Addon - ClanTag Protection",
	author = "FeuerSturm, modif Micmacx",
	description = "Addon - ClanTag Protection for [DoD TMS]",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

new Handle:ClanTag = INVALID_HANDLE
new Handle:ForceClanTag = INVALID_HANDLE
new Handle:ForceClanTagPos = INVALID_HANDLE
new Handle:ClanTagPunishAction = INVALID_HANDLE
new Handle:ClanTagBanTime = INVALID_HANDLE
new bool:g_PluginChangedName[MAXPLAYERS+1]
new String:WLFeature[] = { "clantagprot" }
new bool:IsWhiteListed[MAXPLAYERS+1]
new bool:IsBlackListed[MAXPLAYERS+1]

public OnPluginStart()
{
	HookEvent("player_changename", OnClientChangeName, EventHookMode_Pre)
	ClanTag = CreateConVar("dod_tms_clantagprotect", "[Clan]", "set your ClanTag that you want to protect from being used by public players", _)
	ClanTagPunishAction = CreateConVar("dod_tms_clantagpunishment", "0", "<0/1/2> set punishment for clantag violation  -  0 = only rename player  -  1 = kick player  -  2 = ban player", _, true, 0.0, true, 2.0)
	ClanTagBanTime = CreateConVar("dod_tms_clantagbantime", "1440", "<0/#> set time in minutes to ban offenders (punishment 2 ONLY)  -  0 = permanent", _, true, 0.0)
	ForceClanTag = CreateConVar("dod_tms_forceclantag", "0", "<1/0> enable/disable forcing admins with Kick-Access to use the clantag  -  Root-Admins excluded!", _, true, 0.0, true, 1.0)
	ForceClanTagPos = CreateConVar("dod_tms_forceclantagpos", "1", "<1/2> set position of ClanTag when forcing admins to use it  -  1 = before Nickname  -  2 = after Nickname", _, true, 1.0, true, 2.0)
	LoadTranslations("dodtms_clantagprotect.txt")
	AutoExecConfig(true,"addon_dodtms_clantagprotect", "dod_teammanager_source")
}

public OnAllPluginsLoaded()
{
	CreateTimer(0.8, DoDTMSRunning)
}

public Action:DoDTMSRunning(Handle:timer)
{
	if(!LibraryExists("DoDTeamManagerSource"))
	{
		SetFailState("[DoD TMS] Base Plugin not found!")
		return Plugin_Handled
	}
	TMSRegAddon("H")
	return Plugin_Handled
}

public OnDoDTMSDeleteCfg()
{
	decl String:configfile[256]
	Format(configfile, sizeof(configfile), "cfg/dod_teammanager_source/addon_dodtms_clantagprotect.cfg")
	if(FileExists(configfile))
	{
		DeleteFile(configfile)
	}
}

public OnClientPostAdminCheck(client)
{
	if(TMSIsWhiteListed(client, WLFeature))
	{
		IsWhiteListed[client] = true
	}
	else
	{
		IsWhiteListed[client] = false
	}
	if(TMSIsBlackListed(client, WLFeature))
	{
		IsBlackListed[client] = true
	}
	else
	{
		IsBlackListed[client] = false
	}
	g_PluginChangedName[client] = false
	decl String:clientname[MAX_NAME_LENGTH]
	GetClientName(client, clientname, sizeof(clientname))
	decl String:ProtectedTag[MAX_NAME_LENGTH]
	GetConVarString(ClanTag, ProtectedTag, sizeof(ProtectedTag))
	if(!IsClientImmune(client) && IsClientConnected(client))
	{
		if(StrContains(clientname, ProtectedTag, false) != -1)
		{
			decl String:message[256]
			if(GetConVarInt(ClanTagPunishAction) == 0)
			{
				if(ReplaceString(clientname, sizeof(clientname), ProtectedTag, "", false) > 0)
				{
					new Handle:PlayerInfo = CreateDataPack()
					WritePackCell(PlayerInfo, client)
					WritePackString(PlayerInfo, ProtectedTag)
					WritePackString(PlayerInfo, clientname)
					CreateTimer(0.0, ResetName, PlayerInfo, TIMER_FLAG_NO_MAPCHANGE)
				}
				else
				{
					Format(message, sizeof(message), "%T", "ClanTag Kick", client, ProtectedTag)
					TMSKick(client, message)
				}
			}
			else if(GetConVarInt(ClanTagPunishAction) == 1)
			{
				Format(message, sizeof(message), "%T", "ClanTag Kick", client, ProtectedTag)
				TMSKick(client, message)
			}
			else if(GetConVarInt(ClanTagPunishAction) == 2)
			{
				Format(message, sizeof(message), "%T", "ClanTag Kick", client, ProtectedTag)
				TMSBan(client, GetConVarInt(ClanTagBanTime), message)
			}
		}
	}
	if(IsClientImmune(client) && IsClientConnected(client) && GetConVarInt(ForceClanTag) == 1)
	{
		new AdminId:adminid = GetUserAdmin(client)
		if(GetAdminFlag(adminid, Admin_Kick, Access_Effective) && !GetAdminFlag(adminid, Admin_Root, Access_Effective))
		{
			if(StrContains(clientname, ProtectedTag, false) == -1)
			{
				decl String:Clanname[32]
				if(GetConVarInt(ForceClanTagPos) == 1)
				{
					Format(Clanname, sizeof(Clanname), "%s %s", ProtectedTag, clientname)
				}
				else
				{
					Format(Clanname, sizeof(Clanname), "%s %s", clientname, ProtectedTag)
				}
				new Handle:PlayerInfo = CreateDataPack()
				WritePackCell(PlayerInfo, client)
				WritePackString(PlayerInfo, Clanname)
				WritePackString(PlayerInfo, ProtectedTag)
				WritePackString(PlayerInfo, clientname)
				CreateTimer(0.0, AddClanTag, PlayerInfo, TIMER_FLAG_NO_MAPCHANGE)
			}
		}
	}
}

public Action:OnClientChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(g_PluginChangedName[client])
	{
		g_PluginChangedName[client] = false
		dontBroadcast = true
		return Plugin_Changed
	}
	decl String:clientoldname[MAX_NAME_LENGTH], String:clientnewname[MAX_NAME_LENGTH]
	GetEventString(event, "oldname", clientoldname, sizeof(clientoldname))
	GetEventString(event, "newname", clientnewname, sizeof(clientnewname))
	decl String:ProtectedTag[MAX_NAME_LENGTH]
	GetConVarString(ClanTag, ProtectedTag, sizeof(ProtectedTag))
	if(!IsClientImmune(client) && IsClientInGame(client) && IsClientConnected(client))
	{
		if(StrContains(clientnewname, ProtectedTag, false) != -1)
		{
			decl String:message[256]
			if(GetConVarInt(ClanTagPunishAction) == 0)
			{
				new Handle:PlayerInfo = CreateDataPack()
				WritePackCell(PlayerInfo, client)
				WritePackString(PlayerInfo, ProtectedTag)
				WritePackString(PlayerInfo, clientoldname)
				CreateTimer(0.0, ResetName, PlayerInfo, TIMER_FLAG_NO_MAPCHANGE)
				dontBroadcast = true
				return Plugin_Changed
			}
			else if(GetConVarInt(ClanTagPunishAction) == 1)
			{
				Format(message, sizeof(message), "%T", "ClanTag Kick", client, ProtectedTag)
				TMSKick(client, message)
				dontBroadcast = true
				return Plugin_Changed
			}
			else if(GetConVarInt(ClanTagPunishAction) == 2)
			{
				Format(message, sizeof(message), "%T", "ClanTag Kick", client, ProtectedTag)
				TMSBan(client, GetConVarInt(ClanTagBanTime), message)
				dontBroadcast = true
				return Plugin_Changed
			}
		}
	}
	if(IsClientImmune(client) && IsClientInGame(client) && IsClientConnected(client) && GetConVarInt(ForceClanTag) == 1)
	{
		new AdminId:adminid = GetUserAdmin(client)
		if(GetAdminFlag(adminid, Admin_Kick, Access_Effective) && !GetAdminFlag(adminid, Admin_Root, Access_Effective))
		{
			if(StrContains(clientnewname, ProtectedTag, false) == -1)
			{
				decl String:Clanname[32]
				if(GetConVarInt(ForceClanTagPos) == 1)
				{
					Format(Clanname, sizeof(Clanname), "%s %s", ProtectedTag, clientnewname)
				}
				else
				{
					Format(Clanname, sizeof(Clanname), "%s %s", clientnewname, ProtectedTag)
				}
				new Handle:PlayerInfo = CreateDataPack()
				WritePackCell(PlayerInfo, client)
				WritePackString(PlayerInfo, Clanname)
				WritePackString(PlayerInfo, ProtectedTag)
				WritePackString(PlayerInfo, clientnewname)
				CreateTimer(0.0, AddClanTag, PlayerInfo, TIMER_FLAG_NO_MAPCHANGE)
				dontBroadcast = true
				return Plugin_Changed
			}
		}
	}
	return Plugin_Continue
}

public Action:AddClanTag(Handle:timer, Handle:PlayerInfo)
{
	ResetPack(PlayerInfo)
	new client = ReadPackCell(PlayerInfo)
	decl String:Clanname[32]
	ReadPackString(PlayerInfo, Clanname, sizeof(Clanname))
	decl String:ProtectedTag[32]
	ReadPackString(PlayerInfo, ProtectedTag, sizeof(ProtectedTag))
	decl String:clientnewname[32]
	ReadPackString(PlayerInfo, clientnewname, sizeof(clientnewname))
	CloseHandle(PlayerInfo)
	if(IsClientInGame(client) && IsClientConnected(client))
	{
		g_PluginChangedName[client] = true
		SetClientInfo(client, "name", Clanname)
		decl String:message[256]
		Format(message, sizeof(message), "%T", "ClanTag Forced", client, clientnewname, ProtectedTag)
		TMSMessage(client, message)
	}
	return Plugin_Handled
}

public Action:ResetName(Handle:timer, Handle:PlayerInfo)
{
	ResetPack(PlayerInfo)
	new client = ReadPackCell(PlayerInfo)
	decl String:ProtectedTag[32]
	ReadPackString(PlayerInfo, ProtectedTag, sizeof(ProtectedTag))
	decl String:clientoldname[32]
	ReadPackString(PlayerInfo, clientoldname, sizeof(clientoldname))
	CloseHandle(PlayerInfo)
	if(IsClientInGame(client) && IsClientConnected(client))
	{
		g_PluginChangedName[client] = true
		SetClientInfo(client, "name", clientoldname)
		decl String:message[256]
		Format(message, sizeof(message), "%T", "ClanTag NoAccess", client, clientoldname, ProtectedTag)
		TMSMessage(client, message)
	}
	return Plugin_Handled
}

stock bool:IsClientImmune(client)
{
	if((GetUserAdmin(client) != INVALID_ADMIN_ID || IsWhiteListed[client]) && !IsBlackListed[client])
	{
		return true
	}
	else
	{
		return false
	}
}