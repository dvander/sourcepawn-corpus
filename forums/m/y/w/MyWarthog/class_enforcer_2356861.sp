/* [TF2] Class Enforcer
 * Plugin originally written by: linux_lover
 *
 * Changelog:
 *
 * 0.3.0 10/25/2015 - mywarthog:
 * - The admin flag is no longer hardcoded.
 *   - Added override sm_ce_forceimmuned
 *   - Immunity defaults to the Slay Flag (f)
 * - Added announcements (sm_ce_announce -1/0/1/2)
 * - Added change forced class restarting (sm_ce_restart_type 0/1/2)
 * - The plugin now works on bots.
 * - Started a changelog
 * - The config file is now automatically generated.
 * - Announces the classes to the server at the start of a round, controlled by a new CVar: sm_ce_announce
 * - Added a way to select a Round Restart type: CVar sm_ce_restart_type
 * - Added FCVAR_DONTRECORD to the Plugin's Version CVar definition
 * - Added a default class for both the sm_ce_blue and the sm_ce_red ConVars.
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.3.0"

new Handle:c_Enabled;
new Handle:c_classBlue;
new Handle:c_classRed;
new Handle:c_adminOveride; 
new Handle:c_randomRounds;
new Handle:c_roundStartAnnounce;
new Handle:c_restartType;

new g_iRandomRed;
new g_iRandomBlue;

new TFClassType:g_iRedClass = TFClass_Unknown;
new TFClassType:g_iBlueClass = TFClass_Unknown;

new const String:g_strClassPrint[][] = {"", "Scout", "Sniper", "Soldier", "Demo", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};

public Plugin:myinfo = 
{
	name = "Class Enforcer",
	author = "linux_lover",
	description = "Restricts RED/BLUE to one class.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart()
{
	CreateConVar("sm_ce_version", PLUGIN_VERSION, "Class Enforcer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_Enabled      = CreateConVar("sm_ce_enable", "0", "Enable/Disable Class Enforcer");
	c_classBlue    = CreateConVar("sm_ce_blue", "scout", "Forced class for the Blue team.");
	c_classRed     = CreateConVar("sm_ce_red", "scout", "Forced class for the Red team.");
	c_adminOveride = CreateConVar("sm_ce_admin", "0", "Enable/Disable admin immunity. Controlled by the override sm_ce_forceimmuned, defaults to the slay flag (f).");
	c_randomRounds = CreateConVar("sm_ce_random", "0", "Random forced class.");
	c_roundStartAnnounce = CreateConVar("sm_ce_announce", "0", "Type of announcement to make on round start. -1 = Off, 0 = Chat, 1 = Center HUD, 2 = Hint Box.");
	c_restartType = CreateConVar("sm_ce_restart_type", "0", "Restart round type. 0 = Disabled/Off, 1 = Restart the round, 2 = Respawn all Players.");

	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("teamplay_round_win", ChooseRandomClass);
	HookEvent("teamplay_round_stalemate", ChooseRandomClass);
	HookEvent("teamplay_round_start", AnnounceClassesToServer);

	HookConVarChange(c_randomRounds, ConVarChange_Rounds);
	HookConVarChange(c_classBlue, ConVarChange_Class);
	HookConVarChange(c_classRed, ConVarChange_Class);
	HookConVarChange(c_restartType, ConVarChange_RestartType);
	HookConVarChange(c_roundStartAnnounce, ConVarChange_Announce);

	AutoExecConfig(true, "plugin.class_enforcer");
}

public OnMapStart()
{
	g_iRandomBlue = GetRandomInt(1, 9);
	g_iRandomRed = GetRandomInt(1, 9);
}

public OnConfigsExecuted()
{
	ParseClassStrings();
	if (GetConVarBool(c_Enabled) && GetConVarInt(c_restartType) > 0)
	{
		switch (GetConVarInt(c_restartType))
		{
			case 1:
			{
				SetConVarInt(FindConVar("mp_restartgame"), 1);
			}
			case 2:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) != 1  && GetClientTeam(i) != 0)
					{
						if (TF2_GetPlayerClass(i) == TFClass_DemoMan || TF2_GetPlayerClass(i) == TFClass_Engineer || TF2_GetPlayerClass(i) == TFClass_Spy)
						{
							EntityCheck(i);
						}
						TF2_RespawnPlayer(i);
					}
				} 
			}
			default:
			{
			
			}
		}
	}
}

public ConVarChange_Rounds(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iRandomBlue = GetRandomInt(1, 9);
	g_iRandomRed = GetRandomInt(1, 9);
	if (GetConVarBool(c_Enabled) && GetConVarInt(c_restartType) > 0)
	{
		switch (GetConVarInt(c_restartType))
		{
			case 1:
			{
				SetConVarInt(FindConVar("mp_restartgame"), 1);
			}
			case 2:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) != 1  && GetClientTeam(i) != 0)
					{
						if (TF2_GetPlayerClass(i) == TFClass_DemoMan || TF2_GetPlayerClass(i) == TFClass_Engineer || TF2_GetPlayerClass(i) == TFClass_Spy)
						{
							EntityCheck(i);
						}
						TF2_RespawnPlayer(i);
					}
				} 
			}
			default:
			{
			
			}
		}
	}
}

public ConVarChange_Class(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ParseClassStrings();
	if (GetConVarBool(c_Enabled) && GetConVarInt(c_restartType) > 0)
	{
		switch (GetConVarInt(c_restartType))
		{
			case 1:
			{
				SetConVarInt(FindConVar("mp_restartgame"), 1);
			}
			case 2:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) != 1  && GetClientTeam(i) != 0)
					{
						if (TF2_GetPlayerClass(i) == TFClass_DemoMan || TF2_GetPlayerClass(i) == TFClass_Engineer || TF2_GetPlayerClass(i) == TFClass_Spy)
						{
							EntityCheck(i);
						}
						TF2_RespawnPlayer(i);
					}
				} 
			}
			default:
			{
			
			}
		}
	}
}

public ConVarChange_RestartType(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(c_restartType) < 0 || GetConVarInt(c_restartType) > 2)
	{
		PrintToServer("Invalid value of %i for sm_ce_restart_type. sm_ce_restart_type must be between or equal to 0 and 2.", GetConVarInt(c_restartType));
		SetConVarInt(c_restartType, 0);
	}
}

public ConVarChange_Announce(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(c_roundStartAnnounce) < -1 || GetConVarInt(c_roundStartAnnounce) > 2)
	{
		PrintToServer("Invalid value of %i for sm_ce_announce. sm_ce_announce must be between or equal to -1 and 2.", GetConVarInt(c_roundStartAnnounce));
		SetConVarInt(c_roundStartAnnounce, 0);
	}
}

public ChooseRandomClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iRandomBlue = GetRandomInt(1, 9);
	g_iRandomRed = GetRandomInt(1, 9);
	if (GetConVarBool(c_Enabled) && GetConVarInt(c_restartType) > 0)
	{
		switch (GetConVarInt(c_restartType))
		{
			case 1:
			{
				SetConVarInt(FindConVar("mp_restartgame"), 1);
			}
			case 2:
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) != 1  && GetClientTeam(i) != 0)
					{
						if (TF2_GetPlayerClass(i) == TFClass_DemoMan || TF2_GetPlayerClass(i) == TFClass_Engineer || TF2_GetPlayerClass(i) == TFClass_Spy)
						{
							EntityCheck(i);
						}
						TF2_RespawnPlayer(i);
					}
				} 
			}
			default:
			{
			
			}
		}
	}
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!GetConVarBool(c_Enabled) || (GetConVarBool(c_adminOveride) && CheckCommandAccess(client, "sm_ce_forceimmuned", ADMFLAG_SLAY))) return;
	
	new TFTeam:team = TFTeam:GetClientTeam(client);
	if(GetConVarInt(c_randomRounds))
	{
		if(team == TFTeam_Red && TF2_GetPlayerClass(client) != TFClassType:g_iRandomRed)
		{
			TF2_SetPlayerClass(client, TFClassType:g_iRandomRed, false, true);
			PrintToChat(client, "\x04[!]\x01 Your team is restricted to %s.", g_strClassPrint[g_iRandomRed]);
			TF2_RespawnPlayer(client);
		}else if(team == TFTeam_Blue && TF2_GetPlayerClass(client) != TFClassType:g_iRandomBlue)
		{
			TF2_SetPlayerClass(client, TFClassType:g_iRandomBlue, false, true);
			PrintToChat(client, "\x04[!]\x01 Your team is restricted to %s.", g_strClassPrint[g_iRandomBlue]);
			TF2_RespawnPlayer(client);
		}
		
		return;
	}
	
	if(team == TFTeam_Red && g_iRedClass == TFClass_Unknown) return;
	if(team == TFTeam_Blue && g_iBlueClass == TFClass_Unknown) return;
	
	if(team == TFTeam_Red && TF2_GetPlayerClass(client) != g_iRedClass)
	{
		TF2_SetPlayerClass(client, g_iRedClass, false, true);
		PrintToChat(client, "\x04[!]\x01 Your team is restricted to %s.", g_strClassPrint[g_iRedClass]);
		TF2_RespawnPlayer(client);
	}else if(team == TFTeam_Blue && TF2_GetPlayerClass(client) != g_iBlueClass)
	{
		TF2_SetPlayerClass(client, g_iBlueClass, false, true);
		PrintToChat(client, "\x04[!]\x01 Your team is restricted to %s.", g_strClassPrint[g_iBlueClass]);
		TF2_RespawnPlayer(client);
	}
}

public AnnounceClassesToServer(Handle:event, const String:name[], bool:dontBroadcast)
{
	AnnounceToAll();
}

ParseClassStrings()
{
	new String:strRed[50];
	GetConVarString(c_classRed, strRed, sizeof(strRed));
	
	new String:strBlue[50];
	GetConVarString(c_classBlue, strBlue, sizeof(strBlue));
	
	g_iRedClass = TF2_GetClass(strRed);
	g_iBlueClass = TF2_GetClass(strBlue);

	if (StrEqual(g_strClassPrint[g_iRedClass], "") && !StrEqual(strRed, ""))
	{
		PrintToServer("Invalid value specified for sm_ce_red: %s. Setting to Scout.", strRed);
		ReplaceString(strRed, 50, strRed, "scout", true);
		g_iRedClass = TF2_GetClass(strRed);
	}

	if (StrEqual(g_strClassPrint[g_iBlueClass], "")  && !StrEqual(strBlue, ""))
	{
		PrintToServer("Invalid value specified for sm_ce_blue: %s. Setting to Scout.", strBlue);
		ReplaceString(strBlue, 50, strBlue, "scout", true);
		g_iBlueClass = TF2_GetClass(strBlue);
	}

	if (GetConVarInt(c_restartType) == 0 || GetConVarInt(c_restartType) == 2)
	{
		AnnounceToAll();
	}
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	new ibFlags = ReadFlagString(flags);
	if((GetUserFlagBits(client) & ibFlags) == ibFlags)
	{
		return true;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	
	return false;
}

AnnounceToAll()
{
	if (GetConVarBool(c_Enabled) && GetConVarInt(c_roundStartAnnounce) > -1)
	{
		switch(GetConVarInt(c_roundStartAnnounce))
		{
			case 0:
			{
				if (!GetConVarInt(c_randomRounds))
        			{
        				PrintToChatAll("\x04[!]\x01 This Round's Matchup Is: Red %s vs. Blu %s", g_strClassPrint[g_iRedClass], g_strClassPrint[g_iBlueClass]);
        			}else
        			{
         				 PrintToChatAll("\x04[!]\x01 This Round's Matchup Is: Red %s vs. Blu %s", g_strClassPrint[g_iRandomRed], g_strClassPrint[g_iRandomBlue]);
        			}
			}
			case 1:
			{
        			if (!GetConVarInt(c_randomRounds))
        			{
					PrintCenterTextAll("Red %s vs. Blu %s", g_strClassPrint[g_iRedClass], g_strClassPrint[g_iBlueClass]);
        			}else
        			{
        				PrintCenterTextAll("Red %s vs. Blu %s", g_strClassPrint[g_iRandomRed], g_strClassPrint[g_iRandomBlue]);
        			}          
			}
			case 2:
			{
        			if (!GetConVarInt(c_randomRounds))
        			{
					PrintHintTextToAll("This Round's Matchup Is: Red %s vs. Blu %s", g_strClassPrint[g_iRedClass], g_strClassPrint[g_iBlueClass]);
        			}else
        			{
          				PrintHintTextToAll("This Round's Matchup Is: Red %s vs. Blu %s", g_strClassPrint[g_iRandomRed], g_strClassPrint[g_iRandomBlue]);
        			}
			}
			default:
			{
			
			}
		}
	}
}

EntityCheck(client)
{
	new iEnt = -1;
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		while ((iEnt = FindEntityByClassname(iEnt, "obj_dispenser")) != INVALID_ENT_REFERENCE)
		{
			if (GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
			{
				AcceptEntityInput(iEnt, "Kill");
			}
		}
		iEnt = -1;
		while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
		{
			if (GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
			{
				AcceptEntityInput(iEnt, "Kill");
			}
		}
		iEnt = -1;
		while ((iEnt = FindEntityByClassname(iEnt, "obj_teleporter")) != INVALID_ENT_REFERENCE)
		{
			if (GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder") == client)
			{
				AcceptEntityInput(iEnt, "Kill");
			}
		}
	}else if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
	while ((iEnt = FindEntityByClassname(iEnt, "obj_attachment_sapper")) != INVALID_ENT_REFERENCE)
		{
			if (GetEntPropEnt(iEnt, Prop_Send, "m_hOwner") == client)
			{
				AcceptEntityInput(iEnt, "Kill");
			}
		}
	}else if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
	while ((iEnt = FindEntityByClassname(iEnt, "sticky")) != INVALID_ENT_REFERENCE)
		{
			if (GetEntPropEnt(iEnt, Prop_Send, "m_hThrower") == client)
			{
				AcceptEntityInput(iEnt, "Kill");
			}
		}
	}
}