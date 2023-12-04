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
new String:classname[6][] =
{
	"RIFLEMAN", "ASSAULT", "SUPPORT", "SNIPER", "MG", "ROCKET"
}
new bool:IsWhiteListed[MAXPLAYERS+1]
new bool:IsBlackListed[MAXPLAYERS+1]
new bool:PluginChanged = false

public OnPluginStart()
{
	RestClasses = CreateConVar("dod_tms_restrictclasses", "456", "<0/#######> = set classes to restrict until X players are on  -  0 to disable  -  1 Rifleman  -  2 Assault  -  3 Support  -  4 Sniper  -  5 MG  -  6 Rocket",_, true, 0.0)
	RestMinPlayers = CreateConVar("dod_tms_restrictminplayers", "6", "<#> = set min players needed to unrestrict restricted classes",_, true, 0.0)
	RemoveWeapons = CreateConVar("dod_tms_restrictremoveweapons", "456", "<0/#######> = set classes that get their primary weapons removed on death so they cannot be picked up by others  -  0 to disable  -  1 Rifleman  -  2 Assault  -  3 Support  -  4 Sniper  -  5 MG  -  6 Rocket",_, true, 0.0)
	BlockRespawnClass = CreateConVar("dod_tms_restrictrespawnblock", "2", "<1/2/0> = prevent immediate class change in spawnarea - 1 = simply block class change - 2 = simply ignore SpawnArea - 0 = disabled",_, true, 0.0, true, 2.0)
	ClientImmunity = CreateConVar("dod_tms_restrictimmunity", "1", "<1/0> = enable/disable Admins being immune from almost all actions",_, true, 0.0, true, 1.0)
	RestEnforceLimits = CreateConVar("dod_tms_restrictenforcelimits", "1", "<1/0> = enable/disable enforcing class restrictions",_, true, 0.0, true, 1.0)
	for(new i = 0; i < MAXCLASSES; i++)
	{
		RegAdminCmd(ClassCmd[i], cmd_ClassSelect, 0)
	}
	PrecacheSound("common/weapon_denyselect.wav")
	AutoExecConfig(true,"addon_dodtms_classrest", "dod_teammanager_source")
	LoadTranslations("dodtms_classrest.txt")
}

public Action:cmd_ClassSelect(client, args)
{
	new team = GetClientTeam(client)
	if(team == SPEC || team == UNASSIGNED)
	{
		return Plugin_Continue
	}
	new bool:RespawnBlockSlay = false
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

public Action:resetLimits(Handle:timer, any:cvarnumber)
{
	PluginChanged = true
	SetConVarInt(FindConVar(ClassLimitCvar[cvarnumber]),DefaultClassLimit[cvarnumber])
	return Plugin_Handled
}