#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <sourcemod>
#include <stdio.h>

new EngineVersion:game;
new Handle:g_hThrownKnives; // Store thrown knives
new Handle:g_hTimerDelay[MAXPLAYERS+1];
new bool:g_bHeadshot[MAXPLAYERS+1];
new bool:HasAccess[MAXPLAYERS+1];
#define DMG_HEADSHOT		(1 << 30)

new Handle:cvar_throwingknives_count;
new g_iPlayerKniveCount[MAXPLAYERS+1];

new Handle:cvar_throwingknives_steal;
new Handle:cvar_throwingknives_velocity;
new Handle:cvar_throwingknives_damage;
new Handle:cvar_throwingknives_hsdamage;
new Handle:cvar_throwingknives_modelscale;
new Handle:cvar_throwingknives_gravity;
new Handle:cvar_throwingknives_elasticity;
new Handle:cvar_throwingknives_maxlifetime;
new Handle:cvar_throwingknives_trails;
new Handle:cvar_throwingknives_admins;

new String:config_file[] = "/cstrike/addons/sourcemod/configs/throwingknives.cfg";

int g_iKnifesCounter;

public Plugin:myinfo = {

    name = "Throwing Knives (noblock fix) with Config",
    author = "original by meng, Bacardi, fix by azalty, modified by OpenAI",
    version = "2024-03-23",
    description = "Throwing knives for CSS & CSGO, with noblock fix and configurable options",
    url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
    game = GetEngineVersion();

    if(game != Engine_CSGO && game != Engine_CSS)
    {
        SetFailState("Plugin designed for Counter-Strike: Global Offensive and Counter-Strike: Source");
    }

    RegisterConVars();
    LoadConVars();

    g_hThrownKnives = CreateArray();

    HookEvent("player_spawn", player_spawn);
    HookEvent("round_start", round_start);
    HookEvent("weapon_fire", weapon_fire);
    HookEvent("player_death", player_death, EventHookMode_Pre);

    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i)) OnClientPutInServer(i);
    }
}

public void RegisterConVars()
{
    cvar_throwingknives_count = CreateConVar("sm_throwingknives_count", "3", "Amount of knives players spawn with. 0 = Disable, -1 = infinite");
    cvar_throwingknives_steal = CreateConVar("sm_throwingknives_steal", "1", "If enabled, knife kills get the victims remaining knives.");
    cvar_throwingknives_velocity = CreateConVar("sm_throwingknives_velocity", "2250", "Velocity (speed) adjustment.");
    cvar_throwingknives_damage = CreateConVar("sm_throwingknives_damage", "57", "Damage adjustment.");
    cvar_throwingknives_hsdamage = CreateConVar("sm_throwingknives_hsdamage", "127", "Headshot damage adjustment.");
    cvar_throwingknives_modelscale = CreateConVar("sm_throwingknives_modelscale", "1.0", "Knife size scale");
    cvar_throwingknives_gravity = CreateConVar("sm_throwingknives_gravity", "1.0", "Knife gravity scale");
    cvar_throwingknives_elasticity = CreateConVar("sm_throwingknives_elasticity", "0.2", "Knife elasticity");
    cvar_throwingknives_maxlifetime = CreateConVar("sm_throwingknives_maxlifetime", "1.5", "Knife max life time");
    cvar_throwingknives_trails = CreateConVar("sm_throwingknives_trails", "1", "Knife leave trail effect");
    cvar_throwingknives_admins = CreateConVar("sm_throwingknives_admins", "0", "Admins only when enabled, who have access to admin override \"throwingknives\"");
}

public void LoadConVars()
{
    // Load default values from ConVars
    g_iKnifesCounter = 0;
}

public void WriteConfigFile()
{
    new file = fopen(config_file, "w");

    if (file != -1)
    {
        // Write each ConVar's value to the config file
        fwritestring(file, "sm_throwingknives_count ");
        fwritestring(file, GetConVarString(cvar_throwingknives_count));
        fwritestring(file, "\n");

        fwritestring(file, "sm_throwingknives_steal ");
        fwritestring(file, GetConVarString(cvar_throwingknives_steal));
        fwritestring(file, "\n");

        fwritestring(file, "sm_throwingknives_velocity ");
        fwritestring(file, GetConVarString(cvar_throwingknives_velocity));
        fwritestring(file, "\n");

        fwritestring(file, "\n");

        fwritestring(file, "sm_throwingknives_damage ");
        fwritestring(file, GetConVarString(cvar_throwingknives_damage));
        fwritestring(file, "\n");

        fwritestring(file, "sm_throwingknives_hsdamage ");
        fwritestring(file, GetConVarString(cvar_throwingknives_hsdamage));
        fwritestring(file, "\n");

        fwritestring(file, "sm_throwingknives_modelscale ");
        fwritestring(file, GetConVarString(cvar_throwingknives_modelscale));
        fwritestring(file, "\n");

        fwritestring(file, "sm_throwingknives_gravity ");
        fwritestring(file, GetConVarString(cvar_throwingknives_gravity));
        fwritestring(file, "\n");

        fwritestring(file, "sm_throwingknives_elasticity ");
        fwritestring(file, GetConVarString(cvar_throwingknives_elasticity));
        fwritestring(file, "\n");

        fwritestring(file, "sm_throwingknives_maxlifetime ");
        fwritestring(file, GetConVarString(cvar_throwingknives_maxlifetime));
        fwritestring(file, "\n");

        fwritestring(file, "sm_throwingknives_trails ");
        fwritestring(file, GetConVarString(cvar_throwingknives_trails));
        fwritestring(file, "\n");

        fwritestring(file, "sm_throwingknives_admins ");
        fwritestring(file, GetConVarString(cvar_throwingknives_admins));
        fwritestring(file, "\n");

        fclose(file);
    }
}

public void OnMapStart()
{
    PrecacheModel("models/error.mdl");
}

public OnClientPostAdminCheck(client)
{
	HasAccess[client] = CheckCommandAccess(client, "throwingknives", ADMFLAG_CUSTOM1);
}

public OnClientPutInServer(client)
{
	if(!IsClientSourceTV(client) && !IsClientReplay(client))
	{
		g_iPlayerKniveCount[client] = GetConVarInt(cvar_throwingknives_count); // If plugin reloaded, give ammo again
		SDKHookEx(client, SDKHook_OnTakeDamage, ontakedamage);
	}
}

// SDKHooks_TakeDamage seems not activate this callback, but player knife slash does
public Action:ontakedamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new dmgtype = game == Engine_CSS ? DMG_BULLET|DMG_NEVERGIB:DMG_SLASH|DMG_NEVERGIB;

	if(0 < inflictor <= MaxClients && inflictor == attacker && damagetype == dmgtype)
	{
		g_bHeadshot[attacker] = false; // no headshot when slash

		if(g_hTimerDelay[attacker] != INVALID_HANDLE)
		{
			KillTimer(g_hTimerDelay[attacker]);
			g_hTimerDelay[attacker] = INVALID_HANDLE;
		}
	}
}


public Action:player_death(Handle:event,const String:name[],bool:dontBroadcast)
{
	new String:weapon[20];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if(StrContains(weapon, "knife", false) != -1) // All knive kills, because csgo
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		if(GetConVarBool(cvar_throwingknives_admins) && !HasAccess[attacker])
		{
			return Plugin_Continue;
		}

		new cvar_count = GetConVarInt(cvar_throwingknives_count);

		if(GetConVarBool(cvar_throwingknives_steal) && cvar_count > 0)
		{
			new victim = GetClientOfUserId(GetEventInt(event, "userid"));
			if(g_iPlayerKniveCount[victim] > 0)
			{
				g_iPlayerKniveCount[attacker] += g_iPlayerKniveCount[victim];
				PrintHintText(attacker, "Throwing knives: %i/%i", g_iPlayerKniveCount[attacker], cvar_count);
			}
		}

		if(StrEqual(weapon, "knife", false)) // In csgo, this is throwing knive
		{
			SetEventBool(event, "headshot", g_bHeadshot[attacker]);
			g_bHeadshot[attacker] = false;
		}
	}

	return Plugin_Continue;
}

public player_spawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetConVarBool(cvar_throwingknives_admins) && !HasAccess[client])
	{
		return;
	}

	g_iPlayerKniveCount[client] = GetConVarInt(cvar_throwingknives_count);
}

public Action round_start(Event event, const char[] name, bool dontBroadcast)
{
	g_iKnifesCounter = 0;
	return Plugin_Continue;
}

public weapon_fire(Handle:event,const String:name[],bool:dontBroadcast)
{

	new String:weapon[20];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if( StrContains(weapon, "knife", false) == -1 )
	{
		return;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetConVarBool(cvar_throwingknives_admins) && !HasAccess[client])
	{
		return;
	}

	new cvar_count = GetConVarInt(cvar_throwingknives_count);

	if(g_iPlayerKniveCount[client] <= 0 && cvar_count != -1)
	{
		return;
	}

	if(cvar_count == 0)
	{
		return;
	}

	g_hTimerDelay[client] = CreateTimer(0.0, CreateKnife, client);

}

public Action:CreateKnife(Handle:timer, any:client)
{
	g_hTimerDelay[client] = INVALID_HANDLE;

	new slot_knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	new knife = CreateEntityByName("smokegrenade_projectile");
	int trigger = CreateEntityByName("trigger_multiple");

	if (knife == -1 || trigger == -1 || !DispatchSpawn(knife) || !DispatchSpawn(trigger))
	{
		return;
	}

	// owner
	new team = GetClientTeam(client);
	SetEntPropEnt(knife, Prop_Send, "m_hOwnerEntity", client);
	SetEntPropEnt(knife, Prop_Send, "m_hThrower", client);
	SetEntProp(knife, Prop_Send, "m_iTeamNum", team);

	// player knife model
	new String:model[PLATFORM_MAX_PATH];
	if(slot_knife != -1)
	{
		GetEntPropString(slot_knife, Prop_Data, "m_ModelName", model, sizeof(model));
		if(ReplaceString(model, sizeof(model), "v_knife_", "w_knife_", true) != 1)
		{
			model[0] = '\0';
		}
		else if(game == Engine_CSGO && ReplaceString(model, sizeof(model), ".mdl", "_dropped.mdl", true) != 1)
		{
			model[0] = '\0';
		}
	}

	if(!FileExists(model, true))
	{
		Format(model, sizeof(model), "%s", game == Engine_CSS ? "models/weapons/w_knife_t.mdl": team == CS_TEAM_T ? "models/weapons/w_knife_default_t_dropped.mdl":"models/weapons/w_knife_default_ct_dropped.mdl");
	}

	// model and size
	SetEntProp(knife, Prop_Send, "m_nModelIndex", PrecacheModel(model));
	SetEntPropFloat(knife, Prop_Send, "m_flModelScale", GetConVarFloat(cvar_throwingknives_modelscale));

	// knive elasticity
	SetEntPropFloat(knife, Prop_Send, "m_flElasticity", GetConVarFloat(cvar_throwingknives_elasticity));
	// gravity
	SetEntPropFloat(knife, Prop_Data, "m_flGravity", GetConVarFloat(cvar_throwingknives_gravity));


	// Player origin and angle
	new Float:origin[3], Float:angle[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angle);

	// knive new spawn position and angle is same as player's
	new Float:pos[3];
	GetAngleVectors(angle, pos, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(pos, 50.0);
	AddVectors(pos, origin, pos);

	// knive flying direction and speed/power
	new Float:player_velocity[3], Float:velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", player_velocity);
	GetAngleVectors(angle, velocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(velocity, GetConVarFloat(cvar_throwingknives_velocity));
	AddVectors(velocity, player_velocity, velocity);

	// spin knive
	new Float:spin[] = {4000.0, 0.0, 0.0};
	SetEntPropVector(knife, Prop_Data, "m_vecAngVelocity", spin);

	// Stop grenade detonate and Kill knive after 1 - 30 sec
	SetEntProp(knife, Prop_Data, "m_nNextThinkTick", -1);
	new String:buffer[25];
	Format(buffer, sizeof(buffer), "!self,KillHierarchy,,%0.1f,-1", GetConVarFloat(cvar_throwingknives_maxlifetime));
	DispatchKeyValue(knife, "OnUser1", buffer);
	AcceptEntityInput(knife, "FireUser1");

	// trail effect
	if(GetConVarBool(cvar_throwingknives_trails))
	{
		new color[4] = {255, ...};
		if(game == Engine_CSS)
		{
			TE_SetupBeamFollow(knife, PrecacheModel("sprites/bluelaser1.vmt"),	0, Float:0.5, Float:8.0, Float:1.0, 0, color);
		}
		else
		{
			TE_SetupBeamFollow(knife, PrecacheModel("effects/blueblacklargebeam.vmt"),	0, Float:0.5, Float:1.0, Float:0.1, 0, color);
		}
		TE_SendToAll();
	}

	// Throw knive!
	TeleportEntity(knife, pos, angle, velocity);

	// noblock fix (by azalty: https://github.com/shanapu/MyJailShop/pull/55/commits/f5369a9cc34a8fdacd8aefb57971934f17eedeea - https://forums.alliedmods.net/showthread.php?p=2732127#post2732127)
	DispatchKeyValue(trigger, "spawnflags", "1");
	ActivateEntity(trigger);
	TeleportEntity(trigger, pos, NULL_VECTOR, NULL_VECTOR);
	SetEntityModel(trigger, "models/error.mdl");
	float minbounds[3] = {-5.0, -5.0, -5.0};
	float maxbounds[3] = {5.0, 5.0, 5.0};
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", maxbounds);
	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
	int trigger_effects = GetEntProp(trigger, Prop_Send, "m_fEffects");
	trigger_effects |= 32;
	SetEntProp(trigger, Prop_Send, "m_fEffects", trigger_effects);
	char knife_targetname[32];
	Format(knife_targetname, sizeof(knife_targetname), "throwknife_%i", g_iKnifesCounter);
	g_iKnifesCounter++;
	DispatchKeyValue(knife, "targetname", knife_targetname);
	//DispatchKeyValue(trigger, "parentname", knife_targetname); // m_iParent
	SetVariantString(knife_targetname);
	AcceptEntityInput(trigger, "SetParent");
	SDKHookEx(trigger, SDKHook_Touch, KnifeTriggerHit);

	SDKHookEx(knife, SDKHook_Touch, KnifeHit);

	PushArrayCell(g_hThrownKnives, EntIndexToEntRef(knife));
	g_iPlayerKniveCount[client]--;
	PrintHintText(client, "Throwing knives: %i/%i", g_iPlayerKniveCount[client], GetConVarInt(cvar_throwingknives_count));
}

public Action:KnifeHit(knife, other)
{
	if(0 < other <= MaxClients) // Hits player index
	{
		new victim = other;

		SetVariantString("csblood");
		AcceptEntityInput(knife, "DispatchEffect");
		AcceptEntityInput(knife, "KillHierarchy");

		new attacker = GetEntPropEnt(knife, Prop_Send, "m_hThrower");
		new inflictor = GetPlayerWeaponSlot(attacker, CS_SLOT_KNIFE);

		if(inflictor == -1)
		{
			inflictor = attacker;
		}

		new Float:victimeye[3];
		GetClientEyePosition(victim, victimeye);

		new Float:damagePosition[3];
		new Float:damageForce[3];

		GetEntPropVector(knife, Prop_Data, "m_vecOrigin", damagePosition);
		GetEntPropVector(knife, Prop_Data, "m_vecVelocity", damageForce);

		if(GetVectorLength(damageForce) == 0.0) // knife movement stop
		{
			return;
		}

		// Headshot - shitty way check it, clienteyeposition almost player back...
		new Float:distance = GetVectorDistance(damagePosition, victimeye);
		g_bHeadshot[attacker] = distance <= 20.0;

		// damage values and type
		new Float:damage[2];
		damage[0] = GetConVarFloat(cvar_throwingknives_damage);
		damage[1] = GetConVarFloat(cvar_throwingknives_hsdamage);
		new dmgtype = game == Engine_CSS ? DMG_BULLET|DMG_NEVERGIB:DMG_SLASH|DMG_NEVERGIB;
		//new dmgtype = game == DMG_BULLET|DMG_NEVERGIB;

		if(g_bHeadshot[attacker])
		{
			dmgtype |= DMG_HEADSHOT;
		}

		// create damage
		SDKHooks_TakeDamage(victim, inflictor, attacker,
		g_bHeadshot[attacker] ? damage[1]:damage[0],
		dmgtype, knife, damageForce, damagePosition);

		// blood effect
		new color[] = {255, 0, 0, 255};
		new Float:dir[3];

		TE_SetupBloodSprite(damagePosition, dir, color, 1, PrecacheDecal("sprites/blood.vmt"), PrecacheDecal("sprites/blood.vmt"));
		TE_SendToAll(0.0);

		// ragdoll effect
		new ragdoll = GetEntPropEnt(victim, Prop_Send, "m_hRagdoll");
		if(ragdoll != -1)
		{
			ScaleVector(damageForce, 50.0);
			damageForce[2] = FloatAbs(damageForce[2]); // push up!
			SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", damageForce);
			SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", damageForce);
		}
	}
	else if(FindValueInArray(g_hThrownKnives, EntIndexToEntRef(other)) != -1) // knives collide
	{
		SDKUnhook(knife, SDKHook_Touch, KnifeHit);
		new Float:pos[3], Float:dir[3];
		GetEntPropVector(knife, Prop_Data, "m_vecOrigin", pos);
		TE_SetupArmorRicochet(pos, dir);
		TE_SendToAll(0.0);

		DispatchKeyValue(knife, "OnUser1", "!self,KillHierarchy,,1.0,-1");
		AcceptEntityInput(knife, "FireUser1");
	}
}

public OnEntityDestroyed(entity)
{
    if(!IsValidEdict(entity))
    {
        return;
    }

    new index = FindValueInArray(g_hThrownKnives, EntIndexToEntRef(entity));
    if(index != -1) RemoveFromArray(g_hThrownKnives, index);
}

public Action KnifeTriggerHit(int trigger, int other)
{
	if ((0 < other <= MaxClients) && GetClientTeam(other) != CS_TEAM_T) // Hits player index
	{
		SDKUnhook(trigger, SDKHook_Touch, KnifeTriggerHit);

		int parent = GetEntPropEnt(trigger, Prop_Data, "m_hMoveParent");
		AcceptEntityInput(trigger, "Kill");
		KnifeHit(parent, other);
	}
	return Plugin_Continue;
}

