#include <tf2_stocks>
//#include <tf2attributes>
#define PLUGIN_VERSION  "1.0"

public Plugin:myinfo = {
	name = "Frog Chance",
	author = "MasterOfTheXP",
	description = "http://www.youtube.com/watch?v=GjpGX8eMOkY",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

#define DMG_CLUB (1 << 7)
#define DMG_CRIT (1 << 20)

public OnPluginStart()
{
	HookEvent("player_death", Event_Death);
	
	CreateConVar("sm_frogchance_version", PLUGIN_VERSION, "Please don't touch this, the frogs will not be happy if you do", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
}

public OnMapStart()
{
	PrecacheModel("models/props_2fort/frog.mdl", true);
	PrecacheModel("models/props_junk/wood_crate001a.mdl", true);
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Only count crit-melee kills
	new damagetype = GetEventInt(event, "damagebits");
	if (!(damagetype & DMG_CRIT) || !(damagetype & DMG_CLUB)) return Plugin_Continue;
	
	// Make sure their melee weapon exists and is active
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!killer) return Plugin_Continue;
	new weapon = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(weapon)) return Plugin_Continue;
	if (GetPlayerWeaponSlot(killer, 2) != weapon) return Plugin_Continue;
	
	// If the server has enabled Frog Chance for donators/admins only, check access
	if (!CheckCommandAccess(killer, "frogchance", 0))
		return Plugin_Continue;
	
	// Was the crit forced?
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (4.0 > GetEntPropFloat(killer, Prop_Send, "m_flChargeMeter") || // Demo charge. TFCond_Charging is removed before the kill is made.
	TF2_IsPlayerInCondition(killer, TFCond_Kritzkrieged) ||
	TF2_IsPlayerInCondition(killer, TFCond_Buffed) ||
	TF2_IsPlayerInCondition(killer, TFCond_HalloweenCritCandy) ||
	TF2_IsPlayerInCondition(killer, TFCond_CritCanteen) ||
	TF2_IsPlayerInCondition(killer, TFCond_CritHype) ||
	TF2_IsPlayerInCondition(killer, TFCond_CritOnFirstBlood) ||
	TF2_IsPlayerInCondition(killer, TFCond_CritOnWin) ||
	TF2_IsPlayerInCondition(killer, TFCond_CritOnFlagCapture) ||
	TF2_IsPlayerInCondition(killer, TFCond_CritOnKill) ||
	TF2_IsPlayerInCondition(victim, TFCond_Jarated) ||
	TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeath) ||
	TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeathSilent))
//	Address_Null != TF2Attrib_GetByName(weapon, "crit mod disabled")
//	Address_Null != TF2Attrib_GetByName(weapon, "crit mod disabled HIDDEN") ||
//	Address_Null != TF2Attrib_GetByName(weapon, "no crit vs nonburning"))
		return Plugin_Continue;
	new String:cls[16];
	GetEdictClassname(weapon, cls, sizeof(cls));
	if (!strncmp(cls, "tf_weapon_knife", 15))
		return Plugin_Continue;
	switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 38, 142, 416, 457, 813, 834, 1000: return Plugin_Continue; // Melee weapons with no random crits that can still crit on their own
	}
	
	// Remove ragdoll during the next frame
	CreateTimer(0.0, Timer_RemoveRagdoll, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
	
	// Get client position and rotation
	new Float:Pos[3], Float:Ang[3];
	GetClientEyePosition(victim, Pos);
	GetClientAbsAngles(victim, Ang);
	
	TE_Start("breakmodel");
	TE_WriteNum("m_nModelIndex", PrecacheModel("models/props_2fort/frog.mdl"));
	TE_WriteFloat("m_fTime", 10.0);
	TE_WriteVector("m_vecOrigin", Pos);
	TE_WriteFloat("m_angRotation[0]", Ang[0]);
	TE_WriteFloat("m_angRotation[1]", Ang[1]);
	TE_WriteFloat("m_angRotation[2]", Ang[2]);
	TE_WriteVector("m_vecSize", Float:{1.0, 1.0, 1.0});
	TE_WriteNum("m_nCount", 1);
	TE_SendToAll();
	
	// Balloons!
	new Particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(Particle, "effect_name", "bday_confetti");
	TeleportEntity(Particle, Pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(Particle);
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "Start");
	CreateTimer(0.5, Timer_RemoveEnt, EntIndexToEntRef(Particle), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll <= MaxClients) return;
	AcceptEntityInput(ragdoll, "Kill");
}

public Action:Timer_RemoveEnt(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (ent <= MaxClients) return;
	AcceptEntityInput(ent, "Kill");
}

// This model code works, and is much more accurate to the video, but it's pretty easy to hit the box instead of hitting another player, missing with the Boston Basher, etc.
/*	// Spawn frog
	new Mdl = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(Mdl, "model", "models/props_2fort/frog.mdl");
	Pos[2] -= 20.0;
	TeleportEntity(Mdl, Pos, Ang, NULL_VECTOR);
	DispatchSpawn(Mdl);
	ActivateEntity(Mdl);
	AcceptEntityInput(Mdl, "TurnOn");
	CreateTimer(10.0, Timer_RemoveEnt, EntIndexToEntRef(Mdl), TIMER_FLAG_NO_MAPCHANGE);
	
	// Frog model doesn't have proper physics, so spawn an invisible crate as a prop_physics_multiplayer to parent the frog to
	new Parent = CreateEntityByName("prop_physics_multiplayer");
	DispatchKeyValue(Parent, "model", "models/props_junk/wood_crate001a.mdl");
	DispatchKeyValue(Parent, "physicsmode", "2");
	Pos[2] += 20.0;
	TeleportEntity(Parent, Pos, Ang, NULL_VECTOR);
	DispatchSpawn(Parent);
	ActivateEntity(Parent);
	AcceptEntityInput(Parent, "TurnOn");
	SetEntProp(Parent, Prop_Data, "m_iHealth", 99999);
	SetEntityRenderMode(Parent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(Parent, 0, 0, 0, 0);
	CreateTimer(10.0, Timer_RemoveEnt, EntIndexToEntRef(Parent), TIMER_FLAG_NO_MAPCHANGE);
	
	// Parent the frog to the crate
	SetVariantString("!activator");
	AcceptEntityInput(Mdl, "SetParent", Parent);*/