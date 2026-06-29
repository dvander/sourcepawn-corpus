#if 1 //####################################################### Headers #####################################################//
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#define DEBUG 0

public Plugin:myinfo = {
	name = "SM Forcecamera",
	author = "KawMAN",
	description = "Turn on mp_forcecamera 1 for non admins only",
	version = PLUGIN_VERSION,
	url = "http://wsciekle.pl/"
};
#endif //---------------------------------------------------- Headers End ---------------------------------------------------//

#if 1 //####################################################### GLOBALS #####################################################//

#define MAXADMGROUPS 8

new bool:AllowViewOpp[MAXPLAYERS+1]	= {false, ...};

new bool:g_sm_forcecam				= false;
new Handle:gCvar_sm_forcecam		= INVALID_HANDLE;
new String:g_sm_forcecam_flag[2]	= "";
new Handle:gCvar_sm_forcecam_flag	= INVALID_HANDLE;
new String:g_sm_forcecam_groups[MAXADMGROUPS+1][32];
new Handle:gCvar_sm_forcecam_groups	= INVALID_HANDLE;
new Handle:gCvar_mp_forcecamera		= INVALID_HANDLE;
new Handle:gCvar_sm_forcecam_ver		= INVALID_HANDLE;


#endif //---------------------------------------------------- GLOBALS END ---------------------------------------------------//

#if 1 //####################################################### SM Fwd #####################################################//
public OnPluginStart()
{
	//Load Languages
	LoadTranslations("common.phrases");
	
	gCvar_sm_forcecam = CreateConVar("sm_forcecamera", "1", "Enable SM Force Camera");
	gCvar_sm_forcecam_flag = CreateConVar("sm_forcecamera_flag", "a", "Admin Flag required for view opposite team players");
	gCvar_sm_forcecam_groups = CreateConVar("sm_forcecamera_groups", "Full Admins", "Allow this Groups to view opposite team players");
	gCvar_sm_forcecam_ver = CreateConVar("sm_forcecam_ver", PLUGIN_VERSION, "SM Force Camera Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	gCvar_mp_forcecamera = FindConVar("mp_forcecamera");
	
	RefreshSetting();
	
	HookEvent("player_death", Ev_PlayerDeath);
	HookConVarChange(gCvar_sm_forcecam, MyCvarChange);
	HookConVarChange(gCvar_sm_forcecam_flag, MyCvarChange);
	HookConVarChange(gCvar_sm_forcecam_groups, MyCvarChange);
	HookConVarChange(gCvar_mp_forcecamera, MyCvarChange);
	
	#if DEBUG >= 1
	RegAdminCmd("sm_forcecam_table", Cmd_ForceCamTable, ADMFLAG_ROOT, ""); 
	#endif
}

public OnMapStart()
{
	CreateTimer(5.0, DelayedVersionRefresh);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	AllowViewOpp[client] = false;
	return true;
}

public OnClientPostAdminCheck(client)
{
	decl String:Flag[2];
	AllowViewOpp[client] = false;
	new AdminId:AdmId = GetUserAdmin(client);
	GetConVarString(gCvar_sm_forcecam_flag, Flag, sizeof(Flag));
	if(Flag[0]!='\0')
	{
		decl AdminFlag:Flag2;
		if(FindFlagByChar(Flag[0], Flag2))
		{
			if(GetAdminFlag(AdmId, Flag2))
			{
				#if DEBUG >= 2
				decl String:cname[128];
				GetClientName(client, cname, sizeof(cname));
				new team = GetClientTeam(client);
				PrintToServer("[SM_FORCECAM] %s(%d)[%d] authed by flag", cname, client,team);
				#endif
				AllowViewOpp[client]	= true;
				
			}
		}
	}
	
	new GroupsCount = GetAdminGroupCount(AdmId);
	if(AllowViewOpp[client] != true && GroupsCount>0)
	{
		decl String:GroupName[32];
		for(new i = 0; i<GroupsCount; i++)
		{
			if(AllowViewOpp[client] == true) break;
			
			GetAdminGroup(AdmId, i, GroupName, sizeof(GroupName));
			for(new j = 0; j <= MAXADMGROUPS; j++)
			{
				if(g_sm_forcecam_groups[j][0]!='\0' && strcmp(GroupName, g_sm_forcecam_groups[j], false) == 0)
				{
					#if DEBUG >= 2
					decl String:cname[128];
					GetClientName(client, cname, sizeof(cname));
					new team = GetClientTeam(client);
					PrintToServer("[SM_FORCECAM] %s(%d)[%d] authed by group", cname, client,team);
					#endif
					
					AllowViewOpp[client]	= true;
					break;
				}
			}
		}
	}
	
}

#endif //---------------------------------------------------- SM Fwd END ---------------------------------------------------//

#if 1 //####################################################### Settings #####################################################//

public MyCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]) //----------- On plugins cvar change
{
	if(strcmp(oldValue, newValue)==0) return; //No change
	RefreshSetting(convar);
}

RefreshSetting(Handle:convar=INVALID_HANDLE) //---- Setting state refresh, INVALID_HANDLE == refresh all cvars and precache models
{
	
	if(convar == INVALID_HANDLE || convar == gCvar_sm_forcecam) 
	{
		new bool:boolval = GetConVarBool(gCvar_sm_forcecam);
		if(boolval!=g_sm_forcecam)
		{
			if(boolval)
			{
				g_sm_forcecam = true;
				AddCommandListener(Cmd_spec_prev, "spec_prev");
				AddCommandListener(Cmd_spec_next, "spec_next");
				AddCommandListener(Cmd_spec_player, "spec_player");
				AddCommandListener(Cmd_spec_mode, "spec_mode");
				if(gCvar_mp_forcecamera!=INVALID_HANDLE) SetConVarBool(gCvar_mp_forcecamera, false);
			} 
			else
			{
				g_sm_forcecam = false;
				RemoveCommandListener(Cmd_spec_prev, "spec_prev");
				RemoveCommandListener(Cmd_spec_next, "spec_next");
				RemoveCommandListener(Cmd_spec_player, "spec_player");
				RemoveCommandListener(Cmd_spec_mode, "spec_mode");
			}
		}
		if(convar != INVALID_HANDLE) return;
	}
	
	if(convar == INVALID_HANDLE || convar == gCvar_sm_forcecam_flag) 
	{
		GetConVarString(gCvar_sm_forcecam_flag, g_sm_forcecam_flag, sizeof(g_sm_forcecam_flag));
		
		if(convar != INVALID_HANDLE) return;
	}
	if(convar == INVALID_HANDLE || convar == gCvar_mp_forcecamera) 
	if(convar == INVALID_HANDLE || convar == gCvar_sm_forcecam_groups) 
	{
		decl String:tmp[256];
		GetConVarString(gCvar_sm_forcecam_groups, tmp, sizeof(tmp));
		ExplodeString(tmp, ",", g_sm_forcecam_groups, sizeof(g_sm_forcecam_groups), sizeof(g_sm_forcecam_groups[]));
		if(convar != INVALID_HANDLE) return;
	}
	if(convar == INVALID_HANDLE || convar == gCvar_mp_forcecamera) 
	{
		if(gCvar_mp_forcecamera!=INVALID_HANDLE && g_sm_forcecam) SetConVarBool(gCvar_mp_forcecamera, false);
	}
}

#endif //---------------------------------------------------- Settings END ---------------------------------------------------//

#if 1 //####################################################### Spec Commands #################################################//

public Action:Cmd_spec_mode(client, const String:command[], argc)
{
	if(client == 0 || IsPlayerAlive(client)) return Plugin_Handled;
	if( (!g_sm_forcecam) || AllowViewOpp[client]) return Plugin_Continue;
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", 4); //Force First Person
	return Plugin_Handled;
}

public Action:Cmd_spec_player(client, const String:command[], argc)
{
	if(client == 0 || IsPlayerAlive(client)) return Plugin_Handled;
	if( (!g_sm_forcecam) || AllowViewOpp[client]) return Plugin_Continue;
	
	new team = GetClientTeam(client);
	if(team <= 1) return Plugin_Continue; //Spectator
	
	decl String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	if(arg[0]!='\0')
	{
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
		
		if(target_count != 1 ) return Plugin_Handled;
		
		new observclient = target_list[0];
		new team2 = GetClientTeam(observclient);
		if(team == team2) return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action:Cmd_spec_next(client, const String:command[], argc)
{
	if(client == 0 || IsPlayerAlive(client)) return Plugin_Handled;
	if( (!g_sm_forcecam) || AllowViewOpp[client]) return Plugin_Continue;
	
	new team = GetClientTeam(client);
	if(team <= 1) return Plugin_Continue;  //Spectator
	
	new Observing = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	new NextObserv = NextPrevClient(Observing, true, team);
	
	if(NextObserv != -1 ) {
		#if DEBUG >= 2
		decl String:cname[128],String:cname2[128];
		GetClientName(client, cname, sizeof(cname));
		GetClientName(NextObserv, cname2, sizeof(cname2));
		new team2 = GetClientTeam(NextObserv);
		PrintToServer("C: %s(%d)[%d], used spec_next, %s(%d)[%d]", cname, client,team, cname2, NextObserv, team2);
		#endif 
		
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", NextObserv);
	}
	else return Plugin_Continue; //No more alive players
		
	return Plugin_Handled;
}

public Action:Cmd_spec_prev(client, const String:command[], argc)
{
	if(client == 0 || IsPlayerAlive(client)) return Plugin_Handled;
	if( (!g_sm_forcecam) || AllowViewOpp[client]) return Plugin_Continue;
	
	new team = GetClientTeam(client);
	if(team <= 1) return Plugin_Continue;  //Spectator
	
	new Observing = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	new PrevObserv = NextPrevClient(Observing, false, team);
	if(PrevObserv != -1 ) 
	{
		#if DEBUG >= 2
		decl String:cname[128],String:cname2[128];
		GetClientName(client, cname, sizeof(cname));
		GetClientName(PrevObserv, cname2, sizeof(cname2));
		new team2 = GetClientTeam(PrevObserv);
		PrintToServer("C: %s(%d)[%d], used spec_prev, %s(%d)[%d]", cname, client,team, cname2, PrevObserv, team2);
		#endif 
	
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", PrevObserv);
	}
	else return Plugin_Continue; //No more alive players
	
	return Plugin_Handled;
}

public Action:Ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!AllowViewOpp[client])
	{
		CreateTimer(6.0, DelayedSetObserv, client);
	}
	
	//Check all players who was watching him
	CreateTimer(0.1, DelayedCheckDeath, client);
	
	return Plugin_Continue;
}

public Action:DelayedCheckDeath(Handle:timer, any:client)
{
	decl NextObserv, team, Observing;
	for(new i=1; i<=MaxClients; i++)
	{
		if(!AllowViewOpp[client] && IsClientInGame(i) && (!IsPlayerAlive(i)) ) 
		{
			team = GetClientTeam(i);
			if(team<=1)  continue; //Spec
			Observing = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			if(Observing == client)
			{
				NextObserv = NextPrevClient(client, true, team);
				if(NextObserv > 0) SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", NextObserv);
			}
		}
	}
}
public Action:DelayedSetObserv(Handle:timer, any:client)
{
	if(IsClientInGame(client) && (!IsPlayerAlive(client)))
	{
		new team = GetClientTeam(client);
		
		new Observing = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		new NextObserv = NextPrevClient(Observing, true, team);
		if(NextObserv != -1 ) SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", NextObserv);
		CreateTimer(1.0, DelayedSetMode, client);
	}
}


public Action:DelayedSetMode(Handle:timer, any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client) && (!IsPlayerAlive(client)))
	{
		SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
	}
}

#endif //---------------------------------------------------- Spec Commands End ------------------------------------------------//

#if 1 //####################################################### Helpers #################################################//
NextPrevClient(client, bool:Next = true,Team = -1, bool:Alive = true)
{
	// Check client
	if(client <=0 ) client = 1 ;
	if(client > MaxClients ) client = MaxClients ;

	// add client index to i
	new i = client;

	// increase or decrease i and check will it go out player indexs
	if(Next)
	{
		i++;

		// Go over MAXPLAYERS
		if(i > MaxClients)
		{
			i = 1;
		}
	}
	else
	{
		i--;

		// Less than 1
		if(i < 1)
		{
			i = MaxClients;
		}
	}
	
	
	for(; ; )
	{
		// LOOP, Check now i (at this point it need to be valid client index)

		if(IsClientConnected(i) && IsClientInGame(i) )
		{
			if(!Alive || ( Alive && IsPlayerAlive(i)) )
			{
				if(Team == -1) 
				{
					break;
				}
				new Team2 = GetClientTeam(i);
				if(Team == Team2) 
				{
					break;
				}
			}
		}

		// If loop continue, increase or decrease i now
		if(Next) i++;
		else i--;

		// Will i now go out player indesx ? Make loop go back start

		// Loop is increasing ++ and i is out of indexs, make loop start from 1
		if(i > MaxClients && Next) i = 1;

		// Loop is decreasing -- and i less than 1, make loop start from MAXPLAYERS
		if(i < 1 && !Next) i = MaxClients;

		// Looping till i match client, stop looping and return -1 (there no teammates alive to spec)
		if(i == client) return -1; // No clients
	}
	return i;
}

public Action:DelayedVersionRefresh(Handle:timer, any:client)
{
	SetConVarString(gCvar_sm_forcecam_ver, PLUGIN_VERSION, false, false);
}


#if DEBUG >= 1
public Action:Cmd_ForceCamTable(client, args) 
{
	decl String:cname[64], String:cname2[64], team, team2, Observing;
	ReplyToCommand(client, "##### Observing Table #####");
	ReplyToCommand(client, "#ClientId-ClientName-Team observing ClientId-ClientName-Team#");
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && (!IsPlayerAlive(i)) ) 
		{
			GetClientName(i, cname, sizeof(cname));
			team = GetClientTeam(i);
			if(args>=1 && team<=1)  continue;
			Observing = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			
			if(Observing == -1 || !IsClientInGame(Observing) || !IsPlayerAlive(Observing)) continue;
			GetClientName(Observing, cname2, sizeof(cname2));
			team2 = GetClientTeam(Observing);
			
			ReplyToCommand(client, "%d#%d-%s-%d\t\tobserv\t\t%d-%s-%d", AllowViewOpp[i],i, cname,team, Observing ,cname2,team2);
		}
	}
}
#endif 

#endif //---------------------------------------------------- Helpers End ------------------------------------------------//


