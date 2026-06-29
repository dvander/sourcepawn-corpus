#include <sourcemod>
#include <AG>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION "1.5.1"

#define UPDATE_URL    "http://goldtreeservers.net/download/sourcemod/AG/updater.txt"

new NoBlock;
new bool:g_isHooked;

static bool:Godmode[MAXPLAYERS+1];
static bool:Buddha[MAXPLAYERS+1];
static bool:Invisible[MAXPLAYERS+1];

new Handle:c_RemovalType;
new Handle:c_NoclipGod;
new Handle:c_Updater;
new Handle:c_Spawn;
new Handle:c_RememberGodmode;
new Handle:c_NoclipInvisible;
new Handle:c_C4Hold;
new Handle:c_CanPickupItems;

static g_RemovalType = 0;
static g_NoclipGod = 1;
static g_Updater = 1;
static g_Spawn = 0;
static g_RememberGodmode = 1;
static g_NoclipInvisible = 0;
static g_C4Hold = 0;
static g_CanPickupItems = 1;

enum GameType {
	Game_Unknown = -1,
	Game_TF,
	Game_CSS,
	Game_HL2MP,
};

new GameType:gamemod = Game_Unknown;

public Plugin:myinfo =
{
	name = "Advanced Godmode",
	author = "isokissa3",
	description = "Give godmode or buddha",
	version = PLUGIN_VERSION,
	url = "http://goldtreeservers.net"
}

public OnPluginStart()
{
	get_server_mod();
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
	
	NoBlock = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (NoBlock == -1)
	{
		g_isHooked = false;
		PrintToServer("* FATAL ERROR: Failed to get offset for CBaseEntity::m_CollisionGroup");
	}
	else
	{
		g_isHooked = true;
	}
	
	CreateConVar("sm_ag_version", PLUGIN_VERSION, "Version of Advanced Godmode", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	c_RemovalType = CreateConVar("sm_ag_removaltype", "0", "0 - Disabled. 1 - Removes godmode when an attack key is pressed. 2 - Removes godmode when a player hurts a player. 3 - Removes godmode when a player killed a player.");
	c_NoclipGod = CreateConVar("sm_ag_noclipgod", "1", "0 - Disabled. 1 - Gives godmode to admin whenever he activates noclip.");
	c_Updater = CreateConVar("sm_ag_auto_update", "1", "Enables automatic plugin updating (has no effect if Updater is not installed)");
	c_Spawn = CreateConVar("sm_ag_spawn", "0", "0 - Players automatically spawn with mortal. 1 - Players spawn automatically with godmode. 2 - Players spawn automatically with buddha.");
	c_RememberGodmode = CreateConVar("sm_ag_remembergodmode", "1", "0 - Disabled. 1 - If player somehow dies and he had godmode he will be given godmode automatically when he respawns.");
	c_NoclipInvisible = CreateConVar("sm_ag_noclipinvisible", "0", "0 - Disabled. 1 - Makes admin invisible when he activates noclip.");
	c_C4Hold = CreateConVar("sm_ag_c4", "0", "0 - Admin can't hold C4 when on noclip. 1 - Admin can hold C4 when on noclip.");
	c_CanPickupItems = CreateConVar("sm_ag_pickupitems", "1", "0 - Admin can't pickup items when on noclip. 1 - Admin can pickup items when on noclip.");
	
	HookConVarChange(c_RemovalType, ConvarChanged);
	HookConVarChange(c_NoclipGod, ConvarChanged);
	HookConVarChange(c_Updater, ConvarChanged);
	HookConVarChange(c_Spawn, ConvarChanged);
	HookConVarChange(c_RememberGodmode, ConvarChanged);
	HookConVarChange(c_NoclipInvisible, ConvarChanged);
	HookConVarChange(c_C4Hold, ConvarChanged);
	HookConVarChange(c_CanPickupItems, ConvarChanged);
	
	RegAdminCmd("sm_god", Command_godmode, ADMFLAG_SLAY, "[SM] Usage: sm_god");
	RegAdminCmd("sm_buddha", Command_buddha, ADMFLAG_SLAY, "[SM] Usage: sm_buddha");
	RegConsoleCmd("sm_mortal", Command_mortal, "[SM] Usage: sm_mortal");
	
	if (gamemod == Game_TF)
	{
		HookEvent("object_deflected", Object_Deflected);
		
		HookUserMessage(GetUserMessageId("PlayerJarated"), Event_PlayerJarated);
	}
	
	if (gamemod == Game_TF || gamemod == Game_CSS)
	{
		HookEvent("player_death", Player_Death);
		HookEvent("player_hurt", Player_Hurt);
		HookEvent("player_spawn", Player_Spawn);
	}
	
	if (gamemod == Game_CSS)
	{
		HookEvent("player_blind", Player_Blind);
		HookEvent("item_pickup", Item_Pickup);
		HookEvent("bomb_pickup", Bomb_Pickup);
	}
	
	AddCommandListener(Command_Noclip, "noclip");
	AddCommandListener(Command_Noclip, "sm_noclip"); 
	
	AutoExecConfig();
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
}

public Updater_OnPluginUpdated()
{
	ReloadPlugin();
}

public Action:Updater_OnPluginDownloading() {
	if(g_Updater == 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public ConvarChanged(Handle:Convar, const String:OldValue[], const String:NewValue[])
{
	if(Convar == c_RemovalType)
	g_RemovalType = StringToInt(NewValue);
	
	if(Convar == c_NoclipGod)
	g_NoclipGod = StringToInt(NewValue);
	
	if(Convar == c_Updater)
	g_Updater = StringToInt(NewValue);
	
	if(Convar == c_Spawn)
	g_Spawn = StringToInt(NewValue);
	
	if(Convar == c_RememberGodmode)
	g_RememberGodmode = StringToInt(NewValue);
	
	if(Convar == c_NoclipInvisible)
	g_NoclipInvisible = StringToInt(NewValue);
	
	if(Convar == c_C4Hold)
	g_C4Hold = StringToInt(NewValue);
	
	if(Convar == c_CanPickupItems)
	g_CanPickupItems = StringToInt(NewValue);
}

public Action:Command_godmode(client, args)
{
	if (args == 0 || !CheckCommandAccess(client, "sm_ag_other", ADMFLAG_SLAY, true))
	{
		if(Godmode[client] == false)
		{
			GiveGodmode(client);
		}
		else
		{
			MakeMortal(client);
		}
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_god [#userid|name] [0/1]");
		return Plugin_Handled;
	}
	
	new String:target[32];
	new String:toggle[3];
	GetCmdArg(1, target, sizeof(target));
	new onoff = -1;
	if (args > 1)
	{
		GetCmdArg(2, toggle, sizeof(toggle));
		onoff = StringToInt(toggle);
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
					target,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if (onoff == 1) //Turn on godmode
	{
		ShowActivity2(client, "[SM] ","Enabled God Mode on %s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			PrintToChat(target_list[i],"[SM] An admin has given you God Mode!");
			GiveGodmode(target_list[i]);
		}
	}
	else if (onoff == 0) //Turn off godmode
	{
		ShowActivity2(client, "[SM] ","Disabled God Mode on %s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			PrintToChat(target_list[i],"[SM] An admin has removed your God Mode!");
			MakeMortal(target_list[i]);
		}
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Toggled God Mode on %s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			if (Godmode[target_list[i]] != true) //Mortal or Buddha --> Turn on godmode
			{
				PrintToChat(target_list[i],"[SM] An admin has given you God Mode!");
				GiveGodmode(target_list[i]);
			}
			else //Turn off godmode
			{
				PrintToChat(target_list[i],"[SM] An admin has removed your God Mode!");
				MakeMortal(target_list[i]);
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_buddha(client, args)
{
	if (args == 0 || !CheckCommandAccess(client, "sm_ag_other", ADMFLAG_SLAY, true))
	{
		if(Buddha[client] == false)
		{
			GiveBuddha(client);
		}
		else
		{
			MakeMortal(client);
		}
		return Plugin_Handled;
	}
	
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_buddha [#userid|name] [0/1]");
		return Plugin_Handled;
	}
	
	new String:target[32];
	new String:toggle[3];
	GetCmdArg(1, target, sizeof(target));
	new onoff = -1;
	if (args > 1)
	{
		GetCmdArg(2, toggle, sizeof(toggle));
		onoff = StringToInt(toggle);
	}

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
					target,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if (onoff == 1) //Turn on buddha
	{
		ShowActivity2(client, "[SM] ","Enabled Buddha Mode on %s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			PrintToChat(target_list[i],"[SM] An admin has given you Buddha Mode!");
			GiveBuddha(target_list[i]);
		}
	}
	else if (onoff == 0) //Turn off buddha
	{
		ShowActivity2(client, "[SM] ","Disabled Buddha Mode on %s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			PrintToChat(target_list[i],"[SM] An admin has removed your Buddha Mode!");
			MakeMortal(target_list[i]);
		}
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Toggled Buddha Mode on %s", target_name);
		for (new i = 0; i < target_count; i++)
		{
			if (Buddha[target_list[i]] != true) //Mortal or Godmode --> Turn on buddha
			{
				PrintToChat(target_list[i],"[SM] An admin has given you Buddha Mode!");
				GiveBuddha(target_list[i]);
			}
			else //Turn off buddha
			{
				PrintToChat(target_list[i],"[SM] An admin has removed your God Mode!");
				MakeMortal(target_list[i]);
			}
		}
	}
	return Plugin_Handled;
}  

public Action:Command_mortal(client, args)
{
	MakeMortal(client);
}

public Action:OnPlayerRunCmd(client, &Buttons, &Impulse, Float:Vel[3], Float:Angles[3], &Weapon)
{
	if(g_RemovalType == 1)
	{
		if((Godmode[client] || Buddha[client]) && !(GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			if(IsPlayerAlive(client))
			{
				if(Buttons & (IN_ATTACK|IN_ATTACK2))
				{
					MakeMortal(client);
				}
			}
		}
	}
}

public Action:Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_RemovalType == 2)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if((Godmode[attacker] || Buddha[attacker]) && !(GetUserFlagBits(attacker) & ADMFLAG_ROOT))
		{
			if(client != 0 && IsClientInGame(client) && attacker != 0 && IsClientInGame(attacker))
			{
				MakeMortal(attacker);
			}
		}
	}
}

public Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_RemovalType == 3)
	{
		if((Godmode[attacker] || Buddha[attacker]) && !(GetUserFlagBits(attacker) & ADMFLAG_ROOT))
		{
			if(client != 0 && IsClientInGame(client) && attacker != 0 && IsClientInGame(attacker))
			{
				MakeMortal(attacker);
			}
		}
	}
	
	if((Godmode[client] || Buddha[client]) && g_RememberGodmode == 0)
	{
		Godmode[client] = false;
		Buddha[client] = false;
	}
}

public Object_Deflected(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ownerid = GetClientOfUserId(GetEventInt(event, "ownerid"));
	if (Godmode[ownerid] || Buddha[ownerid])
	{
		new Float:Vel[3];
		TeleportEntity(ownerid, NULL_VECTOR, NULL_VECTOR, Vel);
		TF2_RemoveCondition(ownerid, TFCond_Dazed);
		SetEntPropVector(ownerid, Prop_Send, "m_vecPunchAngle", Vel);
		SetEntPropVector(ownerid, Prop_Send, "m_vecPunchAngleVel", Vel);
	}
}

public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_Spawn == 0 && g_RememberGodmode == 0)
	{
		MakeMortal(client);
	}
	if (g_Spawn == 1 && g_RememberGodmode == 0)
	{
		GiveGodmode(client);
	}
	if (g_Spawn == 2 && g_RememberGodmode == 0)
	{
		GiveBuddha(client);
	}
	
	if (g_RememberGodmode == 1)
	{
		if (Godmode[client])
		{
			GiveGodmode(client);
		}
		if (Buddha[client])
		{
			GiveBuddha(client);
		}
	}
}

public GiveGodmode(client)
{
	Buddha[client] = false;
	Godmode[client] = true;
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
	PrintToChat(client,"\x01\x04God mode on")
	if (g_isHooked == true)
	{
		SetEntData(client, NoBlock, 2, 4, true);
	}
	if (gamemod == Game_TF)
	{
		new flags = GetEntityFlags(client)|FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
}

public GiveBuddha(client)
{
	Godmode[client] = false;
	Buddha[client] = true;
	SetEntProp(client, Prop_Data, "m_takedamage", 1, 1)
	PrintToChat(client,"\x01\x04Buddha Mode on")
	if (g_isHooked == true)
	{
		SetEntData(client, NoBlock, 2, 4, true);
	}
	if (gamemod == Game_TF)
	{
		new flags = GetEntityFlags(client)|FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
}

public MakeMortal(client)
{
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
	if(Godmode[client] == true)
	{
		PrintToChat(client,"\x01\x04God Mode Disabled")
	}
	if (Buddha[client] == true)
	{
		PrintToChat(client,"\x01\x04Buddha Mode Disabled")
	}
	Godmode[client] = false;
	Buddha[client] = false;
	if (g_isHooked == true)
	{
		SetEntData(client, NoBlock, 5, 4, true);
	}
	if (gamemod == Game_TF)
	{
		new flags = GetEntityFlags(client)&~FL_NOTARGET;
		SetEntityFlags(client, flags);
	}
}

public Native_IsPlayerOnGodmode(Handle:plugin, params)
{
	if (Godmode[GetNativeCell(1)] == true) return true;
	else return false;
}

public Native_IsPlayerOnBuddha(Handle:plugin, params)
{
	if (Buddha[GetNativeCell(1)] == true) return true;
	else return false;
}

public Native_IsPlayerMortal(Handle:plugin, params)
{
	if (Godmode[GetNativeCell(1)] == false && Buddha[GetNativeCell(1)] == false) return true;
	else return false;
}

public Native_GiveToPlayerGodmode(Handle:plugin, params)
{
	if (Godmode[GetNativeCell(1)] == false)
	{
		GiveGodmode(GetNativeCell(1));
		return true;
	}
	
	return -1;
}

public Native_GiveToPlayerBuddha(Handle:plugin, params)
{
	if (Buddha[GetNativeCell(1)] == false)
	{
		GiveBuddha(GetNativeCell(1));
		return true;
	}
	
	return -1;
}

public Native_MakePlayerMortal(Handle:plugin, params)
{
	MakeMortal(GetNativeCell(1));
	return true;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("AG");
	CreateNative("IsPlayerOnGodmode", Native_IsPlayerOnGodmode);
	CreateNative("IsPlayerOnBuddha", Native_IsPlayerOnBuddha);
	CreateNative("IsPlayerMortal", Native_IsPlayerMortal);
	CreateNative("GiveToPlayerGodmode", Native_GiveToPlayerGodmode);
	CreateNative("GiveToPlayerOnBuddha", Native_GiveToPlayerBuddha);
	CreateNative("MakePlayerMortal", Native_MakePlayerMortal);
	return APLRes_Success;
}

public Action:Event_PlayerJarated(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	BfReadByte(bf); //Need or its not working :/
	new victim = BfReadByte(bf);
	
	if (Godmode[victim] || Buddha[victim])
	{
		CreateTimer(0.0, RemoveJarate, any:victim);
	}
}

public Action:RemoveJarate(Handle:Timer, any:victim)
{
	if(IsClientInGame(victim) && IsPlayerAlive(victim))
	{
		TF2_RemoveCondition(victim, TFCond_Jarated);
		TF2_RemoveCondition(victim, TFCond_Milked);
	}
}

public Action:Command_Noclip(client, const String:cmd[], argc) 
{ 
	if (Invisible[client] == true)
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
	}
	CreateTimer(0.0, NoclipEvent, any:client);
}

public Action:NoclipEvent(Handle:Timer, any:client)
{
	if (g_NoclipGod)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			new MoveType:movetype = GetEntityMoveType(client);
			if (movetype == MOVETYPE_NOCLIP && GetUserFlagBits(client) & ADMFLAG_SLAY)
			{
				GiveGodmode(client);
				if (g_NoclipInvisible == 1)
				{
					InvisibleOn(client);
				}
			}
			else
			{
				MakeMortal(client);
				InvisibleOff(client);
			}
		}
	}
}

public get_server_mod()
{
	new String: game_folder[64];
	GetGameFolderName(game_folder, sizeof(game_folder));
	if (StrContains(game_folder, "cstrike", false) != -1)
	{
		gamemod = Game_CSS;
	}
	else if (strncmp(game_folder, "tf", 2, false) == 0)
	{
		gamemod = Game_TF;
	}
	else if (StrContains(game_folder, "hl2mp", false) != -1)
	{
		gamemod = Game_HL2MP;
	}
	else
	{
		LogToGame("Advanced Godmode: Mod not in detected list, using defaults");
	}
}

public Player_Blind(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (Godmode[client] || Buddha[client])
	{
		SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
	}
}

public InvisibleOn(client)
{
	Invisible[client] = true;
	new color[4];
	color = {255,255,255,0};
	if (gamemod == Game_HL2MP)
	{
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
	}
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	if(GetClientTeam(client) != 1)
	{
		if (g_CanPickupItems == 0)
		{
			RemoveAllWeapons(client);
		}
	}
}

public InvisibleOff(client)
{
	Invisible[client] = false;
	new color[4];
	color = {255,255,255,255};
	if(GetClientTeam(client) != 1)
	{
		if(IsPlayerAlive(client))
		{
			if (gamemod == Game_CSS)
			{
				if (GetClientTeam(client) == CS_TEAM_T && g_NoclipInvisible == 1)
				{
					GivePlayerItem(client, "weapon_knife");
					GivePlayerItem(client, "weapon_glock");
				}
				if (GetClientTeam(client) == CS_TEAM_CT && g_NoclipInvisible == 1)
				{
					GivePlayerItem(client, "weapon_knife");
					GivePlayerItem(client, "weapon_usp");
				}
			}
			if (gamemod == Game_HL2MP)
			{
				GivePlayerItem(client, "weapon_stunstick");
				GivePlayerItem(client, "weapon_physcannon");
				GivePlayerItem(client, "weapon_pistol");
				GivePlayerItem(client, "weapon_smg1");
			}
		}
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
		SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	}
}

public RemoveAllWeapons(client)
{
	new weaponIndex;
	for (new i = 0; i <= 5; i++)
	{
		while ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
		{
			if (gamemod == Game_CSS)
			{
				decl String:sClassName[128];  
				GetEdictClassname(weaponIndex, sClassName, sizeof(sClassName));
				if(StrEqual(sClassName, "weapon_c4"))  
				{
					CS_DropWeapon(client, weaponIndex, true);
				}
				else
				{
					RemovePlayerItem(client, weaponIndex);
					RemoveEdict(weaponIndex);
				}
			}
			else
			{
				RemovePlayerItem(client, weaponIndex);
				RemoveEdict(weaponIndex);
			}
		}
		
	}
}

public Item_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_C4Hold == 0)
	{
		new userid = GetClientOfUserId(GetEventInt(event, "userid"));
		new MoveType:movetype = GetEntityMoveType(userid);
		if (movetype == MOVETYPE_NOCLIP)
		{
			new weaponIndex;
			for (new i = 0; i <= 5; i++)
			{
				weaponIndex = GetPlayerWeaponSlot(userid, i)
				if (weaponIndex != -1)
				{
					CS_DropWeapon(userid, weaponIndex, true);
				}
			}
		}
	}
}

public Bomb_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_CanPickupItems == 0)
	{
		new userid = GetClientOfUserId(GetEventInt(event, "userid"));
		new MoveType:movetype = GetEntityMoveType(userid);
		if (movetype == MOVETYPE_NOCLIP)
		{
			CS_DropWeapon(userid, GetPlayerWeaponSlot(userid, 4), true);
		}
	}
}

public OnClientDisconnect(client)
{
	Invisible[client] = false;
	Godmode[client] = false;
	Buddha[client] = false;
}