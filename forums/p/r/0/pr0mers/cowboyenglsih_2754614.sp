#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "pr0mers"
#define PLUGIN_VERSION "1.00"
#define MAX_FILE_LEN 256

#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <console>
#include <string>
#include <sdkhooks>
#include <cstrike>

int dizi[MAXPLAYERS + 1];
int toplamatis[MAXPLAYERS + 1];
int kovboymu = 0;
int hayatta1 = 0;
int hayatta2 = 0;
int birsecim=0;
int ikisecim = 0;
char mapname[128];
public void OnPluginStart()
{
	//RegAdminCmd("sm_kovboy", kovboy, ADMFLAG_ROOT);
	HookEvent("round_end", rndend, EventHookMode_PostNoCopy);
	HookEvent("weapon_fire", wpnfired ,EventHookMode_PostNoCopy);
	HookEvent("player_death", adamolduamk, EventHookMode_PostNoCopy);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(kovboymu == 0){
		return Plugin_Continue;
	}
	else if (kovboymu == 1){
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public OnMapStart(){
	GetCurrentMap(mapname, sizeof(mapname));
	decl String:muzik[MAX_FILE_LEN];
	Format(muzik, sizeof(muzik), "sound/kovboy.mp3");
	if(FileExists(muzik)==true) {
		AddFileToDownloadsTable(muzik);
		PrecacheSound("kovboy.mp3", true);
	}
	else {
		LogError("Not all sound files exists.");
	}

}
public kovboy(int client,int bulduk){
	toplamatis[client]=0;
	toplamatis[bulduk]=0;
	new silah = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(silah != -1){
		RemovePlayerItem(client, silah);
	}
	silah = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(silah != -1){
		RemovePlayerItem(client, silah);
	}
	silah = GetPlayerWeaponSlot(bulduk, CS_SLOT_PRIMARY);
	if(silah != -1){
		RemovePlayerItem(bulduk, silah);
	}
	silah = GetPlayerWeaponSlot(bulduk, CS_SLOT_SECONDARY);
	if(silah != -1){
		RemovePlayerItem(bulduk, silah);
	}
	GivePlayerItem(client, "weapon_deagle");
	GivePlayerItem(bulduk, "weapon_deagle");
	EmitSoundToAll("kovboy.mp3");
	float tp[3];
	float tp2[3];
    if (strncmp(mapname, "awp_lego_2", 10) == 0 )
    {
	    tp[0] = 317.12; 
		tp[1] = -935.39;
		tp[2] = -312.41;
		tp2[0] = -283.12; 
		tp2[1] = -935.39;
		tp2[2] = -312.41; // cl_showpos 1 's z axis - 64. if z = 200 then write here 136
    }
    else if(strncmp(mapname, "aim_redline", 11) == 0 ){
   		tp[0] = -512.14; 
		tp[1] = 635.72;
		tp[2] = 0.09;
		tp2[0] = -512.14; 
		tp2[1] = 130.20;
		tp2[2] = 0.09;
  	}
    else{
   		return;
  	}
	SetEntityMoveType(client, MOVETYPE_NONE);
	TeleportEntity(client, tp, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
	SetEntityMoveType(bulduk, MOVETYPE_NONE);
	TeleportEntity(bulduk, tp2, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
	dizi[client] = 1;
	dizi[bulduk] = 1;
	kovboymu = 1;
	PrintHintTextToAll("Ready!!!");
	int sayi = GetRandomFloat(5.0, 10.0);
	CreateTimer(sayi,kovboykapa);
	
}
public rndend(Handle:event, const String:name[], bool:dontBroadcast){
	kovboymu = 0;
	for (int i = 1; i <= MAXPLAYERS; i++){
		if(dizi[i] !=0 ){
			SetEntityMoveType(i, MOVETYPE_WALK);
			dizi[i] = 0;
		}
	}
}
public wpnfired(Handle:event, const String:name[], bool:dontBroadcast){
	if(kovboymu == 1){
		new user_id = GetEventInt(event, "userid");
		new user = GetClientOfUserId(user_id);
		toplamatis[user]++;
		if(toplamatis[user]==2){
			PrintToChatAll("Player %N is executed because he didn't obey the cowboy duel rules",user);
			ForcePlayerSuicide(user);
		}
		PrintToChat(user, "You will be executed if you dont obey the cowboy duel rules");
	}
}
public adamolduamk(Handle:event, const String:name[], bool:dontBroadcast){
	int kisiler = GetMaxClients();
	int kisisayisi = 0;
	int hayatta = 0;
	for (int i = 1; i <= kisiler; i++)
    {
        if(IsClientInGame(i)==true)
        {
        	kisisayisi++;
            if(IsPlayerAlive(i))
            {
            	if(hayatta1==0){
            		hayatta1 = i;
           		}
           		else{
           			hayatta2 = i;
           		}
            	hayatta++;
            }
        }
    }
    //PrintToChatAll("Toplam kişi: %d, Hayatta olanlar: %d", kisisayisi, hayatta);
    //
    if(hayatta == 2 && (GetClientTeam(hayatta1) != GetClientTeam(hayatta2)) && kisisayisi >=8){
    	    if (strncmp(mapname, "awp_lego_2", 10) == 0 )
		    {
			    menuyap();
		    }
		    else if(strncmp(mapname, "aim_redline", 11) == 0 ){
		   		menuyap();
		  	}
			else{
				sifirla();
			}		    
  	}
  	else{
  		sifirla();
  	}
}
stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
public menuyap(){
	birsecim = 0;
	ikisecim = 0;
	Menu menu = new Menu(Menu_Callback);
	menu.SetTitle("Do you accept the cowboy duel?");
	menu.AddItem("evet", "Yes");
	menu.AddItem("hayır", "No");
	menu.ExitButton = false;
	menu.Display(hayatta1,30);
	menu.Display(hayatta2,30);
}
public int Menu_Callback(Menu menu, MenuAction action,int param1,int param2){
	switch (action){
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item,"evet")){
				PrintToChatAll("Player %N accepted the duel.", param1);
				if(param1==hayatta1){
					birsecim = 1;
				}
				if(param1==hayatta2){
					ikisecim = 1;
				}
				
			}
			if(StrEqual(item,"hayır")){
				PrintToChatAll("Scaredy cat %N didn't accept the cowboy duel.", param1);
				if(param1==hayatta1){
					birsecim = -1;
				}
				if(param1==hayatta2){
					ikisecim = -1;
				}
			}
		}
		case MenuAction_End:
		{		
			//delete menu;			
			if(param1 != MenuEnd_Selected){
				//PrintToChatAll("silindi");
				delete menu;
				PrintToChatAll("Cowboy duel has been cancelled");
				sifirla();
			}
			else if(birsecim != 0 && ikisecim !=0 && birsecim != -1 && ikisecim != -1){
				//PrintToChatAll("silindi1");
				delete menu;
				kovboy(hayatta1, hayatta2);
				sifirla();
			}
			else if(birsecim == -1 || ikisecim == -1){
				//PrintToChatAll("silindi2");
			
				delete menu;
				sifirla();
			}
		}
		case MenuAction_Cancel:
		{
			//PrintToChatAll("Korkak tavuk %N kovboy 1v1ini kabul etmedi.", param1);
		}
		
	}
}
public sifirla(){
	hayatta1 = 0;
 	hayatta2 = 0;
	birsecim=0;
	ikisecim = 0;
}
public Action kovboykapa(Handle timer){
	if(kovboymu ==1){
		PrintHintTextToAll("Go!!!");
	}
	kovboymu = 0;
}
