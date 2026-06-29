#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1

new Pedobear = -1;
new Pedobear_Target = -1;
new PedobearAttack = false;

new Float:pedobear_range_original = 0.0;

new Handle:Pedobear_Sound;
new Pedobear_Sound_B = false;

new Float:g_pos[3];

public Plugin:myinfo = 
{
	name = "[TF2] Pedobear NPC",
	author = "Oshizu / Sena™ ¦",
	description = "Allows you summon almight Pedobear NPC to scare off kids micspamming on yer community.",
	version = "2.0.1",
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	new Handle:pedobear_range_original_h = FindConVar("tf_halloween_bot_attack_range");
	pedobear_range_original = GetConVarFloat(pedobear_range_original_h);
	
	HookEvent("pumpkin_lord_summoned", PedobearSpawned, EventHookMode_Pre);
	HookEvent("pumpkin_lord_killed", PedobearDie, EventHookMode_Pre);
	HookEvent("teamplay_round_start", DisablePedo);
	HookEvent("teamplay_round_win", DisablePedo2);
	HookEvent("teamplay_round_stalemate", DisablePedo2);
	HookEvent("player_death", PedoKill, EventHookMode_Pre);
	
	Pedobear_Sound = CreateConVar("sm_tf2npcs_pedobear_ambient", "0", "0 - Disables Ambient | 1 - Enables Ambient | Pedobear Ambient in other words sound that is emitted by pedobear");
	HookConVarChange(Pedobear_Sound, CvarChange_PedobearSound);

	RegAdminCmd("sm_pedobear", PedobearSpawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_pedo", PedobearSpawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_pedobear_sprite", PedobearSpawn_SPR, ADMFLAG_ROOT);
	RegAdminCmd("sm_pedo_sprite", PedobearSpawn_SPR, ADMFLAG_ROOT);
	
	AddNormalSoundHook(HHH_Sound);
	
	Precache();
	HookUserMessage(GetUserMessageId("SayText2"), HalloweenHook, true);
	
	AutoExecConfig(true, "plugin.tf2npcs_pedobear_v2");
}

public Action:PedobearSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(PedobearAttack)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public CvarChange_PedobearSound(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(newValue) > 1)
	{
		SetConVarInt(convar, 1);
		Pedobear_Sound_B = true;
	}
	else if(StringToInt(newValue) < 0)
	{
		SetConVarInt(convar, 0);
		Pedobear_Sound_B = false;
	}
	else if(StringToInt(newValue) == 1)
	{
		Pedobear_Sound_B = true;
	}
	else if(StringToInt(newValue) == 0)
	{
		Pedobear_Sound_B = false;
	}
}

public Action:HalloweenHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{ 
	if(PedobearAttack)
	{
		BfReadByte(bf);
		BfReadByte(bf);

		decl String:szBuffer[256];
		BfReadString(bf, szBuffer, sizeof(szBuffer));
		if (strcmp(szBuffer, "#TF_Halloween_Boss_Killers") == 0)
		{
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}  

public OnPluginEnd()
{
	SetConVarFloat(FindConVar("tf_halloween_bot_attack_range"), pedobear_range_original);
}

stock RemovePedoSound()
{
	if(Pedobear_Sound_B)
	{
		for(new i=1;i<=MaxClients;i++) 
		{ 
			if(IsClientInGame(i)) 
			{
				StopSound(i, SNDCHAN_BODY, "npc/fast_zombie/breathe_loop1.wav");
			}
		}  
	}
}

public Action:PedobearSpawn(client, args)
{
	if(client > 0)
	{
		if(!PedobearAttack)
		{
			PedobearAttack = true;
			SetConVarFloat(FindConVar("tf_halloween_bot_attack_range"), 125.0);
			
			new userid = GetClientUserId(client);
			CreateTimer(0.1, PedobearSpawn_Post, userid);
		}
		else
		{
			PrintToChat(client, "[SM] You can't spawn more than one Pedobear");
		}
	}
	else
	{
		ReplyToCommand(client, "Nick: Is this some kind of sick joke?");
	}
}

public Action:PedobearSpawn_Post(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(client);
	if(IsValidClient(client))
	{
		if(!SetTeleportEndPoint(client))
		{
			PrintToChat(client, "[SM] Could not find spawn point.");
			return Plugin_Handled;
		}
		new entity = CreateEntityByName("headless_hatman");
		if(IsValidEntity(entity))
		{
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
			DispatchSpawn(entity);
			g_pos[2] -= 10.0;
			TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
			
			new ref = EntIndexToEntRef(entity);
			
			CreateTimer(1.0, PedobearSprite, ref);
			CreateTimer(5.0, PedobearModel, ref);
		}
	}
	return Plugin_Handled;
}

public Action:PedoKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(PedobearAttack)
	{
		decl String:WeaponName[256];
		GetEventString(event, "weapon", WeaponName, 256);
		if(StrEqual(WeaponName, "headtaker"))
		{
			SetEventString(event, "weapon", "warrior_spirit");
		}
	}
}

public Action:DisablePedo2(Handle:event, const String:name[], bool:dontBroadcast)
{
	RemovePedoSound();
}

public Action:DisablePedo(Handle:event, const String:name[], bool:dontBroadcast)
{
	PedobearAttack = false;
	RemovePedoSound();
}

public OnMapEnd()
{
	PedobearAttack = false;
}

public Action:HHH_Sound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(PedobearAttack)
	{
		if(StrContains(sample, "halloween_boss", false) != -1)
		{
			return Plugin_Handled;
		}
		else if(StrContains(sample, "footsteps", false) != -1)
		{
			if(StrContains(sample, "giant", false) != -1)
			{
				return Plugin_Handled;
			}
			return Plugin_Continue;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "prop_dynamic", false))
	{
		new ref = EntIndexToEntRef(entity);
		CreateTimer(0.1, modelz, ref);
	}
}

public Action:modelz(Handle:timer, any:ref)
{
	if(PedobearAttack)
	{
		new entity = EntRefToEntIndex(entity);
		
		if(IsValidEntity(entity))
		{
			decl String:model[256];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model,"models/weapons/c_models/c_bigaxe/c_bigaxe.mdl"))
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 0, 0, 0, 0);
			}
		}
	}
}

public Action:PedobearDie(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(PedobearAttack)
	{
		RemovePedobear();
		CreateTimer(1.0, DisablePedobera);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:DisablePedobera(Handle:timer)
{
	PedobearAttack = false;
	RemovePedoSound();
}

public Action:Hook_SetTransmit(entity, client) 
{ 
	return Plugin_Handled; 
}  

public OnMapStart()
{
	Precache();
}

Precache()
{
	PrecacheGeneric("materials/pedobear/pedobear_animated_v2.vmt", true);
	PrecacheGeneric("materials/pedobear/pedobear_animated_v2.vtf", true);
	
	PrecacheDecal("materials/pedobear/pedobear_animated_v2.vmt", true);
	PrecacheDecal("materials/pedobear/pedobear_animated_v2.vtf", true);
	
	PrecacheGeneric("materials/pedobear/pedobear_animated_v2.vmt");
	PrecacheGeneric("materials/pedobear/pedobear_animated_v2.vtf");
	
	PrecacheDecal("materials/pedobear/pedobear_animated_v2.vmt");
	PrecacheDecal("materials/pedobear/pedobear_animated_v2.vtf");
	
	AddFileToDownloadsTable("materials/pedobear/pedobear_animated_v2.vmt");
	AddFileToDownloadsTable("materials/pedobear/pedobear_animated_v2.vtf");
	
	PrecacheSound("npc/fast_zombie/breathe_loop1.wav");
	PrecacheSound("sound/npc/fast_zombie/breathe_loop1.wav");
	
	PedobearAttack = false;
	
	PrecacheModel("models/player/soldier.mdl", true);
}

public Action:PedobearSpawn_SPR(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Handled;
	}
	g_pos[2] += 50.0;
	new ent = CreateEntityByName("env_sprite_oriented");
	if (ent)
	{
		DispatchKeyValue(ent, "model", "materials/pedobear/pedobear_animated_v2.vmt");
		DispatchKeyValue(ent, "classname", "env_sprite_oriented");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "0.1");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", "Pedobear_Sprite");
		DispatchSpawn(ent);
		
		TeleportEntity(ent, g_pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Continue;
}

public Action:PedobearSprite(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if(IsValidEntity(entity))
	{
		new Float:vOrigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);
		vOrigin[2] += 1.0;
		new ent = CreateEntityByName("env_sprite_oriented");
		if (ent)
		{
			DispatchKeyValue(ent, "model", "materials/pedobear/pedobear_animated_v2.vmt");
			DispatchKeyValue(ent, "classname", "env_sprite_oriented");
			DispatchKeyValue(ent, "spawnflags", "1");
			DispatchKeyValue(ent, "scale", "0.1");
			DispatchKeyValue(ent, "rendermode", "1");
			DispatchKeyValue(ent, "rendercolor", "255 255 255");
			DispatchKeyValue(ent, "targetname", "Pedobear_Sprite");
			DispatchSpawn(ent);
			
			TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);
			Pedobear = ent;
			Pedobear_Target = entity;
		}
	}
}

public Action:PedobearModel(Handle:timer, any:ref)
{
	new HHHE = EntRefToEntIndex(ref);
	if(IsValidEntity(HHHE))
	{
		SetEntityModel(HHHE, "models/player/soldier.mdl");
		if(Pedobear_Sound_B)
		{
			for(new i=1;i<=MaxClients;i++) 
			{ 
				if(IsClientInGame(i))
				{
					EmitSoundToClient(i, "npc/fast_zombie/breathe_loop1.wav", HHHE, SNDCHAN_BODY, SNDLEVEL_TRAFFIC);
				}
			}
		}
	}
}
//
public OnGameFrame()
{
	if(PedobearAttack && IsValidEntity(Pedobear_Target))
	{
		decl Float:vOrigin[3];
		GetEntPropVector(Pedobear_Target, Prop_Send, "m_vecOrigin", vOrigin);
		vOrigin[2] += 53.0;
		TeleportEntity(Pedobear, vOrigin, NULL_VECTOR, NULL_VECTOR);
	}
}

stock RemovePedobear()
{
	if(IsValidEntity(Pedobear))
	{
		AcceptEntityInput(Pedobear, "Kill");
		SetConVarFloat(FindConVar("tf_halloween_bot_attack_range"), pedobear_range_original);
	}
}

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

stock bool:IsValidClient(client) 
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client)) 
        return false; 
     
    return true; 
} 