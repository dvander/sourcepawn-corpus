#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
//v1.0.0 on Apr 1, 2014
#define PLUGIN_NAME		"[TF2] Train Rain"
#define PLUGIN_AUTHOR		"FlaminSarge"
#define PLUGIN_VERSION		"1.0.1" //as of Apr 2, 2014
#define PLUGIN_CONTACT		"http://forums.alliedmods.net/showthread.php?t=237931"
#define PLUGIN_DESCRIPTION	"...It's raining trains."

public Plugin:myinfo = {
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_DESCRIPTION,
	version			= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};

#define TRAIN_HIT "trainsawlaser/extra/sound1.wav"
#define TRAIN_HIT_FULL "sound/trainsawlaser/extra/sound1.wav"
#define TRAIN_RAIN "trainsawlaser/extra/sound2.wav"
#define TRAIN_RAIN_FULL "sound/trainsawlaser/extra/sound2.wav"

#define CAP_POINT	(1 << 0)
#define CAP_FLAG	(1 << 1)

new Handle:hCurrTimer = INVALID_HANDLE;
static Float:HEIGHT[3] = { 0.0, 0.0, 1950.0 };
static Float:HEIGHT2[3] = { 0.0, 0.0, 1953.0 };
new Handle:hEntStack;
new Handle:hCvarTimer;
new Handle:hCvarCap;
new bool:bSounds;
public OnPluginStart()
{
	CreateConVar("train_rain_version", PLUGIN_VERSION, "[TF2] Train Rain version", FCVAR_NOTIFY|FCVAR_PLUGIN);
	hCvarTimer = CreateConVar("train_rain_timer", "1", "Automatically rain down trains at random times", FCVAR_PLUGIN);
	HookConVarChange(hCvarTimer, cvhookTimer);
	hCvarCap = CreateConVar("train_rain_cap", "3", "Automatically rain down trains when: 1=point capped, 2=flag capped, 3=both", FCVAR_PLUGIN);
	//CreateConVar("train_rain_enable", "1", "[TF2] Train Rain enabled", FCVAR_PLUGIN);
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("teamplay_point_captured", Event_PointCaptured, EventHookMode_Post);
	HookEvent("teamplay_flag_event", Event_FlagCaptured, EventHookMode_Post);
	//HookEntityOutput("path_track", "OnPass", OnPassTrack);
	HookEntityOutput("func_tracktrain", "OnUser3", OnTrainReset);
	RegAdminCmd("sm_trainrain", Cmd_TrainRain, ADMFLAG_ROOT);
	HookEntityOutput("trigger_hurt", "OnHurtPlayer", OnTrainHurt);
}
public OnMapStart()
{
	if (IsTSL(true)) return;
	PrecacheModel("models/props_vehicles/train_enginecar.mdl");
	PrecacheModel("models/player/demo.mdl");
	//CreateTrainTrack(true);
	hEntStack = CreateStack();
	if (!FileExists(TRAIN_RAIN_FULL, true) || !FileExists(TRAIN_HIT_FULL, true))
	{
		bSounds = false;
	}
	else
	{
		bSounds = true;
		PrecacheSound(TRAIN_HIT, true);
		PrecacheSound(TRAIN_RAIN, true);
		AddFileToDownloadsTable(TRAIN_HIT_FULL);
		AddFileToDownloadsTable(TRAIN_RAIN_FULL);
	}
	hCurrTimer = INVALID_HANDLE;
}
public OnMapEnd()
{
	CloseHandle(hEntStack);
	hEntStack = INVALID_HANDLE;
}
public cvhookTimer(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new bool:oldv = !!StringToInt(oldVal);
	new bool:newv = !!StringToInt(newVal);
	if (newv && !oldv) Event_RoundStart(INVALID_HANDLE, "", false);
	if (oldv && !newv)
	{
		if (hCurrTimer != INVALID_HANDLE)
		{
			CloseHandle(hCurrTimer);
			hCurrTimer = INVALID_HANDLE;
		}
	}
}
public Action:Cmd_TrainRain(client, args)
{
	if (IsTSL()) return Plugin_Handled;
	if (hCurrTimer != INVALID_HANDLE)
	{
		CloseHandle(hCurrTimer);
	}
	Timer_TrainRain(hCurrTimer);
	return Plugin_Handled;
}
public Action:Event_PointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(hCvarCap) & CAP_POINT)
		Cmd_TrainRain(0, 0);
}
public Action:Event_FlagCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "eventtype") != TF_FLAGEVENT_CAPTURED) return;
	if (GetConVarInt(hCvarCap) & CAP_FLAG)
		Cmd_TrainRain(0, 0);
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsTSL()) return;
	if (hCurrTimer != INVALID_HANDLE)
	{
		CloseHandle(hCurrTimer);
		hCurrTimer = INVALID_HANDLE;
	}
	RemakeTrainTimer();
}
public Action:Timer_TrainRain(Handle:timer)
{
	KillAllThings();
	SpawnTrainsAboveEverything();
	RemakeTrainTimer();
	return Plugin_Stop;
}
stock RemakeTrainTimer()
{
	new Float:time = Train_Rain_Time();
	if (time > 0)
		hCurrTimer = CreateTimer(time, Timer_TrainRain, _, TIMER_FLAG_NO_MAPCHANGE);
}
stock Float:Train_Rain_Time()
{
	if (!GetConVarBool(hCvarTimer)) return -1.0;
	return 144.0 - Pow(GetRandomFloat(5.0, 11.0), 2.0);
}
stock SpawnTrainsAboveEverything()
{
	decl Float:pos[3];
	decl String:name[32];
	new alive = 0;
	if (GetClientCount(true) < 1) return;
	new trainref = CreateTrainTrack();
	new train = EntRefToEntIndex(trainref);
	if (!IsValidEntity(train)) return;
	SetVariantString("TrainRainPath1");
	AcceptEntityInput(train, "TeleportToPathTrack");
	AcceptEntityInput(train, "StartForward");
	new Float:hurtmin[3] = { -10.0, -80.0, -305.65 };
	new Float:hurtmax[3] = { 210.7, 80.0, -195.65 };
	new Float:clipmin[3] = { 0.0, -70.0, -205.65 };
	new Float:clipmax[3] = { 206.7, 70.0, 305.65 };
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (!IsPlayerAlive(client)) continue;
		alive++;
		GetClientAbsOrigin(client, pos);
		//pos[2] += 1000.0;
		pos[0] -= 103.4;

		new ent = CreateEntityByName("prop_dynamic");
		DispatchKeyValue(ent, "parentname", "TrainRain");
		SetVariantString("TrainRain");
		AcceptEntityInput(ent, "SetParent");
		FormatEx(name, sizeof(name), "TrainRainProp%d", client);
		DispatchKeyValue(ent, "targetname", name);
		DispatchKeyValue(ent, "solid", "0");
		DispatchKeyValue(ent, "angles", "90 0 0");
		SetEntityModel(ent, "models/props_vehicles/train_enginecar.mdl");
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, Float:{ 90.0, 0.0, 0.0 }, NULL_VECTOR);
		ActivateEntity(ent);
		PushStackCell(hEntStack, EntIndexToEntRef(ent));

		new clip = CreateEntityByName("func_brush");
		DispatchKeyValue(clip, "parentname", "TrainRain");
		SetVariantString("TrainRain");
		AcceptEntityInput(clip, "SetParent");
		FormatEx(name, sizeof(name), "TrainRainClip%d", client);
		DispatchKeyValue(clip, "targetname", name);
		DispatchSpawn(clip);
		ActivateEntity(clip);
		PushStackCell(hEntStack, EntIndexToEntRef(clip));
		TeleportEntity(clip, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(clip, "models/player/demo.mdl");
		SetEntPropVector(clip, Prop_Send, "m_vecMins", clipmin);
		SetEntPropVector(clip, Prop_Send, "m_vecMaxs", clipmax);
		SetEntProp(clip, Prop_Send, "m_nSolidType", 2);
		new enteffects = GetEntProp(clip, Prop_Send, "m_fEffects");
		enteffects |= 32;
		SetEntProp(clip, Prop_Send, "m_fEffects", enteffects);

		new hurt = CreateEntityByName("trigger_hurt");
		DispatchKeyValue(hurt, "damage", "5000");
		DispatchKeyValue(hurt, "damagetype", "16");
		DispatchKeyValue(hurt, "parentname", "TrainRain");
		SetVariantString("TrainRain");
		AcceptEntityInput(hurt, "SetParent");
		DispatchKeyValue(hurt, "spawnflags", "1097");
		FormatEx(name, sizeof(name), "TrainRainHurt%d", client);
		DispatchKeyValue(hurt, "targetname", name);
		DispatchSpawn(hurt);
		ActivateEntity(hurt);
		PushStackCell(hEntStack, EntIndexToEntRef(hurt));
		TeleportEntity(hurt, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(hurt, "models/player/demo.mdl");
		SetEntPropVector(hurt, Prop_Send, "m_vecMins", hurtmin);
		SetEntPropVector(hurt, Prop_Send, "m_vecMaxs", hurtmax);
		SetEntProp(hurt, Prop_Send, "m_nSolidType", 2);
		enteffects = GetEntProp(hurt, Prop_Send, "m_fEffects");
		enteffects |= 32;
		SetEntProp(hurt, Prop_Send, "m_fEffects", enteffects);
	}
	if (alive > 0 && bSounds && GetRandomInt(0, 3))
	{
		EmitSoundToAll(TRAIN_RAIN, SOUND_FROM_PLAYER);	//doubling these is bad but whatever
		if (!GetRandomInt(0, 2)) EmitSoundToAll(TRAIN_RAIN, SOUND_FROM_PLAYER);
	}
}
public OnTrainHurt(const String:output[], caller, activator, Float:delay)
{
	decl String:name[32];
	if (!bSounds) return;
	GetEntPropString(caller, Prop_Data, "m_iName", name, sizeof(name));
	if (GetRandomInt(0, 5)) return;
	if (StrContains(name, "TrainRainHurt") == -1) return;
	EmitSoundToAll(TRAIN_HIT, activator);	//doubling these is baaaaad but whatever
	EmitSoundToAll(TRAIN_HIT, activator);
}
public OnTrainReset(const String:output[], caller, activator, Float:delay)
{
	decl String:name[32];
	GetEntPropString(caller, Prop_Data, "m_iName", name, sizeof(name));
	if (!StrEqual(name, "TrainRain")) return;
	KillAllThings();
}
stock KillAllThings()	//train)
{
	new ref;
	if (hEntStack == INVALID_HANDLE) return;
	while (!IsStackEmpty(hEntStack))
	{
		PopStackCell(hEntStack, ref);
		new ent = EntRefToEntIndex(ref);
		if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
	}
	return;
	//decl String:name[32];
/*	new i = -1;
	while ((i = FindEntityByClassname(i, "func_brush")))
	{
		if (!IsValidEntity(i)) continue;
		if (train != GetEntPropEnt(i, Prop_Send, "moveparent")) continue;
		AcceptEntityInput(i, "Kill");
	}
	i = -1;
	while ((i = FindEntityByClassname(i, "trigger_hurt")))
	{
		if (!IsValidEntity(i)) continue;
		if (train != GetEntPropEnt(i, Prop_Send, "moveparent")) continue;
		AcceptEntityInput(i, "Kill");
	}
	i = -1;
	while ((i = FindEntityByClassname(i, "prop_dynamic")))
	{
		if (!IsValidEntity(i)) continue;
		if (train != GetEntPropEnt(i, Prop_Send, "moveparent")) continue;
		AcceptEntityInput(i, "Kill");
	}*/
}
stock CreateTrainTrack(bool:forceReset = false, bool:kill = false)
{
	static trainref = INVALID_ENT_REFERENCE;
	static trackrefs[3] = { INVALID_ENT_REFERENCE, ... };
	new train = EntRefToEntIndex(trainref);
	new track1 = EntRefToEntIndex(trackrefs[0]);
	new track2 = EntRefToEntIndex(trackrefs[1]);
	new track4 = EntRefToEntIndex(trackrefs[2]);
	if (forceReset || kill)
	{
		if (IsValidEntity(train)) AcceptEntityInput(train, "KillHierarchy");
		if (IsValidEntity(track1)) AcceptEntityInput(track1, "Kill");
		if (IsValidEntity(track2)) AcceptEntityInput(track2, "Kill");
		if (IsValidEntity(track4)) AcceptEntityInput(track4, "Kill");
		trainref = INVALID_ENT_REFERENCE;
		trackrefs[0] = INVALID_ENT_REFERENCE;
		trackrefs[1] = INVALID_ENT_REFERENCE;
		trackrefs[2] = INVALID_ENT_REFERENCE;
	}
	if (kill) return INVALID_ENT_REFERENCE;
	if (!IsValidEntity(track4))
	{
		track4 = CreateEntityByName("path_track");
		DispatchKeyValue(track4, "target", "TrainRainPath1");
	}
	if (!IsValidEntity(track2))
	{
		track2 = CreateEntityByName("path_track");
		DispatchKeyValue(track2, "targetname", "TrainRainPath2");
	}
	if (!IsValidEntity(track1))
	{
		track1 = CreateEntityByName("path_track");
		DispatchKeyValue(track1, "targetname", "TrainRainPath1");
	}
	DispatchKeyValue(track4, "spawnflags", "16");
	DispatchKeyValue(track4, "speed", "1500");
	DispatchKeyValue(track4, "targetname", "TrainRainPath4");
	TeleportEntity(track4, HEIGHT2, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(track4);
	ActivateEntity(track4);
	trackrefs[2] = EntIndexToEntRef(track4);

	DispatchKeyValue(track2, "speed", "1500");
	DispatchKeyValue(track2, "target", "TrainRainPath4");
	TeleportEntity(track2, Float:{ 0.0, 0.0, -1000.0 }, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("OnPass TrainRain:Stop::0.0:-1");
	AcceptEntityInput(track2, "AddOutput");
	SetVariantString("OnPass TrainRain:FireUser3::0.0:-1");
	AcceptEntityInput(track2, "AddOutput");
	DispatchSpawn(track2);
	ActivateEntity(track2);	//OnPass, trigger TrainRainStop, which does Stop on TrainRain
	trackrefs[1] = EntIndexToEntRef(track2);

	DispatchKeyValue(track1, "spawnflags", "16");
	DispatchKeyValue(track1, "speed", "1500");
	DispatchKeyValue(track1, "target", "TrainRainPath2");
	TeleportEntity(track1, HEIGHT, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(track1);
	ActivateEntity(track1);
	trackrefs[0] = EntIndexToEntRef(track1);
		/*new track3 = CreateEntityByName("path_track");
		DispatchKeyValue(track3, "speed", "1500");
		DispatchKeyValue(track3, "target", "TrainRainPath2");
		DispatchKeyValue(track3, "targetname", "TrainRainPath3");
		TeleportEntity(track3, Float:{ 0.0, 0.0, 1000.0 }, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(track3);
		ActivateEntity(track3);	//used to enable/disable cameras, unneeded*/

	if (!IsValidEntity(train))
	{
		train = CreateEntityByName("func_tracktrain");
		DispatchKeyValue(train, "spawnflags", "528");
		DispatchKeyValue(train, "solid", "0");
		DispatchKeyValue(train, "origin", "0 0 1000");
		DispatchKeyValue(train, "speed", "1100");
		DispatchKeyValue(train, "startspeed", "1100");
		DispatchKeyValue(train, "target", "TrainRainPath1");
		DispatchKeyValue(train, "targetname", "TrainRain");
		TeleportEntity(train, HEIGHT, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(train);
		ActivateEntity(train);
		SetVariantString("TrainRainPath1");
		AcceptEntityInput(train, "TeleportToPathTrack");
		AcceptEntityInput(train, "Stop");
		trainref = EntIndexToEntRef(train);
	}
	return trainref;
}
stock bool:IsTSL(bool:forceRecalc = false)
{
	static bool:tsl = false;
	static bool:found = false;
	decl String:map[32];
	if (forceRecalc)
	{
		found = false;
	}
	if (!found)
	{
		GetCurrentMap(map, sizeof(map));
		tsl = StrContains(map, "trainsawlaser", false) != -1;
		found = true;
	}
	return tsl;
}
public OnPluginEnd()
{
	//KillAllThings();
	CreateTrainTrack(_, true);
}