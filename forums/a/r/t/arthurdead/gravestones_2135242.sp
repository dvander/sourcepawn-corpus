/**
    friagram@gmail.com
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/

#include <sourcemod>
#include <sdktools>                
#include <tf2_stocks>
#include <clientprefs>

#define MAX_EPITAPH_LENGTH 	96											// maximum length of death quote string

#define ANNOTATION_HEIGHT       50.0										// distance to raise annotations for epitaphs
#define ANNOTATION_NAME_HEIGHT  20.0										// distance to raise alert annotations
#define OFFSET_HEIGHT          -2.0											// distance to sink stones into the ground

#define MASK_PROP_SPAWN		(CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE)	// contents mask to spawn stones on
#define MAX_SPAWN_DISTANCE		1024.0										// max distance to spawn stones beneath players
#define SOUND_NULL			"vo/null.wav"									// sound file to play for non-audible sounds

#define HUDUPDATERATE			0.5											// how fast to tick updates to the hud

#define PLUGIN_NAME     		"[TF2] Revenge Gravestones"
#define PLUGIN_AUTHOR   		"Friagram"
#define PLUGIN_VERSION  		"1.1.0"   
#define PLUGIN_DESCRIP  		"Drops Gravestones"
#define PLUGIN_CONTACT  		"http://steamcommunity.com/groups/poniponiponi"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIP,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

#define MODEL_RANDOM	7
#define MODEL_SNIPER	8
#define MODEL_PYRO	9
#define MODEL_SCOUT	10
#define MODEL_SOLDIER	11

static const String:g_sGravestoneMDL[][][] = {		// model path... scale of prop....
	{"models/props_manor/gravestone_01.mdl", "0.5"},
	{"models/props_manor/gravestone_02.mdl", "0.5"},
	{"models/props_manor/gravestone_04.mdl", "0.5"},

	{"models/props_manor/gravestone_03.mdl", "0.4"},
	{"models/props_manor/gravestone_05.mdl", "0.4"},

	{"models/props_manor/gravestone_06.mdl", "0.3"},
	{"models/props_manor/gravestone_07.mdl", "0.3"},
	{"models/props_manor/gravestone_08.mdl", "0.3"},
	
	{"models/props_gameplay/tombstone_crocostyle.mdl",		"1.0"},
	{"models/props_gameplay/tombstone_gasjockey.mdl",		"1.0"},
	{"models/props_gameplay/tombstone_specialdelivery.mdl",	"1.0"},
	{"models/props_gameplay/tombstone_tankbuster.mdl",		"1.0"}
};

static const String:g_sSmallestViolin[][] = {		// sound to play when spawning name annotation...
	{"player/taunt_v01.wav"},
	{"player/taunt_v02.wav"},
	{"player/taunt_v05.wav"},
	{"player/taunt_v06.wav"},
	{"player/taunt_v07.wav"},
	{"misc/taps_02.wav"},
	{"misc/taps_03.wav"}
};

new Float:g_fMode;
new Float:g_fAlert;
new Float:g_fDistance;
new Float:g_fTime;
new bool:g_bBots;

new Handle:g_hHUDtimer;											// hud timer

new Handle:g_hEpitaph = INVALID_HANDLE;							// adt array of epitaphs loaded from file
new g_EpitaphSize;												// size of adt array

new bool:g_bPrefShow[MAXPLAYERS+1];								// client preference to view gravestone
new Handle:g_hPrefCookie = INVALID_HANDLE;							// client preference cookie

new g_Gravestone[MAXPLAYERS+1];									// model entity of the player's gravestone
new g_AnnotationEnt[MAXPLAYERS+1];								// model entity of the gravestone the player is looking at

public OnPluginStart()
{
	CreateConVar("revengestone_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	
	new Handle:cVar;
	HookConVarChange(	cVar = CreateConVar("sm_gravestones_mode",  "2", "Mode of operation", FCVAR_PLUGIN, true, 0.0, true, 4.0), ConVarModeChanged);
	g_fMode = GetConVarFloat(cVar);
	if (g_fMode > 1.0)                                       			// If it's not a ratio, round to get a valid mode
	{
		RoundToFloor(g_fMode);
	}

	HookConVarChange(	cVar = CreateConVar("sm_gravestones_alert", "5", "Duration of notification popups", FCVAR_PLUGIN, true, 0.0, true, 20.0), ConVarAlertChanged);
	g_fAlert = GetConVarFloat(cVar);

	HookConVarChange(	cVar = CreateConVar("sm_gravestones_dist",  "400",	"Max distance gravestones will be visible on hud from", FCVAR_PLUGIN, true, 50.0, false,  8000.0), ConVarDistanceChanged);
	g_fDistance = GetConVarFloat(cVar);

	HookConVarChange(	cVar = CreateConVar("sm_gravestones_time",  "600",	"Max time gravestones will exist for", FCVAR_PLUGIN, true, 0.0,  false, 14400.0), ConVarTimeChanged);
	g_fTime = GetConVarFloat(cVar);

	HookConVarChange(	cVar = CreateConVar("sm_gravestones_bots",  "1",		"Allow bots to spawn gravestones", FCVAR_PLUGIN, true, 0.0,  false,     1.0), ConVarBotsChanged);
	g_bBots = GetConVarBool(cVar);

	RegAdminCmd("sm_gravestones_reload", Command_Reloadconfigs, ADMFLAG_RCON, "Reload the Configuration File");
	RegConsoleCmd("sm_gravestones", Command_ViewPrefs, "Switch View Preferences");

	HookEvent("player_death", event_player_death, EventHookMode_Post);

	g_hEpitaph = CreateArray(MAX_EPITAPH_LENGTH);
	
	g_hPrefCookie = RegClientCookie("gravestones_pref", "", CookieAccess_Private);
}

public OnMapStart()
{
	for (new i=0; i < sizeof(g_sGravestoneMDL); i++)
	{
		PrecacheModel( g_sGravestoneMDL[i][0], true );
	}

	for (new i=1; i < sizeof(g_sSmallestViolin); i++)
	{
		PrecacheSound(g_sSmallestViolin[i]);
	}

	PrecacheSound(SOUND_NULL, true);

	for (new i=1; i <= MaxClients; i++)
	{
		g_Gravestone[i]		= INVALID_ENT_REFERENCE;			// better safe than sorry
		g_AnnotationEnt[i]	= -1;							// this will make the annotation dissapear...
		g_bPrefShow[i]		= true;							// in before cookies
	}

	GetEpitaphs();

	if (g_fMode)
	{
		g_hHUDtimer = CreateTimer(HUDUPDATERATE, Timer_UpdateHUD, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		g_hHUDtimer = INVALID_HANDLE;
	}
}

public OnClientCookiesCached(client) 
{
	decl String:value[2];
	GetClientCookie(client, g_hPrefCookie, value, 2);
	if (strlen(value) < 1)
	{
		SetClientCookie(client, g_hPrefCookie, "1");
		g_bPrefShow[client] = true;
	}
	else
	{
		g_bPrefShow[client] = StringToInt(value) == 1 ? true : false;
	}
}

public ConVarModeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_fMode = StringToFloat(newvalue);
	if (g_fMode > 1.0)                                       		// If it's not a ratio, round to get a valid mode
	{
		RoundToFloor(g_fMode);
	}

	if (g_fMode)
	{
		if (g_hHUDtimer != INVALID_HANDLE)
		{
			KillTimer(g_hHUDtimer);
		}
		g_hHUDtimer = CreateTimer(HUDUPDATERATE, Timer_UpdateHUD, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else														// the timer will kill itself if mode is 0
	{
		RemoveAllGravestones();
	}
}

public ConVarAlertChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_fAlert = StringToFloat(newvalue);
}

public ConVarDistanceChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_fDistance = StringToFloat(newvalue);
}

public ConVarTimeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_fTime = StringToFloat(newvalue);
}

public ConVarBotsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bBots = StringToInt(newvalue) == 1 ? true : false;
}

public OnPluginEnd()
{
	RemoveAllGravestones();
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_fMode || GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(CheckCommandAccess(client, "Gravestones_Acess", Admin_Cheats))
	{
		return Plugin_Continue;
	}

	if (client && (g_bBots || !IsFakeClient(client)))					// check if bots are enabled or somehow the client is not valid
	{
		if (g_fMode <= 1.0)
		{
			if (g_fMode >= GetRandomFloat(0.0, 1.0))					// compare ratio to random number between 0 and 1
			{
				SpawnProp(client);
			}
		}
		else if(g_fMode == 2.0)										// revenge kills only
		{
			if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_KILLERREVENGE)
			{
				SpawnProp(client);
			}
		}
		else if(g_fMode == 3.0)										// domination kills only
		{
			if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_KILLERDOMINATION)
			{
				SpawnProp(client);
			}
		}
		else															// revenge and dominations kills
		{
			if (GetEventInt(event, "death_flags") & (TF_DEATHFLAG_KILLERREVENGE|TF_DEATHFLAG_KILLERDOMINATION))
			{
				SpawnProp(client);
			}
		}
	}

	return Plugin_Continue;
}

SpawnProp(client)													// somewhat borrowed from fort wars
{
	decl Handle:TraceRay;
	decl Float:StartOrigin[3];

	new Float:Angles[3] = {90.0, 0.0, 0.0};								// down

	GetClientEyePosition(client, StartOrigin);
	TraceRay = TR_TraceRayFilterEx(StartOrigin, Angles, MASK_PROP_SPAWN, RayType_Infinite, TraceRayProp);
	if (TR_DidHit(TraceRay))
	{
		decl Float:Distance;
		decl Float:EndOrigin[3];
		TR_GetEndPosition(EndOrigin, TraceRay);
		Distance = (GetVectorDistance(StartOrigin, EndOrigin));

		if (Distance < MAX_SPAWN_DISTANCE)
		{
			new ent;
			ent = CreateEntityByName("prop_physics_override");
			if (ent != -1)
			{
				decl idx;
				decl Float:normal[3], Float:normalAng[3];				// offset the prop from the ground plane
				TR_GetPlaneNormal(TraceRay, normal);
				EndOrigin[0] += normal[0]*(OFFSET_HEIGHT);
				EndOrigin[1] += normal[1]*(OFFSET_HEIGHT);
				EndOrigin[2] += normal[2]*(OFFSET_HEIGHT);

				GetClientEyeAngles(client, Angles);
				GetVectorAngles(normal, normalAng);

				Angles[0]  = normalAng[0] -270;						// horizontal is boring

				if (normalAng[0] != 270)
				{
					Angles[1]  = normalAng[1];						// override the horizontal plane
				}

				switch(TF2_GetPlayerClass(client))
				{
					case TFClass_Sniper:	GetRandomInt(0,1) ? (idx = GetRandomInt(0, MODEL_RANDOM)) : (idx = MODEL_SNIPER);
					case TFClass_Pyro:	GetRandomInt(0,1) ? (idx = GetRandomInt(0, MODEL_RANDOM)) : (idx = MODEL_PYRO);
					case TFClass_Scout:	GetRandomInt(0,1) ? (idx = GetRandomInt(0, MODEL_RANDOM)) : (idx = MODEL_SCOUT);
					case TFClass_Soldier:	GetRandomInt(0,1) ? (idx = GetRandomInt(0, MODEL_RANDOM)) : (idx = MODEL_SOLDIER);
					default:
					{
						idx = GetRandomInt(0, MODEL_RANDOM);
					}
				}

				decl String:tname[35];
				decl String:eidx[3];

				GetClientName(client, String:tname, 32);

				if (g_fAlert)
				{
					new bitstring = BuildBitString(EndOrigin);
					if (bitstring)
					{
						new Handle:event = CreateEvent("show_annotation");
						if (event != INVALID_HANDLE)
						{
							SetEventFloat(event, "worldPosX", EndOrigin[0] + (normal[0] * ANNOTATION_NAME_HEIGHT));
							SetEventFloat(event, "worldPosY", EndOrigin[1] + (normal[1] * ANNOTATION_NAME_HEIGHT));
							SetEventFloat(event, "worldPosZ", EndOrigin[2] + (normal[2] * ANNOTATION_NAME_HEIGHT));
							SetEventFloat(event, "lifetime", g_fAlert);
							SetEventInt(event, "id", ent);   // lol?
							SetEventString(event, "text", tname);
							SetEventInt(event, "visibilityBitfield", bitstring);
							SetEventString(event, "play_sound", g_sSmallestViolin[GetRandomInt(0,sizeof(g_sSmallestViolin)-1)]);
							FireEvent(event);
						}
					}
				}

				ReplaceString(tname, 32, ";", ":");
				IntToString(GetRandomInt(0,g_EpitaphSize-1), eidx, 3);
				StrCat(tname, 35, ";");
				StrCat(tname, 35, eidx);

				DispatchKeyValue(ent, "targetname", tname);							// name the prop so we can track it, even if a player disconnects.
				DispatchKeyValue(ent, "solid", "0");
				DispatchKeyValue(ent, "model", g_sGravestoneMDL[idx][0]);
				DispatchKeyValue(ent, "disableshadows", "1");							// lags and looks bad
				DispatchKeyValue(ent, "physdamagescale", "0.0");

				DispatchKeyValueVector(ent, "origin", EndOrigin);
				DispatchKeyValueVector(ent, "angles", Angles);

				DispatchSpawn(ent);

				new Float:scale = StringToFloat(g_sGravestoneMDL[idx][1]);
				if(scale != 1.0)
				{
					SetEntPropFloat(ent, Prop_Send, "m_flModelScale", scale);
				}
				SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2);						// 2 = debris trigger
				SetEntProp(ent, Prop_Send, "m_usSolidFlags", 0);						// 0 = ignore solid type, call into entity for raytrace

				ActivateEntity(ent);

				AcceptEntityInput(ent, "DisableMotion");

				new oldent = EntRefToEntIndex(g_Gravestone[client])
				if (oldent != INVALID_ENT_REFERENCE)
				{
					SetEntPropFloat(oldent, Prop_Send, "m_flModelScale", 1.0);			// if it is not resized, it will crash
					KillWithoutMayhem(oldent);
				}
				g_Gravestone[client] = EntIndexToEntRef(ent);

				CreateTimer(g_fTime, Timer_RemoveGravestone, g_Gravestone[client], TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}

	CloseHandle(TraceRay);
}


public Action:Timer_RemoveGravestone(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent != INVALID_ENT_REFERENCE)
	{
		SetEntPropFloat(ent, Prop_Send, "m_flModelScale", 1.0);
		KillWithoutMayhem(ent);
	}
}

public bool:TraceRayProp(entityhit, mask)
{
	if (entityhit == 0)												// I only want it to hit terrain, no models or debris
	{
		return true;
	}
	return false;
}

public Action:Timer_UpdateHUD(Handle:timer)
{
	if (!g_fMode)																		// they turned off the mod..
	{
		g_hHUDtimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	decl String:buffer[MAX_EPITAPH_LENGTH+32];
	decl String:segment[2][32];
	decl Float:clientpos[3],Float:proppos[3];

	for (new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			new ent = GetObject(i);
			if (ent != -1 && (g_bPrefShow[i] || GetClientButtons(i) & IN_ATTACK2))			// check client prefs, or key activator
			{
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", proppos);
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", clientpos);

				if (GetVectorDistance(clientpos,proppos) < g_fDistance)
				{
					if (g_AnnotationEnt[i] != ent)
					{
						new Handle:event = CreateEvent("show_annotation");
						if (event != INVALID_HANDLE)
						{
							GetEntPropString(ent, Prop_Data, "m_iName", buffer, 36);
							ExplodeString(buffer, ";", segment, 2, 32);					// name;index
							GetArrayString(g_hEpitaph, StringToInt(segment[1]), buffer, MAX_EPITAPH_LENGTH+32);
							ReplaceString(buffer, MAX_EPITAPH_LENGTH, "*", segment[0]);

							decl Float:propAng[3], Float:upVec[3];
							GetEntPropVector(ent, Prop_Send, "m_angRotation", propAng);
							GetAngleVectors(propAng, NULL_VECTOR, NULL_VECTOR, upVec);

							SetEventFloat(event, "worldPosX", proppos[0] + (upVec[0] * ANNOTATION_HEIGHT));
							SetEventFloat(event, "worldPosY", proppos[1] + (upVec[1] * ANNOTATION_HEIGHT));
							SetEventFloat(event, "worldPosZ", proppos[2] + (upVec[2] * ANNOTATION_HEIGHT));
							SetEventFloat(event, "lifetime", 999999.0);				// arbitrarily long
							SetEventInt(event, "id", i);
							SetEventString(event, "text", buffer);
							SetEventInt(event, "visibilityBitfield", 1 << i);
							SetEventString(event, "play_sound", SOUND_NULL);
							FireEvent(event);
							g_AnnotationEnt[i] = ent;
						}
					}
				}
			}
			else if (g_AnnotationEnt[i] != -1)
			{
				new Handle:event = CreateEvent("show_annotation");
				if (event != INVALID_HANDLE)
				{
					SetEventFloat(event, "lifetime", 0.00001);							// arbitrarily short
					SetEventInt(event, "id", i);
					SetEventString(event, "text", " ");
					SetEventInt(event, "visibilityBitfield", 1 << i);
					SetEventInt(event, "follow_entindex", ent);						// follow the client, they won't see it anyway
					SetEventString(event, "play_sound", SOUND_NULL);
					FireEvent(event);
				}
				g_AnnotationEnt[i] = -1;
			}
		}
	}

	return Plugin_Continue;
}

stock GetObject(client)
{
	decl Float:vecClientEyePos[3];
	decl Float:vecClientEyeAng[3];

	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, DontHitSelf, client);

	if (TR_DidHit(INVALID_HANDLE))
	{
		new ent = TR_GetEntityIndex(INVALID_HANDLE);
		if (ent > 0)
		{
			for (new i=1; i <= MaxClients; i++)
			{
				if (EntRefToEntIndex(g_Gravestone[i]) == ent)
				{
					return ent;
				}
			}
		}
	}

	return -1;
}

public bool:DontHitSelf(entity, mask, any:client)
{
	return (client != entity);
}

//////////////////////////////////////////////////////////////////////
/////////////                    Files                   /////////////
//////////////////////////////////////////////////////////////////////

public Action:Command_Reloadconfigs(client, args)
{
	new oldsize = g_EpitaphSize;
	GetEpitaphs();

	if (oldsize > g_EpitaphSize)									// usually people would append lines/correct mistakes
	{															// here they removed or something, so index errors could occur
		RemoveAllGravestones();
	}

	ReplyToCommand(client,"[Gravestones]: Reloaded %i old phrases with %i new", oldsize, g_EpitaphSize);

	return Plugin_Handled;
}

RemoveAllGravestones()
{
	decl ent;
	for (new i=1; i <= MaxClients; i++)
	{
		ent = EntRefToEntIndex(g_Gravestone[i]);
		if (ent != INVALID_ENT_REFERENCE)
		{
			SetEntPropFloat(ent, Prop_Send, "m_flModelScale", 1.0);	// if it is not resized, it will crash
			KillWithoutMayhem(ent);
		}
	}
}

stock GetEpitaphs()
{
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, PLATFORM_MAX_PATH, "configs/gravestones.txt");
	new Handle:fileh = OpenFile(file, "r");

	ClearArray(g_hEpitaph);
	g_EpitaphSize = 0;

	if (fileh == INVALID_HANDLE)
	{
		PushArrayString(g_hEpitaph, "R.I.P. *");					// provide a dummy entry if no file found
		g_EpitaphSize++;
		LogError("[Gravestones]: Could not read %s", file);

		return;
	}

	decl String:buffer[MAX_EPITAPH_LENGTH];
	while (ReadFileLine(fileh, buffer, MAX_EPITAPH_LENGTH))
	{
		TrimString(buffer);
		ReplaceString(buffer, MAX_EPITAPH_LENGTH, "|", "\n");
		PushArrayString(g_hEpitaph, buffer);
		g_EpitaphSize++;

		if (IsEndOfFile(fileh))
		{
			break;
		}
	}

	if (fileh != INVALID_HANDLE)
	{
		CloseHandle(fileh);
	}
	
	if (g_EpitaphSize == 0)
	{
		PushArrayString(g_hEpitaph, "R.I.P. *");					// provide a dummy entry if no file found
		g_EpitaphSize++;
		LogError("[Gravestones]: The file at %s was empty", file);
	}
}

public BuildBitString(Float:position[3])
{
	new bitstring;
	for (new client=1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && g_bPrefShow[client])
		{
			decl Float:EyePos[3];
			GetClientEyePosition(client, EyePos);
			if (GetVectorDistance(position, EyePos) < g_fDistance)
			{
				bitstring |= 1 << client;
			}
		}
	}
	return bitstring;
}

public Action:Command_ViewPrefs(client, args)
{
	if (!client || !IsClientInGame(client))
	{
		return (Plugin_Handled);
	}

	if (g_bPrefShow[client])
	{
		g_bPrefShow[client] = false;
		PrintToChat(client, "\x04[Gravestones]\x01: Automatic display disabled, use alt-fire to view.");
		
		if(AreClientCookiesCached(client))						// make sure DB isn't being slow
		{
			SetClientCookie(client, g_hPrefCookie, "0");
		}
	}
	else
	{
		g_bPrefShow[client] = true;
		PrintToChat(client, "\x04[Gravestones]\x01: Automatic display enabled.");

		if (AreClientCookiesCached(client))						// make sure DB isn't being slow
		{
			SetClientCookie(client, g_hPrefCookie, "1");
		}
	}

	return Plugin_Handled;
}

KillWithoutMayhem(entity)
{
	decl Float:randomvec[3];
	randomvec[0] = GetRandomFloat(-5000.0,5000.0);
	randomvec[1] = GetRandomFloat(-5000.0,5000.0);
	randomvec[2] = -5000.0;
	
	TeleportEntity(entity, randomvec, NULL_VECTOR, NULL_VECTOR); 
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
		
	AcceptEntityInput(entity, "Kill");
}