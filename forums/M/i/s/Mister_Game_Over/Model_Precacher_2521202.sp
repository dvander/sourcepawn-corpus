#pragma semicolon 1
#include <sourcemod>

new Handle:h_L4dSurvivorsEnabled   = INVALID_HANDLE;
new Handle:h_L4d2SurvivorsEnabled  = INVALID_HANDLE;
new Handle:h_WeaponsEnabled        = INVALID_HANDLE;
new Handle:h_M60GlEnabled          = INVALID_HANDLE;
new Handle:h_MeleeWeaponsEnabled   = INVALID_HANDLE;
new Handle:h_CssWeaponsEnabled     = INVALID_HANDLE;
new Handle:h_InfectedEnabled       = INVALID_HANDLE;
new Handle:h_CommonInfectedEnabled = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Model Precacher",
	author = "Satannuts, Mister Game Over",
	description = "Precaches models.",
	version = "1.0",
	url = "steamcommunity.com/profiles/76561198203206199"
};

public OnPluginStart()
{
	h_L4dSurvivorsEnabled   = CreateConVar ("precache_l4d_survivors",    "1",  "Precaching L4D Survivors",         FCVAR_NOTIFY|FCVAR_PLUGIN);	
	h_L4d2SurvivorsEnabled  = CreateConVar ("precache_l4d2_survivors",   "1",  "Precaching L4D2 Survivors",        FCVAR_NOTIFY|FCVAR_PLUGIN);
	h_WeaponsEnabled        = CreateConVar ("precache_weapon",           "1",  "Precaching Weapons",               FCVAR_NOTIFY|FCVAR_PLUGIN);		
	h_M60GlEnabled          = CreateConVar ("precache_m60_gl",           "1",  "Precaching M60, Grenade Launcher", FCVAR_NOTIFY|FCVAR_PLUGIN);	
	h_MeleeWeaponsEnabled   = CreateConVar ("precache_melee_weapons",    "1",  "Precaching Melee Weapons",         FCVAR_NOTIFY|FCVAR_PLUGIN);	
	h_CssWeaponsEnabled	    = CreateConVar ("precache_css_weapons",      "1",  "Precaching Css Weapons",           FCVAR_NOTIFY|FCVAR_PLUGIN);	
	h_InfectedEnabled	    = CreateConVar ("precache_infected",         "1",  "Precaching Infected",              FCVAR_NOTIFY|FCVAR_PLUGIN);	
	h_CommonInfectedEnabled	= CreateConVar ("precache_common_infected",  "1",  "Precaching Common Infected",       FCVAR_NOTIFY|FCVAR_PLUGIN);	
	AutoExecConfig(true, "model_precacher");		
}	

public OnMapStart()
{
	if (!GetConVarBool(h_L4dSurvivorsEnabled)) return;  
	if(!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))          PrecacheModel("models/survivors/survivor_teenangst.mdl");
	if(!IsModelPrecached("models/survivors/survivor_biker.mdl"))              PrecacheModel("models/survivors/survivor_biker.mdl");
	if(!IsModelPrecached("models/survivors/survivor_manager.mdl"))            PrecacheModel("models/survivors/survivor_manager.mdl");
	if(!IsModelPrecached("models/survivors/survivor_namvet.mdl"))             PrecacheModel("models/survivors/survivor_namvet.mdl");

	if (!GetConVarBool(h_L4d2SurvivorsEnabled))	return;
	if(!IsModelPrecached("models/survivors/survivor_coach.mdl"))              PrecacheModel("models/survivors/survivor_coach.mdl");
	if(!IsModelPrecached("models/survivors/survivor_gambler.mdl"))            PrecacheModel("models/survivors/survivor_gambler.mdl");
	if(!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))           PrecacheModel("models/survivors/survivor_mechanic.mdl");
	if(!IsModelPrecached("models/survivors/survivor_producer.mdl"))           PrecacheModel("models/survivors/survivor_producer.mdl");

	if (!GetConVarBool(h_WeaponsEnabled)) return;	
	if (!IsModelPrecached("models/v_models/v_pistola.mdl"))        	          PrecacheModel("models/v_models/v_pistola.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_pistol_a.mdl"))          PrecacheModel("models/w_models/weapons/w_pistol_a.mdl");		
	if (!IsModelPrecached("models/v_models/v_dual_pistola.mdl"))        	  PrecacheModel("models/v_models/v_dual_pistola.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_pistol_b.mdl"))          PrecacheModel("models/w_models/weapons/w_pistol_b.mdl");	
	if (!IsModelPrecached("models/v_models/v_desert_eagle.mdl"))        	  PrecacheModel("models/v_models/v_desert_eagle.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_desert_eagle.mdl"))      PrecacheModel("models/w_models/weapons/w_desert_eagle.mdl");				
	if (!IsModelPrecached("models/v_models/v_shotgun_chrome.mdl"))        	  PrecacheModel("models/v_models/v_shotgun_chrome.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_shotgun.mdl"))           PrecacheModel("models/w_models/weapons/w_shotgun.mdl");	
	if (!IsModelPrecached("models/v_models/v_pumpshotgun.mdl"))        	      PrecacheModel("models/v_models/v_pumpshotgun.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_pumpshotgun_a.mdl"))     PrecacheModel("models/w_models/weapons/w_pumpshotgun_a.mdl");		
	if (!IsModelPrecached("models/v_models/v_autoshotgun.mdl"))        	      PrecacheModel("models/v_models/v_autoshotgun.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_autoshot_m4super.mdl"))  PrecacheModel("models/w_models/weapons/w_autoshot_m4super.mdl");	
	if (!IsModelPrecached("models/v_models/v_shotgun_spas.mdl"))        	  PrecacheModel("models/v_models/v_shotgun_spas.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_shotgun_spas.mdl"))      PrecacheModel("models/w_models/weapons/w_shotgun_spas.mdl");	
	if (!IsModelPrecached("models/v_models/v_smg.mdl"))        	              PrecacheModel("models/v_models/v_smg.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_smg_uzi.mdl"))           PrecacheModel("models/w_models/weapons/w_smg_uzi.mdl");	
	if (!IsModelPrecached("models/v_models/v_silenced_smg.mdl"))        	  PrecacheModel("models/v_models/v_silenced_smg.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_smg_a.mdl"))             PrecacheModel("models/w_models/weapons/w_smg_a.mdl");	
	if (!IsModelPrecached("models/v_models/v_desert_rifle.mdl"))        	  PrecacheModel("models/v_models/v_desert_rifle.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_desert_rifle.mdl"))      PrecacheModel("models/w_models/weapons/w_desert_rifle.mdl");	
	if (!IsModelPrecached("models/v_models/v_rifle.mdl"))        	          PrecacheModel("models/v_models/v_rifle.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_rifle_m16a2.mdl"))       PrecacheModel("models/w_models/weapons/w_rifle_m16a2.mdl");	
	if (!IsModelPrecached("models/v_models/v_rifle_ak47.mdl"))        	      PrecacheModel("models/v_models/v_rifle_ak47.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_rifle_ak47.mdl"))        PrecacheModel("models/w_models/weapons/w_rifle_ak47.mdl");			
	if (!IsModelPrecached("models/v_models/v_huntingrifle.mdl"))        	  PrecacheModel("models/v_models/v_huntingrifle.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_mini14.mdl"))     PrecacheModel("models/w_models/weapons/w_sniper_mini14.mdl");	
	if (!IsModelPrecached("models/v_models/v_sniper_military.mdl"))        	  PrecacheModel("models/v_models/v_sniper_military.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_military.mdl"))   PrecacheModel("models/w_models/weapons/w_sniper_military.mdl");				
	
	if (!GetConVarBool(h_M60GlEnabled)) return;
	if (!IsModelPrecached("models/v_models/v_m60.mdl"))        	              PrecacheModel("models/v_models/v_m60.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl"))               PrecacheModel("models/w_models/weapons/w_m60.mdl");
	if (!IsModelPrecached("models/v_models/v_grenade_launcher.mdl"))          PrecacheModel("models/v_models/v_grenade_launcher.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_grenade_launcher.mdl"))  PrecacheModel("models/w_models/weapons/w_grenade_launcher.mdl");
	
	if (!GetConVarBool(h_MeleeWeaponsEnabled)) return;
	if (!IsModelPrecached("models/weapons/melee/v_golfclub.mdl"))             PrecacheModel("models/weapons/melee/v_golfclub.mdl");
	if (!IsModelPrecached("models/weapons/melee/w_golfclub.mdl"))             PrecacheModel("models/weapons/melee/w_golfclub.mdl");
	if (!IsModelPrecached("models/weapons/melee/v_bat.mdl"))                  PrecacheModel("models/weapons/melee/v_bat.mdl");
	if (!IsModelPrecached("models/weapons/melee/w_bat.mdl"))                  PrecacheModel("models/weapons/melee/w_bat.mdl");
	if (!IsModelPrecached("models/weapons/melee/v_riotshield.mdl"))           PrecacheModel("models/weapons/melee/v_riotshield.mdl");
	if (!IsModelPrecached("models/weapons/melee/w_riotshield.mdl"))           PrecacheModel("models/weapons/melee/w_riotshield.mdl");
	if (!IsModelPrecached("models/weapons/melee/v_tonfa.mdl"))                PrecacheModel("models/weapons/melee/v_tonfa.mdl");
	if (!IsModelPrecached("models/weapons/melee/w_tonfa.mdl"))                PrecacheModel("models/weapons/melee/w_tonfa.mdl");
	if (!IsModelPrecached("models/weapons/melee/v_cricket_bat.mdl"))          PrecacheModel("models/weapons/melee/v_cricket_bat.mdl");	
	if (!IsModelPrecached("models/weapons/melee/w_cricket_bat.mdl"))          PrecacheModel("models/weapons/melee/w_cricket_bat.mdl");	
	if (!IsModelPrecached("models/weapons/melee/v_crowbar.mdl"))              PrecacheModel("models/weapons/melee/v_crowbar.mdl");	
	if (!IsModelPrecached("models/weapons/melee/w_crowbar.mdl"))              PrecacheModel("models/weapons/melee/w_crowbar.mdl");		
	if (!IsModelPrecached("models/weapons/melee/v_chainsaw.mdl"))             PrecacheModel("models/weapons/melee/v_chainsaw.mdl");	
	if (!IsModelPrecached("models/weapons/melee/w_chainsaw.mdl"))             PrecacheModel("models/weapons/melee/w_chainsaw.mdl");	
	if (!IsModelPrecached("models/weapons/melee/v_electric_guitar.mdl"))      PrecacheModel("models/weapons/melee/v_electric_guitar.mdl");	
	if (!IsModelPrecached("models/weapons/melee/w_electric_guitar.mdl"))      PrecacheModel("models/weapons/melee/w_electric_guitar.mdl");	
	if (!IsModelPrecached("models/weapons/melee/v_fireaxe.mdl"))              PrecacheModel("models/weapons/melee/v_fireaxe.mdl");	
	if (!IsModelPrecached("models/weapons/melee/w_fireaxe.mdl"))              PrecacheModel("models/weapons/melee/w_fireaxe.mdl");	
	if (!IsModelPrecached("models/weapons/melee/v_frying_pan.mdl"))           PrecacheModel("models/weapons/melee/v_frying_pan.mdl");	
	if (!IsModelPrecached("models/weapons/melee/w_frying_pan.mdl"))           PrecacheModel("models/weapons/melee/w_frying_pan.mdl");	
	if (!IsModelPrecached("models/weapons/melee/v_katana.mdl"))               PrecacheModel("models/weapons/melee/v_katana.mdl");	
	if (!IsModelPrecached("models/weapons/melee/w_katana.mdl"))               PrecacheModel("models/weapons/melee/w_katana.mdl");	
	if (!IsModelPrecached("models/weapons/melee/v_machete.mdl"))              PrecacheModel("models/weapons/melee/v_machete.mdl");	
	if (!IsModelPrecached("models/weapons/melee/w_machete.mdl"))              PrecacheModel("models/weapons/melee/w_machete.mdl");

	if (!GetConVarBool(h_CssWeaponsEnabled)) return;
	if (!IsModelPrecached("models/v_models/v_rif_sg552.mdl"))                 PrecacheModel("models/v_models/v_rif_sg552.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_rifle_sg552.mdl"))       PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl");
	if (!IsModelPrecached("models/v_models/v_snip_awp.mdl"))                  PrecacheModel("models/v_models/v_snip_awp.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_awp.mdl"))        PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl");
	if (!IsModelPrecached("models/v_models/v_snip_scout.mdl"))                PrecacheModel("models/v_models/v_snip_scout .mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_scout.mdl"))      PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");
	if (!IsModelPrecached("models/v_models/v_smg_mp5.mdl"))                   PrecacheModel("models/v_models/v_smg_mp5.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_smg_mp5.mdl"))           PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");
	if (!IsModelPrecached("models/v_models/v_knife_t.mdl"))                   PrecacheModel("models/v_models/v_knife_t.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_knife_t.mdl"))           PrecacheModel("models/w_models/weapons/w_knife_t.mdl");

	if (!GetConVarBool(h_InfectedEnabled)) return;
	if (!IsModelPrecached("models/infected/hulk.mdl"))                        PrecacheModel("models/infected/hulk.mdl");
	if (!IsModelPrecached("models/infected/hulk_dlc3.mdl"))                   PrecacheModel("models/infected/hulk_dlc3.mdl");	
	if (!IsModelPrecached("models/infected/witch.mdl"))                       PrecacheModel("models/infected/witch.mdl");
	if (!IsModelPrecached("models/infected/witch_bride.mdl"))                 PrecacheModel("models/infected/witch_bride.mdl");	
	if (!IsModelPrecached("models/infected/boomette.mdl"))                    PrecacheModel("models/infected/boomette.mdl");
	if (!IsModelPrecached("models/infected/limbs/exploded_boomette.mdl"))     PrecacheModel("models/infected/limbs/exploded_boomette.mdl");

	if (!GetConVarBool(h_CommonInfectedEnabled)) return;
	if (!IsModelPrecached("models/infected/common_male_ceda.mdl"))            PrecacheModel("models/infected/common_male_ceda.mdl");
	if (!IsModelPrecached("models/infected/common_male_clown.mdl"))           PrecacheModel("models/infected/common_male_clown.mdl");
	if (!IsModelPrecached("models/infected/common_male_fallen_survivor.mdl")) PrecacheModel("models/infected/common_male_fallen_survivor.mdl");
	if (!IsModelPrecached("models/infected/common_male_jimmy.mdl"))           PrecacheModel("models/infected/common_male_jimmy.mdl");
	if (!IsModelPrecached("models/infected/common_male_mud.mdl"))             PrecacheModel("models/infected/common_male_mud.mdl");
	if (!IsModelPrecached("models/infected/common_male_riot.mdl"))            PrecacheModel("models/infected/common_male_riot.mdl");
	if (!IsModelPrecached("models/infected/common_male_roadcrew.mdl"))        PrecacheModel("models/infected/common_male_roadcrew.mdl");
}