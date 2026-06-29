#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "pr0mers"
#define PLUGIN_VERSION "1.00"
#define MAX_FILE_LEN 256
#define MIN_FLOAT -2147483647.0

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
int birsecim = 0;
int ikisecim = 0;

float SpawnPosition[MAXPLAYERS + 1][3];

char mapname[128];

public void OnPluginStart()
{
	//RegAdminCmd("sm_kovboy", kovboy, ADMFLAG_ROOT);
	HookEvent("round_end", rndend, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("weapon_fire", wpnfired ,EventHookMode_Post);
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
		
	if(client == 0 || bulduk == 0)
		return;
		
	/*if(IsNullVector(SpawnPosition[client]))
	{
		sifirla();
		return;
	}
	*/
	float buldukOrigin[3];
	
	buldukOrigin = SpawnPosition[client];
	
	buldukOrigin[0] += 128.0;

	
	if(IsPlayerStuck(bulduk, buldukOrigin))
		buldukOrigin[0] -= 256.0;
	
	if(IsPlayerStuck(bulduk, buldukOrigin))
	{
		buldukOrigin = SpawnPosition[client];
		
		buldukOrigin[1] += 128.0;
	}
	
	if(IsPlayerStuck(bulduk, buldukOrigin))
	{
		buldukOrigin = SpawnPosition[client];
		
		buldukOrigin[1] -= 256.0;
	}
	
	if(IsPlayerStuck(bulduk, buldukOrigin))
	{
		PrintToChatAll("Could not start Cowboy Duel for technical and rare reasons!");
		sifirla();
		return;
	}
		
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
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityMoveType(bulduk, MOVETYPE_NONE);
	
	TeleportEntity(client, SpawnPosition[client], NULL_VECTOR, Float:{0.0, 0.0, 0.0});
	TeleportEntity(bulduk, buldukOrigin, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
	
	TeleportToGround(bulduk);
	
	LookAtClient(client, bulduk);
	LookAtClient(bulduk, client);
	
	dizi[client] = 1;
	dizi[bulduk] = 1;
	kovboymu = 1;
	PrintHintTextToAll("Ready!!!");
	float sayi = GetRandomFloat(5.0, 10.0);
	CreateTimer(sayi,kovboykapa);
	
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == 0)
		return;
		
	RequestFrame(Frame_PlayerSpawn, client);
}

public Frame_PlayerSpawn(client)
{
	if(!IsClientInGame(client)) // Cannot be replaced in one frame, Userid is not necessary.
		return;
		
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", SpawnPosition[client]);
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
	int kisisayisi = 0;
	int hayatta = 0;
	for (int i = 1; i <= MaxClients; i++)
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
	if(hayatta == 2 && (GetClientTeam(hayatta1) != GetClientTeam(hayatta2)) && kisisayisi >= 3){
		menuyap();    
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
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	menu.Display(hayatta1,30);
	
	Menu menu2 = new Menu(Menu_Callback);
	menu2.SetTitle("Do you accept the cowboy duel?");
	menu2.AddItem("", "Yes");
	menu2.AddItem("", "No");
	menu2.ExitButton = false;
	menu2.Display(hayatta2,30);
}
public int Menu_Callback(Menu menu, MenuAction action, int param1, int param2){
	switch (action){
		case MenuAction_Select:
		{
			if(param2 == 0)
			{
				PrintToChatAll("Player %N accepted the duel.", param1);
				
				if(param1==hayatta1)
				{
					birsecim = 1;
					
				}
				if(param1==hayatta2)
				{
					ikisecim = 1;
				}				
			}
			else
			{
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


stock bool IsPlayerStuck(int client, const float Origin[3] = NULL_VECTOR, float HeightOffset = 0.0)
{
	float vecMin[3], vecMax[3], vecOrigin[3];
	
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
    
	if(IsNullVector(Origin))
	{
		GetClientAbsOrigin(client, vecOrigin);
		
		vecOrigin[2] += HeightOffset;
	}	
	else
	{
		vecOrigin = Origin;
		
		vecOrigin[2] += HeightOffset;
    }
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayDontHitPlayers);
	return TR_DidHit();
}

stock void TeleportToGround(int client)
{
	float vecMin[3], vecMax[3], vecOrigin[3], vecFakeOrigin[3];
    
	GetClientMins(client, vecMin);
	GetClientMaxs(client, vecMax);
    
	GetClientAbsOrigin(client, vecOrigin);
	vecFakeOrigin = vecOrigin;
	
	vecFakeOrigin[2] = MIN_FLOAT;
    
	TR_TraceHullFilter(vecOrigin, vecFakeOrigin, vecMin, vecMax, MASK_PLAYERSOLID, TraceRayDontHitPlayers);
	
	TR_GetEndPosition(vecOrigin);
	
	TeleportEntity(client, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityFlags(client, GetEntityFlags(client) & FL_ONGROUND); // Backup...
}

public bool TraceRayDontHitPlayers(int entityhit, int mask) 
{
    return (entityhit>MaxClients || entityhit == 0);
}

//Taken from https://github.com/Franc1sco/aimbot/blob/master/scripting/aimbot.sp

stock void LookAtClient(int iClient, int iTarget)
{
	float fTargetPos[3]; float fTargetAngles[3]; float fClientPos[3]; float fFinalPos[3];
	GetClientEyePosition(iClient, fClientPos);
	GetClientEyePosition(iTarget, fTargetPos);
	GetClientEyeAngles(iTarget, fTargetAngles);
	
	float fVecFinal[3];
	AddInFrontOf(fTargetPos, fTargetAngles, 7.0, fVecFinal);
	MakeVectorFromPoints(fClientPos, fVecFinal, fFinalPos);
	
	GetVectorAngles(fFinalPos, fFinalPos);

	fFinalPos[1] += 180.0;
	TeleportEntity(iClient, NULL_VECTOR, fFinalPos, NULL_VECTOR);
}

stock void AddInFrontOf(float fVecOrigin[3], float fVecAngle[3], float fUnits, float fOutPut[3])
{
	float fVecView[3]; GetViewVector(fVecAngle, fVecView);
	
	fOutPut[0] = fVecView[0] * fUnits + fVecOrigin[0];
	fOutPut[1] = fVecView[1] * fUnits + fVecOrigin[1];
	fOutPut[2] = fVecView[2] * fUnits + fVecOrigin[2];
}

stock void GetViewVector(float fVecAngle[3], float fOutPut[3])
{
	fOutPut[0] = Cosine(fVecAngle[1] / (180 / FLOAT_PI));
	fOutPut[1] = Sine(fVecAngle[1] / (180 / FLOAT_PI));
	fOutPut[2] = -Sine(fVecAngle[0] / (180 / FLOAT_PI));
}

