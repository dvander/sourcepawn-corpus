#include <sdktools>
#include <sdkhooks>

new Handle:hmode = INVALID_HANDLE;
new imode;

new Handle:hlifetime = INVALID_HANDLE;
new Float:lifetime;

new Handle:hmaxheal = INVALID_HANDLE;
new maxheal;

new Handle:hheal_max = INVALID_HANDLE;
new Handle:hheal_min = INVALID_HANDLE;
new heal;

public Plugin:myinfo =
{
	name = "Healthkit From Dead (HFD)",
	author = "Bacardi & Snake 60",
	description = "Drop healthkit from dead player this random health",
	version = "0.4"
}

public OnPluginStart()
{
	if(!HookEventEx("player_death", player_death))
	{
		SetFailState("Event player_death missing");
	}

	hmode = CreateConVar("hfd_mode", "0", "\n1 = change healthkit model healthvial\n2 = dissolve effect\n4 = work suicide\n8 = work teamkills\n16 = Emit sound only to player\n32 = no block for healthkits", FCVAR_NONE, true, 0.0);
/*
	1 = change model to healthvial
	2 = dissolve effect
	4 = work suicide
	8 = work teamkill
	16 = Emit sound only to client
	32 = no block for healthkits
*/
	imode = GetConVarInt(hmode);
	HookConVarChange(hmode, convar_change);

	hlifetime = CreateConVar("hfd_lifetime", "20.0", "How long healthkit stay. Less than 1.0 second disable", FCVAR_NONE, true, 0.0);
	lifetime = GetConVarFloat(hlifetime);
	HookConVarChange(hlifetime, convar_change);

	hmaxheal = CreateConVar("hfd_maxheal", "100", "Max heal", FCVAR_NONE, true, 2.0);
	maxheal = GetConVarInt(hmaxheal);
	HookConVarChange(hmaxheal, convar_change);

	hheal_min = CreateConVar("hfd_heal_min", "10", "Minimum limit in random definition how much health kit heal player", FCVAR_NONE, true, 1.0);
	hheal_max = CreateConVar("hfd_heal_max", "40", "Maximum limit in random definition how much health kit heal player", FCVAR_NONE, true, 1.0);
	heal = GetRandomInt(GetConVarInt(hheal_min),GetConVarInt(hheal_max));
	HookConVarChange(hheal_min, convar_change);
	HookConVarChange(hheal_max, convar_change);

	AutoExecConfig(true, "plugin.hfd");
}

#define healthkit "models/items/healthkit.mdl"
#define healthvial "models/healthvial.mdl"
#define smallmedkit1 "items/smallmedkit1.wav"

public OnConfigsExecuted()
{
	PrecacheModel(healthkit, true);
	PrecacheModel(healthvial, true);
	PrecacheSound(smallmedkit1, true);
}

public convar_change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	imode = GetConVarInt(hmode);
	lifetime = GetConVarFloat(hlifetime);
	maxheal = GetConVarInt(hmaxheal);
	heal = GetRandomInt(GetConVarInt(hheal_min),GetConVarInt(hheal_max));
}

public player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	heal = GetRandomInt(GetConVarInt(hheal_min),GetConVarInt(hheal_max));
	decl client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(imode & 4 && imode & 8) // When suicide and teamkill, no matter what kill player
	{
		DoHealthkit(client);
		return;
	}

	decl attacker;
	attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if((client == attacker || attacker == 0) && imode & 4) // Suicide + world
	{
		DoHealthkit(client);
		return;
	}

	if(attacker != 0) // Prevent check GetClientTeam() invalid player index 0
	{
		decl team1, team2;
		if((team1 = GetClientTeam(client)) == (team2 = GetClientTeam(attacker)) && imode & 8 || team1 != team2) // teamkill or enemy
		{
			DoHealthkit(client);
			//return;
		}
	}
}

DoHealthkit(client)
{
	if(lifetime <= 0.9) // Same as disabled
	{
		return;
	}

	new ent;

	if((ent = CreateEntityByName("prop_physics_multiplayer")) != -1)
	{
		new Float:pos[3], Float:vel[3], String:targetname[100];

		GetClientEyePosition(client, pos); // Let's try get position from higher

		// Random throw how Knagg0 made
		vel[0] = GetRandomFloat(-200.0, 200.0);
		vel[1] = GetRandomFloat(-200.0, 200.0);
		vel[2] = GetRandomFloat(100.0, 200.0);

		TeleportEntity(ent, pos, NULL_VECTOR, vel); // Teleport kit and throw

		Format(targetname, sizeof(targetname), "healthkit_%i", ent); // Create name

		imode & 1 ? DispatchKeyValue(ent, "model", healthvial):DispatchKeyValue(ent, "model", healthkit); // Which kit model
		DispatchKeyValue(ent, "physicsmode", "2"); // Non-Solid, Server-side
		DispatchKeyValue(ent, "massScale", "1.0"); // A scale multiplier for the object's mass.
		DispatchKeyValue(ent, "targetname", targetname); // The name that other entities refer to this entity by.
		DispatchSpawn(ent); // Spawn


		imode & 32 ? SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1):0; //

		if(imode & 2) // Dissolve effect
		{
			new entd;
			if((entd = CreateEntityByName("env_entity_dissolver")) != -1)
			{
				DispatchKeyValue(entd, "dissolvetype", "0");
															/* 		Not much difference
															0 	Energy
															1 	Heavy electrical
															2 	Light electrical
															3 	Core effect 
															*/

				DispatchKeyValue(entd, "magnitude", "250"); // How strongly to push away from the center. Maybe not work
				DispatchKeyValue(entd, "target", targetname); // "Targetname of the entity you want to dissolve."

				// Parent dissolver to healthkit. When entity destroyed, dissolver also.
				TeleportEntity(entd, pos, NULL_VECTOR, NULL_VECTOR);
				SetVariantString("!activator");
				AcceptEntityInput(entd, "SetParent", ent);

				Format(targetname, sizeof(targetname), "OnUser1 !self:Dissolve::%0.2f:-1", lifetime); // Delay dissolve
				SetVariantString(targetname);
				AcceptEntityInput(entd, "AddOutput");

				// Not need this when parent dissolver to other entity
				//Format(targetname, sizeof(targetname), "OnUser1 !self:kill::7.1:-1");
				//SetVariantString(targetname);
				//AcceptEntityInput(entd, "AddOutput");

				AcceptEntityInput(entd, "FireUser1");
			}
		}
		else // No dissolve effect, add kill time in healthkit
		{
			Format(targetname, sizeof(targetname), "OnUser1 !self:kill::%0.2f:-1", lifetime);
			SetVariantString(targetname);
			AcceptEntityInput(ent, "AddOutput");
			AcceptEntityInput(ent, "FireUser1");
		}
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 8); // Need one day find these meanings, this help define touch
		SDKHook(ent, SDKHook_StartTouch, StartTouch); // Follow who touch healthkit
	}
}

public StartTouch(entity, other) // oh, you touch my tralala, mmm... my ding ding dong
{
	if(other > 0 && other <= MaxClients)
	{
		decl health;
		health = GetEntProp(other, Prop_Send, "m_iHealth"); // Get player health

		if(health < maxheal) // Has low health
		{
			health += heal; // Add health

			health > maxheal ? (health = maxheal):0; // Overdose ?

			SetEntProp(other, Prop_Send, "m_iHealth", health); // Set player health

			imode & 16 ? EmitSoundToClient(other, smallmedkit1, _, _, _, _, 0.2):EmitSoundToAll(smallmedkit1, other, _, _, _, 0.2);

			AcceptEntityInput(entity, "Kill"); // Destroy healthkit
		}
	}
}