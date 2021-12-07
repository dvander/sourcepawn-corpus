/*******************************************************************************
  Death Zone

  Version: 2.3
  Author: SWAT_88 / [KH] Royal CS / lamdacore
  
  1.0	Initial release for DoD:S.
  2.0 	Remake for CS:S.
		Added many features:
			Escape Time for each Zone.
			Countdowns, Sounds, and Explosions.
			Reason for each Zone.
			Death Zone that will slay everybody.
  2.1	Fixed a bug in "Reason Message"
  2.2	Added Admin immunity.
  2.3	Fixed another bug in "Reason Message"
  2.4 Added deactivation and botimmunity


  Requirements:

    The latest sourcemod build
   
  Description:
	This is a Death Zone Plugin.
	You can create zones in a cuboid form that will be a zone of death for either the CT, the T team or All players.
	Players in the zone with the specified team will be slain after the given time.
	
  Useful for:
	Preventing Players to get in the enemy spawn zone.
	Anti rush.
	Anti Bug using.
	Camping.
	Not solid walls.
	AFK.

  Features:

    Create a new zone ingame as Spectrator.
    Up to 20 individual zones per team (maximum of 60 zones) storing for each map.
    Set the output messages the way you want.
	Create Escape Times for each zone.
	Create Reasons for killing a player for each zone.
	
  Commands:
  
	"dz_clearzone"		Clears current point coordinates for Death Zone.
	
	"dz_setzone"		Set 3 point coordinates and the min/max height for Barrier-Jumping-Zone.
	 					You have to fly as Spectrator to a point where the first edge of the zone begins and enter sm_setzone. 
						Next fly to the second point where the second edge of the zone should be and enter sm_setzone again.
	 					Now fly to the thirt point and enter again. The fourth point will automatically calculated so that it become a cuboid.
	 					At least the minimum and maximum height for the cuboid, the Reason and the Escape Time have to be specified if you enter sm_setzone 4 more times.
	
	"dz_savezone_ct"	Save the current cooridinates for Death Zone that will slay the CT team.
	
	"dz_savezone_t"		Save the current cooridinates for Death Zone that will slay the T team.
	
	"dz_savezone_all"	Save the current cooridinates for Death Zone that will slay everybody.
	
	"dz_delzone_ct"		Delete the last saved Death Zone that will slay the CT team.
	
	"dz_delzone_t"		Delete the last saved Death Zone that will slay the T team.
	
	"dz_delzone_all"	Delete the last saved Death Zone that will slay everybody.
	
	"dz_testzones"		Test the Death Zones by your current position.	

  Cvars:

	"dz_verbose"	"2"	Sets when/where output is sent and to whom - 0 : No output - 1 : Show only to the user involved - 2 : Show to admins and user involved - 3 : Show to admins only - 4 : Show to everyone

	"dz_immunity"	"1"	- 1 : Admins don't get killed in a DeathZone. - 0 : Admins get killed in a DeathZone.

	"dz_time"		"0" DeactivationTime: - 0: Zones are never disabled. - x: Time for deactivation.
	
	"dz_botimmunity"	"0" - 1: Bots don't get killed in a DeathZone, - 0: Bots get killed in a DeathZone.
	
  Setup (SourceMod):

	Install the smx file to addons\sourcemod\plugins.
	Install the cfg file to cfg\sourcemod
	(Re)Load Plugin or change Map.
	
  TO DO:
  
	Nothing make a request.
	
  Copyright:
  
	Everybody can edit this plugin and copy this plugin.
	
  Thanks to:
	Kicia for Deactivation
	lamdacore
	GODJonez for helping with the is-player-in-zone calculating.
	
  HAVE FUN!!!

*******************************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION 	"2.4"

#define MAX_CT_COORDS 	20
#define MAX_T_COORDS 	20
#define MAX_ALL_COORDS	20

#define TEAM_SPEC 	1
#define TEAM_T 		2
#define TEAM_CT 	3
#define TEAM_ALL	4

static String:teamname[3][] = { "Spectator", "Terrorist", "Counter Terrorist"};

new Float:g_CTCoords[MAX_CT_COORDS][8];
new String:g_CTReason[MAX_CT_COORDS][256];
new g_CTTime[MAX_CT_COORDS];

new Float:g_TCoords[MAX_T_COORDS][8];
new String:g_TReason[MAX_T_COORDS][256];
new g_TTime[MAX_T_COORDS];

new Float:g_ALLCoords[MAX_ALL_COORDS][8];
new String:g_ALLReason[MAX_ALL_COORDS][256];
new g_ALLTime[MAX_ALL_COORDS];

new Float:g_SetCoords[8];
new String:g_SetReason[256];
new g_SetTime;

new g_MaxCoordsT = 0;
new g_MaxCoordsCT = 0;
new g_MaxCoordsALL = 0;

new Handle:g_Verbose;
new Handle:g_Immunity;
new Handle:g_BotImmunity;
new Handle:g_DeactivationTime;
//new Handle:g_ConVarFreezeTime;

//Timebomb
new Handle:g_TimeBombTimers[MAXPLAYERS+1];
new g_TimeBombTracker[MAXPLAYERS+1];
new g_TimeBombTicks;

new bool:g_TimeBombClient[MAXPLAYERS+1];

new g_TimeBombCTZone[MAXPLAYERS+1];
new g_TimeBombTZone[MAXPLAYERS+1];
new g_TimeBombALLZone[MAXPLAYERS+1];

new g_TimeBombTeam[MAXPLAYERS+1];


// Sounds
#define SOUND_BLIP		"buttons/blip1.wav"
#define SOUND_BEEP		"buttons/button17.wav"
#define SOUND_FINAL		"weapons/cguard/charging.wav"
#define SOUND_BOOM		"weapons/explode3.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"

// Following are model indexes for temp entities
new g_ExplosionSprite;

//Deactivation
new g_ZoneActive = 1;
new Handle:g_DeactivateTimer;

public Plugin:myinfo = {
        name = "Death Zone",
        author = "SWAT_88 / [KH] Royal CS / lamdacore",
        description = "Slays players that are in Death Zones.",
        version = PLUGIN_VERSION,
        url = "http://www.kh-clan.com"
};

public OnPluginStart()
{
	CreateConVar("dz_version", PLUGIN_VERSION, "Death Zone Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	g_Immunity = CreateConVar("dz_immunity","1","- 1 : Admins don't get killed in a DeathZone.\n - 0 : Admins get killed in a DeathZone.");
	g_Verbose = CreateConVar("dz_verbose", "2", "Sets when/where output is sent and to whom\n0 = No output\n1 = Show only to the user involved\n2 = Show to admins and user involved\n3 = Show to admins only\n4 = Show to everyone",FCVAR_PLUGIN, true, 0.0, true, 4.0);
	g_DeactivationTime = CreateConVar("dz_time","0","Deactivationtime\n - 0: Zones are never disabled. - x: Time for deactivation.");
	g_BotImmunity = CreateConVar("dz_botimmunity","0", "- 1: Bots don't get killed in a DeathZone,\n - 0: Bots get killed in a DeathZone.");
	
	RegConsoleCmd("dz_clearzone", CommandClearZone, "clears current point coordinates for Death Zone.");
	RegConsoleCmd("dz_setzone", CommandSetZone, "set 3 point coordinates and the min/max height for Death Zone.");
	RegConsoleCmd("dz_savezone_ct", CommandSaveZoneCT, "save the current cooridinates for Death Zone that will slay the CT team.");
	RegConsoleCmd("dz_savezone_t", CommandSaveZoneT, "save the current cooridinates for Death Zone that will slay the T team.");
	RegConsoleCmd("dz_savezone_all", CommandSaveZoneALL, "save the current cooridinates for Death Zone that will slay everybody.");
	RegConsoleCmd("dz_delzone_ct", CommandDeleteZoneCT, "delete the last saved Death Zone that will slay the CT team.");
	RegConsoleCmd("dz_delzone_t", CommandDeleteZoneT, "delete the last saved Death Zone that will slay the T team.");
	RegConsoleCmd("dz_delzone_all", CommandDeleteZoneALL, "delete the last saved Death Zone that will slay everybody.");
	RegConsoleCmd("dz_testzones", CommandTestZones, "test the Death Zones by your current position.");

	AutoExecConfig(true, "DeathZone", "sourcemod");
	
	HookEvent("round_start", RoundStart); 
	HookEvent("round_end", RoundEnd);
	
	CreateTimer(1.0, BarrierJumpingCheckThread, _,TIMER_REPEAT);
}

public OnAllPluginsLoaded(){
	//g_ConVarFreezeTime = FindConVar("mp_freezetime");
}

public OnMapStart()
{
	decl String:szDataFile[256];
	decl String:MapName[32];
	GetCurrentMap(MapName, 32);

	InitializeCoords();

	BuildPath(Path_SM, szDataFile, sizeof(szDataFile), "data/dz_%s.txt", MapName);
	if (FileExists(szDataFile))
	{
		ReadDataFile(szDataFile);
	}

	PrecacheSound(SOUND_BLIP, true);
	PrecacheSound(SOUND_BEEP, true);
	PrecacheSound(SOUND_FINAL, true);
	PrecacheSound(SOUND_BOOM, true);
	PrecacheSound(SOUND_FREEZE, true);

	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
}

public Action:RoundStart(Handle:event,const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_DeactivationTime)){
		//g_DeactivateTimer = CreateTimer(GetConVarFloat(g_DeactivationTime) + GetConVarFloat(g_ConVarFreezeTime), DeactivateZone);
		g_DeactivateTimer = CreateTimer(GetConVarFloat(g_DeactivationTime), DeactivateZone);
	}
	
	return Plugin_Continue;
}

public Action:RoundEnd(Handle:event,const String:name[], bool:dontBroadcast)
{
	//Kill Timer
	if(g_ZoneActive == 1 && GetConVarBool(g_DeactivationTime)){
		KillTimer(g_DeactivateTimer);
		g_DeactivateTimer = INVALID_HANDLE;
	}
	
	g_ZoneActive = 1;
	
	return Plugin_Continue;
}

public Action:DeactivateZone(Handle:timer)
{
	g_ZoneActive = 0;
	
	PrintToChatAll("\x01\x04[Death Zone]\x01 Zones are now disabled!");
	
	return Plugin_Continue;
}

CheckForValidPlayer(client)
{
	if (client <= 0 || !IsClientConnected(client) || !IsClientInGame(client))
		return false;

	new AdminId:adminid = GetUserAdmin(client);
	new bool:has_Root = (adminid == INVALID_ADMIN_ID) ? false : GetAdminFlag(adminid, Admin_Root);
	if (!has_Root)
	{
		ReplyToCommand(client, "You do not have the right permission to this command.");
		return false;
	}

	if (GetClientTeam(client) != TEAM_SPEC)
	{
		ReplyToCommand(client, "You have to be Spectrator to use this command.");
		return false;
	}

	return true;
}

public Action:CommandSetZone(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	new Float:PlayerCoords[3];
	GetClientAbsOrigin(client, PlayerCoords);
	if (g_SetCoords[0] == 0.0)
	{
		g_SetCoords[0] = PlayerCoords[0];
		g_SetCoords[1] = PlayerCoords[1];
		ReplyToCommand(client, "First point setted. (x: %f, y: %f)\nNext will be the second point.", PlayerCoords[0], PlayerCoords[1]);
	}
	else if (g_SetCoords[2] == 0.0)
	{
		g_SetCoords[2] = PlayerCoords[0];
		g_SetCoords[3] = PlayerCoords[1];
		ReplyToCommand(client, "Second point setted. (x: %f, y: %f)\nNext will be the third point.", PlayerCoords[0], PlayerCoords[1]);
	}
	else if (g_SetCoords[4] == 0.0)
	{
		g_SetCoords[4] = PlayerCoords[0];
		g_SetCoords[5] = PlayerCoords[1];
		ReplyToCommand(client, "Third point setted. (x: %f, y: %f)\nNext will be the minimum height.", PlayerCoords[0], PlayerCoords[1]);
	}
	else if (g_SetCoords[6] == 0.0)
	{
		g_SetCoords[6] = PlayerCoords[2];
		ReplyToCommand(client, "Minimum height setted. (zMin: %f)\nNext will be the maximum height.", PlayerCoords[2]);
	}
	else if (g_SetCoords[7] == 0.0)
	{
		g_SetCoords[7] = PlayerCoords[2];
		ReplyToCommand(client, "Maximum height setted. (zMax: %f)\nNext will be the Reason.", PlayerCoords[2]);
	}
	else if (StrEqual(g_SetReason,"")){
		if(args == 0){
			ReplyToCommand(client, "Please set now the Reason for killing, with dz_setzone \"<Reason>\".");
		}
		else{
			GetCmdArg(1,g_SetReason,255);
			ReplyToCommand(client,"Reason setted.\nNext will be the Escape Time.");
		}
	}
	else if (g_SetTime == -1){
		if(args == 0){
			ReplyToCommand(client, "Please set now the Escape Time, with dz_setzone <Time in Seconds>.");
		}
		else{
			new String:time[16];
			GetCmdArg(1,time,15);
			g_SetTime = StringToInt(time);
			ReplyToCommand(client,"Escape Time setted.\nNow save the zone with dz_savezone_ct or dz_savezone_t or dz_savezone_all or reset with dz_clearzone. %d",g_SetTime);
		}
	}
	else
	{
		ReplyToCommand(client, "A zone is already setted.\nx1: %f, y1: %f\nx2: %f, y2: %f\nx3: %f, y3: %f\nzMin: %f, zMax: %f\nReason: %s\n Escape Time: %d\nNow save the zone with dz_savezone_ct or dz_savezone_t or reset with dz_clearzone.",
			g_SetCoords[0],
			g_SetCoords[1],
			g_SetCoords[2],
			g_SetCoords[3],
			g_SetCoords[4],
			g_SetCoords[5],
			g_SetCoords[6],
			g_SetCoords[7],
			g_SetReason,
			g_SetTime);
	}

	return Plugin_Handled;
}

public Action:CommandClearZone(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;


	for (new i=0; i<8; ++i)
		g_SetCoords[i] = 0.0;
	
	strcopy(g_SetReason,255,"");
	g_SetTime = -1;

	ReplyToCommand(client, "Current point coordinates for zone resetted.\nNow redefine zone with dz_setzone.");	

	return Plugin_Handled;
}

public Action:CommandSaveZoneCT(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	for (new i=0; i<8; ++i)
	{
		if (g_SetCoords[i] == 0.0)
		{
			ReplyToCommand(client, "Current coordinates are not complete. Please use dz_setzone more times to define a complete zone.");
			return Plugin_Handled;
		}
		
	}
	
	if (StrEqual(g_SetReason,"")){
		ReplyToCommand(client, "Reason is not complete. Please use dz_setzone more times to define a complete zone.");
		return Plugin_Handled;
	}
	
	if (g_SetTime == -1){
		ReplyToCommand(client, "Escape Time is not complete. Please use dz_setzone more times to define a complete zone.");
		return Plugin_Handled;
	}
	
	if (g_MaxCoordsCT+1 >= MAX_CT_COORDS)
	{
		ReplyToCommand(client, "Maximum number of zones to save reached. Please delete a zone first with dz_delzone_ct.");
		return Plugin_Handled;
	}

	for (new i=0; i<8; ++i)
	{
		g_CTCoords[g_MaxCoordsCT][i] = g_SetCoords[i];
	}
	strcopy(g_CTReason[g_MaxCoordsCT],255,g_SetReason);
	g_CTTime[g_MaxCoordsCT] = g_SetTime;
	
	ReplyToCommand(client, "Zone saved for CT: %d.", g_MaxCoordsCT++);

	WriteDataFile();

	for (new i=0; i<8; ++i)
		g_SetCoords[i] = 0.0;

	strcopy(g_SetReason,255,"");
	g_SetTime = -1;
	
	return Plugin_Handled;
}

public Action:CommandSaveZoneT(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	for (new i=0; i<8; ++i)
	{
		if (g_SetCoords[i] == 0.0)
		{
			ReplyToCommand(client, "Current coordinates are not complete. Please use dz_setzone more times to define a complete zone.");
			return Plugin_Handled;
		}
	}
	
	if (StrEqual(g_SetReason,"")){
		ReplyToCommand(client, "Reason is not complete. Please use dz_setzone more times to define a complete zone.");
		return Plugin_Handled;
	}
	
	if (g_SetTime == -1){
		ReplyToCommand(client, "Escape Time is not complete. Please use dz_setzone more times to define a complete zone.");
		return Plugin_Handled;
	}

	if (g_MaxCoordsT+1 >= MAX_T_COORDS)
	{
		ReplyToCommand(client, "Maximum number of zones to save reached. Please delete a zone first with dz_delzone_t.");
		return Plugin_Handled;
	}

	for (new i=0; i<8; ++i)
	{
		g_TCoords[g_MaxCoordsT][i] = g_SetCoords[i];
	}
	strcopy(g_TReason[g_MaxCoordsT],255,g_SetReason);
	g_TTime[g_MaxCoordsT] = g_SetTime;
	
	ReplyToCommand(client, "Zone saved for T: %d.", g_MaxCoordsT++);

	WriteDataFile();

	for (new i=0; i<8; ++i)
		g_SetCoords[i] = 0.0;
	
	strcopy(g_SetReason,255,"");
	g_SetTime = -1;

	return Plugin_Handled;
}

public Action:CommandSaveZoneALL(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	for (new i=0; i<8; ++i)
	{
		if (g_SetCoords[i] == 0.0)
		{
			ReplyToCommand(client, "Current coordinates are not complete. Please use dz_setzone more times to define a complete zone.");
			return Plugin_Handled;
		}
		
	}
	
	if (StrEqual(g_SetReason,"")){
		ReplyToCommand(client, "Reason is not complete. Please use dz_setzone more times to define a complete zone.");
		return Plugin_Handled;
	}
	
	if (g_SetTime == -1){
		ReplyToCommand(client, "Escape Time is not complete. Please use dz_setzone more times to define a complete zone.");
		return Plugin_Handled;
	}
	
	if (g_MaxCoordsALL+1 >= MAX_ALL_COORDS)
	{
		ReplyToCommand(client, "Maximum number of zones to save reached. Please delete a zone first with dz_delzone_all.");
		return Plugin_Handled;
	}

	for (new i=0; i<8; ++i)
	{
		g_ALLCoords[g_MaxCoordsALL][i] = g_SetCoords[i];
	}
	strcopy(g_ALLReason[g_MaxCoordsALL],255,g_SetReason);
	g_ALLTime[g_MaxCoordsALL] = g_SetTime;
	
	ReplyToCommand(client, "Zone saved for ALL: %d.", g_MaxCoordsALL++);

	WriteDataFile();

	for (new i=0; i<8; ++i)
		g_SetCoords[i] = 0.0;

	strcopy(g_SetReason,255,"");
	g_SetTime = -1;
	
	return Plugin_Handled;
}

public Action:CommandDeleteZoneCT(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	if (g_MaxCoordsCT <= 0)
	{
		ReplyToCommand(client, "There is no zone to delete. The CT-List is empty.");
		return Plugin_Handled;
	}

	for (new i=0; i<8; ++i)
	{
		g_CTCoords[g_MaxCoordsCT][i] = 0.0;
	}
	strcopy(g_CTReason[g_MaxCoordsCT],255,"");
	g_CTTime[g_MaxCoordsCT] = 0;
	
	ReplyToCommand(client, "Last CT-Zone deleted. CT-List has now %d entries.", --g_MaxCoordsCT);

	WriteDataFile();
	return Plugin_Handled;
}

public Action:CommandDeleteZoneT(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	if (g_MaxCoordsT <= 0)
	{
		ReplyToCommand(client, "There is no zone to delete. The T-List is empty.");
		return Plugin_Handled;
	}

	for (new i=0; i<8; ++i)
	{
		g_TCoords[g_MaxCoordsT][i] = 0.0;
	}
	strcopy(g_TReason[g_MaxCoordsT],255,"");
	g_TTime[g_MaxCoordsT] = 0;
	
	ReplyToCommand(client, "Last T-Zone deleted. T-List has now %d entries.", --g_MaxCoordsT);

	WriteDataFile();
	return Plugin_Handled;
}

public Action:CommandDeleteZoneALL(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	if (g_MaxCoordsALL <= 0)
	{
		ReplyToCommand(client, "There is no zone to delete. The ALL-List is empty.");
		return Plugin_Handled;
	}

	for (new i=0; i<8; ++i)
	{
		g_ALLCoords[g_MaxCoordsALL][i] = 0.0;
	}
	strcopy(g_ALLReason[g_MaxCoordsALL],255,"");
	g_ALLTime[g_MaxCoordsALL] = 0;
	
	ReplyToCommand(client, "Last ALL-Zone deleted. ALL-List has now %d entries.", --g_MaxCoordsALL);

	WriteDataFile();
	return Plugin_Handled;
}


public Action:CommandTestZones(client, args)
{
	if (!CheckForValidPlayer(client))
		return Plugin_Handled;

	new i;
	
	for (i=0; i<g_MaxCoordsCT; ++i)
	{
		if (CalculatePlayerInZone(client, g_CTCoords[i]))
		{
			ReplyToCommand(client, "You're in an Death Zone. As an CT You would be slain.");
			return Plugin_Handled;
		}
	}

	for (i=0; i<g_MaxCoordsT; ++i)
	{
		if (CalculatePlayerInZone(client, g_TCoords[i]))
		{
			ReplyToCommand(client, "You're in an Death Zone. As an T You would be slain.");
			return Plugin_Handled;
		}
	}
	
	for (i=0; i<g_MaxCoordsALL; ++i)
	{
		if (CalculatePlayerInZone(client, g_ALLCoords[i]))
		{
			ReplyToCommand(client, "You're in an Death Zone. Everybody would be slain.");
			return Plugin_Handled;
		}
	}

	ReplyToCommand(client, "You're safe. No Death Zone here.");
	return Plugin_Handled;
}

InitializeCoords()
{
	g_MaxCoordsCT = 0;
	g_MaxCoordsT = 0;
	g_MaxCoordsALL = 0;

	for (new i=0; i<8; ++i)
	{
		new ii;
		for (ii=0; ii<MAX_CT_COORDS; ++ii)
		{
			g_CTCoords[ii][i] = 0.0;
			strcopy(g_CTReason[ii],255,"");
			g_CTTime[ii] = 0;
		}

		for (ii=0; ii<MAX_T_COORDS; ++ii)
		{
			g_TCoords[ii][i] = 0.0;
			strcopy(g_TReason[ii],255,"");
			g_TTime[ii] = 0;
		}
		
		for (ii=0; ii<MAX_ALL_COORDS; ++ii)
		{
			g_ALLCoords[ii][i] = 0.0;
			strcopy(g_ALLReason[ii],255,"");
			g_ALLTime[ii] = 0;
		}

		g_SetCoords[i] = 0.0;
	}
	strcopy(g_SetReason,255,"");
	g_SetTime = -1;
}

ReadDataFile(String:szFile[256])
{
	new Handle:hFile = OpenFile(szFile, "r");

	if (hFile == INVALID_HANDLE)
		return;

	while (!IsEndOfFile(hFile))
	{
		decl String:szLine[256];
		if (!ReadFileLine(hFile, szLine, sizeof(szLine)))
			break;

		TrimString(szLine);

		decl String:szCoords[11][256];
		if (ExplodeString(szLine, ",", szCoords, 11, 255) != 11)
			break;
	
		new iTeam = 0;
		for (new i=0; i<11; ++i)
		{
			if (i == 0)
			{
				iTeam = StringToInt(szCoords[i]);
				continue;
			}

			if (iTeam == TEAM_CT)
			{
				if(i == 9){
					strcopy(g_CTReason[g_MaxCoordsCT],255,szCoords[i]);
				}
				else if(i == 10){
					g_CTTime[g_MaxCoordsCT] = StringToInt(szCoords[i]);
				}
				else{
					g_CTCoords[g_MaxCoordsCT][i-1] = StringToFloat(szCoords[i]);
				}
			}
			else if (iTeam == TEAM_T)
			{
				if(i == 9){
					strcopy(g_TReason[g_MaxCoordsT],255,szCoords[i]);
				}
				else if(i == 10){
					g_TTime[g_MaxCoordsT] = StringToInt(szCoords[i]);
				}
				else{
					g_TCoords[g_MaxCoordsT][i-1] = StringToFloat(szCoords[i]);
				}
			}
			else if (iTeam == TEAM_ALL)
			{
				if(i == 9){
					strcopy(g_ALLReason[g_MaxCoordsALL],255,szCoords[i]);
				}
				else if(i == 10){
					g_ALLTime[g_MaxCoordsALL] = StringToInt(szCoords[i]);
				}
				else{
					g_ALLCoords[g_MaxCoordsALL][i-1] = StringToFloat(szCoords[i]);
				}
			}
		}

		if (iTeam == TEAM_CT)
		{
			if (++g_MaxCoordsCT >= MAX_CT_COORDS)
				break;
		}
		else if (iTeam == TEAM_T)
		{
			if (++g_MaxCoordsT >= MAX_T_COORDS)
				break;
		}
		else if (iTeam == TEAM_ALL)
		{
			if (++g_MaxCoordsALL >= MAX_ALL_COORDS)
				break;
		}
	}

	CloseHandle(hFile);
}

WriteDataFile()
{
	decl String:szDataFile[256];
	decl String:MapName[32];
	GetCurrentMap(MapName, 32);
	BuildPath(Path_SM, szDataFile, sizeof(szDataFile), "data/dz_%s.txt", MapName);
	new Handle:hFile = OpenFile(szDataFile, "w");

	if (hFile == INVALID_HANDLE)
		return;

	FileSeek(hFile, 0, SEEK_SET);

	for (new i=0; i<g_MaxCoordsCT; ++i)
	{
		if (!WriteFileLine(hFile, "%d,%f,%f,%f,%f,%f,%f,%f,%f,%s,%d", TEAM_CT, g_CTCoords[i][0], g_CTCoords[i][1], g_CTCoords[i][2], g_CTCoords[i][3], g_CTCoords[i][4], g_CTCoords[i][5], g_CTCoords[i][6], g_CTCoords[i][7],g_CTReason[i],g_CTTime[i]))
			break;
	}

	for (new i=0; i<g_MaxCoordsT; ++i)
	{
		if (!WriteFileLine(hFile, "%d,%f,%f,%f,%f,%f,%f,%f,%f,%s,%d", TEAM_T, g_TCoords[i][0], g_TCoords[i][1], g_TCoords[i][2], g_TCoords[i][3], g_TCoords[i][4], g_TCoords[i][5], g_TCoords[i][6], g_TCoords[i][7],g_TReason[i],g_TTime[i]))
			break;
	}
	
	for (new i=0; i<g_MaxCoordsALL; ++i)
	{
		if (!WriteFileLine(hFile, "%d,%f,%f,%f,%f,%f,%f,%f,%f,%s,%d", TEAM_ALL, g_ALLCoords[i][0], g_ALLCoords[i][1], g_ALLCoords[i][2], g_ALLCoords[i][3], g_ALLCoords[i][4], g_ALLCoords[i][5], g_ALLCoords[i][6], g_ALLCoords[i][7],g_ALLReason[i],g_ALLTime[i]))
			break;
	}

	CloseHandle(hFile);
}

CalculatePlayerInZone(client, Float:ZoneCoords[8])
{
	if(g_ZoneActive == 0) return false;
	
	new Float:PlayerCoord[3];
	GetClientAbsOrigin(client, PlayerCoord);

	new Float:PlayerZ = PlayerCoord[2];
	new Float:ZoneMinZ = ZoneCoords[6];
	new Float:ZoneMaxZ = ZoneCoords[7];
	new Float:Temp;

	if (ZoneMinZ > ZoneMaxZ)
	{
		Temp = ZoneMinZ;
		ZoneMinZ = ZoneMaxZ;
		ZoneMaxZ = Temp;
	}

	if (PlayerZ < ZoneMinZ || PlayerZ > ZoneMaxZ)
		return false;

	new Float:PlayerX = PlayerCoord[0];
	new Float:PlayerY = PlayerCoord[1];
	new Float:ZoneX1 = ZoneCoords[0];
	new Float:ZoneX2 = ZoneCoords[2];
	new Float:ZoneX3 = ZoneCoords[4];
	new Float:ZoneY1 = ZoneCoords[1];
	new Float:ZoneY2 = ZoneCoords[3];
	new Float:ZoneY3 = ZoneCoords[5];
	new Float:TempY1;
	new Float:TempY2;

	if (ZoneX1 > ZoneX2)
	{
		Temp = ZoneX1;
		ZoneX1 = ZoneX2;
		ZoneX2 = Temp;
	}

	TempY1 = (ZoneY2 - ZoneY1) / (ZoneX2 - ZoneX1) * (PlayerX - ZoneX1) + ZoneY1; // calculating for 1 -> 2
	TempY2 = (ZoneY2 - ZoneY1) / (ZoneX2 - ZoneX1) * (PlayerX - ZoneX3) + ZoneY3; // calculating for 3 -> 4

	if (TempY1 > TempY2)
	{
		Temp = TempY1;
		TempY1 = TempY2;
		TempY2 = Temp;
	}
	
	if (PlayerY < TempY1 || PlayerY > TempY2)
		return false;

	TempY1 = (ZoneY3 - ZoneY2) / (ZoneX3 - ZoneX2) * (PlayerX - ZoneX2) + ZoneY2; // calculating for 2 -> 3
	TempY2 = (ZoneY3 - ZoneY2) / (ZoneX3 - ZoneX2) * (PlayerX - ZoneX1) + ZoneY1; // calculating for 4 -> 1

	if (TempY1 > TempY2)
	{
		Temp = TempY1;
		TempY1 = TempY2;
		TempY2 = Temp;
	}
	
	if (PlayerY < TempY1 || PlayerY > TempY2)
		return false;

	return true;
}

HandlePlayerInZone(client, teamid)
{
	if(teamid == TEAM_CT){
		if(g_CTTime[g_TimeBombCTZone[client]] == 0){
			KillClient(client);
		}
		else{
			g_TimeBombTicks = g_CTTime[g_TimeBombCTZone[client]];
		}
	}
	else if(teamid == TEAM_T){
		if(g_TTime[g_TimeBombTZone[client]] == 0){
			KillClient(client);
		}
		else{
			g_TimeBombTicks = g_TTime[g_TimeBombTZone[client]];
		}
	}
	else if(teamid == TEAM_ALL){
		if(g_ALLTime[g_TimeBombALLZone[client]] == 0){
			KillClient(client);
		}
		else{
			g_TimeBombTicks = g_ALLTime[g_TimeBombALLZone[client]];
		}
	}

	g_TimeBombTeam[client] = teamid;
	g_TimeBombClient[client] = true;
	PerformTimeBomb(client,1);

	decl String:name[32];
	decl String:steamid[32];
	GetClientName(client, name, 32);
	GetClientAuthString(client, steamid, 32);
	
	if(teamid == TEAM_CT){
		LogMessage("\"%s<%d><%s><%s><%s>\" entered Death Zone", name, GetClientUserId(client), steamid, teamname[teamid-1], g_CTReason[g_TimeBombCTZone[client]]);
	}
	else if(teamid == TEAM_T){
		LogMessage("\"%s<%d><%s><%s><%s>\" entered Death Zone", name, GetClientUserId(client), steamid, teamname[teamid-1], g_TReason[g_TimeBombTZone[client]]);
	}
	else if(teamid == TEAM_ALL){
		if(GetClientTeam(client) == TEAM_CT){
			LogMessage("\"%s<%d><%s><%s><%s>\" entered Death Zone", name, GetClientUserId(client), steamid, teamname[2], g_ALLReason[g_TimeBombALLZone[client]]);
		}
		else if(GetClientTeam(client) == TEAM_T){
			LogMessage("\"%s<%d><%s><%s><%s>\" entered Death Zone", name, GetClientUserId(client), steamid, teamname[1], g_ALLReason[g_TimeBombALLZone[client]]);
		}
	}

	PrintToChat(client, "\x01\x04[Death Zone]\x01 Being in this zone is not allowed!");
}

public Action:BarrierJumpingCheckThread(Handle:timer)
{
	static iMaxClients = 0;
	static i = 0;
	static iClientTeam = 0;
	static ii = 0;

	iMaxClients = GetMaxClients();

	for (i=1; i<=iMaxClients; ++i)
	{
		if (!IsClientConnected(i))
			continue;

		if (!IsClientInGame(i))
			continue;

		if (IsFakeClient(i) && GetConVarBool(g_BotImmunity))
			continue;

		if (!IsPlayerAlive(i))
			continue;
		
		if (GetConVarBool(g_Immunity) && GetAdminFlag(GetUserAdmin(i), Admin_Generic))
			continue;

		iClientTeam = GetClientTeam(i);
		if (iClientTeam == TEAM_CT)
		{
			for (ii=0; ii<g_MaxCoordsCT; ++ii)
			{
				if (CalculatePlayerInZone(i, g_CTCoords[ii]))
				{
					if(!g_TimeBombClient[i]){
						g_TimeBombCTZone[i] = ii;
						HandlePlayerInZone(i, iClientTeam);
					}
					break;
				}
				else if(g_TimeBombClient[i] && g_TimeBombCTZone[i] == ii){
					PerformTimeBomb(i,0);
				}
			}
		}
		else if (iClientTeam == TEAM_T)
		{
			for (ii=0; ii<g_MaxCoordsT; ++ii)
			{
				if (CalculatePlayerInZone(i, g_TCoords[ii]))
				{
					if(!g_TimeBombClient[i]){
						g_TimeBombTZone[i] = ii;
						HandlePlayerInZone(i, iClientTeam);
					}
					break;
				}
				else if(g_TimeBombClient[i] && g_TimeBombTZone[i] == ii){
					PerformTimeBomb(i,0);
				}
			}
		}
		for (ii=0; ii<g_MaxCoordsALL; ++ii)
		{
			if (CalculatePlayerInZone(i, g_ALLCoords[ii]))
			{
				if(!g_TimeBombClient[i]){
					g_TimeBombALLZone[i] = ii;
					HandlePlayerInZone(i, TEAM_ALL);
				}
				break;
			}
			else if(g_TimeBombClient[i] && g_TimeBombALLZone[i] == ii){
				PerformTimeBomb(i,0);
			}
		}
	}

	return Plugin_Continue;
}

//Timebomb by AlliedModders LLC

public CreateTimeBomb(client)
{
	g_TimeBombTimers[client] = CreateTimer(1.0, Timer_TimeBomb, client, TIMER_REPEAT);
	g_TimeBombTracker[client] = g_TimeBombTicks;
}

public KillTimeBomb(client)
{
	KillTimer(g_TimeBombTimers[client]);
	g_TimeBombTimers[client] = INVALID_HANDLE;
	g_TimeBombClient[client] = false;
}

public KillAllTimeBombs()
{
	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if (g_TimeBombTimers[i] != INVALID_HANDLE)
		{
			KillTimeBomb(i);
		}
	}
}

public PerformTimeBomb(target, toggle)
{
	switch (toggle)
	{
		case (2):
		{
			if (g_TimeBombTimers[target] == INVALID_HANDLE)
			{
				CreateTimeBomb(target);
			}
			else
			{
				KillTimeBomb(target);
			}			
		}

		case (1):
		{
			if (g_TimeBombTimers[target] == INVALID_HANDLE)
			{
				CreateTimeBomb(target);
			}			
		}
		
		case (0):
		{
			if (g_TimeBombTimers[target] != INVALID_HANDLE)
			{
				KillTimeBomb(target);
			}			
		}
	}
}

public Action:Timer_TimeBomb(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		KillTimeBomb(client);		
		return Plugin_Handled;
	}
	
	g_TimeBombTracker[client]--;
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	
	if (g_TimeBombTracker[client] > 0)
	{
		if (g_TimeBombTracker[client] > 1)
		{
			EmitSoundToClient(client, SOUND_BEEP, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
		}
		else
		{
			EmitSoundToClient(client, SOUND_FINAL, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
		}

		PrintHintText(client,"%d Seconds till you explode", g_TimeBombTracker[client]);
	}
	else
	{
		KillClient(client);
	
		KillTimeBomb(client);
	}
	
	return Plugin_Handled;
}

public KillClient(client){
	new Float:vec[3];
	
	if(g_ZoneActive == 0) return;
	
	GetClientAbsOrigin(client, vec);

	TE_SetupExplosion(vec, g_ExplosionSprite, 5.0, 1, 0, 600, 5000);
	TE_SendToAll();

	EmitAmbientSound(SOUND_BOOM, vec, client, SNDLEVEL_RAIDSIREN);

	decl String:name[64];
	GetClientName(client, name, 64);
	new Verbose = GetConVarInt(g_Verbose);

	ForcePlayerSuicide(client);

	for (new players=1; players<=GetMaxClients(); ++players)
	{
		if (IsClientConnected(players) && IsClientInGame(players) && ((GetUserAdmin(players) != INVALID_ADMIN_ID && (Verbose == 2 || Verbose == 3)) || (Verbose == 4)))
		{
			if(g_TimeBombTeam[client] == TEAM_CT)
				PrintToChat(players,"\x01\x04[Death Zone]\x01 %s was killed because of %s!",name,g_CTReason[g_TimeBombCTZone[client]]);
			else if(g_TimeBombTeam[client] == TEAM_T)
				PrintToChat(players,"\x01\x04[Death Zone]\x01 %s was killed because of %s!",name,g_TReason[g_TimeBombTZone[client]]);
			else if(g_TimeBombTeam[client] == TEAM_ALL)
				PrintToChat(players,"\x01\x04[Death Zone]\x01 %s was killed because of %s!",name,g_ALLReason[g_TimeBombALLZone[client]]);
		}
	}
}
