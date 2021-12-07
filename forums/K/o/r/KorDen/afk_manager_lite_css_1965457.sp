//Based on AFK Manager 3.5.0 by Rothgar (dawgclan.net) - https://forums.alliedmods.net/showthread.php?t=79904

#define AFK_CHECK_INTERVAL 5.0
#define Threshold 30.0 //Threshold for amount of movement required to mark a player as AFK.

#pragma semicolon 1
#include <sourcemod>
#include <sdktools_functions>

#define CS_TEAM_SPECTATOR 1
#define g_Spec_FL_Mode 6 // OrangeBox=6

#define VERSION "1.1-css"

#define CheckAdminImmunity(%1) (g_AFlag==0 ? GetUserFlagBits(%1)!=0 : (GetUserFlagBits(%1) & g_AFlag || GetUserFlagBits(%1) & ADMFLAG_ROOT))

new Float:fAFKTime[MAXPLAYERS+1] = {0.0, ...}, bool:g_CheckClient[MAXPLAYERS+1] = {false, ...},
	Float:fEyePosition[MAXPLAYERS+1][3], Float:fMapPosition[MAXPLAYERS+1][3],  // X = Vertical, Y = Height, Z = Horizontal
	iSpecMode[MAXPLAYERS+1], iSpecTarget[MAXPLAYERS+1], //={0, ...}
	Float:g_KickTime, Float:g_MoveTime, Float:g_WarnTime, g_KickMinPlayers, g_MoveMinPlayers, g_Immunity, g_AFlag;

public Plugin:myinfo =
{
    name = "AFK Manager Lite - CSS",
    author = "KorDen, orig by Rothgar",
    description = "Lite version of Rothgar AFK Manager, only for CSS",
    version = VERSION,
    url = "http://dev.sky-play.ru"
};

public OnPluginStart()
{
	LoadTranslations("afk_manager_css.phrases");
	new Handle:cvar=FindConVar("mp_autokick"); //KyleS style
	if (cvar!=INVALID_HANDLE) // Disable Mod Based AFK System
	{
		HookConVarChange(cvar, CvarChange_AFK);
		SetConVarInt(cvar, 0);
	}

	HookConVarChange((cvar=CreateConVar("sm_afk_move_min", "4", "Min players for AFK move")), Cvar_MoveMinPlayers);
	g_MoveMinPlayers=GetConVarInt(cvar);
	
	HookConVarChange((cvar=CreateConVar("sm_afk_kick_min", "6", "Min players for AFK kick")), Cvar_KickMinPlayers);
	g_KickMinPlayers=GetConVarInt(cvar);
	
	HookConVarChange((cvar=CreateConVar("sm_afk_move_time", "60.0", "Time in seconds for AFK Move. 0 = DISABLED")), Cvar_MoveTime);
	g_MoveTime=GetConVarFloat(cvar);
	
	HookConVarChange((cvar=CreateConVar("sm_afk_kick_time", "120.0", "Time in seconds to AFK Kick. 0 = DISABLED")), Cvar_KickTime);
	g_KickTime=GetConVarFloat(cvar);
	
	HookConVarChange((cvar=CreateConVar("sm_afk_warn_time", "30.0", "Time in seconds remaining before warning")), Cvar_WarnTime);
	g_WarnTime=GetConVarFloat(cvar);
	
	HookConVarChange((cvar=CreateConVar("sm_afk_immune", "1", "AFK admins immunity: 0 = DISABLED, 1 = COMPLETE, 2 = KICK, 3 = MOVE")), Cvar_Immunity);
	g_Immunity=GetConVarInt(cvar);
	
	HookConVarChange((cvar=CreateConVar("sm_afk_immune_flag", "", "Admin flag for immunity, blank=any flag")), Cvar_ImmunityFlag);
	SetImmuneFlag(cvar);
	
	HookConVarChange((cvar=CreateConVar("kdlp_afkm", VERSION, "AFK Manager plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)), Cvar_Version);
	SetConVarString(cvar, VERSION);
	
	CloseHandle(cvar);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	HookEvent("player_team", Event_PlayerTeamPost, EventHookMode_Post);
	HookEvent("player_spawn",Event_PlayerSpawn);
	HookEvent("player_death",Event_PlayerDeath);
}

public Cvar_KickTime(Handle:cvar, const String:oldvalue[], const String:newvalue[])
	g_KickTime=GetConVarFloat(cvar);
public Cvar_MoveTime(Handle:cvar, const String:oldvalue[], const String:newvalue[])
	g_MoveTime=GetConVarFloat(cvar);
public Cvar_WarnTime(Handle:cvar, const String:oldvalue[], const String:newvalue[])
	g_WarnTime=GetConVarFloat(cvar);
public Cvar_KickMinPlayers(Handle:cvar, const String:oldvalue[], const String:newvalue[])
	g_KickMinPlayers=GetConVarInt(cvar);
public Cvar_MoveMinPlayers(Handle:cvar, const String:oldvalue[], const String:newvalue[])
	g_MoveMinPlayers=GetConVarInt(cvar);
public Cvar_Immunity(Handle:cvar, const String:oldvalue[], const String:newvalue[])
	g_Immunity=GetConVarInt(cvar);
public Cvar_ImmunityFlag(Handle:cvar, const String:oldvalue[], const String:newvalue[])
	SetImmuneFlag(cvar);
	
public Cvar_Version(Handle:cvar, const String:oldvalue[], const String:newvalue[])
	if (!StrEqual(newvalue, VERSION))
		SetConVarString(cvar, VERSION);

// Disable Mod Based AFK System
public CvarChange_AFK(Handle:cvar, const String:oldvalue[], const String:newvalue[])
	if (StringToInt(newvalue) > 0)
		SetConVarInt(cvar, 0);

public OnMapStart()
{
	AutoExecConfig(true, "afk_manager_css");
	CreateTimer(AFK_CHECK_INTERVAL, Timer_CheckPlayer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	for (new i=1; i<=MaxClients; i++)
	{
		g_CheckClient[i]=false;
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			InitializePlayer(i);
	}
}

SetImmuneFlag(Handle:cvar=INVALID_HANDLE)
{
	decl String:flags[4];
	new AdminFlag:flag;
	GetConVarString(cvar, flags, sizeof(flags));
	if (flags[0]!='\0' && FindFlagByChar(flags[0], flag))
	{
		 g_AFlag=FlagToBit(flag);
	}
	else 
	{
		g_AFlag=0;
	}
}

ResetPlayer(index)
{
	fAFKTime[index] = 0.0;
	fEyePosition[index] = Float:{0.0,0.0,0.0};
	iSpecMode[index] = iSpecTarget[index] = 0;
}

InitializePlayer(index)
{
	if (!(g_Immunity == 1 && CheckAdminImmunity(index)))
	{
		g_CheckClient[index]=true;
		ResetPlayer(index);
	}
}

// Initialize Player once they are put in the server and post-connection authorizations have been performed.
public OnClientPostAdminCheck(client)
	if (!IsFakeClient(client))
		InitializePlayer(client);

public OnClientDisconnect(client)
{
	g_CheckClient[client]=false;
	ResetPlayer(client);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && !IsFakeClient(client) && GetClientTeam(client) &&
		!IsClientObserver(client) && IsPlayerAlive(client) && GetClientHealth(client) > 0)
		ResetPlayer(client); // Reset AFK timer because they spawned.

	// GetClientTeam(client): Unassigned Team? Lincoln is fucking up: Fix for Valve deciding to fire player_spawn on Spectator team?! IsClientObserver(), IsPlayerAlive() and GetClientHealth() do not fix this bug? +Fix for Valve causing Unassigned to not be detected as an Observer in CSS and causing Unassigned to be alive?
}

public Action:Event_PlayerTeamPost(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client>0 && !IsFakeClient(client))
	{
		if(!g_CheckClient[client])
			InitializePlayer(client);

		if(GetEventInt(event, "team") != CS_TEAM_SPECTATOR)
		{
			if (g_CheckClient[client])
				ResetPlayer(client);
		}
		else
		{
			// Player joined or was moved to spectator team? Set new AFK details to ensure timer continues
			GetClientEyeAngles(client, fEyePosition[client]);
			iSpecMode[client] = GetEntProp(client, Prop_Send, "m_iObserverMode");
			iSpecTarget[client] = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
	ResetPlayer(GetClientOfUserId(GetEventInt(event,"attacker")));// Reset attacker when he kills someone.

public Action:Command_Say(client, const String:command[], args)
	ResetPlayer(client); // Reset when player has said something in chat.

// AFK Observer/Spectator Check
bool:CheckObserverAFK(client)
{
	new g_Last_Spec, g_Last_Mode = iSpecMode[client];// Store Last Spec Mode
	iSpecMode[client] = GetEntProp(client, Prop_Send, "m_iObserverMode"); // Check Current Spectator Mode
	if (g_Last_Mode > 0 && iSpecMode[client] != g_Last_Mode) // Check if Spectator Mode Changed
		return false;

	// Store Previous Eye Angle/Origin Values
	decl Float:f_Eye_Loc[3];
	f_Eye_Loc = fEyePosition[client];
	if (iSpecMode[client] == g_Spec_FL_Mode)// Check if player is in Free Look Mode
	{
		GetClientEyeAngles(client, fEyePosition[client]);// Get New Player Eye Angles
	}
	else
	{
		// Check Spectator Target
		g_Last_Spec = iSpecTarget[client];
		iSpecTarget[client] = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

		// Check if player was just moved to Spectator? We have now stored new values.
		if (g_Last_Mode == 0 && g_Last_Spec == 0)
			return true;

		if (g_Last_Spec > 0 && iSpecTarget[client] != g_Last_Spec) // Check if we are spectating the same player.
		{
			// Old target died and is no longer valid.
			if (g_Last_Spec > MaxClients || !IsClientConnected(g_Last_Spec) || !IsClientInGame(g_Last_Spec))
				return false;
			
			return (!IsPlayerAlive(g_Last_Spec));
		}
	}

	// Check if we are looking at the same place.
	if ((fEyePosition[client][0] == f_Eye_Loc[0]) &&
		(fEyePosition[client][1] == f_Eye_Loc[1]) &&
		(fEyePosition[client][2] == f_Eye_Loc[2]))
	{
		return true;
	}
	return false;
}

// AFK Timer
public Action:Timer_CheckPlayer(Handle:Timer, any:data)
{
	new client, clients = 0, g_TeamNum, Float:timeleft;
	decl Float:f_Eye_Loc[3], Float:f_Map_Loc[3];
	
	for (client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client) && !IsFakeClient(client))
			clients++;
	
	new bool:bMovePlayers = (clients >= g_MoveMinPlayers && g_MoveTime > 0.0),
		bool:bKickPlayers = (clients >= g_KickMinPlayers && g_KickTime > 0.0);
		
	if (!bMovePlayers && !bKickPlayers) //Do we have enough players?
		return Plugin_Continue;

	for (client = 1; client <= MaxClients; client++)
	{
		if (!g_CheckClient[client] || !IsClientInGame(client)) // Is this player actually in the game?
			continue;

		g_TeamNum = GetClientTeam(client);
		
		// Check for AFK
		if (IsClientObserver(client))
		{	// Unassigned, Spectator or Dead Player
			if (g_TeamNum > CS_TEAM_SPECTATOR && !IsPlayerAlive(client))
				continue; // Exclude dead players: player is not a spectator = he is dead
			
			if (g_TeamNum == 0 || CheckObserverAFK(client))
			{
				fAFKTime[client] += AFK_CHECK_INTERVAL;
			}
			else
			{
				fAFKTime[client] = 0.0;
				continue;
			}
		}
		else
		{	// Normal player
			f_Eye_Loc = fEyePosition[client]; // Store Previous Eye Angle/Origin & Map Location Values
			f_Map_Loc = fMapPosition[client];
			GetClientEyeAngles(client, fEyePosition[client]);// Get New
			GetClientAbsOrigin(client, fMapPosition[client]);

			// Check Location (Origin) including thresholds && Check Eye Angles && Check if player is frozen
			if ((fEyePosition[client][0] == f_Eye_Loc[0]) && 
				(fEyePosition[client][1] == f_Eye_Loc[1]) &&
				(fEyePosition[client][2] == f_Eye_Loc[2]) &&
				(FloatAbs(fMapPosition[client][0] - f_Map_Loc[0]) < Threshold) &&
				(FloatAbs(fMapPosition[client][1] - f_Map_Loc[1]) < Threshold) &&
				(FloatAbs(fMapPosition[client][2] - f_Map_Loc[2]) < Threshold) &&
				!(GetEntityFlags(client) & FL_FROZEN))
			{
				fAFKTime[client] += AFK_CHECK_INTERVAL;
			}
			else
			{
				fAFKTime[client] = 0.0;
				continue;
			}
		}
		
		// Warn/Move/Kick client. If client isn't ab AFK, we will never be here
		if (bMovePlayers && g_TeamNum > CS_TEAM_SPECTATOR && ( !g_Immunity || g_Immunity == 2 || !CheckAdminImmunity(client)))
		{
			timeleft = g_MoveTime - fAFKTime[client];
			if (timeleft > 0.0)
			{
				if(timeleft <= g_WarnTime)
					PrintToChat(client, "\x04[AFK] \x01%t", "Move_Warning", RoundToFloor(timeleft));
			}
			else
			{
				decl String:f_Name[MAX_NAME_LENGTH+4];
				Format(f_Name,sizeof(f_Name),"\x03%N\x01",client);
				PrintToChatAll("\x04[AFK] \x01%t", "Move_Announce", f_Name);
				ForcePlayerSuicide(client); // Kill Player so round ends properly, this is Valve's normal method.
				ChangeClientTeam(client, CS_TEAM_SPECTATOR); // Move AFK Player to Spectator
			}
		}
		else if (bKickPlayers && (!g_Immunity || g_Immunity == 3 || !CheckAdminImmunity(client)))
		{
			timeleft = g_KickTime - fAFKTime[client];
			if (timeleft > 0.0)
			{
				if (timeleft <= g_WarnTime)
					PrintToChat(client, "\x04[AFK] \x01%t", "Kick_Warning", RoundToFloor(timeleft));
			}
			else
			{
				decl String:f_Name[MAX_NAME_LENGTH+4];
				Format(f_Name,sizeof(f_Name),"\x03%N\x01",client);
				PrintToChatAll("\x04[AFK] %t", "Kick_Announce", f_Name);
				KickClient(client, "[AFK] %t", "Kick_Message");
			}
		}
	}
	return Plugin_Continue;
}