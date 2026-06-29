#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <smlib>

#pragma semicolon 1

#define PL_VERSION "1.5"

// Arrays
new gI_LastUsed[MAXPLAYERS+1]; 
new bool:gB_Autojump[MAXPLAYERS+1];

// Global booleans
new bool:gB_Enabled;
new bool:gB_AutojumpCVar;
new bool:gB_Weapons;
new bool:gB_Gravity;
new bool:gB_Falldamage;
new bool:gB_Notifications;

// Global handles
new Handle:gH_Enabled = INVALID_HANDLE;
new Handle:gH_AutojumpCVar = INVALID_HANDLE;
new Handle:gH_Weapons = INVALID_HANDLE;
new Handle:gH_Gravity = INVALID_HANDLE;
new Handle:gH_Falldamage = INVALID_HANDLE;
new Handle:gH_Notifications = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Bunnyhop Commands (Redux)",
	author = "ml/TimeBomb",
	description = "This plugin features many useful features for bunnyhop servers aka AIO bhop server plugin.",
	version = PL_VERSION,
	url = "not vgames"
}

public OnPluginStart()
{
	// Bhop menu
	RegConsoleCmd("sm_bhop", Cmd_Bhop, "Show the menu of available commands.");
	RegConsoleCmd("sm_commands", Cmd_Bhop, "Show the menu of available commands.");
	
	// Weapons
	RegConsoleCmd("sm_guns", Cmd_Weapons, "Show the menu of the available weapons.");
	RegConsoleCmd("sm_weapons", Cmd_Weapons, "Show the menu of the available weapons.");
	
	// Auto jump
	RegConsoleCmd("sm_aj", Cmd_AJ, "Change your autojump status. Usage: sm_autojump <1/0>");
	RegConsoleCmd("sm_autojump", Cmd_AJ, "Change your autojump status. Usage: sm_autojump <1/0>");
	
	// Gravity
	RegConsoleCmd("sm_grav", Cmd_Gravity, "Show the menu of the gravity changes.");
	RegConsoleCmd("sm_gravity", Cmd_Gravity, "Show the menu of the gravity changes.");
	
	// Cvars
	CreateConVar("sm_bhopredux_version", PL_VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	gH_Enabled = CreateConVar("sm_bhopredux_enabled", "1", "Bunnyhop Commands (Redux) is enabled?", FCVAR_PLUGIN, true, _, true, 1.0);
	gH_AutojumpCVar = CreateConVar("sm_bhopredux_autojump", "1", "Enable auto jumping?", FCVAR_PLUGIN, true, _, true, 1.0);
	gH_Weapons = CreateConVar("sm_bhopredux_weapons", "1", "Allow weapon spawning?", FCVAR_PLUGIN, true, _, true, 1.0);
	gH_Gravity = CreateConVar("sm_bhopredux_gravity", "1", "Allow gravity changing?", FCVAR_PLUGIN, true, _, true, 1.0);
	gH_Falldamage = CreateConVar("sm_bhopredux_falldamage", "1", "Disable damaged caused by falling?", FCVAR_PLUGIN, true, _, true, 1.0);
	gH_Notifications = CreateConVar("sm_bhopredux_noti", "1", "Notificate the players each time a cvar has been changed?", FCVAR_PLUGIN, true, _, true, 1.0);
	
	gB_Enabled = true;
	gB_AutojumpCVar = true;
	gB_Weapons = true;
	gB_Gravity = true;
	gB_Falldamage = true;
	gB_Notifications = true;
	
	HookConVarChange(gH_Enabled, OnCvarChanged);
	HookConVarChange(gH_AutojumpCVar, OnCvarChanged);
	HookConVarChange(gH_Weapons, OnCvarChanged);
	HookConVarChange(gH_Gravity, OnCvarChanged);
	HookConVarChange(gH_Falldamage, OnCvarChanged);
	HookConVarChange(gH_Notifications, OnCvarChanged);
	
	AutoExecConfig(true, "bhopcommands_redux");
}

public OnCvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = StringToInt(newVal)? true:false;
		
		if(gB_Enabled && gB_Notifications)
		{
			PrintToChatAll("\x04[SM]\x01 Bunnyhop Commands plugin is now \x04%sabled", StringToInt(newVal)? "en":"dis");
		}
	}
	
	else if(cvar == gH_AutojumpCVar)
	{
		gB_AutojumpCVar = StringToInt(newVal)? true:false;
		
		if(gB_Enabled && gB_Notifications)
		{
			PrintToChatAll("\x04[SM]\x01 Auto jumping is now \x04%sabled", StringToInt(newVal)? "en":"dis");
		}
	}
	
	else if(cvar == gH_Weapons)
	{
		gB_Weapons = StringToInt(newVal)? true:false;
		
		if(gB_Enabled && gB_Notifications)
		{
			PrintToChatAll("\x04[SM]\x01 Weapon spawning is now \x04%sabled", StringToInt(newVal)? "en":"dis");
		}
	}
	
	else if(cvar == gH_Gravity)
	{
		gB_Gravity = StringToInt(newVal)? true:false;
		
		if(gB_Enabled && gB_Notifications)
		{
			PrintToChatAll("\x04[SM]\x01 Gravity changing is now \x04%sabled", StringToInt(newVal)? "en":"dis");
		}
		
		if(!gB_Gravity)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i))
				{
					SetEntityGravity(i, 1.0);
				}
			}
		}
	}
	
	else if(cvar == gH_Falldamage)
	{
		gB_Falldamage = StringToInt(newVal)? true:false;
		
		if(gB_Enabled && gB_Notifications)
		{
			PrintToChatAll("\x04[SM]\x01 Fall damage is now \x04%sabled", StringToInt(newVal)? "dis":"en");
		}
	}
	
	else if(cvar == gH_Notifications)
	{
		gB_Notifications = StringToInt(newVal)? true:false;
		
		if(gB_Enabled && gB_Notifications)
		{
			PrintToChatAll("\x04[SM]\x01 Fall damage is now \x04%sabled", StringToInt(newVal)? "dis":"en");
		}
	}
}

public OnClientPutInServer(client)
{
	gB_Autojump[client] = true;
	gI_LastUsed[client] = 0;
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!gB_Enabled || !gB_Falldamage)
	{
		return Plugin_Continue;
	}
	
	if(!IsValidClient(attacker) || !IsValidClient(victim, true))
	{
		return Plugin_Continue;
	}
	
	if(damagetype & DMG_FALL)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:Cmd_Gravity(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "\x04[SM]\x01 This plugin is disabled.");
		return Plugin_Handled;
	}
	
	if(!gB_Gravity)
	{
		ReplyToCommand(client, "\x04[SM]\x01 This feature is disabled.");
		return Plugin_Handled;
	}
	
	new Handle:menu = CreateMenu(Gravity_MenuHandler, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "Gravity Menu:\nHello %N! This is your gravity menu, you can change your gravity to any available option.", client);
	AddMenuItem(menu, "0.3", "Super low gravity (30%)");
	AddMenuItem(menu, "0.5", "Low gravity (50%)");
	AddMenuItem(menu, "0.7", "Medium gravity (70%)");
	AddMenuItem(menu, "1.0", "Normal gravity (100%)");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public Gravity_MenuHandler(Handle:menu, MenuAction:action, client, choice)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!gB_Enabled || !gB_Gravity)
			{
				return 0;
			}
			
			new String:sGravity[8];
			GetMenuItem(menu, choice, sGravity, 8);
			SetEntityGravity(client, StringToFloat(sGravity));
			PrintToChat(client, "\x04[SM]\x01 Gravity set to %s.", sGravity);
		}
		
		case MenuAction_Cancel:
		{
			if(choice == MenuEnd_ExitBack)
			{
				Cmd_Bhop(client, 0);
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
	
	return 0;
}

public Action:Cmd_Weapons(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "\x04[SM]\x01 This plugin is disabled.");
		return Plugin_Handled;
	}
	
	if(!gB_Weapons)
	{
		ReplyToCommand(client, "\x04[SM]\x01 This feature is disabled.");
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "\x04[SM]\x01 You can't use this command while you're dead.");
		return Plugin_Handled;
	}
	
	new bool:secondary;
	new bool:primary;
	
	if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1)
	{
		primary = true;
	}
	
	if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1)
	{
		secondary = true;
	}
	
	new Handle:menu = CreateMenu(Weapons_MenuHandler, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "Weapons Menu:\nHello %N! This is your weapons menu, you may spawn any weapon within a delay of 15\nseconds each spawn and must to not have any weapon equipped in the slot of the weapon that you wanna spawn.", client);
	AddMenuItem(menu, "weapon_usp", "USP (secondary)", secondary? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "weapon_deagle", "Desert Eagle (secondary)", secondary? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "weapon_scout", "Schimdt Scout (primary)", primary? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	AddMenuItem(menu, "weapon_awp", "Magnum Snipe Rifle AWP (primary)", primary? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public Weapons_MenuHandler(Handle:menu, MenuAction:action, client, choice)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!gB_Enabled || !gB_Weapons)
			{
				return 0;
			}
			
			if(!IsPlayerAlive(client))
			{
				PrintToChat(client, "\x04[SM]\x01 You can't use this command while you're dead.");
				return 0;
			}
			
			new Time = GetTime();
			if(Time - gI_LastUsed[client] < 15)
			{
				PrintToChat(client, "\x04[SM]\x01 Unable to spawn a weapon, you need to wait %d seconds before you can spawn a weapon again", Time - gI_LastUsed[client]);
				return 0;
			}
			
			gI_LastUsed[client] = Time;
			
			new String:Weapon[32];
			GetMenuItem(menu, choice, Weapon, 32);
			GivePlayerItem(client, Weapon);
			ReplaceString(Weapon, 32, "weapon_", "");
			PrintToChat(client, "\x04[SM]\x01 Given %s.", Weapon);
			Cmd_Weapons(client, 0);
		}
		
		case MenuAction_Cancel:
		{
			if(choice == MenuEnd_ExitBack)
			{
				Cmd_Bhop(client, 0);
			}
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
	
	return 0;
}

public Action:Cmd_Bhop(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "\x04[SM]\x01 This plugin is disabled.");
		return Plugin_Handled;
	}
	
	new Handle:menu = CreateMenu(Bhop_MenuHandler, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "Bunnyhop Commands Menu:\nHello %N! This is your commands menu.", client);
	new String:Autojump[255];
	Format(Autojump, 255, "Toggle your autojump status [%s] (!autojump)", gB_Autojump[client]? "ENABLED":"DISABLED");
	AddMenuItem(menu, gB_Autojump[client]? "sm_autojump 0":"sm_autojump 1", Autojump, gB_AutojumpCVar? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(menu, "sm_weapons", "Spawn a weapon (!weapons)", gB_Weapons? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(menu, "sm_gravity", "Change your gravity (!gravity)", gB_Gravity? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public Bhop_MenuHandler(Handle:menu, MenuAction:action, client, choice)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:Cmd[32];
			GetMenuItem(menu, choice, Cmd, 32);
			FakeClientCommand(client, Cmd);
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
	
	return 0;
}

public Action:Cmd_AJ(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "\x04[SM]\x01 This plugin is disabled.");
		return Plugin_Handled;
	}
	
	if(!gB_AutojumpCVar)
	{
		ReplyToCommand(client, "\x04[SM]\x01 This feature is disabled.");
		return Plugin_Handled;
	}
	
	if(args != 0)
	{
		ReplyToCommand(client, "\x04[SM]\x01 Usage: !autojump <0/1>.");
		return Plugin_Handled;
	}
	
	new String:arg1[8];
	GetCmdArg(1, arg1, 8);
	gB_Autojump[client] = StringToInt(arg1)? true:false;
	ReplyToCommand(client, "\x04[SM]\x01 Auto jumping is now \x04%sabled\x01.", StringToInt(arg1)? "en":"dis");
	
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!bhoppass(client))
	{
		return Plugin_Continue;
	}
	
	if(buttons & IN_JUMP)
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND))
		{
			buttons &= ~IN_JUMP;
		}
	}

	
	return Plugin_Continue;
}

stock bool:bhoppass(client)
{
	if(!IsValidClient(client, true))
	{
		return false;
	}
	
	if(!gB_Enabled || !gB_AutojumpCVar || !gB_Autojump[client] || Client_IsOnLadder(client) || Client_GetWaterLevel(client) > Water_Level:WATER_LEVEL_FEET_IN_WATER)
	{
		return false;
	}
	
	return true;
}

stock bool:IsValidClient(client, bool:alive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (!alive || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}