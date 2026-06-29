// released under GPL v3 license

// based off of Afronanny's [TF2] FriendlyFire Manager plugin

#include <sourcemod>
#include <clientprefs>
#include <sdkhooks>

#define PLUGIN_VERSION		"1.2.0"

enum ResetMethod
{
	RESET_NEVER = -1,
	RESET_DEATH,
	RESET_DISCONNECT,
	RESET_ROUND
};

// Global variables
new Handle:gH_Cvar_FriendlyFire = INVALID_HANDLE;
new bool:gShadow_Cvar_FriendlyFire;
new Handle:gH_Cookie_FriendlyFire = INVALID_HANDLE;
new Handle:gH_Cvar_Tags = INVALID_HANDLE;
new Handle:gH_Cvar_GlobalFF = INVALID_HANDLE;
new bool:gShadow_Cvar_GlobalFF;
new Handle:gH_Cvar_HideFFChanges = INVALID_HANDLE;
new Handle:gH_Cvar_HideTagChanges = INVALID_HANDLE;
new Handle:gH_Cvar_HideTeamAttacks = INVALID_HANDLE;
new Handle:gH_Cvar_ResetMethod = INVALID_HANDLE;
new ResetMethod:gShadow_Cvar_ResetMethod;
new Handle:gH_Cvar_FF_Target = INVALID_HANDLE;
new bool:gShadow_Cvar_FF_Target;
new bool:g_bClientFFisEnabled[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Set FriendlyFire",
	author = "databomb",
	description = "Allows admins to change friendly fire settings for targetted individuals.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConVar("sm_setff_version", PLUGIN_VERSION, "Version of the Set FF Plugin", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gH_Cvar_HideFFChanges = CreateConVar("sm_setff_hide_ff", "0", "Hides the notification of mp_friendlyfire changing values.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_HideTagChanges = CreateConVar("sm_setff_hide_tags", "0", "Hides the notification of sv_tags changing values.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_GlobalFF = CreateConVar("sm_setff_everyone", "0", "Turn on friendly fire for everybody.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_HideTeamAttacks = CreateConVar("sm_setff_hide_teamattack", "0", "Hides team attack messages if your mod supports them.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_FF_Target = CreateConVar("sm_setff_target", "0", "Changes the target behavior of the plugin: 0- Allows the target to attack all teammates, 1- Allows the target to be attacked by all teammates.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Cvar_ResetMethod = CreateConVar("sm_setff_resetmethod", "1", "Choose when the FF will be reset for the targeted player: [-1] Never reset, [0] Resets on death, [1] Resets on disconnect, [2] Resets at end of round", FCVAR_PLUGIN, true, -1.0, true, 2.0);
	
	gH_Cvar_FriendlyFire = FindConVar("mp_friendlyfire");
	gH_Cvar_Tags = FindConVar("sv_tags");
	
	RegAdminCmd("sm_setff", Command_SetFriendlyFire, ADMFLAG_SLAY, "Sets Friendly Fire on a player or group.");
	RegAdminCmd("sm_unsetff", Command_UnSetFriendlyFire, ADMFLAG_SLAY, "Resets Friendly Fire on a player or group.");
	
	if (gH_Cvar_FriendlyFire == INVALID_HANDLE || gH_Cvar_Tags == INVALID_HANDLE)
	{
		SetFailState("Mod does not support mp_friendlyfire or sv_tags, unloading plugin.");
	}
	
	// generic events
	HookEvent("player_disconnect", Event_RemoveFF, EventHookMode_Post);
	HookEvent("player_death", Event_SortFFReset, EventHookMode_Post);
	HookEvent("round_end", Event_SortFFReset, EventHookMode_Post);
	// hook TF2-specific events
	HookEventEx("teamplay_restart_round", Event_SortFFReset, EventHookMode_Post);
	HookEventEx("arena_win_panel", Event_SortFFReset, EventHookMode_Post);
	// hook DOD-specific events
	HookEventEx("dod_round_win", Event_SortFFReset, EventHookMode_Post);
	
	HookConVarChange(gH_Cvar_HideFFChanges, ConVarChanged_Global);
	HookConVarChange(gH_Cvar_HideTagChanges, ConVarChanged_Global);
	HookConVarChange(gH_Cvar_GlobalFF, ConVarChanged_Global);   
	HookConVarChange(gH_Cvar_ResetMethod, ConVarChanged_Global);
	HookConVarChange(gH_Cvar_FriendlyFire, ConVarChanged_Global);
	HookConVarChange(gH_Cvar_FF_Target, ConVarChanged_Global);
	
	gH_Cookie_FriendlyFire = RegClientCookie("friendlyfire", "Holds a clients friendly fire status for future games.", CookieAccess_Protected);
	
	// loop through currently connected clients so a mapchange isn't needed
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (IsClientInGame(idx))
		{
			SDKHook(idx, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		// initialize array
		g_bClientFFisEnabled[idx] = false;
	}
}

public Action:Event_RemoveFF(Handle:event, const String:sName[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bClientFFisEnabled[client] = false;
	
	if (gShadow_Cvar_ResetMethod == RESET_DISCONNECT)
	{
		new bool:bAnyoneHasFF = false;
		for (new idx = 1; idx <= MaxClients; idx++)
		{
			if (g_bClientFFisEnabled[idx])
			{
				bAnyoneHasFF = true;
			}
		}
		if (!bAnyoneHasFF && !gShadow_Cvar_GlobalFF)
		{
			SetConVarBool(gH_Cvar_FriendlyFire, false);
		}
	}
}

public Action:Event_SortFFReset(Handle:event, const String:sName[], bool:dontBroadcast)
{
	switch (gShadow_Cvar_ResetMethod)
	{
		case RESET_DEATH:
		{
			if (StrEqual(sName, "player_death"))
			{
				new client = GetClientOfUserId(GetEventInt(event, "userid"));
				g_bClientFFisEnabled[client] = false;
				
				// check if no one has FF on them
				new bool:bAnyoneHasFF = false;
				for (new idx = 1; idx <= MaxClients; idx++)
				{
					if (g_bClientFFisEnabled[idx])
					{
						bAnyoneHasFF = true;
					}
				}
				
				if (!bAnyoneHasFF && !gShadow_Cvar_GlobalFF)
				{
					SetConVarBool(gH_Cvar_FriendlyFire, false);
				}
			}
		}
		case RESET_ROUND:
		{
			if (StrEqual(sName, "arena_win_panel") || (StrContains(sName, "round") != -1))
			{
				if (!gShadow_Cvar_GlobalFF)
				{
					SetConVarBool(gH_Cvar_FriendlyFire, false);
				}
				for (new idx = 1; idx <= MaxClients; idx++)
				{
					g_bClientFFisEnabled[idx] = false;
				}
			}
		}
	}
}

public ConVarChanged_Global(Handle:cvar, const String:sOldValue[], const String:sNewValue[])
{
	// Ignore changes which result in the same value being set
	if (StrEqual(sOldValue, sNewValue, true))
	{
		return;
	}
	
	// Perform separate integer checking (ignores inbetween floating point values)
	new iNewValue = StringToInt(sNewValue);
	new iOldValue = StringToInt(sOldValue);
	if (iNewValue == iOldValue)
	{
		return;
	}
	
	if (cvar == gH_Cvar_HideFFChanges)
	{
		if (iNewValue)
		{
			SetConVarFlags(gH_Cvar_FriendlyFire, GetConVarFlags(gH_Cvar_FriendlyFire) & ~FCVAR_NOTIFY);
		}
		else
		{
			SetConVarFlags(gH_Cvar_FriendlyFire, GetConVarFlags(gH_Cvar_FriendlyFire) | FCVAR_NOTIFY);
		}
	}
	else if (cvar == gH_Cvar_HideTagChanges)
	{
		if (iNewValue)
		{
			SetConVarFlags(gH_Cvar_Tags, GetConVarFlags(gH_Cvar_Tags) & ~FCVAR_NOTIFY);
		}
		else
		{
			SetConVarFlags(gH_Cvar_Tags, GetConVarFlags(gH_Cvar_Tags) | FCVAR_NOTIFY);
		}
	}
	else if (cvar == gH_Cvar_GlobalFF)
	{
		gShadow_Cvar_GlobalFF = bool:iNewValue;
	}
	else if (cvar == gH_Cvar_HideTeamAttacks)
	{
		if (iNewValue)
		{
			HookUserMessage(GetUserMessageId("TextMsg"), FFMessageHook, true);
		}
		else
		{
			UnhookUserMessage(GetUserMessageId("TextMsg"), FFMessageHook, true);
		}
	}
	else if (cvar == gH_Cvar_ResetMethod)
	{
		gShadow_Cvar_ResetMethod = ResetMethod:iNewValue;
	}
	else if (cvar == gH_Cvar_FriendlyFire)
	{
		gShadow_Cvar_FriendlyFire = bool:iNewValue;
	}
	else if (cvar == gH_Cvar_FF_Target)
	{
		gShadow_Cvar_FF_Target = bool:iNewValue;
	}
}

public OnConfigsExecuted()
{
	// Update the shadow variables from the exec'd configs
	gShadow_Cvar_GlobalFF = bool:GetConVarBool(gH_Cvar_GlobalFF);
	gShadow_Cvar_ResetMethod = ResetMethod:GetConVarInt(gH_Cvar_ResetMethod);
	gShadow_Cvar_FriendlyFire = bool:GetConVarBool(gH_Cvar_FriendlyFire);
	gShadow_Cvar_FF_Target = bool:GetConVarBool(gH_Cvar_FF_Target);

	if (GetConVarBool(gH_Cvar_HideTeamAttacks))
	{
		HookUserMessage(GetUserMessageId("TextMsg"), FFMessageHook, true);
	}
	HookConVarChange(gH_Cvar_HideTeamAttacks, ConVarChanged_Global);
}

public Action:FFMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:message[256];
	BfReadString(bf, message, sizeof(message));
	if (StrContains(message, "teammate_attack") != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientCookiesCached(client)
{
	if (gShadow_Cvar_ResetMethod == RESET_NEVER && IsClientInGame(client) && gH_Cookie_FriendlyFire != INVALID_HANDLE)
	{
		decl String:sCookie[5];
		GetClientCookie(client, gH_Cookie_FriendlyFire, sCookie, sizeof(sCookie));
		// Check for empty cookie
		if (strlen(sCookie) > 0)
		{
			new bool:status = bool:StringToInt(sCookie);
			g_bClientFFisEnabled[client] = status;
		}
	}
}

public Action:Command_SetFriendlyFire(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setff <target>");
	}
	else
	{
		decl String:sSearchPattern[65];
		GetCmdArg(1, sSearchPattern, sizeof(sSearchPattern));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		target_count = ProcessTargetString(sSearchPattern, client, target_list, sizeof(target_list), 0, target_name, sizeof(target_name), tn_is_ml);
		
		if (target_count <= 0)
		{
			ReplyToTargetError(client, target_count);
		}
		else
		{
			for (new i = 0; i < target_count; i++)
			{
				if (IsClientInGame(target_list[i]))
				{
					if (gShadow_Cvar_ResetMethod == RESET_NEVER)
					{
						SetClientCookie(target_list[i], gH_Cookie_FriendlyFire, "1");
					}
					g_bClientFFisEnabled[target_list[i]] = true;
				}
			}
			
			if (!gShadow_Cvar_FriendlyFire)
			{
				SetConVarBool(gH_Cvar_FriendlyFire, true);
			}

			ShowActivity2(client, "[SM] ", "Set FF ON for %s.", target_name);

		}
	}
	return Plugin_Handled;
}

public Action:Command_UnSetFriendlyFire(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unsetff <target>");
	}
	else
	{
		decl String:sSearchPattern[65];
		GetCmdArg(1, sSearchPattern, sizeof(sSearchPattern));
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		target_count = ProcessTargetString(sSearchPattern, client, target_list, sizeof(target_list), 0, target_name, sizeof(target_name), tn_is_ml);
		
		if (target_count <= 0)
		{
			ReplyToTargetError(client, target_count);
		}
		else
		{
			for (new i = 0; i < target_count; i++)
			{
				g_bClientFFisEnabled[target_list[i]] = false;
				
				if (gShadow_Cvar_ResetMethod == RESET_NEVER && IsClientInGame(target_list[i]))
				{
					SetClientCookie(target_list[i], gH_Cookie_FriendlyFire, "0");
				}
			}

			new bool:bAnyoneHasFF = false;
			for (new idx = 1; idx <= MaxClients; idx++)
			{
				if (g_bClientFFisEnabled[idx])
				{
					bAnyoneHasFF = true;
				}
			}
			if (!bAnyoneHasFF && !gShadow_Cvar_GlobalFF)
			{
				SetConVarBool(gH_Cvar_FriendlyFire, false);
			}

			ShowActivity2(client, "[SM] ", "Set FF OFF for %s.", target_name);
		
		}
	}
	return Plugin_Handled;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && victim != attacker)
	{
		// for non-FF servers
		if (gShadow_Cvar_FriendlyFire && !gShadow_Cvar_GlobalFF)
		{
			if (GetClientTeam(victim) == GetClientTeam(attacker))
			{
				if (!gShadow_Cvar_FF_Target)
				{
					// allow the targetted to attack their teammates
					if (!g_bClientFFisEnabled[attacker])
					{
						damage = 0.0;
						return Plugin_Handled;
					}           
				}
				else
				{
					// allow the targetted to be attacked by their teammates
					if (!g_bClientFFisEnabled[victim])
					{
						damage = 0.0;
						return Plugin_Handled;
					}
				}
			}
		}
		// for FF servers
		else if (gShadow_Cvar_FriendlyFire && gShadow_Cvar_GlobalFF)
		{
			if (GetClientTeam(victim) == GetClientTeam(attacker))
			{
				if (!gShadow_Cvar_FF_Target)
				{
					// allow the targetted to no longer attack teammates
					if (g_bClientFFisEnabled[attacker])
					{
						damage = 0.0;
						return Plugin_Handled;
					}
				}
				else
				{
					// allow targetted to be immune from regular FF damage
					if (g_bClientFFisEnabled[victim])
					{
						damage = 0.0;
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}