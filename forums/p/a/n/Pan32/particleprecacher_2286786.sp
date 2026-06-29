#include <sourcemod>
//Include only if needed
//
//Remember to add sm_precache_particles to bspconvars_whitelist.txt
//
//#include <sdktools>
//#include <sdkhooks>
//
#pragma semicolon 1

public Plugin:myinfo ={
	name = "CS:GO particle precacher",
	author = "Copypaste Slim",
	description = "Precaches particle systems to bypass the issues in the per-map manifest system.",
	version = "1.0.0",
	url = "http://a.b.c.d.e.f.g.h.is.a.valid.url.com/"
};

public OnPluginStart(){ 
	RegAdminCmd("sm_precache_particles",Command_PrecacheParticles,ADMFLAG_ROOT,"Precaches a particle system.");
}

public Action:Command_PrecacheParticles(client, args){
	if (args < 1){
		return Plugin_Handled;
	}
	new String:path[256];
	GetCmdArg(1, path, sizeof(path));
	PrintToConsole(client, "Particle precacher called for: %s", path);
	PrecacheGeneric(path, true);
	return Plugin_Handled;
}