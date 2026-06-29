#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define DEBUG 0
#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define MOLOTOV 0
#define EXPLODE 1

//new g_sprite;
new ChargeLock[65];
new ReleaseLock[65];
new CurrentWeapon;
new ClipSize;
new ChargeEndTime[65];
new Handle:ClientTimer[65];

new Handle:sm_lw_lethalweapon 	= INVALID_HANDLE;
new Handle:sm_lw_lethaldamage 	= INVALID_HANDLE;
new Handle:sm_lw_lethalforce 	= INVALID_HANDLE;
new Handle:sm_lw_chargetime		= INVALID_HANDLE;
new Handle:sm_lw_shootonce		= INVALID_HANDLE;
new Handle:sm_lw_ff		= INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Lethal Weapon",
	author = "ztar",
	description = "If you equip sniper rifle, You can shoot chargeshot that causes huge explosion and burning.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

public OnPluginStart()
{
	sm_lw_lethalweapon = CreateConVar("sm_lw_lethalweapon","1", "Enable lethal weapon(0:OFF 1:ON 2:SIMPLE)", CVAR_FLAGS);
	sm_lw_lethaldamage = CreateConVar("sm_lw_lethaldamage","3000", "Damage of lethal weapon.", CVAR_FLAGS);
	sm_lw_lethalforce  = CreateConVar("sm_lw_lethalforce","800.0", "Force of lethal weapon.", CVAR_FLAGS);
	sm_lw_chargetime   = CreateConVar("sm_lw_chargetime","7", "Charge time to burst.", CVAR_FLAGS);
	sm_lw_shootonce	   = CreateConVar("sm_lw_shootonce","0", "Survivor can use it only once during round.", CVAR_FLAGS);
	sm_lw_ff = CreateConVar("sm_lw_ff","0", "Survivor can damage other survivors.", CVAR_FLAGS);
	HookEvent("player_spawn", Event_Player_Spawn);
	HookEvent("weapon_fire", Event_Weapon_Fire);
	HookEvent("bullet_impact", Event_Bullet_Impact);
	HookEvent("player_incapacitated", Event_Player_Incap, EventHookMode_Pre);
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Pre);
	HookEvent("player_death", Event_Player_Hurt, EventHookMode_Pre);
	HookEvent("infected_death", Event_Infected_Hurt, EventHookMode_Pre);
	HookEvent("infected_hurt", Event_Infected_Hurt, EventHookMode_Pre);
	HookEvent("round_end", Event_Round_End, EventHookMode_Pre);
	
	CurrentWeapon = FindSendPropOffs ("CTerrorPlayer", "m_hActiveWeapon");
	ClipSize 	  = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	
	InitCharge();
	
	AutoExecConfig(true, "sm_lethal_weapon");
}

public OnMapStart()
{
	InitPrecache();
}

public OnConfigsExecuted()
{
	InitPrecache();
}

InitCharge()
{
	/* Init charge parametor */
	new i;
	for (i = 1; i <= GetMaxClients(); i++)
	{
		ChargeEndTime[i] = 0;
		ReleaseLock[i] = 0;
		ChargeLock[i] = 0;
		ClientTimer[i] = INVALID_HANDLE;
	}
	for (i = 1; i <= GetMaxClients(); i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
				ClientTimer[i] = CreateTimer(0.5, ChargeTimer, i, TIMER_REPEAT);
		}
	}
}

InitPrecache()
{
	/* Precache model */
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel("models/props_junk/gascan001a.mdl", true);
	
	/* Precache sound */
	PrecacheSound("ambient/spacial_loops/lights_flicker.wav", true);
	PrecacheSound("level/startwam.wav", true);
	PrecacheSound("weapons/awp/gunfire/awp1.wav", true);
	PrecacheSound("animation/bombing_run_01.wav", true);
	
	/* Precache particle */
	PrecacheParticle("gas_explosion_main");
	PrecacheParticle("electrical_arc_01_cp0");
	PrecacheParticle("electrical_arc_01_system");
	
	/* Precache sprite */
///	g_sprite = PrecacheModel("materials/sprites/laser.vmt");
}

public Action:Event_Round_End(Handle:event, String:event_name[], bool:dontBroadcast)
{
	/* Timer end */
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (ClientTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(ClientTimer[i]);
			ClientTimer[i] = INVALID_HANDLE;
		}
		if(IsValidEntity(i) && IsClientInGame(i))
		{
			ChargeEndTime[i] = 0;
			ReleaseLock[i] = 0;
			ChargeLock[i] = 0;
		}
	}
}

public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Timer start */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && client <= GetMaxClients())
	{
		if(IsValidEntity(client) && IsClientInGame(client))
		{
			if (GetClientTeam(client) == 2)
			{
				if (ClientTimer[client] != INVALID_HANDLE)
					CloseHandle(ClientTimer[client]);
				ChargeLock[client] = 0;
				ClientTimer[client] = CreateTimer(0.5, ChargeTimer, client, TIMER_REPEAT);
			}
		}
	}
}

public Action:Event_Player_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Reset client condition */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ReleaseLock[client] = 0;
	ChargeEndTime[client] = RoundToCeil(GetGameTime()) + GetConVarInt(sm_lw_chargetime);
}

public Action:Event_Bullet_Impact(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(ReleaseLock[client])
	{
		decl Float:TargetPosition[3];
		
		TargetPosition[0] = GetEventFloat(event,"x");
		TargetPosition[1] = GetEventFloat(event,"y");
		TargetPosition[2] = GetEventFloat(event,"z");
		
		/* Explode effect */
		ExplodeMain(TargetPosition);
	}
	return Plugin_Continue;
}

public Action:Event_Infected_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(ReleaseLock[client])
	{
		decl Float:TargetPosition[3];
		new target = GetClientAimTarget(client, false);
		if(target < 0)
			return Plugin_Continue;
		GetEntityAbsOrigin(target, TargetPosition);
		
		/* Explode effect */
		EmitSoundToAll("animation/bombing_run_01.wav", target);
		ExplodeMain(TargetPosition);
		
		/* Reset lethal weapon lock */
		ReleaseLock[client] = 0;
	}
	return Plugin_Continue;
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	new dtype = GetEventInt(event, "type");
	if (client == 0) return Plugin_Continue;
        if (target == 0) return Plugin_Continue;
	#if DEBUG
	PrintToChatAll("[DEBUG][%d] Event_Player_Hurt",client);
	#endif
	if(ReleaseLock[client] && dtype != 268435464)
	{
		new health = GetEventInt(event,"health");
		new damage = GetConVarInt(sm_lw_lethaldamage);
		
		decl Float:AttackPosition[3];
		decl Float:TargetPosition[3];
		GetClientAbsOrigin(client, AttackPosition);
		GetClientAbsOrigin(target, TargetPosition);
		
		/* Beam effect */
//		new color[4] = {150, 150, 255, 255};
//		TE_SetupBeamPoints(TargetPosition, AttackPosition, g_sprite,
//							0, 0, 0, 1.0, 5.0, 5.0, 7, 0.0, color, 0);
//		TE_SendToAll();
		
		/* Explode effect */
		EmitSoundToAll("animation/bombing_run_01.wav", target);
		ExplodeMain(TargetPosition);
		
		/* Smash target */
		if(GetConVarInt(sm_lw_lethalweapon) != 2)
			Smash(client, target, GetConVarFloat(sm_lw_lethalforce), 1.5, 2.0);
		
		/* Deal lethal damage */
                if (GetClientTeam(client) == GetClientTeam(target) && GetConVarInt(sm_lw_ff) == 0)
                {
                ReleaseLock[client] = 0;
                }
                else
                {
		SetEntProp(target, Prop_Data, "m_iHealth", health - damage);
                ReleaseLock[client] = 0;
		}
		/* Reset lethal weapon lock */
	}
	return Plugin_Continue;
}

public Action:Event_Weapon_Fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ChargeEndTime[client] = RoundToCeil(GetGameTime()) + GetConVarInt(sm_lw_chargetime);
	
	if(ReleaseLock[client])
	{
		#if DEBUG
		PrintToChatAll("[DEBUG][%d] Fired Lethal Weapon", client);
		#endif
		PrintCenterText(client, " ");
		
		/* Flash screen */
		ScreenFade(client, 200, 200, 255, 255, 100, 1);
		
		/* Emit sound */
		EmitSoundToAll(
			"weapons/awp/gunfire/awp1.wav", client,
			SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL,
			125, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		
		/* Reset client condition */
		CreateTimer(0.2, ReleaseTimer, client, TIMER_HNDL_CLOSE);
		if(GetConVarInt(sm_lw_shootonce))
		{
			ChargeLock[client] = 1;
			PrintHintText(client, "Lethal weapon already fired in this round.");
		}
	}
}

public Action:ReleaseTimer(Handle:timer, any:client)
{
	/* Set ammo after using */
	new Weapon = GetEntDataEnt2(client, CurrentWeapon);
	new iAmmo = FindDataMapOffs(client,"m_iAmmo");
	SetEntData(Weapon, ClipSize, 0);
	SetEntData(client, iAmmo+8,  RoundToFloor(GetEntData(client, iAmmo+8)  / 2.0));
	SetEntData(client, iAmmo+32, RoundToFloor(GetEntData(client, iAmmo+32) / 2.0));
	SetEntData(client, iAmmo+36, RoundToFloor(GetEntData(client, iAmmo+36) / 2.0));
	
	/* Reset flags */
	ReleaseLock[client] = 0;
	ChargeEndTime[client] = RoundToCeil(GetGameTime()) + GetConVarInt(sm_lw_chargetime);
}

public Action:ChargeTimer(Handle:timer, any:client)
{
	StopSound(client, SNDCHAN_AUTO, "ambient/spacial_loops/lights_flicker.wav");
	if(!GetConVarInt(sm_lw_lethalweapon) || ChargeLock[client])
		return Plugin_Continue;
	if (!IsValidEntity(client) || !IsClientInGame(client))
	{
		ClientTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	/* Get data */
	new gt = RoundToCeil(GetGameTime());
	new ct = GetConVarInt(sm_lw_chargetime);
	new buttons = GetClientButtons(client);
	new WeaponClass = GetEntDataEnt2(client, CurrentWeapon);
	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);
	
	/* These weapon allow you to start charging */
	/* Now allowed:HuntingRifle, G3, Scout, AWP */
	if (!StrEqual(weapon, "weapon_sniper_military") &&
		!StrEqual(weapon, "weapon_sniper_awp") &&
		!StrEqual(weapon, "weapon_sniper_scout") &&
		!StrEqual(weapon, "weapon_hunting_rifle"))
//		!StrEqual(weapon, "weapon_pumpshotgun") &&
//		!StrEqual(weapon, "weapon_autoshotgun") &&
//		!StrEqual(weapon, "weapon_shotgun_spas") &&
//		!StrEqual(weapon, "weapon_shotgun_chrome") &&
//		!StrEqual(weapon, "weapon_rifle") &&
//		!StrEqual(weapon, "weapon_rifle_ak47") &&
//		!StrEqual(weapon, "weapon_rifle_desert") &&
//		!StrEqual(weapon, "weapon_rifle_sg552") &&
//		!StrEqual(weapon, "weapon_smg") &&
//		!StrEqual(weapon, "weapon_smg_silenced") &&
//		!StrEqual(weapon, "weapon_smg_mp5"))
	{
		StopSound(client, SNDCHAN_AUTO, "ambient/spacial_loops/lights_flicker.wav");
		ReleaseLock[client] = 0;
		ChargeEndTime[client] = gt + ct;
		return Plugin_Continue;
	}
	
	/* Ducked, not moving, not attacking, not incapaciated */
	new inCharge = ((GetEntityFlags(client) & FL_DUCKING) &&
					(GetEntityFlags(client) & FL_ONGROUND) &&
					!(buttons & IN_FORWARD) &&
					!(buttons & IN_MOVERIGHT) &&
					!(buttons & IN_MOVELEFT) &&
					!(buttons & IN_BACK) &&
					!(buttons & IN_ATTACK) &&
					!(buttons & IN_ATTACK2));
	
	/* If in charging, display charge bar */
	if(inCharge && GetEntData(WeaponClass, ClipSize))
	{
		if(ChargeEndTime[client] < gt)
		{
			/* Charge end, ready to fire */
			PrintCenterText(client, "***************** CHARGED *****************");
			if(ReleaseLock[client] != 1)
			{
				decl Float:pos[3];
				GetClientAbsOrigin(client, pos);
				EmitSoundToAll("level/startwam.wav", client);
				ShowParticle(pos, "electrical_arc_01_system", 5.0);
			}
			ReleaseLock[client] = 1;
			
		}
		else
		{
			/* Not charged yet. Display charge gauge */
			new i, j;
			new String:ChargeBar[50];
			new String:Gauge1[2] = "|";
			new String:Gauge2[2] = " ";
			new Float:GaugeNum = (float(ct) - (float(ChargeEndTime[client] - gt))) * (100.0/float(ct))/2.0;
			ReleaseLock[client] = 0;
			if(GaugeNum > 50.0)
				GaugeNum = 50.0;
			#if DEBUG
			PrintToChat(client, "[DEBUG] Charge meter=%.2f%%", GaugeNum);
			#endif
			for(i=0; i<GaugeNum; i++)
				ChargeBar[i] = Gauge1[0];
			for(j=i; j<50; j++)
				ChargeBar[j] = Gauge2[0];
			if(GaugeNum >= 15)
			{
				/* Gauge meter is 30% or more */
				decl Float:pos[3];
				GetClientAbsOrigin(client, pos);
				pos[2] += 45;
				ShowParticle(pos, "electrical_arc_01_cp0", 5.0);
				EmitSoundToAll("ambient/spacial_loops/lights_flicker.wav", client);
			}
			/* Display gauge */
			PrintCenterText(client, "           << CHARGE IN PROGRESS >>\n0%% %s %3.0f%%", ChargeBar, GaugeNum*2);
		}
	}
	else
	{
		/* Not matching condition */
		StopSound(client, SNDCHAN_AUTO, "ambient/spacial_loops/lights_flicker.wav");
		ReleaseLock[client] = 0;
		ChargeEndTime[client] = gt + ct;
	}
	return Plugin_Continue;
}

public ExplodeMain(Float:pos[3])
{
	/* Main effect when hit */
	ShowParticle(pos, "electrical_arc_01_system", 5.0);
	LittleFlower(pos, EXPLODE);
	
	if(GetConVarInt(sm_lw_lethalweapon) == 1)
	{
		ShowParticle(pos, "gas_explosion_main", 5.0);
		LittleFlower(pos, MOLOTOV);
	}
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	/* Show particle effect you like */
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
    }  
}

public PrecacheParticle(String:particlename[])
{
	/* Precache particle */
    new particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle))
    {
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
    }  
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	/* Delete particle */
    if (IsValidEntity(particle))
    {
        new String:classname[64];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
            RemoveEdict(particle);
    }
}

public LittleFlower(Float:pos[3], type)
{
	/* Cause fire(type=0) or explosion(type=1) */
	new entity = CreateEntityByName("prop_physics");
	if (IsValidEntity(entity))
	{
		pos[2] += 10.0;
		if(type == 0)
			/* fire */
			DispatchKeyValue(entity, "model", "models/props_junk/gascan001a.mdl");
		else
			/* explode */
			DispatchKeyValue(entity, "model", "models/props_junk/propanecanister001a.mdl");
		DispatchSpawn(entity);
		SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "break");
	}
}

public Action:GetEntityAbsOrigin(entity,Float:origin[3])
{
	/* Get target posision */
	decl Float:mins[3], Float:maxs[3];
	GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
	GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
	GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
	
	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
}

Smash(client, target, Float:power, Float:powHor, Float:powVec)
{
	/* Smash target */
	decl Float:HeadingVector[3], Float:AimVector[3];
	GetClientEyeAngles(client, HeadingVector);
	
	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);
	
	decl Float:current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	decl Float:resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);	
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	new Handle:msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
	{
		BfWriteShort(msg, (0x0002 | 0x0008));
	}
	else
	{
		BfWriteShort(msg, (0x0001 | 0x0010));
	}
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}
