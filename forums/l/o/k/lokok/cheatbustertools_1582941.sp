#if 1 //################################## Headers ############################################//
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <sdkhooks>
#define REQUIRE_PLUGIN
#include <smlib>

#define PLUGIN_VERSION "1.2.1"
#define DEBUG 0

public Plugin:myinfo = {
	name = "Cheater Buster Tools",
	author = "KawMAN",
	description = "Tools that helps admins to detect cheaters",
	version = PLUGIN_VERSION,
	url = "http://www.wsciekle.pl/"
};

#endif //--------------------------------- Headers End ----------------------------------------//

#if 1 //################################## Globals ############################################//

const MaxTeams							= MAX_TEAMS;
const MaxCvarLn							= 128;
new Handle:gCvar_Version				= INVALID_HANDLE;

//Client Info
new Clspritent[MAXPLAYERS+1]			= { -1, ... };
new bool:ClESPOn[MAXPLAYERS+1]			= {false, ... };
new bool:ClCanSeeSpr[MAXPLAYERS+1]		= {false, ... };
new ClObserv[MAXPLAYERS+1]				= {0, ...};
new bool:ClCheatOn[MAXPLAYERS+1] 		= { false, ... };

//Config
new String:g_TeamSpr[MaxTeams+1][MaxCvarLn];
new bool:SDKHooksExist					= false;
new bool:ESPShouldOn					= false;
new bool:ESPTurnedOn					= false;
new bool:MidRound						= true;
new Handle:hLookupAttachment			= INVALID_HANDLE;
new bool:AdminCheatsOn					= false;

//Cvars
new Handle:hCvar_AdminESPSprDownload	= INVALID_HANDLE;
new bool:gCvar_AdminESPSprDownload		= false;
new Handle:hCvar_AdminCheatConfig		= INVALID_HANDLE;
new bool:gCvar_AdminCheatConfig			= true;
new Handle:hCvar_SvCheats				= INVALID_HANDLE;
new bool:gCvar_SvCheats					= false;
new Handle:hCvar_AdminESPOnByDefault	= INVALID_HANDLE;
new bool:gCvar_AdminESPOnByDefault		= false;


#endif //--------------------------------- Headers End ----------------------------------------//

#if 1 //################################## SourceMOD Fwd ############################################//
public OnPluginStart()
{

	MarkNativeAsOptional("SDKHook");
	MarkNativeAsOptional("SDKUnhook");
	if(GetExtensionFileStatus("sdkhooks.ext") == 1)	SDKHooksExist = true;
	else											SDKHooksExist = false;
	
	//Load Languages
	LoadTranslations("common.phrases");
	
	//Register Cvars
	hCvar_AdminESPSprDownload = CreateConVar("sm_adminesp_addtodt", "1", "If 1 Sprites will be added to download table", FCVAR_PLUGIN,true,0.0,true,1.0);
	hCvar_AdminCheatConfig = CreateConVar("sm_admincheat_config", "1", "If 1 configs will be executed when someone is using sv_cheats replication", FCVAR_PLUGIN,true,0.0,true,1.0);
	hCvar_AdminESPOnByDefault = CreateConVar("sm_adminesp_onbydefault", "1", "If 1 admins will have sm_adminesp enabled by default", FCVAR_PLUGIN,true,0.0,true,1.0);
	
	hCvar_SvCheats = FindConVar("sv_cheats");
	
	//HookCvars
	HookConVarChange(hCvar_AdminCheatConfig, MyCvarChange);
	HookConVarChange(hCvar_SvCheats, MyCvarChange);
	HookConVarChange(hCvar_AdminESPSprDownload, MyCvarChange);
	HookConVarChange(hCvar_AdminESPOnByDefault, MyCvarChange);
	
	//Prep SDKCalls
	new Handle:hGameConf = LoadGameConfigFile("cheatbuster.gamedata");
 	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "LookupAttachment");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	hLookupAttachment = EndPrepSDKCall();
	
	//Hook Events
	HookEvent("player_spawn", Ev_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Ev_PlayerDeath);
	HookEvent("player_team",Ev_PlayerTeam);
	HookEvent("round_start", Ev_RoundStart);
	HookEvent("round_end", Ev_RoundEnd);
		
	//Register Commands
	if(SDKHooksExist) 
	{
		RegAdminCmd("sm_adminesp", Cmd_AdminESP, ADMFLAG_ROOT, "Admin ESP Set Command");
		RegAdminCmd("sm_adminesp_teamspr", Cmd_AddSpr, ADMFLAG_ROOT, "Define spirit to team");
	}
	else
	{
		RegAdminCmd("sm_adminesp", Cmd_NonSDK, ADMFLAG_ROOT, "Admin ESP Set Command");
		RegAdminCmd("sm_adminesp_teamspr", Cmd_NonSDK, ADMFLAG_ROOT, "Define spirit to team");
	}
	RegAdminCmd("sm_cb_table", Cmd_CBTable, ADMFLAG_ROOT, "Print Transmition Table"); 
	RegAdminCmd("sm_admincheats", Cmd_AdminCheat, ADMFLAG_ROOT, "Admin sv_cheat replication set command");
	
	AutoExecConfig(true, "cheatbustertools");
	gCvar_Version = CreateConVar("sm_adminesp_v", PLUGIN_VERSION, "Admin ESP Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RefreshSetting();
	UpdateState();
	
}

public OnPluginEnd()
{
	ESPTurnOff();
}

public OnMapStart()
{
	RefreshSetting();
	CreateTimer(5.0, DelayedVersionRefresh);
}

public OnClientPutInServer(client)
{
	ClESPOn[client] 	= false;
	ClCanSeeSpr[client]	= false;
	ClCheatOn[client]	= false;
}

public OnClientPostAdminCheck(client)
{
	if ((gCvar_AdminESPOnByDefault) && (GetUserAdmin(client) != INVALID_ADMIN_ID)) {
		ClESPOn[client] 	= true;
		ClCanSeeSpr[client]	= true;
		ClCheatOn[client]	= true;
	}
}

public OnClientDisconnect(client) {
	ClESPOn[client] 	= false;
	ClCanSeeSpr[client]	= false;
	ClCheatOn[client]	= false;
	
	CreateTimer(0.2, TCUpdateState, client);
}

#endif //--------------------------------- SourceMOD Fwd End ----------------------------------------//

#if 1 //################################## Events ############################################//

public Action:Ev_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RefreshClientTran(client);
	if(ESPShouldOn && ESPTurnedOn)
	{
		CreateTimer(1.0, TCCreateESPSpr, client);
	}
	RefreshClientCheats(client);
}
public Action:Ev_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	MidRound = false;
}
public Action:Ev_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	MidRound = true;
	DestroyAllSpr();
	UpdateState();
}

public Action:Ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, TCUpdateObserver, client);
	RefreshClientTran(client);
	DestroyESPSpr(Clspritent[client]);
	Clspritent[client]=-1;
	CreateTimer(0.1, TSObserTarDead, client);
	
	RefreshClientCheats(client);
}

public Action:Ev_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetEventBool(event,"disconnect")) return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new newteam = GetEventInt(event,"team");
	new Spr = Clspritent[client];
	if(newteam <= 1)
	{	//Switched to spec, must remove sprite
		if(IsValidEntity(Spr)) DestroyESPSpr(Spr);
		Clspritent[client] = 0;
	}
	else
	{
		if(Spr <= 0 || !IsValidEntity(Spr)) return Plugin_Continue;
				
		decl String:SprModel[MaxCvarLn];
		Entity_GetModel(Spr, SprModel, sizeof(SprModel));
		if(!StrEqual(SprModel, g_TeamSpr[newteam], false) && g_TeamSpr[newteam][0]!='\0')
		{
			Entity_SetModel(Spr, g_TeamSpr[newteam]);
		}
	}
	return Plugin_Continue;
}

#endif //--------------------------------- Events End ----------------------------------------//

#if 1 //################################## Settings, Precahce Controlers ############################################//

public Action:TCUpdateState(Handle:timer, any:client)
{
	UpdateState();
}

//Commands
public Action:Cmd_AdminESP(client, args)
{
	if (args > 2)
	{
		ReplyToCommand(client, "[AdminESP] Usage: sm_adminesp [0-off,1-on] [#userid|name|team|all]");
		return Plugin_Handled;
	}
	if (args == 0)
	{
		if(!client) {
			ReplyToCommand(client, "[AdminESP] Syntax for console sm_adminesp <1|0> <target>");
			return Plugin_Handled;
		}
		//self toggle
		if(ClESPOn[client]) {
			ClESPOn[client] = false;
		}else {
			ClESPOn[client]=true;
		}
	}
	else if (args == 1)
	{
		if(!client) {
			ReplyToCommand(client, "[AdminESP] Syntax for console sm_adminesp <1|0> <target>");
			return Plugin_Handled;
		}
		//self set
		decl String:arg[65];
		GetCmdArg(1, arg, sizeof(arg));
		new mystate = StringToInt(arg);
		if(mystate) 
		{
			ClESPOn[client] = true; 
		}
		else 
		{
			ClESPOn[client]=false;
		}
	}
	else 
	{
		decl String:arg[65];
		GetCmdArg(2, arg, sizeof(arg));

		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
		if ((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		GetCmdArg(1, arg, sizeof(arg));
		new mystate = StringToInt(arg);
		
		for (new i = 0; i < target_count; i++)
		{
			if(mystate) 
			{
				ClESPOn[target_list[i]] = true;
			}
			else 
			{
				ClESPOn[target_list[i]]= false;
			}
		}
	}
	
	UpdateState();
	
	return Plugin_Handled;
}

public Action:Cmd_AdminCheat(client, args)
{
	if(!client && args <= 1) 
	{
		ReplyToCommand(client, "[AdminESP] In-Game Only");
		return Plugin_Handled;
	}
	if (args > 2)
	{
		ReplyToCommand(client, "[AdminESP] Usage: sm_admincheat [0-off,1-on] [#userid|name|team|all]");
		return Plugin_Handled;	
	}
	if (args == 0)
	{
		//self toggle
		if(ClCheatOn[client]) {
			//PrintToChat(client, "[AdminESP] Cheats for Admins DISABLED");
			ClCheatOn[client] = false;
		}else {
			//PrintToChat(client, "[AdminESP] Cheats for Admins ENABLED");
			ClCheatOn[client]=true;
		}
	}
	else if (args == 1)
	{
		//self set
		decl String:arg[65];
		GetCmdArg(1, arg, sizeof(arg));
		new mystate = StringToInt(arg);
		if(mystate) 
		{
			//PrintToChat(client, "[AdminESP] Cheats for Admins ENABLED");
			ClCheatOn[client] = true; 
		}
		else 
		{
			//PrintToChat(client, "[AdminESP] Cheats for Admins DISABLED");
			ClCheatOn[client]=false;
		}
	}
	else 
	{
		decl String:arg[65], tmp;
		GetCmdArg(2, arg, sizeof(arg));

		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
		if ((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		GetCmdArg(1, arg, sizeof(arg));
		new mystate = StringToInt(arg);
		
		for (new i = 0; i < target_count; i++)
		{
			tmp = target_list[i];
			if(tmp <= 0) continue;
			if(mystate) 
			{
				ClCheatOn[target_list[i]] = true;
			}
			else 
			{
				ClCheatOn[target_list[i]]= false;
			}
		}
	}
	
	UpdateState();
	
	return Plugin_Handled;
}

public Action:Cmd_CBTable(client, args) 
{
	decl String:tmp[MaxCvarLn];
	ReplyToCommand(client, "SDKHooksExist: %d; ESPShouldOn:%d; ClientsUsingCheats:%d", SDKHooksExist, ESPShouldOn, ClientsUsingCheats());
	ReplyToCommand(client, "####### Team sprites ########");
	for(new i=0; i<=MaxTeams; i++)
	{
		if(g_TeamSpr[i][0]=='\0') continue;
		Team_GetName(i, tmp, sizeof(tmp));
		ReplyToCommand(client, "%d-%s Sprite:%s ", i, tmp,g_TeamSpr[i]);
	}
	ReplyToCommand(client, "######## Settings ########");
	for(new i=0;i<=MaxClients;i++)
	{
		tmp = "No-Conn";
		if(i!=0&&IsClientInGame(i)) GetClientName(i, tmp, sizeof(tmp));
		ReplyToCommand(client, "C:%d(%s)\tClCheatOn:%d ClESPOn:%d ClCanSeeSpr:%d ClObserv:%d Clspritent:%d",
		i, tmp, ClCheatOn[i],ClESPOn[i], ClCanSeeSpr[i], ClObserv[i], Clspritent[i]
		);
	}
	
}
public Action:Cmd_AddSpr(client, args) 
{
	if (args < 2 ) // Print Help
	{
		ReplyToCommand(client, "%s", "syntax: sm_adminesp_addteamspr <team index|team name> <path_to_sprite>");
		return Plugin_Handled;
	}
	
	decl String:arg[MaxCvarLn], Team;
	GetCmdArg(1, arg, sizeof(arg));
	if(String_IsNumeric(arg))
	{
		Team = StringToInt(arg);
	} 
	else if((Team = FindTeamByName(arg)) < 0)
	{ 
		ReplyToCommand(client, "%s", "syntax: sm_adminesp_addteamspr <team index|team name> <path_to_sprite>");
		return Plugin_Handled;
	}
	
	GetCmdArg(2, g_TeamSpr[Team], sizeof(g_TeamSpr[]));
	
	Team_GetName(Team, arg, sizeof(arg));
	ReplyToCommand(client, "sprite %s for team %d-%s added", g_TeamSpr[Team], Team, arg);
	//PrecacheModel(g_TeamSpr[Team]);
	PrecacheDecal(g_TeamSpr[Team], true);
	if(gCvar_AdminESPSprDownload) 
	{
		
		Format(arg, sizeof(arg), "%s%s", "materials/", g_TeamSpr[Team]);
		AddFileToDownloadsTable(arg);
		ReplaceString(arg, sizeof(arg), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(arg);
		PrintToServer("added to dt: %s", arg);
	}
	return Plugin_Handled;
}

public Action:Cmd_NonSDK(client, args)
{
	ReplyToCommand(client, "[AdminESP] Server don't have SDKHooks, Command not avilable");
	return Plugin_Handled;
}

RefreshSetting(Handle:CvarHand=INVALID_HANDLE) //---- Settings refresh, INVALID_HANDLE == refresh all
{
	decl bool:boolval;
	if(CvarHand == INVALID_HANDLE || CvarHand == hCvar_AdminCheatConfig) 
	{
		boolval = GetConVarBool(hCvar_AdminCheatConfig);
		if(boolval!=gCvar_AdminCheatConfig)
		{
			if(boolval)
			{
				gCvar_AdminCheatConfig = true;
			} 
			else
			{
				gCvar_AdminCheatConfig = false;
			}
		}
		if(CvarHand != INVALID_HANDLE) return;
	}
	if(CvarHand == INVALID_HANDLE || CvarHand == hCvar_SvCheats) 
	{
		boolval = GetConVarBool(hCvar_SvCheats);
		if(boolval!=gCvar_SvCheats)
		{
			if(boolval)
			{
				gCvar_SvCheats = true;
			} 
			else
			{
				gCvar_SvCheats = false;
			}
		}
		if(CvarHand != INVALID_HANDLE) return;
	}
	if(CvarHand == INVALID_HANDLE || CvarHand == hCvar_AdminESPSprDownload) 
	{
		boolval = GetConVarBool(hCvar_AdminESPSprDownload);
		if(boolval!=gCvar_AdminESPSprDownload)
		{
			if(boolval)
			{
				gCvar_AdminESPSprDownload = true;
			} 
			else
			{
				gCvar_AdminESPSprDownload = false;
			}
		}
		if(CvarHand != INVALID_HANDLE) return;
	}
	if(CvarHand == INVALID_HANDLE || CvarHand == hCvar_AdminESPOnByDefault) 
	{
		boolval = GetConVarBool(hCvar_AdminESPOnByDefault);
		if(boolval!=gCvar_AdminESPOnByDefault)
		{
			if(boolval)
			{
				gCvar_AdminESPOnByDefault = true;
			} 
			else
			{
				gCvar_AdminESPOnByDefault = false;
			}
		}
		if(CvarHand != INVALID_HANDLE) return;
	}
	
	PrecacheSpr();
}

public MyCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]) //----------- On plugins cvar change
{
	if(strcmp(oldValue, newValue)==0) return; //No change
	RefreshSetting(convar);
	
}

PrecacheSpr()
{
	for(new i = 0; i<=MaxTeams; i++)
	{
		if(g_TeamSpr[i][0]!='\0') PrecacheDecal(g_TeamSpr[i]);
	}
}

#if DEBUG >= 1
public Action:Cmd_SprTele(client, args)
{
	
	if( client<=0 || !IsClientInGame(client) || IsPlayerAlive(client) ) return Plugin_Handled;
	new ob = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	if ( Clspritent[ob] <= 0 ) return Plugin_Handled;
	decl Float:vec[3];
	Entity_GetAbsOrigin(Clspritent[ob], vec);
	ReplyToCommand(client, "C: %d Spr: %d SprPos: %f %f %f", ob, Clspritent[ob], vec[0], vec[1], vec[2]);
	TeleportEntity(client, vec, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}
#endif

#endif //--------------------------------- Settings Controlers End----------------------------------------//

#if 1 //################################## sv_cheats replication #################################//

RepCheatsOn()
{
	AdminCheatsOn = true;
	//Set up sv_cheats Rep 1 for all authed dead clients
	ServerCommand("exec sourcemod/admincheats_on.cfg");
	RefreshCheats();
}
RepCheatsOff()
{
	AdminCheatsOn = false;
	ServerCommand("exec sourcemod/admincheats_off.cfg");
	RefreshCheats();
}

RefreshCheats()
{
	for(new client=1;client<=MaxClients;client++)
	{
		RefreshClientCheats(client);
	}
}

RefreshClientCheats(client)
{
	if(!IsClientInGame(client)||IsFakeClient(client)) {
		ClCheatOn[client] = false;
		return;
	}
	if(ClCheatOn[client])
	{
		if(ValidObserver(client))
		{
			SendConVarValue(client, hCvar_SvCheats, "1");
		}
		else
		{
			SendConVarValue(client, hCvar_SvCheats, "0");
		}
	}
	else
	{
		if(!gCvar_SvCheats) SendConVarValue(client, hCvar_SvCheats, "0");
	}
}

bool:ClientsUsingCheats()
{
	if(gCvar_SvCheats) 
	{
		return false;
	}
	for(new i=1;i<=MaxClients;i++)
	{
		if(ClCheatOn[i])
		{
			return true;
		}
	}
	return false;
}

#endif //--------------------------------- sv_cheats replication end------------------------------//

#if 1 //################################## ESP sprites Control, ESPTrunOn/Off ####################//

ESPTurnOn()
{
	ESPTurnedOn = true;
	if(MidRound)
	{
			for(new i=1;i<=MaxClients;i++)
			{
				CreateESPSpr(i);
			}
	}
}
ESPTurnOff()
{
	ESPTurnedOn = false;
	for(new i=1;i<=MaxClients;i++)
	{
		SDKUnhook(Clspritent[i], SDKHook_SetTransmit, Hook_SetTransmit);
		DestroyESPSpr(Clspritent[i]);
		Clspritent[i] = -1;
		ClESPOn[i] = false;
		ClCanSeeSpr[i] = false;
	}
	

}

public Action:TCCreateESPSpr(Handle:timer, any:client)
{
	CreateESPSpr(client);
}

CreateESPSpr(client)
{
	decl String:model[64];
	if(!ValidPlayer(client)) return -1;
	new clientteam = GetClientTeam(client);
	
	if(g_TeamSpr[clientteam][0]=='\0')
	{
		return -1;
	}
	strcopy(model, sizeof(model), g_TeamSpr[clientteam]);
	
	if(Clspritent[client]!=-1)	//ESP Spirit exist, should't so must be destroyed.
	{
		DestroyESPSpr(Clspritent[client]);
		Clspritent[client]=-1;
	}

	decl ClientESPSpr;
	ClientESPSpr = CreateEntityByName("env_sprite"); 
	
	if(ClientESPSpr==-1) 
	{
		LogError("[AdminESP] Can't create sprite for %d", client);
		PrintToServer("[AdminESP] Can't create sprite for %d", client);
		return -1;
	}
	
	new AttachExist = ClientLookupAttachment(client, "forward");
	
	DispatchKeyValue(ClientESPSpr, "model", model); 
	DispatchKeyValue(ClientESPSpr, "rendermode", "0"); 
	DispatchKeyValue(ClientESPSpr, "renderfx", "0"); 
	DispatchKeyValue(ClientESPSpr, "renderamt", "255"); 
	DispatchKeyValue(ClientESPSpr, "scale", "0.5"); 
	DispatchKeyValue(ClientESPSpr, "GlowProxySize", "61.0");
	DispatchKeyValue(ClientESPSpr, "OnUser1", "!self,SetParent,!activator,0,-1");
	if(AttachExist) 
	{
		DispatchKeyValue(ClientESPSpr, "OnUser1", "!self,SetParentAttachment,forward,0.02,-1");
		DispatchKeyValue(ClientESPSpr, "OnUser1", "!self,FireUser2,,0.04,-1");
	}
	else
	{
		DispatchKeyValue(ClientESPSpr, "OnUser1", "!self,FireUser3,,0.02,-1");
	}
	
	DispatchSpawn(ClientESPSpr);
	if(AttachExist) 
	{
		HookSingleEntityOutput(ClientESPSpr, "OnUser2", ESPSprOnUser2); 
	}
	else
	{
		HookSingleEntityOutput(ClientESPSpr, "OnUser3", ESPSprOnUser3); 
	}
	
	SetVariantString("");
	AcceptEntityInput(ClientESPSpr, "FireUser1", client);
	
	if(!SDKHookEx(ClientESPSpr, SDKHook_SetTransmit, Hook_SetTransmit))
	{
		LogError("[AdminESP] Can't hook ESP sprite %d for %d", ClientESPSpr, client);
		PrintToServer("[AdminESP] Can't hook ESP sprite %d for %d", ClientESPSpr, client);
		DestroyESPSpr(ClientESPSpr);
		return -1;
	}
	
	Clspritent[client] = ClientESPSpr;
	//SetEntityRenderMode(ClientESPSpr, RENDER_TRANSCOLOR); 
	return ClientESPSpr;
}

public ESPSprOnUser2(const String:output[], caller, activator, Float:delay)
{
	new Float:vecOrigin[3] = {0.0, ...};
	vecOrigin[2] -= 5.0; 
	if(IsValidEntity(caller)) TeleportEntity(caller, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
}

public ESPSprOnUser3(const String:output[], caller, activator, Float:delay)
{
	new Float:vecOrigin[3] = {0.0, ...};
	vecOrigin[2] += 30.0; //around chest
	if(IsValidEntity(caller)) TeleportEntity(caller, vecOrigin, NULL_VECTOR, NULL_VECTOR);
}

DestroyESPSpr(ent)
{
	if(ent > MaxClients && IsValidEntity(ent))
	{
		SDKUnhook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
		//RemoveEdict(ent);
		AcceptEntityInput(ent, "Kill");
	}
}

DestroyAllSpr()
{
	decl ent;
	#if DEBUG >= 1
	decl String:cname[48];
	#endif
	for(new i = 0; i<=MaxClients; i++)
	{
		ent = Clspritent[i];
		if(ent!=0)
		{
			if(IsValidEntity(ent)) 
			{
				#if DEBUG >= 1
				cname = "";
				if(IsClientInGame(i)) GetClientName(i, cname, sizeof(cname));
				PrintToServer("[ADMINESP] Sprite %d for client %d(%s) exist", ent, i, cname);
				#endif
				DestroyESPSpr(ent);
			}
			Clspritent[i] = 0;
		}
	}
}

public Action:Hook_SetTransmit(entity, client) 
{
	if(ClCanSeeSpr[client] && (entity != Clspritent[ClObserv[client]]) )
	{
		return Plugin_Continue;
	}
	return Plugin_Handled; 
}

RefreshTransmit()
{
	for(new client=1;client<=MaxClients;client++)
	{
		RefreshClientTran(client);
	}
}

RefreshClientTran(client)
{
	if(!IsClientInGame(client)) {
		ClESPOn[client] = false;
		return;
	}
	if(ClESPOn[client])
	{
		if(ValidObserver(client))
		{
			ClCanSeeSpr[client] = true;
		}
		else
		{
			ClCanSeeSpr[client] = false;
		}
	}
	else
	{
		ClCanSeeSpr[client] = false;
	}
}

bool:ClientsUsingESP()
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ClESPOn[i])
		{
			ESPShouldOn = true;
			return true;
		}
	}
	ESPShouldOn = false;
	return false;
}

#endif //--------------------------------- sprites Creators, Destructors, TrunOm/Off End-----------------//

#if 1 //################################## Observer State ############################################//

HookSpecCmd()
{
	AddCommandListener(Cmd_spec_refresh, "spec_prev");
	AddCommandListener(Cmd_spec_refresh, "spec_next");
	AddCommandListener(Cmd_spec_refresh, "spec_player");
	AddCommandListener(Cmd_spec_refresh, "spec_mode");
}
UnHookSpecCmd()
{
	RemoveCommandListener(Cmd_spec_refresh, "spec_prev");
	RemoveCommandListener(Cmd_spec_refresh, "spec_next");
	RemoveCommandListener(Cmd_spec_refresh, "spec_player");
	RemoveCommandListener(Cmd_spec_refresh, "spec_mode");
}

public Action:Cmd_spec_refresh(client, const String:command[], argc)
{
	if(client == 0 || IsPlayerAlive(client)) return Plugin_Continue;
	
	CreateTimer(0.05, TCUpdateObserver, client);
	
	return Plugin_Continue;
}

public Action:TCUpdateObserver(Handle:timer, any:client)
{
	if(!IsClientInGame(client)) 
	{
		ClObserv[client] = 0;
	}
	else
	{
		decl ob, mode;
		ob = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		mode = GetEntProp(client, Prop_Send, "m_iObserverMode"); // mode 6 - free look
		if(ob < 0 || ob > MaxClients || mode == 6) ob = 0;
		ClObserv[client] = ob;
	}
}

public Action:TSObserTarDead(Handle:timer, any:client)
{
	decl Observing;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && (!IsPlayerAlive(i)) ) 
		{
			Observing = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			if(Observing == client)
			{
				CreateTimer(3.00, TCUpdateObserver, i);
			}
		}
	}
}

#endif //--------------------------------- Observer Setup End-----------------------------------------//

#if 1 //################################## Helpers ############################################//

ClientLookupAttachment(client, String:point[])
{
	if(hLookupAttachment==INVALID_HANDLE) return 1; //Can't check so must assume he have it
	if( client<=0 || !IsClientInGame(client) ) return 0;
	return SDKCall(hLookupAttachment, client, point);
}

UpdateState()
{
	//ESP
	if(ClientsUsingESP())
	{
		if(MidRound && !ESPTurnedOn)
		{
			HookSpecCmd();
			ESPTurnOn();
		}
	}
	else
	{
		if(ESPTurnedOn) 
		{
			UnHookSpecCmd();
			ESPTurnOff();
		}
	}
	// Cheats Replication
	if(ClientsUsingCheats())
	{
		if(!AdminCheatsOn) 
		{
			RepCheatsOn();
		}
	}
	else
	{
		if(AdminCheatsOn) 
		{
			RepCheatsOff();
		}
	}
	RefreshTransmit();
	RefreshCheats();
}

ValidPlayer(client)
{
	if(!IsClientInGame(client)) return false;
	if(!IsPlayerAlive(client)) return false;
	return true;
}

ValidObserver(client)
{
	if(!IsClientInGame(client)) return false;
	if(IsPlayerAlive(client)) return false;
	return true;
}

public Action:DelayedVersionRefresh(Handle:timer, any:client)
{
	SetConVarString(gCvar_Version, PLUGIN_VERSION, false, false);
}

#endif //--------------------------------- Helpers End----------------------------------------//