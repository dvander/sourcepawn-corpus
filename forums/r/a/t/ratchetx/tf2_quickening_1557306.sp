#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#include <tf2items>
#include <steamtools>

#define PL_VERSION "1.3"

#define TF_CLASS_UNKNOWN		0
#define TF_CLASS_DEMOMAN		4

#define TF_TEAM_RED				2
#define TF_TEAM_BLU				3

#define LIGHTNING_CEILING		700

#define SOUND_THUNDER		"ambient/explosions/explode_9.wav"
#define IMMORTAL_THEME		"quickening/i_am_immortal.mp3"
#define FINISH_ROUND		"vo/demoman_eyelandertaunt02.wav"

//ConVars
static Handle:cvarEnabled;
static Handle:cvarResurrect;
static Handle:cvarKillDoors;
static Handle:cvarPotentialResurrectHealthMultiplier;
static Handle:cvarResurrectHealthMultiplier;

//Debug ConVars
static Handle:dCvarBotNerf;
static Handle:cCvarPotentialResurrect;
static Handle:dCvarDebugFixup;
static Handle:dCvarDebugKillWeapon;

//Variables
static bool:IsQuickening[MAXPLAYERS+1] = {false, ...};
static Victims[MAXPLAYERS+1][MAXPLAYERS+1];
static bool:IsDead[MAXPLAYERS+1] = {false, ...};
static MyKiller[MAXPLAYERS+1] = {0, ...};
static Float:QuickeningTimes[MAXPLAYERS+1] = {0.0, ...};
static Float:QuickeningCritTimes[MAXPLAYERS+1] = {0.0, ...};
static bool:NoTheme[MAXPLAYERS+1] = {false, ...};
static TheLastHighlander = -1;
static bool:IsArena;

static bool:GameInProgress = false;

static bool:PotentialResurrect[MAXPLAYERS+1] = {false, ...};
static Handle:ResurrectionTimers[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

new g_LightningSprite;

static Handle:HintTimerH = INVALID_HANDLE;

public Plugin:myinfo =
{
	name        = "[TF2] The Quickening",
	author      = "Ratchet",
	description = "Highlander gamemode for Team Fortress 2",
	version     = PL_VERSION,
	url         = "http://steamcommunity.com/id/ratchetX"
}

public OnPluginStart()
{
	HookEvent("player_changeclass", Event_PlayerClass);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundFinished);
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	
	AddCommandListener(DoTaunt, "taunt");
	
	CreateConVar( "quickening_version", PL_VERSION, "The Quickening plugin version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD );
	
	RegConsoleCmd("qcsound", HandleToggleTheme, "Toggles 'I am immortal' theme" );
	RegConsoleCmd("qchelp", HandleHelp, "Opens up help menu" );
	
	//ConVars
	cvarEnabled = CreateConVar("quickening_enabled", "1", "Enables/Disables quickening mod", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarKillDoors = CreateConVar("quickening_kill_doors", "0", "Kill doors? For KOTH map support", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarResurrect = CreateConVar("quickening_respawn_time", "10", "Time it takes before fallen highlander respawns if not absorbed. (1 - 30 seconds)", FCVAR_PLUGIN, true, 1.0, true, 30.0 );
	cvarPotentialResurrectHealthMultiplier = CreateConVar("quickening_hpmult_pres", "0.4", "Potential resurrection health multiplier 0.1 - 0.75 (10%-75%)", FCVAR_PLUGIN, true, 0.1, true, 0.75 );
	cvarResurrectHealthMultiplier = CreateConVar("quickening_hpmult_res", "0.8", "Normal resurrection health multiplier 0.75 - 0.9 (75%-90%)", FCVAR_PLUGIN, true, 0.75, true, 0.9 );
	
	//Debug ConVars (should be 0)
	dCvarBotNerf = CreateConVar("quickening_debug_nbot", "0", "Debug cvar: Nerf bots to 1 HP", FCVAR_PLUGIN | FCVAR_CHEAT, true, 0.0, true, 1.0);
	cCvarPotentialResurrect = CreateConVar("quickening_debug_pres", "0", "Debug cvar: Display potential resurrections status", FCVAR_PLUGIN | FCVAR_CHEAT, true, 0.0, true, 1.0);
	dCvarDebugFixup = CreateConVar("quickening_debug_fixup", "0", "Debug cvar: Display fixup info", FCVAR_PLUGIN | FCVAR_CHEAT, true, 0.0, true, 1.0);
	dCvarDebugKillWeapon = CreateConVar("quickening_debug_kwep", "0", "Debug cvar: Killing weapon", FCVAR_PLUGIN | FCVAR_CHEAT, true, 0.0, true, 1.0);
}

public Action:HintTimer(Handle:Timer, any:Client)
{
	if( !IsArena )
		return;
			
	PrintToChatAll("\x04[QC]\x01 Type \x04/qchelp\x01 for help!");
}

public Action:HandleHelp(Client, Args)
{
	new Handle:HelpPanel = CreatePanel();
	SetPanelTitle( HelpPanel, "The Quickening" );
	
	DrawPanelItem(HelpPanel, "Toggle theme music (/qcsound)" );
	DrawPanelItem(HelpPanel, "About game mode" );
	DrawPanelItem(HelpPanel, "Exit" );
	
	SendPanelToClient(HelpPanel, Client, HandleHelpH, 0);
	
	CloseHandle(HelpPanel);
	
	//Return:
	return Plugin_Handled;
}

public HandleHelpH(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 1:
				ToggleTheme(param1);
			case 2:
				HandleAbout(param1);
			default:
				return;
		}
	}
}

public Action:HandleAbout(Client)
{
	new Handle:AboutPanel = CreatePanel();
	SetPanelTitle( AboutPanel, "About 'The Quickening'" );
	
	DrawPanelItem(AboutPanel, "Only way to kill an immortal" );
	DrawPanelItem(AboutPanel, "is to cut his head off and" );
	DrawPanelItem(AboutPanel, "absorb his powers (taunt) within" );
	
	new String:string[40];
	Format(string, sizeof(string), "%f seconds or else he will resurrect.", GetConVarFloat(cvarResurrect));
	
	DrawPanelItem(AboutPanel, string );
	DrawPanelItem(AboutPanel, "" );
	DrawPanelItem(AboutPanel, "There can be only one." );
	
	SendPanelToClient(AboutPanel, Client, HandleAboutH, 0);
	
	CloseHandle(AboutPanel);
}

public HandleAboutH(Handle:menu, MenuAction:action, param1, param2)
{
	return;
}

public Action:ToggleTheme(Client)
{
	if( !NoTheme[Client] )
	{
		NoTheme[Client] = true;
		PrintToChat(Client, "\x04[QC]\x01 Theme has been toggled \x04off\x01!");
		StopSound(Client, SNDCHAN_AUTO, IMMORTAL_THEME);
	}
	else
	{
		NoTheme[Client] = false;
		PrintToChat(Client, "\x04[QC]\x01 Theme has been toggled \x04on\x01!");
	}
}

public TF2_OnConditionAdded(Client, TFCond:Cond)
{
	if (Cond == TFCond_Taunting) 
		DoTaunt(Client, "taunt", 0);
}

public Action:HandleToggleTheme(Client, Args)
{
	ToggleTheme(Client);
	
	//Return:
	return Plugin_Handled;
}

public OnMapStart()
{
	TheLastHighlander = -1;
	GameInProgress = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		QuickeningTimes[i] = 0.0;
		QuickeningCritTimes[i] = 0.0;
	}
	
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
	SetConVarInt(FindConVar("tf_bot_taunt_victim_chance"), 80);
	
	PrecacheSound(SOUND_THUNDER, true);
	PrecacheSound(IMMORTAL_THEME, true);
	PrecacheSound(FINISH_ROUND, true);
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
	
	AddFileToDownloadsTable("sound/quickening/i_am_immortal.mp3");
	CheckArena();
	
	if( HintTimerH != INVALID_HANDLE )
		KillTimer(HintTimerH);
		
	HintTimerH = CreateTimer(180.0, HintTimer, _, TIMER_REPEAT);
}

public EntityAction(const String:ent_name[], const String:action[])
{
	new ent = -1;
	while ((ent = FindEntityByClassname2(ent, ent_name)) != -1)
		if ((ent>0) && IsValidEdict(ent))
			AcceptEntityInput(ent, action);
}

public Event_RoundFinished(Handle:event, const String:name[], bool:dontBroadcast)
{
	GameInProgress = false;
	
	//Round finished, kill all resurrection times
	for (new i = 1; i <= MaxClients; i++)
		if( ResurrectionTimers[i] != INVALID_HANDLE )
		{
			KillTimer( ResurrectionTimers[i] );
			ResurrectionTimers[i] = INVALID_HANDLE;
		}
}

public Event_ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	GameInProgress = true;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	IsArena = false;
	
	if( !GetConVarBool(cvarEnabled) )
		return;
		
	CheckArena();
	
	if( !IsArena )
		return;
		
	//Does not let to set gamemode without making separate var, derp
	new String:desc[14] = "The Quickening";
	Steam_SetGameDescription(desc);
		
	EntityAction("trigger_capture_area", "Disable");
	EntityAction("team_control_point", "HideModel");
	EntityAction("func_respawnroomvisualizer", "Disable");
	EntityAction("item_healthkit_full", "Kill");
	EntityAction("item_healthkit_medium", "Kill");
	EntityAction("item_healthkit_small", "Kill");
	EntityAction("func_regenerate", "Kill");
	
	if( GetConVarBool(cvarKillDoors) )
		EntityAction("func_door", "Kill");
		
	CheckArena();
	
	decl RED, BLU;
	RED = 0; 
	BLU = 0;
	
	//Count how many alive players are in each team
	for(new i = 1; i <= MaxClients; i++)
	{
		//Kill all the resurrection times
		if( ResurrectionTimers[i] != INVALID_HANDLE )
		{
			KillTimer( ResurrectionTimers[i] );
			ResurrectionTimers[i] = INVALID_HANDLE;
		}
				
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			if( GetClientTeam(i) == TF_TEAM_RED )
				RED++;
			else
				BLU++;
		}
	}
		
	PerformTeamFixup(RED, BLU);
	
	if( IsValidClient(TheLastHighlander) )
	{
		decl String:PlayerName[32];
		GetClientName(TheLastHighlander, PlayerName, 32);
		PrintToChatAll("\x04[QC] %s\x01 was the last Highlander!", PlayerName);

		QuickeningTimes[TheLastHighlander] += 25.0;
		QuickeningCritTimes[TheLastHighlander] += 30.0;
		TheLastHighlander = -1;
	}
		
	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			QuickeningCritTimes[i] = GetGameTime();
			QuickeningTimes[i] = GetGameTime();
			ShowHudText(i, -1, "There can be only one!");
			StopSound(i, SNDCHAN_AUTO, IMMORTAL_THEME);
			IsDead[i] = false;
			MyKiller[i] = 0;
			IsQuickening[i] = false;
			
			//Reset victims
			for( new j = 1; j <= MaxClients; j++)
				Victims[i][j] = false;
				
			if( !NoTheme[i] )
				EmitSoundToClient(i, IMMORTAL_THEME);
			
			PotentialResurrect[i] = false;
		}
}

public CheckArena()
{
	new ent = -1;
	if ((ent = FindEntityByClassname2(-1, "tf_logic_arena")) != -1 && IsValidEdict(ent))
	{
		IsArena = true;
		DispatchKeyValue(ent,"CapEnableDelay","-1");
	}
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if( !IsArena )
		return;
		
	//Make sure it's only demoman
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
	iTeam   = GetClientTeam(iClient);
	
	if(IsValidClient(iClient) && GetClientTeam(iClient) == iTeam && _:TF2_GetPlayerClass(iClient) != TF_CLASS_DEMOMAN && _:TF2_GetPlayerClass(iClient) != TF_CLASS_UNKNOWN)
	{
		TF2_SetPlayerClass(iClient, TFClassType:TF_CLASS_DEMOMAN);
		TF2_RespawnPlayer(iClient);
	}
	
	if( IsValidClient(iClient) && IsFakeClient(iClient) && GetConVarBool(dCvarBotNerf) )
		SetEntityHealth(iClient, 1);
	
	//We just resurrected, we are no longer qued for resurrecting
	PotentialResurrect[iClient] = false;
	
	if( ResurrectionTimers[iClient] != INVALID_HANDLE )
	{
		KillTimer( ResurrectionTimers[iClient] );
		ResurrectionTimers[iClient] = INVALID_HANDLE;
	}
	
	new Weapon = GetPlayerWeaponSlot(iClient, 0);
	
	//Do not allow anything except "Chargin' Targe" and "The Splendid Screen"
	if (IsValidEdict(Weapon) && (Weapon > 0))
		TF2_RemoveWeaponSlot(iClient, 0);
	
	Weapon = GetPlayerWeaponSlot(iClient, 1);
	
	//Only allow "Ali Baba's Wee Booties"
	if (IsValidEdict(Weapon) && (Weapon > 0))
		TF2_RemoveWeaponSlot(iClient, 1);
	
	Weapon = GetPlayerWeaponSlot(iClient, 2);
	
	//Only allow weapons that cut heads off
	if (IsValidEdict(Weapon) && (Weapon > 0))
	{
		new index = -1;
		index = GetEntProp(Weapon, Prop_Send, "m_iItemDefinitionIndex");
		
		//If can't find any of these item give "Claidheamh Mor" without any bonus
		if( index != 132 && index != 172 && index != 327 && index != 266 && index != 404 && index != 357 )
		{
			TF2_RemoveWeaponSlot(iClient, 2);
			Weapon = SpawnWeapon(iClient,"tf_weapon_sword",327,1,1,"");
		}
	}
}

public Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !IsArena )
		return;
		
	//Make sure it's only demoman
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
	iTeam   = GetClientTeam(iClient);
	
	if(IsValidClient(iClient) && GetClientTeam(iClient) == iTeam && _:TF2_GetPlayerClass(iClient) != TF_CLASS_DEMOMAN && _:TF2_GetPlayerClass(iClient) != TF_CLASS_UNKNOWN)
	{
		TF2_SetPlayerClass(iClient, TFClassType:TF_CLASS_DEMOMAN);
		TF2_RespawnPlayer(iClient);
	}
}

public StartQuickening(Client, Kills)
{
	IsQuickening[Client] = true;
	CreateTimer(5.0, StopQuickening, Client);
	
	if( GetGameTime() > QuickeningTimes[Client] )
	{
		if( Kills <= 1 )
			QuickeningTimes[Client] = GetGameTime() + 5.0;
		else
			QuickeningTimes[Client] = GetGameTime() + 7.0+(Kills/2.0)+1.0;
	}
	else
	
		if( Kills <= 1 )
			QuickeningTimes[Client] += 6.0;
		else
			QuickeningTimes[Client] += 6.0+(Kills/2.0)+1.0;
	
	if( GetGameTime() > QuickeningCritTimes[Client] )
		QuickeningCritTimes[Client] = GetGameTime() + 10.0 + Kills*2;
	else
		QuickeningCritTimes[Client] += 10.0 + Kills*2;
	
	SetEntityMoveType(Client, MOVETYPE_NONE);
	SetEntityHealth( Client, GetClientHealth(Client)+(Kills*25) );
	
	CreateTimer( 0.1, DoEffects, Client );
	DoCloud(Client);
}

public Action:DoEffects(Handle:Timer, any:Client)
{
	if( IsQuickening[Client] )
		CreateTimer( 0.15, DoEffects, Client );
		
	DoLightning(Client);
}

public Action:StopQuickening(Handle:Timer, any:Client)
{
	if( ! IsValidClient(Client) )
		return;
		
	IsQuickening[Client] = false;
	
	SetEntityMoveType(Client, MOVETYPE_WALK);
}

stock ForceResurrection(Client)
{
	if( IsValidClient(Client) )
		if(!IsDead[Client] && !IsPlayerAlive(Client) )
		{
			PrintToChat(Client, "\x04[QC]\x01 You have resurrected!");
			Victims[MyKiller[Client]][Client] = false;
			decl String:PlayerName[32];
			GetClientName(Client, PlayerName, 32);
			if (IsValidClient(MyKiller[Client]))
				PrintToChat(MyKiller[Client], "\x04[QC] %s\x01 has resurrected!", PlayerName);
			TF2_RespawnPlayer(Client);
			
			new Float:NewHealth = GetClientHealth(Client)*GetConVarFloat(cvarPotentialResurrectHealthMultiplier);
			SetEntityHealth( Client, RoundToFloor(NewHealth) );
		}
}

public Action:Resurrect(Handle:Timer, any:Client)
{
	ResurrectionTimers[Client] = INVALID_HANDLE;
	
	if( IsValidClient(Client) )
		if(!IsDead[Client] && !IsPlayerAlive(Client) )
		{
			PrintToChat(Client, "\x04[QC]\x01 You have resurrected!");
			Victims[MyKiller[Client]][Client] = false;
			decl String:PlayerName[32];
			GetClientName(Client, PlayerName, 32);
			if (IsValidClient(MyKiller[Client]))
				PrintToChat(MyKiller[Client], "\x04[QC] %s\x01 has resurrected!", PlayerName);
			TF2_RespawnPlayer(Client);
			
			new Float:NewHealth = GetClientHealth(Client)*GetConVarFloat(cvarResurrectHealthMultiplier);
			SetEntityHealth( Client, RoundToFloor(NewHealth) );
		}
}

stock ForceTaunt( Client )
{
	FakeClientCommand(Client, "taunt");
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !IsArena )
		return;
		
	new String:weaponName[32];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	
	if( GetConVarBool(dCvarDebugKillWeapon) )
		PrintToChatAll( "Killed with: %s", weaponName );
			
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	//Only decapitations allow to absorb victim
	if( (strcmp(weaponName, "sword") == 0) || (strcmp(weaponName, "battleaxe") == 0)
		|| (strcmp(weaponName, "claidheamohmor") == 0) || (strcmp(weaponName, "headtaker") == 0)
			|| (strcmp(weaponName, "persian_persuader") == 0) || (strcmp(weaponName, "demokatana") == 0)
				|| (strcmp(weaponName, "taunt_demoman") == 0))
	{
		if( Client != Attacker )
		{
			MyKiller[Client] = Attacker;
			Victims[Attacker][Client] = true;
			SetHudTextParams(-1.0, 0.83, 1.0, 255, 64, 64, 255);
			ShowHudText(Attacker, -1, "TAUNT to absorb his powers!" );
			
			if( IsFakeClient(Client) && IsFakeClient(Attacker) )
				if( GetRandomInt( 0, 100 ) < GetConVarInt(FindConVar("tf_bot_taunt_victim_chance")) )
					ForceTaunt( Attacker );
		}
	}
	else
		if( Client != Attacker )
		{
			PotentialResurrect[Client] = true;	//This player was not killed by decaptitating attack, therefore he is qued for potential resurrection
			
			if( GetConVarBool(cCvarPotentialResurrect) )
				PrintToChatAll( "Potential resurrection detected!" );
		}
		
	ResurrectionTimers[Client] = CreateTimer( GetConVarFloat(cvarResurrect), Resurrect, Client );
	
	decl BLU, RED; 
	decl String:PlayerName[32];
	
	BLU = 0;
	RED = 0;
	
	//Make sure we count this kill
	if( GetClientTeam(Client) == TF_TEAM_RED )
		RED--;
	else
		BLU--;

	//Count how many alive players are in each team
	for(new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			GetClientName(i, PlayerName, 32);
			if( GetClientTeam(i) == TF_TEAM_RED )
				RED++;
			else
				BLU++;
		}
	
	if( GetClientTeam(Client) == RED )
		if( RED == 0 )
			IsDead[Client] = true;
			
	if( GetClientTeam(Client) == BLU )
		if( BLU == 0 )
			IsDead[Client] = true;		
	
	//Do not perform this action when it's one on one battle
	if( RED == 1 && BLU == 1 )
		return;
		
	//Winner BLU
	if( RED == 0 && BLU == 1 )
	{
		//Give the last higlander status
		TheLastHighlander = Attacker;
		
		if( IsValidClient(Attacker) && IsPlayerAlive(Attacker) && !CheckAndApplyPotentialResurrections(RED, BLU) )
		{
			ForceTaunt( Attacker );
			EmitSoundToAll( FINISH_ROUND );
		}
			
		return;
	}
	
	//Winner RED
	if( RED == 1 && BLU == 0 )
	{
		//Give the last higlander status
		TheLastHighlander = Attacker;
		
		if( IsValidClient(Attacker) && IsPlayerAlive(Attacker) && !CheckAndApplyPotentialResurrections(RED, BLU) )
		{
			ForceTaunt( Attacker );
			EmitSoundToAll( FINISH_ROUND );
		}
			
		return;
	}
		
	if( (RED == 0 && BLU > 1) || (RED > 1 && BLU == 0))
	{
		PerformTeamFixup(RED, BLU);
		return;
	}
	
	//Fix team count if one of the teams has 0 or 1
	if( RED <= 1 || BLU <= 1 )
	{
		PerformTeamFixup(RED, BLU);
		return;
	}
		
	//Fix team count if one of the teams has twice as much alive players
	if( RED*2 < BLU || BLU*2 < RED )
		PerformTeamFixup(RED, BLU);
}

//Get head count
stock GetHeads(Client)
{
	new Weapon = GetPlayerWeaponSlot(Client, 2);
	
	//Only allow weapons that cut heads off
	if (IsValidEdict(Weapon) && (Weapon > 0))
	{
		new index = -1;
		index = GetEntProp(Weapon, Prop_Send, "m_iItemDefinitionIndex");
		
		//If can't find any of these item give "Claidheamh Mor" without any bonus
		if( index != 132 || index != 266 )
		return GetEntProp(Client, Prop_Send, "m_iDecapitations");
	}
	
	return 0;
}

//Preserve heads when teams switched
public PreserveHeads(Client, Amount)
{
	SetEntProp(Client, Prop_Send, "m_iDecapitations", Amount);
	TF2_AddCondition(Client, TFCond_SpeedBuffAlly, 0.01);
}

stock PerformTeamFixup(RED, BLU)
{
	if( GetConVarBool(dCvarDebugFixup) )
		PrintToChatAll( "RED: %i, BLU:%i", RED, BLU );
		
	decl HowManyToTransfer, TransferToTeam;
	
	HowManyToTransfer = 0;
	TransferToTeam = 0;
	
	if( RED > BLU )
	{
		HowManyToTransfer = (RED-BLU)/2;
		TransferToTeam = TF_TEAM_BLU;
	}
	else
	{
		HowManyToTransfer = (BLU-RED)/2;
		TransferToTeam = TF_TEAM_RED;
	}
	
	if( GetConVarBool(dCvarDebugFixup) )
		PrintToChatAll( "Need to transfer %i players to %i team.", HowManyToTransfer, TransferToTeam );
	
	for( new i = 1; i <= MaxClients; i++ )
		if(IsValidClient(i) && IsPlayerAlive(i) && TransferToTeam != 0)
			if(GetClientTeam(i) != TransferToTeam && HowManyToTransfer > 0 )
			{
				if( HowManyToTransfer <= 0 )
					break;
				
				//Save values
				decl Float:ClientOrigin[3], Float:ClientAngles[3], Health;
				if( GameInProgress )
				{
					GetClientAbsOrigin(i, ClientOrigin);
					GetClientAbsAngles(i, ClientAngles);
					Health = GetClientHealth(i);
				}
				
				new Heads = GetHeads(i);
				
				//Switch teams
				ChangeClientTeam(i, TransferToTeam);
				TF2_RespawnPlayer(i);
				
				//Do not add to potential resurection list
				PotentialResurrect[i] = false;
				
				if( GameInProgress )
				{
					//Teleport me to my previous location and set previous health
					TeleportEntity(i, ClientOrigin, ClientAngles, NULL_VECTOR);
					SetEntityHealth(i, Health);
					
					if( Heads > 0 )
						PreserveHeads(i, Heads);
				}
				
				HowManyToTransfer--;
			}

}

public OnGameFrame()
{
	//Loop:
	for(new Client = 1; Client <= MaxClients; Client++)
	{
		if(!IsValidClient(Client) || !IsPlayerAlive(Client))
			continue;
			
		if( QuickeningTimes[Client] > GetGameTime() )
			TF2_AddCondition(Client, TFCond_Ubercharged, 0.1);

		if( QuickeningCritTimes[Client] > GetGameTime() )
		{
			TF2_AddCondition(Client, TFCond_Kritzkrieged, 0.1);
			TF2_AddCondition(Client, TFCond_Healing, 0.1);
		}
	}
}

public bool:TraceEntityFilterPlayer(entity, mask, any:data)
{
	return data != entity;
}

DoCloud(target)
{
	// define where the lightning strike ends
	new Float:clientpos[3];
	GetClientAbsOrigin(target, clientpos);
	clientpos[2] -= 26; // increase y-axis by 26 to strike at player's chest instead of the ground
	
	new String:origin[64];
	Format(origin, sizeof(origin), "%f %f %f", clientpos[0], clientpos[1], clientpos[2] + LIGHTNING_CEILING);
	
	// Create the Black Cloud
	new String:gas_name[128];
	Format(gas_name, sizeof(gas_name), "Cloud%i", target);
	new gascloud = CreateEntityByName("env_smokestack");
	DispatchKeyValue(gascloud,"targetname", gas_name);
	DispatchKeyValue(gascloud,"Origin", origin);
	DispatchKeyValue(gascloud,"BaseSpread", "1000");
	DispatchKeyValue(gascloud,"SpreadSpeed", "500");
	DispatchKeyValue(gascloud,"Speed", "100");
	DispatchKeyValue(gascloud,"StartSize", "1000");
	DispatchKeyValue(gascloud,"EndSize", "800");
	DispatchKeyValue(gascloud,"Rate", "10");
	DispatchKeyValue(gascloud,"JetLength", "1000");
	DispatchKeyValue(gascloud,"Twist", "4");
	DispatchKeyValue(gascloud,"RenderColor", "0, 0, 0");
	DispatchKeyValue(gascloud,"RenderAmt", "255");
	DispatchKeyValue(gascloud,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");
	DispatchSpawn(gascloud);
	AcceptEntityInput(gascloud, "TurnOn");
	
	new Handle:entitypack = CreateDataPack();
	CreateTimer(7.0, RemoveCloud, entitypack);
	
	WritePackCell(entitypack, gascloud);
}

DoLightning(target)
{
	if( !IsValidClient(target) )
		return;
		
	// define where the lightning strike ends
	new Float:clientpos[3];
	GetClientAbsOrigin(target, clientpos);
	clientpos[2] -= 26; // increase y-axis by 26 to strike at player's chest instead of the ground
	
	// get random numbers for the x and y starting positions
	new randomx = GetRandomInt(-500, 500);
	new randomy = GetRandomInt(-500, 500);
	
	// define where the lightning strike starts
	new Float:startpos[3];
	startpos[0] = clientpos[0] + randomx;
	startpos[1] = clientpos[1] + randomy;
	startpos[2] = clientpos[2] + LIGHTNING_CEILING;
	
	new Handle:trace = TR_TraceRayFilterEx(clientpos, startpos, MASK_SHOT, RayType_EndPoint, TraceEntityFilterPlayer);

	//This lightning cannot strike me, because i'm inside of a room
	if(TR_DidHit(trace))
		return;
		
	CloseHandle(trace);
	
	// define the color of the strike
	new color[4] = {255, 255, 255, 255};
	
	// define the direction of the sparks
	new Float:dir[3] = {0.0, 0.0, 0.0};
	
	TE_SetupBeamPoints(startpos, clientpos, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, color, 3);
	TE_SendToAll();
	
	TE_SetupSparks(clientpos, dir, 5000, 1000);
	TE_SendToAll();
	
	TE_SetupEnergySplash(clientpos, dir, false);
	TE_SendToAll();
	
	EmitAmbientSound(SOUND_THUNDER, clientpos, target, SNDLEVEL_RAIDSIREN);
}

public Action:RemoveCloud(Handle:timer, Handle:entitypack)
{
	ResetPack(entitypack);
	new gascloud = ReadPackCell(entitypack);

	if (IsValidEntity(gascloud))
	{
		AcceptEntityInput(gascloud, "TurnOff");
		
		CreateTimer(5.0, CloudKill, entitypack);
	}
}

public Action:CloudKill(Handle:timer, Handle:entitypack)
{
	ResetPack(entitypack);
	new gascloud = ReadPackCell(entitypack);
	
	if (IsValidEntity(gascloud))
		AcceptEntityInput(gascloud, "Kill");
}

//Give a weapon
stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
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
	EquipPlayerWeapon(client, entity);
	return entity;
}

//Lol epic function name
stock AbsorbVictimsVictims(Client, Victim)
{
	decl ExtraKills;
	ExtraKills = 0;
	
	for(new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && !IsPlayerAlive(i))
		{
			decl String:PlayerName[32], String:VictimName[32];
			GetClientName(Client, PlayerName, 32);
			if( Victims[Victim][i] && !IsDead[i] )
			{
				IsDead[i] = true;
				Victims[Victim][i] = false;
				GetClientName(i, VictimName, 32);
				ExtraKills++;
				PrintToChat(Client, "\x04[QC]\x01 You have absorbed \x04%s\x01's powers!", VictimName);
				PrintToChat(i, "\x04[QC]\x01 You have been absorbed by \x04%s\x01!", PlayerName);
			}
		}
	
	return ExtraKills;
}

public Action:DoTaunt(Client, const String:command[], argc)
{
	if( !IsPlayerAlive(Client) && !IsQuickening[Client] )
		return;
	
	decl Kills;
	Kills = 0;
	
	//Count how many alive players are in each team
	for(new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && !IsPlayerAlive(i))
		{
			decl String:PlayerName[32], String:VictimName[32];
			GetClientName(Client, PlayerName, 32);
			if( Victims[Client][i] && !IsDead[i] )
			{
				IsDead[i] = true;
				Victims[Client][i] = false;
				GetClientName(i, VictimName, 32);
				Kills++;
				PrintToChat(Client, "\x04[QC]\x01 You have absorbed \x04%s\x01's powers!", VictimName);
				PrintToChat(i, "\x04[QC]\x01 You have been absorbed by \x04%s\x01!", PlayerName);
				Kills += AbsorbVictimsVictims(Client, i);
			}
		}
		
	if( Kills > 0 )
		StartQuickening( Client, Kills );
}

stock bool:CheckAndApplyPotentialResurrections(RED, BLU)
{
	new bool:ResurrectedAnyPlayers = false;
	new PotentialResurrectionAmount = 0;
	
	//Look for players that can potentially resurrect
	for(new i = 1; i <= MaxClients; i++)
		if(IsValidClient(i) && !IsPlayerAlive(i))
			if( PotentialResurrect[i] == true )
			{
				ForceResurrection(i);
				ResurrectedAnyPlayers = true;
				PotentialResurrectionAmount++;
			}
			
	if( RED < BLU )
		BLU += PotentialResurrectionAmount;
	else
		RED += PotentialResurrectionAmount;
			
	if( ResurrectedAnyPlayers == true )
		PerformTeamFixup( RED, BLU );
		
	if( GetConVarBool(cCvarPotentialResurrect) )
		PrintToChatAll( "Potential resurrections return: %i | RED: %i BLU: %i", PotentialResurrectionAmount, RED, BLU );
	
	return ResurrectedAnyPlayers;
}

//Thanks to FlamingSarge
stock bool:IsValidClient(client)
{
	if (client <= 0 || client >= MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}