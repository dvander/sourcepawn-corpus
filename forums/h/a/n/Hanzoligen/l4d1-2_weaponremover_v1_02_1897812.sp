#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.02"
public Plugin:myinfo =
{
	name = "[L4D1+2] Weapon Remover",
	author = "Hanzolo (original version by Rain_orel)",
	description = "Removes weapon spawn when a specified number of pickups is reached",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new ent_table[64][2];
new new_ent_counter = 0;
new Handle:cvar_pluginOn;
new bool:g_pluginOn = true;

new Handle:limit_all;
new Handle:limit_autoshotgun;   // ### L4D1 Weapons (also L4D2) ###
new Handle:limit_rifle;
new Handle:limit_hunting_rifle;
new Handle:limit_pistol;
new Handle:limit_pumpshotgun;
new Handle:limit_smg;
//new Handle:limit_autoshotgun; // ### L4D2 Weapons - doubles are disabled ###
new Handle:limit_grenade_launcher;
//new Handle:limit_hunting_rifle;
//new Handle:limit_pistol;
new Handle:limit_pistol_magnum;
//new Handle:limit_pumpshotgun;
//new Handle:limit_rifle;
new Handle:limit_rifle_ak47;
new Handle:limit_rifle_desert;
new Handle:limit_rifle_m60;
new Handle:limit_rifle_sg552;
new Handle:limit_shotgun_chrome;
new Handle:limit_shotgun_spas;
//new Handle:limit_smg;
new Handle:limit_smg_mp5;
new Handle:limit_smg_silenced;
new Handle:limit_sniper_awp;
new Handle:limit_sniper_military;
new Handle:limit_sniper_scout;
new String:game_name[64];
	
public OnPluginStart()
{
	// Requires L4D1 or L4D2 to run
	//decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false)){
		SetFailState("Plugin supports Left 4 Dead or Left 4 Dead 2 only.");
	}

	CreateConVar("l4d_weaponremove_version", PLUGIN_VERSION, "[l4d1+2] Weapon Remover limits the maximum number of times a weapon can be grabbed", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_pluginOn = CreateConVar("l4d_weaponremove_enable", "1", "Enable or disable Weapon Remover plugin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	limit_all = CreateConVar("l4d_weaponremove_limit_all", "0", "Limits all weapons to this many pickups (0=no limit)", FCVAR_PLUGIN);

	if (g_pluginOn == false)
		UnhookEvent("spawner_give_item", Event_SpawnerGiveItem);
	else
		HookEvent("spawner_give_item", Event_SpawnerGiveItem);
		
	HookConVarChange(cvar_pluginOn, OnOffCvarChanged);
	
	// L4D1 + L4D2
	limit_autoshotgun = CreateConVar("l4d_weaponremove_limit_autoshotgun", "1", "Limit for Autoshotguns (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_rifle = CreateConVar("l4d_weaponremove_limit_rifle", "1", "Limit for M4s (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_hunting_rifle = CreateConVar("l4d_weaponremove_limit_hunting_rifle", "1", "Limit for Sniper Rifles (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_pistol = CreateConVar("l4d_weaponremove_limit_pistol", "1", "Limit for Pistols (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_pumpshotgun = CreateConVar("l4d_weaponremove_limit_pumpshotgun", "1", "Limit for Pumpshotguns (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_smg = CreateConVar("l4d_weaponremove_limit_smg", "1", "Limit for SMGs (0=infinite, -1=disable)", FCVAR_PLUGIN);
	
	// L4D2
	if (StrEqual(game_name, "left4dead2", false)){
	limit_grenade_launcher = CreateConVar("l4d2_weaponremove_limit_grenade_launcher", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_pistol_magnum = CreateConVar("l4d2_weaponremove_limit_pistol_magnum", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_rifle_ak47 = CreateConVar("l4d2_weaponremove_limit_rifle_ak47", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_rifle_desert = CreateConVar("l4d2_weaponremove_limit_rifle_desert", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_rifle_m60 = CreateConVar("l4d2_weaponremove_limit_rifle_m60", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_rifle_sg552 = CreateConVar("l4d2_weaponremove_limit_rifle_sg552", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_shotgun_chrome = CreateConVar("l4d2_weaponremove_limit_shotgun_chrome", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_shotgun_spas = CreateConVar("l4d2_weaponremove_limit_shotgun_spas", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_smg_mp5 = CreateConVar("l4d2_weaponremove_limit_smg_mp5", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_smg_silenced = CreateConVar("l4d2_weaponremove_limit_smg_silenced", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_sniper_awp = CreateConVar("l4d2_weaponremove_limit_sniper_awp", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_sniper_military = CreateConVar("l4d2_weaponremove_limit_sniper_military", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);
	limit_sniper_scout = CreateConVar("l4d2_weaponremove_limit_sniper_scout", "1", "Limit for this weapon (0=infinite, -1=disable)", FCVAR_PLUGIN);	
	}
	
//dyzer-adds
	AutoExecConfig(true, "l4d1-2_weaponremover");
}

public OnMapStart()
{
	for(new i=0;i<63;i++)	{
		ent_table[i][0]=-1;
		ent_table[i][1]=-1;
	}
	new_ent_counter = 0;

	// Remove all weapons which have a limit of "-1"
	// L4D1 + 2
	if (GetConVarInt(limit_autoshotgun)<0) DeleteAllEntities("weapon_autoshotgun_spawn");
	if (GetConVarInt(limit_rifle)<0) DeleteAllEntities("weapon_rifle_spawn");
	if (GetConVarInt(limit_hunting_rifle)<0) DeleteAllEntities("weapon_hunting_rifle_spawn");
	if (GetConVarInt(limit_pistol)<0) DeleteAllEntities("weapon_pistol_spawn");
	if (GetConVarInt(limit_pumpshotgun)<0) DeleteAllEntities("weapon_pumpshotgun_spawn");
	if (GetConVarInt(limit_smg)<0) DeleteAllEntities("weapon_smg_spawn");
	// L4D2
	if (StrEqual(game_name, "left4dead2", false)){
	if (GetConVarInt(limit_grenade_launcher)<0) DeleteAllEntities("weapon_grenade_launcher_spawn");
	if (GetConVarInt(limit_pistol_magnum)<0) DeleteAllEntities("weapon_pistol_magnum_spawn");
	if (GetConVarInt(limit_rifle_ak47)<0) DeleteAllEntities("weapon_rifle_ak47_spawn");
	if (GetConVarInt(limit_rifle_desert)<0) DeleteAllEntities("weapon_rifle_desert_spawn");
	if (GetConVarInt(limit_rifle_m60)<0) DeleteAllEntities("weapon_rifle_m60_spawn");
	if (GetConVarInt(limit_rifle_sg552)<0) DeleteAllEntities("weapon_rifle_sg552_spawn");
	if (GetConVarInt(limit_shotgun_chrome)<0) DeleteAllEntities("weapon_shotgun_chrome_spawn");
	if (GetConVarInt(limit_shotgun_spas)<0) DeleteAllEntities("weapon_shotgun_spas_spawn");
	if (GetConVarInt(limit_smg_mp5)<0) DeleteAllEntities("weapon_smg_mp5_spawn");
	if (GetConVarInt(limit_smg_silenced)<0) DeleteAllEntities("weapon_smg_silenced_spawn");
	if (GetConVarInt(limit_sniper_awp)<0) DeleteAllEntities("weapon_sniper_awp_spawn");
	if (GetConVarInt(limit_sniper_military)<0) DeleteAllEntities("weapon_sniper_military_spawn");
	if (GetConVarInt(limit_sniper_scout)<0) DeleteAllEntities("weapon_sniper_scout_spawn");
	}
	
}

public OnMapEnd(){}

public Event_SpawnerGiveItem(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_pluginOn == false)
		return;

   decl String:item_name[32];
   GetEventString(event, "item", item_name, 32);
   new entity_id = GetEventInt(event, "spawner");
   
   
   if(GetUseCount(entity_id)==-1){
		ent_table[new_ent_counter][0]=entity_id;
		ent_table[new_ent_counter][1]=0;
		new_ent_counter++;
   }
   
   SetUseCount(entity_id);
   
   //PrintToServer("item_name is %s ", item_name); // DEBUG
   
   if((GetUseCount(entity_id)==GetConVarInt(limit_all))||
	  ((StrEqual(item_name, "weapon_autoshotgun", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_autoshotgun)))||
      ((StrEqual(item_name, "weapon_rifle", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_rifle)))||
	  ((StrEqual(item_name, "weapon_hunting_rifle", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_hunting_rifle)))||
	  ((StrEqual(item_name, "weapon_pistol", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_pistol)))||
	  ((StrEqual(item_name, "weapon_pumpshotgun", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_pumpshotgun)))||
	  ((StrEqual(item_name, "weapon_smg", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_smg)))||
	  ((StrEqual(item_name, "weapon_grenade_launcher", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_grenade_launcher)))||
	  ((StrEqual(item_name, "weapon_pistol_magnum", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_pistol_magnum)))||
	  ((StrEqual(item_name, "weapon_rifle_ak47", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_rifle_ak47)))||
	  ((StrEqual(item_name, "weapon_rifle_desert", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_rifle_desert)))||
	  ((StrEqual(item_name, "weapon_rifle_m60", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_rifle_m60)))||
	  ((StrEqual(item_name, "weapon_rifle_sg552", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_rifle_sg552)))||
	  ((StrEqual(item_name, "weapon_shotgun_chrome", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_shotgun_chrome)))||
	  ((StrEqual(item_name, "weapon_shotgun_spas", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_shotgun_spas)))||
	  ((StrEqual(item_name, "weapon_smg_mp5", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_smg_mp5)))||
	  ((StrEqual(item_name, "weapon_smg_silenced", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_smg_silenced)))||
	  ((StrEqual(item_name, "weapon_sniper_awp", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_sniper_awp)))||
	  ((StrEqual(item_name, "weapon_sniper_military", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_sniper_military)))||
	  ((StrEqual(item_name, "weapon_sniper_scout", false)==true)&&(GetUseCount(entity_id)==GetConVarInt(limit_sniper_scout)))	  
	 )
   {
   RemoveEdict(entity_id);
   }
}

GetUseCount(entid)
{
	for(new i=0;i<63;i++){
		if(ent_table[i][0]==entid)return ent_table[i][1];
	}
	return -1
}

SetUseCount(entid)
{
	for(new j=0;j<63;j++){
		if(ent_table[j][0]==entid)ent_table[j][1]++;
	}
}

	
// code for deleting entities from http://docs.sourcemod.net/api/index.php?fastload=show&id=425&
stock DeleteAllEntities(const String:ent_to_delete[])
{
	new entity = -1;
		while ((entity = FindEntityByClassname(entity, ent_to_delete)) != INVALID_ENT_REFERENCE) {
			AcceptEntityInput(entity, "Kill");
		}	
}

public OnOffCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_pluginOn = GetConVarBool(cvar_pluginOn);
}
	
	