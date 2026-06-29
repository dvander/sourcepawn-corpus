#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define EXPLODE_PLUGIN_VERSION "0.1"
#define SOUND_BOOM "ambient/explosions/explode_8.wav"

public Plugin:myinfo = 
{
	name = "Explode",
	author = "chundo",
	description = "Explode a player",
	version = "0.1",
	url = "http://www.mefightclub.com/"
};

new g_fire;
new g_HaloSprite;
new g_ExplosionSprite;
new Handle:g_cvarExplodeMode = INVALID_HANDLE;
new Handle:g_cvarExplodeRadius = INVALID_HANDLE;

public OnPluginStart() {
	LoadTranslations("explode.phrases");
	CreateConVar("sm_explode_version", EXPLODE_PLUGIN_VERSION, "Explode version.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_cvarExplodeMode = CreateConVar("sm_explode_mode", "0", "Sets who explosions will hurt. 0 = target only, 1 = team only, 2 = everyone", FCVAR_PLUGIN);
	g_cvarExplodeRadius = CreateConVar("sm_explode_radius", "600", "Sets who explosions will hurt. 0 = target only, 1 = team only, 2 = everyone", FCVAR_PLUGIN);
	RegAdminCmd("sm_explode", Command_Explode, ADMFLAG_SLAY, "Explode a player");
	AutoExecConfig(false);
}

public OnMapStart() {
	g_fire = PrecacheModel("materials/sprites/fire2.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound(SOUND_BOOM, true);
}

public Action:Command_Explode(client, args) {
	if (args < 1) {   
		ReplyToCommand(client, "[SM] Usage: sm_explode <#userid|name>");
		return Plugin_Handled;
	}   

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0) {   
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}   

	for (new i = 0; i < target_count; i++) {
		PerformExplode(client, target_list[i]);
	}

	ShowActivity2(client, "[SM] ", "%t %s", "Exploded", target_name);

	return Plugin_Handled;
}

public PerformExplode(client, target) {
	new mode = GetConVarInt(g_cvarExplodeMode);
	new radius = GetConVarInt(g_cvarExplodeRadius);

	LogAction(client, target, "\"%L\" slayed \"%L\"", client, target);
	decl Float:location[3];
	GetClientAbsOrigin(target, location);

	new color[4]={188,220,255,200};
	EmitAmbientSound(SOUND_BOOM, location, client, SNDLEVEL_RAIDSIREN);
	TE_SetupExplosion(location, g_ExplosionSprite, 10.0, 1, 0, radius, 5000);
	TE_SendToAll();
	TE_SetupBeamRingPoint(location, 10.0, float(radius), g_fire, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
  	TE_SendToAll();

	location[2] += 10;
	EmitAmbientSound(SOUND_BOOM, location, client, SNDLEVEL_RAIDSIREN);
	TE_SetupExplosion(location, g_ExplosionSprite, 10.0, 1, 0, radius, 5000);
	TE_SendToAll();

	ForcePlayerSuicide(target);

	if (mode > 0)
		HurtOtherPlayers(target, radius, (mode == 1));
}

public HurtOtherPlayers(target, radius, bool:teamonly) {
	new maxClients = GetMaxClients();
	new Float:vec[3];
	GetClientAbsOrigin(target, vec);
	for (new i = 1; i < maxClients; ++i) {
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || target == i
				|| (teamonly && GetClientTeam(i) != GetClientTeam(target)))
			continue;
		
		new Float:pos[3];
		GetClientEyePosition(i, pos);
		new Float:distance = GetVectorDistance(vec, pos);
		if (distance > radius)
			continue;

		new damage = 220;
		damage = RoundToFloor(damage * (radius - distance) / radius);
		SlapPlayer(i, damage, false);
		TE_SetupExplosion(pos, g_ExplosionSprite, 0.05, 1, 0, 1, 1);
		TE_SendToAll();
	}
}
