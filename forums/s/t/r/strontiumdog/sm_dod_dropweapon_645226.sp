//
// SourceMod Script
//
// Developed by <eVa>Dog
// June 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// For Day of Defeat Source only
// This plugin is part of the Realism Mod
// http://forums.alliedmods.net/showthread.php?t=72791
//
//
// CHANGELOG:
// - 07.1.2008 Version 1.0.100

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.101"

new Handle:g_Cvar_Enable = INVALID_HANDLE
new Handle:g_Cvar_Message = INVALID_HANDLE
new Handle:g_Cvar_Headshot = INVALID_HANDLE
new Handle:g_Cvar_Show = INVALID_HANDLE
new String:message[256]

public Plugin:myinfo = 
{
	name = "DoDS Drop Weapon",
	author = "<eVa>Dog",
	description = "Drop Weapon plugin for Day of Defeat Source",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_dod_dropweapon_version", PLUGIN_VERSION, "Version of sm_dod_dropweapon", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_Enable = CreateConVar("sm_dod_dropweapon", "1", "- enables/disables DropWeapon")
	g_Cvar_Message = CreateConVar("sm_dod_dropweapon_message", "You got shot in the arm - pick up your weapon")
	g_Cvar_Headshot = CreateConVar("sm_dod_dropweapon_headshot_message", "made a headshot")
	g_Cvar_Show = CreateConVar("sm_dod_dropweapon_showmessages", "1", " 0 to disable messages, 1 to enable")
	
	HookEvent("player_hurt", PlayerHurtEvent)
}

public OnEventShutdown()
{
	UnhookEvent("player_hurt", PlayerHurtEvent)
}

public PlayerHurtEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client     = GetClientOfUserId(GetEventInt(event, "userid"))
		new attacker   = GetClientOfUserId(GetEventInt(event, "attacker"))
		
		if (client > 0)
		{
			if (attacker > 0)
			{
				new String:weapon[64]  
				GetEventString(event, "weapon", weapon, 64)
				
				new hitgroup = GetEventInt(event, "hitgroup")
				new damage   = GetEventInt(event, "damage")
				
				new String:attacker_name[64]
				GetClientName(attacker, attacker_name, 64)
				
				// Hitgroups
				// 1 = Head
				// 2 = Upper Chest
				// 3 = Lower Chest
				// 4 = Left arm
				// 5 = Right arm
				// 6 = Left leg
				// 7 = Right Leg
				  
				if (!(StrEqual(weapon, "bazooka") || StrEqual(weapon, "pschreck") || StrEqual(weapon, "frag_us") || StrEqual(weapon, "frag_ger") || StrEqual(weapon, "riflegren_us") || StrEqual(weapon, "riflegren_ger")))
				{
					if ((hitgroup == 4) || (hitgroup == 5))
					{
						if (damage >= 40)
						{
							FakeClientCommandEx(client, "drop")
							if (GetConVarInt(g_Cvar_Show) == 1)
							{
								GetConVarString(g_Cvar_Message, message, sizeof(message))
								if (strlen(message) > 0)
								{
									PrintToChat(client,"\x01\x04[SM] %s", message)
								}
							}
						}
					}
					
					if (hitgroup == 1)
					{
						if (GetConVarInt(g_Cvar_Show) == 1)
						{
							GetConVarString(g_Cvar_Headshot, message, sizeof(message))
							if (strlen(message) > 0)
							{
								PrintToChatAll("\x01\x04[SM] %s %s", attacker_name, message)
							}
						}
						else if (GetConVarInt(g_Cvar_Show) == 2)
						{
							GetConVarString(g_Cvar_Headshot, message, sizeof(message))
							if (strlen(message) > 0)
							{
								PrintToChat(attacker, "\x01\x04[SM] %s %s", attacker_name, message)
							}
						}
					}
				}
			}
		}
	}
}