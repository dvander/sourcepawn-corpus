#include <sourcemod>
//#include <tf2>
#include <tf2_stocks>
#include <sdktools_gamerules>
#include <sdkhooks>
#include <morecolors>

#pragma semicolon			1
#pragma newdecls			required

#define PLUGIN_VERSION			"1.0"
#define MAX				MAXPLAYERS+1 //66

public Plugin myinfo = 
{
	name 			= "be a spectating General!",
	author 			= "nergal/assyrian",
	description 		= "Allows specs to be a general for either red or blu!",
	version 		= PLUGIN_VERSION,
	url 			= "hue" //will fill later
}

char charAnnotateCmds[][] = {	//PROPS TO FLAMIN' SARGE
	"Attack Here!",
	"Defend Here!",
	"Fall Back to Here!",
	"Camp Here",
	"Deploy Sentry Here!",
	"Deploy Dispenser Here!",
	"Deploy Teleporter Here!",
};


//const int RedTeam = 2;
//const int BluTeam = 3;

ConVar bEnabled = null;
ConVar bAllowSee = null;
ConVar flAnnoteLife = null;
ConVar RedLimit = null;
ConVar BluLimit = null;
ConVar AdminFlagByPass = null;
ConVar HUDX = null;
ConVar HUDY = null;
ConVar Announcer = null;
Handle hHudText;

enum
{
	IsGen = 0,
	LeadingTeam
};

any General[MAX][2];

#define int(%1)		view_as<int>(%1)
#define float(%1)		view_as<float>(%1)
#define bool(%1)		view_as<bool>(%1)
#define view-%1(%2)	view_as<%1>(%2)

methodmap Commander
{
	public Commander(int userid) //constructor: It's less of a headache to use userids
	{
		if ( IsValidClient( userid ) ) {
			return view-Commander( GetClientUserId( userid ) );
		}
		return view-Commander(-1);
	}

	property int index
	{
		public get()			{ return GetClientOfUserId( int(this) ); }
	}
	property bool bIsGeneral
	{
		public get()			{ return General[ this.index ][ IsGen ]; }
		public set( bool booler )	{ General[ this.index ][ IsGen ] = booler; }
	}
	property int iLeadingTeam
	{
		public get()			{ return General[ this.index ][ LeadingTeam ]; }
		public set( int setint )	{ General[ this.index ][ LeadingTeam ] = setint; }
	}
};

public void OnPluginStart()
{
	//RegConsoleCmd("sm_", functionpointer);
	//RegAdminCmd("sm_", functionpointer, ADMFLAG_KICK);
	RegConsoleCmd("sm_commander", Toggler);
	RegConsoleCmd("sm_general", Toggler);
	RegConsoleCmd("sm_command", CustomCommand);
	RegAdminCmd("sm_annote", DoAdminAnnote, ADMFLAG_KICK);

	bEnabled = CreateConVar("sm_armgeneral_enabled", "1", "Enable the ArmChair General plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	bAllowSee = CreateConVar("sm_armgeneral_seeallannotes", "0", "Allows Generals to see other General's, of the same leading team, annotations", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	flAnnoteLife = CreateConVar("sm_armgeneral_annotelife", "8.0", "How long Annotations can 'live' for", FCVAR_PLUGIN, true, 0.1, true, 9990.0);
	RedLimit = CreateConVar("sm_armgeneral_redlimit", "3", "How many Generals RED Team can have", FCVAR_PLUGIN, true, 0.0, true, 16.0);
	BluLimit = CreateConVar("sm_armgeneral_blulimit", "3", "How many Generals BLU Team can have", FCVAR_PLUGIN, true, 0.0, true, 16.0);
	AdminFlagByPass = CreateConVar("sm_armgeneral_adminflagbypass", "a", "what flag admins require to bypass the Generals limit", FCVAR_PLUGIN);
	HUDX = CreateConVar("sm_armgeneral_hudx", "-0.05", "x coordinate for the General HUD", FCVAR_PLUGIN);
	HUDY = CreateConVar("sm_armgeneral_hudy", "-1.0", "y coordinate for the General HUD", FCVAR_PLUGIN);
	Announcer = CreateConVar("sm_armgeneral_adverttime", "90.0", "how long in seconds for the advertisement to pop up", FCVAR_PLUGIN);

	hHudText = CreateHudSynchronizer();

	AutoExecConfig(true, "ArmChairGenerals");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		OnClientPutInServer(i);
	}
	CreateTimer(Announcer.FloatValue, Announcement, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, OnPreThink);

	Commander officer = Commander(client);
	officer.bIsGeneral = false; //bIsGeneral[client] = false;
	officer.iLeadingTeam = -1; //iLeadingTeam[client] = -1;
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);

	Commander officer = Commander(client);
	officer.bIsGeneral = false;
	officer.iLeadingTeam = -1;
}
public Action Announcement(Handle timer)
{
	if ( bEnabled.BoolValue ) {
		CPrintToChatAll("{green}[ArmChairGenerals]{default} To be a Commanding Officer (or not), use !general or !commander");
	}
	return Plugin_Continue;
}
public Action Toggler(int client, int args)
{
	if (bEnabled.BoolValue)
	{
		if (IsClientInGame(client))
		{
			Commander officer = Commander(client);
			if (officer.bIsGeneral)
			{
				officer.bIsGeneral = false;
				CPrintToChat(client, "{green}[ArmChairGenerals]{default} You're Relieved of Duty!");
			}
			else
			{
				if ( GetClientTeam(client) == int(TFTeam_Spectator) )
				{
					Menu pickteam = new Menu(MenuHandler_PickTeam);
					pickteam.SetTitle( "Pick a Team to Lead!", officer.iLeadingTeam );
					pickteam.AddItem("ammop", "RED Team");
					pickteam.AddItem("ammop", "BLU Team");
					pickteam.Display(client, MENU_TIME_FOREVER);
				}
				else
				{
					CPrintToChat(client, "{green}[ArmChairGenerals]{default} This command can only be used as a Spectator");
					return Plugin_Handled;
				}
			}
		}
		else
		{
			CPrintToChat(client, "{green}[ArmChairGenerals]{default} This command can only be used in-game as Spectator");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}
public Action BeCadet(int client, int args)
{
	if (bEnabled.BoolValue)
	{
		if (IsClientInGame(client))
		{
			Commander officer = Commander(client);
			if (GetClientTeam(client) == int(TFTeam_Spectator))
			{
				Menu pickteam = new Menu(MenuHandler_PickTeam);
				pickteam.SetTitle( "Pick a Team to Lead!", officer.iLeadingTeam );
				pickteam.AddItem("ammop", "RED Team");
				pickteam.AddItem("ammop", "BLU Team");
				pickteam.Display(client, MENU_TIME_FOREVER);
			}
			else
			{
				CPrintToChat(client, "{green}[ArmChairGenerals]{default} This command can only be used as a Spectator");
				return Plugin_Handled;
			}
		}
		else
		{
			CPrintToChat(client, "{green}[ArmChairGenerals]{default} This command can only be used in-game as Spectator");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}
public int MenuHandler_PickTeam(Menu menu, MenuAction action, int client, int select)
{
	char info2[32]; menu.GetItem(select, info2, sizeof(info2));
	if (action == MenuAction_Select)
        {
		Commander officer = Commander(client);
		officer.iLeadingTeam = select+2;
		BecomeNCO(client);
	}
	else if (action == MenuAction_End) delete menu;
}
public Action GetOffGeneral(int client, int args)
{
	if (IsClientInGame(client))
	{
		Commander officer = Commander(client);
		if (officer.bIsGeneral)
		{
			officer.bIsGeneral = false;
			CPrintToChat(client, "{green}[ArmChairGenerals]{default} You're Relieved of Duty!");
		}
		else CPrintToChat(client, "{green}[ArmChairGenerals]{default} You're already off-duty!");
	}
	else
	{
		CPrintToChat(client, "{green}[ArmChairGenerals]{default} This command can only be used in-game.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public void BecomeNCO(int client)
{
	if ( !bEnabled.BoolValue || !IsValidClient(client) ) return;

	int GeneralLimit, iCount = 0;
	char teamname[4];

	Commander officer = Commander(client);
	switch ( officer.iLeadingTeam )
	{
		case 2:
		{
			GeneralLimit = RedLimit.IntValue;
			teamname = "RED";
		}
		case 3:
		{
			GeneralLimit = BluLimit.IntValue;
			teamname = "BLU";
		}
	}

	if (GeneralLimit == -1)
	{
		officer.bIsGeneral = true;
		CPrintToChat(client, "{green}[ArmChairGenerals]{default} You are now a Commanding Officer for %s Team", teamname);
		return;
	}
	else if (GeneralLimit == 0)
	{
		if (IsImmune(client))
		{
			officer.bIsGeneral = true;
			CPrintToChat(client, "{green}[ArmChairGenerals]{default} You are now a Commanding Officer for %s Team", teamname);
		}
		else CPrintToChat(client, "{green}[ArmChairGenerals]{default} **** Commanding Officers are Blocked for that Team ****");
		return;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if ( IsValidClient(i) )
		{
			Commander nco = Commander(i);
			if (GetClientTeam(i) == int(TFTeam_Spectator) && nco.bIsGeneral && i != client)
			{
				iCount++;
			}
		}
	}
	if (iCount < GeneralLimit)
	{
		officer.bIsGeneral = true;
		CPrintToChat(client, "{green}[ArmChairGenerals]{default} You are now a Commanding Officer for %s Team", teamname);
	}
	else if (iCount >= GeneralLimit)
	{
		if (IsImmune(client))
		{
			officer.bIsGeneral = true;
			CPrintToChat(client, "{green}[ArmChairGenerals]{default} You are now a Commanding Officer for %s Team", teamname);
		}
		else CPrintToChat(client, "{green}[ArmChairGenerals]{default} **** Commanding Officer Limit is Reached for this Team ****");
	}
	return;
}
public bool IsImmune(int iClient)
{
	if (!IsValidClient(iClient, false)) return false;
	char sFlags[32]; AdminFlagByPass.GetString(sFlags, sizeof(sFlags));

	// If flags are specified and client has generic or root flag, client is immune
	return !StrEqual(sFlags, "") && GetUserFlagBits(iClient) & (ReadFlagString(sFlags)|ADMFLAG_ROOT);
}
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if ( (0 < client && client <= MaxClients) && GetClientTeam(client) == int(TFTeam_Spectator) )
	{
		Commander officer = Commander(client);
		if (!officer.bIsGeneral) {
			return Plugin_Continue;
		}
		static bool bInReload;
		if ( (buttons & IN_RELOAD) && !bInReload ) bInReload = true;

		else if ( !(buttons & IN_RELOAD) && bInReload )
		{
			AnnoteMenu(officer);
			bInReload = false;
		}
	}
	return Plugin_Continue;
}
public void AnnoteMenu(Commander cadet)
{
	Menu tierone = new Menu(MenuHandler_Annotate);
	char teamname[4];
	switch (cadet.iLeadingTeam)
	{
		case 2: teamname = "RED";
		case 3: teamname = "BLU";
	}
	tierone.SetTitle( "Command your Team: %s; Look @ a spot and Select a Command", teamname );
	for (int i = 0; i < sizeof(charAnnotateCmds); i++) //multidimensional array
	{
		tierone.AddItem("ammop", charAnnotateCmds[i]);
	}
	tierone.AddItem("ammop", "to make a custom command, type /command 'your message' ");
	tierone.Display(cadet.index, MENU_TIME_FOREVER);
}
public int MenuHandler_Annotate(Menu menu, MenuAction action, int client, int select)
{
	char info1[32];
        menu.GetItem(select, info1, sizeof(info1));
	if (action == MenuAction_Select)
        {
		Commander officer = Commander(client);
		switch (select)
		{ //for the first 4 cases, have it message the annotation to everybody. For the rest, annote the building messages to engineers only.
			case 0, 1, 2, 3: MakeAnnote(client, charAnnotateCmds[select], flAnnoteLife.FloatValue, FilterPlayers(officer, true, TFClass_Unknown));
			case 4, 5, 6: MakeAnnote(client, charAnnotateCmds[select], flAnnoteLife.FloatValue, FilterPlayers(officer, true, TFClass_Engineer));
		}
	}
	else if (action == MenuAction_End) delete menu;
}
public void OnPreThink(int client) //powers the HUD
{
	if (IsValidClient(client) && GetClientTeam(client) == int(TFTeam_Spectator))
	{
		Commander officer = Commander(client);
		if (!officer.bIsGeneral) {
			return;
		}

		if ( !(GetClientButtons(client) & IN_SCORE) )
		{
			GeneralHUD(officer, HUDX.FloatValue, HUDY.FloatValue);
		}
	}
	return;
}
public void GeneralHUD(Commander marshall, float x, float y) //ATTEEEEEEEEEEN HUT!
{
	if (GameRules_GetRoundState() > RoundState_Pregame)
	{
		SetHudTextParams(x, y, 1.0, 255, 255, 255, 200);
		int classcount[9] = {0, ...};
		int deadcount = 0;
		char charHUD[200];
		for (int i = 1; i <= MaxClients; i++)
		{
			if ( !IsValidClient(i) || GetClientTeam(i) != marshall.iLeadingTeam ) continue;

			int playerclass = int( TF2_GetPlayerClass(i) );
			if (playerclass > 0) classcount[playerclass-1]++;
			if ( !IsPlayerAlive(i) ) deadcount++;
		}
		char teamname[4];
		switch (marshall.iLeadingTeam)
		{
			case 2: teamname = "RED";
			case 3: teamname = "BLU";
		}
		Format(charHUD, sizeof(charHUD), "Team: %s\nScouts: %i\nSoldiers: %i\nPyros: %i\nDemomen: %i\nHeavies: %i\nEngies: %i\nMedics: %i\nSnipers: %i\nSpies: %i\n\nDead Players: %i\n Press RELOAD\nto Send Commands\nto your Team", teamname, classcount[0], classcount[2], classcount[6], classcount[3], classcount[5], classcount[8], classcount[4], classcount[1], classcount[7], deadcount);

		ShowSyncHudText(marshall.index, hHudText, "%s", charHUD);
	}
}

stock void MakeAnnote(int client, char[] szAnnoteMSG, float life, int BitField)
{
	if (IsValidClient(client))
	{
		float flWorldPos[3]; SetClientEyePos(client, flWorldPos);

		Event event = CreateEvent("show_annotation");
		if (event == null) return;

		event.SetFloat("worldPosX", flWorldPos[0]);
		event.SetFloat("worldPosY", flWorldPos[1]);
		event.SetFloat("worldPosZ", flWorldPos[2]);
		event.SetFloat("lifetime", life);

		if (GetClientAimTarget(client) > 0) event.SetInt("follow_entindex", GetClientAimTarget(client));
		event.SetInt("id", client*GetRandomInt(3, 6)); /*this prevents spam as much as possible while allowing multiple annotes*/
		event.SetString("text", szAnnoteMSG);
		event.SetString("play_sound", "vo/null.wav"); //fuck sound, could easily be spammed from trolls.
		event.SetInt("visibilityBitfield", BitField);
		event.Fire();
	}
	return;
}
public bool SetClientEyePos(int client, float flResult[3])
{
	float vAngles[3], vOrigin[3], vBuffer[3], vStart[3];
	float Distance;
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for annote
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if ( TR_DidHit() )
	{
   	 	TR_GetEndPosition(vStart);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		flResult[0] = vStart[0] + (vBuffer[0]*Distance);
		flResult[1] = vStart[1] + (vBuffer[1]*Distance);
		flResult[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else return false;
	return true;
}
public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}
/*stock int BuildBitString(int client, int team) //props to ol' friagram
{
	int bitstring;
	for (int i = 1; i <= MaxClients; i++)
	{
		if ( IsClientInGame(i) &&
			(GetClientTeam(i) == CGeneral[client].iLeadingTeam
				|| i == client
				|| (bAllowSee.BoolValue
				&& GetClientTeam(i) == GetClientTeam(client)
				&& CGeneral[i].iLeadingTeam == CGeneral[client].iLeadingTeam)) ) //holy shit
		{
			bitstring |= 1 << i;
		}
	}
	return bitstring;
}*/
public int FilterPlayers(Commander corporal, bool TeamOnly, TFClassType tfclass)
{
	int bitstring;
	Commander ncofficer;
	if (TeamOnly)
	{
		static bool FilterAllow[MAX];
		for (int i = 1; i <= MaxClients; i++)
		{
			if ( !IsValidClient(i) ) continue;
			ncofficer = Commander(i);
			FilterAllow[i] = false;

			if ( !tfclass && GetClientTeam(i) == corporal.iLeadingTeam) FilterAllow[i] = true;

			else if (tfclass && TF2_GetPlayerClass(i) == tfclass && GetClientTeam(i) == corporal.iLeadingTeam)
			{
				FilterAllow[i] = true;
			}
			else if (i == corporal.index) FilterAllow[i] = true;

			else if (bAllowSee.BoolValue && GetClientTeam(i) == GetClientTeam(corporal.index) && ncofficer.iLeadingTeam == corporal.iLeadingTeam) FilterAllow[i] = true;

			if (FilterAllow[i]) bitstring |= 1 << i;
		}
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if ( IsValidClient(i) ) bitstring |= 1 << i;
		}
	}
	return bitstring;
}
public Action CustomCommand(int client, int args)
{
	if (bEnabled.BoolValue)
	{
		if (args < 1)
		{
			ReplyToCommand(client, "You SNAFU'd Majorly");
			return Plugin_Handled;
		}
		char chArg[128]; GetCmdArgString(chArg, sizeof(chArg));
		Commander officer = Commander(client);
		MakeAnnote(officer.index, chArg, flAnnoteLife.FloatValue, FilterPlayers(officer, true, TFClass_Unknown));
	}
	return Plugin_Continue;
}
public Action DoAdminAnnote(int client, int args)
{
	if (bEnabled.BoolValue)
	{
		if (args < 1)
		{
			ReplyToCommand(client, "You SNAFU'd Majorly");
			return Plugin_Handled;
		}
		char chArg[128]; GetCmdArgString(chArg, sizeof(chArg));
		Commander administrate = Commander(client);
		AdminAnnote(client, chArg, FilterPlayers(administrate, false, TFClass_Unknown));
	}
	return Plugin_Continue;
}
public void AdminAnnote(int client, char[] chAnnoteMessage, int BitField)
{
	if (IsValidClient(client))
	{
		float flWorldPos[3]; SetClientEyePos(client, flWorldPos);

		Event event = CreateEvent("show_annotation");
		if ( !event ) return;

		event.SetFloat("worldPosX", flWorldPos[0]);
		event.SetFloat("worldPosY", flWorldPos[1]);
		event.SetFloat("worldPosZ", flWorldPos[2]);
		event.SetFloat("lifetime", flAnnoteLife.FloatValue*GetRandomFloat(1.1, 2.0));
		if (GetClientAimTarget(client) > 0) event.SetInt("follow_entindex", GetClientAimTarget(client));

		event.SetInt("id", client);
		event.SetString("text", chAnnoteMessage);
		event.SetString("play_sound", "vo/null.wav"); //fuck sound, could easily be spammed from trolls.
		event.SetInt("visibilityBitfield", BitField);
		event.Fire();
	}
	return;
}
stock bool IsValidClient(int iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients) return false;
	if (!IsClientInGame(iClient)) return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient))) return false;
	return true;
}
