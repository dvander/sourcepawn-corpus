
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.6"
#define ENTITYARRYSIZE 4
#define AMMOARRYSIZE 4
#define AMMOOARRYSIZE 4

static const String:g_weaponEntitys[24][] = { "weapon_amerknife",
										"weapon_spade",
										"weapon_colt",
										"weapon_p38",
										"weapon_m1carb",
										"weapon_c96",
										"weapon_garand",
										"weapon_k98",
										"weapon_thompson",
										"weapon_mp40",
										"weapon_bar",
										"weapon_mp44",
										"weapon_spring",
										"weapon_k98s",
										"weapon_30cal",
										"weapon_mg42",
										"weapon_bazooka",
										"weapon_pschreck",
										"weapon_riflegren_us",
										"weapon_riflegren_ger",
										"weapon_frag_us",
										"weapon_frag_ger",
										"weapon_smoke_us",
										"weapon_smoke_ger"
										};
 
static const g_ammoOffset[24] = {	0,	// weapon_amerknife
									0,	// weapon_spade
									4,	// weapon_colt
									8,	// weapon_p38
									24,	// weapon_m1carb
									12,	// weapon_c96
									16,	// weapon_garand
									20,	// weapon_k98
									32,	// weapon_thompson
									32,	// weapon_mp40
									36,	// weapon_bar
									32,	// weapon_mp44
									28,	// weapon_spring
									20,	// weapon_k98s
									40,	// weapon_30cal
									44,	// weapon_mg42
									48,	// weapon_bazooka
									48,	// weapon_pschreck
									84,	// weapon_riflegren_us
									88,	// weapon_riflegren_ger
									52,	// weapon_frag_us
									56,	// weapon_frag_ger
									68,	// weapon_smoke_us
									72	// weapon_smoke_ger
									};

new Handle:sdk_removeAllItems;

new Handle:g_Cvar_rifleClearUS = INVALID_HANDLE;
new Handle:g_Cvar_rifleEquipUS = INVALID_HANDLE;
new Handle:g_Cvar_rifleAmmoUS = INVALID_HANDLE;
new Handle:g_Cvar_rifleClearGer = INVALID_HANDLE;
new Handle:g_Cvar_rifleEquipGer = INVALID_HANDLE;
new Handle:g_Cvar_rifleAmmoGer = INVALID_HANDLE;

new Handle:g_Cvar_assaultClearUS = INVALID_HANDLE;
new Handle:g_Cvar_assaultEquipUS = INVALID_HANDLE;
new Handle:g_Cvar_assaultAmmoUS = INVALID_HANDLE;
new Handle:g_Cvar_assaultClearGer = INVALID_HANDLE;
new Handle:g_Cvar_assaultEquipGer = INVALID_HANDLE;
new Handle:g_Cvar_assaultAmmoGer = INVALID_HANDLE;

new Handle:g_Cvar_sniperClearUS = INVALID_HANDLE;
new Handle:g_Cvar_sniperEquipUS = INVALID_HANDLE;
new Handle:g_Cvar_sniperAmmoUS = INVALID_HANDLE;
new Handle:g_Cvar_sniperClearGer = INVALID_HANDLE;
new Handle:g_Cvar_sniperEquipGer = INVALID_HANDLE;
new Handle:g_Cvar_sniperAmmoGer = INVALID_HANDLE;

new Handle:g_Cvar_supportClearUS = INVALID_HANDLE;
new Handle:g_Cvar_supportEquipUS = INVALID_HANDLE;
new Handle:g_Cvar_supportAmmoUS = INVALID_HANDLE;
new Handle:g_Cvar_supportClearGer = INVALID_HANDLE;
new Handle:g_Cvar_supportEquipGer = INVALID_HANDLE;
new Handle:g_Cvar_supportAmmoGer = INVALID_HANDLE;

new Handle:g_Cvar_mgClearUS = INVALID_HANDLE;
new Handle:g_Cvar_mgEquipUS = INVALID_HANDLE;
new Handle:g_Cvar_mgAmmoUS = INVALID_HANDLE;
new Handle:g_Cvar_mgClearGer = INVALID_HANDLE;
new Handle:g_Cvar_mgEquipGer = INVALID_HANDLE;
new Handle:g_Cvar_mgAmmoGer = INVALID_HANDLE;

new Handle:g_Cvar_rocketClearUS = INVALID_HANDLE;
new Handle:g_Cvar_rocketEquipUS = INVALID_HANDLE;
new Handle:g_Cvar_rocketAmmoUS = INVALID_HANDLE;
new Handle:g_Cvar_rocketClearGer = INVALID_HANDLE;
new Handle:g_Cvar_rocketEquipGer = INVALID_HANDLE;
new Handle:g_Cvar_rocketAmmoGer = INVALID_HANDLE;

public Plugin:myinfo = { name = "DoD Equipment",
							author = "Lis",
							description = "Give custom equipment and ammo",
							version = PLUGIN_VERSION,
							url = "http://www.kellerkind.de"
							};

/* This is the main function.
 * We setup every needed convar here.
 */
public OnPluginStart() {
CreateConVar("sm_dod_equipment_version", PLUGIN_VERSION, "DoD Equipment", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

// Rifleman player
g_Cvar_rifleClearGer = CreateConVar("sm_equip_rifle_clear_ger", "", "first remove all ger Rifleman equipment", FCVAR_PLUGIN);
g_Cvar_rifleEquipGer = CreateConVar("sm_equip_rifle_equip_ger", "", "Give ger Rifleman other equipment", FCVAR_PLUGIN);
g_Cvar_rifleAmmoGer = CreateConVar("sm_equip_rifle_ammo_ger", "", "Specify ammo for other ger Rifle equipment", FCVAR_PLUGIN);
g_Cvar_rifleClearUS = CreateConVar("sm_equip_rifle_clear_us", "", "first remove all us Rifleman equipment", FCVAR_PLUGIN);
g_Cvar_rifleEquipUS = CreateConVar("sm_equip_rifle_equip_us", "", "Give us Rifleman other equipment", FCVAR_PLUGIN);
g_Cvar_rifleAmmoUS = CreateConVar("sm_equip_rifle_ammo_us", "", "Specify ammo for other us Rifle equipment", FCVAR_PLUGIN);

// Assault player
g_Cvar_assaultClearGer = CreateConVar("sm_equip_assault_clear_ger", "", "first remove all ger Assault equipment", FCVAR_PLUGIN);
g_Cvar_assaultEquipGer = CreateConVar("sm_equip_assault_equip_ger", "", "Give ger Assault other equipment", FCVAR_PLUGIN);
g_Cvar_assaultAmmoGer = CreateConVar("sm_equip_assault_ammo_ger", "", "Specify ammo for other ger Assault equipment", FCVAR_PLUGIN);
g_Cvar_assaultClearUS = CreateConVar("sm_equip_assault_clear_us", "", "first remove all us Assault equipment", FCVAR_PLUGIN);
g_Cvar_assaultEquipUS = CreateConVar("sm_equip_assault_equip_us", "", "Give us Assault other equipment", FCVAR_PLUGIN);
g_Cvar_assaultAmmoUS = CreateConVar("sm_equip_assault_ammo_us", "", "Specify ammo for other us Assault equipment", FCVAR_PLUGIN);

// Support player
g_Cvar_supportClearGer = CreateConVar("sm_equip_support_clear_ger", "", "first remove all ger Support equipment", FCVAR_PLUGIN);
g_Cvar_supportEquipGer = CreateConVar("sm_equip_support_equip_ger", "", "Give ger Support other equipment", FCVAR_PLUGIN);
g_Cvar_supportAmmoGer = CreateConVar("sm_equip_support_ammo_ger", "", "Specify ammo for other ger Support equipment", FCVAR_PLUGIN);
g_Cvar_supportClearUS = CreateConVar("sm_equip_support_clear_us", "", "first remove all us Support equipment", FCVAR_PLUGIN);
g_Cvar_supportEquipUS = CreateConVar("sm_equip_support_equip_us", "", "Give us Support other equipment", FCVAR_PLUGIN);
g_Cvar_supportAmmoUS = CreateConVar("sm_equip_support_ammo_us", "", "Specify ammo for other us Support equipment", FCVAR_PLUGIN);

// Sniper player
g_Cvar_sniperClearGer = CreateConVar("sm_equip_sniper_clear_ger", "", "first remove all ger Sniper equipment", FCVAR_PLUGIN);
g_Cvar_sniperEquipGer = CreateConVar("sm_equip_sniper_equip_ger", "", "Give ger Sniper other equipment", FCVAR_PLUGIN);
g_Cvar_sniperAmmoGer = CreateConVar("sm_equip_sniper_ammo_ger", "", "Specify ammo for other ger Sniper equipment", FCVAR_PLUGIN);
g_Cvar_sniperClearUS = CreateConVar("sm_equip_sniper_clear_us", "", "first remove all us Sniper equipment", FCVAR_PLUGIN);
g_Cvar_sniperEquipUS = CreateConVar("sm_equip_sniper_equip_us", "", "Give us Sniper other equipment", FCVAR_PLUGIN);
g_Cvar_sniperAmmoUS = CreateConVar("sm_equip_sniper_ammo_us", "", "Specify ammo for other us Sniper equipment", FCVAR_PLUGIN);

// MG player
g_Cvar_mgClearGer = CreateConVar("sm_equip_mg_clear_ger", "", "first remove all ger Mg equipment", FCVAR_PLUGIN);
g_Cvar_mgEquipGer = CreateConVar("sm_equip_mg_equip_ger", "", "Give ger Mg other equipment", FCVAR_PLUGIN);
g_Cvar_mgAmmoGer = CreateConVar("sm_equip_mg_ammo_ger", "", "Specify ammo for other ger Mg equipment", FCVAR_PLUGIN);
g_Cvar_mgClearUS = CreateConVar("sm_equip_mg_clear_us", "", "first remove all us Mg equipment", FCVAR_PLUGIN);
g_Cvar_mgEquipUS = CreateConVar("sm_equip_mg_equip_us", "", "Give us Mg other equipment", FCVAR_PLUGIN);
g_Cvar_mgAmmoUS = CreateConVar("sm_equip_mg_ammo_us", "", "Specify ammo for other us Mg equipment", FCVAR_PLUGIN);

// Rocket class
g_Cvar_rocketClearGer = CreateConVar("sm_equip_rocket_clear_ger", "", "first remove all ger Rocket equipment", FCVAR_PLUGIN);
g_Cvar_rocketEquipGer = CreateConVar("sm_equip_rocket_equip_ger", "", "Give ger Rocket other equipment", FCVAR_PLUGIN);
g_Cvar_rocketAmmoGer = CreateConVar("sm_equip_rocket_ammo_ger", "", "Specify ammo for other ger Rocket equipment", FCVAR_PLUGIN);
g_Cvar_rocketClearUS = CreateConVar("sm_equip_rocket_clear_us", "", "first remove all us Rocket equipment", FCVAR_PLUGIN);
g_Cvar_rocketEquipUS = CreateConVar("sm_equip_rocket_equip_us", "", "Give us Rocket other equipment", FCVAR_PLUGIN);
g_Cvar_rocketAmmoUS = CreateConVar("sm_equip_rocket_ammo_us", "", "Specify ammo for other us Rocket equipment", FCVAR_PLUGIN);

StartPrepSDKCall(SDKCall_Player);
PrepSDKCall_SetVirtual(299);
PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
sdk_removeAllItems = EndPrepSDKCall();

if(sdk_removeAllItems == INVALID_HANDLE) {
 SetFailState("Hooking RemoveAllItems Failed. Please contact the author.");
}

HookEvent("player_spawn", PlayerSpawnEvent);

AutoExecConfig(true, "dod_equip");
}

/* Things to be done if a player spawns.
 */
public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast) {
 new client = GetClientOfUserId(GetEventInt(event, "userid"))
 // This is a fix. Without this 0.1 timer the client would get nothing.
 CreateTimer(0.1, EquipClientCustom, client, 0)
}

/* This function is called from the spawn event timer.
 * It finds out the players team and class.
 * Then it executes functions who change equipment.
 */
public Action:EquipClientCustom(Handle:timer, any:client) {
new team = GetClientTeam(client);
new ammo_offset = FindSendPropOffs("CDODPlayer", "m_iAmmo");
new class = GetEntProp(client, Prop_Send, "m_iPlayerClass");

new bool:p_removeItems;
new String:p_strEntityAry[ENTITYARRYSIZE][32];
new p_intAmmoAry[AMMOARRYSIZE];
new p_intOffsetAry[AMMOOARRYSIZE];

if (class == 0) {
 //***** Rifleman class *****
 if (team == 2) {
  // US team
  ParseVariables(g_Cvar_rifleClearUS, g_Cvar_rifleEquipUS, g_Cvar_rifleAmmoUS, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_garand weapon_amerknife weapon_riflegren_us", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
 if (team == 3) {
  // GER Team
  ParseVariables(g_Cvar_rifleClearGer, g_Cvar_rifleEquipGer, g_Cvar_rifleAmmoGer, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_k98 weapon_spade weapon_riflegren_ger", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
}
else if(class == 1) {
 //***** Assault class *****
 if (team == 2) {
  // US Team
  ParseVariables(g_Cvar_assaultClearUS, g_Cvar_assaultEquipUS, g_Cvar_assaultAmmoUS, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_thompson weapon_colt weapon_smoke_us weapon_frag_us", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
 if (team == 3) {
  // GER Team
  ParseVariables(g_Cvar_assaultClearGer, g_Cvar_assaultEquipGer, g_Cvar_assaultAmmoGer, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_mp40 weapon_p38 weapon_smoke_ger weapon_frag_ger", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
}
else if(class == 2)	{
 //***** Support class *****
 if (team == 2) {
  // US Team
  ParseVariables(g_Cvar_supportClearUS, g_Cvar_supportEquipUS, g_Cvar_supportAmmoUS, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_bar weapon_amerknife weapon_frag_us", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
 if (team == 3) {
  // GER Team
  ParseVariables(g_Cvar_supportClearGer, g_Cvar_supportEquipGer, g_Cvar_supportAmmoGer, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_mp44 weapon_spade weapon_frag_ger", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
}
else if(class == 3) {
 //***** Sniper class *****
 if (team == 2) {
  // US Team
  ParseVariables(g_Cvar_sniperClearUS, g_Cvar_sniperEquipUS, g_Cvar_sniperAmmoUS, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_spring weapon_colt weapon_amerknife", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
 if (team == 3) {
  // GER Team
  ParseVariables(g_Cvar_sniperClearGer, g_Cvar_sniperEquipGer, g_Cvar_sniperAmmoGer, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_k98s weapon_p38 weapon_spade", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
}
else if(class == 4) {
 //***** MG class *****
 if (team == 2) {
  // US Team
  ParseVariables(g_Cvar_mgClearUS, g_Cvar_mgEquipUS, g_Cvar_mgAmmoUS, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_30cal weapon_colt weapon_amerknife", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
	
 if (team == 3) {
  // GER Team
  ParseVariables(g_Cvar_mgClearGer, g_Cvar_mgEquipGer, g_Cvar_mgAmmoGer, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_mg42 weapon_p38 weapon_spade", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
}
else if(class == 5) {
 //***** Rocket class *****
 if (team == 2) {
  // US Team
  ParseVariables(g_Cvar_rocketClearUS, g_Cvar_rocketEquipUS, g_Cvar_rocketAmmoUS, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_bazooka weapon_m1carb weapon_amerknife", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
 if (team == 3) {
  // GER Team
  ParseVariables(g_Cvar_rocketClearGer, g_Cvar_rocketEquipGer, g_Cvar_rocketAmmoGer, p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
  DoEquipmentChanges(client, ammo_offset, "weapon_pschreck weapon_c96 weapon_spade", p_removeItems, p_strEntityAry, p_intAmmoAry, p_intOffsetAry);
 }
}
else {
 // Handle all other classes if there are any. No need to do something here for now.
}
	
return Plugin_Handled
}

/* This function reads the in the argument specified cvars.
 * Next thing is that the function splits up the cvars into string arrays.
 * The ammo string array is converted to real numbers for the next step.
 * The function finds out the paired entity and ammo offsets with a loop.
 * This function takes only references as argument.
 * Therefore, the overgiven variables are also changed in the calling function.
 */
public ParseVariables(Handle:argClearCvarHandle, Handle:argEntityCvarHandle, Handle:argAmmoCvarHandle, &bool:argBoolClear, String:argStrEntityAry[4][32], argAmmoAry[], argOffsetAry[]) {
new String:strClear[4];
new String:strEquip[512];
new String:strAmmo[128];
new String:strAmmoAry[AMMOARRYSIZE][5];

GetConVarString(argClearCvarHandle, strClear, sizeof(strClear));
argBoolClear = StrEqual(strClear, "yes");

GetConVarString(argEntityCvarHandle, strEquip, sizeof(strEquip));
ExplodeString(strEquip, " ", argStrEntityAry, ENTITYARRYSIZE, 32);
GetConVarString(argAmmoCvarHandle, strAmmo, sizeof(strAmmo));
ExplodeString(strAmmo, " ", strAmmoAry, AMMOARRYSIZE, 5);
for(new a = 0; a < AMMOARRYSIZE; a++) {
 argAmmoAry[a] = StringToInt(strAmmoAry[a]);
}
for(new a = 0; a < ENTITYARRYSIZE; a++) {
 for(new b = 0; b < sizeof(g_weaponEntitys); b++) {
  if(StrEqual(argStrEntityAry[a], g_weaponEntitys[b])) {
   argOffsetAry[a] = g_ammoOffset[b];
  }
 }
}
return 1;
}

/* This function takes the usable arrays as arguments.
 * If the clear flag was set, every item from a player is removed.
 * It then gives the player the items.
 * The function changes every ammo variable according to the
 * entity offsets.
 */
public DoEquipmentChanges(&any:client, &argAmmoOffset, String:argExcludeString[], &bool:argBoolClear, String:argStrEntityAry[4][32], argAmmoAry[], argOffsetAry[]) {
if(argBoolClear) {
 SDKCall(sdk_removeAllItems, client, false);
}

for(new a = 0; a < ENTITYARRYSIZE; a++) {
 if((!StrEqual(argStrEntityAry[a], ""))) {
  if((StrContains(argExcludeString, argStrEntityAry[a], true) == -1) || (argBoolClear)) {
   GivePlayerItem(client, argStrEntityAry[a]);
  }
 }
}
for(new a = 0; a < AMMOARRYSIZE; a++) {
 if(argAmmoAry[a] != 0) {
  SetEntData(client, argAmmoOffset + argOffsetAry[a], argAmmoAry[a], 4, true);
 }
}
return 1;
}
