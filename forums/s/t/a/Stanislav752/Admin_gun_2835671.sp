#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <banning>




#define FFADE_IN            0x0001
#define FFADE_OUT            0x0002
#define FFADE_MODULATE    0x0004
#define FFADE_STAYOUT    0x0008
#define FFADE_PURGE        0x0010
#define ADD_OUTPUT "OnUser1 !self:Kill::1.5:1"




#define BBAGMDL "models/props/cs_office/Water_bottle.mdl"




public Plugin:myinfo = 
{
	name = "gun for admins",
	author = "Stanislav752",
	description = "gun for admins",
	version = SOURCEMOD_VERSION,
};


new bool:Wgunb[MAXPLAYERS+1]; 
new bool:inoss[MAXPLAYERS+1];


new ragdoll[MAXPLAYERS+1];

new bool:moved[MAXPLAYERS+1];


new ttime[MAXPLAYERS+1];



new const Float:g_fMinS[3] = {-24.0, -24.0, -24.0};
new const Float:g_fMaxS[3] = {24.0, 24.0, 24.0};
new bool:bbshot[MAXPLAYERS+1];


public OnPluginStart()
{
	RegConsoleCmd("sm_gun", GetGun, "give gun");
	
	
	
	
	HookEvent("player_hurt", player_hurt, EventHookMode_Pre);
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_death", player_death);
	HookEvent("weapon_fire", weapon_fire);
	
	HookEvent("bullet_impact", bullet_impact);
	
	
	AddTempEntHook("Shotgun Shot", Hook_FireBullets);
	AddTempEntHook("World Decal", OnWorldDecal);
}



public OnMapStart()
{

	CreateTimer(0.2, move_ragdoll, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}





public Action:Hook_FireBullets(const String:te_name[], const Players[], numClients, Float:delay)
{
	new client = TE_ReadNum("m_iPlayer") + 1;
	decl String:player_weapon[32];
	GetClientWeapon(client, player_weapon, sizeof(player_weapon));
	
	
	
	if(Wgunb[client] == true)
	{
	
		if(StrEqual(player_weapon, "weapon_m3", false))
		{
			PrecacheSound("weapons/glock/glock18-1.wav");
			PrecacheSound("weapons/m3/m3_pump.wav");
			
			
			EmitSoundToAll("weapons/glock/glock18-1.wav", client, SNDCHAN_WEAPON, SNDLEVEL_ROCKET, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
			EmitSoundToAll("weapons/glock/glock18-1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR,
			NULL_VECTOR, true, 0.0);
			
			bbshot[client] = true;
			
			CreateTimer(0.25, playb, client);
			
			
			
			
		}
	}
	
}




public Action:playb(Handle:timer, any:client)
{
	
	EmitSoundToAll("weapons/m3/m3_pump.wav", client, SNDCHAN_WEAPON, SNDLEVEL_ROCKET, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	EmitSoundToAll("weapons/m3/m3_pump.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR,
	NULL_VECTOR, true, 0.0);
	
	bbshot[client] = false;
}







public Action:player_spawn(Handle:event, const String:name[], bool:silent) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Wgunb[client] == true)
	{
		Wgunb[client] = false;
	}
	inoss[client] = false;
	Wgunb[client] = false;
	bbshot[client] = false;
	ttime[client] = 0;
	
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
	SetEntityRenderMode(client, RenderMode:RENDER_NORMAL);
	
	
}


public Action:GetGun(client, args)
{
	if(Wgunb[client] == false)
	{
		new flags = GetUserFlagBits(client); 
		if(flags & ADMFLAG_BAN || flags & ADMFLAG_SLAY || flags & ADMFLAG_ROOT)
		{
			
			if(IsPlayerAlive(client))
			{
			
				new w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				
				
				
				SetEntityHealth(client, 1300);
				GivePlayerItem(client, "weapon_p228");
				GivePlayerItem(client, "weapon_knife");
				GivePlayerItem(client, "weapon_m3");
				
				FakeClientCommand(client, "use weapon_p228");
				FakeClientCommand(client, "use weapon_p228");
				
				
				Wgunb[client] = true;
			}
			else
			{
				new Float:crds[3];
				
				GetClientAbsOrigin(client, crds);
				
				CS_RespawnPlayer(client);
				
				
				new w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
				if(w_index > 0) CS_DropWeapon(client, w_index, true, false);
				
				
				
				SetEntityHealth(client, 1300);
				
				GivePlayerItem(client, "weapon_p228");
				GivePlayerItem(client, "weapon_knife");
				GivePlayerItem(client, "weapon_m3");
				
				FakeClientCommand(client, "use weapon_p228");
				
				
				Wgunb[client] = true;
				
				
				
				
				TeleportEntity(client, crds, NULL_VECTOR, NULL_VECTOR);
			}
			
			
		}
		else
		{
			
			PrintToChat(client, "У вас нет доступа");
		}
	}
	else 
	{
		Wgunb[client] = false;
		GivePlayerItem(client, "weapon_knife");
		FakeClientCommand(client, "use weapon_knife");
		ClientCommand(client, "stop");
		// ServerCommand("tv_stoprecord");
		SetEntityHealth(client, 100);
		// ServerCommand("sm plugins load vip");
	}
	
}



public Action OnWorldDecal(const char[] te_name, const Players[], int numClients, float delay)
{
    float vecOrigin[3];
    int nIndex = TE_ReadNum("m_nIndex");
	
	for(new i=1; i<MaxClients; i++)
	{
		if(Wgunb[i] == true && bbshot[i] == true)
		{
			char sDecalName[64];

			TE_ReadVector("m_vecOrigin", vecOrigin);
			GetDecalName(nIndex, sDecalName, sizeof(sDecalName));
		   
			if(StrContains(sDecalName, "decals/blood") == 0 && StrContains(sDecalName, "_subrect") != -1)
			{
				return Plugin_Handled;
			}
		}
	}

    return Plugin_Continue;
}

stock int GetDecalName(int index, char[] sDecalName, int maxlen)
{
    int table = INVALID_STRING_TABLE;
   
    if (table == INVALID_STRING_TABLE)
        table = FindStringTable("decalprecache");
   
    return ReadStringTable(table, index, sDecalName, maxlen);
}











public Action:weapon_fire(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// PrintToChatAll("%d", client);
	
	
	if(Wgunb[client] == true)
	{
		
		decl String:weapon_name[64]; 
		GetEventString(event, "weapon", weapon_name, sizeof(weapon_name));
		
		if(strcmp(weapon_name, "p228", false) == 0)
		{
			Shake(client, 15.0, 0.4); // float:amplitude, float:duration
			
		}
		else if(strcmp(weapon_name, "m3", false) == 0)
		{
			
			new w_index = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			
			
			if(GetEntProp(w_index, Prop_Send, "m_iClip1") > 0)
			{
				Beanbag(client);
			}
			
		}
	}
	
	
	return Plugin_Continue;

}














Beanbag(client) 
{
	
	static Float:fPos[3], Float:fAng[3], Float:fVel[3], Float:fPVel[3];
	GetClientEyePosition(client, fPos);
	
	GetClientEyeAngles(client, fAng);
	if (IsClientIndex(GetTraceHullEntityIndex(fPos, client)))
		return;
	
	decl Float:v[3];
	GetLookPos(client, v);
	PrecacheModel(BBAGMDL);
	
	
	new entity = CreateEntityByName("flashbang_projectile");
	if ((entity != -1) && DispatchSpawn(entity)) {
		SetEntityModel(entity, BBAGMDL);
		
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.8);
		
		
		new String:buf2[64];
		new Float:seconds2 = 1.5;
		Format(buf2, sizeof(buf2), "OnUser1 !self:kill::%f:1", seconds2); 
		SetVariantString(buf2); 
		AcceptEntityInput(entity, "AddOutput"); 
		AcceptEntityInput(entity, "FireUser1");
		DispatchKeyValue(entity, "OnUser1", "!self:kill::1.5:1");
		
		
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		AcceptEntityInput(entity, "AddOutput");
		
		
		GetClientEyeAngles(client, fAng);
		GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fVel, 6500.0);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVel);
		AddVectors(fVel, fPVel, fVel);
		SetEntPropVector(entity, Prop_Data, "m_vecAngVelocity", {5877.4, 0.0, 0.0});
		SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.3);
	 	// PushArrayCell(g_hLethalArray, entity);
		TeleportEntity(entity, fPos, v, fVel);
		
		SDKHook(entity, SDKHook_StartTouch, StartTouch_bb);
		
	}
	
	
	
	
}



public StartTouch_bb(entity, client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client)) 
	{
		return;
	}
	
	Shake(client, 420.0, 2.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 100.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 1.5);
	
	
	
	
	new rdrop = GetRandomInt(1, 10);
	if(rdrop < 5)
	{
		FakeClientCommand(client, "drop");
		
		
		new owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
		
		
		
		decl String:buf[32];
		
		
		
		
		new us = GetClientUserId(client);
		Format(buf, sizeof(buf),"sm_slap #%d 0", us);
		ServerCommand(buf);
		
	}
	
	
}
















public Action:player_hurt(Handle:event, const String:name[], bool:silent) 
{
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	decl String:weapon_name[64]; 
	GetEventString(event, "weapon", weapon_name, sizeof(weapon_name));
	
	
	moved[client] = false;
	
	
	if(Wgunb[attackerId] == true)
	{
		new hp = 0;
		
		
		
		hp = GetClientHealth(client);
		hp += 10;
		
		
		
		if(StrEqual(weapon_name,"p228"))
		{	
			if(GetEventInt(event, "hitgroup") == 1)
			{
				
				SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 255.0);
				SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 5.0);
				
				
				
				FakeClientCommand(client, "kill");
				
			}
			else if(GetEventInt(event, "hitgroup") == 2)
			{
				
				
				Shake(client, 20.0, 1.5); // float:amplitude, float:duration
				SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 55.0);
				SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 1.0);
				
				
				new oss = GetRandomInt(1, 10);
				if(oss < 6)
				{
					
					FakeClientCommand(client, "drop");
					FakeClientCommand(client, "drop");
					
					LegBrokenF(client, 2);
				}
				
			}
			else if(GetEventInt(event, "hitgroup") == 3)
			{
				
				PerformFade(client, 1, 100, false); // in(time, alpha, bool:in)
				PerformFade(client, 1000, 255, true); // out()
				Shake(client, 6.0, 2.5); // float:amplitude, float:duration
				FakeClientCommand(client, "drop");
				
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.6);
				
				
				
				Shake(client, 25.0, 3.0); // float:amplitude, float:duration
				
				
				SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 75.0);
				SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 1.5);
				
				
				
				new oss = GetRandomInt(1, 10);
				if(oss < 9)
				{
					
					FakeClientCommand(client, "drop");
					FakeClientCommand(client, "drop");
					
					
					
					
					LegBrokenF(client, 3);
				}
				
			}
			else if(GetEventInt(event, "hitgroup") == 4)
			{
				PerformFade(client, 1000, 255, true); // out()
				Shake(client, 3.0, 0.5); // float:amplitude, float:duration
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.2);
				
				FakeClientCommand(client, "drop");
			}
			else if(GetEventInt(event, "hitgroup") == 5)
			{
				PerformFade(client, 1000, 255, true); // out()
				Shake(client, 3.0, 0.5); // float:amplitude, float:duration
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.2);
				
			}
			
			else if(GetEventInt(event, "hitgroup") == 6)
			{
				PerformFade(client, 1000, 255, true); // out()
				Shake(client, 3.0, 0.5); // float:amplitude, float:duration
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.2);
				
			}
			else if(GetEventInt(event, "hitgroup") == 7)
			{
				PerformFade(client, 1000, 255, true); // out()
				Shake(client, 3.0, 0.5); // float:amplitude, float:duration
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.2);
				
			}
			
			
			// PrintToChatAll("hp %d", hp);
			
			if(hp < 17 && IsClientInGame(client))
			{
				FakeClientCommand(client, "kill");
				
				
				// BanClient(client, 0, BANFLAG_AUTHID, "BANNED");
				// ServerCommand("writeid");
				
				
				decl String:buf[32];	
				new us = GetClientUserId(client);
				
				
				Format(buf, sizeof(buf),"sm_ban #%d 0 banned", us);	
				
				PrintToChatAll("%s", buf);
				
				PrintToChatAll("%d", GetClientUserId(attackerId));
				
				FakeClientCommand(attackerId, buf);
				
				
				
				
				
				
				
				
				// CreateTimer(5.0, banT, client);
				
			}
			else
			{
				SetEntityHealth(client, hp);
			}
			
			
		
			
			
			
			
			
			
			
			
			
			return Plugin_Changed;
		}
		else if(StrEqual(weapon_name,"m3"))
		{
			new old_health = GetEntProp(client, Prop_Send, "m_iHealth") + GetEventInt(event, "dmg_health");
			// if (old_health > 20) SetEntData(client, FindSendPropOffs("CCSPlayer", "m_iHealth"), old_health - 20, 4, true);
			
			// PrintToChatAll("hp1 %d", old_health);
			
			
			
			new rd = GetRandomInt(1, 50);
			
			if(rd > 2)
			{
				SetEntData(client, FindSendPropOffs("CCSPlayer", "m_iHealth"), old_health, 4, true);
			}
			else
			{
				old_health -= 5;
				
				if(old_health > 1)
				{
					SetEntData(client, FindSendPropOffs("CCSPlayer", "m_iHealth"), old_health, 4, true);
				}
				else
				{
					FakeClientCommand(client, "kill");
					
					decl String:buf[32];	
					new us = GetClientUserId(client);
					Format(buf, sizeof(buf),"sm_ban #%d 0 banned", us);	
					FakeClientCommand(attackerId, buf);
				}
			}
			
		}
	}
	else
	{
		return Plugin_Continue;
	}
	return Plugin_Changed;
}


















public Action:player_death(Handle:event, const String:name[], bool:silent) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	
	
	
	if(inoss[client] == true)
	{
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
			
		pos[2] -= 80;
		TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
		
		
		ragdoll[client] = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
			
		if(ragdoll[client] > 0)
		{
			RemoveEntity(ragdoll[client]);
		}
		
		
	}
	
	
	// PrintToChatAll("client= %d", client);
	
	// PrintToChatAll("attackerId= %d", attackerId);
	
	//PrintToChatAll("wg %d", Wgunb[attackerId]);
	
	
	if(Wgunb[attackerId] == true)
	{
		
		decl String:wpn[16];
		GetClientWeapon(attackerId, wpn, sizeof(wpn));
		
		
		// PrintToChatAll("1");
		
		if(StrEqual(wpn, "weapon_knife"))
		{
			ChangeClientTeam(client, 1);
		}
	}
	
	
	
	
}


/*
public Action:banT(Handle:timer, any:client)
{
	BanClient(client, 0, BANFLAG_AUTHID, "BANNED");
	
	
	
	ServerCommand("writeid");
	
	
	// PrintToChatAll("ban %d", client);
	
	
	
}

*/



public Action:bullet_impact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	
	
	
	
	
	if(Wgunb[client] == true)
	{
		new Float:x = GetEventFloat(event, "x");
		new Float:y = GetEventFloat(event, "y");
		new Float:z = GetEventFloat(event, "z");
		
		
		new Float:pos[3];
		new Float:imp[3];
		
		imp[0] = x;
		imp[1] = y;
		imp[2] = z;
		
		
		for(new i=1; i<=MaxClients; i++)
		{
			
			if(inoss[i] == true && IsEntInRangeOfPoint(ragdoll[i], 25.0, imp))
			{
				
				GetEntPropVector(ragdoll[i], Prop_Send, "m_vecOrigin", pos);
				
				new m_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
				new old_health = GetEntProp(i, Prop_Send, "m_iHealth");
				
				// PrintToChatAll("%d", ragdoll[i]);


				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.4);

				
				
				PerformFade(i, 1, 70, false); // in(time, alpha, bool:in)
				PerformFade(i, 1500, 255, true); // out()
				FakeClientCommand(i, "drop");
				FakeClientCommand(i, "drop");
				
				new hp = GetClientHealth(i);
				hp -= 15;
				
				
				Shake(i, 55.0, 5.0); // float:amplitude, float:duration
				SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 55.0);
				SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 1.0);
				
				SetEntData(i, m_iHealth, hp, 4, true);
					
					
				if(hp < 15 && IsClientInGame(i))
				{
					SetEntData(i, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
					FakeClientCommand(i, "kill");
					
					// PrintToChatAll("2");
					// CreateTimer(1.0, banT, i);
					
					// BanClient(i, 0, BANFLAG_AUTHID, "BANNED");
					
					decl String:buf[32];
					
					new us = GetClientUserId(i);
					
					
					Format(buf, sizeof(buf),"sm_ban #%d 0 banned", us);
					
					
					
					
					FakeClientCommand(client, buf);
					
					// ServerCommand(buf);
					
					// ServerCommand("writeid");
					
					
				}
			}
			
		}
	}
	
}





public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_JUMP)
	{
		if(inoss[client] == true)
		{
			return Plugin_Handled;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	
	
	
	if(Wgunb[client] == true)
	{
		if(buttons & IN_USE)
		{
			new tgt = GetClientOnAim(client);
			
			if(moved[tgt] == false)
			{
				if(GetClientTeam(tgt) == 2)
				{
					CS_SwitchTeam(tgt, 3);
					
					PrecacheModel("models/player/ct_gign.mdl",true);
					SetEntityModel(tgt, "models/player/ct_gign.mdl");
					
					
					
					
					moved[tgt] = true;
					
					
					
					
				}
				else if(GetClientTeam(tgt) == 3)
				{
					CS_SwitchTeam(tgt, 2);
					
					
					PrecacheModel("models/player/t_arctic.mdl",true);
					SetEntityModel(tgt, "models/player/t_arctic.mdl");
					
					
					moved[tgt] = true;
				}
				
			}
			
		}
		
	}
	
	
	
	
	
	
	
	
	
	
	// PrintToChat(client, "%d", buttons);
	
	return Plugin_Continue;
}



stock Shake(client, Float:flAmplitude, Float:flDuration)
{
	new Handle:hBf=StartMessageOne("Shake", client);
	if(hBf!=INVALID_HANDLE)
	
	BfWriteByte(hBf,  0);
	BfWriteFloat(hBf, flAmplitude);
	BfWriteFloat(hBf, 1.0);
	BfWriteFloat(hBf, flDuration);
	EndMessage();
}


stock PerformFade(iClient, duration, alpha, bool:inn)
{
    new Handle:hFadeClient = StartMessageOne("Fade", iClient);
    BfWriteShort(hFadeClient, duration);
    BfWriteShort(hFadeClient, 0);
    BfWriteShort(hFadeClient, (inn) ? (FFADE_PURGE|FFADE_IN):(FFADE_PURGE|FFADE_OUT|FFADE_STAYOUT));
    BfWriteByte(hFadeClient, 0);    // fade red
    BfWriteByte(hFadeClient, 0);    // fade green
    BfWriteByte(hFadeClient, 0);    // fade blue
    BfWriteByte(hFadeClient, alpha);    // fade alpha
    EndMessage();
}







stock LegBrokenF(victim, hitgroup)
{
	if(IsPlayerAlive(victim))
	{
		new Float:angsB[3];
		
		new m_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
		
		GetClientEyeAngles(victim, angsB);
		angsB[2] -= 60.0;
		
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
		
			
			
		if(IsPlayerAlive(victim) && inoss[victim] == false)
		{
			new Float:pos[3];
				
				
			if(hitgroup == 6)
			{
				GetClientAbsOrigin(victim, pos);
					
				pos[0] += 0.0;
				pos[2] += 0.0;
			}
			else if(hitgroup == 7)
			{
				GetClientAbsOrigin(victim, pos);
					
				pos[0] += 0.0;
				pos[2] += 0.0;
					
					
					
			}
			else if(hitgroup == 3)
			{
				GetClientAbsOrigin(victim, pos);
				

				// pos[0] -= 10.0;
				// pos[2] += 30.0;
				
				
				
				new r = GetRandomInt(1, 3);
				
				if(r < 3)
				{
				
					pos[0] -= 7.0;
					pos[1] += 5.0;
					pos[2] += 35.0;
				}
				else
				{
					pos[0] -= 7.0;
					pos[1] += 5.0;
					pos[2] += 45.0;
				}
				
				
			}
			else
			{
				GetClientAbsOrigin(victim, pos);
					
				pos[0] -= 2.0;
				pos[1] += 5.0;
				pos[2] += 10.0;
				
			}
				
			PrecacheModel("models/props/cs_office/file_box_p1b.mdl",true);
			
			
			
			
			new hp = GetClientHealth(victim);
			hp += 25;
			
			SetEntData(victim, m_iHealth, hp, 4, true);
				
				
			if(GetClientTeam(victim) == 2)
			{
				PrecacheModel("models/player/t_arctic.mdl",true);
				ragdoll[victim] = CreateEntityByName("prop_ragdoll");
				if(ragdoll[victim] != -1)
				{
					DispatchKeyValue(ragdoll[victim], "model", "models/player/t_arctic.mdl");
					DispatchSpawn(ragdoll[victim]);
					TeleportEntity(ragdoll[victim], pos, NULL_VECTOR, NULL_VECTOR);
					
					SetEntityModel(victim, "models/props/cs_office/file_box_p1b.mdl");
					
					SetEntityRenderMode(victim, RenderMode:RENDER_NONE);
					SetEntPropFloat(victim, Prop_Send, "m_flModelScale", 0.4);
					inoss[victim] = true;
				}
			}
			else if(GetClientTeam(victim) == 3)
			{
				PrecacheModel("models/player/ct_gign.mdl",true);
				ragdoll[victim] = CreateEntityByName("prop_ragdoll");
				if(ragdoll[victim] != -1)
				{
					DispatchKeyValue(ragdoll[victim], "model", "models/player/ct_gign.mdl");
					DispatchSpawn(ragdoll[victim]);
					TeleportEntity(ragdoll[victim], pos, NULL_VECTOR, NULL_VECTOR);
					
					SetEntityModel(victim, "models/props/cs_office/file_box_p1b.mdl");
				
					SetEntityRenderMode(victim, RenderMode:RENDER_NONE);
					SetEntPropFloat(victim, Prop_Send, "m_flModelScale", 0.4);
					inoss[victim] = true;
				}
			}
				
			// SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", 0.7);
		}
		
	}
	
	return 0;
	
	
}



stock Float:GetDistance(Float:pos1[3], Float:pos2[3]) //получает дистанцию между двух точек. (В 2д пространстве). 
{
	return SquareRoot(Pow(pos2[0] - pos1[0], 2.0) + Pow(pos2[1] - pos1[1], 2.0));
}

stock IsClientInRangeOfPoint(client, Float:radius, Float:cpos[3]) //проверяет предыдущей функцией, в радиусе ли игрок от определенной точки. 
{
	new Float:ppos[3];
	GetClientAbsOrigin(client, ppos);
	if(GetDistance(ppos, cpos) <= radius) return true;
	return false;
}


stock IsEntInRangeOfPoint(ent, Float:radius, Float:cpos[3]) //проверяет предыдущей функцией, в радиусе ли энт от определенной точки. 
{
	new Float:ppos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", ppos);
	if(GetDistance(ppos, cpos) <= radius) return true;
	return false;
}




public Action:move_ragdoll(Handle:timer)
{
	
	 for(new i = 1; i < MaxClients; i++)
	 {
		
		if(i > 0 && IsClientInGame(i) && inoss[i] == true)
		{
			
			if(IsPlayerAlive(i))
			{

				// if(leghitb[i] == true)
				// {
					
					
					new Float:pos[3];

						new Float:position[3];
				
					
					static Float:fPos[3], Float:fAng[3], Float:fVel[3], Float:fPVel[3];
					
					
				
					// TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					
					
					// SetEntityMoveType(ragdoll[i], MOVETYPE_VPHYSICS);
					
					
					GetClientEyePosition(i, fPos);
					GetClientEyeAngles(i, fAng);
					GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
					ScaleVector(fVel, 700.0);
					AddVectors(fVel, fPVel, fVel);
					
					
					
					GetEntPropVector(ragdoll[i], Prop_Send, "m_vecOrigin", position);
					
					
					GetClientAbsOrigin(i, pos);
					
					if(!IsClientInRangeOfPoint(i, 70.0, position))
					{
						
						
						pos[0] += 50.0;
						
						
						
						// pos[2] += 40.0;
						
						pos[2] += 15.0;
						
						
						
						
						
						
						
						SetEntData(i, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
						
						
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.4);
						
						
						if(ttime[i] > 8)
						{
							TeleportEntity(ragdoll[i], position, NULL_VECTOR, fVel);
							
							ttime[i] += 1;
						}
						else
						{
							TeleportEntity(ragdoll[i], pos, NULL_VECTOR, NULL_VECTOR);
						}
						
						
						
					}
	

			}
		}
		
		
	}
	
	return Plugin_Continue;
}



stock GetClientOnAim(client)
{
	// new int:target = GetClientOnAim(int:viewer_index);
	
	decl Float:origin[3], Float:angles[3];
	GetClientEyePosition(client, origin); 
	GetClientEyeAngles(client, angles);
	TR_TraceRayFilter(origin, angles, MASK_SOLID, RayType_Infinite, Filter, client);

	if (!TR_DidHit())
	return -1;

	new ent = TR_GetEntityIndex();
	TR_GetEndPosition(origin);
	if (ent > 0 && ent <= MaxClients)
	{
		return ent;
	}
	else return -1;
}

public bool:Filter(ent, mask, any:client)
{
    return client != ent;
}





GetTraceHullEntityIndex(Float:pos[3], xindex) {

	TR_TraceHullFilter(pos, pos, g_fMinS, g_fMaxS, MASK_SHOT, THFilter, xindex);
	return TR_GetEntityIndex();
}

public bool:THFilter(entity, contentsMask, any:data) {

	return IsClientIndex(entity) && (entity != data);
}

bool:IsClientIndex(index) {

	return (index > 0) && (index <= MaxClients);
}



stock GetLookPos(client, Float:v[3])
{
     decl Float:EyePosition[3], Float:EyeAngles[3], Handle:h_trace;
     GetClientEyePosition(client, EyePosition);
     GetClientEyeAngles(client, EyeAngles);
     h_trace = TR_TraceRayFilterEx(EyePosition, EyeAngles, MASK_SOLID, RayType_Infinite, GetLookPos_Filter, client);
     TR_GetEndPosition(v, h_trace);
     CloseHandle(h_trace);
}

public bool:GetLookPos_Filter(ent, mask, any:client)
{
      return client != ent;
}


