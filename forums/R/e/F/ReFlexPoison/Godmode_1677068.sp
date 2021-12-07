#include <sourcemod>
#define PLUGIN_VERSION "2.2.1"

new Handle:v_AllowClients = INVALID_HANDLE;
new Handle:v_Announce = INVALID_HANDLE;
new Handle:v_Remember = INVALID_HANDLE;
new Handle:v_Spawn = INVALID_HANDLE;
new Handle:v_SpawnAdminOnly = INVALID_HANDLE;
new g_iState[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
	name = "[Any] Deluxe Godmode",
	author = "DarthNinja",
	description = "Adds advanced godmode controls for clients/admins",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_god", Command_God, "sm_god [#userid|name] [0/1] - Toggles godmode on player(s)");
	RegConsoleCmd("sm_buddha", Command_Buddha, "sm_buddha [#userid|name] [0/1] - Toggles buddha mode on player(s)");
	RegConsoleCmd("sm_mortal", Command_Mortal, "sm_mortal [#userid|name] - Makes specified players mortal");
	CreateConVar("sm_godmode_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_AllowClients = CreateConVar("sm_godmode_clients", "0", "Set to 1 to allow clients to set Godmode on themselves", 0, true, 0.0, true, 1.0);
	v_Spawn = CreateConVar("sm_godmode_spawn", "0", "1 = Players spawn with godmode, 2 = Players spawn with buddha, 0 = Players spawn mortal", 0, true, 0.0, true, 2.0);
	v_Remember = CreateConVar("sm_godmode_remember", "0", "1 = When players respawn the plugin will return their godmode to whatever it was set to prior to death. 0 = Players will respawn with godmode off.", 0, true, 0.0, true, 1.0);
	v_Announce = CreateConVar("sm_godmode_announce", "1", "Tell players if an admin gives/removes their godmode", 0, true, 0.0, true, 1.0);
	v_SpawnAdminOnly = CreateConVar("sm_godmode_spawn_admins", "0", "1 = Only admins spawn with godmode, 0 = All players spawn with godmode.\n Requires sm_godmode_spawn to be set to a non-zero value", 0, true, 0.0, true, 1.0);
	HookEvent("player_spawn", PlayerSpawned);
	LoadTranslations("common.phrases");
}

public OnClientDisconnect(client)
{
	g_iState[client] = 0;
}

public PlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_iState[client] != 0 && GetConVarBool(v_Remember))
	{
		switch (g_iState[client])
		{
			case 1:
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);	//Godmode
				PrintToChat(client,"\x04[SM] \x01You have automatically respawned with \x05God Mode\x01!  You may type \x05!mortal\x01 to turn it off.");
			}
			case 2:
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);	//Buddha
				PrintToChat(client,"\x04[SM] \x01You have automatically respawned with \x05Buddha Mode\x01!  You may type \x05!mortal\x01 to turn it off.");
			}
			//case 0:
				//SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);	//Mortal
		}
	}
	else
	{
		g_iState[client] = 0;
		
		if (GetConVarBool(v_SpawnAdminOnly) && !CheckCommandAccess(client, "godmode_adminonly_override", ADMFLAG_KICK))
			return; //admin only mode + not an admin
		
		if (GetConVarInt(v_Spawn) != 0)
			CreateTimer(0.5, ApplyGodMode, client)
	}
}

public Action:ApplyGodMode(Handle:timer, any:client)
{
	if (IsValidClient(client, true))
	{
		new team = GetClientTeam(client);
		if (team == 2 || team == 3)
		{
			if (GetConVarInt(v_Spawn) == 1)
			{
				PrintToChat(client,"\x04[SM] \x01You have automatically spawned with \x05God Mode\x01!  You may type \x05!mortal\x01 to turn it off.");
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				g_iState[client] = 1;
			}
			else if (GetConVarInt(v_Spawn) == 2)
			{
				PrintToChat(client,"\x04[SM] \x01You have automatically spawned with \x05Buddha Mode\x01!  You may type \x05!mortal\x01 to turn it off.");
				SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
				g_iState[client] = 2;
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_God( client, args )
{
	if (args != 0 && args != 1 && args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_god [#userid|name] [0/1]");
		return Plugin_Handled;
	}
	
	new bool:isAdmin = CheckCommandAccess(client, "sm_slay", ADMFLAG_KICK);
	
	if (!isAdmin && !GetConVarBool(v_AllowClients))
	{
		ReplyToCommand(client, "[SM] You are not authorized to use this command");
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		if (g_iState[client] != 1) //Mortal or Buddha
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			ReplyToCommand(client,"\x01[SM] \x04God Mode on");
			g_iState[client] = 1;
		}
		else // GodMode on
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			ReplyToCommand(client,"\x01[SM] \x04God Mode off");
			g_iState[client] = 0;
		}
		return Plugin_Handled;
	}
	
	if (!isAdmin)
	{
		ReplyToCommand(client, "[SM] You are not authorized to target other players");
		return Plugin_Handled;
	}
	
	if (args == 2)
	{
		new String:target[32];
		new String:arg2[32];
		
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, arg2, sizeof(arg2));
		
		new toggle = StringToInt(arg2)
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
		
		new bool:chat = GetConVarBool(v_Announce);
		
		if (toggle == 1)
		{
			ShowActivity2(client, "\x04[SM] ","\x01Enabled God Mode on \x05%s", target_name);
		}
		else if (toggle == 0)
		{
			ShowActivity2(client, "\x04[SM] ","\x01Disabled God Mode on \x05%s", target_name);
		}
		
		for (new i = 0; i < target_count; i++)
		{	
			if (toggle == 1) //Turn on godmode
			{
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 0, 1);
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has given you \x05God Mode\x01!");
				}
				LogAction(client, target_list[i], "%L enabled godmode on %L", client, target_list[i]);
				g_iState[target_list[i]] = 1;
			}
			
			else if (toggle == 0) //Turn off godmode
			{
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1)
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has removed your \x05God Mode\x01!");
				}
				LogAction(client, target_list[i], "%L disabled godmode on %L", client, target_list[i]);
				g_iState[target_list[i]] = 0;
			}
		}
	}
	
	if (args == 1)
	{
		new String:target[32];
		
		GetCmdArg(1, target, sizeof(target));
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
		
		new bool:chat = GetConVarBool(v_Announce);

		ShowActivity2(client, "\x04[SM] ","\x01Toggled God Mode on \x05%s", target_name);
			
		for (new i = 0; i < target_count; i++)
		{	
			if (g_iState[target_list[i]] != 1) //Mortal or Buddha -> Turn on godmode
			{
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 0, 1);
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has given you \x05God Mode\x01!");
				}
				LogAction(client, target_list[i], "%L enabled godmode on %L", client, target_list[i]);
				g_iState[target_list[i]] = 1;
			}
			
			else //Turn off godmode
			{
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1)
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has removed your \x05God Mode\x01!");
				}
				LogAction(client, target_list[i], "%L disabled godmode on %L", client, target_list[i]);
				g_iState[target_list[i]] = 0;
			}
		}
	}
	
	return Plugin_Handled;
}


public Action:Command_Buddha( client, args )
{
	if (args != 0 && args != 1 && args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_buddha [#userid|name] [0/1]");
		return Plugin_Handled;
	}
	
	new bool:isAdmin = CheckCommandAccess(client, "sm_slay", ADMFLAG_KICK);
	
	if (!isAdmin && !GetConVarBool(v_AllowClients))
	{
		ReplyToCommand(client, "[SM] You are not authorized to use this command");
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		if (g_iState[client] != 2) //Mortal or God
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 1, 1)
			ReplyToCommand(client,"\x01[SM] \x04Buddha Mode on");
			g_iState[client] = 2;
		}
		else // GodMode on
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
			ReplyToCommand(client,"\x01[SM] \x04Buddha Mode off");
			g_iState[client] = 0;
		}
		return Plugin_Handled;
	}
	
	if (!isAdmin)
	{
		ReplyToCommand(client, "[SM] You are not authorized to target other players");
		return Plugin_Handled;
	}
	
	if (args == 2)
	{
		new String:target[32];
		new String:arg2[32];
		
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, arg2, sizeof(arg2));
		
		new toggle = StringToInt(arg2)
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
		
		new bool:chat = GetConVarBool(v_Announce);
		
		if (toggle == 1)
		{
			ShowActivity2(client, "\x04[SM] ","\x01Enabled Buddha on \x05%s", target_name);
		}
		else if (toggle == 0)
		{
			ShowActivity2(client, "\x04[SM] ","\x01Disabled Buddha on \x05%s", target_name);
		}
		
		for (new i = 0; i < target_count; i++)
		{	
			if (toggle == 1) //Turn on buddha
			{
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 1, 1);
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has given you \x05Buddha Mode\x01!");
				}
				LogAction(client, target_list[i], "%L enabled buddha on %L", client, target_list[i]);
				g_iState[target_list[i]] = 2;
			}
			
			else if (toggle == 0) //Turn off buddha
			{
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1)
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has removed your \x05Buddha Mode\x01!");
				}
				LogAction(client, target_list[i], "%L disabled buddha on %L", client, target_list[i]);
				g_iState[target_list[i]] = 0;
			}
		}
	}
	
	if (args == 1)
	{
		new String:target[32];
		
		GetCmdArg(1, target, sizeof(target));
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
		
		new bool:chat = GetConVarBool(v_Announce);

		ShowActivity2(client, "\x04[SM] ","\x01Toggled Buddha on \x05%s", target_name);
			
		for (new i = 0; i < target_count; i++)
		{	
			if (g_iState[target_list[i]] != 2) //Mortal or God -> Turn on Buddha
			{
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 1, 1);
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has given you \x05Buddha Mode\x01!");
				}
				LogAction(client, target_list[i], "%L enabled Buddha on %L", client, target_list[i]);
				g_iState[target_list[i]] = 2;
			}
			
			else //Turn off Buddha
			{
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1)
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has removed your \x05Buddha Mode\x01!");
				}
				LogAction(client, target_list[i], "%L disabled Buddha on %L", client, target_list[i]);
				g_iState[target_list[i]] = 0;
			}
		}
	}
	
	return Plugin_Handled;
}



public Action:Command_Mortal( client, args )
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_mortal [#userid|name]");
		return Plugin_Handled;
	}
	
	new bool:isAdmin = CheckCommandAccess(client, "sm_slay", ADMFLAG_KICK);
	
	if (args == 0)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
		ReplyToCommand(client,"\x01[SM] \x04You are now mortal!");
		g_iState[client] = 0;
		return Plugin_Handled;
	}
	
	if (!isAdmin)
	{
		ReplyToCommand(client, "[SM] You are not authorized to target other players");
		return Plugin_Handled;
	}
	
	
	if (args == 1)
	{
		new String:target[32];
		GetCmdArg(1, target, sizeof(target));
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
		
		new bool:chat = GetConVarBool(v_Announce);

		ShowActivity2(client, "\x04[SM] ","\x01Made \x05%s\x01 mortal", target_name);
			
		for (new i = 0; i < target_count; i++)
		{	
			if (g_iState[target_list[i]] != 0) //Not mortal
			{
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
				if (chat)
				{
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has made you \x05Mortal\x01!");
				}
				LogAction(client, target_list[i], "%L made %L mortal", client, target_list[i]);
				g_iState[target_list[i]] = 0;
			}
		}
	}
	
	return Plugin_Handled;
}

stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
}