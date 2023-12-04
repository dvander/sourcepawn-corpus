#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_NAME             "[L4D2] Random guns ammo"
#define PLUGIN_DESCRIPTION      "Randomizes weapon ammo ,and works with other plugins to completely eliminate infinite ammo/weapon."
#define PLUGIN_VERSION          "1.1"
#define PLUGIN_AUTHOR           "Iciaria"
#define PLUGIN_URL              "https://forums.alliedmods.net/showthread.php?p=2794685"

/*
My English is bad :(
==============================================================================
Credits:
-Psykotik (Crasher_3637)
Ammunition Variation Plugin.
Gave me the idea to write this plugin.

-Machine, dcx2, Electr0 /z, Senip, Shao, Zheldorg
L4D2] Weapon Drop Plugin.
Refer to their code to solve the unexpected "IN_USE" problem.

-NoroHime
[L4D & L4D2] Take Ammo From Previous Weapon Plugin.
Learned from his plugin how to set the reserve ammo value, although mine now uses a separate ammo count.
The most surprising thing is that I now know that the "smlib" library. :)

[L4D & L4D2] HUD Hiddens Plugin.
Learn how to use Forward "OnGameFrame".
-------------------------------------------------------------------------------
Change Logs:

1.1 (Dec-24-2022)
	- Survivor bots now don't always accidentally drop other items when they acquire certain weapons (but the issue is still open).
	- Fix "Array index out-of-bounds"
	- Fix "Invalid entity index -1"
	- Fix "Property "m_iPrimaryAmmoType" not found (entity 25/terror_player_manager)"
	- Various changes to the code.
	- Fixed some wrong annotations/comments.

1.0 (Dec-07-2022)
        - Initial release.

-------------------------------------------------------------------------------
*/

#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))

ConVar g_cvRA_Debug;
ConVar g_cvRA_Enabled;
ConVar g_cvRA_MaxSaveWeapon;
ConVar g_cvRA_FrameCount;

//ConVar g_cvRA_MagnumMin;
//ConVar g_cvRA_MagnumMax;
//ConVar g_cvRA_Magnum_RMin;
//ConVar g_cvRA_Magnum_RMax;
//ConVar g_cvRA_PistolMin;
//ConVar g_cvRA_PistolMax;
ConVar g_cvRA_M60Min;
ConVar g_cvRA_M60Max;
//ConVar g_cvRA_LauncherMin;
//ConVar g_cvRA_LauncherMax;
ConVar g_cvRA_Launcher_RMin;
ConVar g_cvRA_Launcher_RMax;

ConVar g_cvRA_SmgMin;
ConVar g_cvRA_SmgMax;
ConVar g_cvRA_Smg_RMin;
ConVar g_cvRA_Smg_RMax;

ConVar g_cvRA_Smg_sMin;
ConVar g_cvRA_Smg_sMax;
ConVar g_cvRA_Smg_s_RMin;
ConVar g_cvRA_Smg_s_RMax;
ConVar g_cvRA_Smg_mp5Min;
ConVar g_cvRA_Smg_mp5Max;
ConVar g_cvRA_Smg_mp5_RMin;
ConVar g_cvRA_Smg_mp5_RMax;
ConVar g_cvRA_ChromeMin;
ConVar g_cvRA_ChromeMax
ConVar g_cvRA_Chrome_RMin;
ConVar g_cvRA_Chrome_RMax;
ConVar g_cvRA_PumpMin;
ConVar g_cvRA_PumpMax;
ConVar g_cvRA_Pump_RMin;
ConVar g_cvRA_Pump_RMax;
ConVar g_cvRA_M16Min;
ConVar g_cvRA_M16Max;
ConVar g_cvRA_M16_RMin;
ConVar g_cvRA_M16_RMax;
ConVar g_cvRA_Ak47Min;
ConVar g_cvRA_Ak47Max;
ConVar g_cvRA_Ak47_RMin;
ConVar g_cvRA_Ak47_RMax;
ConVar g_cvRA_DesertMin;
ConVar g_cvRA_DesertMax;
ConVar g_cvRA_Desert_RMin;
ConVar g_cvRA_Desert_RMax;
ConVar g_cvRA_Sg552Min;
ConVar g_cvRA_Sg552Max;
ConVar g_cvRA_Sg552_RMin;
ConVar g_cvRA_Sg552_RMax;
ConVar g_cvRA_AutoMin;
ConVar g_cvRA_AutoMax;
ConVar g_cvRA_Auto_RMin;
ConVar g_cvRA_Auto_RMax;
ConVar g_cvRA_SpasMin;
ConVar g_cvRA_SpasMax;
ConVar g_cvRA_Spas_RMin;
ConVar g_cvRA_Spas_RMax;
ConVar g_cvRA_AwpMin;
ConVar g_cvRA_AwpMax;
ConVar g_cvRA_Awp_RMin;
ConVar g_cvRA_Awp_RMax;
ConVar g_cvRA_MilitaryMin;
ConVar g_cvRA_MilitaryMax;
ConVar g_cvRA_Military_RMin;
ConVar g_cvRA_Military_RMax;
ConVar g_cvRA_ScoutMin;
ConVar g_cvRA_ScoutMax;
ConVar g_cvRA_Scout_RMin;
ConVar g_cvRA_Scout_RMax;
ConVar g_cvRA_HuntingMin;
ConVar g_cvRA_HuntingMax;
ConVar g_cvRA_Hunting_RMin;
ConVar g_cvRA_Hunting_RMax;

//[Count] [0 = Handheld Slots/Status, 1 = EntIndex, 2 = Type, 3 = Reserve Ammo]
int g_iweaponEnt_list[512][4];

int g_iweapontype;
int g_iweapon;
int g_iR_random;
int g_iweaponCount;

bool g_bAllow = false;
bool bLateLoad = false;
bool g_bAllowSetAmmo = false;
bool g_bRound =false;
bool g_bcanDropWeapon[MAXPLAYERS+1];

static char g_sAllowDropWeaponType[20][] = {
        "weapon_melee", 
        "weapon_pistol_magnum",
        "weapon_pistol",
        "weapon_rifle_m60",
        "weapon_grenade_launcher",
        "weapon_smg",
        "weapon_smg_silenced",
        "weapon_smg_mp5",
        "weapon_shotgun_chrome",
        "weapon_pumpshotgun",
        "weapon_rifle",
        "weapon_rifle_ak47",
        "weapon_rifle_desert",
        "weapon_rifle_sg552",
        "weapon_autoshotgun",
        "weapon_shotgun_spas",
        "weapon_sniper_awp",
        "weapon_sniper_military",
        "weapon_sniper_scout",
        "weapon_hunting_rifle"
}

public void CreateConvar()
{	
	g_cvRA_FrameCount = CreateConVar("l4d2_AR_FrameCount", "5", "Sync spare ammo every how many server frames?\nShould not be more than the weapon's minimum reload time.\nFor a server tick rate of 20, the default will be to sync every 0.25s.\nFor a server tick rate of 100, recommended to set the value to 15/20.");
	g_cvRA_MaxSaveWeapon = CreateConVar("l4d2_AR_MaxSaveWeapon", "128", "The size of the array used to store weapon data, this determines the maximum number of weapon entities allowed for the plugin to work properly.\nDo not set this value too large! If the plugin works, it probably doesn't need to be changed.",FCVAR_NOTIFY, true, 1.0, true, 512.0);
	g_cvRA_Debug = CreateConVar("l4d2_AR_Debug", "0", "Enabled Debug Mode?\n0 or other value= Disabled, 1 = Enabled\nIf Enabled,Check in-game chat and server console output.");
        g_cvRA_Enabled = CreateConVar("l4d2_AR_Enabled", "0", "Enable this plugins?\n0 or other value = Disabled, 1 = Enabled\nAll ConVar naming rule below follow:\nl4d2_AM_SmgMin SMG(mac-10) Min Primary Ammo\nl4d2_AM_SmgRMin SMG(mac-10) Min Reserved Ammo");
        g_cvRA_M60Min = CreateConVar("l4d2_RA_M60Min", "100");
        g_cvRA_M60Max = CreateConVar("l4d2_RA_M60Max", "200");
//        g_cvRA_LauncherMin = CreateConVar("l4d2_RA_LuncherMin", "");
//        g_cvRA_LauncherMax = CreateConVar("l4d2_RA_LuncherMax", "");
        g_cvRA_Launcher_RMin = CreateConVar("l4d2_RA_Luncher_RMin", "2");
        g_cvRA_Launcher_RMax = CreateConVar("l4d2_RA_Luncher_RMax", "5");

        g_cvRA_SmgMin = CreateConVar("l4d2_RA_SmgMin", "24");
        g_cvRA_SmgMax = CreateConVar("l4d2_RA_SmgMax", "32");
        g_cvRA_Smg_RMin = CreateConVar("l4d2_RA_Smg_RMin", "96");
        g_cvRA_Smg_RMax = CreateConVar("l4d2_RA_Smg_RMax", "160");

        g_cvRA_Smg_sMin = CreateConVar("l4d2_RA_Smg_sMin", "0");
        g_cvRA_Smg_sMax = CreateConVar("l4d2_RA_Smg_sMax", "30");
        g_cvRA_Smg_s_RMin = CreateConVar("l4d2_RA_Smg_s_RMin", "90");
        g_cvRA_Smg_s_RMax = CreateConVar("l4d2_RA_Smg_s_RMax", "150");
        g_cvRA_Smg_mp5Min = CreateConVar("l4d2_RA_Smg_mp5Min", "10");
        g_cvRA_Smg_mp5Max = CreateConVar("l4d2_RA_Smg_mp5Max", "30");
        g_cvRA_Smg_mp5_RMin = CreateConVar("l4d2_RA_Smg_mp5_RMin", "90");
        g_cvRA_Smg_mp5_RMax = CreateConVar("l4d2_RA_Smg_mp5_RMax", "150");
        g_cvRA_ChromeMin = CreateConVar("l4d2_RA_ChromeMin", "3");
        g_cvRA_ChromeMax = CreateConVar("l4d2_RA_ChromeMax", "6");
        g_cvRA_Chrome_RMin = CreateConVar("l4d2_RA_Chrome_RMin", "10");
        g_cvRA_Chrome_RMax = CreateConVar("l4d2_RA_Chrome_RMax", "20");
        g_cvRA_PumpMin = CreateConVar("l4d2_RA_PumpMin", "0");
        g_cvRA_PumpMax = CreateConVar("l4d2_RA_PumpMax", "7");
        g_cvRA_Pump_RMin = CreateConVar("l4d2_RA_Pump_RMin", "10");
        g_cvRA_Pump_RMax = CreateConVar("l4d2_RA_Pump_RMax", "24");
        g_cvRA_M16Min = CreateConVar("l4d2_RA_M16Min", "0");
        g_cvRA_M16Max = CreateConVar("l4d2_RA_M16Max", "30");
        g_cvRA_M16_RMin = CreateConVar("l4d2_RA_M16_RMin", "90");
        g_cvRA_M16_RMax = CreateConVar("l4d2_RA_M16_RMax", "120");
        g_cvRA_Ak47Min = CreateConVar("l4d2_RA_Ak47Min", "0");
        g_cvRA_Ak47Max = CreateConVar("l4d2_RA_Ak47Max", "30");
        g_cvRA_Ak47_RMin = CreateConVar("l4d2_RA_Ak47_RMin", "90");
        g_cvRA_Ak47_RMax = CreateConVar("l4d2_RA_Ak47_RMax", "120");
        g_cvRA_DesertMin = CreateConVar("l4d2_RA_DesertMin", "15");
        g_cvRA_DesertMax = CreateConVar("l4d2_RA_DesertMax", "30");
        g_cvRA_Desert_RMin = CreateConVar("l4d2_RA_Desert_RMin", "90");
        g_cvRA_Desert_RMax = CreateConVar("l4d2_RA_Desert_RMax", "120");
        g_cvRA_Sg552Min = CreateConVar("l4d2_RA_Sg552Min", "0");
        g_cvRA_Sg552Max = CreateConVar("l4d2_RA_Sg552Max", "30");
        g_cvRA_Sg552_RMin = CreateConVar("l4d2_RA_Sg552_RMin", "90");
        g_cvRA_Sg552_RMax = CreateConVar("l4d2_RA_Sg552_RMax", "120");
        g_cvRA_AutoMin = CreateConVar("l4d2_RA_AutoMin", "4");
        g_cvRA_AutoMax = CreateConVar("l4d2_RA_AutoMax", "6");
        g_cvRA_Auto_RMin = CreateConVar("l4d2_RA_Auto_RMin", "12");
        g_cvRA_Auto_RMax = CreateConVar("l4d2_RA_Auto_RMax", "20");
        g_cvRA_SpasMin = CreateConVar("l4d2_RA_SpasMin", "0");
        g_cvRA_SpasMax = CreateConVar("l4d2_RA_SpasMax", "8");
        g_cvRA_Spas_RMin = CreateConVar("l4d2_RA_Spas_RMin", "0");
        g_cvRA_Spas_RMax = CreateConVar("l4d2_RA_Spas_RMax", "32");
        g_cvRA_AwpMin = CreateConVar("l4d2_RA_AwpMin", "1");
        g_cvRA_AwpMax = CreateConVar("l4d2_RA_AwpMax", "10");
        g_cvRA_Awp_RMin = CreateConVar("l4d2_RA_Awp_RMin", "20");
        g_cvRA_Awp_RMax = CreateConVar("l4d2_RA_Awp_RMax", "40");
        g_cvRA_MilitaryMin = CreateConVar("l4d2_RA_MilitaryMin", "0");
        g_cvRA_MilitaryMax = CreateConVar("l4d2_RA_MilitaryMax", "20");
        g_cvRA_Military_RMin = CreateConVar("l4d2_RA_Military_RMin", "40");
        g_cvRA_Military_RMax = CreateConVar("l4d2_RA_Military_RMax", "80");
        g_cvRA_ScoutMin = CreateConVar("l4d2_RA_ScoutMin", "4");
        g_cvRA_ScoutMax = CreateConVar("l4d2_RA_ScoutMax", "10");
        g_cvRA_Scout_RMin = CreateConVar("l4d2_RA_Scout_RMin", "20");
        g_cvRA_Scout_RMax = CreateConVar("l4d2_RA_Scout_RMax", "40");
        g_cvRA_HuntingMin = CreateConVar("l4d2_RA_HuntingMin", "0");
        g_cvRA_HuntingMax = CreateConVar("l4d2_RA_HuntingMax", "10");
        g_cvRA_Hunting_RMin = CreateConVar("l4d2_RA_Hunting_RMin", "20");
        g_cvRA_Hunting_RMax = CreateConVar("l4d2_RA_Hunting_RMax", "40");
}

public Plugin:myinfo =
{
        name = PLUGIN_NAME,
        author = PLUGIN_AUTHOR,
        description = PLUGIN_DESCRIPTION,
        version = PLUGIN_VERSION,
        url = PLUGIN_URL
}

stock void Require_L4D2()
{
        char game[32];
        GetGameFolderName(game, sizeof(game));
        if (!StrEqual(game, "left4dead2", false))
        {
                SetFailState("Plugin supports Left 4 Dead 2 only.");
        }
}

public void ReSet()
{
	for(int i = 0; i < GetConVarInt(g_cvRA_MaxSaveWeapon); i ++)
	{
//		if(g_iweaponEnt_list[i][0] == 0)
//			break;	
		g_iweaponEnt_list[i][0] = 0;
		g_iweaponEnt_list[i][1] = 0;
		g_iweaponEnt_list[i][2] = 0;
		g_iweaponEnt_list[i][3] = 0;
	}
}
public void OnPluginStart()
{
        Require_L4D2();
        CreateConvar();
        AutoExecConfig(true, "l4d2_RandomAmmo");
	
	HookEvent("item_pickup", Event_Item_Pickup);
	HookEvent("player_use", Event_Player_Use);
	HookEvent("round_start_post_nav", Event_RoundStart);
        HookEvent("round_end", Event_RoundEnd);
//	HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);

        if(bLateLoad)
        {
                PrintToChatAll("*LateLoad*");
                for(int i = 1; i <= MaxClients; i++)
                        if(IsClientInGame(i))
                                {
                                        SDKHook(i, SDKHook_WeaponCanUse, eWeaponCanUse);
					SDKHook(i, SDKHook_WeaponSwitchPost, eWeaponSwitchPost);
                               }
        }

}

public void OnMapStart()
{
	for (int i = 1; i <= MAXPLAYERS; i++)   g_bcanDropWeapon[i] = true;
}

public void OnClientPutInServer(int client) 
{
	SDKHook(client, SDKHook_WeaponCanUse, eWeaponCanUse);
	SDKHook(client, SDKHook_WeaponSwitchPost, eWeaponSwitchPost);
	g_bcanDropWeapon[client] = true;
}

public void OnConfigsExecuted()
{
	g_bRound = true;
	if(GetConVarInt(g_cvRA_Debug) == 1)     PrintToServer("===============OnConfigsExecuted & g_bRound = %d++++++++\n",g_bRound);
	if(GetConVarInt(g_cvRA_Enabled) == 1)	
	{
		//Prevent "*_spawn" and "weapon_*(index always = 25)" entity from being counted in the list	
		CreateTimer(0.3, tOnConfigsExecuted);
	
	}
}

public Action tOnConfigsExecuted(Handle timer)
{
	g_bAllow = true;
	ReSet();
	if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToServer("===============OnConfigsExecuted Timer: ReSet g_iweaponEnt_list & g_bAllow = %d++++++++\n",g_bAllow);
	
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(g_cvRA_Enabled) != 1)	
		return;
	if(GetConVarInt(g_cvRA_Debug) == 1)
        {
                PrintToServer("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
                PrintToServer("++++++++++++++++++Round Start: g_bRound = %d+++++++++++++++++++++\n", g_bRound);
                PrintToServer("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
        }
	ReSet();
	//Let "tOnEntityCreated" break it.
	CreateTimer(60.0, tEvent_RoundStart);
}

public Action tEvent_RoundStart(Handle timer)
{
	g_bRound = false;
	if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToServer("++++++++++++++++++Round Start:Timer g_bRound = %d+++++++++++++++++++++", g_bRound);
	return Plugin_Continue;	
}
//It ii seems to only be called when all players die.
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(g_cvRA_Enabled) != 1)	
		return;
        if(GetConVarInt(g_cvRA_Debug) == 1)
        {
                PrintToServer("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
                PrintToServer("++++++++++++++++++Round End:g_bRound = %d+++++++++++++++++++++\n", g_bRound);
                PrintToServer("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
        }
	g_bRound = true;
	ReSet();
	if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToServer("++++Round End:ReSet g_iweaponEnt_list & g_bRound:= %d++++++\n",g_bRound);
			
}

//Prevent accidental "IN_USE" | Refer to the "l4d2_drop" plugin
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& entWeapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(g_bcanDropWeapon[client] == false && (buttons & IN_USE))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}


public void OnGameFrame()
{
	if(GetConVarInt(g_cvRA_Enabled) != 1)	
		return;

	static int skipped = 0;
	if (++skipped >= GetConVarInt(g_cvRA_FrameCount))
	{
		skipped = 0;
		int MaxSaveWeapon = GetConVarInt(g_cvRA_MaxSaveWeapon);
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsValidEntity(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsIn_Incapped(client) )
			{
				for(int i = 0; i <= MaxSaveWeapon; i++)
				{
					if(g_iweaponEnt_list[i][0])
					{
						if(L4D_GetPlayerCurrentWeapon(client) == g_iweaponEnt_list[i][1])
						{
							g_iweaponEnt_list[i][3] = GetClientReservedAmmo(g_iweaponEnt_list[i][1], client);	
						}
					}
				}
			}

		}
	}
}

public int CheckFlags(int weapon, int type)
{
	for(int s = 0; s < GetConVarInt(g_cvRA_MaxSaveWeapon); s++ )
	{
		if(g_iweaponEnt_list[s][1] == weapon && g_iweaponEnt_list[s][2] == type)
		{
			if(GetConVarInt(g_cvRA_Debug) == 1)	
			{
				PrintToChatAll("---------------Set1 Find Flag::%d, Hand:%d, Index:%d, Type:%d, R_Ammo: %d",s,g_iweaponEnt_list[s][0], g_iweaponEnt_list[s][1], g_iweaponEnt_list[s][2], g_iweaponEnt_list[s][3]);
				PrintToServer("---------------Set1 Find Flag::%d, Hand:%d, Index:%d, Type:%d, R_Ammo: %d",s,g_iweaponEnt_list[s][0], g_iweaponEnt_list[s][1], g_iweaponEnt_list[s][2], g_iweaponEnt_list[s][3]);
			}		
			return s;
		}
		if(g_iweaponEnt_list[s][1] == 0 && g_iweaponEnt_list[s][2] == 0)
		{
			g_iweaponEnt_list[s][1] = weapon;
			g_iweaponEnt_list[s][2] = type;
			g_iweaponCount = s;
			if(GetConVarInt(g_cvRA_Debug) == 1)
			{
				PrintToChatAll("---------Set2 None Set Flag:%d, Hand:%d, Index:%d, Type:%d, R_Ammo: %d", s, g_iweaponEnt_list[s][0],g_iweaponEnt_list[s][1], g_iweaponEnt_list[s][2], g_iweaponEnt_list[s][3]);
				PrintToServer("---------------Set2 None Set Flag::%d, Hand:%d, Index:%d, Type:%d, R_Ammo: %d",s,g_iweaponEnt_list[s][0], g_iweaponEnt_list[s][1], g_iweaponEnt_list[s][2], g_iweaponEnt_list[s][3]);
			}
			return -1;
		}
	}
	return -1;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(GetConVarInt(g_cvRA_Enabled) != 1)	
		return;
	if(g_bAllow && entity != 25)
	{	
		for(int i = 0; i<= 19; i++ )
		{
			if(strncmp(classname, g_sAllowDropWeaponType[i], 16) == 0 && StrContains(classname, "_spawn", false) == -1)
			{
				if(i < 3)
				{
					if(g_bRound)
					{
						CreateTimer(0.1, tOnEntityCreated);
						break;	
					}
					break;
				}
				if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToServer("OnEntityCreated| =========================%s---%d",classname,entity);
				CheckFlags(entity, i);
				g_iweapontype = i;
				g_iweapon =  entity;

				if(g_bRound)
				{
					CreateTimer(0.1, tOnEntityCreated);							
					break;					
				}

				if(!g_bRound)
					g_bAllowSetAmmo = true;
			}
		}
	}
}

public Action tOnEntityCreated(Handle timer)
{
	g_bRound = false;
	if(GetConVarInt(g_cvRA_Debug) == 1)
	{
		PrintToChatAll("++++++++++++++++++OnEntityCreated Timer Stop: g_bRound = %d+++++++++++++++++++++", g_bRound);
		PrintToServer("++++++++++++++++++OnEntityCreated Timer Stop: g_bRound = %d+++++++++++++++++++++", g_bRound);
	}	
	return Plugin_Continue;
}
//Check if this weapon is equipped, Maybe speed up the "OnGameFrame"?
public void eWeaponSwitchPost(int iclient, int iweapon)
{
	if(GetConVarInt(g_cvRA_Enabled) != 1)	
		return;

	int MaxSaveWeapon = GetConVarInt(g_cvRA_MaxSaveWeapon);
	int slots0 = GetPlayerWeaponSlot(iclient, 0);
	int slots1 = GetPlayerWeaponSlot(iclient, 1)
	for(int i = 0; i <= MaxSaveWeapon; i++)
	{
		if(g_iweaponEnt_list[i][1] == slots0)
		{
			g_iweaponEnt_list[i][0] = 1;
		}
		if(g_iweaponEnt_list[i][1] == slots1)
		{
			g_iweaponEnt_list[i][0] = 1;
		}
	}
}

public Action:eWeaponCanUse(int iclient, int iweapon)
{
	if(GetConVarInt(g_cvRA_Enabled) != 1 )	
		return Plugin_Continue;

	if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToChatAll("eWeaponCanUse| Handle Weapon:%d, g_bAllowSetAmmo:%d", L4D_GetPlayerCurrentWeapon(iclient), g_bAllowSetAmmo);
	//Prevent invalid entity index(like console "give rifle_ak47")
	if(L4D_GetPlayerCurrentWeapon(iclient) == -1 || iweapon == -1 || iclient == -1)
		return Plugin_Continue;

	if(IS_VALID_SURVIVOR(iclient) && IsValidEntity(iweapon) && !IsIn_Incapped(iclient) || (g_bcanDropWeapon[iclient] && IsFakeClient(iclient)) )
		DropWeapon(iclient, L4D_GetPlayerCurrentWeapon(iclient), iweapon);

	if(g_bAllowSetAmmo)
	{			
		if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToServer("========eWeaponCanUse======");
		int weapon;
		for(int i = 0; i < GetConVarInt(g_cvRA_MaxSaveWeapon); i++)
		{ 
			//When Next Map Start, "Array index out-of-bounds" Index = -1
			//idk why :(
			if(g_iweaponEnt_list[i][1] == 0 && (i -1) != -1)
			{
				weapon = g_iweaponEnt_list[i-1][1];
				if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToChatAll("eWeaponCanUse| -------------Index:%d,Type:%d", g_iweaponEnt_list[i-1][1],g_iweaponEnt_list[i-1][2]);
				break;
			}
		}
		if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToServer("eWeaponCanUse| Start=m_iExtraPrimaryAmmo========Data:%d,Send:%d =========!",GetEntProp(weapon, Prop_Data, "m_iExtraPrimaryAmmo"),GetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo"));
		if(g_iweapontype != 0 && !g_bRound)
			SetWeaponAmmo(weapon);
		if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToServer("eWeaponCanUse| After=m_iExtraPrimaryAmmo=======Send:%d,Send:%d =========!",GetEntProp(weapon, Prop_Data, "m_iExtraPrimaryAmmo"),GetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo"));
		return Plugin_Continue;
	}

	return Plugin_Continue;
}

public void SetWeaponAmmo(int weapon)
{
	int random;
	int R_random;
	switch(g_iweapontype)
	{
		case	0:
		{
			return;
		}
		case	1:
		{
			return;
		}
		case	2:
		{
			return;
		}
		case	3:
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_M60Min),GetConVarInt(g_cvRA_M60Max));
			R_random = 0;
		}
		case	4:
		{	
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Launcher_RMin),GetConVarInt(g_cvRA_Launcher_RMax));
			random = 1;
		}
		case	5:
		{	
			random = GetRandomInt(GetConVarInt(g_cvRA_SmgMin),GetConVarInt(g_cvRA_SmgMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Smg_RMin),GetConVarInt(g_cvRA_Smg_RMax));
			}
		case	6:	
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_Smg_sMin),GetConVarInt(g_cvRA_Smg_sMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Smg_s_RMin),GetConVarInt(g_cvRA_Smg_s_RMax));
		}
		case	7:
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_Smg_mp5Min),GetConVarInt(g_cvRA_Smg_mp5Max)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Smg_mp5_RMin),GetConVarInt(g_cvRA_Smg_mp5_RMax));
		}
		case	8:
		{	
			random = GetRandomInt(GetConVarInt(g_cvRA_ChromeMin),GetConVarInt(g_cvRA_ChromeMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Chrome_RMin),GetConVarInt(g_cvRA_Chrome_RMax));
		}
		case	9:	
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_PumpMin),GetConVarInt(g_cvRA_PumpMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Pump_RMin),GetConVarInt(g_cvRA_Pump_RMax));
		}
		case	10:	
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_M16Min),GetConVarInt(g_cvRA_M16Max)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_M16_RMin),GetConVarInt(g_cvRA_M16_RMax));
		}
		case	11:	
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_Ak47Min),GetConVarInt(g_cvRA_Ak47Max)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Ak47_RMin),GetConVarInt(g_cvRA_Ak47_RMax));
		}
		case	12:	
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_DesertMin),GetConVarInt(g_cvRA_DesertMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Desert_RMin),GetConVarInt(g_cvRA_Desert_RMax));
		}
		case	13:	
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_Sg552Min),GetConVarInt(g_cvRA_Sg552Max)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Sg552_RMin),GetConVarInt(g_cvRA_Sg552_RMax));
		}
		case	14:	
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_AutoMin),GetConVarInt(g_cvRA_AutoMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Auto_RMin),GetConVarInt(g_cvRA_Auto_RMax));
		}
		case	15:	
		{	
			random = GetRandomInt(GetConVarInt(g_cvRA_SpasMin),GetConVarInt(g_cvRA_SpasMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Spas_RMin),GetConVarInt(g_cvRA_Spas_RMax));
		}
		case	16:	
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_AwpMin),GetConVarInt(g_cvRA_AwpMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Awp_RMin),GetConVarInt(g_cvRA_Awp_RMax));
		}
		case	17:	
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_MilitaryMin),GetConVarInt(g_cvRA_MilitaryMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Military_RMin),GetConVarInt(g_cvRA_Military_RMax));
		}
		case	18:	
		{	
			random = GetRandomInt(GetConVarInt(g_cvRA_ScoutMin),GetConVarInt(g_cvRA_ScoutMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Scout_RMin),GetConVarInt(g_cvRA_Scout_RMax));
		}
		case	19:	
		{
			random = GetRandomInt(GetConVarInt(g_cvRA_HuntingMin),GetConVarInt(g_cvRA_HuntingMax)); 
			R_random = GetRandomInt(GetConVarInt(g_cvRA_Hunting_RMin),GetConVarInt(g_cvRA_Hunting_RMax));
		}
		default:
		{
			PrintToChatAll("[L4D2 Random Ammo - Version:%s] InValid Weapon Type !!",PLUGIN_VERSION);
		}
	}
	//Item_Pickup Events
	g_iR_random  = R_random;
	if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToChatAll("SetAmmo: Count:%d, R_random: %d, random: %d",g_iweaponCount, R_random, random);

	g_iweaponEnt_list[g_iweaponCount][3] = R_random;
	SetEntProp(weapon, Prop_Data, "m_iExtraPrimaryAmmo", R_random);
	SetEntProp(weapon, Prop_Data, "m_iClip1", random);

//	SetEntProp(weapon, Prop_Send, "m_iClip1", random);
//	SetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo", R_random);
}

public bool:IsIn_Incapped(client)
{
        return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0);
}
//Get the correct ammo count from the list when the player picks up the weapon.
public void Event_Player_Use(Event event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(g_cvRA_Enabled) != 1)	
		return;

	int iclient = GetClientOfUserId(event.GetInt("userid"));
        int item = event.GetInt("targetid")
        char buffer[24];
        GetEntityClassname(item, buffer, sizeof(buffer));
        if(GetConVarInt(g_cvRA_Debug) == 1)     PrintToServer("===========Event_Player_Use| index: %d===========",item);
        for(int i = 3; i <= 19; i++)
        {
                if(strncmp(buffer, g_sAllowDropWeaponType[i], 16) == 0 && StrContains(buffer, "_spawn", false) == -1)
                {
                        int cout = CheckFlags(item, i);
			if(cout == -1)
				break;
                        if(g_iweaponEnt_list[cout][2] != -1)
                        {
                                if(GetConVarInt(g_cvRA_Debug) == 1)     PrintToChatAll("===========Event_Player_Use| Old Weapon - Count: %d R_Ammo: %d===========",cout,g_iweaponEnt_list[cout][2]);
                                SetClientReservedAmmo(item, iclient, g_iweaponEnt_list[cout][3]);
                                break;
                        }
                }
        }       
}

public void DropWeapon(int iclient, int iweapon, int target_weapon)
{	
        char buffer[24];
        GetEntityClassname(iweapon,buffer,sizeof(buffer));
        char buffer_target[24];
        GetEntityClassname(target_weapon,buffer_target,sizeof(buffer_target));  
        if(GetPlayerWeaponSlot(iclient, 0) != -1 && GetPlayerWeaponSlot(iclient, 1) != -1)
        {
                bool AllowWeaponType = false;
                if(GetConVarInt(g_cvRA_Debug) == 1)     PrintToChatAll("DropWeapon|  client:%d, weapon:%d target: %d, buffer_target: %s", iclient, iweapon, target_weapon, buffer_target);
		//Prevent "First Aid Kit/Defibrillator/...." from being drop.
                for(int s = 0; s<= 19; s++)
                {
                        if(strncmp(buffer_target, g_sAllowDropWeaponType[s], 24) == 0)
                        {
                                AllowWeaponType = true;
                                if(GetConVarInt(g_cvRA_Debug) == 1)     PrintToChatAll("DropWeapon| Allow Target Weapon Type");
                                break;
                        }
                }

                if(!AllowWeaponType)    return;

                for(int i = 0; i<= 19; i++)
                {
                        if(strncmp(buffer_target, g_sAllowDropWeaponType[i], 16) == 0)
                        {
                                if(GetConVarInt(g_cvRA_Debug) == 1)     PrintToChatAll("DropWeapon| Allow Drop Weapn Type! client:%d, weapon:%d*, Type:%d", iclient, iweapon, i);
                                target_weapon = i;
                        }
                }

		int DropWeaponIndex = -1;		
                switch(target_weapon)
                {
                        case    0:      
			{
				SDKHooks_DropWeapon(iclient, GetPlayerWeaponSlot(iclient, 1));
				DropWeaponIndex = GetPlayerWeaponSlot(iclient, 1);
			}
                        case    1:    
			{
				SDKHooks_DropWeapon(iclient, GetPlayerWeaponSlot(iclient, 1));
				DropWeaponIndex = GetPlayerWeaponSlot(iclient, 1);
			}
                        case    2:      
                        {
                                char Have_Pistol[24];
                                GetEntityClassname(GetPlayerWeaponSlot(iclient, 1), Have_Pistol, sizeof(Have_Pistol) );
                                if (strncmp(Have_Pistol, "weapon_pistol_", 14) != 0)
                                        return;
                                SDKHooks_DropWeapon(iclient, GetPlayerWeaponSlot(iclient, 1));
				DropWeaponIndex = GetPlayerWeaponSlot(iclient, 1);

                        }
                        default:
                        {
                                SDKHooks_DropWeapon(iclient, GetPlayerWeaponSlot(iclient, 0));
				DropWeaponIndex = GetPlayerWeaponSlot(iclient, 0);
                        }
                }	
/*------------------------------------------------------------------------------------------------------
I'm not sure whether I need to detect the type of weapon, 
but I accidentally found in my previous test: different types of weapons may have the same entity index.

When Round Start, The first pistol may have the same entity index as subsequent weapons.
I don't know why...
*/
		if(DropWeaponIndex != -1)
		{
			for(int s = 0; s <  GetConVarInt(g_cvRA_MaxSaveWeapon); s++)
			{
				if(g_iweaponEnt_list[s][1] == DropWeaponIndex)
				{
					g_iweaponEnt_list[s][0] = 0;
				}			
			}

		}

		g_bcanDropWeapon[iclient] = false;
		CreateTimer(0.3, tCanDropWeapon, iclient);

	}
/*
	if(IsFakeClient(iclient))
	{
		CreateTimer(0.3, tResetDelay, iclient);
	}
*/	//From l4d2_drop.sp,even if nothing is thrown, we do not allow accidental operation of the button "IN_USE"
	//Survivor bots still sometimes drop weapons, but this time I couldn't reproduce the issue.
	//Even though this problem happens rarely now, I still don't know how to fix it completely.
	CreateTimer(0.1, tResetDelay, iclient); 
}

public Action tCanDropWeapon(Handle timer, any iclient)
{
	g_bcanDropWeapon[iclient] = true;
	return Plugin_Continue;
}

public Action tResetDelay(Handle timer, any iclient)
{
	g_bcanDropWeapon[iclient] = true;
	return Plugin_Continue;
}

public void Event_Item_Pickup(Event event, const char[] name, bool dontBroadcast)
{
	if(GetConVarInt(g_cvRA_Enabled) != 1)	
		return;

	if(GetConVarInt(g_cvRA_Debug) == 1)     PrintToServer("===========Item_Pickup| :g_bAllowSetAmmo:%d - g_bRound: %d===========", g_bAllowSetAmmo, g_bRound );
	int iclient = GetClientOfUserId(event.GetInt("userid"));
	if(g_bAllowSetAmmo && !g_bRound &&g_iweapontype != 0 &&  g_iweapontype != 1 &&  g_iweapontype != 2)
	{
		g_bAllowSetAmmo = false;
		if(GetConVarInt(g_cvRA_Debug) == 1)     PrintToServer("===========Item_Pickup| New Weapon: %d g_bAllowSetAmmo:%d===========",g_iweapon, g_bAllowSetAmmo );
		//For compatibility with the "l4d_reservecontrol" plugin.
		RequestFrame(rEvent_Item_Pickup, iclient);
		return;		
	}
}

rEvent_Item_Pickup(int iclient)
{
	if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToServer("Item_Pickup| Start---------%d---------",GetClientReservedAmmo(g_iweapon,iclient));
	SetClientReservedAmmo(g_iweapon, iclient, g_iR_random);
	if(GetConVarInt(g_cvRA_Debug) == 1)	PrintToServer("Item_Pickup| End---------%d---------",GetClientReservedAmmo(g_iweapon, iclient));
}

//=================The Code blow is from NoroHime's "[L4D & L4D2] Take Ammo From Previous Weapon" plugins(version 1.1.1)========================||

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

        if (late)
                bLateLoad = true;

        MarkNativeAsOptional("L4D_GetWeaponID");

        return APLRes_Success;
}

stock int ammo_offset = -1;
stock int GetClientReservedAmmo(int weapon, int client) {

        if (ammo_offset == -1)
                ammo_offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

        return GetEntData( client, ammo_offset + Weapon_GetPrimaryAmmoType(weapon) * 4 );
}
stock void SetClientReservedAmmo(int weapon, int client, int amount) {

        if (ammo_offset == -1)
                ammo_offset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");

        SetEntData( client, ammo_offset + Weapon_GetPrimaryAmmoType(weapon) * 4, amount);
}

//---------smlib include/smlib/weapons.inc---------------------||
/**
 * Gets the primary ammo Type (int offset)
 *
 * @param weapon                Weapon Entity.
 * @return                              Primary ammo type value.
 */
stock int Weapon_GetPrimaryAmmoType(int weapon)
{
        return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}
