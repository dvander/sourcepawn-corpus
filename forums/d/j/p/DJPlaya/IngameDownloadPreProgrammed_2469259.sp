//#pragma newdecls required

#define PLUGIN_VERSION "1.2"

#include <sourcemod>
#include <sdktools>
#include <filenetmessages>

public Plugin myinfo = 
{
	name = "[TF2 Only?]InGame Download Preprogrammed",
	author = "Playa (Extension by Popoklopsi)",
	description = "Let Clients download Files while they are Ingame",
	version = PLUGIN_VERSION,
	url = "FunForBattle"
};

public void OnClientPostAdminCheck(int client){
	//vog_Nuke
	FNM_SendFile(client, "sound/misc/horror/the_horror1.wav", 0);
	FNM_SendFile(client, "sound/misc/horror/the_horror2.wav", 0);
	FNM_SendFile(client, "sound/misc/horror/the_horror3.wav", 0);
	FNM_SendFile(client, "sound/misc/horror/the_horror4.wav", 0);
	FNM_SendFile(client, "funforbattle/vox_alert_atomic_weapon_detected.mp3", 0);
	//FFB Custom
	FNM_SendFile(client, "funforbattle/cossack_sandvich.wav", 0);
	FNM_SendFile(client, "funforbattle/dispenser_idle.wav", 0);
	//Spray Decals
	FNM_SendFile(client, "materials/decals/melee.vmt", 0);
	FNM_SendFile(client, "materials/decals/melee.vtf", 0);
	FNM_SendFile(client, "materials/decals/minigun.vmt", 0);
	FNM_SendFile(client, "materials/decals/minigun.vtf", 0);
	FNM_SendFile(client, "materials/decals/rocket.vmt", 0);
	FNM_SendFile(client, "materials/decals/rocket.vtf", 0);
	FNM_SendFile(client, "materials/decals/shotgun.vmt", 0);
	FNM_SendFile(client, "materials/decals/shotgun.vtf", 0);
	FNM_SendFile(client, "materials/decals/swag.vmt", 0);
	FNM_SendFile(client, "materials/decals/swag.vtf", 0);
	FNM_SendFile(client, "materials/decals/target.vmt", 0);
	FNM_SendFile(client, "materials/decals/target.vtf", 0);
	//Duel Head Logos
	FNM_SendFile(client, "materials/free_duel/BLU_Target.vmt", 0);
	FNM_SendFile(client, "materials/free_duel/BLU_Target.vtf", 0);
	FNM_SendFile(client, "materials/free_duel/RED_Target.vmt", 0);
	FNM_SendFile(client, "materials/free_duel/RED_Target.vtf", 0);
	//Saxton Hale & Vagineer
	FNM_SendFile(client, "materials/models/player/saxton_hale/eye.vmt", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/eye.vtf", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/eyeball_l.vmt", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/eyeball_r.vmt", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/hale_body.vmt", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/hale_body.vtf", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/hale_body_normal.vtf", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/hale_egg.vmt", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/hale_egg.vtf", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/hale_head.vmt", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/hale_head.vtf", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/hale_misc.vmt", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/hale_misc.vtf", 0);
	FNM_SendFile(client, "materials/models/player/saxton_hale/hale_misc_normal.vtf", 0);
	FNM_SendFile(client, "models/player/saxton_hale/saxton_hale.dx80.vtx", 0);
	FNM_SendFile(client, "models/player/saxton_hale/saxton_hale.dx90.vtx", 0);
	FNM_SendFile(client, "models/player/saxton_hale/saxton_hale.mdl", 0);
	FNM_SendFile(client, "models/player/saxton_hale/saxton_hale.sw.vtx", 0);
	FNM_SendFile(client, "models/player/saxton_hale/saxton_hale.vvd", 0);
	FNM_SendFile(client, "models/player/saxton_hale/vagineer_v134.dx80.vtx", 0);
	FNM_SendFile(client, "models/player/saxton_hale/vagineer_v134.dx90.vtx", 0);
	FNM_SendFile(client, "models/player/saxton_hale/vagineer_v134.mdl", 0);
	FNM_SendFile(client, "models/player/saxton_hale/vagineer_v134.sw.vtx", 0);
	FNM_SendFile(client, "models/player/saxton_hale/vagineer_v134.vvd", 0);
	//Map Photos and Videos
	FNM_SendFile(client, "materials/vgui/maps/menu_photos_koth_haunted_fall_event.vmt", 0);
	FNM_SendFile(client, "materials/vgui/maps/menu_photos_koth_haunted_fall_event.vtf", 0);
	FNM_SendFile(client, "materials/vgui/maps/menu_photos_koth_spaaaace_beta_01.vmt", 0);
	FNM_SendFile(client, "materials/vgui/maps/menu_photos_koth_spaaaace_beta_01.vtf", 0);
	FNM_SendFile(client, "materials/vgui/maps/menu_photos_mvm_manndarin_final.vmt", 0);
	FNM_SendFile(client, "materials/vgui/maps/menu_photos_mvm_manndarin_final.vtf", 0);
	FNM_SendFile(client, "materials/vgui/maps/menu_thumb_mvm_manndarin_final.vmt", 0);
	FNM_SendFile(client, "materials/vgui/maps/menu_thumb_mvm_manndarin_final.vtf", 0);
	FNM_SendFile(client, "media/koth_spaaaace_beta_01.bik", 0);
	//Firework
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_pang01.mp3", 0);
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_shatter01.mp3", 0);
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_spark001.wav", 0);
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_spark002.wav", 0);
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_spark003.wav", 0);
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_spark004.wav", 0);
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_spark005.wav", 0);
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_spark006.wav", 0);
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_spark007.mp3", 0);
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_spark008.mp3", 0);
	FNM_SendFile(client, "sound/ambient/fireworks/fireworks_spark009.mp3", 0);
	//Tetris
	FNM_SendFile(client, "sound/tetris/full_line.mp3", 0);
	FNM_SendFile(client, "sound/tetris/game_over.mp3", 0);
	FNM_SendFile(client, "sound/tetris/level_up.mp3", 0);
	FNM_SendFile(client, "sound/tetris/music_a.mp3", 0);
	FNM_SendFile(client, "sound/tetris/place_block.mp3", 0);
	FNM_SendFile(client, "sound/tetris/rotate_block.mp3", 0);
	FNM_SendFile(client, "sound/tetris/tetris.mp3", 0);
	//Goomba Stomp
	FNM_SendFile(client, "sound/goomba/rebound.wav", 0);
	FNM_SendFile(client, "sound/goomba/stomp.wav", 0);
	//Ion Cannon
	FNM_SendFile(client, "sound/ion/approaching.wav", 0);
	FNM_SendFile(client, "sound/ion/attack.wav", 0);
	FNM_SendFile(client, "sound/ion/beacon_beep.wav", 0);
	FNM_SendFile(client, "sound/ion/beacon_plant.wav", 0);
	FNM_SendFile(client, "sound/ion/beacon_set.wav", 0);
	FNM_SendFile(client, "sound/ion/ready.wav", 0);
	//Hax
	FNM_SendFile(client, "sound/res/drhax/hax.mp3", 0);
	//Trainrain
	FNM_SendFile(client, "sound/trainsawlaser/extra/sound1.wav", 0);
	FNM_SendFile(client, "sound/trainsawlaser/extra/sound2.wav", 0);
	//Fix for Weapon Unusuals
	FNM_SendFile(client, "particles/unusuals_custom1.pcf", 0);
	//I really dunno
	FNM_SendFile(client, "materials/models/player/items/templates/standard.vmt", 0);
}