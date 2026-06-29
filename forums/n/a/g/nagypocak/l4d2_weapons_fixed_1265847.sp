/**********Thanks To**************
* {7~11} TROLL for the original plugin
* CrimsonGt - helped {7~11} TROLL with give player item issues
*********************************/
#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.2.1"

new Handle:g_max_give[48];
new max_give[48]; //array for storing initial quota of each item
new give_quota0[MAXPLAYERS+1]; //quota left (each player) for item 1
new give_quota1[MAXPLAYERS+1]; //quota left (each player) for item 2
new give_quota2[MAXPLAYERS+1]; //quota left (each player) for item 3
new give_quota3[MAXPLAYERS+1]; //quota left (each player) for item 4
new give_quota4[MAXPLAYERS+1]; //quota left (each player) for item 5
new give_quota5[MAXPLAYERS+1]; //quota left (each player) for item 6
new give_quota6[MAXPLAYERS+1]; //quota left (each player) for item 7
new give_quota7[MAXPLAYERS+1]; //quota left (each player) for item 8
new give_quota8[MAXPLAYERS+1]; //quota left (each player) for item 9
new give_quota9[MAXPLAYERS+1]; //quota left (each player) for item 10
new give_quota10[MAXPLAYERS+1]; //quota left (each player) for item 11
new give_quota11[MAXPLAYERS+1]; //quota left (each player) for item 12
new give_quota12[MAXPLAYERS+1]; //quota left (each player) for item 13
new give_quota13[MAXPLAYERS+1]; //quota left (each player) for item 14
new give_quota14[MAXPLAYERS+1]; //quota left (each player) for item 15
new give_quota15[MAXPLAYERS+1]; //quota left (each player) for item 16
new give_quota16[MAXPLAYERS+1]; //quota left (each player) for item 17
new give_quota17[MAXPLAYERS+1]; //quota left (each player) for item 18
new give_quota18[MAXPLAYERS+1]; //quota left (each player) for item 19
new give_quota19[MAXPLAYERS+1]; //quota left (each player) for item 20
new give_quota20[MAXPLAYERS+1]; //quota left (each player) for item 21
new give_quota21[MAXPLAYERS+1]; //quota left (each player) for item 22
new give_quota22[MAXPLAYERS+1]; //quota left (each player) for item 23
new give_quota23[MAXPLAYERS+1]; //quota left (each player) for item 24
new give_quota24[MAXPLAYERS+1]; //quota left (each player) for item 25
new give_quota25[MAXPLAYERS+1]; //quota left (each player) for item 26
new give_quota26[MAXPLAYERS+1]; //quota left (each player) for item 27
new give_quota27[MAXPLAYERS+1]; //quota left (each player) for item 28
new give_quota28[MAXPLAYERS+1]; //quota left (each player) for item 29
new give_quota29[MAXPLAYERS+1]; //quota left (each player) for item 30
new give_quota30[MAXPLAYERS+1]; //quota left (each player) for item 31
new give_quota31[MAXPLAYERS+1]; //quota left (each player) for item 32
new give_quota32[MAXPLAYERS+1]; //quota left (each player) for item 33
new give_quota33[MAXPLAYERS+1]; //quota left (each player) for item 34
new give_quota34[MAXPLAYERS+1]; //quota left (each player) for item 35
new give_quota35[MAXPLAYERS+1]; //quota left (each player) for item 36
new give_quota36[MAXPLAYERS+1]; //quota left (each player) for item 37
new give_quota37[MAXPLAYERS+1]; //quota left (each player) for item 38
new give_quota38[MAXPLAYERS+1]; //quota left (each player) for item 39
new give_quota39[MAXPLAYERS+1]; //quota left (each player) for item 40
new give_quota40[MAXPLAYERS+1]; //quota left (each player) for item 41
new give_quota41[MAXPLAYERS+1]; //quota left (each player) for item 42
new give_quota42[MAXPLAYERS+1]; //quota left (each player) for item 43
new give_quota43[MAXPLAYERS+1]; //quota left (each player) for item 44
new give_quota44[MAXPLAYERS+1]; //quota left (each player) for item 45
new give_quota45[MAXPLAYERS+1]; //quota left (each player) for item 46
new give_quota46[MAXPLAYERS+1]; //quota left (each player) for item 47
new give_quota47[MAXPLAYERS+1]; //quota left (each player) for item 48

public Plugin:myinfo = 
{
	name = "[L4D2] Tank Buster 2 Menu",
	author = "Teddy Ruxpin",
	description = "Allows Clients To Get Weapons Packs and other items",
	version = PLUGIN_VERSION,
	url = "www.blacktusklabs.com"
}
public OnPluginStart()
{
	//tank buster weapons menu cvar
	RegConsoleCmd("tankbuster", TankBusterMenu);
	RegConsoleCmd("goods", TankBusterMenu);
	//plugin version
	CreateConVar("tank_buster2_version", PLUGIN_VERSION, "Tank_Buster_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Quota cvars for each player
	g_max_give[0] = CreateConVar("sm_quota_healt", "-1", " Quota Given to each player for obtaining Full Healt in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[1] = CreateConVar("sm_quota_ammo", "-1", " Quota Given to each player for obtaining Ammunition in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[2] = CreateConVar("sm_quota_first_aid_kit", "-1", " Quota Given to each player for obtaining Fisrt Aid Kit in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[3] = CreateConVar("sm_quota_defibrillator", "-1", " Quota Given to each player for obtaining Defibrillator in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[4] = CreateConVar("sm_quota_pain_pills", "-1", " Quota Given to each player for obtaining Pain Pills in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[5] = CreateConVar("sm_quota_adrenaline", "-1", " Quota Given to each player for obtaining Adrenaline in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[6] = CreateConVar("sm_quota_pistol", "-1", " Quota Given to each player for obtaining Pistol in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[7] = CreateConVar("sm_quota_pistol_magnum", "-1", " Quota Given to each player for obtaining pistol_magnum in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[8] = CreateConVar("sm_quota_chainsaw", "-1", " Quota Given to each player for obtaining chainsaw in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[9] = CreateConVar("sm_quota_pumpshotgun", "-1", " Quota Given to each player for obtaining pump shotgun in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[10] = CreateConVar("sm_quota_shotgun_chrome", "-1", " Quota Given to each player for obtaining chore shutgun in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[11] = CreateConVar("sm_quota_autoshotgun", "-1", " Quota Given to each player for obtaining autoshotgun in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[12] = CreateConVar("sm_quota_shotgun_spas", "-1", " Quota Given to each player for obtaining shotgun_spas in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[13] = CreateConVar("sm_quota_smg", "-1", " Quota Given to each player for obtaining smg uzi in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[14] = CreateConVar("sm_quota_smg_silenced", "-1", " Quota Given to each player for obtaining smg_silenced in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[15] = CreateConVar("sm_quota_smg_mp5", "-1", " Quota Given to each player for obtaining smg_mp5 in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[16] = CreateConVar("sm_quota_rifle", "-1", " Quota Given to each player for obtaining rifle m16 in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[17] = CreateConVar("sm_quota_rifle_ak47", "-1", " Quota Given to each player for obtaining rifle_ak47 in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[18] = CreateConVar("sm_quota_rifle_desert", "-1", " Quota Given to each player for obtaining rifle scar in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[19] = CreateConVar("sm_quota_rifle_sg552", "-1", " Quota Given to each player for obtaining rifle sg552 in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[20] = CreateConVar("sm_quota_hunting_rifle", "-1", " Quota Given to each player for obtaining hunting_rifle in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[21] = CreateConVar("sm_quota_sniper_military", "-1", " Quota Given to each player for obtaining sniper_military in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[22] = CreateConVar("sm_quota_sniper_scout", "-1", " Quota Given to each player for obtaining sniper_scout in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[23] = CreateConVar("sm_quota_sniper_awp", "-1", " Quota Given to each player for obtaining sniper_awp in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[24] = CreateConVar("sm_quota_rifle_m60", "-1", " Quota Given to each player for obtaining rifle_m60 in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[25] = CreateConVar("sm_quota_grenade_launcher", "-1", " Quota Given to each player for obtaining grenade_launcher in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[26] = CreateConVar("sm_quota_molotov", "-1", " Quota Given to each player for obtaining molotov in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[27] = CreateConVar("sm_quota_pipe_bomb", "-1", " Quota Given to each player for obtaining pipe_bomb in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[28] = CreateConVar("sm_quota_vomitjar", "-1", " Quota Given to each player for obtaining vomitjar in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[29] = CreateConVar("sm_quota_gascan", "-1", " Quota Given to each player for obtaining gascan in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[30] = CreateConVar("sm_quota_fireworkcrate", "-1", " Quota Given to each player for obtaining fireworkcrate in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[31] = CreateConVar("sm_quota_propanetank", "-1", " Quota Given to each player for obtaining propanetank in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[32] = CreateConVar("sm_quota_oxygentank", "-1", " Quota Given to each player for obtaining oxygentank in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[33] = CreateConVar("sm_quota_gnome", "-1", " Quota Given to each player for obtaining gnome & cola in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[34] = CreateConVar("sm_quota_upgradepack_explosive", "-1", " Quota Given to each player for obtaining upgradepack_explosive in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[35] = CreateConVar("sm_quota_upgradepack_incendiary", "-1", " Quota Given to each player for obtaining upgradepack_incendiary in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[36] = CreateConVar("sm_quota_golfclub", "-1", " Quota Given to each player for obtaining golfclub in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[37] = CreateConVar("sm_quota_baseball_bat", "-1", " Quota Given to each player for obtaining baseball_bat in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[38] = CreateConVar("sm_quota_cricket_bat", "-1", " Quota Given to each player for obtaining cricket_bat in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[39] = CreateConVar("sm_quota_crowbar", "-1" ," Quota Given to each player for obtaining crowbar in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[40] = CreateConVar("sm_quota_electric_guitar", "-1", " Quota Given to each player for obtaining electric_guitar in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[41] = CreateConVar("sm_quota_fireaxe", "-1", " Quota Given to each player for obtaining fireaxe in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[42] = CreateConVar("sm_quota_frying_pan", "-1", " Quota Given to each player for obtaining frying_pan in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[43] = CreateConVar("sm_quota_katana", "-1", " Quota Given to each player for obtaining katana in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[44] = CreateConVar("sm_quota_machete", "-1", " Quota Given to each player for obtaining machete in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[45] = CreateConVar("sm_quota_tonfa", "-1", " Quota Given to each player for obtaining tonfa in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[46] = CreateConVar("sm_quota_hunting_knife", "-1", " Quota Given to each player for obtaining hunting_knife in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[47] = CreateConVar("sm_quota_riotshield", "-1", " Quota Given to each player for obtaining riotshield in each round ( -1 = unlimited 0 = disabled )");
		//Execute or create cfg
	AutoExecConfig(true, "L4DWeaponsMenu_restricted");	
	
}

public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{ 
	//Get max clients on server
	new maxclients = GetMaxClients();
	
	//Get inital quotas from cvars
	max_give[0] = GetConVarInt(g_max_give[0]);
	max_give[1] = GetConVarInt(g_max_give[1]);
	max_give[2] = GetConVarInt(g_max_give[2]);
	max_give[3] = GetConVarInt(g_max_give[3]);
	max_give[4] = GetConVarInt(g_max_give[4]);
	max_give[5] = GetConVarInt(g_max_give[5]);
	max_give[6] = GetConVarInt(g_max_give[6]);
	max_give[7] = GetConVarInt(g_max_give[7]);
	max_give[8] = GetConVarInt(g_max_give[8]);
	max_give[9] = GetConVarInt(g_max_give[9]);
	max_give[10] = GetConVarInt(g_max_give[10]);
	max_give[11] = GetConVarInt(g_max_give[11]);
	max_give[12] = GetConVarInt(g_max_give[12]);
	max_give[13] = GetConVarInt(g_max_give[13]);
	max_give[14] = GetConVarInt(g_max_give[14]);
	max_give[15] = GetConVarInt(g_max_give[15]);
	max_give[16] = GetConVarInt(g_max_give[16]);
	max_give[17] = GetConVarInt(g_max_give[17]);
	max_give[18] = GetConVarInt(g_max_give[18]);
	max_give[19] = GetConVarInt(g_max_give[19]);
	max_give[20] = GetConVarInt(g_max_give[20]);
	max_give[21] = GetConVarInt(g_max_give[21]);
	max_give[22] = GetConVarInt(g_max_give[22]);
	max_give[23] = GetConVarInt(g_max_give[23]);
	max_give[24] = GetConVarInt(g_max_give[24]);
	max_give[25] = GetConVarInt(g_max_give[25]);
	max_give[26] = GetConVarInt(g_max_give[26]);
	max_give[27] = GetConVarInt(g_max_give[27]);
	max_give[28] = GetConVarInt(g_max_give[28]);
	max_give[29] = GetConVarInt(g_max_give[29]);
	max_give[30] = GetConVarInt(g_max_give[30]);
	max_give[31] = GetConVarInt(g_max_give[31]);
	max_give[32] = GetConVarInt(g_max_give[32]);
	max_give[33] = GetConVarInt(g_max_give[33]);
	max_give[34] = GetConVarInt(g_max_give[34]);
	max_give[35] = GetConVarInt(g_max_give[35]);
	max_give[36] = GetConVarInt(g_max_give[36]);
	max_give[37] = GetConVarInt(g_max_give[37]);
	max_give[38] = GetConVarInt(g_max_give[38]);
	max_give[39] = GetConVarInt(g_max_give[39]);
	max_give[40] = GetConVarInt(g_max_give[40]);
	max_give[41] = GetConVarInt(g_max_give[41]);
	max_give[42] = GetConVarInt(g_max_give[42]);
	max_give[43] = GetConVarInt(g_max_give[43]);
	max_give[44] = GetConVarInt(g_max_give[44]);
	max_give[45] = GetConVarInt(g_max_give[45]);
	max_give[46] = GetConVarInt(g_max_give[46]);
	max_give[47] = GetConVarInt(g_max_give[47]);
		
	
	//Sets inital quotas for every player
	for (new client = 1; client <= maxclients; client++)
	{
		give_quota0[client] = max_give[0];
		give_quota1[client] = max_give[1];
		give_quota2[client] = max_give[2];
		give_quota3[client] = max_give[3];
		give_quota4[client] = max_give[4];
		give_quota5[client] = max_give[5];
		give_quota6[client] = max_give[6];
		give_quota7[client] = max_give[7];
		give_quota8[client] = max_give[8];
		give_quota9[client] = max_give[9];
		give_quota10[client] = max_give[10];
		give_quota11[client] = max_give[11];
		give_quota12[client] = max_give[12];
		give_quota13[client] = max_give[13];
		give_quota14[client] = max_give[14];
		give_quota15[client] = max_give[15];
		give_quota16[client] = max_give[16];
		give_quota17[client] = max_give[17];
		give_quota18[client] = max_give[18];
		give_quota19[client] = max_give[19];
		give_quota20[client] = max_give[20];
		give_quota21[client] = max_give[21];
		give_quota22[client] = max_give[22];
		give_quota23[client] = max_give[23];
		give_quota24[client] = max_give[24];
		give_quota25[client] = max_give[25];
		give_quota26[client] = max_give[26];
		give_quota27[client] = max_give[27];
		give_quota28[client] = max_give[28];
		give_quota29[client] = max_give[29];
		give_quota30[client] = max_give[30];
		give_quota31[client] = max_give[31];
		give_quota32[client] = max_give[32];
		give_quota33[client] = max_give[33];
		give_quota34[client] = max_give[34];
		give_quota35[client] = max_give[35];
		give_quota36[client] = max_give[36];
		give_quota37[client] = max_give[37];
		give_quota38[client] = max_give[38];
		give_quota39[client] = max_give[39];
		give_quota40[client] = max_give[40];
		give_quota41[client] = max_give[41];
		give_quota42[client] = max_give[42];
		give_quota43[client] = max_give[43];
		give_quota44[client] = max_give[44];
		give_quota45[client] = max_give[45];
		give_quota46[client] = max_give[46];
		give_quota47[client] = max_give[47];
				
	}
}

public OnClientPutInServer(client)
{
	//Get inital quotas from cvars
	max_give[0] = GetConVarInt(g_max_give[0]);
	max_give[1] = GetConVarInt(g_max_give[1]);
	max_give[2] = GetConVarInt(g_max_give[2]);
	max_give[3] = GetConVarInt(g_max_give[3]);
	max_give[4] = GetConVarInt(g_max_give[4]);
	max_give[5] = GetConVarInt(g_max_give[5]);
	max_give[6] = GetConVarInt(g_max_give[6]);
	max_give[7] = GetConVarInt(g_max_give[7]);
	max_give[8] = GetConVarInt(g_max_give[8]);
	max_give[9] = GetConVarInt(g_max_give[9]);
	max_give[10] = GetConVarInt(g_max_give[10]);
	max_give[11] = GetConVarInt(g_max_give[11]);
	max_give[12] = GetConVarInt(g_max_give[12]);
	max_give[13] = GetConVarInt(g_max_give[13]);
	max_give[14] = GetConVarInt(g_max_give[14]);
	max_give[15] = GetConVarInt(g_max_give[15]);
	max_give[16] = GetConVarInt(g_max_give[16]);
	max_give[17] = GetConVarInt(g_max_give[17]);
	max_give[18] = GetConVarInt(g_max_give[18]);
	max_give[19] = GetConVarInt(g_max_give[19]);
	max_give[20] = GetConVarInt(g_max_give[20]);
	max_give[21] = GetConVarInt(g_max_give[21]);
	max_give[22] = GetConVarInt(g_max_give[22]);
	max_give[23] = GetConVarInt(g_max_give[23]);
	max_give[24] = GetConVarInt(g_max_give[24]);
	max_give[25] = GetConVarInt(g_max_give[25]);
	max_give[26] = GetConVarInt(g_max_give[26]);
	max_give[27] = GetConVarInt(g_max_give[27]);
	max_give[28] = GetConVarInt(g_max_give[28]);
	max_give[29] = GetConVarInt(g_max_give[29]);
	max_give[30] = GetConVarInt(g_max_give[30]);
	max_give[31] = GetConVarInt(g_max_give[31]);
	max_give[32] = GetConVarInt(g_max_give[32]);
	max_give[33] = GetConVarInt(g_max_give[33]);
	max_give[34] = GetConVarInt(g_max_give[34]);
	max_give[35] = GetConVarInt(g_max_give[35]);
	max_give[36] = GetConVarInt(g_max_give[36]);
	max_give[37] = GetConVarInt(g_max_give[37]);
	max_give[38] = GetConVarInt(g_max_give[38]);
	max_give[39] = GetConVarInt(g_max_give[39]);
	max_give[40] = GetConVarInt(g_max_give[40]);
	max_give[41] = GetConVarInt(g_max_give[41]);
	max_give[42] = GetConVarInt(g_max_give[42]);
	max_give[43] = GetConVarInt(g_max_give[43]);
	max_give[44] = GetConVarInt(g_max_give[44]);
	max_give[45] = GetConVarInt(g_max_give[45]);
	max_give[46] = GetConVarInt(g_max_give[46]);
	max_give[47] = GetConVarInt(g_max_give[47]);
		
	
	//Sets inital quotas for the player just joined   
	give_quota0[client] = max_give[0];
	give_quota1[client] = max_give[1];
	give_quota2[client] = max_give[2];
	give_quota3[client] = max_give[3];
	give_quota4[client] = max_give[4];
	give_quota5[client] = max_give[5];
	give_quota6[client] = max_give[6];
	give_quota7[client] = max_give[7];
	give_quota8[client] = max_give[8];
	give_quota9[client] = max_give[9];
	give_quota10[client] = max_give[10];
	give_quota11[client] = max_give[11];
	give_quota12[client] = max_give[12];
	give_quota13[client] = max_give[13];
	give_quota14[client] = max_give[14];
	give_quota15[client] = max_give[15];
	give_quota16[client] = max_give[16];
	give_quota17[client] = max_give[17];
	give_quota18[client] = max_give[18];
	give_quota19[client] = max_give[19];
	give_quota20[client] = max_give[20];
	give_quota21[client] = max_give[21];
	give_quota22[client] = max_give[22];
	give_quota23[client] = max_give[23];
	give_quota24[client] = max_give[24];
	give_quota25[client] = max_give[25];
	give_quota26[client] = max_give[26];
	give_quota27[client] = max_give[27];
	give_quota28[client] = max_give[28];
	give_quota29[client] = max_give[29];
	give_quota30[client] = max_give[30];
	give_quota31[client] = max_give[31];
	give_quota32[client] = max_give[32];
	give_quota33[client] = max_give[33];
	give_quota34[client] = max_give[34];
	give_quota35[client] = max_give[35];
	give_quota36[client] = max_give[36];
	give_quota37[client] = max_give[37];
	give_quota38[client] = max_give[38];
	give_quota39[client] = max_give[39];
	give_quota40[client] = max_give[40];
	give_quota41[client] = max_give[41];
	give_quota42[client] = max_give[42];
	give_quota43[client] = max_give[43];
	give_quota44[client] = max_give[44];
	give_quota45[client] = max_give[45];
	give_quota46[client] = max_give[46];
	give_quota47[client] = max_give[47];
		
}

public Action:TankBusterMenu(client,args)
{
	TankBuster(client);
	return Plugin_Handled;
}

public Action:TankBuster(clientId)
{
	new Handle:menu = CreateMenu(TankBusterMenuHandler);
	SetMenuTitle(menu, "TankBuster 2 Weapons Menu");
	AddMenuItem(menu, "option0", "Full Health");
	AddMenuItem(menu, "option1", "Ammunition");
	AddMenuItem(menu, "option2", "First Aid Kit");
	AddMenuItem(menu, "option3", "Defibrillator");
	AddMenuItem(menu, "option4", "Pain Pills");
	AddMenuItem(menu, "option5", "Adrenaline");
	AddMenuItem(menu, "option6", "Pistol P220/Glock");
	AddMenuItem(menu, "option7", "Pistol Desert Eagle");
	AddMenuItem(menu, "option8", "Chainsaw");
	AddMenuItem(menu, "option9", "Pump Shotgun");
	AddMenuItem(menu, "option10", "Chrome Shotgun");
	AddMenuItem(menu, "option11", "Autoshotgun Benelli M4");
	AddMenuItem(menu, "option12", "Shotgun Spas 12");
	AddMenuItem(menu, "option13", "SMG UZI");
	AddMenuItem(menu, "option14", "SMG MAC 10 Silenced");
	AddMenuItem(menu, "option15", "SMG HK MP5 * CSS");
	AddMenuItem(menu, "option16", "Rifle M16");
	AddMenuItem(menu, "option17", "Rifle AK47");
	AddMenuItem(menu, "option18", "Rifle FN SCAR");
	AddMenuItem(menu, "option19", "Rifle Sig552 * CSS");
	AddMenuItem(menu, "option20", "Sniper Hunting");
	AddMenuItem(menu, "option21", "Sniper HK MSG90A1");
	AddMenuItem(menu, "option22", "Sniper Scout *CSS");
	AddMenuItem(menu, "option23", "Sniper AWP * CSS");
	AddMenuItem(menu, "option24", "M60 machine gun");
	AddMenuItem(menu, "option25", "Grenade Launcher");
	AddMenuItem(menu, "option26", "Molotov");
	AddMenuItem(menu, "option27", "Pipe Bomb");
	AddMenuItem(menu, "option28", "Vomit Jar");
	AddMenuItem(menu, "option29", "Gascan");
	AddMenuItem(menu, "option30", "Fireworkcrate");
	AddMenuItem(menu, "option31", "Propanetank");
	AddMenuItem(menu, "option32", "Oxygentank");
	AddMenuItem(menu, "option33", "Gnome Chomsky & Cola bottles");
	AddMenuItem(menu, "option34", "Upgradepack Explosive");
	AddMenuItem(menu, "option35", "Upgradepack Incendiary");
	AddMenuItem(menu, "option36", "Golf Club  * Only if level allows");
	AddMenuItem(menu, "option37", "Baseball Bat * Only if level allows");
	AddMenuItem(menu, "option38", "Cricket Bat * Only if level allows");
	AddMenuItem(menu, "option39", "Crowbar * Only if level allows");
	AddMenuItem(menu, "option40", "Electric Guitar * Only if level allows");
	AddMenuItem(menu, "option41", "Fireaxe * Only if level allows");
	AddMenuItem(menu, "option42", "Frying Pan * Only if level allows");
	AddMenuItem(menu, "option43", "Katana * Only if level allows");
	AddMenuItem(menu, "option44", "Machete * Only if level allows");
	AddMenuItem(menu, "option45", "Tonfa * Only if level allows");
	AddMenuItem(menu, "option46", "Hunting Knife * CSS * Only if level allows");
	AddMenuItem(menu, "option47", "Riot Shield * CSS * Only if level allows");
SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
	//return Plugin_Handled;
}

public TankBusterMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	//Strip the CHEAT flag off of the "give" command
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	if ( action == MenuAction_Select ) {  
		switch (itemNum)
		{
			
			
			case 0: // Full Health
			{
				if ( give_quota0[client] > 0 || give_quota0[client] < 0) {
					//Give the player Full Health
					FakeClientCommand(client, "give health");
					//Decrease remaining quota of that player by 1
					give_quota0[client]--;
					//Notify remaining quota
					if (give_quota0[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain Health until next round",give_quota0[client]);
					}
					else if (give_quota0[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Health until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain Health");
				}
			}
			case 1: // Ammunition
			{
				if ( give_quota1[client] > 0 || give_quota1[client] < 0) {
					//Give the player Ammunition
					FakeClientCommand(client, "give ammo");
					//Decrease remaining quota of that player by 1
					give_quota1[client]--;
					//Notify remaining quota
					if (give_quota1[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain Ammunition until next round",give_quota1[client]);
					}
					else if (give_quota1[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Ammunition until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain Ammunition");
				}
			}
			case 2: // first_aid_kit
			{
				if ( give_quota2[client] > 0 || give_quota2[client] < 0) {
					//Give the player a first_aid_kit
					FakeClientCommand(client, "give first_aid_kit");
					//Decrease remaining quota of that player by 1
					give_quota2[client]--;
					//Notify remaining quota
					if (give_quota2[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a first_aid_kit until next round",give_quota2[client]);
					}
					else if (give_quota2[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore first_aid_kit until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a first_aid_kit");
				}
			}
			case 3: // defibrillator
			{
				if ( give_quota3[client] > 0 || give_quota3[client] < 0) {
					//Give the player a defibrillator
					FakeClientCommand(client, "give defibrillator");
					//Decrease remaining quota of that player by 1
					give_quota3[client]--;
					//Notify remaining quota
					if (give_quota3[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a defibrillator until next round",give_quota3[client]);
					}
					else if (give_quota3[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore defibrillator until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a defibrillator");
				}
			}
			case 4: // Pain Pills
			{
				if ( give_quota4[client] > 0 || give_quota4[client] < 0) {
					//Give the player a Pain Pills
					FakeClientCommand(client, "give pain_pills");
					//Decrease remaining quota of that player by 1
					give_quota4[client]--;
					//Notify remaining quota
					if (give_quota4[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain pain_pills until next round",give_quota4[client]);
					}
					else if (give_quota4[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore pain_pills until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain pain_pills");
				}
			}
			case 5: // Adrenaline
			{
				if ( give_quota5[client] > 0 || give_quota5[client] < 0) {
					//Give the player adrenaline
					FakeClientCommand(client, "give adrenaline");
					//Decrease remaining quota of that player by 1
					give_quota5[client]--;
					//Notify remaining quota
					if (give_quota5[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an adrenaline until next round",give_quota5[client]);
					}
					else if (give_quota5[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore adrenaline until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an adrenaline");
				}
			}
			case 6: // Pistol P220/Glock
			{
				if ( give_quota6[client] > 0 || give_quota6[client] < 0) {
					//Give the player a Pistol
					FakeClientCommand(client, "give pistol");
					//Decrease remaining quota of that player by 1
					give_quota6[client]--;
					//Notify remaining quota
					if (give_quota6[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a pistol until next round",give_quota6[client]);
					}
					else if (give_quota6[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore pistol until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a pistol");
				}
			}
			case 7: // Pistol Desert Eagle
			{
				if ( give_quota7[client] > 0 || give_quota7[client] < 0) {
					//Give the player a Desert Eagle
					FakeClientCommand(client, "give pistol_magnum");
					//Decrease remaining quota of that player by 1
					give_quota7[client]--;
					//Notify remaining quota
					if (give_quota7[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Desert Eagle until next round",give_quota7[client]);
					}
					else if (give_quota7[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Desert Eagle until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Desert Eagle");
				}
			}
			case 8: // Chainsaw
			{
				if ( give_quota8[client] > 0 || give_quota8[client] < 0) {
					//Give the player a chainsaw
					FakeClientCommand(client, "give chainsaw");
					//Decrease remaining quota of that player by 1
					give_quota8[client]--;
					//Notify remaining quota
					if (give_quota8[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Chainsaw until next round",give_quota8[client]);
					}
					else if (give_quota8[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Chainsaw until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Chainsaw");
				}
			}
			case 9: // Pump Shotgun
			{
				if ( give_quota9[client] > 0 || give_quota9[client] < 0) {
					//Give the player a Pump Shotgun
					FakeClientCommand(client, "give pumpshotgun");
					//Decrease remaining quota of that player by 1
					give_quota9[client]--;
					//Notify remaining quota
					if (give_quota9[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Pump Shotgun until next round",give_quota9[client]);
					}
					else if (give_quota9[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Pump Shotgun until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Pump Shotgun");
				}
			}
			case 10: // Chrome Shotgun
			{
				if ( give_quota10[client] > 0 || give_quota10[client] < 0) {
					//Give the player a Chrome Shotgun
					FakeClientCommand(client, "give shotgun_chrome");
					//Decrease remaining quota of that player by 1
					give_quota10[client]--;
					//Notify remaining quota
					if (give_quota10[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Chrome Shotgun until next round",give_quota10[client]);
					}
					else if (give_quota10[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Chrome Shotgun until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Chrome Shotgun");
				}
			}
			case 11: // Autoshotgun Benelli M4
			{
				if ( give_quota10[client] > 0 || give_quota11[client] < 0) {
					//Give the player an Autoshotgun
					FakeClientCommand(client, "give autoshotgun");
					//Decrease remaining quota of that player by 1
					give_quota11[client]--;
					//Notify remaining quota
					if (give_quota11[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an Autoshotgun until next round",give_quota11[client]);
					}
					else if (give_quota10[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Autoshotgun until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an Autoshotgun");
				}
			}
			case 12: // Shotgun Spas 12
			{
				if ( give_quota12[client] > 0 || give_quota12[client] < 0) {
					//Give the player a Spas 12
					FakeClientCommand(client, "give shotgun_spas");
					//Decrease remaining quota of that player by 1
					give_quota12[client]--;
					//Notify remaining quota
					if (give_quota12[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Spas 12 until next round",give_quota12[client]);
					}
					else if (give_quota12[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Spas 12 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Spas 12");
				}
			}
			case 13: // SMG UZI
			{
				if ( give_quota13[client] > 0 || give_quota13[client] < 0) {
					//Give the player a UZI
					FakeClientCommand(client, "give smg");
					//Decrease remaining quota of that player by 1
					give_quota13[client]--;
					//Notify remaining quota
					if (give_quota13[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an UZI until next round",give_quota13[client]);
					}
					else if (give_quota13[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore UZI until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an UZI");
				}
			}
			case 14: // SMG MAC 10 Silenced
			{
				if ( give_quota14[client] > 0 || give_quota14[client] < 0) {
					//Give the player a MAC 10 Silenced
					FakeClientCommand(client, "give smg_silenced");
					//Decrease remaining quota of that player by 1
					give_quota14[client]--;
					//Notify remaining quota
					if (give_quota14[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a MAC 10 Silenced until next round",give_quota14[client]);
					}
					else if (give_quota14[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore MAC 10 Silenced until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a MAC 10 Silenced");
				}
			}
			case 15: // SMG HK MP5 * CSS
			{
				if ( give_quota15[client] > 0 || give_quota15[client] < 0) {
					//Give the player a HK MP5
					FakeClientCommand(client, "give smg_mp5");
					//Decrease remaining quota of that player by 1
					give_quota15[client]--;
					//Notify remaining quota
					if (give_quota15[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a HK MP5 until next round",give_quota15[client]);
					}
					else if (give_quota15[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore HK MP5 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a HK MP5");
				}
			}
			case 16: // Rifle M16
			{
				if ( give_quota16[client] > 0 || give_quota16[client] < 0) {
					//Give the player an M16 rifle
					FakeClientCommand(client, "give rifle");
					//Decrease remaining quota of that player by 1
					give_quota16[client]--;
					//Notify remaining quota
					if (give_quota16[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an M16 next round",give_quota16[client]);
					}
					else if (give_quota10[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore M16 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an M16");
				}
			}
			case 17: // Rifle AK47
			{
				if ( give_quota17[client] > 0 || give_quota17[client] < 0) {
					//Give the player a AK47 rifle
					FakeClientCommand(client, "give rifle_ak47");
					//Decrease remaining quota of that player by 1
					give_quota17[client]--;
					//Notify remaining quota
					if (give_quota17[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an AK47 until next round",give_quota17[client]);
					}
					else if (give_quota17[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore AK47 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an AK47");
				}
			}
			case 18: // Rifle FN SCAR
			{
				if ( give_quota18[client] > 0 || give_quota18[client] < 0) {
					//Give the player a FN SCAR rifle
					FakeClientCommand(client, "give rifle_desert");
					//Decrease remaining quota of that player by 1
					give_quota18[client]--;
					//Notify remaining quota
					if (give_quota18[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an FN SCAR until next round",give_quota18[client]);
					}
					else if (give_quota18[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore FN SCAR until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an FN SCAR");
				}
			}
			case 19: // Rifle Sig552 * CSS
			{
				if ( give_quota19[client] > 0 || give_quota19[client] < 0) {
					//Give the player a Sig552 rifle
					FakeClientCommand(client, "give rifle_sg552");
					//Decrease remaining quota of that player by 1
					give_quota19[client]--;
					//Notify remaining quota
					if (give_quota19[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Sig552 until next round",give_quota19[client]);
					}
					else if (give_quota19[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Sig552 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Sig552");
				}
			}
			case 20: // Sniper Hunting
			{
				if ( give_quota20[client] > 0 || give_quota20[client] < 0) {
					//Give the player a Hunting rifle
					FakeClientCommand(client, "give hunting_rifle");
					//Decrease remaining quota of that player by 1
					give_quota20[client]--;
					//Notify remaining quota
					if (give_quota20[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Hunting rifle next round",give_quota20[client]);
					}
					else if (give_quota20[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Hunting rifle until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Hunting rifle");
				}
			}
			case 21: // Sniper HK MSG90A1
			{
				if ( give_quota21[client] > 0 || give_quota21[client] < 0) {
					//Give the player a HK MSG90A1
					FakeClientCommand(client, "give sniper_military");
					//Decrease remaining quota of that player by 1
					give_quota21[client]--;
					//Notify remaining quota
					if (give_quota21[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a HK MSG90A1 until next round",give_quota21[client]);
					}
					else if (give_quota21[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore HK MSG90A1 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a HK MSG90A1");
				}
			}
			case 22: // Sniper Scout *CSS
			{
				if ( give_quota22[client] > 0 || give_quota22[client] < 0) {
					//Give the player a Sniper Scout
					FakeClientCommand(client, "give sniper_scout");
					//Decrease remaining quota of that player by 1
					give_quota22[client]--;
					//Notify remaining quota
					if (give_quota22[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Scout until next round",give_quota22[client]);
					}
					else if (give_quota22[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Scout until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Scout");
				}
			}
			case 23: // Sniper AWP * CSS
			{
				if ( give_quota23[client] > 0 || give_quota23[client] < 0) {
					//Give the player an AWP
					FakeClientCommand(client, "give sniper_awp");
					//Decrease remaining quota of that player by 1
					give_quota23[client]--;
					//Notify remaining quota
					if (give_quota23[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an AWP until next round",give_quota23[client]);
					}
					else if (give_quota23[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore AWP until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an AWP");
				}
			}
			case 24: // M60 machine gun
			{
				if ( give_quota24[client] > 0 || give_quota24[client] < 0) {
					//Give the player an M60
					FakeClientCommand(client, "give rifle_m60");
					//Decrease remaining quota of that player by 1
					give_quota24[client]--;
					//Notify remaining quota
					if (give_quota24[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an M60 until next round",give_quota24[client]);
					}
					else if (give_quota24[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore M60 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an M60");
				}
			}
			case 25: // Grenade Launcher
			{
				if ( give_quota25[client] > 0 || give_quota25[client] < 0) {
					//Give the player a Grenade Launcher
					FakeClientCommand(client, "give grenade_launcher");
					//Decrease remaining quota of that player by 1
					give_quota25[client]--;
					//Notify remaining quota
					if (give_quota25[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Grenade Launcher until next round",give_quota25[client]);
					}
					else if (give_quota25[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Grenade Launcher until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Grenade Launcher");
				}
			}
			case 26: // Molotov
			{
				if ( give_quota26[client] > 0 || give_quota26[client] < 0) {
					//Give the player a Molotov
					FakeClientCommand(client, "give molotov");
					//Decrease remaining quota of that player by 1
					give_quota26[client]--;
					//Notify remaining quota
					if (give_quota26[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Molotov until next round",give_quota26[client]);
					}
					else if (give_quota26[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Molotov until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Molotov");
				}
			}
			case 27: // Pipe Bomb
			{
				if ( give_quota27[client] > 0 || give_quota27[client] < 0) {
					//Give the player a Pipe Bomb
					FakeClientCommand(client, "give pipe_bomb");
					//Decrease remaining quota of that player by 1
					give_quota27[client]--;
					//Notify remaining quota
					if (give_quota27[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Pipe Bomb until next round",give_quota27[client]);
					}
					else if (give_quota27[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Pipe Bomb until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Pipe Bomb");
				}
			}
			case 28: // Vomit Jar
			{
				if ( give_quota28[client] > 0 || give_quota28[client] < 0) {
					//Give the player a Vomit Jar
					FakeClientCommand(client, "give vomitjar");
					//Decrease remaining quota of that player by 1
					give_quota28[client]--;
					//Notify remaining quota
					if (give_quota28[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Vomit Jar until next round",give_quota28[client]);
					}
					else if (give_quota28[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Vomit Jar until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Vomit Jar");
				}
			}
			case 29: // Gascan
			{
				if ( give_quota29[client] > 0 || give_quota29[client] < 0) {
					//Give the player a Gascan
					FakeClientCommand(client, "give gascan");
					//Decrease remaining quota of that player by 1
					give_quota29[client]--;
					//Notify remaining quota
					if (give_quota29[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Gascan until next round",give_quota29[client]);
					}
					else if (give_quota29[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Gascan until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Gascan");
				}
			}
			case 30: // Fireworkcrate
			{
				if ( give_quota30[client] > 0 || give_quota30[client] < 0) {
					//Give the player a Fireworkcrate
					FakeClientCommand(client, "give fireworkcrate");
					//Decrease remaining quota of that player by 1
					give_quota30[client]--;
					//Notify remaining quota
					if (give_quota30[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Fireworkcrate until next round",give_quota30[client]);
					}
					else if (give_quota30[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Fireworkcrate until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Fireworkcrate");
				}
			}
			case 31: // Propanetank
			{
				if ( give_quota31[client] > 0 || give_quota31[client] < 0) {
					//Give the player a Propanetank
					FakeClientCommand(client, "give propanetank");
					//Decrease remaining quota of that player by 1
					give_quota31[client]--;
					//Notify remaining quota
					if (give_quota31[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Propanetank until next round",give_quota31[client]);
					}
					else if (give_quota31[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Propanetank until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Propanetank");
				}
			}
			case 32: // Oxygentank
			{
				if ( give_quota32[client] > 0 || give_quota32[client] < 0) {
					//Give the player a pipe_bomb
					FakeClientCommand(client, "give oxygentank");
					//Decrease remaining quota of that player by 1
					give_quota32[client]--;
					//Notify remaining quota
					if (give_quota32[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an Oxygentank until next round",give_quota32[client]);
					}
					else if (give_quota32[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Oxygentank until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an Oxygentank");
				}
			}
			case 33: // Gnome Chomsky & COla
			{
				if ( give_quota33[client] > 0 || give_quota33[client] < 0) {
					//Give the player a Gnome
					FakeClientCommand(client, "give cola_bottles");
					FakeClientCommand(client, "give gnome");
					//Decrease remaining quota of that player by 1
					give_quota33[client]--;
					//Notify remaining quota
					if (give_quota33[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Gnome & Cola until next round",give_quota33[client]);
					}
					else if (give_quota33[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Gnome & Cola until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Gnome & Cola");
				}
			}
			case 34: // Upgradepack Explosive
			{
				if ( give_quota34[client] > 0 || give_quota34[client] < 0) {
					//Give the player an Upgradepack Explosive
					FakeClientCommand(client, "give upgradepack_explosive");
					//Decrease remaining quota of that player by 1
					give_quota34[client]--;
					//Notify remaining quota
					if (give_quota34[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an Upgradepack Explosive until next round",give_quota34[client]);
					}
					else if (give_quota34[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Upgradepack Explosive until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an Upgradepack Explosive");
				}
			}
			case 35: // Upgradepack Incendiary
			{
				if ( give_quota35[client] > 0 || give_quota35[client] < 0) {
					//Give the player a Upgradepack Incendiary
					FakeClientCommand(client, "give upgradepack_incendiary");
					//Decrease remaining quota of that player by 1
					give_quota35[client]--;
					//Notify remaining quota
					if (give_quota35[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an Upgradepack Incendiary until next round",give_quota35[client]);
					}
					else if (give_quota35[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Upgradepack Incendiary until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an Upgradepack Incendiary");
				}
			}
			case 36: // Golf Club
			{
				if ( give_quota36[client] > 0 || give_quota36[client] < 0) {
					//Give the player a Golf Club
					FakeClientCommand(client, "give golfclub");
					//Decrease remaining quota of that player by 1
					give_quota36[client]--;
					//Notify remaining quota
					if (give_quota36[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Golf Club until next round",give_quota36[client]);
					}
					else if (give_quota36[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Golf Club until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Golf Club");
				}
			}
			case 37: // Baseball Bat
			{
				if ( give_quota37[client] > 0 || give_quota37[client] < 0) {
					//Give the player a Baseball Bat
					FakeClientCommand(client, "give baseball_bat");
					//Decrease remaining quota of that player by 1
					give_quota37[client]--;
					//Notify remaining quota
					if (give_quota37[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Baseball Bat until next round",give_quota37[client]);
					}
					else if (give_quota37[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Baseball Bat until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Baseball Bat");
				}
			}
			case 38: // Cricket Bat
			{
				if ( give_quota38[client] > 0 || give_quota38[client] < 0) {
					//Give the player a Cricket Bat
					FakeClientCommand(client, "give cricket_bat");
					//Decrease remaining quota of that player by 1
					give_quota38[client]--;
					//Notify remaining quota
					if (give_quota38[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Cricket Bat until next round",give_quota38[client]);
					}
					else if (give_quota38[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Cricket Bat until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Cricket Bat");
				}
			}
			case 39: // Crowbar
			{
				if ( give_quota39[client] > 0 || give_quota39[client] < 0) {
					//Give the player a Crowbar
					FakeClientCommand(client, "give crowbar");
					//Decrease remaining quota of that player by 1
					give_quota39[client]--;
					//Notify remaining quota
					if (give_quota39[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Crowbar until next round",give_quota39[client]);
					}
					else if (give_quota39[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Crowbar until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Crowbar");
				}
			}
			case 40: // Electric Guitar
			{
				if ( give_quota40[client] > 0 || give_quota40[client] < 0) {
					//Give the player a Electric Guitar
					FakeClientCommand(client, "give electric_guitar");
					//Decrease remaining quota of that player by 1
					give_quota40[client]--;
					//Notify remaining quota
					if (give_quota40[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an Electric Guitar until next round",give_quota40[client]);
					}
					else if (give_quota40[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Electric Guitar until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an Electric Guitar");
				}
			}
			case 41: // Fireaxe
			{
				if ( give_quota41[client] > 0 || give_quota41[client] < 0) {
					//Give the player a Fireaxe
					FakeClientCommand(client, "give fireaxe");
					//Decrease remaining quota of that player by 1
					give_quota41[client]--;
					//Notify remaining quota
					if (give_quota41[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Fireaxe until next round",give_quota41[client]);
					}
					else if (give_quota41[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Fireaxe until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Fireaxe");
				}
			}
			case 42: // Frying Pan
			{
				if ( give_quota42[client] > 0 || give_quota42[client] < 0) {
					//Give the player a Frying Pan
					FakeClientCommand(client, "give frying_pan");
					//Decrease remaining quota of that player by 1
					give_quota42[client]--;
					//Notify remaining quota
					if (give_quota42[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Frying Pan until next round",give_quota42[client]);
					}
					else if (give_quota42[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Frying Pan until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Frying Pan");
				}
			}
			case 43: // Katana
			{
				if ( give_quota43[client] > 0 || give_quota43[client] < 0) {
					//Give the player a Katana
					FakeClientCommand(client, "give katana");
					//Decrease remaining quota of that player by 1
					give_quota43[client]--;
					//Notify remaining quota
					if (give_quota43[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Katana until next round",give_quota43[client]);
					}
					else if (give_quota43[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Katana until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Katana");
				}
			}
			case 44: // Machete
			{
				if ( give_quota44[client] > 0 || give_quota44[client] < 0) {
					//Give the player a Machete
					FakeClientCommand(client, "give machete");
					//Decrease remaining quota of that player by 1
					give_quota44[client]--;
					//Notify remaining quota
					if (give_quota44[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Machete until next round",give_quota44[client]);
					}
					else if (give_quota44[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Machete until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Machete");
				}
			}			
			case 45: // Tonfa
			{
				if ( give_quota45[client] > 0 || give_quota45[client] < 0) {
					//Give the player a Tonfa
					FakeClientCommand(client, "give tonfa");
					//Decrease remaining quota of that player by 1
					give_quota45[client]--;
					//Notify remaining quota
					if (give_quota45[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Tonfa until next round",give_quota45[client]);
					}
					else if (give_quota45[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Tonfa until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Tonfa");
				}
			}	
			case 46: // Hunting Knife * CSS
			{
				if ( give_quota46[client] > 0 || give_quota46[client] < 0) {
					//Give the player a Hunting Knife
					FakeClientCommand(client, "give hunting_knife");
					//Decrease remaining quota of that player by 1
					give_quota46[client]--;
					//Notify remaining quota
					if (give_quota46[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Hunting Knife until next round",give_quota46[client]);
					}
					else if (give_quota46[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Hunting Knife until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Hunting Knife");
				}
			}
			case 47: // Riot Shield * CSS
			{
				if ( give_quota46[client] > 0 || give_quota46[client] < 0) {
					//Give the player a Riot Shield
					FakeClientCommand(client, "give riotshield");
					//Decrease remaining quota of that player by 1
					give_quota46[client]--;
					//Notify remaining quota
					if (give_quota46[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Riot Shield until next round",give_quota46[client]);
					}
					else if (give_quota46[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Riot Shield until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Riot Shield");
				}
			}
			
			
			
		}
	}
	
	//Add the CHEAT flag back to "give" command
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}
