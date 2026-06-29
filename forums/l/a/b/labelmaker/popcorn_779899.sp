#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <damage>
#undef REQUIRE_PLUGIN
#include <autoupdate>

#define PLUGIN_VERSION "1.1.10"

#define PLAYER_ONFIRE   (1 << 14)
#define PSPY_NOCLOAK	18
#define PSPY_CLOAK		19
#define PSPY_RECHARGE	20
#define SPAT_FLIP		10
#define SPAT_PUSH		11
#define SUR				2
#define ZOM				3
#define MAXABILITY		16
#define VOTE_CLIENTID	0
#define VOTE_USERID		1
#define VOTE_NAME		0
#define VOTE_NO 		"###no###"
#define VOTE_YES 		"###yes###"

//Sounds
#define SOUND_FREEZE				"physics/glass/glass_impact_bullet4.wav"
#define DL_SOUND_RUNESPAWN 			"sound/items/balloon_pop.wav"
#define SOUND_RUNESPAWN				"items/balloon_pop.wav"
#define DL_SOUND_RUNEPICKUP 		"sound/items/mushroom1.wav"
#define SOUND_RUNEPICKUP 			"items/mushroom1.wav"
#define DL_SOUND_ITSALIVE 			"sound/misc/its_alive.wav"
#define SOUND_ITSALIVE 				"misc/its_alive.wav"
#define SOUND_POSERSPY_CLOAK 		"player/spy_cloak.wav"
#define SOUND_POSERSPY_UNCLOAK 		"player/spy_uncloak.wav"
#define SOUND_SPATULA 				"ui/scored.wav"

//Models
#define MODEL_DISPENSER	"models/buildables/dispenser.mdl"
#define MODEL_POPCORN	"models/popcorn/popcorn.mdl"
#define DL_MODEL_POPCORN	"models/popcorn"
#define DL_MATERIAL_POPCORN		"materials/models/popcorn"

//Sprites
#define MODEL_BUBBLE	"materials/sprites/bubble.vmt"

// rune globals
new String:realHN[60];
new String:g_voteInfo[3][65];
new Float:MapX[2];
new Float:MapY[2];
new Float:MapZ[2];
new runeAmount;
new Float:g_spawnLocation[MAXPLAYERS + 1][3];
new g_targetOnline[MAXPLAYERS+1];
new g_runeActive[MAXPLAYERS+1];
new g_runeExtra[MAXPLAYERS+1];
new g_runeBox[MAXPLAYERS + 1];
new g_targetTeam[MAXPLAYERS + 1];
new g_playerAttacking[MAXPLAYERS + 1];
new g_runesDropped;
new g_droprune;
new pop_frankenstein[2];

//Bools
new bool:pop_isActive;
new bool:pop_zfMap;
new bool:pop_arenaMap;
new bool:pop_nopopMap;
new bool:g_alreadykilled[MAXPLAYERS + 1];
new bool:pop_megapopActive = true;
new bool:pop_meleemash;
new bool:pop_startup;
new bool:pop_mapstart;
new bool:pop_inPopMenu[MAXPLAYERS + 1];
new bool:g_CanVote = true;

//Handles
new Handle:Hostname;
//new Handle:g_hKv = INVALID_HANDLE;
new Handle:pop_cvar_ForceOn = INVALID_HANDLE;
new Handle:pop_boxTimer = INVALID_HANDLE;
new Handle:pc_hRegenerate;
new Handle:pc_hGameConf;
new Handle:g_Cvar_Limits;
new Handle:g_hVoteMenu = INVALID_HANDLE;
new Handle:g_Cvar_VoteTime = INVALID_HANDLE;

// UserMessageId for Fade.
new UserMsg:g_FadeUserMsgId;

//Stocks
Handle:BuildPopMenu()
{
	new Handle:menu = CreateMenu(popdispenserMenu);
	SetMenuTitle(menu, "Pick Your Pop!");
	AddMenuItem(menu, "4", "Vampire");
	AddMenuItem(menu, "5", "Snowcone");
	AddMenuItem(menu, "6", "Easter Egg");
	AddMenuItem(menu, "7", "KritsPop");
	AddMenuItem(menu, "14", "VooDoo");
	AddMenuItem(menu, "16", "Spatula");
	AddMenuItem(menu, "8", "Mercury Shoes");
	AddMenuItem(menu, "9", "Safety Net");
	AddMenuItem(menu, "10", "Tomato Juice");
	AddMenuItem(menu, "13", "Poser Spy");
	AddMenuItem(menu, "11", "Bubble Wand");
	SetMenuExitButton(menu, false);
	return menu;
}
bool:IsClientOnTeam(client)
{
	switch (GetClientTeam(client))
	{
		case 2:
		{
			return true;
		}
		case 3:
		{
			return true;
		}
	}

	return false;
}
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max) 
{ 
    MarkNativeAsOptional("AutoUpdate_AddPlugin");
    MarkNativeAsOptional("AutoUpdate_RemovePlugin");
    return true;
}
stock TF2_AddCond(client, cond) {
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar);
    if(!enabled)
	{
        SetConVarInt(cvar, 1);
	}
    FakeClientCommand(client, "addcond %i", cond);
    if(!enabled)
	{
        SetConVarInt(cvar, 0);
	}
}
stock TF2_RemoveCond(client, cond) {
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar);
    if(!enabled)
	{
        SetConVarInt(cvar, 1);
	}
    FakeClientCommand(client, "removecond %i", cond);
    if(!enabled)
	{
        SetConVarInt(cvar, 0);
	}
}  
////////////////////////////////Plugin Specifics//////////////////////////////////////////////
public Plugin:myinfo =
{
	name = "Popcorn",
	author = "LabelMaker",
	description = "Runes Gameplay Mod for TF2",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() 
{
	CreateConVar("popcorn_version", PLUGIN_VERSION, "Popcorn version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	pop_cvar_ForceOn = CreateConVar("sm_pop_force_on", "1", "On \"1\" Popcorn remains active on map changes.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	AutoExecConfig(true, "plugin_tagfort");
	
	HookEvent("teamplay_round_active", Event_round_start);
	HookEvent("teamplay_restart_round", Event_round_start);
	HookEvent("arena_round_start", Event_round_start);
	HookEvent("player_hurt", EventDamage, EventHookMode_Pre);
	//dhAddClientHook(CHK_PreThink, PreThinkHook);
	
	pc_hGameConf = LoadGameConfigFile("popcorn.games");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(pc_hGameConf, SDKConf_Signature, "Regenerate");
	pc_hRegenerate = EndPrepSDKCall();
	
	//Commands
	RegConsoleCmd("droppop", Command_Drop);
	RegConsoleCmd("popkey", Command_Activate);
	RegAdminCmd("sm_pop_enable", command_Enable, ADMFLAG_GENERIC,"Activates the Popcorn plugin");
	RegAdminCmd("sm_pop_disable", command_Disable, ADMFLAG_GENERIC,"Deactivates the Popcorn plugin");
	RegAdminCmd("sm_pop_test", command_Test, ADMFLAG_GENERIC,"Forthcoming Ability Tester");
	
	//vote menu stuff
	g_Cvar_Limits = CreateConVar("sm_votepop_limit", "0.65", "Percent required for successful popcorn vote.");
	g_Cvar_VoteTime = CreateConVar("sm_votepop_timer", "180", "Time in seconds between votes"); 
	RegConsoleCmd("votepop", Command_votepop);
	
	runeAmount = 30;
	pop_startup = true;
	g_FadeUserMsgId = GetUserMessageId("Fade");
}

public OnAllPluginsLoaded() 
{
    if(LibraryExists("pluginautoupdate")) 
	{
        AutoUpdate_AddPlugin("turtlesecu.clanservers.com", "/smplugins/plugins.xml", PLUGIN_VERSION);
    }
}
public OnPluginEnd() 
{
    if(LibraryExists("pluginautoupdate")) 
	{
        AutoUpdate_RemovePlugin();
    }
}
///////////////////////////////Events//////////////////////////////////////////////
public OnMapStart()
{
	if (GetConVarInt(pop_cvar_ForceOn) == 1)
		pop_isActive = true;
	else
		pop_isActive = false;
	
	AddFileToDownloadsTable(DL_SOUND_RUNEPICKUP);
	AddFileToDownloadsTable(DL_SOUND_RUNESPAWN);
	AddFileToDownloadsTable(DL_SOUND_ITSALIVE);
	AddFolderToDownloadTable(DL_MODEL_POPCORN);
	AddFolderToDownloadTable(DL_MATERIAL_POPCORN);
	
	PrecacheModel(MODEL_POPCORN, true);
	PrecacheModel(MODEL_DISPENSER, true);
	PrecacheModel(MODEL_BUBBLE, true);
	
	PrecacheSound(SOUND_RUNESPAWN, true);
	PrecacheSound(SOUND_RUNEPICKUP, true);
	PrecacheSound(SOUND_FREEZE, true);
	PrecacheSound(SOUND_POSERSPY_CLOAK, true);
	PrecacheSound(SOUND_POSERSPY_UNCLOAK, true);
	PrecacheSound(SOUND_ITSALIVE, true);
	PrecacheSound(SOUND_SPATULA, true);

	HookEvent("player_spawn", PlayerSpawnEvent);
	HookEvent("player_death", PlayerDeathEvent);
	HookEvent("player_disconnect", PlayerDisconnectEvent);
	
	MapX[0] = 0.0; MapX[1] = 0.0;
	MapY[0] = 0.0; MapY[1] = 0.0;
	MapZ[0] = 0.0; MapZ[1] = 0.0;
	pop_mapstart = true;
}
public OnMapEnd()
{
	if (pop_isActive == true)
		function_Disable();
}
public OnGameFrame()
{
    SaveAllHealth();
}
public OnEventShutdown()
{
	UnhookEvent("player_spawn", PlayerSpawnEvent);
	UnhookEvent("player_death", PlayerDeathEvent);
	UnhookEvent("player_disconnect", PlayerDisconnectEvent);
}

public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (pop_isActive == false) return;
	function_Enable();
}

public OnClientPutInServer(client)
{
	g_targetOnline[client] = 1;
	SDKHook(client, SDKHook_PreThink, PreThinkHook);
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (pop_frankenstein[0] == client)
	{
		pop_megapopActive = false;
		pop_frankenstein[0] = 0;
		PrintCenterTextAll("Frankenstein has been defeated. -Player has left game");
	}
	if (pop_meleemash && g_runeActive[client] == 9)
	{
		pop_meleemash = false;
		pop_megapopActive = false;
		for(new i = 1; i <= MaxClients; ++i)
		{
			if (IsValidEntity(i) && IsClientInGame(i) && IsClientOnTeam(i))
			{
				SDKCall(pc_hRegenerate, i);
			}
		}
		PrintCenterTextAll("Melee Mash is over, Resupplies are now Active.");
	}
	g_targetOnline[client] = 0;
	g_runeActive[client] = 0;
	g_runeExtra[client] = 0;
	g_runeBox[client] = 0;
	g_targetTeam[client] = 0;
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0)
	{	
		if (pop_mapstart)
		{
			new Float:targetPos[3];
			GetClientEyePosition(client, targetPos);
			
			MapX[0] = targetPos[0]; MapX[1] = targetPos[0];
			MapY[0] = targetPos[1]; MapY[1] = targetPos[1];
			MapZ[0] = targetPos[2]; MapZ[1] = targetPos[2];
			pop_mapstart = false;
		}
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityGravity(client, 1.0);
		DoColorize(client);
		if (IsClientInGame(client))
		{
			SaveHealth(client);
			if (g_runeActive[client] == 9)
			{
				if (pop_frankenstein[0] == client)
				{
					//SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
					TF2_RemoveCond(client, 5);
					pop_megapopActive = false;
					pop_frankenstein[0] = 0;
					PrintCenterTextAll("Frankenstein has been defeated!");
				}
				else if (pop_meleemash)
				{
					pop_meleemash = false;
					function_DisableResupply(false);
					for(new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientInGame(i) && IsClientOnTeam(i))
						{
							SDKCall(pc_hRegenerate, i);
						}
					}
					PrintCenterTextAll("Melee Mash is over, Resupplies are now Active.");
				}
				else
				{
					PrintCenterTextAll("Megapop Event has ended!");
				}
			}
			g_runeActive[client] = 0;
			g_runeExtra[client] = 0;
			g_runeBox[client] = 0;
			g_alreadykilled[client] = false;
			g_targetTeam[client] = GetClientTeam(client);
			pop_inPopMenu[client] = false;
			if (pop_megapopActive)
			{
				if (pop_meleemash)
				{
					CreateTimer(0.1, meleemashTime, client);
				}
			}
		}
	}
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientInGame(client))
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		new runeType = g_runeActive[client];
		new ability = FindAbility(runeType);
		teleportDropRune(client, ability);
		switch (runeType)
		{
			case 9:
			{
				pop_megapopActive = false;
				if (pop_meleemash)
				{
					pop_meleemash = false;
					function_DisableResupply(false);
					for(new i = 1; i <= MaxClients; ++i)
					{
						if (IsClientInGame(i) && IsClientOnTeam(i))
						{
							SDKCall(pc_hRegenerate, i);
						}
					}
					PrintCenterTextAll("Melee Mash is over, Resupplies are now Active.");
				}
			}
			case 7: TF2_RemoveCond(client, 11);
			case 5: //unfreeze
			{
				new Float:vec[3];
				GetClientAbsOrigin(client, vec);
				vec[2] += 10;	
				GetClientEyePosition(client, vec);
				EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
			}
			case 4: //unbox others
			{
				for (new i=1; i <= MaxClients; i++)
				{
					if (g_runeBox[i] == client)
					{
						g_runeBox[i] = 0;
						g_runeExtra[i] = 0;
					}
				}
			}
		}
		g_runeActive[client] = 0;
		g_runeExtra[client] = 0;
		g_runeBox[client] = 0;
		g_targetTeam[client] = 1;
	}
}
public EventDamage(Handle:Event, const String:Name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(Event, "userid"));
	if (g_alreadykilled[victim])
	{
		g_alreadykilled[victim] = false;
		return;
	}
	new attackerID = GetEventInt(Event, "attacker");
	if (attackerID == 0) return;
	new attacker = GetClientOfUserId(attackerID);
	
	new v_health = GetEntProp(victim, Prop_Send, "m_iHealth");
	new damage = GetDamage(Event, victim, attacker, -1, -1);
	new attackerRune = g_runeActive[attacker];
	new victimRune = g_runeActive[victim];
	new victimFlags = GetEntProp(victim, Prop_Data, "m_fFlags", victimFlags);
	new String:weaponName[32];
	new a_health = GetEntProp(attacker, Prop_Send, "m_iHealth");
	if (attacker == victim) return;
	if (attacker != 0 && IsClientConnected(attacker))
	{
		//attacker specifics
		switch (attackerRune)
		{
			case 17:                    //sludge
			{
				v_health += RoundToFloor(float(damage) * 0.5);
				PerformBlind(victim, 1);
			}
			case 11,10:					//spatula
			{
				v_health += RoundToFloor(float(damage) * 0.5);
				spatulaDamage(victim, attacker, attackerRune);
			}
			case 7:	TF2_AddCond(attacker, 11);	//doublepop
			case 6:						//snowcone effects
			{
				GetClientWeapon(attacker, weaponName, sizeof(weaponName)); 
				if (!(StrEqual(weaponName,"tf_weapon_bat") || StrEqual(weaponName,"tf_weapon_club") || StrEqual(weaponName,"tf_weapon_shovel") || StrEqual(weaponName,"tf_weapon_bottle") || StrEqual(weaponName,"tf_weapon_bonesaw") || StrEqual(weaponName,"tf_weapon_fists") || StrEqual(weaponName,"tf_weapon_fireaxe") || StrEqual(weaponName,"tf_weapon_knife") || StrEqual(weaponName,"tf_weapon_wrench") || StrEqual(weaponName,"tf_weapon_bat_wood")))
				{
					if (victimFlags & FL_KILLME) 
					{
						victimFlags -= FL_KILLME;
						SetEntProp(victim, Prop_Data, "m_fFlags", victimFlags); 
					}
					v_health += damage;
					new Float:vec[3];
					GetClientEyePosition(victim, vec);
					EmitAmbientSound(SOUND_FREEZE, vec, victim, SNDLEVEL_RAIDSIREN);
					if (g_runeExtra[victim] != 5)
					{
						SetEntityMoveType(victim, MOVETYPE_NONE);
						SetEntityRenderMode(victim, RENDER_NORMAL);
						SetEntityRenderColor(victim, 97, 187, 241, 255);
						SetAlpha(victim, 175);
						g_runeExtra[victim] = 5;
						CreateTimer(4.0, freezeTime, victim);
					}
				}
			}
			case 3:						//vampire
			{
				a_health += damage;
				new TFClassType:class = TF2_GetPlayerClass(attacker);
				new maxhealth;
				switch (class)
				{
					case TFClass_Scout:		maxhealth = 185;
					case TFClass_Soldier:	maxhealth = 300;
					case TFClass_DemoMan:	maxhealth = 260;
					case TFClass_Medic:		maxhealth = 225;
					case TFClass_Pyro:		maxhealth = 260;
					case TFClass_Spy:		maxhealth = 185;
					case TFClass_Engineer:	maxhealth = 185;
					case TFClass_Sniper:	maxhealth = 185;
					case TFClass_Heavy:		maxhealth = 450;
				}
				if (a_health > maxhealth)
				{
					a_health = maxhealth;
				}
			}
		}
		//victim specifics
		switch (victimRune)
		{
			case 16:					//safetynet
			{
				if (v_health < 50)
				{
					CreateTimer(0.01, safetynetTime, victim);
				}
			}
			case 8:	a_health -= damage;	//voodoo
			case 7:	v_health -= damage;	//doublepop
		}
		//megapop specifics
		if (pop_megapopActive)
		{
			if (g_targetTeam[victim] == g_targetTeam[pop_frankenstein[0]])
			{
				new frankDMG = RoundFloat(damage * 0.5);
				frankensteinDamage(frankDMG, attacker);
			}
		}
		//is victim or attacker dead?
		if (v_health != GetEntProp(victim, Prop_Send, "m_iHealth") && g_runeExtra[victim] != 1)
		{
			if (v_health < 1)
			{
				g_playerAttacking[attacker] = victim;
				CreateTimer(0.01, checkDeath, victim);
			}
			else
			{
				SetEntityHealth(victim, v_health);
				SaveHealth(victim);
			}
		}
		if (a_health != GetEntProp(attacker, Prop_Send, "m_iHealth") && g_runeExtra[attacker] != 1)
		{
			if (a_health < 1)
			{
				g_playerAttacking[victim] = attacker;
				CreateTimer(0.01, checkDeath, attacker);
			}
			else
			{
				SetEntityHealth(attacker, a_health);
				SaveHealth(attacker);
			}
		}
	}
}
public PreThinkHook(client) 
{ 
	new buttons = GetClientButtons(client);
	new runeType = g_runeActive[client];
	if (g_runeExtra[client] == 5)
	{
		if (buttons & IN_ATTACK)
		{
			buttons &= ~IN_ATTACK;
			//buttons -= IN_ATTACK;
			SetEntProp(client, Prop_Data, "m_nButtons", buttons);
		}
    }
	switch (runeType)
	{
		case 15,14:		mercuryshoesPreThink(client, buttons);
	}
	return Plugin_Continue; 
}
///////////////////////////////////////////Vote Menu////////////////////////////////////////////

public Action:Command_votepop(client, args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %s", "Vote in Progress");
		return Plugin_Handled;
	}	
	
	if (!g_CanVote)
	{
		ReplyToCommand(client, "[SM] Popcorn is not allowed at this time");
		return Plugin_Handled;
	}	

	LogAction(client, -1, "\"%L\" initiated a Popcorn vote.", client);
	ShowActivity(client, "%s", "Initiated Popcorn Vote", g_voteInfo[VOTE_NAME]);
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "Turn On Popcorn?");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
	return Plugin_Handled;
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Display)
	{
		decl String:title[64];
		GetMenuTitle(menu, title, sizeof(title));
		
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%s %s", title, g_voteInfo[VOTE_NAME]);

		new Handle:panel = Handle:param2;
		SetPanelTitle(panel, buffer);
	}
	else if (action == MenuAction_DisplayItem)
	{
		decl String:display[64];
		GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "VOTE_NO") == 0 || strcmp(display, "VOTE_YES") == 0)
	 	{
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%s", display);
			return RedrawMenuItem(buffer);
		}
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[SM] %s", "No Votes Cast");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		g_CanVote = false;
		decl String:buffer2[128];
		GetConVarString(g_Cvar_VoteTime, buffer2, sizeof(buffer2));
		new Float:time = StringToFloat(buffer2);
		new Float:votes; 
		new Float:totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		new Float:comp = FloatDiv(votes,totalVotes);
		decl String:buffer[128];
		GetConVarString(g_Cvar_Limits, buffer, sizeof(buffer));
		new Float:comp2 = StringToFloat(buffer);
		if (param1 == 0) // Votes of no wins
		{
			PrintToChatAll("[SM] Popcorn Vote has Failed");
			LogAction(-1, -1, "Popcorn Vote has Failed due to an insufficient amount of votes");
			function_Disable();
			CreateTimer(time, Timer_VoteTimer);
		} 
		else if (comp >= comp2 && param1 == 1)
		{
			new Float:hundred = 100.00;
			new Float:percentage = FloatMul(comp,hundred);
			new percentage2 = RoundFloat(percentage);
			PrintToChatAll("[SM] %i Percent of %i Players Voted for Popcorn", percentage2, totalVotes);
			LogAction(-1, -1, "Popcorn Vote successful");
			function_Enable();
			CreateTimer(time, Timer_VoteTimer);
		}
		else
		{
			new Float:hundred = 100.00;
			new Float:percentage = FloatMul(comp2,hundred);
			new percentage2 = RoundFloat(percentage);
			PrintToChatAll("[SM] Popcorn Vote has failed due to insufficient Votes %i Percent", percentage2);
			LogAction(-1, -1, "Popcorn Vote Failed due to less than %i Percent wanting to change", percentage2);
			CreateTimer(time, Timer_VoteTimer);
		}
	}
	return 0;
}

VoteMenuClose()
{
	CloseHandle(g_hVoteMenu);
	g_hVoteMenu = INVALID_HANDLE;
}

public Action:Timer_VoteTimer(Handle:timer)
{
	g_CanVote = true;
}

///////////////////////////////////////////Commands/////////////////////////////////////////////
public Action:command_Enable (client, args)
{
	if (pop_isActive == false)
	{
		function_Enable ();
	}
}
public Action:command_Disable (client, args)
{
	if (pop_isActive == true)
	{
		function_Disable ();
	}
}
public Action:Command_Drop(client, args)
{
	new runeType = g_runeActive[client];
	if (runeType == 9 || runeType == 0) return Plugin_Handled;
	if (runeType == 7) TF2_RemoveCond(client, 11);
	new ability = FindAbility(runeType);
	teleportDropRune(client, ability);
	g_runeActive[client] = 1;
	g_runeExtra[client] = 0;
	g_runeBox[client] = 0;
	CreateTimer(0.1, runeActiveReset, client);
	SetEntityMoveType(client, MOVETYPE_WALK);
	DoColorize(client);
	return Plugin_Handled;
}

public Action:Command_Activate(client, args)
{
	new runeType = g_runeActive[client];
	switch (runeType)
	{
		case 32,31,30,29,28,27,26,25,24,23,22:		bubblewandActivate(client);
		case 19,18:									poserspyActivate(client, runeType);
		case 17:									tomatojuiceActivate(client);
		case 15,14:									mercuryshoesActivate(client);
		case 12:									popdispenserActivate(client);
		case 11,10:									spatulaActivate(client, runeType);
	}
	return Plugin_Handled;
}
public Action:command_Test(client, args)
{
	/*pop_megapopActive = false;
	popdispenser(client);
	return Plugin_Handled;*/
	frankenstein(client);
}
///////////////////////////////////////////////Functions/////////////////////////////////////////
function_DisableResupply(bool:activate) 
{
	new search = -1;
	if (activate == true)
	{
		while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
			AcceptEntityInput(search, "Disable");
	}
	else
	{
		while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
			AcceptEntityInput(search, "Enable");
	}
}
public function_Enable ()
{
	CheckForGametype();
	if (pop_nopopMap) return;
	if (pop_startup)
	{
		Hostname = FindConVar("hostname");
		GetConVarString(Hostname, realHN, sizeof(realHN));
		pop_startup = false;
	}
	function_ResetHistory();
	//LoadMapConfig();
	pop_boxTimer = CreateTimer(10.0, expandBox, 0, TIMER_REPEAT);
	ServerCommand("hostname %s [Popcorn]", realHN);
	SetConVarInt(pop_cvar_ForceOn, 1);
	throwRunes();
	pop_isActive = true;
}

public function_Disable()
{
	function_ResetHistory();
	//function_killPopcorn();
	ServerCommand("hostname %s", realHN);
	pop_isActive = false;
	SetConVarInt(pop_cvar_ForceOn, 0);
}
public function_ResetHistory()
{
	for(new i = 1; i <= MaxClients; ++i)
	{
		g_runeActive[i] = 0;
		g_runeExtra[i] = 0;
		g_runeBox[i] = 0;
		g_alreadykilled[i] = false;
		g_playerAttacking[i] = 0;
		pop_inPopMenu[i] = false;
	}
	if (pop_boxTimer != INVALID_HANDLE)
	{
		KillTimer(pop_boxTimer, false);
		pop_boxTimer = INVALID_HANDLE;
	}
	g_runesDropped = 0;
	pop_megapopActive = false;
	pop_frankenstein[0] = 0;
}
public Action:runesound(client)
{
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	EmitAmbientSound(SOUND_RUNEPICKUP, vec, client, SNDLEVEL_NORMAL);
}

public Action:addRune(Float:time)
{
	if (g_runesDropped > 0)
	{
		--g_runesDropped;
	}
	else
	{
		new rune = CreateEntityByName("prop_physics");
		if (IsValidEntity(rune))
		{
			SetEntityModel(rune, MODEL_POPCORN);
			SetEntityMoveType(rune, MOVETYPE_VPHYSICS);
			DispatchSpawn(rune);
			SDKHook(rune, SDKHook_Touch, runeTouch);
		}
		CreateTimer(time, teleportRune, rune);
	}
	return Plugin_Handled;
}
///////////////////////////////////////////////////Private Functions////////////////////////////////////////

AddFolderToDownloadTable(const String:Directory[], bool:recursive=false) 
{
	decl String:FileName[64], String:Path[512];
	new Handle:Dir = OpenDirectory(Directory), FileType:Type;
	while(ReadDirEntry(Dir, FileName, sizeof(FileName), Type))     
	{
		if(Type == FileType_Directory && recursive)         
		{           
			FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
			AddFolderToDownloadTable(FileName);
			continue;
			
		}                 
		if (Type != FileType_File) continue;
		FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
		AddFileToDownloadsTable(Path);
	}
	return;	
}
PerformBlind(target, amount)
{
	new targets[2];
	targets[0] = target;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if (amount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else
	{
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);
	
	EndMessage();
}
// TF2 Invisiablilty brought to you by Spazman0 ///////
SetAlpha(target, alpha)
{		
	SetWeaponsAlpha(target,alpha);
	SetEntityRenderMode(target, RENDER_TRANSCOLOR);
	SetEntityRenderColor(target, 255, 255, 255, alpha);	
}

SetWeaponsAlpha(target, alpha)
{
        if(IsPlayerAlive(target))
        {
        	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	
        
        	for(new i = 0, weapon; i < 47; i += 4)
        	{
        		weapon = GetEntDataEnt2(target, m_hMyWeapons + i);
        	
        		if(weapon > -1 )
        		{
        			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
        			SetEntityRenderColor(weapon, 255, 255, 255, alpha);
        		}
        	}
        }
}
DoColorize(client)
{
	SetWeaponsColor(client);
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SetAlpha(client, 255);
}
SetWeaponsColor(client)
{
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	

	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
	
		if(weapon > -1 )
		{
			SetEntityRenderMode(weapon, RENDER_NORMAL);
			SetEntityRenderColor(weapon, 255, 255, 255, 255);
		}
	}
}
CheckForGametype()
{
	new String:Map[256];
	GetCurrentMap(Map, sizeof(Map));
	if (StrContains(Map, "zf_", false) != -1)
	{
		pop_zfMap = true;
	}
	else
	{
		pop_zfMap = false;
	}
	if (StrContains(Map, "arena_", false) != -1)
	{
		pop_arenaMap = true;
	}
	else
	{
		pop_arenaMap = false;
	}
	if ((StrContains(Map, "ph_", false) != -1) || (StrContains(Map, "tr_", false) != -1) || (StrContains(Map, "sn_", false) != -1))
	{
		pop_nopopMap = true;
	}
	else
	{
		pop_nopopMap = false;
	}
}
/*function_killPopcorn()
{
	new search = -1;
	new String:modelname[128];
	while ((search = FindEntityByClassname(search, "prop_physics")) != -1)
	{
		GetEntPropString(search, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		if (StrEqual(modelname, "models/popcorn/popcorn.mdl")) RemoveEdict(search);
	}
}*/

FindAbility(runeType)
{
	new ability;
	switch (runeType) // extract ability from runeType
	{
		case 33:									ability = 17;
		case 32,31,30,29,28,27,26,25,24,23,22,21:	ability = 11;
		case 20,19,18:								ability = 13;
		case 17:									ability = 10;
		case 16:									ability = 9;
		case 15,14:									ability = 8;
		case 11,10:									ability = 16;
		case 8:										ability = 14;
		case 7:										ability = 7;
		case 6:										ability = 5;
		case 4:										ability = 6;
		case 3:										ability = 4;
		default:									ability = GetRandomInt(1, MAXABILITY);
	}
	return ability;
}

KillPlayer(client, attacker)
{
	if (client == attacker)
		attacker = 0;
	new ent = CreateEntityByName("env_explosion");
	if (IsValidEntity(ent))
	{
		g_alreadykilled[client] = true;
		DispatchKeyValue(ent, "iMagnitude", "1000");
		DispatchKeyValue(ent, "iRadiusOverride", "2");
		SetEntPropEnt(ent, Prop_Data, "m_hInflictor", attacker);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", attacker);
		DispatchKeyValue(ent, "spawnflags", "3964");
		DispatchSpawn(ent);
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent, "explode", client, client);
		CreateTimer(0.2, RemoveExplosion, ent);
	}
}
///////////////////////////////////////////////Note:New Rune Setup Section//////////////////////////////
public Action:throwRunes()
{
	for(new i = 0 ;i < runeAmount; ++i)
	{
		addRune(GetRandomFloat(0.1, 120.0));
	}
}
public Action:runeTouch(entity, other)
{
	new String:modelname[128];
	if (!pop_isActive)
	{
		if (IsValidEntity(entity))
		{
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
			if (StrEqual(modelname, "models/popcorn/popcorn.mdl"))
			{
				RemoveEdict(entity);
			}
		}
		return Plugin_Handled;
	}
	if (other > 0 && other <= MaxClients)
	{
		if (IsValidEntity(other))
		{
			if (IsClientConnected(other))
			{
				if (g_runeActive[other] == 0 && IsClientInGame(other))
				{
					new String:Name[4];
					g_runeActive[other] = 1;
					GetEntPropString(entity, Prop_Data, "m_iName", Name, sizeof(Name));
					new ability = StringToInt(Name);
					switch (ability) 
					{ 
						case 17:sludge(other);      //g_runeActive set to 33
						case 16:spatula(other);		//g_runeActive set to 10
						case 15:megapop(other);		//g_runeActive set to 9
						case 14:voodoo(other);		//g_runeActive set to 8
						case 13:poserspy(other);	//g_runeActive set to 18 thru 20
						case 12:uberpop(other);
						case 11:bubblewand(other);	//g_runeActive set to 21 thru 32
						case 10:tomatojuice(other);	//g_runeActive set to 17
						case 9:safetynet(other);	//g_runeActive set to 16
						case 8:mercuryshoes(other);	//g_runeActive set to 14 thru 15
						case 7:doublepop(other);	//g_runeActive set to 7
						case 6:easteregg(other);	//g_runeActive set to 4
						case 5:snowcone(other);		//g_runeActive set to 6
						case 4:vampire(other);		//g_runeActive set to 3
						case 3:bloodbag(other);											//g_runeExtra set to 4 
						case 2:cake(other);
						case 1:badkernal(other); 
						default:cake(other);
					}
					CreateTimer(0.1, teleportRune, entity);
				}
			}
		}
	}
	return Plugin_Handled;
}
//////////////////////////////////////////////Timers/////////////////////////////////////////////////////////
public Action:expandBox(Handle:timer, any:garbage)
{
	new Float:targetPos[3];
	for(new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (IsPlayerAlive(i))
			{
				GetClientEyePosition(i, targetPos);
				//PrintToChat(i, "yourPos: %f, %f, %f", targetPos[0], targetPos[1], targetPos[2]);
				//Create Max X coordinates
				if (targetPos[0] > MapX[0])
					MapX[0] = targetPos[0];
				if (targetPos[0] < MapX[1])
					MapX[1] = targetPos[0];
				//Create Max Y coordinates
				if (targetPos[1] > MapY[0])
					MapY[0] = targetPos[1];
				if (targetPos[1] < MapY[1])
					MapY[1] = targetPos[1];
				//Create Max Z coordinates
				if (targetPos[2] > MapZ[0])
					MapZ[0] = targetPos[2];
				if (targetPos[2] < MapZ[1])
					MapZ[1] = targetPos[2];
				g_spawnLocation[i] = targetPos;
			}
		}    
	}
	return Plugin_Continue;
}
public Action:teleportRune(Handle:timer, any:ent)
{
	new String:modelname[128];
	if (!pop_isActive)
	{
		if (IsValidEntity(ent))
		{
			GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
			if (StrEqual(modelname, "models/popcorn/popcorn.mdl"))
			{
				RemoveEdict(ent);
			}
		}
		return;
	}
	if (IsValidEntity(ent))
	{
		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		if (StrEqual(modelname, "models/popcorn/popcorn.mdl"))
		{
			new Float:pos[3];
			pos[0] = GetRandomFloat(MapX[0],MapX[1]);
			pos[1] = GetRandomFloat(MapY[0],MapY[1]);
			pos[2] = GetRandomFloat(MapZ[0],MapZ[1]);
			new Float:velocity[3];
			velocity[2] = 50.0;
			
			new String:Name[4];
			new ability = GetRandomInt(1, MAXABILITY);
			Format(Name, sizeof(Name), "%d", ability);
			DispatchKeyValue(ent, "targetname", Name);
			
			TeleportEntity(ent, pos, NULL_VECTOR, velocity);
			EmitAmbientSound(SOUND_RUNESPAWN, pos, ent,SNDLEVEL_NORMAL);
			g_droprune = ent;
			CreateTimer(120.0, teleportRune, ent);
		}
	}
}
public Action:teleportDropRune(client, ability)
{
	new ent = g_droprune;
	if (IsValidEntity(ent))
	{
		new String:modelname[128];
		GetEntPropString(ent, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
		if (StrEqual(modelname, "models/popcorn/popcorn.mdl"))
		{
			new Float:pos[3];
			GetClientAbsOrigin(client, pos);
			pos[2] += 120;
			new Float:velocity[3];
			velocity[0] = GetRandomFloat(0.00, 50.0);
			velocity[1] = 50.0;
			velocity[2] = GetRandomFloat(0.00, 50.0);
			
			new String:Name[4];
			Format(Name, sizeof(Name), "%d", ability);
			DispatchKeyValue(ent, "targetname", Name);
			
			TeleportEntity(ent, pos, NULL_VECTOR, velocity);
			//EmitAmbientSound(SOUND_RUNESPAWN, pos, ent,SNDLEVEL_NORMAL);
			CreateTimer(120.0, teleportRune, ent);
		}
	}
}
public Action:runeActiveReset(Handle:timer, any:client)
{
	g_runeActive[client] = 0;
}
public Action:RemoveExplosion(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		RemoveEdict(ent);
	}
}
public Action:checkDeath(Handle:timer, any:client)
{
	new attacker;
	new fFlags = GetEntProp(client, Prop_Data, "m_fFlags", fFlags);
	for(new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientConnected(i) && g_playerAttacking[i] == client)
		{
			g_playerAttacking[i] = 0;
			attacker = i;
			break;
		}
	}
	g_runeExtra[client] = 1;
	if (IsPlayerAlive(client) && !(fFlags & FL_KILLME)) KillPlayer(client, attacker);
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////Popcorn Functions////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action:sludge(client)//g_runeActive set to 33
{
	PrintCenterText(client, "Sludge Slinger");
	PrintHintText(client, "Hitting an enemy will make them go blind for a few seconds");
	g_runeExtra[client] = 0;
	g_runeActive[client] = 32;
	runesound(client);
}
public Action:bubblewand(client)//g_runeActive set to 21 thru 32 - amount of items
{
	PrintCenterText(client, "BubbleWand");
	PrintHintText(client, "Lay tiny bubbles of death with !popkey");
	g_runeExtra[client] = 0;
	g_runeActive[client] = 32;
	runesound(client);
}
public Action:bubblewandActivate(client)
{
	new runeType = g_runeActive[client];
	if (runeType > 21 && runeType < 33)
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 60;
		new bubble = CreateEntityByName("env_sprite");
		if (IsValidEntity(bubble))
		{
			SetEntPropEnt(bubble, Prop_Data,  "m_hOwnerEntity", client);
			SetEntityModel(bubble, MODEL_BUBBLE);
			SetEntityMoveType(bubble, MOVETYPE_NONE);
			SetEntityRenderMode(bubble, RENDER_TRANSTEXTURE);
			DispatchSpawn(bubble);
			TeleportEntity(bubble, vec, NULL_VECTOR, NULL_VECTOR);
			--g_runeActive[client];
			CreateTimer(3.0, bubblewandDelay, bubble);
		}
	}
}
public Action:bubblewandDelay(Handle:timer, any:bubble)
{
	CreateTimer(0.1, bubblewandTime, bubble, TIMER_REPEAT);
}
public Action:bubblewandTime(Handle:timer, any:bubble)
{
	new owner = GetEntPropEnt(bubble, Prop_Data, "m_hOwnerEntity");
	if (!IsClientInGame(owner))
	{
		RemoveEdict(bubble);
		return Plugin_Stop;
	}
	new runeType = g_runeActive[owner];
	if (runeType > 20 && runeType < 33)
	{
		new Float:bubblePos[3];
		new Float:targetPos[3];
		GetEntPropVector(bubble, Prop_Send, "m_vecOrigin", bubblePos);
		for(new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				GetClientEyePosition(i, targetPos);
				if (GetVectorDistance(bubblePos, targetPos, false) <= 100.0)
				{
					RemoveEdict(bubble);
					bubblewandTouch(owner, i);
					return Plugin_Stop;
				}
			}
		}
		return Plugin_Continue;
	}
	else if (runeType == 0)
	{
		RemoveEdict(bubble);
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}
public Action:bubblewandTouch(owner, victim)
{
	new ownerRune = g_runeActive[owner];
	if (ownerRune > 20 && ownerRune < 33)
	{
		++g_runeActive[owner];
	}
	KillPlayer(victim, owner);
}
public Action:poserspy(client)//g_runeActive set to 18 thru 20
{
	PrintCenterText(client, "Poser Spy");
	PrintHintText(client, "Cloak like a spy using !popkey");
	g_runeExtra[client] = 0;
	g_runeActive[client] = PSPY_NOCLOAK;
	runesound(client);
}
public Action:poserspyActivate(client, mode)
{
	new Float:vec[3];
	if(mode == PSPY_NOCLOAK)
	{
		g_runeActive[client] = PSPY_CLOAK;
		g_runeExtra[client] = 5;
		PrintHintText(client,"You are now cloaked");
		SetAlpha(client,0);
		GetClientAbsOrigin(client, vec);
		EmitAmbientSound(SOUND_POSERSPY_CLOAK, vec, client, SNDLEVEL_NORMAL);
		CreateTimer(10.0, poserspyTime, client);
	}
	else if (mode == PSPY_CLOAK)
	{
		g_runeActive[client] = PSPY_RECHARGE;
		g_runeExtra[client] = 0;
		PrintHintText(client,"Cloak Recharging");
		DoColorize(client);
		GetClientAbsOrigin(client, vec);
		EmitAmbientSound(SOUND_POSERSPY_UNCLOAK, vec, client, SNDLEVEL_NORMAL);
		CreateTimer(15.0, poserspyRecharge, client);
	}
}
public Action:poserspyTime(Handle:timer, any:client)
{
	if(g_runeActive[client] == PSPY_CLOAK)
	{
		g_runeActive[client] = PSPY_RECHARGE;
		g_runeExtra[client] = 0;
		PrintHintText(client,"Cloak Recharging");
		DoColorize(client);
		CreateTimer(15.0, poserspyRecharge, client);
	}
}
public Action:poserspyRecharge(Handle:timer, any:client)
{
	if (g_runeActive[client] == PSPY_RECHARGE)
	{
		g_runeActive[client] = PSPY_NOCLOAK;
		PrintHintText(client, "Cloak Recharged");
	}
}
public Action:uberpop(client)
{
	PrintCenterText(client, "Uberpop");
	PrintHintText(client, "Mmmmmm Tasty!");
	g_runeExtra[client] = 0;
	runesound(client);
	new TFClassType:class = TF2_GetPlayerClass(client);
	new health;
	switch (class)
	{
		case TFClass_Scout:		health = 185;
        case TFClass_Soldier:	health = 300;
        case TFClass_DemoMan:	health = 260;
        case TFClass_Medic:		health = 225;
        case TFClass_Pyro:		health = 260;
        case TFClass_Spy:		health = 185;
        case TFClass_Engineer:	health = 185;
        case TFClass_Sniper:	health = 185;
        case TFClass_Heavy:		health = 450;
	}
	SetEntityHealth(client, health);
	CreateTimer(0.1, runeActiveReset, client);
}
public Action:tomatojuice(client)//g_runeActive set to 17
{
	PrintCenterText(client, "TomatoJuice");
	PrintHintText(client, "Your health regenerates, !popkey instantly gives you uber health but lose this ability");
	g_runeExtra[client] = 0;
	g_runeActive[client] = 17;
	runesound(client);
	CreateTimer(1.0, tomatojuiceTime, client, TIMER_REPEAT);
}
public Action:tomatojuiceTime(Handle:timer, any:client)
{
	if (g_runeActive[client] == 17)
	{
		new health = GetEntProp(client, Prop_Send, "m_iHealth");
		health += 3;
		new TFClassType:class = TF2_GetPlayerClass(client);
		new maxhealth;
		switch (class)
		{
			case TFClass_Scout:		maxhealth = 185;
			case TFClass_Soldier:	maxhealth = 300;
			case TFClass_DemoMan:	maxhealth = 260;
			case TFClass_Medic:		maxhealth = 225;
			case TFClass_Pyro:		maxhealth = 260;
			case TFClass_Spy:		maxhealth = 185;
			case TFClass_Engineer:	maxhealth = 185;
			case TFClass_Sniper:	maxhealth = 185;
			case TFClass_Heavy:		maxhealth = 450;
		}
		if (health > maxhealth)
		{
			SetEntityHealth(client, maxhealth);
		}
		else
		{
			SetEntityHealth(client, health);
		}
		SaveHealth(client);
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}
public Action:tomatojuiceActivate(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	new health;
	switch (class)
	{
		case TFClass_Scout:		health = 185;
        case TFClass_Soldier:	health = 300;
        case TFClass_DemoMan:	health = 260;
        case TFClass_Medic:		health = 225;
        case TFClass_Pyro:		health = 260;
        case TFClass_Spy:		health = 185;
        case TFClass_Engineer:	health = 185;
        case TFClass_Sniper:	health = 185;
        case TFClass_Heavy:		health = 450;
	}
	SetEntityHealth(client, health);
	SaveHealth(client);
	g_runeActive[client] = 0;
}
public Action:safetynet(client)//g_runeActive set to 16
{
	PrintCenterText(client, "SafetyNet");
	PrintHintText(client, "If your health is low and you take fire you will be randomly teleported elsewhere");
	g_runeExtra[client] = 0;
	g_runeActive[client] = 16;
	runesound(client);
	safetynetRefresh(client);
}
public Action:safetynetRefresh(client)
{
	new Float:Pos[3];
	for(new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, Pos);
			g_spawnLocation[i] = Pos;
		}
		else
		{
			GetClientAbsOrigin(client, Pos);
			g_spawnLocation[i] = Pos;
		}
	}
}
public Action:safetynetTime(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:pos[3];
		
		pos = g_spawnLocation[GetRandomInt(1, MaxClients)];
		pos[2] += 20;
		
		new playerstate = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		if (playerstate & PLAYER_ONFIRE)
		{
			playerstate -= PLAYER_ONFIRE;
			SetEntProp(client, Prop_Send, "m_nPlayerCond", playerstate);
		} 
		
		TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
		safetynetRefresh(client);
	}
}
public Action:mercuryshoes(client)//g_runeActive set to 14 thru 15
{
	if (pop_zfMap && GetClientTeam(client) == SUR)
	{
		cake(client);
		return;
	}
	PrintCenterText(client, "MercuryShoes");
	PrintHintText(client, "Take flight, !popkey to hover in air");
	g_runeExtra[client] = 0;
	g_runeActive[client] = 14;
	runesound(client);
}
public Action:mercuryshoesActivate(client)
{
	// activates hover mode
	if(IsClientInGame(client) && IsPlayerAlive(client) && !(GetEntityFlags(client) & FL_ONGROUND) && g_runeExtra[client] != 5)
	{
		if(g_runeActive[client] == 14)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			g_runeActive[client] = 15;
		}
		else
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			g_runeActive[client] = 14;
		}
	}
}
public Action:mercuryshoesPreThink(client, buttons)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:velocity[3];
		new Float:angles[3];
		new Float:radians[2];	
		new Float:destination[3];
		new Float:push[2];
		GetClientAbsAngles(client, angles);	
		radians[0] = DegToRad(angles[0]);  
		radians[1] = DegToRad(angles[1]);
		
		if (buttons == IN_JUMP && g_runeExtra[client] != 5)
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			g_runeActive[client] = 14;
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
			velocity[2] = 266.66;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
			return;
		}
		else if (buttons == IN_FORWARD && !(GetEntityFlags(client) & FL_ONGROUND) && g_runeExtra[client] != 5)
		{
			push[0] = 10.0;
			push[1] = 10.0;
		}
		else if (buttons == IN_BACK && !(GetEntityFlags(client) & FL_ONGROUND) && g_runeExtra[client] != 5)
		{
			push[0] = -10.0;
			push[1] = -10.0;
		}
		else if (buttons == IN_RIGHT && !(GetEntityFlags(client) & FL_ONGROUND) && g_runeExtra[client] != 5)
		{
			radians[0] = DegToRad(angles[0] + 90.0); 
			push[0] = 10.0;
			push[1] = 10.0;
		}
		else if (buttons == IN_LEFT && !(GetEntityFlags(client) & FL_ONGROUND) && g_runeExtra[client] != 5)
		{
			radians[0] = DegToRad(angles[0] + 90.0); 
			push[0] = -10.0;
			push[1] = -10.0;
		}
		else return;
		SetEntityMoveType(client, MOVETYPE_WALK);
		g_runeActive[client] = 14;
		destination[0] = push[0] * Cosine(radians[0]) * Cosine(radians[1]);
		destination[1] = push[1] * Cosine(radians[0]) * Sine(radians[1]);
		destination[2] = 0 * Sine(radians[0]);
		
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		velocity[0] += destination[0];
		velocity[1] += destination[1];
		velocity[2] = destination[2];
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	}
}
public Action:popdispenser(client)//gruneActive set to 12
{
	PrintCenterText(client, "Popcorn Dispenser");
	PrintHintText(client, "(!popkey) Place a popcorn dispenser for your teammates!");
	g_runeExtra[client] = 0;
	g_runeActive[client] = 12;
	runesound(client);
}
public Action:popdispenserActivate(client)
{
	// create location based variables
	new Float:origin[3];
	new Float:angles[3];
	new Float:radians[2];
	new Float:destination[3];	
	// get client position and the direction they are facing
	GetClientEyePosition(client, origin);
	origin[2] += 180;
	GetClientAbsAngles(client, angles);	
	// convert degrees to radians
	radians[0] = DegToRad(angles[0]);  
	radians[1] = DegToRad(angles[1]);
	// calculate entity destination after creation (raw number is an offset distance)
	destination[0] = origin[0] + 100 * Cosine(radians[0]) * Cosine(radians[1]);
	destination[1] = origin[1] + 100 * Cosine(radians[0]) * Sine(radians[1]);
	destination[2] = origin[2] + 0 * Sine(radians[0]);
	new ent = CreateEntityByName("prop_physics");
	if (IsValidEntity(ent))
	{
		//SetEntPropEnt(ent, Prop_Data,  "m_hOwnerEntity", client);
		SetEntityModel(ent, MODEL_POPCORN);
		SetEntityRenderColor(ent, 0, 255, 0, 200);
		DispatchSpawn(ent);
		SDKHook(ent, SDKHook_Touch, popdispenserTouch);
		TeleportEntity(ent, destination, NULL_VECTOR, NULL_VECTOR);
	}
}
public Action:popdispenserTouch(entity, other)
{
	if (other > 0 && other <= MaxClients)
	{
		if (IsClientInGame(other) && !pop_inPopMenu[other])
		{
			pop_inPopMenu[other] = true;
			new Handle:pop_menu = BuildPopMenu();
			DisplayMenu(pop_menu, other, MENU_TIME_FOREVER);										
		}
	}
}
public popdispenserMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new String:s_client[2];
		/* Get item info */
		GetMenuItem(menu, param2, info, sizeof(info));
		GetMenuItem(menu, param1, s_client, sizeof(s_client));
		new ability = StringToInt(info);
		new client = StringToInt(s_client);
		PrintToChatAll("Menu Item Selected. Client: %i Ability: %i");
		switch (ability) 
		{ 
			case 16:spatula(client);		//g_runeActive set to 10
			case 15:megapop(client);		//g_runeActive set to 9
			case 14:voodoo(client);		//g_runeActive set to 8
			case 13:poserspy(client);	//g_runeActive set to 18 thru 20
			case 11:bubblewand(client);	//g_runeActive set to 21 thru 32
			case 10:tomatojuice(client);	//g_runeActive set to 17
			case 9:safetynet(client);	//g_runeActive set to 16
			case 8:mercuryshoes(client);	//g_runeActive set to 14 thru 15
			case 7:doublepop(client);	//g_runeActive set to 7
			case 6:easteregg(client);	//g_runeActive set to 4
			case 5:snowcone(client);		//g_runeActive set to 6
			case 4:vampire(client);
			default:cake(client);
		}		
		CreateTimer(60.0, popdispenserTime, client);
	}
	else if (action == MenuAction_Cancel)
	{
		new String:s_client[2];
		GetMenuItem(menu, param1, s_client, sizeof(s_client));
		new client = StringToInt(s_client);
		pop_inPopMenu[client] = false;
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public Action:popdispenserTime(Handle:timer, any:client)
{
	pop_inPopMenu[client] = false;
}
public Action:spatula(client)//g_runeActive set to 10 thru 11
{
	PrintCenterText(client, "Spatula");
	PrintHintText(client, "Shooting players causes them to be flipped in or pushed into the air(!popkey)");
	g_runeExtra[client] = 0;
	g_runeActive[client] = SPAT_FLIP;
	runesound(client);
}
public Action:spatulaActivate(client, mode)
{
	if (mode == SPAT_FLIP)
	{
		PrintHintText(client, "Push mode Active");
		g_runeActive[client] = SPAT_PUSH;
	}
	else // SPAT_PUSH
	{
		PrintHintText(client, "Flip mode Active");
		g_runeActive[client] = SPAT_FLIP;
	}
}
public Action:spatulaDamage(client, attacker, mode)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && g_runeExtra[client] != 5)
	{
		new Float:velocity[3];
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		EmitAmbientSound(SOUND_SPATULA, vec, client, SNDLEVEL_NORMAL);
		SetEntityMoveType(client, MOVETYPE_WALK);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		if (mode == SPAT_FLIP)
		{
			velocity[2] = 750.0;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		}
		else //mode = SPAT_PUSH
		{
			new Float:angles[3];
			new Float:radians[2];
			new Float:destination[3];
			GetClientAbsAngles(attacker, angles);	
			radians[0] = DegToRad(angles[0]);  
			radians[1] = DegToRad(angles[1]);
			destination[0] = 750 * Cosine(radians[0]) * Cosine(radians[1]);
			destination[1] = 750 * Cosine(radians[0]) * Sine(radians[1]);
			velocity[0] += destination[0];
			velocity[1] += destination[1];
			velocity[2] = 750.00;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		}
	}
}
public Action:megapop(client)//g_runeActive set to 9
{
	if (pop_megapopActive)
	{
		uberpop(client);
	}
	else
	{
		pop_megapopActive = true;
		g_runeExtra[client] = 0;
		g_runeActive[client] = 9;
		new diceroll = GetRandomInt(0, 2);
		switch(diceroll)
		{
			case 2:	frankenstein(client);//frankenstein(client);
			case 1:	meleemash(client);
			default: bloodbag(client);
		}
	}
}
public Action:meleemash(client)//megapop
{
	pop_meleemash = true;
	new String:name[32];
	GetClientName(client, name, sizeof(name));
	PrintCenterTextAll("%s has begun Melee Mash!", name);
	PrintCenterText(client, "MegaPop: Melee Mash!");
	runesound(client);
	SetAlpha(client, 255);
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 50, 255, 50, 255);
	function_DisableResupply(true);
	for (new p = 1; p <= MaxClients; ++p)
	{
		if (IsClientInGame(p))
		{
			new weaponIndex;
			// Iterate through weapon slots
			for ( new i = 0; i < 5; i++ )
			{
				// Do not remove melee weapon slot
				if ( ( weaponIndex = GetPlayerWeaponSlot( p, i ) ) != -1 && i != 2 )
				{
					RemovePlayerItem( p, weaponIndex );
					RemoveEdict( weaponIndex );
				}
			}
			new weapon = GetPlayerWeaponSlot(p, 2);
			SetEntPropEnt(p, Prop_Send, "m_hActiveWeapon", weapon);
		}
	}
}
public Action:meleemashTime(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		new weaponIndex;
		// Iterate through weapon slots
		for ( new i = 0; i < 5; i++ )
		{
			// Do not remove melee weapon slot
			if ( ( weaponIndex = GetPlayerWeaponSlot( client, i ) ) != -1 && i != 2 )
			{
				RemovePlayerItem( client, weaponIndex );
				RemoveEdict( weaponIndex );
			}
		}
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}
public Action:frankenstein(client)
{
	if (pop_arenaMap || pop_zfMap)
	{
		badkernal(client);
	}
	if (GetTeamClientCount(g_targetTeam[client]) > 2)
	{
		new String:name[32];
		GetClientName(client, name, sizeof(name));
		PrintCenterTextAll("%s is Frankenstein! Damage his teammates to destroy him.", name);
		PrintCenterText(client, "MegaPop: Frankenstein");
		PrintHintText(client, "You are invincable from attack, you take half of your teammates damage.");
		pop_frankenstein[0] = client;
		pop_frankenstein[1] = GetClientCount(true) * 25;
		//SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		TF2_AddCond(client, 5);
		SetAlpha(client, 255);
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 50, 255, 50, 255);
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		EmitSoundToAll(SOUND_ITSALIVE, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		// Do not remove melee weapon slot
		new weaponIndex;
		// Iterate through weapon slots
		for ( new i = 0; i < 5; i++ )
		{
			// Do not remove melee weapon slot
			if ( ( weaponIndex = GetPlayerWeaponSlot( client, i ) ) != -1 && i != 2 )
			{
				RemovePlayerItem( client, weaponIndex );
				RemoveEdict( weaponIndex );
			}
		}
		CreateTimer(1.0, frankensteinTime, client, TIMER_REPEAT);
	}
	else
	{
		uberpop(client);
	}
}
public Action:frankensteinTime(Handle:timer, any:client)
{
	if (GetTeamClientCount(g_targetTeam[client]) == 2)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		KillPlayer(client, client);
		PrintCenterTextAll("Frankenstein has been defeated! -Lack of Teammates!");
	}
	if (g_runeActive[client] == 9)
	{
		new Handle:hHudText = CreateHudSynchronizer();
		SetHudTextParams(-1.0, 0.2, 1.0, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudText, "Actual Health: %i", pop_frankenstein[1]);
		
		for(new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && (i != client))
			{
				ShowSyncHudText(i, hHudText, "Frankenstein's Health: %i", pop_frankenstein[1]);
			}    
		}
		CloseHandle(hHudText);
		TF2_AddCond(client, 5);
		// Do not remove melee weapon slot
		new weaponIndex;
		// Iterate through weapon slots
		for ( new i = 0; i < 5; i++ )
		{
			// Do not remove melee weapon slot
			if ( ( weaponIndex = GetPlayerWeaponSlot( client, i ) ) != -1 && i != 2 )
			{
				RemovePlayerItem( client, weaponIndex );
				RemoveEdict( weaponIndex );
			}
		}
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}
public Action:frankensteinDamage(damage, attacker)
{
	new frank = pop_frankenstein[0];
	if (frank != 0 && IsPlayerAlive(frank))
	{
		pop_frankenstein[1] -= damage;
		if (pop_frankenstein[1] < 1)
		{
			//SetEntProp(frank, Prop_Data, "m_takedamage", 2, 1);
			TF2_RemoveCond(frank, 5);
			KillPlayer(frank, attacker);
			pop_frankenstein[0] = 0;
			PrintCenterTextAll("Frankenstein has been defeated!");
		}
	}
}
public Action:voodoo(client)//g_runeActive set to 8
{
	if (pop_zfMap && GetClientTeam(client) == ZOM)
	{
		badkernal(client);
		return;
	}
	PrintCenterText(client, "Voodoo Doll");
	PrintHintText(client, "Damage delt to you is also delt back to the attacker.");
	g_runeExtra[client] = 0;
	g_runeActive[client] = 8;
	runesound(client);
}
public Action:doublepop(client)//g_runeActive set to 7
{
	PrintCenterText(client, "Kritspop");
	PrintHintText(client, "Full Krit Attacks, but you take double damage");
	TF2_AddCond(client, 11);
	CreateTimer(1.0, doublepopTime, client, TIMER_REPEAT);
	g_runeExtra[client] = 0;
	g_runeActive[client] = 7;
	runesound(client);
}
public Action:doublepopTime(Handle:timer, any:client)
{
	if (g_runeActive[client] == 7 && IsClientInGame(client))
	{
		TF2_AddCond(client, 11);
		return Plugin_Continue;
	}
	else return Plugin_Stop;
}
public Action:easteregg(client)//g_runeActive set to 4
{
	PrintCenterText(client, "EasterEgg");
	PrintHintText(client, "Cause anyone in your path to jump uncontrollably");
	g_runeExtra[client] = 0;
	g_runeActive[client] = 4;
	runesound(client);
	CreateTimer(1.0, eastereggTime, client, TIMER_REPEAT);
}
public Action:eastereggTime(Handle:timer, any:client)
{
	if (g_runeActive[client] == 4 && IsClientInGame(client))
	{
		new Float:clientPos[3];
		new Float:targetPos[3];
		GetClientEyePosition(client, clientPos);
		for(new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && (i != client) && (g_targetTeam[client] != g_targetTeam[i]))
			{
				GetClientEyePosition(i, targetPos);
				if (GetVectorDistance(clientPos, targetPos, false) <= 500.0)
				{
					g_runeExtra[i] = 2;
					g_runeBox[i] = client;
					CreateTimer(0.5, bunnyhoppedTime, i, TIMER_REPEAT);
				}
				else if (g_runeBox[i] == client)
				{
					g_runeExtra[i] = 0;
					g_runeBox[i] = 0;
				}
			}    
		}
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}
public Action:bunnyhoppedTime(Handle:timer, any:client)
{
	if (g_runeExtra[client] == 2)
	{
		CreateTimer(0.01, bunnyhoppedOnFrame, client);
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}
public Action:bunnyhoppedOnFrame(Handle:timer, any:client)
{
	if((g_runeExtra[client] == 2) && IsClientInGame(client) && IsPlayerAlive(client) && (GetEntityFlags(client) & FL_ONGROUND))
	{
		new Float:velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		velocity[0] += GetRandomFloat(-50.0,50.0);
		velocity[1] += GetRandomFloat(-50.0,50.0);
		velocity[2] = 266.66;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	}
	return Plugin_Handled;
}
public Action:snowcone(client)//g_runeActive set to 6
{
	if (pop_zfMap && GetClientTeam(client) == ZOM)
	{
		bloodbag(client);
		return;
	}
	PrintCenterText(client, "SnowCone");
	PrintHintText(client, "Freeze instead of damaging opponents, use melee to kill your prey");
	SetAlpha(client, 255);
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 97, 187, 241, 192);
	g_runeExtra[client] = 0;
	g_runeActive[client] = 6;
	runesound(client);
}
public Action:freezeTime(Handle:timer, any:client)//g_runeExtra set to 5
{
	if (IsClientInGame(client) && (g_runeExtra[client] == 5))
	{
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;	
		GetClientEyePosition(client, vec);
		EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
		SetEntityMoveType(client, MOVETYPE_WALK);
		DoColorize(client);
		g_runeExtra[client] = 0;
	}
	return Plugin_Handled;
}
public Action:vampire(client)//g_runeActive set to 3
{
	PrintCenterText(client, "Vampire");
	PrintHintText(client, "Damaging others heals you, lose health rapidly");
	SetAlpha(client, 255);
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 226, 140, 255, 192);
	g_runeActive[client] = 3;
	g_runeExtra[client] = 0;
	runesound(client);
	CreateTimer(1.0, vampireTime, client, TIMER_REPEAT);
}
public Action:vampireTime(Handle:timer, any:client)
{
	if (g_runeActive[client] == 3)
	{
		if (GetEntProp(client, Prop_Send, "m_iHealth") > 5)
		{
			SetEntityHealth(client, (GetEntProp(client, Prop_Send, "m_iHealth") - 2));
			SaveHealth(client);
		}
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}
public Action:cake(client)
{
	PrintCenterText(client, "Cake!");
	PrintHintText(client, "25 health");
	new health = GetEntProp(client, Prop_Send, "m_iHealth");
	SetEntityHealth(client, health + 25);
	SaveHealth(client);
	runesound(client);
	CreateTimer(0.1, runeActiveReset, client);
	g_runeExtra[client] = 1;
}
public Action:badkernal(client)
{
	PrintCenterText(client, "Bad Kernal");
	PrintHintText(client, "Ouch! Better luck next time");
	new health = GetEntProp(client, Prop_Send, "m_iHealth");
	SetEntityHealth(client, RoundToCeil(health * 0.5));
	SaveHealth(client);
	CreateTimer(0.1, runeActiveReset, client);
	g_runeExtra[client] = 1;
}

public Action:bloodbag(client) //g_runeExtra set to 4
{
	if (g_runeExtra[client] < 1)
	{
		PrintCenterText(client, "Generous Pain :(");
		PrintHintText(client, "Your donating health to the opposing team");
		CreateTimer(0.1, runeActiveReset, client);
		g_runeExtra[client] = 4;
		CreateTimer(0.5, bloodbagTime, client, TIMER_REPEAT);
	}
	else
	{
		cake(client);
	}
}

public Action:bloodbagTime(Handle:timer, any:client)
{
	if (g_runeExtra[client] == 4)
	{
		for(new i = 1; i < MaxClients; ++i)
		{
			if (IsClientInGame(i))
			{
				if (IsPlayerAlive(i))
				{
					if (g_targetTeam[i] != g_targetTeam[client])
					{
						if (GetEntProp(client, Prop_Send, "m_iHealth") > 50)
						{
							SetEntityHealth(i, (GetEntProp(i, Prop_Send, "m_iHealth") + 1));
							SetEntityHealth(client, (GetEntProp(client, Prop_Send, "m_iHealth") - 1));
							SaveHealth(client);
							SaveHealth(i);
						}
					}
				}
			}
		}
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}