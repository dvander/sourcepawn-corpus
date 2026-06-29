#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

//#define LOOSE_GAME_TYPE_CHECKING

#define PLUGIN_NAME "[TF2] Ninjutsu Barrel"
#define PLUGIN_AUTHOR "1Swat2KillThemAll & RIKUSYO"
#define PLUGIN_DESCRIPTION "Turn into a barrel by channeling the arcane ninjutsu arts of transformation (GNU/GPLv3)"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL ""
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

#define FADE_SCREEN_TYPE_IN  (0x0001 | 0x0010)
#define FADE_SCREEN_TYPE_OUT (0x0002 | 0x0008)

new const stock String:PLAYER_DISGUISE_SOUND[_:TFClassType - 1][5][] = {
	{			// Scout
		"vo/scout_generic01.wav",
		"vo/scout_apexofjump02.wav",
		"vo/scout_award07.wav",
		"vo/scout_award09.wav",
		"vo/scout_cheers04.wav"
	}, {		// Sniper
		"vo/sniper_award02.wav",
		"vo/sniper_award03.wav",
		"vo/sniper_award07.wav",
		"vo/sniper_award11.wav",
		"vo/sniper_award13.wav"
	}, {		// Soldier
		"vo/soldier_cheers01.wav",
		"vo/soldier_goodjob02.wav",
		"vo/soldier_KaBoomAlts02.wav",
		"vo/soldier_positivevocalization01.wav",
		"vo/soldier_yes01.wav"
	}, {		// Demo Man
		"vo/demoman_laughshort01.wav",
		"vo/demoman_laughshort02.wav",
		"vo/demoman_laughevil02.wav",
		"vo/demoman_laughshort03.wav",
		"vo/demoman_laughevil05.wav"
	}, {		// Medic
		"vo/medic_cheers01.wav",
		"vo/medic_cheers05.wav",
		"vo/medic_specialcompleted11.wav",
		"vo/medic_positivevocalization01.wav",
		"vo/medic_positivevocalization02.wav"
	}, {		// Heavy
		"vo/heavy_yell2.wav",
		"vo/heavy_specialweapon05.wav",
		"vo/heavy_specialcompleted05.wav",
		"vo/heavy_laughterbig04.wav",
		"vo/heavy_yell1.wav"
	}, {		// Pyro
		"vo/pyro_positivevocalization01.wav",
		"vo/pyro_specialcompleted01.wav",
		"vo/pyro_standonthepoint01.wav",
		"vo/pyro_autocappedintelligence01.wav",
		"vo/pyro_autodejectedtie01.wav"
	}, {		// Spy
		"vo/spy_cheers04.wav",
		"vo/spy_positivevocalization01.wav",
		"vo/spy_positivevocalization02.wav",
		"vo/spy_positivevocalization04.wav",
		"vo/spy_laughshort05.wav"
	}, {		// Engineer
		"vo/engineer_engineer_laughevil01.wav",
		"vo/engineer_engineer_laughevil03.wav",
		"vo/engineer_engineer_laughevil05.wav",
		"vo/engineer_laughhappy01.wav",
		"vo/engineer_yes02.wav"
	}
};

new const stock String:PLAYER_DISGUISED_SOUND[_:TFClassType - 1][5][] = {
	{			// Scout
		"vo/scout_beingshotinvincible29.wav",
		"vo/scout_laughevil01.wav",
		"vo/scout_laughevil02.wav",
		"vo/scout_laughevil03.wav",
		"vo/scout_laughhappy01.wav"
	}, {		// Sniper
		"vo/sniper_laughevil01.wav",
		"vo/sniper_laughevil02.wav",
		"vo/sniper_laughevil03.wav",
		"vo/sniper_laughshort04.wav",
		"vo/sniper_laughshort01.wav"
	}, {		// Soldier
		"vo/soldier_laughevil01.wav",
		"vo/soldier_laughevil02.wav",
		"vo/soldier_laughevil03.wav",
		"vo/soldier_laughlong01.wav",
		"vo/soldier_laughshort01.wav"
	}, {		// Demo Man
		"vo/demoman_laughevil01.wav",
		"vo/demoman_laughshort05.wav",
		"vo/demoman_laughevil03.wav",
		"vo/demoman_laughevil04.wav",
		"vo/demoman_laughshort06.wav"
	}, {		// Medic
		"vo/medic_laughevil01.wav",
		"vo/medic_laughevil02.wav",
		"vo/medic_laughevil03.wav",
		"vo/medic_laughevil04.wav",
		"vo/medic_laughevil05.wav"
	}, {		// Heavy
		"vo/heavy_laughevil04.wav",
		"vo/heavy_laughevil02.wav",
		"vo/heavy_laughevil03.wav",
		"vo/heavy_laughevil01.wav",
		"vo/heavy_laughhappy01.wav"
	}, {		// Pyro
		"vo/pyro_laughevil02.wav",
		"vo/pyro_autoonfire02.wav",
		"vo/pyro_laughevil04.wav",
		"vo/pyro_goodjob01.wav",
		"vo/pyro_laughevil03.wav"
	}, {		// Spy
		"vo/spy_laughevil01.wav",
		"vo/spy_laughevil02.wav",
		"vo/spy_laughshort05.wav",
		"vo/spy_laughhappy02.wav",
		"vo/spy_laughshort04.wav"
	}, {		// Engineer
		"vo/engineer_engineer_laughevil02.wav",
		"vo/engineer_engineer_laughevil04.wav",
		"vo/engineer_laughhappy02.wav",
		"vo/engineer_laughshort02.wav",
		"vo/engineer_laughshort03.wav"
	}
};

new const stock String:PLAYER_REVEALED_SOUND[_:TFClassType - 1][5][] = {
	{			// Scout
		"vo/scout_award12.wav",
		"vo/scout_battlecry05.wav",
		"vo/scout_cartgoingbackdefense03.wav",
		"vo/scout_domination02.wav",
		"vo/scout_generic01.wav"
	}, {		// Sniper
		"vo/sniper_award02.wav",
		"vo/sniper_award11.wav",
		"vo/sniper_award12.wav",
		"vo/sniper_battlecry03.wav",
		"vo/sniper_cheers02.wav"
	}, {		// Soldier
		"vo/soldier_battlecry06.wav",
		"vo/soldier_KaBoomAlts01.wav",
		"vo/soldier_PickAxeTaunt04.wav",
		"vo/soldier_robot07.wav",
		"vo/soldier_specialcompleted02.wav"
	}, {		// Demo Man
		"vo/demoman_laughhappy01.wav",
		"vo/demoman_laughhappy02.wav",
		"vo/demoman_laughlong01.wav",
		"vo/demoman_laughlong02.wav",
		"vo/demoman_laughshort04.wav"
	}, {		// Medic
		"vo/medic_cheers06.wav",
		"vo/medic_battlecry01.wav",
		"vo/medic_cheers05.wav",
		"vo/medic_yes02.wav",
		"vo/medic_cheers01.wav"
	}, {		// Heavy
		"vo/heavy_autodejectedtie03.wav",
		"vo/heavy_award01.wav",
		"vo/heavy_award02.wav",
		"vo/heavy_battlecry01.wav",
		"vo/heavy_battlecry03.wav"
	}, {		// Pyro
		"vo/pyro_battlecry01.wav",
		"vo/pyro_battlecry02.wav",
		"vo/pyro_cheers01.wav",
		"vo/pyro_helpme01.wav",
		"vo/pyro_laughevil01.wav"
	}, {		// Spy
		"vo/spy_specialcompleted12.wav",
		"vo/spy_battlecry01.wav",
		"vo/spy_battlecry04.wav",
		"vo/spy_positivevocalization03.wav",
		"vo/spy_specialcompletion06.wav"
	}, {		// Engineer
		"vo/engineer_laughevil06.wav",
		"vo/engineer_gunslingertriplepunchfinal01.wav",
		"vo/engineer_laughlong01.wav",
		"vo/engineer_laughlong02.wav",
		"vo/engineer_laughshort01.wav"
	}
};

new const stock String:FULLY_CHARGED_SOUND[] = "player/recharged.wav";
new const stock String:NO_CHARGE_SOUND[] = "weapons/medigun_no_target.wav";

new const stock String:BARREL_MODEL[] = "models/props_farm/wooden_barrel.mdl";
new const stock String:BARREL_SPAWN_SOUND[] = "items/pumpkin_drop.wav";
new const stock String:BARREL_SPAWN_SMOKE_PARTICLE[] = "Explosion_Smoke_1";
new const stock String:BARREL_SPAWN_FLASH_PARTICLE[] = "Explosion_Flash_1";

new bool:g_LateLoad;

new bool:g_IsDisguised[MAXPLAYERS+1] = { false, ... };
new g_BarrelEntity[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
new g_PrevEntityFlags[MAXPLAYERS+1] = { FL_ONGROUND, ... };
new g_Damage[MAXPLAYERS+1] = { 0, ... };
new Float:g_StunTime[MAXPLAYERS+1] = { 0.0, ... };
new Float:g_LastDisguiseTime[MAXPLAYERS+1] = { 0.0, ... };
new Handle:g_hTimer[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

new Handle:g_hCvEnabled, g_CvEnabled;
new Handle:g_hCvChargeTime, Float:g_CvChargeTime;
new Handle:g_hCvMaxDamage, g_CvMaxDamage;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	g_LateLoad = late;

	return APLRes_Success;
}

public OnPluginStart() {
	decl String:game_dir[32];

	GetGameFolderName(game_dir, sizeof(game_dir));
	if (!StrEqual(game_dir, "tf")) {
		#if defined LOOSE_GAME_TYPE_CHECKING
		LogError("This game is only supposed to run on 'Team Fortress 2'");
		#else
		SetFailState("This game is only supposed to run on 'Team Fortress 2'");
		#endif // #if defined LOOSE_GAME_TYPE_CHECKING
	}

	HookEvent("player_stunned", Event_PlayerStunned, EventHookMode_Pre);
	HookEvent("post_inventory_application", Event_Charge, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	InitVersionCvar("ninjutsu_barrel", PLUGIN_NAME, PLUGIN_VERSION);

	g_CvEnabled = InitCvar(g_hCvEnabled, OnConVarChanged, "sm_ninjutsu_barrel_enabled", "1", "Whether this plugin should be enabled", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_CvChargeTime = InitCvar(g_hCvChargeTime, OnConVarChanged, "sm_ninjutsu_barrel_charge_time", "10.0", "The minimum amount of time in seconds between transformations", FCVAR_DONTRECORD, true, 0.0);
	g_CvMaxDamage = InitCvar(g_hCvMaxDamage, OnConVarChanged, "sm_ninjutsu_barrel_max_damage", "50", "The maximum amount of damage you can take as a barrel before transforming (0 = infinite)", FCVAR_DONTRECORD, true, 0.0);

	RegAdminCmd("sm_ninjutsu", ConCmd_Ninjutsu, 0, "Channel the arcane ninjutsu arts of transformation to turn yourself into a barrel.");

	if (g_LateLoad) {
		OnMapStart();
	}
}

public OnPluginEnd() {
	OnMapEnd();
}

public OnMapStart() {
	PrecacheSound(BARREL_SPAWN_SOUND, true);
	PrecacheModel(BARREL_MODEL, true);

	PrecacheSound(FULLY_CHARGED_SOUND, true);
	PrecacheSound(NO_CHARGE_SOUND, true);
	for (new i = 0, max = _:TFClassType - 1; i < max; i++) {
		for (new j = 0; j < 5; j++) {
			PrecacheSound(PLAYER_DISGUISE_SOUND[i][j], true);
			PrecacheSound(PLAYER_DISGUISED_SOUND[i][j], true);
			PrecacheSound(PLAYER_REVEALED_SOUND[i][j], true);
		}
	}
}

public OnMapEnd() {
	for (new i = 1; i <= MaxClients; i++) {
		OnClientDisconnect(i);
	}
}

public OnClientConnected(client) {
	g_IsDisguised[client] = false;
	g_BarrelEntity[client] = INVALID_ENT_REFERENCE;
	g_PrevEntityFlags[client] = FL_ONGROUND;
	g_LastDisguiseTime[client] = 0.0;

	CloseHandle2(g_hTimer[client]);
}

public OnClientDisconnect(client) {
	CloseHandle2(g_hTimer[client]);
	RemoveDisguise(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	if (!g_IsDisguised[client]) {
		return Plugin_Continue;
	}

	new flags = GetEntityFlags(client),
		old_flags = g_PrevEntityFlags[client];

	g_PrevEntityFlags[client] = flags;

	if (g_LastDisguiseTime[client] + 1.0 >= GetGameTime()) {
		buttons &= ~(IN_ATTACK | IN_ATTACK2 | IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT);
	}

	if (g_StunTime[client] - GetGameTime() > 0) {
		buttons &= ~(IN_ATTACK | IN_ATTACK2);
	}

	if ((flags & (FL_INWATER | FL_DUCKING)) != FL_DUCKING ||
		(!(old_flags & FL_ONGROUND) && (flags & FL_ONGROUND)) ||
		(buttons & (IN_ATTACK | IN_ATTACK2 | IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT)) ||
		TF2_IsPlayerInCondition(client, TFCond_Taunting)
	) {
		RemoveDisguise(client);
		return Plugin_Continue;
	}

	buttons |= IN_DUCK;

	if (g_BarrelEntity[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_BarrelEntity[client])) {
		decl Float:origin[3];

		GetClientAbsOrigin(client, origin);
		origin[2] += 30.0;
		TeleportEntity(g_BarrelEntity[client], origin, NULL_VECTOR, NULL_VECTOR);
	}

	return Plugin_Changed;
}

public Action:ConCmd_Ninjutsu(client, argc) {
	if (g_CvEnabled) {
		Disguise(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Event_PlayerStunned(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsClientValid(client) || !g_IsDisguised[client]) {
		return;
	}

	TF2_RemoveCondition(client, TFCond_Dazed);
	g_StunTime[client] = GetGameTime() + GetEntPropFloat(client, Prop_Send, "m_flMovementStunTime");
}

public Event_Charge(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsClientValid(client) || !g_IsDisguised[client]) {
		return;
	}

	g_LastDisguiseTime[client] = 0.0;
	EmitSoundToClient(client, FULLY_CHARGED_SOUND, client, _, _, _, 1.0);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsClientValid(client) || !g_IsDisguised[client]) {
		return;
	}

	g_Damage[client] += GetEventInt(event, "damageamount");

	if (g_CvMaxDamage > 0 && g_Damage[client] > g_CvMaxDamage) {
		RemoveDisguise(client);
	}
}
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsClientValid(client)) {
		return;
	}

	RemoveDisguise(client);
}

Disguise(client) {
	if (!IsClientValid(client) || !IsPlayerAlive(client)) {
		return;
	}

	if (g_IsDisguised[client]) {
		if (g_LastDisguiseTime[client] + 1.0 < GetGameTime()) {
			RemoveDisguise(client);
		}

		return;
	}

	if ((GetEntityFlags(client) & (FL_DUCKING | FL_ONGROUND | FL_INWATER)) != (FL_DUCKING | FL_ONGROUND) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked)	// Glitchy
	) {
		return;
	}

	new Float:time_left = g_CvChargeTime - (GetGameTime() - g_LastDisguiseTime[client]);
	if (time_left > 0) {
		EmitSoundToClient(client, NO_CHARGE_SOUND, client, _, _, _, 1.0);
		PrintHintText(client, "You need to wait %.f seconds before you can transform again.", time_left);
		return;
	}

	new Float:origin[3] = { 0.0, 0.0, -30.0 },
		Float:angle[3] = { -90.0, 0.0, 0.0 };

	AttachParticle(client, BARREL_SPAWN_FLASH_PARTICLE, 1.0, origin, angle);
	for (new i = 0; i < 10; i++) {
		for (new i = 0; i < 2; i++) {
			origin[i] = GetRandomFloat(-5.0, 5.0);
		}

		AttachParticle(client, BARREL_SPAWN_SMOKE_PARTICLE, 1.0, origin, angle);
	}
	FadeScreen(client, 50, 50, 50, 255, 100, FADE_SCREEN_TYPE_IN);

	new ragdoll = INVALID_ENT_REFERENCE;
	while ((ragdoll = FindEntityByClassname2(ragdoll, "tf_ragdoll")) != -1) {
		if (GetEntProp(ragdoll, Prop_Send, "m_iPlayerIndex") == client) {
			AcceptEntityInput(ragdoll, "Kill");
		}
	}

	HidePlayer(client);

	g_BarrelEntity[client] = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(g_BarrelEntity[client])) {
		SetEntityModel(g_BarrelEntity[client], BARREL_MODEL);

		DispatchSpawn(g_BarrelEntity[client]);

		SetVariantInt(99999);
		AcceptEntityInput(g_BarrelEntity[client], "SetHealth");

		GetClientAbsOrigin(client, origin);
		origin[2] += 30.0;
		TeleportEntity(g_BarrelEntity[client], origin, NULL_VECTOR, NULL_VECTOR);
	}

	EmitSoundToAll(BARREL_SPAWN_SOUND, client, _, _, SND_CHANGEPITCH, 1.0, 55);
	EmitSoundToAll(PLAYER_DISGUISE_SOUND[_:TF2_GetPlayerClass(client)-1][GetRandomInt(0, 4)], client, _, _, _, 1.0);

	SetEntPropEnt(client, Prop_Data, "m_hObserverTarget", client);
	SetEntProp(client, Prop_Data, "m_iObserverMode", 1);

	g_IsDisguised[client] = true;
	g_Damage[client] = 0;
	g_LastDisguiseTime[client] = GetGameTime();

	CloseHandle2(g_hTimer[client]);
	g_hTimer[client] = CreateTimer(3.0 + GetRandomFloat(0.0, 3.0), Timer_Shout, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Shout(Handle:timer, any:data) {
	static sound_index = -1;
	if (++sound_index >= 5) {
		sound_index = 0;
	}

	new client = GetClientOfUserId(data);

	if (!IsClientValid(client) || !IsPlayerAlive(client)) {
		return;
	}

	EmitSoundToAll(PLAYER_DISGUISED_SOUND[_:TF2_GetPlayerClass(client)-1][sound_index], client, _, _, _, 1.0);

	g_hTimer[client] = CreateTimer(3.0 + GetRandomFloat(0.0, 3.0), Timer_Shout, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

RemoveDisguise(client) {
	if (!g_IsDisguised[client]) {
		return;
	}

	KillBarrel(client);

	if (IsClientValid(client)) {
		g_LastDisguiseTime[client] = GetGameTime();

		if (IsPlayerAlive(client)) {
			SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
			HidePlayer(client, false);

			if (!TF2_IsPlayerInCondition(client, TFCond_Taunting)) {
				EmitSoundToAll(PLAYER_REVEALED_SOUND[_:TF2_GetPlayerClass(client)-1][GetRandomInt(0, 4)], client, _, _, _, 1.0);
			}

			new Float:duration = g_StunTime[client] - GetGameTime();
			if (duration > 0) {
				new Handle:data = CreateDataPack();
				WritePackCell(data, GetClientUserId(client));
				WritePackFloat(data, duration);
				CreateTimer(0.05, Timer_StunPlayer, data, TIMER_FLAG_NO_MAPCHANGE | TIMER_HNDL_CLOSE);
			}
		}

		g_hTimer[client] = CreateTimer(g_CvChargeTime, Timer_FullyCharged, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	g_IsDisguised[client] = false;
}

public Action:Timer_StunPlayer(Handle:timer, any:data) {
	ResetPack(data);
	new client = GetClientOfUserId(ReadPackCell(data));

	if (!IsClientValid(client)) {
		return;
	}

	TF2_StunPlayer(client, ReadPackFloat(data), 0.0, TF_STUNFLAGS_GHOSTSCARE | TF_STUNFLAG_NOSOUNDOREFFECT);
}

public Action:Timer_FullyCharged(Handle:timer, any:data) {
	new client = GetClientOfUserId(data);

	g_hTimer[client] = INVALID_HANDLE;

	if (!IsClientValid(client)) {
		return;
	}

	EmitSoundToClient(client, FULLY_CHARGED_SOUND, client, _, _, _, 1.0);
}

stock HidePlayer(any:client, bool:hide = true) {
	new RenderMode:mode = RENDER_TRANSCOLOR;
	new color = 0;

	if (!hide) {
		mode = RENDER_NORMAL;
		color = 255;
	}

	SetEntityRenderMode(client, mode);
	SetEntityRenderColor(client, _, _, _, color);

	for (new i = 0; i < 5; i++) {
		new weapon = GetPlayerWeaponSlot(client, i);

		if (weapon != INVALID_ENT_REFERENCE) {
			SetEntityRenderMode(weapon, mode);
			SetEntityRenderColor(weapon, _, _, _, color);
		}
	}

	new hat = INVALID_ENT_REFERENCE;
	while ((hat = FindEntityByClassname2(hat, "tf_wearable")) != INVALID_ENT_REFERENCE) {
		if (GetEntPropEnt(hat, Prop_Send, "m_hOwnerEntity") == client) {
			SetEntityRenderMode(hat, mode);
			SetEntityRenderColor(hat, _, _, _, color);
		}
	}
}

BreakBarrel(client) {
	if (!IsClientValid(client) || !IsPlayerAlive(client)) {
		return;
	}

	new entity = CreateEntityByName("prop_physics_override");

	if (IsValidEdict(entity)) {
		SetEntityModel(entity, BARREL_MODEL);
		DispatchSpawn(entity);

		decl Float:origin[3],
			Float:angle[3];

		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
		origin[2] += 30.0;

		GetClientEyeAngles(client, angle);
		AddVectors(angle, Float:{ 0.0, 40.0, 0.0 }, angle);

		TeleportEntity(entity, origin, angle, NULL_VECTOR);

		AcceptEntityInput(entity, "Break");
		AcceptEntityInput(entity, "Kill");
	}
}

KillBarrel(client) {
	if (g_BarrelEntity[client] == INVALID_ENT_REFERENCE || !IsValidEntity(g_BarrelEntity[client])) {
		return;
	}

	BreakBarrel(client);
	AcceptEntityInput(g_BarrelEntity[client], "Kill");
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (cvar == g_hCvEnabled) {
		if (!(g_CvEnabled = bool:StringToInt(newVal))) {
			for (new i = 1; i <= MaxClients; i++) {
				RemoveDisguise(i);
			}
		}
	}
	else if (cvar == g_hCvChargeTime) {
		g_CvChargeTime = StringToFloat(newVal);
	}
	else if (cvar == g_hCvMaxDamage) {
		g_CvMaxDamage = StringToInt(newVal);
	}
}

stock GetEntityAbsVelocity(entity, Float:vec[3]) {
	for (new i = 0; i < 3; i++) {
		decl String:prop[32];

		Format(prop, sizeof(prop), "m_vecVelocity[%i]", i);
		vec[i] = GetEntPropFloat(entity, Prop_Send, prop);
	}
}

stock any:AttachParticle(entity, const String:particle_type[], Float:time, Float:add_origin[3] = NULL_VECTOR, Float:add_angle[3] = NULL_VECTOR) {
	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle)) {
		decl Float:origin[3],
			Float:angle[3],
			String:target_name[32];

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		AddVectors(origin, add_origin, origin);

		GetEntPropVector(entity, Prop_Send, "m_angRotation", angle);
		AddVectors(angle, add_angle, angle);

		TeleportEntity(particle, origin, angle, NULL_VECTOR);

		GetEntPropString(entity, Prop_Data, "m_iName", target_name, sizeof(target_name));

		DispatchKeyValue(particle, "target_name", "tf2particle");
		DispatchKeyValue(particle, "parent_name", target_name);
		DispatchKeyValue(particle, "effect_name", particle_type);

		DispatchSpawn(particle);

		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", entity, particle, 0);

		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		CreateTimer(time, Timer_RemoveParticle, particle);
	}
	else {
		LogError("AttachParticle: could not create info_particle_system");
	}

	return particle;
}

public Action:Timer_RemoveParticle(Handle:timer, any:particle) {
	if (IsValidEntity(particle)) {
		decl String:class_name[32];
		GetEdictClassname(particle, class_name, sizeof(class_name));

		if (StrEqual(class_name, "info_particle_system", false)) {
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "Kill");
			particle = INVALID_ENT_REFERENCE;
		}
	}
}

stock FadeScreen(client, red, green, blue, alpha, duration, type) {
	new Handle:msg = StartMessageOne("Fade", client);

	BfWriteShort(msg, 255);
	BfWriteShort(msg, duration);
	BfWriteShort(msg, type);
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

stock FindEntityByClassname2(start_entity, const String:class_name[]) {
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (start_entity > -1 && !IsValidEntity(start_entity)) {
		start_entity--;
	}
	return FindEntityByClassname(start_entity, class_name);
}

/**
 * \brief Returns whether the client is valid.
 *
 * If the client is out of range, this function assumes the input was a client serial.
 *
 * \return									Whether the client is valid
 */
stock IsClientValid(
	&client,								///<! [in, out] The client's index
	bool:in_game = true,					///<! [in] Whether the client has to be ingame
	bool:in_kick_queue = false				///<! [in] Whether the client can be in the kick queue
) {
	if (client <= 0 || client > MaxClients) {
		client = GetClientFromSerial(client);
	}

	return client > 0 && client <= MaxClients && IsClientConnected(client) && (!in_game || IsClientInGame(client)) && (in_kick_queue || !IsClientInKickQueue(client));
}

/**
 * \brief Creates a plugin version console variable.
 *
 * \return									Whether creating the console variable was successful
 * \error									Convar name is blank or is the same as an existing console command
 */
stock InitVersionCvar(
	const String:cvar_name[],				///<! [in] The console variable's name (sm_<name>_version)
	const String:plugin_name[],				///<! [in] The plugin's name
	const String:plugin_version[],			///<! [in] The plugin's version
	additional_flags = 0					///<! [in] additional FCVAR_* flags  (default: FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD)
) {
	if (StrEqual(cvar_name, "") || StrEqual(plugin_name, "")) {
		return false;
	}

	new cvar_name_len = strlen(cvar_name) + 12,
		descr_len = strlen(cvar_name) + 20;
	decl String:name[cvar_name_len],
		String:descr[descr_len];

	Format(name, cvar_name_len, "sm_%s_version", cvar_name);
	Format(descr, descr_len, "\"%s\" - version number", plugin_name);

	new Handle:cvar = FindConVar(name),
		flags = FCVAR_NOTIFY | FCVAR_DONTRECORD | additional_flags;

	if (cvar != INVALID_HANDLE) {
		SetConVarString(cvar, plugin_version);
		SetConVarFlags(cvar, flags);
	}
	else {
		cvar = CreateConVar(name, plugin_version, descr, flags);
	}

	if (cvar != INVALID_HANDLE) {
		CloseHandle(cvar);
		return true;
	}

	LogError("Couldn't create version console variable \"%s\".", name);
	return false;
}

/**
 * \brief Creates a new console variable and hooks it to the specified OnConVarChanged: callback.
 *
 * This function attempts to deduce from the default value what type of data (int, float)
 * is supposed to be stored in the console variable, and returns its value accordingly.
 * (Its type can also be manually specified.) Alternatively one could opt to let the
 * ConVarChanged: callback do the initialisation. This is however prone to error;
 * should CreateConVar() fail, the callback is never fired.
 *
 * \return									Context sensitive; check detailed description
 * \error									Callback is invalid, or convar name is blank or is the same as an existing console command
 */
stock any:InitCvar(
	&Handle:cvar,							///<! [out] A handle to the newly created convar. If the convar already exists, a handle to it will still be returned.
	ConVarChanged:callback,					///<! [in] Callback function called when the convar's value is modified.
	const String:name[],					///<! [in] Name of new convar
	const String:defaultValue[],			///<! [in] String containing the default value of new convar
	const String:description[] = "",		///<! [in] Optional description of the convar
	flags = 0,								///<! [in] Optional bitstring of flags determining how the convar should be handled. See FCVAR_* constants for more details
	bool:hasMin = false,					///<! [in] Optional boolean that determines if the convar has a minimum value
	Float:min = 0.0,						///<! [in] Minimum floating point value that the convar can have if hasMin is true
	bool:hasMax = false,					///<! [in] Optional boolean that determines if the convar has a maximum value
	Float:max = 0.0,						///<! [in] Maximum floating point value that the convar can have if hasMax is true
	type = -1								///<! [in] Return / initialisation type
) {
	cvar = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	if (cvar != INVALID_HANDLE) {
		HookConVarChange(cvar, callback);
	}
	else {
		LogMessage("Couldn't create console variable \"%s\", using default value \"%s\".", name, defaultValue);
	}

	if (type < 0 || type > 3) {
		type = 1;
		new len = strlen(defaultValue);
		for (new i = 0; i < len; i++) {
			if (defaultValue[i] == '.') {
				type = 2;
			}
			else if (IsCharNumeric(defaultValue[i])) {
				continue;
			}
			else {
				type = 0;
				break;
			}
		}
	}

	if (type == 1) {
		return cvar != INVALID_HANDLE ? GetConVarInt(cvar) : StringToInt(defaultValue);
	}
	else if (type == 2) {
		return cvar != INVALID_HANDLE ? GetConVarFloat(cvar) : StringToFloat(defaultValue);
	}
	else if (cvar != INVALID_HANDLE && type == 3) {
		Call_StartFunction(INVALID_HANDLE, callback);
		Call_PushCell(cvar);
		Call_PushString("");
		Call_PushString(defaultValue);
		Call_Finish();

		return true;
	}

	return 0;
}

stock CloseHandle2(&Handle:hndl) {
	if (hndl != INVALID_HANDLE) {
		CloseHandle(hndl);
		hndl = INVALID_HANDLE;
	}
}
