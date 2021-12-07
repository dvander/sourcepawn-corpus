#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

// DEVELOPMENT INFO
// Scout - "primary_death_burning" - 88 frames
// Soldier - "primary_death_burning" - 116 frames
// Pyro - No burning taunt
// Demoman - "PRIMARY_death_burning" - 67 frames
// Heavy - "PRIMARY_death_burning" - 92 frames
// Engineer - "PRIMARY_death_burning" - 103 frames
// Medic - "primary_death_burning" - 100 frames
// Sniper - "primary_death_burning" - 131 frames
// Spy - "primary_death_burning" - 57 frames

new const String:g_Animations[][] = { 
	"primary_death_burning",
	"PRIMARY_death_burning"
};

new const Float:g_AnimationTimes[][] = {
	{ 0.0 } /* Unknown */,
	{ /* 2:28 */ 3.2 } /* Scout */,
	{ /* 4:11 */ 4.8 } /* Sniper */, 	
	{ /* 3:26 */ 4.2 } /* Soldier */,
	{ /* 2:07 */ 2.6 } /* Demoman */,
	{ /* 3:10 */ 3.6 } /* Medic */, 
	{ /* 3:02 */ 3.5 } /* Heavy */,	
	{ /* 0:00 */ 0.0 } /* Pyro */,
	{ /* 1:27 */ 2.2 } /* Spy */,
	{ /* 3:13 */ 3.8 } /* Engineer */
};

new g_ClientAnimEntity[MAXPLAYERS+1] = 0;
new bool:g_bPyrovision[MAXPLAYERS+1];
new g_iFireParticle[MAXPLAYERS + 1];


public Plugin:myinfo = 
{
	name = "[TF2] Burning Death Animations",
	author = "404: User Not Found",
	description = "Adds in the unused burning death animations.",
	version = PLUGIN_VERSION,
	url = "http://www.unfgaming.net"
};

public OnPluginStart()
{	
	CreateConVar("sm_burnanim_version", PLUGIN_VERSION, "[TF2] Burning Death Animations", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_testanims", Command_TestAnims, "Test out the animations!");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", Event_EquipItem,  EventHookMode_Post);
}

//-----------------------------------------------------------------------------
// Purpose: Hooking item equip - Ripped from my Lo-Fi Beacon plugin
//-----------------------------------------------------------------------------
public Action:Event_EquipItem(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Define what the client is.
	new user = GetEventInt(event, "userid");
	new client = GetClientOfUserId(user);

	// Make sure the item we're detecting is a hat
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_wearable")) != -1)
	{
		// Double check the net class to make sure it's definitely a "wearable"
		decl String:netclass[32];
		if (GetEntityNetClass(entity, netclass, sizeof(netclass)) && strcmp(netclass, "CTFWearable") == 0)
		{
			// Check owner entity
			if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			{
				// Check if hat is Pyrovision Goggles
				new entityindex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
				if (entityindex == 743 || entityindex == 744)
				{
					// Pyrovision on!
					g_bPyrovision[client] = true;
				}
				else
				{
					// Pyrovision off!
					g_bPyrovision[client] = false;
				}
			}
		}
	}
	return Plugin_Continue;
}

//-----------------------------------------------------------------------------
// Purpose: Hooking player_death event
//-----------------------------------------------------------------------------
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetEventInt(event, "userid");
	new attacker = GetEventInt(event, "attacker");
	new customkill = GetEventInt(event, "customkill");
	
	if (!IsValidClient(victim))
	{
		return Plugin_Continue;
	}
	if (!IsValidClient(attacker))
	{
		return Plugin_Continue;
	}
	if (attacker==victim)
	{
		return Plugin_Continue;
	}
	
	// Check if victim is a Pyro
	new TFClassType:victimClass = TF2_GetPlayerClass(victim);
	if (victimClass == TFClass_Pyro)
	{
		// Victim was a Pyro. Pyro doesn't have a burning death animation, so we're not going to worry about this.
		return Plugin_Handled;
	}
	
	// Check if attacker was a Pyro
	new TFClassType:attackerClass = TF2_GetPlayerClass(attacker);
	if (attackerClass == TFClass_Pyro)
	{
		// Doesn't seem to work.
		if (customkill == TF_CUSTOM_BURNING)
		{
			new g_BurnAnim = 0;
			SetAlpha(victim, 0);
			TF2_StunPlayer(victim, g_AnimationTimes[TF2_GetPlayerClass(victim)][g_BurnAnim], 1.0, TF_STUNFLAGS_LOSERSTATE);
			AttachNewPlayerModel(victim, g_BurnAnim);
			CreateTimer(g_AnimationTimes[TF2_GetPlayerClass(victim)][g_BurnAnim], Timer_EndBurningDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		}
		// Doesn't seem to work.
		if (TF2_IsPlayerInCondition(victim, TFCond_OnFire))
		{
			new g_BurnAnim = 0;
			SetAlpha(victim, 0);
			TF2_StunPlayer(victim, g_AnimationTimes[TF2_GetPlayerClass(victim)][g_BurnAnim], 1.0, TF_STUNFLAGS_LOSERSTATE);
			AttachNewPlayerModel(victim, g_BurnAnim);
			CreateTimer(g_AnimationTimes[TF2_GetPlayerClass(victim)][g_BurnAnim], Timer_EndBurningDeath, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

//-----------------------------------------------------------------------------
// Purpose: Ignite player model
//-----------------------------------------------------------------------------
stock IgnitePlayerModel(client)
{	
	ExtinguishPlayerModel(client);
	if (g_bPyrovision[client] == true)
	{
		// Pyrovision On, We use rainbow fire.
		new head = MakeParticle(client, "burningplayer_rainbow_red", "bip_head");
		if (IsValidEntity(head))
		{
			g_iFireParticle[client] = EntIndexToEntRef(head);
		}
	}
	else
	{
		// No Pyrovision, we use normal fire
		new head = MakeParticle(client, "burningplayer_red", "bip_head");
		if (IsValidEntity(head))
		{
			g_iFireParticle[client] = EntIndexToEntRef(head);
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose: Remove fire particles
//-----------------------------------------------------------------------------
stock ExtinguishPlayerModel(client)
{
	new ent = EntRefToEntIndex(g_iFireParticle[client]);
	if (ent > MaxClients && IsValidEntity(ent)) 
	{
		AcceptEntityInput(ent, "Kill");
	}
	g_iFireParticle[client] = INVALID_ENT_REFERENCE;
}

//-----------------------------------------------------------------------------
// Purpose: Animation test command
//-----------------------------------------------------------------------------
public Action:Command_TestAnims(client, args)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		// Check if player is a Pyro
		new TFClassType:playerClass = TF2_GetPlayerClass(client);
		if (playerClass == TFClass_Pyro)
		{
			// Player is a Pyro. Pyro doesn't have a burning death animation, so we're not going to worry about this.
			return Plugin_Handled;
		}
		
		IgnitePlayerModel(client);
		new g_BurnAnim = 0;
		SetAlpha(client, 0);
		TF2_StunPlayer(client, g_AnimationTimes[TF2_GetPlayerClass(client)][g_BurnAnim], 1.0, TF_STUNFLAGS_LOSERSTATE);
		AttachNewPlayerModel(client, g_BurnAnim);
		CreateTimer(g_AnimationTimes[TF2_GetPlayerClass(client)][g_BurnAnim], Timer_EndBurningDeath, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

//-----------------------------------------------------------------------------
// Purpose: Create fake player model
//-----------------------------------------------------------------------------
public AttachNewPlayerModel(client, g_BurnAnim)
{	
	new TFClassType:playerClass = TF2_GetPlayerClass(client);
	if (playerClass == TFClass_Engineer || playerClass == TFClass_DemoMan || playerClass == TFClass_Heavy)
	{
		g_BurnAnim+=1;
	}
	
	new model = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(model))
	{
		new Float:pos[3], Float:angles[3];
		decl String:clientmodel[256], String:skin[2];
		
		GetClientModel(client, clientmodel, sizeof(clientmodel));
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(model, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		angles[2] = 0.0;
		IntToString(GetClientTeam(client)-2, skin, sizeof(skin));
		
		DispatchKeyValue(model, "skin", skin);
		DispatchKeyValue(model, "model", clientmodel);
		DispatchKeyValue(model, "DefaultAnim", g_Animations[g_BurnAnim]);	
		DispatchKeyValueVector(model, "angles", angles);
		
		DispatchSpawn(model);
		
		SetVariantString(g_Animations[g_BurnAnim]);
		AcceptEntityInput(model, "SetAnimation");
		
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(model, "AddOutput");
		
		decl String:SelfDeleteStr[128];
		Format(SelfDeleteStr, sizeof(SelfDeleteStr), "OnUser1 !self:KillHierarchy::%f:1", g_AnimationTimes[TF2_GetPlayerClass(client)][0]+0.1); 
		SetVariantString(SelfDeleteStr);
		AcceptEntityInput(model, "AddOutput");
		
		SetVariantString("");
		AcceptEntityInput(model, "FireUser1");
		
		// Ignite!
		IgnitePlayerModel(client);
		g_ClientAnimEntity[client] = model;
	}
}

//-----------------------------------------------------------------------------
// Purpose: Set player model alpha
//-----------------------------------------------------------------------------
stock SetAlpha(target, alpha)
{
	SetWeaponsAlpha(target, alpha);
	SetWearablesAlpha(target, alpha);
	SetEntityRenderMode(target, RENDER_TRANSCOLOR);
	SetEntityRenderColor(target, 255, 255, 255, alpha);
}

//-----------------------------------------------------------------------------
// Purpose: Set weapon model alpha
//-----------------------------------------------------------------------------
stock SetWeaponsAlpha(target, alpha)
{
	decl String:classname[64];
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	for (new i = 0, weapon; i < 189; i += 4)
	{
		weapon = GetEntDataEnt2(target, m_hMyWeapons + i);
		if (weapon > -1 && IsValidEdict(weapon))
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			if (StrContains(classname, "tf_weapon", false) != -1 || StrContains(classname, "tf_wearable", false) != -1)
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, alpha);
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose: Set cosmetic model alpha
//-----------------------------------------------------------------------------
stock SetWearablesAlpha(target, alpha)
{
	if (IsPlayerAlive(target))
	{
		new Float:pos[3], Float:wearablepos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
		new wearable= -1;
		while ((wearable= FindEntityByClassname(wearable, "tf_wearable")) != -1)
		{
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos);
			if (GetVectorDistance(pos, wearablepos, true) < 2)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wearable, 255, 255, 255, alpha);
			}
		}
		while ((wearable= FindEntityByClassname(wearable, "tf_wearable_item_demoshield")) != -1)
		{
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos);
			if (GetVectorDistance(pos, wearablepos, true) < 2)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wearable, 255, 255, 255, alpha);
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose: End burning death timer
//-----------------------------------------------------------------------------
public Action:Timer_EndBurningDeath(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		
		SetAlpha(client, 255);
		if (IsPlayerAlive(client))
		{
			// Player can walk again!
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
	// Kill the prop_dynamic
	if(g_ClientAnimEntity[client] > 0 && IsValidEdict(g_ClientAnimEntity[client]))
	{
		AcceptEntityInput(g_ClientAnimEntity[client], "Kill");
		ExtinguishPlayerModel(client);
	}
}

//-----------------------------------------------------------------------------
// Purpose: Make particles (Credit to Pelipoika)
//-----------------------------------------------------------------------------
stock MakeParticle(client, String:effect[], String:attachment[])
{
	decl Float:pos[3];
	decl Float:ang[3];
	decl String:buffer[128];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	pos[2] += 70.0;
	GetClientEyeAngles(client, ang);
	new String:strTargetName[MAX_NAME_LENGTH];
	GetClientName(client, strTargetName, sizeof(strTargetName));
	DispatchKeyValue(client, "targetname", strTargetName);
	ang[0] *= -1;
	ang[1] += 180.0;
	if (ang[1] > 180.0) ang[1] -= 360.0;
	ang[2] = 0.0;
//	GetAngleVectors(ang, pos2, NULL_VECTOR, NULL_VECTOR);
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle)) return -1;
	TeleportEntity(particle, pos, ang, NULL_VECTOR);
	DispatchKeyValue(particle, "effect_name", effect);
	SetVariantString("!activator");
	
	DispatchKeyValue(particle, "parentname", strTargetName);
	AcceptEntityInput(particle, "SetParent", client, particle, 0);
	if (attachment[0] != '\0')
	{
		//SetVariantString(attachment);
		//SetVariantString("primary");	
		//AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
	}
	Format(buffer, sizeof(buffer), "%s_%s%d", effect, attachment, particle);
	DispatchKeyValue(particle, "targetname", buffer);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", client);
	AcceptEntityInput(particle, "Start");
	return particle;
}

//-----------------------------------------------------------------------------
// Purpose: Valid client check stock
//-----------------------------------------------------------------------------
stock bool:IsValidClient(client) 
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}