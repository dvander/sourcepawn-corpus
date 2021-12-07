#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PYROGAS_SND 	"misc/flame_engulf.wav"
#define FFADE_OUT	0x0002        // Fade out 

#define MAX_PLAYERS 33
new Float:g_DrugAngles[56] = {0.0, 3.0, 6.0, 9.0, 12.0, 15.0, 18.0, 21.0, 24.0, 27.0, 30.0, 33.0, 36.0, 39.0, 42.0, 39.0, 36.0, 33.0, 30.0, 27.0, 24.0, 21.0, 18.0, 15.0, 12.0, 9.0, 6.0, 3.0, 0.0, -3.0, -6.0, -9.0, -12.0, -15.0, -18.0, -21.0, -24.0, -27.0, -30.0, -33.0, -36.0, -39.0, -42.0, -39.0, -36.0, -33.0, -30.0, -27.0, -24.0, -21.0, -18.0, -15.0, -12.0, -9.0, -6.0, -3.0 };
new Handle:specialDrugTimers[ MAX_PLAYERS+1 ];
new BossTeam=_:TFTeam_Blue;
new gSmoke1;
new gGlow1;
new gHalo1;
new gExplosive1;
new gLaser1;
new gAfterburn;
new gExplosion;
new fov_offset;
new zoom_offset;


public Plugin:myinfo = {
	name = "Freak Fortress 2: Phat Rages",
	author = "frog,Kemsan,Peace Maker,LeGone,RainBolt Dash",
	version = "0.9.4",
};
	
public OnPluginStart2()
{
	fov_offset = FindSendPropOffs("CBasePlayer", "m_iFOV");
	zoom_offset = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	gLaser1 = PrecacheModel("materials/sprites/laser.vmt");
	gSmoke1 = PrecacheModel("materials/effects/fire_cloud1.vmt");
	gHalo1 = PrecacheModel("materials/sprites/halo01.vmt");
	gGlow1 = PrecacheModel("sprites/blueglow2.vmt", true);
	gExplosive1 = PrecacheModel("materials/sprites/sprite_fire01.vmt");
	PrecacheModel("models/props_wasteland/rockgranite03b.mdl");
	PrecacheSound(PYROGAS_SND,true);
	PrecacheSound("ambient/explosions/citadel_end_explosion2.wav",true);
	PrecacheSound("ambient/explosions/citadel_end_explosion1.wav",true);
	PrecacheSound("ambient/energy/weld1.wav",true);
	PrecacheSound("ambient/halloween/mysterious_perc_01.wav",true);
}

public Action:Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	CreateTimer(0.1, EndSickness);
	CreateTimer(0.2, ResetScale);
	CreateTimer(0.3, EndDrowning);
	CreateTimer(0.4, ResetCaber);
}

public Action:Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(0));
	if (Boss>0)
	{
		new BossMeleeweapon = GetPlayerWeaponSlot(Boss, TFWeaponSlot_Melee);
		if (BossMeleeweapon != -1)
		{
			if (GetEntProp(BossMeleeweapon, Prop_Send, "m_iItemDefinitionIndex") == 307)	
			{
				SDKHook(Boss, SDKHook_PreThink, CaberReset);
			}
		}
	}
}

public CaberReset(client)
{
	new stickbomb = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee); 
	if (stickbomb <= MaxClients || !IsValidEdict(stickbomb)) 
	{ 
	    return; 
	}
	SetEntProp(stickbomb, Prop_Send, "m_iDetonated", 0); 
	SetEntProp(stickbomb, Prop_Send, "m_bBroken", 0); 
}

public Action:ResetCaber(Handle:timer)
{
	decl i;
	for( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_PreThink, CaberReset);
		}
	}
	return Plugin_Stop;
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntData(client, fov_offset, 90, 4, true);
	SetEntData(client, zoom_offset, 90, 4, true);
	ClientCommand(client, "r_screenoverlay \"\"");
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name,"rage_ioncannon"))			//Ion Cannon by Peace Maker & LeGone
		Rage_IonCannon(ability_name,index);
	else if (!strcmp(ability_name,"rage_delirium"))			//Based on original Polish Nurse Rage by Kemsan
		Rage_Delirium(ability_name,index);
	else if (!strcmp(ability_name,"rage_hellfire"))			//Based on original Pyrogas Rage by Kemsan	
		Rage_Hellfire(ability_name,index);
	else if (!strcmp(ability_name,"rage_scaleboss"))		//Scale Boss	
		Rage_ScaleBoss(ability_name,index);
	else if (!strcmp(ability_name,"rage_scaleplayers"))		//Scale players
		Rage_ScalePlayers(ability_name,index);
	else if (!strcmp(ability_name,"rage_drown"))			//Drown players
		Rage_Drown(ability_name,index);
	else if (!strcmp(ability_name,"rage_explosion"))		//Fireball Explosion - variation of explosive_dance_rage by RainBolt Dash
		Rage_Explosion(ability_name,index);
	else if (!strcmp(ability_name,"rage_visualeffect"))		//Visual effect on players
		Rage_VisualEffect(ability_name,index);
	return Plugin_Continue;
}


Rage_VisualEffect(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new effect=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	        	//effect
	new duration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	        	//duration
	new Float:range=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 3);	        //range
	
	decl Float:pos[3];
	decl Float:pos2[3];
	
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if ((GetVectorDistance(pos,pos2)<range)) {
			
				SetVariantInt(0);
				AcceptEntityInput(i, "SetForcedTauntCam");
				
				switch(effect)
				{
					case 0:
					{
						ClientCommand(i, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt"); // extreme fish eye
					}
					case 1:
					{
						ClientCommand(i, "r_screenoverlay effects/strider_bulge_dudv.vmt"); //central screen crunch
					}
					case 2:
					{
						ClientCommand(i, "r_screenoverlay effects/tp_eyefx/tpeye.vmt"); // rainbow flashes					
					}
					case 3:
					{
						ClientCommand(i, "r_screenoverlay effects/tp_eyefx/tpeye2.vmt"); // fire flashes					
					}
					case 4:
					{
						ClientCommand(i, "r_screenoverlay effects/tp_eyefx/tpeye3.vmt"); // blue/green flashes					
					}
					case 5:
					{
						ClientCommand(i, "r_screenoverlay effects/com_shield003a.vmt"); // blue/green web					
					}
					case 6:
					{
						ClientCommand(i, "r_screenoverlay effects/ar2_altfire1.vmt"); //central fire ball					
					}
					case 7:
					{
						ClientCommand(i, "r_screenoverlay effects/screenwarp.vmt"); // golden madness opaque					
					}
					case 8:
					{
						ClientCommand(i, "r_screenoverlay effects/tvscreen_noise002a.vmt"); // tv static transparent										
					}
				}
			}
		}	
	}
	CreateTimer(float(duration), ClearVisualEffect);
}


public Action:ClearVisualEffect(Handle:timer)
{
	decl i;
	for( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i))
		{
			ClientCommand(i, "r_screenoverlay \"\"");
		}
	}
	return Plugin_Stop;
}


Rage_Drown(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new duration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	        	//duration
	new Float:range=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 2);	        //range
	
	decl Float:pos[3];
	decl Float:pos2[3];
	
	duration = duration + 4;
	
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if ((GetVectorDistance(pos,pos2)<range)) {
				SDKHook(i, SDKHook_PreThink, DrownEvent);
			}
		}	
	}
	CreateTimer(float(duration), EndDrowning);
}

public DrownEvent(client)
{
	SetEntProp(client, Prop_Send, "m_nWaterLevel", 3);    
}

public Action:EndDrowning(Handle:timer)
{
	decl i;
	for( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_PreThink, DrownEvent);
		}
	}
	return Plugin_Stop;
}

Rage_Explosion(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new damage=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	        //damage 
	new range=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	        //damage radius
	new String:s[512];
	FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,3,s,512); //sound path

	decl Float:vOrigin[3];
	
	gExplosion = 0;
	
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", vOrigin);

	new Handle:data = CreateDataPack();
	CreateDataTimer(0.12, SetExplosion, data, TIMER_REPEAT);
	WritePackFloat(data, vOrigin[0]);
	WritePackFloat(data, vOrigin[1]);
	WritePackFloat(data, vOrigin[2]);
	WritePackCell(data, range); // Range
	WritePackCell(data, damage); // Damge
	WritePackCell(data, index);
	WritePackString(data, s);
	ResetPack(data);
	env_shake(vOrigin, 120.0, 10000.0, 4.0, 50.0);
}


public Action:SetExplosion(Handle:timer, Handle:data)
{
	ResetPack(data);
	new Float:vOrigin[3];
	vOrigin[0] = ReadPackFloat(data);
	vOrigin[1] = ReadPackFloat(data);
	vOrigin[2] = ReadPackFloat(data);
	new range = ReadPackCell(data);
	new damage = ReadPackCell(data);
	new index = ReadPackCell(data);
	decl String:s[512];
    	ReadPackString(data, s, 512);
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	gExplosion++;
	
	if (gExplosion >= 15)
	{
		gExplosion = 0;
		return Plugin_Stop;
	}

	//SetExplodeAtClient( Boss, afterBurnDamage, rageDistance, DMG_BURN );
	
	for(new i=0;i<5;i++)
	{
		decl proj;
		proj = CreateEntityByName("env_explosion");   
		DispatchKeyValueFloat(proj, "DamageForce", 180.0);
		SetEntProp(proj, Prop_Data, "m_iMagnitude", 400, 4);
		SetEntProp(proj, Prop_Data, "m_iRadiusOverride", 400, 4);
		SetEntPropEnt(proj, Prop_Data, "m_hOwnerEntity", Boss);
		DispatchSpawn(proj);	
		
		AcceptEntityInput(proj, "Explode");
		AcceptEntityInput(proj, "kill");
	}
	if (gExplosion % 4 == 1) {
		SetExplodeAtClient( Boss, damage, range, DMG_BLAST );
		if (strlen(s))
		{
			EmitSoundToAll(s, Boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss, vOrigin, NULL_VECTOR, true, 0.0);
			for (new i=1; i<=MaxClients; i++)
				if (IsClientInGame(i) && (i!=Boss))
				{
					EmitSoundToClient(i,s, Boss, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, Boss, vOrigin, NULL_VECTOR, true, 0.0);
				}
		}
	}
	return Plugin_Continue;	
}


Rage_ScaleBoss(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new Float:scale=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 1);	        //scale
	new duration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	        //duration
	SetEntPropFloat(Boss, Prop_Send, "m_flModelScale", scale);
	CreateTimer(float(duration), ResetScale);
}

Rage_ScalePlayers(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new Float:scale=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 1);	//scale
	new duration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	        //duration
	new Float:range=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 3);	        //range
	
	decl Float:pos[3];
	decl Float:pos2[3];
	
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if ((GetVectorDistance(pos,pos2)<range)) {
				SetEntPropFloat(i, Prop_Send, "m_flModelScale", scale);
			}
		}	
	}
	CreateTimer(float(duration), ResetScale);
}

public Action:ResetScale(Handle:timer)
{
	decl i;
	for( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i))
		{
			SetEntPropFloat(i, Prop_Send, "m_flModelScale", 1.0);
		}
	}
	return Plugin_Stop;
}


//Based on original Saxtoner Pyrogas rage by Kemsan
Rage_Hellfire(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new sound=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	        //sound
	new rageDamage=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	        //damage
	new rageDistance=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 3);	//distance (range)
	new afterBurnDamage=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 4);     //afterburn damage
	new afterBurnDuration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 5);	//afterburn duration (seconds)
	
	new Float:vel[3];
	vel[2] = 20.0;
	TeleportEntity( Boss,  NULL_VECTOR, NULL_VECTOR, vel );
	SetExplodeAtClient( Boss, rageDamage, rageDistance, DMG_BURN );
	
	decl Float:pos[3];
	decl Float:pos2[3];
	decl i;
	decl Float:distance;
	
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	for ( i = 1; i <= MaxClients; i++ ) {
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			GetEntPropVector( i, Prop_Send, "m_vecOrigin", pos2 );
			distance = GetVectorDistance( pos,pos2 );
			if ( !TF2_IsPlayerInCondition( i, TFCond_Ubercharged ) && !TF2_IsPlayerInCondition( i, TFCond_Bonked ) && ( distance < rageDistance ) ) 
			{					
				TF2_IgnitePlayer( i, Boss );
				ClientCommand(i, "r_screenoverlay effects/tp_eyefx/tpeye2.vmt"); // fire flashes	
			}
		}
	}
	if(sound!=0)
	{
		EmitSoundToAll(PYROGAS_SND);
		EmitSoundToAll(PYROGAS_SND);
	}
	new Handle:pack = CreateDataPack();
	gAfterburn = 0;
	CreateDataTimer(1.0, AfterBurn, pack, TIMER_REPEAT);
	WritePackCell(pack, Boss);
	WritePackCell(pack, afterBurnDamage);
	WritePackCell(pack, afterBurnDuration);
	WritePackCell(pack, rageDistance);
	ResetPack(pack);
}

 
public Action:AfterBurn(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Boss = ReadPackCell(pack);
	new afterBurnDamage = ReadPackCell(pack);
	new afterBurnDuration = ReadPackCell(pack);
	new rageDistance = ReadPackCell(pack);
	
	if (gAfterburn >= afterBurnDuration)
	{
		gAfterburn = 0;
		decl i;
		for( i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				ClientCommand(i, "r_screenoverlay \"\"");
			}	
		}
		
		return Plugin_Stop;
	}
	SetExplodeAtClient( Boss, afterBurnDamage, rageDistance, DMG_BURN );
	gAfterburn++;
	return Plugin_Continue;	
}

SetExplodeAtClient( client, damage, radius, dmgtype )
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl Float:pos[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", pos );
		new particle = CreateEntityByName( "info_particle_system" );
		if ( IsValidEdict( particle ) )
		{
			TeleportEntity( particle, pos, NULL_VECTOR, NULL_VECTOR );
			DispatchKeyValue( particle, "effect_name", "cinefx_goldrush" );
			ActivateEntity( particle );
			AcceptEntityInput (particle, "start" );
			
			decl String:strAddOutput[64];
			Format( strAddOutput, sizeof( strAddOutput ), "OnUser1 !self:kill::%f:1", 0.5 );
			SetVariantString( strAddOutput);
			AcceptEntityInput( particle, "AddOutput" );	
			AcceptEntityInput( particle, "FireUser1" );    
		
			SetDamageRadial( client, damage, pos, radius, dmgtype );
		}
	}
}

SetDamageRadial( attacker, dmg,  Float:pos[3], radius, dmgtype )
{
	new i;
	new Float:dist;
	
	for  ( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			decl Float:pos2[3];
			GetEntPropVector( i, Prop_Send, "m_vecOrigin", pos2 );
			dist = GetVectorDistance( pos2, pos );
			
			pos[2] += 60;
			if (dist <= radius )
			{
				if (dmgtype & DMG_BURN)
				{
					ClientCommand(i, "r_screenoverlay effects/tp_eyefx/tpeye2.vmt"); // fire flashes
				}
				SDKHooks_TakeDamage( i, attacker, attacker, float( dmg ) /* float( RoundFloat( dmg * (radius - dist ) / dist ) ) */, dmgtype, GetPlayerWeaponSlot( attacker, 1 ) );  
			}
		}
	}
}

//Based on Ion Cannon by Peace Maker & LeGone
Rage_IonCannon(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new distance=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	        //blast speed seconds
	new range=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	        //damage radius
	new damage=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 3);	        //damage
	new aim=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 4);	        	//aim
	
	
	distance = distance * 29;
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vStart[3];
	
	GetClientEyePosition(Boss, vOrigin);
	GetClientEyeAngles(Boss, vAngles);
	
	if (aim==0) {

		new Handle:data = CreateDataPack();
		WritePackFloat(data, vOrigin[0]);
		WritePackFloat(data, vOrigin[1]);
		WritePackFloat(data, vOrigin[2]);
		WritePackCell(data, distance); // Distance
		WritePackFloat(data, 0.0); // nphi
		WritePackCell(data, range); // Range
		WritePackCell(data, damage); // Damge
		ResetPack(data);
		IonAttack(data);
	
	} else {
	
		new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    	
		if(TR_DidHit(trace))
		{   	 
   		 	TR_GetEndPosition(vStart, trace);
	
			CloseHandle(trace);
	
			new Handle:data = CreateDataPack();
			WritePackFloat(data, vStart[0]);
			WritePackFloat(data, vStart[1]);
			WritePackFloat(data, vStart[2]);
			WritePackCell(data, distance); // Distance
			WritePackFloat(data, 0.0); // nphi
			WritePackCell(data, range); // Range
			WritePackCell(data, damage); // Damge
			ResetPack(data);

			IonAttack(data);
		}
		else
		{
			CloseHandle(trace);
		}
	}
}

public DrawIonBeam(Float:startPosition[3])
{
	decl Float:position[3];
	position[0] = startPosition[0];
	position[1] = startPosition[1];
	position[2] = startPosition[2] + 1500.0;	

	TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 0.15, 25.0, 25.0, 0, 1.0, {0, 150, 255, 255}, 3 );
	TE_SendToAll();
	position[2] -= 1490.0;
	TE_SetupSmoke(startPosition, gSmoke1, 10.0, 2);
	TE_SendToAll();
	TE_SetupGlowSprite(startPosition, gGlow1, 1.0, 1.0, 255);
	TE_SendToAll();
}

public IonAttack(Handle:data)
{
	new Float:startPosition[3];
	new Float:position[3];
	startPosition[0] = ReadPackFloat(data);
	startPosition[1] = ReadPackFloat(data);
	startPosition[2] = ReadPackFloat(data);
	new distance = ReadPackCell(data);
	new Float:nphi = ReadPackFloat(data);
	new range = ReadPackCell(data);
	new damage = ReadPackCell(data);
	
	if (distance > 0)
	{
		EmitSoundToAll("ambient/energy/weld1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);
		
		// Stage 1
		new Float:s=Sine(nphi/360*6.28)*distance;
		new Float:c=Cosine(nphi/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[2] = startPosition[2];
		
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);

		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);
		
		// Stage 2
		s=Sine((nphi+45.0)/360*6.28)*distance;
		c=Cosine((nphi+45.0)/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);
		
		// Stage 3
		s=Sine((nphi+90.0)/360*6.28)*distance;
		c=Cosine((nphi+90.0)/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);
		
		// Stage 3
		s=Sine((nphi+135.0)/360*6.28)*distance;
		c=Cosine((nphi+135.0)/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);

		if (nphi >= 360)
			nphi = 0.0;
		else
			nphi += 5.0;
	}
	distance -= 5;
	
	new Handle:nData = CreateDataPack();
	WritePackFloat(nData, startPosition[0]);
	WritePackFloat(nData, startPosition[1]);
	WritePackFloat(nData, startPosition[2]);
	WritePackCell(nData, distance);
	WritePackFloat(nData, nphi);
	WritePackCell(nData, range);
	WritePackCell(nData, damage);
	ResetPack(nData);

	if (distance > -50)
		CreateTimer(0.1, DrawIon, nData, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	else
	{
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[2] += 1500.0;
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 5.0, 30.0, 30.0, 0, 1.0, {255, 255, 255, 255}, 3);
		TE_SendToAll();
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 4.0, 50.0, 50.0, 0, 1.0, {200, 255, 255, 255}, 3);
		TE_SendToAll();
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 3.0, 80.0, 80.0, 0, 1.0, {100, 255, 255, 255}, 3);
		TE_SendToAll();
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 2.0, 100.0, 100.0, 0, 1.0, {0, 255, 255, 255}, 3);
		TE_SendToAll();
		
		TE_SetupSmoke(startPosition, gSmoke1, 350.0, 15);
		TE_SendToAll();
		TE_SetupGlowSprite(startPosition, gGlow1, 3.0, 15.0, 255);
		TE_SendToAll();

		makeexplosion(0, -1, startPosition, "", damage, range);

		position[2] = startPosition[2] + 50.0;
		new Float:fDirection[3] = {-90.0,0.0,0.0};
		env_shooter(fDirection, 25.0, 0.1, fDirection, 800.0, 120.0, 120.0, position, "models/props_wasteland/rockgranite03b.mdl");

		env_shake(startPosition, 120.0, 10000.0, 15.0, 250.0);

		TE_SetupExplosion(startPosition, gExplosive1, 10.0, 1, 0, 0, 5000);
		TE_SendToAll();
		
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 0.5, 100.0, 5.0, {150, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 5.0, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 2.5, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 6.0, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();

		// Light
		new ent = CreateEntityByName("light_dynamic");

		DispatchKeyValue(ent, "_light", "255 255 255 255");
		DispatchKeyValue(ent, "brightness", "5");
		DispatchKeyValueFloat(ent, "spotlight_radius", 500.0);
		DispatchKeyValueFloat(ent, "distance", 500.0);
		DispatchKeyValue(ent, "style", "6");

		DispatchSpawn(ent);
		AcceptEntityInput(ent, "TurnOn");
	
		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		
		RemoveEntity(ent, 3.0);
		
		// Sound
		EmitSoundToAll("ambient/explosions/citadel_end_explosion1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);
		EmitSoundToAll("ambient/explosions/citadel_end_explosion2.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);	

		// Blend
		sendfademsg(0, 10, 200, FFADE_OUT, 255, 255, 255, 150);
		
		// Knockback
		new Float:vReturn[3], Float:vClientPosition[3], Float:dist;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
			{	
				GetClientEyePosition(i, vClientPosition);

				dist = GetVectorDistance(vClientPosition, position, false);
				if (dist < range)
				{
					MakeVectorFromPoints(position, vClientPosition, vReturn);
					NormalizeVector(vReturn, vReturn);
					ScaleVector(vReturn, 10000.0 - dist*10);

					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vReturn);
				}
			}
		}
	}
}

public Action:DrawIon(Handle:Timer, any:data)
{
	IonAttack(data);
	
	return (Plugin_Stop);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}

stock bool:makeexplosion(attacker = 0, inflictor = -1, const Float:attackposition[3], const String:weaponname[] = "", magnitude = 100, radiusoverride = 0, Float:damageforce = 0.0, flags = 0){
	
	new explosion = CreateEntityByName("env_explosion");
	
	if(explosion != -1)
	{
		DispatchKeyValueVector(explosion, "Origin", attackposition);
		
		decl String:intbuffer[64];
		IntToString(magnitude, intbuffer, 64);
		DispatchKeyValue(explosion,"iMagnitude", intbuffer);
		if(radiusoverride > 0)
		{
			IntToString(radiusoverride, intbuffer, 64);
			DispatchKeyValue(explosion,"iRadiusOverride", intbuffer);
		}
		
		if(damageforce > 0.0)
			DispatchKeyValueFloat(explosion,"DamageForce", damageforce);

		if(flags != 0)
		{
			IntToString(flags, intbuffer, 64);
			DispatchKeyValue(explosion,"spawnflags", intbuffer);
		}

		if(!StrEqual(weaponname, "", false))
			DispatchKeyValue(explosion,"classname", weaponname);

		DispatchSpawn(explosion);
		if(IsClientConnectedIngame(attacker))
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", attacker);

		if(inflictor != -1)
			SetEntPropEnt(explosion, Prop_Data, "m_hInflictor", inflictor);
			
		AcceptEntityInput(explosion, "Explode");
		AcceptEntityInput(explosion, "Kill");
		
		return (true);
	}
	else
		return (false);
}

// Thanks to V0gelz
stock env_shooter(Float:Angles[3], Float:iGibs, Float:Delay, Float:GibAngles[3], Float:Velocity, Float:Variance, Float:Giblife, Float:Location[3], String:ModelType[] )
{
	//decl Ent;

	//Initialize:
	new Ent = CreateEntityByName("env_shooter");
		
	//Spawn:

	if (Ent == -1)
		return;

  	//if (Ent>0 && IsValidEdict(Ent))

	if(Ent>0 && IsValidEntity(Ent) && IsValidEdict(Ent))
  	{

		//Properties:
		//DispatchKeyValue(Ent, "targetname", "flare");

		// Gib Direction (Pitch Yaw Roll) - The direction the gibs will fly. 
		DispatchKeyValueVector(Ent, "angles", Angles);
	
		// Number of Gibs - Total number of gibs to shoot each time it's activated
		DispatchKeyValueFloat(Ent, "m_iGibs", iGibs);

		// Delay between shots - Delay (in seconds) between shooting each gib. If 0, all gibs shoot at once.
		DispatchKeyValueFloat(Ent, "delay", Delay);

		// <angles> Gib Angles (Pitch Yaw Roll) - The orientation of the spawned gibs. 
		DispatchKeyValueVector(Ent, "gibangles", GibAngles);

		// Gib Velocity - Speed of the fired gibs. 
		DispatchKeyValueFloat(Ent, "m_flVelocity", Velocity);

		// Course Variance - How much variance in the direction gibs are fired. 
		DispatchKeyValueFloat(Ent, "m_flVariance", Variance);

		// Gib Life - Time in seconds for gibs to live +/- 5%. 
		DispatchKeyValueFloat(Ent, "m_flGibLife", Giblife);
		
		// <choices> Used to set a non-standard rendering mode on this entity. See also 'FX Amount' and 'FX Color'. 
		DispatchKeyValue(Ent, "rendermode", "5");

		// Model - Thing to shoot out. Can be a .mdl (model) or a .vmt (material/sprite). 
		DispatchKeyValue(Ent, "shootmodel", ModelType);

		// <choices> Material Sound
		DispatchKeyValue(Ent, "shootsounds", "-1"); // No sound

		// <choices> Simulate, no idea what it realy does tbh...
		// could find out but to lazy and not worth it...
		//DispatchKeyValue(Ent, "simulation", "1");

		SetVariantString("spawnflags 4");
		AcceptEntityInput(Ent,"AddOutput");

		ActivateEntity(Ent);

		//Input:
		// Shoot!
		AcceptEntityInput(Ent, "Shoot", 0);
			
		//Send:
		TeleportEntity(Ent, Location, NULL_VECTOR, NULL_VECTOR);

		//Delete:
		//AcceptEntityInput(Ent, "kill");
		RemoveEntity(Ent, 1.0);
	}
}

stock env_shake(Float:Origin[3], Float:Amplitude, Float:Radius, Float:Duration, Float:Frequency)
{
	decl Ent;

	//Initialize:
	Ent = CreateEntityByName("env_shake");
		
	//Spawn:
	if(DispatchSpawn(Ent))
	{
		//Properties:
		DispatchKeyValueFloat(Ent, "amplitude", Amplitude);
		DispatchKeyValueFloat(Ent, "radius", Radius);
		DispatchKeyValueFloat(Ent, "duration", Duration);
		DispatchKeyValueFloat(Ent, "frequency", Frequency);

		SetVariantString("spawnflags 8");
		AcceptEntityInput(Ent,"AddOutput");

		//Input:
		AcceptEntityInput(Ent, "StartShake", 0);
		
		//Send:
		TeleportEntity(Ent, Origin, NULL_VECTOR, NULL_VECTOR);

		//Delete:
		RemoveEntity(Ent, 30.0);
	}
}

stock RemoveEntity(entity, Float:time = 0.0)
{
	if (time == 0.0)
	{
		if(IsValidEntity(entity))
		{
			new String:edictname[32];
			GetEdictClassname(entity, edictname, 32);

			if (StrEqual(edictname, "player"))
				KickClient(entity); // HaHa =D
			else
				AcceptEntityInput(entity, "kill");
		}
	}
	else
	{
		CreateTimer(time, RemoveEntityTimer, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:RemoveEntityTimer(Handle:Timer, any:entity)
{
	if(IsValidEntity(entity))
		AcceptEntityInput(entity, "kill"); // RemoveEdict(entity);
	
	return (Plugin_Stop);
}

stock bool:IsClientConnectedIngame(client)
{
	if(client > 0 && client <= MaxClients)
		if(IsClientInGame(client))
			return (true);

	return (false);
}

stock sendfademsg(client, duration, holdtime, fadeflag, r, g, b, a)
{
	new Handle:fademsg;
	
	if (client == 0)
		fademsg = StartMessageAll("Fade");
	else
		fademsg = StartMessageOne("Fade", client);
	
	BfWriteShort(fademsg, duration);
	BfWriteShort(fademsg, holdtime);
	BfWriteShort(fademsg, fadeflag);
	BfWriteByte(fademsg, r);
	BfWriteByte(fademsg, g);
	BfWriteByte(fademsg, b);
	BfWriteByte(fademsg, a);
	EndMessage();
}


//Based on original Saxtoner Polish Nurse rage by Kemsan
Rage_Delirium(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new rageDistance=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	//rage distance
	new rageDuration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	//rage duration
	
	decl Float:pos[3];
	decl Float:pos2[3];
	decl Float:distance;
	decl i;

	TF2_RemoveCondition( Boss, TFCond_Taunting );
		
	new Float:vel[3];
	vel[2]=20.0;
		
	TeleportEntity( Boss,  NULL_VECTOR, NULL_VECTOR, vel );
	GetEntPropVector( Boss, Prop_Send, "m_vecOrigin", pos );
		
	for( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			distance = GetVectorDistance( pos, pos2 );
			if ( distance < rageDistance && GetClientTeam(i)!=BossTeam )
			{
				SetVariantInt(0);
				AcceptEntityInput(i, "SetForcedTauntCam");
				fxDrug_Create( i );
			}
		}	
	}
	
	GetEntPropVector( Boss, Prop_Send, "m_vecOrigin", pos );
		
	new Float:vec[3];
	GetClientAbsOrigin( Boss, vec );
	vec[2] += 10;
			
	TE_SetupBeamRingPoint(vec, 10.0, float(rageDistance)/2, gLaser1, gHalo1, 0, 15, 0.5, 10.0, 0.0, { 128, 128, 128, 255 }, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec, 10.0, float(rageDistance)/2, gLaser1, gHalo1, 0, 10, 0.6, 20.0, 0.5, { 75, 75, 255, 255 }, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec, 0.0, float(rageDistance), gLaser1, gHalo1, 0, 0, 0.5, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec, 0.0, float(rageDistance), gLaser1, gHalo1, 0, 0, 5.0, 100.0, 5.0, {64, 64, 128, 255}, 0, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec, 0.0, float(rageDistance), gLaser1, gHalo1, 0, 0, 2.5, 100.0, 5.0, {32, 32, 64, 255}, 0, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec, 0.0, float(rageDistance), gLaser1, gHalo1, 0, 0, 6.0, 100.0, 5.0, {16, 16, 32, 255}, 0, 0);
	TE_SendToAll();
	
	CreateTimer(float(rageDuration), EndSickness);

}

public Action:EndSickness(Handle:timer)
{
	decl i;
	for( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			fxDrug_Kill( i );
		}
	}
	return Plugin_Stop;
}

/* 
* Create colorfull drug on client
*/
stock fxDrug_Create(client)
{
	specialDrugTimers[ client ] = CreateTimer(0.1, fxDrug_Timer, client, TIMER_REPEAT);	
}

/* 
* Kill drug on selected client
*/
stock fxDrug_Kill(client)
{
	if ( IsClientInGame( client ) && IsClientConnected( client ) )
	{
		specialDrugTimers[ client ] = INVALID_HANDLE;	
		
		new Float:angs[3];
		GetClientEyeAngles(client, angs);
			
		angs[2] = 0.0;
			
		TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);	
		
		ClientCommand(client, "r_screenoverlay \"\"");
		
		SetEntData(client, fov_offset, 90, 4, true);
		SetEntData(client, zoom_offset, 90, 4, true);
	}
}

/*
* Kill drug on client after X seconds
*/
public Action:fxDrug_KillTimer(Handle:timer,any:client)
{
	if( client > 0 )
		if ( IsClientInGame( client ) && IsClientConnected( client ) )
			 fxDrug_Kill( client );
}

/*
* Run drug timer
*/
public Action:fxDrug_Timer(Handle:timer, any:client)
{
	static Repeat = 0;
	
	if ( !IsClientInGame( client ) )
	{
		fxDrug_Kill( client );
		return Plugin_Stop;
	}
	
	if ( !IsPlayerAlive( client ) )
	{
		fxDrug_Kill( client );
		return Plugin_Stop;
	}
	
	if( specialDrugTimers[ client ] == INVALID_HANDLE )
	{
		fxDrug_Kill( client );
		return Plugin_Stop;
	}
	
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");
	
	new Float:angs[3];
	GetClientEyeAngles(client, angs);

	angs[2] = g_DrugAngles[Repeat % 56];
	angs[1] = g_DrugAngles[(Repeat+14) % 56];
	angs[0] = g_DrugAngles[(Repeat+21) % 56];

	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
	
	SetEntData(client, fov_offset, 160, 4, true);
	SetEntData(client, zoom_offset, 160, 4, true);
	
	if (Repeat == 0) {
		EmitSoundToClient(client, "ambient/halloween/mysterious_perc_01.wav");
	} else if ((Repeat%15) == 0) {
		EmitSoundToClient(client, "ambient/halloween/mysterious_perc_01.wav");
	}
	
	ClientCommand(client, "r_screenoverlay effects/tp_eyefx/tpeye.vmt"); // rainbow flashes
	
	Repeat++;
	
	new clients[2];
	clients[0] = client;	
	
	sendfademsg(client, 255, 255, FFADE_OUT, GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255), 150);
	
	return Plugin_Handled;

}

stock SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}