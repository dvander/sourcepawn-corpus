/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/
//
// SourceMod Script
//
// Developed by <eVa>Dog
// June-August 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// Weighted Companion Cube soccer for TF2
// Shoot, blow up and whack a Weighted Companion Cube around a map
//
// Do not edit code without permission.
// If you do change the code, you do so at your own risk.
//
// Thanks and recognition for the following Code Snippets:
// Beacon adapted from AlliedModders' beacon command
// TF2 Class ammo regen adapted from Deltron's tf2_cap_regen script
// TF2 Particle system by L.Duke adapted for Cube Soccer

// Wut? No Pragma semicolon?  Nope.  Just one more thing to check when it fails to compile!

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

// Plugin Version
#define PLUGIN_VERSION "1.1.001"

// Define bits to detect player on fire
#define PLAYER_ONFIRE	    (1 << 14)

#define SCOUT TFClass_Scout
#define SNIPER TFClass_Sniper
#define SOLDIER TFClass_Soldier
#define DEMO TFClass_DemoMan
#define MEDIC TFClass_Medic
#define HEAVY TFClass_Heavy
#define PYRO TFClass_Pyro
#define SPY TFClass_Spy
#define ENGIE TFClass_Engineer

// Handles
new Handle:g_Cvar_Delay   = INVALID_HANDLE
new Handle:g_Cvar_Caps    = INVALID_HANDLE
new Handle:g_Cvar_Restock = INVALID_HANDLE
new Handle:g_Cvar_Weight  = INVALID_HANDLE
new Handle:g_Cvar_Det     = INVALID_HANDLE
new Handle:g_Cvar_DetSize = INVALID_HANDLE
new Handle:g_Cvar_Enable  = INVALID_HANDLE
new Handle:g_Cvar_MsgType = INVALID_HANDLE
new Handle:g_Cvar_Dmg     = INVALID_HANDLE
new Handle:g_Cvar_DmgType = INVALID_HANDLE
new Handle:g_Cvar_Solid   = INVALID_HANDLE
new Handle:cube_timer = INVALID_HANDLE
new Handle:hAdminMenu = INVALID_HANDLE

// String Arrays
new String:g_modelname1[128] 
new String:g_cappoint[128] 
new String:g_posbar[64]
new String:leftbar[64]
new String:rightbar[64]
new String:g_MapName[64]
new String:bar[64]
new String:redtext[64]
new String:blutext[64]

// Floats and vectors
new Float:g_Center_point[3]
new Float:g_Red_point[3]
new Float:g_Red_angle[3]
new Float:g_Blue_point[3]
new Float:g_Blue_angle[3]
new Float:g_Cube[3]
new Float:g_CubePrevious[3]
new Float:g_RedHeal[3]
new Float:g_BlueHeal[3]
new Float:totaldistance
new Float:redtocenter
new Float:bluetocenter
new Float:cubetocenter
new Float:cubetocenterprevious
new Float:cubedist
new Float:playerdistance[64]
new Float:bestshot
new Float:avgHeight

// Integers and integer arrays
// blue = 3
// red = 2
new bestshotid = -1
new neutral = 0
new g_ent
new g_entblue
new g_entred
new g_entbluemed
new g_entredmed
new g_ent_location_offset
new g_useCustomGoals = 0
new g_usePosBar = 1
new g_BeamSprite
new g_HaloSprite
new g_bonus
new delaycount
new win_flag
new msg_flag
new regen_count
new beam_count
new bluescore
new redscore

new g_last[33]
new playerhealth[33]

// Booleans
new bool:g_Enabled = true
new bool:g_Setup = true

// Colors used
new FullColor[4] = {255, 255, 255, 255}

static const TFClass_MaxAmmo[TFClassType][3] =
{
  {-1, -1, -1}, {32, 36, -1},
  {25, 75, -1}, {16, 32, -1},
  {16, 24, -1}, {150, -1, -1},
  {200, 32, -1}, {200, 32, -1},
  {24, -1, -1}, {32, 200, 200}
}

static const TFClass_MaxClip[TFClassType][2] = 
{
  {-1, -1}, {6, 12}, {25, 0}, {4, 6}, {4, 8}, 
  {40, -1}, {-1, 6}, {-1, 6}, {6, -1}, {6, 12}
}

public Plugin:myinfo = 
{
	name = "TF2 Cube Soccer",
	author = "<eVa>Dog",
	description = "Play cube soccer!",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_cube_version", PLUGIN_VERSION, "Version of TF2 Cube Soccer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	g_Cvar_Delay   = CreateConVar("sm_cube_resetdelay", "30", "- seconds elapsed before Cube is returned to center", _, true, 1.0)
	g_Cvar_Caps    = CreateConVar("sm_cube_cappoints", "0", "- enables/disables cap points <1 to enable (default)>", _, true, 0.0, true, 1.0)
	g_Cvar_Restock = CreateConVar("sm_cube_restockdelay", "2", "- the number of seconds between restocking", _, true, 0.1)
	g_Cvar_Weight  = CreateConVar("sm_cube_weight", "0.6", "- the weight of the Cube, where 0.1 is very light and 1.0 is normal", _, true, 0.1)
	g_Cvar_Det     = CreateConVar("sm_cube_detonate", "1", "- detonate Cube, when goal scored", _, true, 0.0, true, 1.0)
	g_Cvar_DetSize = CreateConVar("sm_cube_detonateforce", "400", "- amount of damage the detonated Cube does, when goal scored", _, true, 0.0)
	g_Cvar_Enable  = CreateConVar("sm_cube_enable", "1", "- enables/disables the plugin", _, true, 0.0, true, 1.0)
	g_Cvar_MsgType = CreateConVar("sm_cube_msgtype", "0", "- 0 is HUD text 1 is menu text" , _, true, 0.0, true, 1.0)
	g_Cvar_DmgType = CreateConVar("sm_cube_dmgtype", "0", "- 0 is disabled 1 reduced damage away from the Cube 2 is mirror damage", _, true, 0.0, true, 2.0)
	g_Cvar_Dmg     = CreateConVar("sm_cube_dmg", "0.5", "- the amount of damage weapons do, when the player is far away from the Cube", _, true, 0.1, true, 1.0)
	g_Cvar_Solid   = FindConVar("sv_turbophysics")

	RegAdminCmd("sm_cube_reset", admin_reset, ADMFLAG_CHAT, " - returns the Cube to start")
	RegAdminCmd("sm_cube_save_center", admin_centerpoint, ADMFLAG_CHAT, " - saves the center point for the Cube")
	RegAdminCmd("sm_cube_save_red", admin_savered, ADMFLAG_CHAT, " - saves the end point for the red team")
	RegAdminCmd("sm_cube_save_blue", admin_saveblue, ADMFLAG_CHAT, " - saves the end point for the blue team")
	RegAdminCmd("sm_cube_disable_caps", remove_cappoints, ADMFLAG_CHAT, " - disables TF2 cap points")
	RegAdminCmd("sm_cube_loc", admin_findloc, ADMFLAG_CHAT, " - displays your location and angle")
	
	HookEvent("teamplay_round_start", RoundStartEvent)
	HookEvent("teamplay_round_active", RoundActiveEvent) 
	HookEvent("teamplay_restart_round", RestartEvent)
	HookEvent("player_hurt", PlayerHurtEvent)
	HookEvent("player_spawn", PlayerSpawnEvent)
	
	HookConVarChange(g_Cvar_Enable, EnableDisableCube)
	
	HookEntityOutput("item_healthkit_medium", "OnPlayerTouch", HealthReset)
	
	g_modelname1 = "models/props/metal_box.mdl"
	g_cappoint =  "models/goalposts.mdl"
	g_posbar =  "----------------------------------------"
	
	g_ent_location_offset = FindSendPropOffs("CTFPlayer", "m_vecOrigin")
	
	LoadTranslations("cube.phrases")
	
	AutoExecConfig(true, "cube")
	
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE) && GetConVarBool(g_Cvar_Enable))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnEventShutdown()
{
	UnhookEvent("teamplay_round_start", RoundStartEvent)
	UnhookEvent("teamplay_round_active", RoundActiveEvent)
	UnhookEvent("teamplay_restart_round", RestartEvent)
	UnhookEvent("player_hurt", PlayerHurtEvent)
	UnhookEvent("player_spawn", PlayerSpawnEvent)
}

public OnMapStart()
{
	SetConVarInt(g_Cvar_Solid, 0)
	
	AddFileToDownloadsTable("models/props/metal_box.mdl")
	AddFileToDownloadsTable("models/props/metal_box.phy")
	AddFileToDownloadsTable("models/props/metal_box.dx80.vtx")
	AddFileToDownloadsTable("models/props/metal_box.dx90.vtx")
	AddFileToDownloadsTable("models/props/metal_box.sw.vtx")
	AddFileToDownloadsTable("models/props/metal_box.vvd")
	AddFileToDownloadsTable("models/goalposts.mdl")
	AddFileToDownloadsTable("models/goalposts.phy")
	AddFileToDownloadsTable("models/goalposts.dx80.vtx")
	AddFileToDownloadsTable("models/goalposts.dx90.vtx")
	AddFileToDownloadsTable("models/goalposts.sw.vtx")
	AddFileToDownloadsTable("models/goalposts.vvd")
	AddFileToDownloadsTable("models/goalposts.xbox.vtx")
	AddFileToDownloadsTable("materials/models/props/metal_box.vmt")
	AddFileToDownloadsTable("materials/models/props/metal_box.vtf")
	AddFileToDownloadsTable("materials/models/props/metal_box_skin001.vmt")
	AddFileToDownloadsTable("materials/models/props/metal_box_skin001.vtf")
	AddFileToDownloadsTable("materials/models/props/metal_box_exponent.vtf")
	AddFileToDownloadsTable("materials/models/props/metal_box_lightwarp.vtf")
	AddFileToDownloadsTable("materials/models/props/metal_box_normal.vtf")
	AddFileToDownloadsTable("materials/models/tor.vtf")
	AddFileToDownloadsTable("materials/models/tor.vmt")
	
	PrecacheModel(g_modelname1, true)
	PrecacheModel(g_cappoint, true)
	g_BeamSprite = PrecacheModel("materials/sprites/light_glow03.vmt")
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt")
	PrecacheModel("models/items/medkit_medium.mdl", true)
		
	PrecacheSound("items/regenerate.wav", true)
	PrecacheSound("items/spawn_item.wav", true)
	
	// Get the name of the map 
	GetCurrentMap(g_MapName, sizeof(g_MapName))

	if (GetConVarBool(g_Cvar_Enable))
		g_Enabled = true
	else
		g_Enabled = false
	
	Format(redtext, sizeof(redtext), "%T", "RedGoal", LANG_SERVER)
	Format(blutext, sizeof(blutext), "%T", "BlueGoal", LANG_SERVER)
	
	// Reset the scores
	bluescore = 0
	redscore = 0
}

public OnMapEnd()
{
	if (g_Enabled)
	{
		if (cube_timer != INVALID_HANDLE)
		{
			KillTimer(cube_timer)
			cube_timer = INVALID_HANDLE
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if (g_Enabled)
	{
		if (GetConVarInt(g_Cvar_MsgType) == 1)
		{
			WelcomeMessage(client)
		}
	}
}

public Action:PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)   
{
	if ((g_Enabled) && (g_Setup))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		CreateTimer(0.1, GetPlayerHealth, client)
	}
}

public Action:GetPlayerHealth(Handle:timer, any:client) 
{
	playerhealth[client] = GetClientHealth(client)
}

public Action:PlayerHurtEvent(Handle:event,  const String:name[], bool:dontBroadcast)   
{
	new client   = GetClientOfUserId(GetEventInt(event, "userid"))
	new health   = GetEventInt(event, "health")
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	
	if ((g_Enabled) && (g_Setup) && (g_bonus == 0))
	{
		if (GetConVarInt(g_Cvar_DmgType) == 1)
		{
			if (attacker > 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker))
			{
				if ((client > 0) && (IsClientInGame(client)) && (IsPlayerAlive(client)) && (client != attacker))
				{
					new Float:attackerVector[3]
					GetClientAbsOrigin(attacker, attackerVector)
					new Float:attackerdistance = GetVectorDistance(attackerVector, g_Cube)			
				
					new Float:clientVector[3]
					GetClientAbsOrigin(client, clientVector)
					new Float:clientdistance = GetVectorDistance(clientVector, g_Cube)
				
					if ((clientdistance > 500) && (attackerdistance > 500))
					{
						new damage = playerhealth[client] - health
						new Float:multiplier = GetConVarFloat(g_Cvar_Dmg)
						if (multiplier > 1.0)
							multiplier = 1.0
					
						playerhealth[client]  = health + RoundFloat(damage * multiplier)
						SetEntityHealth(client, playerhealth[client])
					}
				}
			}
		}
		// Mirror damage
		else if (GetConVarInt(g_Cvar_DmgType) == 2)
		{
			if (attacker > 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker))
			{
				if ((client > 0) && (IsClientInGame(client)) && (IsPlayerAlive(client)) && (client != attacker))
				{
					new Float:attackerVector[3]
					GetClientAbsOrigin(attacker, attackerVector)
					new Float:attackerdistance = GetVectorDistance(attackerVector, g_Cube)			
				
					new Float:clientVector[3]
					GetClientAbsOrigin(client, clientVector)
					new Float:clientdistance = GetVectorDistance(clientVector, g_Cube)
				
					if ((clientdistance > 500) && (attackerdistance > 500))
					{
						new Float:multiplier = GetConVarFloat(g_Cvar_Dmg)
						if (multiplier > 1.0)
							multiplier = 1.0
							
						new damage = playerhealth[client] - health
						playerhealth[client]  = health + RoundFloat(damage * multiplier)
						SetEntityHealth(client, playerhealth[client])
						
						playerhealth[attacker]  = playerhealth[attacker] - RoundFloat(damage * multiplier)
						if (playerhealth[attacker] >= 1)
						{
							SetEntityHealth(attacker, playerhealth[attacker])
						}
						else if (playerhealth[attacker] <= 0)
						{
							ForcePlayerSuicide(attacker)
						}
					}
				}
			}
		}
	}
}

public RestartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_Enabled)
	{
		if (cube_timer != INVALID_HANDLE)
		{
			KillTimer(cube_timer)
			cube_timer = INVALID_HANDLE
		}
	}
}

public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_Enabled)
	{
		delaycount = 0
		win_flag = 0
		msg_flag = 0
		
		for (new q = 0; q <= 10; q++)
		{
			g_last[q] = 0
		}
		
		g_entredmed = 0
		g_entbluemed = 0
		
		new Float:vAngle[3]

		new Float:posred[3]
		new Float:posblue[3]
		new Float:poscenter[3]
		new Float:vecresult[3]
		new Float:camangle[3]
		vAngle[0] = -90.0
		vAngle[1] = 0.0
		vAngle[2] = 0.0

		if (GetMapData(g_MapName))
		{
			g_Setup = true
			
			new edict_index = FindEntityByClassname(-1, "team_control_point_master")
			if (edict_index == -1)
			{
				new g_ctf = CreateEntityByName("team_control_point_master")
				DispatchSpawn(g_ctf)
				AcceptEntityInput(g_ctf, "Enable")
			}		
		
			// Begin spawning the Cube and Goal entities
			// If the config has a custom goal then ignore the goal spawns
			
			new Float:origin[3]
			origin = g_Center_point

			g_ent = CreateEntityByName("prop_physics_multiplayer")
			SetEntityModel(g_ent, g_modelname1)
			DispatchKeyValue(g_ent, "ExplodeRadius", "500")
			
			new String:explodeforce[16]
			Format(explodeforce, sizeof(explodeforce), "%i", GetConVarInt(g_Cvar_DetSize))
			DispatchKeyValue(g_ent, "ExplodeDamage", explodeforce)
			
			new String:weight[8]
			Format(weight, sizeof(weight), "%f", GetConVarFloat(g_Cvar_Weight))
			DispatchKeyValue(g_ent, "massScale", weight)
			DispatchKeyValue(g_ent, "targetname", "the_cube")
			SetEntityMoveType(g_ent, MOVETYPE_VPHYSICS)
			SetEntProp(g_ent, Prop_Data, "m_CollisionGroup", 5)
			SetEntProp(g_ent, Prop_Data, "m_usSolidFlags", 16)
			SetEntProp(g_ent, Prop_Data, "m_nSolidType", 6)
			DispatchSpawn(g_ent)
			AcceptEntityInput(g_ent, "DisableMotion")
			origin[2] += 20
			TeleportEntity(g_ent, origin, NULL_VECTOR, NULL_VECTOR)

			new Float:originblue[3]
			originblue = g_Blue_point
			g_BlueHeal = g_Blue_point
			g_BlueHeal[2] +=20

			if (!g_useCustomGoals)
			{
				g_entblue = CreateEntityByName("prop_physics_override")
				SetEntityModel(g_entblue, g_cappoint)
				DispatchKeyValue(g_entblue, "StartDisabled", "false")
				DispatchKeyValue(g_entblue, "targetname", "blue_goal")
				DispatchKeyValue(g_entblue, "Solid", "6")
				SetEntProp(g_entblue, Prop_Data, "m_CollisionGroup", 5)
				SetEntProp(g_entblue, Prop_Data, "m_usSolidFlags", 16)
				SetEntProp(g_entblue, Prop_Data, "m_nSolidType", 6)
				SetEntityRenderColor(g_entblue, 150, 200, 255, 255)
				DispatchSpawn(g_entblue)
				AcceptEntityInput(g_entblue, "Enable")
				AcceptEntityInput(g_entblue, "TurnOn")
				AcceptEntityInput(g_entblue, "DisableMotion")
				TeleportEntity(g_entblue, originblue, g_Blue_angle, NULL_VECTOR)
			}
			
			
			new Float:originred[3]
			originred = g_Red_point
			g_RedHeal = g_Red_point
			g_RedHeal[2] +=20
			if (!g_useCustomGoals)
			{
				g_entred = CreateEntityByName("prop_physics_override")
				SetEntityModel(g_entred, g_cappoint)
				DispatchKeyValue(g_entred, "StartDisabled", "false")
				DispatchKeyValue(g_entred, "targetname", "red_goal")
				DispatchKeyValue(g_entred, "Solid", "6")
				SetEntProp(g_entred, Prop_Data, "m_CollisionGroup", 5)
				SetEntProp(g_entred, Prop_Data, "m_usSolidFlags", 16)
				SetEntProp(g_entred, Prop_Data, "m_nSolidType", 6)
				SetEntityRenderColor(g_entred, 255, 70, 70, 255)
				DispatchSpawn(g_entred)
				AcceptEntityInput(g_entred, "Enable")
				AcceptEntityInput(g_entred, "TurnOn")
				AcceptEntityInput(g_entred, "DisableMotion")
				TeleportEntity(g_entred, originred, g_Red_angle, NULL_VECTOR)
			}			
				
			// Add the cameras above the Goals
			originblue[2] += 190
			new Handle:trace = TR_TraceRayEx(originblue, vAngle, MASK_SOLID, RayType_Infinite)

			// Get the height from above the props to the roof of the map
			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(posblue, trace)
			}
			CloseHandle(trace)
			
			originred[2] += 190
			trace = TR_TraceRayEx(originred, vAngle, MASK_SOLID, RayType_Infinite)

			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(posred, trace)
			}
			CloseHandle(trace)
			
			origin[2] += 190
			trace = TR_TraceRayEx(origin, vAngle, MASK_SOLID, RayType_Infinite)

			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(poscenter, trace)
			}
			CloseHandle(trace)
			
			//Average the heights and set all the cameras to the same height
			avgHeight = (posred[2] + posblue[2] + poscenter[2]) / 3
			avgHeight -= 10
			
			posred[2] = avgHeight
			posblue[2] = avgHeight
			poscenter[2] = avgHeight
			
			new g_iop1 = CreateEntityByName("info_observer_point")
			DispatchKeyValue(g_iop1, "Angles", "90 0 0")
			DispatchKeyValue(g_iop1, "TeamNum", "0")
			DispatchKeyValue(g_iop1, "StartDisabled", "0")
			DispatchKeyValue(g_iop1, "associated_team_entity", "the_cube")
			DispatchSpawn(g_iop1)
			AcceptEntityInput(g_iop1, "Enable")
			TeleportEntity(g_iop1, poscenter, NULL_VECTOR, NULL_VECTOR)
			
			MakeVectorFromPoints(posred, origin, vecresult)
			GetVectorAngles(vecresult, camangle)
			
			new g_iop2 = CreateEntityByName("info_observer_point")
			DispatchKeyValue(g_iop2, "TeamNum", "0")
			DispatchKeyValue(g_iop2, "StartDisabled", "0")
			DispatchKeyValue(g_iop2, "associated_team_entity", "red_goal")
			DispatchSpawn(g_iop2)
			AcceptEntityInput(g_iop2, "Enable")
			TeleportEntity(g_iop2, posred, camangle, NULL_VECTOR)

			MakeVectorFromPoints(posblue, origin, vecresult)
			GetVectorAngles(vecresult, camangle)
			 
			new g_iop3 = CreateEntityByName("info_observer_point")
			DispatchKeyValue(g_iop3, "TeamNum", "0")
			DispatchKeyValue(g_iop3, "StartDisabled", "0")
			DispatchKeyValue(g_iop3, "associated_team_entity", "blue_goal")
			DispatchSpawn(g_iop3)
			AcceptEntityInput(g_iop3, "Enable")
			TeleportEntity(g_iop3, posblue, camangle, NULL_VECTOR)

			CreateTimer(1.0, HealthSpawn, 2)
			CreateTimer(1.0, HealthSpawn, 3)

			//Reset stats
			regen_count = 0
			beam_count = 0
			bestshot = 0.0
			bestshotid = -1
			
			for (new i = 1; i < 33; i++)
			{
				playerdistance[i] = 0.0
			}
			
			totaldistance = GetVectorDistance(g_Red_point, g_Blue_point)
			redtocenter   = GetVectorDistance(g_Red_point, g_Center_point)
			bluetocenter  = GetVectorDistance(g_Blue_point, g_Center_point)

			if (GetConVarInt(g_Cvar_Caps) == 0)
			{
				remove_cappoints(-1, 0)
			}
			
			if (cube_timer == INVALID_HANDLE)
			{
				cube_timer = CreateTimer(0.1, CheckCube, g_ent, TIMER_REPEAT)
			}
		}
		else
		{
			PrintToServer("[CUBE] %T", "NoMapData", LANG_SERVER)
			g_Setup = false
		}
	}
}

public RoundActiveEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((g_Enabled) && (g_Setup))
	{		
		AcceptEntityInput(g_ent, "EnableMotion")
		
		if (GetConVarInt(g_Cvar_MsgType) == 0)
		{
			HUD_text2("Score a goal with the Companion Cube", "0.3", "4")
		}
	}
}

public Action:CheckCube(Handle:timer, any:client)
{
	new position
	new delay = GetConVarInt(g_Cvar_Delay)
	
		
	if (g_ent > 0)
	{
		GetEntDataVector(g_ent, g_ent_location_offset, g_Cube)
	}
	
	// Check to see Cube has moved
	if ((g_Cube[0] == g_CubePrevious[0]) &&
		(g_Cube[1] == g_CubePrevious[1]) &&
		(g_Cube[2] == g_CubePrevious[2]))
	{
		delaycount++
		
		if ((delaycount >= (delay * 10)) && (msg_flag == 0))
		{
			admin_reset(-1, 0)
			msg_flag = 1
		}
		
		if ((delaycount == ((delay - 10) * 10)) && (msg_flag == 0))
		{
			PrintToChatAll("[CUBE] %T", "CubeWarning", LANG_SERVER)
		}
		
		cubedist = 0.0
	}
	else
	{
		delaycount = 0
		msg_flag = 0
		
		cubedist = GetVectorDistance(g_Cube, g_CubePrevious)
	}
	
	new Float:distanceblue = GetVectorDistance(g_Cube, g_Blue_point)
	new Float:distancered = GetVectorDistance(g_Cube, g_Red_point)
	
	for (new q = 1; q < 10; q++)
	{
		g_last[q] = g_last[q + 1]
	}
	
	if (IsValidEntity(g_ent))
	{
		g_last[10] = GetEntPropEnt(g_ent, Prop_Data, "m_hLastAttacker")
	}
	
	if ((cubedist > 0) && (g_last[10] > 0) && (g_last[10] < 33))
	{
		playerdistance[g_last[10]] = playerdistance[g_last[10]] + cubedist
		if (cubedist > bestshot)
		{
			bestshot = cubedist
			bestshotid = g_last[10]
		}  
	}
	
	cubetocenter = GetVectorDistance(g_Cube, g_Center_point)
	
	if ((distancered < 150) && (cubetocenter > redtocenter) && (win_flag == 0))
	{
		if ((cubetocenterprevious < cubetocenter) && (cubetocenterprevious < redtocenter))
		{
			redscore++
			new assistid = 0
			for (new r = 9; r > 0; r--)
			{
				if (g_last[r] != g_last[10])
				{
					assistid = g_last[r]
					break
				}
			}
			ForceWinners(2, g_last[10], assistid)
			win_flag = 1
			return Plugin_Stop
		}
	}
	if ((distanceblue < 150) && (cubetocenter > bluetocenter) && (win_flag == 0))
	{
		if ((cubetocenterprevious < cubetocenter) && (cubetocenterprevious < bluetocenter))
		{
			bluescore++
			new assistid = 0
			for (new r = 9; r > 0; r--)
			{
				if (g_last[r] != g_last[10])
				{
					assistid = g_last[r]
					break
				}
			}
			ForceWinners(3, g_last[10], assistid)
			win_flag = 1
			return Plugin_Stop
		}
	}
	
	g_CubePrevious = g_Cube
	cubetocenterprevious = cubetocenter
	beam_count++

	if (beam_count == 10)
	{		
		if (g_usePosBar)
		{
			if (distanceblue > totaldistance)
			{
				distanceblue = totaldistance
			}
			
			new Float:disp_blue = (distanceblue / (distanceblue + distancered)) * totaldistance
			
			position = RoundFloat((disp_blue / totaldistance) * 40)

			if (position > 0)
			{
				Format(leftbar, position, "%s", g_posbar)
			}
			
			new rightposition = 40 - position
			if (rightposition > 0)
			{
				Format(rightbar, rightposition, "%s", g_posbar)
			}
			
			Format(bar, 41, "%s|%s", leftbar, rightbar)
			
			Cube_Location(bar)
		}
		
		beam_count = 0
	}

	regen_count++		
	if (regen_count >= RoundFloat(10 * GetConVarFloat(g_Cvar_Restock)))
	{
		//BeamRingPoint(origin, startradius, endradius, texture, halo, startframe, framerate, life, width, spread, amp, color(rgba), speed, fade)
		TE_SetupBeamRingPoint(g_Cube, 10.0, 800.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 55.0, 0.1, FullColor, 10, 5)
		TE_SendToAll()
		
		for (new target = 1; target <= GetMaxClients(); target++)
		{					
			if (IsClientInGame(target))
			{
				if (IsPlayerAlive(target))
				{
					new Float:targetVector[3]
					GetClientAbsOrigin(target, targetVector)
							
					new Float:distance = GetVectorDistance(targetVector, g_Cube)
							
					if (distance < 400)
					{
						SetEntityHealth(target, TF2_GetPlayerResourceData(target, TFResource_MaxHealth))
												
						new TFClassType:class = TF2_GetPlayerClass(target)
						FillClientAmmo(target, class)
						FillClientClip(target, class)
						
						new playerstate = GetEntProp(target, Prop_Send, "m_nPlayerCond")
						if ((playerstate & PLAYER_ONFIRE) != 0)
						{
							SetEntProp(target, Prop_Send, "m_nPlayerCond", (playerstate & (~PLAYER_ONFIRE)))
						}
					}
				}
			}
		}
		regen_count = 0
	}
	
	return Plugin_Continue
}

public Action:ForceWinners(winners, scorer, assister)
{
	if (cube_timer != INVALID_HANDLE)
	{
		KillTimer(cube_timer)
		cube_timer = INVALID_HANDLE
	}
	
	g_bonus = 1
	
	new String:scoredby[256]
	new String:assistedby[256]
	new String:buffer[256]
	
	if ((scorer > 0) && (IsClientInGame(scorer)))
	{
		new String:ScorerName[64]
		GetClientName(scorer, ScorerName, sizeof(ScorerName))
		Format(buffer, sizeof(buffer), "%T", "ScoredBy", LANG_SERVER)
		Format(scoredby, sizeof(scoredby), "%s: %s", buffer, ScorerName)
		
		new scorerteam = GetClientTeam(scorer)
		if (scorerteam == winners)
		{
			LogToGame("\"%L\" triggered \"cube_score\"", scorer)
		}
		else
		{
			LogToGame("\"%L\" triggered \"cube_score_own_goal\"", scorer)
		}
		
		if (IsPlayerAlive(scorer))
		{
			AttachParticle(scorer, "Achieved")
		}
		
		HUD_text2(scoredby, "0.3", "1")
	}
	
	if ((assister > 0) && (IsClientInGame(assister)))
	{
		new String:AssisterName[64]
		GetClientName(assister, AssisterName, sizeof(AssisterName)) 
		Format(buffer, sizeof(buffer), "%T", "AssistedBy", LANG_SERVER)
		Format(assistedby, sizeof(assistedby), "%s: %s", buffer, AssisterName)
		
		new assisterteam = GetClientTeam(assister)
		if (assisterteam == winners)
		{
			LogToGame("\"%L\" triggered \"cube_score_assist\"", assister)
		}
		else
		{
			LogToGame("\"%L\" triggered \"cube_score_own_goal_assist\"", assister)
		}
		
		if (IsPlayerAlive(assister))
		{
			AttachParticle(assister, "Achieved")
		}
		
		HUD_text2(assistedby, "0.33", "2")
	}
	
	new Float:highestDistance = 0.0
	new highestDistanceClient = -1
	
	for (new target = 1; target <= GetMaxClients(); target++)
	{
		if (playerdistance[target] > highestDistance)
		{
			highestDistance = playerdistance[target]
			highestDistanceClient = target
		}
		if (IsClientInGame(target))
		{	
			PrintToChat(target, "%t %i ft! (%im)", "Pushed" , RoundFloat(playerdistance[target] / 12), RoundFloat(playerdistance[target] * 0.0254))
		}
		playerdistance[target] = 0.0
	}
	
	new String:BestDistanceName[64]
	GetClientName(highestDistanceClient, BestDistanceName, sizeof(BestDistanceName))
	Format(buffer, sizeof(buffer), "%T", "MostDistance", LANG_SERVER)
	new String:bestdistance[256]
	Format(bestdistance, sizeof(bestdistance), "%s: %s", buffer, BestDistanceName)
	HUD_text2(bestdistance, "0.36", "3")
	if ((highestDistanceClient) && (IsClientInGame(highestDistanceClient)) && (IsPlayerAlive(highestDistanceClient)) && (highestDistanceClient != scorer))
	{
		AttachParticle(highestDistanceClient, "Achieved")
	}
	LogToGame("\"%L\" triggered \"cube_distance\"", highestDistanceClient)
	
	new String:BestShotName[64]
	GetClientName(bestshotid, BestShotName, sizeof(BestShotName))
	Format(buffer, sizeof(buffer), "%T", "BestShot", LANG_SERVER)
	new String:bestshots[256]
	Format(bestshots, sizeof(bestshots), "%s: %s", buffer, BestShotName)
	HUD_text2(bestshots, "0.39", "4")
	
	if ((bestshotid) && (IsClientInGame(bestshotid)) && (IsPlayerAlive(bestshotid)) && (bestshotid != scorer) && (bestshotid != highestDistanceClient))
	{
		AttachParticle(bestshotid, "Achieved")
	}
	LogToGame("\"%L\" triggered \"cube_best_shot\"", bestshotid)
	
	new control = FindEntityByClassname(-1, "team_control_point_master")
	SetVariantInt(winners)
	AcceptEntityInput(control, "SetWinner")
	
	if (GetConVarInt(g_Cvar_Det) == 1)
	{
		CreateTimer(2.0, Kablooey, 0)
	}
	return Plugin_Continue
}

public Action:Kablooey(Handle:timer, any:client)
{	
	AcceptEntityInput(g_ent, "Break")
	ShowParticle(g_Cube, "cinefx_goldrush", 5.0)
}
	
public Action:admin_reset(client, args)
{
	if ((g_Enabled) && (g_Setup))
	{
		new Float:origin[3]
		origin = g_Center_point
		origin[2] += 20
		TeleportEntity(g_ent, origin, NULL_VECTOR, NULL_VECTOR)
		
		if (client > 0)
		{
			new String:AdminName[128]
			GetClientName(client, AdminName, sizeof(AdminName))
			PrintToChatAll("[CUBE] %s %T", AdminName, "AdminCubeReturned", LANG_SERVER)
		}
		else
		{
			PrintToChatAll("[CUBE] %T", "CubeReturned", LANG_SERVER)
		}
	}
	else
	{
		if (client > 0)
			PrintToChat(client, "[CUBE] %T", "NoMapData", client)
	}
	return Plugin_Handled
}

public Action:admin_findloc(client, args)
{
	if (client > 0)
	{
		new Float:vLocation[3]
		new Float:vAngles[3]
		GetClientAbsOrigin(client, vLocation)
		GetClientEyeAngles(client, vAngles)
		PrintToChat(client, "[CUBE] %t: %f %f %f", "YourLocation", vLocation[0], vLocation[1], vLocation[2])
		PrintToConsole(client, "[CUBE] %t: %f %f %f", "YourLocation", vLocation[0], vLocation[1], vLocation[2])
		PrintToChat(client, "[CUBE] %t: %f %f %f", "YourAngle", vAngles[0], vAngles[1], vAngles[2])
		PrintToConsole(client, "[CUBE] %t: %f %f %f", "YourAngle", vAngles[0], vAngles[1], vAngles[2])
	}
	return Plugin_Handled
}

public Action:admin_centerpoint(client, args)
{
	if (client > 0)
	{
		GetClientAbsOrigin(client, g_Center_point)
		SetMapData(g_MapName, "center", g_Center_point)
		PrintToChat(client, "[CUBE] %T", "CenterSaved", client)
	}
	return Plugin_Handled
}

public Action:admin_savered(client, args)
{
	if (client > 0)
	{
		GetClientAbsOrigin(client, g_Red_point)
		SetMapData(g_MapName, "red", g_Red_point)
		GetClientEyeAngles(client, g_Red_angle)
		g_Red_angle[0] = 0.000000
		SetMapData(g_MapName, "redangle", g_Red_angle)
		PrintToChat(client, "[CUBE] %T", "RedSaved", client)
	}
	return Plugin_Handled
}

public Action:admin_saveblue(client, args)
{
	if (client > 0)
	{
		GetClientAbsOrigin(client, g_Blue_point)
		SetMapData(g_MapName, "blue", g_Blue_point)
		GetClientEyeAngles(client, g_Blue_angle)
		g_Blue_angle[0] = 0.000000
		SetMapData(g_MapName, "blueangle", g_Blue_angle)
		PrintToChat(client, "[CUBE] %T", "BlueSaved", client)	
	}
	return Plugin_Handled
}

bool:GetMapData(String:mapname[])
{
	new Handle:kv = CreateKeyValues("MapData")
	
	decl String:datapath[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, datapath, PLATFORM_MAX_PATH, "configs/sm_cube_mapdata.txt")
		
	FileToKeyValues(kv, datapath)
	if (!KvJumpToKey(kv, mapname))
	{
		return false
	}
	
	KvGetVector(kv, "center", g_Center_point)
	KvGetVector(kv, "red", g_Red_point)
	KvGetVector(kv, "blue", g_Blue_point)
	KvGetVector(kv, "redangle", g_Red_angle)
	KvGetVector(kv, "blueangle", g_Blue_angle)
	
	g_useCustomGoals = KvGetNum(kv, "usemapgoals", 0)
	g_usePosBar      = KvGetNum(kv, "usepositionbar", 1)
	
	CloseHandle(kv) 
	return true
}

bool:SetMapData(String:mapname[], String:key[], Float:vector[3])
{
	new Handle:kv = CreateKeyValues("MapData")

	decl String:datapath[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, datapath, PLATFORM_MAX_PATH, "configs/sm_cube_mapdata.txt")

	FileToKeyValues(kv, datapath)
	if (!KvJumpToKey(kv, mapname, true))
	{
		return false
	}

	KvSetVector(kv, key, vector)

	KvRewind(kv)
	KeyValuesToFile(kv, datapath)

	CloseHandle(kv)
	return true
}

public Action:remove_cappoints(client, args)
{
	if (g_Enabled)
	{
		new edict_index
		new x = -1
		
		for (new i = 0; i < 5; i++)
		{
			edict_index = FindEntityByClassname(x, "trigger_capture_area")
			if (IsValidEntity(edict_index))
			{
				SetVariantInt(neutral)
				AcceptEntityInput(edict_index, "SetTeam")
				AcceptEntityInput(edict_index, "Disable")
				x = edict_index
			}
		}
		
		x = -1
		for (new i = 0; i < 5; i++)
		{
			edict_index = FindEntityByClassname(x, "team_control_point")
			if (IsValidEntity(edict_index))
			{
				AcceptEntityInput(edict_index, "Disable")
				AcceptEntityInput(edict_index, "HideModel")
				x = edict_index
			}
		}
		
		x = -1
		new flag_index
		for (new i = 0; i < 5; i++)
		{
			flag_index = FindEntityByClassname(x, "item_teamflag")
			if (IsValidEntity(flag_index))
			{
				AcceptEntityInput(flag_index, "Disable")
				PrintToServer("[CUBE] Cube - Flag disabled: %i", flag_index)
				x = flag_index
			}
		}
	}
	else
	{
		PrintToChat(client, "[CUBE] %T", "CubeDisabled", client)
	}
	return Plugin_Handled
}

public Action:Cube_Location(String:position[64])
{
	new g_text = CreateEntityByName("game_text")
	DispatchKeyValue(g_text,"targetname", "game_text01")
	DispatchKeyValue(g_text,"message", blutext)
	DispatchKeyValue(g_text,"spawnflags", "1")
	DispatchKeyValue(g_text,"channel", "1")
	DispatchKeyValue(g_text,"holdtime", "1")
	DispatchKeyValue(g_text,"fxtime", "0.1")
	DispatchKeyValue(g_text,"fadeout", "0.1")
	DispatchKeyValue(g_text,"fadein", "0.1")
	DispatchKeyValue(g_text,"x", "0.205")
	DispatchKeyValue(g_text,"y", "0.755")
	DispatchKeyValue(g_text,"color", "0 0 255")
	DispatchKeyValue(g_text,"effect", "0")
	DispatchSpawn(g_text)
	AcceptEntityInput(g_text, "Display")
	
	new g_text2 = CreateEntityByName("game_text")
	DispatchKeyValue(g_text2,"targetname", "game_text02")
	DispatchKeyValue(g_text2,"message", redtext)
	DispatchKeyValue(g_text2,"spawnflags", "1")
	DispatchKeyValue(g_text2,"channel", "2")
	DispatchKeyValue(g_text2,"holdtime", "1")
	DispatchKeyValue(g_text2,"fxtime", "0.1")
	DispatchKeyValue(g_text2,"fadeout", "0.1")
	DispatchKeyValue(g_text2,"fadein", "0.1")
	DispatchKeyValue(g_text2,"x", "0.70")
	DispatchKeyValue(g_text2,"y", "0.755")
	DispatchKeyValue(g_text2,"color", "255 0 0")
	DispatchKeyValue(g_text2,"effect", "0")
	DispatchSpawn(g_text2)
	AcceptEntityInput(g_text2, "Display")

	new g_text3 = CreateEntityByName("game_text")
	DispatchKeyValue(g_text3,"targetname", "game_text03")
	DispatchKeyValue(g_text3,"message", position)
	DispatchKeyValue(g_text3,"spawnflags", "1")
	DispatchKeyValue(g_text3,"channel", "3")
	DispatchKeyValue(g_text3,"holdtime", "1")
	DispatchKeyValue(g_text3,"fxtime", "0.1")
	DispatchKeyValue(g_text3,"fadeout", "0.1")
	DispatchKeyValue(g_text3,"fadein", "0.1")
	DispatchKeyValue(g_text3,"x", "-1")
	DispatchKeyValue(g_text3,"y", "0.755")
	DispatchKeyValue(g_text3,"color", "255 255 0")
	DispatchKeyValue(g_text3,"color2", "0 110 240")
	DispatchKeyValue(g_text3,"effect", "0")
	DispatchSpawn(g_text3)
	AcceptEntityInput(g_text3, "Display")
	
	AcceptEntityInput(g_text, "Kill")
	AcceptEntityInput(g_text2, "Kill")
	AcceptEntityInput(g_text3, "Kill")
}

public Action:HUD_text2(String:info[256], String:y[8], String:channel[8])
{
	new g_text4 = CreateEntityByName("game_text")
	new String:tname[13]
	Format(tname, 12, "game_text_%i", g_text4)
	DispatchKeyValue(g_text4,"targetname", tname)
	DispatchKeyValue(g_text4,"message", info)
	DispatchKeyValue(g_text4,"spawnflags", "1")
	DispatchKeyValue(g_text4,"channel", channel)
	DispatchKeyValue(g_text4,"holdtime", "8")
	DispatchKeyValue(g_text4,"fxtime", "0.25")
	DispatchKeyValue(g_text4,"fadeout", "0.5")
	DispatchKeyValue(g_text4,"fadein", "1.5")
	DispatchKeyValue(g_text4,"x", "-1")
	DispatchKeyValue(g_text4,"y", y)
	DispatchKeyValue(g_text4,"color", "255 255 255")
	DispatchKeyValue(g_text4,"color2", "0 110 240")
	DispatchKeyValue(g_text4,"effect", "0")
	DispatchSpawn(g_text4)
	AcceptEntityInput(g_text4, "Display")
	CreateTimer(10.0, kill_entity, g_text4) 
}

public Action:kill_entity(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		AcceptEntityInput(ent, "Kill")
	}
}

stock FillClientAmmo(client, TFClassType:class)
{
	for (new i=0 ; i<sizeof(TFClass_MaxAmmo[]) ; i++)
	{
		if (TFClass_MaxAmmo[class][i] == -1) continue

		SetEntData(client,FindSendPropInfo("CTFPlayer", "m_iAmmo") + ((i+1)*4),TFClass_MaxAmmo[class][i], 4, true)
		EmitSoundToClient(client, "items/regenerate.wav", _, _, _, _, 0.8)
	}
}

stock FillClientClip(client, TFClassType:class)
{
	for (new i=0 ; i<sizeof(TFClass_MaxClip[]) ; i++)
	{
		if (TFClass_MaxClip[class][i] == -1) continue
		new weapon = GetPlayerWeaponSlot(client, i);
		if (weapon == -1) continue
		SetEntData(weapon,FindSendPropInfo("CTFWeaponBase", "m_iClip1"),TFClass_MaxClip[class][i])
	}
}

AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system")
	
	new String:tName[128]
	if (IsValidEdict(particle))
	{
		new Float:pos[3]
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos)
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR)
		
		Format(tName, sizeof(tName), "target%i", ent)
		DispatchKeyValue(ent, "targetname", tName)
		
		DispatchKeyValue(particle, "targetname", "tf2particle")
		DispatchKeyValue(particle, "parentname", tName)
		DispatchKeyValue(particle, "effect_name", particleType)
		DispatchSpawn(particle)
		SetVariantString(tName)
		AcceptEntityInput(particle, "SetParent", particle, particle, 0)
		SetVariantString("head")
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0)
		ActivateEntity(particle)
		AcceptEntityInput(particle, "start")
		CreateTimer(5.0, DeleteParticles, particle)
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[256]
        GetEdictClassname(particle, classname, sizeof(classname))
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle)
        }
    }
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
    new particle = CreateEntityByName("info_particle_system")
    if (IsValidEdict(particle))
    {
        TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR)
        DispatchKeyValue(particle, "effect_name", particlename)
        ActivateEntity(particle)
        AcceptEntityInput(particle, "start")
        CreateTimer(time, DeleteParticles, particle)
    }  
}

public Action:HealthSpawn(Handle:timer, any:team)
{
	if (team == 3)
	{
		if (g_entbluemed == 0)
		{
			g_entbluemed = CreateEntityByName("item_healthkit_medium")
			DispatchKeyValue(g_entbluemed, "targetname", "redhealth")
			DispatchKeyValue(g_entbluemed, "StartDisabled", "false")
			DispatchKeyValue(g_entbluemed, "TeamNum", "0")
			DispatchSpawn(g_entbluemed)
			AcceptEntityInput(g_entbluemed, "Enable")
			TeleportEntity(g_entbluemed, g_Red_point, g_Red_angle, NULL_VECTOR)
			EmitSoundToAll("items/spawn_item.wav", g_entbluemed, _, _, _, 0.6)
		}
	}
	
	if (team == 2)
	{
		if (g_entredmed == 0)
		{
			g_entredmed = CreateEntityByName("item_healthkit_medium")
			DispatchKeyValue(g_entredmed, "targetname", "bluehealth")
			DispatchKeyValue(g_entredmed, "StartDisabled", "false")
			DispatchKeyValue(g_entredmed, "TeamNum", "0")
			DispatchSpawn(g_entredmed)
			AcceptEntityInput(g_entredmed, "Enable")
			TeleportEntity(g_entredmed, g_Blue_point, g_Blue_angle, NULL_VECTOR)
			EmitSoundToAll("items/spawn_item.wav", g_entredmed, _, _, _, 0.6)
		}
	}
}

public HealthReset(const String:output[], caller, activator, Float:delay) 
{	
	new Float:timedly = GetConVarFloat(g_Cvar_Restock) * 2.5
	if (caller == g_entbluemed)
	{
		if (IsValidEntity(caller))
	    {
			AcceptEntityInput(caller, "Kill")
			g_entbluemed = 0
			CreateTimer(timedly, HealthSpawn, 3)
		}
	}
	 else if (caller == g_entredmed)
	{
		if (IsValidEntity(caller))
		{
			AcceptEntityInput(caller, "Kill")
			g_entredmed = 0
			CreateTimer(timedly, HealthSpawn, 2)
		}
	}
}

public EnableDisableCube(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) > 0)
	{
		g_Enabled = true
		new Handle:topmenu
		if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		{
			OnAdminMenuReady(topmenu)
		}
		PrintToChatAll("[SM] %t", "ActionEnabled")
	}
	else
	{
		g_Enabled = false
		hAdminMenu = INVALID_HANDLE
		PrintToChatAll("[SM] %t", "ActionDisabled")
	}
}

// Routine adapted from AlliedModders sm_msay command
WelcomeMessage(client)
{
	decl String:title[100]
	decl String:message[192]
	
	Format(title, 64, "%T", "WelcomeTitle", client)
	Format(message, 192, "%T", "WelcomeMessage", client)
	
	ReplaceString(message, 192, "\\n", "\n")
	
	new Handle:mSayPanel = CreatePanel()
	SetPanelTitle(mSayPanel, title)
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER)
	DrawPanelText(mSayPanel, message)
	DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER)

	SetPanelCurrentKey(mSayPanel, 10)
	DrawPanelItem(mSayPanel, "Press to Exit", ITEMDRAW_CONTROL)

	SendPanelToClient(mSayPanel, client, Handler_DoNothing, 20)

	CloseHandle(mSayPanel)
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	/* Do nothing */
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu

	new TopMenuObject:player_commands = AddToTopMenu(
		hAdminMenu,		// Menu
		"cube",		// Name
		TopMenuObject_Category,	// Type
		Handle_Category,	// Callback
		INVALID_TOPMENUOBJECT	// Parent
		)

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
			"sm_cube_save_red",
			TopMenuObject_Item,
			AdminMenu_Red,
			player_commands,
			"sm_cube_save_red",
			ADMFLAG_CHAT)
		
		AddToTopMenu(hAdminMenu,
			"sm_cube_save_blue",
			TopMenuObject_Item,
			AdminMenu_Blue,
			player_commands,
			"sm_cube_save_blue",
			ADMFLAG_CHAT)
			
		AddToTopMenu(hAdminMenu,
			"sm_cube_save_center",
			TopMenuObject_Item,
			AdminMenu_Center,
			player_commands,
			"sm_cube_save_center",
			ADMFLAG_CHAT)
			
		AddToTopMenu(hAdminMenu,
			"sm_cube_reset",
			TopMenuObject_Item,
			AdminMenu_Reset,
			player_commands,
			"sm_cube_reset",
			ADMFLAG_CHAT)
	}
}
public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	switch( action )
	{
		case TopMenuAction_DisplayTitle:
			Format( buffer, maxlength, "Control the Game:" )
		case TopMenuAction_DisplayOption:
			Format( buffer, maxlength, "Cube Commands" )
	}
}
 
public AdminMenu_Red(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Save the Red Goal")
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_savered(param, 0)
	}
}

public AdminMenu_Blue(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Save the Blue Goal")
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_saveblue(param, 0)
	}
}

public AdminMenu_Center(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Save the Cube Start Point")
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_centerpoint(param, 0)
	}
}

public AdminMenu_Reset(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Reset the Cube")
	}
	else if (action == TopMenuAction_SelectOption)
	{
		admin_reset(param, 0)
	}
}