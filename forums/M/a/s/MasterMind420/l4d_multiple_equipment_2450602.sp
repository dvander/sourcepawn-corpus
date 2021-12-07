#pragma semicolon 1
//#pragma newdecls required //FORCES USE OF NEW SYNTAX

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#define LEN64 64
#define MAX_FRAMECHECK 10

GameMode;
L4D2Version;

LastWeapon[MAXPLAYERS+1];
LastButton[MAXPLAYERS+1];
ItemInfo[MAXPLAYERS+1][5][4];
ItemAttachEnt[MAXPLAYERS+1][5];
static BackupItemInfo[MAXPLAYERS+1][5][4];

String:VoteFix[MAXPLAYERS+1][32];
String:ItemName[MAXPLAYERS+1][5][LEN64];
static String:BackupItemName[MAXPLAYERS+1][5][LEN64];

bool:AfkFix[MAXPLAYERS+1];
bool:DeathFix[MAXPLAYERS+1];
bool:RescueFix[MAXPLAYERS+1];
bool:RoundStart[MAXPLAYERS+1];
bool:bThirdPerson[MAXPLAYERS+1];

Float:Pos[3];
Float:Ang[3];
Float:InHeal[MAXPLAYERS+1];
Float:InRevive[MAXPLAYERS+1];
Float:SwapTime[MAXPLAYERS+1];
Float:ThrowTime[MAXPLAYERS+1];
Float:PressingTime[MAXPLAYERS+1];
Float:PressStartTime[MAXPLAYERS+1];
Float:LastSwitchTime[MAXPLAYERS+1];
Float:LastMeSwitchTime[MAXPLAYERS+1];

Handle:l4d_me_mode;
Handle:l4d_me_view;
Handle:l4d_me_slot[5];
Handle:l4d_me_afk_save;
Handle:l4d_me_player_connect;
Handle:l4d_me_pistol_clip_lock;
Handle:l4d_me_custom_notify;
Handle:l4d_me_custom_notify_msg;
Handle:l4d_me_thirdpersonshoulder_view;

public Plugin:myinfo =
{
	name = "Multiple Equipment",
	author = "MasterMind420 & Ludastar & Pan Xiaohai & Marcus101RR",
	description = "Carry 2 items in each slot",
	version = "3.6",
	url = ""
}

public OnPluginStart()
{
	GameCheck();

/*CONVARS*/
	l4d_me_slot[0] = CreateConVar("l4d_me_slot0", "1", "(Primary), 0=Disable, 1=Enable");
	l4d_me_slot[1] = CreateConVar("l4d_me_slot1", "1", "(Secondary), 0=Disable, 1=Enable");
	l4d_me_slot[2] = CreateConVar("l4d_me_slot2", "1", "(Pipebomb), 0=Disable, 1=Enable");
	l4d_me_slot[3] = CreateConVar("l4d_me_slot3", "1", "(Medkit), 0=Disable, 1=Enable");
	l4d_me_slot[4] = CreateConVar("l4d_me_slot4", "1", "(Pills), 0=Disable, 1=Enable");
	l4d_me_mode = CreateConVar("l4d_me_mode", "1", "1=Single Tap Mode, 2=Double Tap Mode");
	l4d_me_view = CreateConVar("l4d_me_view", "1", "0=Disable Extra Equipment View, 1=Enable Extra Equipment View");
	l4d_me_afk_save = CreateConVar("l4d_me_afk_save", "1", "0=Disable AFK Save, 1=Enable AFK Save");
	l4d_me_custom_notify = CreateConVar("l4d_me_custom_notify", "0", "0=Disable Custom Message, 1=Enable Chat Message, 2=Enable Hint Message");
	l4d_me_custom_notify_msg = CreateConVar("l4d_me_custom_notify_msg", "| MULTIPLE EQUIPMENT || --->PRESS [H] FOR HELP<--- |", "Create a custom welcome message for your server.");
	l4d_me_thirdpersonshoulder_view = CreateConVar("l4d_me_thirdpersonshoulder_view", "1", "0=Disable Thirdpersonshoulder View, 1=Enable Thirdpersonshoulder View");
	l4d_me_player_connect = CreateConVar("l4d_me_player_connect", "0", "0=Disable Player Connect Message, 1=Enable Player Connect Message");
	l4d_me_pistol_clip_lock = CreateConVar("l4d_me_pistol_clip_lock", "1", "0=Disable pistol clip lock at 1 bullet, 1=Enable pistol clip lock at 1 bullet");

/*EVENT HOOKS*/
	HookEvent("player_death", player_death, EventHookMode_Pre);
	HookEvent("player_disconnect", player_disconnect, EventHookMode_Pre);
	
	HookEvent("player_use", player_use, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", player_spawn, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", mission_lost, EventHookMode_PostNoCopy);
	HookEvent("map_transition", map_transition, EventHookMode_PostNoCopy);

	HookEvent("survivor_rescued", survivor_rescued);
	HookEvent("player_bot_replace", enter_afk_pre_player_bot_replace);
	HookEvent("bot_player_replace", exit_afk_post_bot_player_replace);

	HookEvent("weapon_fire", weapon_fire);
	HookEvent("heal_begin", heal_begin);
	HookEvent("heal_end", heal_end);
	HookEvent("heal_success", heal_success);
 	HookEvent("revive_begin", revive_begin);
	HookEvent("revive_end", revive_end);
	HookEvent("pills_used", pills_used);

	if(L4D2Version)
	{
		HookEvent("molotov_thrown", molotov_thrown);
		HookEvent("adrenaline_used", adrenaline_used);
	}

/*REGISTER COMMANDS*/
	RegConsoleCmd("sm_s0", sm_s0);

/*CREATE CONFIG*/
	AutoExecConfig(true, "l4d_multiple_equipment");
	
/*COMMAND LISTENERS*/
	AddCommandListener(Listener_CallVote, "callvote");

/*TIMERS*/
	//CreateTimer(0.1, AmmoLockPrimary, _, TIMER_REPEAT);
	//CreateTimer(0.1, AmmoLockSecondary, _, TIMER_REPEAT);
}

public OnClientPutInServer(client)
{
	Survivor_Connect(client);
}

public OnClientPostAdminCheck(client)
{
	//if (!IsSurvivor(client))
	//	return;

	CreateTimer(0.1, AmmoLockPrimary, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	if (GetConVarInt(l4d_me_pistol_clip_lock) == 1)
		CreateTimer(0.1, AmmoLockSecondary, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	if(!IsFakeClient(client))
		CreateTimer(5.0, FixWeaponView, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Listener_CallVote(client, const String:command[], argc)
{
	GetCmdArg(1, VoteFix[client], sizeof(VoteFix[]));
	if (StrEqual(VoteFix[client], "restartgame", false) || StrEqual(VoteFix[client], "changemission", false) || StrEqual(VoteFix[client], "returntolobby", false))
	{
		ResetClientStateAll();
	}
}

Survivor_Connect(client)
{
	if (!IsSurvivor(client))
		return;

	Activate_ME(client);

	//PLAYER NAME CONNECT MESSAGE
	if(GetConVarInt(l4d_me_player_connect) == 1 && !IsFakeClient(client))
	{
		PrintToChatAll("%N Connected", client);
	}

	//ROUND START WEAPON VIEW FIX
	if(GetConVarInt(l4d_me_view) == 1 && !IsFakeClient(client))
	{
		CreateTimer(5.0, FixWeaponView, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	//CUSTOM CONNECT MESSAGE(>>>UNTESTED<<<)
	if(!(GetEntityFlags(client) & FL_FROZEN) && IsValidEntity(client))
	{
		if(IsFakeClient(client) || GetConVarInt(l4d_me_custom_notify) != 1 || GetConVarInt(l4d_me_custom_notify) != 2)
		{
			return;
		}
		else
		{
			CreateTimer(5.0, ME_Notify_Client, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Activate_ME(client)
{
	LoadEquipment(client);
	RemoveItemAttach(client, -1);
	if(IsSurvivor(client) && !IsFakeClient(client))
	{
		AttachAllEquipment(client);
	}
}

//WEAPON VIEW FIX
public Action:FixWeaponView(Handle:Timer, any:client)
{
	RemoveItemAttach(client, -1);
	if(IsSurvivor(client) && !IsFakeClient(client))
	{
		AttachAllEquipment(client);
	}
}

public Action:ME_Notify_Client(Handle:Timer, any:client)
{
	if(IsValidClient(client, 2, true))
	{
		new String:ME_Msg[99];
		GetConVarString(l4d_me_custom_notify_msg, ME_Msg, sizeof (ME_Msg));
		if (GetConVarInt(l4d_me_custom_notify) == 1) { PrintToChat(client, "%s", ME_Msg); }
		if (GetConVarInt(l4d_me_custom_notify) == 2) { PrintHintText(client, "%s", ME_Msg); }
	}
}

/*
public Action:ThirdPersonCheck(Handle:Timer)
{
	if (!IsServerProcessing())
		return Plugin_Continue;

	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client) || IsClientInKickQueue(client))
			return Plugin_Continue;

		QueryClientConVar(client, "c_thirdpersonshoulder", QueryClientConVarCallback);
	}
	return Plugin_Continue;
}
*/

public QueryClientConVarCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (result != ConVarQuery_Okay) { bThirdPerson[client] = false; }
	else { bThirdPerson[client] = true; }

	if (!StrEqual(cvarValue, "false") && !StrEqual(cvarValue, "0")) //THIRDPERSONSHOULDER
	{
		if(RoundStart[client])
		{
			RoundStart[client] = false;
			bThirdPerson[client] = false;
		}
		else if(AfkFix[client]){ bThirdPerson[client] = false; }
		else if(DeathFix[client]) { bThirdPerson[client] = false; }
		else if(RescueFix[client]) { bThirdPerson[client] = false; }
		else { bThirdPerson[client] = true; }
	}
	else //FIRSTPERSON
	{
		if(RoundStart[client])
		{
			RoundStart[client] = false;
			bThirdPerson[client] = false;
		}
		AfkFix[client] = false;
		DeathFix[client] = false;
		RescueFix[client] = false;
		bThirdPerson[client] = false;
	}
}

public Action:AmmoLockPrimary(Handle:Timer, any:client)
{
	if (!IsServerProcessing())
		return Plugin_Continue;

	//for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsClientInKickQueue(client))
			return Plugin_Continue;
			
		static Weapon;
		Weapon = GetPlayerWeaponSlot(client, 0);
		//Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if (!IsValidEntity(Weapon))
			return Plugin_Continue;

		decl String:sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		decl AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType != -1)
		{
			decl Clip;
			Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

			decl Ammo;
			Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

			if (Ammo < 1 && Clip == 1) //LOCK GUN CLIPS
			{
				if (StrEqual(sWeapon, "weapon_rifle_m60", false) || StrEqual(sWeapon, "weapon_grenade_launcher", false) ||
					StrEqual(sWeapon, "weapon_rifle", false) || StrEqual(sWeapon, "weapon_rifle_ak47", false) ||
					StrEqual(sWeapon, "weapon_rifle_desert", false) || StrEqual(sWeapon, "weapon_rifle_sg552", false) ||
					StrEqual(sWeapon, "weapon_smg", false) || StrEqual(sWeapon, "weapon_smg_silenced", false) ||
					StrEqual(sWeapon, "weapon_smg_mp5", false) || StrEqual(sWeapon, "weapon_pumpshotgun", false) ||
					StrEqual(sWeapon, "weapon_shotgun_chrome", false) || StrEqual(sWeapon, "weapon_autoshotgun", false) ||
					StrEqual(sWeapon, "weapon_shotgun_spas", false) || StrEqual(sWeapon, "weapon_hunting_rifle", false) ||
					StrEqual(sWeapon, "weapon_sniper_military", false) || StrEqual(sWeapon, "weapon_sniper_awp", false) ||
					StrEqual(sWeapon, "weapon_sniper_scout", false))

					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
			}
		}
	}
	return Plugin_Continue;
}

public Action:AmmoLockSecondary(Handle:Timer, any:client)
{
	if (!IsServerProcessing())
		return Plugin_Continue;

	//for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsClientInKickQueue(client))
			return Plugin_Continue;
			
		decl Weapon;
		Weapon = GetPlayerWeaponSlot(client, 1);
		//Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if (!IsValidEntity(Weapon))
			return Plugin_Continue;

		decl String:sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		decl AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType != -1)
		{
			decl Clip;
			Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

			decl Ammo;
			Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

			if (Ammo < 1 && Clip == 1) //LOCK GUN CLIPS
			{
				if (StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false))
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
			}
		}
	}
	return Plugin_Continue;
}

public Action:player_use(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	new AmmoPile = GetClientAimTarget(client, false);
	if (AmmoPile < 32 || !IsValidEntity(AmmoPile))
		return Plugin_Continue;

	decl String:eName[32];
	GetEntityClassname(AmmoPile, eName, sizeof(eName));

	static Weapon;
	//Weapon = GetPlayerWeaponSlot(client, 0);
	Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (!IsValidEntity(Weapon)) 
		return Plugin_Continue;

	decl String:sWeapon[32];
	GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

	if (!StrEqual(eName, "weapon_ammo_spawn", false))
		return Plugin_Continue;
	{
		static AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType != -1)
		{
			static Clip;
			Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");
			
			static Ammo;
			Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);
			
			if (Ammo > 0 && Clip == 1)
			{
				//PISTOL/MAGNUM
				if (StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false))
				{
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
					SetEntProp(Weapon, Prop_Send, "m_iClip1", 0); //FORCE AUTO RELOAD
				}

				//M60
				if (StrEqual(sWeapon, "weapon_rifle_m60", false))
				{
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
					SetEntProp(Weapon, Prop_Send, "m_iClip1", 0); //FORCE AUTO RELOAD
				}

				//GRENADE LAUNCHER
				else if (StrEqual(sWeapon, "weapon_grenade_launcher", false))
				{
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
					SetEntProp(Weapon, Prop_Send, "m_iClip1", 0); //FORCE AUTO RELOAD
				}

				//ASSAULT
				if (StrEqual(sWeapon, "weapon_rifle", false) || StrEqual(sWeapon, "weapon_rifle_ak47", false) || StrEqual(sWeapon, "weapon_rifle_desert", false) || StrEqual(sWeapon, "weapon_rifle_sg552", false))
				{
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
					SetEntProp(Weapon, Prop_Send, "m_iClip1", 0); //FORCE AUTO RELOAD
				}
				//SMG
				else if (StrEqual(sWeapon, "weapon_smg", false) || StrEqual(sWeapon, "weapon_smg_silenced", false) || StrEqual(sWeapon, "weapon_smg_mp5", false))
				{
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
					SetEntProp(Weapon, Prop_Send, "m_iClip1", 0); //FORCE AUTO RELOAD
				}
				//SHOTGUN
				else if (StrEqual(sWeapon, "weapon_pumpshotgun", false) || StrEqual(sWeapon, "weapon_shotgun_chrome", false))
				{
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
					SetEntProp(Weapon, Prop_Send, "m_iClip1", 0); //FORCE AUTO RELOAD
				}
				else if (StrEqual(sWeapon, "weapon_autoshotgun", false) || StrEqual(sWeapon, "weapon_shotgun_spas", false))
				{
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
					SetEntProp(Weapon, Prop_Send, "m_iClip1", 0); //FORCE AUTO RELOAD
				}
				//SNIPER
				else if (StrEqual(sWeapon, "weapon_hunting_rifle", false))
				{
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
					SetEntProp(Weapon, Prop_Send, "m_iClip1", 0); //FORCE AUTO RELOAD
				}
				else if (StrEqual(sWeapon, "weapon_sniper_military", false) || StrEqual(sWeapon, "weapon_sniper_awp", false) || StrEqual(sWeapon, "weapon_sniper_scout", false))
				{
					SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); //UNLOCK GUN CLIP
					SetEntProp(Weapon, Prop_Send, "m_iClip1", 0); //FORCE AUTO RELOAD
				}
			}
		}
	}
	return Plugin_Continue;
}

/*
public Action:AmmoLock(Handle:Timer)
{
	if (!IsServerProcessing())
		return Plugin_Continue;

	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsClientInKickQueue(client))
			return Plugin_Continue;
			
		decl Weapon;
		//Weapon = GetPlayerWeaponSlot(client, 0);
		Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if (!IsValidEntity(Weapon))
			return Plugin_Continue;

		decl String:sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		static AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType != -1)
		{
			static Clip;
			Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

			static Ammo;
			Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

			if (Ammo < 1 && Clip == 1) //LOCK GUN CLIPS
			{
				if ((StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false)) && GetConVarInt(l4d_me_pistol_reloading_plugin) != 1)
					return Plugin_Continue;
				SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
			}
		}
	}
	return Plugin_Continue;
}
*/

public OnGameFrame()
{
	static iFrameskip = 0;
	iFrameskip = (iFrameskip + 1) % MAX_FRAMECHECK;
	if(iFrameskip != 0 || !IsServerProcessing())
		return;

	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client) || IsClientInKickQueue(client))
			continue;
/*
//WEAPON AMMO CLIP LOCK
		decl Weapon;
		//Weapon = GetPlayerWeaponSlot(client, 0);
		Weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if (!IsValidEntity(Weapon))
			continue;

		decl String:sWeapon[32];
		GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

		static AmmoType;
		AmmoType = GetEntProp(Weapon, Prop_Data, "m_iPrimaryAmmoType");
		if (AmmoType != -1)
		{
			static Clip;
			Clip = GetEntProp(Weapon, Prop_Data, "m_iClip1");

			static Ammo;
			Ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, AmmoType);

			if (Ammo < 1 && Clip == 1) //LOCK GUN CLIPS
			{
				if ((StrEqual(sWeapon, "weapon_pistol", false) || StrEqual(sWeapon, "weapon_pistol_magnum", false)) && GetConVarInt(l4d_me_pistol_reloading_plugin) != 1)
					continue;
				SetEntPropFloat(Weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1000.0);
			}
		}
//WEAPON AMMO CLIP LOCK
*/
		//if(IsFakeClient(client))
		//	continue;

//THIRDPERSON CHECK
		if (GetConVarInt(l4d_me_thirdpersonshoulder_view) == 1)
			QueryClientConVar(client, "c_thirdpersonshoulder", QueryClientConVarCallback);
//THIRDPERSON CHECK

//CHARACTER SWITCH WEAPON VIEW FIX
		//static CharacterSwitch;
		//CharacterSwitch = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		new CharacterSwitch = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if(CharacterSwitch)
			CreateTimer(0.5, FixWeaponView, client, TIMER_FLAG_NO_MAPCHANGE);
//CHARACTER SWITCH WEAPON VIEW FIX
    }
}

public Action:sm_s0(client, args)
{
    if (!IsSurvivor(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

    new Float:time=GetEngineTime();
    new buttons=GetClientButtons(client);

    if(time-PressStartTime[client]>0.18)
		Process(client, time, buttons, true);

    PressStartTime[client]=time;
    return Plugin_Continue;
}

public Action:weapon_fire(Handle:event, const String:name[], bool:dontBroadcast)
{
    static client;
    client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!IsSurvivor(client) && !IsPlayerAlive(client))
		return Plugin_Continue;

    decl String:item[10];
    GetEventString(event, "weapon", item, sizeof(item));

    switch(item[0]) //check the first char instead of each string
    {
        case 'p':
        {
            if(StrEqual(item, "pipe_bomb")) { ThrowTime[client]=GetEngineTime(); }
        }
        case 'm':
        {
            if(StrEqual(item, "molotov")) { ThrowTime[client]=GetEngineTime(); }
        }
        case 'v':
        {
            if(StrEqual(item, "vomitjar")) { ThrowTime[client]=GetEngineTime(); }
        }
    }
    return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    static lastButton;
    lastButton = LastButton[client];
    LastButton[client] = buttons;

    static Float:time;
    time = GetEngineTime();

    if((buttons & IN_ATTACK2) && !(lastButton & IN_ATTACK2))
    {
        static w;
        w = Process(client, time, buttons, false);
        if(w > 0)
			LastSwitchTime[client]=time, LastWeapon[client]=w;
    }
    else
    {
        if(weapon > 0 && GetConVarInt(l4d_me_mode) == 1) //SINGLE TAP MODE
        {
            new newweapon = weapon;

            if(LastWeapon[client] == weapon)
            {
                new w = Process(client, time, buttons, true, weapon);
                if(w > 0)
					newweapon = w;
            }
            else
				Process(client, time, buttons, false);

            LastSwitchTime[client]=time;
            LastWeapon[client]=newweapon;
        }
        if(weapon > 0 && GetConVarInt(l4d_me_mode) == 2) //DOUBLE TAP MODE
        {
            new newweapon=weapon;

            if(LastWeapon[client]==weapon)
				Process(client, time, buttons, true, weapon);
            else
				Process(client, time, buttons, false);

            LastSwitchTime[client]=time;
            LastWeapon[client]=newweapon;
        }
    }
    return Plugin_Continue;
}

public Action:DelayRestore(Handle:timer, any:client)
{
	Restore(client);
	return Plugin_Stop;
}

Restore(client)
{
	Process(client, GetEngineTime(), GetClientButtons(client), false);
}

Process(client, Float:time, button, bool:isSwitch, currentWeapon=0)
{
	new theNewWeapon=0;
	if(!IsValidClient(client, 2, true)) { return theNewWeapon; }
	{
		new m_pounceAttacker = GetEntProp(client, Prop_Send, "m_pounceAttacker");
		new m_tongueOwner = GetEntProp(client, Prop_Send, "m_tongueOwner");
		new m_isIncapacitated = GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
		new m_isHangingFromLedge = GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1);
		if(L4D2Version)
		{
			new m_pummelAttacker=GetEntProp(client, Prop_Send, "m_pummelAttacker", 1);
			new m_jockeyAttacker=GetEntProp(client, Prop_Send, "m_jockeyAttacker", 1);
			if(m_pounceAttacker > 0 || m_tongueOwner > 0 || m_isHangingFromLedge > 0 || m_isIncapacitated > 0 || m_pummelAttacker > 0 || m_jockeyAttacker > 0) { return theNewWeapon; }
		}
		else
		{
			if(m_pounceAttacker > 0 || m_tongueOwner > 0 || m_isHangingFromLedge > 0 || m_isIncapacitated > 0) { return theNewWeapon; }
		}
	} 
	new activeWeapon=currentWeapon;
	if(activeWeapon == 0) { activeWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon"); }
	if(activeWeapon <= 0) { activeWeapon = 0; }
	new activeSlot=-1;
	for(new slot=0; slot<5; slot++)
	{
		if(!L4D2Version && slot==1) { continue; }
		if(GetConVarInt(l4d_me_slot[slot])==0) { continue; }
		if( slot==2 ) 
		{
			if(time-ThrowTime[client]<2.0) { continue; }
		}
		new ent=GetPlayerWeaponSlot(client, slot);
		if(activeWeapon == ent && ent > 0 && activeWeapon > 0) { activeSlot=slot; }
		else if(ent <= 0) { theNewWeapon=SwapItem(client, slot, 0); }
	}
	if(activeSlot>=0 && isSwitch) { theNewWeapon=SwapItem(client, activeSlot, activeWeapon); }
	button=button+0;
	time+=0.0;
	if(!isSwitch && activeWeapon > 0)
	{
		SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", activeWeapon);
		theNewWeapon=activeWeapon;
	}
	return theNewWeapon;
}

SwapItem(client, slot, oldweapon=0)
{
	new theNewWeapon=0;
	decl String:oldWeaponName[LEN64]="";
	new clip=0;
	new ammo=0;
	new upgradeBit=0;
	new upammo=0;
	if(oldweapon > 0)
	{
		GetItemClass(oldweapon, oldWeaponName);
		if (StrEqual(oldWeaponName, "")) { return 0; }
		new bool:isPistol=false;
		if(StrEqual(oldWeaponName, "weapon_pistol")) { isPistol=true; }
		GetItemInfo(client, slot, oldweapon, ammo, clip, upgradeBit, upammo, isPistol);
		RemovePlayerItem(client, oldweapon);
		AcceptEntityInput(oldweapon, "kill");
	}
	new newweapon=0;
	if(!StrEqual(ItemName[client][slot], "")) { newweapon=CreateWeaponEnt(ItemName[client][slot]); }
	if(newweapon > 0)
	{
		EquipPlayerWeapon(client, newweapon);
		SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon" , newweapon);
		SetItemInfo(client, slot, newweapon , ItemInfo[client][slot][0], ItemInfo[client][slot][1],ItemInfo[client][slot][2],ItemInfo[client][slot][3]);
		theNewWeapon=newweapon;
	}
	ItemName[client][slot]=oldWeaponName;
	ItemInfo[client][slot][0]=ammo;
	ItemInfo[client][slot][1]=clip;
	ItemInfo[client][slot][2]=upgradeBit;
	ItemInfo[client][slot][3]=upammo;	
	RemoveItemAttach(client, slot);
	ItemAttachEnt[client][slot]=0;
	ItemAttachEnt[client][slot]=CreateItemAttach(client, oldWeaponName, slot);
	return theNewWeapon;
}

SetItemInfo (client, slot, weapon,  ammo, clip, upgradeBit, upammo)
{
	if(slot==0)
	{
		if(L4D2Version) { SetClientWeaponInfo_l4d2(client, weapon, ammo, clip, upgradeBit, upammo); }
		else { SetClientWeaponInfo_l4d1(client, weapon, ammo, clip); }
	}
	else
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
 		if(slot == 1 && ammo > 0) { SetEntProp(weapon, Prop_Send, "m_hasDualWeapons" ,ammo); }
	}
}

GetItemInfo(client, slot, weapon, &ammo, &clip,  &upgradeBit, &upammo, bool:isPistol)
{
	if(slot==0)
	{
		if(L4D2Version) { GetClientWeaponInfo_l4d2(client, weapon, ammo, clip, upgradeBit, upammo); }
		else { GetClientWeaponInfo_l4d1(client,weapon, ammo, clip); }
	}
	else
	{
		ammo=0;
		upgradeBit=0;
		upammo=0;
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1" );
		if(isPistol) { ammo = GetEntProp(weapon, Prop_Send, "m_hasDualWeapons" ); }
	}
}

RemoveItemAttach(client, slot)
{
	new startSlot = slot;
	new endSlot = slot;
	if (slot < 0 || slot > 4)
	{
		startSlot=0;
		endSlot=4;
	}
	for (new i = startSlot; i <= endSlot; i++)
	{
		new entity = ItemAttachEnt[client][i];
		ItemAttachEnt[client][i]=0;
		if(entity > 0 && IsValidEntS(entity, "prop_dynamic"))
		{			
			AcceptEntityInput(entity, "ClearParent");
			AcceptEntityInput(entity, "Kill");
		}
	}
}

SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0] = x, target[1] = y, target[2] = z;
}

CreateItemAttach(client, String:classname[], slot)
{
	if(GetConVarInt(l4d_me_view) != 1) { return 0; }

	decl String:model[LEN64];

	if(L4D2Version) { GetModelFromClass_l4d2(classname, model, slot); }
	else { GetModelFromClass_l4d1(classname, model, slot); }
	
	if(StrEqual(classname, "") || StrEqual(model, "")) { return 0; }

	new entity = CreateEntityByName("prop_dynamic_override");
	if(entity == -1) { return 0; }

	SetEntityModel(entity, model);
	DispatchSpawn(entity);
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 2);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client, entity, 0);

	switch(slot)
	{
		case 0: //Slot0
		{
			SetVariantString("medkit");
			AcceptEntityInput(entity, "SetParentAttachment", entity, entity, 0);
			if(L4D2Version) { SetVector(Pos, 2.0, 0.0, -7.0), SetVector(Ang, -22.0, 100.0, 180.0); }
			else { SetVector(Pos, 2.0, -4.0, 5.0), SetVector(Ang, -15.0, 90.0, 180.0); }
		}
		case 1: //Slot1
		{
			SetVariantString("molotov");
			AcceptEntityInput(entity, "SetParentAttachment", entity, entity, 0);
			if(L4D2Version) { SetVector(Pos, 0.0,  0.0, 0.0), SetVector(Ang, 120.0, 90.0, 0.0); }
			else { SetVector(Pos, 2.0, -4.0, 5.0), SetVector(Ang, -15.0, 90.0, 180.0); }
		}
		case 2: //Slot2
		{
			SetVariantString("molotov");
			AcceptEntityInput(entity, "SetParentAttachment", entity, entity, 0);
			if(L4D2Version) { SetVector(Pos, 0.0, 4.0, 0.0), SetVector(Ang, 0.0, 90.0, 0.0); }
			else { SetVector(Pos, 0.0, 4.0, 0.0), SetVector(Ang, 0.0, 90.0, 0.0); }
		}
		case 3: //Slot3
		{
			SetVariantString("medkit");
			AcceptEntityInput(entity, "SetParentAttachment", entity, entity, 0);
			if(L4D2Version)
			{
				if(StrEqual(classname, "weapon_defibrillator")) { SetVector(Pos, -0.0, 10.0, 0.0), SetVector(Ang, -90.0, 0.0, 0.0); }
				else { SetVector(Pos, -0.0, 10.0, 0.0), SetVector(Ang, 0.0, 0.0, 0.0); }
			}
			else { SetVector(Pos, -0.0, 10.0, 0.0), SetVector(Ang, 0.0, 0.0, 0.0); }
		}
		case 4: //Slot4
		{
			SetVariantString("pills");
			AcceptEntityInput(entity, "SetParentAttachment", entity, entity, 0);
			if(L4D2Version)
			{
				if(StrEqual(classname, "weapon_adrenaline")) { SetVector(Pos, 5.0, 3.0, 0.0), SetVector(Ang, 0.0, 90.0, 90.0); }
				else { SetVector(Pos, 5.0, 3.0,0.0), SetVector(Ang, 0.0, 90.0, 0.0); }
			}
			else { SetVector(Pos, 5.0, 3.0,0.0), SetVector(Ang, 0.0, 90.0, 0.0); }
		}
	}
	AcceptEntityInput(entity, "DisableShadow");
	TeleportEntity(entity, Pos, Ang, NULL_VECTOR);
	SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit_View);
	return entity;
}

public Action:Hook_SetTransmit_View(int entity, int client)
{
	if(IsClientInGame(client) && IsFakeClient(client))
		return Plugin_Handled;

	if(!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	new Float:T = GetEngineTime();

	static iEntOwner;
	iEntOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	if(iEntOwner != client)
		return Plugin_Continue;

	if(!IsSurvivorThirdPerson(client))
		return Plugin_Handled;

	if(!L4D2Version)
	{
		if(T-InHeal[client] < 5.0 || T-InRevive[client] < 5.0)
			return Plugin_Continue;
	}
	return Plugin_Continue;
}

AttachAllEquipment(client)
{
	if(!IsSurvivor(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return;

	for(new slot=0; slot<=4; slot++)
		ItemAttachEnt[client][slot] = CreateItemAttach(client, ItemName[client][slot], slot);
}

DropSecondaryItem(client)
{
	new Float:origin[3];
	GetClientEyePosition(client,origin);
	for(new slot=0; slot<=4; slot++)
	{
		if(!StrEqual(ItemName[client][slot], ""))
		{
			new ammo=ItemInfo[client][slot][0];
			new clip=ItemInfo[client][slot][1];
			new info1=ItemInfo[client][slot][2];
			new info2=ItemInfo[client][slot][3];
			if(slot==0)
			{
				if(L4D2Version) { DropPrimaryWeapon_l4d2(client,ItemName[client][slot], ammo, clip, info1, info2); }
				else { DropPrimaryWeapon_l4d1(client, ItemName[client][slot], ammo, clip); }
			}
			else
			{
				new ent = CreateWeaponEnt(ItemName[client][slot]);
				TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
				ActivateEntity(ent);
			}
		}
	}
}

SaveEquipment(i) //FOR AFK
{
	for(new slot=0; slot<=4; slot++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			BackupItemName[i][slot]=ItemName[i][slot];
			BackupItemInfo[i][slot][0]=ItemInfo[i][slot][0];
			BackupItemInfo[i][slot][1]=ItemInfo[i][slot][1];
			BackupItemInfo[i][slot][2]=ItemInfo[i][slot][2];
			BackupItemInfo[i][slot][3]=ItemInfo[i][slot][3];
		}
	}
}

SaveEquipmentAll() //FOR MAP TRANSITION
{
	for(new i=1; i<=MaxClients; i++)
	{
		for(new slot=0; slot<=4; slot++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				BackupItemName[i][slot]=ItemName[i][slot];
				BackupItemInfo[i][slot][0]=ItemInfo[i][slot][0];
				BackupItemInfo[i][slot][1]=ItemInfo[i][slot][1];
				BackupItemInfo[i][slot][2]=ItemInfo[i][slot][2];
				BackupItemInfo[i][slot][3]=ItemInfo[i][slot][3];
			}
		}
	}
}

LoadEquipment(i) //FOR ROUND START
{
	for(new slot=0; slot<=4; slot++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			ItemName[i][slot]=BackupItemName[i][slot];
			ItemInfo[i][slot][0]=BackupItemInfo[i][slot][0];
			ItemInfo[i][slot][1]=BackupItemInfo[i][slot][1];
			ItemInfo[i][slot][2]=BackupItemInfo[i][slot][2];
			ItemInfo[i][slot][3]=BackupItemInfo[i][slot][3];
		}
	}
}

LoadEquipmentAll() //FOR MISSION LOST
{
	for(new i=1; i<=MaxClients; i++)
	{
		for(new slot=0; slot<=4; slot++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				ItemName[i][slot]=BackupItemName[i][slot];
				ItemInfo[i][slot][0]=BackupItemInfo[i][slot][0];
				ItemInfo[i][slot][1]=BackupItemInfo[i][slot][1];
				ItemInfo[i][slot][2]=BackupItemInfo[i][slot][2];
				ItemInfo[i][slot][3]=BackupItemInfo[i][slot][3];
			}
		}
	}
}

#define model_weapon_rifle "models/w_models/weapons/w_rifle_m16a2.mdl"
#define model_weapon_rifle_sg552 "models/w_models/weapons/w_rifle_sg552.mdl"
#define model_weapon_rifle_desert "models/w_models/weapons/w_desert_rifle.mdl"
#define model_weapon_rifle_ak47 "models/w_models/weapons/w_rifle_ak47.mdl"
#define model_weapon_smg "models/w_models/weapons/w_smg_uzi.mdl"
#define model_weapon_smg_silenced "models/w_models/weapons/w_smg_a.mdl"
#define model_weapon_smg_mp5 "models/w_models/weapons/w_smg_mp5.mdl"
#define model_weapon_pumpshotgun "models/w_models/weapons/w_shotgun.mdl"
#define model_weapon_shotgun_chrome "models/w_models/weapons/w_pumpshotgun_A.mdl"
#define model_weapon_autoshotgun "models/w_models/weapons/w_autoshot_m4super.mdl"
#define model_weapon_shotgun_spas "models/w_models/weapons/w_shotgun_spas.mdl"
#define model_weapon_hunting_rifle "models/w_models/weapons/w_sniper_mini14.mdl"
#define model_weapon_sniper_scout "models/w_models/weapons/w_sniper_scout.mdl"
#define model_weapon_sniper_military "models/w_models/weapons/w_sniper_military.mdl"
#define model_weapon_sniper_awp "models/w_models/weapons/w_sniper_awp.mdl"
#define model_weapon_rifle_m60 "models/w_models/weapons/w_m60.mdl"
#define model_weapon_grenade_launcher "models/w_models/weapons/w_grenade_launcher.mdl"
#define model_weapon_pistol "models/w_models/weapons/w_pistol_A.mdl"
#define model_weapon_pistol_magnum "models/w_models/weapons/w_desert_eagle.mdl"
#define model_weapon_chainsaw "models/weapons/melee/w_chainsaw.mdl"
#define model_weapon_melee_fireaxe "models/weapons/melee/w_fireaxe.mdl"
#define model_weapon_melee_baseball_bat "models/weapons/melee/w_bat.mdl"
#define model_weapon_melee_crowbar "models/weapons/melee/w_crowbar.mdl"
#define model_weapon_melee_electric_guitar "models/weapons/melee/w_electric_guitar.mdl"
#define model_weapon_melee_cricket_bat "models/weapons/melee/w_cricket_bat.mdl"
#define model_weapon_melee_frying_pan  "models/weapons/melee/w_frying_pan.mdl"
#define model_weapon_melee_golfclub  "models/weapons/melee/w_golfclub.mdl"
#define model_weapon_melee_machete  "models/weapons/melee/w_machete.mdl"
#define model_weapon_melee_katana  "models/weapons/melee/w_katana.mdl"
#define model_weapon_melee_tonfa  "models/weapons/melee/w_tonfa.mdl"
#define model_weapon_melee_riotshield  "models/weapons/melee/w_riotshield.mdl"
#define model_weapon_molotov "models/w_models/weapons/w_eq_molotov.mdl"
#define model_weapon_pipe_bomb "models/w_models/weapons/w_eq_pipebomb.mdl"
#define model_weapon_vomitjar "models/w_models/weapons/w_eq_bile_flask.mdl"
#define model_weapon_first_aid_kit "models/w_models/weapons/w_eq_Medkit.mdl"
#define model_weapon_defibrillator "models/w_models/weapons/w_eq_defibrillator.mdl"
#define model_weapon_upgradepack_explosive "models/w_models/weapons/w_eq_explosive_ammopack.mdl"
#define model_weapon_upgradepack_incendiary "models/w_models/weapons/w_eq_incendiary_ammopack.mdl"
#define model_weapon_pain_pills "models/w_models/weapons/w_eq_painpills.mdl"
#define model_weapon_adrenaline "models/w_models/weapons/w_eq_adrenaline.mdl"

GetModelFromClass_l4d2(String:weapon[], String:model[LEN64], slot=0)
{
	if(slot==0)
	{
		if(StrEqual(weapon, "weapon_rifle"))strcopy(model, LEN64, model_weapon_rifle);
		else if(StrEqual(weapon, "weapon_rifle_sg552"))strcopy(model, LEN64, model_weapon_rifle_sg552);
		else if(StrEqual(weapon, "weapon_rifle_desert"))strcopy(model, LEN64, model_weapon_rifle_desert);
		else if(StrEqual(weapon, "weapon_rifle_ak47"))strcopy(model, LEN64, model_weapon_rifle_ak47);
		else if(StrEqual(weapon, "weapon_rifle_m60"))strcopy(model, LEN64, model_weapon_rifle_m60);
		else if(StrEqual(weapon, "weapon_smg"))strcopy(model, LEN64, model_weapon_smg);
		else if(StrEqual(weapon, "weapon_smg_silenced"))strcopy(model, LEN64, model_weapon_smg_silenced);
		else if(StrEqual(weapon, "weapon_smg_mp5"))strcopy(model, LEN64, model_weapon_smg_mp5);
		else if(StrEqual(weapon, "weapon_pumpshotgun"))strcopy(model, LEN64, model_weapon_pumpshotgun);
		else if(StrEqual(weapon, "weapon_shotgun_chrome"))strcopy(model, LEN64, model_weapon_shotgun_chrome);
		else if(StrEqual(weapon, "weapon_autoshotgun"))strcopy(model, LEN64, model_weapon_autoshotgun);
		else if(StrEqual(weapon, "weapon_shotgun_spas"))strcopy(model, LEN64, model_weapon_shotgun_spas);
		else if(StrEqual(weapon, "weapon_hunting_rifle"))strcopy(model, LEN64, model_weapon_hunting_rifle);
		else if(StrEqual(weapon, "weapon_sniper_scout"))strcopy(model, LEN64, model_weapon_sniper_scout);
		else if(StrEqual(weapon, "weapon_sniper_military"))strcopy(model, LEN64, model_weapon_sniper_military);
		else if(StrEqual(weapon, "weapon_sniper_awp"))strcopy(model, LEN64, model_weapon_sniper_awp);
		else if(StrEqual(weapon, "weapon_grenade_launcher"))strcopy(model, LEN64, model_weapon_grenade_launcher);
		else model="";
	}
	else if(slot==1)
	{
		if(StrEqual(weapon, "weapon_pistol"))strcopy(model, LEN64, model_weapon_pistol);
		else if(StrEqual(weapon, "weapon_pistol_magnum"))strcopy(model, LEN64, model_weapon_pistol_magnum);
		else if(StrEqual(weapon, "weapon_chainsaw"))strcopy(model, LEN64, model_weapon_chainsaw);
		else if(StrEqual(weapon, "weapon_melee_fireaxe"))strcopy(model, LEN64, model_weapon_melee_fireaxe);
		else if(StrEqual(weapon, "weapon_melee_baseball_bat"))strcopy(model, LEN64, model_weapon_melee_baseball_bat);
		else if(StrEqual(weapon, "weapon_melee_crowbar"))strcopy(model, LEN64, model_weapon_melee_crowbar);
		else if(StrEqual(weapon, "weapon_melee_electric_guitar"))strcopy(model, LEN64, model_weapon_melee_electric_guitar);
		else if(StrEqual(weapon, "weapon_melee_cricket_bat"))strcopy(model, LEN64, model_weapon_melee_cricket_bat);
		else if(StrEqual(weapon, "weapon_melee_frying_pan"))strcopy(model, LEN64, model_weapon_melee_frying_pan);
		else if(StrEqual(weapon, "weapon_melee_golfclub"))strcopy(model, LEN64, model_weapon_melee_golfclub);
		else if(StrEqual(weapon, "weapon_melee_machete"))strcopy(model, LEN64, model_weapon_melee_machete);
		else if(StrEqual(weapon, "weapon_melee_katana"))strcopy(model, LEN64, model_weapon_melee_katana);
		else if(StrEqual(weapon, "weapon_melee_tonfa"))strcopy(model, LEN64, model_weapon_melee_tonfa);
		else if(StrEqual(weapon, "weapon_melee_riotshield"))strcopy(model, LEN64, model_weapon_melee_riotshield);
		else model="";
	}
	else if(slot==2)
	{
		if(StrEqual(weapon, "weapon_molotov"))strcopy(model, LEN64, model_weapon_molotov);
		else if(StrEqual(weapon, "weapon_pipe_bomb"))strcopy(model, LEN64, model_weapon_pipe_bomb);
		else if(StrEqual(weapon, "weapon_vomitjar"))strcopy(model, LEN64, model_weapon_vomitjar);
		else model="";
	}
	else if(slot==3)
	{
		if(StrEqual(weapon, "weapon_first_aid_kit"))strcopy(model, LEN64, model_weapon_first_aid_kit);
		else if(StrEqual(weapon, "weapon_defibrillator"))strcopy(model, LEN64, model_weapon_defibrillator);
		else if(StrEqual(weapon, "weapon_upgradepack_explosive"))strcopy(model, LEN64, model_weapon_upgradepack_explosive);
		else if(StrEqual(weapon, "weapon_upgradepack_incendiary"))strcopy(model, LEN64, model_weapon_upgradepack_incendiary);
		else model="";
	}
	else if(slot==4)
	{
		if(StrEqual(weapon, "weapon_pain_pills"))strcopy(model, LEN64, model_weapon_pain_pills);
		else if(StrEqual(weapon, "weapon_adrenaline"))strcopy(model, LEN64, model_weapon_adrenaline);
		else model="";
	}
}

#define model1_weapon_rifle "models/w_models/weapons/w_rifle_m16a2.mdl"
#define model1_weapon_autoshotgun "models/w_models/weapons/w_autoshot_m4super.mdl"
#define model1_weapon_pumpshotgun "models/w_models/Weapons/w_shotgun.mdl"
#define model1_weapon_hunting_rifle "models/w_models/weapons/w_sniper_mini14.mdl"
#define model1_weapon_smg "models/w_models/Weapons/w_smg_uzi.mdl"
#define model1_weapon_pistol "models/w_models/Weapons/w_pistol_1911.mdl"
#define model1_weapon_molotov "models/w_models/weapons/w_eq_molotov.mdl"
#define model1_weapon_pipe_bomb "models/w_models/weapons/w_eq_pipebomb.mdl"
#define model1_weapon_first_aid_kit "models/w_models/weapons/w_eq_Medkit.mdl"
#define model1_weapon_pain_pills "models/w_models/weapons/w_eq_painpills.mdl"

GetModelFromClass_l4d1(String:weapon[], String:model[LEN64],slot=0)
{
	if(slot==0)
	{
		if(StrEqual(weapon, "weapon_rifle"))strcopy(model, LEN64, model1_weapon_rifle);
		else if(StrEqual(weapon, "weapon_autoshotgun"))strcopy(model, LEN64, model1_weapon_autoshotgun);
		else if(StrEqual(weapon, "weapon_pumpshotgun"))strcopy(model, LEN64, model1_weapon_pumpshotgun);
		else if(StrEqual(weapon, "weapon_hunting_rifle"))strcopy(model, LEN64, model1_weapon_hunting_rifle);
		else if(StrEqual(weapon, "weapon_smg"))strcopy(model, LEN64, model1_weapon_smg);
		else model="";
	}
	else if(slot==1)
	{
		if(StrEqual(weapon, "weapon_pistol"))strcopy(model, LEN64, model1_weapon_pistol);
		else model="";
	}
	else if(slot==2)
	{
		if(StrEqual(weapon, "weapon_molotov"))strcopy(model, LEN64, model1_weapon_molotov);
		else if(StrEqual(weapon, "weapon_pipe_bomb"))strcopy(model, LEN64, model1_weapon_pipe_bomb);
		else model="";
	}
	else if(slot==3)
	{
		if(StrEqual(weapon, "weapon_first_aid_kit"))strcopy(model, LEN64, model1_weapon_first_aid_kit);
		else model="";
	}
	else if(slot==4)
	{
		if(StrEqual(weapon, "weapon_pain_pills"))strcopy(model, LEN64, model1_weapon_pain_pills);
		else model="";
	}
}

GetItemClass(ent, String:classname[LEN64])
{
	classname="";
	if(ent > 0)
	{
		GetEdictClassname(ent, classname, LEN64);
		if(StrEqual(classname, "weapon_melee"))
		{
			decl String:model[128];
			GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
			if(StrContains(model, "fireaxe")>=0)classname="weapon_melee_fireaxe";
			else if(StrContains(model, "v_bat")>=0)	classname="weapon_melee_baseball_bat";
			else if(StrContains(model, "crowbar")>=0)classname="weapon_melee_crowbar";
			else if(StrContains(model, "electric_guitar")>=0)classname="weapon_melee_electric_guitar";
			else if(StrContains(model, "cricket_bat")>=0)classname="weapon_melee_cricket_bat";
			else if(StrContains(model, "frying_pan")>=0)classname="weapon_melee_frying_pan";
			else if(StrContains(model, "golfclub")>=0)classname="weapon_melee_golfclub";
			else if(StrContains(model, "machete")>=0)classname="weapon_melee_machete";
			else if(StrContains(model, "katana")>=0)classname="weapon_melee_katana";
			else if(StrContains(model, "tonfa")>=0)classname="weapon_melee_tonfa";
			else if(StrContains(model, "riotshield")>=0)classname="weapon_melee_riotshield";
			else classname="";
		}
	}
}

CreateWeaponEnt(String:classname[])
{
	if(StrEqual(classname, "")) return 0;
	if(StrContains(classname, "weapon_melee_")<0)
	{
		new ent=CreateEntityByName(classname);
		DispatchSpawn(ent);
		return ent;
	}
	else
	{
		new ent=CreateEntityByName("weapon_melee");
		if(StrEqual(classname, "weapon_melee_fireaxe"))DispatchKeyValue( ent, "melee_script_name", "fireaxe");
		else if(StrEqual(classname, "weapon_melee_baseball_bat"))DispatchKeyValue( ent, "melee_script_name", "baseball_bat");
		else if(StrEqual(classname, "weapon_melee_crowbar"))DispatchKeyValue( ent, "melee_script_name", "crowbar");
		else if(StrEqual(classname, "weapon_melee_electric_guitar"))DispatchKeyValue( ent, "melee_script_name", "electric_guitar");
		else if(StrEqual(classname, "weapon_melee_cricket_bat"))DispatchKeyValue( ent, "melee_script_name", "cricket_bat");
		else if(StrEqual(classname, "weapon_melee_frying_pan"))DispatchKeyValue( ent, "melee_script_name", "frying_pan");
		else if(StrEqual(classname, "weapon_melee_golfclub"))DispatchKeyValue( ent, "melee_script_name", "golfclub");
		else if(StrEqual(classname, "weapon_melee_machete"))DispatchKeyValue( ent, "melee_script_name", "machete");
		else if(StrEqual(classname, "weapon_melee_katana"))DispatchKeyValue( ent, "melee_script_name", "katana");
		else if(StrEqual(classname, "weapon_melee_tonfa"))DispatchKeyValue( ent, "melee_script_name", "tonfa");
		else if(StrEqual(classname, "weapon_melee_riotshield"))DispatchKeyValue( ent, "melee_script_name", "riotshield");
		DispatchSpawn(ent);
		return ent;
	}
}

public OnMapStart()
{
	if(L4D2Version)
	{
		PrecacheModel(model_weapon_rifle);
		PrecacheModel(model_weapon_rifle_sg552);
		PrecacheModel(model_weapon_rifle_desert);
		PrecacheModel(model_weapon_rifle_ak47);
		PrecacheModel(model_weapon_rifle_m60);
		PrecacheModel(model_weapon_smg);
		PrecacheModel(model_weapon_smg_silenced);
		PrecacheModel(model_weapon_smg_mp5);
		PrecacheModel(model_weapon_pumpshotgun);
		PrecacheModel(model_weapon_shotgun_chrome);
		PrecacheModel(model_weapon_autoshotgun);
		PrecacheModel(model_weapon_shotgun_spas);
		PrecacheModel(model_weapon_hunting_rifle);
		PrecacheModel(model_weapon_sniper_scout);
		PrecacheModel(model_weapon_sniper_military);
		PrecacheModel(model_weapon_sniper_awp);
		PrecacheModel(model_weapon_grenade_launcher);
		
		PrecacheModel(model_weapon_pistol);
		PrecacheModel(model_weapon_pistol_magnum);
		PrecacheModel(model_weapon_chainsaw);
		
		PrecacheModel(model_weapon_melee_fireaxe);
		PrecacheModel(model_weapon_melee_baseball_bat);
		PrecacheModel(model_weapon_melee_crowbar);
		PrecacheModel(model_weapon_melee_electric_guitar);
		PrecacheModel(model_weapon_melee_cricket_bat);
		PrecacheModel(model_weapon_melee_frying_pan);
		PrecacheModel(model_weapon_melee_golfclub);
		PrecacheModel(model_weapon_melee_machete);
		PrecacheModel(model_weapon_melee_katana);
		PrecacheModel(model_weapon_melee_tonfa);
		PrecacheModel(model_weapon_melee_riotshield);
		
		PrecacheModel(model_weapon_molotov);
		PrecacheModel(model_weapon_pipe_bomb);
		PrecacheModel(model_weapon_vomitjar);
		
		PrecacheModel(model_weapon_first_aid_kit);
		PrecacheModel(model_weapon_defibrillator);
		PrecacheModel(model_weapon_upgradepack_explosive);
		PrecacheModel(model_weapon_upgradepack_incendiary);
		PrecacheModel(model_weapon_pain_pills);
		PrecacheModel(model_weapon_adrenaline);

		PrecacheGeneric( "scripts/melee/baseball_bat.txt", true);
		PrecacheGeneric( "scripts/melee/cricket_bat.txt", true);
		PrecacheGeneric( "scripts/melee/crowbar.txt", true);
		PrecacheGeneric( "scripts/melee/electric_guitar.txt", true);
		PrecacheGeneric( "scripts/melee/fireaxe.txt", true);
		PrecacheGeneric( "scripts/melee/frying_pan.txt", true);
		PrecacheGeneric( "scripts/melee/golfclub.txt", true);
		PrecacheGeneric( "scripts/melee/katana.txt", true);
		PrecacheGeneric( "scripts/melee/machete.txt", true);
		PrecacheGeneric( "scripts/melee/tonfa.txt", true);
		PrecacheGeneric( "scripts/melee/riotshield.txt", true);
	}
	else
	{
		PrecacheModel(model1_weapon_rifle);
		PrecacheModel(model1_weapon_autoshotgun);
		PrecacheModel(model1_weapon_pumpshotgun);
		PrecacheModel(model1_weapon_hunting_rifle);
		PrecacheModel(model1_weapon_smg);
		PrecacheModel(model1_weapon_pistol);
		PrecacheModel(model1_weapon_molotov);
		PrecacheModel(model1_weapon_pipe_bomb);
		PrecacheModel(model1_weapon_first_aid_kit);
		PrecacheModel(model1_weapon_pain_pills);
	}

	for (new client = 1; client <= MaxClients; client++)
	{
		AfkFix[client] = false;
		RescueFix[client] = false;
		RoundStart[client] = true;
	}
}

/*AFK RELATED CODE*/
public enter_afk_pre_player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));

	if(IsClientInGame(client))
	{
		RemoveItemAttach(client, -1);
		if(GetConVarInt(l4d_me_afk_save) == 1) { SaveEquipment(client); } else { ResetClientState(client); }
		if(GetConVarInt(l4d_me_view) == 1 && !IsFakeClient(client)) { AfkFix[client] = true; }
	}
}

public exit_afk_post_bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));

	if(IsClientInGame(client))
	{
		RemoveItemAttach(client, -1);
		if(GetConVarInt(l4d_me_afk_save) == 1) { LoadEquipment(client); } else { ResetClientState(client); }
		if(GetConVarInt(l4d_me_view) == 1 && !IsFakeClient(client)) { CreateTimer(0.5, FixWeaponView, client, TIMER_FLAG_NO_MAPCHANGE); }
	}
}
/*AFK RELATED CODE*/

public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==2)
	{
		RemoveItemAttach(client,-1);
		DropSecondaryItem(client);
	}
	ResetClientState(client);
	DeathFix[client] = true; //FIXES THIRDPERSONSHOULDER BUG AFTER DEATH AND MAPCHANGE
}

/*FIXES THIRDPERSONSHOULDER VIEW BUG AFTER RESCUE*/
public Action:survivor_rescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	RescueFix[client] = true;
}

public Action:mission_lost(Handle:event, const String:strName[], bool:DontBroadcast)
{
	LoadEquipmentAll();
}

public Action:map_transition(Handle:event, const String:name[], bool:dontBroadcast)
{
	SaveEquipmentAll();
}

/*
public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{

}

public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{

}
*/

public Action:player_spawn(Handle:event, const String:name[], bool:dont_broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsClientInGame(client))
	{
		CreateTimer(5.0, FixWeaponView, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

/*REMOVE ALL EXTRA EQUIPMENT FROM FULLY DISCONNECTED CLIENTS*/
public Action:player_disconnect(Handle:event, const String:name[], bool:dont_broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ResetClientState(client);
}

SetClientWeaponInfo_l4d1(client, ent, ammo, clip)
{
	if (ent > 0)
	{
		new String:weapon[32];
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(ent, weapon, 32);
		SetEntProp(ent, Prop_Send, "m_iClip1", clip);
		if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun"))
		{
			SetEntData(client, ammoOffset+(6*4), ammo);
		}
		else if (StrEqual(weapon, "weapon_smg"))
		{
			SetEntData(client, ammoOffset+(5*4), ammo);
		}
		else if (StrEqual(weapon, "weapon_rifle"))
		{
			SetEntData(client, ammoOffset+(3*4), ammo);
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle"))
		{
			SetEntData(client, ammoOffset+(2*4), ammo);
		}
		else if (StrEqual(weapon, "weapon_pistol"))
		{
			SetEntProp(ent, Prop_Send, "m_hasDualWeapons", ammo );
		}
	}
}

SetClientWeaponInfo_l4d2(client, ent ,  ammo,  clip, upgradeBit, upammo)
{
	if (ent > 0 && GetClientTeam(client) == 2)
	{
		new String:weapon[32];
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(ent, weapon, 32);
		SetEntProp(ent, Prop_Send, "m_iClip1", clip);
		SetEntProp(ent, Prop_Send, "m_upgradeBitVec", upgradeBit);
		SetEntProp(ent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo);
		if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
		{
			SetEntData(client, ammoOffset+(12), ammo);
		}
		if (StrEqual(weapon, "weapon_rifle_m60"))
		{
			SetEntData(client, ammoOffset+(12), ammo);
		}
		else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
		{
			SetEntData(client, ammoOffset+(20), ammo);
		}
		else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
		{
			SetEntData(client, ammoOffset+(28), ammo);
		}
		else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
		{
			SetEntData(client, ammoOffset+(32), ammo);
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle"))
		{
			SetEntData(client, ammoOffset+(36), ammo);
		}
		else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
		{
			SetEntData(client, ammoOffset+(40), ammo);
		}
		else if (StrEqual(weapon, "weapon_grenade_launcher"))
		{
			SetEntData(client, ammoOffset+(68), ammo);
		}
		else if (StrEqual(weapon, "weapon_pistol"))
		{
			SetEntProp(ent, Prop_Send, "m_hasDualWeapons", ammo );
		}
	}
}

GetClientWeaponInfo_l4d1(client ,ent, &ammo, &clip)
{
	if (ent > 0)
	{
		new String:weapon[32];
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(ent, weapon, 32);
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
			if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun"))
			{
				ammo = GetEntData(client, ammoOffset+(6*4));
			}
			else if (StrEqual(weapon, "weapon_smg"))
			{
				ammo = GetEntData(client, ammoOffset+(5*4));
			}
			else if (StrEqual(weapon, "weapon_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(3*4));
			}
			else if (StrEqual(weapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(2*4));
			}
			else if (StrEqual(weapon, "weapon_pistol"))
			{
				ammo = GetEntProp(ent, Prop_Send, "m_hasDualWeapons" );
			}
		}
	}
}

GetClientWeaponInfo_l4d2(client, ent, &ammo, &clip, &upgradeBit, &upammo)
{
	if (ent > 0 && GetClientTeam(client) == 2)
	{
		new String:weapon[32];
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(ent, weapon, 32);
		upgradeBit = GetEntProp(ent, Prop_Send, "m_upgradeBitVec");
		upammo = GetEntProp(ent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
		clip = GetEntProp(ent, Prop_Send, "m_iClip1");
		
		if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") ||
			StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_rifle_m60"))
		{
			ammo = GetEntData(client, ammoOffset+(12));
		}
		else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
		{
			ammo = GetEntData(client, ammoOffset+(20));
		}
		else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
		{
			ammo = GetEntData(client, ammoOffset+(28));
		}
		else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
		{
			ammo = GetEntData(client, ammoOffset+(32));
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle"))
		{
			ammo = GetEntData(client, ammoOffset+(36));
		}
		else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
		{
			ammo = GetEntData(client, ammoOffset+(40));
		}
		else if (StrEqual(weapon, "weapon_grenade_launcher"))
		{
			ammo = GetEntData(client, ammoOffset+(68));
		}
		else if (StrEqual(weapon, "weapon_pistol"))
		{
			ammo = GetEntProp(ent, Prop_Send, "m_hasDualWeapons");
		}
	}
}

DropPrimaryWeapon_l4d1(client, String:weapon[LEN64] ,ammo, clip)
{
	new bool:Drop=false;
	if (StrEqual(weapon, "weapon_pumpshotgun") ||
		StrEqual(weapon, "weapon_autoshotgun") ||
		StrEqual(weapon, "weapon_smg") ||
		StrEqual(weapon, "weapon_rifle") ||
		StrEqual(weapon, "weapon_hunting_rifle"))
	{
		Drop=true;
	}
 	if(Drop)
	{
		new index = CreateEntityByName(weapon);
		new Float:origin[3];
		GetClientEyePosition(client,origin);
		DispatchSpawn(index);
		TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(index);
		SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
		SetEntProp(index, Prop_Send, "m_iClip1", clip);
	}
}

DropPrimaryWeapon_l4d2(client, String:weapon[LEN64] ,ammo, clip,  upgradeBit, upammo)
{
	new bool:Drop=false;
	if (StrEqual(weapon, "weapon_grenade_launcher") ||
		StrEqual(weapon, "weapon_rifle_m60") ||
		StrEqual(weapon, "weapon_smg") ||
		StrEqual(weapon, "weapon_smg_silenced") ||
		StrEqual(weapon, "weapon_smg_mp5") ||
		StrEqual(weapon, "weapon_rifle") ||
		StrEqual(weapon, "weapon_rifle_sg552") ||
		StrEqual(weapon, "weapon_rifle_desert") ||
		StrEqual(weapon, "weapon_rifle_ak47") ||
		StrEqual(weapon, "weapon_pumpshotgun") ||
		StrEqual(weapon, "weapon_shotgun_chrome") ||
		StrEqual(weapon, "weapon_autoshotgun") ||
		StrEqual(weapon, "weapon_shotgun_spas") ||
		StrEqual(weapon, "weapon_hunting_rifle") ||
		StrEqual(weapon, "weapon_sniper_scout") ||
		StrEqual(weapon, "weapon_sniper_military") ||
		StrEqual(weapon, "weapon_sniper_awp"))
	{
		Drop=true;
	}
	if(Drop)
	{
		new index = CreateEntityByName(weapon);
		new Float:origin[3];
		GetClientEyePosition(client,origin);
		DispatchSpawn(index);
		TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(index);
		SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
		SetEntProp(index, Prop_Send, "m_iClip1", clip);
		upgradeBit+=0;
		upammo+=0;
	}
}

ResetClientState(i)
{
	for(new slot=0; slot<=4; slot++)
	{
		ItemName[i][slot]="";
		ItemInfo[i][slot][0]=0;
		ItemInfo[i][slot][1]=0;
		ItemInfo[i][slot][2]=0;
		ItemInfo[i][slot][3]=0;
		ItemAttachEnt[i][slot]=0;
	}
	InHeal[i]=0.0;
	InRevive[i]=0.0;
	LastButton[i]=0;
	SwapTime[i]=0.0;
	PressingTime[i]=0.0;
	PressStartTime[i]=0.0;
	LastMeSwitchTime[i]=0.0;
	LastSwitchTime[i]=0.0;
	ThrowTime[i]=0.0;
}

ResetClientStateAll()
{
	for(new i=1; i <= MaxClients; i++)
	{
		ResetClientState(i);
	}
}

GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version=true;
	}
	else
	{
		L4D2Version=false;
	}
	GameMode+=0;
}

public Action:heal_begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	InHeal[player]=GetEngineTime();
}

public Action:heal_end(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	InHeal[player]=0.0;
}

public Action:revive_begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	InRevive[player]=GetEngineTime();
}

public Action:revive_end(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	InRevive[player]=0.0;
}

public Action:heal_success(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	CreateTimer(0.1, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:molotov_thrown(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	CreateTimer(1.5, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:adrenaline_used(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	CreateTimer(0.1, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:pills_used (Handle:event, const String:name[], bool:dontBroadcast)
{
 	new player = GetClientOfUserId(GetEventInt(event, "userid"));
 	CreateTimer(0.1, DelayRestore, player, TIMER_FLAG_NO_MAPCHANGE);
}

IsValidClient(client, team=0, bool:alive=true)
{
	if(client > 0 && client <= MaxClients)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client)!=team && team!=0)return false;
			if(!IsPlayerAlive(client) && alive)return false;
			return true;
		}
	}
	return false;
}

IsValidEnt(ent)
{
	if(ent > 0 && IsValidEdict(ent) && IsValidEntity(ent)) { return true; }
	else { return false; }
}

IsValidEntS(ent, String:classname[LEN64])
{
	if(IsValidEnt(ent))
	{
		decl String:name[LEN64];
		GetEdictClassname(ent, name, LEN64);
		if(StrEqual(classname, name)) { return true; }
	}
	return false;
}

static bool:IsSurvivorThirdPerson(iClient)
{
	if(bThirdPerson[iClient]) //FOR THIRDPERSONSHOULDER COMMAND
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_TimeForceExternalView") > 0) //FOR THIRDPERSON
		return true;
	if(GetEntProp(iClient, Prop_Send, "m_isHangingFromLedge") > 0) //FOR LEDGE
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_isIncapacitated") > 0) //FOR INCAP
		return true;
	if(GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > -1.0) //FOR STAGGER
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_tongueOwner") > 0) //FOR SMOKER
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker") > 0) //FOR HUNTER
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker") > 0) //FOR JOCKEY
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_carryAttacker") > 0) //FOR CHARGER CARRY
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker") > 0) //FOR CHARGER PUMMEL
		return true;
	if(GetEntPropEnt(iClient, Prop_Send, "m_reviveTarget") > 0) //FOR HELPING SOMEONE
		return true;

	switch(GetEntProp(iClient, Prop_Send, "m_iCurrentUseAction"))
	{
		case 1:
		{
			static iTarget;
			iTarget = GetEntPropEnt(iClient, Prop_Send, "m_useActionTarget");
			
			if(iTarget == GetEntPropEnt(iClient, Prop_Send, "m_useActionOwner"))
				return true;
			else if(iTarget != iClient)
				return true;
		}
		case 4, 6, 7, 8, 9, 10:
			return true;
	}
	
	decl String:sModel[64];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	switch(sModel[29])
	{
		case 'b'://nick
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 620, 667, 671, 672, 626, 625, 624, 623, 622, 621, 661:
					return true;
			}
		}
		case 'd'://rochelle
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 629, 674, 678, 679, 630, 631, 632, 633, 634, 668, 677:
					return true;
			}
		}
		case 'c'://coach
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 621, 656, 660, 661, 622, 623, 624, 625, 626, 650:
					return true;
			}
		}
		case 'h'://ellis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 625, 671, 675, 676, 626, 627, 628, 629, 630, 631, 665:
					return true;
			}
		}
		case 'v'://bill
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 528, 759, 763, 764, 529, 530, 531, 532, 533, 534, 753:
					return true;
			}
		}
		case 'n'://zoey
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 537, 819, 823, 824, 538, 539, 540, 541, 542, 543, 813:
					return true;
			}
		}
		case 'e'://francis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 531, 762, 766, 767, 532, 533, 534, 535, 536, 537, 756:
					return true;
			}
		}
		case 'a'://louis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 528, 759, 763, 764, 529, 530, 531, 532, 533, 534, 753:
					return true;
			}
		}
		case 'w'://adawong
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 629, 674, 678, 679, 630, 631, 632, 633, 634:
					return true;
			}
		}
	}
	return false;
}

stock bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool:IsAliveSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2;
}

/*
stock bool:IsValidSurvivorBot(client)
{
	return (0 < client <= MaxClients && IsFakeClient(client) && GetClientTeam(client) == 2);
}

static bool:IsSurvivorBot(client)
{
	if(0 < client <= MaxClients && IsFakeClient(client) && GetClientTeam(client) == 2)
		return true;
	return false;
}

stock bool:IsValidSpectator(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1);
}

stock bool:IsValidSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool:IsValidSurvivorBot(client)
{
	return (0 < client <= MaxClients && IsFakeClient(client) && GetClientTeam(client) == 2);
}

stock bool:IsValidInfected(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}

stock bool:IsValidInfectedBot(client)
{
	return (0 < client <= MaxClients && IsFakeClient(client) && GetClientTeam(client) == 3);
}
*/

/*---------->>>>>>>>>>NOTES<<<<<<<<<<----------
IsClientInGame(client); //Returns if a certain player has entered the game.
IsPlayerAlive(client); //Returns if the client is alive or dead.
IsFakeClient(client); //Returns if a certain player is a fake client.
IsClientObserver(client); //Returns if a certain player is an observer/spectator.
IsClientInKickQueue(client); //Returns if a client is in the "kick queue".

GetClientTeam(client); //Retrieves a client's team index.
GetClientHealth(client); //Returns the client's health.
GetClientModel(client, String:model[], maxlen); //Returns the client's model name.
GetClientWeapon(client, String:weapon[], maxlen); //Returns the client's weapon name.
*/