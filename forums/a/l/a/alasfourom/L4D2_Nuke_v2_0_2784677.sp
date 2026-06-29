/*=========================================================================================================

	Plugin Info:

*	Name	:	L4D Elevator Teleport
*	Author	:	alasfourom
*	Descp	:	Teleport Survivors To The Elevator After Time Passes
*	Link	:	https://forums.alliedmods.net/showthread.php?t=338961
*	Thanks	:	Grey83, Silvers, honorcode23 , Peace-Maker, finishlast, SupermenCJ

===========================================================================================================

Version 1.3 (17-Aug-2022) - Added 2 Teleportation Points In c3m1_plankcountry and c5m2_park.

Version 1.2 (10-Aug-2022) - Added countdown, elevator auto-activated after teleport.

Version 1.1 (06-Aug-2022) - Rewrote the plugin, made it more simple.

Version 1.0 (06-Aug-2022) - Initial release.*/

/* =============================================================================================================== *
 *											Includes, Pragmas and Defines			   							   *
 *================================================================================================================ */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.0"

#define NUKE_SOUND "animation/overpass_jets.wav"
#define EXPLOSION_SOUND "ambient/explosions/explode_1.wav"
#define EXPLOSION_DEBRIS "animation/plantation_exlposion.wav"
#define FIRE_PARTICLE "gas_explosion_ground_fire"
#define EXPLOSION_PARTICLE "FluidExplosion_fps"

#define FFADE_IN            0x0001
#define FFADE_OUT           0x0002
#define FFADE_MODULATE      0x0004
#define FFADE_STAYOUT       0x0008
#define FFADE_PURGE         0x0010

#define MAX_ENTITIES		8
#define EXPLOSION_PARTICLE "FluidExplosion_fps"

/* =============================================================================================================== *
 *                                				F18_Sounds & g_sVocalize										   *
 *================================================================================================================ */

char F18_Sounds[6][128] =
{
	"animation/jets/jet_by_01_lr.wav",
	"animation/jets/jet_by_02_lr.wav",
	"animation/jets/jet_by_03_lr.wav",
	"animation/jets/jet_by_04_lr.wav",
	"animation/jets/jet_by_05_lr.wav",
	"animation/jets/jet_by_05_rl.wav"
};

static const char g_sVocalize[][] =
{
	"scenes/Coach/WorldC5M4B04.vcd",		//Damn! That one was close!
	"scenes/Coach/WorldC5M4B05.vcd",		//Shit. Damn, that one was close!
	"scenes/Coach/WorldC5M4B02.vcd",		//STOP BOMBING US.
	"scenes/Gambler/WorldC5M4B09.vcd",		//Well, it's official: They're trying to kill US now.
	"scenes/Gambler/WorldC5M4B05.vcd",		//Christ, those guys are such assholes.
	"scenes/Gambler/World220.vcd",			//WHAT THE HELL ARE THEY DOING?  (reaction to bombing)
	"scenes/Gambler/WorldC5M4B03.vcd",		//STOP BOMBING US!
	"scenes/Mechanic/WorldC5M4B02.vcd",		//They nailed that.
	"scenes/Mechanic/WorldC5M4B03.vcd",		//What are they even aiming at?
	"scenes/Mechanic/WorldC5M4B04.vcd",		//We need to get the hell out of here.
	"scenes/Mechanic/WorldC5M4B05.vcd",		//They must not see us.
	"scenes/Mechanic/WorldC5M103.vcd",		//HEY, STOP WITH THE BOMBING!
	"scenes/Mechanic/WorldC5M104.vcd",		//PLEASE DO NOT BOMB US
	"scenes/Producer/WorldC5M4B04.vcd",		//Something tells me they're not checking for survivors anymore.
	"scenes/Producer/WorldC5M4B01.vcd",		//We need to keep moving.
	"scenes/Producer/WorldC5M4B03.vcd"		//That was close.
};

/* =============================================================================================================== *
 *									Plugin Variables - Float, Int, Bool, ConVars			   					   *
 *================================================================================================================ */

static int g_iEntities[MAX_ENTITIES];
float g_fEnd;

Handle g_hTimer;

bool g_bNukeTime_Started;
bool g_bNuke_Activated;
bool g_bAirstrike;
bool g_bNukeCmd_Used;
bool g_bPlayersAreGettingStriked;

ConVar 	g_hNukeEnable;
ConVar 	g_hNukeTime;
ConVar 	g_hAnnounce;
ConVar 	g_hWarning;
ConVar 	g_hNukePause;

/* =============================================================================================================== *
 *                                		 		 	Plugin Info													   *
 *================================================================================================================ */

public Plugin myinfo =
{
	name = "L4D2 Nuke",
	version = PLUGIN_VERSION,
	description = "City Will Be Nuked After Countdown Time Passes",
	author = "alasfourom",
	url = "https://forums.alliedmods.net/showthread.php?t=338742"
}

public void OnPluginStart()
{
	CreateConVar ("l4d2_nuke_version", PLUGIN_VERSION, "L4D2 Nuke" ,FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hNukeEnable = CreateConVar("l4d2_nuke_enable", "1.0", "0 = Disable, 1 = Enable All Chapters, 2 = Enable Only In Finals", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_hNukeTime   = CreateConVar("l4d2_nuke_timer", "600.0", "Set The Time In Seconds At Which Players Will Be Nuked", FCVAR_NOTIFY);
	g_hAnnounce   = CreateConVar("l4d2_nuke_announcer", "90.0", "At What Time In Seconds You Want The Hint Text Announcement To Be Displayed", FCVAR_NOTIFY);
	g_hWarning 	  = CreateConVar("l4d2_nuke_warning", "1", "Display Nuke Warning Text When Players Leave Saferoom", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hNukePause  = CreateConVar("l4d2_nuke_pause", "1", "Pausing Nuke Countdown When A Survivor Reaches The Check Point", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig(true, "L4D2_Nuke_v2.0");
	
	HookEvent("player_entered_checkpoint", Event_EnteredCheckPoint);
	HookEvent("player_left_start_area", Event_LeftStartArea);
	HookEvent("player_left_safe_area", Event_LeftStartArea);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	RegAdminCmd("sm_nuke_start", Command_Nuke_Start, ADMFLAG_UNBAN);
	RegAdminCmd("sm_nuke_stop", Command_Nuke_Stop, ADMFLAG_UNBAN);
	RegConsoleCmd("sm_nuke", Command_Nuke, "Print Nuke Countdown To Players");
}

public void OnMapStart()
{
	g_bNukeTime_Started = false;
	g_bNuke_Activated = false;
	g_bNukeCmd_Used = false;
	g_bPlayersAreGettingStriked = false;
	
	PrecacheSound(NUKE_SOUND);
	PrecacheSound(EXPLOSION_SOUND);
	PrecacheSound(EXPLOSION_DEBRIS);
	
	int i = 0;
	while (i < 6)
	{
		PrecacheSound(F18_Sounds[i], true);
		i += 1;
	}
	
	PrecacheParticle(EXPLOSION_PARTICLE);
	PrecacheParticle(FIRE_PARTICLE);
	
	PrecacheModel("models/f18/f18_sb.mdl", true);
	PrecacheModel("models/missiles/f18_agm65maverick.mdl", true);
}

public Action Command_Nuke_Start(int client, int args)
{
	if (g_bNukeCmd_Used)
		PrintToChat(client, "\x04[Nuke] \x01You Need To \x03Start A New Round \x01To Activate It Again.");
		
	else if(!g_bNukeTime_Started)
		PrintToChat(client, "\x04[Nuke] \x01You Need To \x03Leave Saferoom \x01First To Activate It.");
		
	else if(g_bNuke_Activated)
		PrintToChat(client, "\x04[Nuke] \x01Nuke Already \x03Activated\x01.");
		
	else 
	{
		g_bNuke_Activated = true;
		g_bNukeCmd_Used = true;
		PrintToChatAll("\x04[Nuke] \x01Player \x03%N \x01Has Launched The Nuke.", client);
	}
	
	return Plugin_Handled;
}

public Action Command_Nuke_Stop(int client, int args)
{
	if (g_bNukeCmd_Used)
		PrintToChat(client, "\x04[Nuke] \x01You Need To \x03Start A New Round \x01To Activate It Again.");
		
	else if(!g_bNukeTime_Started)
		PrintToChat(client, "\x04[Nuke] \x01You Need To \x03Leave Saferoom \x01First To Abort It.");
	
	else if(g_bNuke_Activated)
		PrintToChat(client, "\x04[Nuke] \x01Its \x03Too Late To \x01Abort It.");
		
	else
	{
		g_bNukeTime_Started = false;
		g_bNuke_Activated = false;
		g_bAirstrike = false;
		g_bNukeCmd_Used = true;
			
		if (g_bNuke_Activated) delete g_hTimer;
		PrintToChatAll("\x04[Nuke] \x01Player \x03%N \x01Has Aborted The Launch Time.", client);
	}
	
	return Plugin_Handled;
}

public Action Command_Nuke(int client, int args)
{
	if (GetConVarInt(g_hNukeEnable) == 0)
		return Plugin_Handled;
	
	else if (GetConVarInt(g_hNukeEnable) == 1)
	{
		if (g_bNukeTime_Started)
		{
			int timeleft = RoundToNearest(g_fEnd - GetEngineTime());
			if(timeleft > 0) PrintToChatAll("\x04[Warning] \x01Nuke Timeleft: \x03%d min %d sec", timeleft / 60, timeleft % 60);
		}
		else
		{
			int timestart = RoundToNearest(g_hNukeTime.FloatValue);
			PrintToChatAll("\x04[Warning] \x01Nuke Timeleft: \x03%d min %d sec", timestart / 60, timestart % 60);
		}
	}
	
	else if (GetConVarInt(g_hNukeEnable) == 2 && !IsFinalMap())
		PrintToChat(client, "\x04[Warning] \x01Nuke Will Launch At \x03Final Chapter\x01.");
	
	else if (GetConVarInt(g_hNukeEnable) == 2 && IsFinalMap())
	{
		if (g_bNukeTime_Started)
		{
			int timeleft = RoundToNearest(g_fEnd - GetEngineTime());
			if(timeleft > 0) PrintToChatAll("\x04[Warning] \x01Nuke Timeleft: \x03%d min %d sec", timeleft / 60, timeleft % 60);
		}
		else
		{
			int timestart = RoundToNearest(g_hNukeTime.FloatValue);
			PrintToChatAll("\x04[Warning] \x01Nuke Timeleft: \x03%d min %d sec", timestart / 60, timestart % 60);
		}
	}
	return Plugin_Handled;
}

/* =============================================================================================================== *
 *                     				 Timer Countdown Starts After Leaving Saferoom								   *
 *================================================================================================================ */

public void Event_LeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(g_hNukeEnable) != 0 && !g_bNukeTime_Started)
	{
		g_fEnd = GetEngineTime() + g_hNukeTime.FloatValue;
		
		int timeleft = RoundToNearest(g_fEnd - GetEngineTime());
		g_bNukeTime_Started = true;
		
		if (GetConVarInt(g_hNukeEnable) == 1)
		{
			if (g_hWarning.BoolValue) PrintToChatAll("\x04[Warning] \x01Nuke Countdown Started: \x03%d min %d sec", timeleft / 60, timeleft % 60);
			CreateTimer (1.0, Timer_Nuke_Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (GetConVarInt(g_hNukeEnable) == 2 && IsFinalMap())
		{
			if (g_hWarning.BoolValue) PrintToChatAll("\x04[Warning] \x01Nuke Countdown Started: \x03%d min %d sec", timeleft / 60, timeleft % 60);
			CreateTimer (1.0, Timer_Nuke_Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bNukeTime_Started = false;
	g_bNuke_Activated = false;
	g_bAirstrike = false;
	g_bNukeCmd_Used = false;
	g_bPlayersAreGettingStriked = false;
	
	if (g_bNuke_Activated) delete g_hTimer;
}

public void Event_EnteredCheckPoint(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hNukePause.BoolValue)
	{
		g_bNukeTime_Started = false;
		g_bNuke_Activated = false;
		g_bAirstrike = false;
		
		if (g_bNuke_Activated) delete g_hTimer;
	}
}

/* =============================================================================================================== *
 *                     				 	Timer: Countdown Before Nuke Launched									   *
 *================================================================================================================ */

public Action Timer_Nuke_Countdown(Handle timer)
{
	int timeleft = RoundToNearest(g_fEnd - GetEngineTime());
	if (timeleft >= 0 && g_bNukeTime_Started && !g_bNuke_Activated)
	{
		if (timeleft <= g_hAnnounce.FloatValue)
			PrintHintTextToAll("Nuke Time: %d", timeleft);
			
		if (timeleft == 25)
		{
			g_bPlayersAreGettingStriked = true;
			NukeActivated();
		}
			
		if (!g_bNukeTime_Started) return Plugin_Stop;
			
		return Plugin_Continue;
	}
	else if (g_bNuke_Activated && !g_bPlayersAreGettingStriked)
	{
		g_bPlayersAreGettingStriked = true;
		g_fEnd = GetEngineTime() + 25.0;
		int time = RoundToNearest(g_fEnd - GetEngineTime());
		PrintHintTextToAll("Nuke Time: %d", time);
		CreateTimer (1.0, Timer_NukeCmd_Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		NukeActivated();
	}
		
	return Plugin_Stop;
}

public Action Timer_NukeCmd_Countdown(Handle timer)
{
	if(g_bNuke_Activated)
	{
		int timeleft = RoundToNearest(g_fEnd - GetEngineTime());
		if (timeleft >= 0)
		{
			PrintHintTextToAll("Nuke Time: %d", timeleft);
			return Plugin_Continue;
		}
		else return Plugin_Stop;
	}
	else return Plugin_Stop;
}

void NukeActivated()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			StartAirstrike(i);
	}
	
	CreateTimer(25.0, Timer_Start_Nuke_Launcher, _);
}

public Action Timer_Start_Nuke_Launcher(Handle timer)
{
	if(g_bNukeTime_Started)
	{
		Nuke_Launcher();
		PrintHintTextToAll("Nuke Launched");
	}
	return Plugin_Handled;
}

void Nuke_Launcher()
{
	EmitSoundToAll(NUKE_SOUND);
	Activate_FadeEffects();
	g_hTimer = CreateTimer(2.0, Timer_IncapAliveSurvivors, _, TIMER_FLAG_NO_MAPCHANGE);
	g_hTimer = CreateTimer(2.0, Timer_Activate_Strike, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	g_hTimer = CreateTimer(6.2, Timer_SlayAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	g_bNuke_Activated = true;
	return;
}

/* =============================================================================================================== *
 *                     				 				Fade Effects												   *
 *================================================================================================================ */

void Activate_FadeEffects()
{
	CreateFade(FFADE_OUT);
	CreateTimer(2.5, Timer_Remove_FadeEffects, _, TIMER_FLAG_NO_MAPCHANGE);
	return;
}

public Action Timer_Remove_FadeEffects(Handle timer)
{
	CreateFade(FFADE_IN);
	return Plugin_Stop;
}

void CreateFade(int type)
{
	Handle hFadeClient = StartMessageAll("Fade");
	BfWriteShort(hFadeClient, 800);
	BfWriteShort(hFadeClient, 800);
	BfWriteShort(hFadeClient, (FFADE_PURGE|type|FFADE_STAYOUT));
	BfWriteByte(hFadeClient, 255);
	BfWriteByte(hFadeClient, 255);
	BfWriteByte(hFadeClient, 255);
	BfWriteByte(hFadeClient, 255);
	EndMessage();
}

/* =============================================================================================================== *
 *                     				 				Incapping Players											   *
 *================================================================================================================ */

public Action Timer_IncapAliveSurvivors(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			SetEntityHealth(i, 1);
			SDKHooks_TakeDamage(i, i, i, 100.0);
		}
	}
	return Plugin_Stop;
}

/* =============================================================================================================== *
 *                     				 					Slay Players											   *
 *================================================================================================================ */

public Action Timer_SlayAlivePlayers(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
	g_bNuke_Activated = false;
	return Plugin_Stop;
}

/* =============================================================================================================== *
 *         												Activate Strike 										   *
 *================================================================================================================ */

public Action Timer_Activate_Strike(Handle timer)
{
	static int StrikeTimes = 0;
	float radius = 1.0, pos[3];
	
	if (StrikeTimes >= 3)
	{
		StrikeTimes = 0;
		return Plugin_Stop;
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, pos);
			pos[0] += GetRandomFloat(radius*-1, radius);
			pos[1] += GetRandomFloat(radius*-1, radius);
			CreateExplosion(pos);
		}
	}
	
	StrikeTimes++;
	return Plugin_Continue;
}

void CreateExplosion(float pos[3], const float duration = 6.0)
{
	static char buffer[32];
	int ent = CreateEntityByName("info_particle_system");
	
	if(ent != -1)
	{
		DispatchKeyValue(ent, "effect_name", FIRE_PARTICLE);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		ActivateEntity(ent);

		AcceptEntityInput(ent, "Start");
		FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Stop::%f:1", duration);
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
	FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Kill::%f:1", duration+1.5);

	if((ent = CreateEntityByName("info_particle_system")) != -1)
	{
		DispatchKeyValue(ent, "effect_name", EXPLOSION_PARTICLE);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		ActivateEntity(ent);

		AcceptEntityInput(ent, "Start");
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
	
	if((ent = CreateEntityByName("env_explosion")) != -1)
	{
		DispatchKeyValue(ent, "fireballsprite", "sprites/muzzleflash4.vmt");
		DispatchKeyValue(ent, "iMagnitude", "1");
		DispatchKeyValue(ent, "iRadiusOverride", "1");
		DispatchKeyValue(ent, "spawnflags", "828");
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);

		AcceptEntityInput(ent, "Explode");
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}
	
	if((ent = CreateEntityByName("env_physexplosion")) != -1)
	{
		DispatchKeyValue(ent, "radius", "1");
		DispatchKeyValue(ent, "magnitude", "1");
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);

		AcceptEntityInput(ent, "Explode");
		SetVariantString(buffer);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");
	}

	EmitAmbientSound(EXPLOSION_SOUND, pos);
	EmitAmbientSound(EXPLOSION_DEBRIS, pos);

	static const float power = 1.0, flMxDistance = 1.0;
	float orig[3], vec[3], result[3];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", orig);
			if(GetVectorDistance(pos, orig) <= flMxDistance)
			{
				MakeVectorFromPoints(pos, orig, vec);
				GetVectorAngles(vec, result);

				GetEntPropVector(i, Prop_Data, "m_vecVelocity", vec);

				result[0] = Cosine(DegToRad(result[1])) * power + vec[0];
				result[1] = Sine(DegToRad(result[1])) * power + vec[1];
				result[2] = power;

				TeleportEntity(i, orig, NULL_VECTOR, result);
			}
		}
	}
}

/* =============================================================================================================== *
 *               Silvers AirStrike Plugin Edited By SupermenCJ, and Adjusted To Fit Nuke Plugin					   *
 *================================================================================================================ */

void StartAirstrike(int client)
{
	if (g_bAirstrike) return;
	float g_pos[3];
	float vAng[3];
	GetClientAbsOrigin(client, g_pos);
	GetClientEyeAngles(client, vAng);
	
	DataPack h = new DataPack();
	h.WriteFloat(g_pos[0]);
	h.WriteFloat(g_pos[1]);
	h.WriteFloat(g_pos[2]);
	h.WriteFloat(vAng[1]);
	h.WriteFloat(GetEngineTime());
	g_bAirstrike = true;
	CreateTimer(1.5, UpdateAirstrike, h, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action UpdateAirstrike(Handle timer, DataPack h)
{  
	h.Reset();
	float g_pos[3];
	float vAng[3];
	g_pos[0] = h.ReadFloat();
	g_pos[1] = h.ReadFloat();
	g_pos[2] = h.ReadFloat();
	vAng[1] = h.ReadFloat();
	float time = h.ReadFloat();
	
	if (GetEngineTime() - time > 25.0 || !g_bAirstrike)
	{
		g_bAirstrike = false;
		h.Close(); 
		return Plugin_Stop;		
	}
	
	g_pos[2] += 1.0;
	float radius = 1200.0;
	g_pos[0] += GetRandomFloat(radius*-1, radius);
	g_pos[1] += GetRandomFloat(radius*-1, radius);
	vAng[1] += GetRandomFloat(radius*-1, radius);
	ShowAirstrike(g_pos, vAng[1]);
	
	return Plugin_Continue;
}

void ShowAirstrike(float vPos[3], float direction)
{
	int index = -1;
	for (int i = 0; i < MAX_ENTITIES; i++)
	{
		if (!IsValidEntRef(g_iEntities[i]))
		{
			index = i;
			break;
		}
	}

	if (index == -1) return;

	float vAng[3];
	float vSkybox[3];
	vAng[0] = 0.0;
	vAng[1] = direction;
	vAng[2] = 0.0;

	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vSkybox);

	int entity = CreateEntityByName("prop_dynamic_override");
	g_iEntities[index] = EntIndexToEntRef(entity);
	DispatchKeyValue(entity, "targetname", "silver_f18_model");
	DispatchKeyValue(entity, "disableshadows", "1");
	DispatchKeyValue(entity, "model", "models/f18/f18_sb.mdl");
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Data, "m_iHammerID", RoundToNearest(vPos[2]));
	float height = vPos[2] + 1000.0;
	if (height > vSkybox[2] - 200)
		vPos[2] = vSkybox[2] - 200;
	else
		vPos[2] = height;
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 5.0);

	int random = GetRandomInt(1, 5);
	if (random == 1)
		SetVariantString("flyby1");
	else if (random == 2)
		SetVariantString("flyby2");
	else if (random == 3)
		SetVariantString("flyby3");
	else if (random == 4)
		SetVariantString("flyby4");
	else if (random == 5)
		SetVariantString("flyby5");
	AcceptEntityInput(entity, "SetAnimation");
	AcceptEntityInput(entity, "Enable");
	
	SetVariantString("OnUser1 !self:Kill::6.5.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
	
	CreateTimer(1.5, tmrDrop, EntIndexToEntRef(entity));
}

public Action tmrDrop(Handle timer, any f18)
{
	if (IsValidEntRef(f18))
	{
		float g_cvarRadiusF18 = 950.0;
		float vPos[3];
		float vAng[3];
		float vVec[3];
		GetEntPropVector(f18, Prop_Data, "m_vecAbsOrigin", vPos);
		GetEntPropVector(f18, Prop_Data, "m_angRotation", vAng);

		int entity = CreateEntityByName("grenade_launcher_projectile");
		DispatchSpawn(entity);
		SetEntityModel(entity, "models/missiles/f18_agm65maverick.mdl");

		SetEntityMoveType(entity, MOVETYPE_NOCLIP);
		CreateTimer(0.9, TimerGrav, EntIndexToEntRef(entity));

		GetAngleVectors(vAng, vVec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vVec, vVec);
		ScaleVector(vVec, -800.0);
		
		MoveForward(vPos, vAng, vPos, 2400.0);

		vPos[0] += GetRandomFloat(-1.0 * g_cvarRadiusF18, g_cvarRadiusF18);
		vPos[1] += GetRandomFloat(-1.0 * g_cvarRadiusF18, g_cvarRadiusF18);
		TeleportEntity(entity, vPos, vAng, vVec);
		
		SDKHook(entity, SDKHook_Touch, OnBombTouch);
		
		SetVariantString("OnUser1 !self:Kill::10.0:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");

		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.3);

		int projectile = entity;
		// BLUE FLAMES
		entity = CreateEntityByName("info_particle_system");
		if (entity != -1)
		{
			DispatchKeyValue(entity, "effect_name", "flame_blue");
			DispatchSpawn(entity);
			ActivateEntity(entity);
			TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
			
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", projectile);

			SetVariantString("OnUser4 !self:Kill::10.0:1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser4");
			AcceptEntityInput(entity, "Start");
		}
		// FLAMES
		entity = CreateEntityByName("info_particle_system");
		if (entity != -1)
		{
			DispatchKeyValue(entity, "effect_name", "fire_medium_01");
			DispatchSpawn(entity);
			ActivateEntity(entity);
			TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", projectile);

			SetVariantString("OnUser4 !self:Kill::10.0:1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser4");
			AcceptEntityInput(entity, "Start");
		}

		// SPARKS
		entity = CreateEntityByName("info_particle_system");
		if (entity != -1)
		{
			DispatchKeyValue(entity, "effect_name", "fireworks_sparkshower_01e");
			DispatchSpawn(entity);
			ActivateEntity(entity);
			TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", projectile);

			SetVariantString("OnUser4 !self:Kill::10.0:1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser4");
			AcceptEntityInput(entity, "Start");
		}

		// RPG SMOKE
		entity = CreateEntityByName("info_particle_system");
		if (entity != -1)
		{
			DispatchKeyValue(entity, "effect_name", "rpg_smoke");
			DispatchSpawn(entity);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "start");
			TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", projectile);

			SetVariantString("OnUser3 !self:Kill::10.0:1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser3");

			// Refire
			SetVariantString("OnUser1 !self:Stop::0.65:-1");
			AcceptEntityInput(entity, "AddOutput");
			SetVariantString("OnUser1 !self:FireUser2::0.7:-1");
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");

			SetVariantString("OnUser2 !self:Start::0:-1");
			AcceptEntityInput(entity, "AddOutput");
			SetVariantString("OnUser2 !self:FireUser1::0:-1");
			AcceptEntityInput(entity, "AddOutput");
		}

		// SOUND	
		EmitSoundToAll(F18_Sounds[GetRandomInt(0, 5)], entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
	}
}

public Action TimerGrav(Handle timer, any entity)
{
	if (IsValidEntRef(entity)) CreateTimer(0.1, TimerGravity, entity, TIMER_REPEAT);
}

public Action TimerGravity(Handle timer, any entity)
{
	if (IsValidEntRef(entity))
	{
		int tick = GetEntProp(entity, Prop_Data, "m_iHammerID");
		if (tick > 10)
		{
			SetEntityMoveType(entity, MOVETYPE_FLYGRAVITY);
			return Plugin_Stop;
		}
		else
		{
			SetEntProp(entity, Prop_Data, "m_iHammerID", tick + 1);

			float vAng[3];
			GetEntPropVector(entity, Prop_Data, "m_vecVelocity", vAng);
			vAng[2] -= 50.0;
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vAng);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

public Action OnBombTouch(int entity, int activator)
{
	char sTemp[64];
	GetEdictClassname(activator, sTemp, sizeof(sTemp));

	if (strcmp(sTemp, "trigger_multiple") && strcmp(sTemp, "trigger_hurt"))
	{
		SDKUnhook(entity, SDKHook_Touch, OnBombTouch);

		CreateTimer(0.1, TimerBombTouch, EntIndexToEntRef(entity));
	}
}

public Action TimerBombTouch(Handle timer, any entity)
{
	if (EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE)
		return;

	float vPos[3];
	char sTemp[64];
	int g_iCvarDamage = 80;
	int g_iCvarDistance = 400;
	int g_iCvarShake = 1000;
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
	AcceptEntityInput(entity, "Kill");
	IntToString(g_iCvarDamage, sTemp, sizeof(sTemp));

	entity = CreateEntityByName("env_explosion");
	DispatchKeyValue(entity, "spawnflags", "1916");
	IntToString(g_iCvarDamage, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "iMagnitude", sTemp);
	IntToString(g_iCvarDistance, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "iRadiusOverride", sTemp);
	DispatchSpawn(entity);
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "Explode");

	int shake  = CreateEntityByName("env_shake");
	if (shake != -1)
	{
		DispatchKeyValue(shake, "spawnflags", "8");
		DispatchKeyValue(shake, "amplitude", "16.0");
		DispatchKeyValue(shake, "frequency", "1.5");
		DispatchKeyValue(shake, "duration", "0.9");
		IntToString(g_iCvarShake, sTemp, sizeof(sTemp));
		DispatchKeyValue(shake, "radius", sTemp);
		DispatchSpawn(shake);
		ActivateEntity(shake);
		AcceptEntityInput(shake, "Enable");

		TeleportEntity(shake, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(shake, "StartShake");

		SetVariantString("OnUser1 !self:Kill::1.1:1");
		AcceptEntityInput(shake, "AddOutput");
		AcceptEntityInput(shake, "FireUser1");
	}

	int client;
	float fDistance;
	float fNearest = 1500.0;
	float vPos2[3];

	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, vPos2);
			fDistance = GetVectorDistance(vPos, vPos2);

			if (fDistance <= fNearest)
			{
				client = i;
				fNearest = fDistance;
			}
		}
		i += 1;
	}

	if (client)
		Vocalize(client);

	entity = CreateEntityByName("info_particle_system");
	if (entity != -1)
	{
		int random = GetRandomInt(1, 4);
		if (random == 1)
			DispatchKeyValue(entity, "effect_name", EXPLOSION_PARTICLE);
		else if (random == 2)
			DispatchKeyValue(entity, "effect_name", "missile_hit1");
		else if (random == 3)
			DispatchKeyValue(entity, "effect_name", "gas_explosion_main");
		else if (random == 4)
			DispatchKeyValue(entity, "effect_name", "explosion_huge");

		if (random == 1)
			vPos[2] += 175.0;
		else if (random == 2)
			vPos[2] += 100.0;
		else if (random == 4)
			vPos[2] += 25.0;

		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}

	int random = GetRandomInt(0, 2);
	if (random == 0)
		EmitSoundToAll("weapons/hegrenade/explode3.wav", entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
	else if (random == 1)
		EmitSoundToAll("weapons/hegrenade/explode4.wav", entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
	else if (random == 2)
		EmitSoundToAll("weapons/hegrenade/explode5.wav", entity, SNDCHAN_AUTO, SNDLEVEL_HELICOPTER);
}

void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}

void Vocalize(int client)
{
	if (GetRandomInt(1, 100) > 70)
		return;

	char sTemp[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", sTemp, 64);

	int random;
	if (sTemp[26] == 'c')							// c = Coach
		random = GetRandomInt(0, 2);
	else if (sTemp[26] == 'g')						// g = Gambler
		random = GetRandomInt(3, 6);
	else if (sTemp[26] == 'm' && sTemp[27] == 'e')	// me = Mechanic
		random = GetRandomInt(7, 12);
	else if (sTemp[26] == 'p')						// p = Producer
		random = GetRandomInt(13, 15);
	else
		return;

	int entity = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(entity, "SceneFile", g_sVocalize[random]);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Data, "m_hOwner", client);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start", client, client);
}

bool IsValidEntRef(int entity)
{
	if (entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE) return true;
	return false;
}

/* =============================================================================================================== *
 *                     				 				PrecacheParticle											   *
 *================================================================================================================ */

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if ( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}
	if ( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

/* =============================================================================================================== *
 *                     				 					IsFinalMap											 	   *
 *================================================================================================================ */

bool IsFinalMap()
{
	return (FindEntityByClassname(-1, "info_changelevel") == -1
		&& FindEntityByClassname(-1, "trigger_changelevel") == -1);
}