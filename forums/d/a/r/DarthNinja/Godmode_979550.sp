/*
	This code reviewed and approved by Foxes.
*/

#define PLUGIN_VERSION "2.3.1"

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
	RegAdminCmd("sm_god", Command_God, 0, "sm_god [#userid|name] [0/1] - Toggles godmode on player(s)");
	RegAdminCmd("sm_buddha", Command_Buddha, 0, "sm_buddha [#userid|name] [0/1] - Toggles buddha mode on player(s)");
	RegAdminCmd("sm_mortal", Command_Mortal, 0, "sm_mortal [#userid|name] - Makes specified players mortal");

	CreateConVar("sm_godmode_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_Spawn = CreateConVar("sm_godmode_spawn", "0", "1 = Players spawn with godmode, 2 = Players spawn with buddha, 0 = Players spawn mortal", 0, true, 0.0, true, 2.0);
	v_Remember = CreateConVar("sm_godmode_remember", "0", "1 = When players respawn the plugin will return their godmode to whatever it was set to prior to death. 0 = Players will respawn with godmode off.", 0, true, 0.0, true, 1.0);
	v_Announce = CreateConVar("sm_godmode_announce", "1", "Tell players if an admin gives/removes their godmode", 0, true, 0.0, true, 1.0);
	v_SpawnAdminOnly = CreateConVar("sm_godmode_spawn_admins", "0", "1 = Only admins spawn with godmode, 0 = All players spawn with godmode.\n Requires sm_godmode_spawn to be set to a non-zero value", 0, true, 0.0, true, 1.0);
	HookEvent("player_spawn", OnPlayerSpawned);
	LoadTranslations("common.phrases");
}

public OnClientDisconnect(client)
{
	g_iState[client] = 0;
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	//Had godmode on before -> reapply
	if (g_iState[client] != 0 && GetConVarBool(v_Remember))
	{
		new Handle:Packhead;
		CreateDataTimer(0.1, ApplyGodMode, Packhead);
		WritePackCell(Packhead, client);
		WritePackCell(Packhead, 1);
	}
	else
	{
		g_iState[client] = 0;

		if (GetConVarBool(v_SpawnAdminOnly) && !CheckCommandAccess(client, "godmode_adminonly_override", ADMFLAG_SLAY, true))
			return; //admin only mode + not an admin

		if (GetConVarInt(v_Spawn) != 0)
		{
			new Handle:Packhead;
			CreateDataTimer(0.1, ApplyGodMode, Packhead);
			WritePackCell(Packhead, client);
			WritePackCell(Packhead, 0);
		}
	}
}

public Action:ApplyGodMode(Handle:timer, any:Packhead)
{
	ResetPack(Packhead);
	new client = ReadPackCell(Packhead);
	new saved = ReadPackCell(Packhead);
	//CloseHandle(Packhead);
	
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		//Check to see if players are supposed to spawn with damage disabled:
		switch (GetConVarInt(v_Spawn))
		{
			case 1:
			{
				PrintToChat(client,"\x04[SM] \x01You have automatically spawned with \x05God Mode\x01!  You may type \x05!mortal\x01 to turn it off.");
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				g_iState[client] = 1;
				return Plugin_Handled;
			}
			case 2:
			{
				PrintToChat(client,"\x04[SM] \x01You have automatically spawned with \x05Buddha Mode\x01!  You may type \x05!mortal\x01 to turn it off.");
				SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
				g_iState[client] = 2;
				return Plugin_Handled;
			}
		}

		// Plugin is set to remember godmode states
		if (saved)
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
				//default:
					//SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);	//Mortal
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_God(client, args)
{
	if (args != 0 && !CheckCommandAccess(client, "sm_godmode_admin", ADMFLAG_SLAY, true))
	{
		ReplyToCommand(client, "[SM] Usage: sm_god");
		return Plugin_Handled;
	}
	if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_god [#userid|name] [0/1]");
		return Plugin_Handled;
	}

	if (args == 0)
	{
		if (!IsClientConnected(client) || !IsPlayerAlive(client))
			return Plugin_Handled;

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

	// Player is an admin and is using 1 or more args
	new String:target[32];
	new String:toggle[3];
	GetCmdArg(1, target, sizeof(target));
	new iToggle = -1;
	if (args > 1)
	{
		GetCmdArg(2, toggle, sizeof(toggle));
		iToggle = StringToInt(toggle);
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
		target,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

	new bool:bAnnounce = GetConVarBool(v_Announce);

	if (iToggle == 1)	 //Turn on godmode
	{
		ShowActivity2(client, "\x04[SM] ","\x01Enabled God Mode on \x05%s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			if (bAnnounce)
				PrintToChat(target_list[i],"\x04[SM] \x01An admin has given you \x05God Mode\x01!");
			LogAction(client, target_list[i], "%L enabled godmode on %L", client, target_list[i]);
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 0, 1);
			g_iState[target_list[i]] = 1;
		}
	}
	else if (iToggle == 0) //Turn off godmode
	{
		ShowActivity2(client, "\x04[SM] ","\x01Disabled God Mode on \x05%s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			if (bAnnounce)
				PrintToChat(target_list[i],"\x04[SM] \x01An admin has removed your \x05God Mode\x01!");
			LogAction(client, target_list[i], "%L disabled godmode on %L", client, target_list[i]);
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
			g_iState[target_list[i]] = 0;
		}
	}
	else
	{
		ShowActivity2(client, "\x04[SM] ", "\x01Toggled God Mode on \x05%s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			if (g_iState[target_list[i]] != 1) //Mortal or Buddha -> Turn on godmode
			{
				if (bAnnounce)
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has given you \x05God Mode\x01!");
				LogAction(client, target_list[i], "%L enabled godmode on %L", client, target_list[i]);
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 0, 1);
				g_iState[target_list[i]] = 1;
			}
			else //Turn off godmode
			{
				if (bAnnounce)
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has removed your \x05God Mode\x01!");
				LogAction(client, target_list[i], "%L disabled godmode on %L", client, target_list[i]);
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
				g_iState[target_list[i]] = 0;
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_Buddha(client, args)
{
	if (args != 0 && !CheckCommandAccess(client, "sm_buddhamode_admin", ADMFLAG_SLAY, true))
	{
		ReplyToCommand(client, "[SM] Usage: sm_buddha");
		return Plugin_Handled;
	}
	if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_buddha [#userid|name] [0/1]");
		return Plugin_Handled;
	}

	if (args == 0)
	{
		if (!IsClientConnected(client) || !IsPlayerAlive(client))
			return Plugin_Handled;

		if (g_iState[client] != 2) //Mortal or God
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
			ReplyToCommand(client,"\x01[SM] \x04Buddha Mode on");
			g_iState[client] = 2;
		}
		else // GodMode on
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			ReplyToCommand(client,"\x01[SM] \x04Buddha Mode off");
			g_iState[client] = 0;
		}
		return Plugin_Handled;
	}

	// Player is an admin and is using 1 or more args
	new String:target[32];
	new String:toggle[3];
	GetCmdArg(1, target, sizeof(target));
	new iToggle = -1;
	if (args > 1)
	{
		GetCmdArg(2, toggle, sizeof(toggle));
		iToggle = StringToInt(toggle);
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
		target,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

	new bool:bAnnounce = GetConVarBool(v_Announce);

	if (iToggle == 1)	 //Turn on Buddha
	{
		ShowActivity2(client, "\x04[SM] ","\x01Enabled Buddha Mode on \x05%s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			if (bAnnounce)
				PrintToChat(target_list[i],"\x04[SM] \x01An admin has given you \x05Buddha Mode\x01!");
			LogAction(client, target_list[i], "%L enabled buddha mode on %L", client, target_list[i]);
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 1, 1);
			g_iState[target_list[i]] = 2;
		}
	}
	else if (iToggle == 0) //Turn off Buddha
	{
		ShowActivity2(client, "\x04[SM] ","\x01Disabled Buddha Mode on \x05%s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			if (bAnnounce)
				PrintToChat(target_list[i],"\x04[SM] \x01An admin has removed your \x05Buddha Mode\x01!");
			LogAction(client, target_list[i], "%L disabled buddha mode on %L", client, target_list[i]);
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
			g_iState[target_list[i]] = 0;
		}
	}
	else
	{
		ShowActivity2(client, "\x04[SM] ", "\x01Toggled Buddha Mode on \x05%s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			if (g_iState[target_list[i]] != 2) //Mortal or God -> Turn on Buddha
			{
				if (bAnnounce)
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has given you \x05Buddha Mode\x01!");
				LogAction(client, target_list[i], "%L enabled buddha mode on %L", client, target_list[i]);
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 1, 1);
				g_iState[target_list[i]] = 2;
			}
			else //Turn off godmode
			{
				if (bAnnounce)
					PrintToChat(target_list[i],"\x04[SM] \x01An admin has removed your \x05God Mode\x01!");
				LogAction(client, target_list[i], "%L disabled buddha mode on %L", client, target_list[i]);
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
				g_iState[target_list[i]] = 0;
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_Mortal( client, args )
{	
	if (args != 0 && !CheckCommandAccess(client, "sm_mortalmode_admin", ADMFLAG_SLAY, true))
	{
		ReplyToCommand(client, "[SM] Usage: sm_mortal");
		return Plugin_Handled;
	}
	if (args < 0 || args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_mortal [#userid|name]");
		return Plugin_Handled;
	}
	
	if (args == 0)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
		ReplyToCommand(client,"\x01[SM] \x04You are now mortal!");
		g_iState[client] = 0;
		return Plugin_Handled;
	}

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
			if (chat)
				PrintToChat(target_list[i],"\x04[SM] \x01An admin has made you \x05Mortal\x01!");
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
			LogAction(client, target_list[i], "%L made %L mortal", client, target_list[i]);
			g_iState[target_list[i]] = 0;
		}
	}
	return Plugin_Handled;
}
