#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#include <tf2items>
#include <sdkhooks>

#define PL_VERSION "1.12"

#define SOUND_THUNDER "ambient/explosions/explode_9.wav"
#define IMMORTAL_THEME "quickening/i_am_immortal.mp3"

new bool:IsQuickening[MAXPLAYERS+1];
new Victims[MAXPLAYERS+1][MAXPLAYERS+1];
new bool:IsDead[MAXPLAYERS+1];
new MyKiller[MAXPLAYERS+1];
new Float:QuickeningTimes[MAXPLAYERS+1];
new Float:QuickeningCritTimes[MAXPLAYERS+1];
new bool:NoTheme[MAXPLAYERS+1];

new Handle:cvarEnabled;

new bool:IsArena;

new g_LightningSprite;

public Plugin:myinfo =
{
	name        = "[TF2] The Quickening",
	author      = "Ratchet",
	description = "Highlander gamemode for Team Fortress 2",
	version     = PL_VERSION,
	url         = ""
}

public OnPluginStart()
{
	HookEvent("player_changeclass", Event_PlayerClass);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("teamplay_round_start", Event_RoundStart);

	CreateConVar( "quickening_version", PL_VERSION, "The Quickening plugin version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD );

	RegConsoleCmd("qcsound", HandleToggleTheme, "Toggles 'I am immortal' theme" );
	RegConsoleCmd("qchelp", HandleHelp, "Opens up help menu" );

	cvarEnabled = CreateConVar("tf2_quickening_enabled", "1", "Enables/Disables quickening mod", FCVAR_PLUGIN, true, 0.0, true, 1.0);
}
public TF2_OnConditionAdded(client, TFCond:condition)
{
	if (condition == TFCond_Taunting) DoTaunt(client, "+taunt", 0);
}
public OnClientPutInServer(Client)
{
	CreateTimer(60.0, HintTimer, GetClientUserId(Client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:HintTimer(Handle:Timer, any:userid)
{
	new Client = GetClientOfUserId(userid);
	if (!IsValidClient(Client)) return;
	if (!GetConVarBool(cvarEnabled)) PrintToChat(Client, "\x04[HL]\x01 Type \x04/qchelp\x01 for help!");
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

	DrawPanelItem(AboutPanel, "The only way to kill an immortal" );
	DrawPanelItem(AboutPanel, "is to cut his head off and" );
	DrawPanelItem(AboutPanel, "absorb his powers (taunt) within" );
	DrawPanelItem(AboutPanel, "five seconds, else he will resurrect." );
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
		PrintToChat(Client, "\x04[HL]\x01 Theme has been toggled \x04off\x01!");
		StopSound(Client, SNDCHAN_AUTO, IMMORTAL_THEME);
	}
	else
	{
		NoTheme[Client] = false;
		PrintToChat(Client, "\x04[HL]\x01 Theme has been toggled \x04on\x01!");
	}
}

public Action:HandleToggleTheme(Client, Args)
{
	ToggleTheme(Client);

	//Return:
	return Plugin_Handled;
}

public OnEventShutdown()
{
	UnhookEvent("player_changeclass", Event_PlayerClass);
	UnhookEvent("player_spawn", Event_PlayerSpawn);
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("teamplay_round_start", Event_RoundStart);
}

public OnMapStart()
{
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
	SetConVarInt(FindConVar("tf_bot_taunt_victim_chance"), 100);

	PrecacheSound(SOUND_THUNDER, true);
	PrecacheSound(IMMORTAL_THEME, true);
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");

	AddFileToDownloadsTable("sound/quickening/i_am_immortal.mp3");
	CheckArena();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	IsArena = false;

	if( !GetConVarBool(cvarEnabled) )
		return;

	CheckArena();

	if( !IsArena )
		return;

	new CP=-1,CPm=-1;
	while ((CP = FindEntityByClassname2(CP, "trigger_capture_area")) != -1)
	{
		if ((CP>0) && IsValidEdict(CP))
			AcceptEntityInput(CP, "Disable");
	}
	while ((CPm = FindEntityByClassname2(CPm, "team_control_point")) != -1)
	{
		if ((CPm>0) && IsValidEdict(CPm))
			AcceptEntityInput(CPm, "HideModel");
	}

	CheckArena();

	decl MaxPlayers;
	MaxPlayers = GetMaxClients();
	decl RED, BLU;
	RED = 0; 
	BLU = 0;

	//Count how many alive players are in each team
	for(new i = 1; i <= MaxPlayers; i++)
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			if( GetClientTeam(i) == _:TFTeam_Red )
				RED++;
			else
				BLU++;
		}

	PerformTeamFixup(RED, BLU, true);

	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	for (new i = 1; i <= MaxClients; i++)
		if (IsValidClient(i) && IsPlayerAlive(i))
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

	if(IsValidClient(iClient) && GetClientTeam(iClient) == iTeam && TF2_GetPlayerClass(iClient) != TFClass_DemoMan && TF2_GetPlayerClass(iClient) != TFClass_Unknown)
	{
		TF2_SetPlayerClass(iClient, TFClass_DemoMan);
		TF2_RespawnPlayer(iClient);
	}

	new Weapon = GetPlayerWeaponSlot(iClient, 0);
	
	//Only allow "Ali Baba's Wee Booties"
	if (IsValidEdict(Weapon) && (Weapon > 0))
		TF2_RemoveWeaponSlot(iClient, 0);

	Weapon = GetPlayerWeaponSlot(iClient, 1);

	//Do not allow anything except "Chargin' Targe" and "The Splendid Screen"
	if (IsValidEdict(Weapon) && (Weapon > 0))
		TF2_RemoveWeaponSlot(iClient, 1);

	Weapon = GetPlayerWeaponSlot(iClient, 2);

	//Only allow weapons that cut heads off
	if (IsValidEdict(Weapon) && (Weapon > 0))
	{
		decl String:classname[64];
		//If the weapon can't cut off heads, replace it with a Claidheamh Mor that doesn't have any attributes
		if (!(GetEdictClassname(Weapon, classname, sizeof(classname)) && (StrEqual(classname, "tf_weapon_sword", false) || StrEqual(classname, "tf_weapon_katana", false))))
		{
			TF2_RemoveWeaponSlot(iClient, 2);
			Weapon = SpawnWeapon(iClient,"tf_weapon_sword",327,1,6,"");
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

	if(IsValidClient(iClient) && GetClientTeam(iClient) == iTeam && TF2_GetPlayerClass(iClient) != TFClass_DemoMan && TF2_GetPlayerClass(iClient) != TFClass_Unknown)
	{
		TF2_SetPlayerClass(iClient, TFClass_DemoMan);
		TF2_RespawnPlayer(iClient);
	}
}

public StartQuickening(Client, Kills)
{
	IsQuickening[Client] = true;
	CreateTimer(5.0, StopQuickening, GetClientUserId(Client));

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

	CreateTimer( 0.1, DoEffects, GetClientUserId(Client) );
	DoCloud(Client);
}

public Action:DoEffects(Handle:Timer, any:userid)
{
	new Client = GetClientOfUserId(userid);
	if (!IsValidClient(Client)) return;
	if( IsQuickening[Client] )
		CreateTimer( 0.15, DoEffects, userid );

	DoLightning(Client);
}

public Action:StopQuickening(Handle:Timer, any:userid)
{
	new Client = GetClientOfUserId(userid);
	if (!IsValidClient(Client)) return;
	IsQuickening[Client] = false;

	SetEntityMoveType(Client, MOVETYPE_WALK);
}

public Action:Resurrect(Handle:Timer, any:userid)
{
	new Client = GetClientOfUserId(userid);
	if (!IsValidClient(Client)) return;
	if(IsValidClient(Client) && !IsDead[Client] && !IsPlayerAlive(Client))
	{
		PrintToChat(Client, "\x04[HL]\x01 You have resurrected!");
		Victims[MyKiller[Client]][Client] = false;
		decl String:PlayerName[32];
		GetClientName(Client, PlayerName, 32);
		if (IsValidClient(MyKiller[Client])) PrintToChat(MyKiller[Client], "\x04[HL]\x01 %s has resurrected!", PlayerName);
		TF2_RespawnPlayer(Client);
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !IsArena )
		return;

	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if( Client != Attacker )
	{
		MyKiller[Client] = Attacker;
		Victims[Attacker][Client] = true;
		SetHudTextParams(-1.0, 0.83, 1.0, 255, 64, 64, 255);
		ShowHudText(Attacker, -1, "TAUNT to absorb his powers!" );
	}

	CreateTimer( 5.0, Resurrect, GetClientUserId(Client) );

	decl MaxPlayers;
	MaxPlayers = GetMaxClients();
	decl BLU, RED; 
	decl String:PlayerName[32];

	BLU = 0;
	RED = 0;

	//Make sure we count this kill
	if( GetClientTeam(Client) == _:TFTeam_Red )
		RED--;
	else
		BLU--;

	//Count how many alive players are in each team
	for(new i = 1; i <= MaxPlayers; i++)
		if(IsValidClient(i) && IsPlayerAlive(i))
		{
			GetClientName(i, PlayerName, 32);
			if( GetClientTeam(i) == _:TFTeam_Red )
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

	//PrintToChatAll( "RED: %i BLU: %i", RED, BLU );

	//Do not perform this action when it's one on one battle
	if( RED == 1 && BLU == 1 )
		return;

	if( RED == 0 && BLU == 1 )
		return;

	if( RED == 1 && BLU == 0 )
		return;

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

stock PerformTeamFixup(RED, BLU, IsScramble = false)
{
	//PrintToChatAll( "RED: %i, BLU:%i", RED, BLU );
	decl MaxPlayers, HowManyToTransfer, TransferToTeam;
	MaxPlayers = GetMaxClients();

	HowManyToTransfer = 0;
	TransferToTeam = 0;

	if( RED > BLU )
	{
		HowManyToTransfer = (RED-BLU)/2;
		TransferToTeam = _:TFTeam_Blue;
	}
	else
	{
		HowManyToTransfer = (BLU-RED)/2;
		TransferToTeam = _:TFTeam_Red;
	}

	//PrintToChatAll( "Need to transfer %i players to %i team.", HowManyToTransfer, TransferToTeam );

	for( new i = 1; i <= MaxPlayers; i++ )
		if(IsValidClient(i) && IsPlayerAlive(i) && TransferToTeam != 0)
			if(GetClientTeam(i) != TransferToTeam && HowManyToTransfer > 0 )
			{
				if( HowManyToTransfer <= 0 )
					break;

				//Save values
				decl Float:ClientOrigin[3], Float:ClientAngles[3], Health;
				if( !IsScramble )
				{
					GetClientAbsOrigin(i, ClientOrigin);
					GetClientAbsAngles(i, ClientAngles);
					Health = GetClientHealth(i);
				}

				//Switch teams
				ChangeClientTeam(i, TransferToTeam);
				TF2_RespawnPlayer(i);

				if( !IsScramble )
				{
					//Teleport me to my previous location and set previous health
					TeleportEntity(i, ClientOrigin, ClientAngles, NULL_VECTOR);
					SetEntProp(i, Prop_Send, "m_iHealth", Health);
				}

				HowManyToTransfer--;
			}

}

public OnGameFrame()
{
	//Declare:
	decl MaxPlayers;

	//Initialize:
	MaxPlayers = GetMaxClients();

	//Loop:
	for(new Client = 1; Client <= MaxPlayers; Client++)
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
	Format(origin, sizeof(origin), "%f %f %f", clientpos[0], clientpos[1], clientpos[2] + 1000);

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

	CreateTimer(7.0, RemoveCloud, EntIndexToEntRef(gascloud));
}
stock bool:IsValidClient(client)
{
	if (client <= 0 || client >= MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
DoLightning(target)
{
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
	startpos[2] = clientpos[2] + 1000;

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

public Action:RemoveCloud(Handle:timer, any:ref)
{
	new gascloud = EntRefToEntIndex(ref);

	if (IsValidEntity(gascloud))
	{
		AcceptEntityInput(gascloud, "TurnOff");

		CreateTimer(5.0, CloudKill, ref);
	}
}

public Action:CloudKill(Handle:timer, any:ref)
{
	new gascloud = EntRefToEntIndex(ref);

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

public Action:OnGetGameDescription(String:gameDesc[64])
{
	Format(gameDesc, sizeof(gameDesc), "The Highlander");
	return Plugin_Changed;
}

public Action:DoTaunt(Client, const String:command[], argc)
{
	if( !IsPlayerAlive(Client) && !IsQuickening[Client] )
		return;

	decl MaxPlayers, Kills;
	Kills = 0;
	MaxPlayers = GetMaxClients();

	//Count how many alive players are in each team
	for(new i = 1; i <= MaxPlayers; i++)
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
				PrintToChat(Client, "\x04[HL]\x01 You have absorbed \x04%s\x01's powers!", VictimName);
				PrintToChat(i, "\x04[HL]\x01 You have been absorbed by \x04%s\x01!", PlayerName);
			}
		}

	if( Kills > 0 )
		StartQuickening( Client, Kills );
}