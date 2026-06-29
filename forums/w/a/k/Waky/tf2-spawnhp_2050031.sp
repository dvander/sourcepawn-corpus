#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <smlib>
#include <tf2>
#include <waky>

//------------Defines------------
#define PLUGIN_VERSION "1.0"
#define URL "www.area-community.net"
#define AUTOR "Waky"
#define NAME "SpawnHP"
#define DESCRIPTION "Sets Players HP at roundstart"
#define MAX_FILE_LEN 256

//--------------- CLASSES --------------
#define D "demoman"
#define S "sniper"
#define SC "scout"
#define SP "spy"
#define H "heavy"
#define SO "soldier"
#define P "pyro"
#define E "engineer"
#define M "medic"

new Handle:hPluginenable = INVALID_HANDLE;
new Handle:hD = INVALID_HANDLE;
new Handle:hS = INVALID_HANDLE;
new Handle:hSC = INVALID_HANDLE;
new Handle:hSP = INVALID_HANDLE;
new Handle:hH = INVALID_HANDLE;
new Handle:hSO = INVALID_HANDLE;
new Handle:hP = INVALID_HANDLE;
new Handle:hE = INVALID_HANDLE;
new Handle:hM = INVALID_HANDLE;

new iPluginenable;
new iD;
new iS;
new iSC;
new iSP;
new iH;
new iSO;
new iP;
new iE;
new iM;


public Plugin:myinfo = 
{
	name = NAME,
	author = AUTOR,
	description = DESCRIPTION,
	version = PLUGIN_VERSION,
	url = URL
}
public OnPluginStart()
{
	HookEvent("player_spawn",OnPlayerSpawn,EventHookMode_Post);
	hPluginenable = CreateConVar("spawnhp_enable","1","Enable plugin? 1=On, 0=Off");
	hD = CreateConVar("spawnhp_demoman","100","How much life should the demoman at the spawn?");
	hS = CreateConVar("spawnhp_sniper","100","How much life should the sniper at the spawn?");
	hSC = CreateConVar("spawnhp_scout","100","How much life should the scout at the spawn?");
	hSP = CreateConVar("spawnhp_spy","100","How much life should the spy at the spawn?");
	hH = CreateConVar("spawnhp_heavy","100","How much life should the heavy at the spawn?");
	hSO = CreateConVar("spawnhp_soldier","100","How much life should the soldier at the spawn?");
	hP = CreateConVar("spawnhp_pyro","100","How much life should the pyro at the spawn?");
	hE = CreateConVar("spawnhp_engineer","100","How much life should the engineer at the spawn?");
	hM = CreateConVar("spawnhp_medic","100","How much life should the medic at the spawn?");
	AutoExecConfig(true,"tf2-spawnhp");
}
public OnConfigsExecuted()
{
	iPluginenable = GetConVarInt(hPluginenable);
	iD = GetConVarInt(hD);
	iM = GetConVarInt(hM);
	iS = GetConVarInt(hS);
	iSC = GetConVarInt(hSC);
	iSP = GetConVarInt(hSP);
	iH = GetConVarInt(hH);
	iSO = GetConVarInt(hSO);
	iP = GetConVarInt(hP);
	iE = GetConVarInt(hE);
	iM = GetConVarInt(hM);
}
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(iPluginenable)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsClientValid(client))
		{
			decl String:sClass[MAX_FILE_LEN];
			TF2_GetClass(sClass);
			if(StrEqual(sClass,D,true))
			{
				SetEntityHealth(client,iD);
			}
			else if(StrEqual(sClass,S,true))
			{
				SetEntityHealth(client,iS);
			}
			else if(StrEqual(sClass,SC,true))
			{
				SetEntityHealth(client,iSC);
			}
			else if(StrEqual(sClass,SP,true))
			{
				SetEntityHealth(client,iSP);
			}
			else if(StrEqual(sClass,H,true))
			{
				SetEntityHealth(client,iH);
			}
			else if(StrEqual(sClass,SO,true))
			{
				SetEntityHealth(client,iSO);
			}
			else if(StrEqual(sClass,P,true))
			{
				SetEntityHealth(client,iP);
			}	
			else if(StrEqual(sClass,E,true))
			{
				SetEntityHealth(client,iE);
			}	
			else if(StrEqual(sClass,M,true))
			{
				SetEntityHealth(client,iM);
			}
		}
	}
}
