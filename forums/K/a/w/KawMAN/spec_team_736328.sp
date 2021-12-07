/*
-------------------------------------------------
L4D VS Spectator Team by KawMAN
-------------------------------------------------
ChangeLog:
3.01.09 - V 1.1
-Now plugin dont kill player if he is playing 
 as Tank
-shorter delay betwen kill and join spectators
-changed kill by FakeClientCommand to kill by 
 ForcePlayerSuicide

8.01.09 - V1.2
-Added function forcing move player to 
 spectator after connect to server 
 (when other players is outside Safe Room). 
 This should prevent situation when player 
 control character but he is still loading 
 game (cant move, and cant defend)
8.01.09 - V1.2.1
-Showing up "chooseteam" menu after join 
 spectator
 (when type "spectate" and when player connect)
10.01.09 - V 1.2.2
- Now plugin works only in Versus Mode
15.01.09 - V 1.3.0
- Changed name to Spectator Team (spec_team)
- Prevent spawning bot by team switch
- This plugin force vs_max_team_switches to 9999
  so default team switches limit no longer exist
  (in practice)
14.03.09 - V 1.3.5
- Added reminder (see cvar section)
- Added autokick from spectator
- Added Translation File
- Added AutoExec config file
- Some code optimalization
Thanks for bman87 and for all who used my plugins
Some code is from other alliedmoders scripts
18.03.09 - V 1.4.0
- Added cvar l4d_st_changemethod
- Added switch to survivors by SDKCall
- Added Signatures file l4dspec_team.txt. Signatures taken from Fyren l4dunscrambler
- Fixed not switching from infected to survivors


-------------------------------------------------
*/
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4.0"
#define DEBUG 0


public Plugin:myinfo = 
{
	name = "L4D Spectator Team",
	author = "KawMAN",
	description = "Enable Spectator Team in Versus Mode",
	version = PLUGIN_VERSION,
	url = "http://wsciekle.pl"
}

new first_join[MAXPLAYERS+1];
new String:g_tankmodel[]="models/infected/hulk.mdl";
new left=0;

//Cvar Handles
new Handle:g_limit_surv = INVALID_HANDLE;
new Handle:g_unjoin = INVALID_HANDLE;
new Handle:g_reminder_mode = INVALID_HANDLE;
new Handle:g_reminder_timer = INVALID_HANDLE;
new Handle:g_autokick_time = INVALID_HANDLE;
new Handle:g_changemeth = INVALID_HANDLE;
new Handle:versus = INVALID_HANDLE;
new Handle:max_switches = INVALID_HANDLE;
new Handle:gConf = INVALID_HANDLE;
new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;

//Cvar Values Def
new unjoin=1;
new reminder_mode=1;
new changemeth=1;
new Float:reminder_timer=40.0;
new Float:autokick_time=200.0;

//Other Values
new limit_surv = 4;
new Handle:autokick[MAXPLAYERS+1]={INVALID_HANDLE};
new flagi;


public OnPluginStart()
{
	LoadTranslations("l4d_spec_team.phrases");
	
	//Prep SDK Call
	gConf = LoadGameConfigFile("l4dspec_team");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();
	
	//Reg Commands
	RegConsoleCmd("spectate", To_Spectate);
	RegConsoleCmd("jointeam", do_chooseteam);
	
	//Reg Cvars
	CreateConVar("sm_specfix_v", PLUGIN_VERSION, "L4D Spectator fix version(now Spectator Team)", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_unjoin = CreateConVar("l4d_join_to_spec_after_conn", "1", "1-Move player to spectator team after connect", 0, true, 0.0,true,1.0);
	g_reminder_mode = CreateConVar("l4d_st_reminder_mode", "1", "Reminder mode, 0 = Off, 1 = Show messages in chat, 2 = Show messages in chat and choseteam menu", 0, true, 0.0,true,2.0);
	g_reminder_timer = CreateConVar("l4d_st_reminder_time", "40.0", "Remind every n sec about join to team when on spectator", 0,true, 10.0,true,300.0);
	g_autokick_time = CreateConVar("l4d_st_autokick_time", "200.0", "Kick spectator after n sec, if 0 autokick is off", 0, true, 0.0,true,9000.0);
	g_changemeth = CreateConVar("l4d_st_changemethod", "1", "How plugin should switch to survivors: 1-by SDKCall 2-by sb_takecontrol cmd", 0, true, 1.0,true,2.0);
	AutoExecConfig(true, "l4d_spec_team");
	
	//Hook cvars
	HookConVarChange(g_unjoin, ConVarChanged);
	HookConVarChange(g_reminder_mode, ConVarChanged);
	HookConVarChange(g_reminder_timer, ConVarChanged);
	HookConVarChange(g_autokick_time, ConVarChanged);
	HookConVarChange(g_changemeth, ConVarChanged);
	
	
	//Hook events
	HookEvent("player_team", Event_plrteam);
	HookEvent("player_left_start_area", Event_left);
	HookEvent("round_end", Event_roundstart);
	
	//Finding base game mode cvar
	versus = FindConVar("director_no_human_zombies");
	g_limit_surv = FindConVar("survivor_limit");
	
	//"Turn off" max team switch limit
	max_switches = FindConVar("vs_max_team_switches");
	SetConVarInt(max_switches, 9999);
	HookConVarChange(max_switches, OnLimitChanged);
	
	//Set values
	flagi = GetCommandFlags("sb_takecontrol");
	
	ReadCvars();
}

public OnClientPutInServer(client)
{
	first_join[client] = 1;
}

public OnMapStart()
{
	//Should be changed by round start event, but ...
	left=0;
}
//Actions
public Action:To_Spectate(client, args)
{
	//spectate work only do versus, in coop use take break
	if(GetConVarInt(versus)==0&&IsValidPlayer(client))
	{
		new cTeam  = GetClientTeam( client );
		if (cTeam == 3)
		{
			new String:model[255];
			GetClientModel(client, model, sizeof(model));
			if(strcmp(g_tankmodel,model,true)!= 0) 
			{
				ForcePlayerSuicide(client);
			}
		}
		//Player switched to spectator
		new String:name[255];
		GetClientName(client,name,sizeof(name));
		PrintToChatAll("[SM] %s %t",name,"#Switched Himslef To Spec");
		CreateTimer(0.1, movetospec, client)
		return Plugin_Handled;
	}
	//else
	// {
		//Coop Mode - Use take break message or client command	
	// }
	return Plugin_Handled;
}

public Action:do_chooseteam(client, args)
{
	if(args==1&&IsValidPlayer(client))
	{
		new String:arg[11];
		GetCmdArg(1, arg, sizeof(arg));
		if(strcmp(arg,"Survivor", false)==0)
		{
			
			new cTeam  = GetClientTeam( client );
			if (cTeam == 3)
			{
				if(RealPlayerCountInS() < limit_surv)
				{
					new String:model[255];
					GetClientModel(client, model, sizeof(model));
					//Can't change team if playing as tank
					if(strcmp(g_tankmodel,model,true)!= 0) 
					{
						ForcePlayerSuicide(client);	
					}
					CreateTimer(0.1, movetosurv, client);
				}
				return Plugin_Handled;
			}
		}
	}
	if(autokick[client] != INVALID_HANDLE)
	{
		KillTimer(autokick[client]);
		autokick[client]=INVALID_HANDLE;
	}
	return Plugin_Continue;
}

public Action:movetospec(Handle:timer, any:client)
{
	ChangeClientTeam(client,1);
	ClientCommand(client, "chooseteam");
	PrintToChat(client, "[SM] %t","#Chooseteam");
	PrintHintText(client, "%t","#Chooseteam");
	//Reminder Timer
	if(reminder_mode)
	{
		CreateTimer(reminder_timer, Reminder, client, TIMER_REPEAT)
	}
	//Auto Kick Timer
	if(autokick_time>0)
	{
		autokick[client]=CreateTimer(autokick_time, autokicker, client);
	}
}

public Action:Reminder(Handle:timer, any:client)
{
	if (IsValidPlayer(client))
	{
		if (GetClientTeam(client)!=1)
		{
			return Plugin_Stop;
		}
		if(reminder_mode==2) ClientCommand(client, "chooseteam");
		PrintToChat(client, "[SM] %t","#Chooseteam");
		PrintHintText(client, "%t","#Chooseteam");
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action:autokicker(Handle:timer, any:client)
{
	if (IsValidPlayer(client))
	{
		if (GetClientTeam(client)==1)
		{
			KickClient(client, "%t","#Kick_msg");
		}
	}
	autokick[client]=INVALID_HANDLE;
	return Plugin_Continue
}

public Action:movetosurv(Handle:timer, any:client)
{
#if DEBUG
	PrintToServer("Move to surv %d",client);
#endif
	if(IsValidPlayer(client))
	{
		new cTeam;
		cTeam = GetClientTeam( client );
#if DEBUG
		PrintToServer("%d Vaild team: %d",client,cTeam);
#endif
		if(cTeam != 2)
		{
			if(changemeth == 1)
			{
#if DEBUG
				PrintToServer("%d ChangeMethod 1",client);
#endif
				if(TakeBotSDK(client,false))
				{
#if DEBUG
					PrintToServer("%d TakeBotSKD flase",client);
#endif
					return Plugin_Continue;
				}
				if(TakeBotSDK(client,true)) 
				{
#if DEBUG
					PrintToServer("%d TakeBotSKD true",client);
#endif
					return Plugin_Continue;
				}
			}
			else
			{
#if DEBUG
				PrintToServer("%d ChangeMethod else",client);
#endif
				if(TakeBotCMD(client,false))
				{
#if DEBUG
					PrintToServer("%d TakeBotCMD false",client);
#endif
					return Plugin_Continue; //Try to get alive bot
				}
				if(TakeBotCMD(client,true)) 
				{
#if DEBUG
					PrintToServer("%d TakeBotCMD true",client);
#endif
					return Plugin_Continue; //Try to get dead bot
				}
			}
#if DEBUG
			PrintToServer("%d after switch method %d",client,changemeth);
#endif

			//Print when no place in surv
			PrintToChat(client,"[SM] No place in survivior");
		}
	}
	return Plugin_Handled;
}

//Hooked Events
public Event_plrteam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(versus)==0)
	{
		new userid = GetEventInt(event, "userid");
		new plr_index = GetClientOfUserId(userid);
		if (plr_index!=0&&IsValidPlayer(plr_index))
		{
			if (first_join[plr_index]==1)
			{
				if (left==1)
				{
					first_join[plr_index]=0;
					if(unjoin != 0)
					{
						CreateTimer(0.1, movetospec, plr_index);
					}
				}
				else
				{
					first_join[plr_index]=0;
				}
			}
		}
	}
}

public Event_left(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Surv left start area
	left=1;	
}

public Event_roundstart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//On new rounds, turn off moveing to spec
	left=0;	
}

//Cvar
public OnLimitChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) != 9999)
	{
		SetConVarInt(max_switches, 9999);
	}
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ReadCvars();
}

public ReadCvars()
{
	limit_surv=GetConVarInt(g_limit_surv);
	unjoin=GetConVarInt(g_unjoin);
	reminder_mode=GetConVarInt(g_reminder_mode);
	reminder_timer=GetConVarFloat(g_reminder_timer);
	autokick_time=GetConVarFloat(g_autokick_time);
	changemeth=GetConVarInt(g_changemeth);
	
}

//Helper
public bool:TakeBotSDK(client, bool:canbedead)
{
#if DEBUG
	PrintToServer("Searchfor bot");
#endif
	//Search for bot
	new maxclients=GetMaxClients();
	for(new i=1;i<=maxclients; i++)
	{
#if DEBUG
		PrintToServer("Searchfor bot. check client: %d Max:%d",i,GetMaxClients());
#endif
		if(IsClientConnected(i)&&IsClientInGame(i))
		{
#if DEBUG
			PrintToServer("Searchfor bot. client : %d is connected and in game",i);
#endif
			if(IsFakeClient(i))
			{
#if DEBUG
				PrintToServer("Searchfor bot. client : %d is bot",i);
#endif
				if(IsPlayerAlive(i)||canbedead)
				{
#if DEBUG
					PrintToServer("Searchfor bot. bot : %d is Alive or can be dead %d",i,canbedead);
#endif
					ChangeClientTeam(client, 1); 
					SDKCall(fSHS, i, client); 
					SDKCall(fTOB, client, true);
					return true;
				}
			}
		}
	}
	return false;
}

public bool:TakeBotCMD(client, bool:canbedead)
{
	//Search for bot
	new maxclients=GetMaxClients();
	for(new i=1; i <= maxclients; i++)
	{
		if(IsClientConnected(i)&&IsClientInGame(i))
		{
			if(IsFakeClient(i))
			{
				new String:name[255];
				GetClientName(i, name, sizeof(name));
				if(strcmp(name,"zoey",false)== 0||strcmp(name,"louis",false)== 0||strcmp(name,"bill",false)== 0||strcmp(name,"francis",false)== 0)
				{
					if(IsPlayerAlive(i)||canbedead)
					{
						if(IsValidPlayer(client))
						{
							SetCommandFlags("sb_takecontrol", flagi & ~FCVAR_CHEAT);
							FakeClientCommand(client, "sb_takecontrol %s",name);
							SetCommandFlags("sb_takecontrol", flagi);
							return true;
						}
					}
				}
			}
		}
	}
	return false;
}

public IsValidPlayer (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}

public RealPlayerCountInS()
{
	new rp_in_surv=0;
	new maxclients=GetMaxClients();
	for(new i=1;i<=maxclients;i++)
	{
		if(IsValidPlayer(i))
		{
			new tTeam  = GetClientTeam(i);
			if (tTeam == 2)
			{
				rp_in_surv++;
			}
		}
	}
	return rp_in_surv;
}
