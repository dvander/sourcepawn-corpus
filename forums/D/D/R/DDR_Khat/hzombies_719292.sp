/*
CHANGELOG
	v1.0.6
	-Patched to work with the "DLC" update
	-Fixed a bug in the voting causing it to break all voting
	-A few more optimizations and alterations of code for efficientcy
	-Fixed a smalll issue with difficulty vote detection
	-Added sanitization checks to callvote.
	-Added support for "survival" mode
	-Silenced "Gamemode" / "Difficulty" changing when applying difficulty
	-Added a "Enabler" that can disable locking until reset (for external plugin support)
	v1.0.5
	-Fixed a bug which caused server to lock to co-op.
	-More optimizations and removing of redundant code.
	-Fixed difficulty string comparison.
	-Difficulty is now available for voting.
	-Added CVAR for disability difficulty vote. (Do not recommend this..)
	-Added command to check difficulty (and give basic info on damage level) !diff
	v1.0.4
	-Further coding optimizations.
	-Implemented a "Disable" on both CVARS. (-1 for human_zombies , NA for difficulty)
	-Difficulty should only require one change now.
	-Fixed potential freezing (and crashing) of server during a map change.
	-Fixed Lobby difficulty locking.
	v1.0.3
	-Fixed another if branch using old CVAR Logic
	-Fixed variable loading order, now is gracious of server.cfg (and other cfg files)
	v1.0.2
	-Fixed a bug which did not enforce difficulty change when using CFG files.
	-Fixed a if branch statement using the old CVAR logic (0 allow, 1 disallow)
	-Fixed a mistake which would force VS mode even in CO-OP.
	v1.0.1
	-Change of l4d_human_zombies to make it seem logical (0 = disallow, 1 = allow)
	-Added l4d_difficulty for forcing of difficulty (Easy, Normal, Hard, Impossible) Works in VS also.
	v1.0
	-Initial Release
CREDITS
	DDRKhat
	-Author of plugin
	Gu¿r–i¿Ò & Limewire
	-Testing of difficulty to ensure it was truly set and not faked
	bug
	-bugtesting
	Sammy-ROCK! + Fyren
	-Finding the CVAR which locked difficulty when joining via lobby
	Solleck
	-Swiftly helping me test the newly discovered CVAR
	Tsunami
	-Helping with the "difficulty sorter"
	Dirty`Dave
	-Providing a server with the game-mode bug fixed in 1.0.5
	Predcrab
	-Answering and supplying info to several questions and situations I had	
*/
#include <sourcemod>

#define PLUGIN_VERSION 		"1.0.6"
#define CVAR_FLAGS 		FCVAR_PLUGIN
new Handle:g_hzombies		= INVALID_HANDLE;
new Handle:g_huzombies		= INVALID_HANDLE;
new Handle:g_difficulty		= INVALID_HANDLE;
new Handle:g_hdifficulty	= INVALID_HANDLE;
new Handle:g_fulobby		= INVALID_HANDLE;
new Handle:g_votediff		= INVALID_HANDLE;
new Handle:VoteTimer		= INVALID_HANDLE;
new Handle:g_enable			= INVALID_HANDLE;

new isexecuting;
new yesvotes;
new novotes;
new voters[8];
new canvote = 1;
new MAX_VOTES
new String:difficulty[64]	= "Normal";
new String:gmode[64]			= "versus";
new String:cancel[64]		= "NA";
new String:voted[64] = "";
new String:votetitle[64] = "";
new String:hzombies[64];

public Plugin:myinfo =
{
	name = "L4D Director Enforcer",
	author = "DDRKhat",
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
	g_votediff = CreateConVar("l4dde_votedifficulty","1","<0/1> (Dis)Allow voting the difficulty (Versus mode only)",CVAR_FLAGS);
	g_enable = CreateConVar("l4dde_enable","1","<0/1> Disable will stop locking / Enable will enforce and lock CVARS",CVAR_FLAGS);
	g_huzombies = CreateConVar("l4dde_gamemode","NA","Force the director to take on a gamemode",CVAR_FLAGS);
	g_hdifficulty = CreateConVar("l4dde_difficulty","NA","Force the game difficulty NA to disable (Easy, Normal, Hard, Impossible)",CVAR_FLAGS);
	HookConVarChange(g_hzombies, ConVarChange_hzombies);
	HookConVarChange(g_huzombies, ConVarChange_hzombies);
	HookConVarChange(g_difficulty, ConVarChange_difficulty);
	HookConVarChange(g_hdifficulty, ConVarChange_difficulty);
	HookConVarChange(g_fulobby, ConVarChange_fulobby);
	HookConVarChange(g_enable, ConVarChange_enable);
	RegConsoleCmd("callvote",Callvote_Handler);
	RegConsoleCmd("Vote",vote);
	RegConsoleCmd("diff",itis);
	AutoExecConfig(true, "hzombies");
}
public OnMapStart()
{
	SetConVarInt(g_enable,1)
}

public OnMapEnd()
{
	SetConVarString(g_huzombies,cancel);
	SetConVarString(g_hdifficulty,cancel);
}	

public ConVarChange_fulobby(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(g_fulobby)!=0) SetConVarInt(g_fulobby,0);
}

public ConVarChange_enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(g_enable)>1) SetConVarInt(g_enable,1);
	if(GetConVarInt(g_enable)<0) SetConVarInt(g_enable,0);
	if(GetConVarInt(g_enable)==1) {SetConVarString(g_hzombies,gmode);SetConVarString(g_difficulty,difficulty);}
}

public ConVarChange_hzombies(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(g_enable)==0) return;
	SetConVarFlags(g_hzombies, GetConVarFlags(g_hzombies) & ~FCVAR_NOTIFY);
	new String:fgmode[64];
	GetConVarString(g_hzombies,gmode,sizeof(gmode));
	GetConVarString(g_huzombies,fgmode,sizeof(fgmode))
	if(strncmp(fgmode,cancel,sizeof(fgmode),false)==0) return;
	if(gmode[0]!=fgmode[0]) SetConVarString(g_hzombies,fgmode[0])
}

public ConVarChange_difficulty(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(g_enable)==0) return;
	SetConVarFlags(g_difficulty, GetConVarFlags(g_difficulty) & ~FCVAR_NOTIFY|FCVAR_REPLICATED);
	GetConVarString(g_hdifficulty,difficulty,sizeof(difficulty));
	if(!isexecuting) GetConVarString(g_huzombies,hzombies,sizeof(hzombies));
	if(strncmp(difficulty,cancel,sizeof(difficulty),false)==0) return;
	difficulty[0] = diff(difficulty);
	SetConVarString(g_huzombies,"coop");
	isexecuting=1;
	SetConVarString(g_difficulty,difficulty);
	SetConVarString(g_huzombies,hzombies);
	if(strncmp(hzombies,cancel,sizeof(hzombies),false)==0) SetConVarString(g_hzombies,"versus");
	isexecuting=0;
	SetConVarFlags(g_difficulty, GetConVarFlags(g_difficulty) | FCVAR_NOTIFY|FCVAR_REPLICATED);
}

diff(String:diffis[])
{
	if(strncmp(diffis,"easy",128,false)==0) strcopy(diffis,128,"Easy")
	else if(strncmp(diffis,"hard",128,false)==0) strcopy(diffis,128,"Hard")
	else if(strncmp(diffis,"advanced",128,false)==0) strcopy(diffis,128,"Hard")
	else if(strncmp(diffis,"impossible",128,false)==0) strcopy(diffis,128,"Impossible")
	else if(strncmp(diffis,"expert",128,false)==0) strcopy(diffis,128,"Impossible")
	else if(strncmp(diffis,"na",128,false)==0) strcopy(diffis,128,"NA")
	else strcopy(diffis,128,"Normal") // If we set it to something which can cause a error!
	return diffis[0];
}

namediff()
{
	if(strncmp(voted,"Easy",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Easy")
	else if(strncmp(voted,"Hard",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Advanced")
	else if(strncmp(voted,"Impossible",sizeof(voted),false)==0) strcopy(voted,sizeof(voted),"Expert")
	else strcopy(voted,sizeof(voted),"Normal") // If we set it to something which can cause a error!
}

Players()
{
	new connectedplayers;
	for(new i=1;i<GetMaxClients();i++) if(IsClientConnected(i)&&!IsFakeClient(i)) connectedplayers++;
	return connectedplayers;
}

public Action:Callvote_Handler(client, args)
{	
	new String:arg[2][16];
	GetCmdArg(1,arg[0],16);
	GetCmdArg(2,arg[1],16);
	if(StrContains(arg[0],"ChangeDifficult",false)>=0&&strncmp(gmode,"coop",sizeof(gmode),false)!=0&&GetConVarInt(g_votediff)==1&&canvote==1)
	{
		new Handle:msg = CreateEvent("vote_started");
		voted = arg[1];
		voted[0] = diff(voted);
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
		yesvotes = 0;
		novotes = 0;
		canvote = 0;
		UpdateVotes();
		VoteTimer = CreateTimer(20.0,TimerHandle,1);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public UpdateVotes()
{
	if(StrContains(votetitle,"Difficulty",false)>=0&&strncmp(gmode,"coop",sizeof(gmode),false)!=0&&GetConVarInt(g_votediff)==1)
	{
		new Handle:msg = CreateEvent("vote_changed");
		SetEventInt(msg,"yesVotes",yesvotes);
		SetEventInt(msg,"noVotes",novotes);
		SetEventInt(msg,"potentialVotes",MAX_VOTES);
		FireEvent(msg);
		if (yesvotes+novotes == MAX_VOTES) EndVote();
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
	CreateTimer(40.0,TimerHandle,2);
	new Handle:msg = CreateEvent("vote_ended");
	FireEvent(msg);
	if (yesvotes > novotes)
	{
		new String:result[64] = "Difficulty changed to ";
		StrCat(result,64,voted);
		msg = CreateEvent("vote_passed");
		SetEventString(msg,"details","#L4D_TargetID_Player");
		SetEventString(msg,"param1",result);
		voted[0] = diff(voted);
		SetConVarFlags(g_difficulty, GetConVarFlags(g_difficulty) & ~FCVAR_NOTIFY|FCVAR_REPLICATED);
		SetConVarString(g_hdifficulty,voted);
		SetConVarFlags(g_difficulty, GetConVarFlags(g_difficulty) | FCVAR_NOTIFY|FCVAR_REPLICATED);
	}
	else msg = CreateEvent("vote_failed");
	SetEventInt(msg,"team",0);
	for (new i=0; i<MAX_VOTES; i++) voters[i]=0;
	FireEvent(msg);
}
public Action:vote(client, args)
{
	if(StrContains(votetitle,"Difficulty",false)>=0&&strncmp(gmode,"coop",sizeof(gmode),false)!=0&&GetConVarInt(g_votediff)==1)
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