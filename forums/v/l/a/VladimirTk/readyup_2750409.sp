#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
//#include <builtinvotes>
#include <nativevotes>
#include <colors>

#pragma semicolon 1
#pragma newdecls required

#define NULL_VELOCITY Float:{0.0, 0.0, 0.0}
#define MAX_FOOTERS 10
#define MAX_FOOTER_LEN 65
#define MAX_SOUNDS 5

#define SOUND "ui\\survival_medal.wav"

#define DEBUG 0

public Plugin myinfo =
{
	name = "L4D2 Ready-Up",
	author = "CanadaRox, (Lazy unoptimized additions by Sir)",
	description = "New and improved ready-up plugin.",
	version = "9.2.3",
	url = ""
};

enum L4D2Team:
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
}

// Plugin Cvars
Handle l4d_ready_disable_spawns;
Handle l4d_ready_cfg_name;
Handle l4d_ready_survivor_freeze;
Handle l4d_ready_max_players;
Handle l4d_ready_enable_sound;
Handle l4d_ready_delay;
Handle l4d_ready_chuckle;
Handle l4d_ready_live_sound;
Handle g_hVote;

//AFK?!
float g_fButtonTime[MAXPLAYERS+1];

// Game Cvars
Handle director_no_specials;
Handle god;
Handle sb_stop;
Handle sv_infinite_primary_ammo;

Handle casterTrie;
Handle liveForward;
Handle menuPanel;
Handle readyCountdownTimer;
char readyFooter[MAX_FOOTERS][MAX_FOOTER_LEN];
bool hiddenPanel[MAXPLAYERS + 1];
bool hiddenManually[MAXPLAYERS + 1];
bool inLiveCountdown = false;
bool inReadyUp;
bool isPlayerReady[MAXPLAYERS + 1];
int footerCounter = 0;
int readyDelay;
Handle allowedCastersTrie;
char liveSound[256];
bool blockSecretSpam[MAXPLAYERS + 1];
bool bHostName;
char sCmd[32];
int iCmd;
float g_fTime;

char countdownSound[MAX_SOUNDS][]=
{
	"buttons\\blip2.wav",
	"buttons\\blip2.wav",
	"buttons\\blip2.wav",
	"buttons\\blip2.wav",
	"buttons\\blip2.wav"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("AddStringToReadyFooter", Native_AddStringToReadyFooter);
	CreateNative("IsInReady", Native_IsInReady);
	CreateNative("IsClientCaster", Native_IsClientCaster);
	CreateNative("IsIDCaster", Native_IsIDCaster);
	liveForward = CreateGlobalForward("OnRoundIsLive", ET_Event);
	RegPluginLibrary("readyup");
	return APLRes_Success;
}

public void OnPluginStart()
{
	
	CreateConVar("l4d_ready_enabled", "1", "This cvar doesn't do anything, but if it is 0 the logger wont log this game.", 0, true, 0.0, true, 1.0);
	l4d_ready_cfg_name = CreateConVar("l4d_ready_cfg_name", "", "Configname to display on the ready-up panel", FCVAR_PRINTABLEONLY);
	l4d_ready_disable_spawns = CreateConVar("l4d_ready_disable_spawns", "0", "Prevent SI from having spawns during ready-up", 0, true, 0.0, true, 1.0);
	l4d_ready_survivor_freeze = CreateConVar("l4d_ready_survivor_freeze", "1", "Freeze the survivors during ready-up.  When unfrozen they are unable to leave the saferoom but can move freely inside", 0, true, 0.0, true, 1.0);
	l4d_ready_max_players = CreateConVar("l4d_ready_max_players", "8", "Maximum number of players to show on the ready-up panel.", 0, true, 0.0, true, MAXPLAYERS+1.0);
	l4d_ready_delay = CreateConVar("l4d_ready_delay", "3", "Number of seconds to count down before the round goes live.", 0, true, 0.0);
	l4d_ready_enable_sound = CreateConVar("l4d_ready_enable_sound", "1", "Enable sound during countdown & on live");
	l4d_ready_chuckle = CreateConVar("l4d_ready_chuckle", "1", "Enable chuckle during countdown");
	l4d_ready_live_sound = CreateConVar("l4d_ready_live_sound", "ui\\survival_medal.wav", "The sound that plays when a round goes live");
	HookConVarChange(l4d_ready_survivor_freeze, SurvFreezeChange);

	HookEvent("round_start", RoundStart_Event);
	HookEvent("player_team", PlayerTeam_Event);

	GetConVarString(l4d_ready_live_sound, liveSound, sizeof(liveSound));
	PrecacheSound(SOUND);
	PrecacheSound("buttons\\blip1.wav");
	PrecacheSound("buttons\\blip2.wav");
	PrecacheSound(liveSound);
	for (int i = 0; i < MAX_SOUNDS; i++)
	{
		PrecacheSound(countdownSound[i]);
	}
	
	casterTrie = CreateTrie();
	allowedCastersTrie = CreateTrie();

	director_no_specials = FindConVar("director_no_specials");
	god = FindConVar("god");
	sb_stop = FindConVar("sb_stop");
	sv_infinite_primary_ammo = FindConVar("sv_infinite_primary_ammo");
	
	RegAdminCmd("sm_caster", Caster_Cmd, ADMFLAG_BAN, "Registers a player as a caster so the round will not go live unless they are ready");
	RegAdminCmd("sm_forcestart", ForceStart_Cmd, ADMFLAG_BAN, "Forces the round to start regardless of player ready status.  Players can unready to stop a force");
	RegAdminCmd("sm_fs", ForceStart_Cmd, ADMFLAG_BAN, "Forces the round to start regardless of player ready status.  Players can unready to stop a force");
	RegConsoleCmd("\x73\x6d\x5f\x62\x6f\x6e\x65\x73\x61\x77", Secret_Cmd, "Every player has a different secret number between 0-1023");
	RegConsoleCmd("sm_hide", Hide_Cmd, "Hides the ready-up panel so other menus can be seen");
	RegConsoleCmd("sm_show", Show_Cmd, "Shows a hidden ready-up panel");
	AddCommandListener(Say_Callback, "say");
	AddCommandListener(Say_Callback, "say_team");
	AddCommandListener(Vote_Callback, "Vote");
	RegConsoleCmd("sm_notcasting", NotCasting_Cmd, "Deregister yourself as a caster or allow admins to deregister other players");
	RegConsoleCmd("sm_uncast", NotCasting_Cmd, "Deregister yourself as a caster or allow admins to deregister other players");
	RegConsoleCmd("sm_r", Ready_Cmd, "Mark yourself as ready for the round to go live");
	RegConsoleCmd("sm_toggleready", ToggleReady_Cmd, "Toggle your ready status");
	RegConsoleCmd("sm_nr", Unready_Cmd, "Mark yourself as not ready if you have set yourself as ready");
	RegConsoleCmd("sm_return", Return_Cmd, "Return to a valid saferoom spawn if you get stuck during an unfrozen ready-up period");
	RegConsoleCmd("sm_cast", Cast_Cmd, "Registers the calling player as a caster so the round will not go live unless they are ready");
	RegConsoleCmd("sm_kickspecs", KickSpecs_Cmd, "Let's vote to kick those Spectators!");
	RegServerCmd("sm_resetcasters", ResetCaster_Cmd, "Used to reset casters between matches.  This should be in confogl_off.cfg or equivalent for your system");
	RegServerCmd("sm_add_caster_id", AddCasterSteamID_Cmd, "Used for adding casters to the whitelist -- i.e. who's allowed to self-register as a caster");

#if DEBUG
	RegAdminCmd("sm_initready", InitReady_Cmd, ADMFLAG_ROOT);
	RegAdminCmd("sm_initlive", InitLive_Cmd, ADMFLAG_ROOT);
#endif

	LoadTranslations("common.phrases");
	CreateTimer(0.2, CheckStuff);
	
	// Crear automáticamente el archivo de configuración en cfg/sourcemod
	AutoExecConfig( true, "readyup" );
}

public Action CheckStuff(Handle timer)
{
	bHostName = (FindPluginByFile("server_namer.smx") != INVALID_HANDLE);	
}

public Action Say_Callback(int client, const char[] command, int argc)
{
	SetEngineTime(client);
}

/*****Con esta funcion haces que la votacion se pueda iniciar con F1 y F2******/

public Action Vote_Callback(int client, char[] command, int argc)
{
	// Used to fast ready/unready through default keybinds for voting
	if (!inReadyUp) return;
	if (NativeVotes_IsVoteInProgress()) return;
	if (!client) return;
	
	char sArg[8];
	GetCmdArg(1, sArg, sizeof(sArg));
	if (strcmp(sArg, "Yes", false) == 0)
		Ready_Cmd(client, 0);
	else if (strcmp(sArg, "No", false) == 0)
		Unready_Cmd(client, 0);
}
/******************************************************************************/
public void OnPluginEnd()
{
	InitiateLive(false);
}

public void OnMapStart()
{
	/* OnMapEnd needs this to work */
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		blockSecretSpam[client] = false;
	}
	readyCountdownTimer = INVALID_HANDLE;

	char sMap[64];
	GetCurrentMap(sMap, 64);
}

public Action KickSpecs_Cmd(int client, int args)
{
	if (IsClientInGame(client) && GetClientTeam(client) != 1)
	{
		if (NativeVotes_IsNewVoteAllowed())
		{
			int iNumPlayers;
			int[] iPlayers = new int[MaxClients];
			//list of non-spectators players
			for (int i=1; i<=MaxClients; i++)
			{
				if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == 1))
				{
					continue;
				}
				iPlayers[iNumPlayers++] = i;
			}
			char sBuffer[64];
			g_hVote = NativeVotes_Create(VoteActionHandler, NativeVotesType_Custom_YesNo, MenuAction_VoteCancel | MenuAction_VoteEnd | MenuAction_End);
			Format(sBuffer, sizeof(sBuffer), "Kick Non-Admin & Non-Casting Spectators?");
			NativeVotes_SetTitle(g_hVote, sBuffer);
			//SetBuiltinVoteArgument(g_hVote, sBuffer);
			NativeVotes_SetInitiator(g_hVote, client);
			NativeVotes_SetResultCallback(g_hVote, SpecVoteResultHandler);
			//SetBuiltinVoteResultCallback(g_hVote, SpecVoteResultHandler);
			NativeVotes_Display(g_hVote, iPlayers, iNumPlayers, 20);
			return;
		}
		PrintToChat(client, "No se puede iniciar la votación ahora.");
	}
	return;
}

public int VoteActionHandler(Handle vote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			g_hVote = INVALID_HANDLE;
			NativeVotes_Close(vote);
		}
		case MenuAction_VoteCancel:
		{
			NativeVotes_DisplayFail(vote, NativeVotesFail_Generic);
		}
	}
}

public int SpecVoteResultHandler(Handle vote, int num_votes, int num_clients, const client_info1[],const client_info2[], int num_items, const item_info1[],const item_info2[])
{
	for (int i=0; i<num_items; i++)
    {
        if (item_info1[i] == NATIVEVOTES_VOTE_YES)
        {
            if (item_info2[i] > (num_votes / 2))
            {
                NativeVotes_DisplayPass(vote, "Ciao Spectators!");
                for (int c=1; c<=MaxClients; c++)
                {
                    if (IsClientInGame(c) && (GetClientTeam(c) == 1) && !IsClientCaster(c) && GetUserAdmin(c) == INVALID_ADMIN_ID)
                    {
                        KickClient(c, "No Spectators, please!");
                    }
                }
                return;
            }
        }
    }
	NativeVotes_DisplayFail(vote,NativeVotesFail_Loses);
	//DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

public Action Secret_Cmd(int client, int args)
{
	if (inReadyUp && IsClientInGame(client) && GetClientTeam(client) != 1)
	{
		char steamid[64];
		char argbuf[30];
		GetCmdArg(1, argbuf, sizeof(argbuf));
		int arg = StringToInt(argbuf);
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		int id = StringToInt(steamid[10]);

		if ((id & 1023) ^ arg == 'C'+'a'+'n'+'a'+'d'+'a'+'R'+'o'+'x')
		{
			DoSecrets(client);
			isPlayerReady[client] = true;
			if (CheckFullReady())
				InitiateLiveCountdown();

			return Plugin_Handled;
		}
		
	}
	return Plugin_Continue;
}

stock void DoSecrets(int client)
{
	PrintCenterTextAll("\x42\x4f\x4e\x45\x53\x41\x57\x20\x49\x53\x20\x52\x45\x41\x44\x59\x21");
	if ((view_as<L4D2Team>(GetClientTeam(client)) == L4D2Team_Survivor) && !blockSecretSpam[client])
	{
		int particle = CreateEntityByName("info_particle_system");
		float pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] += 50;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", "achieved");
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(10.0, killParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
		Command_Play(SOUND);
		//EmitSoundToAll(SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
		/*for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;
			if (IsFakeClient(i))
				continue;
			EmitSoundToClient(i, SOUND, i, SNDCHAN_WEAPON, SNDLEVEL_SCREAMING);
		}*/
		CreateTimer(2.0, SecretSpamDelay, client);
		blockSecretSpam[client] = true;
	}
}

public Action SecretSpamDelay(Handle timer, int client)
{
	blockSecretSpam[client] = false;
}

public Action killParticle(Handle timer, int entity)
{
	if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

/* This ensures all cvars are reset if the map is changed during ready-up */
public void OnMapEnd()
{
	if (inReadyUp)
		InitiateLive(false);
}

public void OnClientDisconnect(int client)
{
	hiddenPanel[client] = false;
	hiddenManually[client] = false;
	isPlayerReady[client] = false;
	g_fButtonTime[client] = 0.0;
}

void SetEngineTime(int client)
{
	g_fButtonTime[client] = GetEngineTime();
}

public int Native_AddStringToReadyFooter(Handle plugin,int numParams)
{
	char footer[MAX_FOOTER_LEN];
	GetNativeString(1, footer, sizeof(footer));
	if (footerCounter < MAX_FOOTERS)
	{
		if (strlen(footer) < MAX_FOOTER_LEN)
		{
			strcopy(readyFooter[footerCounter], MAX_FOOTER_LEN, footer);
			footerCounter++;
			return view_as<int>(true);
		}
	}
	return view_as<int>(false);
}

public int Native_IsInReady(Handle plugin, int numParams)
{
	return view_as<int>(inReadyUp);
}

public int Native_IsClientCaster(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return view_as<int>(IsClientCaster(client));
}

public int Native_IsIDCaster(Handle plugin, int numParams)
{
	char buffer[64];
	GetNativeString(1, buffer, sizeof(buffer));
	return view_as<int>(IsIDCaster(buffer));
}

stock bool IsClientCaster(int client)
{
	char buffer[64];
	return GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer)) && IsIDCaster(buffer);
}

stock bool IsIDCaster(const char[] AuthID)
{
	int dummy;
	return GetTrieValue(casterTrie, AuthID, dummy);
}

public Action Cast_Cmd(int client, int args)
{  
	char buffer[64];
	GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));

	if (GetClientTeam(client) != 1) ChangeClientTeam(client, 1);

	SetTrieValue(casterTrie, buffer, 1);
	CPrintToChat(client, "{blue}[{default}Cast{blue}] {default}Te has registrado como caster");
	CPrintToChat(client, "{blue}[{default}Cast{blue}] {default}Vuelve a conectarte para que tus addons funcionen.");
	return Plugin_Handled;
}

public Action Caster_Cmd(int client, int args)
{   
	if (args < 1)
	{
		ReplyToCommand(client, "[Cast] Modo de uso: sm_caster <nombre del jugador>");
		return Plugin_Handled;
	}
	
	char buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	int target = FindTarget(client, buffer, true, false);
	if (target > 0) // If FindTarget fails we don't need to print anything as it prints it for us!
	{
		if (GetClientAuthId(target, AuthId_Steam2, buffer, sizeof(buffer)))
		{
			SetTrieValue(casterTrie, buffer, 1);
			ReplyToCommand(client, "%N registrado como caster", target);
			CPrintToChat(client, "{blue}[{olive}!{blue}] {default}Un admin te ha registrado como caster");
		}
		else
		{
			ReplyToCommand(client, "No se pudo encontrar Steam ID. Comprueba si hay errores tipográficos y deja que el jugador consiga estar totalmente conectado.");
		}
	}
	return Plugin_Handled;
}

public Action ResetCaster_Cmd(int args)
{
	ClearTrie(casterTrie);
	return Plugin_Handled;
}

public Action AddCasterSteamID_Cmd(int args)
{
	char buffer[128];
	GetCmdArgString(buffer, sizeof(buffer));
	if (buffer[0] != EOS) 
	{
		int index;
		GetTrieValue(allowedCastersTrie, buffer, index);
		if (index != 1)
		{
			SetTrieValue(allowedCastersTrie, buffer, 1);
			PrintToServer("[casters_database] Added '%s'", buffer);
		}
		else PrintToServer("[casters_database] '%s' already exists", buffer);
	}
	else PrintToServer("[casters_database] No args specified / empty buffer");
	return Plugin_Handled;
}

public Action Hide_Cmd(int client, int args)
{
	hiddenPanel[client] = true;
	hiddenManually[client] = true;
	return Plugin_Handled;
}

public Action Show_Cmd(int client, int args)
{
	hiddenPanel[client] = false;
	hiddenManually[client] = false;
	return Plugin_Handled;
}

public Action NotCasting_Cmd(int client, int args)
{
	char buffer[64];
	
	if (args < 1) // If no target is specified
	{
		GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
		RemoveFromTrie(casterTrie, buffer);
		CPrintToChat(client, "{blue}[{default}Reconnect{blue}] {default}Te estas reconectando al servidor...");
		CPrintToChat(client, "{blue}[{default}Reconnect{blue}] {default}¡Hay una pantalla negra en lugar de una barra de carga!");
		CreateTimer(3.0, Reconnect, client);
		return Plugin_Handled;
	}
	else // If a target is specified
	{
		AdminId id;
		id = GetUserAdmin(client);
		bool hasFlag = false;
		
		if (id != INVALID_ADMIN_ID)
		{
			hasFlag = GetAdminFlag(id, Admin_Ban); // Check for specific admin flag
		}
		
		if (!hasFlag)
		{
			ReplyToCommand(client, "Solo los administradores pueden eliminar a otros usuarios. Utilice sm_notcasting sin argumentos si desea eliminarse.");
			return Plugin_Handled;
		}
		
		GetCmdArg(1, buffer, sizeof(buffer));
		
		int target = FindTarget(client, buffer, true, false);
		if (target > 0) // If FindTarget fails we don't need to print anything as it prints it for us!
		{
			if (GetClientAuthId(target, AuthId_Steam2, buffer, sizeof(buffer)))
			{
				RemoveFromTrie(casterTrie, buffer);
				ReplyToCommand(client, "%N ya no es caster", target);
			}
			else
			{
				ReplyToCommand(client, "No se pudo encontrar Steam ID. Comprueba si hay errores tipográficos y deja que el jugador consiga estar totalmente conectado.");
			}
		}
		return Plugin_Handled;
	}
}

public Action Reconnect(Handle timer, int client)
{
	if (IsClientConnected(client) && IsClientInGame(client)) ReconnectClient(client);
}

public Action ForceStart_Cmd(int client, int args)
{
	if (inReadyUp)
	{
		InitiateLiveCountdown();
	}
	return Plugin_Handled;
}

public Action Ready_Cmd(int client, int args)
{
	if (inReadyUp && IsClientInGame(client) && IsPlayer(client))
	{
		isPlayerReady[client] = true;
		if (CheckFullReady())
			InitiateLiveCountdown();
	}

	return Plugin_Handled;
}

public Action Unready_Cmd(int client, int args)
{
	if (inReadyUp && IsClientInGame(client) && IsPlayer(client))
	{
		SetEngineTime(client);
		isPlayerReady[client] = false;
		CancelFullReady();
	}

	return Plugin_Handled;
}

public Action ToggleReady_Cmd(int client, int args)
{
	if (inReadyUp && IsClientInGame(client) && IsPlayer(client))
	{
		if (!isPlayerReady[client])
		{
			isPlayerReady[client] = true;
			if (CheckFullReady()) InitiateLiveCountdown();
		}
		else
		{
			SetEngineTime(client);
			isPlayerReady[client] = false;
			CancelFullReady();
		}
	}
	return Plugin_Handled;
}

/* No need to do any other checks since it seems like this is required no matter what since the intros unfreezes players after the animation completes */
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (inReadyUp)
	{
		if (buttons && !IsFakeClient(client)) SetEngineTime(client);
		if (IsClientInGame(client) && view_as<L4D2Team> (GetClientTeam(client)) == L4D2Team_Survivor)
		{
			if (GetConVarBool(l4d_ready_survivor_freeze))
			{
				if (!(GetEntityMoveType(client) == MOVETYPE_NONE || GetEntityMoveType(client) == MOVETYPE_NOCLIP))
				{
					SetClientFrozen(client, true);
				}
			}
			else
			{
				if (GetEntityFlags(client) & FL_INWATER)
				{
					ReturnPlayerToSaferoom(client, false);
				}
			}
		}
	}
}

public void SurvFreezeChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	ReturnTeamToSaferoom(L4D2Team_Survivor);
	SetTeamFrozen(L4D2Team_Survivor, GetConVarBool(convar));
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (inReadyUp)
	{
		ReturnPlayerToSaferoom(client, false);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Return_Cmd(int client, int args)
{
	if (client > 0
			&& inReadyUp
			&& view_as<L4D2Team> (GetClientTeam(client)) == L4D2Team_Survivor)
	{
		ReturnPlayerToSaferoom(client, false);
	}
	return Plugin_Handled;
}

public void RoundStart_Event(Handle event, const char[] name, bool dontBroadcast)
{
	InitiateReadyUp();
}

public void PlayerTeam_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEngineTime(client);
	L4D2Team oldteam = view_as<L4D2Team> (GetEventInt(event, "oldteam"));
	L4D2Team team = view_as<L4D2Team> (GetEventInt(event, "team"));
	if ((oldteam == L4D2Team_Survivor || oldteam == L4D2Team_Infected ||
			team == L4D2Team_Survivor || team == L4D2Team_Infected) && isPlayerReady[client])
	{
		CancelFullReady();
	}
}

#if DEBUG
public Action InitReady_Cmd(int client, int args)
{
	InitiateReadyUp();
	return Plugin_Handled;
}

public Action InitLive_Cmd(int client, int args)
{
	InitiateLive();
	return Plugin_Handled;
}
#endif

public int DummyHandler(Handle menu, MenuAction action, int param1, int param2) { }

public Action MenuRefresh_Timer(Handle timer)
{
	if (inReadyUp)
	{
		UpdatePanel();
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action MenuCmd_Timer(Handle timer)
{
	if (inReadyUp)
	{
		iCmd > 9 ? (iCmd = 1) : (iCmd += 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

void UpdatePanel()
{
	if (NativeVotes_IsVoteInProgress())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && NativeVotes_IsClientInVotePool(i)) hiddenPanel[i] = true;
		}
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !hiddenManually[i]) hiddenPanel[i] = false;
			}
		}		
	}

	if (menuPanel != INVALID_HANDLE)
	{
		CloseHandle(menuPanel);
		menuPanel = INVALID_HANDLE;
	}

	char survivorBuffer[800] = "";
	char infectedBuffer[800] = "";
	char casterBuffer[500] = "";
	char specBuffer[500] = "";
	int survivorCount = 0;
	int infectedCount = 0;
	int casterCount = 0;
	int playerCount = 0;
	int specCount = 0;

	menuPanel = CreatePanel();

	//Draw That Stuff
	char ServerBuffer[128];
	char ServerName[64];
	char cfgName[32];
	PrintCmd();
	
	float fTime = GetEngineTime();
	int iPassTime = RoundToFloor(fTime - g_fTime);

	// Support for Server_Namer.smx and Normal Hostname.
	if (bHostName) GetConVarString(FindConVar("sn_main_name"), ServerName, sizeof(ServerName));
	else GetConVarString(FindConVar("hostname"), ServerName, sizeof(ServerName));
	GetConVarString((l4d_ready_cfg_name), cfgName, sizeof(cfgName));
	Format(ServerBuffer, sizeof(ServerBuffer), "%s", ServerName);
	DrawPanelText(menuPanel, ServerBuffer);
	DrawPanelText(menuPanel, "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	Format(ServerBuffer, sizeof(ServerBuffer), "▸ Slots: %d/%d\n▸ Tickrate: 100\n▸ Config: %s", GetSeriousClientCount(), GetConVarInt(FindConVar("sv_maxplayers")), cfgName);
	DrawPanelText(menuPanel, ServerBuffer);
	FormatTime(ServerBuffer, sizeof(ServerBuffer), "▸ %d/%m/%Y - %I:%M%p");
	Format(ServerBuffer, sizeof(ServerBuffer), "%s (%s%d:%s%d)", ServerBuffer, (iPassTime / 60 < 10) ? "0" : "", iPassTime / 60, (iPassTime % 60 < 10) ? "0" : "", iPassTime % 60);
	DrawPanelText(menuPanel, ServerBuffer);
	Format(ServerBuffer, sizeof(ServerBuffer), "▸ Comandos: %s", (sCmd));
	DrawPanelText(menuPanel, ServerBuffer);
	DrawPanelText(menuPanel, "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");

	char nameBuf[MAX_NAME_LENGTH*2];
	char authBuffer[64];
	bool caster;
	int dummy;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			++playerCount;
			GetClientName(client, nameBuf, sizeof(nameBuf));
			GetClientAuthId(client, AuthId_Steam2, authBuffer, sizeof(authBuffer));
			caster = GetTrieValue(casterTrie, authBuffer, dummy);
			if (IsPlayer(client))
			{
				if (isPlayerReady[client])
				{
					GetClientTeam(client) == 2 ? survivorCount++ : infectedCount++;
					if (!inLiveCountdown) PrintHintText(client, "Presiona [F2] o escriba !nr para cancelar.");
					GetClientTeam(client) == 2 ? Format(nameBuf, sizeof(nameBuf), "->☑ %s\n", nameBuf) : Format(nameBuf, sizeof(nameBuf), "->☑ %s\n", nameBuf);
					GetClientTeam(client) == 2 ? StrCat(survivorBuffer, sizeof(survivorBuffer), nameBuf) : StrCat(infectedBuffer, sizeof(infectedBuffer), nameBuf);
				}	
				else		
				{
					GetClientTeam(client) == 2 ? survivorCount++ : infectedCount++;
					if (!inLiveCountdown) PrintHintText(client, "Preparate y presiona [F1] o escriba !r\npara comenzar la ronda");
					if ((fTime - g_fButtonTime[client]) > 15.0) GetClientTeam(client) == 2 ? Format(nameBuf, sizeof(nameBuf), "->☐ %s [AFK]\n", nameBuf) 
					: Format(nameBuf, sizeof(nameBuf), "->☐ %s [AFK]\n", nameBuf);

					else GetClientTeam(client) == 2 ? Format(nameBuf, sizeof(nameBuf), "->☐ %s\n", nameBuf) 
					: Format(nameBuf, sizeof(nameBuf), "->☐ %s\n", nameBuf);
					GetClientTeam(client) == 2 ? StrCat(survivorBuffer, sizeof(survivorBuffer), nameBuf) : StrCat(infectedBuffer, sizeof(infectedBuffer), nameBuf);
				}
			}
			else if (caster)
			{
				++casterCount;
				Format(nameBuf, sizeof(nameBuf), "%s\n", nameBuf);
				StrCat(casterBuffer, sizeof(casterBuffer), nameBuf);
			}
			else
			{
				++specCount;
				Format(nameBuf, sizeof(nameBuf), "%s\n", nameBuf);
				StrCat(specBuffer, sizeof(specBuffer), nameBuf);
			}
		}
	}

	int bufLen = strlen(survivorBuffer);
	if (bufLen != 0)
	{
		survivorBuffer[bufLen] = '\0';
		ReplaceString(survivorBuffer, sizeof(survivorBuffer), "#buy", "<- TROLL");
		ReplaceString(survivorBuffer, sizeof(survivorBuffer), "#", "_");
		DrawPanelText(menuPanel, "->1. Supervivientes");
		DrawPanelText(menuPanel, survivorBuffer);
	}

	bufLen = strlen(infectedBuffer);
	if (bufLen != 0)
	{
		infectedBuffer[bufLen] = '\0';
		ReplaceString(infectedBuffer, sizeof(infectedBuffer), "#buy", "<- TROLL");
		ReplaceString(infectedBuffer, sizeof(infectedBuffer), "#", "_");
		DrawPanelText(menuPanel, "->2. Infectados");
		DrawPanelText(menuPanel, infectedBuffer);
	}

	if (casterCount > 0 || specCount > 0) DrawPanelText(menuPanel, " ");

	bufLen = strlen(casterBuffer);
	if (bufLen != 0)
	{
		casterBuffer[bufLen] = '\0';
		ReplaceString(casterBuffer, sizeof(casterBuffer), "#buy", "<- TROLL");
		ReplaceString(casterBuffer, sizeof(casterBuffer), "#", "_");
		DrawPanelText(menuPanel, "->3. Casters");
		DrawPanelText(menuPanel, casterBuffer);
	}

	bufLen = strlen(specBuffer);
	if (bufLen != 0)
	{
		specBuffer[bufLen] = '\0';
		casterCount > 0 ? DrawPanelText(menuPanel, "->4. Espectadores") : DrawPanelText(menuPanel, "->3. Espectadores");
		ReplaceString(specBuffer, sizeof(specBuffer), "#buy", "<- TROLL");
		ReplaceString(specBuffer, sizeof(specBuffer), "#", "_");
		if (playerCount > GetConVarInt(l4d_ready_max_players))
			FormatEx(specBuffer, sizeof(specBuffer), "Uniendose al juego.. (%d)", specCount);
		DrawPanelText(menuPanel, specBuffer);
	}

	for (int i = 0; i < MAX_FOOTERS; i++)
	{
		DrawPanelText(menuPanel, readyFooter[i]);
	}

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && !hiddenPanel[client])
		{
			SendPanelToClient(menuPanel, client, DummyHandler, 1);
		}
	}
}

void InitiateReadyUp()
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		isPlayerReady[i] = false;
	}

	UpdatePanel();
	CreateTimer(1.0, MenuRefresh_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(4.0, MenuCmd_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	g_fTime = GetEngineTime();

	inReadyUp = true;
	inLiveCountdown = false;
	readyCountdownTimer = INVALID_HANDLE;

	if (GetConVarBool(l4d_ready_disable_spawns))
	{
		SetConVarBool(director_no_specials, true);
	}

	SetConVarFlags(sv_infinite_primary_ammo, GetConVarFlags(sv_infinite_primary_ammo) & ~FCVAR_NOTIFY);
	SetConVarBool(sv_infinite_primary_ammo, true);
	SetConVarFlags(sv_infinite_primary_ammo, GetConVarFlags(sv_infinite_primary_ammo) | FCVAR_NOTIFY);
	SetConVarFlags(god, GetConVarFlags(god) & ~FCVAR_NOTIFY);
	SetConVarBool(god, true);
	SetConVarFlags(sb_stop, GetConVarFlags(sb_stop) | FCVAR_NOTIFY);
	SetConVarBool(sb_stop, true);
	L4D2_CTimerStart(L4D2CT_VersusStartTimer, 99999.9);
	return;
}

void PrintCmd()
{
	switch (iCmd)
	{
		case 1: Format(sCmd, sizeof(sCmd), "->1. !r / !nr");
		case 2: Format(sCmd, sizeof(sCmd), "->2. !pause");
		case 3: Format(sCmd, sizeof(sCmd), "->3. !boss");
		case 4: Format(sCmd, sizeof(sCmd), "->4. !tank / !witch");
		case 5: Format(sCmd, sizeof(sCmd), "->5. !current");
		case 6: Format(sCmd, sizeof(sCmd), "->6. !votekick");
		case 7: Format(sCmd, sizeof(sCmd), "->7. !lerps");
		case 8: Format(sCmd, sizeof(sCmd), "->8. !match / !rmatch");
		case 9: Format(sCmd, sizeof(sCmd), "->9. !nice");
	}
}

void InitiateLive(bool real = true)
{
	inReadyUp = false;
	inLiveCountdown = false;

	SetTeamFrozen(L4D2Team_Survivor, false);

	SetConVarFlags(sv_infinite_primary_ammo, GetConVarFlags(sv_infinite_primary_ammo) & ~FCVAR_NOTIFY);
	SetConVarBool(sv_infinite_primary_ammo, false);
	SetConVarFlags(sv_infinite_primary_ammo, GetConVarFlags(sv_infinite_primary_ammo) | FCVAR_NOTIFY);
	SetConVarBool(director_no_specials, false);
	SetConVarFlags(god, GetConVarFlags(god) & ~FCVAR_NOTIFY);
	SetConVarBool(god, false);
	SetConVarFlags(sb_stop, GetConVarFlags(sb_stop) | FCVAR_NOTIFY);
	SetConVarBool(sb_stop, false);

	L4D2_CTimerStart(L4D2CT_VersusStartTimer, 60.0);

	for (int i = 0; i < 4; i++)
	{
		GameRules_SetProp("m_iVersusDistancePerSurvivor", 0, _,
				i + 4 * GameRules_GetProp("m_bAreTeamsFlipped"));
	}

	for (int i = 0; i < MAX_FOOTERS; i++)
	{
		readyFooter[i] = "";
	}

	footerCounter = 0;
	if (real)
	{
		Call_StartForward(liveForward);
		Call_Finish();
	}
}

public void OnBossVote()
{
	readyFooter[1] = "";
	footerCounter = 1;
}

void ReturnPlayerToSaferoom(int client, bool flagsSet = true)
{
	int warp_flags;
	int give_flags;
	if (!flagsSet)
	{
		warp_flags = GetCommandFlags("warp_to_start_area");
		SetCommandFlags("warp_to_start_area", warp_flags & ~FCVAR_CHEAT);
		give_flags = GetCommandFlags("give");
		SetCommandFlags("give", give_flags & ~FCVAR_CHEAT);
	}

	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
	{
		FakeClientCommand(client, "give health");
	}

	FakeClientCommand(client, "warp_to_start_area");

	if (!flagsSet)
	{
		SetCommandFlags("warp_to_start_area", warp_flags);
		SetCommandFlags("give", give_flags);
	}

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);//, NULL_VELOCITY);
}

void ReturnTeamToSaferoom(L4D2Team team)
{
	int warp_flags = GetCommandFlags("warp_to_start_area");
	SetCommandFlags("warp_to_start_area", warp_flags & ~FCVAR_CHEAT);
	int give_flags = GetCommandFlags("give");
	SetCommandFlags("give", give_flags & ~FCVAR_CHEAT);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && view_as<L4D2Team> (GetClientTeam(client)) == team)
		{
			ReturnPlayerToSaferoom(client, true);
		}
	}

	SetCommandFlags("warp_to_start_area", warp_flags);
	SetCommandFlags("give", give_flags);
}

void SetTeamFrozen(L4D2Team team, bool freezeStatus)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && view_as<L4D2Team> (GetClientTeam(client)) == team)
		{
			SetClientFrozen(client, freezeStatus);
		}
	}
}

bool CheckFullReady()
{
	int readyCount = 0;
	int casterCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if (IsClientCaster(client))
			{
				casterCount++;
			}

			if (IsPlayer(client))
			{
				if (isPlayerReady[client]) readyCount++;
			}
		}
	}
	// Non-Versus Mode!
	//if we're running a versus game,
	char GameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, 32);
	if (StrContains(GameMode, "coop", false) != -1 || StrContains(GameMode, "survival", false) != -1 || StrEqual(GameMode, "realism", false))
	{
		return readyCount >= GetRealClientCount();
	}
	// Players vs Players
	return readyCount >= (GetRealClientCount() + GetSIClientCount()); // + casterCount
}

void InitiateLiveCountdown()
{
	if (readyCountdownTimer == INVALID_HANDLE)
	{
		ReturnTeamToSaferoom(L4D2Team_Survivor);
		SetTeamFrozen(L4D2Team_Survivor, true);
		PrintHintTextToAll("XtremeMod");
		inLiveCountdown = true;
		readyDelay = GetConVarInt(l4d_ready_delay);
		readyCountdownTimer = CreateTimer(1.0, ReadyCountdownDelay_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action ReadyCountdownDelay_Timer(Handle timer)
{
	if (readyDelay == 0)
	{
		PrintHintTextToAll("Comienza la ronda!");
		InitiateLive();
		readyCountdownTimer = INVALID_HANDLE;
		if (GetConVarBool(l4d_ready_enable_sound))
		{
			if (GetConVarBool(l4d_ready_chuckle))
			{
				Command_Play(countdownSound[GetRandomInt(0,MAX_SOUNDS-1)]);
				//EmitSoundToAll(countdownSound[GetRandomInt(0,MAX_SOUNDS-1)]);
			}
			else
			{ 
				Command_Play(liveSound);
				//EmitSoundToAll(liveSound, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
			}
		}
		return Plugin_Stop;
	}
	else
	{
		PrintHintTextToAll("Iniciando en: %d SEG(s)...\nPresiona [F2] o escriba !nr para cancelar", readyDelay);
		if (GetConVarBool(l4d_ready_enable_sound))
		{
			Command_Play("buttons\\blip1.wav");
			//EmitSoundToAll("weapons\\hegrenade\\beep.wav", _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
		}
		readyDelay--;
	}
	return Plugin_Continue;
}

void CancelFullReady()
{
	if (readyCountdownTimer != INVALID_HANDLE)
	{
		SetTeamFrozen(L4D2Team_Survivor, GetConVarBool(l4d_ready_survivor_freeze));
		inLiveCountdown = false;
		CloseHandle(readyCountdownTimer);
		readyCountdownTimer = INVALID_HANDLE;
		PrintHintTextToAll("Cuenta regresiva cancelada!");
	}
}

int GetRealClientCount() 
{
	int clients = 0;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i))
		{ 
			if (!IsClientInGame(i)) clients++;
			else if (!IsFakeClient(i) && GetClientTeam(i) == L4D2Team_Survivor) clients++;
		}
	}
	return clients;
}


int GetSeriousClientCount()
{
	int clients = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			clients++;
		}
	}
	return clients;
}



int GetSIClientCount()
{
	int clients = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == L4D2Team_Infected)
		{
			//if (IsPlayerAlive(i))
			//{
			if (!IsFakeClient(i))
				clients++;
			//}
		}
	}
	return clients;
}



stock void SetClientFrozen(int client, int freeze)
{
	SetEntityMoveType(client, freeze ? MOVETYPE_NONE : MOVETYPE_WALK);
}

stock bool IsPlayerAfk(int client, float fTime)
{
	return __FLOAT_GT__(floatSub(fTime, g_fButtonTime[client]), 15.0);
}

stock bool IsPlayer(int client)
{
	L4D2Team team = view_as<L4D2Team>(GetClientTeam(client));
	return (team == L4D2Team_Survivor || team == L4D2Team_Infected);
}




public Action Command_Play(const char[] arguments)
{

	for(int i=1; i<=MaxClients; i++)
	{
		if( !IsClientInGame(i) )
		continue;
     	  	ClientCommand(i, "playgamesound %s", arguments);
		//PrintToChatAll("*************************2*****************************");

	}  
	//return Plugin_Handled;
}