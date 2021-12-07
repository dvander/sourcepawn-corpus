#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <psyrtd>

#undef REQUIRE_EXTENSIONS
#undef AUTOLOAD_EXTENSIONS
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS

#define SOUND_BLIP		"buttons/blip1.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_BEEP		"buttons/button17.wav"
#define SOUND_FINAL		"weapons/cguard/charging.wav"
#define SOUND_BOOM		"weapons/explode3.wav"

#define GRAVITY_NORMAL 1.0

#define atof(%1) StringToFloat(%1)
#define PRECACHESOUND(%1);\
if (!IsSoundPrecached(%1))\
{\
	PrecacheSound(%1, true);\
}

#define BLACK   {200,200,200,192}
#define GREY	{128,128,128,255}
#define RED		{255, 75, 75,255}
#define BLUE	{ 75, 75,255,255}
#define GREEN	{ 75,255, 75,255}
#define INVIS   {255,255,255,  0}
#define NORMAL  {255,255,255,255}
#define FROZEN  {  0,128,255,135}
#define FREEZE  {  0,128,255,192}

enum Speed
{
	Speed_Normal,
	Speed_Slow,
	Speed_Fast
};

new g_iMaxEnts;
new g_offsetMyWeapons;
new g_offsetWearable;
new g_offsetShield;

new Handle:g_EffectTimers[MAXPLAYERS+1] = INVALID_HANDLE;

// god mode
new Handle:g_cvGodModeEnable;
new Handle:g_cvGodModeDuration;
new g_eidGodMode = -1;

// toxic
new Handle:g_cvToxicEnable;
new Handle:g_cvToxicDuration;
new Handle:g_cvToxicRadius;
new g_eidToxic = -1;

// explode
new Handle:g_cvExplodeEnable;

// speed mods
new Handle:g_cvSnailEnable;
new Handle:g_cvSnailDuration;
new Handle:g_cvSnailSpeed;
new g_eidSnail = -1;
new Handle:g_cvCheetahEnable;
new Handle:g_cvCheetahDuration;
new Handle:g_cvCheetahSpeed;
new g_eidCheetah = -1;
new Speed:g_PlayerSpeed[MAXPLAYERS+1] = Speed_Normal;
new Float:g_fLastSpeed[MAXPLAYERS+1];

// health gain
new Handle:g_cvHealthBuffEnable;
new Handle:g_cvHealthBuffAmt;

// invisibility
new Handle:g_cvInvisEnable;
new Handle:g_cvInvisDuration;
new g_eidInvis = -1;

// freeze
new Handle:g_cvFreezeEnable;
new Handle:g_cvFreezeDuration;
new g_eidFreeze = -1;
new g_GlowSprite;

// timebomb
new Handle:g_cvTimebombEnable;
new g_TimeBombTime[MAXPLAYERS+1];
new g_BeamSprite;
new g_ExplosionSprite;
new g_HaloSprite;

// noclip
new Handle:g_cvNoclipEnable;
new Handle:g_cvNoclipDuration;
new g_eidNoclip = -1;

// ignite
new Handle:g_cvIgniteEnable;

// lowgravity
new Handle:g_cvLowGravEnable;
new Handle:g_cvLowGravDuration;
new Handle:g_cvLowGravAmt;
new g_eidLowGrav = -1;

// health loss
new Handle:g_cvHealthNerfEnable;
new Handle:g_cvHealthNerfAmt;

// drugged
new Handle:g_cvDrugsEnable;
new Handle:g_cvDrugsDuration;
new g_eidDrugs;
new const Float:g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

// blind
new Handle:g_cvBlindEnable;
new Handle:g_cvBlindDuration;
new g_eidBlind;
new UserMsg:g_FadeUserMsgId;

// weaponstrip

// beacon
new Handle:g_cvBeaconEnable;
new Handle:g_cvBeaconDuration;
new g_eidBeacon;

// mirror damage

new psyRTDGame:g_Game = psyRTDGame_Unknown;

public Plugin:myinfo = 
{
	name = "psyRTD Generic Effects",
	author = "psychonic",
	description = "Generic effects module for psyRTD",
	version = "1.1.1",
	url = "http://www.nicholashastings.com"
};

public OnPluginStart()
{
	g_cvGodModeEnable = CreateConVar("psyrtd_godmode_enable", "1", "Enable rolling God Mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvGodModeDuration = CreateConVar("psyrtd_godmode_duration", "10", "Duration of God Mode effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvGodModeDuration, OnGodModeDurationChanged);
	
	g_cvToxicEnable = CreateConVar("psyrtd_toxic_enable", "1", "Enable rolling Toxic", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvToxicDuration = CreateConVar("psyrtd_toxic_duration", "10", "Duration of Toxic effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvToxicDuration, OnToxicDurationChanged);
	g_cvToxicRadius = CreateConVar("psyrtd_toxic_radius", "275", "Radius of Toxic effect", FCVAR_PLUGIN, true, 0.0);
	
	g_cvCheetahEnable = CreateConVar("psyrtd_cheetah_enable", "1", "Enable rolling Cheetah", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvCheetahDuration = CreateConVar("psyrtd_cheetah_duration", "13", "Duration of Cheetah effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvCheetahDuration, OnCheetahDurationChanged);
	g_cvCheetahSpeed = CreateConVar("psyrtd_cheetah_speed", "400", "Player speed of Cheetah effect", FCVAR_PLUGIN, true, 0.0);
	
	g_cvHealthBuffEnable = CreateConVar("psyrtd_healthbuff_enable", "1", "Enable rolling Health Buff", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvHealthBuffAmt = CreateConVar("psyrtd_healthbuff_amount", "500", "Amount of health to add for Health Buff effect", FCVAR_PLUGIN, true, 1.0);
	
	g_cvNoclipEnable = CreateConVar("psyrtd_noclip_enable", "1", "Enable rolling Noclip", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvNoclipDuration = CreateConVar("psyrtd_noclip_duration", "10", "Duration of Noclip effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvNoclipDuration, OnNoclipDurationChanged);
	
	g_cvLowGravEnable = CreateConVar("psyrtd_lowgrav_enable", "1", "Enable rolling Low Gravity", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvLowGravDuration = CreateConVar("psyrtd_lowgrav_duration", "10", "Duration of Low Gravity effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvLowGravDuration, OnLowGravDurationChanged);
	g_cvLowGravAmt = CreateConVar("psyrtd_lowgrav_amount", "50", "% of current sv_gravity for Low Gravity effect", FCVAR_PLUGIN, true, 0.0);
	
	g_cvInvisEnable = CreateConVar("psyrtd_invisibility_enable", "1", "Enable rolling Invisibility", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvInvisDuration = CreateConVar("psyrtd_invisibility_duration", "10", "Duration of Invisibility effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvInvisDuration, OnInvisDurationChanged);
	
	g_cvExplodeEnable = CreateConVar("psyrtd_explode_enable", "1", "Enable rolling Explode", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_cvSnailEnable = CreateConVar("psyrtd_snail_enable", "1", "Enable rolling Snail", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvSnailDuration = CreateConVar("psyrtd_snail_duration", "12", "Duration of Snail effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvSnailDuration, OnSnailDurationChanged);
	g_cvSnailSpeed = CreateConVar("psyrtd_snail_speed", "50", "Player speed of Snail effect", FCVAR_PLUGIN, true, 0.0);
	
	g_cvFreezeEnable = CreateConVar("psyrtd_freeze_enable", "1", "Enable rolling Freeze", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvFreezeDuration = CreateConVar("psyrtd_freeze_duration", "8", "Duration of Freeze effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvFreezeDuration, OnFreezeDurationChanged);
	
	g_cvTimebombEnable = CreateConVar("psyrtd_timebomb_enable", "1", "Enable rolling Timebomb", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_cvIgniteEnable = CreateConVar("psyrtd_ignite_enable", "1", "Enable rolling Ignite", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_cvHealthNerfEnable = CreateConVar("psyrtd_healthnerf_enable", "1", "Enable rolling Health Nerf", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvHealthNerfAmt = CreateConVar("psyrtd_healthnerf_amount", "50", "% of health to lose for Health Nerf effect", FCVAR_PLUGIN, true, 1.0, true, 100.0);
	
	g_cvDrugsEnable = CreateConVar("psyrtd_drugs_enable", "1", "Enable rolling Drugs", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvDrugsDuration = CreateConVar("psyrtd_drugs_duration", "12", "Duration of Drugs effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvDrugsDuration, OnDrugsDurationChanged);
	
	g_cvBlindEnable = CreateConVar("psyrtd_blind_enable", "1", "Enable rolling Blind", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvBlindDuration = CreateConVar("psyrtd_blind_duration", "12", "Duration of Blind effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvBlindDuration, OnBlindDurationChanged);
	g_FadeUserMsgId = GetUserMessageId("Fade");
	
	g_cvBeaconEnable = CreateConVar("psyrtd_beacon_enable", "1", "Enable rolling Beacon", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvBeaconDuration = CreateConVar("psyrtd_beacon_duration", "12", "Duration of Beacon effect", FCVAR_PLUGIN, true, 1.0);
	HookConVarChange(g_cvBeaconDuration, OnBeaconDurationChanged);
	
	AutoExecConfig(true, "psyrtd_generic");
}

public OnAllPluginsLoaded()
{

	if (!LibraryExists("psyrtd"))
	{
		SetFailState("psyRTD Not Found!");
	}
	
	g_eidGodMode = psyRTD_RegisterTimedEffect(psyRTDEffectType_Good, "God Mode", GetConVarFloat(g_cvGodModeDuration), DoGodMode, EndGodMode);
	g_eidToxic = psyRTD_RegisterTimedEffect(psyRTDEffectType_Good, "Toxic", GetConVarFloat(g_cvToxicDuration), DoToxic, EndToxic);
	psyRTD_RegisterEffect(psyRTDEffectType_Good, "Health Buff", DoHealthBuff);
	g_eidCheetah = psyRTD_RegisterTimedEffect(psyRTDEffectType_Good, "Cheetah", GetConVarFloat(g_cvCheetahDuration), DoCheetah, EndCheetah);
	g_eidNoclip = psyRTD_RegisterTimedEffect(psyRTDEffectType_Good, "Noclip", GetConVarFloat(g_cvNoclipDuration), DoNoclip, EndNoclip);
	g_eidLowGrav = psyRTD_RegisterTimedEffect(psyRTDEffectType_Good, "Low Gravity", GetConVarFloat(g_cvLowGravDuration), DoLowGrav, EndLowGrav);
	g_eidInvis = psyRTD_RegisterTimedEffect(psyRTDEffectType_Good, "Invisibility", GetConVarFloat(g_cvInvisDuration), DoInvis, EndInvis);
	psyRTD_RegisterEffect(psyRTDEffectType_Bad, "Explode", DoExplode);
	g_eidSnail = psyRTD_RegisterTimedEffect(psyRTDEffectType_Bad, "Snail", GetConVarFloat(g_cvSnailDuration), DoSnail, EndSnail);
	g_eidFreeze = psyRTD_RegisterTimedEffect(psyRTDEffectType_Bad, "Freeze", GetConVarFloat(g_cvFreezeDuration), DoFreeze, EndFreeze);
	psyRTD_RegisterEffect(psyRTDEffectType_Bad, "Timebomb", DoTimebomb);
	psyRTD_RegisterEffect(psyRTDEffectType_Bad, "Ignite", DoIgnite);
	psyRTD_RegisterEffect(psyRTDEffectType_Bad, "Health Nerf", DoHealthNerf);
	g_eidDrugs = psyRTD_RegisterTimedEffect(psyRTDEffectType_Bad, "Drugs", GetConVarFloat(g_cvDrugsDuration), DoDrugs, EndDrugs);
	g_eidBlind = psyRTD_RegisterTimedEffect(psyRTDEffectType_Bad, "Blind", GetConVarFloat(g_cvBlindDuration), DoBlind, EndBlind);
	g_eidBeacon = psyRTD_RegisterTimedEffect(psyRTDEffectType_Bad, "Beacon", GetConVarFloat(g_cvBeaconDuration), DoBeacon, EndBeacon);
	g_Game = psyRTD_GetGame();

	g_offsetMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	if (g_Game == psyRTDGame_TF)
	{
		g_offsetWearable = FindSendPropInfo("CTFWearableItem", "m_hOwnerEntity");
		g_offsetShield = FindSendPropInfo("CTFWearableItemDemoShield", "m_hOwnerEntity");
	}
}

public OnPluginUnload()
{
	psyRTD_UnregisterAllEffects();
}

public OnMapStart()
{
	g_iMaxEnts = GetMaxEntities();
	PRECACHESOUND(SOUND_BLIP);
	PRECACHESOUND(SOUND_FREEZE);
	PRECACHESOUND(SOUND_BEEP);
	PRECACHESOUND(SOUND_FINAL);
	PRECACHESOUND(SOUND_BOOM);
	g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}

public psyRTDAction:DoGodMode(client)
{
	if (!GetConVarBool(g_cvGodModeEnable))
	{
		return psyRTD_Reroll;
	}
	
	SetEntProp(client, Prop_Data, "m_takedamage", 0);
	return psyRTD_Continue;
}

public EndGodMode(client, psyRTDEffectEndReason:reason)
{
	if (!IsClientInGame(client))
	{
		return;
	}
	
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
}

public psyRTDAction:DoToxic(client)
{
	if (!GetConVarBool(g_cvToxicEnable))
	{
		return psyRTD_Reroll;
	}
	
	Colorize(client, BLACK);
	
	g_EffectTimers[client] = CreateTimer(0.5, Timer_Toxic, GetClientUserId(client), TIMER_REPEAT);
	
	return psyRTD_Continue;
}

public EndToxic(client, psyRTDEffectEndReason:reason)
{
	if (reason != psyRTDEndReason_PlayerLeft)
	{
		Colorize(client, NORMAL);
	}
	
	if (g_EffectTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_EffectTimers[client]);
	}
	g_EffectTimers[client] = INVALID_HANDLE;
}

public psyRTDAction:DoHealthBuff(client)
{
	if (!GetConVarBool(g_cvHealthBuffEnable))
	{
		return psyRTD_Reroll;
	}
	
	SetEntProp(client, Prop_Data, "m_iHealth", (GetEntProp(client, Prop_Data, "m_iHealth")+GetConVarInt(g_cvHealthBuffAmt)));
	
	if (g_Game == psyRTDGame_TF)
	{
		CreateParticle("healhuff_red", 5.0, client);
		CreateParticle("healhuff_blu", 5.0, client);
	}
	
	return psyRTD_Continue;
}

public psyRTDAction:DoCheetah(client)
{
	if (!GetConVarBool(g_cvCheetahEnable))
	{
		return psyRTD_Reroll;
	}
	
	if (g_Game == psyRTDGame_TF)
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		if (class == TFClass_Heavy || class == TFClass_Sniper)
		{
			return psyRTD_NotApplicable;
		}
	}
	
	g_PlayerSpeed[client] = Speed_Fast;
	g_fLastSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(g_cvSnailSpeed));
	
	return psyRTD_Continue;
}

public EndCheetah(client, psyRTDEffectEndReason:reason)
{
	g_PlayerSpeed[client] = Speed_Normal;
	if (reason == psyRTDEndReason_TimeExpired)
	{
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_fLastSpeed[client]);
	}
}

public psyRTDAction:DoNoclip(client)
{
	if (!GetConVarBool(g_cvNoclipEnable))
	{
		return psyRTD_Reroll;
	}
	
	SetEntityMoveType(client, MOVETYPE_NOCLIP);
	
	return psyRTD_Continue;
}

public EndNoclip(client, psyRTDEffectEndReason:reason)
{
	if (!IsClientInGame(client))
	{
		return;
	}
	
	SetEntityMoveType(client, MOVETYPE_WALK);
}

public psyRTDAction:DoLowGrav(client)
{
	if (!GetConVarBool(g_cvLowGravEnable))
	{
		return psyRTD_Reroll;
	}
	
	SetEntityGravity(client, (GetConVarFloat(g_cvLowGravAmt)/100.0));
	
	return psyRTD_Continue;
}

public EndLowGrav(client, psyRTDEffectEndReason:reason)
{
	if (!IsClientInGame(client))
	{
		return;
	}
	
	SetEntityGravity(client, GRAVITY_NORMAL);
}

public psyRTDAction:DoInvis(client)
{
	if (!GetConVarBool(g_cvInvisEnable))
	{
		return psyRTD_Reroll;
	}
	
	Colorize(client, INVIS);
	
	return psyRTD_Continue;
}

public EndInvis(client, psyRTDEffectEndReason:reason)
{
	if (!IsClientInGame(client))
	{
		return;
	}
	
	Colorize(client, NORMAL);
}

public psyRTDAction:DoExplode(client)
{
	if (!GetConVarBool(g_cvExplodeEnable))
	{
		return psyRTD_Reroll;
	}
	
	FakeClientCommand(client, "explode");
	return psyRTD_Continue;
}

public psyRTDAction:DoSnail(client)
{
	if (!GetConVarBool(g_cvSnailEnable))
	{
		return psyRTD_Reroll;
	}
	
	if (g_Game == psyRTDGame_TF)
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		if (class == TFClass_Heavy || class == TFClass_Sniper)
		{
			return psyRTD_NotApplicable;
		}
	}
	
	g_PlayerSpeed[client] = Speed_Slow;
	g_fLastSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(g_cvSnailSpeed));
	
	return psyRTD_Continue;
}

public EndSnail(client, psyRTDEffectEndReason:reason)
{
	g_PlayerSpeed[client] = Speed_Normal;
	if (reason == psyRTDEndReason_TimeExpired)
	{
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_fLastSpeed[client]);
	}
}

public psyRTDAction:DoFreeze(client)
{
	if (!GetConVarBool(g_cvFreezeEnable))
	{
		return psyRTD_Reroll;
	}
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	Colorize(client, FREEZE);

	decl Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
	
	g_EffectTimers[client] = CreateTimer(0.5, Timer_Freeze, GetClientUserId(client), TIMER_REPEAT);
	
	return psyRTD_Continue;
}

public EndFreeze(client, psyRTDEffectEndReason:reason)
{
	if (reason != psyRTDEndReason_PlayerLeft)
	{
		decl Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;	
		
		GetClientEyePosition(client, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
		
		SetEntityMoveType(client, MOVETYPE_WALK);
		
		Colorize(client, NORMAL);
	}
	
	if (g_EffectTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_EffectTimers[client]);
	}
	g_EffectTimers[client] = INVALID_HANDLE;
}

public psyRTDAction:DoTimebomb(client)
{
	if (!GetConVarBool(g_cvTimebombEnable))
	{
		return psyRTD_Reroll;
	}
	
	g_TimeBombTime[client] = 10;
	CreateTimer(1.0, Timer_Timebomb, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return psyRTD_Continue;
}

public psyRTDAction:DoIgnite(client)
{
	if (!GetConVarBool(g_cvIgniteEnable))
	{
		return psyRTD_Reroll;
	}
	
	if (g_Game == psyRTDGame_TF)
	{
		TF2_IgnitePlayer(client, client);
	}
	else
	{
		IgniteEntity(client, 10.0);
	}
	
	return psyRTD_Continue;
}

public psyRTDAction:DoHealthNerf(client)
{
	if (!GetConVarBool(g_cvHealthNerfEnable))
	{
		return psyRTD_Reroll;
	}
	
	SlapPlayer(client, GetEntProp(client, Prop_Data, "m_iHealth") * (GetConVarInt(g_cvHealthNerfAmt)/100));
	
	return psyRTD_Continue;
}

public psyRTDAction:DoDrugs(client)
{
	if (!GetConVarBool(g_cvDrugsEnable))
	{
		return psyRTD_Reroll;
	}
	
	new userid = GetClientUserId(client);
	Timer_Drugs(INVALID_HANDLE, userid);
	g_EffectTimers[client] = CreateTimer(1.0, Timer_Drugs, userid, TIMER_REPEAT);
	
	return psyRTD_Continue;
}

public EndDrugs(client, psyRTDEffectEndReason:reason)
{
	if (reason != psyRTDEndReason_PlayerLeft)
	{
		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		decl Float:angs[3];
		GetClientEyeAngles(client, angs);
		
		angs[2] = 0.0;
		
		TeleportEntity(client, pos, angs, NULL_VECTOR);	
		
		new clients[2];
		clients[0] = client;	
		
		new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
		BfWriteShort(message, 1536);
		BfWriteShort(message, 1536);
		BfWriteShort(message, (0x0001 | 0x0010));
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		EndMessage();	
	}
	
	if (g_EffectTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_EffectTimers[client]);
	}
	g_EffectTimers[client] = INVALID_HANDLE;
}

public psyRTDAction:DoBlind(client)
{
	if (g_FadeUserMsgId == INVALID_MESSAGE_ID || !GetConVarBool(g_cvBlindEnable))
	{
		return psyRTD_Reroll;
	}
	
	new targets[2];
	targets[0] = client;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0002 | 0x0008));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 254);
	EndMessage();
	
	return psyRTD_Continue;
}

public EndBlind(client, psyRTDEffectEndReason:reason)
{
	if (reason == psyRTDEndReason_PlayerLeft)
	{
		return;
	}
	
	new targets[2];
	targets[0] = client;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();
}

public psyRTDAction:DoBeacon(client)
{
	if (!GetConVarBool(g_cvBeaconEnable))
	{
		return psyRTD_Reroll;
	}
	
	new userid = GetClientUserId(client);
	Timer_Drugs(INVALID_HANDLE, userid);
	g_EffectTimers[client] = CreateTimer(1.0, Timer_Beacon, userid, TIMER_REPEAT);
	
	return psyRTD_Continue;
}

public EndBeacon(client, psyRTDEffectEndReason:reason)
{
	if (reason != psyRTDEndReason_PlayerLeft)
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	
	if (g_EffectTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_EffectTimers[client]);
	}
	g_EffectTimers[client] = INVALID_HANDLE;
}

public Action:Timer_Toxic(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		g_EffectTimers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	decl Float:vec[3];
	GetClientEyePosition(client, vec);
	
	new team = GetClientTeam(client);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		
		// should probably be a cvar override for this in case of DM
		if (GetClientTeam(i) == team)
		{
			continue;
		}
		
		// Godmode/uber exception
		if (GetEntProp(i, Prop_Data, "m_takedamage") == 0
			|| (g_Game == psyRTDGame_TF && (TF2_GetPlayerConditionFlags(client) & TF_CONDFLAG_UBERCHARGED) == TF_CONDFLAG_UBERCHARGED)
		)
		{
			continue;
		}
		
		decl Float:pos[3];
		GetClientEyePosition(i, pos);
		
		new Float:distance = GetVectorDistance(vec, pos);
		
		if (distance < GetConVarFloat(g_cvToxicRadius))
		{
			KillPlayerWithExplosion(i, client);
			psyRTD_PrintToChat(i, "You were killed by %N's toxicity.", client);
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_Freeze(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		g_EffectTimers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	Colorize(client, FROZEN);
	
	decl Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	
	TE_SetupGlowSprite(vec, g_GlowSprite, 0.95, 1.5, 50);
	TE_SendToAll();
	
	return Plugin_Continue;
}

public Action:Timer_Timebomb(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		Colorize(client, NORMAL);
		return Plugin_Stop;
	}
	
	g_TimeBombTime[client]--;
	
	decl Float:vec[3];
	GetClientEyePosition(client, vec);
	
	if (g_TimeBombTime[client] > 0)
	{
		new color;
		
		if (g_TimeBombTime[client] > 1)
		{
			color = RoundToFloor(g_TimeBombTime[client] * (12.8));
			EmitAmbientSound(SOUND_BEEP, vec, client, SNDLEVEL_RAIDSIREN);	
		}
		else
		{
			color = 0;
			EmitAmbientSound(SOUND_FINAL, vec, client, SNDLEVEL_RAIDSIREN);
		}
		
		new colorarr[4] = {255,128,0,255};
		colorarr[2] = color;
		Colorize(client, colorarr);
		
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;

		TE_SetupBeamRingPoint(vec, 10.0, 200.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, {128, 128, 128, 255}, 10, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vec, 10.0, 200.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, {255, 255, 255, 255}, 10, 0);
		TE_SendToAll();
		return Plugin_Continue;
	}
	else
	{
		TE_SetupExplosion(vec, g_ExplosionSprite, 5.0, 1, 0, 600, 5000);
		TE_SendToAll();

		EmitAmbientSound(SOUND_BOOM, vec, client, SNDLEVEL_RAIDSIREN);

		ForcePlayerSuicide(client);
		Colorize(client, NORMAL);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || i == client)
			{
				continue;
			}
			
			decl Float:pos[3];
			GetClientEyePosition(i, pos);
			
			new Float:distance = GetVectorDistance(vec, pos);
			
			if (distance > 600)
			{
				continue;
			}
			
			new damage = RoundToFloor(220 * ((600 - distance) / 600));
				
			SlapPlayer(i, damage, false);
			TE_SetupExplosion(pos, g_ExplosionSprite, 0.05, 1, 0, 1, 1);
			TE_SendToAll();
		}
		return Plugin_Stop;
	}
}

public Action:Timer_Drugs(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		g_EffectTimers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	decl Float:angs[3];
	GetClientEyeAngles(client, angs);
	
	angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);
	
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 255);
	BfWriteShort(message, 255);
	BfWriteShort(message, (0x0002));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, GetRandomInt(0,255));
	BfWriteByte(message, 128);
	
	EndMessage();
	
	return Plugin_Continue;
}

public Action:Timer_Beacon(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		g_EffectTimers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new team = GetClientTeam(client);
	if (g_Game == psyRTDGame_INSMOD)
	{
		team -= 1;
	}

	decl Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, GREY, 10, 0);
	TE_SendToAll();
	
	if (team == 2)
	{
		TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, RED, 10, 0);
	}
	else if (team == 3)
	{
		TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, BLUE, 10, 0);
	}
	else
	{
		TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, GREEN, 10, 0);
	}
	
	TE_SendToAll();
		
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);
	
	return Plugin_Continue;
}

public OnGameFrame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		switch (g_PlayerSpeed[i])
		{
			case Speed_Slow:
			{
				SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", GetConVarFloat(g_cvSnailSpeed));
				continue;
			}
			case Speed_Fast:
			{
				SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", GetConVarFloat(g_cvCheetahSpeed));
				continue;
			}
		}
	}
}

// From pheadxdll's tf2 rtd
Colorize(client, color[4])
{
	// Colorize player and weapons
	for (new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, g_offsetMyWeapons + i);
	
		if (IsValidEdict(weapon))
		{
			decl String:strClassname[128];
			GetEdictClassname(weapon, strClassname, sizeof(strClassname));
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
		}
	}
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	if (g_Game != psyRTDGame_TF)
	{
		return;
	}
	
	// Colorize any wearable items
	for (new i = MaxClients + 1; i <= g_iMaxEnts; i++)
	{
		if (!IsValidEntity(i))
		{
			continue;
		}
		
		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		
		if (strcmp(netclass, "CTFWearableItem") == 0)
		{
			if (GetEntDataEnt2(i, g_offsetWearable) == client)
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		}
		else if (strcmp(netclass, "CTFWearableItemDemoShield") == 0)
		{
			if (GetEntDataEnt2(i, g_offsetShield) == client)
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
		if (IsValidEntity(iWeapon))
		{
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iWeapon, color[0], color[1], color[2], color[3]);
		}
	}
	
	return;
}

KillPlayerWithExplosion(client, attacker)
{
	new ent = CreateEntityByName("env_explosion");
	
	if (!IsValidEntity(ent))
	{
		return;
	}
	
	DispatchKeyValue(ent, "iMagnitude", "1000");
	DispatchKeyValue(ent, "iRadiusOverride", "2");
	SetEntPropEnt(ent, Prop_Data, "m_hInflictor", attacker);
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", attacker);
	DispatchKeyValue(ent, "spawnflags", "3964");
	DispatchSpawn(ent);
	
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(ent, "explode", client, client);
	CreateTimer(0.2, RemoveExplosion, ent);
}

public Action:RemoveExplosion(Handle:timer, any:ent)
{
	if (!IsValidEntity(ent))
	{
		return;
	}
	
	decl String:edictname[128];
	GetEdictClassname(ent, edictname, sizeof(edictname));
	if (StrEqual(edictname, "env_explosion"))
	{
		RemoveEdict(ent);
	}
}

public OnGodModeDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidGodMode, psyRTDEffectType_Good, atof(newValue));
}

public OnToxicDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidToxic, psyRTDEffectType_Good, atof(newValue));
}

public OnCheetahDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidCheetah, psyRTDEffectType_Good, atof(newValue));
}

public OnNoclipDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidNoclip, psyRTDEffectType_Good, atof(newValue));
}

public OnLowGravDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidLowGrav, psyRTDEffectType_Good, atof(newValue));
}

public OnInvisDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidInvis, psyRTDEffectType_Good, atof(newValue));
}

public OnSnailDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidSnail, psyRTDEffectType_Bad, atof(newValue));
}

public OnFreezeDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidFreeze, psyRTDEffectType_Bad, atof(newValue));
}

public OnDrugsDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidDrugs, psyRTDEffectType_Bad, atof(newValue));
}

public OnBlindDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidBlind, psyRTDEffectType_Bad, atof(newValue));
}

public OnBeaconDurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	psyRTD_ChangeEffectDuration(g_eidBeacon, psyRTDEffectType_Bad, atof(newValue));
}

stock CreateParticle(const String:strType[], Float:flTime, iEntity)
{
	new iParticle = CreateEntityByName("info_particle_system");
	
	if (!IsValidEdict(iParticle))
	{
		return;
	}
	
	decl Float:flPos[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
	TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(iParticle, "effect_name", strType);
	
	SetVariantString("!activator");
	AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);
	
	SetVariantString("head");
	AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);
	
	DispatchKeyValue(iParticle, "targetname", "particle");
	
	DispatchSpawn(iParticle);
	ActivateEntity(iParticle);
	AcceptEntityInput(iParticle, "Start");
	
	CreateTimer(flTime, Timer_DeleteParticle, iParticle);
}

public Action:Timer_DeleteParticle(Handle:timer, any:iParticle)
{
	if (!IsValidEdict(iParticle))
	{
		return Plugin_Stop;
	}
	
	decl String:strClassname[50];
	GetEdictClassname(iParticle, strClassname, sizeof(strClassname));
		
	if (strcmp(strClassname, "info_particle_system", false) == 0)
	{
		RemoveEdict(iParticle);
	}
	
	return Plugin_Stop;
}