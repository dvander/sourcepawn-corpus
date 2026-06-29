//──────────────────────────────────────────────────────────────────────────────
#pragma semicolon 1
//──────────────────────────────────────────────────────────────────────────────
#include <sourcemod>
#include <sdktools>
#include <tf2>
//──────────────────────────────────────────────────────────────────────────────
#define PLUGIN_VERSION "2.0.1"
//──────────────────────────────────────────────────────────────────────────────
#define FIREBALL	0 // Done
#define BATS 		1 // Done
#define PUMPKIN 	2 // Done
#define TELE 		3 // Done
#define LIGHTNING 	4 // Done
#define BOSS 		5 // Done
#define METEOR 		6 // Done
#define ZOMBIEH 	7 // Done
#define ZOMBIE 		8
#define PUMPKIN2 	9

// Amount of effects
// Currently not all spells used
#define EFFECTS		7

// Max used stings length
#define STR_LEN		100
//──────────────────────────────────────────────────────────────────────────────
#define LOG_PREFIX	"[Spells]"
#define CHAT_PREFIX	"\x01[\x07B262FFSpells\x01]"
//──────────────────────────────────────────────────────────────────────────────
public Plugin:myinfo = 
{
	name = "[TF2] Spells",
	author = "Mitch (base) & avi9526 (menu)",
	description = "Allows Players to shoot spells",
	version = PLUGIN_VERSION,
	url = "http://www.mitch.dev/"
}
//──────────────────────────────────────────────────────────────────────────────
// Global variables
//──────────────────────────────────────────────────────────────────────────────

new Handle:	cCheatOverride;

new Handle:	hVersion;

// Store individual player data needed to plugin
enum PlayerData
{
	TimeUsed[EFFECTS]	// when player last time used spell
};

enum Spell
{
	// Identifier
			ID,
	// Name
	String:	Name[STR_LEN],
	// Description
	String:	Desc[STR_LEN],
	// Global Handle Console Variable - Delay
	Handle:	hDelay,
	// Delay
			Delay,
	// CVar name
	String:	DelayCVar[STR_LEN]
};

new	Spells[EFFECTS][Spell];

// Array
new Players[MAXPLAYERS+1][PlayerData];
//──────────────────────────────────────────────────────────────────────────────
// Hook functions
//──────────────────────────────────────────────────────────────────────────────
public OnPluginStart()
{
	hVersion = CreateConVar("sm_spells_version", PLUGIN_VERSION, "Spells Version", FCVAR_PLUGIN | FCVAR_NOTIFY);
	if(hVersion != INVALID_HANDLE)
	{
		SetConVarString(hVersion, PLUGIN_VERSION);
	}
	//cCheatOverride = CreateConVar("sm_admin_spell_level", "a", "Level required to execute the spell commands",FCVAR_PLUGIN);
	
	InitSpellData();
	
	for(new i = 0; i < EFFECTS; i++)
	{
		Spells[i][hDelay] = CreateConVar(Spells[i][DelayCVar], "60", "How much player must wait before use spell again", _, true, 1.0, false, 100.0);
		Spells[i][Delay] = GetConVarInt(Spells[i][hDelay]);
		HookConVarChange(Spells[i][hDelay], OnConVarChanged);
	}
	
	// Spells menu
	RegConsoleCmd("sm_spells", Command_Menu, "Spells menu");
	RegConsoleCmd("sm_spell", Command_Menu, "Spells menu");
	
	//RegConsoleCmd("tf_test_spellindex",SpellCommand);
	//SetCommandFlags("tf_test_spellindex",GetCommandFlags("tf_test_spellindex")^FCVAR_CHEAT);
}
//──────────────────────────────────────────────────────────────────────────────
// If console variable changed - need change corresponding internal variables
public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	for(new i = 0; i < EFFECTS; i++)
	{
		if(convar == Spells[i][hDelay])
		{
			Spells[i][Delay] = StringToInt(newValue);
			LogAction(-1, -1, "%s %s now is %d", LOG_PREFIX, Spells[i][DelayCVar], Spells[i][Delay]);
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
public OnPluginEnd()
{
	ResetAllData();
}
//──────────────────────────────────────────────────────────────────────────────
public OnMapStart()
{
	ResetAllData();
}
//──────────────────────────────────────────────────────────────────────────────
public OnClientDisconnect(client)
{
	ResetPlayerData(client);
}
//──────────────────────────────────────────────────────────────────────────────
// Stocks
//──────────────────────────────────────────────────────────────────────────────
// Ckeck if client is normal player (human) that already in game, not bot or etc
stock IsValidClient(Client)
{
	if ((Client <= 0) || (Client > MaxClients) || (!IsClientInGame(Client)))
	{
		return false;
	}
	if (IsClientSourceTV(Client) || IsClientReplay(Client))
	{
		return false;
	}
	// Skip bots
	new String:Auth[32];
	GetClientAuthString(Client, Auth, sizeof(Auth));
	if (StrEqual(Auth, "BOT", false) || StrEqual(Auth, "STEAM_ID_PENDING", false) || StrEqual(Auth, "STEAM_ID_LAN", false))
	{
		return false;
	}
	return true;
}
//──────────────────────────────────────────────────────────────────────────────
// 0 - ready
// > 0 - delay
stock IsSpellReady(client, Index)
{
	// How much time passed since last use of spell menu
	new TimePass = GetTime() - Players[client][TimeUsed][Index];
	if(Players[client][TimeUsed][Index] && TimePass < Spells[Index][Delay])
	{
		// If less than delay - tell player to wait more
		return Spells[Index][Delay] - TimePass;
	}
	else
	{
		return 0;
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Variables support
//──────────────────────────────────────────────────────────────────────────────
InitSpellData()
{
	new i = 0;
	
	// Amount of this spells must be stored in EFFECTS constant
	
	Spells[i][ID] = TELE;
	Format(Spells[i][Name], STR_LEN, "transpose");
	Format(Spells[i][Desc], STR_LEN, "Transpose");
	Format(Spells[i][DelayCVar], STR_LEN, "sm_spelldelay_transpose");
	i++;
	
	//Spells[i][ID] = PUMPKIN2;
	//Format(Spells[i][Name], STR_LEN, "pumpkin");
	//Format(Spells[i][Desc], STR_LEN, "Pumpkin");
	//Format(Spells[i][DelayCVar], STR_LEN, "sm_spelldelay_pumpkin");
	//i++;
	
	Spells[i][ID] = FIREBALL;
	Format(Spells[i][Name], STR_LEN, "fireball");
	Format(Spells[i][Desc], STR_LEN, "Fireball");
	Format(Spells[i][DelayCVar], STR_LEN, "sm_spelldelay_fireball");
	i++;
	
	Spells[i][ID] = BATS;
	Format(Spells[i][Name], STR_LEN, "bats");
	Format(Spells[i][Desc], STR_LEN, "Bats");
	Format(Spells[i][DelayCVar], STR_LEN, "sm_spelldelay_bats");
	i++;
	
	//Spells[i][ID] = PUMPKIN;
	//Format(Spells[i][Name], STR_LEN, "pumpkins");
	//Format(Spells[i][Desc], STR_LEN, "Pumpkins");
	//Format(Spells[i][DelayCVar], STR_LEN, "sm_spelldelay_pumpkins");
	//i++;
	
	Spells[i][ID] = LIGHTNING;
	Format(Spells[i][Name], STR_LEN, "lightning");
	Format(Spells[i][Desc], STR_LEN, "Lightning");
	Format(Spells[i][DelayCVar], STR_LEN, "sm_spelldelay_lightning");
	i++;
	
	//Spells[i][ID] = ZOMBIEH;
	//Format(Spells[i][Name], STR_LEN, "skeletons");
	//Format(Spells[i][Desc], STR_LEN, "Skeletons");
	//Format(Spells[i][DelayCVar], STR_LEN, "sm_spelldelay_skeletons");
	//i++;
	
	Spells[i][ID] = ZOMBIE;
	Format(Spells[i][Name], STR_LEN, "skeleton");
	Format(Spells[i][Desc], STR_LEN, "Skeleton");
	Format(Spells[i][DelayCVar], STR_LEN, "sm_spelldelay_skeleton");
	i++;
	
	Spells[i][ID] = BOSS;
	Format(Spells[i][Name], STR_LEN, "monoculus");
	Format(Spells[i][Desc], STR_LEN, "Monoculus");
	Format(Spells[i][DelayCVar], STR_LEN, "sm_spelldelay_monoculus");
	i++;
	
	Spells[i][ID] = METEOR;
	Format(Spells[i][Name], STR_LEN, "meteors");
	Format(Spells[i][Desc], STR_LEN, "Meteor Shower");
	Format(Spells[i][DelayCVar], STR_LEN, "sm_spelldelay_meteors");
	i++;
}
//──────────────────────────────────────────────────────────────────────────────
ResetPlayerData(client)
{
	for(new Index = 0; Index < EFFECTS; Index++)
	{
		Players[client][TimeUsed][Index] = 0;
	}
}
//──────────────────────────────────────────────────────────────────────────────
ResetAllData()
{
	for(new cli=0; cli<MAXPLAYERS+1; cli++)
	{
		ResetPlayerData(cli);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Menu
//──────────────────────────────────────────────────────────────────────────────
// Console command to call menu
public Action:Command_Menu(client, args)
{
	if (!IsValidClient(client))
	{
		LogAction(-1, -1, "%s Wrong client '%L' triggered this function", LOG_PREFIX, client);
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s You must be alive", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	if(args == 0)
	{
		// Command called without arguments - show menu
		ShowMenu(client);
	}
	else
	{
		// Command called with argument -  1st argument must be a spell name
		
		new String:SpellName[STR_LEN];
		GetCmdArg(1, SpellName, sizeof(SpellName));
		
		new TimeWait;
		new bool:Match = false;	// true if 1st argument matched some spell name
		
		// Selector
		// Go through all known spells
		for(new Index = 0; Index < EFFECTS; Index++)
		{
			// Compare for current spell name from list match requested from command line
			if(StrEqual(SpellName, Spells[Index][Name], false) && IsPlayerAlive(client))
			{
				// We have match - found requested spell
				Match = true;
				// But is it ready?
				TimeWait = IsSpellReady(client, Index);	// 0 - spell ready, >0 - time to wait
				if(TimeWait == 0)
				{
					// Spell is ready - do the work
					ShootProjectile(client, Spells[Index][ID]);
					// Save time when player used spell
					Players[client][TimeUsed][Index] = GetTime();
				}
				else
				{
					// Spell is not ready - notify player
					PrintToChat(client, "%s Wait \x07FFA500%d\x01 second(s)", CHAT_PREFIX, TimeWait);
				}
				break;
			}
		}
		// If loop above don't find any spell name that match requested in 1st argument
		// then print all spell names to player
		if(!Match)
		{
			PrintToChat(client, "%s Write \x07FFA500%s\x01 for menu", CHAT_PREFIX, "!spells");
			PrintToChat(client, "Or use following names for spells in command line");
			for(new Index = 0; Index < EFFECTS; Index++)
			{
				PrintToChat(client, "\x07FFA500%s\x01 - «%s»", Spells[Index][Name] ,Spells[Index][Desc]);
			}
		}
	}
	
	return Plugin_Handled;
}
//──────────────────────────────────────────────────────────────────────────────
// Function to show menu
public ShowMenu(client)
{
	new Handle:Menu = CreateMenu(MenuHandler, MenuAction_Start|MenuAction_Select|MenuAction_Cancel|MenuAction_End);
	SetMenuTitle(Menu, "Spells");
	
	decl String:Msg[STR_LEN];
	new iDelay = 0;
	
	for(new Index = 0; Index < EFFECTS; Index++)
	{
		iDelay = IsSpellReady(client, Index);
		if(iDelay == 0)
		{
			AddMenuItem(Menu, Spells[Index][Name], Spells[Index][Desc]);
		}
		else
		{
			Format(Msg, sizeof(Msg), "%s (%d sec)", Spells[Index][Desc], iDelay);
			AddMenuItem(Menu, Spells[Index][Name], Msg, ITEMDRAW_DISABLED);
		}
	}
	
	SetMenuExitButton(Menu, true);
	DisplayMenu(Menu, client, 15);

	return;
}
//──────────────────────────────────────────────────────────────────────────────
// Menu action handling
public MenuHandler(Handle:Menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_Select)
		{
			decl String:Info[STR_LEN];
			GetMenuItem(Menu, param2, Info, sizeof(Info));
			
			// Selector
			// Go through all known spells
			for(new Index = 0; Index < EFFECTS; Index++)
			{
				// Compare for current spell name from list match selected in menu
				if(StrEqual(Info, Spells[Index][Name]) && IsPlayerAlive(param1))
				{
					ShootProjectile(param1, Spells[Index][ID]);
					// Save time when player used spell
					Players[param1][TimeUsed][Index] = GetTime();
					break;
				}
			}
			ShowMenu(param1);
		}

	if(action==MenuAction_End)
	{
		CloseHandle(Menu);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Internal routines
//──────────────────────────────────────────────────────────────────────────────
ShootProjectile(client, spell)
{
	new Float:vAngles[3]; // original
	new Float:vPosition[3]; // original
	GetClientEyeAngles(client, vAngles);
	GetClientEyePosition(client, vPosition);
	new String:strEntname[45] = "";
	switch(spell)
	{
		case FIREBALL: 		strEntname = "tf_projectile_spellfireball";
		case LIGHTNING: 	strEntname = "tf_projectile_lightningorb";
		case PUMPKIN: 		strEntname = "tf_projectile_spellmirv";
		case PUMPKIN2: 		strEntname = "tf_projectile_spellpumpkin";
		case BATS: 			strEntname = "tf_projectile_spellbats";
		case METEOR: 		strEntname = "tf_projectile_spellmeteorshower";
		case TELE: 			strEntname = "tf_projectile_spelltransposeteleport";
		case BOSS:			strEntname = "tf_projectile_spellspawnboss";
		case ZOMBIEH:		strEntname = "tf_projectile_spellspawnhorde";
		case ZOMBIE:		strEntname = "tf_projectile_spellspawnzombie";
	}
	new iTeam = GetClientTeam(client);
	new iSpell = CreateEntityByName(strEntname);
	
	if(!IsValidEntity(iSpell))
		return -1;
	
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0]*1100.0; //Speed of a tf2 rocket.
	vVelocity[1] = vBuffer[1]*1100.0;
	vVelocity[2] = vBuffer[2]*1100.0;
	
	SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iSpell,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iSpell,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntProp(iSpell,    Prop_Send, "m_nSkin", (iTeam-2));
	
	TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);
	/*switch(spell)
	{
		case FIREBALL, LIGHTNING:
		{
			TeleportEntity(iSpell, vPosition, vAngles, vVelocity);
		}
		case BATS, METEOR, TELE:
		{
			//TeleportEntity(iSpell, vPosition, vAngles, vVelocity);
			//SetEntPropVector(iSpell, Prop_Send, "m_vecForce", vVelocity);
			
		}
	}*/
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(iSpell);
	/*
	switch(spell)
	{
		//These spells have arcs.
		case BATS, METEOR, TELE:
		{
			vVelocity[2] += 32.0;
		}
	}*/
	TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	return iSpell;
}
//──────────────────────────────────────────────────────────────────────────────
// Other console commands
//──────────────────────────────────────────────────────────────────────────────
public Action:SpellCommand(client, args)
{
	new String:access[8];
	GetConVarString(cCheatOverride,access,8);
	if (client == 0)
	{
		return Plugin_Handled;
	}
	if (GetUserFlagBits(client)&ReadFlagString(access) > 0 || GetUserFlagBits(client)&ADMFLAG_ROOT > 0)
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

//tf_projectile_spelltransposeteleport
//tf_projectile_spellfireball
//tf_projectile_spellmirv - tf_projectile_spellpumpkin
//tf_projectile_spellbats
//tf_projectile_lightningorb
//tf_projectile_spellspawnboss
//tf_projectile_spellmeteorshower
//tf_projectile_spellspawnhorde - tf_projectile_spellspawnzombie
//──────────────────────────────────────────────────────────────────────────────
