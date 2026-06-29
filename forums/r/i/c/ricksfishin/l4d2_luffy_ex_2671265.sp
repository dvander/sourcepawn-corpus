#define PLUGIN_VERSION	"0.8"
/*
v 0.8 - improved item pick up condition.
	  - improved rocket.
	  - improved airstrike damage.
	  - add f18 model while launching air strike.
	  - added witch spawn limit.
	  - randomize between witch or lazer sight.
	  - added tank spawn limit.
	  - randomize between tank or explosive or incendiary.
	  - added new reward sound.
	  - added cvar for bot pick up.
	  - added shield.
	  - new sound.
	  - new model.
v 0.7 - little code cleanup.
	  - added ability summon airstrike.
	  - added item drop glowing.
	  - inproved visibility.
v 0.6 - update for luffy_rpg only.
v 0.5 - fixed weapon drop on empty ammo.
	  - added more weapon category.
v 0.4 - slight update.
v 0.3 - more update.
v 0.2 - addad beam spirit.
	  - change player colour more light.
	  - add cvar max HP regenerate.
	  - reset B&W on HP regen.
v 0.1 - fixed Luffy max spawn (Max 20).
	  - added 3 more model and more function.
v 0.0 - credit to Bacardi for the set parent problem.
	  - Credit to S-Slow for the awesome model.
	  - Credit to Powerload for the scrip explaination.
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define STAR_1_MDL		"models/editor/air_node_hint.mdl"
#define STAR_2_MDL		"models/editor/air_node.mdl"
#define MUSHROOM_MDL	"models/props_fairgrounds/elephant.mdl"
#define GROUND_MDL		"models/editor/overlay_helper.mdl"
#define CHAIN_MDL		"models/props_fairgrounds/alligator.mdl"
#define GOMBA_MDL		"models/props_fairgrounds/giraffe.mdl"
#define LUMA_MDL		"models/items/l4d_gift.mdl"
#define AXIS_MDL		"models/editor/axis_helper_thick.mdl"
#define JETF18_MDL		"models/f18/f18.mdl"
#define RANDOM_MDL		"random"
#define AMMO_MDL		"models/props/terror/ammo_stack.mdl"
#define SHIELD_MDL		"models/weapons/melee/w_riotshield.mdl"

#define REWARD_SOUND	"level/gnomeftw.wav"
#define HEALTH_SOUND	"ui/bigreward.wav"
#define SPEED_SOUND		"ui/pickup_guitarriff10.wav"
#define CLOCK_SOUND		"level/startwam.wav"
#define STRENGTH_SOUND	"ui/critical_event_1.wav"
#define TIMEOUT_SOUND	"ambient/machines/steam_release_2.wav"
#define TELEPOT_SOUND	"ui/menu_horror01.wav"
#define ZAP_SOUND_1		"ambient/energy/zap1.wav"
#define ZAP_SOUND_2		"ambient/energy/zap3.wav"
#define ZAP_SOUND_3		"ambient/energy/spark5.wav"
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define AIRSTRIK_SOUND1	"npc/soldier1/misc05.wav"
#define AIRSTRIK_SOUND2	"npc/soldier1/misc06.wav"
#define AIRSTRIK_SOUND3	"npc/soldier1/misc10.wav"
#define JETPASS_SOUND	"animation/jets/jet_by_01_lr.wav"
#define TANK_SOUND		"player/tank/voice/attack/tank_attack_03.wav"
#define WITCH_SOUND		"npc/witch/voice/attack/female_distantscream1.wav"

#define BEAMOBJECT		"models/editor/camera.mdl"
#define BEAMSPRITE		"materials/sprites/laserbeam.vmt"

#define MISSILE_DMY		"models/w_models/weapons/w_eq_molotov.mdl"
#define MISSILE_MDL		"models/missiles/f18_agm65maverick.mdl"
#define MISSILE_JNK		"models/props_junk/gascan001a.mdl"
#define MISSILE_SOUND1	"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define MISSILE_SOUND2	"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_2.wav"
#define SUPERSHIELD_SND	"ambient/alarms/klaxon1.wav"

#define DMG_GENERIC		0
#define DMG_EXPLOSIVE	-2122317758

#define SLOT_NUM		20
#define WEPN_NUM		200
#define BAZK_NUM		2000
#define MAX_WING		9

#define SMOKER			1
#define HUNTER			3
#define JOCKEY			5
#define TANK			8

new Handle:g_LuffyEnable;
new Handle:g_LuffyChance;
new Handle:g_LuffyMax;
new Handle:g_SuperCoolDown;
new Handle:g_ClockCoolDown;
new Handle:g_StrCoolDown;
new Handle:g_SuperSpeedMax;
new Handle:g_Message;
new Handle:g_HPregenMax;
new Handle:g_TankDrop;
new Handle:g_BotPickUp;
new Handle:g_BotDrop;
new Handle:g_DropWeapon;
new Handle:g_ItemGlow;
new Handle:g_MissaleNum;
new Handle:g_MissaleSelf;
new Handle:g_MissaleIncap;
new Handle:g_MissaleDmg;
new Handle:g_TankDamage;
new Handle:g_ItemStay;
new Handle:g_TankMax;
new Handle:g_WitchMax;
new Handle:g_Hinttext;
new Handle:g_ShieldLifeee;
new Handle:g_ShieldType;

new Handle:g_ItemLife[SLOT_NUM]				= { INVALID_HANDLE, ... };
new Handle:g_AddHealth[MAXPLAYERS+1]		= { INVALID_HANDLE, ... };
new Handle:g_SuperSpeed[MAXPLAYERS+1]		= { INVALID_HANDLE, ... };
new Handle:g_SuperStrength[MAXPLAYERS+1]	= { INVALID_HANDLE, ... };
new Handle:g_ClockDevice[MAXPLAYERS+1]		= { INVALID_HANDLE, ... };
new Handle:g_UnFreeze[MAXPLAYERS+1]			= { INVALID_HANDLE, ... };

new bool:g_ClientBTN[MAXPLAYERS+1][2];
new g_Rocket[BAZK_NUM][3];
new Float:g_lRocket[BAZK_NUM]				= { 0.0, ... };

new g_Shield[MAXPLAYERS+1][MAX_WING];
new Float:g_ShieldLife[MAXPLAYERS+1]		= { 0.0, ... };
new bool:g_ShieldInEffect[MAXPLAYERS+1]		= { false, ... };
new g_Attacker[MAXPLAYERS+1]				= { 0, ... };

new g_BeamSprite;
new g_Color[4]								= { 0, ... };
new g_ItemSlot[SLOT_NUM]					= { -1, ... };
new g_WepnSlot[WEPN_NUM]					= { -1, ... };
new g_CleintHP[MAXPLAYERS+1]				= { 0, ... };
new g_BeamSP[MAXPLAYERS+1]					= { 0, ... };
new g_BeamObject[MAXPLAYERS+1]				= { 0, ... };
new g_PropCount[MAXPLAYERS+1]				= { 0, ... };
new g_ClientHely[MAXPLAYERS+1]				= { -1, ... };
new Float:g_ItemLimitLife[SLOT_NUM]			= { 0.0, ... };

new First	= 0;
new Last	= 0;
new drawLuck[MAXPLAYERS+1][2];

new String:curMap[128];
new bool:Developer = false;

public Plugin:myinfo =
{
	name = "luffy items",
	author = "GsiX",
	description = "Si dead drop luffy item.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1819303#post1819303"
}

public OnPluginStart()
{
	CreateConVar( "l4d2_luffy_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD );
	g_LuffyEnable	= CreateConVar( "l4d2_luffy_enabled",			"1",		"0:Off, 1:On,  Toggle plugin on/of", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_LuffyChance	= CreateConVar( "l4d2_luffy_chance",			"40",		"0% - 100%,  Chance SI drop luffy item.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_LuffyMax		= CreateConVar( "l4d2_luffy_max",				"3",		"Number of luffy item droped at once ( Max 20 Luffy ).", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_SuperCoolDown	= CreateConVar( "l4d2_luffy_speed_cooldown",	"25",		"Time in seconds for Super Speed cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ClockCoolDown	= CreateConVar( "l4d2_luffy_clock_cooldown",	"25",		"Time in seconds for Clock Device cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_StrCoolDown	= CreateConVar( "l4d2_luffy_strength_cooldown",	"25",		"Time in seconds for Super Strength cool down.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_SuperSpeedMax	= CreateConVar( "l4d2_luffy_speedmax",			"80",		"0% - 100%, Max super speed added to normal speed.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_Message		= CreateConVar( "l4d2_luffy_announce",			"1",		"0:Off, 1:On, Toggle announce to chat when Luffy item acquired.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_HPregenMax	= CreateConVar( "l4d2_luffy_regen_max",			"100",		"How much max HP we regenerate.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_TankDrop		= CreateConVar( "l4d2_luffy_tank_drop",			"0",		"0:Off, 1:On, If on tank will drop luffy item.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_BotPickUp		= CreateConVar( "l4d2_luffy_bot_pickup",		"0",		"0:Off, 1:On, If on Survivor Bot allowed to pick up Luffy item.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_BotDrop		= CreateConVar( "l4d2_luffy_bot_kill",			"0",		"0:Off, 1:On, If off, luffy item will not drop if SI killed by Survivor Bot.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_DropWeapon	= CreateConVar( "l4d2_luffy_weapon_drop",		"3",		"0:off, 1:Drop T1 weapn, 2:Drop T2, 3:Drop Both.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ItemGlow		= CreateConVar( "l4d2_luffy_item_glow",			"6",		"0:off, 1:Light blue, 2:Pink, 3:Yellow, 4:Red, 5:Blue, 6:Random.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_MissaleNum	= CreateConVar( "l4d2_luffy_airstrike_num",		"40",		"How many missile we launce at one strike ( Max=1000, This effect pc performance).", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_MissaleSelf	= CreateConVar( "l4d2_luffy_airstrike_self",	"0",		"0:Off, 1:On, If on, missile allowed friendly fire.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_MissaleIncap	= CreateConVar( "l4d2_luffy_airstrike_incap",	"0",		"0:Disable, 1:Enable, If disable, missile will stop firing if player incap or ledge grab.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_MissaleDmg	= CreateConVar( "l4d2_luffy_airstrike_damage",	"20",		"How much damage our missile done, also effect shield damage", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_TankDamage	= CreateConVar( "l4d2_luffy_airstrike_tank",	"50",		"How much damage our missile done to the Tank also effect shield damage on tank", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ItemStay		= CreateConVar( "l4d2_luffy_item_life",			"25",		"How long luffy item droped stay on the ground. Min: 10 sec, Max:300 sec.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_TankMax		= CreateConVar( "l4d2_luffy_tank_max",			"1",		"If number of Tank more than this, reward replaced with somting else.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_WitchMax		= CreateConVar( "l4d2_luffy_witch_max",			"1",		"If number of Witch more than this, reward replaced with somting else.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_Hinttext		= CreateConVar( "l4d2_luffy_hint_msg",			"1",		"0:Off, 1:On, Toggel hint text announce", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ShieldLifeee	= CreateConVar( "l4d2_luffy_shield_life",		"25",		"How long our shield remaind on.. Min: 1 sec, Max:60 sec.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_ShieldType	= CreateConVar( "l4d2_luffy_shield_type",		"0",		"0:Shield follow body motion, 1:Shield allign to world plane", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig( true, "l4d2_luffy");
	
	HookEvent( "round_start",			EVENT_RoundStart );
	HookEvent( "round_end",				EVENT_RoundEnd );
	HookEvent( "player_death",			EVENT_PlayerDeath,			EventHookMode_Pre );
	HookEvent( "player_hurt",			EVENT_PlayerHurt,			EventHookMode_Post );
	HookEvent( "player_team",			EVENT_PlayerSpawn );
	HookEvent( "player_spawn",			EVENT_PlayerSpawn );
	HookEvent( "heal_begin",			EVENT_HealBegin,			EventHookMode_Post );
	HookEvent( "heal_success",			EVENT_HealSuccess,			EventHookMode_Post );
	HookEvent( "player_use",			EVENT_PlayerUse,			EventHookMode_Post );
	HookEvent( "survivor_rescued",		EVENT_SurvivorRescued );
	HookEvent( "upgrade_pack_used",		EVENT_UpgradePackUsed );
	HookEvent( "upgrade_pack_added",	EVENT_UpgradePackAdded );
	
	HookConVarChange( g_LuffyEnable,	CVAR_Changed );
	RegAdminCmd( 	"sm_bazoka",	CommandBazoka, ADMFLAG_ROOT );
}

public OnMapStart()
{
	PrecacheAll();
}

PrecacheAll()
{
	PrecacheModel( STAR_1_MDL );
	PrecacheModel( STAR_2_MDL );
	PrecacheModel( MUSHROOM_MDL );
	PrecacheModel( CHAIN_MDL );
	PrecacheModel( GOMBA_MDL );
	PrecacheModel( LUMA_MDL );
	PrecacheModel( GROUND_MDL );
	PrecacheModel( JETF18_MDL );
	PrecacheModel( AXIS_MDL );
	PrecacheModel( AMMO_MDL );
	PrecacheModel( SHIELD_MDL );
	
	PrecacheModel( MISSILE_DMY );
	PrecacheModel( MISSILE_MDL );
	PrecacheModel( MISSILE_JNK );

	PrecacheModel( BEAMOBJECT );
	g_BeamSprite	= PrecacheModel( BEAMSPRITE );

	PrecacheSound( REWARD_SOUND, true );
	PrecacheSound( HEALTH_SOUND, true );
	PrecacheSound( SPEED_SOUND, true );
	PrecacheSound( CLOCK_SOUND, true );
	PrecacheSound( STRENGTH_SOUND, true );
	PrecacheSound( TIMEOUT_SOUND, true );
	PrecacheSound( TELEPOT_SOUND, true );
	PrecacheSound( ZAP_SOUND_1, true );
	PrecacheSound( ZAP_SOUND_2, true );
	PrecacheSound( ZAP_SOUND_3, true );
	PrecacheSound( SOUND_FREEZE, true );
	PrecacheSound( AIRSTRIK_SOUND1, true );
	PrecacheSound( AIRSTRIK_SOUND2, true );
	PrecacheSound( AIRSTRIK_SOUND3, true );
	PrecacheSound( MISSILE_SOUND1, true );
	PrecacheSound( MISSILE_SOUND2, true );
	PrecacheSound( JETPASS_SOUND, true );
	PrecacheSound( TANK_SOUND, true );
	PrecacheSound( WITCH_SOUND, true );
	PrecacheSound( SUPERSHIELD_SND, true );
	
	/* not sure if this from pan xiohai or AutomicStryker */
	PrecacheParticle( "gas_explosion_pump" );
	PrecacheParticle( "electrical_arc_01_cp0" );
	PrecacheParticle( "electrical_arc_01_system" );
}

public Action:CommandBazoka( client, args )
{
	if ( IsValidClient( client ) && Developer )
	{
		g_ClientBTN[client][0]	= true;
		g_ClientBTN[client][1]	= true;
		switch( GetRandomInt( 1, 3 ))
		{
			case 1:
			{
				EmitSoundToClient( client, AIRSTRIK_SOUND1 );
			}
			case 2:
			{
				EmitSoundToClient( client, AIRSTRIK_SOUND2 );
			}
			case 3:
			{
				EmitSoundToClient( client, AIRSTRIK_SOUND3 );
			}
		}
		PrintHintText( client, "++ Press 'RELOAD + FIRE' when ready to call Air Strike ++" );
	}
	return Plugin_Handled;
}

public CVAR_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 )
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ))
			{
				ResetClient( i );
			}
		}
	}
}

public EVENT_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	GetCurrentMap( curMap, sizeof( curMap ));
	
	new max = GetConVarInt( g_LuffyMax );
	if ( max >= SLOT_NUM ) max = SLOT_NUM - 1;
	if ( max < 1 ) max = 1;
	
	for( new i = 1; i < BAZK_NUM; i++ )
	{
		g_Rocket[i][0]			= -1;
		g_Rocket[i][1]			= -1;
		g_Rocket[i][2]			= -1;
		g_lRocket[i]			= 0.0;
		
		if ( i <= max )
		{
			g_ItemSlot[i]		= -1;
			g_ItemLimitLife[i]	= 0.0;
			g_ItemLife[i]		= INVALID_HANDLE;
		}
		
		if ( i < WEPN_NUM )
		{
			g_WepnSlot[i]		= -1;
		}
		
		if ( i <= MAXPLAYERS )
		{
			g_ShieldLife[i]		= 0.0;
			g_ShieldInEffect[i]	= false;
			g_Shield[i][0]		= -1;
			g_Shield[i][1]		= -1;
			g_Shield[i][2]		= -1;
			g_Shield[i][3]		= -1;
			g_Shield[i][4]		= -1;
			g_Shield[i][5]		= -1;
			g_Shield[i][6]		= -1;
			g_Shield[i][7]		= -1;
			g_Shield[i][8]		= -1;
			
			drawLuck[i][0]		= 0;
			drawLuck[i][1]		= 0;
			g_ClientHely[i]		= -1;
			g_Attacker[i]		= 0;
			g_BeamSP[i]			= 0;
			g_PropCount[i]		= 0;
			g_CleintHP[i]		= 0;
			g_BeamObject[i]		= -1;
			g_ClientBTN[i][0]	= false;
			g_ClientBTN[i][1]	= false;
			g_AddHealth[i]		= INVALID_HANDLE;
			g_ClockDevice[i]	= INVALID_HANDLE;
			g_SuperSpeed[i]		= INVALID_HANDLE;
			g_SuperStrength[i]	= INVALID_HANDLE;
			g_UnFreeze[i]		= INVALID_HANDLE;
		}
	}
}

public EVENT_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	for( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsValidClient( i ))
		{
			ResetClient( i );
		}
	}
}

public EVENT_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( IsValidClient( client ))
	{
		g_ClientBTN[client][0]	= false;
		g_ClientBTN[client][1]	= false;
		ResetClient( client );
	}
}

public EVENT_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new client = GetClientOfUserId( GetEventInt( event, "victim" ));
	if ( IsValidClient( client ))
	{
		g_ClientBTN[client][0]	= false;
		g_ClientBTN[client][1]	= false;
		ResetClient( client );
	}
}

public EVENT_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( IsValidClient( client ))
	{
		decl String:NamePuckUp[128];
		
		new item = GetEventInt( event, "targetid" );
		for ( new i = 0; i < WEPN_NUM; i++ )
		{
			if ( g_WepnSlot[i] == item )
			{
				GetEntityClassname( item, NamePuckUp, sizeof( NamePuckUp ));
				if ( StrEqual( NamePuckUp, "upgrade_laser_sight", false ) || StrEqual( NamePuckUp, "weapon_ammo_spawn", false ))
				{
					ToggleGlowEnable( item, false );
					Item_Destroy( item );
				}
				else
				{
					RestockAmmo( client, NamePuckUp, item );
				}
				item = -1;
				g_WepnSlot[i] = -1;
				break;
			}
		}
	}
}

public EVENT_UpgradePackUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new client	= GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( IsValidClient( client ))
	{
		new item = GetEventInt( event, "upgradeid" );
		
		while ( drawLuck[client][0] == drawLuck[client][1] )
		{
			drawLuck[client][1] = GetRandomInt( 1, 18 );
		}
		drawLuck[client][0] = drawLuck[client][1];
			
		switch( drawLuck[client][0] )
		{
			case 1:	{ RunFreezeClient( client );									}
			case 2:	{ SetupPlayerShield( client, 1, 0 );							}
			case 3:	{ GivePlayerItems( client, "weapon_pipe_bomb" );				}
			case 4:	{ GivePlayerItems( client, "weapon_molotov" );					}
			case 5:	{ GivePlayerItems( client, "weapon_vomitjar" );					}
			case 6: { CheatCommand( client, "z_spawn", "tank auto" );				}
			case 7: { GivePlayerItems( client, "weapon_first_aid_kit" );			}
			case 8:	{ GivePlayerItems( client, "weapon_defibrillator" );			}
			case 9:	{ GivePlayerItems( client, "weapon_pain_pills" );				}
			case 10: { GivePlayerItems( client, "weapon_adrenaline" );				}
			case 11: { CheatCommand( client, "z_spawn", "witch auto" );				}
			case 12: { GivePlayerItems( client, "weapon_upgradepack_explosive" );	}
			case 13: { GivePlayerItems( client, "weapon_upgradepack_incendiary" );	}
			case 14: { CheatCommand( client, "director_force_panic_event", "" );	}
			case 15: { GivePlayerItems( client, "upgrade_laser_sight" );			}
			case 16: { GivePlayerItems( client, "weapon_ammo_spawn" );				}
			case 17: { return; }	// give him the package
			case 18: { return; }	// give him the package
		}
		
		Item_Destroy( item );
	}
}

public EVENT_UpgradePackAdded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new item = GetEventInt( event, "upgradeid" );
	if ( item != -1 )
	{
		Item_Destroy( item );
	}
}

public Action:EVENT_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new client		= GetClientOfUserId( GetEventInt( event, "userid" ));
	new attacker	= GetClientOfUserId( GetEventInt( event, "attacker" ));
	
	if ( IsValidInfected( client ) && IsValidClient( attacker ))
	{
		if ( g_SuperStrength[attacker] != INVALID_HANDLE )
		{
			SetupSpark( client );
		}
		
		if ( g_ShieldInEffect[attacker] )
		{
			SetupSpark( client );
			CallTheAnimation( client, 5 );
		}
	}
}

public Action:EVENT_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new client		= GetClientOfUserId( GetEventInt( event, "userid" ));
	new attacker	= GetClientOfUserId( GetEventInt( event, "attacker" ));
	new slot		= GetEmptySlot();
	
	if ( IsValidInfected( client ) && IsValidClient( attacker ) && slot != -1 )
	{
		if (( GetEntProp( client, Prop_Send, "m_zombieClass") == 8 && GetConVarInt( g_TankDrop ) == 0 ) || ( IsFakeClient( attacker ) && GetConVarInt( g_BotDrop ) == 0 ))
		{
			return;
		}
		
		new drop = true;
		decl Float:infPos[3];
		decl Float:surPos[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", infPos );
		
		for ( new i = 1; i <= MaxClients; i ++ )
		{
			if ( IsValidClient( i ))
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", surPos );
				if ( GetVectorDistance( infPos, surPos ) <= 70.0 )
				{
					drop = false;
					break;
				}
			}
		}

		if ( drop )
		{
			if ( GetRandomInt( 0, 100 ) <= GetConVarInt( g_LuffyChance ))
			{
				switch( GetRandomInt( 1, 10 ))
				{
					case 1:
					{
						DropItem( client, STAR_1_MDL, slot );
					}
					case 2:
					{
						DropItem( client, STAR_2_MDL, slot );
					}
					case 3:
					{
						DropItem( client, MUSHROOM_MDL, slot );
					}
					case 4:
					{
						DropItem( client, CHAIN_MDL, slot );
					}
					case 5:
					{
						DropItem( client, GROUND_MDL, slot );
					}
					case 6:
					{
						DropItem( client, AXIS_MDL, slot );
					}
					case 7:
					{
						DropItem( client, GOMBA_MDL, slot );
					}
					case 8:
					{
					DropItem( client, LUMA_MDL, slot );
					}
					case 9:
					{
						DropItem( client, JETF18_MDL, slot );
					}
					case 10:
					{
						DropItem( client, RANDOM_MDL, slot );
					}
				}
			}
		}
		
		if ( g_SuperStrength[attacker] != INVALID_HANDLE )
		{
			switch( GetRandomInt( 1, 2 ))
			{
				case 1:
				{
					SetUpExplosion( client, "gas_explosion_pump", 2.0 );
				}
				case 2:
				{
					SetUpExplosion( client, "electrical_arc_01_system", 5.0 );
					SetUpExplosion( client, "electrical_arc_01_cp0", 5.0 );
				}
			}
			if (( GetClientHealth( attacker ) + 2 ) <= 100 )
			{
				SetEntityHealth( attacker, ( GetClientHealth( attacker ) + 2 ));
			}
		}
	}
}

public Action:EVENT_HealBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new client = GetClientOfUserId( GetEventInt( event, "subject" ));
	
	if ( IsValidClient( client ))
	{
		g_CleintHP[client] = GetEntProp( client, Prop_Data, "m_iHealth" );
		if ( g_CleintHP[client] < 50 )
		{
			g_CleintHP[client] = 50;
		}
	}
}

public Action:EVENT_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new client = GetClientOfUserId( GetEventInt( event, "subject" ));
	
	if ( IsValidClient( client ))
	{
		if ( g_CleintHP[client] > 0 )
		{
			SetEntProp( client, Prop_Data, "m_iHealth", g_CleintHP[client] );
			
			g_AddHealth[client]		= CreateTimer( 0.1, Timer_AddHealth, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
			g_CleintHP[client]		= 0;
		}
	}
}

public Action:OnPlayerRunCmd( client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon )
{
	if (( buttons & IN_RELOAD ) && ( buttons & IN_ATTACK ) && ( g_ClientBTN[client][0] ))
	{
		g_ClientBTN[client][0]	= false;
		PrintHintTextToAll( "++ %N Has Launched Air Strike ++", client );
		
		switch( GetRandomInt( 1, 3 ))
		{
			case 1:
			{
				EmitSoundToAll( AIRSTRIK_SOUND1, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE );
			}
			case 2:
			{
				EmitSoundToAll( AIRSTRIK_SOUND2, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE );
			}
			case 3:
			{
				EmitSoundToAll( AIRSTRIK_SOUND3, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE );
			}
		}
		new miss = GetConVarInt( g_MissaleNum );
		if ( miss < 1 ) miss = 1;
		if ( miss > 1000 ) miss = 1000;
		
		new Float:pp	= 0.1;
		new Float:cc	= pp * float( miss );
		new Float:inc	= 0.0;
		for ( new i = 1; i <= miss; i++ )
		{
			CreateTimer( inc, Timer_CommandCenter, client );
			inc	+= pp;
			if ( inc >= cc )
			{
				new l = SummonMilitaryChopper( client );
				if ( l != -1 )
				{
					CreateTimer( inc, DeletIndex, l );
					CreateTimer( 0.1, Timer_ChopperLife, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_CommandCenter( Handle:timer, any:client )
{
	if ( IsValidClient( client ))
	{
		if ( GetConVarInt( g_MissaleIncap ) == 0 )
		{
			if ( GetEntProp( client, Prop_Send, "m_isIncapacitated" ) == 0 && GetEntProp( client, Prop_Send, "m_isHangingFromLedge" ) == 0 )
			{
				CommandCenter( client );
			}
		}
		else
		{
			CommandCenter( client );
		}
	}
}

public Action:Timer_BazokaLife( Handle:timer, any:index )
{
	g_lRocket[index] -= 0.1;
	if ( IsValidEntity( index ) && g_lRocket[index] >= 0.0 )
	{
		decl Float:_finPos[3];
		decl Float:_origin[3];
		decl Float:_angles[3];
		GetEntPropVector( index, Prop_Send, "m_vecOrigin", _origin );
		GetEntPropVector( index, Prop_Data, "m_angRotation", _angles );
		
		new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, DontHitSelf, index );
		if( TR_DidHit( trace ) )
		{ 
			TR_GetEndPosition( _finPos, trace );
			if ( GetVectorDistance( _origin, _finPos ) <= 50.0 )
			{
				SetupBazokaExplosion( index );
			}
		}
		else
		{
			SetupBazokaExplosion( index );
		}
		CloseHandle( trace );
		return Plugin_Continue;
	}
	
	SetupBazokaExplosion( index );
	
	return Plugin_Stop;
}

public Action:Timer_ChopperLife( Handle:timer, any:client )
{
	decl Float:_chopchopPos[3];
	decl Float:_chopchopAng[3];
	
	if ( IsValidClient( client ) && IsValidEntity( g_ClientHely[client] ))
	{
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", _chopchopPos );
		GetEntPropVector( client, Prop_Data, "m_angRotation", _chopchopAng );
		_chopchopPos[2] += 130.0;
		_chopchopAng[0] += 15.0;
		TeleportEntity( g_ClientHely[client], _chopchopPos,  _chopchopAng , NULL_VECTOR );
	}
	else
	{
		if ( IsValidEntity( g_ClientHely[client] ))
		{
			ToggleGlowEnable( g_ClientHely[client], false );
			Item_Destroy( g_ClientHely[client] );
		}
		
		if ( IsValidClient( client ))
		{
			EmitSoundToClient( client, JETPASS_SOUND );
		}
		g_ClientBTN[client][1]	= false;
		g_ClientHely[client]	= -1;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_AddHealth( Handle:timer, any:client )
{
	if ( IsValidClient( client ) && GetEntProp( client, Prop_Data, "m_iHealth" ) < GetConVarInt( g_HPregenMax ) )
	{
		SetEntProp( client, Prop_Data, "m_iHealth", ( GetEntProp( client, Prop_Data, "m_iHealth" ) + 1 ));
	}
	else
	{
		if ( IsValidClient( client ))
		{
			EmitSoundToClient( client, TIMEOUT_SOUND );
			SetEntProp( client, Prop_Send, "m_currentReviveCount", 0 );
			SetEntProp( client, Prop_Send, "m_bIsOnThirdStrike", 0 );
			SetEntPropFloat( client, Prop_Send, "m_healthBuffer", 0.0 );
		}
		
		if ( g_AddHealth[client] != INVALID_HANDLE )
		{
			KillTimer( g_AddHealth[client] );
			g_AddHealth[client] = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_ClockDevice( Handle:timer, any:client )
{
	g_PropCount[client] --;
	
	if ( IsValidClient( client ) && g_PropCount[client] > 0 )
	{
		SetUpBeamSpirit( client, "red", 1.5, 30.0, 180 );
		if ( GetConVarInt( g_Hinttext ) > 0 )
		{
			PrintHintText( client, "++ Clock Device last in %d ++", g_PropCount[client] );
		}
	}
	else
	{
		if ( IsValidClient( client ))
		{
			EmitSoundToClient( client, TIMEOUT_SOUND );
			if ( GetConVarInt( g_Hinttext ) > 0 )
			{
			
				PrintHintText( client, "-- Clock Device time out --" );
			}
		}

		ResetClient( client );
		
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_SuperSpeed( Handle:timer, any:client )
{
	g_PropCount[client] --;
	
	if ( IsValidClient( client ) && g_PropCount[client] > 0 )
	{
		SetUpBeamSpirit( client, "blue", 1.5, 30.0, 180 );
		if ( GetConVarInt( g_Hinttext ) > 0 )
		{
			PrintHintText( client, "++ Super Speed last in %d ++", g_PropCount[client] );
		}
	}
	else
	{
		if ( IsValidClient( client ))
		{
			EmitSoundToClient( client, TIMEOUT_SOUND );
			if ( GetConVarInt( g_Hinttext ) > 0 )
			{
				PrintHintText( client, "-- Super Speed time out --" );
			}
		}

		ResetClient( client );

		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_SuperStrength( Handle:timer, any:client )
{
	g_PropCount[client] --;
	
	if ( IsValidClient( client ) && g_PropCount[client] > 0 )
	{
		SetUpBeamSpirit( client, "green", 1.5, 30.0, 180 );
		if ( GetConVarInt( g_Hinttext ) > 0 )
		{
			PrintHintText( client, "++ Super Strength last in %d ++", g_PropCount[client] );
		}
	}
	else
	{
		if ( IsValidClient( client ))
		{
			EmitSoundToClient( client, TIMEOUT_SOUND );
			if ( GetConVarInt( g_Hinttext ) > 0 )
			{
				PrintHintText( client, "-- Super Strength time out --" );
			}
		}

		ResetClient( client );

		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_RandomLifeSpawn( Handle:timer, any:index )
{
	new id = GetIndex( index );
	if( id == -1 ) return Plugin_Stop;
	g_ItemLimitLife[id] -= 0.1; 

	if ( IsValidEntity( index ) && g_ItemLimitLife[id] > 0.1 )
	{
		RotateAdvance( index, 10.0, 1 );
		SetRandomModel( index );
		
		decl Float:myPos[3];
		decl Float:hePos[3];
		GetEntPropVector( index, Prop_Send, "m_vecOrigin", myPos );
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ))
			{
				if ( IsFakeClient( i ) && GetConVarInt( g_BotPickUp ) == 0 )
				{
					continue;
				}
				
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", hePos );
				if ( GetVectorDistance( myPos, hePos ) < 50.0 )
				{
					decl String:modName[256];
					GetEntPropString( index, Prop_Data, "m_ModelName", modName, sizeof( modName ));
					if ( StrEqual( modName, JETF18_MDL, false ) && g_ClientBTN[i][1] )
					{
						continue;
					}
					else if ( StrEqual( modName, MUSHROOM_MDL, false) && GetEntProp( i, Prop_Data, "m_iHealth" ) >= GetConVarInt( g_HPregenMax ) )
					{
						continue;
					}
					if ( g_ClockDevice[i] != INVALID_HANDLE || g_SuperSpeed[i] != INVALID_HANDLE || g_AddHealth[i] != INVALID_HANDLE || g_SuperStrength[i] != INVALID_HANDLE || g_ShieldInEffect[i]|| g_ItemLife[id] != INVALID_HANDLE )
					{
						continue;
					}
					
					ToggleGlowEnable( index, false );
					RewardPicker( i, index );
					Item_Destroy( index );
					break;
				}
			}
		}
	}
	else
	{
		if ( g_ItemLife[id] != INVALID_HANDLE )
		{
		    KillTimer( g_ItemLife[id] );
		    g_ItemLife[id] = INVALID_HANDLE;
		}
		g_ItemSlot[id] = -1;
		
		if ( IsValidEntity( index ))
		{
			ToggleGlowEnable( index, false );
			Item_Destroy( index );
		}
		return Plugin_Stop;
	}
	//PrintToChatAll(" Item Spining");
	return Plugin_Continue;
}

public  Action:Timer_ItemLifeSpawn( Handle:timer, any:index )
{
	new id = GetIndex( index );
	if( id == -1 ) return Plugin_Stop;
	g_ItemLimitLife[id] -= 0.1; 

	if ( IsValidEntity( index ) && g_ItemLimitLife[id] > 0.1 )
	{
		RotateAdvance( index, 10.0, 1 );
		
		decl Float:myPos[3];
		decl Float:hePos[3];
		GetEntPropVector( index, Prop_Send, "m_vecOrigin", myPos );
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ))
			{
				if ( IsFakeClient( i ) && GetConVarInt( g_BotPickUp ) == 0 )
				{
					continue;
				}
				
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", hePos );
				if ( GetVectorDistance( myPos, hePos ) < 50.0 )
				{
					decl String:moName[256];
					GetEntPropString( index, Prop_Data, "m_ModelName", moName, sizeof( moName ));
					if ( StrEqual( moName, JETF18_MDL, false ) && g_ClientBTN[i][1] )
					{
						continue;
					}
					else if ( StrEqual( moName, MUSHROOM_MDL, false) && GetEntProp( i, Prop_Data, "m_iHealth" ) >= GetConVarInt( g_HPregenMax ) )
					{
						continue;
					}
					if ( g_ClockDevice[i] != INVALID_HANDLE || g_SuperSpeed[i] != INVALID_HANDLE || g_AddHealth[i] != INVALID_HANDLE || g_SuperStrength[i] != INVALID_HANDLE || g_ShieldInEffect[i]   )
					
					{
						continue;
					}
					
					ToggleGlowEnable( index, false );
					RewardPicker( i, index );
					Item_Destroy( index );
					break;
				}
			}
		}
	}
	else
	{
		if ( g_ItemLife[id] != INVALID_HANDLE )
		{
		 KillTimer( g_ItemLife[id] );
		 g_ItemLife[id] = INVALID_HANDLE;
		}
		g_ItemSlot[id] = -1;
		
		if ( IsValidEntity( index ))
		{
			ToggleGlowEnable( index, false );
			Item_Destroy( index );
		}
		return Plugin_Stop;
	}
	//PrintToChatAll(" Item Spining");
	return Plugin_Continue;
}

public Action:Timer_FreePlayer( Handle:timer, any:client )
{
	g_PropCount[client]--;
	
	if( IsValidClient( client ) && g_PropCount[client] > 0 && GetEntProp( client, Prop_Send, "m_isIncapacitated" ) == 0 && GetEntProp( client, Prop_Send, "m_isHangingFromLedge" ) == 0 )
	{
		if ( GetConVarInt( g_Hinttext ) > 0 )
		{
			PrintHintText( client, "-- You will be unfreze in %d --", g_PropCount[client] );
		}
	}
	else
	{
		g_PropCount[client] = 0;
		if ( IsValidClient( client ))
		{
			SetEntityMoveType( client, MOVETYPE_WALK );
			SetColour( client, 255, 255, 255, 255 );
			if ( GetConVarInt( g_Hinttext ) > 0 )
			{
				PrintHintText( client, "++ You were unfrezed ++" );
			}
			EmitSoundToClient( client, SOUND_FREEZE );
		}
		if ( g_UnFreeze[client] != INVALID_HANDLE )
		{
			KillTimer( g_UnFreeze[client] );
			g_UnFreeze[client] = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_RestoreCollution( Handle:timer, any:client )
{
	if ( IsInGame( client ) && IsPlayerAlive( client ))
	{
		SetEntityMoveType( client, MOVETYPE_WALK );
	}
}

public Action:Timer_LuckInfected( Handle:timer, any:client )
{
	new attacker = g_Attacker[client];
	if ( IsValidClient( client ) && IsValidInfected( attacker ) && IsPlayerAlive( attacker ))
	{
		EmitSoundToClient( client, HEALTH_SOUND );
		
		if ( GetEntProp( attacker, Prop_Send, "m_zombieClass") == SMOKER || GetEntProp( attacker, Prop_Send, "m_zombieClass") == HUNTER )
		{
			SetEntityMoveType( attacker, MOVETYPE_NOCLIP );
			CreateTimer( 0.1, Timer_RestoreCollution, attacker );
			
			if ( GetEntProp( client, Prop_Send, "m_isIncapacitated" ) == 1 )
			{
				CheatCommand( client, "give", "health" );
				SetEntProp( client, Prop_Send, "m_isHangingFromLedge", 0 );
				SetEntProp( client, Prop_Send, "m_isIncapacitated", 0 );
				SetEntProp( client, Prop_Data, "m_iHealth", 1 );
				SetEntPropFloat( client, Prop_Send, "m_healthBuffer", GetConVarFloat( FindConVar( "survivor_revive_health" )));
			}
		}
		else if ( GetEntProp( attacker, Prop_Send, "m_zombieClass") == JOCKEY )
		{
			CheatCommand( attacker, "dismount", "" );
		}
	}
	g_Attacker[client] = 0;
}

public Action:Timer_ShieldRotate( Handle:timer, any:client )
{
	g_ShieldLife[client] -= 0.1;
	
	if ( IsValidClient( client ) && IsValidEntity( g_Shield[client][0] ) && g_ShieldLife[client] > 0.0 )
	{
		if ( GetConVarInt( g_ShieldType ) == 1 )
		{
			decl Float:s_currPos[3];
			decl Float:s_currAng[3];
			GetEntPropVector( client, Prop_Send, "m_vecOrigin", s_currPos );
			GetEntPropVector( g_Shield[client][0], Prop_Data, "m_angRotation", s_currAng );
			s_currPos[2] += 50.0;
			TeleportEntity( g_Shield[client][0], s_currPos, s_currAng, NULL_VECTOR );
			RotateAdvance( g_Shield[client][0], 25.0, 1 );
		}
		else
		{
			RotateAdvance( g_Shield[client][0], 25.0, 0 );
		}
		return Plugin_Continue;
	}
	else
	{
		for ( new i = ( MAX_WING - 1 ); i >= 0; i-- )
		{
			if ( g_Shield[client][i] != -1 )
			{
				Item_Destroy( g_Shield[client][i] );
			}
			g_Shield[client][i] = -1;
		}
		g_ShieldLife[client] = 0.0;
	}
	return Plugin_Stop;
}

public Action:Timer_WingDamage( Handle:timer, any:client )
{
	if ( IsValidClient( client ) && IsValidEntity( g_Shield[client][0] ))
	{
		decl Float:wgPos[3];
		decl Float:ddPos[3];
		decl String:nameType[128];
		new ddamag = GetConVarInt( g_MissaleDmg );
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", wgPos );
		
		new eCount = GetEntityCount();
		for ( new i = 1; i <= eCount; i++ )
		{
			if ( !IsValidEntity( i )) continue;
			
			if ( i <= MaxClients )
			{
				if ( IsValidInfected( i ) && IsPlayerAlive( i ))
				{
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", ddPos );
					if ( GetVectorDistance( wgPos, ddPos ) <= 100.0 )
					{
						if ( GetEntProp( i, Prop_Send, "m_zombieClass" ) == TANK )
						{
							DealDamage( i, GetConVarInt( g_TankDamage ), client, DMG_GENERIC, "weapon_rifle" );
							CreateShieldPush( client, i, 200.0 );
						}
						else
						{
							DealDamage( i, ddamag, client, DMG_GENERIC, "weapon_rifle" );
							CreateShieldPush( client, i, 200.0 );
						}
					}
				}
			}
			else
			{
				GetEntityClassname( i, nameType, sizeof( nameType ));
				if ( StrContains( nameType, "infected", false) != -1 )
				{
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", ddPos );
					if ( GetVectorDistance( wgPos, ddPos ) <= 100.0 )
					{
						DealDamage( i, ddamag, client, DMG_GENERIC, "weapon_rifle" );
						CreateShieldPush( client, i, 200.0 );
					}
				}
				if ( StrContains( nameType, "witch", false) != -1 )
				{
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", ddPos );
					if ( GetVectorDistance( wgPos, ddPos ) <= 100.0 )
					{
						DealDamage( i, ddamag, client, DMG_GENERIC, "weapon_rifle" );
						CreateShieldPush( client, i, 200.0 );
					}
				}
			}
		}
		return Plugin_Continue;
	}
	
	g_ShieldInEffect[client] = false;
	
	return Plugin_Stop;
}

public Action:Timer_WingPush( Handle:timer, any:client )
{
	if ( IsValidClient( client ) && IsValidEntity( g_Shield[client][0] ))
	{
		decl Float:wgPos[3];
		decl Float:ddPos[3];
		decl String:nameType[128];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", wgPos );
		
		new eCount = GetEntityCount();
		for ( new i = 1; i <= eCount; i++ )
		{
			if ( !IsValidEntity( i )) continue;
			
			if ( i <= MaxClients )
			{
				if ( IsValidInfected( i ) && IsPlayerAlive( i ))
				{
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", ddPos );
					if ( GetVectorDistance( wgPos, ddPos ) <= 100.0 )
					{
						if ( GetEntProp( i, Prop_Send, "m_zombieClass" ) == TANK )
						{
							DealDamage( i, 1, client, DMG_EXPLOSIVE, "weapon_rifle" );
							CreateShieldPush( client, i, 800.0 );
						}
						else
						{
							DealDamage( i, 1, client, DMG_EXPLOSIVE, "weapon_rifle" );
							CreateShieldPush( client, i, 800.0 );
						}
					}
				}
			}
			else
			{
				GetEntityClassname( i, nameType, sizeof( nameType ));
				if ( StrContains( nameType, "infected", false) != -1 )
				{
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", ddPos );
					if ( GetVectorDistance( wgPos, ddPos ) <= 100.0 )
					{
						DealDamage( i, 1, client, DMG_EXPLOSIVE, "weapon_rifle" );
						CreateShieldPush( client, i, 800.0 );
					}
				}
				if ( StrContains( nameType, "witch", false) != -1 )
				{
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", ddPos );
					if ( GetVectorDistance( wgPos, ddPos ) <= 100.0 )
					{
						DealDamage( i, 1, client, DMG_EXPLOSIVE, "weapon_rifle" );
						CreateShieldPush( client, i, 800.0 );
					}
				}
			}
		}
		return Plugin_Continue;
	}
	
	g_ShieldInEffect[client] = false;
	
	return Plugin_Stop;
}

public Action:Timer_LevelupAnimation( Handle:timer, any:client )
{
	if ( IsValidClient( client ))
	{
		decl String:mmmm[32];
		new bool:Continue1 = false;
		new bool:Continue2 = false;
		decl Float:lvlPos[3];
		decl Float:lvlAng[3];
		decl Float:lvlNew[3];
		decl Float:lvlBuf[3];
		decl Float:lvlVec[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", lvlPos );
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", lvlNew );
		
		lvlPos[2] += 30.0;
		lvlNew[0] += GetRandomFloat( -100.0, 100.0 );
		lvlNew[1] += GetRandomFloat( -100.0, 100.0 );
		lvlNew[2] += GetRandomFloat( 100.0, 130.0 );
		
		MakeVectorFromPoints( lvlNew, lvlPos, lvlBuf );
		GetVectorAngles( lvlBuf, lvlAng );
		
		new upLevelBody = CreateEntityByName( "molotov_projectile" );
		if( upLevelBody != -1 )
		{
			DispatchKeyValue( upLevelBody, "model", MISSILE_DMY );
			DispatchKeyValueVector( upLevelBody, "origin", lvlNew );
			DispatchKeyValueVector( upLevelBody, "Angles", lvlAng );
			SetEntPropFloat( upLevelBody, Prop_Send,"m_flModelScale",0.01 );
			SetEntProp( upLevelBody, Prop_Send, "m_CollisionGroup", 1 );
			SetEntPropEnt( upLevelBody, Prop_Data, "m_hOwnerEntity", -1 );
			SetEntityGravity( upLevelBody, 0.01 ); 
			DispatchSpawn( upLevelBody );
			
			Continue1 = true;
		}
		
		if ( !Continue1 ) return;
		
		new upLevel = CreateEntityByName( "prop_dynamic_override" );
		if ( upLevel != -1 )
		{
			SetEntPropEnt( upLevel, Prop_Data, "m_hOwnerEntity", -1)	;
			Format( mmmm, sizeof( mmmm ), "missile%d", upLevelBody );
			DispatchKeyValue( upLevelBody, "targetname", mmmm );
			DispatchKeyValue( upLevel, "model", JETF18_MDL );  
			DispatchKeyValue( upLevel, "parentname", mmmm);  
			DispatchKeyValueVector( upLevel, "origin", lvlNew );
			DispatchKeyValueVector( upLevel, "Angles", lvlAng );
			SetEntPropFloat( upLevel, Prop_Send, "m_flModelScale", 0.035 );
			SetEntProp( upLevel, Prop_Send, "m_CollisionGroup", 1 );
			SetVariantString( mmmm );
			AcceptEntityInput( upLevel, "SetParent", upLevel, upLevel, 0 );
			DispatchSpawn( upLevel );
			SetColour( upLevel, 150, 150, 150, 180 );
			Continue2 = true;
		}
		
		if ( !Continue2 ) return;
		
		lvlAng[0] += GetRandomFloat( -5.0, 5.0 );
		lvlAng[1] += GetRandomFloat( -5.0, 5.0 );
		
		GetAngleVectors( lvlAng, lvlVec, NULL_VECTOR, NULL_VECTOR );
		NormalizeVector( lvlVec, lvlVec );
		ScaleVector( lvlVec, 500.0 );
		TeleportEntity( upLevelBody, NULL_VECTOR, NULL_VECTOR, lvlVec );
		CreateTimer( 0.19, DeletIndex, upLevel, TIMER_FLAG_NO_MAPCHANGE );
		CreateTimer( 0.20, DeletIndex, upLevelBody, TIMER_FLAG_NO_MAPCHANGE );
	}
}

CallTheAnimation( client, number )
{
	if ( IsValidClient( client ))
	{
		new Float:cc = 0.0;
		for ( new i = 1; i <= number; i++ )
		{
			CreateTimer( cc, Timer_LevelupAnimation, client, TIMER_FLAG_NO_MAPCHANGE );
			cc += 0.1;
		}
	}
}

DropItem( client, const String:Model[], slotNumber )
{
	if ( !StrEqual( Model, "random", false ))
	{
		if ( !IsModelPrecached( Model ))
		{
			PrecacheModel( Model );
		}
	}
	
	g_ItemSlot[slotNumber] = CreateEntityByName( "prop_dynamic_override" );
	if ( g_ItemSlot[slotNumber] != -1 )
	{
		new Float:life = GetConVarFloat( g_ItemStay );
		if ( life > 300.0 ) life = 300.0;
		if ( life < 10.0 ) life = 10.0;
		
		g_ItemLimitLife[slotNumber] = life;
		
		new Float:vecPos[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", vecPos );
		vecPos[2] += 20.0;
	
		DispatchKeyValueFloat( g_ItemSlot[slotNumber], "fademindist", 10000.0);
		DispatchKeyValueFloat( g_ItemSlot[slotNumber], "fademaxdist", 20000.0);
		DispatchKeyValueFloat( g_ItemSlot[slotNumber], "fadescale", 0.0); 
		
		if( StrEqual( Model, RANDOM_MDL, false ))
		{
			DispatchKeyValue( g_ItemSlot[slotNumber], "model", STAR_1_MDL );
			DispatchSpawn( g_ItemSlot[slotNumber] );
			SetColour( g_ItemSlot[slotNumber], 255, 255, 255, 220 );
			g_ItemLife[slotNumber] = CreateTimer( 0.1, Timer_RandomLifeSpawn, g_ItemSlot[slotNumber], TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		}
		else
		{
			DispatchKeyValue( g_ItemSlot[slotNumber], "model", Model );
			DispatchSpawn( g_ItemSlot[slotNumber] );
			
			if ( StrEqual( Model, JETF18_MDL, false ))
			{
				SetEntPropFloat( g_ItemSlot[slotNumber], Prop_Send, "m_flModelScale", 0.05 );
			}
			g_ItemLife[slotNumber] = CreateTimer( 0.1, Timer_ItemLifeSpawn, g_ItemSlot[slotNumber], TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		}
		SetEntProp( g_ItemSlot[slotNumber], Prop_Send, "m_CollisionGroup", 1 ); 
		ToggleGlowEnable( g_ItemSlot[slotNumber], true );
		TeleportEntity( g_ItemSlot[slotNumber], vecPos, NULL_VECTOR, NULL_VECTOR);
	}
}

SetRandomModel( item )
{
	if ( IsValidEntity( item ))
	{
		new String:ModelRandom[128];
		
		while ( Last == First )
		{
			First = GetRandomInt( 1, 9 );
		}
		Last = First;
		
		switch( Last )
		{
			case 1: { ModelRandom = STAR_1_MDL		;}
			case 2: { ModelRandom = STAR_2_MDL		;}
			case 3: { ModelRandom = MUSHROOM_MDL	;}
			case 4: { ModelRandom = CHAIN_MDL		;}
			case 5: { ModelRandom = GOMBA_MDL		;}
			case 6: { ModelRandom = LUMA_MDL		;}
			case 7: { ModelRandom = AXIS_MDL		;}
			case 8: { ModelRandom = JETF18_MDL		;}
			case 9: { ModelRandom = GROUND_MDL		;}
		}
		SetEntityModel( item, ModelRandom );
		
		if ( Last == 8 )
		{
			SetEntPropFloat( item, Prop_Send, "m_flModelScale", 0.05 );
		}
		else
		{
			SetEntPropFloat( item, Prop_Send, "m_flModelScale", 1.0 );
		}
	}
}

RewardPicker( client, ent )
{
	if ( IsValidClient( client ))
	{
		decl String:mName[256];
		GetEntPropString( ent, Prop_Data, "m_ModelName", mName, sizeof(mName));

		if ( StrEqual( mName, STAR_1_MDL, false))
		{
			RunClockDevice( client );
			CallTheAnimation( client, 10 );
		}
		else if ( StrEqual( mName, STAR_2_MDL, false))
		{
			RunSuperSpeed( client );
			CallTheAnimation( client, 10 );
		}
		else if ( StrEqual( mName, MUSHROOM_MDL, false))
		{
			RunClientHP( client );
			CallTheAnimation( client, 10 );
		}
		else if ( StrEqual( mName, GROUND_MDL, false))
		{
			RunSuperStrength( client );
			CallTheAnimation( client, 10 );
		}
		else if ( StrEqual( mName, CHAIN_MDL, false))
		{
			new item = GetRandomInt( 1, 11 );
			if ( item == 1 )
			{
				GivePlayerItems( client, "upgrade_laser_sight" );
			}
			else if ( item == 2 )
			{
				GivePlayerItems( client, "weapon_ammo_spawn" );
			}
			else if ( item > 2 && item < 7 )
			{
				if ( FindEntity( client, "Witch" ) < GetConVarInt( g_WitchMax ))
				{
					CheatCommand( client, "z_spawn", "witch auto" );
				}
				else
				{
					switch( GetRandomInt( 1, 5 ))
					{
						case 1: { RunFreezeClient( client ); 								}
						case 2: { RewardTeleport( client, "Witch" );						}
						case 3: { RunSuperSpeed( client ); 									}
						case 4: { SetupPlayerShield( client, 1, 0 );						}
						case 5: { CheatCommand( client, "director_force_panic_event", "" );	}
					}
				}
			}
			else if ( item >= 7 && item < 11 )
			{
				switch( GetRandomInt( 1, 4 ))
				{
					case 1:
					{
						EmitSoundToClient( client, REWARD_SOUND );
						if ( GetConVarInt( g_Message ) > 0 )
						{
							PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05Your got empty luck!!" );
						}
					}
					case 2:	{ RunFreezeClient( client );								}
					case 3: { RewardTeleport( client, "Survivor" );						}
					case 4: { SetupPlayerShield( client, 1, 0 );						}
				}
			}
			else
			{
				switch( GetRandomInt( 1, 3 ))
				{
					case 1: { GivePlayerItems( client, "weapon_defibrillator" );		}
					case 2: { GivePlayerItems( client, "weapon_pain_pills" );			}
					case 3: { GivePlayerItems( client, "weapon_adrenaline" );			}
				}
			}
		}
		else if ( StrEqual( mName, GOMBA_MDL, false))
		{
			new item = GetRandomInt( 1, 11 );
			if ( item == 1 )
			{
				GivePlayerItems( client, "weapon_upgradepack_explosive" );
			}
			else if ( item == 2 )
			{
				GivePlayerItems( client, "weapon_upgradepack_incendiary" );
			}
			else if ( item >= 3 && item < 7 )
			{
				if ( FindEntity( client, "Tank" ) < GetConVarInt( g_TankMax ))
				{
					CheatCommand( client, "z_spawn", "tank auto" );
				}
				else
				{
					switch( GetRandomInt( 1, 6 ))
					{
						case 1: { RunFreezeClient( client );								}
						case 2: { RunClientHP( client );									}
						case 3: { RunSuperStrength( client );								}
						case 4: { SetupPlayerShield( client, 1, 0 );						}
						case 5: { CheatCommand( client, "director_force_panic_event", "" );	}
						case 6: { RewardTeleport( client, "Tank" );							}
					}
				}
			}
			else if ( item >= 7 && item < 11 )
			{
				switch( GetRandomInt( 1, 4 ))
				{
					case 1:
					{
						EmitSoundToClient( client, REWARD_SOUND );
						if ( GetConVarInt( g_Message ) > 0 )
						{
							PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05Your got empty luck!!" );
						}
					}
					case 2: { RunFreezeClient( client );			}
					case 3: { RewardTeleport( client, "Survivor" );	}
					case 4: { SetupPlayerShield( client, 1, 0 );	}
				}
			}
			else
			{
				switch( GetRandomInt( 1, 3 ))
				{
					case 1: { GivePlayerItems( client, "weapon_pipe_bomb" );	}
					case 2: { GivePlayerItems( client, "weapon_molotov" );		}
					case 3: { GivePlayerItems( client, "weapon_vomitjar" );		}
				}
			}
		}
		else if ( StrEqual( mName, LUMA_MDL, false))
		{
			DropRandomWeapon( client );
		}
		else if ( StrEqual( mName, JETF18_MDL, false))
		{
			g_ClientBTN[client][0] = true;
			g_ClientBTN[client][1] = true;
			
			CallTheAnimation( client, 30 );
			switch( GetRandomInt( 1, 3 ))
			{
				case 1:
				{
					EmitSoundToClient( client, AIRSTRIK_SOUND1 );
				}
				case 2:
				{
					EmitSoundToClient( client, AIRSTRIK_SOUND2 );
				}
				case 3:
				{
					EmitSoundToClient( client, AIRSTRIK_SOUND3 );
				}
			}
			
			if ( GetConVarInt( g_Message ) > 0 )
			{
				PrintToChatAll( "\x04[\x05LUFFY\x04]: %N \x05acquired \x04Air Strike.", client );
				PrintHintText( client, "++ Press 'RELOAD + FIRE' when ready to call Air Strike ++" );
			}
		}
		else if ( StrEqual( mName, AXIS_MDL, false))
		{
			switch( GetRandomInt( 1, 8 ))
			{
				case 1:	{ RunFreezeClient( client );								}
				case 2: { RunFreezeClient( client );								}
				case 3: { RewardTeleport( client, "Survivor" );						}
				case 4: { RewardTeleport( client, "Witch" );						}
				case 5: { RewardTeleport( client, "Tank" );							}
				case 6: { SetupPlayerShield( client, 1, 0 );						}
				case 7: { CheatCommand( client, "director_force_panic_event", "" );	}
				case 8:
				{
					switch( GetRandomInt( 1, 5 ))
					{
						case 1: { GivePlayerItems( client, "weapon_pipe_bomb" );	}
						case 2: { GivePlayerItems( client, "weapon_molotov" );		}
						case 3: { GivePlayerItems( client, "weapon_vomitjar" );		}
						case 4: { GivePlayerItems( client, "upgrade_laser_sight" );	}
						case 5: { GivePlayerItems( client, "weapon_ammo_spawn" );	}
					}
				}
			}
		}
	}
}

RewardTeleport( client, const String:who[] )
{
	if ( IsValidClient( client ))
	{
		if ( StrContains( curMap, "c5m2", false ) != -1 )
		{
			if ( StrEqual( who, "Witch", false ) || StrEqual( who, "Tank", false ))
			{
				if ( GetConVarInt( g_Message ) > 0 )
				{
					PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You found \x05Empty Object!!" );
				}
				return;
			}
		}
		
		new other = FindTeleportEntity( client, who );
		if ( other == 0 )
		{
			if ( StrContains( who, "Survivor", false ) != -1 )
			{
				switch( GetRandomInt( 1, 3 ))
				{
					case 1: { GivePlayerItems( client, "weapon_defibrillator" );	}
					case 2: { GivePlayerItems( client, "weapon_pain_pills" );		}
					case 3: { GivePlayerItems( client, "weapon_adrenaline" );		}
				}
			}
			else if ( StrContains( who, "Tank", false ) != -1 )
			{
				CheatCommand( client, "z_spawn", "tank auto" );
			}
			else if ( StrContains( who, "Witch", false ) != -1 )
			{
				CheatCommand( client, "z_spawn", "witch auto" );
			}
		}
		else
		{
			TeleportMeTo( client, other );
			if ( GetConVarInt( g_Message ) > 0 )
			{
				PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You are lucky!! you acquired \x04%s Teleport.", who );
			}
		}
	}
}

/* ---- Set Client Property Start ---- */
RunClockDevice( client )
{
	if ( IsValidClient( client))
	{
		ResetClient( client );
		
		g_PropCount[client] = GetConVarInt( g_ClockCoolDown ) + 1;
		g_ShieldLife[client] = GetConVarFloat( g_ClockCoolDown ) - 0.2;
		SetupPlayerShield( client, 2, 1 );
		
		SetEntProp( client, Prop_Data, "m_takedamage", 0, 1 );
		SetColour( client, 255, 128, 128, 200 );
		
		CreateTimer( 0.0, Timer_ClockDevice, client, TIMER_FLAG_NO_MAPCHANGE );
		g_ClockDevice[client] = CreateTimer( 1.0, Timer_ClockDevice, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );

		EmitSoundToClient( client, CLOCK_SOUND );
			
		if ( GetConVarInt( g_Message ) > 0 )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Clocking Device" );
		}
	}
}

RunSuperSpeed( client )
{
	if ( IsValidClient( client ))
	{
		ResetClient( client );
		g_PropCount[client] = GetConVarInt( g_SuperCoolDown ) + 1;
		g_ShieldLife[client] = GetConVarFloat( g_SuperCoolDown ) - 0.2;
		SetupPlayerShield( client, 2, 2 );
		
		new Float:speed = ( GetConVarFloat( g_SuperSpeedMax ) / 100.0 ) + 1.0;
		if ( speed > 2.0 ) speed = 2.0;
		if ( speed < 1.0 ) speed = 1.0;
			
		SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", speed );
		SetColour( client, 0, 128, 255, 200 );
		
		CreateTimer( 0.0, Timer_SuperSpeed, client, TIMER_FLAG_NO_MAPCHANGE );
		g_SuperSpeed[client] = CreateTimer( 1.0, Timer_SuperSpeed, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
			
		EmitSoundToClient( client, SPEED_SOUND );
			
		if ( GetConVarInt( g_Message ) > 0 )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Super Speed" );
		}
	}
}

RunClientHP( client )
{
	if ( IsValidClient( client ))
	{
		EmitSoundToClient( client, HEALTH_SOUND );
		g_AddHealth[client] = CreateTimer( 0.1, Timer_AddHealth, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		if ( GetConVarInt( g_Message ) > 0 )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04HP Regenerate" );
		}
	}
}

RunSuperStrength( client )
{
	if ( IsValidClient( client ))
	{
		ResetClient( client );
		
		g_PropCount[client] = GetConVarInt( g_StrCoolDown ) + 1;
		g_ShieldLife[client] = GetConVarFloat( g_StrCoolDown ) - 0.2;
		SetupPlayerShield( client, 2, 3 );
		
		SetEntityGravity( client, 0.4 );
		SetColour( client, 128, 255, 128, 200 );
		
		CreateTimer( 0.0, Timer_SuperStrength, client, TIMER_FLAG_NO_MAPCHANGE );
		g_SuperStrength[client] = CreateTimer( 1.0, Timer_SuperStrength, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		
		EmitSoundToClient( client, STRENGTH_SOUND );
		
		if ( GetConVarInt( g_Message ) > 0 )
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Super Strength" );
		}
	}
}

RunFreezeClient( client )
{
	if ( IsValidClient( client ))
	{
		ResetClient( client );
		switch( GetRandomInt( 1, 2 ))
		{
			case 1:
			{
				
				g_PropCount[client] = 10;
				SetEntityMoveType( client, MOVETYPE_NONE );
				SetColour( client, 0, 128, 255, 180 );
				CreateTimer( 1.0, Timer_FreePlayer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
					
				SetUpExplosion( client, "electrical_arc_01_system", 5.0 );
				SetUpExplosion( client, "electrical_arc_01_cp0", 5.0 );
			}
			case 2:
			{
				g_PropCount[client] = 5;
				SetEntityMoveType( client, MOVETYPE_NONE );
				SetColour( client, 255, 128, 128, 180 );
				
				CreateTimer( 1.0, Timer_FreePlayer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
					
				new entity = CreateEntityByName( "prop_physics" );
				if ( IsValidEntity( entity ))
				{
					decl Float:playerPos[3];
					GetEntPropVector( client, Prop_Send, "m_vecOrigin", playerPos );
					
					/* fire */
					DispatchKeyValue( entity, "model", MISSILE_JNK );
					DispatchKeyValue( entity, "ExplodeDamage", "20" );
					DispatchKeyValue( entity, "ExplodeRadius", "300" );
					DispatchSpawn( entity );
					SetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity", client );
					SetEntData( entity, GetEntSendPropOffs( entity, "m_CollisionGroup" ), 1, 1, true );
					TeleportEntity( entity, playerPos, NULL_VECTOR, NULL_VECTOR );
					AcceptEntityInput( entity, "break" );
					SetUpExplosion( client, "gas_explosion_pump", 5.0 );
				}
			}
		}
		EmitSoundToAll( SOUND_FREEZE, client, SNDCHAN_AUTO );
	}
}

ResetClient( client )
{
	KillBeamSpirit( client );
	
	if ( g_ClockDevice[client] != INVALID_HANDLE )
	{
		KillTimer( g_ClockDevice[client] );
		g_ClockDevice[client] = INVALID_HANDLE;
	}
		
	if ( g_SuperSpeed[client] != INVALID_HANDLE )
	{
		KillTimer( g_SuperSpeed[client] );
		g_SuperSpeed[client] = INVALID_HANDLE;
	}
	
	if ( g_AddHealth[client] != INVALID_HANDLE )
	{
		KillTimer( g_AddHealth[client] );
		g_AddHealth[client] = INVALID_HANDLE;
	}
	
	if ( g_SuperStrength[client] != INVALID_HANDLE )
	{
		KillTimer( g_SuperStrength[client] );
		g_SuperStrength[client] = INVALID_HANDLE;
	}
	
	if ( g_UnFreeze[client] != INVALID_HANDLE )
	{
		KillTimer( g_UnFreeze[client] );
		g_UnFreeze[client] = INVALID_HANDLE;
	}
	
	if ( IsValidClient( client ))
	{
		SetEntityGravity( client, 1.0 );
		SetEntProp( client, Prop_Data, "m_takedamage", 2, 1 );
		SetEntPropFloat( client, Prop_Data, "m_flLaggedMovementValue", 1.0 );
		SetColour( client, 255, 255, 255, 255 );
	}
}
/* ---- Set Client Property End ---- */

DropRandomWeapon( client )
{
	if ( IsValidClient( client ))
	{
		new r;
		switch( GetConVarInt( g_DropWeapon ))
		{
			case 0:
			{
				r = GetRandomInt( 7, 12 );
			}
			case 1:
			{
				r = GetRandomInt( 1, 12 );
			}
			case 2:
			{
				r = GetRandomInt( 7, 23 );
			}
			case 3:
			{
				r = GetRandomInt( 1, 23 );
			}
		}
		
		switch( r )
		{
			
			// T1 weapon
			case 1:
			{
				GivePlayerItems( client, "weapon_smg" );
			}
			case 2:
			{
				GivePlayerItems( client, "weapon_smg_silenced" );
			}
			case 3:
			{
				GivePlayerItems( client, "weapon_smg_mp5" );
			}
			case 4:
			{
				GivePlayerItems( client, "weapon_pumpshotgun" );
			}
			case 5:
			{
				GivePlayerItems( client, "weapon_shotgun_chrome" );
			}
			case 6:
			{
				GivePlayerItems( client, "weapon_hunting_rifle" );
			}
			// mid random
			case 7:
			{
				if ( GetConVarInt( g_Message ) > 0 )
				{
					PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04EMPTY Box" );
				}
			}
			case 8:
			{
				RunFreezeClient( client );
				if ( GetConVarInt( g_Message ) > 0 )
				{
					PrintToChatAll( "\x04[\x05LUFFY\x04]: \x05Your unlucky Gift  \x04>.<'" );
				}
			}
			case 9:
			{
				RewardTeleport( client, "Survivor" );
			}
			case 10:
			{
				RewardTeleport( client, "Witch" );
			}
			case 11:
			{
				RewardTeleport( client, "Tank" );
			}
			case 12:
			{
				SetupPlayerShield( client, 1, 0 );
			}
			// T2 weapon
			case 13:
			{
				GivePlayerItems( client, "weapon_rifle_m60" );
			}
			case 14:
			{
				GivePlayerItems( client, "weapon_grenade_launcher" );
			}
			case 15:
			{
				GivePlayerItems( client, "weapon_rifle" );
			}
			case 16:
			{
				GivePlayerItems( client, "weapon_rifle_ak47" );
			}
			case 17:
			{
				GivePlayerItems( client, "weapon_rifle_desert" );
			}
			case 18:
			{
				GivePlayerItems( client, "weapon_rifle_sg552" );
			}
			case 19:
			{
				GivePlayerItems( client, "weapon_shotgun_spas" );
			}
			case 20:
			{
				GivePlayerItems( client, "weapon_autoshotgun" );
			}
			case 21:
			{
				GivePlayerItems( client, "weapon_sniper_scout" );
			}
			case 22:
			{
				GivePlayerItems( client, "weapon_sniper_military" );
			}
			case 23:
			{
				GivePlayerItems( client, "weapon_sniper_awp" );
			}
		}
	}
}

GivePlayerItems( client, const String:item[] )
{
	if ( IsValidClient( client ))
	{
		new bool:glow = false;
		new bool:print = false;
		new String:buffer[32];
		new Float:mmPos[3];
		new Float:mmAng[3];
		new ent = CreateEntityByName( item );
		
		if ( ent != -1 )
		{
			EmitSoundToClient( client, REWARD_SOUND );
			
			GetEntPropVector( client, Prop_Send, "m_vecOrigin", mmPos );
			GetEntPropVector( client, Prop_Data, "m_angRotation", mmAng );
			
			if ( StrEqual( item, "weapon_rifle_m60", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Rifle M60" );
			}
			else if ( StrEqual( item, "weapon_grenade_launcher", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Grenade Launcher" );
			}
			else if ( StrEqual( item, "weapon_rifle", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Rifle M16" );
			}
			else if ( StrEqual( item, "weapon_rifle_ak47", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Rifle AK47" );
			}
			else if ( StrEqual( item, "weapon_rifle_desert", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Rifle Desert" );
			}
			else if ( StrEqual( item,"weapon_rifle_sg552", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Rifle SG552" );
			}
			else if ( StrEqual( item, "weapon_shotgun_spas", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Shotgun SPAS" );
			}
			else if ( StrEqual( item, "weapon_autoshotgun", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Auto Shotgun" );
			}
			else if ( StrEqual( item, "weapon_sniper_awp", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Sniper AWP" );
			}
			else if ( StrEqual( item, "weapon_sniper_military", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Sniper Military" );
			}
			else if ( StrEqual( item, "weapon_sniper_scout", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Sniper Scout" );
			}
			else if ( StrEqual( item, "weapon_hunting_rifle", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Hunting Rifle" );
			}
			else if ( StrEqual( item, "weapon_shotgun_chrome", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Shotgun Chrome" );
			}
			else if ( StrEqual( item, "weapon_pumpshotgun", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "Pump Shotgun" );
			}
			else if ( StrEqual( item, "weapon_smg", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "SMG" );
			}
			else if ( StrEqual( item, "weapon_smg_silenced", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "SMG Silenced" );
			}
			else if ( StrEqual( item, "weapon_smg_mp5", false ))
			{
				print = true;
				Format( buffer, sizeof( buffer ), "SMG MP5" );
			}
			else if ( StrEqual( item, "upgrade_laser_sight", false ))
			{
				print = true;
				glow = true;
				mmPos[2] -= 30.0;
				Format( buffer, sizeof( buffer ), "Upgrade Laser Sight" );
			}
			else if ( StrEqual( item, "weapon_ammo_spawn", false ))
			{
				print = true;
				glow = true;
				mmPos[2] -= 30.0;
				Format( buffer, sizeof( buffer ), "Ammo Pile" );
			}
			
			mmPos[2] += 30.0;
			DispatchKeyValueVector( ent, "Origin", mmPos );
			DispatchKeyValueVector( ent, "Angles", mmAng );
			DispatchSpawn( ent );
	
			if ( print )
			{
				new wp = GetEmptyWepon();
				if ( wp != -1 )
				{
					g_WepnSlot[wp] = ent;
					if ( glow )
					{
						ToggleGlowEnable( ent, true );
					}
					//PrintToChatAll("DROP WEAPON INDEX: %d", ent );
				}
				
				if ( GetConVarInt( g_Message ) > 0 )
				{
					PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04%s", buffer );
				}
			}
			else
			{
				if ( GetConVarInt( g_Message ) > 0 )
				{
					PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04%s", item );
				}
			}
		}
	}
}

GetEmptySlot()
{
	new max = GetConVarInt( g_LuffyMax );
	if ( max >= SLOT_NUM ) max = SLOT_NUM - 1;
	if ( max < 1 ) max = 1;
	
	for( new i = 0; i <=  max; i++ )
	{
		if ( g_ItemSlot[i] == -1 )
		{
			return i;
		}
	}
	return -1;
}

GetEmptyWepon()
{
	for( new i = 0; i < WEPN_NUM; i++ )
	{
		if ( g_WepnSlot[i] == -1 )
		{
			return i;
		}
	}
	return -1;
}

GetIndex( index )
{
	new max = GetConVarInt( g_LuffyMax );
	if ( max >= SLOT_NUM ) max = SLOT_NUM - 1;
	if ( max < 1 ) max = 1;
	
	for( new i = 0; i <=  max; i++ )
	{
		if ( index == g_ItemSlot[i] )
		{
			return i;
		}
	}
	return -1;
}

SetUpBeamSpirit( client, const String:ColoR[], Float:Life, Float:width, Alpha )
{
	if ( IsValidClient( client ))
	{
		KillBeamSpirit( client );
		
		new mr_Noob = CreateEntityByName( "prop_dynamic_override" );
		if ( mr_Noob != -1 )
		{
			new Float:nooB[3];
			decl Float:noobAng[3];
			GetEntPropVector( client, Prop_Send, "m_vecOrigin", nooB );
			GetEntPropVector( client, Prop_Data, "m_angRotation", noobAng );

			DispatchKeyValue( mr_Noob, "model", BEAMOBJECT );
			SetEntPropVector( mr_Noob, Prop_Send, "m_vecOrigin", nooB ); 
			SetEntPropVector( mr_Noob, Prop_Send, "m_angRotation", noobAng ); 
			DispatchSpawn( mr_Noob );
			SetEntPropFloat( mr_Noob, Prop_Send, "m_flModelScale", 0.1 );
			SetEntProp( mr_Noob, Prop_Send, "m_nSolidType", 1 );
			SetColour( mr_Noob, 255, 255, 255, 0 );
			
			SetVariantString( "!activator" );
			AcceptEntityInput( mr_Noob, "SetParent", client );
			SetVariantString( "spine" );
			AcceptEntityInput( mr_Noob, "SetParentAttachment" );
			
			new col[4];
			col[0] = 0;
			col[1] = 0;
			col[2] = 0;
			col[3] = Alpha;
			
			new col2[4];
			col2[0] = 0;
			col2[1] = 0;
			col2[2] = 0;
			col2[3] = Alpha;
			
			if ( StrEqual( ColoR, "red", false ))
			{
				col[0] = 255;
				col2[1] = 255;
			}
			else if ( StrEqual( ColoR, "green", false ))
			{
				col[1] = 255;
				col2[0] = 255;
			}
			else if ( StrEqual( ColoR, "blue", false ))
			{
				col[2] = 255;
				col2[0] = 255;
			}
			
			TE_SetupBeamFollow( mr_Noob, g_BeamSprite, 0, Life, width, 5.0, 3, col );
			TE_SendToAll();

			TE_SetupBeamFollow( mr_Noob, g_BeamSprite, 0, Life, 5.0, 5.0, 3, col2 );
			TE_SendToAll();
			
			g_BeamObject[client] = mr_Noob;
		}
	}
}

KillBeamSpirit( client )
{
	if ( g_BeamObject[client] != -1 )
	{
		Item_Destroy( g_BeamObject[client] );
		g_BeamObject[client] = -1;
	}
}

SetupSpark( client )
{
	g_Color[0] = 0;
	g_Color[1] = 0;
	g_Color[2] = 0;
	g_Color[3] = 255;
	
	switch( GetRandomInt( 1, 5 ))
	{
		case 1:
		{
			// light green
			g_Color[0] = 128;
			g_Color[1] = 255;
			g_Color[2] = 128;
		}
		case 2:
		{
			 // green
			g_Color[1] = 255;
		}
		case 3:
		{
			 // blue
			g_Color[2] = 255;
		}
		case 4:
		{
			 // light purple
			g_Color[0] = 255;
			g_Color[1] = 128;
			g_Color[2] = 255;
		}
		case 5:
		{
			 // red
			g_Color[0] = 255;
		}
	}
	
	decl Float:vecOrigin[3];
	for ( new i = 0; i <= 5; i++ )
	{
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", vecOrigin);
		vecOrigin[0] += GetRandomFloat( -30.0, 30.0 );
		vecOrigin[1] += GetRandomFloat( -30.0, 30.0 );
		vecOrigin[2] += GetRandomFloat( 10.0, 80.0 );
		TE_SetupBloodSprite( vecOrigin, NULL_VECTOR, g_Color, GetRandomInt( 5, 50 ), g_BeamSprite, g_BeamSprite );
		TE_SendToAll();
		
		switch( GetRandomInt( 1, 3 )) {
			case 1: {
				EmitSoundToAll( ZAP_SOUND_1, client, SNDCHAN_AUTO );
			}
			case 2: {
				EmitSoundToAll( ZAP_SOUND_2, client, SNDCHAN_AUTO );
			}
			case 3: {
				EmitSoundToAll( ZAP_SOUND_3, client, SNDCHAN_AUTO );
			}
		}
	}
}

ToggleGlowEnable( entity, bool:on=false )
{
	if ( IsValidEntity( entity ))
	{
		new m_iGlowType	= 0;
		new m_glowColor	= 0;
		
		if ( on )
		{
			new select;
			new glowType = GetConVarInt( g_ItemGlow );
			if ( glowType > 0 && glowType <= 6 )
			{
				m_iGlowType = 3;
				new colorRGB[3] = { 0, 0, 0 };
				
				if ( glowType == 6 ) select = GetRandomInt( 1, 5 );
				else select = glowType;
				
				switch( select )
				{
					case 1:
					{
						colorRGB[1] = 128;
						colorRGB[2] = 255;
					}
					case 2:
					{
						colorRGB[0] = 255;
						colorRGB[2] = 255;
					}
					case 3:
					{
						colorRGB[0] = 255;
						colorRGB[1] = 255;
					}
					case 4:
					{
						colorRGB[0] = 255;
					}
					case 5:
					{
						colorRGB[2] = 255;
					}
				}
				m_glowColor = colorRGB[0] + ( colorRGB[1] * 256 ) + ( colorRGB[2] * 65536 );
			}
			else
			{
				m_glowColor = 0;
			}
		}
		SetEntProp( entity, Prop_Send, "m_iGlowType", m_iGlowType );
		SetEntProp( entity, Prop_Send, "m_nGlowRange", 0 );
		SetEntProp( entity, Prop_Send, "m_glowColorOverride", m_glowColor );
	}
}

CommandCenter( client )
{
	if ( IsValidClient( client ))
	{
		new bool:launch		= false;
		decl Float:vO[3];
		decl Float:vA[3];
		decl Float:vN[3];
		decl Float:vT[3];
		
		GetClientEyePosition( client, vO );
		GetClientEyeAngles( client, vA );
		new Handle:trace = TR_TraceRayFilterEx( vO, vA, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers, client );
		if( TR_DidHit( trace ) )
		{ 
			TR_GetEndPosition( vN, trace );
			launch = true;
		}
		CloseHandle( trace );
		
		if ( launch )
		{
			vO[0] += GetRandomFloat( -80.0, 80.0 );
			vO[1] += GetRandomFloat( -80.0, 80.0 );
			vO[2] += GetRandomFloat( 100.0, 130.0 );
			
			MakeVectorFromPoints( vO, vN, vT );
			ScaleVector( vT, 0.2 );
			AddVectors( vT, vO, vO );
			
			MakeVectorFromPoints( vO, vN, vT );
			GetVectorAngles( vT, vA );
			
			vA[0] += GetRandomFloat( -10.0, 10.0 );	// yaw angle ( for more accuracy, comment out this ).
			vA[1] += GetRandomFloat( -10.0, 10.0 );	// pitc angle ( for more accuracy, comment out this ).
			
			LaunchBazoka( client, vO, vA );
		}
		else
		{
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05Null aimed location!!" );
		}
	}
}

LaunchBazoka( client, Float:tPos[3], Float:tAng[3] )
{
	if ( IsValidClient( client ))
	{
		new bool:r_body		= false;
		new bool:r_head		= false;
		new bool:r_exaust	= false;
		
		new body = CreateEntityByName( "molotov_projectile" );
		if( body != -1 )
		{
			DispatchKeyValue( body, "model", MISSILE_DMY );
			DispatchKeyValueVector( body, "origin", tPos );
			DispatchKeyValueVector( body, "Angles", tAng );
			SetEntPropFloat( body, Prop_Send,"m_flModelScale",0.01 );
			SetEntPropEnt( body, Prop_Data, "m_hOwnerEntity", -1 );
			DispatchKeyValueFloat( body, "fademindist", 10000.0 );
			DispatchKeyValueFloat( body, "fademaxdist", 20000.0 );
			DispatchKeyValueFloat( body, "fadescale", 0.0); 
			SetEntityGravity( body, 0.01 ); 
			DispatchSpawn( body );
			SetEntPropEnt( body, Prop_Data, "m_hOwnerEntity", client );
			
			g_Rocket[body][2] = body;
			r_body = true;
		}
		if ( r_body )
		{
			new head = CreateEntityByName( "prop_dynamic_override" );
			if( head != -1 )
			{
				decl String:namE[20];
				Format( namE, sizeof( namE ), "missile%d", body );
				DispatchKeyValue( body, "targetname", namE );
				DispatchKeyValue( head, "model", MISSILE_MDL );  
				DispatchKeyValue( head, "parentname", namE);  

				DispatchKeyValueVector( head, "origin", tPos );
				DispatchKeyValueVector( head, "Angles", tAng );
				
				SetVariantString( namE );
				AcceptEntityInput( head, "SetParent", head, head, 0 );
				DispatchSpawn( head );  
				DispatchKeyValueFloat( head, "fademindist", 10000.0 );
				DispatchKeyValueFloat( head, "fademaxdist", 20000.0 );
				DispatchKeyValueFloat( head, "fadescale", 0.0 ); 
				SetEntPropFloat( head, Prop_Send,"m_flModelScale",0.2 );
				
				g_Rocket[body][1] = head;
				r_head = true;
			}
		}
		if ( r_head )
		{
			decl Float:flmOri[3] = { 0.0, 0.0, 0.0 };
			decl Float:flmAng[3] = { 0.0, 180.0, 0.0 };
	
			decl String:exaustName[128];
			new exaust = CreateEntityByName( "env_steam" );
			if ( exaust != -1 )
			{
				decl String:lg[32];
				Format( lg, sizeof( lg ), "%d.0", 50 );
				Format( exaustName, sizeof( exaustName ), "target%d", body );
				DispatchKeyValue( body, "targetname", exaustName );
				DispatchKeyValue( exaust, "SpawnFlags", "1" );
				DispatchKeyValue( exaust, "Type", "0" );
				DispatchKeyValue( exaust, "InitialState", "1" );
				DispatchKeyValue( exaust, "Spreadspeed", "10" );
				DispatchKeyValue( exaust, "Speed", "200" );
				DispatchKeyValue( exaust, "Startsize", "5" );
				DispatchKeyValue( exaust, "EndSize", "30" );
				DispatchKeyValue( exaust, "Rate", "555" );
				DispatchKeyValue( exaust, "RenderColor", "60 80 200" );
				DispatchKeyValue( exaust, "JetLength", lg ); 
				DispatchKeyValue( exaust, "RenderAmt", "180" );
				DispatchSpawn( exaust );
				SetVariantString( exaustName );
				AcceptEntityInput( exaust, "SetParent", exaust, exaust, 0 );
				TeleportEntity( exaust, flmOri, flmAng, NULL_VECTOR );
				AcceptEntityInput( exaust, "TurnOn" );
				
				g_Rocket[body][0] = exaust;
				r_exaust = true;
			}
		}
		if ( r_exaust )
		{
			decl Float:vV[3];
			g_lRocket[body] = 2.0;
			GetAngleVectors( tAng, vV, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector( vV, vV );
			ScaleVector( vV, 1000.0 ); 
			TeleportEntity( body, NULL_VECTOR, NULL_VECTOR, vV );
			
			CreateTimer( 0.1, Timer_BazokaLife, body, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
		}
	}
}

SetupBazokaExplosion( index )
{
	if ( IsValidEntity( index ))
	{
		SetupBazokaDamage( index );
		SetUpExplosion( index, "gas_explosion_pump", 0.5 );
		
		switch( GetRandomInt( 1, 2 ))
		{
			case 1:	{ EmitSoundToAll( MISSILE_SOUND1, index, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE)	;}
			case 2:	{ EmitSoundToAll( MISSILE_SOUND2, index, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE)	;}
		}
		
		for ( new m = 0; m < 3; m++ )
		{
			if ( g_Rocket[index][m] != -1 && IsValidEntity( g_Rocket[index][m] ))
			{
				Item_Destroy( g_Rocket[index][m] );
				g_Rocket[index][m] = -1;
			}
		}
	}
}

SummonMilitaryChopper( client )
{
	if ( IsValidClient( client ))
	{
		new chopper = CreateEntityByName( "prop_dynamic_override" );
		if( chopper != -1 )
		{
			decl Float:_choPos[3];
			decl Float:_choAng[3];
			GetEntPropVector( client, Prop_Send, "m_vecOrigin", _choPos );
			GetEntPropVector( client, Prop_Data, "m_angRotation", _choAng );
			_choPos[2] += 130.0;
			_choAng[0] += 10.0;
			DispatchKeyValue( chopper, "model", JETF18_MDL );
			SetEntPropFloat( chopper, Prop_Send,"m_flModelScale", 0.1 );
			DispatchKeyValueFloat( chopper, "fademindist", 10000.0);
			DispatchKeyValueFloat( chopper, "fademaxdist", 20000.0);
			DispatchKeyValueFloat( chopper, "fadescale", 0.0); 
			SetEntityMoveType( chopper, MOVETYPE_NOCLIP);
			AcceptEntityInput( chopper, "TurnOn" );
			DispatchSpawn( chopper );
			ToggleGlowEnable( chopper, true );
			TeleportEntity( chopper, _choPos, _choAng, NULL_VECTOR );
			
			CreateExaust( chopper, 100 );
			g_ClientHely[client] = chopper;
			return chopper;
		}
	}
	return -1;
}

CreateExaust( ent, length )
{ 
	new Float:flmOri[3] = { 0.0, 0.0, 0.0 };
	new Float:flmAng[3] = { 0.0, 180.0, 0.0 };
	
	decl String:exaustName[128];
	Format( exaustName, sizeof( exaustName ), "target%d", ent );
	
	new exaust = CreateEntityByName( "env_steam" );
	if ( exaust != -1 )
	{
		decl String:lg[32];
		Format( lg, sizeof( lg ), "%d.0", length );
		
		DispatchKeyValue( ent, "targetname", exaustName );
		DispatchKeyValue( exaust, "SpawnFlags", "1" );
		DispatchKeyValue( exaust, "Type", "0" );
		DispatchKeyValue( exaust, "InitialState", "1" );
		DispatchKeyValue( exaust, "Spreadspeed", "10" );
		DispatchKeyValue( exaust, "Speed", "350" );
		DispatchKeyValue( exaust, "Startsize", "5" );
		DispatchKeyValue( exaust, "EndSize", "30" );
		DispatchKeyValue( exaust, "Rate", "555" );
		DispatchKeyValue( exaust, "RenderColor", "60 80 200" );
		DispatchKeyValue( exaust, "JetLength", lg ); 
		DispatchKeyValue( exaust, "RenderAmt", "180" );
	
		DispatchSpawn( exaust );
		SetVariantString( exaustName );
		AcceptEntityInput( exaust, "SetParent", exaust, exaust, 0 );
		TeleportEntity( exaust, flmOri, flmAng, NULL_VECTOR );
		AcceptEntityInput( exaust, "TurnOn" );
		
		return exaust;
	}
	return -1;
}

SetupBazokaDamage( indx )
{
	if ( IsValidEntity( indx ))
	{
		new Float:radius		= 200.0;
		new Float:magnitudDeal	= 50.0;
		new OverRide			= GetConVarInt( g_MissaleDmg );
		new TankDamage			= GetConVarInt( g_TankDamage );
		new client				= GetEntPropEnt( indx, Prop_Data, "m_hOwnerEntity" );
		if ( client < 1 )
		{
			client = indx;
		}
		SetEntPropEnt( indx, Prop_Data, "m_hOwnerEntity", -1 );
		
		if ( OverRide < 1 ) OverRide = 1;
		if ( TankDamage < 1 ) TankDamage = 1;
		
		new Float:lock[3];
		GetEntPropVector( indx, Prop_Send, "m_vecOrigin", lock );
		
		new Float:lockT[3];
		new cnt = GetEntityCount();
		decl String:_infected[64];
		for ( new i = 1; i <= cnt; i++ )
		{
			if ( IsValidEntity( i ))
			{
				if ( i <= MaxClients )
				{
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", lockT );
					if ( GetVectorDistance( lock, lockT ) <= radius )
					{
						if ( IsValidClient( i ))
						{
							magnitudDeal	= 10.0;
						}
						if ( IsValidInfected( i ) && IsPlayerAlive( i ))
						{
							if ( GetEntProp( i, Prop_Send, "m_zombieClass" ) == TANK )
							{
								DealDamage( i, TankDamage, client, DMG_EXPLOSIVE, "weapon_rifle" );
							}
							else
							{
								DealDamage( i, OverRide, client, DMG_EXPLOSIVE, "weapon_rifle" );
							}
						}
					}
				}
				else
				{
					GetEntityClassname( i, _infected, sizeof( _infected ));
					if ( StrContains( _infected, "infected", false ) != -1 )
					{
						GetEntPropVector( i, Prop_Send, "m_vecOrigin", lockT );
						if ( GetVectorDistance( lock, lockT ) <= radius )
						{
							DealDamage( i, OverRide, client, DMG_EXPLOSIVE, "weapon_rifle" );
						}
					}
					else if ( StrContains( _infected, "witch", false ) != -1 )
					{
						GetEntPropVector( i, Prop_Send, "m_vecOrigin", lockT );
						if ( GetVectorDistance( lock, lockT ) <= radius )
						{
							DealDamage( i, OverRide, client, DMG_EXPLOSIVE, "weapon_rifle" );
						}
					}
				}
			}
		}
		
		new magnitud = CreateEntityByName( "point_push" );
		if ( magnitud != -1 )
		{
			DispatchKeyValueFloat ( magnitud, "magnitude", magnitudDeal );
			DispatchKeyValueFloat ( magnitud, "radius", radius );
			SetVariantString( "spawnflags 24" );
			AcceptEntityInput( magnitud, "AddOutput" );
			DispatchSpawn( magnitud );
			TeleportEntity( magnitud, lock, NULL_VECTOR, NULL_VECTOR );
			AcceptEntityInput( magnitud, "Enable" );
			CreateTimer( 0.2, DeletIndex, magnitud );
		}
		
		if ( GetConVarInt( g_MissaleSelf ) == 0 ) return;
		
		new damage = CreateEntityByName( "point_hurt" );
 		if ( damage != -1 )
		{
			DispatchKeyValue( damage, "Damage", "0.0" );
			DispatchKeyValue( damage, "DamageRadius", "200" ); 
			DispatchKeyValue( damage, "DamageDelay", "0.0" );
			DispatchSpawn( damage );
			TeleportEntity( damage, lock, NULL_VECTOR, NULL_VECTOR );
			AcceptEntityInput( damage, "Hurt" );
			CreateTimer( 0.1, DeletIndex, damage );
		}
	}
}

CreateShieldPush( client, target, Float:force=0.0 )
{
	if ( IsValidClient( client ) && IsValidEntity( target ))
	{
		if (( GetEntProp( client, Prop_Send, "m_tongueOwner" ) > 0 )	||
		( GetEntPropEnt( client, Prop_Send, "m_pounceAttacker" ) > 0 )	||
		( GetEntPropEnt( client, Prop_Send, "m_jockeyAttacker" ) > 0 ))
		{
			g_Attacker[client] = target;
			CreateTimer( 0.0, Timer_LuckInfected, client, TIMER_FLAG_NO_MAPCHANGE );
		}

		decl Float:ppDM[3];
		decl Float:qqDM[3];
		decl Float:qqAA[3];
		decl Float:qqDA[3];
		decl Float:qqVv[3];
		
		GetEntPropVector( target, Prop_Send, "m_vecOrigin", ppDM );
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", qqDM );
		
		MakeVectorFromPoints( qqDM, ppDM, qqAA );
		GetVectorAngles( qqAA, qqDA );
		qqDA[0] -= 20.0;
		GetAngleVectors( qqDA, qqVv, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector( qqVv, qqVv );
		ScaleVector( qqVv, force );
		TeleportEntity( target, NULL_VECTOR, NULL_VECTOR, qqVv );
	}
}

SetupPlayerShield( client, type, color )
{
	if ( IsValidClient( client ))
	{
		if ( g_ShieldInEffect[client] ) return;
		
		new Color = color;
		new bool:parent	= false;
		decl Float:_sOrg[3];
		decl Float:_sAng[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", _sOrg );
		GetEntPropVector( client, Prop_Data, "m_angRotation", _sAng );
		_sOrg[2] += 50.0;
		
		new Body = CreateEntityByName( "prop_dynamic_override" );
		if( Body != -1 )
		{
			SetEntPropEnt( Body, Prop_Data, "m_hOwnerEntity", -1)	;
			DispatchKeyValue( Body, "model", AXIS_MDL );
			DispatchKeyValueVector( Body, "origin", _sOrg );
			DispatchKeyValueVector( Body, "Angles", _sAng );
			SetEntPropFloat( Body, Prop_Send, "m_flModelScale", 0.01 );
			SetEntProp( Body, Prop_Send, "m_CollisionGroup", 1 ); 
			DispatchSpawn( Body );  
			
			if ( GetConVarInt( g_ShieldType ) == 0 )
			{
				SetVariantString( "!activator" );
				AcceptEntityInput( Body, "SetParent", client );
				SetVariantString( "spine" );
				AcceptEntityInput( Body, "SetParentAttachment" );
				
				decl Float:b_Org[3] = { 0.0, 0.0, 0.0 };
				decl Float:b_Ang[3] = { 0.0, 0.0, -90.0 };
				TeleportEntity( Body, b_Org, b_Ang, NULL_VECTOR);
			}

			SetColour( Body, 255, 255, 255, 0 );
			g_Shield[client][0] = Body;
			parent = true;
		}
		
		if ( !parent ) return;
		
		new numberWing = 3;
		if ( type == 1 || type == 3 )
		{
			g_ShieldInEffect[client]	= true;
			g_ShieldLife[client]		= GetConVarFloat( g_ShieldLifeee );
			numberWing					= 8;
			EmitSoundToClient( client, SUPERSHIELD_SND );
			PrintToChat( client, "\x04[\x05LUFFY\x04]: \x05You acquired \x04Super Shield" );
		}
		else if ( type == 2 )
		{
			numberWing = 6;
		}

		new Float:wingRadius		= 70.0;
		new Float:IncRadius			= 360.0 / float( numberWing );
		new Float:wingAngle			= 0.0;
		new Float:wingPosition		= 90.0;
		decl Float:Coordiante[3]	= { 0.0, 0.0, 0.0 };
		
		for ( new i = 1; i <= numberWing; i ++ )
		{
			Coordiante[0] = wingRadius * Cosine( DegToRad( wingAngle ));
			Coordiante[1] = wingRadius * Sine( DegToRad( wingAngle ));
			
			g_Shield[client][i] = AttachWing( client, Body, Coordiante, wingPosition, type, Color );
			if ( g_Shield[client][i] == -1 )
			{
				PrintToServer( "[LUFFY]: Error wing creation fail!!!" );
				break;
			}
			wingAngle		+= IncRadius;
			wingPosition	+= IncRadius;
		}
	
		CreateTimer( 0.1, Timer_ShieldRotate, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	}
}

AttachWing( client, parent, Float:Coord[3], Float:Ang, Type, ccolor )
{
	new wing = -1;
	
	if ( IsValidClient( client ))
	{
		new bool:ok = false;
		decl String:namE[32];
		decl Float:clientPos[3];
		decl Float:clientAng[3];
		decl Float:bufferAng[3];
		
		if ( Type == 1 )
		{
			bufferAng[0] = 0.0;	bufferAng[1] = Ang;	bufferAng[2] = 0.0;
		}
		else if ( Type == 2 )
		{
			bufferAng[0] = -90.0;	bufferAng[1] = ( Ang + 90.0 );	bufferAng[2] = 0.0;
		}
		else if ( Type == 3 )
		{
			bufferAng[0] = 0.0;	bufferAng[1] = ( Ang - 90.0 );	bufferAng[2] = 0.0;
		}
		
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", clientPos );
		GetEntPropVector( client, Prop_Data, "m_angRotation", clientAng );
		
		new shield = CreateEntityByName( "prop_dynamic_override" );
		if ( shield != -1 )
		{
			SetEntPropEnt( shield, Prop_Data, "m_hOwnerEntity", -1)	;
			Format( namE, sizeof( namE ), "missile%d", parent );
			DispatchKeyValue( parent, "targetname", namE );
			DispatchKeyValue( shield, "parentname", namE);  
			DispatchKeyValueVector( shield, "origin", clientPos );
			DispatchKeyValueVector( shield, "Angles", clientAng );
			
			if ( Type == 1 || Type == 2 )
			{
				DispatchKeyValue( shield, "model", JETF18_MDL ); 
				SetEntPropFloat( shield, Prop_Send, "m_flModelScale", 0.035 );
			}
			else if ( Type == 3 )
			{
				DispatchKeyValue( shield, "model", SHIELD_MDL );  
			}
			
			SetEntProp( shield, Prop_Send, "m_CollisionGroup", 1 );
			SetVariantString( namE );
			AcceptEntityInput( shield, "SetParent", shield, shield, 0 );
			DispatchSpawn( shield );  
			TeleportEntity( shield, Coord, bufferAng, NULL_VECTOR);
			
			ok = true;
			wing = shield;
		}
		
		if ( ok )
		{
			if ( Type == 1 )
			{
				SetColour( shield, 255, 255, 255, 200 );
				ToggleGlowEnable( shield, true );
				CreateTimer( 0.1, Timer_WingDamage, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
			}
			else if ( Type == 2 )
			{
				if ( ccolor == 1 ) SetColour( shield, 255, 128, 128, 150 );
				if ( ccolor == 2 ) SetColour( shield, 0, 128, 255, 150 );
				if ( ccolor == 3 ) SetColour( shield, 128, 255, 128, 150 );
			}
			else if ( Type == 3 )
			{
				SetColour( shield, 150, 150, 150, 180 );
				ToggleGlowEnable( shield, true );
				CreateTimer( 0.1, Timer_WingPush, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
			}
		}
	}
	return wing;
}

public bool:DontHitSelf( entity, contentsMask, any:data )
{
	if ( entity == data ) 
	{
		return false; 
	}
	else if( entity > MaxClients )
	{
		if ( IsValidEntity( entity ))
		{
			decl String:edictname[128];
			GetEdictClassname( entity, edictname, 128 );
			if ( StrContains( edictname, "prop_dynamic" ) != -1 )
			{
				return false;
			}
		}
	}
	return true;
}

public bool:TraceEntityFilterPlayers( entity, contentsMask, any:data )
{
	return entity > MaxClients && entity != data;
}

/* code from pan xiohai */
SetUpExplosion( client, String:particlename[], Float:time )
{
	new particle = CreateEntityByName( "info_particle_system" );
	if ( IsValidEdict( particle ))
	{
		decl Float:vecOrigin[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", vecOrigin );
	
		TeleportEntity( particle, vecOrigin, NULL_VECTOR, NULL_VECTOR );
		DispatchKeyValue( particle, "effect_name", particlename );
		DispatchKeyValue( particle, "targetname", "particle" );
		DispatchSpawn( particle );
		ActivateEntity( particle );
		AcceptEntityInput( particle, "start" );
		CreateTimer( time,  DeletIndex, particle );
	}  
}
/* code from pan xiohai */
public PrecacheParticle( String:particlename[] )
{
	new particle = CreateEntityByName("info_particle_system");
	if ( IsValidEdict( particle ))
	{
		DispatchKeyValue( particle, "effect_name", particlename );
		DispatchKeyValue( particle, "targetname", "particle" );
		DispatchSpawn( particle );
		ActivateEntity( particle );
		AcceptEntityInput( particle, "start");
		
		CreateTimer( 0.01,  DeletIndex, particle );
	}  
}

public Action:DeletIndex( Handle:timer, any:index )
{
    Item_Destroy( index );
}

// Because I love you.
stock DealDamage( victim, damage, attacker=0, dmg_type=DMG_GENERIC, String:weapon[]="" )
{
	if( victim > 0 && GetEntProp( victim, Prop_Data, "m_iHealth" ) > 0 && attacker > 0 && damage > 0 )
	{
		new String:dmg_str[16];
		IntToString( damage, dmg_str, 16 );
		new String:dmg_type_str[32];
		IntToString( dmg_type, dmg_type_str, 32 );
		new pointHurt = CreateEntityByName( "point_hurt" );
		if ( pointHurt )
		{
			DispatchKeyValue( victim,"targetname","war3_hurtme" );
			DispatchKeyValue( pointHurt, "DamageTarget","war3_hurtme" );
			DispatchKeyValue( pointHurt, "Damage",dmg_str );
			DispatchKeyValue( pointHurt,"DamageType", dmg_type_str );
			if ( !StrEqual( weapon, "" ))
			{
				DispatchKeyValue( pointHurt, "classname", weapon );
			}
			DispatchSpawn( pointHurt );
			AcceptEntityInput( pointHurt, "Hurt",( attacker > 0 ) ? attacker:-1 );
			DispatchKeyValue( pointHurt, "classname", "point_hurt" );
			DispatchKeyValue( victim, "targetname", "war3_donthurtme" );
			RemoveEdict( pointHurt );
		}
	}
}

stock SetVector( Float:buffer[3], Float:x, Float:y, Float:z )
{
	buffer[0] = x;
	buffer[1] = y;
	buffer[2] = z;
}

stock SetColour( ent, r, g, b, a )
{
	if ( IsValidEntity( ent ))
	{
		SetEntityRenderMode( ent, RENDER_TRANSCOLOR );
		SetEntityRenderColor( ent, r, g, b, a );
	}
}

stock CheatCommand( client, const String:cheats[], const String:command[] )
{
	if ( IsInGame( client ) && IsPlayerAlive( client ))
	{
		new userflags = GetUserFlagBits( client );
		new cmdflags = GetCommandFlags( cheats );
		
		SetUserFlagBits( client, ADMFLAG_ROOT );
		SetCommandFlags( cheats, cmdflags & ~FCVAR_CHEAT );
		
		FakeClientCommand( client,"%s %s", cheats, command );
		
		SetCommandFlags( cheats, cmdflags );
		SetUserFlagBits( client, userflags );
		
		if ( StrContains( command, "witch auto", false ) != -1 )
		{
			EmitSoundToClient( client, WITCH_SOUND );
			if ( GetConVarInt( g_Message ) > 0 ) PrintToChatAll( "\x04[\x05LUFFY\x04]: \x04%N \x05acquired \x04Witch Luffy!!", client );
		}
		else if ( StrContains( command, "tank auto", false ) != -1 )
		{
			EmitSoundToClient( client, TANK_SOUND );
			if ( GetConVarInt( g_Message ) > 0 ) PrintToChatAll( "\x04[\x05LUFFY\x04]: \x04%N \x05acquired \x04Tank Luffy!!", client );
		}
		
		if ( StrContains( cheats, "director_force_panic_event", false ) != -1 )
		{
			if ( GetConVarInt( g_Message ) > 0 ) PrintToChatAll( "\x04[\x05LUFFY\x04]: \x04%N \x05acquired \x04Panic Luffy!!", client );
		}
	}
}

stock FindEntity( client, const String:_findWhat[] )
{
	new scan = 0;
	if ( StrEqual( _findWhat, "Tank", false ))
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidInfected( i ) && IsPlayerAlive( i ))
			{
				if ( GetEntProp( i, Prop_Send, "m_zombieClass") == 8 )
				{
					scan += 1;
				}
			}
		}
	}
	else if ( StrEqual( _findWhat, "Witch", false ))
	{
		decl String:_name[64];
		new _max	= GetEntityCount();
		for ( new i = MaxClients; i <= _max; i++ )
		{
			if ( IsValidEntity( i ))
			{
				GetEntityClassname( i, _name, sizeof( _name ));
				if ( StrContains( _name, "witch", false) != -1 )
				{
					if ( GetEntProp( i, Prop_Data, "m_iHealth" ) > 1 )
					{
						scan += 1;
					}
				}
			}
		}
	}
	else if ( StrEqual( _findWhat, "Survivor", false ))
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ) && i != client )
			{
				scan += 1;
				break;
			}
		}
	}
	return scan;
}

stock FindTeleportEntity( client, const String:_findWhatTele[] )
{
	new scan = 0;
	if ( StrEqual( _findWhatTele, "Tank", false ))
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidInfected( i ) && IsPlayerAlive( i ))
			{
				if ( GetEntProp( i, Prop_Send, "m_zombieClass") == 8 )
				{
					scan = i;
					break;
				}
			}
		}
	}
	else if ( StrEqual( _findWhatTele, "Witch", false ))
	{
		decl String:_name[64];
		new _max	= GetEntityCount();
		for ( new i = MaxClients; i <= _max; i++ )
		{
			if ( IsValidEntity( i ))
			{
				GetEntityClassname( i, _name, sizeof( _name ));
				if ( StrContains( _name, "witch", false) != -1 )
				{
					if ( GetEntProp( i, Prop_Data, "m_iHealth" ) > 1 )
					{
						scan = i;
						break;
					}
				}
			}
		}
	}
	else if ( StrEqual( _findWhatTele, "Survivor", false ))
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ) && i != client )
			{
				scan = i;
				break;
			}
		}
	}
	return scan;
}

stock TeleportMeTo( caller, subject )
{
	if ( IsValidClient( caller ))
	{
		decl Float:_location[3];
		GetEntPropVector( subject, Prop_Send, "m_vecOrigin", _location );
		_location[2] += 5.0;
		TeleportEntity( caller, _location, NULL_VECTOR, NULL_VECTOR );
		EmitSoundToClient( caller, TELEPOT_SOUND );
	}
}

stock RestockAmmo( client, const String:wepAmmo[], wepIndex )
{
	if ( IsValidClient( client ))
	{
		new ammoStock	= 0;
		
		if ( StrEqual( wepAmmo, "weapon_rifle_m60", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_m60_max" ));
		}
		else if ( StrEqual( wepAmmo, "weapon_grenade_launcher", false ))
		{
			ammoStock = GetConVarInt( FindConVar("ammo_grenadelauncher_max"));
		}
		else if ( StrEqual( wepAmmo, "weapon_rifle", false ) || StrEqual( wepAmmo, "weapon_rifle_ak47", false ) || StrEqual( wepAmmo, "weapon_rifle_desert", false ) || StrEqual( wepAmmo,"weapon_rifle_sg552", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_assaultrifle_max" ));
		}
		else if ( StrEqual( wepAmmo, "weapon_shotgun_spas", false ) || StrEqual( wepAmmo, "weapon_autoshotgun", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_autoshotgun_max" ));
		}
		else if ( StrEqual( wepAmmo, "weapon_sniper_awp", false ) || StrEqual( wepAmmo, "weapon_sniper_military", false ) || StrEqual( wepAmmo, "weapon_sniper_scout", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_sniperrifle_max" ));
		}
		else if ( StrEqual( wepAmmo, "weapon_hunting_rifle", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_huntingrifle_max" ));
		}
		else if ( StrEqual( wepAmmo, "weapon_shotgun_chrome", false ) || StrEqual( wepAmmo, "weapon_pumpshotgun", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_shotgun_max" ));
		}
		else if ( StrEqual( wepAmmo, "weapon_smg", false ) || StrEqual( wepAmmo, "weapon_smg_silenced", false ) || StrEqual( wepAmmo, "weapon_smg_mp5", false ))
		{
			ammoStock = GetConVarInt( FindConVar( "ammo_smg_max" ));
		}
		if ( ammoStock > 0 )
		{
			new iPrimType = GetEntProp( wepIndex, Prop_Send, "m_iPrimaryAmmoType");
			SetEntProp( client, Prop_Send, "m_iAmmo", ammoStock, _, iPrimType );
			//PrintToChatAll("RESTOCK WEAPON INDEX: %d", wepIndex );
		}
	}
}

stock RotateAdvance( index, Float:value, axis )
{
	if ( IsValidEntity( index ))
	{
		decl Float:rotate_[3];
		GetEntPropVector( index, Prop_Data, "m_angRotation", rotate_ );
		rotate_[axis] += value;
		TeleportEntity( index, NULL_VECTOR, rotate_, NULL_VECTOR);
	}
}

stock Item_Destroy( entity )
{
	if ( entity != -1 && IsValidEntity( entity ))
	{
		decl Float:desPos[3];
		GetEntPropVector( entity, Prop_Send, "m_vecOrigin", desPos );

		desPos[2] += 5000.0;
		
		TeleportEntity( entity, desPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput( entity, "Kill" );
	}
}

stock bool:IsValidInfected( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) != 3 ) return false;
	return true;
}

stock bool:IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) != 2 ) return false;
	if ( !IsPlayerAlive( client )) return false;
	return true;
}

stock bool:IsInGame( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	return true;
}

