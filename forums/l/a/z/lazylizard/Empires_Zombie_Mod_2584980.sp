/*
/////////////////////////////////////////////////////////////////////////////////////////////////////
Empires Zombie MOD How to Play

Objective same as before- kill Enemy CV 

NF (AKA ZOMBIES)advantages Zero ticket loss - as using !zme (emp_sv_debug_reviveself in console for now as dev disabled server side binding) can spawn right away on the spot to kill BE
NF disadvantage Zombies cant build anything except eng turrents
NF Has no com so has to defend ""main"" CV spot aka zomibe hive (barrack to change class one its lose you are stuck as is)

BE you got 200 sec or less to have a plan RUSH TANKS and destroy NF CV (only 2 tanks /10 BE player) or MAKE AN amazing base catch ONLY 1/5 BE players CV turrets 
HOWEVER if you die any way / sucide included you will be auto switched to NF (After all you are dead)

TO active plugin !zombiemod will start a vote any time in game perfer to do it like !tankwars at start of map
then paly as normal except using !zme for NF (right now you will have to open console and paste emp_sv_debug_reviveself only once and press up arrow ever time you die as bind is disabled.  )

Open console by going to 1) options 2) multiplayer 3) tick enable console 4) press ` same button as ~ (shiftmode)

DONT FORGET TO HAVE FUN!!!!!!
!@zy(!z@r!) = Lazylizard

Future plans to intergate zombie models only if you love me :P
/////////////////////////////////////////////////////////////////////////////////////////////////////////
*/



#include <sourcemod>
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>



//Change the following to limit the number of time this kind of vote is called
#define maxVote 2
bool zombieyesno;
int voteTimes;
int Anumber;

new Handle:v_SoundFile1 = INVALID_HANDLE;
new Handle:v_SoundFile2 = INVALID_HANDLE;


public Plugin:myinfo = {
	name = "Zombiemod_addon Client Initialized Voting",
	author = "LazyLizard",
	description = "!zombiemod to enable NF are zombies !zme to use instant self -revive",
	version = "1.7",
	
	
}

public OnPluginStart()
{
	
	HookEvent("player_death", death);
	HookEvent("vehicle_enter", vehicle_enter_hooking);
	
	v_SoundFile1 = CreateConVar("sm_bhs_soundfile1", "bhs/zvote.mp3", "path/file.ext to sound file");
	v_SoundFile2 = CreateConVar("sm_bhs_soundfile2", "bhs/brains.mp3", "path/file.ext to sound file");
	

	}


public OnMapStart()
{
	voteTimes = 0;
	zombieyesno = false;

	new String:SoundFile1[128]
	GetConVarString(v_SoundFile1, SoundFile1, sizeof(SoundFile1))
	PrecacheSound(SoundFile1,true);
	decl String:SoundFileLong1[192];
	Format(SoundFileLong1, sizeof(SoundFileLong1), "sound/%s", SoundFile1);
	AddFileToDownloadsTable(SoundFileLong1);
	
	new String:SoundFile2[128]
	GetConVarString(v_SoundFile2, SoundFile2, sizeof(SoundFile2))
	PrecacheSound(SoundFile2,true);
	decl String:SoundFileLong2[192];
	Format(SoundFileLong2, sizeof(SoundFileLong2), "sound/%s", SoundFile2);
	AddFileToDownloadsTable(SoundFileLong2);
	
	
}



public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);
	} else if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			
			 PrintToChatAll("\x04 YES is the answer to ZOMBIEEEEEESSS");
			voteTimes = voteTimes+1;
			
			new String:SoundFile[128]
	GetConVarString(v_SoundFile2, SoundFile, sizeof(SoundFile))
	EmitSoundToAll (SoundFile);
	ServerCommand("mp_autoteambalance 0");
ServerCommand("emp_teamswitch_delay 5000");
ServerCommand("emp_sv_respawn_penalty 30");
ServerCommand("emp_sv_kick_commander_nf");
ServerCommand("emp_sv_max_vehicles 2");
ServerCommand("emp_sv_max_turrets 3");
ServerCommand("hostname (:WDT:)Zombiemod_is_on_readup_on_How_to_play_in_group_disscussion");
//int GetClientCount(bool inGameOnly)

		ServerCommand("sv_cheats 1");
		zombieyesno = true;
		return Plugin_Continue;
		}
		else
		{
			PrintToChatAll("\x04 Vote has failed. YOU fools voted no!!! How dare you The undead cannot rise");
			voteTimes = voteTimes+1;
			
			
			ServerCommand("sv_cheats 0");
			zombieyesno = false;
			return Plugin_Continue;
		}
	}
}




public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{

	if (strcmp(sArgs, "!zme", false) == 0)
{
//1 spec 2 nf 3 be 
Anumber = GetClientTeam(client);
if (Anumber == 1)
{
PrintToChat(client, "\x04 Cannot use [!zme] You are not undead!! Well you are technical a Ghost");
//PrintToChatAll ("Clinet id is %i" , client);
//ChangeClientTeam(client, 2);
}
if (Anumber == 2)
{
PrintToChat(client, "\x04 BRRAAAAAIIIIINNNNSSSS!!!!!! you used self revive you son of an undead");
//PrintToChatAll ("Clinet id is %i" , client);
//ChangeClientTeam(client, 2);
//process  emp_sv_debug_reviveself  using binding or console
}
if (Anumber == 3)
{
PrintToChat(client, "\x04 Cannot use [!zme] You are not undead yet!! Save the Human race.");
//PrintToChatAll ("Clinet id is %i" , client);
//ChangeClientTeam(client, 2);
}
}


	if (strcmp(sArgs, "!zombiemod", false) == 0)
	{
	
if (voteTimes >= maxVote)
    {
		PrintToChat(client, "\x04[Vote-Zombiemod]\x03 There was already an Zombiemod vote.");
		return Plugin_Continue;	
 	}
	
	
	
	ShowActivity2(client, "[SM] ", "\x04 Initiated Vote Zombiemod");
	LogAction(client, -1, "\"%L\" used vote-Zombiemod", client);
	new Handle:menu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(menu, "Zombiemod - BRRAAAAAIIIIINNNNSSSS");
	AddMenuItem(menu, "notsure1", "Yes of course MORE DEAD (ONLY NF use !zme)");
	AddMenuItem(menu, "notsure2", "No i watch vampire diaries and i like sparkles on my man");
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 18);
	new String:SoundFile[128]
	GetConVarString(v_SoundFile1, SoundFile, sizeof(SoundFile))
	EmitSoundToAll (SoundFile);
		
	return Plugin_Continue;

	
}

 
	/* Let say continue normally */
				return Plugin_Continue;
}



//extras ----- -to make it do more

public void vehicle_enter_hooking(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(zombieyesno==true)
	{
	//PrintToChatAll("TRUE11111");	
	ServerCommand("emp_sv_kick_commander_nf");
	//ServerCommand(emp_sv_kick_commander_penalty 15);
	}
	return Plugin_Continue;
}



public void death(Handle:event, const String:name[], bool:dontBroadcast)
{

	if(zombieyesno==true)
	{
		new Vic = GetClientOfUserId(GetEventInt(event, "userid"));
		decl 	String:weapon[32];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		
		if ((strcmp(weapon, "hs_nf_smg1", false) == 0)||		(strcmp(weapon, "nf_smg1", false) == 0)||		(strcmp(weapon, "hs_nf_pistol", false) == 0)||		(strcmp(weapon, "nf_pistol", false) == 0)||		(strcmp(weapon, "hs_nf_smg2", false) == 0)||		(strcmp(weapon, "nf_smg2", false) == 0)||		(strcmp(weapon, "hs_nf_shot_pistol", false) == 0)||		(strcmp(weapon, "nf_shot_pistol", false) == 0)||		(strcmp(weapon, "hs_nf_smg3", false) == 0)||		(strcmp(weapon, "nf_smg3", false) == 0)||		(strcmp(weapon, "hs_nf_shotgun", false) == 0)||		(strcmp(weapon, "nf_shotgun", false) == 0)||		(strcmp(weapon, "hs_nf_rifle", false) == 0)||		(strcmp(weapon, "nf_rifle", false) == 0)||		(strcmp(weapon, "hs_nf_50cal", false) == 0)||		(strcmp(weapon, "nf_50cal", false) == 0)||		(strcmp(weapon, "hs_nf_hmg", false) == 0)||		(strcmp(weapon, "nf_hmg", false) == 0)||		(strcmp(weapon, "nf_rpg_missile", false) == 0)||		(strcmp(weapon, "nf_mine", false) == 0)||		(strcmp(weapon, "emp_shell", false) == 0)||		(strcmp(weapon, "hs_nf_scout_rifle", false) == 0)||		(strcmp(weapon, "nf_scout_rifle", false) == 0)||		(strcmp(weapon, "nf_stickygren", false) == 0)||		(strcmp(weapon, "nf_grenade", false) == 0)){
	ChangeClientTeam(Vic, 2);
	}
	}
	return Plugin_Continue;
}