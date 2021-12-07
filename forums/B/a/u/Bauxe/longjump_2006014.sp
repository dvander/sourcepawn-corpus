#include <sourcemod>
#include <morecolors>
 
new Handle:sm_enablelongjump = INVALID_HANDLE;
new Handle:sm_enablelastjumps = INVALID_HANDLE;
new Handle:sm_distancecalc = INVALID_HANDLE;
new Handle:spawnTimers[MAXPLAYERS+1]
new bool:enableplugin;
new bool:enablelastjumps;
new bool:distancecalc;
 
public Plugin:myinfo =
{
	name = "LongJump",
	author = "Like a Bauxe",
	description = "Display LongJump Distance. Thanks to Promethium & ArathusX",
	version = "1.1.1",
	url = "https://forums.alliedmods.net/showthread.php?p=2006014"
};
 
enum players
{
	bool:p_alive,
	p_HUDEnabled,
	bool:p_Jumped,
	Float:p_Initial[3],
	Float:p_Final[3],
	Float:p_DistanceX,
	Float:p_DistanceZ,
	Float:p_Distance,
	Float:p_Height,
	Float:p_Previousheight,
	Float:p_Initialspeed,
	Float:p_BestJump
}
 
new playersArray[MAXPLAYERS][players];
 
enum jumps
{
	Float:l_jump0,
	Float:l_jump1,
	Float:l_jump2,
	Float:l_jump3,
	Float:l_jump4,
	Float:l_jump5,
	Float:l_jump6,
	Float:l_jump7,
	Float:l_jump8,
	Float:l_jump9
}
 
new jumpsArray[MAXPLAYERS][jumps];
 
public OnPluginStart()
{
	CreateConVar("sm_longjump_version", "1.1.0", "LongJump Version", FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_lj", Cmd_longjump, "Display Longjump HUD");
	RegConsoleCmd("sm_longjump", Cmd_longjump, "Display Longjump HUD");
	RegConsoleCmd("sm_lastjumps", Cmd_lastjumps, "Print last 10 jumps to console");
	RegConsoleCmd("sm_bestjump", Cmd_bestjump, "Display your best longjump");
	RegConsoleCmd("sm_ljcommands", Cmd_ljcommands, "Display all LongJump Commands");
	
	sm_enablelongjump = CreateConVar("sm_enablelongjump", "1", "Enable / Disable Plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_enablelastjumps = CreateConVar("sm_enablelastjumps", "1", "Allow viewing of past 10 LongJumps", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_distancecalc = CreateConVar("sm_distancecalc", "1", "Method of calculation. 1 = Front to Back (Extra 32 Units)", FCVAR_NONE, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "longjump");
	
	enableplugin = GetConVarBool(sm_enablelongjump);
	enablelastjumps = GetConVarBool(sm_enablelastjumps);
	distancecalc = GetConVarBool(sm_distancecalc);
	
	HookConVarChange(sm_enablelongjump, ConVarChanged);
	HookEvent("player_jump", Event_player_jump);
	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("player_death", Event_player_death);
}
 
public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	enableplugin = GetConVarBool(sm_enablelongjump);
}
 
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(playersArray[client][p_alive] == false)
	{
		spawnTimers[client] = CreateTimer(2.0, GameSpawn, client);
	}
}
 
public Action:GameSpawn(Handle:timer, any:client)
{
	playersArray[client][p_alive] = true;
}
 
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	playersArray[client][p_alive] = false;
}
       
public Action:Cmd_longjump(client, args)
{      
	if(enableplugin)
	{
		if(playersArray[client][p_HUDEnabled] == 0)
		{
			playersArray[client][p_HUDEnabled] = 1;
			CPrintToChat(client, "\x07C7800E[LJ] \x01Enabled!");
		}
		else if(playersArray[client][p_HUDEnabled] == 1)
		{
			playersArray[client][p_HUDEnabled] = 0;
			CPrintToChat(client, "\x07C7800E[LJ] \x01Disabled!");
		}
	}
	return Plugin_Handled;
}
 
public Action:Cmd_lastjumps(client, args)
{
	if(enableplugin && enablelastjumps)
	{
		CPrintToChat(client, "\x07C7800E[LJ] \x01Check Console for Output");
		PrintToConsole(client, "%f, %f, %f, %f, %f, %f, %f, %f, %f, %f", jumpsArray[client][l_jump0], jumpsArray[client][l_jump1], jumpsArray[client][l_jump2], jumpsArray[client][l_jump3], jumpsArray[client][l_jump4], jumpsArray[client][l_jump5], jumpsArray[client][l_jump6], jumpsArray[client][l_jump7], jumpsArray[client][l_jump8], jumpsArray[client][l_jump9]);
	}
	else
	{
		CPrintToChat(client, "\x07C7800E[LJ] \x01This feature is disabled.");
	}
	return Plugin_Handled;
}
 
public Action:Event_player_jump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(enableplugin && playersArray[client][p_alive] == true)
	{
		if(playersArray[client][p_Jumped] == true && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
		{
			return Plugin_Handled;
		}
		else
		{
			playersArray[client][p_Jumped] = true;
			
			decl Float:fInitial[3];
			
			GetClientAbsOrigin(client, fInitial);
			
			playersArray[client][p_Initial] = fInitial;
			
			decl Float:fVelocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
			
			playersArray[client][p_Initialspeed] = SquareRoot(Pow(fVelocity[0], 2.0) + Pow(fVelocity[1], 2.0) + Pow(fVelocity[2], 2.0));
		}
	}
	
	return Plugin_Continue;
}
 
public Action:OnPlayerRunCmd(client)
{
	if(enableplugin && playersArray[client][p_alive] == true)
	{
		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			if(playersArray[client][p_Jumped] == false && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
			{
				return Plugin_Continue;
			}
			else
			{
				playersArray[client][p_Jumped] = false;

				decl Float:fFinal[3];

				GetClientAbsOrigin(client, fFinal);

				playersArray[client][p_Final] = fFinal;

				playersArray[client][p_DistanceX] = playersArray[client][p_Final][0] - playersArray[client][p_Initial][0];

				if(playersArray[client][p_DistanceX] < 0)
				{
					playersArray[client][p_DistanceX] = -playersArray[client][p_DistanceX];
				}

				playersArray[client][p_DistanceZ] = (playersArray[client][p_Final][1] - playersArray[client][p_Initial][1]);

				if(playersArray[client][p_DistanceZ] < 0)
				{
					playersArray[client][p_DistanceZ] = -playersArray[client][p_DistanceZ];
				}
	
				playersArray[client][p_Height] = (playersArray[client][p_Final][2] - playersArray[client][p_Initial][2]);
				
				if(-2 < playersArray[client][p_Height] < 2)
				{
					playersArray[client][p_Height] = 0.0;
				}
				
				if(playersArray[client][p_DistanceX] < 0)
				{
					playersArray[client][p_DistanceX] = -playersArray[client][p_DistanceX];
				}
				
				if(playersArray[client][p_DistanceZ] < 0)
				{
					playersArray[client][p_DistanceZ] = -playersArray[client][p_DistanceZ];
				}
				
				playersArray[client][p_Distance] = SquareRoot(Pow(playersArray[client][p_DistanceX], 2.0) + Pow(playersArray[client][p_DistanceZ], 2.0));
				
				if(distancecalc)
				{
					playersArray[client][p_Distance] = playersArray[client][p_Distance] + 32;
				}
				
				if(playersArray[client][p_HUDEnabled] == 1)
				{
					new String:HUDMessage[256];
					new String:Distance[16];
					new String:Height[16];
					new String:lastJump[16];
					new String:lastHeight[16];
					new String:bestJump[16];
					
					FloatToString(playersArray[client][p_Distance], Distance, sizeof(Distance));
					FloatToString(playersArray[client][p_Height], Height, sizeof(Height));
					FloatToString(jumpsArray[client][l_jump0], lastJump, sizeof(lastJump));
					FloatToString(playersArray[client][p_Previousheight], lastHeight, sizeof(lastHeight));
					FloatToString(playersArray[client][p_BestJump], bestJump, sizeof(bestJump));
					
					HUDMessage[0] = '\0';
					
					StrCat(HUDMessage, sizeof(HUDMessage), "LongJump by Bauxe\n\nDistance: ");
					StrCat(HUDMessage, sizeof(HUDMessage), Distance);
					StrCat(HUDMessage, sizeof(HUDMessage), "\nHeight Change: ");
					StrCat(HUDMessage, sizeof(HUDMessage), Height);
					
					if(jumpsArray[client][l_jump0] != 0.0)
					{
						StrCat(HUDMessage, sizeof(HUDMessage), "\n\nPrevious Jump: ");
						StrCat(HUDMessage, sizeof(HUDMessage), lastJump);
						StrCat(HUDMessage, sizeof(HUDMessage), "\nPrevious Height Change: ");
						StrCat(HUDMessage, sizeof(HUDMessage), lastHeight);
					}
					
					if(playersArray[client][p_BestJump] != 0.0)
					{
						StrCat(HUDMessage, sizeof(HUDMessage), "\n\nBest Jump: ");
						StrCat(HUDMessage, sizeof(HUDMessage), bestJump);
					}
					
					new Handle:hBuffer = StartMessageOne("KeyHintText", client);
					BfWriteByte(hBuffer, 1);
					BfWriteString(hBuffer, HUDMessage);
					EndMessage();
				}
				
				if(enablelastjumps)
				{
					jumpsArray[client][l_jump9] = jumpsArray[client][l_jump8];
					jumpsArray[client][l_jump8] = jumpsArray[client][l_jump7];
					jumpsArray[client][l_jump7] = jumpsArray[client][l_jump6];
					jumpsArray[client][l_jump6] = jumpsArray[client][l_jump5];
					jumpsArray[client][l_jump5] = jumpsArray[client][l_jump4];
					jumpsArray[client][l_jump4] = jumpsArray[client][l_jump3];
					jumpsArray[client][l_jump3] = jumpsArray[client][l_jump2];
					jumpsArray[client][l_jump2] = jumpsArray[client][l_jump1];
					jumpsArray[client][l_jump1] = jumpsArray[client][l_jump0];
					jumpsArray[client][l_jump0] = playersArray[client][p_Distance];
					playersArray[client][p_Previousheight] = playersArray[client][p_Height];
				}
				
				if(playersArray[client][p_Height] == 0.0)
				{
					if(playersArray[client][p_Distance] > playersArray[client][p_BestJump] && playersArray[client][p_Distance] < 276.0)
					{
						playersArray[client][p_BestJump] = playersArray[client][p_Distance];
					}
				}
			}
		}
	}      
	return Plugin_Continue;
}
 
public Action:Cmd_bestjump(client, args)
{
	if(args >= 1)
	{
		new String:arg1[32]
		GetCmdArg(1, arg1, sizeof(arg1));
		
		new target = FindTarget(client, arg1)
		
		if(target == -1)
		{
			return Plugin_Handled;
		}
		
		else
		{
			new String:name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));
			
			CPrintToChat(client, "\x07C7800E[LJ] \x01%s's Best Jump: %f", name, playersArray[target][p_BestJump]);            
		}
	}
	
	else
	{
		CPrintToChat(client, "\x07C7800E[LJ] \x01Your Best Jump: %f", playersArray[client][p_BestJump]);
	}
	
	return Plugin_Handled;
}
 
public LJMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 0)
		{
			ClientCommand(param1, "sm_longjump");
		}
		else if(param2 == 1)
		{
			ClientCommand(param1, "sm_lastjumps");
		}
		else if(param2 == 2)
		{
			ClientCommand(param1, "sm_bestjump");
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Cmd_ljcommands(client, args)
{
	new Handle:menu = CreateMenu(LJMenu);
	SetMenuTitle(menu, "LongJump Commands");
	AddMenuItem(menu, "hud", "LongJump HUD");
	AddMenuItem(menu, "lastjumps", "Last 10 Jumps");
	AddMenuItem(menu, "bestjump", "Best LongJump");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
	
	return Plugin_Handled;
}