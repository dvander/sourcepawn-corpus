 /**********Thanks To**************
* {7~11} TROLL for the original plugin
* CrimsonGt - helped {7~11} TROLL with give player item issues
*********************************/
#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.2.1"

new Handle:g_max_give[50];
new max_give[50]; //array for storing initial quota of each item
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
new give_quota48[MAXPLAYERS+1]; //quota left (each player) for item 49
new give_quota49[MAXPLAYERS+1]; //quota left (each player) for item 50

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
	g_max_give[0] = CreateConVar("sm_quota_riflepack", "-1", " Quota Given to each player for obtaining adrenaline in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[1] = CreateConVar("sm_quota_explosivepack", "-1", " Quota Given to each player for obtaining adrenaline in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[2] = CreateConVar("sm_quota_pistolpack", "-1", " Quota Given to each player for obtaining adrenaline in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[3] = CreateConVar("sm_quota_sniperpack", "-1", " Quota Given to each player for obtaining adrenaline in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[4] = CreateConVar("sm_quota_adrenaline", "-1", " Quota Given to each player for obtaining adrenaline in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[5] = CreateConVar("sm_quota_defibrillator", "-1", " Quota Given to each player for obtaining defibrillator in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[6] = CreateConVar("sm_quota_first_aid_kit", "-1", " Quota Given to each player for obtaining first_aid_kit in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[7] = CreateConVar("sm_quota_pain_pills", "-1", " Quota Given to each player for obtaining pain_pills in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[8] = CreateConVar("sm_quota_chainsaw", "-1", " Quota Given to each player for obtaining chainsaw in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[9] = CreateConVar("sm_quota_pumpshotgun", "-1", " Quota Given to each player for obtaining pumpshotgun in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[10] = CreateConVar("sm_quota_autoshotgun", "-1", " Quota Given to each player for obtaining autoshotgun in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[11] = CreateConVar("sm_quota_shotgun_chrome", "-1", " Quota Given to each player for obtaining shotgun_chrome in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[12] = CreateConVar("sm_quota_shotgun_spas", "-1", " Quota Given to each player for obtaining shotgun_spas in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[13] = CreateConVar("sm_quota_pistol", "-1", " Quota Given to each player for obtaining pistol in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[14] = CreateConVar("sm_quota_pistol_magnum", "-1", " Quota Given to each player for obtaining pistol_magnum in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[15] = CreateConVar("sm_quota_hunting_rifle", "-1", " Quota Given to each player for obtaining hunting_rifle in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[16] = CreateConVar("sm_quota_rifle", "-1", " Quota Given to each player for obtaining rifle in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[17] = CreateConVar("sm_quota_rifle_ak47", "-1", " Quota Given to each player for obtaining rifle_ak47 in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[18] = CreateConVar("sm_quota_rifle_desert", "-1", " Quota Given to each player for obtaining rifle_desert in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[19] = CreateConVar("sm_quota_rifle_sg552", "-1", " Quota Given to each player for obtaining rifle_sg552 in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[20] = CreateConVar("sm_quota_smg", "-1", " Quota Given to each player for obtaining smg in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[21] = CreateConVar("sm_quota_smg_mp5", "-1", " Quota Given to each player for obtaining smg_mp5 in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[22] = CreateConVar("sm_quota_smg_silenced", "-1", " Quota Given to each player for obtaining smg_silenced in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[23] = CreateConVar("sm_quota_sniper_awp", "-1", " Quota Given to each player for obtaining sniper_awp in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[24] = CreateConVar("sm_quota_sniper_military", "-1", " Quota Given to each player for obtaining sniper_military in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[25] = CreateConVar("sm_quota_sniper_scout", "-1", " Quota Given to each player for obtaining sniper_scout in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[26] = CreateConVar("sm_quota_grenade_launcher", "-1", " Quota Given to each player for obtaining grenade_launcher in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[27] = CreateConVar("sm_quota_fireworkcrate", "-1", " Quota Given to each player for obtaining fireworkcrate in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[28] = CreateConVar("sm_quota_gascan", "-1", " Quota Given to each player for obtaining gascan in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[29] = CreateConVar("sm_quota_molotov", "-1", " Quota Given to each player for obtaining molotov in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[30] = CreateConVar("sm_quota_oxygentank", "-1", " Quota Given to each player for obtaining oxygentank in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[31] = CreateConVar("sm_quota_propanetank", "-1", " Quota Given to each player for obtaining propanetank in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[32] = CreateConVar("sm_quota_pipe_bomb", "-1", " Quota Given to each player for obtaining pipe_bomb in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[33] = CreateConVar("sm_quota_vomitjar", "-1", " Quota Given to each player for obtaining vomitjar in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[34] = CreateConVar("sm_quota_gnome", "-1", " Quota Given to each player for obtaining gnome in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[35] = CreateConVar("sm_quota_upgradepack_incendiary", "-1", " Quota Given to each player for obtaining upgradepack_incendiary in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[36] = CreateConVar("sm_quota_upgradepack_explosive", "-1", " Quota Given to each player for obtaining upgradepack_explosive in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[37] = CreateConVar("sm_quota_baseball_bat", "-1", " Quota Given to each player for obtaining baseball_bat in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[38] = CreateConVar("sm_quota_cricket_bat", "-1" ," Quota Given to each player for obtaining cricket_bat in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[39] = CreateConVar("sm_quota_crowbar", "-1", " Quota Given to each player for obtaining crowbar in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[40] = CreateConVar("sm_quota_electric_guitar", "-1", " Quota Given to each player for obtaining electric_guitar in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[41] = CreateConVar("sm_quota_fireaxe", "-1", " Quota Given to each player for obtaining fireaxe in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[42] = CreateConVar("sm_quota_frying_pan", "-1", " Quota Given to each player for obtaining frying_pan in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[43] = CreateConVar("sm_quota_katana", "-1", " Quota Given to each player for obtaining katana in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[44] = CreateConVar("sm_quota_machete", "-1", " Quota Given to each player for obtaining machete in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[45] = CreateConVar("sm_quota_tonfa", "-1", " Quota Given to each player for obtaining tonfa in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[46] = CreateConVar("sm_quota_knife", "-1", " Quota Given to each player for obtaining knife in each round ( -1 = unlimited 0 = disabled )");	
	g_max_give[47] = CreateConVar("sm_quota_golfclub", "-1", " Quota Given to each player for obtaining golfclub in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[48] = CreateConVar("sm_quota_riotshield", "-1", " Quota Given to each player for obtaining riotshield in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[49] = CreateConVar("sm_quota_rifle_m60", "-1", " Quota Given to each player for obtaining rifle_m60 in each round ( -1 = unlimited 0 = disabled )");


	//Execute or create cfg
	AutoExecConfig(true, "Tankbuster_2_Quota");	
	
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
	max_give[48] = GetConVarInt(g_max_give[48]);
	max_give[49] = GetConVarInt(g_max_give[49]);
	
	
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
		give_quota48[client] = max_give[48];
		give_quota49[client] = max_give[49];
		
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
	max_give[48] = GetConVarInt(g_max_give[48]);
	max_give[49] = GetConVarInt(g_max_give[49]);
	
	
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
	give_quota48[client] = max_give[48];
	give_quota49[client] = max_give[49];
	
}

public Action:TankBusterMenu(client,args)
{
	TankBuster(client);
	return Plugin_Handled;
}

public Action:TankBuster(clientId) {
	new Handle:menu = CreateMenu(TankBusterMenuHandler);
	SetMenuTitle(menu, "TankBuster 2 Weapons Menu");
	AddMenuItem(menu, "option0", "Rifle Package");
	AddMenuItem(menu, "option1", "Explosive Package");
	AddMenuItem(menu, "option2", "Pistol Package");
	AddMenuItem(menu, "option3", "Sniper Package");
	AddMenuItem(menu, "option4", "Adrenaline");
	AddMenuItem(menu, "option5", "Defibrillator");
	AddMenuItem(menu, "option6", "First Aid Kit");
	AddMenuItem(menu, "option7", "Pain Pills");
	AddMenuItem(menu, "option8", "Chainsaw");
	AddMenuItem(menu, "option9", "Shotgun");
	AddMenuItem(menu, "option10", "Autoshotgun");
	AddMenuItem(menu, "option11", "Shotgun Chrome");
	AddMenuItem(menu, "option12", "Shotgun Spas");
	AddMenuItem(menu, "option13", "Pistol");
	AddMenuItem(menu, "option14", "Pistol Magnum");
	AddMenuItem(menu, "option15", "Hunting Rifle");
	AddMenuItem(menu, "option16", "Rifle M4 ");
	AddMenuItem(menu, "option17", "Rifle AK47");
	AddMenuItem(menu, "option18", "Rifle Desert");
	AddMenuItem(menu, "option19", "Rifle SG552");
	AddMenuItem(menu, "option20", "SMG");
	AddMenuItem(menu, "option21", "SMG MP5");
	AddMenuItem(menu, "option22", "SMG Silenced");
	AddMenuItem(menu, "option23", "Sniper AWP");
	AddMenuItem(menu, "option24", "Sniper Military");
	AddMenuItem(menu, "option25", "Sniper Scout");
	AddMenuItem(menu, "option26", "Grenade Launcher");
	AddMenuItem(menu, "option27", "Fireworkcrate");
	AddMenuItem(menu, "option28", "Gascan");
	AddMenuItem(menu, "option29", "Molotov");
	AddMenuItem(menu, "option30", "Oxygentank");
	AddMenuItem(menu, "option31", "Propanetank");
	AddMenuItem(menu, "option32", "Pipe Bomb");
	AddMenuItem(menu, "option33", "Vomit Jar");
	AddMenuItem(menu, "option34", "Gnome");
	AddMenuItem(menu, "option35", "Upgradepack Incendiary");
	AddMenuItem(menu, "option36", "Upgradepack Explosive");
	AddMenuItem(menu, "option37", "Baseball Bat * Only if level allows");
	AddMenuItem(menu, "option38", "Cricket Bat * Only if level allows");
	AddMenuItem(menu, "option39", "Crowbar * Only if level allows");
	AddMenuItem(menu, "option40", "Electric Guitar * Only if level allows");
	AddMenuItem(menu, "option41", "Fireaxe * Only if level allows");
	AddMenuItem(menu, "option42", "Frying Pan * Only if level allows");
	AddMenuItem(menu, "option43", "Katana * Only if level allows");
	AddMenuItem(menu, "option44", "Machete * Only if level allows");
	AddMenuItem(menu, "option45", "Tonfa * Only if level allows");
	AddMenuItem(menu, "option46", "Knife * Only if level allows");
	AddMenuItem(menu, "option47", "Golf Club * Only if level allows");
	AddMenuItem(menu, "option48", "Riot Shield * CSS * Only if level allows");
	AddMenuItem(menu, "option49", "M60 Machine Gun");
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
			
			
			case 0: //Rifle Pack
			{
				if ( give_quota0[client] > 0 || give_quota0[client] < 0) {
					//Give the player a Rifle Pack
					FakeClientCommand(client, "give rifle");
					FakeClientCommand(client, "give pistol_magnum");
					FakeClientCommand(client, "give pipe_bomb");
					FakeClientCommand(client, "give fireworkcrate");
					FakeClientCommand(client, "give first_aid_kit");
					FakeClientCommand(client, "give adrenaline");
					FakeClientCommand(client, "give defibrillator");
					FakeClientCommand(client, "give upgradepack_incendiary");
					FakeClientCommand(client, "give upgradepack_explosive");
					FakeClientCommand(client, "give katana");
					FakeClientCommand(client, "give baseball_bat");
					FakeClientCommand(client, "give vomit_jar");
					//Decrease remaining quota of that player by 1
					give_quota0[client]--;
					//Notify remaining quota
					if (give_quota0[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Rifle Pack until next round",give_quota0[client]);
					}
					else if (give_quota0[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Rifle Packs until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Rifle Pack");
				}
			}
			case 1: //Explosive Pack
			{
				if ( give_quota1[client] > 0 || give_quota1[client] < 0) {
					//Give the player a Explosive Pack
					FakeClientCommand(client, "give adrenaline");
					FakeClientCommand(client, "give pistol_magnum");
					FakeClientCommand(client, "give grenade_launcher");
					FakeClientCommand(client, "give molotov");
					FakeClientCommand(client, "give fireworkcrate");
					FakeClientCommand(client, "give first_aid_kit");
					FakeClientCommand(client, "give adrenaline");	
					FakeClientCommand(client, "give defibrillator");	
					FakeClientCommand(client, "give upgradepack_incendiary");
					FakeClientCommand(client, "give upgradepack_explosive");
					FakeClientCommand(client, "give katana");
					FakeClientCommand(client, "give baseball_bat");
					FakeClientCommand(client, "give vomit_jar");
					//Decrease remaining quota of that player by 1
					give_quota1[client]--;
					//Notify remaining quota
					if (give_quota1[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Explosive Pack until next round",give_quota1[client]);
					}
					else if (give_quota1[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Explosive Pack until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Explosive Pack");
				}
			}
			case 2: // Pistols Pack
			{
				if ( give_quota2[client] > 0 || give_quota2[client] < 0) {
					//Give the player a Pistols Pack
					FakeClientCommand(client, "give pistol");
					FakeClientCommand(client, "give pistol");
					FakeClientCommand(client, "give pistol_magnum");
					FakeClientCommand(client, "give pistol_magnum");
					FakeClientCommand(client, "give pipe_bomb");
					FakeClientCommand(client, "give first_aid_kit");
					FakeClientCommand(client, "give adrenaline");
					FakeClientCommand(client, "give defibrillator");
					FakeClientCommand(client, "give upgradepack_incendiary");
					FakeClientCommand(client, "give upgradepack_explosive");
					FakeClientCommand(client, "give katana");
					FakeClientCommand(client, "give baseball_bat");
					FakeClientCommand(client, "give vomit_jar");
					//Decrease remaining quota of that player by 1
					give_quota2[client]--;
					//Notify remaining quota
					if (give_quota2[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Pistols Pack until next round",give_quota2[client]);
					}
					else if (give_quota2[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Pistols Pack until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Pistols Pack");
				}
			}
			case 3: // Sniper Pack
			{
				if ( give_quota3[client] > 0 || give_quota3[client] < 0) {
					//Give the player a Sniper Pack
					FakeClientCommand(client, "give sniper_military");
					FakeClientCommand(client, "give pistol_magnum");
					FakeClientCommand(client, "give pipe_bomb");
					FakeClientCommand(client, "give first_aid_kit");
					FakeClientCommand(client, "give adrenaline");
					FakeClientCommand(client, "give defibrillator");
					FakeClientCommand(client, "give upgradepack_incendiary");
					FakeClientCommand(client, "give upgradepack_explosive");
					FakeClientCommand(client, "give katana");
					FakeClientCommand(client, "give baseball_bat");
					FakeClientCommand(client, "give vomit_jar");
					//Decrease remaining quota of that player by 1
					give_quota3[client]--;
					//Notify remaining quota
					if (give_quota3[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Sniper Pack until next round",give_quota3[client]);
					}
					else if (give_quota3[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Sniper Pack until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Sniper Pack");
				}
			}
			case 4: //adrenaline
			{
				if ( give_quota4[client] > 0 || give_quota4[client] < 0) {
					//Give the player a adrenaline
					FakeClientCommand(client, "give adrenaline");
					//Decrease remaining quota of that player by 1
					give_quota4[client]--;
					//Notify remaining quota
					if (give_quota4[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an adrenaline until next round",give_quota4[client]);
					}
					else if (give_quota4[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore adrenaline until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an adrenaline");
				}
			}
			case 5: //defibrillator
			{
				if ( give_quota5[client] > 0 || give_quota5[client] < 0) {
					//Give the player a pistol
					FakeClientCommand(client, "give defibrillator");
					//Decrease remaining quota of that player by 1
					give_quota5[client]--;
					//Notify remaining quota
					if (give_quota5[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a defibrillator until next round",give_quota5[client]);
					}
					else if (give_quota5[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore defibrillator until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a defibrillator");
				}
			}
			case 6: //first_aid_kit
			{
				if ( give_quota6[client] > 0 || give_quota6[client] < 0) {
					//Give the player a first_aid_kit
					FakeClientCommand(client, "give first_aid_kit");
					//Decrease remaining quota of that player by 1
					give_quota6[client]--;
					//Notify remaining quota
					if (give_quota6[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a first_aid_kit until next round",give_quota6[client]);
					}
					else if (give_quota6[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore first_aid_kit until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a first_aid_kit");
				}
			}
			case 7: //pain_pills
			{
				if ( give_quota7[client] > 0 || give_quota7[client] < 0) {
					//Give the player a pain_pills
					FakeClientCommand(client, "give pain_pills");
					//Decrease remaining quota of that player by 1
					give_quota7[client]--;
					//Notify remaining quota
					if (give_quota7[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a pain_pills until next round",give_quota7[client]);
					}
					else if (give_quota7[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore pain_pills until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a pain_pills ");
				}
			}
			case 8: //chainsaw
			{
				if ( give_quota8[client] > 0 || give_quota8[client] < 0) {
					//Give the player chainsaw
					FakeClientCommand(client, "give chainsaw");
					//Decrease remaining quota of that player by 1
					give_quota8[client]--;
					//Notify remaining quota
					if (give_quota8[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain chainsaw until next round",give_quota8[client]);
					}
					else if (give_quota8[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore chainsaw until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain chainsaw");
				}
			}
			case 9: //pumpshotgun
			{
				if ( give_quota9[client] > 0 || give_quota9[client] < 0) {
					//Give the player pumpshotgun
					FakeClientCommand(client, "give pumpshotgun");
					//Decrease remaining quota of that player by 1
					give_quota9[client]--;
					//Notify remaining quota
					if (give_quota9[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain pumpshotgun until next round",give_quota9[client]);
					}
					else if (give_quota9[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore pumpshotgun until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain pumpshotgun");
				}
			}
			case 10: // autoshotgun
			{
				if ( give_quota10[client] > 0 || give_quota10[client] < 0) {
					//Give the player a autoshotgun
					FakeClientCommand(client, "give autoshotgun");
					//Decrease remaining quota of that player by 1
					give_quota10[client]--;
					//Notify remaining quota
					if (give_quota10[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a autoshotgun until next round",give_quota10[client]);
					}
					else if (give_quota10[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore autoshotgun until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a autoshotgun");
				}
			}
			case 11: // shotgun_chrome
			{
				if ( give_quota10[client] > 0 || give_quota11[client] < 0) {
					//Give the player a autoshotgun
					FakeClientCommand(client, "give shotgun_chrome");
					//Decrease remaining quota of that player by 1
					give_quota11[client]--;
					//Notify remaining quota
					if (give_quota11[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a shotgun_chrome until next round",give_quota11[client]);
					}
					else if (give_quota10[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore shotgun_chrome until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a shotgun_chrome");
				}
			}
			case 12: // shotgun_spas
			{
				if ( give_quota12[client] > 0 || give_quota12[client] < 0) {
					//Give the player a shotgun_spas
					FakeClientCommand(client, "give shotgun_spas");
					//Decrease remaining quota of that player by 1
					give_quota12[client]--;
					//Notify remaining quota
					if (give_quota12[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a shotgun_spas until next round",give_quota12[client]);
					}
					else if (give_quota12[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore shotgun_spas until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a shotgun_spas");
				}
			}
			case 13: // pistol
			{
				if ( give_quota13[client] > 0 || give_quota13[client] < 0) {
					//Give the player a pistol
					FakeClientCommand(client, "give pistol");
					//Decrease remaining quota of that player by 1
					give_quota13[client]--;
					//Notify remaining quota
					if (give_quota13[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a pistol until next round",give_quota13[client]);
					}
					else if (give_quota13[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore pistol until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a pistol");
				}
			}
			case 14: // pistol_magnum
			{
				if ( give_quota14[client] > 0 || give_quota14[client] < 0) {
					//Give the player a pistol_magnum
					FakeClientCommand(client, "give pistol_magnum");
					//Decrease remaining quota of that player by 1
					give_quota14[client]--;
					//Notify remaining quota
					if (give_quota14[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a pistol_magnum until next round",give_quota14[client]);
					}
					else if (give_quota14[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore pistol_magnum until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a pistol_magnum");
				}
			}
			case 15: // hunting_rifle
			{
				if ( give_quota15[client] > 0 || give_quota15[client] < 0) {
					//Give the player a hunting_rifle
					FakeClientCommand(client, "give hunting_rifle");
					//Decrease remaining quota of that player by 1
					give_quota15[client]--;
					//Notify remaining quota
					if (give_quota15[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a hunting_rifle until next round",give_quota15[client]);
					}
					else if (give_quota15[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore hunting_rifle until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a hunting_rifle");
				}
			}
			case 16: // rifle
			{
				if ( give_quota16[client] > 0 || give_quota16[client] < 0) {
					//Give the player a rifle
					FakeClientCommand(client, "give rifle");
					//Decrease remaining quota of that player by 1
					give_quota16[client]--;
					//Notify remaining quota
					if (give_quota16[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a rifle until next round",give_quota16[client]);
					}
					else if (give_quota10[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore rifle until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a rifle");
				}
			}
			case 17: // rifle_ak47
			{
				if ( give_quota17[client] > 0 || give_quota17[client] < 0) {
					//Give the player a rifle_ak47
					FakeClientCommand(client, "give rifle_ak47");
					//Decrease remaining quota of that player by 1
					give_quota17[client]--;
					//Notify remaining quota
					if (give_quota17[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a rifle_ak47 until next round",give_quota17[client]);
					}
					else if (give_quota17[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore rifle_ak47 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a rifle_ak47");
				}
			}
			case 18: // rifle_desert
			{
				if ( give_quota18[client] > 0 || give_quota18[client] < 0) {
					//Give the player a rifle_desert
					FakeClientCommand(client, "give rifle_desert");
					//Decrease remaining quota of that player by 1
					give_quota18[client]--;
					//Notify remaining quota
					if (give_quota18[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a rifle_desert until next round",give_quota18[client]);
					}
					else if (give_quota18[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore rifle_desert until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a rifle_desert");
				}
			}
			case 19: // rifle_sg552
			{
				if ( give_quota19[client] > 0 || give_quota19[client] < 0) {
					//Give the player a rifle_sg552
					FakeClientCommand(client, "give rifle_sg552");
					//Decrease remaining quota of that player by 1
					give_quota19[client]--;
					//Notify remaining quota
					if (give_quota19[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a rifle_sg552 until next round",give_quota19[client]);
					}
					else if (give_quota19[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore rifle_sg552 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a rifle_sg552");
				}
			}
			case 20: // smg
			{
				if ( give_quota20[client] > 0 || give_quota20[client] < 0) {
					//Give the player a smg
					FakeClientCommand(client, "give smg");
					//Decrease remaining quota of that player by 1
					give_quota20[client]--;
					//Notify remaining quota
					if (give_quota20[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a smg until next round",give_quota20[client]);
					}
					else if (give_quota20[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore smg until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a smg");
				}
			}
			case 21: // smg_mp5
			{
				if ( give_quota21[client] > 0 || give_quota21[client] < 0) {
					//Give the player a smg_mp5
					FakeClientCommand(client, "give smg_mp5");
					//Decrease remaining quota of that player by 1
					give_quota21[client]--;
					//Notify remaining quota
					if (give_quota21[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a smg_mp5 until next round",give_quota21[client]);
					}
					else if (give_quota21[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore smg_mp5 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a smg_mp5");
				}
			}
			case 22: // smg_silenced
			{
				if ( give_quota22[client] > 0 || give_quota22[client] < 0) {
					//Give the player a smg_silenced
					FakeClientCommand(client, "give smg_silenced");
					//Decrease remaining quota of that player by 1
					give_quota22[client]--;
					//Notify remaining quota
					if (give_quota22[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a smg_silenced until next round",give_quota22[client]);
					}
					else if (give_quota22[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore smg_silenced until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a smg_silenced");
				}
			}
			case 23: // sniper_awp
			{
				if ( give_quota23[client] > 0 || give_quota23[client] < 0) {
					//Give the player a sniper_awp
					FakeClientCommand(client, "give sniper_awp");
					//Decrease remaining quota of that player by 1
					give_quota23[client]--;
					//Notify remaining quota
					if (give_quota23[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a sniper_awp until next round",give_quota23[client]);
					}
					else if (give_quota23[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore sniper_awp until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a sniper_awp");
				}
			}
			case 24: // sniper_military
			{
				if ( give_quota24[client] > 0 || give_quota24[client] < 0) {
					//Give the player a sniper_military
					FakeClientCommand(client, "give sniper_military");
					//Decrease remaining quota of that player by 1
					give_quota24[client]--;
					//Notify remaining quota
					if (give_quota24[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a sniper_military until next round",give_quota24[client]);
					}
					else if (give_quota24[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore sniper_military until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a sniper_military");
				}
			}
			case 25: // sniper_scout
			{
				if ( give_quota25[client] > 0 || give_quota25[client] < 0) {
					//Give the player a sniper_scout
					FakeClientCommand(client, "give sniper_scout");
					//Decrease remaining quota of that player by 1
					give_quota25[client]--;
					//Notify remaining quota
					if (give_quota25[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a sniper_scout until next round",give_quota25[client]);
					}
					else if (give_quota25[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore sniper_scout until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a sniper_scout");
				}
			}
			case 26: // grenade_launcher
			{
				if ( give_quota26[client] > 0 || give_quota26[client] < 0) {
					//Give the player a grenade_launcher
					FakeClientCommand(client, "give grenade_launcher");
					//Decrease remaining quota of that player by 1
					give_quota26[client]--;
					//Notify remaining quota
					if (give_quota26[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a grenade_launcher until next round",give_quota26[client]);
					}
					else if (give_quota26[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore grenade_launcher until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a grenade_launcher");
				}
			}
			case 27: // fireworkcrate
			{
				if ( give_quota27[client] > 0 || give_quota27[client] < 0) {
					//Give the player a fireworkcrate
					FakeClientCommand(client, "give fireworkcrate");
					//Decrease remaining quota of that player by 1
					give_quota27[client]--;
					//Notify remaining quota
					if (give_quota27[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a fireworkcrate until next round",give_quota27[client]);
					}
					else if (give_quota27[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore fireworkcrate until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a fireworkcrate");
				}
			}
			case 28: // gascan
			{
				if ( give_quota28[client] > 0 || give_quota28[client] < 0) {
					//Give the player a gascan
					FakeClientCommand(client, "give gascan");
					//Decrease remaining quota of that player by 1
					give_quota28[client]--;
					//Notify remaining quota
					if (give_quota28[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a gascan until next round",give_quota28[client]);
					}
					else if (give_quota28[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore gascan until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a gascan");
				}
			}
			case 29: // molotov
			{
				if ( give_quota29[client] > 0 || give_quota29[client] < 0) {
					//Give the player a molotov
					FakeClientCommand(client, "give molotov");
					//Decrease remaining quota of that player by 1
					give_quota29[client]--;
					//Notify remaining quota
					if (give_quota29[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a molotov until next round",give_quota29[client]);
					}
					else if (give_quota29[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore molotov until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a molotov");
				}
			}
			case 30: // oxygentank
			{
				if ( give_quota30[client] > 0 || give_quota30[client] < 0) {
					//Give the player a oxygentank
					FakeClientCommand(client, "give oxygentank");
					//Decrease remaining quota of that player by 1
					give_quota30[client]--;
					//Notify remaining quota
					if (give_quota30[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a oxygentank until next round",give_quota30[client]);
					}
					else if (give_quota30[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore oxygentank until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a oxygentank");
				}
			}
			case 31: // propanetank
			{
				if ( give_quota31[client] > 0 || give_quota31[client] < 0) {
					//Give the player a propanetank
					FakeClientCommand(client, "give propanetank");
					//Decrease remaining quota of that player by 1
					give_quota31[client]--;
					//Notify remaining quota
					if (give_quota31[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a propanetank until next round",give_quota31[client]);
					}
					else if (give_quota31[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore propanetank until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a propanetank");
				}
			}
			case 32: // pipe_bomb
			{
				if ( give_quota32[client] > 0 || give_quota32[client] < 0) {
					//Give the player a pipe_bomb
					FakeClientCommand(client, "give pipe_bomb");
					//Decrease remaining quota of that player by 1
					give_quota32[client]--;
					//Notify remaining quota
					if (give_quota32[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a pipe_bomb until next round",give_quota32[client]);
					}
					else if (give_quota32[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore pipe_bomb until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a pipe_bomb");
				}
			}
			case 33: // vomitjar
			{
				if ( give_quota33[client] > 0 || give_quota33[client] < 0) {
					//Give the player a vomitjar
					FakeClientCommand(client, "give vomitjar");
					//Decrease remaining quota of that player by 1
					give_quota33[client]--;
					//Notify remaining quota
					if (give_quota33[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a vomitjar until next round",give_quota33[client]);
					}
					else if (give_quota33[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore vomitjar until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a vomitjar");
				}
			}
			case 34: // gnome
			{
				if ( give_quota34[client] > 0 || give_quota34[client] < 0) {
					//Give the player a gnome
					FakeClientCommand(client, "give gnome");
					//Decrease remaining quota of that player by 1
					give_quota34[client]--;
					//Notify remaining quota
					if (give_quota34[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a gnome until next round",give_quota34[client]);
					}
					else if (give_quota34[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore gnome until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a gnome");
				}
			}
			case 35: // upgradepack_incendiary
			{
				if ( give_quota35[client] > 0 || give_quota35[client] < 0) {
					//Give the player a autoshotgun
					FakeClientCommand(client, "give upgradepack_incendiary");
					//Decrease remaining quota of that player by 1
					give_quota35[client]--;
					//Notify remaining quota
					if (give_quota35[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a upgradepack_incendiary until next round",give_quota35[client]);
					}
					else if (give_quota35[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore upgradepack_incendiary until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a upgradepack_incendiary");
				}
			}
			case 36: // upgradepack_explosive
			{
				if ( give_quota36[client] > 0 || give_quota36[client] < 0) {
					//Give the player a upgradepack_explosive
					FakeClientCommand(client, "give upgradepack_explosive");
					//Decrease remaining quota of that player by 1
					give_quota36[client]--;
					//Notify remaining quota
					if (give_quota36[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a upgradepack_explosive until next round",give_quota36[client]);
					}
					else if (give_quota36[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore upgradepack_explosive until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a upgradepack_explosive");
				}
			}
			case 37: // baseball_bat
			{
				if ( give_quota37[client] > 0 || give_quota37[client] < 0) {
					//Give the player a baseball_bat
					FakeClientCommand(client, "give baseball_bat");
					//Decrease remaining quota of that player by 1
					give_quota37[client]--;
					//Notify remaining quota
					if (give_quota37[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a baseball_bat until next round",give_quota37[client]);
					}
					else if (give_quota37[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore baseball_bat until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a baseball_bat");
				}
			}
			case 38: // baseball_bat
			{
				if ( give_quota38[client] > 0 || give_quota38[client] < 0) {
					//Give the player a baseball_bat
					FakeClientCommand(client, "give baseball_bat");
					//Decrease remaining quota of that player by 1
					give_quota38[client]--;
					//Notify remaining quota
					if (give_quota38[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a baseball_bat until next round",give_quota38[client]);
					}
					else if (give_quota38[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore baseball_bat until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a baseball_bat");
				}
			}
			case 39: // crowbar
			{
				if ( give_quota39[client] > 0 || give_quota39[client] < 0) {
					//Give the player a crowbar
					FakeClientCommand(client, "give crowbar");
					//Decrease remaining quota of that player by 1
					give_quota39[client]--;
					//Notify remaining quota
					if (give_quota39[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a crowbar until next round",give_quota39[client]);
					}
					else if (give_quota39[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore crowbar until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a crowbar");
				}
			}
			case 40: // electric_guitar
			{
				if ( give_quota40[client] > 0 || give_quota40[client] < 0) {
					//Give the player a autoshotgun
					FakeClientCommand(client, "give electric_guitar");
					//Decrease remaining quota of that player by 1
					give_quota40[client]--;
					//Notify remaining quota
					if (give_quota40[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a electric_guitar until next round",give_quota40[client]);
					}
					else if (give_quota40[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore electric_guitar until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a electric_guitar");
				}
			}
			case 41: // fireaxe
			{
				if ( give_quota41[client] > 0 || give_quota41[client] < 0) {
					//Give the player a fireaxe
					FakeClientCommand(client, "give fireaxe");
					//Decrease remaining quota of that player by 1
					give_quota41[client]--;
					//Notify remaining quota
					if (give_quota41[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a fireaxe until next round",give_quota41[client]);
					}
					else if (give_quota41[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore fireaxe until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a fireaxe");
				}
			}
			case 42: // frying_pan
			{
				if ( give_quota42[client] > 0 || give_quota42[client] < 0) {
					//Give the player a frying_pan
					FakeClientCommand(client, "give frying_pan");
					//Decrease remaining quota of that player by 1
					give_quota42[client]--;
					//Notify remaining quota
					if (give_quota42[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a frying_pan until next round",give_quota42[client]);
					}
					else if (give_quota42[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore frying_pan until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a frying_pan");
				}
			}
			case 43: // katana
			{
				if ( give_quota43[client] > 0 || give_quota43[client] < 0) {
					//Give the player a katana
					FakeClientCommand(client, "give katana");
					//Decrease remaining quota of that player by 1
					give_quota43[client]--;
					//Notify remaining quota
					if (give_quota43[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a katana until next round",give_quota43[client]);
					}
					else if (give_quota43[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore katana until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a katana");
				}
			}
			case 44: // machete
			{
				if ( give_quota44[client] > 0 || give_quota44[client] < 0) {
					//Give the player a machete
					FakeClientCommand(client, "give machete");
					//Decrease remaining quota of that player by 1
					give_quota44[client]--;
					//Notify remaining quota
					if (give_quota44[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a machete until next round",give_quota44[client]);
					}
					else if (give_quota44[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore machete until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a machete");
				}
			}			
			case 45: // tonfa
			{
				if ( give_quota45[client] > 0 || give_quota45[client] < 0) {
					//Give the player a tonfa
					FakeClientCommand(client, "give tonfa");
					//Decrease remaining quota of that player by 1
					give_quota45[client]--;
					//Notify remaining quota
					if (give_quota45[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a tonfa until next round",give_quota45[client]);
					}
					else if (give_quota45[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore tonfa until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a tonfa");
				}
			}	
			case 46: // knife
			{
				if ( give_quota46[client] > 0 || give_quota46[client] < 0) {
					//Give the player a knife
					FakeClientCommand(client, "give knife");
					//Decrease remaining quota of that player by 1
					give_quota46[client]--;
					//Notify remaining quota
					if (give_quota46[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a knife until next round",give_quota46[client]);
					}
					else if (give_quota46[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore knife until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a knife");
				}
			}
			case 47: // Golf Club
			{
				if ( give_quota47[client] > 0 || give_quota47[client] < 0) {
					//Give the player a Golf Club
					FakeClientCommand(client, "give golfclub");
					//Decrease remaining quota of that player by 1
					give_quota47[client]--;
					//Notify remaining quota
					if (give_quota47[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Golf Club until next round",give_quota47[client]);
					}
					else if (give_quota47[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Golf Club until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Golf Club");
				}
			}
			case 48: // Riot Shield * CSS
			{
				if ( give_quota48[client] > 0 || give_quota48[client] < 0) {
					//Give the player a Riot Shield
					FakeClientCommand(client, "give riotshield");
					//Decrease remaining quota of that player by 1
					give_quota48[client]--;
					//Notify remaining quota
					if (give_quota48[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Riot Shield until next round",give_quota48[client]);
					}
					else if (give_quota48[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Riot Shield until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Riot Shield");
				}
			}
			case 49: // M60 machine gun
			{
				if ( give_quota49[client] > 0 || give_quota49[client] < 0) {
					//Give the player an M60
					FakeClientCommand(client, "give rifle_m60");
					//Decrease remaining quota of that player by 1
					give_quota49[client]--;
					//Notify remaining quota
					if (give_quota49[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an M60 until next round",give_quota49[client]);
					}
					else if (give_quota49[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore M60 until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an M60");
				}
			}
			
			
			
		}
	}
	
	//Add the CHEAT flag back to "give" command
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}
