#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.5"
#define MERASMUS "merasmus"
#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255

new Handle:g_Size = INVALID_HANDLE;
new Handle:g_Glow = INVALID_HANDLE;
new Handle:BaseHP = INVALID_HANDLE;
new Handle:HPPerPlayer = INVALID_HANDLE;

new Float:g_pos[3];
new g_trackEntity = -1;
new g_healthBar = -1;

public Plugin:myinfo = {
	name = "[TF2] Merasmus Spawner",
	author = "Tak (Chaosxk)",
	description = "RUN COWARDS! RUN!!!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) {
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart() {
	CreateConVar("sm_merasmus_version", PLUGIN_VERSION, "Version of this plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Size = CreateConVar("sm_merasmus_resize", "1.0", "Size of Merasmus. Min = 0 Max = 10", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_Glow = CreateConVar("sm_merasmus_glow", "0.0", "Should Merasmus be glowing?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_merasmus", Meras, ADMFLAG_GENERIC, "Spawns Meras!");
	RegAdminCmd("sm_meras", Meras, ADMFLAG_GENERIC, "Spawns Meras!");
	RegAdminCmd("sm_slaymeras", SlayMeras, ADMFLAG_GENERIC, "Slays Meras!");
	
	HookConVarChange(g_Size, cvarChange);
	HookConVarChange(g_Glow, cvarChange);
	
	BaseHP = FindConVar("tf_merasmus_health_base");
	HPPerPlayer = FindConVar("tf_merasmus_health_per_player");
	
	LoadTranslations("common.phrases");
	AutoExecConfig(true, "merasmus");
}

public OnPluginEnd() {
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "merasmus")) != -1) {
		if(IsValidEntity(ent)) {
			new Handle:g_Event = CreateEvent("merasmus_killed", true);
			FireEvent(g_Event);
			AcceptEntityInput(ent, "Kill");
		}
	}
}

public OnMapStart() {
	PrecacheMe();
	FindHealthBar();
}

public cvarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(convar == g_Size) {
		if(GetConVarFloat(g_Size) > 0.0) {
			LogMessage("[SM] Merasmus size is set to %0.0f.", StringToFloat(newValue));
			new ent = -1;
			while((ent = FindEntityByClassname(ent, "merasmus")) != -1) {
				if(!IsValidEntity(ent)) return;
				SetEffects(ent);
			}
		}
		else if(GetConVarFloat(g_Size) <= 0.0) {
			LogMessage("[SM] Value must be greater than 0.");
			SetConVarFloat(g_Size, StringToFloat(oldValue));
		}
	}
	else if(convar == g_Glow) {
		switch(GetConVarInt(g_Glow)) {
			case 0: LogMessage("[SM] Merasmus is no longer glowing!");
			case 1: LogMessage("[SM] Merasmus is now glowing!");
		}
		new ent = -1;
		while((ent = FindEntityByClassname(ent, "merasmus")) != -1) {
			if(!IsValidEntity(ent)) return;
			SetEffects(ent);
		}
	}
	return;
}

public Action:SlayMeras(client, args) {
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "merasmus")) != -1) {
		if(!IsValidEntity(ent)) return Plugin_Handled;
		new Handle:g_Event = CreateEvent("merasmus_killed", true);
		FireEvent(g_Event);
		AcceptEntityInput(ent, "Kill");
	}
	return Plugin_Handled;
}

public Action:Meras(client, args) {
	if(!IsValidClient(client)) {
		ReplyToCommand(client, "[SM] Command is in-game only.");
		return Plugin_Handled;
	}
	if(!SetTeleportEndPoint(client)) {
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	g_pos[2] -= 10.0;
	new String:sHealth[15], HP = -1;
	if(args == 1) {
		GetCmdArgString(sHealth, sizeof(sHealth));
		HP = StringToInt(sHealth);
	}
	
	new iBaseHP = GetConVarInt(BaseHP);
	new iPlayer = GetConVarInt(HPPerPlayer);
	if(args == 0) {
		HP = iBaseHP + (iPlayer*GetClientCount(true));
	}
	if(args > 1) {
		ReplyToCommand(client, "[SM] Format: sm_merasmus <health>");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32) {
		PrintToChat(client, "[SM] Too many entities have been spawned, reload the map.");
		return Plugin_Handled;
	}
	new entity = CreateEntityByName(MERASMUS);
	if(!IsValidEntity(entity)) {
		PrintToChat(client, "[SM] Couldn't spawn Merasmus, for some reason.");
		return Plugin_Handled;
	}
	DispatchSpawn(entity);
	if(HP > -1) {
		SetEntProp(entity, Prop_Data, "m_iHealth", HP * 4);
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", HP * 4);
	}
	TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

SetTeleportEndPoint(client) {
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) {
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else {
		CloseHandle(trace);
		return false;
	}

	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
	return entity > GetMaxClients() || !entity;
}

FindHealthBar() {
	g_healthBar = FindEntityByClassname(-1, HEALTHBAR_CLASS);
	if(g_healthBar == -1) {
		g_healthBar = CreateEntityByName(HEALTHBAR_CLASS);
		if(g_healthBar != -1) {
			DispatchSpawn(g_healthBar);
		}
	}
}

public OnEntityCreated(entity, const String:classname[]) {
	if(StrEqual(classname, HEALTHBAR_CLASS)) {
		g_healthBar = entity;
	}
	else if (g_trackEntity == -1 && StrEqual(classname, MERASMUS)) {
		g_trackEntity = entity;
		SDKHook(entity, SDKHook_SpawnPost, UpdateBossHealth);
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnMerasmusDamaged);
	}
}

public OnEntityDestroyed(entity) {
	if (entity == -1) return;
	else if (entity == g_trackEntity) {
		g_trackEntity = FindEntityByClassname(-1, MERASMUS);
		if (g_trackEntity == entity) {
			g_trackEntity = FindEntityByClassname(entity, MERASMUS);
		}
		if (g_trackEntity > -1) {
			SDKHook(g_trackEntity, SDKHook_OnTakeDamagePost, OnMerasmusDamaged);
		}
		UpdateBossHealth(g_trackEntity);
	}
}

public OnMerasmusDamaged(victim, attacker, inflictor, Float:damage, damagetype) {
	UpdateBossHealth(victim);
	UpdateDeathEvent(victim);
}

public UpdateDeathEvent(entity) {
	if(IsValidEntity(entity)) {
		new maxHP = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new HP = GetEntProp(entity, Prop_Data, "m_iHealth");
		if(HP <= (maxHP * 0.75)) {
			SetEntProp(entity, Prop_Data, "m_iHealth", 0);
			if(HP <= -1) {
				SetEntProp(entity, Prop_Data, "m_takedamage", 0);
			}
		}
	}
}

public UpdateBossHealth(entity) {
	if (g_healthBar == -1) return;
	new percentage;
	if (IsValidEntity(entity)) {
		new maxHP = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new HP = GetEntProp(entity, Prop_Data, "m_iHealth");
		if (HP <= 0) {
			percentage = 0;
		}
		else {
			percentage = RoundToCeil(float(HP) / (maxHP / 4) * HEALTHBAR_MAX);
		}
	}
	else {
		percentage = 0;
	}	
	SetEntProp(g_healthBar, Prop_Send, HEALTHBAR_PROPERTY, percentage);
}

stock SetEffects(entity) {
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", GetConVarFloat(g_Size));
	SetEntProp(entity, Prop_Send, "m_bGlowEnabled", GetConVarFloat(g_Glow));
}

stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

PrecacheMe() {
	PrecacheModel("models/bots/merasmus/merasmus.mdl", true);
	PrecacheModel("models/prop_lakeside_event/bomb_temp.mdl", true);
	PrecacheModel("models/prop_lakeside_event/bomb_temp_hat.mdl", true);
	
	for(new i = 1; i <= 17; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_appears0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_appears%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 11; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_attacks0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_attacks%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 54; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_headbomb0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_headbomb%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 33; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_held_up0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_held_up%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 2; i <= 4; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_island0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 3; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_bcon_skullhat0%d.wav", i);
		PrecacheSound(iString, true);
	}

	for(new i = 1; i <= 2; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_combat_idle0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 12; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_defeated0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_defeated%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 9; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_found0%d.wav", i);
		PrecacheSound(iString, true);
	}

	for(new i = 3; i <= 6; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_grenades0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 1; i <= 26; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_headbomb_hit0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_headbomb_hit%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 19; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_heal10%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_heal1%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 49; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_idles0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_hide_idles%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 16; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_leaving0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_leaving%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	for(new i = 1; i <= 5; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_pain0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 4; i <= 8; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_ranged_attack0%d.wav", i);
		PrecacheSound(iString, true);
	}
	
	for(new i = 2; i <= 13; i++) {
		decl String:iString[PLATFORM_MAX_PATH];
		if(i < 10) Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_staff_magic0%d.wav", i);
		else Format(iString, sizeof(iString), "vo/halloween_merasmus/sf12_staff_magic%d.wav", i);
		if(FileExists(iString)) {
			PrecacheSound(iString, true);
		}
	}
	
	PrecacheSound("vo/halloween_merasmus/sf12_hide_idles_demo01.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire06.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire07.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire23.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magic_backfire29.wav", true);
	PrecacheSound("vo/halloween_merasmus/sf12_magicwords11.wav", true);
	
	PrecacheSound("misc/halloween/merasmus_appear.wav", true);
	PrecacheSound("misc/halloween/merasmus_death.wav", true);
	PrecacheSound("misc/halloween/merasmus_disappear.wav", true);
	PrecacheSound("misc/halloween/merasmus_float.wav", true);
	PrecacheSound("misc/halloween/merasmus_hiding_explode.wav", true);
	PrecacheSound("misc/halloween/merasmus_spell.wav", true);
	PrecacheSound("misc/halloween/merasmus_stun.wav", true);
}