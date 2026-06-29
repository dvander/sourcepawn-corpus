#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <advancegunmenu>
new String:Guns[100][40][40];
new Handle:g_GunMenuItemSelectForward;
new Handle:g_GunMenuDisableForward;
new Handle:MenuTimer;
new Handle:g_Time;
new bool:disabled = false;

public Plugin:myinfo = 
{
	name = "Advance Gun Menu",
	author = "ShadowDragon",
	description = "custom gun menu",
	version = "0.1",
	url = "ltgamers.net"
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
	#else
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
	#endif
{
	MarkNativeAsOptional("GetUserMessageType"); 
	
	RegPluginLibrary("advanceweapons");
	// CreateNative("Unsure", Native_Unsure);
	
	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
	return APLRes_Success;
	#else
	return true;
	#endif
}

public OnPluginStart()
{
	RegConsoleCmd("sm_weapons",Cmd_Weapons,"Open Menu");
	LoadWeapons();
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("round_end", RoundEnd);
	g_Time = CreateConVar("TimeUntillDisabled","20.0","The time untill you are unable to use !weapons");
	g_GunMenuItemSelectForward = CreateGlobalForward("OnGunMenuSelect", ET_Event, Param_String, Param_String, Param_Cell, Param_Cell);
	g_GunMenuDisableForward = CreateGlobalForward("OnGunMenuDisable", ET_Event, Param_String, Param_String, Param_Cell, Param_Cell);
	AutoExecConfig(true,"Advance-Gun-Menu")
}
public Action:PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	disabled = false;
}
public Action:RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	disabled = false;
	MenuTimer = CreateTimer(GetConVarFloat(g_Time),DisableWeaponMenu);
}
public Action:DisableWeaponMenu(Handle:time)
{
	disabled = true;
	GunMenuDisable();
	KillTimer(MenuTimer);
}
public LoadWeapons()
{
	//Debug message
	PrintToServer("Advance Weapons created by ShadowDragon!");
	PrintToServer("Advance Weapons: <Loading>");
	//Find the file
	new String:wp[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, wp, PLATFORM_MAX_PATH, "configs/weapons/weapons.ini"); 
	new Handle:kv = CreateKeyValues("Weapons");
	FileToKeyValues(kv, wp);
	
	if(KvGotoFirstSubKey(kv))
	{
		new String:Gun_Name[15],String:Gun_ID[15], i = 0;
		do
		{
			KvGetSectionName(kv, Gun_Name, sizeof(Gun_Name));
			//Get ID String
			KvGetString(kv, "ID", Gun_ID, sizeof(Gun_ID), "ERROR");
			if(StrEqual(Gun_ID, "ERROR")) SetFailState("\n\n Advance Guns Menu: Sorry but i can not find the value 'ID' there may be a problem in weapons.ini \n\n");
			
			Guns[i][0] = Gun_Name;
			Guns[i][1] = Gun_ID;
			
			
			PrintToServer("Advance Guns Menu Loaded: Weapon <%s>", Guns[i][0]);
			i++;
		}
		while(KvGotoNextKey(kv));
			
	}
	else
	{
		PrintToServer("Advance Guns Menu: No Items Found");
	}
}


public Action:Cmd_Weapons(client,args)
{
	if(IsPlayerAlive(client))
	{
		if(disabled == false)
		{
			GunMenu(client);
		}
		else
		{
			
		}
	}
	return Plugin_Handled;
}

GunMenu(client)
{
	new Handle:menu = CreateMenu(gunshandle);
	SetMenuTitle(menu, "Advance Gun Menu");
	for(new i_guns = 0; i_guns < Guns[i_guns][1][0]; i_guns++)
	{
		AddMenuItem(menu, Guns[i_guns][0][0], Guns[i_guns][0][0]);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 50);
}

public gunshandle(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			for(new i = 0; i < Guns[i][1][0]; i++)
			{
				
				if (StrEqual(info, Guns[i][0][0]))
				{
					new String:name[100];
					GetClientName(param1, name,sizeof(name))
					GivePlayerItem(param1, Guns[i][0]);
					
					GunMenuItemSelect(Guns[i][0], name, param1);
				}
				
			}
			
		}
	}
}

public GunMenuItemSelect(String:WeaponName[], String:PlayerName[], Index)
{
	
	Call_StartForward(g_GunMenuItemSelectForward);
	Call_PushString(WeaponName);
	Call_PushString(PlayerName);
	Call_PushCell(Index);
	Call_Finish();
}
public GunMenuDisable()
{
	
	Call_StartForward(g_GunMenuDisableForward);
	Call_Finish();
}
