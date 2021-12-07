#define PLUGIN_VERSION		"2.0.0"

#include <sdktools>
#include <sdktools_sound>
#include <sourcemod>

#define ZOMBIECLASS_HUNTER 3

#define JET "animation/jets/jet_by_02_lr.wav"

public Plugin:myinfo = {
	name		= "[L4D|L4D2]Jet hunter",
	author		= "King",
	description	= "Allows hunter are jets.",
	version		= PLUGIN_VERSION,
	url			= ""
}

new
	Handle:g_cvJetEnable	= INVALID_HANDLE,
	Handle:g_cvJetMax		= INVALID_HANDLE,
	bool:g_bJets		= true,
	g_fLastButtons[MAXPLAYERS+1],
	g_iJet[MAXPLAYERS+1],
	g_iJetMax
	
public OnPluginStart() {
	CreateConVar(
		"l4d2_jet_hunter_version", PLUGIN_VERSION,
		"Double Jump Version",
		FCVAR_NOTIFY
	)
	
	g_cvJetEnable = CreateConVar(
		"l4d2_jet_hunter_enabled", "1",
		"Enables double-jumping.",
		FCVAR_NOTIFY
	)
	
	g_cvJetMax = CreateConVar(
		"l4d2_impulse_max", "1",
		"The maximum number of jets impulse allowed while already lunge pounce.",
		FCVAR_NOTIFY
	)
	
	HookConVarChange(g_cvJetEnable,	convar_ChangeEnable)
	HookConVarChange(g_cvJetMax,		convar_ChangeMax)
	
	g_bJets	= GetConVarBool(g_cvJetEnable)
	g_iJetMax		= GetConVarInt(g_cvJetMax)
	
	AutoExecConfig(true, "l4d2_jet_hunter");
}

public OnMapStart()
{
	PrecacheSound(JET, true);
	
	AddFileToDownloadsTable("sound/animation/jets/jet_by_02_lr.wav");

	PrecacheParticle("electrical_arc_01_system");
}

public convar_ChangeEnable(Handle:convar, const String:oldVal[], const String:newVal[]) {
	if (StringToInt(newVal) >= 1) {
		g_bJets = true
	} else {
		g_bJets = false
	}
}

public convar_ChangeMax(Handle:convar, const String:oldVal[], const String:newVal[]) {
	g_iJetMax = StringToInt(newVal)
}

stock Landed(const any:client) {
	g_iJet[client] = 0	// reset jumps count
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(g_bJets)
	{
		new fCurFlags = GetEntityFlags(client);
		if(fCurFlags & FL_ONGROUND)
		{
			Landed(client);
		}
		else if(!(g_fLastButtons[client] & IN_RELOAD) && (buttons & IN_RELOAD) && !(fCurFlags & FL_ONGROUND) && IsValidHunter(client))
		{
			ReImpulse(client);
		}
		
		g_fLastButtons[client] = buttons;
	}
}

stock ReImpulse(const any:client)
{
	if (g_iJet[client] < g_iJetMax) // has jumped at least once but hasn't exceeded max re-jumps
	{						
		g_iJet[client]++											// increment jump count
		decl Float:fVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	
		fVelocity[0] *= 1.5;
		fVelocity[1] *= 1.5;
	
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);		// boost player
		
		EmitSoundToAll(JET, SNDCHAN_WEAPON, SNDLEVEL_SCREAMING, client);
		Show(client);
	}
}

public Show(client)
{
	if (IsValidHunter(client))
    {
		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
	
		ShowParticle(pos, "electrical_arc_01_system", 5.0);
	}
}


stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return false;
	}
	
	return true;
}

stock bool:IsValidHunter(client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 3)
	{
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_HUNTER)
		{
			return true;
		}
	}
	
	return false;
}

public PrecacheParticle(String:particlename[])
{
	/* Precache particle */
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
	}  
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	/* Show particle effect you like */
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}  
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	/* Delete particle */
    if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
            		RemoveEdict(particle);
	}
}