#include <sdktools>
#include <sdkhooks>

new Handle:hmode = INVALID_HANDLE;
new imode;

new Handle:hlifetime = INVALID_HANDLE;
new Float:lifetime;

new Handle:hmaxheal = INVALID_HANDLE;
new maxheal;

new Handle:hheal = INVALID_HANDLE;
new heal[2];// [0] = min. [1] = max.

new Handle:hdissolvetype = INVALID_HANDLE;
new dissolvetype;

public Plugin:myinfo =
{
	name = "Healthkit From Dead (HFD)",
	author = "Bacardi",
	description = "Drop healthkit from dead player",
	version = "0.6"
}

new String:files[][] = {
	"materials/models/healthvial/healthvial.vmt",
	"materials/models/healthvial/healthvial.vtf",
	"materials/models/healthvial/healthvial_mask.vtf",
	"materials/models/items/healthkit01.vmt",
	"materials/models/items/healthkit01.vtf",
	"materials/models/items/healthkit01_mask.vtf",
	"models/items/healthkit.dx80.vtx",
	"models/items/healthkit.dx90.vtx",
	"models/items/healthkit.mdl",
	"models/items/healthkit.phy",
	"models/items/healthkit.sw.vtx",
	"models/items/healthkit.vvd",
	"models/healthvial.dx80.vtx",
	"models/healthvial.dx90.vtx",
	"models/healthvial.mdl",
	"models/healthvial.phy",
	"models/healthvial.sw.vtx",
	"models/healthvial.vvd",
	"sound/items/smallmedkit1.wav"
}

public OnPluginStart()
{

	for(new a = 0; a < sizeof(files); a++)
	{
		if(!FileExists(files[a], true))
		{
			SetFailState("No recommended file in server '%s'", files[a]);
		}
	}

	if(!HookEventEx("player_death", player_death))
	{
		SetFailState("Event player_death missing");
	}

	hmode = CreateConVar("hfd_mode", "2", "\n1 = change healthkit model healthvial\n2 = dissolve effect\n4 = work suicide\n8 = work teamkills\n16 = Emit sound only to player\n32 = no block for healthkits\n64 = Print hint text to player who gain heal\n128 = Bots can't get healthkit\n256 = Bots don't drop healthkit", FCVAR_NONE, true, 0.0);
/*
	1 = change model to healthvial
	2 = dissolve effect
	4 = work suicide
	8 = work teamkill
	16 = Emit sound only to client
	32 = no block for healthkits
	64 = Print hint text to player who gain heal
	128 = Bots can't get healthkit
	256 = Bots don't drop healthkit
*/
	imode = GetConVarInt(hmode);
	HookConVarChange(hmode, convar_change);

	hlifetime = CreateConVar("hfd_lifetime", "10.0", "How long healthkit stay. Less than 1.0 second disable", FCVAR_NONE, true, 0.0);
	lifetime = GetConVarFloat(hlifetime);
	HookConVarChange(hlifetime, convar_change);

	hmaxheal = CreateConVar("hfd_maxheal", "100", "Max heal", FCVAR_NONE, true, 2.0);
	maxheal = GetConVarInt(hmaxheal);
	HookConVarChange(hmaxheal, convar_change);

	hheal = CreateConVar("hfd_heal", "10", "How much healthkit heal player.\nUsing random values \"min , max\"", FCVAR_NONE, true, 1.0); // Can use random value "5 , 20"
	Check_cvar_heal();
	HookConVarChange(hheal, convar_change);

	hdissolvetype = CreateConVar("hfd_dissolvetype", "0", "Change dissolvetype\n0 Energy\n1 Heavy electrical\n2 Light electrical\n3 Core effect", FCVAR_NONE, true, 0.0, true, 3.0);
	dissolvetype = GetConVarInt(hdissolvetype);
	HookConVarChange(hdissolvetype, convar_change);
}

#define healthkit "models/items/healthkit.mdl" // Default healthkit, please don't edit.


// Below, you can replace/edit second model path to use different model.
//				WARNING!
// Model file need exist in server and have "collision"/"physic", otherwise server crash and hang up.

//			HL2MP and all mods
#define healthvial "models/healthvial.mdl" // This is now in use
//#define healthvial "models/healthkit.mdl"



#define smallmedkit1 "items/smallmedkit1.wav" // Sound

public OnConfigsExecuted()
{
	for(new a = 0; a < sizeof(files); a++)
	{
		if(FileExists(files[a], false))
		{
			AddFileToDownloadsTable(files[a]);
		}
	}

	PrecacheModel(healthkit, true);
	PrecacheModel(healthvial, true);
	PrecacheSound(smallmedkit1, true);
}

public convar_change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	imode = GetConVarInt(hmode);
	lifetime = GetConVarFloat(hlifetime);
	maxheal = GetConVarInt(hmaxheal);
	Check_cvar_heal();
	dissolvetype = GetConVarInt(hdissolvetype);
}

Check_cvar_heal()
{
	heal[0] = GetConVarInt(hheal);

	new String:buffer[10], indx;
	buffer[0] = '\0';
	GetConVarString(hheal, buffer, sizeof(buffer));

	if((indx = StrContains(buffer, ",")) > 1) // found comma
	{
		Format(buffer, sizeof(buffer), "%s", buffer[indx+1]);
		heal[1] = StringToInt(buffer);

		if(heal[1] <= heal[0]) // Max value is less or equal as min value
		{
			heal[1] = 0; // Reset
		}
	}
	else // No comma
	{
		heal[1] = 0; // Reset
	}
}

public player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid")); // victim

	if(imode & 256 && IsFakeClient(client)) // Bots don't drop healthkit mode
	{
		return;
	}

	if(imode & 4 && imode & 8) // When mode suicide and teamkill, no matter what kill player
	{
		DoHealthkit(client);
		return;
	}

	new attacker;
	attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if((client == attacker || attacker == 0)) // Check first was it Suicide or world... and don't let these continue code, God Damnit :P
	{
		imode & 4 ? DoHealthkit(client):0; // Is mode "suicide" enable
		return;
	}

	if(GetClientTeam(client) != GetClientTeam(attacker) || imode & 8) // check first was attacker enemy. If not then check is mode "teamkill"
	{
		DoHealthkit(client);
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

		Format(targetname, sizeof(targetname), "healthkit_%i", ent); // Create name

		imode & 1 ? DispatchKeyValue(ent, "model", healthvial):DispatchKeyValue(ent, "model", healthkit); // Which kit model
		DispatchKeyValue(ent, "physicsmode", "2"); // Non-Solid, Server-side
		DispatchKeyValue(ent, "massScale", "1.0"); // A scale multiplier for the object's mass.
		DispatchKeyValue(ent, "targetname", targetname); // The name that other entities refer to this entity by.
		DispatchSpawn(ent); // Spawn

		TeleportEntity(ent, pos, NULL_VECTOR, vel); // Teleport kit and throw

		imode & 32 ? SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1):0; // No block health kits

		if(imode & 2) // Dissolve effect
		{
			new entd;
			if((entd = CreateEntityByName("env_entity_dissolver")) != -1)
			{
				DispatchKeyValueFloat(entd, "dissolvetype", float(dissolvetype));
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
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 8); //     FSOLID_TRIGGER                = 0x0008,		// This is something may be collideable but fires touch functions
																											// even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)

		SDKHook(ent, SDKHook_StartTouchPost, StartTouchPost); // Follow who touch healthkit
	}
}

public StartTouchPost(entity, other) // oh, you touch my tralala, mmm... my ding ding dong
{
	if(other > 0 && other <= MaxClients)
	{
		if(imode & 128 && IsFakeClient(other)) // Bots can't get healthkit mode
		{
			return;
		}

		new health;
		health = GetEntProp(other, Prop_Send, "m_iHealth"); // Get player health

		if(health < maxheal) // Has low health
		{
			new add;
			add = heal[1] ? GetRandomInt(heal[0], heal[1]):heal[0]; // If heal[1] have value than 0, use random. Otherwise add normal heal value

			health += add; // Add heal

			health > maxheal ? (health = maxheal):0; // Overdose ?

			SetEntProp(other, Prop_Send, "m_iHealth", health); // Set player health

			imode & 16 ? EmitSoundToClient(other, smallmedkit1, _, SNDCHAN_ITEM, _, _, 0.2):EmitSoundToAll(smallmedkit1, other, SNDCHAN_ITEM, _, _, 0.2); // Sound only picker or emit sound to all from picker

			AcceptEntityInput(entity, "Kill"); // Destroy healthkit

			imode & 64 ? PrintHintText(other, "%s\n+%iHP", imode & 1 ? "Healthvial":"Healthkit", add):0; // Print hint msg to player
		}
	}
}