//////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Addon - ClassRestrictions
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <dodtms_base>

#define MAXCLASSES 12

public Plugin:myinfo = 
{
	name = "[DoD TMS] Addon - Class Restrictions",
	author = "FeuerSturm, modif Micmacx",
	description = "ClassRestriction Addon for [DoD TMS]",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

new Handle:RestClasses = INVALID_HANDLE
new Handle:RestMinPlayers = INVALID_HANDLE
new Handle:RemoveWeapons = INVALID_HANDLE
new Handle:BlockRespawnClass = INVALID_HANDLE
new Handle:ClientImmunity = INVALID_HANDLE
new Handle:RestEnforceLimits = INVALID_HANDLE
new g_BlockSuicide[MAXPLAYERS+1]
new String:ClassLimitCvar[MAXCLASSES][] =
{
	"mp_limit_allies_rifleman", "mp_limit_allies_assault", "mp_limit_allies_support", "mp_limit_allies_sniper", "mp_limit_allies_mg", "mp_limit_allies_rocket",
	"mp_limit_axis_rifleman", "mp_limit_axis_assault", "mp_limit_axis_support", "mp_limit_axis_sniper", "mp_limit_axis_mg", "mp_limit_axis_rocket"
}
new DefaultClassLimit[MAXCLASSES]
new String:ClassCmd[MAXCLASSES][] =
{
	"cls_garand", "cls_tommy", "cls_bar", "cls_spring", "cls_30cal", "cls_bazooka",
	"cls_k98", "cls_mp40", "cls_mp44", "cls_k98s", "cls_mg42", "cls_pschreck"
}
new String:ClassAlliedWeap[MAXCLASSES-6][] =
{
	"weapon_garand", "weapon_thompson", "weapon_bar", "weapon_spring", "weapon_30cal", "weapon_bazooka"
}
new String:ClassAxisWeap[MAXCLASSES-6][] =
{
	"weapon_k98", "weapon_mp40", "weapon_mp44", "weapon_k98_scoped", "weapon_mg42", "weapon_pschreck"
}
new String:classname[6][] =
{
	"RIFLEMAN", "ASSAULT", "SUPPORT", "SNIPER", "MG", "ROCKET"
}
new String:WLFeature[] = { "classrestrict" }
new bool:IsWhiteListed[MAXPLAYERS+1]
new bool:IsBlackListed[MAXPLAYERS+1]
new PlayersOnServer
new bool:PluginChanged = false

public OnPluginStart()
{
	RestClasses = CreateConVar("dod_tms_restrictclasses", "45", "<0/#######> = set classes to restrict until X players are on  -  0 to disable  -  1 Rifleman  -  2 Assault  -  3 Support  -  4 Sniper  -  5 MG  -  6 Rocket",_, true, 0.0)
	RestMinPlayers = CreateConVar("dod_tms_restrictminplayers", "6", "<#> = set min players needed to unrestrict restricted classes",_, true, 0.0)
	RemoveWeapons = CreateConVar("dod_tms_restrictremoveweapons", "456", "<0/#######> = set classes that get their primary weapons removed on death so they cannot be picked up by others  -  0 to disable  -  1 Rifleman  -  2 Assault  -  3 Support  -  4 Sniper  -  5 MG  -  6 Rocket",_, true, 0.0)
	BlockRespawnClass = CreateConVar("dod_tms_restrictrespawnblock", "2", "<1/2/0> = prevent immediate class change in spawnarea - 1 = simply block class change - 2 = simply ignore SpawnArea - 0 = disabled",_, true, 0.0, true, 2.0)
	ClientImmunity = CreateConVar("dod_tms_restrictimmunity", "1", "<1/0> = enable/disable Admins being immune from almost all actions",_, true, 0.0, true, 1.0)
	RestEnforceLimits = CreateConVar("dod_tms_restrictenforcelimits", "1", "<1/0> = enable/disable enforcing class restrictions",_, true, 0.0, true, 1.0)
	HookEventEx("player_death", OnPlayerDeath, EventHookMode_Post)
	HookEventEx("player_hurt", OnPlayerHurt, EventHookMode_Post)
	for(new i = 0; i < MAXCLASSES; i++)
	{
		RegAdminCmd(ClassCmd[i], cmd_ClassSelect, 0)
		HookConVarChange(FindConVar(ClassLimitCvar[i]), UpdateClasslimits)
	}
	RegAdminCmd("cls_random", cmd_RandomClass, 0)
	RegAdminCmd("joinclass", cmd_joinClass, 0)
	RegConsoleCmd("kill", cmdKill)
	PrecacheSound("common/weapon_denyselect.wav")
	AutoExecConfig(true,"addon_dodtms_classrest", "dod_teammanager_source")
	LoadTranslations("dodtms_classrest.txt")
}

public UpdateClasslimits(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!PluginChanged && StringToInt(oldValue) != StringToInt(newValue))
	{
		CatchDefaultLimits()
		return
	}
	PluginChanged = false
}

public OnMapEnd()
{
	PlayersOnServer = (GetTeamClientCount(ALLIES) + GetTeamClientCount(AXIS))
}

public OnMapStart()
{
	CreateTimer(30.0, ResetPlayerCount, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE)
}

public Action:ResetPlayerCount(Handle:timer)
{
	PlayersOnServer = 0
	return Plugin_Handled
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
	g_BlockSuicide[client] = 0
}

public Action:cmdKill(client, args)
{
	if(IsPlayerAlive(client))
	{
		if(g_BlockSuicide[client] == 1)
		{
			return Plugin_Handled
		}
	}
	return Plugin_Continue
}

public Action:UnBlockSuicide(Handle:timer, any: client)
{
	g_BlockSuicide[client] = 0
	return Plugin_Handled
}

public OnDoDTMSDeleteCfg()
{
	decl String:configfile[256]
	Format(configfile, sizeof(configfile), "cfg/dod_teammanager_source/addon_dodtms_classrest.cfg")
	if(FileExists(configfile))
	{
		DeleteFile(configfile)
	}
}

public OnAllPluginsLoaded()
{
	CreateTimer(0.3, DoDTMSRunning)
}

public Action:DoDTMSRunning(Handle:timer)
{
	if(!LibraryExists("DoDTeamManagerSource"))
	{
		SetFailState("[DoD TMS] Base Plugin not found!")
		return Plugin_Handled
	}
	TMSRegAddon("C")
	return Plugin_Handled
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new RemWeapons = GetConVarInt(RemoveWeapons)
	if(RemWeapons != 0 && GetClientHealth(client) <= 0)
	{
		new PriWeapon = GetPlayerWeaponSlot(client, 0)
		if(PriWeapon != -1)
		{
			decl String:WeaponName[32]
			GetEdictClassname(PriWeapon, WeaponName, sizeof(WeaponName))
			decl String:RemWeaponString[32]
			IntToString(RemWeapons, RemWeaponString, sizeof(RemWeaponString))
			decl String:istr[2]
			for(new i = 1; i <= 6; i++)
			{
				IntToString(i, istr, sizeof(istr))
				if(StrContains(RemWeaponString, istr) != -1 && (strcmp(WeaponName, ClassAlliedWeap[i-1]) == 0 || strcmp(WeaponName, ClassAxisWeap[i-1]) == 0))
				{
					RemoveEdict(PriWeapon)
					return Plugin_Continue
				}
			}
		}
	}
	return Plugin_Continue
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new class = GetEntProp(client, Prop_Send, "m_iPlayerClass")
	new currteam = GetClientTeam(client)
	if(GetConVarInt(RestEnforceLimits) == 1 && !IsClientImmune(client) && class>=0)
	{
		decl String:Restricted[7]
		GetConVarString(RestClasses,Restricted,sizeof(Restricted))
		new classno = class+1
		new String:classnostr[2]
		IntToString(classno,classnostr,sizeof(classnostr))
		if(StrContains(Restricted,classnostr) != -1)
		{
			if((GetTeamClientCount(ALLIES) + GetTeamClientCount(AXIS)) < GetConVarInt(RestMinPlayers))
			{
				decl String:message[256]
				Format(message,sizeof(message),"%T", "Class Restricted", client, GetConVarInt(RestMinPlayers))
				TMSMessage(client, message)
				TMSChangeToTeam(client, currteam)
				TMSCenterMessage(client, message)
				return Plugin_Continue
			}
		}
		new clteamadd[4] =
		{
			0, 0, 0, 6
		}
		new currclass = (class + clteamadd[currteam])
		if(DefaultClassLimit[currclass] == -1)
		{
			return Plugin_Continue
		}
		else
		{
			new SameClass = 0
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == currteam)
				{
					new iclass = GetEntProp(i, Prop_Send, "m_iPlayerClass")
					if(iclass == class)
					{
						SameClass++
					}
				}
			}
			if(SameClass > DefaultClassLimit[currclass])
			{
				decl String:message[256]
				Format(message,sizeof(message),"%T", "Player ClassFull", client)
				TMSMessage(client, message)
				TMSChangeToTeam(client, currteam)
				TMSCenterMessage(client, message)
				return Plugin_Continue
			}
		}	
	}
	return Plugin_Continue
}

public OnConfigsExecuted()
{
	CatchDefaultLimits()
}

public CatchDefaultLimits()
{
	for(new i = 0; i < MAXCLASSES; i++)
	{
		DefaultClassLimit[i] = GetConVarInt(FindConVar(ClassLimitCvar[i]))
	}
}

public Action:resetLimits(Handle:timer, any:cvarnumber)
{
	PluginChanged = true
	SetConVarInt(FindConVar(ClassLimitCvar[cvarnumber]),DefaultClassLimit[cvarnumber])
	return Plugin_Handled
}

public Action:cmd_RandomClass(client, args)
{
	new team = GetClientTeam(client)
	if(team == SPEC || team == UNASSIGNED)
	{
		return Plugin_Continue
	}
	if(!IsClientImmune(client))
	{
		if(IsPlayerAlive(client))
		{
			if(TMSGetClientSpawnArea(client, 1000) && GetConVarInt(BlockRespawnClass) != 0)
			{
				decl String:sound[256]
				Format(sound,sizeof(sound),"common/weapon_denyselect.wav")
				TMSSound(client, sound)
				decl String:message[256]
				Format(message,sizeof(message),"%T", "No SpawnClass", client)
				TMSMessage(client, message)
				g_BlockSuicide[client] = 1
				CreateTimer(0.1, UnBlockSuicide, client, TIMER_FLAG_NO_MAPCHANGE)
				return Plugin_Handled
			}
		}
		if((GetTeamClientCount(ALLIES) + GetTeamClientCount(AXIS)) < GetConVarInt(RestMinPlayers) && PlayersOnServer < GetConVarInt(RestMinPlayers))
		{
			decl String:sound[256]
			Format(sound,sizeof(sound),"common/weapon_denyselect.wav")
			TMSSound(client, sound)
			decl String:message[256]
			Format(message,sizeof(message),"%T", "Class Restricted", client, GetConVarInt(RestMinPlayers))
			TMSMessage(client, message)
			g_BlockSuicide[client] = 1
			CreateTimer(0.1, UnBlockSuicide, client, TIMER_FLAG_NO_MAPCHANGE)
			return Plugin_Handled
		}
	}
	return Plugin_Continue
}

public Action:cmd_ClassSelect(client, args)
{
	new team = GetClientTeam(client)
	if(team == SPEC || team == UNASSIGNED)
	{
		return Plugin_Continue
	}
	new bool:RespawnBlockSlay = false
	if(!IsClientImmune(client))
	{
		if(IsPlayerAlive(client))
		{
			if(TMSGetClientSpawnArea(client, 1000))
			{
				new RespawnBlock = GetConVarInt(BlockRespawnClass)
				if(RespawnBlock == 1)
				{
					decl String:sound[256]
					Format(sound,sizeof(sound),"common/weapon_denyselect.wav")
					TMSSound(client, sound)
					decl String:message[256]
					Format(message,sizeof(message),"%T", "No SpawnClass", client)
					TMSMessage(client, message)
					g_BlockSuicide[client] = 1
					CreateTimer(0.1, UnBlockSuicide, client, TIMER_FLAG_NO_MAPCHANGE)
					return Plugin_Handled
				}
				else if(RespawnBlock == 2)
				{
					RespawnBlockSlay = true
				}
			}
		}
	}
	decl String:cls_cmd[13]
	GetCmdArg(0,cls_cmd,sizeof(cls_cmd))
	new cvarnumber
	for(new i = 0; i < MAXCLASSES; i++)
	{
		if(StrEqual(cls_cmd, ClassCmd[i]))
		{
			new clteamsub[4] =
			{
				0, 0, 0, 6
			}
			decl String:Restricted[7]
			GetConVarString(RestClasses,Restricted,sizeof(Restricted))
			new classno = i-clteamsub[team]+1
			new String:classnostr[2]
			IntToString(classno,classnostr,sizeof(classnostr))
			if(StrContains(Restricted,classnostr) != -1)
			{
				if(!IsClientImmune(client))
				{
					if((GetTeamClientCount(ALLIES) + GetTeamClientCount(AXIS)) < GetConVarInt(RestMinPlayers) && PlayersOnServer < GetConVarInt(RestMinPlayers))
					{
						decl String:sound[256]
						Format(sound,sizeof(sound),"common/weapon_denyselect.wav")
						TMSSound(client, sound)
						decl String:message[256]
						Format(message,sizeof(message),"%T", "Class Restricted", client, GetConVarInt(RestMinPlayers))
						TMSMessage(client, message)
						g_BlockSuicide[client] = 1
						CreateTimer(0.1, UnBlockSuicide, client, TIMER_FLAG_NO_MAPCHANGE)
						ChangeClientTeam(client, SPEC)
						ChangeClientTeam(client, team)
						return Plugin_Handled
					}
				}
			}
			cvarnumber = i
			if(RespawnBlockSlay)
			{
				new desclass = classno-1
				new class = GetEntProp(client, Prop_Send, "m_iPlayerClass")
				if(IsClassAvailable(client, team, class, desclass, cvarnumber))
				{
					decl String:respawnmessage[256]
					Format(respawnmessage, sizeof(respawnmessage), "%T %T", "RespawnAs", client, classname[desclass], client)
					TMSMessage(client, respawnmessage)
					SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", desclass)
					QueryClientConVar(client, "hud_classautokill", ConVarQueryFinished:SuicideCatch)
					return Plugin_Handled
				}
				if(class != desclass)
				{
					return Plugin_Continue
				}
				return Plugin_Handled
			}
			if(IsClientImmune(client))
			{
				if(GetConVarInt(FindConVar(ClassLimitCvar[cvarnumber])) != -1)
				{
					PluginChanged = true
					SetConVarInt(FindConVar(ClassLimitCvar[cvarnumber]),-1)
					CreateTimer(0.0, resetLimits, cvarnumber)
				}
			}
		}
	}
	return Plugin_Continue
}

public SuicideCatch(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName1[], const String:cvarValue1[])
{
	new suicide = StringToInt(cvarValue1)
	if(suicide == 1)
	{
		TMSSlay(client)
	}
}

public Action:cmd_joinClass(client, args)
{
	decl String:message[256]
	Format(message,sizeof(message),"%T", "No CmdJoinclass", client)
	TMSMessage(client, message)
	return Plugin_Handled
}

stock bool:IsClassAvailable(client, team, class, desclass, cvarnumber)
{
	new SameClass = 0
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team)
		{
			new iclass = GetEntProp(i, Prop_Send, "m_iPlayerClass")
			if(iclass == desclass)
			{
				SameClass++
			}
		}
	}
	if((SameClass >= DefaultClassLimit[cvarnumber] && DefaultClassLimit[cvarnumber] != -1) || class == desclass)
	{
		return false
	}
	else
	{
		return true
	}
}

stock bool:IsClientImmune(client)
{
	if((GetUserAdmin(client) != INVALID_ADMIN_ID || IsWhiteListed[client]) && !IsBlackListed[client] && GetConVarInt(ClientImmunity) == 1)
	{
		return true
	}
	else
	{
		return false
	}
}