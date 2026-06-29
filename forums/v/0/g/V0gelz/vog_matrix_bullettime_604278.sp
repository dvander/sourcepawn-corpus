/***************************************************************************
 *  vog_matrix_bullettime.sma
 *   version 1.1          Date: 12/12/2008
 *   Author: Frederik     frederik156@hotmail.com
 *   Alias: V0gelz
 *           
 *  I remember i was playing on a server and suddenly everything slowed down.
 *  and i tought 'now that is cool' and i searched around how he did it.
 *  I found it was just a cvar that the server had to change.
 *  So i tought why not remake my matrix plugin and add some more nice effects to it.
 *
 *
 *  Credits
 *     for the flying bullets:  Bonaparte for this laser tag plugin.
 *		http://forums.alliedmods.net/showthread.php?t=60382
 *     for the sounds:  MBchrono for this matrix script on eventscripts.
 *		http://addons.eventscripts.com/addons/view/mb_matrix
 *  
 *  Admin commands:
 *
 *  sm_matrix_bt		-1/0 this enables matrix bullet time
 *				when it is set to 1 it will
 *				stay untill an admin sets it back to 0.
 *  CVARS:
 *
 *  sm_matrix_bt_vote 1         -enables/disables the player's "vote_bullettime"
 *                              chat command so that only admins can set
 *                              the bt mode.
 *
 *  sm_matrix_bt_vote_delay 180	-time before the bt vote
 *				is allowed after map start. 180 = 3 min.
 *
 *  sm_matrix_bt_vote_int 180   -interval between vote casts. In seconds.
 *				180 = 3 min.
 *
 * For Players:
 *
 *      Say: vote_bullettime    -- sets up a vote
 *
 *
 ***************************************************************************/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

new StartTime;
new LastVote;
new Handle:Vote_Matrix_BT;
new Handle:VoteDelay;
new Handle:VotesInterval;
new Handle:TimeScale;
new enable_tracer;
new precache_laser;

new Handle:hGameConf = INVALID_HANDLE;
new Handle:hGetWeaponPosition = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Matrix Bullet Time Plugin",
	author = "V0gelz",
	description = "Matrix bullet time.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	// Admin commands
	RegAdminCmd("sm_matrix_bt", Command_Matrix_BT, ADMFLAG_VOTE, "Set matrix bullet time mode 1/0");
	RegConsoleCmd("say", Command_OnSay);

	// Time Scale && Remove the cheat flags
	new flags;
	TimeScale = FindConVar("host_timescale");
	flags = GetConVarFlags(TimeScale);
	SetConVarFlags(TimeScale, (flags & ~(FCVAR_CHEAT)));

	// Voting stuff
	CreateConVar("sm_matrix_bt_version",PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	Vote_Matrix_BT = CreateConVar("sm_matrix_bt_vote","1", "Bullet Time Voting on/off.", FCVAR_PLUGIN);
	VoteDelay= CreateConVar("sm_matrix_bt_vote_delay","180.0", "Time before the matrix bullet time vote is allowed after map start.", 0, true, 0.0, true, 1000.0);
	VotesInterval = CreateConVar("sm_matrix_bt_vote_int", "180.0", "Interval between vote casts.", 0, true, 0.0, true, 60.0);

	// Event hooks
	HookEvent("bullet_impact", BulletImpact);

	// Auto-generate config
	AutoExecConfig();

	hGameConf = LoadGameConfigFile("plugin.matrix_lasers");

	// Prep some virtual SDK calls
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "Weapon_ShootPosition");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	hGetWeaponPosition = EndPrepSDKCall();

}

public OnMapStart()
{
	StartTime = GetTime();
	precache_laser = PrecacheModel("materials/sprites/laser.vmt");

	PrecacheSound( "misc/matrix/enter.mp3", true);
	PrecacheSound( "misc/matrix/exit.mp3", true);
}

public Action:Command_OnSay( client , args)
{
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));

	new String:User[32];
	GetClientName(client,User,31);

	new startidx;
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if ((strcmp(text[startidx], "bullet", false) == 0) || (strcmp(text[startidx], "bt", false) == 0) || (strcmp(text[startidx], "bullet time", false) == 0))
	{
		new bullet_time = GetConVarInt(TimeScale);
		if(bullet_time == 0.5)
		{
			PrintToChatAll("Wooohhhh i see bullet flying around!");
		}
		if(bullet_time == 1)
		{
			PrintToChatAll("Boring normal time is on now.");
		}
		return Plugin_Handled;
	}

	if (strcmp(text[startidx], "vote_bullettime", false) == 0)
	{
		new Float:MATRIX_BT_VOTE = GetConVarFloat(Vote_Matrix_BT);
		if(MATRIX_BT_VOTE == 1 && enable_tracer == 0)
		{
			if (IsVoteInProgress())
			{
				PrintToChat( client ,"[SM]  Voting has started...");
				return Plugin_Handled;
			}

			new nFromStart = GetTime() - StartTime;
			new nFromLast = GetTime() - LastVote;	

			new bullet_time = GetConVarInt(TimeScale);

			if(nFromLast >= GetConVarInt(VotesInterval))
			{
				if(nFromStart >= GetConVarInt(VoteDelay))
				{
					PrintToChatAll("%s :   vote_bullettime", User);
					if(bullet_time == 1)
					{
						new Handle:menu = CreateMenu(Handle_Matrix_BT2_VoteMenu);
						SetMenuTitle(menu, "Do you want Matrix style bullet time?");
						AddMenuItem(menu, "yes", "Slow down the time Neo!");
						AddMenuItem(menu, "no", "No thanks");
						SetMenuExitButton(menu, false);
						VoteMenuToAll(menu, 20);
					}
					if(bullet_time == 0.5)
					{
						new Handle:menu = CreateMenu(Handle_Matrix_BT2_VoteMenu);
						SetMenuTitle(menu, "Do you want Normal time back?");
						AddMenuItem(menu, "yes", "Yes Neo please!");
						AddMenuItem(menu, "no", "No thanks");
						SetMenuExitButton(menu, false);
						VoteMenuToAll(menu, 20);
					}
					LastVote = GetTime();
					PrintToChat( client ,"[SM]  Vote started...");
					PrintToChatAll("[SM]  The matrix bullet time vote has started!");
				}
				else
				{
					PrintToChat( client ,"[SM]  Voting not allowed yet.");
				}
			}
			else
			{
				PrintToChat( client ,"[SM]  Voting not allowed yet.");
			}
		}
		if(MATRIX_BT_VOTE == 0)
		{
			PrintToChat( client ,"[SM]  Sorry, 'vote_bullettime' is disabled unless admin sets it otherwise");
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	if( enable_tracer == 1 )
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));	

		new Float:bulletOrigin[3];
		SDKCall( hGetWeaponPosition, attacker, bulletOrigin );

		new Float:bulletDestination[3];
		bulletDestination[0] = GetEventFloat( event, "x" );
		bulletDestination[1] = GetEventFloat( event, "y" );
		bulletDestination[2] = GetEventFloat( event, "z" );

		// The following code moves the beam a little bit further away from the player
		new Float:distance = GetVectorDistance( bulletOrigin, bulletDestination );

		// calculate the percentage between 0.4 and the actual distance
		new Float:percentage = 0.4 / ( distance / 100 );

		// we add the difference between origin and destination times the percentage to calculate the new origin
		new Float:newBulletOrigin[3];
		newBulletOrigin[0] = bulletOrigin[0] + ( ( bulletDestination[0] - bulletOrigin[0] ) * percentage );
		newBulletOrigin[1] = bulletOrigin[1] + ( ( bulletDestination[1] - bulletOrigin[1] ) * percentage ) - 0.08;
		newBulletOrigin[2] = bulletOrigin[2] + ( ( bulletDestination[2] - bulletOrigin[2] ) * percentage );
	
		new color[4]={224,224,255,150};

		TE_SetupBeamPoints( newBulletOrigin, bulletDestination, precache_laser, 0, 0, 0, 0.3, 3.0, 3.0, 1, 0.0, color, 0);
		TE_SendToAll();
	}
}


public Handle_Matrix_BT2_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);
	} 
	else if (action == MenuAction_VoteEnd)
	{
		new bullet_time = GetConVarInt(TimeScale);
		PrintToChatAll("[SM]  Vote has ended...");

		if(bullet_time == 1)
		{
			/* 0=yes, 1=no */
			if (param1 == 0)
			{
				PrintToChatAll("Voting Results: Matrix Bullet Time has started for 15 Seconds!");
				
				CreateTimer(0.1, count_15);
				CreateTimer(0.5, count_14);
				CreateTimer(1.0, count_13);
				CreateTimer(1.5, count_12);
				CreateTimer(2.0, count_11);
				CreateTimer(2.5, count_10);
				CreateTimer(3.0, count_9);
				CreateTimer(3.5, count_8);
				CreateTimer(4.0, count_7);
				CreateTimer(4.5, count_6);
				CreateTimer(5.0, count_5);
				CreateTimer(5.5, count_4);
				CreateTimer(6.0, count_3);
				CreateTimer(6.5, count_2);
				CreateTimer(7.0, count_1);
				CreateTimer(7.5, count_01);

			}
			if (param1 == 1)
			{
				PrintToChatAll("Voting Results: Matrix Bullet Time vote failed!");
			}
		}
	}
}

public Action:Command_Matrix_BT(client, Arguments)
{
	//Error Check:
	if(Arguments < 1)
	{

		PrintToConsole(client, "[SM]  Usage: sm_matrix_bt 1/0");
		return Plugin_Handled;
	}

	//Retrieve Arguments:
	new String:Given_Matrix_BT[32], Converted_Matrix_BT;
	GetCmdArg(1, Given_Matrix_BT, sizeof(Given_Matrix_BT));
		
	//Convert:
	StringToIntEx(Given_Matrix_BT, Converted_Matrix_BT);

	new String:User[32];
	GetClientName(client,User,31);

	if(Converted_Matrix_BT == 1)
	{
		PrintToConsole(client,"[SM]  MATRIX BULLET TIME mode is now ON");
		PrintToChatAll("[SM]  Admin %s has turned MATRIX BULLET TIME ON", User);
		ServerCommand( "host_timescale 0.5" );
	}

	if(Converted_Matrix_BT == 0)
	{
		PrintToConsole(client,"[SM]  MATRIX BULLET TIME mode is now OFF");
		PrintToChatAll("[SM]  Admin %s has turned MATRIX BULLET TIME OFF", User);
		ServerCommand( "host_timescale 1" );
	}

	return Plugin_Handled;
}

public Action:count_01(Handle:timer){
enable_tracer = 0;
ServerCommand( "host_timescale 1" );
EmitSoundToAll("misc/matrix/exit.mp3");
PrintCenterTextAll("Bullet Time has ended!");
}

public Action:count_1(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 1 second!");
}

public Action:count_2(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 2 second!");
}

public Action:count_3(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 3 second!");
}

public Action:count_4(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 4 second!");
}

public Action:count_5(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 5 second!");
}

public Action:count_6(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 6 second!");
}

public Action:count_7(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 7 second!");
}

public Action:count_8(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 8 second!");
}
public Action:count_9(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 9 second!");
}

public Action:count_10(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 10 second!");
}

public Action:count_11(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 11 second!");
}

public Action:count_12(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 12 second!");
}

public Action:count_13(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 13 second!");
}

public Action:count_14(Handle:timer){
PrintCenterTextAll("Bullet Time will end in 14 second!");
}

public Action:count_15(Handle:timer){
enable_tracer = 1;
EmitSoundToAll("misc/matrix/enter.mp3");
ServerCommand( "host_timescale 0.5" );
PrintCenterTextAll("Bullet Time will end in 15 second!");
}