/** Change Log
 **
 ** 1.0.0: Initial Release.
 ** 1.1.0: -Allow users to block TP requests from other users, or all users.
 **        -Allow admins to bring clients to them without authorization. Did not make available to clients because its functionality is so similar to sm_goto
 **        -Fixed an Invalid Handle error
 ** 1.2.0: -Actually fixed the Invalid Handle error...
 **        -Added function to allow users to ACCEPT all TP requests without displaying a menu
 **        -Cleaned up code a bit
 ** 1.3.0: -Added a teleport back command (sm_tpb or sm_goback)
 ** 1.3.1: -Cvar to prevent users from teleporting to their previous location more than once. Prevents its usage as a checkpoint.
 ** 1.3.2: -Fixed (cleaned up) usage of TeleportStatus enum
 ** 1.3.3: -Added Cvar to make the plugin Admin Only
 ** 1.3.4: -Code fixes, thanks to 11530
 **
 **/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3.4"

enum TeleportStatus
{
	NotifyAll = 0,
	DenyAll,
	AcceptAll
};

new Handle:CooldownTime = INVALID_HANDLE;
new Handle:AdminBypass = INVALID_HANDLE;
new Handle:AdminAuthBypass = INVALID_HANDLE;
new Handle:CooldownTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:TargetOppositeTeam = INVALID_HANDLE;
new Handle:Version = INVALID_HANDLE;
new Handle:TeleportBackLimit = INVALID_HANDLE;
new Handle:AdminsOnly = INVALID_HANDLE;
new InCooldown[MAXPLAYERS + 1] = false;
new String:BypassFlagString[10];
new String:AuthBypassFlagString[10];
new String:AdminFlagString[10];
new BypassFlagBit;
new AuthBypassFlagBit;
new AdminFlagBit = 0;
new Float:CooldownTimeLeft[MAXPLAYERS + 1];
new Float:LastLocation[MAXPLAYERS + 1][3];

new BlockedPlayer[MAXPLAYERS + 1][MAXPLAYERS + 1]; //[client][blocked player]
new TeleportStatus:PlayerStatus[MAXPLAYERS + 1];


public Plugin:myinfo =
{
	name = "GoTo Players",
	author = "BB",
	description = "Allows players to teleport to other players",
	version = PLUGIN_VERSION,
};

public OnPluginStart()
{
	CooldownTime = CreateConVar("gt_cooldowntime", "60.0", "Time between a player's use of the goto command.");
	AdminBypass = CreateConVar("gt_admin_cooldown_bypass", "c", "Admin flag required to bypass the cooldown time.");
	AdminAuthBypass = CreateConVar("gt_admin_auth_bypass", "z", "Admin flag required to bypass authorization of command.");
	TargetOppositeTeam = CreateConVar("gt_target_opposite_team", "1", "Allow users to target members of the opposite team.");
	TeleportBackLimit = CreateConVar("gt_teleport_back_limit", "0", "Prevent users from teleporting back to their saved location multiple times.");
	AdminsOnly = CreateConVar("gt_admins_only", "0", "0 - Anyone can use. Otherwise, enter the flag that should be allowed to use the command.");
	RegConsoleCmd("sm_goto", Command_GoTo, "Teleport to a player");
	RegConsoleCmd("sm_unblock", Command_Unblock, "Unblock a player or all players");
	RegConsoleCmd("sm_tpb", Command_GoBack, "Teleport to your last location");
	RegConsoleCmd("sm_goback", Command_GoBack, "Teleport to your last location");
	RegAdminCmd("sm_bring", Command_Bring, ADMFLAG_KICK, "Bring a player to you");
	Version = CreateConVar("goto_ver", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(Version, PLUGIN_VERSION, _, true);
	
	AutoExecConfig(true, "goto");
	
	LoadTranslations("common.phrases.txt");
}

public OnConfigsExecuted()
{
	GetConVarString(AdminBypass, BypassFlagString, sizeof(BypassFlagString));
	BypassFlagBit = ReadFlagString(BypassFlagString);
	
	GetConVarString(AdminAuthBypass, AuthBypassFlagString, sizeof(AuthBypassFlagString));
	AuthBypassFlagBit = ReadFlagString(AuthBypassFlagString);
	
	GetConVarString(AdminsOnly, AdminFlagString, sizeof(AdminFlagString));
	if(StrEqual(AdminFlagString, "0") == false)
		AdminFlagBit = ReadFlagString(AdminFlagString);
}

public OnClientPostAdminCheck(client)
{
	ClearTimer(CooldownTimer[client]);
	
	if(InCooldown[client])
		InCooldown[client] = false;
	LastLocation[client][0] = 0.0;
	LastLocation[client][1] = 0.0;
	LastLocation[client][2] = 0.0;
}

public OnClientDisconnect(client)
{
	ClearTimer(CooldownTimer[client]);
	
	InCooldown[client] = false;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		BlockedPlayer[i][client] = 0;
	}
	
	PlayerStatus[client] = NotifyAll;
	
	LastLocation[client][0] = 0.0;
	LastLocation[client][1] = 0.0;
	LastLocation[client][2] = 0.0;
}

public Action:Command_GoTo(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "\x03[SM] Usage: sm_goto <player>");
		return Plugin_Handled;
	}
	if(client < 1)
	{
		ReplyToCommand(client, "[SM] This can only be used in game.");
		return Plugin_Handled;
	}
	
	if(GetUserFlagBits(client) & AuthBypassFlagBit)
	{
		if(IsPlayerAlive(client))
		{
			new player;
			new String:target[32];
			GetCmdArg(1, target, sizeof(target));

			player = FindTarget(client, target, true, false);
			
			if(player != -1)
			{
				if(IsClientInGame(player))
				{
					if(IsPlayerAlive(player))
					{
						TeleportPlayer(client, player);
						return Plugin_Handled;
					}
					else
					{
						PrintToChat(client, "\x03[SM] %N is not alive.", player);
						return Plugin_Handled;
					}
				}
			}
			else
			{
				PrintToChat(client, "\x03[SM] Invalid target: %s", target);
				return Plugin_Handled;
			}
		}
		else
			PrintToChat(client, "\x03[SM] You must be alive to use this command.");
		
		return Plugin_Handled;
	}
	else if(AdminFlagBit == 0 || (GetUserFlagBits(client) & AdminFlagBit))
	{
		if(!InCooldown[client] || (GetUserFlagBits(client) & BypassFlagBit))
		{
			if(IsPlayerAlive(client))
			{
				new player;
				new String:target[32];
				GetCmdArg(1, target, sizeof(target));

				player = FindTarget(client, target, true, false);
				
				if(player != -1)
				{
					if(IsClientInGame(player))
					{
						if(!BlockedPlayer[player][client] && PlayerStatus[player] != DenyAll)
						{
							if(IsPlayerAlive(player))
							{
								if(GetClientTeam(player) != GetClientTeam(client) && GetConVarInt(TargetOppositeTeam) == 0)
								{
									PrintToChat(client, "\x03[SM] You cannot target player on the opposite team.");
									return Plugin_Handled;
								}
								else
								{
									if(PlayerStatus[player] == AcceptAll)
									{
										TeleportPlayer(client, player);
										return Plugin_Handled;
									}
									else
									{
										AskMenu(client, player);
										PrintToChat(client, "\x03[SM] Sent a teleport request to %N.", player);
									}
								}
								
							}
						}
						else
						{
							PrintToChat(client, "\x03[SM] %N does not accept teleport requests.", player);
							return Plugin_Handled;
						}
					}
				}
				else
				{
					PrintToChat(client, "\x03[SM] Invalid target: %s", target);
					return Plugin_Handled;
				}
			}
			else
			{
				PrintToChat(client, "\x03[SM] You must be alive to use this command.");
				return Plugin_Handled;
			}
		}
		else
			PrintToChat(client, "\x03[SM] You are in cool down stage for %.1f seconds", (CooldownTimeLeft[client] - GetGameTime()));
	}
	else
		PrintToChat(client, "\x03[SM] Only admins may use this command.");	
	return Plugin_Handled;
}
public Action:Command_Bring(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "\x03[SM] Usage: sm_bring <player>");
		return Plugin_Handled;
	}
	if(client < 1)
	{
		ReplyToCommand(client, "[SM] This can only be used in game.");
		return Plugin_Handled;
	}
	
	new player;
	new String:target[32];
	GetCmdArg(1, target, sizeof(target));

	player = FindTarget(client, target);
	if(player != -1)
	{
		if(IsClientInGame(player))
		{
			if(IsPlayerAlive(client))
			{
				if(IsPlayerAlive(player))
				{
					TeleportPlayer(player, client);
					return Plugin_Handled;
				}
				else
				{
					PrintToChat(client, "\x03[SM] %N is not alive.", player);
					return Plugin_Handled;
				}
			}
			else
			{
				PrintToChat(client, "\x03[SM] You must be alive to use this command.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}
		
TeleportPlayer(client, target)
{
	new Float:coords[3];
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", LastLocation[client]);
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", coords);
	
	TeleportEntity(client, coords, NULL_VECTOR, NULL_VECTOR);
	PrintToChat(client, "\x03[SM] You teleported to %N. Type !tpb to teleport back to your last location.", target);
}
	
AskMenu(client, target)
{
	if(IsClientInGame(target) && IsPlayerAlive(target))
	{
		new Handle:Menu = CreateMenu(AskMenu_Handler);
		new String:asker[12];
		new userid = GetClientUserId(client)
		IntToString(userid, asker, sizeof(asker));
		//Format(asker, sizeof(asker), "%i", client);
		
		SetMenuTitle(Menu, "Allow %N to teleport to you?", client);
		AddMenuItem(Menu, asker, "Yes");
		AddMenuItem(Menu, asker, "No");
		AddMenuItem(Menu, asker, "Block this user");
		AddMenuItem(Menu, asker, "Block ALL users");
		AddMenuItem(Menu, asker, "Accept ALL requests");
		DisplayMenu(Menu, target, 20);
		if(!(GetUserFlagBits(client) & BypassFlagBit))
		{
			InCooldown[client] = true;
			CooldownTimer[client] = CreateTimer(GetConVarFloat(CooldownTime), ResetCooldown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			CooldownTimeLeft[client] = GetGameTime() + GetConVarInt(CooldownTime);
		}
	}
}

public AskMenu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
//param 1 is client of teleport target
//param 2 is response of target. 0 = accept 1 = deny
	decl String:info[32];
	
	GetMenuItem(menu, param2, info, sizeof(info));
	
	new client = GetClientOfUserId(StringToInt(info));
	
	if(action == MenuAction_Select)
	{
		if(IsClientInGame(param1) && IsPlayerAlive(param1))
		{
			switch(param2)
			{
				case 0:
				{
					TeleportPlayer(client, param1);
				}
				case 1:
				{
					PrintToChat(client, "\x03[SM] %N denied your teleport request.", param1);
				}
				case 2:
				{
					PrintToChat(client, "\x03[SM] %N denied your request and blocked you.", param1);
					PrintToChat(param1, "\x03[SM] You blocked %N. Type !unblock <player> to unblock them.", client);
					BlockedPlayer[param1][client] = 1;
				}
				case 3:
				{
					PrintToChat(client, "\x03[SM] %N does not allow users to teleport to him.", param1);
					PrintToChat(param1, "\x03[SM] You blocked all players.");
					PlayerStatus[param1] = DenyAll;
				}
				case 4:
				{
					TeleportPlayer(client, param1);
					PlayerStatus[param1] = AcceptAll;
					PrintToChat(param1, "\x03 [SM] You will no longer be notified of teleport requests.");
				}
					
			}
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Command_Unblock(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "\x03[SM] Usage: sm_unblock <player|all>");
		return Plugin_Handled;
	}
	if(client < 1)
	{
		ReplyToCommand(client, "[SM] This can only be used in game.");
		return Plugin_Handled;
	}
	
	new String:target[32];
	GetCmdArg(1, target, sizeof(target));
	
	if(StrEqual(target, "all"))
	{
		PlayerStatus[client] = NotifyAll;
		for(new i = 1; i <= MaxClients; i++)
		{
			BlockedPlayer[client][i] = 0;
		}
		PrintToChat(client, "\x03[SM] You will now accept teleport requests from users.");
		return Plugin_Handled;
	}

	new player = FindTarget(client, target, true, false);
	if(player != -1)
	{
		BlockedPlayer[client][player] = 0;
		PrintToChat(client, "\x03[SM] You unblocked %N", player);
	}
	
	return Plugin_Handled;
}

public Action:Command_GoBack(client, args)
{
	if(client < 1)
	{
		ReplyToCommand(client, "[SM] This can only be used in game.");
		return Plugin_Handled;
	}
	
	if((LastLocation[client][0] == 0.0) && (LastLocation[client][1] == 0.0) && (LastLocation[client][2] == 0.0))
	{
		PrintToChat(client, "\x03[SM] You do not have a saved location.");
		return Plugin_Handled;
	}
	
	TeleportEntity(client, LastLocation[client], NULL_VECTOR, NULL_VECTOR);
	if(GetConVarInt(TeleportBackLimit))
	{
		LastLocation[client][0] = 0.0;
		LastLocation[client][1] = 0.0;
		LastLocation[client][2] = 0.0;
	}
	return Plugin_Handled;
}
	
	
public Action:ResetCooldown(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0)
	{
		InCooldown[client] = false;
		CooldownTimer[client] = INVALID_HANDLE;
	}
}

stock ClearTimer(&Handle:CDTimer)
{
    if(CDTimer != INVALID_HANDLE)
    {
        CloseHandle(CDTimer);
        CDTimer = INVALID_HANDLE;
    }
}  
	