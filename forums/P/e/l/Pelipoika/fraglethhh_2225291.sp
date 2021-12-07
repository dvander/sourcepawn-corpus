#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>

#define HHH				"models/bots/headless_hatman.mdl"
#define AXE				"models/weapons/c_models/c_bigaxe/c_bigaxe.mdl"
#define SND_LAUGH		"Halloween.HeadlessBossLaugh"
#define SND_DYING		"Halloween.HeadlessBossDying"
#define SND_DEATH		"Halloween.HeadlessBossDeath"
#define SND_PAIN		"Halloween.HeadlessBossPain"
#define SND_BOO			"Halloween.HeadlessBossBoo"
#define SND_ALERT		"Halloween.HeadlessBossAlert"
#define SND_ATTACK		"Halloween.HeadlessBossAttack"
#define SND_SPAWN		"Halloween.HeadlessBossSpawn"
#define SND_SPAWNRUMBLE	"Halloween.HeadlessBossSpawnRumble"
#define SND_FOOT		"Halloween.HeadlessBossFootfalls"
#define SND_AXEHITFLESH	"Halloween.HeadlessBossAxeHitFlesh"
#define SND_AXEHITWORLD	"Halloween.HeadlessBossAxeHitWorld"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Horsemann",
	author = "FlaminSarge",
	description = "Be the Horsemann",
	url = "http://forums.alliedmods.net/showthread.php?t=166819"
}

new bool:g_IsModel[MAXPLAYERS+1] = { false, ... };
new bool:g_bIsTP[MAXPLAYERS+1] = { false, ... };
new bool:g_bIsHHH[MAXPLAYERS + 1] = { false, ... };
new g_iHHHParticle[MAXPLAYERS + 1][3];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_fbehhh", Command_Horsemann, ADMFLAG_ROOT, "It's a good time to run - turns <target> into a Horsemann");
	
	AddNormalSoundHook(HorsemannSH);
	
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_Death,  EventHookMode_Post);
}

public OnClientPutInServer(client)
{
	OnClientDisconnect_Post(client);
}

public OnClientDisconnect_Post(client)
{
	if(g_bIsHHH[client])
	{
		g_IsModel[client] = false;
		g_bIsTP[client] = false;
		g_bIsHHH[client] = false;
		ClearHorsemannParticles(client);
	}
}

public OnPluginEnd()
{
	for (new client = 1; client <= MaxClients; client++)
		if(IsValidClient(client))
			ClearHorsemannParticles(client);
}

public OnMapStart()
{
	PrecacheModel(HHH, true);
	PrecacheModel(AXE, true);
	PrecacheSound("player/footsteps/giant1.wav", true);
	PrecacheSound("player/footsteps/giant2.wav", true);
	
	PrecacheScriptSound(SND_LAUGH);
	PrecacheScriptSound(SND_DYING);
	PrecacheScriptSound(SND_DEATH);
	PrecacheScriptSound(SND_PAIN);
	PrecacheScriptSound(SND_BOO);
	PrecacheScriptSound(SND_ALERT);
	PrecacheScriptSound(SND_ATTACK);
	PrecacheScriptSound(SND_SPAWN);
	PrecacheScriptSound(SND_SPAWNRUMBLE);
	PrecacheScriptSound(SND_FOOT);
	PrecacheScriptSound(SND_AXEHITFLESH);
	PrecacheScriptSound(SND_AXEHITWORLD);
	
	PrecacheSound("ui/halloween_boss_defeated_fx.wav");
	PrecacheSound("vo/halloween_boss/knight_dying.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh01.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh02.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh03.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh04.wav");
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_bIsHHH[client])
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		
		RemoveModel(client);
		ClearHorsemannParticles(client);
	}
	g_bIsHHH[client] = false;
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new deathflags = GetEventInt(event, "death_flags");
	
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsHHH[client])
		{
			ClearHorsemannParticles(client);

			EmitGameSoundToAll(SND_DYING);
			EmitGameSoundToAll(SND_DEATH);
			
			SetVariantInt(0);
			AcceptEntityInput(client, "SetForcedTauntCam");
			
			RemoveModel(client);
			
			g_bIsHHH[client] = false;
		}
	}
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);

		g_IsModel[client] = true;
	}
}

public Action:RemoveModel(client)
{
	if (IsValidClient(client) && g_IsModel[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		g_IsModel[client] = false;
	}
}

stock ClearHorsemannParticles(client)
{
	TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 0.0);
	TE_ParticleToAll("halloween_boss_death", _, _, _, client);
	
	for (new i = 0; i < 3; i++)
	{
		new ent = EntRefToEntIndex(g_iHHHParticle[client][i]);
		if (ent > MaxClients && IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
		g_iHHHParticle[client][i] = INVALID_ENT_REFERENCE;
	}
}

stock DoHorsemannParticles(client)
{
	ClearHorsemannParticles(client);
	new lefteye = MakeParticle(client, "halloween_boss_eye_glow", "lefteye");
	if (IsValidEntity(lefteye))
	{
		g_iHHHParticle[client][0] = EntIndexToEntRef(lefteye);
	}
	new righteye = MakeParticle(client, "halloween_boss_eye_glow", "righteye");
	if (IsValidEntity(righteye))
	{
		g_iHHHParticle[client][1] = EntIndexToEntRef(righteye);
	}
	
	TE_ParticleToAll("ghost_pumpkin", _, _, _, client);
}

stock MakeParticle(client, String:effect[], String:attachment[])
{
	decl Float:pos[3];
	decl Float:ang[3];
	decl String:buffer[128];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	GetClientEyeAngles(client, ang);
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
	AcceptEntityInput(particle, "SetParent", client, particle, 0);
	if (attachment[0] != '\0')
	{
		SetVariantString(attachment);
		AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
	}
	Format(buffer, sizeof(buffer), "%s_%s%d", effect, attachment, particle);
	DispatchKeyValue(particle, "targetname", buffer);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", client);
	AcceptEntityInput(particle, "Start");
	return particle;
}

public Action:Command_Horsemann(client, args)
{
	decl String:arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		MakeHorsemann(target_list[i]);
	}

	return Plugin_Handled;
}

MakeHorsemann(client)
{
	TF2_SetPlayerClass(client, TFClass_DemoMan);
	TF2_RegeneratePlayer(client);

	EmitGameSoundToAll(SND_SPAWN);
	EmitGameSoundToAll(SND_SPAWNRUMBLE);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_minigun", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, HHH);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
	DoHorsemannParticles(client);
	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_SetHealth(client, 1525);	//overheal, will seep down to normal max health... probably.
	
	static const Float:vecHHHMins[3] = {-25.505956, -38.176700, -11.582711}, Float:vecHHHMaxs[3] = {17.830757, 38.176841, 138.456878};

	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecHHHMins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecHHHMaxs);
	
	g_bIsHHH[client] = true;
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
	
	TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", 2.0);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveAxe(client);
}

stock GiveAxe(client)
{
	TF2_RemoveAllWearables(client);

	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_sword");
		TF2Items_SetItemIndex(hWeapon, 266);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 5);
		new String:weaponAttribs[256];
		//This is so, so bad and I am so very, very sorry, but TF2Attributes will be better.
		Format(weaponAttribs, sizeof(weaponAttribs), "26 ; 1325 ; 5 ; 1.45 ; 107 ; 1.25 ; 402 ; 1 ; 109 ; 0.1 ; 69 ; 0.75 ; 13 ; 0.9");
		new String:weaponAttribsArray[32][32];
		new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
		if (attribCount > 0) 
		{
			TF2Items_SetNumAttributes(hWeapon, attribCount/2);
			new i2 = 0;
			for (new i = 0; i < attribCount; i+=2) 
			{
				TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
				i2++;
			}
		} 
		else 
		{
			TF2Items_SetNumAttributes(hWeapon, 0);
		}
		new weapon = TF2Items_GiveNamedItem(client, hWeapon);
		EquipPlayerWeapon(client, weapon);

		CloseHandle(hWeapon);
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", PrecacheModel(AXE));
		SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", PrecacheModel(AXE), _, 0);
	}	
}

stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

public Event_PlayerHurt(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(iVictim != iAttacker && iVictim >= 1 && iVictim <= MaxClients && IsClientInGame(iVictim) && iAttacker >= 1 && iAttacker <= MaxClients && IsClientInGame(iAttacker))
	{
		if(IsPlayerAlive(iVictim) && GetEventInt(hEvent, "health") > 0 && !TF2_IsPlayerInCondition(iVictim, TFCond_Dazed) && g_bIsHHH[iAttacker])
		{
			TF2_StunPlayer(iVictim, 1.5, _, TF_STUNFLAGS_GHOSTSCARE);
		}
	}
}

public Action:HorsemannSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!g_bIsHHH[entity]) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		switch(GetRandomInt(1, 2))
		{
			case 1:	Format(sample, sizeof(sample), "player/footsteps/giant1.wav");
			case 2:	Format(sample, sizeof(sample), "player/footsteps/giant2.wav");
		}
		EmitSoundToAll(sample, entity);

		new Float:clientPos[3];
		GetClientAbsOrigin(entity, clientPos);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			if (!IsPlayerAlive(i)) continue;
			if (i == entity) continue;
			
			new Float:zPos[3];
			GetClientAbsOrigin(i, zPos);

			new Float:flDistance = GetVectorDistance(clientPos, zPos);
			
			if (flDistance < 500.0)
			{
				ScreenShake(i, FloatAbs((500.0 - flDistance) / (500.0 - 0.0) * 15.0), 5.0, 1.0);
			}
		}
	
		return Plugin_Changed;
	}
	if(StrContains(sample, "knight_axe_miss", false) != -1 || StrContains(sample, "knight_axe_hit", false) != -1)
	{
		new Float:clientPos[3];
		GetClientAbsOrigin(entity, clientPos);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			if (!IsPlayerAlive(i)) continue;

			new Float:zPos[3];
			GetClientAbsOrigin(i, zPos);

			new Float:flDistance = GetVectorDistance(clientPos, zPos);
			
			if (flDistance < 500.0)
			{
				ScreenShake(i, FloatAbs((500.0 - flDistance) / (500.0 - 0.0) * 15.0), 5.0, 1.0);
			}
		}
	}
	else if(StrContains(sample, "sword_swing", false) != -1 || StrContains(sample, "cbar_miss", false) != -1)
	{
		switch(GetRandomInt(1, 4))
		{
			case 1:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_attack01.wav");
			case 2:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_attack02.wav");
			case 3:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_attack03.wav");
			case 4:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_attack04.wav");
		}
		EmitSoundToAll(sample, entity, SNDCHAN_VOICE, 95, 0, 1.0, 100);
		TE_ParticleToAll("ghost_pumpkin", _, _, _, entity);
		
		return Plugin_Changed;
	}
	else if(StrContains(sample, "vo/", false) != -1)
	{
		if(StrContains(sample, "_medic0", false) != -1)
		{
			Format(sample, sizeof(sample), "vo/halloween_boss/knight_alert.wav");
			return Plugin_Changed;
		}
		else if(StrContains(sample, "pain", false) != -1)
		{
		//	Format(sample, sizeof(sample), "Halloween.HeadlessBossPain");
			switch(GetRandomInt(1, 3))
			{
				case 1:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_pain01.wav");
				case 2:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_pain02.wav");
				case 3:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_pain03.wav");
			}
			return Plugin_Changed;
		}
		else
		{
			switch(GetRandomInt(1, 4))
			{
				case 1:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_laugh01.wav");
				case 2:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_laugh02.wav");
				case 3:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_laugh03.wav");
				case 4:	Format(sample, sizeof(sample), "vo/halloween_boss/knight_laugh04.wav");
			}
			
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
//	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

stock TF2_RemoveAllWearables(client)
{
	new wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}

TE_ParticleToAll(String:Name[], Float:origin[3]=NULL_VECTOR, Float:start[3]=NULL_VECTOR, Float:angles[3]=NULL_VECTOR, entindex=-1,attachtype=-1,attachpoint=-1, bool:resetParticles=true)
{
    // find string table
    new tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    
    // find particle index
    new String:tmp[256];
    new count = GetStringTableNumStrings(tblidx);
    new stridx = INVALID_STRING_INDEX;
    new i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }
    
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);    
    TE_SendToAll();
}

stock ScreenShake(target, Float:intensity=30.0, Float:duration=10.0, Float:frequency=3.0)
{
    new Handle:bf; 
    if ((bf = StartMessageOne("Shake", target)) != INVALID_HANDLE)
    {
        BfWriteByte(bf, 0);
        BfWriteFloat(bf, intensity);
        BfWriteFloat(bf, duration);
        BfWriteFloat(bf, frequency);
        EndMessage();
    }
}