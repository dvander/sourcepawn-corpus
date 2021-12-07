public Plugin:myinfo = 
{
	name = "Precache",
	author = "gamemann",
	description = "",
	version = "1.0",
	url = "http://games223.com"
}
	
public PrecacheSurvModel()
{

		//css weapons and m60
		PrecacheModel("models/v_models/v_rif_sg552.mdl");
		PrecacheModel("models/v_models/v_smg_mp5.mdl");
		PrecacheModel("models/v_models/v_snip_awp.mdl");
		PrecacheModel("models/v_models/v_sniper_scout.mdl");

		PrecacheModel("models/w_models/weapons/w_rif_sg552.mdl");
		PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");
		PrecacheModel("models/w_models/weapons/w_snip_awp.mdl");
		PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");
		PrecacheModel("models/v_models/v_m60.mdl");
		PrecacheModel("models/w_models/w_models/weapons/w_m60.mdl");
		//other stuff
		if (!IsModelPrecached("models/infected/common_male_ceda.mdl")) PrecacheModel("models/infected/common_male_ceda.mdl", true); 
		SetConVarInt(FindConVar("precache_l4d1_survivors"), 1, true, true);
		//w weapon models
		PrecacheModel("models/weapons/melee/w_fireaxe.mdl");
		PrecacheModel("models/weapons/melee/w_crowbar.mdl");
		PrecacheModel("models/weapons/melee/w_electric_guitar.mdl");
		PrecacheModel("models/weapons/melee/w_chainsaw.mdl");
		PrecacheModel("modles/weapons/melee/w_cricket_bat");
		PrecacheModel("models/weapons/melee/w_bat.mdl");
		PrecacheModel("models/weapons/melee/w_tonfa.mdl");
		PrecacheModel("models/weapons/melee/w_riotshield.mdl");
		PrecacheModel("models/weapons/melee/w_katana.mdl");
		PrecacheModel("models/weapons/melee/w_machete.mdl");
		PrecacheModel("models/weapons/melee/w_frying_pan.mdl");
		PrecacheModel("models/weapons/melee/w_didgeridoo.mdl");
		//gun weapons
		PrecacheModel("models/w_models/weapons/50cal.mdl");
		PrecacheModel("models/w_models/weapons/w_autoshot_m4super.mdl")
		PrecacheModel("models/w_models/weapons/w_cola.mdl");
		PrecacheModel("models/w_models/weapons/w_desert_rifle.mdl");
		//v weapon models
		PrecacheModel("models/weapons/melee/v_fireaxe.mdl");
		PrecacheModel("models/weapons/melee/v_crowbar.mdl");
		PrecacheModel("models/weapons/melee/v_electric_guitar.mdl");
		PrecacheModel("models/weapons/melee/v_chainsaw.mdl");
		PrecacheModel("modles/weapons/melee/v_cricket_bat");
		PrecacheModel("models/weapons/melee/v_bat.mdl");
		PrecacheModel("models/weapons/melee/v_tonfa.mdl");
		PrecacheModel("models/weapons/melee/v_riotshield.mdl");
		PrecacheModel("models/weapons/melee/v_katana.mdl");
		PrecacheModel("models/weapons/melee/v_machete.mdl");
		PrecacheModel("models/weapons/melee/v_frying_pan.mdl");
		PrecacheModel("models/weapons/melee/v_didgeridoo.mdl");

		//survivors
		PrecacheModel("models/survivors/survivor_coach.mdl");
		PrecacheModel("models/survivors/survivor_gambler.mdl");
		PrecacheModel("models/survivors/survivor_producer.mdl");
		PrecacheModel("models/survivors/survivor_mechanic.mdl");
		PrecacheModel("models/survivors/survivor_teenangst.mdl");
		PrecacheModel("models/survivors/survivor_biker.mdl");
		PrecacheModel("models/survivors/survivor_manager.mdl");
		PrecacheModel("models/survivors/survivor_namvet.mdl");
		
		//infected models
		PrecacheModel("models/infected/charger.mdl");
		PrecacheModel("models/infected/hunter.mdl");
		PrecacheModel("models/infected/boomer.mdl");
		PrecacheModel("models/infected/smoker.mdl");
		PrecacheModel("models/infected/jockey.mdl");
		PrecacheModel("models/infected/spitter.mdl");
		PrecacheModel("models/infected/witch.mdl");
		PrecacheModel("models/infected/witch_bride.mdl");
		PrecacheModel("models/infected/boomette.mdl");
		PrecacheModel("models/infected/hulk.mdl");
		//commen zombies
		PrecacheModel("models/infected/common_male_ceda.mdl");
		PrecacheModel("models/infected/common_male_clown.mdl");
		PrecacheModel("models/infected/common_male_mud.mdl");
		PrecacheModel("models/infected/common_male_roadcrew.mdl");
		PrecacheModel("models/infected/common_male_riot.mdl");
		PrecacheModel("models/infected/common_male_fallen_survivor.mdl");
		PrecacheModel("models/infected/common_male_jimmy.mdl");
		//other
		PrecacheModel("models/error.mdl");
		PrecacheModel("models/weapons/error.mdl");
		PrecacheModel("models/infected/error.mdl");
		PrecacheModel("models/infected/limbs/exploded_boomette.mdl");
		PrecacheModel("models/infected/limbs/exploded_boomer_steak1.mdl");
		PrecacheModel("models/infected/limbs/exploded_boomer_steak2.mdl");
}

public OnMapStart()
{
	PrecacheSurvModel();
}