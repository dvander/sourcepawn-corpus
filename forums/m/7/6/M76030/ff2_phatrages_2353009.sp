#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

//Miscs
#define FFADE_OUT	0x0002        // Fade out 
#define MAX_PLAYERS 33
new gSmoke1;
new gGlow1;
new gHalo1;
new gExplosive1;
new gLaser1;
new gAfterburn;
new gExplosion;
new fov_offset;
new zoom_offset;
#define INACTIVE 100000000.0

//Ion Cannon
#define IONCANNON "rage_ioncannon"
#define IONCANNONALIAS "IOC"
new bool:IonCannon_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS
new distance;
new IOCDist;
new IOCdamage;
new aimmode;

//Delirium
#define DELIRIUM "rage_delirium"
#define DELIRIUMALIAS "DEL"
new bool:Delirium_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS
new DeliriumDistance;
new Float:DeliriumDuration;
new Float:g_DrugAngles[56] = {0.0, 3.0, 6.0, 9.0, 12.0, 15.0, 18.0, 21.0, 24.0, 27.0, 30.0, 33.0, 36.0, 39.0, 42.0, 39.0, 36.0, 33.0, 30.0, 27.0, 24.0, 21.0, 18.0, 15.0, 12.0, 9.0, 6.0, 3.0, 0.0, -3.0, -6.0, -9.0, -12.0, -15.0, -18.0, -21.0, -24.0, -27.0, -30.0, -33.0, -36.0, -39.0, -42.0, -39.0, -36.0, -33.0, -30.0, -27.0, -24.0, -21.0, -18.0, -15.0, -12.0, -9.0, -6.0, -3.0 };
new Handle:specialDrugTimers[ MAX_PLAYERS+1 ];

//Hellfire
#define HELLFIRE "rage_hellfire"
#define HELLFIREALIAS "HLF"
#define PYROGAS_SND 	"misc/flame_engulf.wav"
new bool:HellFire_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS
new hellsound;
new rageDamage;
new rageDistance;
new afterBurnDamage;
new afterBurnDuration;

// Scaling
new Float:oldScale[MAXPLAYERS+1]=1.0;
//Scale Boss
#define SCALEBOSS "rage_scaleboss"
#define SCALEBOSSALIAS "SCB"
new bool:BossScale_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS
new Float:BossScale;
new Float:BossDuration;

//Scale Players
#define SCALEPLAYER "rage_scaleplayers"
#define SCALEPLAYERALIAS "SCP"
new bool:PlayerScale_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS
new Float:PlayerScale;
new Float:PlayerDuration;
new Float:PlayerDistance;

//Explosions
#define EXPLOSION "rage_explosion"
#define EXPLOSIONALIAS "EXP"
new bool:Explosion_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS
//new ExplosionDamage;
//new Float:ExplosionDistance;

//Drown
#define DROWN "rage_drown"
#define DROWNALIAS "RDR"
new bool:Drown_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS
new Float:DrownDuration;
new Float:DrownDistance;

//Visualeffects
#define EFFECT "rage_visualeffect"
#define EFFECTALIAS "VIS"
new bool:Visual_TriggerAMS[MAXPLAYERS+1]; // global boolean to use with AMS
new VisualEffect;
new Float:EffectDuration;
new Float:EffectDistance;

// Hitboxes
new bool:isHitBoxAvailable=false;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Phat Rages",
	author = "frog,Kemsan,Peace Maker,LeGone,RainBolt Dash, SHADoW NiNE TR3S, M76030",
	version = "0.9.7",
};
	
public OnPluginStart2()
{
	fov_offset = FindSendPropOffs("CBasePlayer", "m_iFOV");
	zoom_offset = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	isHitBoxAvailable=((FindSendPropOffs("CBasePlayer", "m_vecSpecifiedSurroundingMins") != -1) && FindSendPropOffs("CBasePlayer", "m_vecSpecifiedSurroundingMaxs") != -1);
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
	if(FF2_GetRoundState()==1)
	{
		HookAbilities();
	}
}

public Action:Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if (IsValidClient(client))
		{
			oldScale[client]=1.0;
			
			//Ion Cannon
			IonCannon_TriggerAMS[client] = false;
			
			//Delirium
			DeliriumDuration = INACTIVE;
			Delirium_TriggerAMS[client] = false;
			
			//Hellfire
			HellFire_TriggerAMS[client] = false;
			
			//Scale Boss
			BossDuration = INACTIVE;
			BossScale_TriggerAMS[client] = false;
			
			//Scale Players
			PlayerDuration = INACTIVE;
			PlayerScale_TriggerAMS[client] = false;
			
			//Explosions
			Explosion_TriggerAMS[client] = false;
			
			//Drown
			DrownDuration = INACTIVE;
			Drown_TriggerAMS[client] = false;
			
			//Visualeffects
			EffectDuration = INACTIVE;
			Visual_TriggerAMS[client] = false;
		}
	}
	CreateTimer(0.1, EndSickness);
	CreateTimer(0.2, ResetScale);
	CreateTimer(0.3, EndDrowning);
	CreateTimer(0.4, ResetCaber);
}

public Action:Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	HookAbilities();
}

public HookAbilities()
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(!IsValidClient(client))
			continue;
		
		oldScale[client]=1.0;
		
		//Ion Cannon
		IonCannon_TriggerAMS[client]=false;
		
		//Delirium
		Delirium_TriggerAMS[client]=false;
		DeliriumDuration = INACTIVE;
		
		//Hellfire
		HellFire_TriggerAMS[client]=false;
		
		//Boss Scale
		BossScale_TriggerAMS[client]=false;
		BossDuration = INACTIVE;
		
		//Player Scale
		PlayerScale_TriggerAMS[client]=false;
		PlayerDuration = INACTIVE;
		
		//Explosion
		Explosion_TriggerAMS[client]=false;
		
		//Drown
		Drown_TriggerAMS[client]=false;
		DrownDuration = INACTIVE;
		
		//Visualeffect
		Visual_TriggerAMS[client]=false;
		EffectDuration = INACTIVE;
		
		new boss=FF2_GetBossIndex(client);
		if(boss>=0)
		{
			new BossMeleeweapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
			if (BossMeleeweapon != -1)
			{
				if (GetEntProp(BossMeleeweapon, Prop_Send, "m_iItemDefinitionIndex") == 307)	
				{
					SDKHook(client, SDKHook_PreThink, CaberReset);
				}
			}
			if(FF2_HasAbility(boss, this_plugin_name, IONCANNON))
			{
				IonCannon_TriggerAMS[client]=bool:FF2_GetAbilityArgument(boss, this_plugin_name, IONCANNON, 5);
				if(IonCannon_TriggerAMS[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, IONCANNON, IONCANNONALIAS);
				}
			}
			if(FF2_HasAbility(boss, this_plugin_name, DELIRIUM))
			{
				Delirium_TriggerAMS[client]=bool:FF2_GetAbilityArgument(boss, this_plugin_name, DELIRIUM, 3);
				if(Delirium_TriggerAMS[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, DELIRIUM, DELIRIUMALIAS);
				}
			}
			if(FF2_HasAbility(boss, this_plugin_name, HELLFIRE))
			{
				HellFire_TriggerAMS[client]=bool:FF2_GetAbilityArgument(boss, this_plugin_name, HELLFIRE, 6);
				if(HellFire_TriggerAMS[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, HELLFIRE, HELLFIREALIAS);
				}
			}
			if(FF2_HasAbility(boss, this_plugin_name, SCALEBOSS))
			{
				BossScale_TriggerAMS[client]=bool:FF2_GetAbilityArgument(boss, this_plugin_name, SCALEBOSS, 3);
				if(BossScale_TriggerAMS[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, SCALEBOSS, SCALEBOSSALIAS);
				}
			}
			if(FF2_HasAbility(boss, this_plugin_name, SCALEPLAYER))
			{
				PlayerScale_TriggerAMS[client]=bool:FF2_GetAbilityArgument(boss, this_plugin_name, SCALEPLAYER, 4);
				if(PlayerScale_TriggerAMS[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, SCALEPLAYER, SCALEPLAYERALIAS);
				}
			}
			if(FF2_HasAbility(boss, this_plugin_name, EXPLOSION))
			{
				Explosion_TriggerAMS[client]=bool:FF2_GetAbilityArgument(boss, this_plugin_name, EXPLOSION, 3);
				if(Explosion_TriggerAMS[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, EXPLOSION, EXPLOSIONALIAS);
				}
			}
			if(FF2_HasAbility(boss, this_plugin_name, DROWN))
			{
				Drown_TriggerAMS[client]=bool:FF2_GetAbilityArgument(boss, this_plugin_name, DROWN, 3);
				if(Drown_TriggerAMS[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, DROWN, DROWNALIAS);
				}
			}
			if(FF2_HasAbility(boss, this_plugin_name, EFFECT))
			{
				Visual_TriggerAMS[client]=bool:FF2_GetAbilityArgument(boss, this_plugin_name, EFFECT, 4);
				if(Visual_TriggerAMS[client])
				{
					AMS_InitSubability(boss, client, this_plugin_name, EFFECT, EFFECTALIAS);
				}
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
	ClientCommand(client, "r_screenoverlay 0");
}

public Action:FF2_OnAbility2(boss,const String:plugin_name[],const String:ability_name[],action)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return Plugin_Continue; // Because some FF2 forks still allow RAGE to be activated when the round is over....
		
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if (!strcmp(ability_name,IONCANNON))			//Ion Cannon by Peace Maker & LeGone
		Rage_IonCannon(client);
	else if (!strcmp(ability_name,DELIRIUM))			//Based on original Polish Nurse Rage by Kemsan
		Rage_Delirium(client);
	else if (!strcmp(ability_name,HELLFIRE))			//Based on original Pyrogas Rage by Kemsan	
		Rage_Hellfire(client);
	else if (!strcmp(ability_name,SCALEBOSS))		//Scale Boss	
		Rage_ScaleBoss(client);
	else if (!strcmp(ability_name,SCALEPLAYER))		//Scale players
		Rage_ScalePlayers(client);
	else if (!strcmp(ability_name,EXPLOSION))		//Fireball Explosion - variation of explosive_dance_rage by RainBolt Dash
		Rage_Explosion(client);
	else if (!strcmp(ability_name,DROWN))			//Drown players
		Rage_Drown(client);
	else if (!strcmp(ability_name,EFFECT))		//Visual effect on players
		Rage_VisualEffect(client);
	return Plugin_Continue;
}

Rage_VisualEffect(client)
{
	if(Visual_TriggerAMS[client]) // Prevent normal 100% RAGE activation if using AMS
		return;
	VIS_Invoke(client);
}

public bool:VIS_CanInvoke(client)
{
	return true;
}

public VIS_Invoke(client)
{
	new boss=FF2_GetBossIndex(client);
	VisualEffect=FF2_GetAbilityArgument(boss,this_plugin_name,EFFECT, 1);	        	//effect
	EffectDuration=GetEngineTime()+FF2_GetAbilityArgumentFloat(boss,this_plugin_name,EFFECT, 2); //duration
	EffectDistance=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,EFFECT, 3);	        //range
	
	decl Float:pos[3];
	decl Float:pos2[3];
	
	if(Visual_TriggerAMS[client])
	{
		new String:VisualSound[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, EFFECT, 5, VisualSound, sizeof(VisualSound)); // SOUND
	
		if(VisualSound[0]!='\0')
		{
			new String:sndPath[PLATFORM_MAX_PATH];
			Format(sndPath, sizeof(sndPath), "sound/%s", VisualSound);
			if(FileExists(sndPath, true))
			{
				if(!IsSoundPrecached(VisualSound))
				{
					PrecacheSound(VisualSound);
				}	
				EmitSoundToAll(VisualSound);
			}
		
		}
	}
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=FF2_GetBossTeam())
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if ((GetVectorDistance(pos,pos2)<EffectDistance)) {
			
				SetVariantInt(0);
				AcceptEntityInput(i, "SetForcedTauntCam");
				
				switch(VisualEffect)
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
				SDKHook(i, SDKHook_PreThink, Visual_Prethink);
			}
		}	
	}
}

public Visual_Prethink(client)
{
	EffectTick(client, GetEngineTime());
}

public EffectTick(client, Float:gameTime)
{
	if(gameTime>=EffectDuration)
	{
		EffectDuration=INACTIVE;
		for(new i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i))
			{
				ClientCommand(i, "r_screenoverlay 0");
			}
		}
		SDKUnhook(client, SDKHook_PreThink, Visual_Prethink);
	}
}


Rage_Drown(client)
{
	if(Drown_TriggerAMS[client]) // Prevent normal 100% RAGE activation if using AMS
		return;
	RDR_Invoke(client);
}

public bool:RDR_CanInvoke(client)
{
	return true;
}

public RDR_Invoke(client)
{
	new boss=FF2_GetBossIndex(client);
	DrownDuration=GetEngineTime()+FF2_GetAbilityArgumentFloat(boss,this_plugin_name,DROWN, 1); //duration
	DrownDistance=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,DROWN, 2);	        //range
	
	decl Float:pos[3];
	decl Float:pos2[3];
	
	if(Drown_TriggerAMS[client])
	{
		new String:DrownSound[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, DROWN, 4, DrownSound, sizeof(DrownSound)); // SOUND
	
		if(DrownSound[0]!='\0')
		{
			new String:sndPath[PLATFORM_MAX_PATH];
			Format(sndPath, sizeof(sndPath), "sound/%s", DrownSound);
			if(FileExists(sndPath, true))
			{
				if(!IsSoundPrecached(DrownSound))
				{
					PrecacheSound(DrownSound);
				}	
				EmitSoundToAll(DrownSound);
			}
		
		}
	}
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=FF2_GetBossTeam())
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if ((GetVectorDistance(pos,pos2)<DrownDistance)) {
				SDKHook(i, SDKHook_PreThink, DrownEvent);
			}
		}	
	}
}

public DrownEvent(client)
{
	SetEntProp(client, Prop_Send, "m_nWaterLevel", 3);
	DrownTick(client, GetEngineTime());
}

public DrownTick(client, Float:gameTime)
{
	if(gameTime>=DrownDuration)
	{
		DrownDuration=INACTIVE;
		for(new i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i))
			{
				SDKUnhook(i, SDKHook_PreThink, DrownEvent);
			}
		}
	}
}

public Action:EndDrowning(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SDKUnhook(i, SDKHook_PreThink, DrownEvent);
		}
	}
	return Plugin_Stop;
}

Rage_Explosion(client)
{
	if(Explosion_TriggerAMS[client]) // Prevent normal 100% RAGE activation if using AMS
		return;
	EXP_Invoke(client);
}

public bool:EXP_CanInvoke(client)
{
	return true;
}

public EXP_Invoke(client)
{
	new boss=FF2_GetBossIndex(client);
	new damage=FF2_GetAbilityArgument(boss,this_plugin_name,EXPLOSION, 1);	        //damage 
	new range=FF2_GetAbilityArgument(boss,this_plugin_name,EXPLOSION, 2);	        //damage radius

	new String:ExplosionSound[PLATFORM_MAX_PATH];
	if(Explosion_TriggerAMS[client])
	{
		FF2_GetAbilityArgumentString(boss, this_plugin_name, EXPLOSION, 4, ExplosionSound, sizeof(ExplosionSound)); // SOUND
	
		if(ExplosionSound[0]!='\0')
		{
			new String:sndPath[PLATFORM_MAX_PATH];
			Format(sndPath, sizeof(sndPath), "sound/%s", ExplosionSound);
			if(FileExists(sndPath, true))
			{
				if(!IsSoundPrecached(ExplosionSound))
				{
					PrecacheSound(ExplosionSound);
				}	
				EmitSoundToAll(ExplosionSound);
			}
		
		}
	}

	decl Float:vOrigin[3];
	
	gExplosion = 0;
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vOrigin);

	new Handle:data = CreateDataPack();
	CreateDataTimer(0.12, SetExplosion, data, TIMER_REPEAT);
	WritePackFloat(data, vOrigin[0]);
	WritePackFloat(data, vOrigin[1]);
	WritePackFloat(data, vOrigin[2]);
	WritePackCell(data, range); // Range
	WritePackCell(data, damage); // Damge
	WritePackCell(data, client);
	WritePackString(data, ExplosionSound);
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
	new client = ReadPackCell(data);
	decl String:s[512];
    	ReadPackString(data, s, 512);
	gExplosion++;
	
	if (gExplosion >= 15)
	{
		gExplosion = 0;
		return Plugin_Stop;
	}

	//SetExplodeAtClient(client, afterBurnDamage, rageDistance, DMG_BURN );
	
	for(new i=0;i<5;i++)
	{
		decl proj;
		proj = CreateEntityByName("env_explosion");   
		DispatchKeyValueFloat(proj, "DamageForce", 180.0);
		SetEntProp(proj, Prop_Data, "m_iMagnitude", 400, 4);
		SetEntProp(proj, Prop_Data, "m_iRadiusOverride", 400, 4);
		SetEntPropEnt(proj, Prop_Data, "m_hOwnerEntity", client);
		DispatchSpawn(proj);	
		
		AcceptEntityInput(proj, "Explode");
		AcceptEntityInput(proj, "kill");
	}
	if (gExplosion % 4 == 1) {
		SetExplodeAtClient(client, damage, range, DMG_BLAST );
		if (strlen(s))
		{
			EmitSoundToAll(s,client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, vOrigin, NULL_VECTOR, true, 0.0);
			for (new i=1; i<=MaxClients; i++)
				if (IsClientInGame(i) && (i!=client))
				{
					EmitSoundToClient(i,s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, vOrigin, NULL_VECTOR, true, 0.0);
				}
		}
	}
	return Plugin_Continue;	
}


Rage_ScaleBoss(client)
{
	if(BossScale_TriggerAMS[client]) // Prevent normal 100% RAGE activation if using AMS
		return;
	SCB_Invoke(client);
}

public bool:SCB_CanInvoke(client)
{
	return true;
}

public SCB_Invoke(client)
{
	new boss=FF2_GetBossIndex(client);
	oldScale[client]=GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	BossScale=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,SCALEBOSS, 1);	        //scale
	
	if(BossScale_TriggerAMS[client])
	{
		new String:ScaleBossSound[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, SCALEBOSS, 4, ScaleBossSound, sizeof(ScaleBossSound)); // SOUND
	
		if(ScaleBossSound[0]!='\0')
		{
			new String:sndPath[PLATFORM_MAX_PATH];
			Format(sndPath, sizeof(sndPath), "sound/%s", ScaleBossSound);
			if(FileExists(sndPath, true))
			{
				if(!IsSoundPrecached(ScaleBossSound))
				{
					PrecacheSound(ScaleBossSound);
				}	
				EmitSoundToAll(ScaleBossSound);
			}
		
		}
	}
	
	if(BossScale!=oldScale[client])
	{
	
		if(BossScale>oldScale[client])
		{
			new Float:curpos[3];
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", curpos);
			if(!IsSpotSafe(client, curpos, BossScale))
			{
				PrintHintText(client, "You were not resized %f times to avoid getting stuck!", BossScale);
				LogError("[PhatRages] %N was not resized %f times to avoid getting stuck!", client, BossScale);
				return;
			}
		}
		
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", BossScale);
		if(isHitBoxAvailable)
		{
			UpdatePlayerHitbox(client, BossScale);
		}
		SDKHook(client, SDKHook_PreThink, Scale_Prethink);
		if(BossDuration!=INACTIVE)
			BossDuration+=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, SCALEBOSS, 2);
		else
			BossDuration = GetEngineTime()+FF2_GetAbilityArgumentFloat(boss,this_plugin_name,SCALEBOSS, 2);	        //duration
	}
}
				
				
Rage_ScalePlayers(client)
{
	if(PlayerScale_TriggerAMS[client]) // Prevent normal 100% RAGE activation if using AMS
		return;
	SCP_Invoke(client);
}

public bool:SCP_CanInvoke(client)
{
	return true;
}

public SCP_Invoke(client)
{
	new boss=FF2_GetBossIndex(client);
	PlayerScale=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,SCALEPLAYER, 1);	//scale
	if(PlayerDuration!=INACTIVE)
		PlayerDuration+=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,SCALEPLAYER, 2);	        //duration
	else
		PlayerDuration=GetEngineTime()+FF2_GetAbilityArgumentFloat(boss,this_plugin_name,SCALEPLAYER, 2);	        //duration
	PlayerDistance=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,SCALEPLAYER, 3);	        //range
	
	decl Float:pos[3];
	decl Float:pos2[3];
	
	if(PlayerScale_TriggerAMS[client])
	{
		new String:ScalePlayerSound[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, SCALEPLAYER, 5, ScalePlayerSound, sizeof(ScalePlayerSound)); // SOUND
	
		if(ScalePlayerSound[0]!='\0')
		{
			new String:sndPath[PLATFORM_MAX_PATH];
			Format(sndPath, sizeof(sndPath), "sound/%s", ScalePlayerSound);
			if(FileExists(sndPath, true))
			{
				if(!IsSoundPrecached(ScalePlayerSound))
				{
					PrecacheSound(ScalePlayerSound);
				}	
				EmitSoundToAll(ScalePlayerSound);
			}
		
		}
	}
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=FF2_GetBossTeam())
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if ((GetVectorDistance(pos,pos2)<PlayerDistance)) 
			{
				oldScale[i]=GetEntPropFloat(i, Prop_Send, "m_flModelScale");
				if(PlayerScale!=oldScale[i])
				{
					
					if(PlayerScale>oldScale[i])
					{
						new Float:curpos[3];
						GetEntPropVector(i, Prop_Data, "m_vecOrigin", curpos);
						if(!IsSpotSafe(i, curpos, PlayerScale))
						{
							PrintHintText(i, "You were not resized %f times to avoid getting stuck!", PlayerScale);
							LogError("[PhatRages] %N was not resized %f times to avoid getting stuck!", i, PlayerScale);
							return;
						}
					}
					
					if(isHitBoxAvailable)
					{
						UpdatePlayerHitbox(i, PlayerScale);
					}
					
					SDKHook(i, SDKHook_PreThink, Scale_Prethink);
					SetEntPropFloat(i, Prop_Send, "m_flModelScale", PlayerScale);
				}
			}
		}	
	}
}

public Scale_Prethink(client)
{
	ScaleTick(client, GetEngineTime());
}

public ScaleTick(client, Float:gameTime)
{
	if(gameTime>=PlayerDuration)
	{
		PlayerDuration=INACTIVE;
		for(new i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i))
			{
				SDKUnhook(i, SDKHook_PreThink, Scale_Prethink);
				
				if(oldScale[client]>PlayerScale)
				{
					new Float:curpos[3];
					GetEntPropVector(i, Prop_Data, "m_vecOrigin", curpos);
					if(!IsSpotSafe(i, curpos, oldScale[i]))
					{
						PrintHintText(i, "You were not resized %f times to avoid getting stuck!", oldScale[i]);
						LogError("[PhatRages] %N was not resized %f times to avoid getting stuck!", i, oldScale[i]);
						return;
					}
				}
				
				SetEntPropFloat(i, Prop_Send, "m_flModelScale", oldScale[i]);
				if(isHitBoxAvailable)
				{
					UpdatePlayerHitbox(i, oldScale[i]);
				}
			}
		}
	}
	if(gameTime>=BossDuration)
	{
		BossDuration=INACTIVE;
		SDKUnhook(client, SDKHook_PreThink, Scale_Prethink);
		
		if(oldScale[client]>BossScale)
		{
			new Float:curpos[3];
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", curpos);
			if(!IsSpotSafe(client, curpos, oldScale[client]))
			{
				PrintHintText(client, "You were not resized %f times to avoid getting stuck!", oldScale[client]);
				LogError("[PhatRages] %N was not resized %f times to avoid getting stuck!", client, oldScale[client]);
				return;
			}
		}
		
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", oldScale[client]);
		if(isHitBoxAvailable)
		{
			UpdatePlayerHitbox(client, oldScale[client]);
		}
	}
}

public Action:ResetScale(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i))
		{
			SetEntPropFloat(i, Prop_Send, "m_flModelScale", oldScale[i] != 1.0 ? 1.0 : oldScale[i]);
			if(isHitBoxAvailable)
			{
				UpdatePlayerHitbox(i, oldScale[i] != 1.0 ? 1.0 : oldScale[i]);
			}
		}
	}
}

/*
	sarysa's safe resizing code
*/

new bool:ResizeTraceFailed;
new ResizeMyTeam;
public bool:Resize_TracePlayersAndBuildings(entity, contentsMask)
{
	if (IsValidClient(entity,true))
	{
		if (GetClientTeam(entity) != ResizeMyTeam)
		{
			ResizeTraceFailed = true;
		}
	}
	else if (IsValidEntity(entity))
	{
		static String:classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if ((strcmp(classname, "obj_sentrygun") == 0) || (strcmp(classname, "obj_dispenser") == 0) || (strcmp(classname, "obj_teleporter") == 0)
			|| (strcmp(classname, "prop_dynamic") == 0) || (strcmp(classname, "func_physbox") == 0) || (strcmp(classname, "func_breakable") == 0))
		{
			ResizeTraceFailed = true;
		}
	}

	return false;
}

bool:Resize_OneTrace(const Float:startPos[3], const Float:endPos[3])
{
	static Float:result[3];
	TR_TraceRayFilter(startPos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, Resize_TracePlayersAndBuildings);
	if (ResizeTraceFailed)
	{
		return false;
	}
	TR_GetEndPosition(result);
	if (endPos[0] != result[0] || endPos[1] != result[1] || endPos[2] != result[2])
	{
		return false;
	}
	
	return true;
}

// the purpose of this method is to first trace outward, upward, and then back in.
bool:Resize_TestResizeOffset(const Float:bossOrigin[3], Float:xOffset, Float:yOffset, Float:zOffset)
{
	static Float:tmpOrigin[3];
	tmpOrigin[0] = bossOrigin[0];
	tmpOrigin[1] = bossOrigin[1];
	tmpOrigin[2] = bossOrigin[2];
	static Float:targetOrigin[3];
	targetOrigin[0] = bossOrigin[0] + xOffset;
	targetOrigin[1] = bossOrigin[1] + yOffset;
	targetOrigin[2] = bossOrigin[2];
	
	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;
		
	tmpOrigin[0] = targetOrigin[0];
	tmpOrigin[1] = targetOrigin[1];
	tmpOrigin[2] = targetOrigin[2] + zOffset;

	if (!Resize_OneTrace(targetOrigin, tmpOrigin))
		return false;
		
	targetOrigin[0] = bossOrigin[0];
	targetOrigin[1] = bossOrigin[1];
	targetOrigin[2] = bossOrigin[2] + zOffset;
		
	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;
		
	return true;
}

bool:Resize_TestSquare(const Float:bossOrigin[3], Float:xmin, Float:xmax, Float:ymin, Float:ymax, Float:zOffset)
{
	static Float:pointA[3];
	static Float:pointB[3];
	for (new phase = 0; phase <= 7; phase++)
	{
		// going counterclockwise
		if (phase == 0)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 1)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 2)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 3)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 4)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 5)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 6)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 7)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymax;
		}

		for (new shouldZ = 0; shouldZ <= 1; shouldZ++)
		{
			pointA[2] = pointB[2] = shouldZ == 0 ? bossOrigin[2] : (bossOrigin[2] + zOffset);
			if (!Resize_OneTrace(pointA, pointB))
				return false;
		}
	}
		
	return true;
}

public bool:IsSpotSafe(clientIdx, Float:playerPos[3], Float:sizeMultiplier)
{
	ResizeTraceFailed = false;
	ResizeMyTeam = GetClientTeam(clientIdx);
	static Float:mins[3];
	static Float:maxs[3];
	mins[0] = -24.0 * sizeMultiplier;
	mins[1] = -24.0 * sizeMultiplier;
	mins[2] = 0.0;
	maxs[0] = 24.0 * sizeMultiplier;
	maxs[1] = 24.0 * sizeMultiplier;
	maxs[2] = 82.0 * sizeMultiplier;

	// the eight 45 degree angles and center, which only checks the z offset
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1], maxs[2])) return false;

	// 22.5 angles as well, for paranoia sake
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, maxs[1], maxs[2])) return false;

	// four square tests
	if (!Resize_TestSquare(playerPos, mins[0], maxs[0], mins[1], maxs[1], maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.75, maxs[0] * 0.75, mins[1] * 0.75, maxs[1] * 0.75, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.5, maxs[0] * 0.5, mins[1] * 0.5, maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.25, maxs[0] * 0.25, mins[1] * 0.25, maxs[1] * 0.25, maxs[2])) return false;
	
	return true;
}

/*
	Hitbox scaling
*/
stock UpdatePlayerHitbox(const client, Float:scale)
{
	new Float:vecScaledPlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecScaledPlayerMax[3] = { 24.5,  24.5, 83.0 };
	ScaleVector(vecScaledPlayerMin, scale);
	ScaleVector(vecScaledPlayerMax, scale);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}



Rage_Hellfire(client)
{
	if(HellFire_TriggerAMS[client]) // Prevent normal 100% RAGE activation if using AMS
		return;
	HLF_Invoke(client);
}

public bool:HLF_CanInvoke(client)
{
	return true;
}

public HLF_Invoke(client)
{
	new boss=FF2_GetBossIndex(client);
	hellsound=FF2_GetAbilityArgument(boss,this_plugin_name,HELLFIRE, 1);	        //sound
	rageDamage=FF2_GetAbilityArgument(boss,this_plugin_name,HELLFIRE, 2);	        //damage
	rageDistance=FF2_GetAbilityArgument(boss,this_plugin_name,HELLFIRE, 3);	//distance (range)
	afterBurnDamage=FF2_GetAbilityArgument(boss,this_plugin_name,HELLFIRE, 4);     //afterburn damage
	afterBurnDuration=FF2_GetAbilityArgument(boss,this_plugin_name,HELLFIRE, 5);	//afterburn duration (seconds)
	
	if(HellFire_TriggerAMS[client])
	{
		new String:HellFireSound[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, HELLFIRE, 7, HellFireSound, sizeof(HellFireSound)); // SOUND
	
		if(HellFireSound[0]!='\0')
		{
			new String:sndPath[PLATFORM_MAX_PATH];
			Format(sndPath, sizeof(sndPath), "sound/%s", HellFireSound);
			if(FileExists(sndPath, true))
			{
				if(!IsSoundPrecached(HellFireSound))
				{
					PrecacheSound(HellFireSound);
				}	
				EmitSoundToAll(HellFireSound);
			}
		
		}
	}
	
	new Float:vel[3];
	vel[2] = 20.0;
	TeleportEntity(client,  NULL_VECTOR, NULL_VECTOR, vel );
	SetExplodeAtClient( client, rageDamage, rageDistance, DMG_BURN );
	
	decl Float:pos[3];
	decl Float:pos2[3];
	decl Float:distancedistance;
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	for (new i = 1; i <= MaxClients; i++ ) {
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=FF2_GetBossTeam())
		{
			GetEntPropVector( i, Prop_Send, "m_vecOrigin", pos2 );
			distancedistance = GetVectorDistance( pos,pos2 );
			if ( !TF2_IsPlayerInCondition( i, TFCond_Ubercharged ) && !TF2_IsPlayerInCondition( i, TFCond_Bonked ) && ( distancedistance < rageDistance ) ) 
			{					
				TF2_IgnitePlayer( i, client );
				ClientCommand(i, "r_screenoverlay effects/tp_eyefx/tpeye2.vmt"); // fire flashes	
			}
		}
	}
	if(hellsound!=0)
	{
		EmitSoundToAll(PYROGAS_SND);
		EmitSoundToAll(PYROGAS_SND);
	}
	new Handle:pack = CreateDataPack();
	gAfterburn = 0;
	CreateDataTimer(1.0, AfterBurn, pack, TIMER_REPEAT);
	WritePackCell(pack, client);
	WritePackCell(pack, afterBurnDamage);
	WritePackCell(pack, afterBurnDuration);
	WritePackCell(pack, rageDistance);
	ResetPack(pack);
}
 
public Action:AfterBurn(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new packafterBurnDamage = ReadPackCell(pack);
	new packafterBurnDuration = ReadPackCell(pack);
	new packDistance = ReadPackCell(pack);
	
	if (gAfterburn >= packafterBurnDuration)
	{
		gAfterburn = 0;
		decl i;
		for( i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				ClientCommand(i, "r_screenoverlay 0");
			}	
		}
		
		return Plugin_Stop;
	}
	SetExplodeAtClient( client, packafterBurnDamage, packDistance, DMG_BURN );
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

SetDamageRadial( attacker, dmg,  Float:pos[3], Radiusradius, dmgtype )
{
	new i;
	new Float:dist;
	
	for  ( i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=FF2_GetBossTeam())
		{
			decl Float:pos2[3];
			GetEntPropVector( i, Prop_Send, "m_vecOrigin", pos2 );
			dist = GetVectorDistance( pos2, pos );
			
			pos[2] += 60;
			if (dist <= Radiusradius )
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


Rage_IonCannon(client)
{
	if(IonCannon_TriggerAMS[client]) // Prevent normal 100% RAGE activation if using AMS
		return;
	IOC_Invoke(client);
}

public bool:IOC_CanInvoke(client)
{
	return true;
}

public IOC_Invoke(client)
{
	new boss=FF2_GetBossIndex(client);
	distance=FF2_GetAbilityArgument(boss,this_plugin_name,IONCANNON, 1);	        //blast speed seconds
	IOCDist=FF2_GetAbilityArgument(boss,this_plugin_name,IONCANNON, 2);	        //damage radius
	IOCdamage=FF2_GetAbilityArgument(boss,this_plugin_name,IONCANNON, 3);	        //damage
	aimmode=FF2_GetAbilityArgument(boss,this_plugin_name,IONCANNON, 4);	        	//aim
	
	distance = distance * 29;
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vStart[3];
	
	if(IonCannon_TriggerAMS[client])
	{
		new String:IonCannonSound[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, IONCANNON, 6, IonCannonSound, sizeof(IonCannonSound)); // SOUND
	
		if(IonCannonSound[0]!='\0')
		{
			new String:sndPath[PLATFORM_MAX_PATH];
			Format(sndPath, sizeof(sndPath), "sound/%s", IonCannonSound);
			if(FileExists(sndPath, true))
			{
				if(!IsSoundPrecached(IonCannonSound))
				{
					PrecacheSound(IonCannonSound);
				}	
				EmitSoundToAll(IonCannonSound);
			}
		
		}
	}
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	if (aimmode==0) {

		new Handle:data = CreateDataPack();
		WritePackFloat(data, vOrigin[0]);
		WritePackFloat(data, vOrigin[1]);
		WritePackFloat(data, vOrigin[2]);
		WritePackCell(data, distance); // Distance
		WritePackFloat(data, 0.0); // nphi
		WritePackCell(data, IOCDist); // Range
		WritePackCell(data, IOCdamage); // Damge
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
			WritePackCell(data, IOCDist); // Range
			WritePackCell(data, IOCdamage); // Damge
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
	new Iondistance = ReadPackCell(data);
	new Float:nphi = ReadPackFloat(data);
	new Ionrange = ReadPackCell(data);
	new Iondamage = ReadPackCell(data);
	
	if (Iondistance > 0)
	{
		EmitSoundToAll("ambient/energy/weld1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);
		
		// Stage 1
		new Float:s=Sine(nphi/360*6.28)*Iondistance;
		new Float:c=Cosine(nphi/360*6.28)*Iondistance;
		
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
		s=Sine((nphi+45.0)/360*6.28)*Iondistance;
		c=Cosine((nphi+45.0)/360*6.28)*Iondistance;
		
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
		s=Sine((nphi+90.0)/360*6.28)*Iondistance;
		c=Cosine((nphi+90.0)/360*6.28)*Iondistance;
		
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
		s=Sine((nphi+135.0)/360*6.28)*Iondistance;
		c=Cosine((nphi+135.0)/360*6.28)*Iondistance;
		
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
	Iondistance -= 5;
	
	new Handle:nData = CreateDataPack();
	WritePackFloat(nData, startPosition[0]);
	WritePackFloat(nData, startPosition[1]);
	WritePackFloat(nData, startPosition[2]);
	WritePackCell(nData, Iondistance);
	WritePackFloat(nData, nphi);
	WritePackCell(nData, Ionrange);
	WritePackCell(nData, Iondamage);
	ResetPack(nData);

	if (Iondistance > -50)
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

		makeexplosion(0, -1, startPosition, "", Iondamage, Ionrange);

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
				if (dist < Ionrange)
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


Rage_Delirium(client)
{
	if(Delirium_TriggerAMS[client]) // Prevent normal 100% RAGE activation if using AMS
		return;
	DEL_Invoke(client);
}

public bool:DEL_CanInvoke(client)
{
	return true;
}

public DEL_Invoke(client)
{
	new boss=FF2_GetBossIndex(client);
	DeliriumDistance=FF2_GetAbilityArgument(boss,this_plugin_name,DELIRIUM, 1);	//rage distance
	
	decl Float:pos[3];
	decl Float:pos2[3];
	decl Float:Delidistance;
	
	if(Delirium_TriggerAMS[client])
	{
		new String:DeliriumSound[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, DELIRIUM, 4, DeliriumSound, sizeof(DeliriumSound)); // SOUND
	
		if(DeliriumSound[0]!='\0')
		{
			new String:sndPath[PLATFORM_MAX_PATH];
			Format(sndPath, sizeof(sndPath), "sound/%s", DeliriumSound);
			if(FileExists(sndPath, true))
			{
				if(!IsSoundPrecached(DeliriumSound))
				{
					PrecacheSound(DeliriumSound);
				}	
				EmitSoundToAll(DeliriumSound);
			}
		
		}
	}
	
	TF2_RemoveCondition( client, TFCond_Taunting );
		
	new Float:vel[3];
	vel[2]=20.0;
		
	TeleportEntity( client,  NULL_VECTOR, NULL_VECTOR, vel );
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", pos );
		
	for(new i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=FF2_GetBossTeam())
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			Delidistance = GetVectorDistance( pos, pos2 );
			if ( Delidistance < DeliriumDistance && GetClientTeam(i)!=FF2_GetBossTeam() )
			{
				SetVariantInt(0);
				AcceptEntityInput(i, "SetForcedTauntCam");
				fxDrug_Create( i );
				SDKHook(i, SDKHook_PreThink, Delirium_Prethink);
			}
		}	
	}
	
	GetEntPropVector( client, Prop_Send, "m_vecOrigin", pos );
		
	new Float:vec[3];
	GetClientAbsOrigin( client, vec );
	vec[2] += 10;
			
	TE_SetupBeamRingPoint(vec, 10.0, float(DeliriumDistance)/2, gLaser1, gHalo1, 0, 15, 0.5, 10.0, 0.0, { 128, 128, 128, 255 }, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec, 10.0, float(DeliriumDistance)/2, gLaser1, gHalo1, 0, 10, 0.6, 20.0, 0.5, { 75, 75, 255, 255 }, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec, 0.0, float(DeliriumDistance), gLaser1, gHalo1, 0, 0, 0.5, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec, 0.0, float(DeliriumDistance), gLaser1, gHalo1, 0, 0, 5.0, 100.0, 5.0, {64, 64, 128, 255}, 0, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec, 0.0, float(DeliriumDistance), gLaser1, gHalo1, 0, 0, 2.5, 100.0, 5.0, {32, 32, 64, 255}, 0, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec, 0.0, float(DeliriumDistance), gLaser1, gHalo1, 0, 0, 6.0, 100.0, 5.0, {16, 16, 32, 255}, 0, 0);
	TE_SendToAll();
	
	DeliriumDuration=GetEngineTime()+FF2_GetAbilityArgumentFloat(boss,this_plugin_name,DELIRIUM, 2);	//rage duration
}

public Delirium_Prethink(client)
{
	DrunkTick(client, GetEngineTime());
}

public DrunkTick(client, Float:gameTime)
{
	if(gameTime>=DeliriumDuration)
	{
		DeliriumDuration=INACTIVE;
		for(new i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				fxDrug_Kill(i);
				SDKUnhook(i, SDKHook_PreThink, Delirium_Prethink);
			}
		}
	}
}

public Action:EndSickness(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++ )
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			fxDrug_Kill( i );
			SDKUnhook(i, SDKHook_PreThink, Delirium_Prethink);
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
		
		ClientCommand(client, "r_screenoverlay 0");
		
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

stock bool:IsValidClient(client, bool:checkifAlive=false, bool:replayCheck=false)
{
	if (client <= 0 || client > MaxClients) return false;
	if(checkifAlive) return IsClientInGame(client) && IsPlayerAlive(client);
	if(replayCheck) return IsClientInGame(client) && (IsClientSourceTV(client) || IsClientReplay(client));
	return IsClientInGame(client);
}


stock Handle:FindPlugin(String: pluginName[])
{
	new String: buffer[256];
	new String: path[PLATFORM_MAX_PATH];
	new Handle: iter = GetPluginIterator();
	new Handle: pl = INVALID_HANDLE;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		Format(path, sizeof(path), "%s.ff2", pluginName);
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (StrContains(buffer, path, false) >= 0)
			break;
		else
			pl = INVALID_HANDLE;
	}
	
	CloseHandle(iter);

	return pl;
}

stock AMS_InitSubability(bossIdx, clientIdx, const String: pluginName[], const String: abilityName[], const String: prefix[])
{
	new Handle:plugin = FindPlugin("ff2_sarysapub3");
	if (plugin != INVALID_HANDLE)
	{
		new Function:func = GetFunctionByName(plugin, "AMS_InitSubability");
		if (func != INVALID_FUNCTION)
		{
			Call_StartFunction(plugin, func);
			Call_PushCell(bossIdx);
			Call_PushCell(clientIdx);
			Call_PushString(pluginName);
			Call_PushString(abilityName);
			Call_PushString(prefix);
			Call_Finish();
		}
		else
			LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability()");
	}
	else
		LogError("ERROR: Unable to initialize ff2_sarysapub3:AMS_InitSubability(). Make sure this plugin exists!");
}