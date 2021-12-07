#include <sourcemod>
//#include <clientprefs>
#include <morecolors>
//#include <sdktools_functions>
//#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2_player>
#include <freak_fortress_2>
int BossIndex;
int respawn[MAXPLAYERS+1];
//int team[MAXPLAYERS+1];



public Plugin myinfo =
{
	name = "Respawn ticket for FF2",
	author = "fafa_junhe, Hoto Cocoa, WhiteFalcon",
	description = "Respawn player in ff2",
	version = "1.1",
	url = "https://forums.alliedmods.net/"
};
ConVar cvarPlayersLeft
ConVar cvarToomuchDamage
public void OnPluginStart()
{
	RegAdminCmd("sm_spawn", Command_spawn, ADMFLAG_RESERVATION, "Use a respawn ticket.");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("teamplay_round_start", On_RoundStart, EventHookMode_Pre);
	cvarPlayersLeft = CreateConVar("respawn_playersleft", "4", "When the number of players alive is less than this, players are not allowed to respawn, 0 to disable.", _, true, 1.0, true, 34.0);
	cvarToomuchDamage = CreateConVar("respawn_toomuchdamage", "1", "1 - Don't allow player to respawn when their damage reach the ragedamage. 0 - Disable.", _, true, 0.0, true, 1.0);
}
public void On_RoundStart(Event hevent, const char[] name, bool dontBroadcast)
{
	for(int n=1; n <= MaxClients; n++)
	{
		if(!IsClientInGame(n))	continue;
		respawn[n]=true;
	}
	GetBossIndex();
}

public void GetBossIndex()
{
	BossIndex = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client))	continue;
		int boss = FF2_GetBossIndex(client);
		if (boss < 0)	continue;
		BossIndex = boss;
		break;
	}
}

GetAlivePlayersCount( iTeam )
{
  new iCount, i; iCount = 0;

  for( i = 1; i <= MaxClients; i++ )
    if( IsClientInGame( i ) && IsPlayerAlive( i ) && GetClientTeam( i ) == iTeam )
      iCount++;

  return iCount;
} 

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new DeathFlags = GetEventInt(event, "death_flags");
	new Bossteam = FF2_GetBossTeam();
	
	if (Bossteam == GetClientTeam(client))
	{
		respawn[client] = true;
	}
    if (DeathFlags & 32)
    {
        //dead ringer
    }
    else
    {
		if (CheckCommandAccess(client, "sm_spawn", ADMFLAG_RESERVATION))
		{
			if(!respawn[client])
			{
				
			}
			else
			{
				show_Panel(client);
			}
		}
	}


}

public Action Command_spawn (int client, int args)
{
	if(!IsClientInGame(client))
	{
		//InGame Only
		return Plugin_Handled;
	}
	if(FF2_GetBossIndex(client) != -1)
	{
		//Player is Boss
		CPrintToChat(client,"{default}[{olive}FF2{default}]Boss cannot respawn", client);
		return Plugin_Handled;
	}
	if(cvarToomuchDamage.IntValue)
	{	
		if(FF2_GetClientDamage(client) >= FF2_GetBossRageDamage(BossIndex))
		{
			//Player's damage has reached the ragedamage
			CPrintToChat(client,"{default}[{olive}FF2{default}]You have dealt a lot of damage so there's no need to respawn", client);
			return Plugin_Handled;
		}
	}
	if(FF2_GetRoundState() != 1)
	{
		//Round Is not in progress "yet"
		CPrintToChat(client,"{default}[{olive}FF2{default}]You can only respawn in game.", client);
		return Plugin_Handled;
	}
	if(GetAlivePlayersCount(GetClientTeam(client)) <= cvarPlayersLeft)
	{
		//We are in the endgame
		CPrintToChat(client,"{default}[{olive}FF2{default}]You cannot respawn because we are at the endgame.", client);
		return Plugin_Handled;
	}
	static int CurHealth, CurDamage, CurLives;
	CurLives = FF2_GetBossLives(BossIndex);
	CurHealth = FF2_GetBossHealth(BossIndex);
	CurDamage = FF2_GetClientDamage(client);
	if(IsPlayerAlive(client))
	{
		//You are alive
		CPrintToChat(client,"{default}[{olive}FF2{default}]You are still alive.", client);
		return Plugin_Handled;
	}
	if(!respawn[client])
	{
		//Used your spawn ticket
		CPrintToChat(client,"{default}[{olive}FF2{default}]You have already used the ticket in this round.", client);
		return Plugin_Handled;
	}
	if(CurHealth <= 0 || CurLives <= 0)
	{
		//boss already dead
		CPrintToChat(client,"{default}[{olive}FF2{default}]Boss is ded.", client);
		return Plugin_Handled;
	}
	TF2_RespawnPlayer(client);
	TF2_RegeneratePlayer(client);
	SetEntityHealth(client, TF2_GetPlayerMaxHealth(client));
	if(CurDamage <=0)
	{
		//no damage therefore no restore
		float CurBossRage;
		CurBossRage = FF2_GetBossCharge(BossIndex, 0);
		CurBossRage = (CurBossRage + 7.00);
		FF2_SetBossCharge(BossIndex, 0, CurBossRage);
		CPrintToChatAll("{default}[{olive}FF2{default}]%N has used a respawn ticket and Boss gains 7% rage.", client);
		respawn[client] = false;
		return Plugin_Handled;
	}
	if(FF2_GetBossMaxLives(BossIndex) > 1)	//Boss has more than 1 live
	{
		//int CalcDmg, Lives;
		/*int CalcDmg;
		CalcDmg = CurDamage;
		for(int n= 1; n <= FF2_GetBossMaxLives(BossIndex); n++)
		{
			if(CalcDmg > FF2_GetBossMaxHealth(BossIndex))
			{
				CalcDmg -= FF2_GetBossMaxHealth(BossIndex);
				//Lives++;
			} else break;
		}*/
		//FF2_SetBossLives(BossIndex, CurLives  + Lives);
		//FF2_SetBossHealth(BossIndex, FF2_GetBossMaxHealth(BossIndex) - CalcDmg);
		int Healthtoset, MaxHealthWithLives;
		MaxHealthWithLives = FF2_GetBossMaxHealth(BossIndex) * FF2_GetBossMaxLives(BossIndex);
		Healthtoset = CurHealth + CurDamage;
		if(Healthtoset > MaxHealthWithLives)
		{
			Healthtoset = MaxHealthWithLives
			FF2_SetBossHealth(BossIndex, Healthtoset);
			CPrintToChatAll("{default}[{olive}FF2{default}]%N uses a respawn ticket. Boss has restore their health!", client);
			respawn[client] = false;
			return Plugin_Handled;
		}
		FF2_SetBossHealth(BossIndex, Healthtoset);
		//FF2_SetBossHealth(BossIndex, FF2_GetBossMaxHealth(BossIndex) * FF2_GetBossMaxLives(BossIndex) - CalcDmg);
		//restore lives wasted by this client 
		//and health
		respawn[client] = false;
		CPrintToChatAll("{default}[{olive}FF2{default}]%N uses a respawn ticket. Boss restores %d HP!", client, CurDamage);
		return Plugin_Handled;
	}
	int Healthtoset2;
	Healthtoset2 = CurHealth + CurDamage;
	if(Healthtoset2 > FF2_GetBossMaxHealth(BossIndex))
	{
		Healthtoset2 = FF2_GetBossMaxHealth(BossIndex);
	}
	FF2_SetBossHealth(BossIndex, Healthtoset2);
	//all done
	CPrintToChatAll("{default}[{olive}FF2{default}]%N uses a respawn ticket. Boss restores %d HP!", client, CurDamage);
	respawn[client] = false;
	return Plugin_Handled;
}


public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (strcmp(info,"yes")>=0)
		{
			FakeClientCommand(param1,"sm_spawn");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
void show_Panel(int client)
{
	char buffer[32];
	Menu menu3 = new Menu(MenuHandler1);
	SetMenuTitle(menu3,"Use a respawn ticket?");
	Format(buffer,sizeof(buffer),"Yes for sure.");
	AddMenuItem(menu3,"yes",buffer);
	Format(buffer,sizeof(buffer),"No, not this time.");
	AddMenuItem(menu3,"no",buffer);
	SetMenuExitButton(menu3,true);
	DisplayMenu(menu3,client,20);
}
