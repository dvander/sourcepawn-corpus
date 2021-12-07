/*
FOR UNIVERSAL VANILLA SERVERS
	
	(ps: plugin does not fit those servers who wanna lock them in specific gamemode with restricted callvotes)
	
FEATURES
	
	Primary:
	-on "callvote" for any mission ingame (hospital,hospital_vs,farm,farm_vs,smalltown,smalltown_vs,airport,airport_vs,lighthouse)
	 "mp_gamemode" fits the map depends on mission u choose
	 
	-anybody can start vote for any difficulty at any time in any gamemode : survival and versus (coop allowed by default)
	
	Secondary:	
	-unlocked "callvote" for other missions while trapped in survival mode (since latest vavle L4D update 1.0.1.2 while in survival mode 
	 its impossible to callvote for any missions like it was before DLC)
	-any wrong votes using changedifficulty launch vote for Normal difficulty
	-any wrong votes using changemission while in survival mode launch vote for Lighthouse mission
	-no config file needed (user friendly)

	From original version:
	
	- type !diff or /diff in chat to know current difficulty or z_difficulty in console (standart feature)
	
USAGE

	Ingame console examples:  
	-callvote changemission "smalltown_vs" for versus
	-callvote changemission "airport" for coop
	-callvote changemission "lighthouse" for survival
	-callvote changedifficulty "hard" or "ImposSible" or "HARD" or "AdVaNcEd"
	
DATE
	
	Plugin was finished in 3 days  25.04.2009 at 3:00AM GMT +2
	Final tests are accomplished and all features works stable
	
CREDITS
	
	DDRKhat
	-Author of plugin

	AcidTester
	-Modification
	
	Cheers going to all ppl who take part in this plugin before me and to those ppl which parts of codes of many plugins i've injected and modified.

TESTERS

	AcidTester
	Random ppl who joined server
	
TODO

	Improve voters count mechanism	
	
*/
#include <sourcemod>

#define PLUGIN_VERSION 		"1.0.5 Mod"
#define MAX_LINE_WIDTH 64
#define CVAR_FLAGS 		FCVAR_PLUGIN
new Handle:g_hzombies		= INVALID_HANDLE;
new Handle:g_huzombies		= INVALID_HANDLE;
new Handle:g_difficulty		= INVALID_HANDLE;
new Handle:g_hdifficulty	= INVALID_HANDLE;
new Handle:g_mission		= INVALID_HANDLE;
new Handle:g_fulobby		= INVALID_HANDLE;
new Handle:g_votediff		= INVALID_HANDLE;
new Handle:VoteTimer		= INVALID_HANDLE;

new yesvotes;
new novotes;
new voters[8];
new canvote = 1;
new MAX_VOTES
new String:difficulty[64]	= "Normal";
new String:cancel[64]		= "NA";
new String:voted[64] = "";
new String:votetitle[64] = "";
new String:gmode[64] = "";
new String:mission[64] = "";
new bool:IsMapVS;
new bool:IsMapSV;
new bool:IsSurvival;

public Plugin:myinfo =
{
	name = "L4D Director Enforcer",
	author = "DDRKhat&AcidTester",
	description = "Enforce director variables",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_hzombies_version", PLUGIN_VERSION, "L4D Director Enforcer version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hzombies = FindConVar("mp_gamemode");
	g_difficulty = FindConVar("z_difficulty");
	g_fulobby = FindConVar("z_difficulty_locked");
	g_votediff = CreateConVar("l4d_votedifficulty","1","<0/1> (Dis)Allow voting the difficulty (Versus mode only)",CVAR_FLAGS);
	g_huzombies = CreateConVar("l4d_human_zombies","-1","Force the director to allow/disallow zombies (-1=disable 0=disallow 1=allow)",CVAR_FLAGS);
	g_mission = CreateConVar("l4d_change_mission","NA","Buffer for mission name storage when we vote some",CVAR_FLAGS);
	g_hdifficulty = CreateConVar("l4d_difficulty","NA","Force the game difficulty NA to disable (Easy, Normal, Hard, Impossible)",CVAR_FLAGS);
	HookConVarChange(g_hzombies, ConVarChange_hzombies);
	HookConVarChange(g_huzombies, ConVarChange_hzombies);
	HookConVarChange(g_difficulty, ConVarChange_difficulty);
	HookConVarChange(g_hdifficulty, ConVarChange_difficulty);
	HookConVarChange(g_mission, ConVarChange_mission);
	HookConVarChange(g_fulobby, ConVarChange_fulobby);
	RegConsoleCmd("callvote",Callvote_Handler);
	RegConsoleCmd("Vote",vote);
	RegConsoleCmd("diff",itis);
	//AutoExecConfig(true, "hzombies");
	HookEvent("round_start", RoundStart, EventHookMode_Post);
}

public OnMapStart()
{
	SetConVarInt(g_huzombies,-1);
	SetConVarString(g_hdifficulty,difficulty);
	IsSurvival = false;	
}

public OnMapEnd()
{
	SetConVarInt(g_huzombies,-1);
	SetConVarString(g_hdifficulty,difficulty);	
}	

public Action:RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	// We determine if map is vs ...
	GetConVarString(g_hzombies,gmode,sizeof(gmode));
	new String:MapName[80];
	GetCurrentMap(MapName, sizeof(MapName));
	if (StrContains(MapName, "_vs_", false) != -1) 
		IsMapVS = true;
	else 
		IsMapVS = false;
	
	// We determine if map is sv ...
	if (StrContains(MapName, "_sv_", false) != -1) 
		IsMapSV = true;
	else
		IsMapSV = false;
	
	// We change gamemode if its not already fits current map.
	if (IsMapVS && StrContains(gmode, "survival", false) == -1)
		SetConVarString(g_hzombies,"versus");
	
	if (IsMapSV)
		SetConVarString(g_hzombies,"survival");
	
	if (!IsMapVS && !IsMapSV && StrContains(gmode, "survival", false) == -1)
		SetConVarString(g_hzombies,"coop");
		
	if (!IsMapVS && !IsMapSV && IsSurvival)
		SetConVarString(g_hzombies,"coop");

	if (IsMapVS && IsSurvival)
		SetConVarString(g_hzombies,"versus");
}

public ConVarChange_fulobby(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(g_fulobby)!=0) SetConVarInt(g_fulobby,0);
}

public ConVarChange_hzombies(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(g_huzombies)==-1) return;
	if(GetConVarInt(g_huzombies)==0) SetConVarString(g_hzombies,"coop");  // 1 coop
	if(GetConVarInt(g_huzombies)==1) SetConVarString(g_hzombies,"versus"); // 0 versus
	if(GetConVarInt(g_huzombies)==2) SetConVarString(g_hzombies,"survival"); 	
}

public ConVarChange_mission(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(g_mission,mission,sizeof(mission));
	GetConVarString(g_hzombies,gmode,sizeof(gmode));
	if(StrContains(gmode, "survival", false) != -1)
	{	 
	miss();
	IsSurvival = true;
	CreateTimer(3.0,TimerDelay);
	}
}

public Action:TimerDelay(Handle:timer)
{
	ServerCommand("changelevel %s", mission);
	SetConVarString(g_mission,"");
}

public ConVarChange_difficulty(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(g_hdifficulty,difficulty,sizeof(difficulty));
	GetConVarString(g_hzombies,gmode,sizeof(gmode));
	if(StrContains(gmode, "versus", false) != -1) {
	if(strncmp(difficulty,cancel,sizeof(difficulty),false)==0) return;
	diff();
	SetConVarInt(g_huzombies,0);
	SetConVarString(g_difficulty,difficulty);
	SetConVarInt(g_huzombies,1);
	GetConVarString(g_hzombies,gmode,sizeof(gmode));
	}
	else if(StrContains(gmode, "survival", false) != -1) {
	if(strncmp(difficulty,cancel,sizeof(difficulty),false)==0) return;
	diff();
	SetConVarInt(g_huzombies,0);
	SetConVarString(g_difficulty,difficulty);
	SetConVarInt(g_huzombies,2);
	GetConVarString(g_hzombies,gmode,sizeof(gmode));
	}	
}

IsClientBot(client)
{
    decl String:SteamID[MAX_LINE_WIDTH];
    GetClientAuthString(client, SteamID, sizeof(SteamID));

    if (StrEqual(SteamID, "BOT"))
        return true;

    return false;
}

public OnClientPostAdminCheck(client)
{
    if (IsClientBot(client))
        return;
}

public OnClientDisconnect(client)
{
    if (IsClientBot(client))
        return;
}

diff()
{
	if(strncmp(difficulty,"easy",sizeof(difficulty),false)==0) strcopy(difficulty,sizeof(difficulty),"Easy")
	else if(strncmp(difficulty,"hard",sizeof(difficulty),false)==0) strcopy(difficulty,sizeof(difficulty),"Hard")
	else if(strncmp(difficulty,"advanced",sizeof(difficulty),false)==0) strcopy(difficulty,sizeof(difficulty),"Hard")
	else if(strncmp(difficulty,"impossible",sizeof(difficulty),false)==0) strcopy(difficulty,sizeof(difficulty),"Impossible")
	else if(strncmp(difficulty,"expert",sizeof(difficulty),false)==0) strcopy(difficulty,sizeof(difficulty),"Impossible")
	else if(strncmp(difficulty,"na",sizeof(difficulty),false)==0) strcopy(difficulty,sizeof(difficulty),"NA")
	else strcopy(difficulty,sizeof(difficulty),"Normal") // If we set it to something which can cause a error!
}

namediff()
{
	if(strncmp(voted,"easy",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Easy")
	else if(strncmp(voted,"hard",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Advanced")
	else if(strncmp(voted,"advanced",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Advanced")
	else if(strncmp(voted,"expert",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Expert")
	else if(strncmp(voted,"impossible",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Expert")
	else strcopy(voted,sizeof(voted),"Normal") // If we set it to something which can cause a error!
}

miss()
{
	if(strncmp(mission,"hospital",sizeof(mission),false)==0) strcopy(mission,sizeof(mission),"l4d_hospital01_apartment")
	else if(strncmp(mission,"smalltown",sizeof(mission),false)==0) strcopy(mission,sizeof(mission),"l4d_smalltown01_caves")
	else if(strncmp(mission,"airport",sizeof(mission),false)==0) strcopy(mission,sizeof(mission),"l4d_airport01_greenhouse")
	else if(strncmp(mission,"farm",sizeof(mission),false)==0) strcopy(mission,sizeof(mission),"l4d_farm01_hilltop")
	else if(strncmp(mission,"hospital_vs",sizeof(mission),false)==0) strcopy(mission,sizeof(mission),"l4d_vs_hospital01_apartment")
	else if(strncmp(mission,"smalltown_vs",sizeof(mission),false)==0) strcopy(mission,sizeof(mission),"l4d_vs_smalltown01_caves")
	else if(strncmp(mission,"airport_vs",sizeof(mission),false)==0) strcopy(mission,sizeof(mission),"l4d_vs_airport01_greenhouse")
	else if(strncmp(mission,"farm_vs",sizeof(mission),false)==0) strcopy(mission,sizeof(mission),"l4d_vs_farm01_hilltop")
	else if(strncmp(mission,"lighthouse",sizeof(mission),false)==0) strcopy(mission,sizeof(mission),"l4d_sv_lighthouse")
	//else return //for test
}

namemiss()
{
	if(strncmp(voted,"hospital",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Hospital")
	else if(strncmp(voted,"farm",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Farm")
	else if(strncmp(voted,"smalltown",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Smalltown")
	else if(strncmp(voted,"airport",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Airport")
	else if(strncmp(voted,"smalltown_vs",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Smalltown_vs")
	else if(strncmp(voted,"airport_vs",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Airport_vs")
	else if(strncmp(voted,"farm_vs",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Farm_vs")
	else if(strncmp(voted,"hospital_vs",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Hospital_vs")
	else strcopy(voted,sizeof(voted),"Lighthouse") // If we set it to something which can cause a error!
}

Players()
{
	new connectedplayers;
	for(new i=1;i<=GetMaxClients();i++) if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && !IsFakeClient(i)) connectedplayers++;
	return connectedplayers;
}

public Action:Callvote_Handler(client, args)
{
	GetConVarString(g_hzombies,gmode,sizeof(gmode));
	for(new i=0; i<MAX_VOTES; i++) voters[i]=0;
	if(canvote==0) return Plugin_Handled;
	new String:arg[2][16];
	GetCmdArg(1,arg[0],16);
	GetCmdArg(2,arg[1],16);
	if(StrContains(arg[0],"changedifficult",true)>=0 && (StrContains(gmode, "versus", false) != -1 || StrContains(gmode, "survival", false) != -1) && GetConVarInt(g_votediff)==1)
	{
		new Handle:msg = CreateEvent("vote_started");
		voted = arg[1];
		namediff();
		strcopy(votetitle,64,"Change difficulty to ");
		StrCat(votetitle,64,voted);
		StrCat(votetitle,64,"?");
		SetEventString(msg,"issue","#L4D_TargetID_Player");
		SetEventString(msg,"param1",votetitle);
		SetEventInt(msg,"team",0);
		SetEventInt(msg,"initiator",0);
		MAX_VOTES = Players();
		FireEvent(msg);
		for(new i=0; i<MAX_VOTES; i++) voters[i]=0;  // 8
		yesvotes = 0;
		novotes = 0;
		canvote = 0;
		UpdateVotes();
		VoteTimer = CreateTimer(10.0,TimerHandle,1);
		return Plugin_Handled;
	}	
	else if(StrContains(arg[0],"changemissio",true)>=0 && StrContains(gmode, "survival", false) != -1)
	{
		new Handle:msg = CreateEvent("vote_started");
		voted = arg[1];
		namemiss();
		strcopy(votetitle,64,"Change mission to ");
		StrCat(votetitle,64,voted);
		StrCat(votetitle,64,"?");
		SetEventString(msg,"issue","#L4D_TargetID_Player");
		SetEventString(msg,"param1",votetitle);
		SetEventInt(msg,"team",0);
		SetEventInt(msg,"initiator",0);
		MAX_VOTES = Players();
		FireEvent(msg);
		for(new i=0; i<MAX_VOTES; i++) voters[i]=0;
		yesvotes = 0;
		novotes = 0;
		canvote = 0;
		UpdateVotes();
		VoteTimer = CreateTimer(10.0,TimerHandle,1);
		return Plugin_Handled;
	}	

	return Plugin_Continue;
}

public UpdateVotes()
{
	if(StrContains(votetitle,"Difficulty",false)>=0 && (StrContains(gmode, "versus", false) != -1 || StrContains(gmode, "survival", false) != -1) && GetConVarInt(g_votediff)==1)
	{
		new Handle:msg = CreateEvent("vote_changed");
		SetEventInt(msg,"yesVotes",yesvotes);
		SetEventInt(msg,"noVotes",novotes);
		SetEventInt(msg,"potentialVotes",MAX_VOTES);
		FireEvent(msg);
		if (yesvotes+novotes == MAX_VOTES) EndVote();
	}
	else if(StrContains(votetitle,"Mission",false)>=0 && StrContains(gmode, "survival", false) != -1)
	{
		new Handle:msg = CreateEvent("vote_changed");
		SetEventInt(msg,"yesVotes",yesvotes);
		SetEventInt(msg,"noVotes",novotes);
		SetEventInt(msg,"potentialVotes",MAX_VOTES);
		FireEvent(msg);
		if (yesvotes+novotes == MAX_VOTES) EndVote2();
	}
}

public Action:TimerHandle(Handle:timer, any:votetype)
{
	if(votetype==1) EndVote();
	if(votetype==2) canvote=1;
}

public EndVote()
{
	KillTimer(VoteTimer);
	CreateTimer(1.0,TimerHandle,2);
	new Handle:msg = CreateEvent("vote_ended");
	FireEvent(msg);
	if (yesvotes > novotes)
	{
		new String:result[64] = "Difficulty changed to ";
		StrCat(result,64,voted);
		msg = CreateEvent("vote_passed");
		SetEventString(msg,"details","#L4D_TargetID_Player");
		SetEventString(msg,"param1",result);
		SetConVarString(g_hdifficulty,voted);
	}
	else msg = CreateEvent("vote_failed");
	SetEventInt(msg,"team",0);
	FireEvent(msg);	
}

public EndVote2()
{
	KillTimer(VoteTimer);
	CreateTimer(1.0,TimerHandle,2);
	new Handle:msg = CreateEvent("vote_ended");
	FireEvent(msg);
	if (yesvotes > novotes)
	{
		new String:result[64] = "Mission changed to ";
		StrCat(result,64,voted);
		msg = CreateEvent("vote_passed");
		SetEventString(msg,"details","#L4D_TargetID_Player");
		SetEventString(msg,"param1",result);
		SetConVarString(g_mission,voted);
	}
	else msg = CreateEvent("vote_failed");
	SetEventInt(msg,"team",0);
	FireEvent(msg);	
}

public Action:vote(client, args)
{
    if(StrContains(votetitle,"Difficulty",false)>=0 && (StrContains(gmode, "versus", false) != -1 || StrContains(gmode, "survival", false) != -1) && GetConVarInt(g_votediff)==1)
    {
        for (new i=0; i<MAX_VOTES; i++) if(voters[i]==client) return Plugin_Handled;
        new String:arg[8];
        GetCmdArg(1,arg,8);
        if (strcmp(arg,"Yes",true) == 0) yesvotes++;
        else if (strcmp(arg,"No",true) == 0) novotes++;
        else return Plugin_Continue
        for (new i=0; i<MAX_VOTES; i++) if (voters[i] == 0) voters[i] = client;
        UpdateVotes();
        return Plugin_Continue;
    }
   	else if(StrContains(votetitle,"Mission",false)>=0 && StrContains(gmode, "survival", false) != -1)
    {
        for (new i=0; i<MAX_VOTES; i++) if(voters[i]==client) return Plugin_Handled;
        new String:arg[8];
        GetCmdArg(1,arg,8);
        if (strcmp(arg,"Yes",true) == 0) yesvotes++;
        else if (strcmp(arg,"No",true) == 0) novotes++;
        else return Plugin_Continue
        for (new i=0; i<MAX_VOTES; i++) if (voters[i] == 0) voters[i] = client;
        UpdateVotes();
        return Plugin_Continue;
    }
    return Plugin_Continue
}

public Action:itis(client, args)
{
	new String:diffis[64];
	new String:message[128];
	new Atk;
	GetConVarString(g_difficulty,diffis,sizeof(diffis));
	if(strncmp(diffis,"Easy",sizeof(diffis),false)==0) {strcopy(diffis,sizeof(diffis),"Easy");Atk=1;}
	else if(strncmp(diffis,"Hard",sizeof(diffis),false)==0) {strcopy(diffis,sizeof(diffis),"Advanced");Atk=5;}
	else if(strncmp(diffis,"Impossible",sizeof(diffis),false)==0) {strcopy(diffis,sizeof(diffis),"Expert");Atk=20;}
	else {strcopy(diffis,sizeof(diffis),"Normal");Atk=2;} // If we set it to something which can cause a error!
	Format(message,sizeof(message),"\x04[L4DDE] Difficulty:\x03 %s \x05(Common Infected do\x03 %i \x05damage)",diffis,Atk);
	PrintToChat(client, message);
	return Plugin_Handled;
}