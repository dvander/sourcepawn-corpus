#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

int g_iTarget[MAXPLAYERS + 1];

bool g_bTargetSelected;
bool g_bInverted[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Abusive Admin Commands",
	author = "Mugiwara",
	description = "Abusive Admin commands, that makes the job even better. ^^",
	version = "1.4",
	url = "",
}

/*===============================================================================================================================*/
/********************************************************* [ONLOADS CALLBACKS] ***************************************************/
/*===============================================================================================================================*/

public void OnPluginStart()
{
	RegAdminCmd("sm_target", Cmd_Target, ADMFLAG_GENERIC);
	RegAdminCmd("sm_untarget", Cmd_Untarget, ADMFLAG_GENERIC);
	
	RegAdminCmd("sm_targetsay", Cmd_TargetSay, ADMFLAG_GENERIC);
	RegAdminCmd("sm_targetteamsay", Cmd_TargetTeamSay, ADMFLAG_GENERIC);
	
	RegAdminCmd("sm_chicken", Cmd_Chicken, ADMFLAG_GENERIC);
	RegAdminCmd("sm_brake", Cmd_Brake, ADMFLAG_GENERIC);
	RegAdminCmd("sm_shake", Cmd_Shake, ADMFLAG_GENERIC);
	
	RegAdminCmd("sm_abuse", Cmd_Abuse, ADMFLAG_GENERIC);
	RegAdminCmd("sm_invert", Cmd_Invert, ADMFLAG_GENERIC);
}

/*===============================================================================================================================*/
/********************************************************* [PLAYER QUIT CALLBACKS] ***************************************************/
/*===============================================================================================================================*/
public void OnClientDisconnect(int client)
{
	for (int i = 0; i <= sizeof(g_iTarget); i++)
	{
		if (g_iTarget[i] == client)
			g_iTarget[i] = 0;
	}
	if (g_bInverted[client])
		g_bInverted[client] = false;
}


/*===============================================================================================================================*/
/********************************************************* [TARGET CALLBACKS] ****************************************************/
/*===============================================================================================================================*/

public Action Cmd_Target(int iClient, int iArgs)
{
	if (iArgs < 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_target <playername>");
		
		return Plugin_Handled;
	}
	
	char sTarget[MAX_NAME_LENGTH];
	
	GetCmdArg(1, sTarget, sizeof(sTarget));
	
	int iTarget = FindTarget(iClient, sTarget);
	
	if (IsValidClient(iTarget))
	{
		g_iTarget[iClient] = iTarget;
	}
	
	ReplyToCommand(iClient, "[SM] Target selected: %N", g_iTarget[iClient]);
	
	g_bTargetSelected = true;
	
	return Plugin_Continue;
}

public Action Cmd_Untarget(int iClient, int iArgs)
{
	if (iArgs < 0)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_untarget");
		
		return Plugin_Handled;
	}
	
	ReplyToCommand(iClient, "[SM] %N is no longer a target!", g_iTarget[iClient]);
	
	g_iTarget[iClient] = 0;
	
	g_bTargetSelected = false;
	
	return Plugin_Continue;
}

/*===============================================================================================================================*/
/********************************************************* [TARGETSAY CALLBACKS] *************************************************/
/*===============================================================================================================================*/

public Action Cmd_TargetSay(int iClient, int iArgs)
{
	if (iArgs < 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_targetsay <message>");
		
		return Plugin_Handled;
	}
	
	if (!g_bTargetSelected)
	{
		ReplyToCommand(iClient, "[SM] You have to select a target");
		
		return Plugin_Handled;
	}
	
	char sMessage[256];
	
	GetCmdArgString(sMessage, sizeof(sMessage));
	
	StripQuotes(sMessage);
	
	FakeClientCommand(g_iTarget[iClient], "say %s", sMessage);
	
	return Plugin_Continue;
}

public Action Cmd_TargetTeamSay(int iClient, int iArgs)
{
	if (iArgs < 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_targetsay <message>");
		
		return Plugin_Handled;
	}
	
	if (!g_bTargetSelected)
	{
		ReplyToCommand(iClient, "[SM] You have to select a target");
		
		return Plugin_Handled;
	}
	
	char sMessage[256];
	
	GetCmdArgString(sMessage, sizeof(sMessage));
	
	StripQuotes(sMessage);
	
	FakeClientCommand(g_iTarget[iClient], "say_team %s", sMessage);
	
	return Plugin_Continue;
}

/*===============================================================================================================================*/
/********************************************************* [CHICKEN CALLBACKS] ***************************************************/
/*===============================================================================================================================*/

public Action Cmd_Chicken(int iClient, int iArgs)
{
	if (!g_bTargetSelected)
	{
		ReplyToCommand(iClient, "[SM] You have to select a target");
		
		return Plugin_Handled;
	}
	
	float fLocation[3];
		
	GetEntPropVector(g_iTarget[iClient], Prop_Send, "m_vecOrigin", fLocation);
		
	int iChicken = CreateEntityByName("chicken");
	
	if (IsValidEntity(iChicken))
	{
		DispatchSpawn(iChicken);
		
		SetEntityModel(iChicken, "models/chicken/chicken.mdl");
		
		TeleportEntity(iChicken, fLocation, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Continue;
}

/*===============================================================================================================================*/
/********************************************************* [MOVEMENT CALLBACKS] **************************************************/
/*===============================================================================================================================*/

public Action Cmd_Brake(int iClient, int iArgs)
{
	if (!g_bTargetSelected)
	{
		ReplyToCommand(iClient, "[SM] You have to select a target");
		
		return Plugin_Handled;
	}

	SetEntPropFloat(g_iTarget[iClient], Prop_Data, "m_flLaggedMovementValue", 0.0);
		
	CreateTimer(1.0, Timer_Default, iClient);
	
	return Plugin_Continue;
}

public Action Timer_Default(Handle hTimer, int iClient)
{
	SetEntPropFloat(g_iTarget[iClient], Prop_Data, "m_flLaggedMovementValue", 1.0);
}

/*===============================================================================================================================*/
/********************************************************* [SHAKE CALLBACKS] *****************************************************/
/*===============================================================================================================================*/

public Action Cmd_Shake(int iClient, int iArgs)
{
	if (!g_bTargetSelected)
	{
		ReplyToCommand(iClient, "[SM] You have to select a target");
		
		return Plugin_Handled;
	}
	
	ScreenShake(g_iTarget[iClient]);
	
	return Plugin_Continue;
}

/*===============================================================================================================================*/
/********************************************************* [MENU CALLBACKS] ******************************************************/
/*===============================================================================================================================*/

public Action Cmd_Abuse(int iClient, int iArgs)
{
	if (IsValidClient(iClient))
	{
		Menu hMenu = new Menu(Menu_Handler);
		
		hMenu.SetTitle("Abusive Admin Commands");
		
		hMenu.AddItem("", "Spawn Chicken");
		hMenu.AddItem("", "Slam Brake");
		hMenu.AddItem("", "Shake Screen");
		
		hMenu.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int Menu_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam)
{
	switch (hAction)
	{
		case MenuAction_Select:
		{
			if (IsValidClient(iClient))
			{
				switch (iParam)
				{
					case 0: ClientCommand(iClient, "sm_chicken");
					
					case 1: ClientCommand(iClient, "sm_brake");
					
					case 2: ClientCommand(iClient, "sm_shake");
				}
			}
		}
		
		case MenuAction_End:
		{
			delete hMenu;
		}
	}
}

/*===============================================================================================================================*/
/********************************************************* [INVERT COMMANDS CALLBACKS] *******************************************/
/*===============================================================================================================================*/

public Action Cmd_Invert(int iClient, int args)
{
	if (!g_bTargetSelected)
	{
		ReplyToCommand(iClient, "[SM] You have to select a target");
		
		return Plugin_Handled;
	}
	
	g_bInverted[g_iTarget[iClient]] = !g_bInverted[g_iTarget[iClient]];
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &impulse, float vel[3], float angles[3], int &weapon) 
{
	if (g_bInverted[iClient]) 
	{
		vel[1] = -vel[1]; // Will always equal to the opposite value, according to rules of arithmetic.

		if (iButtons & IN_MOVELEFT) // Fixes walking animations for CS:GO.
		{
			iButtons &= ~IN_MOVELEFT;
			iButtons |= IN_MOVERIGHT;
		}
		else if (iButtons & IN_MOVERIGHT)
		{
			iButtons &= ~IN_MOVERIGHT;
			iButtons |= IN_MOVELEFT;
		}

		vel[0] = -vel[0];
	
		if(iButtons & IN_FORWARD)
		{
			iButtons &= ~IN_FORWARD;
			iButtons |= IN_BACK;
		}
		else if (iButtons & IN_BACK)
		{
			iButtons &= ~IN_BACK;
			iButtons |= IN_FORWARD;
		}
		return Plugin_Changed;
	}	
	return Plugin_Continue;
}


/*===============================================================================================================================*/
/********************************************************* [STOCKS] **************************************************************/
/*===============================================================================================================================*/

stock bool IsValidClient(int iClient)
{
	if (!(0 < iClient <= MaxClients) || !IsClientInGame(iClient) || IsFakeClient(iClient))
	{
		return false;
	}
	
	return true;
}

stock int ScreenShake(int iClient, float fAmplitude = 100.0)
{
	Handle hMessage = StartMessageOne("Shake", iClient, 1);
	
	PbSetInt(hMessage, "command", 0);
	PbSetFloat(hMessage, "local_amplitude", fAmplitude);
	PbSetFloat(hMessage, "frequency", 255.0);
	PbSetFloat(hMessage, "duration", 5.0);
	
	EndMessage();
}