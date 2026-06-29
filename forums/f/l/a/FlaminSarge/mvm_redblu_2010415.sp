#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sendproxy>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION		"1.0"

public Plugin:myinfo =
{
	name			= "[TF2] RED+BLU vs Machine",
	author			= "FlaminSarge",
	description	= "Changes MvM so that it's RED and BLU versus the robots, not just RED",
	version		= PLUGIN_VERSION,
	url				= "http://forums.alliedmods.net/showthread.php?t=223208"
};

new iSetTeam[MAXPLAYERS + 1] = { -1, ... };
new Handle:hSyncHud;
public OnMapStart()
{
	if (IsMvM(true))
		CreateTimer(0.3, Timer_MoneyCheck, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}
stock bool:IsMvM(bool:forceRecalc = false)
{
	static bool:found = false;
	static bool:ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}
public OnPluginStart()
{
	CreateConVar("mvm_redblu_version", PLUGIN_VERSION, "[TF2] RED+BLU vs Machine version", FCVAR_NOTIFY|FCVAR_PLUGIN);
	LoadTranslations("common.phrases");
	RegAdminCmd("mvm_myteam", MyTeam, 0);
	hSyncHud = CreateHudSynchronizer();
	//cvars for bot teams, etc, to go here
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		iSetTeam[client] = IsFakeClient(client) ? 0 : GetRandomInt(2, 3);
		SendProxy_Hook(client, "m_nSkin", Prop_Int, SkinProxy);
		SendProxy_Hook(client, "m_iTeamNum", Prop_Int, TeamProxyClient);
	}
	HookEvent("player_builtobject", player_builtobject);
	HookEvent("player_spawn", player_spawn);
}
public Action:Timer_MoneyCheck(Handle:timer)
{
	static lastMoney[MAXPLAYERS + 1];
	if (!IsMvM()) return Plugin_Stop;
	SetHudTextParams(0.185, 0.92, 10000.0, 235, 235, 235, 255);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			lastMoney[client] = 0;
			continue;
		}
		if (IsFakeClient(client)) continue;
		new money = iSetTeam[client] == 3 ? GetEntProp(client, Prop_Send, "m_nCurrency") : 0;
		if (lastMoney[client] != money)
		{
			if (iSetTeam[client] == 3)
			{
				ShowSyncHudText(client, hSyncHud, "$%d", money);
				lastMoney[client] = money;
			}
			else
			{
				ClearSyncHud(client, hSyncHud);
				lastMoney[client] = 0;
			}
		}
	}
	return Plugin_Continue;
}
public Action:SkinProxy(entity, const String:propName[], &iValue, element)
{
//	PrintToChatAll("%d", entity);
	return Plugin_Continue;
}
public Action:MyTeam(client, args)
{
	if (client <= 0) return Plugin_Handled;
	if (!IsMvM()) return Plugin_Handled;
	decl String:arg1[32];
	ReplyToCommand(client, "[SM] Current MvM team is %s", iSetTeam[client] == 3 ? "BLU" : "RED");
	if (args > 0)
	{
		if (!CheckCommandAccess(client, "mvm_redblu_set_access", ADMFLAG_ROOT, true))
		{
			ReplyToCommand(client, "%t You can only check your team.", "No Access");
			return Plugin_Handled;
		}
		GetCmdArg(1, arg1, sizeof(arg1));
		new team = StringToInt(arg1);
		if (team < 2 || team > 3) team = 2;
		iSetTeam[client] = team;
		ReplyToCommand(client, "[SM] Set MvM team to %s", team == 3 ? "BLU" : "RED");
	}
	return Plugin_Handled;
}
public player_spawn(Handle:event, const String:name[], bool:bDontBroadcast)
{
	if (!IsMvM()) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return;
	if (IsFakeClient(client)) return;
//	SendProxy_Unhook(client, "m_iTeamNum", TeamProxyClient);
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
		TF2Attrib_SetByName(client, "mod see enemy health", 1.0);
	else
		TF2Attrib_RemoveByName(client, "mod see enemy health");
	CreateTimer(0.8, Timer_MoneyDisplay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
public Action:Timer_MoneyDisplay(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client)) return;
	if (iSetTeam[client] != 3) return;
	SetHudTextParams(0.185, 0.92, 10000.0, 235, 235, 235, 255);
	ShowSyncHudText(client, hSyncHud, "$%d", GetEntProp(client, Prop_Send, "m_nCurrency"));
}
/*public Action:Timer_HookTeam(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client)) return;
	SendProxy_Hook(client, "m_iTeamNum", Prop_Int, TeamProxyClient);
}*/
public player_builtobject(Handle:event, const String:name[], bool:bDontBroadcast)
{
//	if (GetEventInt(event, "object") != _:TFObject_Dispenser && GetEventInt(event, "object") != _:TFObject_Sentry) return;
	if (!IsMvM()) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return;
	new obj = GetEventInt(event, "index");
	new skin = GetEntProp(obj, Prop_Send, "m_nSkin");
	new Handle:pack;
	CreateDataTimer(0.0, Timer_SetSkin, pack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, EntIndexToEntRef(obj));
	if (GetClientTeam(client) == _:TFTeam_Blue)
	{
		SetEntProp(obj, Prop_Send, "m_nSkin", skin > 2 ? 3 : 1);
		SetEntityRenderColor(obj, 100, 100, 100, 255);
		WritePackCell(pack, 0);
	}
	else
	{
		SetEntProp(obj, Prop_Send, "m_nSkin", skin > 2 ? iSetTeam[client] : iSetTeam[client] - 2);
		WritePackCell(pack, iSetTeam[client]);
	}
}
public Action:Timer_SetSkin(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new obj = EntRefToEntIndex(ReadPackCell(pack));
	if (obj < MaxClients || !IsValidEntity(obj)) return Plugin_Stop;
	SendProxy_Hook(obj, "m_nSkin", Prop_Int, SkinProxy);
	SendProxy_Hook(obj, "m_iTeamNum", Prop_Int, TeamProxyObject);

	new skin = GetEntProp(obj, Prop_Send, "m_nSkin");
	new team = ReadPackCell(pack);
	if (team == 0)
	{
		SetEntProp(obj, Prop_Send, "m_nSkin", skin > 1 ? 3 : 1);
		SetEntityRenderColor(obj, 100, 100, 100, 255);
	}
	else SetEntProp(obj, Prop_Send, "m_nSkin", skin > 1 ? team : team - 2);
	return Plugin_Continue;
}
public OnClientPutInServer(client)
{
	iSetTeam[client] = IsFakeClient(client) ? 0 : GetRandomInt(2, 3);
	SendProxy_Hook(client, "m_nSkin", Prop_Int, SkinProxy);
	SendProxy_Hook(client, "m_iTeamNum", Prop_Int, TeamProxyClient);
}
public Action:TeamProxyClient(entity, const String:propName[], &iValue, element)
{
	if (!IsMvM()) return Plugin_Continue;
	if (GetClientTeam(entity) != _:TFTeam_Red) return Plugin_Continue;
	if (iSetTeam[entity] < 0) return Plugin_Continue;
//	PrintToChatAll("%d", entity);
	iValue = iSetTeam[entity];
	return Plugin_Changed;
}
public Action:TeamProxyObject(entity, const String:propName[], &iValue, element)
{
	if (!IsMvM()) return Plugin_Continue;
	if (GetEntSendPropOffs(entity, "m_bDisposableBuilding", true) <= 0) return Plugin_Continue;
	new client = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
	if (!IsValidClient(client)) return Plugin_Continue;
	if (iSetTeam[client] < 0) return Plugin_Continue;
	iValue = iSetTeam[client];
	return Plugin_Changed;
}
stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}
