/*	Killicons.sp  */
/*  Made by: Plaffy46  */

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
//#include <sdktools>
#include <tf2_stocks>
#include <tf2>

#define PLUGIN_VERSION "1.00"
#define    MAX_EDICT_BITS    11
#define    MAX_EDICTS        (1 << MAX_EDICT_BITS)


public Plugin:myinfo = 
{
	name = "[TF2]Better Killicons",
	author = "Plaffy46",
	description = "Adds and fixes various killicons from the Improved Killicons Pack and some others.",
	version = PLUGIN_VERSION,
	url = "Nope"
}

new g_hProjectileOwners[MAX_EDICTS+1]=-1;//for reflected stuff
new Handle:cvarEnabled;//um...
new bool:Enabled;
new Handle:cvarProjectilesEnabled;
new bool:ProjectilesEnabled;

public OnPluginStart()
{
	CreateConVar("sm_killicons_version", PLUGIN_VERSION, "[TF2]Killicons version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	cvarEnabled = CreateConVar("sm_killicons_enable","1","Enable/disable [TF2]Killicons, entirely.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarProjectilesEnabled = CreateConVar("sm_killicons_projectiles_enabled","1","Enable/disable killicons checks related to specific reflected projectiles.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookEvent("player_death",OnDeath, EventHookMode_Pre);//most important event for everything...
	HookEvent("object_deflected",OnProjDeflected, EventHookMode_Pre);//for killicons about specific reflected projs (reflected_rocket_blackbox or reflected_rocket_cow_mangler? etc.)
	HookConVarChange(cvarEnabled, OnConVarChanged);
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/vgui/logos/ImprovedKillIcons/d.vmt");
	AddFileToDownloadsTable("materials/vgui/logos/ImprovedKillIcons/d.vtf");
	AddFileToDownloadsTable("materials/vgui/logos/ImprovedKillIcons/dneg.vmt");
	AddFileToDownloadsTable("materials/vgui/logos/ImprovedKillIcons/dneg.vtf");
	AddFileToDownloadsTable("materials/vgui/logos/ImprovedKillIcons/dneg_images.vtf");
	AddFileToDownloadsTable("materials/vgui/logos/ImprovedKillIcons/dneg_images_v2.vtf");
	AddFileToDownloadsTable("materials/vgui/logos/ImprovedKillIcons/dneg_images_v3.vtf");
	AddFileToDownloadsTable("scripts/mod_textures.txt");//NEEDS TO BE TESTED!!!!
}

public OnConVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (cvar == cvarEnabled) Enabled = bool:StringToInt(newValue);
	if (cvar == cvarProjectilesEnabled) ProjectilesEnabled = bool:StringToInt(newValue);
}

public Action:OnDeath(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	//if(!Enabled) return Plugin_Continue;
	
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	// new iAssister = GetClientOfUserId(GetEventInt(hEvent, "assister"));
	new iCustom = GetEventInt(hEvent, "customkill");
	// new iMiniCrit = GetEventBool(hEvent, "minicrit"); //Can't implement background effect in killicons like critical things
	//will let this here in case some people gimme killicons like double donk which are minicrits
	new iEntity = GetEventInt(hEvent, "inflictor_entindex");
	new String:weapon[33];
	GetEventString(hEvent, "weapon", weapon, sizeof(weapon));				
	if (!IsValidClient(iVictim)) return Plugin_Continue;
	if (!IsValidClient(iAttacker)) return Plugin_Continue;
	if (iAttacker==iVictim) return Plugin_Continue;
	
	new iSlot = GetWeaponSlot(weapon);
	new iIndex = GetPlayerWeaponIndex(iAttacker,iSlot);
	
	if(iCustom == TF_CUSTOM_BACKSTAB)
	{
		switch(iIndex)
		{
			case 649:
			{
				SetEventString(hEvent, "weapon", "spy_cicle_backstab");
				SetEventString(hEvent, "weapon_logclassname", "spy_cicle_backstab");
				SetEventInt(hEvent, "customkill", 0);//won't work without this, what...?
			}
			case 225:
			{
				SetEventString(hEvent, "weapon", "eternal_reward_backstab");
				SetEventString(hEvent, "weapon_logclassname", "eternal_reward_backstab");
				SetEventInt(hEvent, "customkill", 0);//idem.
			}
			case 356:
			{
				SetEventString(hEvent, "weapon", "kunai_backstab");
				SetEventString(hEvent, "weapon_logclassname", "kunai_backstab");
				SetEventInt(hEvent, "customkill", 0);//etc.
			}
			case 423:
			{
				SetEventString(hEvent, "weapon", "backstab_saxxy");
				SetEventString(hEvent, "weapon_logclassname", "backstab_saxxy");
				SetEventInt(hEvent, "customkill", 0);
			}
			case 461:
			{
				SetEventString(hEvent, "weapon", "kunai_backstab");
				SetEventString(hEvent, "weapon_logclassname", "kunai_backstab");
				SetEventInt(hEvent, "customkill", 0);
			}	
			case 574:
			{
				SetEventString(hEvent, "weapon", "voodoo_pin_backstab");
				SetEventString(hEvent, "weapon_logclassname", "voodoo_pin_backstab");
				SetEventInt(hEvent, "customkill", 0);
			}
			default:
			{
				//Nothing
			}
		}
		return Plugin_Continue;//don't really know what to use
	}
	
	else if (StrEqual(weapon, "wrangler_kill"))
	{
		//PrintToChatAll("nah");
		new iLevel = GetEntProp(iEntity,Prop_Send,"m_iUpgradeLevel");
		new isMini = GetEntProp(iEntity,Prop_Send,"m_bMiniBuilding");
		if(isMini)
		{
			SetEventString(hEvent, "weapon", "wrangler_kill_mini"); 
			SetEventString(hEvent, "weapon_logclassname", "wrangler_kill_mini");
		}
		else if(iLevel==2)
		{
			SetEventString(hEvent, "weapon", "wrangler_kill_2"); 
			SetEventString(hEvent, "weapon_logclassname", "wrangler_kill_2");
		}
		else if(iLevel==3)
		{
			SetEventString(hEvent, "weapon", "wrangler_kill_3"); 
			SetEventString(hEvent, "weapon_logclassname", "wrangler_kill_3");
		}
		else
		{
			//nothing
		}
		return Plugin_Continue;
	}
		
	else if(iCustom == TF_CUSTOM_HEADSHOT)
	{
		if(StrEqual(weapon, "bazaar_bargain"))
		{
			SetEventString(hEvent, "weapon", "bazaar_headshot");
			SetEventString(hEvent, "weapon_logclassname", "bazaar_headshot");
			SetEventInt(hEvent, "customkill", 0);
		}
		
		else if(StrEqual(weapon, "machina"))
		{	
			SetEventString(hEvent, "weapon", "machina_headshot");
			SetEventString(hEvent, "weapon_logclassname", "machina_headshot");
			SetEventInt(hEvent, "customkill", 0);
		}
		
		else if(StrEqual(weapon, "awper_hand"))
		{	
			SetEventString(hEvent, "weapon", "awper_hand_headshot");
			SetEventString(hEvent, "weapon_logclassname", "awper_hand_headshot");
			SetEventInt(hEvent, "customkill", 0);
		}			
	}
		
	else if(iCustom == TF_CUSTOM_TAUNT_FENCING)
	{
		switch(iIndex)
		{
				case 225:
				{	
					SetEventString(hEvent, "weapon", "taunt_spy_eternal_reward");
					SetEventString(hEvent, "weapon_logclassname", "taunt_spy_eternal_reward");
					SetEventInt(hEvent, "customkill", 0);
				}
				case 356:
				{	
					SetEventString(hEvent, "weapon", "taunt_spy_kunai");
					SetEventString(hEvent, "weapon_logclassname", "taunt_spy_kunai");
					SetEventInt(hEvent, "customkill", 0);
				}
				case 423:
				{
					SetEventString(hEvent, "weapon", "taunt_spy_saxxy");
					SetEventString(hEvent, "weapon_logclassname", "taunt_spy_saxxy");
					SetEventInt(hEvent, "customkill", 0);
				}
				case 461:
				{	
					SetEventString(hEvent, "weapon", "taunt_spy_big_earner");
					SetEventString(hEvent, "weapon_logclassname", "taunt_spy_big_earner");
					SetEventInt(hEvent, "customkill", 0);
				}
				case 574:
				{	
					SetEventString(hEvent, "weapon", "taunt_spy_voodoo_pin");
					SetEventString(hEvent, "weapon_logclassname", "taunt_spy_voodoo_pin");
					SetEventInt(hEvent, "customkill", 0);
				}
				case 727:
				{	
					SetEventString(hEvent, "weapon", "taunt_spy_black_rose");
					SetEventString(hEvent, "weapon_logclassname", "taunt_spy_black_rose");
					SetEventInt(hEvent, "customkill", 0);
				}
				default:
				{
				
				}
		}
	}			
	else if(iCustom == TF_CUSTOM_FLARE_PELLET)
	{
		SetEventString(hEvent, "weapon", "taunt_pyro_scorchshot");
		SetEventString(hEvent, "weapon_logclassname", "taunt_pyro_scorchshot");
	}
	
	else if(iCustom == TF_CUSTOM_TAUNT_BARBARIAN_SWING)
	{
		switch(iIndex)
		{
			case 357:
			{	
				SetEventString(hEvent, "weapon", "taunt_demoman_katana");
				SetEventString(hEvent, "weapon_logclassname", "taunt_demoman_katana");
				SetEventInt(hEvent, "customkill", 0);
			}
			case 404:
			{	
				SetEventString(hEvent, "weapon", "taunt_demoman_persian_persuader");
				SetEventString(hEvent, "weapon_logclassname", "taunt_demoman_persian_persuader");
				SetEventInt(hEvent, "customkill", 0);
			}
			case 327:
			{	
				SetEventString(hEvent, "weapon", "taunt_demoman_claidheamohmor");
				SetEventString(hEvent, "weapon_logclassname", "taunt_demoman_claidheamohmor");
				SetEventInt(hEvent, "customkill", 0);
			}
			case 266:
			{	
				SetEventString(hEvent, "weapon", "taunt_demoman_headtaker");
				SetEventString(hEvent, "weapon_logclassname", "taunt_demoman_headtaker");
				SetEventInt(hEvent, "customkill", 0);
			}
			case 482:
			{	
				SetEventString(hEvent, "weapon", "taunt_demoman_nessieclub");
				SetEventString(hEvent, "weapon_logclassname", "taunt_demoman_nessieclub");
				SetEventInt(hEvent, "customkill", 0);
			}
		}
	}
	
	else if(iCustom == TF_CUSTOM_DECAPITATION_BOSS)
	{
		SetEventString(hEvent, "weapon", "headtaker_boss");
		SetEventString(hEvent, "weapon_logclassname", "headtaker_boss");
		SetEventInt(hEvent, "customkill", 0);
	}
		
	else if(iIndex==1 && GetEntProp(GetEntPropEnt(iAttacker,PropType:0,"m_hActiveWeapon"), PropType:0, "m_bBroken")==1)
	{
		SetEventString(hEvent, "weapon", "bottle_unbroken");
		SetEventString(hEvent, "weapon_logclassname", "bottle_unbroken");
	}
	else if(iIndex==609 && GetEntProp(GetEntPropEnt(iAttacker,PropType:0,"m_hActiveWeapon"), PropType:0, "m_bBroken")==1)
	{
		SetEventString(hEvent, "weapon", "scotland_shard_unbroken");
		SetEventString(hEvent, "weapon_logclassname", "scotland_shard_unbroken");
	}
	else if(StrEqual(weapon, "deflect_rocket"))//reflected rawkets
	{
		if(!ProjectilesEnabled) return Plugin_Continue;
		new owner = g_hProjectileOwners[iEntity];//what is the first owner of the proj?
		switch(GetPlayerWeaponIndex(owner,0))//deduce weapon index
		{
			case 228:
			{
				SetEventString(hEvent, "weapon", "deflect_rocket_blackbox");
				SetEventString(hEvent, "weapon_logclassname", "deflect_rocket_blackbox");
			}
			case 730:
			{
				SetEventString(hEvent, "weapon", "deflect_rocket_dumpster_device");
				SetEventString(hEvent, "weapon_logclassname", "deflect_rocket_dumpster_device");
			}
			case 127:
			{
				SetEventString(hEvent, "weapon", "deflect_rocket_directhit");
				SetEventString(hEvent, "weapon_logclassname", "deflect_rocket_directhit");
			}
			case 414:
			{
				SetEventString(hEvent, "weapon", "deflect_rocket_liberty");
				SetEventString(hEvent, "weapon_logclassname", "deflect_rocket_liberty");
			}						
		}
	}
	else if(StrEqual(weapon, "deflect_promode"))
	{
		if(GetPlayerWeaponIndex(g_hProjectileOwners[iEntity],0)== 308)
		{
			SetEventString(hEvent, "weapon", "deflect_loch_n_load");
			SetEventString(hEvent, "weapon_logclassname", "deflect_loch_n_load");
		}
	}
	else if (StrEqual(weapon, "huntsman"))
	{
		new damagebits = GetEventInt(hEvent, "damagebits");// copy pasta from another plugin (masteroftheXp, i think)
		if (iCustom == 1 && damagebits & DMG_PLASMA)
		{
			SetEventString(hEvent, "weapon", "huntsman_flyingburn_headshot");
			SetEventInt(hEvent, "customkill", 0);
		}
	}
	else if (StrEqual(weapon, "deflect_arrow"))
	{
		if (iCustom == 1)
		{
			SetEventString(hEvent, "weapon", "deflect_huntsman_headshot");
			SetEventInt(hEvent, "customkill", 0);
		}
	}
	else if (StrEqual(weapon, "deflect_huntsman_flyingburn"))
	{
		new damagebits = GetEventInt(hEvent, "damagebits");
		if (iCustom == 1 && damagebits & DMG_PLASMA)
		{
			SetEventString(hEvent, "weapon", "deflect_huntsman_headshot"); 
			SetEventInt(hEvent, "customkill", 0);
		}
	}
	
	else if(iIndex==851)//Awper bodyshot. WHY would you use a pro and stylish gun to bodyshot people? U MAD?
	{
		SetEventString(hEvent, "weapon", "awper_hand");
		SetEventString(hEvent, "weapon_logclassname", "awper_hand");
	}
	else if(iIndex==775)
	{
		SetEventString(hEvent, "weapon", "pickaxe_escape");
		SetEventString(hEvent, "weapon_logclassname", "pickaxe_escape");
	}
	else if(iIndex==349 && !TF2_IsPlayerInCondition(iVictim,TFCond_OnFire))
	{
		SetEventString(hEvent, "weapon", "lava_bat_nofire");
		SetEventString(hEvent, "weapon_logclassname", "lava_bat_nofire");
	}
	else if(iIndex==38 && !TF2_IsPlayerInCondition(iVictim,TFCond_OnFire))
	{
		SetEventString(hEvent, "weapon", "axtinguisher_nofire");
		SetEventString(hEvent, "weapon_logclassname", "axtinguisher_nofire");
	}
	else if(iIndex==457 && !TF2_IsPlayerInCondition(iVictim,TFCond_OnFire))
	{
		SetEventString(hEvent, "weapon", "mailbox_nofire");
		SetEventString(hEvent, "weapon_logclassname", "mailbox_nofire");
	}
	else//TODO: add a check isMvM and hasBEtheBusterPlugin, so we don't have to check this
	{
		decl String:model[64];
		GetClientModel(iAttacker, model, sizeof(model));
		if(StrEqual(model, "models/bots/demo/bot_sentry_buster.mdl"))//buster model = buster killicon, so people using be the buster thing will enjoy that killicon too
		{
			SetEventString(hEvent, "weapon", "sentry_buster");
			SetEventString(hEvent, "weapon_logclassname", "sentry_buster");
		}
	}
	
	return Plugin_Continue;		
}

public Action:OnProjDeflected(Handle:hEvent,const String:name[], bool:dontBroadcast)
{
	if(!ProjectilesEnabled) return;
	// new iReflector = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iOwner = GetClientOfUserId(GetEventInt(hEvent, "ownerid"));
	new iEntity = GetEventInt(hEvent, "object_entindex");
	if(IsClassName(iEntity,"tf_projectile_rocket") || IsClassName(iEntity,"tf_projectile_pipe"))
	{
		// PrintToChatAll("Yup., iOwner: %d", g_hProjectileOwners[iEntity]);
		g_hProjectileOwners[iEntity]=iOwner;//real OWNER of the proj, not the pyro reflector
	}
	
}

// public onEntityCreated(iEntity, const String:strClassname[])
// {
	// if (!IsValidEntity(iEntity)) return;
	// if (IsClassName(iEntity,"tf_projectile_rocket")||IsClassName(iEntity,"tf_projectile_pipe"))
    // {
    	// new iClient = GetOwner(iEntity);
		// g_hProjectileOwners[iEntity]=iClient;
	// }
// }

stock bool:IsDeflected(iEntity)
{
	return (GetEntProp(iEntity, Prop_Send, "m_iDeflected")>=1);
}

stock GetPlayerWeaponIndex(client, slot)
{
	if(!IsValidClient(client)) return -1;
	new ent = slot > -1 ? GetPlayerWeaponSlot(client, slot) : GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(ent)) return -1;
	return GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
}

stock GetWeaponIndex(ent)
{
	if (!IsValidEntity(ent)) return -1;
	return GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
}

stock bool:IsClassName(iEntity, String:strClassname[]) {
    if (iEntity <= 0) return false;
    if (!IsValidEdict(iEntity)) return false;
        
    decl String:strClassname2[32];
    GetEdictClassname(iEntity, strClassname2, sizeof(strClassname2));
    if (!StrEqual(strClassname, strClassname2, false)) return false;
    
    return true;
}


stock GetOwner(iEntity)
{
    if (IsClassName(iEntity, "tf_projectile_pipe")) return GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
    if (IsClassName(iEntity, "tf_projectile_pipe_remote")) return GetEntPropEnt(iEntity, Prop_Send, "m_hThrower");
    return GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
}

stock bool:IsValidClient(iClient) 
{
    if (iClient <= 0 ||
    	iClient > MaxClients ||
    	!IsClientInGame(iClient))
    	return false;
    
    return true;
}

stock GetWeaponSlot(String:strWeapon[]) {
    // Scout
    if (StrEqual(strWeapon, "soda_popper")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_soda_popper")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_scattergun")) return 0;
    if (StrEqual(strWeapon, "scattergun")) return 0;
    if (StrEqual(strWeapon, "force_a_nature")) return 0;
    if (StrEqual(strWeapon, "handgun_scout_secondary")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_handgun_scout_secondary")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_pistol_scout")) return 1;
    if (StrEqual(strWeapon, "pistol_scout")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_lunchbox_drink")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_bat_wood")) return 2;
    if (StrEqual(strWeapon, "tf_weapon_bat_giftwrap")) return 2;
    if (StrEqual(strWeapon, "bat_giftwrap")) return 2;
    if (StrEqual(strWeapon, "ball")) return 2;
    if (StrEqual(strWeapon, "bat_wood")) return 2;
    if (StrEqual(strWeapon, "bat")) return 2;
    if (StrEqual(strWeapon, "tf_weapon_bat")) return 2;
    if (StrEqual(strWeapon, "taunt_scout")) return 2;
    if (StrEqual(strWeapon, "tf_weapon_bat_fish")) return 2;
    if (StrEqual(strWeapon, "bat_fish")) return 2;
    if (StrEqual(strWeapon, "tf_weapon_handgun_scout_primary")) return 1;
    
    // Soldier
    if (StrEqual(strWeapon, "tf_weapon_rocketlauncher")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_particle_cannon")) return 0;
    if (StrEqual(strWeapon, "particle_cannon")) return 0;
    if (StrEqual(strWeapon, "tf_projectile_energy_ring")) return 0;
    if (StrEqual(strWeapon, "energy_ring")) return 0;
    if (StrEqual(strWeapon, "tf_projectile_rocket")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_rocketlauncher_directhit")) return 0;
    if (StrEqual(strWeapon, "rocketlauncher_directhit")) return 0;
    if (StrEqual(strWeapon, "tf_projectile_energy_ball")) return 1;
    if (StrEqual(strWeapon, "energy_ball")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_shotgun_soldier")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_raygun")) return 1;
    if (StrEqual(strWeapon, "raygun")) return 1;
    if (StrEqual(strWeapon, "shotgun_soldier")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_buff_item")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_shovel")) return 2;
    if (StrEqual(strWeapon, "shovel")) return 2;
    if (StrEqual(strWeapon, "pickaxe")) return 2;
    if (StrEqual(strWeapon, "tf_weapon_katana")) return 2;
    if (StrEqual(strWeapon, "demokatana")) return 2;
    if (StrEqual(strWeapon, "katana")) return 2;
    if (StrEqual(strWeapon, "taunt_soldier")) return 2;
    
    // Pyro
    if (StrEqual(strWeapon, "tf_weapon_drg_pomson")) return 0;
    if (StrEqual(strWeapon, "drg_pomson")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_flamethrower")) return 0;
    if (StrEqual(strWeapon, "flamethrower")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_flaregun_revenge")) return 1;
    if (StrEqual(strWeapon, "flaregun_revenge")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_flaregun")) return 1;
    if (StrEqual(strWeapon, "flaregun")) return 1;
    if (StrEqual(strWeapon, "taunt_pyro")) return 1;
    if (StrEqual(strWeapon, "shotgun_pyro")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_shotgun_pyro")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_fireaxe")) return 2;
    if (StrEqual(strWeapon, "fireaxe")) return 2;
    if (StrEqual(strWeapon, "axtinguisher")) return 2;
    if (StrEqual(strWeapon, "firedeath")) return -2;
    if (StrEqual(strWeapon, "tf_weapon_flaregun_revenge")) return 1;
    
    // Demoman
	if (StrEqual(strWeapon, "tf_projectile_pipe")) return 0;
	if (StrEqual(strWeapon, "tf_weapon_grenadelauncher")) return 0;
	if (StrEqual(strWeapon, "tf_weapon_cannon")) return 0;
	if (StrEqual(strWeapon, "tf_weapon_pipebomblauncher")) return 1;
	if (StrEqual(strWeapon, "tf_projectile_pipe_remote")) return 1;
    if (StrEqual(strWeapon, "sticky_resistance")) return 1;
    if (StrEqual(strWeapon, "tf_wearable_demoshield")) return 1;
    if (StrEqual(strWeapon, "wearable_demoshield")) return 1;
    if (StrEqual(strWeapon, "demoshield")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_bottle")) return 2;
    if (StrEqual(strWeapon, "bottle")) return 2;
    if (StrEqual(strWeapon, "tf_weapon_sword")) return 2;
    if (StrEqual(strWeapon, "tf_weapon_stickbomb")) return 2;
    if (StrEqual(strWeapon, "stickbomb")) return 2;
    if (StrEqual(strWeapon, "sword")) return 2;
    if (StrEqual(strWeapon, "taunt_demoman")) return 2;
	if (StrEqual(strWeapon, "tf_weapon_stickbomb")) return 2;
    
    // Heavy
    if (StrEqual(strWeapon, "tf_weapon_minigun")) return 0;
    if (StrEqual(strWeapon, "minigun")) return 0;
    if (StrEqual(strWeapon, "natascha")) return 0;
    if (StrEqual(strWeapon, "brass_beast")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_shotgun_hwg")) return 1;
    if (StrEqual(strWeapon, "shotgun_hwg")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_lunchbox")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_fists")) return 2;
    if (StrEqual(strWeapon, "fists")) return 2;
    if (StrEqual(strWeapon, "taunt_heavy")) return 2;
    if (StrEqual(strWeapon, "gloves")) return 2;
    
    // Engineer
    if (StrEqual(strWeapon, "tf_weapon_shotgun_primary")) return 0;
    if (StrEqual(strWeapon, "shotgun_primary")) return 0;
    if (StrEqual(strWeapon, "taunt_guitar_kill")) return 0;
    if (StrEqual(strWeapon, "frontier_kill")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_sentry_revenge")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_laser_pointer")) return 1;
    if (StrEqual(strWeapon, "wrangler_kill")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_pistol")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_mechanical_arm")) return 1;
    if (StrEqual(strWeapon, "mechanical_arm")) return 1;
    if (StrEqual(strWeapon, "pistol")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_wrench")) return 2;
    if (StrEqual(strWeapon, "wrench")) return 2;
    if (StrEqual(strWeapon, "tf_weapon_robot_arm")) return 2;
    if (StrEqual(strWeapon, "robot_arm_combo_kill")) return 2;
    if (StrEqual(strWeapon, "robot_arm_kill")) return 2;
    if (StrEqual(strWeapon, "robot_arm_blender_kill")) return 2;
    if (StrEqual(strWeapon, "tf_weapon_pda_engineer_build")) return 3;
    if (StrEqual(strWeapon, "tf_weapon_pda_engineer_destroy")) return 4;
    if (StrEqual(strWeapon, "tf_weapon_drg_pomson")) return 0;
    
    if (StrEqual(strWeapon, "obj_sentrygun")) return 9;
    if (StrEqual(strWeapon, "sentrygun")) return 9;
    
    // Medic
    if (StrEqual(strWeapon, "tf_weapon_syringegun_medic")) return 0;
    if (StrEqual(strWeapon, "syringegun_medic")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_medigun")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_bonesaw")) return 2;
    if (StrEqual(strWeapon, "bonesaw")) return 2;
    if (StrEqual(strWeapon, "ubersaw")) return 2;
    if (StrEqual(strWeapon, "tf_weapon_crossbow")) return 0;
    
    // Sniper
    if (StrEqual(strWeapon, "tf_weapon_compound_bow")) return 0;
    if (StrEqual(strWeapon, "tf_projectile_arrow")) return 0;
    if (StrEqual(strWeapon, "projectile_arrow")) return 0;
    if (StrEqual(strWeapon, "arrow")) return 0;
    if (StrEqual(strWeapon, "taunt_sniper")) return 0;
    if (StrEqual(strWeapon, "huntsman")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_sniperrifle")) return 0;
    if (StrEqual(strWeapon, "sniperrifle")) return 0;
    if (StrEqual(strWeapon, "tf_weapon_smg")) return 1;
    if (StrEqual(strWeapon, "smg")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_jar")) return 1;
    if (StrEqual(strWeapon, "tf_weapon_club")) return 2;
    if (StrEqual(strWeapon, "club")) return 2;
    
    // Spy
    if (StrEqual(strWeapon, "tf_weapon_revolver", false)) return 0;
    if (StrEqual(strWeapon, "revolver", false)) return 0;
    if (StrEqual(strWeapon, "ambassador", false)) return 0;
    if (StrEqual(strWeapon, "tf_weapon_pda_spy", false)) return 1;
    if (StrEqual(strWeapon, "tf_weapon_knife", false)) return 2;
    if (StrEqual(strWeapon, "knife", false)) return 2;
    if (StrEqual(strWeapon, "taunt_spy", false)) return 2;
    if (StrEqual(strWeapon, "tf_weapon_invis", false)) return 4;
    
    return -2;
}
