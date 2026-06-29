// GunGame by Benni

#include <sourcemod>
#include <sdktools>


//Stocks:
#include "rp_stocks"


//Terminate:
#pragma semicolon 0
#pragma compress 0



static Level1[33];



public Plugin:myinfo = 
{
	name = "GunGame",
	author = "Benjamin1995",
	description = "GunGame for Half Life 2 Deathmatch",
	version = "2.1",
	url = "http://www.bfs-server.de"
}


//Initation:
public OnPluginStart() {
	LoadTranslations("common.phrases");
	
	//Events:
	HookEvent("player_death", EventDeath);
	HookEvent("player_spawn", EventSpawn, EventHookMode_Pre);
	
	
	//Server Variable:
	CreateConVar("benni_gungame_version", "2.1", "Benni_GunGame Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
}



public OnClientPostAdminCheck (Client) {
	Level1[Client] = 0;

	}



//Spawn:
public EventSpawn(Handle:Event, const String:Name[], bool:Broadcast)
{
	
	//Declare:
	decl Client;
	
	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	

CreateTimer(0.5, RemoveWeapons, Client);
CreateTimer(1.5, GunGameWeapons, Client);


	//Close:
	CloseHandle(Event);
}



//Remove Weapons:
public Action:RemoveWeapons(Handle:Timer, any:Client)
{
	
	//Declare:
	decl Offset;
	decl MaxGuns;
	decl WeaponId;
	
	//Initialize:
	Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	
	//Weapons:
	if(Level1[Client] < 100) MaxGuns = 20;

	
	//Loop:
	for(new X = 0; X < MaxGuns; X = (X + 4))
	{
		
		//Initialize:
		WeaponId = GetEntDataEnt(Client, Offset + X);
		
		//Valid:
		if(WeaponId > 0)
		{
			
			//Weapon:
			RemovePlayerItem(Client, WeaponId);
			RemoveEdict(WeaponId);
		}
	}
}


//GunGame Weapons:
public Action:WonRound(Handle:Timer, any:Client)
{
		new MaxClients = GetMaxClients();
	for(new i = 1; i < MaxClients; i++)
	{	
Level1[i] = 0;
ServerCommand("sm_slay @all");

	}
	
	}

//GunGame Weapons:
public Action:GunGameWeapons(Handle:Timer, any:Client)
{
	
if(Level1[Client] == 0){
GivePlayerItem(Client, "weapon_crowbar");
}
if(Level1[Client] == 2){
GivePlayerItem(Client, "weapon_stunstick");
}
if(Level1[Client] == 3){
GivePlayerItem(Client, "weapon_pistol");
}
if(Level1[Client] == 4){
GivePlayerItem(Client, "weapon_smg1");
}
if(Level1[Client] == 5){
GivePlayerItem(Client, "weapon_rpg");
}
if(Level1[Client] == 6){
GivePlayerItem(Client, "weapon_frag");
GivePlayerItem(Client, "weapon_physcannon");
}
if(Level1[Client] == 7){
GivePlayerItem(Client, "weapon_ar2");
}
if(Level1[Client] == 8){
GivePlayerItem(Client, "weapon_crossbow");
}
if(Level1[Client] == 9){
GivePlayerItem(Client, "weapon_shotgun");
}
if(Level1[Client] == 10){
GivePlayerItem(Client, "weapon_357");
}
if(Level1[Client] == 11){
GivePlayerItem(Client, "weapon_slam");
GivePlayerItem(Client, "weapon_physcannon");
}
}

//Death:
public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	
	//Declare:
	decl Client, Attacker;
	decl String:WeaponName[80];
	decl String:ClientName[80], String:AttackerName[80];
	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));

	
	//Initialize:
	GetClientName(Attacker, AttackerName, 80);
	GetClientName(Client, ClientName, 80);
	
	//Weapon:
	GetClientWeapon(Attacker, WeaponName, 32);
	
	//World:
	if(Client == 0 || Attacker == 0)
	{		
			//Declare:
	decl Offset;
	decl MaxGuns;
	decl WeaponId;
	
	//Initialize:
	Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	
	//Weapons:
	if(Level1[Client] < 100) MaxGuns = 20;

	
	//Loop:
	for(new X = 0; X < MaxGuns; X = (X + 4))
	{
		
		//Initialize:
		WeaponId = GetEntDataEnt(Client, Offset + X);
		
		//Valid:
		if(WeaponId > 0)
		{
			
			//Weapon:
			RemovePlayerItem(Client, WeaponId);
			RemoveEdict(WeaponId);
		}
	}
	 return Plugin_Handled;
	}
	
	
	//World:
	if(Attacker == Client) 
	{
				//Declare:
	decl Offset;
	decl MaxGuns;
	decl WeaponId;
	
	//Initialize:
	Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	
	//Weapons:
	if(Level1[Client] < 100) MaxGuns = 20;

	
	//Loop:
	for(new X = 0; X < MaxGuns; X = (X + 4))
	{
		
		//Initialize:
		WeaponId = GetEntDataEnt(Client, Offset + X);
		
		//Valid:
		if(WeaponId > 0)
		{
			
			//Weapon:
			RemovePlayerItem(Client, WeaponId);
			RemoveEdict(WeaponId);
		}
	}
	 return Plugin_Handled;
	}
	
	if(Attacker == 0)
	{		
			//Declare:
	decl Offset;
	decl MaxGuns;
	decl WeaponId;
	
	//Initialize:
	Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	
	//Weapons:
	if(Level1[Client] < 100) MaxGuns = 20;

	
	//Loop:
	for(new X = 0; X < MaxGuns; X = (X + 4))
	{
		
		//Initialize:
		WeaponId = GetEntDataEnt(Client, Offset + X);
		
		//Valid:
		if(WeaponId > 0)
		{
			
			//Weapon:
			RemovePlayerItem(Client, WeaponId);
			RemoveEdict(WeaponId);
		}
	}
	 return Plugin_Handled;			
	}
		//Declare:
	decl Offset;
	decl MaxGuns;
	decl WeaponId;
	
	//Initialize:
	Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");
	
	//Weapons:
	if(Level1[Client] < 100) MaxGuns = 20;

	
	//Loop:
	for(new X = 0; X < MaxGuns; X = (X + 4))
	{
		
		//Initialize:
		WeaponId = GetEntDataEnt(Client, Offset + X);
		
		//Valid:
		if(WeaponId > 0)
		{
			
			//Weapon:
			RemovePlayerItem(Client, WeaponId);
			RemoveEdict(WeaponId);
		}
	}
	if(Level1[Attacker] == 0) {
	if(StrEqual(WeaponName, "weapon_crowbar", false)) {
		
     Level1[Attacker] = 2;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now in Level \x04%d\x04\x01", AttackerName, Level1[Attacker]);		
	 		CreateTimer(0.1, RemoveWeapons, Attacker);
CreateTimer(0.5, GunGameWeapons, Attacker);
	}
	}
	if(Level1[Attacker] == 2) {
	if(StrEqual(WeaponName, "weapon_stunstick", false)) {
		
     Level1[Attacker] += 1;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now in Level \x04%d\x04\x01", AttackerName, Level1[Attacker]);	
   		CreateTimer(0.1, RemoveWeapons, Attacker);
CreateTimer(0.5, GunGameWeapons, Attacker);	
	}
	}
	if(Level1[Attacker] == 3) {
	if(StrEqual(WeaponName, "weapon_pistol", false)) {
		
     Level1[Attacker] += 1;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now in Level \x04%d\x04\x01", AttackerName, Level1[Attacker]);		
	 		CreateTimer(0.1, RemoveWeapons, Attacker);
CreateTimer(0.5, GunGameWeapons, Attacker);
	}
	}
		if(Level1[Attacker] == 4) {
	if(StrEqual(WeaponName, "weapon_smg1", false)) {
		
     Level1[Attacker] += 1;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now in Level \x04%d\x04\x01", AttackerName, Level1[Attacker]);		
	 		CreateTimer(0.1, RemoveWeapons, Attacker);
CreateTimer(0.5, GunGameWeapons, Attacker);
	}
	}
	if(Level1[Attacker] == 5) {
	if(StrEqual(WeaponName, "weapon_rpg", false)) {
		
     Level1[Attacker] += 1;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now in Level \x04%d\x04\x01", AttackerName, Level1[Attacker]);	
   		CreateTimer(0.1, RemoveWeapons, Attacker);
CreateTimer(0.5, GunGameWeapons, Attacker);	
	}
	}
	if(Level1[Attacker] == 6) {
	if(StrEqual(WeaponName, "weapon_frag", false) || StrEqual(WeaponName, "weapon_physcannon", false)) {
		
     Level1[Attacker] += 1;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now in Level \x04%d\x04\x01", AttackerName, Level1[Attacker]);		
	 		CreateTimer(0.1, RemoveWeapons, Attacker);
CreateTimer(0.5, GunGameWeapons, Attacker);
	}
	}
	if(Level1[Attacker] == 7) {
	if(StrEqual(WeaponName, "weapon_ar2", false)) {
		
     Level1[Attacker] += 1;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now in Level \x04%d\x04\x01", AttackerName, Level1[Attacker]);	
   		CreateTimer(0.1, RemoveWeapons, Attacker);
CreateTimer(0.5, GunGameWeapons, Attacker);	
	}
	}
	if(Level1[Attacker] == 8) {
	if(StrEqual(WeaponName, "weapon_crossbow", false)) {
		
     Level1[Attacker] += 1;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now in Level \x04%d\x04\x01", AttackerName, Level1[Attacker]);		
	 		CreateTimer(0.1, RemoveWeapons, Attacker);
CreateTimer(0.5, GunGameWeapons, Attacker);
	}
	}
	if(Level1[Attacker] == 9) {
	if(StrEqual(WeaponName, "weapon_shotgun", false)) {
		
     Level1[Attacker] += 1;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now in Level \x04%d\x04\x01", AttackerName, Level1[Attacker]);		
	 		CreateTimer(0.1, RemoveWeapons, Attacker);
CreateTimer(0.5, GunGameWeapons, Attacker);
	}
	}
	if(Level1[Attacker] == 10) {
	if(StrEqual(WeaponName, "weapon_357", false)) {
		
     Level1[Attacker] += 1;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 is now in Level \x04%d\x04\x01", AttackerName, Level1[Attacker]);		
	 		CreateTimer(0.1, RemoveWeapons, Attacker);
CreateTimer(0.5, GunGameWeapons, Attacker);
	}
	}
	if(Level1[Attacker] == 11) {
	if(StrEqual(WeaponName, "weapon_slam", false) || StrEqual(WeaponName, "weapon_physcannon", false)) {
		
     Level1[Attacker] += 1;
	 PrintToChatAll("\x04\x01[GunGame]\x04 %s\x04\x01 has won this Round", AttackerName);		
	 PrintCenterTextAll("%s won the Round", AttackerName);
   CreateTimer(0.1, WonRound, Attacker);
	}
	}

	//Close:
	CloseHandle(Event);
	}













