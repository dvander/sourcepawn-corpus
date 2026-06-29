/////////////////////////////////////////////////////////////////////
//
// The Detonator.
//
/////////////////////////////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include "rmf/tf2_codes"
#include "rmf/tf2_events"

/////////////////////////////////////////////////////////////////////
//
//  The Detonator is a modified version of Flare Fireworks plugin by RIKUSYO.
//  http://forums.alliedmods.net/showthread.php?p=895202
/////////////////////////////////////////////////////////////////////
#define PL_NAME "Flare Detonate"
#define PL_DESC "Flare Detonate"
#define PL_VERSION "1.0"




#define SOUND_FLARE_DETONATE1 "player/pl_impact_flare3.wav"

#define EFFECT_FIREWORK "Explosions_MA_FloatieEmbers"
#define EFFECT_FIREWORK_FLARE "Explosions_MA_FlyingEmbers"
#define EFFECT_FIREWORK_FLASH "Explosions_MA_Flashup"
#define DMG_GENERIC			0
#define DMG_CRUSH			(1 << 0)
#define DMG_BULLET			(1 << 1)
#define DMG_SLASH			(1 << 2)
#define DMG_BURN			(1 << 3)
#define DMG_VEHICLE			(1 << 4)
#define DMG_FALL			(1 << 5)
#define DMG_BLAST			(1 << 6)
#define DMG_CLUB			(1 << 7)
#define DMG_SHOCK			(1 << 8)
#define DMG_SONIC			(1 << 9)
#define DMG_ENERGYBEAM			(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE	(1 << 11)
#define DMG_NEVERGIB			(1 << 12)
#define DMG_ALWAYSGIB			(1 << 13)
#define DMG_DROWN			(1 << 14)
#define DMG_TIMEBASED			(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE			(1 << 15)
#define DMG_NERVEGAS			(1 << 16)
#define DMG_POISON			(1 << 17)
#define DMG_RADIATION			(1 << 18)
#define DMG_DROWNRECOVER		(1 << 19)
#define DMG_ACID			(1 << 20)
#define DMG_SLOWBURN			(1 << 21)
#define DMG_REMOVENORAGDOLL		(1 << 22)
#define DMG_PHYSGUN			(1 << 23)
#define DMG_PLASMA			(1 << 24)
#define DMG_AIRBOAT			(1 << 25)
#define DMG_DISSOLVE			(1 << 26)
#define DMG_BLAST_SURFACE		(1 << 27)
#define DMG_DIRECT			(1 << 28)
#define DMG_BUCKSHOT			(1 << 29)

public Plugin:myinfo = 
{
	name = "The Detonator",
	author = "chicken and RIKUSYO",
	description = "Detonate flares to jump with and burn enemies. Based on TF2 beta.",
	version = PL_VERSION,
	url = "http://www.pwned.in"
}
new Handle:g_EffectiveRadius	= INVALID_HANDLE;		// ConVar有効範囲
new Handle:g_ProjectileSpeed	= INVALID_HANDLE;		// ConVar弾速
new Handle:cvFlareIcon;


new Handle:g_FlareCheckTimer[MAXPLAYERS+1]	= INVALID_HANDLE;	// フレアチェクタイマー
stock Action:Event_FiredUser(Handle:event, const String:name[], any:client=0)
{
	if(StrEqual(name, EVENT_PLUGIN_START))
	{



		CreateConVar("sm_detonatorversion", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	        cvFlareIcon = CreateConVar("sv_flare_icon", "flaregun", "kill icon for detonated flares");
		g_IsPluginOn = CreateConVar("sm_flaredetonate_enabled","1","Flare Detonate Enable/Disable (0 = disabled | 1 = enabled)");

		HookConVarChange(g_IsPluginOn, ConVarChange_IsPluginOn);

		g_EffectiveRadius = CreateConVar("sm_flare_radius",				"4.5", "Effective radius[meter] (0.0-100.0)");
		g_ProjectileSpeed = CreateConVar("sm_flare_speed",	"1.0", "Flare speed magnification (0.0-10.0)");
		HookConVarChange(g_EffectiveRadius, ConVarChange_Radius);
		HookConVarChange(g_ProjectileSpeed, ConVarChange_Magnification);
		CreateConVar("sm_flarefirework_class", "7", "7 = Pyro, do NOT change.");

	}

	

	if(StrEqual(name, EVENT_PLUGIN_INIT))
	{
	
	}
	
	if(StrEqual(name, EVENT_PLUGIN_FINAL))
	{
	}
	
	if(StrEqual(name, EVENT_MAP_START))
	{
		
		PrePlayParticle(EFFECT_FIREWORK_FLARE);
		PrePlayParticle(EFFECT_FIREWORK);
		PrePlayParticle(EFFECT_FIREWORK_FLASH);
		PrecacheSound(SOUND_FLARE_DETONATE1, true);		
	}
	
	// ゲームフレーム
	if(StrEqual(name, EVENT_GAME_FRAME))
	{
		new maxclients = GetMaxClients();
		for (new i = 1; i <= maxclients; i++)
		{
			FrameAction(i);
		}
	}
	

	if(StrEqual(name, EVENT_PLAYER_DISCONNECT))
	{
	}
	return Plugin_Continue;
}

stock FrameAction(any:client)
{
	// ゲームに入っている
	if( IsClientInGame(client) && IsPlayerAlive(client))
	{
		// パイロ
		if( TF2_GetPlayerClass( client ) == TFClass_Pyro && g_AbilityUnlock[client])
		{
			if( CheckElapsedTime(client, 0.1) )
			{
				FlareFirework(client);
			}
		}

	}

}

public FlareFirework(any:client)
{
	if ( GetClientButtons(client) & IN_ATTACK2 )
	{
		if(TF2_CurrentWeaponEqual(client, "CTFFlareGun"))
		{
			SaveKeyTime(client);
			
			new ent = -1;
			new flare = -1;
			while ((ent = FindEntityByClassname(ent, "tf_projectile_flare")) != -1)
			{
				new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
				if(iOwner == client)
				{
					flare = ent;
				}
			}
			
			if(flare != -1)
			{
				ShowParticleEntity(flare, EFFECT_FIREWORK_FLARE, 0.1);
				ShowParticleEntity(flare, EFFECT_FIREWORK_FLASH, 0.1);

				new Float:pos[3];
				pos[2] = -10.0;
				
				new Float:ang[3];
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos);
				ang[0] = 90.0;
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos, ang);
				ang[0] = 180.0;
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos, ang);
				ang[0] = 270.0;
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos, ang);
				ang[0] = 90.0;
				ang[1] = 90.0;
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos, ang);
				ang[0] = 90.0;
				ang[1] = 270.0;
				ShowParticleEntity(flare, EFFECT_FIREWORK, 0.1, pos, ang);
				EmitSoundToAll(SOUND_FLARE_DETONATE1, flare, _, _, SND_CHANGEPITCH, 1.0, 150);
				

				
				new Float:fFlarePos[3];
				new Float:fVictimPos[3];
				new maxclients = GetMaxClients();
				for (new victim = 1; victim <= maxclients; victim++)
				{
					if( IsClientInGame(victim) && IsPlayerAlive(victim) )
					{
						// 喰らうのは敵と自分
						//if( GetClientTeam(victim) != GetClientTeam(client) )
                                                if(victim==client || GetClientTeam(victim) != GetClientTeam(client))
						{
							// フレアの位置
							GetEntPropVector(flare, Prop_Data, "m_vecOrigin", fFlarePos);
							// 被害者位置
							GetClientAbsOrigin(victim, fVictimPos);
							if(CanSeeTarget( flare, fFlarePos, victim, fVictimPos, GetConVarFloat(g_EffectiveRadius), true, false))
							{
								// 燃やす
						                new String:tempString[32]; GetConVarString(cvFlareIcon, tempString, sizeof(tempString));
						                DealDamage(victim, 33, fFlarePos, client, DMG_BURN, tempString);
								TF2_IgnitePlayer(victim, client);				
							}
						}
					}
				}
				
				AcceptEntityInput( flare, "Kill" );
			}
		}
	}
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	// MODがONの時だけ
	if( !g_IsRunning )
		return Plugin_Continue;	

	// パイロで有効の時
	if( TF2_GetPlayerClass(client) == TFClass_Pyro && g_AbilityUnlock[client] )
	{
		// フレアガン
		if( StrEqual( weaponname, "tf_weapon_flaregun") )
		{
			// チェック
			ClearTimer( g_FlareCheckTimer[client] );
			g_FlareCheckTimer[client] = CreateTimer( 0.05, Timer_FlareCheck, client );
		}
		
	}
	

	return Plugin_Continue;	
}

DealDamage(victim, damage, Float:loc[3],attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="")
{
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
	{
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		//PrintToChat(victim, "victim %i is valid and hit by attacker %i", victim, attacker);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			//new Float:vicOri[3];
			//GetClientAbsOrigin(victim, vicOri);
			TeleportEntity(pointHurt, loc, NULL_VECTOR, NULL_VECTOR);
			//Format(tName, sizeof(tName), "hurtme%d", victim);
			DispatchKeyValue(victim,"targetname","hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				//PrintToChat(victim, "weaponname = %s", weapon);
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			//Format(tName, sizeof(tName), "donthurtme%d", victim);
			DispatchKeyValue(victim,"targetname","donthurtme");
			//TeleportEntity(pointHurt[victim], gHoldingArea, NULL_VECTOR, NULL_VECTOR);
			//CreateTimer(0.01, TPHurt, victim);
			RemoveEdict(pointHurt);
		}
	}
}

public Action:Timer_FlareCheck(Handle:timer, any:client)
{
	g_FlareCheckTimer[client] = INVALID_HANDLE;
	
	// 遅する
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_projectile_flare")) != -1)
	{
		new iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if(iOwner == client)
		{
			new Float:vec[ 3 ];
			new Float:speed;
			
			// ベクトル取得
			GetEntPropVector( ent, Prop_Data, "m_vecAbsVelocity", vec );

			// 速度取得
			speed = GetVectorLength( vec );
			
			if( speed > 2000 * GetConVarFloat( g_ProjectileSpeed )  )
			{
				speed *= GetConVarFloat( g_ProjectileSpeed );
				
				NormalizeVector( vec, vec );
				
				// ベクトルを上書き
				ScaleVector( vec, speed );
				SetEntPropVector( ent, Prop_Data, "m_vecAbsVelocity", vec );
				
			}
		}
	}	
}
