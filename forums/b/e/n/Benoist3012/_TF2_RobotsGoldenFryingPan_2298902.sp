#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <tf2items>
new Handle:CvarGolden = INVALID_HANDLE;
#define PLUGIN_VERSION 		"0.1"

public Plugin:myinfo = 
{
	name = "[TF2]Golden Frying Pan for mvm bots!",
	author = "Benoist3012",
	description = "Replace robot's melee weapons with the golden frying pan.Or if the robot name contains GFP",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	if (GetEngineVersion() != Engine_TF2)
	{
		PrintToServer("Sorry! This plugin only works for TF2.");
		SetFailState("Incompatible game engine. Requires TF2.");
	}
	HookEvent("player_spawn", OnPlayerSpawnPre, EventHookMode_Pre );
	CvarGolden = CreateConVar("sm_tf2rgfp", "3", "1=Only robots with base melee wep,2=Only bot name GFP,3=Both");
}
public Action:OnPlayerSpawnPre( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if(IsFakeClient(iClient) && GetClientTeam(iClient) == _:TFTeam_Blue)
	{
		new	Value = GetConVarInt(CvarGolden);
		PrintToChatAll("Value:%i",Value);
		if(Value == 1 || Value == 3)
		{
			new meleewep=GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
			if(IsValidEdict(meleewep))
			{
				new index=GetEntProp(meleewep, Prop_Send, "m_iItemDefinitionIndex");
				if(index<=30)
				{
					CreateTimer(1.0,GiveGoldenFryingPan,iClient);
				}
			}
		}
		if(Value == 2 || Value == 3)
		{
			new String:strname[255];
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

public Action:GiveGoldenFryingPan(Handle:timer,any:iClient)
{
	TF2_RemoveWeaponSlot( iClient, 2 );
	new String:weaponAttribs[256];
	Format(weaponAttribs, sizeof(weaponAttribs), "150 ; 1 ; 542 ; 0");
	SpawnWeapon(iClient, "saxxy", 1071, 100, 6, weaponAttribs);
}
stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
	new String:ClientClass[18];
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
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, ClientClass);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	if( IsValidEdict( entity ) )
	{
		EquipPlayerWeapon( client, entity );
	}	
	return entity;
}