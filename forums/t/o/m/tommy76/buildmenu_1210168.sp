#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"


new Handle:cvar_adminonly     = INVALID_HANDLE;
new Handle:cvar_enabled        = INVALID_HANDLE;
new Handle:cvar_maxspawns = INVALID_HANDLE;
new maxspawns;

//new String:path_modelstxt[PLATFORM_MAX_PATH];

new Handle:h_array_SpawnEnts[MAXPLAYERS + 1] = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Build Menu",
	author = "tommy",
	description = "Menu for spawning objects.",
	version = PLUGIN_VERSION,
	url = ""
};
public OnPluginStart() {
	CreateConVar("buildmenu_version", PLUGIN_VERSION, "Build Menu Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("buildmenu", BuildMenu);
	RegConsoleCmd("bm", BuildMenu);
	
	RegConsoleCmd( "sm_mountedgun",   SpawnMinigun, "spawn a mounted gun", FCVAR_PLUGIN );
	//RegConsoleCmd( "sm_minigunattach",   SpawnMinigunAttach, "spawn a minigun attached to you (toggles)", FCVAR_PLUGIN );
	RegConsoleCmd( "sm_spawnammostack", SpawnAmmoStack, "spawn an ammo stack", FCVAR_PLUGIN );
	RegConsoleCmd( "sm_spawnirondoor",  SpawnIronDoor, "spawn a reinforced iron door", FCVAR_PLUGIN );
	RegConsoleCmd( "sm_spawnitem",      SpawnItem, "spawn a prop_dynamic or prop_physics entity", FCVAR_PLUGIN );
	RegConsoleCmd( "sm_rotate",         RotateEntity, "rotate an entity", FCVAR_PLUGIN );

	RegConsoleCmd( "listmyspawns",    SpawnList, "List your spawns", FCVAR_PLUGIN );
	RegConsoleCmd( "removeall",  DeleteMySpawns, "Remove all your spawned items", FCVAR_PLUGIN );
	RegConsoleCmd( "removelast",  RemoveLastSpawn, "Remove your last spawn", FCVAR_PLUGIN );
	RegConsoleCmd( "removefirst",  RemoveFirstSpawn, "Remove your first spawn", FCVAR_PLUGIN );
	
	RegConsoleCmd( "sm_spawnitemnorm", SpawnItemNorm, "spawn a prop_dynamic or prop_physics entity", FCVAR_PLUGIN );

	RegConsoleCmd("remove", RemoveObj);
	RegConsoleCmd("rotatecw", RotateClockwise);
	RegConsoleCmd("rotateccw", RotateCounterClock);

	cvar_maxspawns = CreateConVar("buildmenu_maxspawns", "10", "max model spawns", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DEMO );
	cvar_enabled   = CreateConVar( "buildmenu_enabled", "1", "enable or disable the menu", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DEMO );
	cvar_adminonly = CreateConVar( "buildmenu_adminonly", "0", "enable for admins only", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DEMO );

	
	for(new i=1;i<=MAXPLAYERS;i++) {
		h_array_SpawnEnts[i] = CreateArray();
	}

	HookEvent("round_end", Event_RoundEnd);
	HookConVarChange(cvar_maxspawns,convar_ChangeMax);
	
	//BuildPath(Path_SM, path_modelstxt, sizeof(path_modelstxt), "configs/l4d2models.txt");
}
public OnMapStart()
{
	maxspawns = GetConVarInt(cvar_maxspawns);

	SetRandomSeed( RoundFloat( GetEngineTime() ) );

	//clear client spawns
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
public OnClientPostAdminCheck(client) {
	ClearArray(h_array_SpawnEnts[client]);		
	//attachedminigun[client] = 0;
}
public OnClientDisconnect(client){
	ClearArray(h_array_SpawnEnts[client]);
}
public convar_ChangeMax(Handle:convar, const String:oldVal[], const String:newVal[]) {
	maxspawns = StringToInt(newVal);
}
public Action:SpawnList(client,args){
	new String:modelname[128];
	new String:edictname[128];
	new ent;
	new size = GetArraySize(h_array_SpawnEnts[client]);
	if(size == 0)
	{
		PrintToChat(client,"You have 0 spawned objects");
		return Plugin_Handled;
	}
	for(new i=0;i<size;i++)
	{
		ent = GetArrayCell(h_array_SpawnEnts[client], i);

		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, 128);
		GetEdictClassname(ent, edictname, 128);
		PrintToChat(client, "%i. Ent:%i Model:%s Class:%s", i+1, ent, modelname, edictname);
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
	
	PrintToChat(client,"Removed all your objects. You now have %i spawned objects.", GetArraySize(h_array_SpawnEnts[client]));
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
			PrintToChat(client, "Removed: Ent:%i Model:%s Class:%s", ent,modelname, edictname);
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
			PrintToChat(client, "Removed: Ent:%i Model:%s Class:%s", ent,modelname, edictname);
		}
		RemoveFromArray(h_array_SpawnEnts[client], GetArraySize(h_array_SpawnEnts[client]) - 1 );
	}
}
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
	Format(title, sizeof(title), "Build Menu - IN TESTING", client);
	SetMenuTitle(menu, title);
	//SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "0", "Controls");
	AddMenuItem(menu, "1", "Most Used");
	AddMenuItem(menu, "2", "Fences/Barricades");
	AddMenuItem(menu, "3", "Vehicles");
	AddMenuItem(menu, "4", "Indoor Stuff");
	AddMenuItem(menu, "5", "Outdoor Stuff");
	AddMenuItem(menu, "6", "Misc");
	AddMenuItem(menu, "7", "Misc");
	AddMenuItem(menu, "8", "REMOVED - All (3211 Items)(dynamic)");
	AddMenuItem(menu, "9", "REMOVED - Weapons");
	
	DisplayMenu(menu, client, 60);
}

public MenuHandler_MainBuildMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		switch (param2){
			case 0:{
				DisplayControlsMenu(param1);
			}
			case 1:{
				DisplayMostUsedMenu(param1);
			}
			case 2:{
				DisplayFenceMenu(param1);
			}
			case 3:{
				DisplayVehicleMenu(param1);
			}
			case 4: {
				DisplayIndoorMenu(param1);
			}
			case 5:{
				DisplayOutdoorMenu(param1);
			}
			case 6:{
				DisplayStairsMenu(param1);
			}
			case 7:{
				DisplayMiscMenu(param1);
			}
			case 8:{
				//DisplayAllMenu(param1);
			}
			case 9:{
				//DisplayWeaponMenu(param1);
			}
		}
	}
	//else if (action == MenuAction_Cancel)
	//{
	//	DisplayMainBuildMenu(param1);
	//}
}
////////////////////////////////////////Control Menu//////////////////////////////
DisplayControlsMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_ControlsMenu);
	SetMenuTitle(menu, "Controls");
	AddMenuItem(menu, "remove", "Remove object aiming at (!remove)");
	AddMenuItem(menu, "sm_rotate 15", "Rotate object clockwise (!rotatecw)");
	AddMenuItem(menu, "sm_rotate -15", "Rotate object counterclockwise (!rotateccw)");
	AddMenuItem(menu, "listmyspawns", "List all of your spawned items (listmyspawns)");
	AddMenuItem(menu, "removeall", "Remove all your spawned items (removeall)");
	AddMenuItem(menu, "removelast", "Remove your last spawn (removelast)");
	AddMenuItem(menu, "removefirst", "Remove your first spawn (removefirst)");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_ControlsMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, info);
		DisplayControlsMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
////////////////////////////////////Most Used Menu///////////////////////////////////////
DisplayMostUsedMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_MostUsedMenu);
	SetMenuTitle(menu, "Most Used");
	AddMenuItem(menu, "sm_mountedgun", "Mounted Gun");
	AddMenuItem(menu, "sm_spawnirondoor", "Safe Room Door");
	AddMenuItem(menu, "sm_spawnitem d a models/props_unique/airport/temp_barricade.mdl", "Temp Fence");
	AddMenuItem(menu, "sm_spawnammostack", "Ammo Stack");
	AddMenuItem(menu, "sm_spawnitem p i models/props_unique/airport/atlas_break_ball.mdl", "Globe");
	AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/barricade001_128_reference.mdl", "Barricades(2)");
	AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/barricade001_64_reference.mdl", "Barricade(1)");
	AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/barricade_gate001_64_reference.mdl", "Special Barricade");
    AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/barricade_razorwire001_128_reference.mdl", "Bardel");
    AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/concrete_barrier001_128_reference.mdl", "Concrete Barrier");
    AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/concrete_barrier001_96_reference.mdl", "Concrete Barrier2");
    AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/concrete_block001_128_reference.mdl", "Block Concrete");
    AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/concrete_wall001_96_reference.mdl", "Concrete Wall");
    AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/police_barrier001_128_reference.mdl", "Police Barrier");
    AddMenuItem(menu, "sm_spawnitem d a models/props_junk/wood_crate001a.mdl", "Wood Crate");
	AddMenuItem(menu, "", "");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_MostUsedMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, info);
		DisplayMostUsedMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
////////////////////////////////////////Fence/Barricades////////////////////////
DisplayFenceMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_FenceMenu);
	SetMenuTitle(menu, "Fences/Barricades");
    AddMenuItem(menu, "sm_spawnitem d a models/props_urban/fence_gate002_256.mdl", "Gate Fence");
    AddMenuItem(menu, "sm_spawnitem d a models/props_urban/gate_wall001_256.mdl", "Wall fence");
    AddMenuItem(menu, "sm_spawnitem d a models/props_urban/hotel_railing001.mdl", "Fence hotel");
    AddMenuItem(menu, "sm_spawnitem d a models/props_urban/fence_cover001_128.mdl", "Fence Cover");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_FenceMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		FakeClientCommand(param1, info);
		
		//DisplayControlsMenu(param1);
		DisplayFenceMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
///////////////////////////////////////////////////Vehicles////////////////////////////
DisplayVehicleMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_VehicleMenu);
	SetMenuTitle(menu, "Vehicles");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/racecar.mdl", "Jimmy Car");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/racecar_damaged.mdl", "Damaged Jimmy Car");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/tractor01.mdl", "Tractor");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/utility_truck.mdl", "Utility truck");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/train_box_open.mdl", "Open train box");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/taxi_rural.mdl", "Taxi rural");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/suv_2001.mdl", "Suv 2001");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/semi_truck3.mdl", "Red truck");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/semi_trailer_freestanding.mdl", "Trailer");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/radio_generator.mdl", "Scavenge generator");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/pickup_truck_78.mdl", "Pickup");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/hmmwv_supply.mdl", "Supply military");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/cara_95sedan_wrecked.mdl", "Wrecked car");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/cara_95sedan.mdl", "Car 95");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/cara_84sedan.mdl", "Car 84");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/bus01_2.mdl", "Bus");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/ambulance.mdl", "Ambulance(L4D1)");
    AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/police_car_rural.mdl", "Police car");
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
		
		//DisplayControlsMenu(param1);
		DisplayVehicleMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
///////////////////////////////////////////////////////////Indoor///////////////////////
DisplayIndoorMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_IndoorMenu);
	SetMenuTitle(menu, "Indoor Stuff");
	
	//add stuff here
	
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
		
		//DisplayControlsMenu(param1);
		DisplayIndoorMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
///////////////////////////////////////////////Outdoor////////////////////////////////////////
DisplayOutdoorMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_OutdoorMenu);
	SetMenuTitle(menu, "Outdoor Stuff");

	//add stuff here
	
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
		
		
		//DisplayControlsMenu(param1);
		DisplayOutdoorMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);	
	}
}
////////////////////////////////////////////////////Stairs//////////////////////////////////
DisplayStairsMenu(client) {
    new Handle:menu = CreateMenu(MenuHandler_StairsMenu);
    SetMenuTitle(menu, "Stairs");
    AddMenuItem(menu, "sm_spawnitem d a models/props_downtown/staircase01.mdl", "Big Stair");
    AddMenuItem(menu, "sm_spawnitem d a models/props_exteriors/wood_stairs_120.mdl", "Wood stair");
    AddMenuItem(menu, "sm_spawnitem d a models/props_exteriors/wood_stairs_120_swamp.mdl", "Swamp stair");
    AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/stair_metal_02.mdl", "Metal stair");
    AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/stair_treads_straight.mdl", "Big Wood stair");
    AddMenuItem(menu, "sm_spawnitem d a models/props_mall/atrium_stairs.mdl", "Atrium Stair(HUGE)");
    AddMenuItem(menu, "sm_spawnitem d a models/props_urban/hotel_stairs001.mdl", "Hotel Stair(1)");
    AddMenuItem(menu, "sm_spawnitem d a models/props_urban/hotel_stairs002.mdl", "Hotel Stair(2)");
    AddMenuItem(menu, "sm_spawnitem d a models/props_exteriors/stairs_house_01.mdl", "Stair House");
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
		
		//DisplayControlsMenu(param1);
		DisplayStairsMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
		
	}
}
////////////////////////////////////////////////////Misc////////////////////////////////
DisplayMiscMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_MiscMenu);
	SetMenuTitle(menu, "Misc");
	AddMenuItem(menu, "sm_spawnammostack", "Ammo Stack");
	AddMenuItem(menu, "sm_spawnitem d a models/props_downtown/door_pillar02.mdl", "Pillar");
    AddMenuItem(menu, "sm_spawnitem d a models/props_downtown/parade_float.mdl", "Carnival Parade");
    AddMenuItem(menu, "sm_spawnitem d a models/props_fairgrounds/building_support_32.mdl", "Support build");
    AddMenuItem(menu, "sm_spawnitem d a models/props_fairgrounds/slide.mdl", "Big slide");
    AddMenuItem(menu, "sm_spawnitem d a models/props_fairgrounds/traffic_barrel.mdl", "Traffic barrel");
    AddMenuItem(menu, "sm_spawnitem d a models/props_misc/triage_tent.mdl", "Big tent");
    AddMenuItem(menu, "sm_spawnitem d a models/props_mall/information_desk.mdl", "Mall Information");
    AddMenuItem(menu, "sm_spawnitem d a models/props_urban/dumpster001.mdl", "Empty Dumster");
	AddMenuItem(menu, "", "");
	SetMenuExitBackButton(menu, true);	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_MiscMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
	
		FakeClientCommand(param1, info);
		
		//DisplayControlsMenu(param1);
		DisplayMiscMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
		
	}
}

public bool:UnderLimit(client){
	if(GetArraySize(h_array_SpawnEnts[client]) >= maxspawns) {
		decl String:name[32];
		GetClientName(client, name, sizeof(name));
		PrintToServer("[Build Menu] %s hit limit of %i.", name, maxspawns);
		return false;
	}
	else
		return true;
}
AddToLimit(client,ent){
	PushArrayCell(h_array_SpawnEnts[client], ent);
	PrintToChat(client,"You now have %i spawned objects. Max:%i", GetArraySize(h_array_SpawnEnts[client]),maxspawns);
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
				PrintToChat(i,"You removed ent:%i. You now have %i spawned objects.", ent, GetArraySize(h_array_SpawnEnts[i]));
			else {
				PrintToChat(i,"%s removed ent:%i. You now have %i spawned objects.", ent, GetArraySize(h_array_SpawnEnts[i]));
				PrintToChat(client,"That was %s's object (ent:%i). %s's was reduced, but you still have %i spawned objects.", name, ent, name, GetArraySize(h_array_SpawnEnts[client]));
			}
			return;
		}
	}
	PrintToChat(client,"Object (ent:%i) removed, but not in any player spawned list. You still have %i spawned objects.", ent, GetArraySize(h_array_SpawnEnts[client]));
	return;
}

/////////////////////////TRIGGERS
public Action:RotateClockwise(client,args) {
	FakeClientCommand(client, "sm_rotate 15");
	return Plugin_Handled;
}
public Action:RotateCounterClock(client,args) {	
	FakeClientCommand(client, "sm_rotate -15");
	return Plugin_Handled;
}
public Action:SpawnGlobe(client,args){
	FakeClientCommand(client, "sm_spawnitem p i models/props_unique/airport/atlas_break_ball.mdl");
}
bool:IsAccessGranted( client )
{
    new bool:granted = true;

    // client = 0 means server, server always got access
    if ( client != 0 && GetConVarInt( cvar_adminonly ) > 0 )
    {
        if ( !GetAdminFlag( GetUserAdmin( client ), Admin_Generic, Access_Effective ) )
        {
            ReplyToCommand( client, "Currently, only admins can use buildmenu. Possibly due to abuse." );
            granted = false;
        }
    }
    
    if ( granted )
    {
        if ( GetConVarInt(cvar_enabled) <= 0 )
        {
            ReplyToCommand( client, "buildmenu is disabled" );
            granted = false;
        }
    }
    
    return granted;
}

public Action:SpawnMinigun(client, args)
{
	if ( !IsAccessGranted( client ) )
    {
        return Plugin_Handled;
    }
	if( !client )
	{
		ReplyToCommand(client, "Cannot create a minigun over rcon/server console");
		return Plugin_Handled;	
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;	
	}
			
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3];
	
	new index = CreateEntityByName ( "prop_minigun");
	
	if (index == -1)
	{
		ReplyToCommand(client, "Failed to create minigun!");
		return Plugin_Handled;
	}
	
	DispatchKeyValue(index, "model", "Minigun_1");
	//SetEntityModel (index, "models/w_models/weapons/w_minigun.mdl");
	DispatchKeyValueFloat (index, "MaxPitch", 360.00);
	DispatchKeyValueFloat (index, "MinPitch", -360.00);
	DispatchKeyValueFloat (index, "MaxYaw", 90.00);
	DispatchSpawn(index);
	

	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 32;
	VecOrigin[1] += VecDirection[1] * 32;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(index, "Angles", VecAngles);
	DispatchSpawn(index);
	TeleportEntity(index, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	ReplyToCommand (client, "Created Minigun with Index %i at Position: %i,%i,%i", index, VecOrigin[0], VecOrigin[1], VecOrigin[2]);
	//iLastMinigunIndex = index;
	
	AddToLimit(client,index);
	
	return Plugin_Handled;
}
/*
public Action:SpawnMinigun( client, args )
{
    if ( !IsAccessGranted( client ) )
    {
        return Plugin_Handled;
    }
    
    new index = CreateEntity( client, "prop_minigun", "minigun", "models/w_models/weapons/w_minigun.mdl" );
    if ( index != -1 )
    {
        decl Float:position[3], Float:angles[3];
        if ( GetClientAimedLocationData( client, position, angles, NULL_VECTOR ) == -1 )
        {
            RemoveEdict( index );
            ReplyToCommand( client, "Can't find a location to place, remove entity (%i)", index );
            return Plugin_Handled;
        }
        
        angles[0] = 0.0;
        angles[2] = 0.0;
        DispatchKeyValueVector( index, "Origin", position );
        DispatchKeyValueVector( index, "Angles", angles );
        DispatchKeyValueFloat( index, "MaxPitch",  40.00 );
        DispatchKeyValueFloat( index, "MinPitch", -30.00 );
        DispatchKeyValueFloat( index, "MaxYaw",    90.00 );
        DispatchSpawn( index );
        }

    return Plugin_Handled;
}
*/
public Action:SpawnAmmoStack( client, args )
{
	if(!IsAccessGranted(client))
		return Plugin_Handled;

	if(!UnderLimit(client)) {
		PrintToChat(client, "You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;
	}
	new index;
	if ( GetRandomInt( 1, 2 ) == 1 )
    {
        index = CreateEntity( client, "weapon_ammo_spawn", "ammo stack", "models/props/terror/ammo_stack.mdl" );
    }
	else
    {
        index = CreateEntity( client, "weapon_ammo_spawn", "ammo stack", "models/props_unique/spawn_apartment/coffeeammo.mdl" );
    }
	if ( index != -1 )
    {
        decl Float:position[3], Float:ang_eye[3], Float:ang_ent[3], Float:normal[3];
        if ( GetClientAimedLocationData( client, position, ang_eye, normal ) == -1 )
        {
            RemoveEdict( index );
            ReplyToCommand( client, "Can't find a location to place, remove entity (%i)", index );
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
public Action:SpawnIronDoor( client, args )
{
	if ( !IsAccessGranted( client ) )
    {
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "You have exceeded the %i item spawn limit. Delete something to spawn more items.", maxspawns);
		return Plugin_Handled;	
	}
	new index = CreateEntity( client, "prop_door_rotating", "iron door", "models/props_doors/checkpoint_door_01.mdl" );
	if ( index != -1 )
    {
        decl Float:position[3], Float:angles[3], Float:normal[3];
        if ( GetClientAimedLocationData( client, position, angles, normal ) == -1 )
        {
            RemoveEdict( index );
            ReplyToCommand( client, "Can't find a location to place, remove entity (%i)", index );
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
public Action:SpawnItemNorm( client, args )
{
	if ( !IsAccessGranted( client ) )
		return Plugin_Handled;

	if ( args < 3 )
    {
		ReplyToCommand( client, "Usage: sm_spawnitem <d|p> <i|a> \"filename.mdl\" [1|-1]\n    \
                                    d = dynamic item, p = physics item\n    \
                                    i = spawn in front of you\n    \
                                    a = spawn at where you aim\n    \
                                    1 = place facing toward you\n   \
                                    -1 = place facing against you" );
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "You have exceeded the %i item spawn limit. Delete one of your obects to spawn more.", maxspawns);
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
		index = CreateEntity( client, "prop_physics", "physics item", modelname );
	else
		index = CreateEntity( client, "prop_dynamic", "dynamic item", modelname );
    
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
		//else  //prop_physics
		//{
		//	SetEntProp( index, Prop_Data, "m_spawnflags", 256 );
		//}
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
	}
	if(IsValidEntity(index))
		AddToLimit(client,index);
	else
		PrintToChat(client,"ERROR: Invalid Entity - Object unable to spawn.");
	return Plugin_Handled;
}
public Action:SpawnItem( client, args )
{
	if ( !IsAccessGranted( client ) )
		return Plugin_Handled;

	if ( args < 3 )
    {
		ReplyToCommand( client, "Usage: sm_spawnitem <d|p> <i|a> \"filename.mdl\" [1|-1]\n    \
                                    d = dynamic item, p = physics item\n    \
                                    i = spawn in front of you\n    \
                                    a = spawn at where you aim\n    \
                                    1 = place facing toward you\n   \
                                    -1 = place facing against you" );
		return Plugin_Handled;
	}
	if(!UnderLimit(client)) {
		PrintToChat(client, "You have exceeded the %i item spawn limit. Delete one of your obects to spawn more.", maxspawns);
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
		PrintToChat(client,"ERROR: Invalid Entity - Object unable to spawn.");
	return Plugin_Handled;
}
public Action:RemoveObj( client, args )
{
	if ( !IsAccessGranted( client ) )
		return Plugin_Handled;
    
	new player = GetPlayerIndex( client );
    
	if ( player == 0 )
	{
		ReplyToCommand( player, "Cannot spawn entity over rcon/server console" );
		return Plugin_Handled;
	}
	
	new String:param[128];
	
	new index = -1;
	if ( args > 0 )
	{
		GetCmdArg( 1, param, sizeof(param) );
		index = StringToInt( param );
	}
	else
		index = GetClientAimedLocationData( client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR );
	
	
	GetEdictClassname( index, param, 128 );
	if ( strcmp( param, "prop_door_rotating_checkpoint" ) == 0 )
	{
		PrintToChatAll("Remove of checkpoint door was blocked.");
		return Plugin_Handled;
	}
    
	if ( index > MaxClients )
    {
		RemoveEdict( index );

		ReplyToCommand( player, "Entity:%i removed", index );
		RemoveFromLimit(client, index);
    }
	else if ( index > 0 )
    {
        ReplyToCommand( player, "Cannot remove player (index %i)", index );
    }
	else
    {
        ReplyToCommand( player, "Nothing picked to remove" );
    }
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
        ReplyToCommand( player, "Cannot spawn entity over rcon/server console" );
        return Plugin_Handled;
    }

    new index = GetClientAimedLocationData( client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR );
    if ( index <= 0 )
    {
        ReplyToCommand( player, "Nothing picked to rotate" );
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
GetPlayerIndex( client )
{
    if ( client == 0 && !IsDedicatedServer() )
    {
        return 1;
    }
    
    return client;
}
//---------------------------------------------------------
// spawn a given entity type and assign it a model
//---------------------------------------------------------
CreateEntity( client, const String:entity_name[], const String:item_name[], const String:model[] = "" )
{
    new player = GetPlayerIndex( client );
    
    if ( player == 0 )
    {
        ReplyToCommand( player, "Cannot spawn entity over rcon/server console" );
        return -1;
    }

    new index = CreateEntityByName( entity_name );
    if ( index == -1 )
    {
        ReplyToCommand( player, "Failed to create %s !", item_name );
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

    ReplyToCommand( player, "Successfully create %s (index %i)", item_name, index );

    return index;
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
        ReplyToCommand( player, "Failed to pick the aimed location" );
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
// the filter function for TR_TraceRayFilterEx
//---------------------------------------------------------
public bool:TraceEntityFilterPlayers( entity, contentsMask, any:data )
{
    return entity > MaxClients && entity != data;
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

RotateYaw( Float:angles[3], Float:degree )
{
    decl Float:direction[3], Float:normal[3];
    GetAngleVectors( angles, direction, NULL_VECTOR, normal );
    
    new Float:sin = Sine( degree * 0.01745328 );     // Pi/180
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
        ReplyToCommand( client, "Failed to rotate the minigun!" );
        return;
    }

    // delete current minigun
    RemoveEdict( index );
        
    if ( !IsModelPrecached( "models/w_models/weapons/w_minigun.mdl" ) )
    {
        PrecacheModel( "models/w_models/weapons/w_minigun.mdl" );
    }
    SetEntityModel( newindex, "models/w_models/weapons/w_minigun.mdl" );
    DispatchKeyValueFloat( newindex, "MaxPitch",  40.00 );
    DispatchKeyValueFloat( newindex, "MinPitch", -30.00 );
    DispatchKeyValueFloat( newindex, "MaxYaw",    90.00 );
    DispatchKeyValueVector( newindex, "Angles", angles );
    DispatchKeyValueVector( newindex, "Origin", origin );
    
    DispatchSpawn( newindex );
}



///////////////////////////////////////////L4D 1 Stuff
/*
////////////////////////////////////Most Used Menu///////////////////////////////////////
DisplayMostUsedMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_MostUsedMenu);
	SetMenuTitle(menu, "Most Used");
	AddMenuItem(menu, "sm_mountedgun", "Mounted Gun");
	AddMenuItem(menu, "sm_spawnirondoor", "Safe Room Door");
	AddMenuItem(menu, "sm_spawnitem d a models/props_unique/airport/temp_barricade.mdl", "Temp Fence");
	AddMenuItem(menu, "sm_spawnammostack", "Ammo Stack");
	AddMenuItem(menu, "sm_spawnitem p i models/props_unique/airport/atlas_break_ball.mdl", "Globe");
	AddMenuItem(menu, "", "");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_MostUsedMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		FakeClientCommand(param1, info);
		DisplayMostUsedMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
////////////////////////////////////////Fence/Barricades////////////////////////
DisplayFenceMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_FenceMenu);
	SetMenuTitle(menu, "Fences/Barricades");
	AddMenuItem(menu, "sm_spawnitem d a models/props_street/police_barricade.mdl", "Police Barricade (1)");
	AddMenuItem(menu, "sm_spawnitem d a models/props_street/police_barricade2.mdl", "Police Barricade (3)");
	AddMenuItem(menu, "sm_spawnitem d a models/props_street/police_barricade3.mdl", "Police Barricade (6)");
	AddMenuItem(menu, "sm_spawnitem d a models/props_street/police_barricade4.mdl", "Police Barricade (12)");
	AddMenuItem(menu, "sm_spawnitem d a models/props_wasteland/exterior_fence002c.mdl", "Fence");
	AddMenuItem(menu, "sm_spawnitem d a models/props_wasteland/exterior_fence002a.mdl", "Fence Narrow");
	AddMenuItem(menu, "sm_spawnitem d a models/props_c17/concrete_barrier001a.mdl", "Concrete Barrier");
	AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/sandbags_line2.mdl", "Sandbag Line");
	AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/sandbags_corner2.mdl 1", "Sandbag Corner");
	AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/sandbags_corner3.mdl 1", "Sandbag Corner Short");
	AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/fortification_indoor_01.mdl", "Indoor Barricade");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_militia/boxes_frontroom.mdl", "Stacked Boxes");
	AddMenuItem(menu, "sm_spawnitem d a models/props_unique/wooden_barricade_break1.mdl", "Wooden Barricade");
	AddMenuItem(menu, "sm_spawnitem d a models/props/de_train/chainlinkgate.mdl", "Chain-Linked Fence");
	AddMenuItem(menu, "sm_spawnitem d a models/props_fortifications/fencesmash.mdl", "Fence");
	AddMenuItem(menu, "sm_spawnitem d a models/props_exteriors/sandbags_curved.mdl", "Sandbags Corner");
	AddMenuItem(menu, "sm_spawnitem d a models/props_exteriors/sandbags_straight.mdl", "Sandbags Line");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_FenceMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		FakeClientCommand(param1, info);
		
		//DisplayControlsMenu(param1);
		DisplayFenceMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
///////////////////////////////////////////////////Vehicles////////////////////////////
DisplayVehicleMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_VehicleMenu);
	SetMenuTitle(menu, "Vehicles");
	AddMenuItem(menu, "sm_spawnitem d i models/props_vehicles/army_truck.mdl", "Army Truck");
	AddMenuItem(menu, "sm_spawnitem d i models/props_vehicles/humvee.mdl", "Humvee");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/cara_82hatchback.mdl", "HatchBack car");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/ambulance.mdl", "Ambulance");
	AddMenuItem(menu, "prop_dynamic_create props_vehicles/police_car_glass.mdl;prop_dynamic_create props_vehicles/police_car_lightbar.mdl;prop_dynamic_create props_vehicles/police_car_lights_on.mdl", "Police Car - TEST");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/church_bus01.mdl", "Church Bus");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/airport_fuel_truck.mdl", "Fuel Truck");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/flatnose_truck.mdl", "Flatnose Truck");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/bus01.mdl", "Bus");
	AddMenuItem(menu, "sm_spawnitem d a models/props_trainstation/train003.mdl", "Train");
	AddMenuItem(menu, "sm_spawnitem d a models/props/de_nuke/truck_nuke.mdl", "Open Truck");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/tractor01.mdl", "Tractor");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/tanker001a.mdl", "Destroyed Tanker");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/semi_truck", "Semi-Truck");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/semi_trailer.mdl", "Trailer");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/c130.mdl", "C13 Military Plane");
	AddMenuItem(menu, "sm_spawnitem d a models/props_debris/airliner_wreckage1.mdl", "Plane Head");
	AddMenuItem(menu, "sm_spawnitem d a models/props_debris/airliner_wreckage2.mdl", "Plane Wing");
	AddMenuItem(menu, "sm_spawnitem d a models/props_debris/airliner_wreckage3.mdl", "Plane Tail");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/airliner_finale_left.mdl;sm_spawnitem d a models/props_vehicles/airliner_finale_right.mdl", "Airliner - ERROR");
	AddMenuItem(menu, "sm_spawnitem d a models/hybridphysx/news_helicoptor_hoveranim.mdl", "Opened Rescue Heli");
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
		
		//DisplayControlsMenu(param1);
		DisplayVehicleMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
///////////////////////////////////////////////////////////Indoor///////////////////////
DisplayIndoorMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_IndoorMenu);
	SetMenuTitle(menu, "Indoor Stuff");
	AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/couch.mdl", "Couch");
	AddMenuItem(menu, "sm_spawnitem d a models/props_windows/window_industrial.mdl", "Window");
	AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/bed.mdl", "Bed");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_office/vending_machine.mdl", "Soda Machine");
	AddMenuItem(menu, "sm_spawnitem d a models/props_equipment/snack_machine.mdl", "Snack Machine");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_militia/television_console01.mdl", "T.V.");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_militia/bar01.mdl", "Bar");
	AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/magazine_rack.mdl", "Magazines");
	AddMenuItem(menu, "sm_spawnitem d a models/props_furniture/bathtub1.mdl", "BathTub");
	AddMenuItem(menu, "sm_spawnitem p a models/props/cs_militia/barstool01.mdl", "Stool");
	AddMenuItem(menu, "sm_spawnitem p a models/props/cs_militia/caseofbeer01.mdl", "Beer");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_militia/wood_bench.mdl", "Bench");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_militia/wood_table.mdl", "Wooden Table");
	AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/dvd_player.mdl", "DVD Player");
	AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/dryer.mdl", "Dryer");
	AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/desk_metal.mdl", "Metal Desk");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_office/Chair_office.mdl", "Chair");
	AddMenuItem(menu, "sm_spawnitem d a models/props_furniture/desk1.mdl", "Wooden Desk");
	AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/toilet.mdl", "Toilet");
	AddMenuItem(menu, "sm_spawnitem d a models/props_lab/monitor01a.mdl", "Computer");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_militia/microwave01.mdl", "Microwave");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_office/light_ceiling.mdl", "Ceiling Light");
	AddMenuItem(menu, "sm_spawnitem d a models/props/de_inferno/furnituredrawer001a.mdl", "Drawer");
	AddMenuItem(menu, "sm_spawnitem d a models/props/de_nuke/clock.mdl", "Clock");
	AddMenuItem(menu, "sm_spawnitem d a models/props_doors/emergency_exit_sign.mdl", "Emergency Exit Sign");
	AddMenuItem(menu, "sm_spawnitem d a models/props_equipment/phone_booth_indoor.mdl", "Wall Phone");
	AddMenuItem(menu, "sm_spawnitem d a models/props_furniture/kitchen_countertop1.mdl", "CounterTop");
	AddMenuItem(menu, "sm_spawnitem d a models/props_furniture/piano.mdl", "Piano");
	AddMenuItem(menu, "sm_spawnitem d a models/props_office/desk_01.mdl", "Desk");
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
		
		//DisplayControlsMenu(param1);
		DisplayIndoorMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
	}
}
///////////////////////////////////////////////Outdoor////////////////////////////////////////
DisplayOutdoorMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_OutdoorMenu);
	SetMenuTitle(menu, "Outdoor Stuff");
	AddMenuItem(menu, "sm_spawnitem d a models/props_junk/dumpster.mdl", "Dumpster");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_militia/silo_01.mdl", "Silo");
	AddMenuItem(menu, "sm_spawnitem d a models/props_junk/barrel_fire.mdl", "Barrel");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_assault/streetlight.mdl", "Small Street Light");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_militia/mailbox01.mdl", "MailBox");
	AddMenuItem(menu, "sm_spawnitem d i models/props_unique/rope_bridge.mdl -1", "Bridge");
	AddMenuItem(menu, "sm_spawnitem d a models/props_industrial/wire_spool_01.mdl", "Wire Spool");
	AddMenuItem(menu, "sm_spawnitem d a models/props_equipment/light_floodlight.mdl", "FloodLight");
	AddMenuItem(menu, "sm_spawnitem d a models/props_equipment/scaffolding.mdl", "Scaffolding");
	AddMenuItem(menu, "sm_spawnitem d a models/props_street/phonepole1_tall.mdl", "Phone pole");
	AddMenuItem(menu, "sm_spawnitem d a models/props_industrial/oil_pipes.mdl", "Pipes");
	AddMenuItem(menu, "sm_spawnitem d a models/props_junk/trashdumpster02.mdl", "Big Dumpster");
	AddMenuItem(menu, "sm_spawnitem d a models/hybridphysx/animated_construction_lift.mdl", "Lift");
	AddMenuItem(menu, "sm_spawnitem d a models/props_unique/haybails_farmhouse.mdl", "Haybails");
	AddMenuItem(menu, "sm_spawnitem p a models/props_canal/boat001a.mdl", "Breaked Boat");
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
		
		
		//DisplayControlsMenu(param1);
		DisplayOutdoorMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);	
	}
}
////////////////////////////////////////////////////Misc////////////////////////////////
DisplayMiscMenu(client) {
	new Handle:menu = CreateMenu(MenuHandler_MiscMenu);
	SetMenuTitle(menu, "Misc");
	AddMenuItem(menu, "sm_spawnammostack", "Ammo Stack");
	AddMenuItem(menu, "sm_spawnitem d i models/props_exteriors/wood_stairs_120.mdl 1", "Stairs");
	AddMenuItem(menu, "sm_spawnitem d i models/props_exteriors/wood_stairs_40.mdl 1", "Stairs Short");
	AddMenuItem(menu, "sm_spawnitem d a models/props_exteriors/wood_railing001.mdl", "Wood Railing");
	AddMenuItem(menu, "sm_spawnitem d a models/hybridphysx/lawnmower_bloodpool.mdl", "Big Puddle of Blood");
	AddMenuItem(menu, "sm_spawnitem d a models/props/de_nuke/cinderblock_stack.mdl", "Cinderblocks");
	AddMenuItem(menu, "sm_spawnitem d a models/props_unique/generator_switch_01.mdl", "Generator Switcher");
	AddMenuItem(menu, "sm_spawnitem d i models/props_buildings/barn_steps.mdl 1", "Barn Steps");
	AddMenuItem(menu, "sm_spawnitem d a models/props_doors/roll-up_door_half.mdl", "Roll-up Door");
	AddMenuItem(menu, "sm_spawnitem p a models/props_unique/wooden_barricade_gascans.mdl", "Gascan Stack");
	AddMenuItem(menu, "sm_spawnitemnorm p a models/props_equipment/gas_pump.mdl", "Gas Pump - TEST");
	AddMenuItem(menu, "sm_spawnitem d a models/props_cemetery/cemetery_column.mdl", "Column");
	AddMenuItem(menu, "sm_spawnitem d a models/props_unique/atm01.mdl", "ATM");
	AddMenuItem(menu, "sm_spawnitem d a models/props_equipment/luggage_x_ray.mdl", "Luggage X-ray");
	AddMenuItem(menu, "sm_spawnitem d a models/props_equipment/securitycheckpoint.mdl", "Metal Detector");
	AddMenuItem(menu, "sm_spawnitem d a models/props_street/warehouse_vent_pipe01.mdl", "Pipe");
	AddMenuItem(menu, "sm_spawnitem d a models/props_unique/guncabinet01_main.mdl", "Gun Cabinet");
	AddMenuItem(menu, "sm_spawnitem p a models/props_junk/wood_crate001a_damagedmax.mdl", "1 Box");
	AddMenuItem(menu, "sm_spawnitem p a models/props_junk/wood_crate002a.mdl", "2 Box");
	AddMenuItem(menu, "sm_spawnitem p a models/props_junk/wood_pallet001a.mdl", "Pallet");
	AddMenuItem(menu, "sm_spawnitem d a models/extras/info_speech.mdl", "Commentary");
	AddMenuItem(menu, "sm_spawnitem d a models/props_doors/doorfreezer01.mdl", "Unbreakable Door");
	AddMenuItem(menu, "sm_spawnitem d i models/props_urban/fire_escape_wide_upper.mdl 1", "Fire Escape Stairs - FIXED?");
	AddMenuItem(menu, "sm_spawnitem d a models/props_unique/generator_short.mdl", "Short Generator");
	AddMenuItem(menu, "prop_dynamic_create models/props_unique/hospital05_rooftop_stair01.mdl", "Rooftop Stairs 1 - NOT WORK");
	AddMenuItem(menu, "prop_dynamic_create models/props_unique/hospital05_rooftop_stair02.mdl", "Rooftop Stairs 2 - NOT WORK");
	AddMenuItem(menu, "prop_dynamic_create models/props_unique/hospital05_rooftop_stair03.mdl", "Rooftop Stairs 3 - NOT WORK");
	AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/medicalcabinet02.mdl", "Medical Cabinet");
	AddMenuItem(menu, "sm_spawnitem d a models/props_vehicles/airport_baggage_cart2.mdl", "Airport Baggage");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_assault/box_stack1.mdl", "Stacked Boxes 1");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_assault/box_stack2.mdl", "Stacked Boxes 2");
	AddMenuItem(menu, "sm_spawnitem d a models/props/de_prodigy/concretebags2.mdl", "Concrete Bags");
	AddMenuItem(menu, "sm_spawnitem d a models/props/cs_militia/housefence_door.mdl", "House Fence");
	AddMenuItem(menu, "sm_spawnitem d a models/props_exteriors/wood_stairs_wide_48.mdl", "Wide Wooden Stairs");
	AddMenuItem(menu, "sm_spawnitem d a models/props/de_nuke/crate_extralarge.mdl", "Large Crate");
	AddMenuItem(menu, "sm_spawnitem d a models/props/de_nuke/crate_small.mdl", "Small Crate");
	AddMenuItem(menu, "prop_physics_create  models/props_equipment/gas_pump_nodebris.mdl", "Gas Pump - nodebris - TEST");
	AddMenuItem(menu, "sm_spawnitem p a models/props_junk/wood_crate001a.mdl", "Woodcrate");
	AddMenuItem(menu, "sm_spawnitem d a models/props_equipment/sleeping_bag1.mdl", "Sleeping Bag");
	AddMenuItem(menu, "sm_spawnitem d a models/props_junk\food_pile01.mdl", "Scattered Food");
	AddMenuItem(menu, "sm_spawnitem d a models/props/terror/hamradio.mdl", "Radio");
	AddMenuItem(menu, "sm_spawnitem d a models/props_junk/trashcluster01b.mdl", "Junk");
	AddMenuItem(menu, "sm_spawnitem d a models/props_interiors/elevator_panel.mdl", "Elevator Panel");	
	AddMenuItem(menu, "", "");
	SetMenuExitBackButton(menu, true);	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public MenuHandler_MiscMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End){
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
	
		FakeClientCommand(param1, info);
		
		//DisplayControlsMenu(param1);
		DisplayMiscMenu(param1);
	}
	else if (action == MenuAction_Cancel){
		DisplayMainBuildMenu(param1);
		
	}
}
*/





/*
sm_spawnitem <d|p> <a|i> "*.mdl" [-1|1]
d: spawn as prop_dynamic
p: spawn as prop_physics
a: spawn at where you aim( just like prop_dynamic_create)
i: spawn in front of you
*.mdl: just go for a prop list and find something interesting
-1: align the angle of spawned item and show its back to you
1: same as above, but show the front to you
without[-1:1]: item will aligned in default angle(similar to prop_dynamic_create)
*/