#define PLUGIN_VERSION "1.0 coop"

#include <sourcemod>

#define debug 0

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Simple Afk Manager",
	author = "raziEiL [disawar1]",
	description = "Afk manager for cooperative gamemode",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static	 Handle:g_hAutoKick, Handle:g_hKickT, Handle:g_hAdmin, Float:g_fCvarKickT, g_iCvarAdmFlag, Handle:g_hTimer[MAXPLAYERS+1];

public OnPluginStart()
{
	g_hAutoKick = FindConVar("mp_autokick");

	CreateConVar("sam_version", PLUGIN_VERSION, "Simple Afk Manager plugin version", FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hKickT	= CreateConVar("sam_kick_time", "120", "Time before idle player will be kicked in seconds");
	g_hAdmin	= CreateConVar("sam_respect_admins", "k", "Admins have immunity againts afk manager. Flag value or empty \"\" to don't protect admins");
	AutoExecConfig(true, "SimpleAfkManager");

	HookConVarChange(g_hAutoKick,		OnCvarChange_AutoKick);
	HookConVarChange(g_hKickT,			OnCvarChange_KickT);
	HookConVarChange(g_hAdmin,			OnCvarChange_Admin);
	SAM_GetAllCvar();

	HookEvent("player_team", Event_PlayerTeam);
}

public OnClientDisconnect(client)
{
	if (client)
		SAM_TimeToKill(client);
}

public Action:Event_PlayerTeam(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client && !IsFakeClient(client)){

		SAM_TimeToKill(client);

		if (bWhoAmI(client)){

			#if debug
				PrintToChatAll("[IDLE debug] Event_PlayerTeam()-> %N have admin flag", client);
			#endif

			return;
		}

		if (!GetEventBool(event, "disconnect") && GetEventInt(event, "team") == 1){

			g_hTimer[client] = CreateTimer(g_fCvarKickT, SAM_t_ActionKick, client, TIMER_FLAG_NO_MAPCHANGE);

			#if debug
				PrintToChatAll("[IDLE debug] Event_PlayerTeam()-> %N afk, timer %x hndl", client, g_hTimer[client]);
			#endif
		}
	}
}

SAM_TimeToKill(client)
{
	if (g_hTimer[client] != INVALID_HANDLE){

		#if debug
			PrintToChatAll("[IDLE debug] SAM_TimeToKill(%N)-> Kill %x timer hndl", client, g_hTimer[client]);
		#endif

		KillTimer(g_hTimer[client]);
		g_hTimer[client] = INVALID_HANDLE;
	}
}

public Action:SAM_t_ActionKick(Handle:timer, any:client)
{
	#if debug
		PrintToChatAll("[IDLE debug] SAM_t_ActionKick(%N) Kick player", client);
	#endif

	KickClient(client, "You away from keyboard for %.1f sec", g_fCvarKickT);
	g_hTimer[client] = INVALID_HANDLE;
}

bool:bWhoAmI(client)
{
	return g_iCvarAdmFlag && GetUserFlagBits(client) && CheckCommandAccess(client, "", g_iCvarAdmFlag);
}

public OnCvarChange_AutoKick(Handle:hHandle, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		SetConVarInt(g_hAutoKick, 0); // Dont kick IDLE players by server
}

public OnCvarChange_KickT(Handle:hHandle, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		g_fCvarKickT = GetConVarFloat(g_hKickT);
}

public OnCvarChange_Admin(Handle:hHandle, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		GetAdmCvar();
}

GetAdmCvar()
{
	decl String:sFlags[2];
	GetConVarString(g_hAdmin, sFlags, 2);

	g_iCvarAdmFlag = ReadFlagString(sFlags);
}

public OnConfigsExecuted()
{
	SAM_GetAllCvar();
}

SAM_GetAllCvar()
{
	SetConVarInt(g_hAutoKick, 0);
	g_fCvarKickT = GetConVarFloat(g_hKickT);
	GetAdmCvar();
}
