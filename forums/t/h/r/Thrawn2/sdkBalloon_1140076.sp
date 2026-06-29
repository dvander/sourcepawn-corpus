#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"

public Plugin:myinfo =
{
	name = "tBalloon",
	author = "ThrAAAwn, L. Duke",
	description = "Spawns a floating balloon",
	version = PLUGIN_VERSION,
	url = "thrawn.de"
}

#define MDL_BALLOON "models/player/gibs/gibs_balloon.mdl"
#define SND_DROP "weapons/grenade_throw.wav"

new Handle:g_hCvarEnable;
new Handle:g_hCvarDelay;
new Handle:g_hCvarLife;
new Handle:g_hCvarModel;
new Handle:g_hCvarVSpeed;
new Handle:g_hCvarHSpeed;
new Handle:g_hCvarHMult;
new Handle:g_hCvarDamage;
new Handle:g_hCvarRadius;

new bool:g_bEnabled;
new String:g_sModel[256];
new Float:g_fDelay;
new Float:g_fLife;
new Float:g_fVSpeed;
new Float:g_fHSpeed;
new String:g_sRadius[8];
new String:g_sDamage[8];
new Float:g_fHMult;
new Float:g_fNextDrop[MAXPLAYERS+1];

public OnPluginStart()
{
	CreateConVar("sm_tballoon_version", PLUGIN_VERSION, "tBalloon version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hCvarModel =CreateConVar("sm_balloon_mdl", MDL_BALLOON, "Balloon model name");
	g_hCvarDelay = CreateConVar("sm_balloon_delay", "30.0", "How often players can release a balloon (in seconds)");
	g_hCvarLife = CreateConVar("sm_balloon_life", "5.0", "How long before balloon explodes (in seconds)");
	g_hCvarVSpeed = CreateConVar("sm_balloon_vspeed", "80.0", "Vertical speed of balloon");
	g_hCvarHSpeed = CreateConVar("sm_balloon_hspeed", "300.0", "Initial horizontal speed of balloon");
	g_hCvarHMult = CreateConVar("sm_balloon_hspeedmult", "0.98", "Drag multiplier (1.0 to not slow down horizontal speed");
	g_hCvarDamage = CreateConVar("sm_balloon_damage", "100.0", "Damage dealt on explosion");
	g_hCvarRadius = CreateConVar("sm_balloon_radius", "256", "Radius of explosion");

	HookConVarChange(g_hCvarEnable, Cvar_ChangedEnable);
	//HookConVarChange(g_hCvarModel, Cvar_Changed);
	HookConVarChange(g_hCvarDelay, Cvar_Changed);
	HookConVarChange(g_hCvarLife, Cvar_Changed);
	HookConVarChange(g_hCvarVSpeed, Cvar_Changed);
	HookConVarChange(g_hCvarHSpeed, Cvar_Changed);
	HookConVarChange(g_hCvarHMult, Cvar_Changed);
	HookConVarChange(g_hCvarDamage, Cvar_Changed);
	HookConVarChange(g_hCvarRadius, Cvar_Changed);

	RegConsoleCmd("sm_balloon", Command_Balloon);

	AutoExecConfig(true, "plugin.tBalloon");
}

public OnConfigsExecuted() {
	g_fDelay = GetConVarFloat(g_hCvarDelay);
	g_fLife = GetConVarFloat(g_hCvarLife);
	g_fVSpeed = GetConVarFloat(g_hCvarVSpeed);
	g_fHSpeed = GetConVarFloat(g_hCvarHSpeed);
	GetConVarString(g_hCvarRadius, g_sRadius, sizeof(g_sRadius));
	GetConVarString(g_hCvarDamage, g_sDamage, sizeof(g_sDamage));
	g_fHMult = GetConVarFloat(g_hCvarHMult);

	GetConVarString(g_hCvarModel, g_sModel, sizeof(g_sModel));
	PrecacheModel(g_sModel, true);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public Cvar_ChangedEnable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hCvarEnable);

	if(!g_bEnabled)
		ClearBalloons();
}

public OnMapStart()
{
	// precache files
	PrecacheSound(SND_DROP, true);

	// initialize next drop times
	for (new i = 1; i <= MaxClients;i++)
	{
		g_fNextDrop[i] = -1000.0;
	}
}

public Action:Command_Balloon(client, args)
{
	if(g_bEnabled) {
		// check when last jumppad dropped
		new Float:time = GetEngineTime();
		if (time < g_fNextDrop[client])
		{
			PrintCenterText(client, "You must wait %d seconds.", RoundToCeil(g_fNextDrop[client]-time));
			return Plugin_Handled;
		}

		// set next time allowed
		g_fNextDrop[client] = time + g_fDelay;

		// set position, angles, and speed for jumppad prop
		new Float:vspeed = g_fVSpeed;
		new Float:hspeed = g_fHSpeed;
		new Float:startpt[3];
		GetClientEyePosition(client, startpt);
		new Float:angle[3];
		new Float:speed[3];
		new Float:playerspeed[3];
		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, speed, NULL_VECTOR, NULL_VECTOR);
		startpt[0] += 48.0 * Cosine(0.0174532925 * angle[1]);
		startpt[1] += 48.0 * Sine(0.0174532925 * angle[1]);
		speed[0]*=vspeed; speed[1]*=hspeed; speed[2]=hspeed;

		GetEntPropVector(client, Prop_Data, "m_veg_hCvarelocity", playerspeed);
		AddVectors(speed, playerspeed, speed);


		// create the balloon
		new entity = CreateEntityByName("prop_physics_override");
		if (IsValidEntity(entity))
		{
			new String:tmp[256];

			SetEntityModel(entity, g_sModel);

			SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
			SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0);
			SetEntProp(entity, Prop_Data, "m_usSolidFlags", 28);
			SetEntProp(entity, Prop_Data, "m_nSolidType", 6);

			DispatchSpawn(entity);

			TeleportEntity(entity, startpt, NULL_VECTOR, speed);
			SDKHook(entity, SDKHook_VPhysicsUpdate, ThinkHook);

			// setup explosion
			SetEntPropEnt(entity, Prop_Data, "m_hLastAttacker", client);

			// send "kill" event to the event queue
			new String:addoutput[64];
			Format(addoutput, sizeof(addoutput), "OnUser1 !self:break::%f:1", g_fLife);
			SetVariantString(addoutput);
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");

			DispatchKeyValue(entity, "ExplodeRadius", g_sRadius);
			DispatchKeyValue(entity, "ExplodeDamage", g_sDamage);
			Format(tmp, sizeof(tmp), "!self,Break,,0,-1");
			DispatchKeyValue(entity, "OnHealthChanged", tmp);
			Format(tmp, sizeof(tmp), "!self,Kill,,0,-1");
			DispatchKeyValue(entity, "OnBreak", tmp);

			DispatchKeyValue(entity, "targetname", "tballoon");

			// play sound
			EmitSoundToAll(SND_DROP, client);
		}
	} else {
		ReplyToCommand(client, "tBalloon is disabled.");
	}

	return Plugin_Handled;

}

// entity is thinking
public ThinkHook(entity)
{
	// Calculate and apply a new velocity to the player.
	new Float:speed[3];
	new Float:drag = g_fHMult;
	GetEntPropVector(entity, Prop_Data, "m_vecvelocity", speed);
	speed[0]*=drag;
	speed[1]*=drag;
	speed[2] = g_fVSpeed;
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, speed);
}

public ClearBalloons()
{
	new balloon = MaxClients+1;

	while ((balloon = FindEntityByClassname(balloon, "prop_physics_override")) != -1) {
		if (IsValidEntity(balloon)) {
			new String:targetname[32];
			GetEntPropString(balloon, Prop_Data, "m_iName", targetname, sizeof(targetname));

			if (StrEqual(targetname, "tballoon")) {
				AcceptEntityInput(balloon, "Kill");
			}
		}
	}
}
