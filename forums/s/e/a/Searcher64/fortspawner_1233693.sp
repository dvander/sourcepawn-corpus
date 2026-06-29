#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define VERSION "1.0.0.0"
#define DESCRIPTION "FortSpawner spawn item for build Fort"

#define MODEL_MINIGUN	   "models/w_models/weapons/w_minigun.mdl"
#define MODEL_AMMOSTACK	 "models/props/terror/ammo_stack.mdl"
#define MODEL_COFFEEAMMO	"models/props_unique/spawn_apartment/coffeeammo.mdl"
#define MODEL_IRONDOOR	  "models/props_doors/checkpoint_door_01.mdl"
#define MODEL_METALDOOR	  "models/props_doors/doormain01_airport.mdl"
#define MODEL_FREEZEDOOR 		"models/props_doors/doorfreezer01.mdl"

new g_aim_target[MAXPLAYERS];

new Handle:g_cvar_adminonly	 = INVALID_HANDLE;
new Handle:g_cvar_enabled		= INVALID_HANDLE;
new Handle:cvar_maxspawns = INVALID_HANDLE;
new maxspawns;
new Handle:h_array_SpawnEnts[MAXPLAYERS + 1] = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name		= "[L4D2] Build System",
	author	  = "klarg",
	description = DESCRIPTION,
	version	 = VERSION,
	url		 = ""
};
//////////
////  special thank Tommy76 for your code and for your help 
////////////////

public OnPluginStart()
{
	CreateConVar( "bsversion", VERSION, DESCRIPTION, FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	RegConsoleCmd ( "spawnmg", SpawnMinigun, "spawn a minigun", FCVAR_PLUGIN );
	RegConsoleCmd ( "spawnammo", SpawnAmmoStack, "spawn an ammo stack", FCVAR_PLUGIN );
	RegConsoleCmd ( "spawndoor", SpawnIronDoor, "spawn a reinforced iron door", FCVAR_PLUGIN );
	RegConsoleCmd ( "spawndoor2", SpawnMetalDoor, "spawn a reinforced metal door", FCVAR_PLUGIN );
	RegConsoleCmd ( "spawndoor3", SpawnFreezerDoor, "spawn a reinforced freezer door", FCVAR_PLUGIN );
	RegConsoleCmd ( "spawnmed", SpawnMedKit, "spawn a medkit", FCVAR_PLUGIN );
	RegConsoleCmd ( "spawnpills", SpawnPills, "spawn a medkit", FCVAR_PLUGIN );
	RegConsoleCmd ( "spawnmolo", SpawnMolotov, "spawn a molotov", FCVAR_PLUGIN );
	RegConsoleCmd ( "rotate", RotateEntity, "rotate an entity", FCVAR_PLUGIN );
	RegConsoleCmd ( "remove", RemoveEntity, "remove an entity, won't remove player by accident", FCVAR_PLUGIN );
	RegConsoleCmd ( "build", BuildMenu, "Spawn Menu", FCVAR_PLUGIN );
	RegConsoleCmd ( "spawnitem", SpawnItem, "spawn a prop_dynamic or prop_physics entity", FCVAR_PLUGIN );
	RegConsoleCmd ( "listspawns", SpawnList, "List your spawns", FCVAR_PLUGIN );
	RegConsoleCmd ( "removeall", DeleteMySpawns, "Remove all your spawned items", FCVAR_PLUGIN );
	RegConsoleCmd ( "removelast", RemoveLastSpawn, "Remove your last spawn", FCVAR_PLUGIN );
	RegConsoleCmd ( "removefirst", RemoveFirstSpawn, "Remove your first spawn", FCVAR_PLUGIN );
	
	RegConsoleCmd ("+grab", Command_catch, "grab start");
	RegConsoleCmd ("-grab", Command_release, "grab stop");
	
	cvar_maxspawns = CreateConVar("maxspawns", "30", "max model spawns", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DEMO );
	g_cvar_enabled   = CreateConVar( "spawnenable", "1", "0: disable  Build System MOD, 1: enable MOD", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DEMO );
	g_cvar_adminonly  = CreateConVar("spawnadmin", "1", "0: every client can build, 1: only admin can build", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DEMO );

	for(new i=1;i<=MAXPLAYERS;i++) {
		h_array_SpawnEnts[i] = CreateArray();
	}


	HookEvent("round_end", Event_RoundEnd);
	HookConVarChange(cvar_maxspawns,convar_ChangeMax);
	
	AutoExecConfig(true, "FortSpawner");
	
}


public OnMapStart()
{
 	maxspawns = GetConVarInt(cvar_maxspawns);   
	SetRandomSeed( RoundFloat( GetEngineTime() ) );
	//clear client spawns, need's that don't use Fake data
	for(new i = 1; i <= MAXPLAYERS; i++) {
		ClearArray(h_array_SpawnEnts[i]);
	}
}


public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//clear client spawns
	for(new i = 1; i <= MAXPLAYERS; i++) {
		ClearArray(h_array_SpawnEnts[i]);
	}
	return Plugin_Continue;
}
public OnClientDisconnect(client){
	ClearArray(h_array_SpawnEnts[client]);
}
public convar_ChangeMax(Handle:convar, const String:oldVal[], const String:newVal[]) {
	maxspawns =  GetConVarInt(cvar_maxspawns);
}
public Action:SpawnList(client,args){
	new String:modelname[128];
	new String:edictname[128];
	new ent;
	new size = GetArraySize(h_array_SpawnEnts[client]);
	if(size == 0)
	{
		PrintToChat(client,"[Build System] You have 0 spawned objects");
		return Plugin_Handled;
	}
	for(new i=0;i<size;i++)
	{
		ent = GetArrayCell(h_array_SpawnEnts[client], i);

		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
		GetEdictClassname(ent, edictname, 128);
		PrintToChat(client, "[Build System] %i. Ent:%i Model:%s Class:%s", i+1, ent, modelname, edictname);
	}
	return Plugin_Handled;
}
public Action:DeleteMySpawns(client,args){
	while(GetArraySize(h_array_SpawnEnts[client]))
	{
		if(IsValidEntity(GetArrayCell(h_array_SpawnEnts[client], 0)))
			RemoveEdict(GetArrayCell(h_array_SpawnEnts[client], 0));
	
		RemoveFromArray(h_array_SpawnEnts[client], 0);
	}
	
	PrintToChat(client,"[Build System] Removed all your objects. You now have %i spawned objects.", GetArraySize(h_array_SpawnEnts[client]));
	return Plugin_Handled;
}

public Action:RemoveFirstSpawn(client,args)
{
	if(GetArraySize(h_array_SpawnEnts[client]) > 0)
	{
		new ent = GetArrayCell(h_array_SpawnEnts[client], 0 );
		if(IsValidEntity(ent))
		{
			RemoveEdict(ent);
			new String:modelname[128];
			new String:edictname[128];
			GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
			GetEdictClassname(ent, edictname, 128);
			PrintToChat(client, "[Build System] Removed: Ent:%i Model:%s Class:%s", ent,modelname, edictname);
		}
		
		RemoveFromArray(h_array_SpawnEnts[client], 0);
		
	}
}
public Action:RemoveLastSpawn(client,args)
{
	if(GetArraySize(h_array_SpawnEnts[client]) > 0)
	{
		new ent = GetArrayCell(h_array_SpawnEnts[client], GetArraySize(h_array_SpawnEnts[client]) - 1 );
		if(IsValidEntity(ent))
		{
			RemoveEdict(ent);
			new String:modelname[128];
			new String:edictname[128];
			GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
			GetEdictClassname(ent, edictname, 128);
			PrintToChat(client, "[Build System] Removed: Ent:%i Model:%s Class:%s", ent,modelname, edictname);
		}
		RemoveFromArray(h_array_SpawnEnts[client], GetArraySize(h_array_SpawnEnts[client]) - 1 );
	}
}




////////////////////////////////////////////////////////////////////////////////
//
// registered commands
//
////////////////////////////////////////////////////////////////////////////////


//////////
//////Menu
///// Thx tommy76
//////////////////////////////////////////////////////////////////////////////
public Action:BuildMenu(client,args)
{
	if ( !IsAccessGranted( client ) ){
		return Plugin_Handled;
	}
	DisplayMainBuildMenu(client);	
	return Plugin_Handled;
}

///////////////////////////////////////////////////Main Menu//////////////////////
DisplayMainBuildMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_MainBuildMenu);
	
	decl String:title[100];
	Format(title, sizeof(title), "Build System Menu", client);
	SetMenuTitle(menu, title);
	//SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "0", "Control Panel");
	AddMenuItem(menu, "1", "Cheats");
	AddMenuItem(menu, "2", "Useful Objects");
	AddMenuItem(menu, "3", "House Building Objects");
	AddMenuItem(menu, "4", "TEST MENU");
	AddMenuItem(menu, "5", "Vehicles");
	AddMenuItem(menu, "6", "Indoor Objects");
	AddMenuItem(menu, "7", "Outdoor Objects");
	AddMenuItem(menu, "8", "Stairs/Steps");
	AddMenuItem(menu, "9", "Other");

	
	DisplayMenu(menu, client, 60);
}

public MenuHandler_MainBuildMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		
	}
	else if (action == MenuAction_Select){
		switch (param2){
			case 0:{
				DisplayControlMenu(param1);
			}
			case 1:{
				DisplayCheatsMenu(param1);
			}
			case 2:{
				DisplayUsefulObjectsMenu(param1);
			}
			case 3:{
				DisplayHouseMenu(param1);
			}
			case 4:{
				DisplayFortMenu(param1);
			}
			case 5:{
				DisplayVehicleMenu(param1);
			}
			case 6:{
				DisplayIndoorMenu(param1);
			}
			case 7:{
				DisplayOutdoorMenu(param1);
			}
			case 8:{
				DisplayStairsMenu(param1);
			}
			case 9:{
				DisplayOtherMenu(param1);
			}
		
		}
	}
	
}
////////////////////////////////////////Control Menu//////////////////////////////


DisplayControlMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_ControlMenu);
	SetMenuTitle(menu, "Controls");
	AddMenuItem(menu, "sm_cvar spawnadmin 0" , "Build System - Enable for non-admins also");
	AddMenuItem(menu, "sm_cvar spawnadmin 1", "Build System - Admin Only");
	AddMenuItem(menu, "sm_cvar spawnenable 0", "Disable Build System");
	AddMenuItem(menu, "sm_cvar sv_cheats 0", "Disable Cheats");
	AddMenuItem(menu, "sm_cvar sv_cheats 1", "Enable Cheats");
	AddMenuItem(menu, "remove", "Remove object aiming at");
	AddMenuItem(menu, "listspawns", "List Your Spawns");
	AddMenuItem(menu, "removeall", "Remove all your spawned items");
	AddMenuItem(menu, "removelast", "Remove your last spawn");
	AddMenuItem(menu, "removefirst", "Remove your first spawn");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_ControlMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, info);
		DisplayControlMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
////////////////////////////////////////Cheats Menu//////////////////////////////


DisplayCheatsMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_CheatsMenu);
	SetMenuTitle(menu, "Cheats");
	AddMenuItem(menu, "noclip" , "Toggle Flying (noclip)");
	AddMenuItem(menu, "give health", "Give full health/up from incapacitate");
	AddMenuItem(menu, "respawn", "Respawn");
	AddMenuItem(menu, "give first_aid_kit", "Give me a Medical Kit");
	AddMenuItem(menu, "give defibrillator", "Give me a defribrillator");
	AddMenuItem(menu, "give pain_pills", "Give me pills");
	AddMenuItem(menu, "give adrenaline", "Give me adrenaline");
	AddMenuItem(menu, "give upgradepack_incendiary", "Give me fire ammo pack");
	AddMenuItem(menu, "give upgradepack_explosive", "Give me explosive ammo pack");
	AddMenuItem(menu, "give molotov", "Give me a molotov");
	AddMenuItem(menu, "give pipe_bomb", "Give me a pipe bomb");
	AddMenuItem(menu, "give vomitjar", "Give me a boomer bile jar");
	AddMenuItem(menu, "give autoshotgun", "Give me an autoshotgun");
	AddMenuItem(menu, "give shotgun_spas", "Give me a SPAS autoshotgun");
	AddMenuItem(menu, "give rifle", "Give me a rifle");
	AddMenuItem(menu, "give smg", "Give me a SMG");
	AddMenuItem(menu, "give rifle_m60", "Give me a M60");
	AddMenuItem(menu, "give rifle_sg552", "Give me a SG552");
	AddMenuItem(menu, "give rifle_desert", "Give me a desert rifle");
	AddMenuItem(menu, "give smg_mp5", "Give me a MP5 SMG");
	AddMenuItem(menu, "give sniper_military", "Give me a sniper rifle");
	AddMenuItem(menu, "give sniper_awp", "Give me an sniper awp");
	AddMenuItem(menu, "give sniper_scout", "Give me a sniper scout");
	AddMenuItem(menu, "give sniper_military", "Give me a military sniper");
	AddMenuItem(menu, "give pistol_magnum", "Give me a desert eagle[deagle]");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_CheatsMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, info);
		DisplayCheatsMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}

////////////////////////////////////Most Used Menu///////////////////////////////////////
DisplayUsefulObjectsMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_UsefulObjectsMenu);
	SetMenuTitle(menu, "Useful Objects");
	AddMenuItem(menu, "spawnmg", "Mounted Machine Gun");
	AddMenuItem(menu, "spawnmed", "Medical Kit");
	AddMenuItem(menu, "spawnpills", "Pain Pills");
	AddMenuItem(menu, "spawndoor", "Safe Room Door");
	AddMenuItem(menu, "spawndoor2", "Wooden Door");
	AddMenuItem(menu, "spawndoor3", "Freezer Door");
	AddMenuItem(menu, "spawnammo", "Ammo Stack");
	AddMenuItem(menu, "spawnitem p a models/props_unique/wooden_barricade_gascans.mdl", "Gascan Group");
	AddMenuItem(menu, "spawnitem d a models/props_unique/airport/temp_barricade.mdl", "Metal Barrier");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/barricade001_128_reference.mdl", "Barricade Long");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/barricade001_64_reference.mdl", "Barricade Short");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/barricade_gate001_64_reference.mdl", "Barricade Short-No support");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/barricade_razorwire001_128_reference.mdl", "Barbed Wire");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/concrete_barrier001_128_reference.mdl", "[Short] Concrete Barrier");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/concrete_barrier001_96_reference.mdl", "[Long] Concrete Barrier");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/concrete_block001_128_reference.mdl", "Block Concrete");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/police_barrier001_128_reference.mdl", "Police Barrier");
	AddMenuItem(menu, "spawnitem p a models/props_junk/wood_crate001a.mdl", "Wooden Crate");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_UsefulObjectsMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, info);
		DisplayUsefulObjectsMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
////////////////////////////////////////House Building Objects////////////////////////
DisplayHouseMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_HouseMenu);
	SetMenuTitle(menu, "House Building Objects");

	AddMenuItem(menu, "spawnitem d a models/props_urban/gate_wall001_256.mdl", "Hotel Concrete Wall");
	AddMenuItem(menu, "spawnitem d a models/props_urban/hotel_railing001.mdl", "Small fence");
	AddMenuItem(menu, "spawnitem d a models/props_urban/fence_cover001_128.mdl", "Thin Wall");
	AddMenuItem(menu, "spawnitem d a models/props_urban/fence_gate002_256.mdl", "Wired Fence");
	AddMenuItem(menu, "spawnitem d a models/props_cemetery/cemetery_column.mdl", "[Tall] Concrete Pillar");
	AddMenuItem(menu, "spawnitem d a models/props_windows/brick_window03_pillar.mdl", "House Column 2");
	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/track_column_01.mdl", "Round Column");
	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/walkway_structure.mdl", "Doorway Arch");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/guard_tower.mdl", "Guard Tower Platform");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/housefence_door.mdl", "Wooden House Fence");
	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/entrance_structure.mdl", "[HUGE] Entrance Structure");
	AddMenuItem(menu, "spawnitem d a models/props_misc/triage_tent.mdl", "[Big] Tent");
	AddMenuItem(menu, "spawnitem d a models/props_swamp/plank001a_192.mdl", "[Supported] Plank A");
	AddMenuItem(menu, "spawnitem d a models/props_swamp/plank001b_192.mdl", "[No Support] Plank B");
	AddMenuItem(menu, "spawnitem d a models/props_swamp/boardwalk_tall_128.mdl", "[Tall] Board Walk");
	AddMenuItem(menu, "spawnitem p a models/props_junk/wood_pallet001a.mdl", "Wooden Board");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_HouseMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		FakeClientCommand(param1, info);
		
		
		DisplayHouseMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
//////////////////////////////////////// Fortifications ////////////////////////
DisplayFortMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_FortMenu);
	SetMenuTitle(menu, "Fortifications");

	AddMenuItem(menu, "spawnitem d a models/props_fortifications/barricade_gate001_64_reference.mdl", "Barricade Gate");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/concrete_wall001_96_reference.mdl", "Concrete Wall");
	
	
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_FortMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		FakeClientCommand(param1, info);
		
		
		DisplayFortMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
///////////////////////////////////////////////////Vehicles////////////////////////////
DisplayVehicleMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_VehicleMenu);
	SetMenuTitle(menu, "Vehicles");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/racecar.mdl", "Jimmy's Car");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/racecar_damaged.mdl", "Damaged Jimmy's Car");
	AddMenuItem(menu, "spawnitem d a models/props_downtown/parade_float.mdl", "Carnival Parade Car");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/tractor01.mdl", "Tractor");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/ceda_trailer_closed.mdl", "CEDA Trailer");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/helicopter_rescue.mdl", "Rescue Helicopter");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/train_box_open.mdl", "Open train box");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/taxi_rural.mdl", "Taxi rural");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/semi_trailer_freestanding.mdl", "Trailer");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/radio_generator.mdl", "Scavenge generator");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/pickup_truck_78.mdl", "Pickup Truck");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/hmmwv_supply.mdl", "Military Supply Truck");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/bus01_2.mdl", "Bus");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/ambulance.mdl", "Ambulance(L4D1)");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/police_car_rural.mdl", "Police car");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_VehicleMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		FakeClientCommand(param1, info);
		
		DisplayVehicleMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}

///////////////////////////////////////////////////////////Indoor///////////////////////
DisplayIndoorMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_IndoorMenu);
	SetMenuTitle(menu, "Indoor Objects");
	
	AddMenuItem(menu, "spawnitem d a models/props_doors/doorfreezer01.mdl", "[NoBreak]Freezer Door");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/couch.mdl", "Couch");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/sofa.mdl", "Sofa");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/sofa_chair.mdl", "Sofa Armchair");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/sofa01.mdl", "Sofa 1");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/sofa_chair01.mdl", "Sofa 1 Armchair");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/sofa02.mdl", "Sofa 2");
	AddMenuItem(menu, "spawnitem d a models/props_trailers/trailer_couch.mdl", "Combined Couches");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/boothfastfood01.mdl", "C-Shaped Couch");
	AddMenuItem(menu, "spawnitem d a models/props_windows/window_industrial.mdl", "Window");
	AddMenuItem(menu, "spawnitem d a models/props_equipment/securitycheckpoint.mdl", "Metal Detector");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/bed.mdl", "Bed");
	AddMenuItem(menu, "spawnitem d a models/props_equipment/sleeping_bag1.mdl", "Sleeping Bag");
	AddMenuItem(menu, "spawnitem d a models/props_c17/furnituredresser001a.mdl", "Dresser");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/dresser_short.mdl", "Short Dresser");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/shelves_wood.mdl", "Wooden Shelves");
	AddMenuItem(menu, "spawnitem d a models/props/cs_office/bookshelf2.mdl", "Book Shelf");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/bookcasehutch01.mdl", "Book Case Hutch");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/books01.mdl", "Books");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/books02.mdl", "Books 2");
	AddMenuItem(menu, "spawnitem d a models/props_furniture/cafe_cabinet1.mdl", "[Big] Cafe Cabinet");
	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/garbage_pizza_box.mdl", "Garbage Pizza Box");
	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/garbage_popcorn_tub.mdl", "Empty Popcorn Tub");
	AddMenuItem(menu, "spawnitem d a models/props_c17/metalladder001.mdl", "Metal Ladder");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/ladderwood.mdl", "Wooden Ladder");
	AddMenuItem(menu, "spawnitem d a models/props/cs_office/vending_machine.mdl", "Soda Machine");
	AddMenuItem(menu, "spawnitem d a models/props_equipment/snack_machine.mdl", "Snack Machine");
	AddMenuItem(menu, "spawnitem d a models/props_street/garbage_can.mdl", "Garbage Can");
	AddMenuItem(menu, "spawnitem d a models/props_street/trashbin01.mdl", "Garbage Bin");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/television_console01.mdl", "[Big] Television");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/tv.mdl", "Television");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/dvd_player.mdl", "[Small] DVD Player");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/bar01.mdl", "Bar Corner Table");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/barstool01.mdl", "Wooden Bar Stool");
	AddMenuItem(menu, "spawnitem d a models/props_furniture/cafe_barstool1.mdl", "Velvet Bar Stool");
	AddMenuItem(menu, "spawnitem d a models/props_c17/chair_stool01a.mdl", "Metal Bar Stool");
	AddMenuItem(menu, "spawnitem p a models/props/cs_militia/caseofbeer01.mdl", "Beer Box");
	AddMenuItem(menu, "spawnitem d a models/props_furniture/kitchen_countertop1.mdl", "Counter Top");
	AddMenuItem(menu, "spawnitem d a models/props_furniture/cupboard1.mdl", "[Small] Cupboard");
	AddMenuItem(menu, "spawnitem d a models/props/terror/hamradio.mdl", "Radio");
	AddMenuItem(menu, "spawnitem d a models/props_misc/german_radio.mdl", "German Radio");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/magazine_rack.mdl", "Magazine Rack");
	AddMenuItem(menu, "spawnitem d a models/props_furniture/bathtub1.mdl", "Bath Tub");
	AddMenuItem(menu, "spawnitem d a models/props_c17/furnituresink001a.mdl", "Sink");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/toilet.mdl", "Toilet");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/refrigerator03.mdl", "Refrigerator");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/coffee_maker.mdl", "Coffee Maker");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/medicalcabinet02.mdl", "Medical Cabinet");
	AddMenuItem(menu, "spawnitem d a models/props_unique/guncabinet01_main.mdl", "[Empty]Gun Cabinet");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/newspaperstack01.mdl", "Newspaper Stack");
	AddMenuItem(menu, "spawnitem d a models/props_junk/trashcluster01b.mdl", "Trash");
	AddMenuItem(menu, "spawnitem d a models/props_junk\food_pile01.mdl", "Scattered Food Pile");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/shelves_wood.mdl", "Wooden Shelves");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/stove01.mdl", "Dirty Stove");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/stove03_industrial.mdl", "Industrial Stove");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/stove04_industrial.mdl", "Industrial Stove 2");
	AddMenuItem(menu, "spawnitem d a models/props_c17/furniturefireplace001a.mdl", "Metal Fireplace");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/wood_bench.mdl", "Wooden Bench");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/wood_table.mdl", "Wooden Table");
	AddMenuItem(menu, "spawnitem d a models/props_c17/furnituretable001a.mdl", "Round Table");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/coffee_table_oval.mdl", "Oval Coffee Table");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/coffee_table_rectangular.mdl", "Rectangle Coffee Table");
	AddMenuItem(menu, "spawnitem d a models/props_c17/furniturechair001a.mdl", "Wooden Chair");
	AddMenuItem(menu, "spawnitem d a models/props_furniture/hotel_chair.mdl", "Velvet Hotel Chair");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/dryer.mdl", "Dryer Machine");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/desk_executive.mdl", "Fancy Desk");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/desk_metal.mdl", "Metal Desk");
	AddMenuItem(menu, "spawnitem d a models/props_office/desk_01.mdl", "Office Metal Desk");
	AddMenuItem(menu, "spawnitem p a models/props_lab/binderblue.mdl", "Blue Binder");
	AddMenuItem(menu, "spawnitem p a models/props_lab/bindergreen.mdl", "Green Binder");
	AddMenuItem(menu, "spawnitem p a models/props_lab/desklamp01.mdl", "Desk Lamp");
	AddMenuItem(menu, "spawnitem p a models/props_interiors/lamp_table02.mdl", "Table Lamp");
	AddMenuItem(menu, "spawnitem p a models/props_furniture/lamp1.mdl", "Lamp");
	AddMenuItem(menu, "spawnitem d a models/props_lab/Chair_office.mdl", "Office Chair");
	AddMenuItem(menu, "spawnitem d a models/props_lab/monitor01a.mdl", "Computer Monitor");
	AddMenuItem(menu, "spawnitem d a models/props_lab/harddrive02.mdl", "Computer Tower");
	AddMenuItem(menu, "spawnitem p a models/props_c17/computer01_keyboard.mdl", "Computer Keyboard");
	AddMenuItem(menu, "spawnitem p a models/props/cs_office/file_cabinet_01.mdl", "File Cabinets");
	AddMenuItem(menu, "spawnitem d a models/props_furniture/desk1.mdl", "Wooden Study Desk");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/microwave01.mdl", "[Big] Microwave");
	AddMenuItem(menu, "spawnitem d a models/props/cs_office/light_ceiling.mdl", "Ceiling Light");
	AddMenuItem(menu, "spawnitem d a models/props/de_nuke/wall_light.mdl", "Wall Lights");
	AddMenuItem(menu, "spawnitem d a models/props_furniture/inn_chandelier1.mdl", "[Small] Inn Chandelier");
	AddMenuItem(menu, "spawnitem d a models/props_equipment/phone_booth_indoor.mdl", "Wall Phone");
	AddMenuItem(menu, "spawnitem d a models/props/de_nuke/clock.mdl", "Clock");
	AddMenuItem(menu, "spawnitem d a models/props_doors/emergency_exit_sign.mdl", "Emergency Exit Sign");
	AddMenuItem(menu, "spawnitem d a models/props_furniture/piano.mdl", "Piano");
	
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_IndoorMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		FakeClientCommand(param1, info);
		
		DisplayIndoorMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
///////////////////////////////////////////////Outdoor////////////////////////////////////////
DisplayOutdoorMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_OutdoorMenu);
	SetMenuTitle(menu, "Outdoor Objects");
	AddMenuItem(menu, "spawnitem d a models/props_junk/dumpster.mdl", "Dumpster");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/silo_01.mdl", "[Big] Silo");
	AddMenuItem(menu, "spawnitem d a models/props_junk/barrel_fire.mdl", "Barrel");
	AddMenuItem(menu, "spawnitem d a models/props/cs_assault/streetlight.mdl", "Small Street Light");
	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/foodcart.mdl", "Food Cart Trailer");
	AddMenuItem(menu, "spawnitem d a models/props_exteriors/guardshack.mdl", "Guard Shack");
	AddMenuItem(menu, "spawnitem d a models/props/cs_militia/mailbox01.mdl", "Mail Box");
	AddMenuItem(menu, "spawnitem d a models/props_unique/rope_bridge.mdl -1", "[Big] Rope Bridge");
	AddMenuItem(menu, "spawnitem d a models/props_industrial/wire_spool_01.mdl", "Wire Spool");
	AddMenuItem(menu, "spawnitem d a models/props_equipment/light_floodlight.mdl", "Flood Light Stand");
	AddMenuItem(menu, "spawnitem d a models/props_equipment/scaffolding.mdl", "Scaffolding");
	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/stadium_bench_customb.mdl", "[Big] Stadium Bench");
	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/entrance_sign.mdl", "Whispering Oaks Entrance Sign");
	AddMenuItem(menu, "spawnitem d a models/props_equipment/gas_pump.mdl", "Gas Pump");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/concrete_post001_48.mdl", "Concrete Post");
	AddMenuItem(menu, "spawnitem d a models/props_unique/atm01.mdl", "ATM Machine");
	AddMenuItem(menu, "spawnitem d a models/props_street/phonepole1_tall.mdl", "Telephone pole");
	AddMenuItem(menu, "spawnitem d a models/props_industrial/oil_pipes.mdl", "[TALL] Pipes");
	AddMenuItem(menu, "spawnitem d a models/props_junk/trashdumpster02.mdl", "[Big] Dumpster");
	AddMenuItem(menu, "spawnitem d a models/props_unique/haybails_farmhouse.mdl", "[HUGE] Haybails");
	AddMenuItem(menu, "spawnitem p a models/props_canal/boat001a.mdl", "Broken Boat");
	SetMenuExitBackButton(menu, true);	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_OutdoorMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		FakeClientCommand(param1, info);
		
		
		DisplayOutdoorMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);	
	}
}
////////////////////////////////////////////////////Stairs//////////////////////////////////
DisplayStairsMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_StairsMenu);
	SetMenuTitle(menu, "Stairs/Steps");
	AddMenuItem(menu, "spawnitem d a models/props_exteriors/wood_stairs_120.mdl", "Wood stair");
	AddMenuItem(menu, "spawnitem d a models/props_exteriors/wood_stairs_120_swamp.mdl", "Swamp stairs");
	AddMenuItem(menu, "spawnitem d a models/props_buildings/barn_steps.mdl 1", "Barn Steps");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/stair_metal_02.mdl", "Metal stairs");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/stair_treads_straight.mdl", "Big Wooden Stairs");
	AddMenuItem(menu, "spawnitem d a models/props_mall/atrium_stairs.mdl", "[HUGE] Atrium Stair");
	AddMenuItem(menu, "spawnitem d a models/props_urban/hotel_stairs001.mdl", "[Long] Hotel Stair");
	AddMenuItem(menu, "spawnitem d a models/props_urban/hotel_stairs002.mdl", "[Short] Hotel Stair");
	AddMenuItem(menu, "spawnitem d a models/props_exteriors/stairs_house_01.mdl", "House Stairs");
	AddMenuItem(menu, "spawnitem d a models/props_urban/fire_escape_wide_upper.mdl 1", "Fire Escape Stairs");
	AddMenuItem(menu, "spawnitem d a models/props_exteriors/wood_stairs_wide_48.mdl", "Wide Wooden Stairs");
	AddMenuItem(menu, "spawnitem d a models/props_trailers/steps01.mdl", "[Long] Steps");
	AddMenuItem(menu, "spawnitem d a models/props_trailers/steps02.mdl", "[Small] Steps");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_StairsMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
	
		FakeClientCommand(param1, info);
		
		DisplayStairsMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
		
	}
}
////////////////////////////////////////////////////Other////////////////////////////////
DisplayOtherMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_OtherMenu);
	SetMenuTitle(menu, "Other");

	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/building_support_32.mdl", "[Small] Support build");
	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/slide.mdl", "[Big] Slide");
	AddMenuItem(menu, "spawnitem d a models/props_fairgrounds/traffic_barrel.mdl", "Traffic Barrel");
	AddMenuItem(menu, "spawnitem d a models/props_fortifications/orange_cone001_reference.mdl", "Traffic Cone");
	AddMenuItem(menu, "spawnitem d a models/props_mall/information_desk.mdl", "[Big] Mall Information");
	AddMenuItem(menu, "spawnitem d a models/props_urban/dumpster001.mdl", "[Big] Empty Dumster");
	AddMenuItem(menu, "spawnitem d a models/props/de_nuke/cinderblock_stack.mdl", "Cinderblocks");
	AddMenuItem(menu, "spawnitem d a models/props_unique/generator_switch_01.mdl", "Generator Switch");
	AddMenuItem(menu, "spawnitem d a models/props_doors/roll-up_door_half.mdl", "Roll-Up Door");
	AddMenuItem(menu, "spawnitem d a models/props_equipment/luggage_x_ray.mdl", "X-Ray Luggage Machine");
	AddMenuItem(menu, "spawnitem d a models/props_street/warehouse_vent_pipe01.mdl", "Pipe");
	AddMenuItem(menu, "spawnitem p a models/props_junk/wood_crate001a_damagedmax.mdl", "[Short] Wooden Box");
	AddMenuItem(menu, "spawnitem p a models/props_junk/wood_crate002a.mdl", "[Long] Wooden Box");
	AddMenuItem(menu, "spawnitem d a models/extras/info_speech.mdl", "Commentary");
	AddMenuItem(menu, "spawnitem d a models/props_unique/generator_short.mdl", "Single Generator");
	AddMenuItem(menu, "spawnitem d a models/props_vehicles/airport_baggage_cart2.mdl", "Airport Baggage");
	AddMenuItem(menu, "spawnitem d a models/props/cs_assault/box_stack1.mdl", "[Tall/Thin] Office Boxes");
	AddMenuItem(menu, "spawnitem d a models/props/cs_assault/box_stack2.mdl", "[Small/Wide] Office Boxes");
	AddMenuItem(menu, "spawnitem d a models/props/de_prodigy/concretebags2.mdl", "Mortar Bags");
	AddMenuItem(menu, "spawnitem d a models/props/de_nuke/crate_extralarge.mdl", "[Tall/Rectangle] Crate");
	AddMenuItem(menu, "spawnitem d a models/props/de_nuke/crate_small.mdl", "[Short/Box] Crate");
	AddMenuItem(menu, "spawnitem d a models/props_interiors/elevator_panel.mdl", "Elevator Panel");	
	AddMenuItem(menu, "spawnitem p i models/props_unique/airport/atlas_break_ball.mdl", "Big Ball");
	AddMenuItem(menu, "", "");
	SetMenuExitBackButton(menu, true);	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_OtherMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
	
		FakeClientCommand(param1, info);
		
		DisplayOtherMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
		
	}
}


public bool:UnderLimit(client){
	if(GetArraySize(h_array_SpawnEnts[client]) >= maxspawns) {
		decl String:name[32];
		GetClientName(client, name, sizeof(name));
		PrintToServer("[Build System] %s hit limit of %i.", name, maxspawns);
		return false;
	}
	else
		return true;
}
AddToLimit(client,ent){
	PushArrayCell(h_array_SpawnEnts[client], ent);
	PrintToChat(client,"[Build System]You now have %i spawned objects. Max:%i", GetArraySize(h_array_SpawnEnts[client]),maxspawns);
}
RemoveFromLimit(client,ent){
	new foundindex;
	for(new i=1;i<=MAXPLAYERS;i++) {
		foundindex = FindValueInArray(h_array_SpawnEnts[i], ent);
		if(foundindex >= 0) {
			RemoveFromArray(h_array_SpawnEnts[i],foundindex);
			decl String:name[32];
			GetClientName(client, name, sizeof(name));
			if(client == i)
				PrintToChat(i,"[Build System]You removed ent:%i. You now have %i spawned objects.", ent, GetArraySize(h_array_SpawnEnts[i]));
			else {
				PrintToChat(i,"[Build System] %s removed ent:%i. You now have %i spawned objects.", ent, GetArraySize(h_array_SpawnEnts[i]));
				PrintToChat(client,"[Build System] That was %s's object (ent:%i). %s's was reduced, but you still have %i spawned objects.", name, ent, name, GetArraySize(h_array_SpawnEnts[client]));
			}
			return;
		}
	}
	PrintToChat(client,"[Build System] Object (ent:%i) removed, but not in any player spawned list. You still have %i spawned objects.", ent, GetArraySize(h_array_SpawnEnts[client]));
	return;
}

//////////////
///// Grab Tool thx Flud
//////////////
public Action:Command_catch(client, args)
{	
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}
	g_aim_target[client] = GetClientAimTarget(client, false);

	if (!IsValidEntity (g_aim_target[client]))
	{
		PrintToChat(client, "[Build System] Not a valid entity.");
		return Plugin_Handled;
	}

	decl String:m_ModelName[255];
	GetEntPropString(g_aim_target[client], Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));

	PrintToChat(client, "[Build System] You catch [%s] [%i]",m_ModelName, g_aim_target[client]);
	SetParent(client, g_aim_target[client]);
	return Plugin_Continue;
}

public Action:Command_release(client, args)
{
	RemoveParent(g_aim_target[client]);
}

RemoveParent(entity)
{
	if(IsValidEntity(entity))
	{
		decl Float:origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
		SetVariantString("");
		AcceptEntityInput(entity, "SetParent", -1, -1, 0);

		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
	}
}

bool:SetParent(client, entity)
{
	if(IsValidEntity(entity) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemoveParent(entity);
		new String:steamid[20];
		GetClientAuthString(client, steamid, sizeof(steamid));
		DispatchKeyValue(client, "targetname", steamid);
		SetVariantString(steamid);
		AcceptEntityInput(entity, "SetParent", -1, -1, 0);
		return true;
	}
	return false;
}

//---------------------------------------------------------
// spawn a minigun
// the field of fire arc is sticked after you spawned it
// so place it well, or delete it and respawn it with a better angle
//---------------------------------------------------------

public Action:SpawnMinigun( client, args )
{
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}
	
	new index = CreateEntity( client, "prop_minigun", "minigun", MODEL_MINIGUN );
	if ( index != -1 )
	{
		decl Float:position[3], Float:angles[3];
		if ( GetClientAimedLocationData( client, position, angles, NULL_VECTOR ) == -1 )
		{
			RemoveEdict( index );
			ReplyToCommand( client, "[Build System] Can't find a location to place, remove entity (%i)", index );
			return Plugin_Handled;
		}
		if(!UnderLimit(client)) {
		PrintToChat(client, "[Build System] You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;	
	}
		angles[0] = 0.0;
		angles[2] = 0.0;
		DispatchKeyValueVector( index, "Origin", position );
		DispatchKeyValueVector( index, "Angles", angles );
		DispatchKeyValueFloat( index, "MaxPitch",  40.00 );
		DispatchKeyValueFloat( index, "MinPitch", -30.00 );
		DispatchKeyValueFloat( index, "MaxYaw",	360.00 );
		DispatchSpawn( index );
	
	
	
	
		DispatchSpawn(index);
	
	
	
	//iLastMinigunIndex = index;
	
		AddToLimit(client,index);
		}

	return Plugin_Handled;
}


////////
///// SPAWN ITEM
//////////
public Action:SpawnItem( client, args )
{
	if ( !IsAccessGranted( client ) )
		return Plugin_Handled;

	if ( args < 3 )
	{
		ReplyToCommand( client, "Usage: fortspawn_spawnitem <d|p> <i|a> \"filename.mdl\" [1|-1]\n	\
									d = dynamic item, p = physics item\n	\
									i = spawn in front of you\n	\
									a = spawn at where you aim\n	\
									1 = place facing toward you\n   \
									-1 = place facing against you" );
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "[Build System] You have exceeded the %i item spawn limit. Delete one of your obects to spawn more.", maxspawns);
		return Plugin_Handled;	
	}
	new String:param[128];
	
	new bool:isPhysics = false;
	GetCmdArg( 1, param, sizeof(param) );
	if ( strcmp( param, "p" ) == 0 )
	{
		isPhysics = true;
	}
	else if ( strcmp( param, "d" ) != 0 )
	{
		ReplyToCommand( client, "unknown parameter: %s", param );
		return Plugin_Handled;
	}
	
	new bool:isInFront = false;
	GetCmdArg( 2, param, sizeof(param) );
	if ( strcmp( param, "i" ) == 0 )
	{
		isInFront = true;
	}
	else if ( strcmp( param, "a" ) != 0 )
	{
		ReplyToCommand( client, "unknown parameter: %s", param );
		return Plugin_Handled;
	}
	new String:modelname[128];
	GetCmdArg( 3, modelname, sizeof(modelname) );
	
	new facing = 0;
	if ( args > 3 )
	{
		GetCmdArg( 4, param, sizeof(param) );
		facing = StringToInt( param );
	}
	new index = -1;
	if ( isPhysics )
		index = CreateEntity( client, "prop_physics_override", "physics item", modelname );
	else
		index = CreateEntity( client, "prop_dynamic_override", "dynamic item", modelname );
	
	if ( index != -1 )
	{
		decl Float:min[3], Float:max[3];
		GetEntPropVector( index, Prop_Send, "m_vecMins", min );
		GetEntPropVector( index, Prop_Send, "m_vecMaxs", max );
		
		decl Float:position[3], Float:ang_eye[3], Float:ang_ent[3], Float:normal[3];
		if ( isInFront )
		{
			new Float:distance = 50.0;
			if ( facing == 0 )
				distance += SquareRoot( (max[0] - min[0]) * (max[0] - min[0]) + (max[1] - min[1]) * (max[1] - min[1]) ) * 0.5;
			else if ( facing > 0 )
				distance += max[0];
			else
				distance -= min[0];
			
			GetClientFrontLocationData( client, position, ang_eye, distance );
			normal[0] = 0.0;
			normal[1] = 0.0;
			normal[2] = 1.0;
		}
		else
		{
			if ( GetClientAimedLocationData( client, position, ang_eye, normal ) == -1 )
			{
				RemoveEdict( index );
				ReplyToCommand( client, "Can't find a location to place, remove entity (%i)", index );
				return Plugin_Handled;
			}
		}
		
		NegateVector( normal );
		GetVectorAngles( normal, ang_ent );
		ang_ent[0] += 90.0;
		
		// the created entity will face a default direction based on ground normal
		
		if ( facing != 0 )
		{
			// here we will rotate the entity to let it face or back to you
			decl Float:cross[3], Float:vec_eye[3], Float:vec_ent[3];
			GetAngleVectors( ang_eye, vec_eye, NULL_VECTOR, NULL_VECTOR );
			GetAngleVectors( ang_ent, vec_ent, NULL_VECTOR, NULL_VECTOR );
			GetVectorCrossProduct( vec_eye, normal, cross );
			new Float:yaw = GetAngleBetweenVectors( vec_ent, cross, normal );
			if ( facing > 0 )
				RotateYaw( ang_ent, yaw - 90.0 );
			else
				RotateYaw( ang_ent, yaw + 90.0 );
		}
		
		// avoid some model burying under ground/in wall
		// don't forget the normal was negated
		position[0] -= normal[0] * min[2];
		position[1] -= normal[1] * min[2];
		position[2] -= normal[2] * min[2];

		if ( !isPhysics )
		{
			//SetEntProp( index, Prop_Data, "m_nSolidType", 6 );
			SetEntProp( index, Prop_Send, "m_nSolidType", 6 );
		}
		else  //prop_physics
		{
			SetEntProp( index, Prop_Data, "m_spawnflags", 256 );
		}
		DispatchKeyValueVector( index, "Origin", position );
		DispatchKeyValueVector( index, "Angles", ang_ent );
		if(isPhysics)
			DispatchKeyValueFloat(index, "massscale", 0.26);
		
		DispatchSpawn( index );
		if ( !isPhysics )
		{
			// we need to make a prop_dynamic entity collide
			// don't know why but the following code work
			AcceptEntityInput( index, "DisableCollision" );
			AcceptEntityInput( index, "EnableCollision" );
			AcceptEntityInput(index, "TurnOn");
		}
		else
		{
			AcceptEntityInput(index, "EnableMotion");
			AcceptEntityInput(index, "Wake");
		}
	}
	if(IsValidEntity(index))
		AddToLimit(client,index);
	else
		PrintToChat(client,"[Build System] ERROR: Invalid Entity - Object unable to spawn.");
	return Plugin_Handled;

}

//---------------------------------------------------------
// spawn an ammo stack
//---------------------------------------------------------
public Action:SpawnAmmoStack( client, args )
{
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "[Build System] You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;
	}
	new index;
	if ( GetRandomInt( 1, 2 ) == 1 )
	{
		index = CreateEntity( client, "weapon_ammo_spawn", "ammo stack", MODEL_AMMOSTACK );
	}
	else
	{
		index = CreateEntity( client, "weapon_ammo_spawn", "ammo stack", MODEL_COFFEEAMMO );
	}

	if ( index != -1 )
	{
		decl Float:position[3], Float:ang_eye[3], Float:ang_ent[3], Float:normal[3];
		if ( GetClientAimedLocationData( client, position, ang_eye, normal ) == -1 )
		{
			RemoveEdict( index );
			ReplyToCommand( client, "[Build System] Can't find a location to place, remove entity (%i)", index );
			return Plugin_Handled;
		}

		NegateVector( normal );
		GetVectorAngles( normal, ang_ent );
		ang_ent[0] += 90.0;
		
		decl Float:cross[3], Float:vec_eye[3], Float:vec_ent[3];
		GetAngleVectors( ang_eye, vec_eye, NULL_VECTOR, NULL_VECTOR );
		GetAngleVectors( ang_ent, vec_ent, NULL_VECTOR, NULL_VECTOR );
		GetVectorCrossProduct( vec_eye, normal, cross );
		new Float:yaw = GetAngleBetweenVectors( vec_ent, cross, normal );
		RotateYaw( ang_ent, yaw + 90.0 );

		DispatchKeyValueVector( index, "Origin", position );
		DispatchKeyValueVector( index, "Angles", ang_ent );
		DispatchSpawn( index );
	}
 	AddToLimit(client,index);
	return Plugin_Handled;
}


//---------------------------------------------------------
// spawn an iron door, which is unbreakable
// the door angle will align to wall(if placed on wall)
// and try to stand on floor and under ceil if now far from them
//---------------------------------------------------------
public Action:SpawnIronDoor( client, args )
{
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "[Build System] You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;	
	}
	new index = CreateEntity( client, "prop_door_rotating", "iron door", MODEL_IRONDOOR );
	if ( index != -1 )
	{
		decl Float:position[3], Float:angles[3], Float:normal[3];
		if ( GetClientAimedLocationData( client, position, angles, normal ) == -1 )
		{
			RemoveEdict( index );
			ReplyToCommand( client, "[Build System] Can't find a location to place, remove entity (%i)", index );
			return Plugin_Handled;
		}
		
		decl Float:min[3], Float:max[3];
		GetEntPropVector( index, Prop_Send, "m_vecMins", min );
		GetEntPropVector( index, Prop_Send, "m_vecMaxs", max );
		
		// try to stand on floor and under ceil if close enough
		decl Float:right[3], Float:pos_new[3], Float:ang_new[3];
		GetVectorVectors( normal, right, NULL_VECTOR );

		new Handle:trace;

		pos_new[0] = position[0] + normal[0] * 30.0;
		pos_new[1] = position[1] + normal[1] * 30.0;
		pos_new[2] = position[2];

		new bool:decided = false;

		ang_new[0] = 90.0;
		ang_new[1] = 0.0;
		ang_new[2] = 0.0;
		trace = TR_TraceRayFilterEx( pos_new, ang_new, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayers );
		if ( TR_DidHit( trace ) )
		{
			decl Float:below[3];
			TR_GetEndPosition( below, trace );
			if ( pos_new[2] + min[2] <= below[2] )
			{
				position[2] = below[2] - min[2];
				decided = true;
			}
		}
		CloseHandle( trace );

		if ( !decided )
		{
			ang_new[0] = 270.0;
			trace = TR_TraceRayFilterEx( pos_new, ang_new, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayers );
			if ( TR_DidHit( trace ) )
			{
				decl Float:above[3];
				TR_GetEndPosition( above, trace );
				if ( pos_new[2] + max[2] >= above[2] )
				{
					position[2] = above[2] - max[2];
				}
			}
			CloseHandle( trace );
		}

		// align angle to wall if placed on wall
		if ( normal[2] < 1.0 && normal[2] > -1.0 )
		{
			GetVectorAngles( right, angles );
		}

		angles[0] = 0.0;
		angles[2] = 0.0;
		position[0] += normal[0] * 2.0;
		position[1] += normal[1] * 2.0;
		DispatchKeyValueVector( index, "Origin", position );
		DispatchKeyValueVector( index, "Angles", angles );
		SetEntProp( index, Prop_Data, "m_spawnflags", 8192 );
		SetEntProp( index, Prop_Data, "m_bForceClosed", 0 );
		SetEntProp( index, Prop_Data, "m_nHardwareType", 1 );
		SetEntPropFloat( index, Prop_Data, "m_flAutoReturnDelay", -1.0 );
		SetEntPropFloat( index, Prop_Data, "m_flSpeed", 200.0 );
		DispatchSpawn( index );
	}
	AddToLimit(client,index);
	return Plugin_Handled;
}

//--------------------------------------------------------
//metal door
//--------------------------------------------------------
public Action:SpawnMetalDoor( client, args )
{
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "[Build System] You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;	
	}
	new index = CreateEntity( client, "prop_door_rotating", "metal door", MODEL_METALDOOR );
	if ( index != -1 )
	{
		decl Float:position[3], Float:angles[3], Float:normal[3];
		if ( GetClientAimedLocationData( client, position, angles, normal ) == -1 )
		{
			RemoveEdict( index );
			ReplyToCommand( client, "[Build System] Can't find a location to place, remove entity (%i)", index );
			return Plugin_Handled;
		}
		
		decl Float:min[3], Float:max[3];
		GetEntPropVector( index, Prop_Send, "m_vecMins", min );
		GetEntPropVector( index, Prop_Send, "m_vecMaxs", max );
		
		// try to stand on floor and under ceil if close enough
		decl Float:right[3], Float:pos_new[3], Float:ang_new[3];
		GetVectorVectors( normal, right, NULL_VECTOR );

		new Handle:trace;

		pos_new[0] = position[0] + normal[0] * 30.0;
		pos_new[1] = position[1] + normal[1] * 30.0;
		pos_new[2] = position[2];

		new bool:decided = false;

		ang_new[0] = 90.0;
		ang_new[1] = 0.0;
		ang_new[2] = 0.0;
		trace = TR_TraceRayFilterEx( pos_new, ang_new, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayers );
		if ( TR_DidHit( trace ) )
		{
			decl Float:below[3];
			TR_GetEndPosition( below, trace );
			if ( pos_new[2] + min[2] <= below[2] )
			{
				position[2] = below[2] - min[2];
				decided = true;
			}
		}
		CloseHandle( trace );

		if ( !decided )
		{
			ang_new[0] = 270.0;
			trace = TR_TraceRayFilterEx( pos_new, ang_new, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayers );
			if ( TR_DidHit( trace ) )
			{
				decl Float:above[3];
				TR_GetEndPosition( above, trace );
				if ( pos_new[2] + max[2] >= above[2] )
				{
					position[2] = above[2] - max[2];
				}
			}
			CloseHandle( trace );
		}

		// align angle to wall if placed on wall
		if ( normal[2] < 1.0 && normal[2] > -1.0 )
		{
			GetVectorAngles( right, angles );
		}

		angles[0] = 0.0;
		angles[2] = 0.0;
		position[0] += normal[0] * 2.0;
		position[1] += normal[1] * 2.0;
		DispatchKeyValueVector( index, "Origin", position );
		DispatchKeyValueVector( index, "Angles", angles );
		SetEntProp( index, Prop_Data, "m_spawnflags", 8192 );
		SetEntProp( index, Prop_Data, "m_bForceClosed", 0 );
		SetEntProp( index, Prop_Data, "m_nHardwareType", 1 );
		SetEntPropFloat( index, Prop_Data, "m_flAutoReturnDelay", -1.0 );
		SetEntPropFloat( index, Prop_Data, "m_flSpeed", 200.0 );
		DispatchSpawn( index );
	}
	AddToLimit(client,index);
	return Plugin_Handled;
}
//---------------------------------------------------------
// spawn an Freezer door, which is unbreakable
// the door angle will align to wall(if placed on wall)
// and try to stand on floor and under ceil if now far from them
//---------------------------------------------------------
public Action:SpawnFreezerDoor( client, args )
{
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "[Build System] You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;	
	}
	new index = CreateEntity( client, "prop_door_rotating", "Freezer door", MODEL_FREEZEDOOR );
	if ( index != -1 )
	{
		decl Float:position[3], Float:angles[3], Float:normal[3];
		if ( GetClientAimedLocationData( client, position, angles, normal ) == -1 )
		{
			RemoveEdict( index );
			ReplyToCommand( client, "[Build System] Can't find a location to place, remove entity (%i)", index );
			return Plugin_Handled;
		}
		
		decl Float:min[3], Float:max[3];
		GetEntPropVector( index, Prop_Send, "m_vecMins", min );
		GetEntPropVector( index, Prop_Send, "m_vecMaxs", max );
		
		// try to stand on floor and under ceil if close enough
		decl Float:right[3], Float:pos_new[3], Float:ang_new[3];
		GetVectorVectors( normal, right, NULL_VECTOR );

		new Handle:trace;

		pos_new[0] = position[0] + normal[0] * 30.0;
		pos_new[1] = position[1] + normal[1] * 30.0;
		pos_new[2] = position[2];

		new bool:decided = false;

		ang_new[0] = 90.0;
		ang_new[1] = 0.0;
		ang_new[2] = 0.0;
		trace = TR_TraceRayFilterEx( pos_new, ang_new, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayers );
		if ( TR_DidHit( trace ) )
		{
			decl Float:below[3];
			TR_GetEndPosition( below, trace );
			if ( pos_new[2] + min[2] <= below[2] )
			{
				position[2] = below[2] - min[2];
				decided = true;
			}
		}
		CloseHandle( trace );

		if ( !decided )
		{
			ang_new[0] = 270.0;
			trace = TR_TraceRayFilterEx( pos_new, ang_new, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayers );
			if ( TR_DidHit( trace ) )
			{
				decl Float:above[3];
				TR_GetEndPosition( above, trace );
				if ( pos_new[2] + max[2] >= above[2] )
				{
					position[2] = above[2] - max[2];
				}
			}
			CloseHandle( trace );
		}

		// align angle to wall if placed on wall
		if ( normal[2] < 1.0 && normal[2] > -1.0 )
		{
			GetVectorAngles( right, angles );
		}

		angles[0] = 0.0;
		angles[2] = 0.0;
		position[0] += normal[0] * 2.0;
		position[1] += normal[1] * 2.0;
		DispatchKeyValueVector( index, "Origin", position );
		DispatchKeyValueVector( index, "Angles", angles );
		SetEntProp( index, Prop_Data, "m_spawnflags", 8192 );
		SetEntProp( index, Prop_Data, "m_bForceClosed", 0 );
		SetEntProp( index, Prop_Data, "m_nHardwareType", 1 );
		SetEntPropFloat( index, Prop_Data, "m_flAutoReturnDelay", -1.0 );
		SetEntPropFloat( index, Prop_Data, "m_flSpeed", 200.0 );
		DispatchSpawn( index );
	}
	AddToLimit(client,index);
	return Plugin_Handled;
}
//--------------------------------------------------------
// spawn medkit
//--------------------------------------------------------
public Action:SpawnMedKit( client, args )
{
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "[Build System] You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;
	}
	new index;
	if ( GetRandomInt( 1, 2 ) == 1 )
	{
		index = CreateEntity( client, "weapon_first_aid_kit", "medical kit", MODEL_AMMOSTACK );
	}
	else
	{
		index = CreateEntity( client, "weapon_first_aid_kit", "medical kit", MODEL_COFFEEAMMO );
	}

	if ( index != -1 )
	{
		decl Float:position[3], Float:ang_eye[3], Float:ang_ent[3], Float:normal[3];
		if ( GetClientAimedLocationData( client, position, ang_eye, normal ) == -1 )
		{
			RemoveEdict( index );
			ReplyToCommand( client, "[Build System] Can't find a location to place, remove entity (%i)", index );
			return Plugin_Handled;
		}
		
		NegateVector( normal );
		GetVectorAngles( normal, ang_ent );
		ang_ent[0] += 90.0;
		
		decl Float:cross[3], Float:vec_eye[3], Float:vec_ent[3];
		GetAngleVectors( ang_eye, vec_eye, NULL_VECTOR, NULL_VECTOR );
		GetAngleVectors( ang_ent, vec_ent, NULL_VECTOR, NULL_VECTOR );
		GetVectorCrossProduct( vec_eye, normal, cross );
		new Float:yaw = GetAngleBetweenVectors( vec_ent, cross, normal );
		RotateYaw( ang_ent, yaw + 90.0 );

		DispatchKeyValueVector( index, "Origin", position );
		DispatchKeyValueVector( index, "Angles", ang_ent );
		DispatchSpawn( index );
	}
 	AddToLimit(client,index);
	return Plugin_Handled;
}

//---------------------------------------------------------
//spawn a molotov
//---------------------------------------------------------
public Action:SpawnMolotov( client, args )
{
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "[Build System] You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;
	}
	new index;
	if ( GetRandomInt( 1, 2 ) == 1 )
	{
		index = CreateEntity( client, "weapon_molotov", "molotov", MODEL_AMMOSTACK );
	}
	else
	{
		index = CreateEntity( client, "weapon_molotov", "molotov", MODEL_COFFEEAMMO );
	}

	if ( index != -1 )
	{
		decl Float:position[3], Float:ang_eye[3], Float:ang_ent[3], Float:normal[3];
		if ( GetClientAimedLocationData( client, position, ang_eye, normal ) == -1 )
		{
			RemoveEdict( index );
			ReplyToCommand( client, "[Build System] Can't find a location to place, remove entity (%i)", index );
			return Plugin_Handled;
		}
		
		NegateVector( normal );
		GetVectorAngles( normal, ang_ent );
		ang_ent[0] += 90.0;
		
		decl Float:cross[3], Float:vec_eye[3], Float:vec_ent[3];
		GetAngleVectors( ang_eye, vec_eye, NULL_VECTOR, NULL_VECTOR );
		GetAngleVectors( ang_ent, vec_ent, NULL_VECTOR, NULL_VECTOR );
		GetVectorCrossProduct( vec_eye, normal, cross );
		new Float:yaw = GetAngleBetweenVectors( vec_ent, cross, normal );
		RotateYaw( ang_ent, yaw + 90.0 );

		DispatchKeyValueVector( index, "Origin", position );
		DispatchKeyValueVector( index, "Angles", ang_ent );
		DispatchSpawn( index );
	}
 	AddToLimit(client,index);
	return Plugin_Handled;
}
//--------------------------------------------------------
// spawn pills
//--------------------------------------------------------
public Action:SpawnPills( client, args )
{
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "[Build System] You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;
	}
	new index;
	if ( GetRandomInt( 1, 2 ) == 1 )
	{
		index = CreateEntity( client, "weapon_pain_pills", "pain pills", MODEL_AMMOSTACK );
	}
	else
	{
		index = CreateEntity( client, "weapon_pain_pills", "pain pills", MODEL_COFFEEAMMO );
	}

	if ( index != -1 )
	{
		decl Float:position[3], Float:ang_eye[3], Float:ang_ent[3], Float:normal[3];
		if ( GetClientAimedLocationData( client, position, ang_eye, normal ) == -1 )
		{
			RemoveEdict( index );
			ReplyToCommand( client, "[Build System] Can't find a location to place, remove entity (%i)", index );
			return Plugin_Handled;
		}
		
		NegateVector( normal );
		GetVectorAngles( normal, ang_ent );
		ang_ent[0] += 90.0;
		
		decl Float:cross[3], Float:vec_eye[3], Float:vec_ent[3];
		GetAngleVectors( ang_eye, vec_eye, NULL_VECTOR, NULL_VECTOR );
		GetAngleVectors( ang_ent, vec_ent, NULL_VECTOR, NULL_VECTOR );
		GetVectorCrossProduct( vec_eye, normal, cross );
		new Float:yaw = GetAngleBetweenVectors( vec_ent, cross, normal );
		RotateYaw( ang_ent, yaw + 90.0 );

		DispatchKeyValueVector( index, "Origin", position );
		DispatchKeyValueVector( index, "Angles", ang_ent );
		DispatchSpawn( index );
	}
 	AddToLimit(client,index);
	return Plugin_Handled;
}

//---------------------------------------------------------
// rotate the aimed entity
// will recognize a minigun and rotate it properly
//---------------------------------------------------------
public Action:RotateEntity( client, args )
{
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}
	
	new player = GetPlayerIndex( client );
	
	if ( player == 0 )
	{
		ReplyToCommand( player, "[Build System] Cannot spawn entity over rcon/server console" );
		return Plugin_Handled;
	}

	new index = GetClientAimedLocationData( client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR );
	if ( index <= 0 )
	{
		ReplyToCommand( player, "[Build System] Nothing picked to rotate" );
		return Plugin_Handled;
	}
	
	new String:param[128];

	new Float:degree;
	if ( args > 0 )
	{
		GetCmdArg( 1, param, sizeof(param) );
		degree = StringToFloat( param );
	}

	GetEdictClassname( index, param, 128 );
	if ( strcmp( param, "prop_minigun" ) == 0 )
	{
		RotateMinigun( player, index, degree );
		return Plugin_Handled;
	}
	
	decl Float:angles[3];
	GetEntPropVector( index, Prop_Data, "m_angRotation", angles );
	RotateYaw( angles, degree );
	
	DispatchKeyValueVector( index, "Angles", angles );

	return Plugin_Handled;
}

//---------------------------------------------------------
// remove the entity you aim at
// anything but player can be removed by this function
//---------------------------------------------------------
public Action:RemoveEntity( client, args )
{
	if ( !IsAccessGranted( client ) )
	{
		return Plugin_Handled;
	}

	new player = GetPlayerIndex( client );
	
	if ( player == 0 )
	{
		ReplyToCommand( player, "[Build System] Cannot spawn entity over rcon/server console" );
		return Plugin_Handled;
	}
	
	new index = -1;
	if ( args > 0 )
	{
		new String:param[128];
		GetCmdArg( 1, param, sizeof(param) );
		index = StringToInt( param );
	}
	else
	{
		index = GetClientAimedLocationData( client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR );
	}
	
	if ( index > MaxClients )
	{
		RemoveEdict( index );

		ReplyToCommand( player, "[Build System] Entity (index %i) removed", index );
		RemoveFromLimit( client, index );
	}
	else if ( index > 0 )
	{
		ReplyToCommand( player, "[Build System] Cannot remove player (index %i)", index );
	}
	else
	{
		ReplyToCommand( player, "[Build System] Nothing picked to remove" );
	}

	return Plugin_Handled;
}




////////////////////////////////////////////////////////////////////////////////
//
// interior functions
//
////////////////////////////////////////////////////////////////////////////////

//---------------------------------------------------------
// spawn a given entity type and assign it a model
//---------------------------------------------------------
CreateEntity( client, const String:entity_name[], const String:item_name[], const String:model[] = "" )
{
	new player = GetPlayerIndex( client );
	
	if ( player == 0 )
	{
		ReplyToCommand( player, "[Build System] Cannot spawn entity over rcon/server console" );
		return -1;
	}

	new index = CreateEntityByName( entity_name );
	if ( index == -1 )
	{
		ReplyToCommand( player, "[Build System] Failed to create %s !", item_name );
		return -1;
	}

	if ( strlen( model ) != 0 )
	{
		if ( !IsModelPrecached( model ) )
		{
			PrecacheModel( model );
		}
		SetEntityModel( index, model );
	}

	ReplyToCommand( player, "[Build System] Successfully created %s (index %i)", item_name, index );

	return index;
}

//---------------------------------------------------------
// do a specific rotation on the given angles
//---------------------------------------------------------
RotateYaw( Float:angles[3], Float:degree )
{
	decl Float:direction[3], Float:normal[3];
	GetAngleVectors( angles, direction, NULL_VECTOR, normal );
	
	new Float:sin = Sine( degree * 0.01745328 );	 // Pi/180
	new Float:cos = Cosine( degree * 0.01745328 );
	new Float:a = normal[0] * sin;
	new Float:b = normal[1] * sin;
	new Float:c = normal[2] * sin;
	new Float:x = direction[2] * b + direction[0] * cos - direction[1] * c;
	new Float:y = direction[0] * c + direction[1] * cos - direction[2] * a;
	new Float:z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;
	
	GetVectorAngles( direction, angles );

	decl Float:up[3];
	GetVectorVectors( direction, NULL_VECTOR, up );

	new Float:roll = GetAngleBetweenVectors( up, normal, direction );
	angles[2] += roll;
}



//---------------------------------------------------------
// specail method to rotate a minigun
// to make sure it still function properly after rotation
//---------------------------------------------------------
RotateMinigun( client, index, Float:degree )
{
	decl Float:origin[3], Float:angles[3];
	GetEntPropVector( index, Prop_Data, "m_vecOrigin", origin );
	GetEntPropVector( index, Prop_Data, "m_angRotation", angles );

	angles[1] += degree;

	// respawn a new one
	new newindex = CreateEntityByName( "prop_minigun" );
	if ( newindex == -1 )
	{
		ReplyToCommand( client, "[Build System] Failed to rotate the minigun!" );
		return;
	}

	// delete current minigun
	RemoveEdict( index );
		
	if ( !IsModelPrecached( MODEL_MINIGUN ) )
	{
		PrecacheModel( MODEL_MINIGUN );
	}
	SetEntityModel( newindex, MODEL_MINIGUN );
	DispatchKeyValueFloat( newindex, "MaxPitch",  40.00 );
	DispatchKeyValueFloat( newindex, "MinPitch", -30.00 );
	DispatchKeyValueFloat( newindex, "MaxYaw",	90.00 );
	DispatchKeyValueVector( newindex, "Angles", angles );
	DispatchKeyValueVector( newindex, "Origin", origin );
	
	DispatchSpawn( newindex );
}

//---------------------------------------------------------
// return 0 if it is a server
//---------------------------------------------------------
GetPlayerIndex( client )
{
	if ( client == 0 && !IsDedicatedServer() )
	{
		return 1;
	}
	
	return client;
}

//---------------------------------------------------------
// check if this MOD can be used by specific client
//---------------------------------------------------------
bool:IsAccessGranted( client )
{
	new bool:granted = true;

	// client = 0 means server, server always got access
	if ( client != 0 && GetConVarInt( g_cvar_adminonly ) > 0 )
	{
		if ( !GetAdminFlag( GetUserAdmin( client ), Admin_Generic, Access_Effective ) )
		{
			ReplyToCommand( client, "[Build System] Only admins can use the Build System at the moment." );
			granted = false;
		}
	}
	
	if ( granted )
	{
		if ( GetConVarInt( g_cvar_enabled ) <= 0 )
		{
			ReplyToCommand( client, "[Build System] Building System has been disabled at the moment." );
			granted = false;
		}
	}
	
	return granted;
}

//---------------------------------------------------------
// the filter function for TR_TraceRayFilterEx
//---------------------------------------------------------
public bool:TraceEntityFilterPlayers( entity, contentsMask, any:data )
{
	return entity > MaxClients && entity != data;
}

//---------------------------------------------------------
// get position, angles and normal of aimed location if the parameters are not NULL_VECTOR
// return the index of entity you aimed
//---------------------------------------------------------
GetClientAimedLocationData( client, Float:position[3], Float:angles[3], Float:normal[3] )
{
	new index = -1;
	
	new player = GetPlayerIndex( client );

	decl Float:_origin[3], Float:_angles[3];
	GetClientEyePosition( player, _origin );
	GetClientEyeAngles( player, _angles );

	new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers );
	if( !TR_DidHit( trace ) )
	{ 
		ReplyToCommand( player, "[Build System] Failed to pick the aimed location" );
		index = -1;
	}
	else
	{
		TR_GetEndPosition( position, trace );
		TR_GetPlaneNormal( trace, normal );
		angles[0] = _angles[0];
		angles[1] = _angles[1];
		angles[2] = _angles[2];

		index = TR_GetEntityIndex( trace );
	}
	CloseHandle( trace );
	
	return index;
}

//---------------------------------------------------------
// get position just in front of you
// and the angles you are facing in horizontal
//---------------------------------------------------------
GetClientFrontLocationData( client, Float:position[3], Float:angles[3], Float:distance = 50.0 )
{
	new player = GetPlayerIndex( client );

	decl Float:_origin[3], Float:_angles[3];
	GetClientAbsOrigin( player, _origin );
	GetClientEyeAngles( player, _angles );

	decl Float:direction[3];
	GetAngleVectors( _angles, direction, NULL_VECTOR, NULL_VECTOR );
	
	position[0] = _origin[0] + direction[0] * distance;
	position[1] = _origin[1] + direction[1] * distance;
	position[2] = _origin[2];
	
	angles[0] = 0.0;
	angles[1] = _angles[1];
	angles[2] = 0.0;
}

//---------------------------------------------------------
// calculate the angle between 2 vectors
// the direction will be used to determine the sign of angle (right hand rule)
// all of the 3 vectors have to be normalized
//---------------------------------------------------------
Float:GetAngleBetweenVectors( const Float:vector1[3], const Float:vector2[3], const Float:direction[3] )
{
	decl Float:vector1_n[3], Float:vector2_n[3], Float:direction_n[3], Float:cross[3];
	NormalizeVector( direction, direction_n );
	NormalizeVector( vector1, vector1_n );
	NormalizeVector( vector2, vector2_n );
	new Float:degree = ArcCosine( GetVectorDotProduct( vector1_n, vector2_n ) ) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct( vector1_n, vector2_n, cross );
	
	if ( GetVectorDotProduct( cross, direction_n ) < 0.0 )
	{
		degree *= -1.0;
	}

	return degree;
}