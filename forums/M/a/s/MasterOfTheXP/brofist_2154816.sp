#pragma semicolon 1
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2.1"
public Plugin:myinfo = {
	name = "BROFIST",
	author = "MasterOfTheXP",
	description = "Turns high fives into BROFISTs!",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

#define BROFIST_EFFECT_SOUND (1 << 0)
#define BROFIST_EFFECT_SHAKE (1 << 1)
#define BROFIST_EFFECT_HUDTEXT (1 << 2)
#define BROFIST_EFFECT_OVERLAY (1 << 3)
#define BROFIST_EFFECT_PARTICLE (1 << 4)
#define BROFIST_EFFECT_EXPLOSION (1 << 5)

new Handle:cvarEffects;
new Handle:cvarRadius;
new Handle:cvarRadiusAim;

new Effects;
new Float:MaxRadius, Float:MaxAimRadius;

new Handle:hudText;

new Handle:ClearOverlayTimer[MAXPLAYERS + 1];
new bool:DoingHighFive[MAXPLAYERS + 1];

public OnPluginStart()
{
	cvarEffects = CreateConVar("sm_brofist", "51", "BROFIST effects! 1=Sound, 2=Shake, 4=HUD Text, 8=Overlay, 16=Particle, 32=Explosion. Add up the numbers to get the value you want. Default: 51 (Sound + Shake + Particle + Explosion)");
	
	cvarRadius = CreateConVar("sm_brofist_radius", "200.0", "How close players must be (in Hammer units) to see most effects.");
	cvarRadiusAim = CreateConVar("sm_brofist_radius_aim", "750.0", "Even if a player is not close enough, they will be considered close enough if they are within this radius and aiming at one of the bros.");
	
	Effects = GetConVarInt(cvarEffects);
	HookConVarChange(cvarEffects, OnConVarChanged);
	
	CreateConVar("sm_brofist_version", PLUGIN_VERSION, "Be a bro, don't touch this <2", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	AddNormalSoundHook(SoundHook);
	
	hudText = CreateHudSynchronizer();
}

public OnMapStart()
{
	PrecacheSound("mstr/brofist.mp3");
	AddFileToDownloadsTable("sound/mstr/brofist.mp3");
	AddFileToDownloadsTable("materials/mstr/brofist_a.vmt");
	AddFileToDownloadsTable("materials/mstr/brofist_a.vtf");
	AddFileToDownloadsTable("materials/mstr/brofist_b.vmt");
	AddFileToDownloadsTable("materials/mstr/brofist_b.vtf");
	PrecacheModel("materials/mstr/brofist_a.vmt");
	PrecacheModel("materials/mstr/brofist_b.vmt");
}

public OnClientDisconnect(client)
	DoingHighFive[client] = false;

public TF2_OnConditionAdded(partner, TFCond:cond)
{
	if (cond != TFCond_Taunting) return;
	new effects = GetConVarInt(cvarEffects);
	if (!effects) return;
	
	new initiator = GetEntPropEnt(partner, Prop_Send, "m_hHighFivePartner");
	if (initiator == -1) return;
	
	if (!DoingHighFive[initiator] && !DoingHighFive[partner]) return;
	
	if (!CheckCommandAccess(initiator, "brofist", 0, true) && !CheckCommandAccess(partner, "brofist", 0, true)) return;
	
	MaxRadius = GetConVarFloat(cvarRadius);
	MaxAimRadius = GetConVarFloat(cvarRadiusAim);
	
	if (effects & BROFIST_EFFECT_SOUND)
	{
		EmitSoundToAll("mstr/brofist.mp3", initiator);
	}
	if (effects & BROFIST_EFFECT_SHAKE)
	{
		ShakeScreen(1.8, initiator);
		ShakeScreen(1.8, initiator);
		ShakeScreen(2.0, initiator);
		ShakeScreen(2.3, initiator);
		ShakeScreen(2.6, initiator);
	}
	if (effects & BROFIST_EFFECT_HUDTEXT)
	{
		DelayedText(initiator, 2.2, "BRO");
		DelayedText(initiator, 2.6, "BROFIST");
	}
	if (effects & BROFIST_EFFECT_OVERLAY)
	{
		DelayedOverlay(initiator, 2.2, "mstr/brofist_a");
		DelayedOverlay(initiator, 2.6, "mstr/brofist_b");
	}
	if (effects & BROFIST_EFFECT_PARTICLE)
	{
		DelayedSprite(initiator, 2.2, "materials/mstr/brofist_a.vmt");
		DelayedSprite(initiator, 2.6, "materials/mstr/brofist_b.vmt");
	}
	if (effects & BROFIST_EFFECT_EXPLOSION)
	{
		CreateTimer(1.8, Timer_MICHAELBAY, GetClientUserId(initiator), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public TF2_OnConditionRemoved(client, TFCond:cond)
{
	if (cond != TFCond_Taunting) return;
	DoingHighFive[client] = false;
}

public Action:SoundHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!(Effects & BROFIST_EFFECT_SOUND)) return Plugin_Continue;
	if (StrContains(sound, "high_five.wav", false) > -1)
	{
		Format(sound, PLATFORM_MAX_PATH, "mstr/brofist.mp3");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!StrEqual(classname, "instanced_scripted_scene", false)) return;
	SDKHook(entity, SDKHook_Spawn, OnSceneSpawned);
}

public Action:OnSceneSpawned(entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwner"), String:scenefile[128];
	GetEntPropString(entity, Prop_Data, "m_iszSceneFile", scenefile, sizeof(scenefile));
	if (StrContains(scenefile, "hi5", false) > -1)
		DoingHighFive[client] = true;
}

public OnConVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	Effects = GetConVarInt(cvarEffects);
}

public Action:Timer_MICHAELBAY(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	
	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", "cinefx_goldrush");
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "Start");
	CreateTimer(0.1, Timer_RemoveEnt, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
}

stock DelayedSprite(client, Float:time, const String:material[])
{
	new Handle:data;
	CreateDataTimer(time, Timer_ShowSprite, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, GetClientUserId(client));
	WritePackString(data, material);
	ResetPack(data);
}

public Action:Timer_ShowSprite(Handle:timer, Handle:data)
{
	new client = GetClientOfUserId(ReadPackCell(data)), partner, String:material[PLATFORM_MAX_PATH];
	ReadPackString(data, material, sizeof(material));
	if (!client) return;
	partner = GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner");
	if (!partner) return;
	new ent = CreateEntityByName("env_sprite");
	DispatchKeyValue(ent, "model", material);
	DispatchKeyValue(ent, "rendermode", "9");
	DispatchKeyValueFloat(ent, "scale", 0.025);
	DispatchSpawn(ent);
	new Float:Pos[3];
	GetClientEyePosition(client, Pos);
	TeleportEntity(ent, Pos, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(ent);
	CreateTimer(1.5, Timer_RemoveEnt, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
}

stock DelayedOverlay(client, Float:time, const String:material[])
{
	new Handle:data;
	CreateDataTimer(time, Timer_ShowOverlay, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, GetClientUserId(client));
	WritePackString(data, material);
	ResetPack(data);
}

public Action:Timer_ShowOverlay(Handle:timer, Handle:data)
{
	new client = GetClientOfUserId(ReadPackCell(data)), partner, String:material[PLATFORM_MAX_PATH];
	ReadPackString(data, material, sizeof(material));
	if (!client) return;
	partner = GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner");
	if (!partner) return;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (i != client && i != partner)
		{
			if (!MaxRadius && !MaxAimRadius) continue;
			if (!IsClientCloseEnoughToBROFIST(i, client, partner)) continue;
		}
		DoOverlay(i, material);
		ClearOverlayTimer[i] = CreateTimer(1.0, Timer_ClearOverlay, GetClientUserId(i));
	}
}

public Action:Timer_ClearOverlay(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	if (ClearOverlayTimer[client] != timer) return;
	DoOverlay(client, "");
}

stock DelayedText(client, Float:time, const String:text[])
{
	new Handle:data;
	CreateDataTimer(time, Timer_ShowText, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, GetClientUserId(client));
	WritePackString(data, text);
	ResetPack(data);
}

public Action:Timer_ShowText(Handle:timer, Handle:data)
{
	new client = GetClientOfUserId(ReadPackCell(data)), partner, String:text[33];
	ReadPackString(data, text, sizeof(text));
	if (!client) return;
	partner = GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner");
	if (!partner) return;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (i != client && i != partner)
		{
			if (!MaxRadius && !MaxAimRadius) continue;
			if (!IsClientCloseEnoughToBROFIST(i, client, partner)) continue;
		}
		SetHudTextParams(-1.0, 0.6, 1.5, 255, 255, 255, 255);
		ShowSyncHudText(i, hudText, text);
	}
}

stock ShakeScreen(Float:time, client) CreateTimer(time, Timer_ShakeScreen, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

public Action:Timer_ShakeScreen(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid), partner;
	if (!client) return;
	partner = GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner");
	if (!partner) return;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (i != client && i != partner)
		{
			if (!MaxRadius && !MaxAimRadius) continue;
			if (!IsClientCloseEnoughToBROFIST(i, client, partner)) continue;
		}
		new flags = GetCommandFlags("shake");
		SetCommandFlags("shake", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "shake");
		SetCommandFlags("shake", flags);
	}
}

public Action:Timer_RemoveEnt(Handle:timer, any:ref)
{
	new Ent = EntRefToEntIndex(ref);
	if (Ent <= MaxClients || Ent > 2048) return;
	if (!IsValidEntity(Ent)) return;
	AcceptEntityInput(Ent, "Kill");
}

stock bool:IsClientCloseEnoughToBROFIST(client, bro_one, bro_two)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	new Float:Pos[3];
	GetClientEyePosition(client, Pos);
	for (new i = 1; i <= 2; i++)
	{
		new bro = i == 1 ? bro_one : bro_two, Float:BroPos[3];
		GetClientEyePosition(bro, BroPos);
		new Float:dist = GetVectorDistance(Pos, BroPos);
		if (dist > MaxRadius)
		{
			if (dist > MaxAimRadius && (!IsPositionInSightRange(client, BroPos, 30.0) || !HasClearSight(client, bro))) continue;
		}
		return true;
	}
	return false;
}

stock DoOverlay(client, String:material[] = "")
{ // Ghost Mode
	if (!IsFakeClient(client))
	{
		new iFlags = GetCommandFlags("r_screenoverlay");
		SetCommandFlags("r_screenoverlay", iFlags & ~FCVAR_CHEAT);
		if (!StrEqual(material, "")) ClientCommand(client, "r_screenoverlay \"%s\"", material);
		else ClientCommand(client, "r_screenoverlay \"\"");
		SetCommandFlags("r_screenoverlay", iFlags);
	}
}

stock bool:IsPositionInSightRange(client, Float:Pos[3], Float:angle=90.0, Float:distance=0.0, bool:heightcheck=true, bool:negativeangle=false)
{ // http://forums.alliedmods.net/showthread.php?t=210080
	if (angle > 360.0 || angle < 0.0) ThrowError("Invalid angle %f", angle);
	if (!IsClientInGame(client)) ThrowError("Client %i is not in-game", client);
	
	new Float:clientpos[3], Float:anglevector[3], Float:targetvector[3], Float:resultangle, Float:resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if (negativeangle)
	NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	if (heightcheck && distance > 0) resultdistance = GetVectorDistance(clientpos, Pos);
	clientpos[2] = Pos[2] = 0.0;
	MakeVectorFromPoints(clientpos, Pos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if (resultangle <= angle/2)
	{
		if (distance > 0)
		{
			if(!heightcheck) resultdistance = GetVectorDistance(clientpos, Pos);
			return distance >= resultdistance;
		}
		else return true;
	}
	else return false;
}
stock HasClearSight(client, target)
{
	new Float:ClientPos[3], Float:TargetPos[3], Float:Result[3];
	GetClientEyePosition(client, ClientPos);
	GetClientAbsOrigin(target, TargetPos);
	TargetPos[2] += 32.0;
	
	MakeVectorFromPoints(ClientPos, TargetPos, Result);
	GetVectorAngles(Result, Result);
	
	TR_TraceRayFilter(ClientPos, Result, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	return target == TR_GetEntityIndex();
}
public bool:TraceRayDontHitSelf(Ent, Mask, any:Hit) return Ent != Hit;