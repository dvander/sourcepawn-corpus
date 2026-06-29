#include <sourcemod>
#include <sdktools>

#define PREFIX "[SM] "

bool:IsClientInCall[MAXPLAYERS+1] = {false, ...};
int CallPartner[MAXPLAYERS+1][2];
int g_CallCount = 0;

public Plugin:myinfo =
{
	name = "Admin call",
	author = "tommie113",
	description = "Admins can call players.",
	version = "1.1",
	url = "https://www.sourcemod.net/"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_call", CallCmd, ADMFLAG_ROOT);
	RegAdminCmd("sm_leavecall", LeavecallCmd, ADMFLAG_ROOT);
	RegAdminCmd("sm_joincall", JoincallCmd, ADMFLAG_ROOT);
}

public OnMapStart()
{
	g_CallCount = 0;
	for(new i = 0; i<MAXPLAYERS+1; i++)
	{
		IsClientInCall[i] = false;
		CallPartner[i][0] = 0;
		CallPartner[i][1] = 0;
	}
}

public OnClientConnected(client)
{
	IsClientInCall[client] = false;
	CallPartner[client][0] = 0;
	CallPartner[client][1] = 0;
	
	if(g_CallCount > 0)
	{
		for(new i = 1; i<MAXPLAYERS; i++)
		{
			if(CallPartner[i][0] != 0)
			{
				SetListenOverride(i, client, Listen_No);
				SetListenOverride(client, i, Listen_No);
				SetListenOverride(CallPartner[i][0], client, Listen_No);
				SetListenOverride(client, CallPartner[i][0], Listen_No);
				
				if(CallPartner[i][1] != 0)
				{
					SetListenOverride(CallPartner[i][1], client, Listen_No);
					SetListenOverride(client, CallPartner[i][1], Listen_No);
				}
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if(IsClientInCall[client])
	{	
		int target1;
		target1 = CallPartner[client][0];
		int target2;
		target2 = CallPartner[client][1];
		
		new AdminId:admin = GetUserAdmin(client);
		
		if(target2 != 0 && GetAdminFlag(admin, Admin_Root, Access_Effective))
		{
			for(new i = 1; i<MAXPLAYERS; i++)
			{
				if(client != i && IsClientConnected(i) && !IsFakeClient(i))
				{
					SetListenOverride(i, client, Listen_Default);
					SetListenOverride(client, i, Listen_Default);
				}
			}
			
			if(CallPartner[target1][0] == client)
			{
				CallPartner[target1][0] = CallPartner[target1][1];
				CallPartner[target1][1] = 0;
			} else if(CallPartner[target1][1] == client)
			{
				CallPartner[target1][1] = 0;
			}
			
			if(CallPartner[target2][0] == client)
			{
				CallPartner[target2][0] = CallPartner[target2][1];
				CallPartner[target2][1] = 0;
			} else if(CallPartner[target2][1] == client)
			{
				CallPartner[target2][1] = 0;
			}
			
			char clientname[64];
			GetClientName(client, clientname, sizeof(clientname));
			PrintToChat(target1, "%s%s has left your call, because he has left the server!", PREFIX, clientname);
			PrintToChat(target2, "%s%s has left your call, because he has left the server!", PREFIX, clientname);
			
			IsClientInCall[client] = false;
			CallPartner[client][0] = 0;
			CallPartner[client][1] = 0;
		}
		
		if(!GetAdminFlag(admin, Admin_Root, Access_Effective))
		{
			for(new i = 1; i<MAXPLAYERS; i++)
			{
				if(target1 != i && client != i && IsClientConnected(i) && !IsFakeClient(i))
				{
					SetListenOverride(i, client, Listen_Default);
					SetListenOverride(client, i, Listen_Default);
					SetListenOverride(i, target1, Listen_Default);
					SetListenOverride(target1, i, Listen_Default);
				
					if(target2 != 0 && target2 != i)
					{
						SetListenOverride(i, target2, Listen_Default);
						SetListenOverride(target2, i, Listen_Default);
					}
				}
			}
			
			SetListenOverride(client, target1, Listen_Default);
			SetListenOverride(target1, client, Listen_Default);
			
			IsClientInCall[client] = false;
			IsClientInCall[target1] = false;
			IsClientInCall[target2] = false;
			
			char clientname[64];
			GetClientName(client, clientname, sizeof(clientname));
			PrintToChat(target1, "%sYour call has been stopped because %s left the server. You can now hear everyone again and everyone can hear you again!", PREFIX, clientname);
			if(target2 != 0)
			{
				PrintToChat(target2, "%sYour call has been stopped because %s left the server. You can now hear everyone again and everyone can hear you again!", PREFIX, clientname);
			}
			
			CallPartner[target1][0] = 0;
			CallPartner[target1][1] = 0;
			CallPartner[target2][0] = 0;
			CallPartner[target2][1] = 0;
			CallPartner[client][0] = 0;
			CallPartner[client][1] = 0;
			
			g_CallCount--;
		}
	}
}

public Action:CallCmd(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "%sUsage: !call <target>", PREFIX);
		return Plugin_Handled;
	}
	
	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int target;
	target = FindTarget(client, arg1, true);
	
	if(target == -1)
	{
		ReplyToCommand(client, "%sCannot find target!", PREFIX);
		return Plugin_Handled;
	}
	
	if(target == client)
	{
		ReplyToCommand(client, "%sYou cannot call yourself!", PREFIX);
		return Plugin_Handled;
	}
	
	if(IsClientInCall[client])
	{
		ReplyToCommand(client, "%sYou are already in a call!", PREFIX);
		return Plugin_Handled;
	}
	
	if(IsClientInCall[target])
	{
		ReplyToCommand(client, "%sThe person you are trying to call is already in a call!", PREFIX);
		return Plugin_Handled;
	}
	
	SetListenOverride(target, client, Listen_Yes);
	SetListenOverride(client, target, Listen_Yes);
	
	for(new i = 1; i<MAXPLAYERS; i++)
	{
		if(target != i && client != i && IsClientConnected(i) && !IsFakeClient(i))
		{
			SetListenOverride(i, client, Listen_No);
			SetListenOverride(client, i, Listen_No);
			SetListenOverride(i, target, Listen_No);
			SetListenOverride(target, i, Listen_No);
		}
	}
	
	IsClientInCall[client] = true;
	IsClientInCall[target] = true;
	CallPartner[client][0] = target;
	CallPartner[target][0] = client;
	
	char targetname[64];
	GetClientName(target, targetname, sizeof(targetname));
	ReplyToCommand(client, "%sYou are now in a call with: %s. Type !stopcall to stop the call!", PREFIX, targetname);
	
	char adminname[64];
	GetClientName(client, adminname, sizeof(adminname));
	PrintToChat(target, "%sYou are now in a call with admin: %s. You can only hear this admin now and he is the only one that can hear you!", PREFIX, adminname);
	
	g_CallCount++;
	
	return Plugin_Handled;
}

public Action:LeavecallCmd(client, args)
{
	if(!IsClientInCall[client])
	{
		ReplyToCommand(client, "%sYou are not in any call right now!", PREFIX);
		return Plugin_Handled;
	}
	
	if(CallPartner[client][0] == 0)
	{
		return Plugin_Handled;
	}
	
	int target1;
	target1 = CallPartner[client][0];
	int target2;
	target2 = CallPartner[client][1];
	
	if(target2 != 0)
	{
		for(new i = 1; i<MAXPLAYERS; i++)
		{
			if(target1 != i && target2 != i && client != i && IsClientConnected(i) && !IsFakeClient(i))
			{
				SetListenOverride(i, client, Listen_Default);
				SetListenOverride(client, i, Listen_Default);
			}
		}
		
		SetListenOverride(client, target1, Listen_No);
		SetListenOverride(target1, client, Listen_No);
		SetListenOverride(client, target2, Listen_No);
		SetListenOverride(target2, client, Listen_No);
		
		
		if(CallPartner[target1][0] == client)
		{
			CallPartner[target1][0] = CallPartner[target1][1];
			CallPartner[target1][1] = 0;
		} else if(CallPartner[target1][1] == client)
		{
			CallPartner[target1][1] = 0;
		}
		
		if(CallPartner[target2][0] == client)
		{
			CallPartner[target2][0] = CallPartner[target2][1];
			CallPartner[target2][1] = 0;
		} else if(CallPartner[target2][1] == client)
		{
			CallPartner[target2][1] = 0;
		}
		
		char clientname[64]; char target1name[64]; char target2name[64];
		GetClientName(client, clientname, sizeof(clientname));
		GetClientName(target1, target1name, sizeof(target2name));
		GetClientName(target2, target2name, sizeof(target2name));
		PrintToChat(target1, "%s%s has left your call. You are now in a call with %s!", PREFIX, clientname, target2name);
		PrintToChat(target2, "%s%s has left your call. You are now in a call with %s!", PREFIX, clientname, target1name);
		
		IsClientInCall[client] = false;
		CallPartner[client][0] = 0;
		CallPartner[client][1] = 0;
		
		ReplyToCommand(client, "%sYou have succesfully left your call!", PREFIX);
		
		return Plugin_Handled;
	}
	
	if(target2 == 0)
	{
		for(new i = 1; i<MAXPLAYERS; i++)
		{
			if(target1 != i && client != i && IsClientConnected(i) && !IsFakeClient(i))
			{
				SetListenOverride(i, client, Listen_Default);
				SetListenOverride(client, i, Listen_Default);
				SetListenOverride(i, target1, Listen_Default);
				SetListenOverride(target1, i, Listen_Default);
			}
		}
		
		SetListenOverride(target1, client, Listen_Default);
		SetListenOverride(client, target1, Listen_Default);
		
		IsClientInCall[client] = false;
		IsClientInCall[target1] = false;
		CallPartner[client][0] = 0;
		CallPartner[target1][0] = 0;
		
		char target1name[64];
		GetClientName(target1, target1name, sizeof(target1name));
		ReplyToCommand(client, "You stopped your call with %s.", target1name);
		
		char adminname[64];
		GetClientName(client, adminname, sizeof(adminname));
		PrintToChat(target1, "%sYour call with %s has been stopped. You can now hear everyone again and everyone can hear you again!", PREFIX, adminname);
		
		g_CallCount--;
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:JoincallCmd(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "%sUsage: !joincall <target>", PREFIX);
		return Plugin_Handled;
	}
	
	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int target;
	target = FindTarget(client, arg1, true);
	
	int target1;
	target1 = CallPartner[target][0];
	int target2;
	target2 = CallPartner[target][1];
	
	if(target == -1)
	{
		ReplyToCommand(client, "%sCannot find target!", PREFIX);
		return Plugin_Handled;
	}
	
	if(target == client)
	{
		ReplyToCommand(client, "%sYou cannot join your own call!", PREFIX);
		return Plugin_Handled;
	}
	
	if(IsClientInCall[client])
	{
		ReplyToCommand(client, "%sYou are already in a call!", PREFIX);
		return Plugin_Handled;
	}
	
	if(!IsClientInCall[target])
	{
		ReplyToCommand(client, "%sThe person you are trying to join is not in a call!", PREFIX);
		return Plugin_Handled;
	}
	
	if(target2 != 0)
	{
		ReplyToCommand(client, "%sThe call you are trying to join already has 3 people in it!", PREFIX);
		return Plugin_Handled;
	}
	
	SetListenOverride(target, client, Listen_Yes);
	SetListenOverride(client, target, Listen_Yes);
	SetListenOverride(target1, client, Listen_Yes);
	SetListenOverride(client, target1, Listen_Yes);
	
	for(new i = 1; i<MAXPLAYERS; i++)
	{
		if(target != i && client != i && target1 != i && IsClientConnected(i) && !IsFakeClient(i))
		{
			SetListenOverride(i, client, Listen_No);
			SetListenOverride(client, i, Listen_No);
		}
	}
	
	char name1[64];
	char name2[64];
	char clientname[64];
	GetClientName(target, name1, sizeof(name1));
	GetClientName(target1, name2, sizeof(name2));
	GetClientName(client, clientname, sizeof(clientname));
	
	ReplyToCommand(client, "%sYou are now in a call with %s and %s! You can only hear them now and they are the only ones that can hear you!", PREFIX, name1, name2);
	
	PrintToChat(target, "%s%s has joined your call!", PREFIX, clientname);
	PrintToChat(target1, "%s%s has joined your call!", PREFIX, clientname);
	
	IsClientInCall[client] = true;
	CallPartner[client][0] = target;
	CallPartner[client][1] = target1;
	CallPartner[target][1] = client;
	CallPartner[target1][1] = client;
	
	return Plugin_Handled;
}