/* -------------------CHANGELOG--------------------
 1.4
 - Removed sm_kickafks command
 - Added @afk/@afks and @notafk/@notafks/@active target filters
 - A bit more of code optimization

 1.3
 - Added ConVar to contol ignoring admins

 1.2
 - Code optimizations + fixed error log spam after updating to SM 1.6
 - Added sm_kickafks command

 1.1
 - Provided useful native and forwards for plugins developers

 1.0
 - Initial release
^^^^^^^^^^^^^^^^^^^^CHANGELOG^^^^^^^^^^^^^^^^^^^^ */


#include <sourcemod>
#include <sdktools>
//#define PRIVATE_BUILD //I run different versions for my servers and for public release. Actually, not much of differents, but public version does not need unnecessary dependencies
#if defined PRIVATE_BUILD
#include <natives_and_forwards>
#endif

new Handle:hcVisibleMaxPlayers = INVALID_HANDLE;
new Handle:Timer_afk[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:Timer_spec[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:Timer_AnnounceSpec[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:Timer_AnnounceKick[MAXPLAYERS + 1] = INVALID_HANDLE;
//too many handles
new iarPressedButtons[MAXPLAYERS + 1]; //array with pressed buttons for each index. I bet it`s safe to not reset this value on client disconnect

//cvars
new Handle:cvarFreeSlotsBeforeKick = INVALID_HANDLE;
new Handle:cvarSecondsBeforeSpec = INVALID_HANDLE;
new Handle:cvarSecondsBeforeKick = INVALID_HANDLE;
new Handle:cvarAnnounceBeforeKick = INVALID_HANDLE;
new Handle:cvarIgnoreAdmins = INVALID_HANDLE;
//cvars local variables
new CLV_cvarFreeSlotsBeforeKick;
new Float:CLV_cvarSecondsBeforeSpec;
new Float:CLV_cvarSecondsBeforeKick;
new Float:CLV_cvarAnnounceBeforeKick;
new bool:CLV_cvarIgnoreAdmins;
//forwards
new Handle:OnAFK;
new Handle:OnComeBack;

new bool:IsIndexAway[MAXPLAYERS + 1];

#define PL_VERSION "1.4"

public Plugin:myinfo =
{
	name = "Play Or Leave",
	version = PL_VERSION,
	author = "sheo",
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
	{
		strcopy(error, err_max, "This plugin cannot be loaded midgame");
		return APLRes_Failure;
	}
	else
	{
		OnAFK = CreateGlobalForward("AFK_OnAway", ET_Ignore, Param_Cell);
		OnComeBack = CreateGlobalForward("AFK_OnComeBack", ET_Ignore, Param_Cell);
		CreateNative("AFK_IsPlayerAway", Native_IsPlayerAFK);
		RegPluginLibrary("afk_manager");
		return APLRes_Success;
	}
}

public OnPluginStart()
{
	//Check if TF2
	if (GetEngineVersion() != Engine_TF2)
	{
		SetFailState("This plugin does not support any game besides TF2");
	}
	//cvars
	hcVisibleMaxPlayers = FindConVar("sv_visiblemaxplayers");
	cvarFreeSlotsBeforeKick = CreateConVar("sm_sheoafk_free_slots_before_kick", "4", "How many slots should left on the server when AFK manager starts kicking spectators.", 0, true, 1.0, false);
	cvarSecondsBeforeSpec = CreateConVar("sm_sheoafk_seconds_before_spec", "60.0", "How many seconds to wait before spectating an afk player", 0, true, 10.0, false);
	cvarSecondsBeforeKick = CreateConVar("sm_sheoafk_seconds_before_kick", "120.0", "How many seconds to wait before kicking an afk spectator\n- This counts from the moment the player joins spectator team", 0, true, 10.0, false);
	cvarAnnounceBeforeKick = CreateConVar("sm_sheoafk_seconds_before_warn", "15.0", "How many seconds before kick/spec a player should be announced about oncoming action", 0, true, 5.0, false);
	cvarIgnoreAdmins = CreateConVar("sm_sheoafk_ignore_admins", "0", "Set to 1 to ignore admins\n- This does not include the native and forwards, they are working for all players\n- Also sm_kickafks will kick everyone who is AFK", 0, true, 0.0, true, 1.0);
	CreateConVar("tf2_sheoafk_manager_version", PL_VERSION, "Plugin version...", FCVAR_PLUGIN | FCVAR_NOTIFY);
	LoadTranslations("afk_manager");
	WritePluginSettingsToVariables();
	//Disable default idle manager
	SetConVarInt(FindConVar("mp_idlemaxtime"), 9999999);
	//hooks
	HookConVarChange(cvarFreeSlotsBeforeKick, OnPluginSettingsChanged);
	HookConVarChange(cvarSecondsBeforeSpec, OnPluginSettingsChanged);
	HookConVarChange(cvarSecondsBeforeKick, OnPluginSettingsChanged);
	HookConVarChange(cvarAnnounceBeforeKick, OnPluginSettingsChanged);
	HookConVarChange(cvarIgnoreAdmins, OnPluginSettingsChanged);
	HookEvent("player_team", OnPlayerTeam);
	//Filtering options
	AddMultiTargetFilter("@afk", AFKTargetHandler, "AFK", false);
	AddMultiTargetFilter("@afks", AFKTargetHandler, "AFK", false);
	AddMultiTargetFilter("@notafk", NotAFKTargetHandler, "Active", false);
	AddMultiTargetFilter("@notafks", NotAFKTargetHandler, "Active", false);
	AddMultiTargetFilter("@active", NotAFKTargetHandler, "Active", false);
}

public bool:AFKTargetHandler(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsIndexAway[i])
		{
			PushArrayCell(clients, i);
		}
	}
	return true;
}

public bool:NotAFKTargetHandler(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		#if defined PRIVATE_BUILD
		if (NAF_IsClientReallyInGame(i) && !IsIndexAway[i])
		#else
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 0 && !IsIndexAway[i])
		#endif
		{
			PushArrayCell(clients, i);
		}
	}
	return true;
}

public OnPluginSettingsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	WritePluginSettingsToVariables();
}

WritePluginSettingsToVariables()
{
	CLV_cvarFreeSlotsBeforeKick = GetConVarInt(cvarFreeSlotsBeforeKick);
	CLV_cvarSecondsBeforeSpec = GetConVarFloat(cvarSecondsBeforeSpec);
	CLV_cvarSecondsBeforeKick = GetConVarFloat(cvarSecondsBeforeKick);
	CLV_cvarAnnounceBeforeKick = GetConVarFloat(cvarAnnounceBeforeKick);
	CLV_cvarIgnoreAdmins = GetConVarBool(cvarIgnoreAdmins);
}

public OnClientPutInServer(client)
{
	if (client > 0 && !IsFakeClient(client))
	{
		Timer_AnnounceKick[client] = CreateTimer(CLV_cvarSecondsBeforeKick - CLV_cvarAnnounceBeforeKick, Timer_AnnounceToKick, client); //Consider unassigned player as afk
	}
}

public OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!GetEventBool(event, "disconnect") && client > 0 && !IsFakeClient(client))
	{
		ResetTimer(client, GetEventInt(event, "team"));
	}
}

public Action:Timer_AnnounceToSpec(Handle:timer, any:client) //time for some announcements
{
	Timer_AnnounceSpec[client] = INVALID_HANDLE;
	PrintToChat(client, "%t", "MoveOrSpec");
	Timer_spec[client] = CreateTimer(CLV_cvarAnnounceBeforeKick, Timer_MoveToSpec, client);
}

public Action:Timer_MoveToSpec(Handle:timer, any:client)
{
	Timer_spec[client] = INVALID_HANDLE;
	if (!CLV_cvarIgnoreAdmins || !(GetUserFlagBits(client) & ADMFLAG_RESERVATION))
	{
		//Tshh be quiet, there is a stolen code starts here
		new iEnt = -1;
		while ((iEnt = FindEntityByClassname(iEnt, "item_teamflag")) > -1)
		{
			if (IsValidEntity(iEnt))
			{
				if (GetEntPropEnt(iEnt, Prop_Data, "m_hMoveParent") == client)
				{
					AcceptEntityInput(iEnt, "ForceDrop");
				}
			}
		}
		//And ends here
		ChangeClientTeam(client, 1);
	}
	IsIndexAway[client] = true;
	Call_StartForward(OnAFK);
	Call_PushCell(client);
	Call_Finish();
}
#if defined PRIVATE_BUILD
#else
ProcessTeamCheck(client, teamnum)
{
	if (teamnum > 0)
	{
		ResetTimer(client, teamnum);
	}
}

#endif
ResetTimer(client, teamnum)
{
	if (IsIndexAway[client])
	{
		IsIndexAway[client] = false;
		Call_StartForward(OnComeBack);
		Call_PushCell(client);
		Call_Finish();
	}
	if (Timer_afk[client] != INVALID_HANDLE)
	{
		KillTimer(Timer_afk[client]);
		Timer_afk[client] = INVALID_HANDLE;
		PrintToChat(client, "%t", "Aborted");
	}
	else if (Timer_spec[client] != INVALID_HANDLE)
	{
		KillTimer(Timer_spec[client]);
		Timer_spec[client] = INVALID_HANDLE;
		PrintToChat(client, "%t", "Aborted");
	}
	else if (Timer_AnnounceSpec[client] != INVALID_HANDLE)
	{
		KillTimer(Timer_AnnounceSpec[client]);
		Timer_AnnounceSpec[client] = INVALID_HANDLE;
	}
	else if (Timer_AnnounceKick[client] != INVALID_HANDLE)
	{
		KillTimer(Timer_AnnounceKick[client]);
		Timer_AnnounceKick[client] = INVALID_HANDLE;
	}
	if (teamnum > 1) //spectimer if valid player, kicktimer if spec
	{
		Timer_AnnounceSpec[client] = CreateTimer(CLV_cvarSecondsBeforeSpec - CLV_cvarAnnounceBeforeKick, Timer_AnnounceToSpec, client);
	}
	else if (teamnum == 1) //probably reduntant check
	{
		Timer_AnnounceKick[client] = CreateTimer(CLV_cvarSecondsBeforeKick - CLV_cvarAnnounceBeforeKick, Timer_AnnounceToKick, client);
	}
}

public Action:Timer_AnnounceToKick(Handle:timer, any:client) //time for some announcements
{
	Timer_AnnounceKick[client] = INVALID_HANDLE;
	PrintToChat(client, "%t", "MoveOrKick");
	Timer_afk[client] = CreateTimer(CLV_cvarAnnounceBeforeKick, Timer_Kick_Callback, client);
	if (!IsIndexAway[client])
	{
		IsIndexAway[client] = true;
		Call_StartForward(OnAFK);
		Call_PushCell(client);
		Call_Finish();
	}
}

public Action:Timer_Kick_Callback(Handle:timer, any:client) //kick if the server is almost full, restart timer otherwise
{
	Timer_afk[client] = INVALID_HANDLE;
	if ((GetConnectedPlayersCount() >= GetConVarInt(hcVisibleMaxPlayers) - CLV_cvarFreeSlotsBeforeKick) && (!CLV_cvarIgnoreAdmins || !(GetUserFlagBits(client) & ADMFLAG_RESERVATION)))
	{
		KickClient(client, "%t", "KickedForAFK");
	}
	else
	{
		Timer_afk[client] = CreateTimer(20.0, Timer_Kick_Callback, client);
	}
}

public OnClientDisconnect(client)
{
	KillTimers(client);
}

public OnClientConnected(client)
{
	KillTimers(client);
}

KillTimers(client)
{
	if (!IsFakeClient(client))
	{
		IsIndexAway[client] = false;
		if (Timer_afk[client] != INVALID_HANDLE)
		{
			KillTimer(Timer_afk[client]);
			Timer_afk[client] = INVALID_HANDLE;
		}
		else if (Timer_spec[client] != INVALID_HANDLE)
		{
			KillTimer(Timer_spec[client]);
			Timer_spec[client] = INVALID_HANDLE;
		}
		else if (Timer_AnnounceSpec[client] != INVALID_HANDLE)
		{
			KillTimer(Timer_AnnounceSpec[client]);
			Timer_AnnounceSpec[client] = INVALID_HANDLE;
		}
		else if (Timer_AnnounceKick[client] != INVALID_HANDLE)
		{
			KillTimer(Timer_AnnounceKick[client]);
			Timer_AnnounceKick[client] = INVALID_HANDLE;
		}
	}
}

GetConnectedPlayersCount()
{
	new count;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			count++;
		}
	}
	return count;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	#if defined PRIVATE_BUILD
	if (iarPressedButtons[client] != buttons && NAF_IsClientReallyInGame(client))
	#else
	if (iarPressedButtons[client] != buttons)
	#endif
	{
		iarPressedButtons[client] = buttons;
		#if defined PRIVATE_BUILD
		ResetTimer(client, GetClientTeam(client)); //buttons changes only
		#else
		ProcessTeamCheck(client, GetClientTeam(client));
		#endif
	}
}

public Native_IsPlayerAFK(Handle:plugin, numParams)
{
	return IsIndexAway[GetNativeCell(1)];
}