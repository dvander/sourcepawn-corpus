#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <tf2items>

#pragma semicolon 1
#pragma newdecls required

Handle CvarGolden = INVALID_HANDLE;
#define PLUGIN_VERSION 		"0.1"

public Plugin myinfo = 
{
	name = "[TF2]Golden Frying Pan for mvm bots!",
	author = "Benoist3012",
	description = "Replace robot's melee weapons with the golden frying pan.Or if the robot name contains GFP",
	version = PLUGIN_VERSION
}

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_TF2)
	{
		PrintToServer("Sorry! This plugin only works for TF2.");
		SetFailState("Incompatible game engine. Requires TF2.");
	}
	HookEvent("player_spawn", OnPlayerSpawnPre, EventHookMode_Pre );
	CvarGolden = CreateConVar("sm_tf2rgfp", "3", "1=Only robots with base melee wep,2=Only bot name GFP,3=Both");
}

//is this an MvM map?
bool IsMvMMap() 
{
	char curMap[32];
	GetCurrentMap(curMap, sizeof(curMap));
	return strncmp("mvm_", curMap, 4, false) == 0;
}

public Action OnPlayerSpawnPre( Handle hEvent, const char[] strEventName, bool bDontBroadcast )
{
	int iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if(IsFakeClient(iClient) && IsMvMMap() && GetClientTeam(iClient) == view_as<int>(TFTeam_Blue))
	{
		int	Value = GetConVarInt(CvarGolden);
		PrintToChatAll("Value:%i",Value);
		if(Value == 1 || Value == 3)
		{
			int meleewep=GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
			if(IsValidEdict(meleewep))
			{
				int index=GetEntProp(meleewep, Prop_Send, "m_iItemDefinitionIndex");
				if(index<=30)
				{
					CreateTimer(1.0,GiveGoldenFryingPan,iClient);
				}
			}
		}
		if(Value == 2 || Value == 3)
		{
			char strname[255];
			GetClientInfo(iClient, "name", strname,sizeof(strname));
			PrintToChatAll("Name: %s",strname);
			if(!StrContains(strname, "GFP", false))
			{
				PrintToChatAll("Give golden frying pan");
				CreateTimer(1.0,GiveGoldenFryingPan,iClient);
				ReplaceString(strname, sizeof(strname), "GFP", "", false);
				SetClientInfo(iClient, "name", strname);
			}
		}
	}
	return Plugin_Continue;
}

public Action GiveGoldenFryingPan(Handle timer, any iClient)
{
	TF2_RemoveWeaponSlot( iClient, 2 );
	char weaponAttribs[256];
	Format(weaponAttribs, sizeof(weaponAttribs), "150 ; 1 ; 542 ; 0");
	SpawnWeapon(iClient, "saxxy", 1071, 100, 6, weaponAttribs);
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, char[] att, int visible = 1)
{
	char ClientClass[18];
	switch(TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:        strcopy(ClientClass, sizeof(ClientClass), "tf_weapon_bat");
		case TFClass_Soldier:    strcopy(ClientClass, sizeof(ClientClass), "tf_weapon_shovel");
		case TFClass_Pyro:        strcopy(ClientClass, sizeof(ClientClass), "tf_weapon_fireaxe");
		case TFClass_DemoMan:    strcopy(ClientClass, sizeof(ClientClass), "tf_weapon_bottle");
		case TFClass_Heavy:        strcopy(ClientClass, sizeof(ClientClass), "tf_weapon_fists");
		case TFClass_Engineer:    strcopy(ClientClass, sizeof(ClientClass), "tf_weapon_wrench");
		case TFClass_Medic:        strcopy(ClientClass, sizeof(ClientClass), "tf_weapon_bonesaw");
		case TFClass_Sniper:    strcopy(ClientClass, sizeof(ClientClass), "tf_weapon_club");
		case TFClass_Spy:        strcopy(ClientClass, sizeof(ClientClass), "tf_weapon_knife");
	}
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, ClientClass);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2 = 0;
		for (int i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	if( IsValidEdict( entity ) )
	{
		EquipPlayerWeapon( client, entity );
	}	
	return entity;
}