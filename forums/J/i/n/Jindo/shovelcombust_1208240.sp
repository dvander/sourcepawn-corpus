/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define SOLDIER_PAIN_01		"vo/soldier_DirectHitTaunt04.wav"
#define SOLDIER_PAIN_02		"vo/soldier_DirectHitTaunt03.wav"
#define SOLDIER_PAIN_03		"vo/soldier_DirectHitTaunt01.wav"

#define EXPLODE_01			"weapons/explode1.wav"
#define EXPLODE_02			"weapons/explode2.wav"
#define EXPLODE_03			"weapons/explode3.wav"

#define CVAR_VERSION		0
#define CVAR_ENABLE			1
#define CVAR_RADIUS			2
#define CVAR_GAMEPLAY		3
#define CVAR_DAMAGE			4
#define CVAR_DURATION		5
#define CVAR_STRENGTH		6
#define CVAR_UBER			7
#define CVAR_KRITZ			8
#define CVAR_NUMTIMES		9
#define CVAR_COOLDOWN		10
#define CVAR_MESSAGES		11
#define CVAR_PARTICLE_S		12
#define CVAR_PARTICLE_L		13
#define CVAR_IGNITE			14
#define NUM_CVARS			15

#define PL_VERSION		"0.2"

new Handle:g_cvars[NUM_CVARS];
new g_ent1[MAXPLAYERS+1];
new g_ent2[MAXPLAYERS+1];
new g_target[MAXPLAYERS+1];
new bool:g_combust[MAXPLAYERS+1];
new bool:g_cancombust[MAXPLAYERS+1];
new g_ignitesleft[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Fireproof Mass of Scar Tissue",
	author = "Jindo",
	description = "Spontaneously combusting shovel.",
	version = PL_VERSION,
	url = "http://www.topaz-games.com/"
}

public OnPluginStart()
{
	g_cvars[CVAR_VERSION] = CreateConVar("shovelcombust_version", PL_VERSION, "Version of the plugin.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_cvars[CVAR_ENABLE] = CreateConVar("sc_enable", "1", "Enable the plugin.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	
	g_cvars[CVAR_GAMEPLAY] = CreateConVar("sc_gameplay", "0", "Enable gameplay balance-defying alterations.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvars[CVAR_DAMAGE] = CreateConVar("sc_damage", "50.0", "How much damage the explosion deals (if sc_gameplay is non-zero.)", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvars[CVAR_IGNITE] = CreateConVar("sc_ignite", "1", "Set players on fire if they are within range of the ignition explosion.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvars[CVAR_DURATION] = CreateConVar("sc_duration", "10.0", "How long any effects of the ignition will last.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvars[CVAR_STRENGTH] = CreateConVar("sc_strength", "4.5", "Knock-back strength of the explosion (if sc_gameplay is non-zero.)", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvars[CVAR_RADIUS] = CreateConVar("sc_radius", "50.0", "Radius in game units of the area affected by ignition, players within this range are sent flying and ignited (if sc_gameplay is non-zero.)", FCVAR_PLUGIN|FCVAR_REPLICATED);
	
	g_cvars[CVAR_UBER] = CreateConVar("sc_uber", "1", "Enable uber upon ignition.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvars[CVAR_KRITZ] = CreateConVar("sc_crits", "2", "0=None, 1=Kritz, 2=Minicrits", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvars[CVAR_NUMTIMES] = CreateConVar("sc_numtimes", "1", "Number of times the ignition can be used per life.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvars[CVAR_COOLDOWN] = CreateConVar("sc_cooldown", "10.0", "Optional cooldown between usages (starting from when the effects end.)", FCVAR_PLUGIN|FCVAR_REPLICATED);
	
	g_cvars[CVAR_MESSAGES] = CreateConVar("sc_messages", "2", "0=No messages, 1=Chat prompts, 2=Center screen prompts.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvars[CVAR_PARTICLE_L] = CreateConVar("sc_explosion", "1", "Enable use of the explosion particle.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	g_cvars[CVAR_PARTICLE_S] = CreateConVar("sc_firewep", "1", "Enable use of the flame particle.", FCVAR_PLUGIN|FCVAR_REPLICATED);
	
	LoadTranslations("common.phrases");
	LoadTranslations("shovelcombust.phrases");
	
	HookEvent("player_changeclass", Event_ChangeClass);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_Regenerate);
}

public OnMapStart()
{
	PrecacheSound(SOLDIER_PAIN_01, true);
	PrecacheSound(SOLDIER_PAIN_02, true);
	PrecacheSound(SOLDIER_PAIN_03, true);
	PrecacheSound(EXPLODE_01, true);
	PrecacheSound(EXPLODE_02, true);
	PrecacheSound(EXPLODE_03, true);
}

public Action:Event_Regenerate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new num_ignites = GetConVarInt(g_cvars[CVAR_NUMTIMES])
	if (num_ignites)
	{
		g_ignitesleft[client] = num_ignites;
	}
	else
	{
		g_ignitesleft[client] = 1;
	}
	g_cancombust[client] = true;
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new num_ignites = GetConVarInt(g_cvars[CVAR_NUMTIMES])
	if (num_ignites)
	{
		g_ignitesleft[client] = num_ignites;
	}
	else
	{
		g_ignitesleft[client] = 1;
	}
	g_cancombust[client] = true;
	g_combust[client] = false;
	return Plugin_Continue;
}

public Action:Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new class = GetEventInt(event, "class");
	if (TFClassType:class != TFClass_Soldier)
	{
		if (g_combust[client])
		{
			g_combust[client] = false
			DeleteParticle(g_ent1[client]);
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (GetConVarInt(g_cvars[CVAR_ENABLE]))
	{
		if (buttons & IN_ATTACK2)
		{
			if (!g_combust[client] && g_cancombust[client])
			{
				if (TF2_GetPlayerClass(client) == TF2_GetClass("soldier") && ActiveWeapon(client) == GetPlayerWeaponSlot(client, 2) && GetPlayerWeaponIndex(client, 2) == 6)
				{
					if (g_ignitesleft[client] > 0)
					{
						Combust(client);
						if (GetConVarInt(g_cvars[CVAR_GAMEPLAY]))
						{
							ExplosionDamage(client);
						}
					}
					g_combust[client] = true;
					g_ignitesleft[client]--;
					
					if (g_ignitesleft[client] >= 0)
					{
						switch (GetConVarInt(g_cvars[CVAR_MESSAGES]))
						{
							case 1:			PrintToChat(client, "%t", "Ignitions remaining", g_ignitesleft[client]);
							case 2:			PrintCenterText(client, "%t", "Ignitions remaining", g_ignitesleft[client]);
						}
					}
					
					buttons &= ~IN_ATTACK2;
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}

ExplosionDamage(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i))
		{
			if (GetClientTeam(i) != GetClientTeam(client))
			{
				new Float:client_pos[3], Float:target_pos[3];
				GetClientAbsOrigin(client, client_pos);
				GetClientAbsOrigin(i, target_pos);
				new Float:radius = GetConVarFloat(g_cvars[CVAR_RADIUS]);
				if (IsInRange(client_pos, target_pos, radius*2))
				{
					new Float:strength = GetConVarFloat(g_cvars[CVAR_STRENGTH]);
					new Float:vel[3];
					
					GetEntPropVector(i, Prop_Data, "m_vecVelocity", vel);
					vel[0] = (radius-(target_pos[0]-client_pos[0]))*strength;
					vel[1] = -(radius-(target_pos[1]-client_pos[1]))*strength;
					vel[2] = strength*100.0;
					
					new hp = GetConVarInt(g_cvars[CVAR_DAMAGE]);
					
					if (GetClientHealth(i) >= hp+1)
					{
						SetEntityHealth(i, GetClientHealth(i)-hp);
					}
					else
					{
						SetEntityHealth(i, 1);
					}
					
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vel);
					
					if (GetConVarInt(g_cvars[CVAR_IGNITE]))
					{
						TF2_IgnitePlayer(i, client);
					}
				}
			}
		}
	}
}

stock bool:IsInRange(Float:pos1[3], Float:pos2[3], Float:radius)
{
	if (pos2[0] >= pos1[0]-radius && pos2[0] <= pos1[0]+radius)
	{
		if (pos2[1] >= pos1[1]-radius && pos2[1] <= pos1[1]+radius)
		{
			if (pos2[2] >= pos1[2]-radius && pos2[2] <= pos1[2]+radius)
			{
				return true;
			}
		}
	}
	return false;
}

Combust(client)
{
	if (!g_combust[client] && g_cancombust[client])
	{
		if (client > 0 && client <= MaxClients)
		{
			if (IsClientConnected(client) && IsClientInGame(client))
			{
				if (ActiveWeapon(client) == GetPlayerWeaponSlot(client, 2) && GetPlayerWeaponIndex(client, 2) == 6)
				{
					if (g_ignitesleft[client] > 0)
					{
						CreateTimer(0.1, Timer_Combust, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(0.1, Timer_Flame, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(GetConVarFloat(g_cvars[CVAR_DURATION]), Timer_Delete, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						switch (GetRandomInt(1, 3))
						{
							case 1: EmitSoundToAll(SOLDIER_PAIN_01, client, SNDCHAN_VOICE);
							case 2: EmitSoundToAll(SOLDIER_PAIN_02, client, SNDCHAN_VOICE);
							case 3: EmitSoundToAll(SOLDIER_PAIN_03, client, SNDCHAN_VOICE);
						}
					}
				}
			}
		}
	}
}

stock ActiveWeapon(client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock GetPlayerWeaponIndex(client, slot)
{
	return GetEntProp(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_iItemDefinitionIndex");
}

public Action:Timer_Flame(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		if (TF2_GetPlayerClass(client) == TF2_GetClass("soldier"))
		{
			if (GetPlayerWeaponIndex(client, 2) == 6)
			{
				
				if (GetConVarInt(g_cvars[CVAR_PARTICLE_S]))
				{
					AttachParticle(client, "buildingdamage_dispenser_fire1");
				}
				
				if (GetConVarInt(g_cvars[CVAR_GAMEPLAY]))
				{
					new Float:duration = GetConVarFloat(g_cvars[CVAR_DURATION]);
					new pcond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
					if (GetConVarInt(g_cvars[CVAR_UBER]) && !(pcond & TF_CONDFLAG_UBERCHARGED))
					{
						TF2_AddCondition(client, TFCond_Ubercharged, duration);
					}
					if (GetConVarInt(g_cvars[CVAR_KRITZ]) == 1 && !(pcond & TF_CONDFLAG_KRITZKRIEGED))
					{
						TF2_AddCondition(client, TFCond_Kritzkrieged, duration);
					}
					if (GetConVarInt(g_cvars[CVAR_KRITZ]) == 2 && !(pcond & TF_CONDFLAG_BUFFED))
					{
						TF2_AddCondition(client, TFCond_Buffed, duration);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action:Timer_Combust(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		if (TF2_GetPlayerClass(client) == TF2_GetClass("soldier"))
		{
			if (GetPlayerWeaponIndex(client, 2) == 6)
			{
				if (GetConVarInt(g_cvars[CVAR_PARTICLE_L]))
				{
					AttachParticle(client, "cinefx_goldrush");
					
					new Float:pos[3];
					GetClientAbsOrigin(client, pos);
					switch (GetRandomInt(1, 3))
					{
						case 1: EmitAmbientSound(EXPLODE_01, pos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 40.0, SNDPITCH_NORMAL, 0.0);
						case 2: EmitAmbientSound(EXPLODE_02, pos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 40.0, SNDPITCH_NORMAL, 0.0);
						case 3: EmitAmbientSound(EXPLODE_03, pos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 40.0, SNDPITCH_NORMAL, 0.0);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action:Timer_Delete(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	DeleteParticle(g_ent1[client]);
	DeleteParticle(g_ent2[client]);
	g_ent1[client] = 0;
	g_ent2[client] = 0;
	g_target[client] = 0;
	if (GetConVarInt(g_cvars[CVAR_GAMEPLAY]))
	{
		new pcond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		if (GetConVarInt(g_cvars[CVAR_UBER]) && pcond & TF_CONDFLAG_UBERCHARGED)
		{
			TF2_RemoveCondition(client, TFCond_Ubercharged);
		}
		if (GetConVarInt(g_cvars[CVAR_KRITZ]) == 1 && pcond & TF_CONDFLAG_KRITZKRIEGED)
		{
			TF2_RemoveCondition(client, TFCond_Kritzkrieged);
		}
		if (GetConVarInt(g_cvars[CVAR_KRITZ]) == 2 && pcond & TF_CONDFLAG_BUFFED)
		{
			TF2_RemoveCondition(client, TFCond_Buffed);
		}
	}
	if (GetConVarInt(g_cvars[CVAR_COOLDOWN]))
	{
		CreateTimer(GetConVarFloat(g_cvars[CVAR_COOLDOWN]), Timer_Cooldown, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Timer_Cooldown(Handle:timer, any:client)
{
	g_combust[client] = false;
	g_cancombust[client] = true;
	if (g_ignitesleft[client] > 0)
	{
		switch (GetConVarInt(g_cvars[CVAR_MESSAGES]))
		{
			case 1:		PrintToChat(client, "%t", "Ignitable");
			case 2:		PrintCenterText(client, "%t", "Ignitable");
		}
	}
	return Plugin_Handled;
}

stock AttachParticle(ent, String:particle_type[])
{
	new particle = CreateEntityByName("info_particle_system");
	decl String:name[128];
	
	new Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	
	if (IsValidEdict(particle))
	{
		if (strcmp(particle_type, "buildingdamage_dispenser_fire1"))
		{
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			
			Format(name, sizeof(name), "target%i", ent);
			
			DispatchKeyValue(ent, "targetname", name);
			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "parentname", name);
			DispatchKeyValue(particle, "effect_name", particle_type);
			DispatchSpawn(particle);
			
			SetVariantString(name);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			SetVariantString("flag");
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			
			g_ent1[ent] = particle;
		}
		else
		{
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			
			Format(name, sizeof(name), "target%i", ent);
			
			DispatchKeyValue(ent, "targetname", name);
			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "parentname", name);
			DispatchKeyValue(particle, "effect_name", particle_type);
			DispatchSpawn(particle);
			
			SetVariantString(name);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			SetVariantString("weapon_bone_1");
			AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			
			g_ent2[ent] = particle;
		}
		g_target[ent] = 1;
	}
}

stock DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
        decl String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));
		
        if (!strcmp(classname, "info_particle_system"))
        {
            RemoveEdict(particle);
        }
    }
}