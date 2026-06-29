#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

// +--------------------------+
// |	Updated soccer mode   |
// +--------------------------+

new g_CurrentRound = 1;
new g_CurrentHalf = 1;

//new Handle:h_RandPassword;
new Handle:soccer_enable;
new Handle:soccer_sprint_enabled;
new Handle:soccer_sprint_time;
new Handle:soccer_sprint_cooldown;
new Handle:soccer_sprint_speed;
new Handle:soccer_respawn_enable = INVALID_HANDLE;
new Handle:soccer_respawn_delay = INVALID_HANDLE;
new bool:soccer_mixmod_enable = false;
new bool:client_connected[MAXPLAYERS+1];
new bool:client_sprintusing[MAXPLAYERS+1];
new bool:client_sprintcool[MAXPLAYERS+1];
new bool:g_SwapNow = false;
new String:LastAttacker[512];
new LastAttackerUser;

// +----------------------+
// |	Beacon Settings	  |
// +----------------------+
new g_BeamSprite;
new g_HaloSprite;
new greenColor[4] = {0, 255, 0, 255};
new grayColor[4] = {128, 128, 128, 255};
new blueColor[4] = {0, 0, 255, 255};
new redColor[4] = {255, 75, 75, 255};
new Float:Origin[3];
new Float:Originn[3];
new Float:Originnn[3];

// +----------------------------------------------------------------------------------+
public Plugin:myinfo =
{
	name = "SoccerMod",
	author = "EGood",
	description = "SoccerMod",
	version = PLUGIN_VERSION,
	url = "gamex.co.il"
}
// +----------------------------------------------------------------------------------+
public OnPluginStart()
{
	/*
		cVars
	*/
	CreateConVar("sm_soccermod_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	soccer_enable = CreateConVar("sm_soccer_enable", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	soccer_sprint_enabled = CreateConVar("sm_sprint_enable", "1", "Enable/Disable Sprint.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	soccer_sprint_time = CreateConVar("sm_sprint_time", "3", "sprint time.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	soccer_sprint_cooldown = CreateConVar("sm_sprint_cooldown", "7", "sprint cooldown time.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	soccer_sprint_speed = CreateConVar("sm_sprint_speed", "1.4", " sprint speed.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	soccer_respawn_enable = CreateConVar("sm_soccer_respawn_enable", "1", "Enables/disables AutoRespawn on this server at any given time", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	soccer_respawn_delay = CreateConVar("sm_soccer_respawn_delay", "7", "Amount of time (in seconds) after players die before they are automatically respawned");
	soccer_mixmod_enable = CreateConVar("sm_soccer_mixmod_enable", "0", "Enables/disables soccer mix mod.", FCVAR_NONE, true, 0.0, true, 1.0);

	/*
		ExecConfig
	*/
    AutoExecConfig(true, "soccermod");
	
	/*
		Regs
	*/
	RegConsoleCmd("sprint", Cmd_StartSprint);
	RegConsoleCmd("sm_info", Cmd_Info);
	RegConsoleCmd("sm_score", Cmd_Score);
	AddCommandListener(Command_Team, "jointeam");
	RegAdminCmd("sm_start", Command_Start, ADMFLAG_KICK, "Starts a mix.");
	RegAdminCmd("sm_stop", Command_Stop, ADMFLAG_KICK, "Stops the current mix.");
	RegAdminCmd("sm_live", Command_Live, ADMFLAG_KICK, "Restarts the round.");
	RegAdminCmd("sm_spec", Command_Spec, ADMFLAG_KICK, "Go to fucking spec.");
	
	/*
		Hooks
	*/
	HookEvent("round_start", RoundStart);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);	
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_MixRoundEnd);
	
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}
// +----------------------------------------------------------------------------------+
public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	PrecacheSound("ambient/misc/brass_bell_C.wav", true);	
	soccer_mixmod_enable = false;
}
// +----------------------------------------------------------------------------------+
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (soccer_mixmod_enable)
	{
		CPrintToChatAll("{olive}[Soccer-Mix]{green} Round {lightgreen}%d{green}/{lightgreen}10 - Half {lightgreen}%d{green}/{lightgreen}2{green}.", g_CurrentRound, g_CurrentHalf);
	}
}
// +----------------------------------------------------------------------------------+
public OnEntityCreated(edict, const String:classname[])
{
	SDKHook(edict, SDKHook_OnTakeDamage, OnEntityTakeDamage);
}
// +----------------------------------------------------------------------------------+
public Action:OnEntityTakeDamage(edict, &inflictor, &attacker, &Float:damage, &damagetype)
{
	decl String:classname[512];
	GetEdictClassname(edict, classname, sizeof(classname));
	
	if ( IsValidEdict(edict) && IsValidEntity(edict) )
	{
		decl String:aName[64];
		GetClientName(attacker, aName, sizeof(aName));
		LastAttacker = aName;
		LastAttackerUser = attacker;
	}
}
// +----------------------------------------------------------------------------------+
public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (soccer_mixmod_enable)
	{
		g_CurrentRound++;
		
		if (g_CurrentRound == 10)
		{
			if (g_CurrentHalf == 1)
			{
				g_SwapNow = true;
				CPrintToChatAll("{olive}[Soccer-Mix]{green} Teams will be swap AUTOMATICALLY after this round. Do {olive}NOT{green} change your team.");
			}
			else
			{
				soccer_mixmod_enable = false;
	
				g_CurrentRound = 1;
				g_CurrentHalf = 1;
				CPrintToChatAll("{olive}[Soccer-Mix] {green}Mix ended!");				
			}
		}
	}
}
// +----------------------------------------------------------------------------------+
stock SetclientFrags(client, frags)
{
	SetEntProp(client, Prop_Data, "m_iFrags", frags);
	return 1;
}
// +----------------------------------------------------------------------------------+
stock CreateBeacon(client)
{
	GetClientAbsOrigin(client, Origin);
	Origin[2] += 30;
	GetClientAbsOrigin(client, Originn);
	Originn[2] += 20;
	GetClientAbsOrigin(client, Originnn);
	Originnn[2] += 10;
	
	/*
		Red
	*/
	TE_SetupBeamRingPoint(Origin, 10.0, 100.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, grayColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(Origin, 10.0, 100.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	TE_SendToAll();
	/*
		Green
	*/
	TE_SetupBeamRingPoint(Originn, 10.0, 200.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, grayColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(Originn, 10.0, 200.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 10, 0);
	TE_SendToAll();
	/*
		Blue
	*/
	TE_SetupBeamRingPoint(Originnn, 10.0, 300.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, grayColor, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(Originnn, 10.0, 300.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
	TE_SendToAll();
}
// +----------------------------------------------------------------------------------+
public Event_MixRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Add frag to the winner
	new cFrags = GetClientFrags(LastAttackerUser);
	new nFrags = cFrags + 1;
	SetclientFrags(LastAttackerUser, nFrags);
	
	if ( LastAttackerUser != -1 )
	{
		PrintToChatAll("\x04Soccer\x05 |\x03 Player\x04 %s\x05 Scored\x03 on this round\x04!", LastAttacker);
	}
	LastAttackerUser = -1;
	// +---------------------------------------+
	// |	Create Beacon around the winner	   |
	// +---------------------------------------+
	CreateBeacon(LastAttackerUser);

	if ( soccer_mixmod_enable && g_SwapNow )
	{
		new ctscore = GetTeamScore(3);
		new tscore = GetTeamScore(2);
		
		for ( new i = 1; i <= GetMaxClients(); i++ )
		{
			if ( IsClientInGame(i) )
			{
				new cTeam = GetClientTeam(i);
				
				if ( cTeam == 3 )
				{
					CS_SwitchTeam(i, 2);
				}
				else if ( cTeam == 2 )
				{
					CS_SwitchTeam(i, 3);
				}
			}
		}
		
		SetTeamScore(3, tscore);
		SetTeamScore(2, ctscore);
		
		g_CurrentRound = 1;
		g_CurrentHalf = 2;
		
		EmitSoundToAll("ambient/misc/brass_bell_C.wav");
		CPrintToChatAll("{olive}[Soccer-Mix]{green} Teams swaped. HALF 2!");
		
		g_SwapNow = false;
	}
}
// +----------------------------------------------------------------------------------+
public Action:Command_Start(client, args)
{
	if (soccer_mixmod_enable)
	{
		CPrintToChat(client, "{olive}[Soccer-Mix]{green} A mix has already started.");
		return Plugin_Handled;
	}
	
	ServerCommand("mp_allowspectators 0");
	ServerCommand("mp_restartgame 1");
	
	soccer_mixmod_enable = true;
	
	g_CurrentRound = 1;
	g_CurrentHalf = 1;
	
	return Plugin_Handled;

}
// +----------------------------------------------------------------------------------+
public Action:Command_Stop(client, args)
{
	if (!soccer_mixmod_enable)
	{
		CPrintToChat(client, "{olive}[Soccer-Mix]{green} A mix hasn't started already.");
		return Plugin_Handled;
	}
	
	ServerCommand("mp_allowspectators 1");
	ServerCommand("mp_restartgame 1");
	ServerCommand("sv_alltalk 1");
	
	soccer_mixmod_enable = false;
	
	g_CurrentRound = 1;
	g_CurrentHalf = 1;
	
	return Plugin_Handled;
}
// +----------------------------------------------------------------------------------+
public Action:Command_Live(client, args)
{
	ServerCommand("mp_allowspectators 0");
	ServerCommand("mp_restartgame 1");
	ServerCommand("sv_alltalk 0");
	return Plugin_Handled;
}
// +----------------------------------------------------------------------------------+
public Action:Command_Spec(client, args)
{
	PrintToChatAll("\x04Soccer\x05 |\x03 Moving players to\x04 Spectator\x03...");
	ServerCommand("mp_allowspectators 1");
	
	for ( new i = 1; i <= GetMaxClients(); i++ )
	{
		if ( IsClientInGame(i) )
		{
			ChangeClientTeam(i, 1);
		}
	}
	
	return Plugin_Handled;
}
// +----------------------------------------------------------------------------------+
public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(soccer_enable) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if ( IsClientInGame(client) )
		{
			new cTeam = GetClientTeam(client);
			if ( cTeam == 1 || cTeam == 0 )
			{
				RemovePlayerItem(client, 0);
				RemovePlayerItem(client, 1);
			}
		}

		if (GetClientTeam(client) == CS_TEAM_T)
		{
			SetEntityHealth(client, 100);
		}
		else if (GetClientTeam(client) == CS_TEAM_CT)
		{
			SetEntityHealth(client, 100);
		}
	}
}
// +----------------------------------------------------------------------------------+
public Action:RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(!GetConVarBool(soccer_sprint_enabled))
		return;
	new clients= GetMaxClients();		
	for(new client= 1; client<=clients; client++)
	{
		//
		if(IsClientInGame(client))
		{
			Skill_Sprint_Reset(client);
			ServerCommand("phys_pushscale 970");
			ServerCommand("phys_timescale 1");
			ServerCommand("sv_turbophysics 0");
			ServerCommand("mp_freezetime 0");
			PrintToChatAll("\x05Game Score :\x04CT \x05- \x03%d \x05VS \x04T \x05- \x03%d .", GetTeamScore(2), GetTeamScore(3));
		}
	}
}
// +----------------------------------------------------------------------------------+
public Skill_Sprint_Reset(client)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	client_sprintusing[client]=false;
	client_sprintcool[client]=true;
}
// +----------------------------------------------------------------------------------+
public Action:Cmd_StartSprint(client, args)
{
	if (!GetConVarBool(soccer_sprint_enabled))
		return;
	
	if (client_sprintusing[client])
	{
		return;
	}
	
	if (!client_sprintcool[client])
	{
		return;
	}
	client_sprintusing[client]=true;
	client_sprintcool[client]=false;
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(soccer_sprint_speed));
	PrintToChat(client, "\x04Soccer Sprint \x05- \x03Started");
	CreateTimer(GetConVarFloat(soccer_sprint_time), Timer_SprintEnd, client);
}
// +----------------------------------------------------------------------------------+
public Action:Cmd_Info(client, args)
{
	if (GetConVarInt(soccer_enable) == 1)
	{
		PrintToChatAll("\x04Info :");
		PrintToChatAll("\x04Mod Created by EGood.");
		PrintToChatAll("\x04Server Number : 15");
		PrintToChatAll("\x04www.cssc.co.il");
	}
}
// +----------------------------------------------------------------------------------+
public Action:Cmd_Score(client, args)
{
	if (GetConVarInt(soccer_enable) == 1)
	{
		PrintToChat(client, "\x05Game Score :\x04CT \x05- \x03%d \x05VS \x04T \x05- \x03%d .", GetTeamScore(2), GetTeamScore(3));
	}
}
// +----------------------------------------------------------------------------------+
public Action:Timer_SprintEnd(Handle:timer, any:client)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	if(!client_sprintusing[client])
	{
		return;
	}
	client_sprintusing[client]=false;
	PrintToChat(client, "\x04Soccer Sprint \x05- \x03Ended");
	CreateTimer(GetConVarFloat(soccer_sprint_cooldown), Timer_SprintCooldown, client);
}
// +----------------------------------------------------------------------------------+
public Action:Timer_SprintCooldown(Handle:timer, any:client)
{
	if ( client_sprintcool[client] )
	{
		return;
	}
	client_sprintcool[client] = true;
	PrintToChat(client, "\x04Soccer Sprint \x05- \x03You can use Sprint.");
}

// +----------------------------------------------------------------------------------+
public OnClientPutInServer(client)
{
	if (GetConVarInt(soccer_enable) == 1)
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		client_connected[client]= true;
		Skill_Sprint_Reset(client);
	}
}

// +----------------------------------------------------------------------------------+
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ( damagetype & DMG_FALL )
	{
		return Plugin_Handled;
	}
	if ( damagetype & DMG_BULLET )
	{
		return Plugin_Handled;
	}
	if ( damagetype & DMG_SLASH )
	{
		return Plugin_Handled;
	}
	if ( damagetype & DMG_CRUSH )
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

// +----------------------------------------------------------------------------------+
public Action:Command_Team(client, const String:command[], args)
{
	if ( soccer_mixmod_enable )
	{
		if ( g_CurrentRound == 10 && g_CurrentHalf == 1 )
		{
			PrintToChatAll("\x04Soccer\x05 |\x03 You\x04 can\'t\x03 change your\x05 team\x03 now\x04!");
			return Plugin_Handled;
		}
	}
	if ( GetConVarBool(soccer_respawn_enable) )
	{
		decl String:teamString[3];
		GetCmdArg(1, teamString, sizeof(teamString));
		new newTeam = StringToInt(teamString);

		if ( newTeam <= 1 )
		{
			if ( GetClientTeam(client) > 1 )
			{
				return Plugin_Continue;
			}
			else
				return Plugin_Handled;
		}
		else
		{
			new Float:RespawnDelayTime = GetConVarFloat(soccer_respawn_delay);
			CreateTimer(RespawnDelayTime, RespawnClient, client);
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}
// +----------------------------------------------------------------------------------+
public Action:RespawnClient(Handle:timer, any:client)
{
	CS_RespawnPlayer(client);
}
// +----------------------------------------------------------------------------------+
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ctscore = GetTeamScore(3);
	new tscore = GetTeamScore(2);

	SetTeamScore(3, tscore);
	SetTeamScore(2, ctscore);
}
// +----------------------------------------------------------------------------------+
