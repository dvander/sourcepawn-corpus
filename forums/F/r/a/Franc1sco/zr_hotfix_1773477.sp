#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

public Plugin:myinfo =
{
	name = "SM ZR Hot Fix",
	author = "Franc1sco steam: franug",
	description = "For fix a bug in ZR for CSGO",
	version = "v1.2",
	url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
	CreateConVar("zr_smallhotfix", "v1.2", _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	new vida = GetClientHealth(client);
	if(vida < 300) // not have a zombie class :/ (this number must be greater than the life of the human)
	{
		// the zombie health is the most important
		SetEntityHealth(client, 4000); // zombie HP (edit it to your preferences)
		
		// this is optional
		//SetEntityModel(client, "models/player/mapeadores/morell/zh/zh3.mdl"); // zombie model
		//SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.1); // zombie velocity
		
	}
}

