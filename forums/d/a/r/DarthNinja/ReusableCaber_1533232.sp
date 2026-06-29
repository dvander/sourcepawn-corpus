#include <sourcemod>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0.0"

new Handle:v_CaberUsesBase = INVALID_HANDLE;
new Handle:v_CaberUsesAdmin = INVALID_HANDLE;
new Handle:v_CaberTimer = INVALID_HANDLE;

new g_iCaberUses[MAXPLAYERS+1] = 0;

public Plugin:myinfo = {
	name             = "[TF2] Reusable Caber",
	author         = "DarthNinja",
	description     = "Save a Creeper, (re)use a Caber!",
	version         = PLUGIN_VERSION,
	url             = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_caber_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_CaberUsesBase = CreateConVar("caber_uses_base", "0", "The number of times to reset a player's caber (resets on locker touch)");
	v_CaberUsesAdmin = CreateConVar("caber_uses_admin", "1", "The number of times to reset a player's caber (resets on locker touch)");
	v_CaberTimer = CreateConVar("caber_timer", "0.5", "How many seconds to wait before resetting cabers");
	
	RegAdminCmd("sm_cabertest", GetCaberState, ADMFLAG_BAN, "Get Caber State");
	RegAdminCmd("sm_resetcaber", ResetCaber, ADMFLAG_BAN, "Reset ur Ullapool Caber to its unexploded state");
	RegAdminCmd("sm_caber", GiveCabers, ADMFLAG_BAN, "Give a player some cabers");
	
	AutoExecConfig(true, "ReuseACaber");
	
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
}

public OnClientDisconnect(client)
{
	g_iCaberUses[client] = 0;
}

public Action:GiveCabers(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_caber <player> <number of extra cabers>");
		return Plugin_Handled;
	}

	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;

	GetCmdArg(1, buffer, sizeof(buffer));

	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, buffer, sizeof(buffer));
	new iValueToSet = StringToInt(buffer);
	
	for (new i = 0; i < target_count; i++)
	{
		g_iCaberUses[target_list[i]] = iValueToSet;
	}

	ReplyToCommand(client, "\x04[\x03SM\x04]\x01: Set \x04%s's\x01 Ullapool Cabers to have \x05%i\x01 extra uses!", target_name, iValueToSet);
	return Plugin_Handled
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new iA = GetConVarInt(v_CaberUsesAdmin);
	new iB = GetConVarInt(v_CaberUsesBase)
	
	if (CheckCommandAccess(client, "caber_access", ADMFLAG_CUSTOM1) && g_iCaberUses[client] < iA && g_iCaberUses[client] != -1)
		g_iCaberUses[client] = iA;
	else if (g_iCaberUses[client] < iB && g_iCaberUses[client] != -1)
		g_iCaberUses[client] = iB;
}

public OnConfigsExecuted()
{
	CreateTimer(GetConVarFloat(v_CaberTimer), Timer_ResetCaber, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ResetCaber(Handle:Timer)
{
	for (new i=1; i<=MaxClients; i++)
	{		
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (g_iCaberUses[i] < 1 && g_iCaberUses[i] != -1))
			continue;
		
		new iWeapon = GetPlayerWeaponSlot(i, 2);
		if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 307 && GetEntProp(iWeapon, Prop_Send, "m_iDetonated") == 1)
		{
			SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 0);
			if (g_iCaberUses[i] != -1)	//Unlimited ammo check, not really any point to this though
				g_iCaberUses[i]--;
		}
	}
	return Plugin_Continue;
}

public Action:ResetCaber(client, args)
{
	new iWeapon = GetPlayerWeaponSlot(client, 2);
	new iItemID = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");

	if (iItemID == 307)
	{
		SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 0);
		ReplyToCommand(client, "Caber Reset");
	}
	else
		ReplyToCommand(client, "Caber, do you have it?!");
	return Plugin_Handled;
}

public Action:GetCaberState(client, args)
{
	if (!IsClientInGame(client) || TF2_GetPlayerClass(client) != TFClass_DemoMan)
	{
		ReplyToCommand(client, "Error, you must be ingame and a demoman!");
		return Plugin_Handled;
	}
	/*
	-------------------------------------------------
	-
	-	307	= The Ullapool Caber
	-
	-------------------------------------------------
	*/
	//new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new iWeapon = GetPlayerWeaponSlot(client, 2);
	new iItemID = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	
	if (iItemID != 307)
	{
		ReplyToCommand(client, "You do not have a ullapool caber!");
		return Plugin_Handled;
	}
	
	new iDetonated = GetEntProp(iWeapon, Prop_Send, "m_iDetonated");
	
	ReplyToCommand(client, "The current state of m_iDetonated for your Ullapool Caber is: %i", iDetonated)
	
	return Plugin_Handled;
}