#include <tf2attributes>
#include <morecolors>

new Float:FootprintID[MAXPLAYERS+1] = 0.0

new String:AdmFlag[32];

new Handle:CvarFlagAccess;

public Plugin:myinfo = 
{
	name = "[TF2] Halloween Footprints",
	author = "Oshizu",
	description = "Looks Fancy Ahhhh",
	version ="1.0",
	url = "www.otaku-gaming.net"
}

public OnPluginStart()
{
	CvarFlagAccess = CreateConVar("sm_footsteps_flag", "a", "Player need to have this flag to use the plugin.", FCVAR_PLUGIN);
	
	RegConsoleCmd("sm_footprints", FootSteps, "Show footsteps menu");
	RegConsoleCmd("sm_footsteps", FootSteps, "Show footsteps menu");

	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post)

	AutoExecConfig(true, "plugin.footsteps");
}

public OnClientDisconnect(client)
{
	if(FootprintID[client] > 0.0)
	{
		FootprintID[client] = 0.0
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(FootprintID[client] > 0.0)
	{
		TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", FootprintID[client]);
	}
}

public Action:FootSteps(client, args)
{
	GetConVarString(CvarFlagAccess, AdmFlag, sizeof(AdmFlag));
	new CustomFlag = ReadFlagString(AdmFlag);
	if(IsValidClient(client) && CheckCommandAccess(client, "sm_footsteps", CustomFlag,true) == true )
		ShowMenu(client);
	else
		CPrintToChat(client, "{default}[SM] You do {red}not {default}have access to this command.");
	return Plugin_Handled;
}

ShowMenu(client)
{
	new Handle:ws = CreateMenu(FootStepsCALLBACK);
	SetMenuTitle(ws, "Choose Your Footprints Effect");

	AddMenuItem(ws, "0", "No Effect");
	AddMenuItem(ws, "", "----------", ITEMDRAW_DISABLED);
	AddMenuItem(ws, "1", "Team Based");
	AddMenuItem(ws, "7777", "Blue");
	AddMenuItem(ws, "933333", "Light Blue")
	AddMenuItem(ws, "8421376", "Yellow");
	AddMenuItem(ws, "4552221", "Corrupted Green");
	AddMenuItem(ws, "3100495", "Dark Green");
	AddMenuItem(ws, "51234123", "Lime");
	AddMenuItem(ws, "5322826", "Brown");
	AddMenuItem(ws, "8355220", "Oak Tree Brown");
	AddMenuItem(ws, "13595446", "Flames");
	AddMenuItem(ws, "8208497", "Cream");
	AddMenuItem(ws, "41234123", "Pink");
	AddMenuItem(ws, "300000", "Satan's Blue");
	AddMenuItem(ws, "2", "Purple");
	AddMenuItem(ws, "3", "4 8 15 16 23 42");
	AddMenuItem(ws, "83552", "Ghost In The Machine");
	AddMenuItem(ws, "9335510", "Holy Flame");

	DisplayMenu(ws, client, MENU_TIME_FOREVER);
}

public FootStepsCALLBACK(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_End) CloseHandle(menu);

	if(action == MenuAction_Select) // Js41637 idea
    { 
        decl String:info[12]; 
        decl String:infodesc[36]; 
        GetMenuItem(menu, param2, info, sizeof(info), _, infodesc, sizeof(infodesc));
 
        new Float:weapon_glow = StringToFloat(info); 
        FootprintID[client] = weapon_glow 
        if(weapon_glow == 0.0) 
        { 
            TF2Attrib_RemoveByName(client, "SPELL: set Halloween footstep type");
            CPrintToChat(client, "[SM] Removed Halloween Effects"); 
        } 
        else 
        { 
            TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", weapon_glow);
            CPrintToChat(client, "[SM] Applied Halloween Effect: {haunted}%s", infodesc);
        } 
    }  
}

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	return IsClientInGame(iClient);
}
